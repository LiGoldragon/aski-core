# aski-core — The Anatomy of Aski

The .aski definitions that describe the structure of aski code itself.
Domains, structs, and traits that name every kind of construct in the
aski language. Pure data — no implementation logic.

## What This Is

aski-core defines the **anatomy** of the aski language: what types,
domains, structs, and traits exist in the compiler's data model.
These .aski files are the source of truth for:

- **askicc** — reads these definitions to build its data-tree and
  derive enums from the discovered names
- **askic** — knows what types it's working with

No Rust code, no parser logic. Just the declarative skeleton of
the language.

## The Sema Engine

The sema engine is the 3-compiler pipeline:
- **askicc** reads .synth grammar + aski-core definitions → data-tree
- **askic** uses the data-tree to parse .aski programs → typed parse tree
- **semac** walks the parse tree → .sema binary + codegen

We are building the **bootstrap sema engine** in Rust. When the
engine can compile aski, all Rust will be rewritten in aski —
the **self-hosted sema engine**.

## VCS

Jujutsu (`jj`) mandatory. Git is storage backend only.
