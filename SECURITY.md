# Security Policy

## Scope

Brainwaves is an offline macOS app. It makes no network requests and has no server. Security concerns are therefore mostly local, for example:

- how user data is stored (`~/Library/Application Support/Brainwaves/userdata.json`, mode `0600`);
- parsing of that file (malformed or hostile JSON);
- the build and release pipeline (`scripts/`, `.github/workflows/`);
- audio safety defects, such as output exceeding the limiter ceiling. We treat these as security issues.

## Reporting

Please report vulnerabilities privately using GitHub's "Report a vulnerability" (Security Advisories) on this repository. Do not open a public issue. We aim to acknowledge reports within 7 days.

## Supported versions

Only the latest release and the `main` branch receive fixes.
