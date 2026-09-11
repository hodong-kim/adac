-- ============================================================================
-- adac-ast-validation.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.AST.Validation is

  --! summary: Validate one numeric literal in this store.
  procedure validate_numeric_literal
    (self    : Store;
     literal : Node_ID);

  --! summary: Validate one current discriminant specification.
  procedure validate_discriminant_specification
    (self         : Store;
     discriminant : Node_ID);

  --! summary: Validate one current record component in this store.
  procedure validate_record_component_declaration
    (self      : Store;
     component : Node_ID);

  --! summary: Validate one exception declaration in this store.
  procedure validate_exception_declaration
    (self        : Store;
     declaration : Node_ID);

  --! summary: Validate one derived-type declaration in this store.
  procedure validate_derived_type_declaration
    (self        : Store;
     declaration : Node_ID);

  --! summary: Validate one explicit range constraint in this store.
  procedure validate_range_constraint
    (self       : Store;
     constraint : Node_ID);

  procedure validate_index_constraint
    (self       : Store;
     constraint : Node_ID);

  --! summary: Validate one subtype declaration in this store.
  procedure validate_subtype_declaration
    (self        : Store;
     declaration : Node_ID);

  --! summary: Validate one current record variant.
  procedure validate_record_variant
    (self    : Store;
     variant : Node_ID);

  --! summary: Validate one current record variant part.
  procedure validate_record_variant_part
    (self         : Store;
     variant_part : Node_ID);

  procedure validate_record_type_declaration
    (self        : Store;
     declaration : Node_ID);

  --! summary: Validate one access-to-object type declaration in this store.
  procedure validate_access_object_type_declaration
    (self        : Store;
     declaration : Node_ID);

  procedure validate_exception_handler
    (self    : Store;
     handler : Node_ID);

  --! summary: Validate one bounded block used as a handler statement.
  procedure validate_exception_handler_block_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one current handled sequence in this store.
  procedure validate_handled_sequence
    (self     : Store;
     sequence : Node_ID);

  --! summary: Validate one current elsif part in this store.
  procedure validate_elsif_part
    (self : Store;
     part : Node_ID);

  --! summary: Validate one current if statement in this store.
  procedure validate_if_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one selected extended-return statement.
  procedure validate_extended_return_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one current exit statement.
  procedure validate_exit_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one return statement and optional expression.
  procedure validate_return_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one current raise-with-message statement.
  procedure validate_raise_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one assignment statement in this store.
  procedure validate_assignment_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one case alternative in this store.
  procedure validate_case_alternative
    (self        : Store;
     alternative : Node_ID);

  --! summary: Validate one case statement in this store.
  procedure validate_case_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one block statement in this store.
  procedure validate_block_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one current iterator-loop statement in this store.
  procedure validate_loop_statement
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one procedure-call statement in this store.
  procedure validate_procedure_call
    (self      : Store;
     statement : Node_ID);

  --! summary: Validate one character literal in this store.
  procedure validate_character_literal
    (self    : Store;
     literal : Node_ID);

  --! summary: Validate one string literal in this store.
  procedure validate_string_literal
    (self    : Store;
     literal : Node_ID);

  --! summary: Validate one null literal in this store.
  procedure validate_null_literal
    (self    : Store;
     literal : Node_ID);

  --! summary: Validate one nonaggregate simple-expression shape.
  procedure validate_nonaggregate_simple_expression_shape
    (self       : Store;
     expression : Node_ID);

  --! summary: Validate one current named record aggregate in this store.
  procedure validate_record_aggregate
    (self      : Store;
     aggregate : Node_ID);

  --! summary: Validate one current named array aggregate in this store.
  procedure validate_array_aggregate
    (self      : Store;
     aggregate : Node_ID);

  --! summary: Validate one bounded qualified record-aggregate expression.
  procedure validate_bracket_aggregate
    (self      : Store;
     aggregate : Node_ID);

  procedure validate_qualified_expression
    (self       : Store;
     expression : Node_ID);

  procedure validate_allocator
    (self      : Store;
     allocator : Node_ID);

  --! summary: Validate one explicit-range case choice.
  procedure validate_case_range_choice
    (self   : Store;
     choice : Node_ID);

  --! summary: Validate one explicit-range membership choice.
  procedure validate_membership_range_choice
    (self   : Store;
     choice : Node_ID);

  --! summary: Validate one current short-circuit expression chain.
  procedure validate_short_circuit_expression
    (self       : Store;
     expression : Node_ID);

  --! summary: Validate one current represented expression in this store.
  procedure validate_expression
    (self       : Store;
     expression : Node_ID);

  --! summary: Validate one current name subtree in this store.
  procedure validate_name
    (self : Store;
     name : Node_ID);

  --! summary: Validate one bounded aspect specification in this store.
  procedure validate_aspect_specification
    (self   : Store;
     aspect : Node_ID);

  --! summary: Validate one current parameter specification in this store.
  procedure validate_parameter
    (self      : Store;
     parameter : Node_ID);

  --! summary: Validate one current object-declaration subtree in this store.
  procedure validate_declaration
    (self        : Store;
     declaration : Node_ID);

  --! summary: Validate one current use-type clause in this store.
  procedure validate_use_type_clause
    (self   : Store;
     clause : Node_ID);

  --! summary: Validate one current package-use clause.
  procedure validate_use_package_clause
    (self   : Store;
     clause : Node_ID);

  --! summary: Validate one package-renaming declaration in this store.
  procedure validate_package_renaming_declaration
    (self        : Store;
     declaration : Node_ID);

  --! summary: Validate one generic package-instantiation subtree.
  procedure validate_package_instantiation
    (self          : Store;
     instantiation : Node_ID);

  --! summary: Validate one current package-declaration subtree in this store.
  procedure validate_package_declaration
    (self        : Store;
     declaration : Node_ID);

  --! summary: Validate one selected package-body stub in this store.
  procedure validate_package_body_stub
    (self : Store;
     stub : Node_ID);

  --! summary: Validate one current package-body subtree in this store.
  procedure validate_package_body
    (self : Store;
     package_body : Node_ID);

  --! summary: Validate one current procedure-body subtree in this store.
  procedure validate_procedure_body
    (self : Store;
     procedure_body : Node_ID);

  --! summary: Validate one current subunit subtree in this store.
  procedure validate_subunit
    (self    : Store;
     subunit : Node_ID);

  --! summary: Validate one current function-body subtree in this store.
  procedure validate_function_body
    (self          : Store;
     function_body : Node_ID);

  --! summary: Validate an AST rooted at a node in this store.
  --! contract
  --!   Raises `Program_Error` when the identifier is foreign or an internal
  --!   AST invariant is violated. Validation does not modify the store.
  procedure validate
    (self : Store;
     root : Node_ID);

end Adac.AST.Validation;
