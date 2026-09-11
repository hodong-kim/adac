-- ============================================================================
-- adac-semantics.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;

with Adac.AST;
with Adac.Source;
with Adac.Symbols;
with Adac.Types;

package Adac.Semantics is

  type Entity_ID is private;

  INVALID_ENTITY_ID : constant Entity_ID;

  type Entity_Kind is
    (Object_Entity,
     Procedure_Body_Entity);

  type Entity_ID_List is private;

  type Procedure_Statement_Kind is
    (Null_Procedure_Statement,
     Return_Procedure_Statement,
     Local_Integer_Static_Assignment_Statement,
     Local_Integer_Copy_Assignment_Statement,
     Local_Boolean_Static_Assignment_Statement,
     Local_Boolean_Copy_Assignment_Statement,
     Local_Boolean_Not_Assignment_Statement,
     Local_Boolean_Binary_Assignment_Statement,
     Local_Boolean_And_Then_Assignment_Statement,
     Local_Boolean_Or_Else_Assignment_Statement,
     Local_Boolean_Expression_Assignment_Statement);

  type Boolean_Binary_Operator_Kind is
    (No_Boolean_Binary_Operator,
     And_Boolean_Binary_Operator,
     Or_Boolean_Binary_Operator,
     Xor_Boolean_Binary_Operator,
     Equal_Boolean_Binary_Operator,
     Not_Equal_Boolean_Binary_Operator,
     Less_Boolean_Binary_Operator,
     Less_Equal_Boolean_Binary_Operator,
     Greater_Boolean_Binary_Operator,
     Greater_Equal_Boolean_Binary_Operator);

  type Boolean_Short_Circuit_Operator_Kind is
    (And_Then_Boolean_Short_Circuit_Operator,
     Or_Else_Boolean_Short_Circuit_Operator);

  type Boolean_Expression_Value_Kind is
    (Boolean_Expression_Constant_Value,
     Boolean_Expression_Local_Value,
     Boolean_Expression_Not_Value,
     Boolean_Expression_Binary_Value);

  type Boolean_Expression_Value_List is private;
  type Procedure_Statement_List is private;

  type Subtype_Constraint is private;

  type Subtype_Constraint_Kind is
    (No_Constraint,
     Signed_Integer_Range_Constraint);

  NO_SUBTYPE_CONSTRAINT : constant Subtype_Constraint;

  --! summary: Build one checked semantic signed-integer range constraint value.
  function make_signed_integer_range_constraint
    (lower_bound : Long_Long_Integer;
     upper_bound : Long_Long_Integer)
  return Subtype_Constraint;

  --! summary: Return the representation kind of one subtype constraint.
  function subtype_constraint_category
    (constraint : Subtype_Constraint)
  return Subtype_Constraint_Kind;

  --! summary: Return the lower bound of a signed-integer range constraint.
  function subtype_constraint_lower_bound
    (constraint : Subtype_Constraint)
  return Long_Long_Integer;

  --! summary: Return the upper bound of a signed-integer range constraint.
  function subtype_constraint_upper_bound
    (constraint : Subtype_Constraint)
  return Long_Long_Integer;

  --! summary: Return whether one integer value satisfies a subtype constraint.
  function subtype_constraint_contains
    (constraint : Subtype_Constraint;
     value      : Long_Long_Integer)
  return Boolean;

  --! summary: Validate one semantic subtype-constraint value.
  procedure validate (constraint : Subtype_Constraint);

  type Lexical_Scope is private;

  type Scope_Binding_Kind is
    (Local_Object_Binding,
     Local_Subtype_Binding,
     Local_Static_Integer_Constant_Binding,
     Local_Static_Boolean_Constant_Binding,
     Local_Integer_Number_Binding,
     Local_Real_Number_Binding);

  --! summary: Add one direct local-object binding if the symbol is unbound.
  procedure try_bind_local_object
    (self     : in out Lexical_Scope;
     symbols  : Adac.Symbols.Store;
     symbol   : Adac.Symbols.Symbol_ID;
     local    : Positive;
     inserted : out Boolean);

  --! summary: Add one direct local-subtype binding if the symbol is unbound.
  procedure try_bind_local_subtype
    (self        : in out Lexical_Scope;
     symbols     : Adac.Symbols.Store;
     symbol      : Adac.Symbols.Symbol_ID;
     declaration : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint  : Subtype_Constraint;
     inserted    : out Boolean);

  --! summary: Add one static local Integer constant if the symbol is unbound.
  procedure try_bind_local_static_integer_constant
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Subtype_Constraint;
     value         : Long_Long_Integer;
     inserted      : out Boolean);

  --! summary: Add one static local Boolean constant if the symbol is unbound.
  procedure try_bind_local_static_boolean_constant
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Boolean_Value;
     inserted      : out Boolean);

  --! summary: Add one integer named-number binding if the symbol is unbound.
  procedure try_bind_local_integer_number
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Integer_Value;
     inserted      : out Boolean);

  --! summary: Add one real named-number binding if the symbol is unbound.
  procedure try_bind_local_real_number
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Real_Value;
     inserted      : out Boolean);

  --! summary: Resolve one direct local-object symbol to its local ordinal.
  function resolve_local_object
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Natural;

  --! summary: Resolve one direct local-subtype symbol to its semantic type.
  function resolve_local_subtype
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the constraint of one resolved local subtype.
  function resolve_local_subtype_constraint
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Subtype_Constraint;

  --! summary: Resolve one local static constant to its semantic type.
  function resolve_local_static_integer_constant_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the checked value of one resolved local static constant.
  function resolve_local_static_integer_constant_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Long_Long_Integer;

  --! summary: Resolve one local static Boolean constant type.
  function resolve_local_static_boolean_constant_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return one resolved local static Boolean constant value.
  function resolve_local_static_boolean_constant_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Boolean_Value;

  --! summary: Resolve one local integer named number to its semantic type.
  function resolve_local_integer_number_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the checked value of one local integer named number.
  function resolve_local_integer_number_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Integer_Value;

  --! summary: Resolve one local real named number to its semantic type.
  function resolve_local_real_number_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the checked value of one local real named number.
  function resolve_local_real_number_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Real_Value;

  --! summary: Return the number of direct bindings in a lexical scope.
  function scope_binding_count (self : Lexical_Scope) return Natural;

  --! summary: Return the number of local-object bindings in a lexical scope.
  function scope_local_object_count (self : Lexical_Scope) return Natural;

  --! summary: Return one binding kind in source order.
  function scope_binding_kind_at
    (self  : Lexical_Scope;
     index : Positive)
  return Scope_Binding_Kind;

  --! summary: Return one binding symbol in source order.
  function scope_binding_symbol_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one object binding local ordinal.
  function scope_binding_local_at
    (self  : Lexical_Scope;
     index : Positive)
  return Positive;

  --! summary: Return one subtype binding declaration.
  function scope_binding_subtype_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one subtype binding semantic type.
  function scope_binding_subtype_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one subtype binding semantic constraint.
  function scope_binding_subtype_constraint_at
    (self  : Lexical_Scope;
     index : Positive)
  return Subtype_Constraint;

  --! summary: Return one static-constant binding declaration.
  function scope_binding_static_constant_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one static-constant binding semantic type.
  function scope_binding_static_constant_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one static-constant nominal subtype constraint.
  function scope_binding_static_constant_constraint_at
    (self  : Lexical_Scope;
     index : Positive)
  return Subtype_Constraint;

  --! summary: Return one static-constant checked integer value.
  function scope_binding_static_constant_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Long_Long_Integer;

  --! summary: Return one static Boolean constant value.
  function scope_binding_static_boolean_constant_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Boolean_Value;

  --! summary: Return one integer named-number declaration.
  function scope_binding_integer_number_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one integer named-number semantic type.
  function scope_binding_integer_number_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one integer named-number checked universal value.
  function scope_binding_integer_number_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Universal_Integer_Value;

  --! summary: Return one real named-number declaration in source order.
  function scope_binding_real_number_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one real named-number type in source order.
  function scope_binding_real_number_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one real named-number value in source order.
  function scope_binding_real_number_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Universal_Real_Value;

  --! summary: Validate the structural state of one lexical scope.
  procedure validate (self : Lexical_Scope);

  --! summary: Validate lexical-scope symbols against their owning store.
  procedure validate
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store);

  --! summary: Append one semantic entity identifier to a temporary list.
  procedure append
    (self   : in out Entity_ID_List;
     entity : Entity_ID);

  --! summary: Return the number of identifiers in a temporary entity list.
  function entity_list_count (self : Entity_ID_List) return Natural;

  --! summary: Return one identifier from a temporary semantic entity list.
  function entity_list_element
    (self  : Entity_ID_List;
     index : Positive)
  return Entity_ID;


  --! summary: Append one static Boolean leaf to a temporary expression tree.
  procedure append_boolean_expression_constant
    (self   : in out Boolean_Expression_Value_List;
     syntax : Adac.AST.Node_ID;
     value  : Adac.Types.Boolean_Value);

  --! summary: Append one defined mutable-local Boolean read leaf.
  procedure append_boolean_expression_local
    (self                        : in out Boolean_Expression_Value_List;
     syntax                      : Adac.AST.Node_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     value                       : Adac.Types.Boolean_Value);

  --! summary: Apply Boolean not to the current expression-tree root.
  procedure append_boolean_expression_not
    (self   : in out Boolean_Expression_Value_List;
     syntax : Adac.AST.Node_ID);

  --! summary: Combine the two current expression-tree roots with one operator.
  procedure append_boolean_expression_binary
    (self          : in out Boolean_Expression_Value_List;
     syntax        : Adac.AST.Node_ID;
     operator_kind : Boolean_Binary_Operator_Kind);

  --! summary: Return the current temporary Boolean expression root value.
  function boolean_expression_root_value
    (self : Boolean_Expression_Value_List)
  return Adac.Types.Boolean_Value;

  --! summary: Return whether the expression root depends on a runtime local.
  function boolean_expression_has_runtime_read
    (self : Boolean_Expression_Value_List)
  return Boolean;

  --! summary: Append one checked non-assignment procedure statement.
  procedure append_statement
    (self      : in out Procedure_Statement_List;
     statement : Adac.AST.Node_ID;
     kind      : Procedure_Statement_Kind);

  --! summary: Append one checked local Integer static assignment.
  procedure append_local_integer_static_assignment
    (self          : in out Procedure_Statement_List;
     statement     : Adac.AST.Node_ID;
     target_local  : Positive;
     expected_type : Adac.Types.Type_ID;
     integer_value : Long_Long_Integer);

  --! summary: Append one checked local Boolean static assignment.
  procedure append_local_boolean_static_assignment
    (self          : in out Procedure_Statement_List;
     statement     : Adac.AST.Node_ID;
     target_local  : Positive;
     expected_type : Adac.Types.Type_ID;
     boolean_value : Adac.Types.Boolean_Value);

  --! summary: Append one checked direct local Boolean copy assignment.
  procedure append_local_boolean_copy_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     boolean_value               : Adac.Types.Boolean_Value);

  --! summary: Append unary Boolean not of one checked local source.
  procedure append_local_boolean_not_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     boolean_value               : Adac.Types.Boolean_Value);

  --! summary: Append one checked binary Boolean local assignment.
  procedure append_local_boolean_binary_assignment
    (self                              : in out Procedure_Statement_List;
     statement                         : Adac.AST.Node_ID;
     target_local                      : Positive;
     expected_type                     : Adac.Types.Type_ID;
     operator_kind                     : Boolean_Binary_Operator_Kind;
     left_source_local                 : Positive;
     left_source_definition_statement  : Natural;
     right_source_local                : Positive;
     right_source_definition_statement : Natural;
     boolean_value                     : Adac.Types.Boolean_Value);

  --! summary: Append one checked direct-local Boolean short-circuit assignment.
  procedure append_local_boolean_short_circuit_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     operator_kind               : Boolean_Short_Circuit_Operator_Kind;
     left_source_local           : Positive;
     left_definition_statement   : Natural;
     right_source_local          : Positive;
     right_definition_statement  : Natural;
     boolean_value               : Adac.Types.Boolean_Value);

  --! summary: Append one checked eager Boolean expression-tree assignment.
  procedure append_local_boolean_expression_assignment
    (self          : in out Procedure_Statement_List;
     statement     : Adac.AST.Node_ID;
     target_local  : Positive;
     expected_type : Adac.Types.Type_ID;
     expression    : Boolean_Expression_Value_List);

  --! summary: Append one checked direct local Integer copy assignment.
  procedure append_local_integer_copy_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     integer_value               : Long_Long_Integer);

  --! summary: Return the number of checked statements in a temporary list.
  function statement_list_count
    (self : Procedure_Statement_List)
  return Natural;

  --! summary: Return one checked statement kind from a temporary list.
  function statement_list_kind_at
    (self  : Procedure_Statement_List;
     index : Positive)
  return Procedure_Statement_Kind;

  --! summary: Return one checked statement syntax node from a temporary list.
  function statement_list_syntax
    (self  : Procedure_Statement_List;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the expected type of a temporary checked assignment.
  function statement_list_expected_type
    (self  : Procedure_Statement_List;
     index : Positive)
  return Adac.Types.Type_ID;

  type Store is limited private;

  --! summary: Create an empty append-only semantic entity store.
  function create return Store;

  --! summary: Append one uninitialized variable-object semantic entity.
  function append_object
    (self          : in out Store;
     declaration   : Adac.AST.Node_ID;
     symbol        : Adac.Symbols.Symbol_ID;
     span          : Adac.Source.Span;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Subtype_Constraint)
  return Entity_ID;

  --! summary: Append one variable object with a checked integer initializer.
  function append_object
    (self                : in out Store;
     declaration         : Adac.AST.Node_ID;
     symbol              : Adac.Symbols.Symbol_ID;
     span                : Adac.Source.Span;
     semantic_type       : Adac.Types.Type_ID;
     integer_initializer : Long_Long_Integer;
     constraint          : Subtype_Constraint)
  return Entity_ID;

  --! summary: Append one variable object with a checked Boolean initializer.
  function append_object
    (self                : in out Store;
     declaration         : Adac.AST.Node_ID;
     symbol              : Adac.Symbols.Symbol_ID;
     span                : Adac.Source.Span;
     semantic_type       : Adac.Types.Type_ID;
     boolean_initializer : Adac.Types.Boolean_Value;
     constraint          : Subtype_Constraint)
  return Entity_ID;

  --! summary: Append one procedure with scope, locals, and checked statements.
  function append_procedure
    (self        : in out Store;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span;
     scope       : Lexical_Scope;
     locals      : Entity_ID_List;
     statements  : Procedure_Statement_List)
  return Entity_ID;

  --! summary: Return the number of entities owned by the store.
  function entity_count (self : Store) return Natural;

  --! summary: Return the concrete kind of an entity owned by the store.
  function kind_of
    (self   : Store;
     entity : Entity_ID)
  return Entity_Kind;

  --! summary: Return the syntax declaration associated with an entity.
  function declaration
    (self   : Store;
     entity : Entity_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the declared symbol associated with an entity.
  function symbol
    (self   : Store;
     entity : Entity_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the source span associated with an entity.
  function entity_span
    (self   : Store;
     entity : Entity_ID)
  return Adac.Source.Span;

  --! summary: Return the semantic type of an object entity.
  function object_type
    (self   : Store;
     entity : Entity_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the nominal subtype constraint of an object entity.
  function object_subtype_constraint
    (self   : Store;
     entity : Entity_ID)
  return Subtype_Constraint;

  --! summary: Return whether an object has a checked integer initializer.
  function object_has_integer_initializer
    (self   : Store;
     entity : Entity_ID)
  return Boolean;

  --! summary: Return the checked integer initializer value of an object.
  function object_integer_initializer
    (self   : Store;
     entity : Entity_ID)
  return Long_Long_Integer;

  --! summary: Return whether an object has a checked Boolean initializer.
  function object_has_boolean_initializer
    (self   : Store;
     entity : Entity_ID)
  return Boolean;

  --! summary: Return the checked Boolean initializer value of an object.
  function object_boolean_initializer
    (self   : Store;
     entity : Entity_ID)
  return Adac.Types.Boolean_Value;

  --! summary: Return the directly declared local-object count of a procedure.
  function procedure_local_count
    (self      : Store;
     procedure_entity : Entity_ID)
  return Natural;

  --! summary: Return one directly declared local object of a procedure.
  function procedure_local_at
    (self      : Store;
     procedure_entity : Entity_ID;
     index     : Positive)
  return Entity_ID;

  --! summary: Return the lexical binding count of a procedure.
  function procedure_scope_binding_count
    (self             : Store;
     procedure_entity : Entity_ID)
  return Natural;

  --! summary: Return one procedure lexical binding symbol in source order.
  function procedure_scope_binding_symbol_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one procedure lexical binding local ordinal.
  function procedure_scope_binding_local_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return one procedure lexical binding kind.
  function procedure_scope_binding_kind_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Scope_Binding_Kind;

  --! summary: Return one procedure subtype binding declaration.
  function procedure_scope_binding_subtype_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one procedure subtype binding semantic type.
  function procedure_scope_binding_subtype_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one procedure subtype binding constraint.
  function procedure_scope_binding_subtype_constraint_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Subtype_Constraint;

  --! summary: Return one stored static-constant declaration.
  function procedure_scope_binding_static_constant_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one stored static-constant semantic type.
  function procedure_scope_binding_static_constant_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one stored static-constant nominal constraint.
  function procedure_scope_binding_static_constant_constraint_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Subtype_Constraint;

  --! summary: Return one stored static-constant checked value.
  function procedure_scope_binding_static_constant_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Long_Long_Integer;

  --! summary: Return one stored static Boolean constant value.
  function procedure_scope_binding_static_boolean_constant_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value;

  --! summary: Return one stored integer named-number declaration.
  function procedure_scope_binding_integer_number_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one stored integer named-number semantic type.
  function procedure_scope_binding_integer_number_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one stored integer named-number checked value.
  function procedure_scope_binding_integer_number_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Integer_Value;

  --! summary: Return one stored real named-number declaration.
  function procedure_scope_binding_real_number_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one stored real named-number semantic type.
  function procedure_scope_binding_real_number_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return one stored real named-number checked value.
  function procedure_scope_binding_real_number_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Real_Value;

  --! summary: Return one procedure binding index for an existing symbol.
  function procedure_scope_binding_index_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural;

  --! summary: Resolve one procedure-local symbol through its lexical scope.
  function procedure_local_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural;

  --! summary: Resolve one procedure-local subtype symbol to its type.
  function procedure_subtype_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the constraint of one stored procedure-local subtype.
  function procedure_subtype_constraint_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Subtype_Constraint;

  --! summary: Return the checked statement count of a procedure entity.
  function procedure_statement_count
    (self             : Store;
     procedure_entity : Entity_ID)
  return Natural;

  --! summary: Return one checked procedure statement kind.
  function procedure_statement_kind_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Procedure_Statement_Kind;

  --! summary: Return the canonical syntax node of one checked statement.
  function procedure_statement_syntax
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the target local ordinal of a checked assignment.
  function assignment_target_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return the expected semantic type of a checked assignment.
  function assignment_expected_type
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID;

  --! summary: Return the known integer value of a checked assignment.
  function assignment_integer_value
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Long_Long_Integer;

  --! summary: Return the known Boolean value of a checked Boolean assignment.
  function assignment_boolean_value
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value;

  --! summary: Return the logical operator of a checked Boolean binary
  --!          assignment.
  function assignment_boolean_operator
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Boolean_Binary_Operator_Kind;

  --! summary: Return the source local ordinal of a checked source-reading
  --!          assignment.
  function assignment_source_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return the source-definition statement of a checked source read.
  function assignment_source_definition_statement
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Natural;

  --! summary: Return the right source local of a checked Boolean binary read.
  function assignment_right_source_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive;

  --! summary: Return the right source definition of a Boolean binary read.
  function assignment_right_source_definition_statement
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Natural;

  --! summary: Return the value count of a checked Boolean expression tree.
  function assignment_boolean_expression_value_count
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Natural;

  --! summary: Return one checked Boolean expression-tree value kind.
  function assignment_boolean_expression_value_kind
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Boolean_Expression_Value_Kind;

  --! summary: Return one checked Boolean expression-tree syntax node.
  function assignment_boolean_expression_syntax
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one checked Boolean expression-tree known value.
  function assignment_boolean_expression_known_value
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Types.Boolean_Value;

  --! summary: Return one expression-tree local source ordinal.
  function assignment_boolean_expression_source_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive;

  --! summary: Return one expression-tree local source definition statement.
  function assignment_boolean_expression_source_definition
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Natural;

  --! summary: Return one expression-tree Boolean binary operator.
  function assignment_boolean_expression_operator
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Boolean_Binary_Operator_Kind;

  --! summary: Return one expression-tree left/unary operand value index.
  function assignment_boolean_expression_operand
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive;

  --! summary: Return one expression-tree binary right operand value index.
  function assignment_boolean_expression_right_operand
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive;

  --! summary: Validate the structural state of an entity identifier.
  procedure validate (entity : Entity_ID);

  --! summary: Validate an entity and its structurally stored references.
  procedure validate
    (self   : Store;
     entity : Entity_ID);

private

  type Store_Marker is record
    identity : Boolean := False;
  end record;
  type Store_Marker_Access is access constant Store_Marker;

  type Entity_ID is record
    owner : Store_Marker_Access := null;
    index : Natural := 0;
  end record;

  INVALID_ENTITY_ID : constant Entity_ID :=
    (owner => null,
     index => 0);

  package Entity_ID_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Entity_ID);

  type Entity_ID_List is record
    items : Entity_ID_Vectors.Vector;
  end record;

  type Boolean_Expression_Value_Record is record
    kind                        : Boolean_Expression_Value_Kind :=
      Boolean_Expression_Constant_Value;
    syntax                      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    boolean_value               : Adac.Types.Boolean_Value :=
      Adac.Types.False_Boolean_Value;
    source_local                : Natural := 0;
    source_definition_statement : Natural := 0;
    boolean_operator            : Boolean_Binary_Operator_Kind :=
      No_Boolean_Binary_Operator;
    operand_value               : Natural := 0;
    right_operand_value         : Natural := 0;
    subtree_value_count         : Natural := 1;
  end record;

  package Boolean_Expression_Value_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Boolean_Expression_Value_Record);

  type Boolean_Expression_Value_List is record
    items : Boolean_Expression_Value_Vectors.Vector;
  end record;

  type Procedure_Statement_Record is record
    kind                        : Procedure_Statement_Kind :=
      Null_Procedure_Statement;
    syntax                      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    target_local                : Natural := 0;
    expected_type               : Adac.Types.Type_ID :=
      Adac.Types.INVALID_TYPE_ID;
    integer_value               : Long_Long_Integer := 0;
    boolean_value               : Adac.Types.Boolean_Value :=
      Adac.Types.False_Boolean_Value;
    boolean_operator            : Boolean_Binary_Operator_Kind :=
      No_Boolean_Binary_Operator;
    source_local                : Natural := 0;
    source_definition_statement : Natural := 0;
    right_source_local          : Natural := 0;
    right_source_definition_statement : Natural := 0;
    first_boolean_expression_value : Natural := 0;
    boolean_expression_value_count : Natural := 0;
  end record;

  package Procedure_Statement_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Procedure_Statement_Record);

  type Procedure_Statement_List is record
    items                     : Procedure_Statement_Vectors.Vector;
    boolean_expression_values : Boolean_Expression_Value_Vectors.Vector;
  end record;

  type Subtype_Constraint is record
    kind        : Subtype_Constraint_Kind := No_Constraint;
    lower_bound : Long_Long_Integer := 0;
    upper_bound : Long_Long_Integer := 0;
  end record;

  NO_SUBTYPE_CONSTRAINT : constant Subtype_Constraint :=
    (kind        => No_Constraint,
     lower_bound => 0,
     upper_bound => 0);

  type Scope_Binding_Record is record
    kind           : Scope_Binding_Kind := Local_Object_Binding;
    symbol         : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    symbol_ordinal : Natural := 0;
    local_ordinal  : Natural := 0;
    subtype_declaration  : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    static_constant_declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    number_declaration   : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    semantic_type        : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    constraint_value     : Subtype_Constraint := NO_SUBTYPE_CONSTRAINT;
    static_constant_value : Long_Long_Integer := 0;
    static_boolean_constant_value : Adac.Types.Boolean_Value :=
      Adac.Types.False_Boolean_Value;
    integer_number_value : Adac.Types.Universal_Integer_Value :=
      Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
    real_number_value    : Adac.Types.Universal_Real_Value :=
      Adac.Types.INVALID_UNIVERSAL_REAL_VALUE;
  end record;

  package Scope_Binding_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Scope_Binding_Record);

  package Scope_Lookup_Maps is new Ada.Containers.Ordered_Maps
    (Key_Type     => Positive,
     Element_Type => Positive);

  type Lexical_Scope is record
    bindings           : Scope_Binding_Vectors.Vector;
    lookup             : Scope_Lookup_Maps.Map;
    local_object_count : Natural := 0;
  end record;

  type Procedure_Scope_Lookup_Key is record
    procedure_entity_index : Positive;
    symbol_ordinal         : Positive;
  end record;

  function procedure_scope_key_less
    (left  : Procedure_Scope_Lookup_Key;
     right : Procedure_Scope_Lookup_Key)
  return Boolean;

  package Procedure_Scope_Lookup_Maps is new Ada.Containers.Ordered_Maps
    (Key_Type     => Procedure_Scope_Lookup_Key,
     Element_Type => Positive,
     "<"          => procedure_scope_key_less);

  type Entity_Record is record
    kind        : Entity_Kind := Procedure_Body_Entity;
    declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    symbol      : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    span        : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    semantic_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    has_integer_initializer : Boolean := False;
    integer_initializer     : Long_Long_Integer := 0;
    has_boolean_initializer : Boolean := False;
    boolean_initializer     : Adac.Types.Boolean_Value :=
      Adac.Types.False_Boolean_Value;
    constraint_value : Subtype_Constraint := NO_SUBTYPE_CONSTRAINT;
    first_scope_binding  : Natural := 0;
    scope_binding_count  : Natural := 0;
    first_local_relation : Natural := 0;
    local_count          : Natural := 0;
    first_statement      : Natural := 0;
    statement_count      : Natural := 0;
    first_boolean_expression_value : Natural := 0;
    boolean_expression_value_count : Natural := 0;
  end record;

  package Entity_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Entity_Record);

  package Entity_Index_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Positive);

  type Store is limited record
    initialized : Boolean := False;
    marker      : aliased Store_Marker;
    entities       : Entity_Vectors.Vector;
    scope_bindings : Scope_Binding_Vectors.Vector;
    scope_lookup   : Procedure_Scope_Lookup_Maps.Map;
    relations                 : Entity_Index_Vectors.Vector;
    statements                : Procedure_Statement_Vectors.Vector;
    boolean_expression_values : Boolean_Expression_Value_Vectors.Vector;
  end record;

end Adac.Semantics;
