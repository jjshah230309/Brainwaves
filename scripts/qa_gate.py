#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Brainwaves QA gate. See qa/PROCESS.md.

  qa_gate.py                 static checks + QA record consistency (CI on every push)
  qa_gate.py --release       also require every governed file to be approved at its current hash
  qa_gate.py --record R-NNN  record an APPROVE review's artifact hashes in qa/approvals.json
  qa_gate.py --status        show the approval status of each governed file
  qa_gate.py --check-dois    verify bibliography DOIs against Crossref (needs network)
"""
import argparse
import datetime as dt
import glob
import hashlib
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BIB = "docs/research/bibliography.md"
REVIEWS = "qa/reviews"
CORRECTIONS = "qa/corrections-log.md"
APPROVALS = "qa/approvals.json"
CLAIMS_SWIFT = "Sources/BrainwavesCore/Safety/ClaimsPolicy.swift"
GOVERNED = [
    "docs/**/*.md", "Sources/**/*.swift", "Tests/**/*.swift", "scripts/*", "Package.swift", "README.md",
    ".claude/agents/qa-reviewer.md", "qa/RUBRIC.md", "qa/PROCESS.md", ".github/workflows/*.yml",
]
NETWORK_PATTERNS = [r"\bURLSession\b", r"\bURLRequest\b", r"\bNWConnection\b", r"^\s*import\s+Network\b",
                    r"\bCFNetwork\b", r"\bWKWebView\b", r"\bNSURLConnection\b"]
FINDING_ID = re.compile(r"\bR-(\d{3})-F(\d{2})\b")
SEVERITIES_REQUIRING_CORRECTION = {"blocking", "major", "minor"}


def path(rel):
    return os.path.join(ROOT, rel)


def read(rel):
    with open(path(rel), encoding="utf-8") as f:
        return f.read()


def expand(patterns):
    files = set()
    for pattern in patterns:
        for match in glob.glob(path(pattern), recursive=True):
            if os.path.isfile(match):
                files.add(os.path.relpath(match, ROOT))
    return sorted(files)


def sha256(rel):
    with open(path(rel), "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


# ---------------------------------------------------------------- static checks

def bibliography():
    """Returns {key: row_text} from the bibliography tables."""
    entries = {}
    for line in read(BIB).splitlines():
        m = re.match(r"^\|\s*`([a-z0-9][a-z0-9-]*)`\s*\|(.*)$", line)
        if m:
            entries[m.group(1)] = m.group(2)
    return entries


def check_citations(errors):
    entries = bibliography()
    for key, row in entries.items():
        if not re.search(r"https?://", row):
            errors.append(f"{BIB}: entry `{key}` has no DOI or URL")
    for rel in expand(["docs/**/*.md", "README.md"]):
        for n, line in enumerate(read(rel).splitlines(), 1):
            for group in re.findall(r"\[(@[^\]]+)\]", line):
                for key in re.findall(r"@([a-z0-9][a-z0-9-]*)", group):
                    if key not in entries:
                        errors.append(f"{rel}:{n}: citation [@{key}] is not in the bibliography")
    return entries


def banned_phrases():
    source = read(CLAIMS_SWIFT)
    block = re.search(r"bannedPhrases:\s*\[String\]\s*=\s*\[(.*?)\]", source, re.S)
    return re.findall(r'"([^"]+)"', block.group(1)) if block else []


def check_sources(errors):
    phrases = banned_phrases()
    if not phrases:
        errors.append(f"{CLAIMS_SWIFT}: could not read the banned phrase list")
    for rel in expand(["Sources/**/*.swift", "README.md"]):
        text = read(rel)
        lines = text.splitlines()
        if rel != CLAIMS_SWIFT:
            for phrase in phrases:
                for n, line in enumerate(lines, 1):
                    if re.search(r"\b" + re.escape(phrase) + r"\b", line, re.I):
                        errors.append(f"{rel}:{n}: banned claim phrase '{phrase}'")
        if rel.startswith("Sources/"):
            for pattern in NETWORK_PATTERNS:
                for n, line in enumerate(lines, 1):
                    if re.search(pattern, line):
                        errors.append(f"{rel}:{n}: network API is not allowed ({pattern})")
            for n, line in enumerate(lines, 1):
                if re.search(r"brain\.?fm", line, re.I):
                    errors.append(f"{rel}:{n}: competitor name in product source")


# ---------------------------------------------------------------- QA records

def parse_reviews():
    reviews = {}
    for file in sorted(glob.glob(path(f"{REVIEWS}/R-*.md"))):
        text = open(file, encoding="utf-8").read()
        rid = re.search(r"\*\*Review ID:\*\*\s*(R-\d{3})", text)
        verdict = re.search(r"\*\*Verdict:\*\*\s*(REJECT|REVISE|APPROVE)\b", text)
        artifacts = re.search(r"\*\*Artifacts:\*\*\s*(.+)", text)
        findings = {}
        section = text.split("## Findings", 1)[1].split("\n## ", 1)[0] if "## Findings" in text else ""
        for line in section.splitlines():
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) >= 2 and FINDING_ID.fullmatch(cells[0]):
                findings[cells[0]] = cells[1].lower()
        reviews[os.path.basename(file)[:-3]] = {
            "id": rid.group(1) if rid else None,
            "verdict": verdict.group(1) if verdict else None,
            "artifacts": re.findall(r"`([^`]+)`", artifacts.group(1)) if artifacts else [],
            "findings": findings,
            "file": os.path.relpath(file, ROOT),
        }
    return reviews


def parse_corrections():
    rows = {}
    if not os.path.exists(path(CORRECTIONS)):
        return rows
    for line in read(CORRECTIONS).splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells and FINDING_ID.fullmatch(cells[0]):
            rows[cells[0]] = cells
    return rows


def check_records(errors):
    reviews = parse_reviews()
    corrections = parse_corrections()
    for name, review in reviews.items():
        if review["id"] != name:
            errors.append(f"{review['file']}: Review ID does not match the file name")
        if review["verdict"] is None:
            errors.append(f"{review['file']}: missing or invalid verdict")
        if not review["artifacts"]:
            errors.append(f"{review['file']}: no artifacts listed")
        for fid, severity in review["findings"].items():
            if not fid.startswith(name + "-"):
                errors.append(f"{review['file']}: finding {fid} does not belong to {name}")
            if severity not in SEVERITIES_REQUIRING_CORRECTION:
                continue
            row = corrections.get(fid)
            if row is None:
                errors.append(f"{CORRECTIONS}: no correction logged for {severity} finding {fid}")
                continue
            verified = re.search(r"R-\d{3}", row[-1]) if row else None
            if not verified:
                errors.append(f"{CORRECTIONS}: {fid} is not marked as verified by a later review")
            elif verified.group(0) <= name or verified.group(0) not in reviews:
                errors.append(f"{CORRECTIONS}: {fid} must be verified by an existing review later than {name}")
    approvals = load_approvals()
    for entry in approvals["approvals"]:
        review = reviews.get(entry.get("review"))
        if review is None or review["verdict"] != "APPROVE":
            errors.append(f"{APPROVALS}: {entry.get('path')} cites {entry.get('review')}, which is not an APPROVE review")
    return reviews


def load_approvals():
    if not os.path.exists(path(APPROVALS)):
        return {"approvals": []}
    with open(path(APPROVALS), encoding="utf-8") as f:
        return json.load(f)


def approval_status():
    approved = {e["path"]: e for e in load_approvals()["approvals"]}
    status = {}
    for rel in expand(GOVERNED):
        entry = approved.get(rel)
        if entry is None:
            status[rel] = "unapproved"
        elif entry["sha256"] != sha256(rel):
            status[rel] = "changed-since-approval"
        else:
            status[rel] = f"approved ({entry['review']})"
    return status


def record(review_id):
    errors = []
    check_citations(errors)
    check_sources(errors)
    reviews = check_records(errors)
    review = reviews.get(review_id)
    if review is None:
        errors.append(f"no review file qa/reviews/{review_id}.md")
    elif review["verdict"] != "APPROVE":
        errors.append(f"{review_id} verdict is {review['verdict']}, not APPROVE")
    if errors:
        report(errors)
        return 1
    data = load_approvals()
    today = dt.date.today().isoformat()
    files = expand(review["artifacts"])
    keep = [e for e in data["approvals"] if e["path"] not in files]
    keep += [{"path": f, "sha256": sha256(f), "review": review_id, "date": today} for f in files]
    data["approvals"] = sorted(keep, key=lambda e: e["path"])
    with open(path(APPROVALS), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print(f"Recorded approval of {len(files)} file(s) under {review_id}.")
    return 0


def check_dois():
    failures = 0
    for key, row in bibliography().items():
        m = re.search(r"https://doi\.org/(\S+?)\s*\|", row)
        if not m:
            continue
        doi = m.group(1)
        try:
            with urllib.request.urlopen(f"https://api.crossref.org/works/{doi}", timeout=20) as r:
                meta = json.load(r)["message"]
            title = (meta.get("title") or ["?"])[0]
            print(f"ok   {key}: {doi} — {title[:80]}")
        except Exception as e:  # noqa: BLE001 — report every failure, keep going
            failures += 1
            print(f"FAIL {key}: {doi} — {e}")
    return 1 if failures else 0


def report(errors):
    for e in errors:
        print("FAIL", e)
    print(f"{len(errors)} problem(s) found." if errors else "All QA gate checks passed.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--release", action="store_true")
    ap.add_argument("--record", metavar="REVIEW_ID")
    ap.add_argument("--status", action="store_true")
    ap.add_argument("--check-dois", action="store_true")
    args = ap.parse_args()

    if args.record:
        return record(args.record)
    if args.check_dois:
        return check_dois()
    if args.status:
        for rel, state in approval_status().items():
            print(f"{state:28} {rel}")
        return 0

    errors = []
    check_citations(errors)
    check_sources(errors)
    check_records(errors)
    if args.release:
        for rel, state in approval_status().items():
            if not state.startswith("approved"):
                errors.append(f"{rel}: {state}")
    report(errors)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
