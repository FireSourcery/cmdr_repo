# doc

The reasoning behind the library that the code does not state. Effective Dart is the baseline: an entry records only
where `cmdr` and `struct_data` add to it or depart from it. The principles are the firmware's and are not copied here:
[FireSourcery_Library/Docs/Principles](../../../FireSourcery_Library/Docs/Principles/README.md).

| Folder | Holds | Entry |
|---|---|---|
| [conventions/](conventions/) | Rules followed every time | one topic per file, free-form |
| [decisions/](decisions/) | What we chose and why; binds later work | `NNNN_title.md` |
| [findings/](findings/) | What we measured or learned, dated | `YYYY-MM-DD_title.md` |

A folder is created with its first entry. Patterns (`pattern_name.md`) and findings (`YYYY-MM-DD_title.md`) take the
shapes in [Docs/README.md](../../../FireSourcery_Library/Docs/README.md) of the firmware.

A module's notes are named for the module and ship with the package that holds it, because doc comments carry no
diagram or `##` section ([app decisions/0002](../../kelly_user_app/doc/decisions/0002_markdown_in_md_files.md)):
struct_data's [doc/packet_design.md](../packages/struct_data/doc/packet_design.md) and
[lib/src/packet/packet_payload.md](../packages/struct_data/lib/src/packet/packet_payload.md).

**Lifecycle.** A correction or an open thread starts as a Claude memory. Once settled it becomes an entry here and
leaves memory. A rule applied in every session also gets a short bullet in [CLAUDE.md](../CLAUDE.md), linking its
entry. Where an entry and `CLAUDE.md` disagree, `CLAUDE.md` wins.

## Decision shape

Nygard, "Documenting Architecture Decisions" (2011). A record is not rewritten once accepted; a later one supersedes it.

```markdown
# NNNN Title

**Status** — proposed, accepted, or superseded by NNNN.
**Context** — the forces, and the findings behind them.
**Decision** — what we do.
**Consequences** — what it costs, what it settles, what stays open.
```

## Entries

| Entry | About |
|---|---|
| [conventions/library_code.md](conventions/library_code.md) | Changing library code: fix in place, assert, document, carry type parameters |
| [decisions/0001_hosted_sibling_dependency.md](decisions/0001_hosted_sibling_dependency.md) | Accepted: cmdr names struct_data in hosted form |
| [decisions/0002_flyweight_menu_binds_at_creation.md](decisions/0002_flyweight_menu_binds_at_creation.md) | Accepted: the flyweight menu binds its item buttons at creation; no inherited-widget lookup |
