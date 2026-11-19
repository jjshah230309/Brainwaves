# QA Process: From AI-Generated Draft to Approved Release

> [!IMPORTANT]
> **Rule.** No AI-generated artifact (research, design, code, scripts, user-facing copy) may be merged as *approved* or publicly released until:
> 1. an **independent** QA review has recorded an `APPROVE` verdict;
> 2. **every** finding from every earlier review has a documented correction or a justified decline in `qa/corrections-log.md`; and
> 3. `scripts/qa_gate.py --release` passes, which proves that the approved content hashes match the files being released.

## 1. Roles

| Role | Who | Responsibilities |
|---|---|---|
| **Author** | An AI assistant or a human contributor | Produces the artifact; writes corrections |
| **Reviewer** | The `qa-reviewer` subagent (`.claude/agents/qa-reviewer.md`), run in a **fresh context** with read-only tools | Verifies against primary sources, scores, issues the verdict |
| **Maintainer** | A human with write access | Saves the review record verbatim, runs the gate, records the approval, decides releases |

Independence: the reviewer must not be the same session or context that wrote the artifact. It receives only the artifact paths and the earlier review IDs, never the author's reasoning.

## 2. Workflow

```
 Author drafts ──▶ Submit for review (list of artifacts)
                        │
                        ▼
                 Reviewer: R-NNN ──▶ verdict?
                        │
       ┌────────────────┼──────────────────────────┐
     REJECT          REVISE                     APPROVE
       │                │                          │
       ▼                ▼                          ▼
 Author corrects every finding;          Maintainer runs
 logs each in corrections-log.md         `qa_gate.py --record R-NNN`
       │                                  (stores SHA-256 of each artifact)
       ▼                                           │
 Re-review R-NNN+1 (re-verifies all prior          ▼
 findings) ────────────────────────────▶   Release only if
                                           `qa_gate.py --release` passes
```

Any later edit to an approved file changes its hash, so the file returns to *unapproved* until it is reviewed again.

## 3. Records

| File | Contents | Format |
|---|---|---|
| `qa/reviews/R-NNN.md` | One review, saved verbatim | Template in `.claude/agents/qa-reviewer.md` |
| `qa/corrections-log.md` | One row per finding: correction, files changed, and the review that verified it | Markdown table |
| `qa/approvals.json` | Approved artifact hashes | `{ "approvals": [ { "path", "sha256", "review", "date" } ] }` |

## 4. Running a review (Claude Code)

The agent is defined in `.claude/agents/qa-reviewer.md`. In Claude Code, ask:

> Use the qa-reviewer agent to review R-004 for `docs/design/*.md`. Prior reviews: R-002, R-003.

Save the returned record to `qa/reviews/R-004.md` exactly as returned. Then:

```bash
python3 scripts/qa_gate.py            # static checks + record consistency
```

```bash
python3 scripts/qa_gate.py --record R-004   # only for an APPROVE verdict
```

```bash
python3 scripts/qa_gate.py --release  # all governed files approved at current hash
```

```bash
python3 scripts/qa_gate.py --check-dois     # optional: re-verify DOIs against Crossref
```

## 5. Gate checks

| Check | Mode | Fails when |
|---|---|---|
| Citation integrity | always | A `[@key]` in a document has no bibliography entry, or an entry has no DOI or URL |
| Claims policy | always | A banned phrase (from `ClaimsPolicy.swift`) appears in `Sources/` or `README.md` |
| No network code | always | `URLSession`, `URLRequest`, `NWConnection`, `import Network`, `CFNetwork`, `WKWebView` or `NSURLConnection` appear in `Sources/` |
| Trademark | always | "brain.fm" or "brainfm" appears in `Sources/` |
| Correction traceability | always | A `blocking`, `major` or `minor` finding has no row in `corrections-log.md`, or its row is not verified by a later review |
| Approval integrity | always | An approval cites a review that is missing or not `APPROVE` |
| Release coverage | `--release` | A governed file has no approval, or its hash has changed since approval |

Governed files: `docs/**/*.md`, `Sources/**/*.swift`, `Tests/**/*.swift`, `scripts/*`, `Package.swift`, `README.md`, `.claude/agents/qa-reviewer.md`, `qa/RUBRIC.md`, `qa/PROCESS.md`, `.github/workflows/*.yml`.

## 6. Limits of this process

- An AI reviewer can miss errors, just as an author can. The process lowers that risk but does not remove it. A human maintainer remains accountable for releases, and should spot-check at least one review per release.
- The reviewer checks claims against sources it can reach. Paywalled full texts may limit verification; the review must say when that happened.
