#![allow(non_snake_case)]
//! aski-core — Kernel schema shared between aski-rs and aski-cc.
//!
//! Everything here is generated from kernel.aski by askic.
//! The World struct, relation types, queries, and derivation rules
//! are all generated — no hand-written Ascent.

// World, enums, structs, queries, derive() — all generated from kernel.aski
include!(concat!(env!("OUT_DIR"), "/kernel.rs"));

// ═══════════════════════════════════════════════════════════════
// ID Generator
// ═══════════════════════════════════════════════════════════════

pub struct IdGen {
    pub next: i64,
}

impl IdGen {
    pub fn new() -> Self {
        Self { next: 1 }
    }

    pub fn next(&mut self) -> i64 {
        let id = self.next;
        self.next += 1;
        id
    }
}

impl Default for IdGen {
    fn default() -> Self {
        Self::new()
    }
}

// ═══════════════════════════════════════════════════════════════
// World lifecycle
// ═══════════════════════════════════════════════════════════════

pub fn run_rules(world: &mut World) {
    world.derive();
}

// ═══════════════════════════════════════════════════════════════
// Query functions for the new meta-model
// ═══════════════════════════════════════════════════════════════

/// All types of a given form (Domain or Struct).
pub fn query_types_by_form(world: &World, form: TypeForm) -> Vec<&Type> {
    world.types.iter().filter(|t| t.form == form).collect()
}

/// Type by name.
pub fn query_type_by_name<'a>(world: &'a World, name: &str) -> Option<&'a Type> {
    world.types.iter().find(|t| t.name == name)
}

/// Domain variants ordered by ordinal.
pub fn query_domain_variants(world: &World, domain_name: &str) -> Vec<(i32, String, Option<String>)> {
    let type_id = world.types.iter()
        .find(|t| t.form == TypeForm::Domain && t.name == domain_name)
        .map(|t| t.id);

    let Some(tid) = type_id else { return Vec::new() };

    let mut variants: Vec<_> = world.variants.iter()
        .filter(|v| v.type_id == tid)
        .map(|v| (v.ordinal as i32, v.name.clone(),
                   if v.contains_type.is_empty() { None } else { Some(v.contains_type.clone()) }))
        .collect();
    variants.sort_by_key(|(ord, _, _)| *ord);
    variants
}

/// Struct fields ordered by ordinal.
pub fn query_struct_fields(world: &World, struct_name: &str) -> Vec<(i32, String, String)> {
    let type_id = world.types.iter()
        .find(|t| t.form == TypeForm::Struct && t.name == struct_name)
        .map(|t| t.id);

    let Some(tid) = type_id else { return Vec::new() };

    let mut fields: Vec<_> = world.fields.iter()
        .filter(|f| f.type_id == tid)
        .map(|f| (f.ordinal as i32, f.name.clone(), f.field_type.clone()))
        .collect();
    fields.sort_by_key(|(ord, _, _)| *ord);
    fields
}

/// Which domain owns this variant name?
pub fn query_variant_domain(world: &World, variant_name: &str) -> Option<(String, i64)> {
    world.variant_ofs.iter()
        .find(|v| v.variant_name == variant_name)
        .map(|v| (v.type_name.clone(), v.type_id))
}

/// Instances of a given type.
pub fn query_instances_by_type(world: &World, type_id: i64) -> Vec<&Instance> {
    world.instances.iter().filter(|i| i.type_id == type_id).collect()
}

/// Field values for an instance.
pub fn query_field_values(world: &World, instance_id: i64) -> Vec<&FieldValue> {
    let mut fvs: Vec<_> = world.field_values.iter()
        .filter(|fv| fv.instance_id == instance_id)
        .collect();
    fvs.sort_by_key(|fv| fv.field_ordinal);
    fvs
}

/// Grammar rules for a dialect.
pub fn query_rules_by_dialect<'a>(world: &'a World, dialect: &str) -> Vec<&'a Rule> {
    world.rules.iter().filter(|r| r.dialect == dialect).collect()
}

/// Arms for a rule, ordered by ordinal.
pub fn query_arms(world: &World, rule_id: i64) -> Vec<&Arm> {
    let mut arms: Vec<_> = world.arms.iter()
        .filter(|a| a.rule_id == rule_id)
        .collect();
    arms.sort_by_key(|a| a.ordinal);
    arms
}

