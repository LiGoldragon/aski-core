# synth-core — Grammar rkyv Contract (askicc↔askic)

synth-core defines every type in the rkyv message that askicc
produces and askic deserializes. corec generates Rust with rkyv
derives from the `.core` definitions. Both askicc (serializer)
and askic (deserializer) depend on synth-core as a Cargo crate
via flake-crates/.

## .core Definitions

- `core/dialect.core` — SurfaceKind, Dialect, DialectTree, Rule,
  Alternative, Item, ItemContent, Label, Tag, Binding,
  LabelKind, TagKind, Casing, Cardinality, DelimKind,
  DialectKind, LiteralToken, KeywordToken.

## How It Works

```
core/dialect.core → corec → generated/synth_core.rs → lib.rs includes it
```

`src/lib.rs` does `include!("../generated/synth_core.rs")`.
Run `corec core generated/synth_core.rs` to regenerate locally.
In nix, the flake runs corec automatically.

## The Pipeline

```
corec       — .core → Rust with rkyv derives (the tool)
synth-core  — grammar .core + corec → Rust rkyv types (this repo)
aski-core   — parse tree .core + corec → Rust rkyv types
askicc      — uses synth-core types → dsls.rkyv (domain-data-tree, all 4 DSLs combined)
askic       — uses synth-core (input) + aski-core (output)
veric/semac — use aski-core / veri-core types
```

## v0.20 Shape

- `SurfaceKind` — Core, Aski, Synth, Exec, **Rfi** (v0.20 adds Rfi, 5 surfaces)
- `Dialect { surface, kind, rules }` — one .synth file, surface-tagged
- `DialectTree { dialects }` — flat Vec across all five surfaces
- `Tag { kind: TagKind }` — output node type identifier (`#Tag#`)
- `Label { binding, kind: LabelKind, casing }` — source-read role
  (`@`, `:`, `'` produce Declare, Reference, Origin bindings)
- Cross-surface refs: `ItemContent::DialectRef { surface: Option<SurfaceKind>, target: DialectKind }`

**v0.20 additions to TagKind:** AssociatedType, AssociatedTypeImpl,
SelfAssocType, SelfRef, RfiGroup.

**v0.20 additions to LabelKind:** AssociatedName. Retired: ExportedName.

**v0.20 additions to DialectKind:** TraitItem, TraitImplItem.

## ⚠️ `core/dialect.core` uses LEGACY fake-enum-TOC

Line 15-19:
```
(Dialect
  DialectTree Dialect Rule Alternative Item ItemContent
  ...)
```

This is the legacy fake-enum-TOC form (same as aski-core .core files).
v0.20 grammar supports a proper module header but corec's parser
hasn't been updated yet. Migration is paired — corec + .core files
together. Not blocking.

## Rust Style

**No free functions — methods on types always.** `main` is the
only exception.

## VCS

Jujutsu (`jj`) mandatory. Git is storage backend only.
