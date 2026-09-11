-- ============================================================================
-- adac-ast-validation.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.AST.Validation is

  package Implementation renames Adac.AST.Validation_Implementation;

  procedure validate_numeric_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    Implementation.validate_numeric_literal (self, literal);
  end validate_numeric_literal;

  procedure validate_discriminant_specification
    (self         : Store;
     discriminant : Node_ID)
  is
  begin
    Implementation.validate_discriminant_specification
      (self, discriminant);
  end validate_discriminant_specification;

  procedure validate_record_component_declaration
    (self      : Store;
     component : Node_ID)
  is
  begin
    Implementation.validate_record_component_declaration (self, component);
  end validate_record_component_declaration;

  procedure validate_exception_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_exception_declaration (self, declaration);
  end validate_exception_declaration;

  procedure validate_derived_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_derived_type_declaration (self, declaration);
  end validate_derived_type_declaration;

  procedure validate_range_constraint
    (self       : Store;
     constraint : Node_ID)
  is
  begin
    Implementation.validate_range_constraint (self, constraint);
  end validate_range_constraint;

  procedure validate_index_constraint
    (self       : Store;
     constraint : Node_ID)
  is
  begin
    Implementation.validate_index_constraint (self, constraint);
  end validate_index_constraint;

  procedure validate_subtype_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_subtype_declaration (self, declaration);
  end validate_subtype_declaration;

  procedure validate_record_variant
    (self    : Store;
     variant : Node_ID)
  is
  begin
    Implementation.validate_record_variant (self, variant);
  end validate_record_variant;

  procedure validate_record_variant_part
    (self         : Store;
     variant_part : Node_ID)
  is
  begin
    Implementation.validate_record_variant_part (self, variant_part);
  end validate_record_variant_part;

  procedure validate_record_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_record_type_declaration (self, declaration);
  end validate_record_type_declaration;

  procedure validate_access_object_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_access_object_type_declaration
      (self, declaration);
  end validate_access_object_type_declaration;

  procedure validate_exception_handler
    (self    : Store;
     handler : Node_ID)
  is
  begin
    Implementation.validate_exception_handler (self, handler);
  end validate_exception_handler;

  procedure validate_exception_handler_block_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_exception_handler_block_statement
      (self, statement);
  end validate_exception_handler_block_statement;

  procedure validate_handled_sequence
    (self     : Store;
     sequence : Node_ID)
  is
  begin
    Implementation.validate_handled_sequence (self, sequence);
  end validate_handled_sequence;

  procedure validate_elsif_part
    (self : Store;
     part : Node_ID)
  is
  begin
    Implementation.validate_elsif_part (self, part);
  end validate_elsif_part;

  procedure validate_if_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_if_statement (self, statement);
  end validate_if_statement;

  procedure validate_extended_return_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_extended_return_statement (self, statement);
  end validate_extended_return_statement;

  procedure validate_exit_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_exit_statement (self, statement);
  end validate_exit_statement;

  procedure validate_return_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_return_statement (self, statement);
  end validate_return_statement;

  procedure validate_raise_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_raise_statement (self, statement);
  end validate_raise_statement;

  procedure validate_assignment_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_assignment_statement (self, statement);
  end validate_assignment_statement;

  procedure validate_case_alternative
    (self        : Store;
     alternative : Node_ID)
  is
  begin
    Implementation.validate_case_alternative (self, alternative);
  end validate_case_alternative;

  procedure validate_case_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_case_statement (self, statement);
  end validate_case_statement;

  procedure validate_block_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_block_statement (self, statement);
  end validate_block_statement;

  procedure validate_loop_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_loop_statement (self, statement);
  end validate_loop_statement;

  procedure validate_procedure_call
    (self      : Store;
     statement : Node_ID)
  is
  begin
    Implementation.validate_procedure_call (self, statement);
  end validate_procedure_call;

  procedure validate_character_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    Implementation.validate_character_literal (self, literal);
  end validate_character_literal;

  procedure validate_string_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    Implementation.validate_string_literal (self, literal);
  end validate_string_literal;

  procedure validate_null_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    Implementation.validate_null_literal (self, literal);
  end validate_null_literal;

  procedure validate_nonaggregate_simple_expression_shape
    (self       : Store;
     expression : Node_ID)
  is
  begin
    Implementation.validate_nonaggregate_simple_expression_shape
      (self, expression);
  end validate_nonaggregate_simple_expression_shape;

  procedure validate_record_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
  begin
    Implementation.validate_record_aggregate (self, aggregate);
  end validate_record_aggregate;

  procedure validate_array_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
  begin
    Implementation.validate_array_aggregate (self, aggregate);
  end validate_array_aggregate;

  procedure validate_bracket_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
  begin
    Implementation.validate_bracket_aggregate (self, aggregate);
  end validate_bracket_aggregate;

  procedure validate_qualified_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    Implementation.validate_qualified_expression (self, expression);
  end validate_qualified_expression;

  procedure validate_allocator
    (self      : Store;
     allocator : Node_ID)
  is
  begin
    Implementation.validate_allocator (self, allocator);
  end validate_allocator;

  procedure validate_case_range_choice
    (self   : Store;
     choice : Node_ID)
  is
  begin
    Implementation.validate_case_range_choice (self, choice);
  end validate_case_range_choice;

  procedure validate_membership_range_choice
    (self   : Store;
     choice : Node_ID)
  is
  begin
    Implementation.validate_membership_range_choice (self, choice);
  end validate_membership_range_choice;

  procedure validate_short_circuit_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    Implementation.validate_short_circuit_expression (self, expression);
  end validate_short_circuit_expression;

  procedure validate_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    Implementation.validate_expression (self, expression);
  end validate_expression;

  procedure validate_name
    (self : Store;
     name : Node_ID)
  is
  begin
    Implementation.validate_name (self, name);
  end validate_name;

  procedure validate_aspect_specification
    (self   : Store;
     aspect : Node_ID)
  is
  begin
    Implementation.validate_aspect_specification (self, aspect);
  end validate_aspect_specification;

  procedure validate_parameter
    (self      : Store;
     parameter : Node_ID)
  is
  begin
    Implementation.validate_parameter (self, parameter);
  end validate_parameter;

  procedure validate_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_declaration (self, declaration);
  end validate_declaration;

  procedure validate_use_type_clause
    (self   : Store;
     clause : Node_ID)
  is
  begin
    Implementation.validate_use_type_clause (self, clause);
  end validate_use_type_clause;

  procedure validate_use_package_clause
    (self   : Store;
     clause : Node_ID)
  is
  begin
    Implementation.validate_use_package_clause (self, clause);
  end validate_use_package_clause;

  procedure validate_package_renaming_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_package_renaming_declaration (self, declaration);
  end validate_package_renaming_declaration;

  procedure validate_package_instantiation
    (self          : Store;
     instantiation : Node_ID)
  is
  begin
    Implementation.validate_package_instantiation (self, instantiation);
  end validate_package_instantiation;

  procedure validate_package_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    Implementation.validate_package_declaration (self, declaration);
  end validate_package_declaration;

  procedure validate_package_body_stub
    (self : Store;
     stub : Node_ID)
  is
  begin
    Implementation.validate_package_body_stub (self, stub);
  end validate_package_body_stub;

  procedure validate_package_body
    (self : Store;
     package_body : Node_ID)
  is
  begin
    Implementation.validate_package_body (self, package_body);
  end validate_package_body;

  procedure validate_procedure_body
    (self : Store;
     procedure_body : Node_ID)
  is
  begin
    Implementation.validate_procedure_body (self, procedure_body);
  end validate_procedure_body;

  procedure validate_subunit
    (self    : Store;
     subunit : Node_ID)
  is
  begin
    Implementation.validate_subunit (self, subunit);
  end validate_subunit;

  procedure validate_function_body
    (self          : Store;
     function_body : Node_ID)
  is
  begin
    Implementation.validate_function_body (self, function_body);
  end validate_function_body;

  procedure validate
    (self : Store;
     root : Node_ID)
  is
  begin
    Implementation.validate (self, root);
  end validate;

end Adac.AST.Validation;
