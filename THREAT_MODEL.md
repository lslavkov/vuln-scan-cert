# Threat Model — vuln-scan-cert

> **SKELETON.** Structure follows the wg-agentic-sdlc `THREAT_MODEL_README.md`
> practice (entry points, assets, threats, mitigations) from memory of its
> description, not the exact published schema. Realign field names/format once the

Paired with [`SECURITY.md`](SECURITY.md) (how to report). This file says **what is in
scope**: security assumptions, attack surface, and prioritized threats. It is meant to
be machine-readable so AI security scanners can focus on the surfaces that matter.

## Assumptions

- Runs on a trusted OpenShift cluster with OpenShift Pipelines (Tekton).
- Kubernetes Secrets are the only credential store; RBAC restricts who can read them.
- Pipeline is triggered by trusted operators / CI, not arbitrary external users.

```yaml
# ---- machine-readable threat model (skeleton) ----
version: 0
system: vuln-scan-cert
description: >
  Tekton pipeline that provisions an RHACS Central, scans container images for CVEs,
  exports results, and optionally destroys the Central.

entry_points:
  - id: EP-01
    name: pipeline-parameters
    detail: >
      images, existing-central-id, destroy-central, cloud-account-id, central-aws-region,
      *-creds-secret. Attacker-influenced values change what is scanned and whether a
      Central is created/destroyed. destroy-central gates deletion; existing-central-id does not prevent deletion.
  - id: EP-02
    name: downloaded-binaries
    detail: >
      roxctl and ocm are fetched at runtime from mirror.openshift.com and github.com over
      HTTPS with redirects followed. Executed as part of the pipeline.
  - id: EP-03
    name: external-apis
    detail: OCM API (api.openshift.com), RHACS Central API (ROX_ENDPOINT).
  - id: EP-04
    name: scanned-image-content
    detail: >
      Untrusted image metadata flows into json-to-csv.py and into filenames derived from
      the image ref.

assets:
  - id: A-01
    name: ROX_API_TOKEN / M2M access token
    sensitivity: high
    note: >
      Large enough to exceed Tekton's 4096-byte result limit. Now passed via a short-lived
      per-PipelineRun Secret (secretKeyRef) instead of a Tekton result (see T-03).
  - id: A-02
    name: OCM_TOKEN
    sensitivity: high
  - id: A-03
    name: rh-openid credentials (CLIENT_ID / CLIENT_SECRET)
    sensitivity: high
  - id: A-04
    name: registry.redhat.io service-account credentials
    sensitivity: high
  - id: A-05
    name: cloud_account_id / provisioned Central instances
    sensitivity: medium
  - id: A-06
    name: scan results (JSON/CSV on scan-results workspace)
    sensitivity: low

threats:
  - id: T-01
    title: Supply-chain compromise of roxctl download in scan path
    entry_point: EP-02
    asset: [A-06, A-01]
    severity: high
    status: open
    detail: >
      scripts/shell/scan-image.sh downloads roxctl (hardcoded v4.4.2) with `curl -sL`
      and NO checksum verification, then executes it. checksum-roxctl.sh exists (CERTSA-73)
      but is not wired into this path. A poisoned mirror or redirect yields arbitrary code
      execution inside the pipeline (see curl CTX II tabletop, wg-agentic-sdlc
      deterministic-package-management).
    mitigation:
      - Verify sha256 before chmod/exec in scan-image.sh using the checksum-roxctl.sh logic.
      - Pin the roxctl version once (align scan-image.sh 4.4.2 with ROXCTL_VERSION) and fail hard on mismatch.
  - id: T-02
    title: Unverified ocm binary download
    entry_point: EP-02
    asset: [A-02, A-05]
    severity: medium
    status: open
    detail: install-ocm.sh fetches a pinned GitHub release URL but does not verify a checksum/signature.
    mitigation: [Add checksum verification for ocm, mirror the roxctl approach.]
  - id: T-03
    title: Secret leakage via task results / logs
    entry_point: EP-01
    asset: [A-01, A-02]
    severity: high
    status: mitigated
    detail: >
      Access tokens were written to Tekton STEP/TASK results and passed via sidecar-logs,
      which echoed them to pod logs in plaintext (issue #31). ROX_API_TOKEN now transits a
      short-lived per-PipelineRun Secret (secretKeyRef), so no token exceeds the 4096-byte
      limit and sidecar-logs is no longer required; OCM_TOKEN stops being logged once the
      cluster reverts results-from to the default. See rhacs/README.md.
    mitigation:
      - ROX_API_TOKEN stored in a per-run Secret, consumed via secretKeyRef; Secret deleted
        in the finally cleanup-creds task and owned by the PipelineRun for GC.
      - Revert results-from/max-result-size cluster flags to defaults (disables sidecar-logs).
      - Scripts never echo token values.
  - id: T-04
    title: Insecure TLS to Central
    entry_point: EP-03
    asset: [A-01, A-06]
    severity: medium
    status: open
    detail: scan-image.sh passes --insecure-skip-tls-verify=${INSECURE}, enabling MITM if set true.
    mitigation: [Default INSECURE=false; document when true is acceptable; verify Central cert.]
  - id: T-05
    title: Unintended Central destruction / cost abuse
    entry_point: EP-01
    asset: [A-05]
    severity: medium
    status: open
    detail: >
      destroy-central=true deletes the Central in the finally block; existing-central-id
      is meant to protect a reused Central. Misconfigured params could delete a shared Central
      or provision unbounded new ones.
    mitigation: [Guard destroy logic against existing-central-id; require explicit review to change it.]
  - id: T-06
    title: Untrusted image metadata handling
    entry_point: EP-04
    asset: [A-06]
    severity: low
    status: open
    detail: image refs drive filenames (sed/regex sanitized) and json-to-csv.py parses scanner output.
    mitigation: [Keep filename sanitization; add a parser self-check; treat scan JSON as untrusted input.]

agent_specific:
  - id: AG-01
    title: Prompt injection via scan output / repo content into an agent
    severity: medium
    mitigation: [Do not feed raw scan output to an agent with tool access; filter/limit.]
  - id: AG-02
    title: Agent secret exposure
    severity: high
    mitigation: [Keep secrets out of agent runtime; see wg-agentic-sdlc agent-secret-isolation.]
```
