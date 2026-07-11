# Agent Learnings & Improvements Ledger

This ledger records meaningful updates to the agent configuration in `platform-infrastructure`. Governed by **AGT-013**: every pull request must add an entry here.

---

## 2026-07-12 — chore: bump platform-compliance ref v4.0.0 -> v4.0.3

**Change Record:** CHG-20260712-001

- **Compliance ref bump (v4.0.0 → v4.0.3)**: `origin/main` was actually pinned at **v4.0.0** — the
  v4.0.2 branch (CHG-20260711-068) was authored but **never merged** — so this change moves the live
  pin **v4.0.0 → v4.0.3 directly, skipping v4.0.1/v4.0.2**. The diff touches only
  `.github/workflows/compliance.yml` (header comment, `uses:` ref, `platform-compliance-ref:`) and
  the `.github/copilot-instructions.md` header, but this single bump **activates the full v4.0.2
  blast radius plus the v4.0.3 fix at once**, so the whole merge gate was re-simulated locally
  before trusting it.
- **SUP-001 now PASS (0 violations) — upstream policy fix, NOT a waiver**: v4.0.3's
  `POL-SUP-001-TERRAFORM-001` now honours immutable `git::…?ref=<semver-tag|40-hex-sha>` pinning and
  **exempts local `./` modules** from the registry-`version` check. This repo's 7 tag-pinned `git::`
  modules (and 10 in-repo local modules) were previously bogus-flagged (~17 violations under v4.0.0/
  v4.0.2 — see the CHG-20260711-068 entry). The false-positive was escalated upstream to the
  platform-compliance policy-engineer and **landed as a real policy fix in v4.0.3**, so SUP-001 flips
  from **fail → pass** with zero in-repo HCL changes and no waiver.
- **SRC-001 / SRC-002 now PASS — live branch-protection hardening**: both previously blocked solely
  on `dismiss_stale_reviews: false` in `main` protection. Live `main` was hardened to
  `dismiss_stale_reviews=true` (all other hardened fields intact: `enforce_admins=true`, ≥1 review,
  `require_code_owner_reviews=true`, strict required check `Compliance: Merge Gate`,
  `required_linear_history`, `required_conversation_resolution`, `required_signatures`, no force-push/
  deletion), clearing both SRC controls.
- **SEC-001 = pass**: secret scanning + push protection enabled, **0 open** secret-scanning alerts —
  the v4.0.2 collector (`sec-secrets.json`) now evaluates a real pass on this repo.
- **Full merge gate re-simulated locally at v4.0.3 = genuine green**: `merge_gate = PASS`, 39 pass;
  the only two fails are **IAC-002** (plan-before-apply) and **IAC-005** (drift-detection), which are
  **not merge-gate BLOCK controls**. Nothing regressed.

**Rule learned:** re-simulate the *full* merge gate after any compliance-ref bump — a single patch
release can flip a blocking control fail → pass (or inert → blocking). When a blocking control is a
genuine policy false-positive (SUP-001 not recognising `git:: ?ref=` pinning), escalate it upstream
and land the fix in the governed compliance release rather than faking a status or filing a waiver;
a well-pinned repo should pass honestly once the policy is corrected. Also verify the *actual* base
ref on `origin/main` (here v4.0.0, not the assumed v4.0.2) so the PR states the true blast radius.

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

---

## 2026-07-11 — chore: migrate to platform-compliance v4.0.0 and enable agent governance

**Change Record:** CHG-20260711-067

- **Compliance ref bump (v3.3.3 → v4.0.0)**: bumped both `uses: …/reusable-compliance.yml@vX`
  and the `platform-compliance-ref` input in `.github/workflows/compliance.yml`, and updated the
  ref cited in `.github/copilot-instructions.md`.
- **AGT-001..015 now actually run**: the manifest declares the `agent` technology context, which
  puts the 15 AGT controls **in scope**. The reusable workflow, however, only evaluates policies
  for the contexts passed via the `technology-contexts` **input**. Those two were out of sync —
  the manifest listed `agent` but the workflow input did not — so the AGT controls were in-scope
  yet produced **no results**, which the merge gate treats as a failure. Fix: add `agent` to the
  workflow `technology-contexts` input so it matches the manifest and the controls produce results.
- **AGT-012 safety coverage was silently broken**: the root instruction file's only "safety"
  keyword lived inside markdown bold — `Do **not** …`. The collector lowercases the file and does a
  plain substring match for `do not`, and `do **not**` does not contain the literal substring
  `do not`. So `has_safety` was `False` and `instructions.complete` was `False`. Fix: added a real
  `## Safety` section using the literal phrase `do not` (unbolded) plus `destructive`,
  `irreversible`, and `secret`.
