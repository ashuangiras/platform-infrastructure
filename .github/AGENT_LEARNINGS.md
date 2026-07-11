# Agent Learnings & Improvements Ledger

This ledger records meaningful updates to the agent configuration in `platform-infrastructure`. Governed by **AGT-013**: every pull request must add an entry here.

---

## 2026-07-11 — fix: resolve policy failures + pin module sources to v1.0.0

**Change Record:** CHG-20260711-049

- **SUP-001**: Pinned all platform-modules source refs from `?ref=main` to `?ref=v1.0.0`. Using a branch name like `main` is treated as an unpinned dependency — any push to that branch can silently change the behaviour of this infrastructure. Pinning to a semver tag ensures the infrastructure code and the module code are versioned together.
- **SEC-004**: Fixed `terraform-plan.yml` workflow permissions. Top-level `permissions: read-all`; write scoped to the job only.
- **SEC-005**: Added Semgrep SAST scan (`p/terraform` ruleset).
- **LIC-001**: Added MIT LICENSE.
- **SUP-004**: Added release workflow with `anchore/sbom-action`.
- **IAC-005**: Added daily drift detection workflow (`terraform validate` on all component directories).
- **AGT-008**: Added PreToolUse safety hook.
- **AGT-013**: Created this ledger.

**Rule learned:** Infrastructure repositories have the strictest version pinning requirement. A module source `?ref=main` in platform-infrastructure means the running infrastructure could change silently whenever platform-modules is updated. Always pin infrastructure to a specific tag; update the pin deliberately as part of a governed change.
