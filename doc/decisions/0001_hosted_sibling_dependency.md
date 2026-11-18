# 0001 cmdr names struct_data in hosted form

**Status** — accepted, 2026-11-12.

**Context** — `cmdr` depends on its sibling `struct_data`, and both are meant for pub.dev. pub refuses a path
dependency at publish. Inside the repo's pub workspace, a member that names a sibling by version still resolves to the
local member, with the constraint enforced (`^0.9.0` against a local 0.2.0 fails). Outside a workspace, pub reads only
the package's own pubspec. A path form (`path: ../struct_data`) was applied first, to make the app's git-pinned form
resolve, and rejected: this pubspec is the published artifact.

**Decision** — `packages/cmdr/pubspec.yaml` names `struct_data` in hosted form (`struct_data: ^0.1.3`). A consumer
outside the workspace that needs the local copy carries the override; the app does
([its decision 0001](../../../kelly_user_app/doc/decisions/0001_library_by_path_override.md)).

**Consequences**
- The library pubspec stays publishable; the cost of the hosted form lands on the consumer.
- pub.dev's `struct_data` 0.1.3 differs from the local copy under the same version: the version moves off 0.1.3 at the
  struct_data release, and cmdr's constraint moves with it, which pub enforces inside the workspace.
- pub.dev's `cmdr` is an unrelated package, so cmdr cannot be published under its name; a rename comes first.