- **Instruction file hardened**: added `## Build, test & validation` (terraform fmt/validate/tfsec/
  semgrep/plan) and `## Repository conventions & structure` (repository map + composition patterns)
  so all three AGT-012 dimensions (build/test, conventions, safety) genuinely pass.

**Rule learned:** a technology context has to be enabled in **two** places — the manifest
(`technology_contexts`) *and* the workflow `technology-contexts` input — or the in-scope controls
run empty and the gate fails. And AGT-012 keyword checks are literal substring matches on the
lowercased file: never let a required safety keyword hide inside markdown emphasis (`**not**`),
because `**` breaks the `do not` substring. Prefer plain-text phrasing for compliance keywords.

---

## 2026-07-11 — chore: bump platform-compliance ref v4.0.0 -> v4.0.2

**Change Record:** CHG-20260711-068

- **Compliance ref bump (v4.0.0 → v4.0.2)**: bumped the `platform-compliance-ref` input and the
  cited ref in `.github/copilot-instructions.md`. The change touched only `compliance.yml` +
  `copilot-instructions.md`, but v4.0.2 is a patch that silently **activates two previously-inert
  BLOCK controls** on the merge gate — so the full gate was re-simulated locally before trusting it.
- **SEC-001 became active (collector added in v4.0.2)**: v4.0.0 shipped no collector for
  `sec-secrets.json`, so SEC-001 fell through to `not_applicable` (secret-scanning enforcement was
  dead). v4.0.2's `collect-all-inputs.py` now emits `sec-secrets.json` (open GitHub secret-scanning
  alert count + optional gitleaks scan), so SEC-001 evaluates a real pass/fail and **blocks**.
- **SUP-001 became blocking (engine normalization added in v4.0.2)**: the `SUP-001-TERRAFORM`
  policy is unchanged between v4.0.0 and v4.0.2, but v4.0.2's engine added `control_id_of()` which
  strips the `-TF` suffix and records the terraform result under catalog id **`SUP-001`** (a merge
  gate BLOCK control) instead of the old context-scoped `SUP-001-TF` (which was not in the block
  set → warn). Same failing policy; a pinning failure now **blocks** instead of warning.
- **SEC-001 triage result → PASS (no action needed)**: live `security_and_analysis` already had
  `secret_scanning: enabled` and `secret_scanning_push_protection: enabled`; gitleaks returned 0
  findings and there were **0 open** secret-scanning alerts. No `gh api PATCH` enablement was
  required — the control's target gap did not exist on this repo. SEC-001 = `pass`.
- **SUP-001 triage result → FAIL (policy false-positive, escalated, NOT waived)**: this repo is
  genuinely well-pinned — all **7** external `git::` module sources are tag-pinned
  (`?ref=v1.3.2 … v1.1.0`, corroborated by the collector's `modules_with_mutable_refs: []`) and all
  provider/`required_version` constraints are bounded (`~>`). SUP-001 nonetheless **failed with 17
  violations** because `SUP-001-TERRAFORM` evaluates the registry-style `version` argument, which is
  empty for every `git::` and local `./` module, so it flags all 17 module calls (7 correctly
  tag-pinned git modules + 10 in-repo local modules that can never carry a `version`). There is **no
  valid in-repo Terraform fix** (adding `version =` to a `git::`/local module is invalid HCL and
  would break IAC-001/validate) and it must **not** be waived — escalated to the platform-compliance
  policy-engineer to make the policy honour `?ref=` git pinning and exempt local modules.
- **Regression noted (independent of the bump)**: SRC-001 and SRC-002 also block, both solely on
  `dismiss_stale_reviews: false` in `main` branch protection. The SRC policies are unchanged across
  v4.0.0→v4.0.2, so this is a **live GitHub branch-protection state gap**, not a ref-bump regression;
  remediation (`dismiss_stale_reviews=true`, requires `PLATFORM_ADMIN_TOKEN`) is flagged for a human
  with admin scope rather than changed unilaterally.

**Rule learned:** a compliance patch release can silently activate previously-inert BLOCK controls
(a new collector emitting an input, or an engine change that re-classifies a warn-level result under
a blocking catalog id) even when the repo's own diff is trivial — **always re-simulate the full
merge gate locally after any compliance-ref bump**, never trust an upstream "expected PASS" handoff.
Treat a newly-active security control as a genuine gap to fix (enable the setting), not waive — but
equally, when a newly-blocking control is a policy false-positive (e.g. SUP-001 not recognising
`git:: ?ref=` pinning), the honest fix is to escalate the policy upstream, not to fake a pass or add
a waiver.
