<!-- Written by oma-security. One file per review round: .oma/06-devops/security-review.md -->

# Security review — <project> — round <N>

Reviewed <UTC date> against commit `<short sha>`. Application probed at
`<localhost url>`. Scope: this repository only.

## Verdict

<One paragraph. Is this safe to expose to the internet? If not, the single
reason why. No hedging — the user is making a real decision from this line.>

| Severity | Count | Ship-blocking |
|---|---|---|
| critical | 0 | yes |
| high | 0 | yes |
| medium | 0 | no |
| low | 0 | no |

Dependency audit: `<command>` → `<n critical, n high, n moderate>`
(`<n>` reachable from application code, `<n>` dev-only).

## Findings

### SEC-001 · <severity> · <one-line title>

- **Where:** `path/to/file.ts:42`
- **What an attacker does:** <the concrete steps>
- **What they get:** <the concrete impact — whose data, how much, what they can change>
- **Evidence:**
  ```
  <actual command and output, or the code itself>
  ```
- **Fix:** <specific change, not "validate input">
- **Filed as:** `T-###` (owner: `oma-backend`)

<Repeat per finding, ordered critical → low.>

## Checked and clean

What was verified and found sound. A review listing only problems is
indistinguishable from a review that stopped early.

| Area | How it was checked | Result |
|---|---|---|
| Authorization on user-owned resources | Cross-user probe: user B requested user A's `<resource>` id | 404, correctly scoped |
| Secrets in tree and history | `git log -p` + working-tree scan for key-shaped strings | none found |
| Input validation at route boundaries | every handler in the api contract read | all validate before use |
| Session cookie flags | inspected `Set-Cookie` on login | httpOnly, SameSite=Lax, Secure in prod |
| Password storage | read the hashing call | argon2id, cost params `<...>` |
| ... | | |

## Not checked

<Honest list. Things outside this review: infrastructure, the deploy platform's
own configuration, third-party services, physical/social attack surface,
anything requiring credentials this environment doesn't have.>

## Recommendations beyond the findings

<Hardening worth doing that isn't a defect: rate limiting, CSP tightening,
audit logging, backups. Each with the reason it matters for this application
specifically, not in general.>
