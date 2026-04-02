# aski-core — Shared Kernel Schema

The contract between aski-rs (Rust backend) and aski-cc (aski compiler).

Defines the Kernel World — an Ascent struct with typed Datalog relations
representing the simplified aski AST. aski-rs consumes this directly.
aski-cc's Surface DB is a superset that projects down to the Kernel.

## VCS

Jujutsu (`jj`) mandatory. Git is storage backend only.

## Language Policy

Rust only for application logic. Nix only for builds.
