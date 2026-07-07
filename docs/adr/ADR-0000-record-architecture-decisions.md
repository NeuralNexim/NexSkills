# ADR-0000: Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-07-07
- **Issue:** —

## Context

NexSkills makes engineering decisions — the installer's multi-tool wrapper scheme, the
`ALL_SKILLS` manifest format, the `nexskills-` filename prefix, the pull-from-`main`
distribution model — that future contributors (human and AI) need to understand. Without a
durable record, the *why* is lost and settled questions get re-litigated.

## Decision

We will record every significant architectural decision as a numbered ADR under `docs/adr/`,
following `docs/ADR_GUIDE.md`. One decision per file. ADRs are frozen on merge and superseded
by new ADRs, never edited in place.

## Consequences

- Installer/manifest/distribution changes carry an ADR before implementation.
- Code and docs can cite `# see ADR-NNNN` instead of inlining rationale.
- Reviewers can reject a PR that makes an architectural change with no ADR.

## Alternatives considered

- **No formal record** — rejected: rationale lives only in commit messages and memory, which
  don't survive.
- **A single running design doc** — rejected: no per-decision status/supersession.
