-- ============================================================================
-- adac-compilation-semantics.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Semantics;
with Adac.Source;
with Adac.Symbols;
with Adac.Types;

package Adac.Compilation.Semantics is

  --! summary: Add one direct local binding to an in-progress scope.
  procedure try_bind_local_object
    (self     : Context;
     scope    : in out Adac.Semantics.Lexical_Scope;
     symbol   : Adac.Symbols.Symbol_ID;
     local    : Positive;
     inserted : out Boolean);

  --! summary: Add one local subtype binding to an in-progress scope.
  procedure try_bind_local_subtype
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Adac.Semantics.Subtype_Constraint;
     inserted      : out Boolean);

  --! summary: Add one static local Integer constant binding.
  procedure try_bind_local_static_integer_constant
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Adac.Semantics.Subtype_Constraint;
     value         : Long_Long_Integer;
     inserted      : out Boolean);

  --! summary: Add one static local Boolean constant binding.
  procedure try_bind_local_static_boolean_constant
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Boolean_Value;
     inserted      : out Boolean);

  --! summary: Add one integer named-number binding to an in-progress scope.
  procedure try_bind_local_integer_number
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Integer_Value;
     inserted      : out Boolean);

  --! summary: Add one real named-number binding to an in-progress scope.
  procedure try_bind_local_real_number
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Real_Value;
     inserted      : out Boolean);

  --! summary: Resolve one symbol through an in-progress lexical scope.
  function resolve_local_object
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Natural;

  --! summary: Resolve one local subtype through an in-progress scope.
  function resolve_local_subtype
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the constraint of one in-progress local subtype.
  function resolve_local_subtype_constraint
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint;

  --! summary: Resolve one local static constant to its semantic type.
  function resolve_local_static_integer_constant_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return one local static constant checked integer value.
  function resolve_local_static_integer_constant_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Long_Long_Integer;

  --! summary: Resolve one local static Boolean constant type.
  function resolve_local_static_boolean_constant_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return one local static Boolean constant value.
  function resolve_local_static_boolean_constant_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Boolean_Value;

  --! summary: Resolve one local integer named number to its semantic type.
  function resolve_local_integer_number_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return one local integer named-number checked universal value.
  function resolve_local_integer_number_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Integer_Value;

  --! summary: Resolve one local real named number to its semantic type.
  function resolve_local_real_number_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return one local real named-number checked value.
  function resolve_local_real_number_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Real_Value;

  --! summary: Return the fixed constraint of one supported Standard subtype.
  function resolve_predefined_subtype_constraint
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint;

  --! summary: Return the fixed constraint of one Standard expanded subtype.
  function resolve_predefined_subtype_constraint
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint;

  --! summary: Publish one validated uninitialized local variable object.
  function create_object
    (self          : in out Context;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Adac.Semantics.Subtype_Constraint)
  return Adac.Semantics.Entity_ID;

  --! summary: Publish one local variable with a checked integer initializer.
  function create_object
    (self                : in out Context;
     declaration         : Adac.AST.Node_ID;
     semantic_type       : Adac.Types.Type_ID;
     integer_initializer : Long_Long_Integer;
     constraint          : Adac.Semantics.Subtype_Constraint)
  return Adac.Semantics.Entity_ID;

  --! summary: Publish one local variable with a checked Boolean initializer.
  function create_object
    (self                : in out Context;
     declaration         : Adac.AST.Node_ID;
     semantic_type       : Adac.Types.Type_ID;
     boolean_initializer : Adac.Types.Boolean_Value;
     constraint          : Adac.Semantics.Subtype_Constraint)
  return Adac.Semantics.Entity_ID;

  --! summary: Publish a procedure with scope, locals, and checked statements.
  function create_procedure
    (self        : in out Context;
     declaration : Adac.AST.Node_ID;
     scope       : Adac.Semantics.Lexical_Scope;
     locals      : Adac.Semantics.Entity_ID_List;
     statements  : Adac.Semantics.Procedure_Statement_List)
  return Adac.Semantics.Entity_ID;

  --! summary: Return the number of semantic entities in this compilation.
  function entity_count (self : Context) return Natural;

  --! summary: Return the concrete kind of a context-owned semantic entity.
  function kind_of
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Semantics.Entity_Kind;

  --! summary: Return the syntax declaration associated with an entity.
  function declaration
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the declared symbol associated with an entity.
  function symbol
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the source span associated with an entity.
  function entity_span
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Source.Span;

  --! summary: Return the semantic type of a local object entity.
  function object_type
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the nominal subtype constraint of one local object.
  function object_subtype_constraint
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Semantics.Subtype_Constraint;

  --! summary: Return whether a local object has a checked integer initializer.
  function object_has_integer_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Boolean;

  --! summary: Return the checked integer initializer value of a local object.
  function object_integer_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Long_Long_Integer;

  --! summary: Return whether a local object has a checked Boolean initializer.
  function object_has_boolean_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Boolean;

  --! summary: Return the checked Boolean initializer value of a local object.
  function object_boolean_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Types.Boolean_Value;

  --! summary: Return the directly declared local-object count of a procedure.
  function procedure_local_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID)
  return Natural;

  --! summary: Return one directly declared local object of a procedure.
  function procedure_local_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Entity_ID;

  --! summary: Return the direct lexical binding count of a procedure.
  function procedure_scope_binding_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID)
  return Natural;

  --! summary: Return one procedure binding kind in source order.
  function procedure_scope_binding_kind_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Scope_Binding_Kind;

  --! summary: Return one procedure binding symbol in source order.
  function procedure_scope_binding_symbol_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one procedure binding local ordinal in source order.
  function procedure_scope_binding_local_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return one stored local subtype declaration.
  function procedure_scope_binding_subtype_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one stored local subtype semantic type.
  function procedure_scope_binding_subtype_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one stored local subtype constraint.
  function procedure_scope_binding_subtype_constraint_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Subtype_Constraint;

  --! summary: Return one stored static-constant declaration.
  function procedure_scope_binding_static_constant_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one stored static-constant semantic type.
  function procedure_scope_binding_static_constant_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one stored static-constant nominal constraint.
  function procedure_scope_binding_static_constant_constraint_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Subtype_Constraint;

  --! summary: Return one stored static-constant checked value.
  function procedure_scope_binding_static_constant_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Long_Long_Integer;

  --! summary: Return one stored static Boolean constant value.
  function procedure_scope_binding_static_boolean_constant_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value;

  --! summary: Return one stored integer named-number declaration.
  function procedure_scope_binding_integer_number_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one stored integer named-number semantic type.
  function procedure_scope_binding_integer_number_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one stored integer named-number checked value.
  function procedure_scope_binding_integer_number_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Integer_Value;

  --! summary: Return one stored real named-number declaration.
  function procedure_scope_binding_real_number_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one stored real named-number semantic type.
  function procedure_scope_binding_real_number_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one stored real named-number checked value.
  function procedure_scope_binding_real_number_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Real_Value;

  --! summary: Return one stored binding index for an existing symbol.
  function procedure_scope_binding_index_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural;

  --! summary: Resolve one symbol through a procedure's stored lexical scope.
  function procedure_local_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural;

  --! summary: Resolve one subtype through a procedure's stored lexical scope.
  function procedure_subtype_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the constraint of one stored procedure-local subtype.
  function procedure_subtype_constraint_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint;

  --! summary: Return the checked statement count of a procedure entity.
  function procedure_statement_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID)
  return Natural;

  --! summary: Return one checked procedure statement kind.
  function procedure_statement_kind_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Procedure_Statement_Kind;

  --! summary: Return the canonical syntax node of one checked statement.
  function procedure_statement_syntax
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the bound local ordinal of a checked assignment.
  function assignment_target_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return the expected type of a checked assignment expression.
  function assignment_expected_type
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return the checked integer value of a literal assignment.
  function assignment_integer_value
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Long_Long_Integer;

  --! summary: Return the known Boolean result of a checked assignment.
  function assignment_boolean_value
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value;

  --! summary: Return the logical operator of a Boolean binary assignment.
  function assignment_boolean_operator
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Boolean_Binary_Operator_Kind;

  --! summary: Return the source local ordinal of a checked source read.
  function assignment_source_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return the source-definition statement of a checked source read.
  function assignment_source_definition_statement
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Natural;

  --! summary: Return the right source local of a Boolean binary assignment.
  function assignment_right_source_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return the right source definition of a Boolean binary
  --!          assignment.
  function assignment_right_source_definition_statement
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Natural;

  --! summary: Return the value count of a checked Boolean expression tree.
  function assignment_boolean_expression_value_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Natural;

  --! summary: Return one checked Boolean expression-tree value kind.
  function assignment_boolean_expression_value_kind
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Semantics.Boolean_Expression_Value_Kind;

  --! summary: Return one checked Boolean expression-tree syntax node.
  function assignment_boolean_expression_syntax
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one checked Boolean expression-tree known value.
  function assignment_boolean_expression_known_value
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Types.Boolean_Value;

  --! summary: Return one Boolean expression-tree local source ordinal.
  function assignment_boolean_expression_source_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive;

  --! summary: Return one Boolean expression-tree local definition statement.
  function assignment_boolean_expression_source_definition
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Natural;

  --! summary: Return one Boolean expression-tree binary operator.
  function assignment_boolean_expression_operator
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Semantics.Boolean_Binary_Operator_Kind;

  --! summary: Return one Boolean expression-tree left/unary operand index.
  function assignment_boolean_expression_operand
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive;

  --! summary: Return one Boolean expression-tree binary right operand index.
  function assignment_boolean_expression_right_operand
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive;

  --! summary: Validate an entity and all compilation-context ownership links.
  procedure validate
    (self   : Context;
     entity : Adac.Semantics.Entity_ID);

end Adac.Compilation.Semantics;
