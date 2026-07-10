# platform-infrastructure — Agent Guidelines

`platform-infrastructure` is a governed repository. All compliance rules come from the mother repo:

> **[platform-compliance](https://github.com//platform-compliance)**  
> Profile: **`PROF-TERRAFORM-ROOT-V1`** | Compliance ref: **`v2.6.0`**  
> Profile definition: [04-profiles/PROF-TERRAFORM-ROOT-V1.yaml](https://github.com//platform-compliance/blob/main/04-profiles/PROF-TERRAFORM-ROOT-V1.yaml)

Do **not** add governance objects (controls, policies, bindings) here — all governance changes go to platform-compliance.

## Repository context

- **Type:** `terraform-root`
- **Technology contexts:** github,github-actions,terraform
- **Compliance workflow:** `.github/workflows/compliance.yml` — runs on every PR
- **Manifest:** `.compliance-manifest.yaml` — declares profile and contexts

## Terraform root configuration repo

This repository applies real infrastructure. Key controls: IAC-001 (fmt/validate), IAC-002 (plan-before-apply), IAC-003, IAC-004, SUP-001. Never apply without a reviewed plan and a passing deployment gate.

## Delivery model

- `main` is protected: **1 required review + CODEOWNERS + `Compliance: Merge Gate` status check + required commit signatures**.
- All changes land via **PR + bootstrap-merge** (single developer) — see the `pr-engineer` agent.
- Every PR body must include a **Change Record** (`CHG-YYYYMMDD-NNN`) and a completed **Agent Readiness & Retro** section (required by CHG-001 and AGT-014).

## Universal pre-flight (before any work)

1. Confirm `git rev-parse --abbrev-ref HEAD` is **not** `main`. Create a branch: `git checkout -b <area>/<slug>`.
2. Identify which controls apply to your change.
3. Check `.compliance-manifest.yaml` before adding a new technology context.

## Universal post-flight (before opening a PR)

1. Language/tool-specific checks pass (fmt, lint, validate, tfsec — see the author agent).
2. No BLOCK-level compliance gate failures on the branch.
3. PR body has **Change Record** and **Agent Readiness & Retro** section.

## Quick reference

```bash
forge validate <file> --compliance-dir /path/to/platform-compliance
forge check all  --compliance-dir /path/to/platform-compliance
forge gate merge --compliance-dir /path/to/platform-compliance
```
