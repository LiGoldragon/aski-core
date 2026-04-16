# aski-core — The Anatomy of Aski + cc

Sema is the thing. Aski is one text notation for specifying
sema. aski-core defines the anatomy of the aski notation and
contains cc (the bootstrap core compiler).

## .aski Anatomy Files

Declarative definitions of aski's structure:
- `core/node.aski` — NodeKind, Node, NameRef, Span
- `core/name.aski` — NameDomain, Operator
- `core/scope.aski` — ScopeKind, Scope, Declaration, Visibility

These are the source of truth. Writing a domain in Rust
instead of defining it in .aski is always wrong.

Domain = any data definition (enum + struct + newtype).
Never means just "enum."

## cc — Core Compiler (crate)

A minimal hardcoded Rust parser that reads the .aski anatomy
files and generates Rust types (NodeKind, NameDomain, etc.).

cc solves the bootstrap problem: .aski files aren't self-
compiling. cc turns them into Rust. Once the engine can
compile aski, cc is replaced by the engine's own parser.

cc's output is used by both askicc and askic.

## The Two Compilers

```
askic (frontend)   .aski → .sema    contains cc + askicc
semac (backend)    .sema → .rs      independent, no aski knowledge
```

Sema is the center. askic is one frontend. semac is the
permanent backend.

## VCS

Jujutsu (`jj`) mandatory. Git is storage backend only.
