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

---

## 2026-07-11 — feat: data/ + identity/ components + permanent local backend (PC-0162)

**Change Record:** CHG-20260711-057

- **versions.tf**: switched permanently to `backend "local"` per ADR-0014/0020 circular dependency resolution. MinIO cannot store the state of what deploys it. Added postgresql + vault providers.
- **Module refs**: all existing components bumped from v1.0.0 → v1.1.1 (picks up macOS vault/consul compatibility fixes).
- **secrets/ + discovery/**: added `drop_capabilities`, `run_as_user` passthrough variables so root tfvars can override module defaults for macOS staging.
- **data/**: new component — deploys shared PostgreSQL (with authentik DB+role) and Redis (with authentik ACL user). Credentials in sensitive outputs → written to Vault by integrations/.
- **identity/**: new component — deploys Authentik server + worker using data/ outputs as database_url + redis_url inputs. No embedded database.
- **Rule learned**: always pass override variables through the component layer to root variables.tf. Hardcoded module defaults that work on Linux create invisible staging failures. The correct posture: production-safe defaults in modules, staging overrides via tfvars.