/// Pattern elements for an arm, ordered by element ordinal.
pub fn query_pat_elems(world: &World, rule_id: i64, arm_ordinal: i64) -> Vec<&PatElem> {
    let mut elems: Vec<_> = world.pat_elems.iter()
        .filter(|e| e.rule_id == rule_id && e.arm_ordinal == arm_ordinal)
        .collect();
    elems.sort_by_key(|e| e.elem_ordinal);
    elems
}

/// Result elements for an arm, ordered by element ordinal.
pub fn query_result_elems(world: &World, rule_id: i64, arm_ordinal: i64) -> Vec<&ResultElem> {
    let mut elems: Vec<_> = world.result_elems.iter()
        .filter(|e| e.rule_id == rule_id && e.arm_ordinal == arm_ordinal)
        .collect();
    elems.sort_by_key(|e| e.elem_ordinal);
    elems
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn derive_variant_of() {
        let mut world = World::default();
        world.types.push(Type { id: 1, name: "Element".into(), form: TypeForm::Domain, parent: 0 });
        world.variants.push(Variant { type_id: 1, ordinal: 0, name: "Fire".into(), contains_type: String::new() });
        world.variants.push(Variant { type_id: 1, ordinal: 1, name: "Water".into(), contains_type: String::new() });
        run_rules(&mut world);
        assert_eq!(world.variant_ofs.len(), 2);
        assert!(world.variant_ofs.iter().any(|v| v.variant_name == "Fire" && v.type_name == "Element"));
    }

    #[test]
    fn query_domain_variants_ordered() {
        let mut world = World::default();
        world.types.push(Type { id: 1, name: "Sign".into(), form: TypeForm::Domain, parent: 0 });
        world.variants.push(Variant { type_id: 1, ordinal: 2, name: "Gemini".into(), contains_type: String::new() });
        world.variants.push(Variant { type_id: 1, ordinal: 0, name: "Aries".into(), contains_type: String::new() });
        world.variants.push(Variant { type_id: 1, ordinal: 1, name: "Taurus".into(), contains_type: String::new() });
        run_rules(&mut world);
        let variants = query_domain_variants(&world, "Sign");
        assert_eq!(variants[0].1, "Aries");
        assert_eq!(variants[1].1, "Taurus");
        assert_eq!(variants[2].1, "Gemini");
    }

    #[test]
    fn query_struct_fields_ordered() {
        let mut world = World::default();
        world.types.push(Type { id: 1, name: "Point".into(), form: TypeForm::Struct, parent: 0 });
        world.fields.push(Field { type_id: 1, ordinal: 1, name: "Y".into(), field_type: "F64".into() });
        world.fields.push(Field { type_id: 1, ordinal: 0, name: "X".into(), field_type: "F64".into() });
        let fields = query_struct_fields(&world, "Point");
        assert_eq!(fields[0].1, "X");
        assert_eq!(fields[1].1, "Y");
    }

    #[test]
    fn recursive_type_detection() {
        let mut world = World::default();
        world.types.push(Type { id: 1, name: "Tree".into(), form: TypeForm::Struct, parent: 0 });
        world.types.push(Type { id: 2, name: "Branch".into(), form: TypeForm::Struct, parent: 0 });
        world.fields.push(Field { type_id: 1, ordinal: 0, name: "children".into(), field_type: "Branch".into() });
        world.fields.push(Field { type_id: 2, ordinal: 0, name: "subtree".into(), field_type: "Tree".into() });
        run_rules(&mut world);
        assert!(world.recursive_types.iter().any(|r| r.parent_type == "Tree" && r.child_type == "Tree"));
        assert!(world.recursive_types.iter().any(|r| r.parent_type == "Branch" && r.child_type == "Branch"));
    }

    #[test]
    fn instance_and_field_values() {
        let mut world = World::default();
        world.types.push(Type { id: 1, name: "Point".into(), form: TypeForm::Struct, parent: 0 });
        world.instances.push(Instance { id: 100, type_id: 1, parent: 0 });
        world.field_values.push(FieldValue {
            instance_id: 100, field_ordinal: 0, value_kind: FieldValueKind::StringVal,
            ordinal_value: 0, string_value: "hello".into(), ref_value: 0,
        });
        let fvs = query_field_values(&world, 100);
        assert_eq!(fvs.len(), 1);
        assert_eq!(fvs[0].string_value, "hello");
    }
}
