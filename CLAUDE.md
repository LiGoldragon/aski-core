# aski-core — rkyv Contract (askicc↔askic)

aski-core defines every type that appears in the rkyv message
between askicc and askic. corec generates Rust with rkyv
derives from the .aski definitions. Both askicc (serializer)
and askic (deserializer) depend on aski-core as a Cargo crate
via flake-crates/.

## .aski Definitions

- `core/name.aski` — NameDomain, Operator
- `core/scope.aski` — ScopeKind, Visibility
- `core/span.aski` — Span
- `core/dialect.aski` — Dialect, Rule, Alternative, Item,
  ItemContent, Cardinality, Casing, DelimKind

Still missing: DialectKind, Sigil.

## How It Works

```
core/*.aski → corec → generated/aski_core.rs → lib.rs includes it
```

src/lib.rs does `include!("../generated/aski_core.rs")`.
Run `corec core generated/aski_core.rs` to regenerate locally.
In nix, the flake runs corec automatically.

## The Pipeline

```
corec       — .aski → Rust with rkyv derives (the tool)
aski-core   — grammar .aski + corec → Rust rkyv types (this repo)
sema-core   — parse tree .aski + corec → Rust rkyv types
askicc      — uses aski-core types → rkyv dialect-data-tree
askic       — uses aski-core (input) + sema-core (output)
semac       — uses sema-core types only
```

## Rust Style

**No free functions — methods on types always.** `main` is
the only exception.

## VCS

Jujutsu (`jj`) mandatory. Git is storage backend only.
