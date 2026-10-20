# Security Policy

## Reporting a vulnerability

This is a Red Hat internal project. Report suspected vulnerabilities in this
pipeline (or in credentials/secrets exposure) through Red Hat Product Security
rather than a public issue:

- Internal: file a ticket in the owning team's Jira project (see `OWNERS`).

Do not include live tokens, credentials, or scan output containing them in reports.

## Scope

This pipeline provisions RHACS Central instances and handles Red Hat SSO, OCM, and
registry credentials. The security assumptions, attack surface, and prioritized
threats are maintained as a versioned, machine-readable artifact:

➡️ See [`THREAT_MODEL.md`](THREAT_MODEL.md).
