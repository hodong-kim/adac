-- ============================================================================
-- adac-compilation-syntax.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Source;
with Adac.Symbols;

package Adac.Compilation.Syntax is

  --! summary: Append one lexically validated numeric literal.
  function create_numeric_literal
    (self     : in out Context;
     form     : Adac.AST.Numeric_Literal_Kind;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one lexically validated character literal.
  function create_character_literal
    (self     : in out Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one lexically validated string literal.
  function create_string_literal
    (self     : in out Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current `null` literal expression.
  function create_null_literal
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current named record aggregate.
  --! contract
  --!   Each association value must be an earlier nonaggregate simple
  --!   expression whose transitive expression subtree contains no record
  --!   aggregate or qualified expression.
  function create_record_aggregate
    (self         : in out Context;
     associations : Adac.AST.Record_Component_Association_List;
     span         : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current named array aggregate.
  function create_array_aggregate
    (self         : in out Context;
     associations : Adac.AST.Array_Component_Association_List;
     span         : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current positional bracket aggregate.
  function create_bracket_aggregate
    (self        : in out Context;
     expressions : Adac.AST.Node_List;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one bounded current qualified expression.
  function create_qualified_expression
    (self         : in out Context;
     subtype_mark : Adac.AST.Node_ID;
     operand      : Adac.AST.Node_ID;
     span         : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current `new qualified_expression` allocator.
  function create_allocator
    (self       : in out Context;
     new_span   : Adac.Source.Span;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current if conditional expression.
  function create_if_expression
    (self            : in out Context;
     condition       : Adac.AST.Node_ID;
     then_expression : Adac.AST.Node_ID;
     else_expression : Adac.AST.Node_ID;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one bounded case-expression alternative.
  function create_case_expression_alternative
    (self       : in out Context;
     choices    : Adac.AST.Node_List;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one bounded Ada 2022 raise expression.
  function create_raise_expression
    (self           : in out Context;
     exception_name : Adac.AST.Node_ID;
     message        : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one bounded case conditional expression.
  function create_case_expression
    (self                 : in out Context;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append the current parenthesized conditional-expression primary.
  function create_parenthesized_expression
    (self       : in out Context;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current unary expression.
  function create_unary_operator
    (self              : in out Context;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     operand           : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current binary-exponentiating factor.
  function create_binary_exponentiating
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current binary-multiplying expression.
  function create_binary_multiplying
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current binary-adding expression.
  function create_binary_adding
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current binary relation to this compilation's AST.
  function create_relation
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one explicit-range membership choice.
  function create_membership_range_choice
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current membership expression.
  function create_membership_expression
    (self          : in out Context;
     tested        : Adac.AST.Node_ID;
     operator_kind : Adac.AST.Membership_Operator_Kind;
     not_span      : Adac.Source.Span;
     in_span       : Adac.Source.Span;
     choices       : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current logical operator expression.
  function create_logical_expression
    (self          : in out Context;
     left_operand  : Adac.AST.Node_ID;
     operator_kind : Adac.AST.Logical_Operator_Kind;
     operator_span : Adac.Source.Span;
     right_operand : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current short-circuit control form.
  function create_short_circuit_expression
    (self                 : in out Context;
     left_operand         : Adac.AST.Node_ID;
     operator_kind        : Adac.AST.Short_Circuit_Operator_Kind;
     operator_first_span  : Adac.Source.Span;
     operator_second_span : Adac.Source.Span;
     right_operand        : Adac.AST.Node_ID;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one identifier-name node to this compilation's AST.
  function create_identifier_name
    (self   : in out Context;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one selected-name node to this compilation's AST.
  function create_selected_name
    (self          : in out Context;
     prefix        : Adac.AST.Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one explicit-dereference name node.
  function create_explicit_dereference_name
    (self     : in out Context;
     prefix   : Adac.AST.Node_ID;
     all_span : Adac.Source.Span;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one selected-component node after a non-simple name.
  function create_selected_component
    (self          : in out Context;
     prefix        : Adac.AST.Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one parenthesized-name staging node.
  function create_parenthesized_name
    (self   : in out Context;
     prefix : Adac.AST.Node_ID;
     items  : Adac.AST.Node_List;
     span   : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one parenthesized name with association metadata.
  function create_parenthesized_name
    (self   : in out Context;
     prefix : Adac.AST.Node_ID;
     items  : Adac.AST.Parenthesized_Name_Item_List;
     span   : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current explicit-range slice name.
  function create_slice_name
    (self        : in out Context;
     prefix      : Adac.AST.Node_ID;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current identifier-attribute name.
  function create_attribute_name
    (self            : in out Context;
     prefix          : Adac.AST.Node_ID;
     designator      : Adac.Symbols.Symbol_ID;
     designator_span : Adac.Source.Span;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one bounded aspect specification.
  function create_aspect_specification
    (self        : in out Context;
     mark_symbol : Adac.Symbols.Symbol_ID;
     mark_span   : Adac.Source.Span;
     definition  : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one parameter specification with defining identifiers.
  function create_parameter_specification
    (self                 : in out Context;
     defining_identifiers : Adac.AST.Defining_Identifier_List;
     mode                 : Adac.AST.Parameter_Mode_Kind;
     subtype_mark         : Adac.AST.Node_ID;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append an identifier-list parameter with a default expression.
  function create_parameter_specification
    (self                 : in out Context;
     defining_identifiers : Adac.AST.Defining_Identifier_List;
     mode                 : Adac.AST.Parameter_Mode_Kind;
     subtype_mark         : Adac.AST.Node_ID;
     default_expression   : Adac.AST.Node_ID;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current parameter specification.
  function create_parameter_specification
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     mode          : Adac.AST.Parameter_Mode_Kind;
     subtype_mark  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one parameter with a represented default expression.
  function create_parameter_specification
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Adac.AST.Parameter_Mode_Kind;
     subtype_mark       : Adac.AST.Node_ID;
     default_expression : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current object declaration.
  function create_object_declaration
    (self          : in out Context;
     form          : Adac.AST.Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one object declaration with an index constraint.
  function create_constrained_object_declaration
    (self             : in out Context;
     form             : Adac.AST.Object_Declaration_Form;
     symbol           : Adac.Symbols.Symbol_ID;
     defining_span    : Adac.Source.Span;
     subtype_mark     : Adac.AST.Node_ID;
     index_constraint : Adac.AST.Node_ID;
     initializer      : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current object-renaming declaration.
  function create_object_renaming_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     renamed_name  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current number declaration.
  function create_number_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current exception declaration.
  function create_exception_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current procedure declaration.
  function create_procedure_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current procedure-body stub.
  function create_procedure_body_stub
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current function declaration.
  function create_function_declaration
    (self           : in out Context;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Adac.AST.Node_List;
     result_subtype : Adac.AST.Node_ID;
     aspect         : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current expression-function declaration.
  function create_function_declaration
    (self           : in out Context;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Adac.AST.Node_List;
     result_subtype : Adac.AST.Node_ID;
     expression     : Adac.AST.Node_ID;
     aspect         : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current `[limited] private` type declaration.
  --! contract
  --!   `discriminants` may be empty and otherwise contains earlier current
  --!   discriminant specifications in source order before `is`.
  function create_private_type_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     discriminants : Adac.AST.Node_List;
     span          : Adac.Source.Span;
     limited_form  : Boolean := False)
  return Adac.AST.Node_ID;

  --! summary: Append one current unconstrained derived-type declaration.
  function create_derived_type_declaration
    (self                : in out Context;
     symbol              : Adac.Symbols.Symbol_ID;
     defining_span       : Adac.Source.Span;
     parent_subtype_mark : Adac.AST.Node_ID;
     span                : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one explicit range constraint.
  function create_range_constraint
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one single-range index constraint.
  function create_index_constraint
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current subtype declaration.
  function create_subtype_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     constraint    : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one identifier-only enumeration type declaration.
  function create_enumeration_type_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     literals      : Adac.AST.Enumeration_Literal_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current discriminant specification.
  function create_discriminant_specification
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     subtype_mark       : Adac.AST.Node_ID;
     default_expression : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current record-component declaration.
  function create_record_component_declaration
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     aliased_form       : Boolean;
     subtype_mark       : Adac.AST.Node_ID;
     default_expression : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current record variant.
  function create_record_variant
    (self                : in out Context;
     choices             : Adac.AST.Node_List;
     components          : Adac.AST.Node_List;
     null_component_list : Boolean;
     span                : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current record variant part.
  function create_record_variant_part
    (self              : in out Context;
     discriminant_name : Adac.AST.Node_ID;
     variants          : Adac.AST.Node_List;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current record-type declaration.
  function create_record_type_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     limited_form  : Boolean;
     discriminants : Adac.AST.Node_List;
     components    : Adac.AST.Node_List;
     variant_part  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current access-to-object type declaration.
  function create_access_object_type_declaration
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     modifier           : Adac.AST.General_Access_Modifier_Kind;
     designated_subtype : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current `others` exception choice.
  function create_others_exception_choice
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current exception handler.
  function create_exception_handler
    (self                    : in out Context;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID;
     choice_parameter_span   : Adac.Source.Span;
     choices                 : Adac.AST.Node_List;
     statements              : Adac.AST.Node_List;
     span                    : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current handled sequence.
  function create_handled_sequence
    (self       : in out Context;
     statements : Adac.AST.Node_List;
     handlers   : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current elsif part.
  function create_elsif_part
    (self       : in out Context;
     condition  : Adac.AST.Node_ID;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current if statement.
  function create_if_statement
    (self            : in out Context;
     condition       : Adac.AST.Node_ID;
     then_statements : Adac.AST.Node_List;
     elsif_parts     : Adac.AST.Node_List;
     else_statements : Adac.AST.Node_List;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current assignment statement.
  function create_assignment_statement
    (self       : in out Context;
     target     : Adac.AST.Node_ID;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current explicit-range case choice.
  function create_case_range_choice
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current case alternative.
  --! summary: Append one current `others` case choice.
  function create_others_case_choice
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_case_alternative
    (self       : in out Context;
     choices    : Adac.AST.Node_List;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current case statement.
  function create_case_statement
    (self                 : in out Context;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current unlabeled block statement.
  function create_block_statement
    (self             : in out Context;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current unlabeled loop without an iteration scheme.
  function create_simple_loop_statement
    (self       : in out Context;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current unlabeled `while` loop statement.
  function create_while_loop_statement
    (self       : in out Context;
     condition  : Adac.AST.Node_ID;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one ordinary unlabeled discrete-range `for` loop.
  function create_discrete_range_loop_statement
    (self             : in out Context;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     lower_bound      : Adac.AST.Node_ID;
     upper_bound      : Adac.AST.Node_ID;
     statements       : Adac.AST.Node_List;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one ordinary `for` loop using a `Range` attribute.
  function create_range_attribute_loop_statement
    (self             : in out Context;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     range_attribute  : Adac.AST.Node_ID;
     statements       : Adac.AST.Node_List;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current unlabeled iterator-loop statement.
  function create_loop_statement
    (self             : in out Context;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     iterable_name    : Adac.AST.Node_ID;
     statements       : Adac.AST.Node_List;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one positional-only procedure-call statement.
  function create_procedure_call_statement
    (self          : in out Context;
     callable_name : Adac.AST.Node_ID;
     actuals       : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one association-aware procedure-call statement.
  function create_procedure_call_statement
    (self          : in out Context;
     callable_name : Adac.AST.Node_ID;
     actuals       : Adac.AST.Procedure_Call_Actual_Association_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one selected extended-return statement.
  function create_extended_return_statement
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     sequence      : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current exit statement.
  function create_exit_statement
    (self             : in out Context;
     loop_name_symbol : Adac.Symbols.Symbol_ID;
     loop_name_span   : Adac.Source.Span;
     when_span        : Adac.Source.Span;
     condition        : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one return statement with optional represented expression.
  function create_return_statement
    (self       : in out Context;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one bare `raise;` re-raise statement.
  function create_bare_raise_statement
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current raise-with-message statement.
  function create_raise_statement
    (self           : in out Context;
     exception_name : Adac.AST.Node_ID;
     message        : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one statement to this compilation's AST store.
  function create_statement
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current plain with clause.
  function create_with_clause
    (self  : in out Context;
     names : Adac.AST.Node_List;
     span  : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current `use type` basic declarative item.
  function create_use_type_clause
    (self          : in out Context;
     subtype_marks : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current package `use` basic declarative item.
  function create_use_package_clause
    (self          : in out Context;
     package_names : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current package-renaming declaration.
  function create_package_renaming_declaration
    (self            : in out Context;
     defining_name   : Adac.AST.Program_Unit_Name;
     renamed_package : Adac.AST.Node_ID;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current generic package-instantiation node.
  function create_package_instantiation
    (self          : in out Context;
     defining_name : Adac.AST.Program_Unit_Name;
     generic_name  : Adac.AST.Node_ID;
     actuals       : Adac.AST.Generic_Actual_Association_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current package-declaration node.
  function create_package_declaration
    (self                 : in out Context;
     defining_name        : Adac.AST.Program_Unit_Name;
     visible_declarations : Adac.AST.Node_List;
     private_part_span    : Adac.Source.Span;
     private_declarations : Adac.AST.Node_List;
     end_name             : Adac.AST.Program_Unit_Name;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append a package declaration with an implicit empty private part.
  function create_package_declaration
    (self                 : in out Context;
     defining_name        : Adac.AST.Program_Unit_Name;
     visible_declarations : Adac.AST.Node_List;
     end_name             : Adac.AST.Program_Unit_Name;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one selected package-body stub node.
  function create_package_body_stub
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current package-body node.
  function create_package_body
    (self          : in out Context;
     defining_name : Adac.AST.Program_Unit_Name;
     declarations  : Adac.AST.Node_List;
     end_name      : Adac.AST.Program_Unit_Name;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current procedure-body node.
  function create_procedure_body
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Adac.AST.Node_List;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one Ada subunit around an earlier proper body.
  function create_subunit
    (self             : in out Context;
     parent_unit_name : Adac.AST.Program_Unit_Name;
     proper_body      : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one current function body with represented declarations.
  function create_function_body
    (self             : in out Context;
     function_symbol  : Adac.Symbols.Symbol_ID;
     parameters       : Adac.AST.Node_List;
     result_subtype   : Adac.AST.Node_ID;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one compilation-unit root to this compilation's AST store.
  function create_compilation_unit
    (self          : in out Context;
     context_items : Adac.AST.Node_List;
     unit_item     : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Return the number of AST nodes owned by this compilation.
  function node_count (self : Context) return Natural;

  --! summary: Return the concrete kind of a context-owned AST node.
  function kind_of
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.AST.Node_Kind;

  --! summary: Return the source span of a context-owned AST node.
  function node_span
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether a handler has a choice parameter.
  function exception_handler_has_choice_parameter
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the optional choice-parameter symbol.
  function exception_handler_choice_parameter_symbol
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the optional choice-parameter defining span.
  function exception_handler_choice_parameter_span
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the exception-choice count of a handler.
  function exception_handler_choice_count
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one exception choice of a handler.
  function exception_handler_choice_at
    (self    : Context;
     handler : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the statement count of an exception handler.
  function exception_handler_statement_count
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one statement of an exception handler.
  function exception_handler_statement_at
    (self    : Context;
     handler : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the ordinary statement count of a handled sequence.
  function handled_sequence_statement_count
    (self     : Context;
     sequence : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one ordinary statement of a handled sequence.
  function handled_sequence_statement_at
    (self     : Context;
     sequence : Adac.AST.Node_ID;
     index    : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the handler count of a handled sequence.
  function handled_sequence_handler_count
    (self     : Context;
     sequence : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one handler of a handled sequence.
  function handled_sequence_handler_at
    (self     : Context;
     sequence : Adac.AST.Node_ID;
     index    : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the condition expression of an if statement.
  function if_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function elsif_condition
    (self : Context;
     part : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function elsif_statement_count
    (self : Context;
     part : Adac.AST.Node_ID)
  return Natural;

  function elsif_statement_at
    (self  : Context;
     part  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the then-branch statement count of an if statement.
  function if_then_statement_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one then-branch statement of an if statement.
  function if_then_statement_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  function if_elsif_part_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural;

  function if_elsif_part_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the else-branch statement count of an if statement.
  function if_else_statement_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one else-branch statement of an if statement.
  function if_else_statement_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  function exit_has_loop_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean;

  function exit_loop_name_symbol
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function exit_loop_name_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function exit_has_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean;

  function exit_when_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function exit_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function return_has_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean;

  function return_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function extended_return_symbol
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function extended_return_defining_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function extended_return_subtype_mark
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function extended_return_handled_sequence
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function raise_form
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Raise_Statement_Form;

  function raise_exception_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function raise_message_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the target name of an assignment statement.
  function assignment_target
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the RHS expression of an assignment statement.
  function assignment_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the discrete-choice count of a case alternative.
  function case_alternative_choice_count
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one discrete choice of a case alternative.
  function case_alternative_choice_at
    (self        : Context;
     alternative : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the lower bound of an explicit case range choice.
  function case_range_choice_lower_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact `..` span of an explicit case range choice.
  function case_range_choice_range_span
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the upper bound of an explicit case range choice.
  function case_range_choice_upper_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the statement count of a case alternative.
  function case_alternative_statement_count
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one statement of a case alternative.
  function case_alternative_statement_at
    (self        : Context;
     alternative : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the selecting expression of a case statement.
  function case_selecting_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the alternative count of a case statement.
  function case_alternative_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one alternative of a case statement.
  function case_alternative_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the declaration count of a block statement.
  function block_declaration_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one declaration of a block statement.
  function block_declaration_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the handled sequence of a block statement.
  function block_handled_sequence
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the source form of a represented loop statement.
  function loop_form
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Loop_Statement_Form;

  --! summary: Return the represented condition of a `while` loop.
  function loop_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a represented `for` loop parameter.
  function loop_parameter_symbol
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a represented `for` loop parameter.
  function loop_parameter_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether a represented `for` loop uses `reverse`.
  function loop_is_reverse
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the iterable name of an iterator loop.
  function loop_iterable_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the lower bound of an ordinary discrete-range loop.
  function loop_range_attribute
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function loop_range_lower_bound
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the upper bound of an ordinary discrete-range loop.
  function loop_range_upper_bound
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the body-statement count of a represented loop.
  function loop_statement_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one body statement of a represented loop.
  function loop_statement_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the callable name of a procedure-call statement.
  function procedure_call_callable_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the actual-association count of a procedure call.
  function procedure_call_actual_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one procedure-call actual association form.
  function procedure_call_actual_form
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Procedure_Call_Actual_Association_Form;

  --! summary: Return the selector of one named procedure-call actual.
  function procedure_call_actual_selector_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return one procedure-call actual expression.
  function procedure_call_actual_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the lexical form of a numeric literal.
  function numeric_literal_form
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return Adac.AST.Numeric_Literal_Kind;

  --! summary: Return the exact source spelling of a numeric literal.
  function numeric_literal_spelling
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return String;

  --! summary: Return the exact source spelling of a string literal.
  function character_literal_spelling
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return String;

  function string_literal_spelling
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return String;

  function record_aggregate_association_count
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  return Natural;

  function record_aggregate_selector_symbol_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID;

  function record_aggregate_selector_span_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Source.Span;

  function record_aggregate_expression_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  function array_aggregate_association_count
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  return Natural;

  function array_aggregate_choice_count
    (self              : Context;
     aggregate         : Adac.AST.Node_ID;
     association_index : Positive)
  return Natural;

  function array_aggregate_choice_at
    (self              : Context;
     aggregate         : Adac.AST.Node_ID;
     association_index : Positive;
     choice_index      : Positive)
  return Adac.AST.Node_ID;

  function array_aggregate_expression_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  function bracket_aggregate_expression_count
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  return Natural;

  function bracket_aggregate_expression_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID;

  function qualified_expression_subtype_mark
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function qualified_expression_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact `new` keyword span of an allocator.
  function allocator_new_span
    (self      : Context;
     allocator : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the qualified expression allocated by an allocator.
  function allocator_expression
    (self      : Context;
     allocator : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function if_expression_condition
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function if_expression_then_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function if_expression_else_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function case_expression_selecting_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function case_expression_alternative_count
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Natural;

  function case_expression_alternative_at
    (self       : Context;
     expression : Adac.AST.Node_ID;
     index      : Positive)
  return Adac.AST.Node_ID;

  function case_expression_alternative_choice_count
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Natural;

  function case_expression_alternative_choice_at
    (self        : Context;
     alternative : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  function case_expression_alternative_expression
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function raise_expression_exception_name
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function raise_expression_has_message
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Boolean;

  function raise_expression_message
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function parenthesized_expression_child
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact unary operator spelling.
  function unary_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String;

  function unary_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function unary_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact exponentiating operator spelling.
  function binary_exponentiating_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String;

  function binary_exponentiating_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function binary_exponentiating_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function binary_exponentiating_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact binary-multiplying operator spelling.
  function binary_multiplying_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String;

  function binary_multiplying_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function binary_multiplying_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function binary_multiplying_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact binary-adding operator spelling.
  function binary_adding_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String;

  --! summary: Return the binary-adding operator token span.
  function binary_adding_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the left operand of a binary-adding expression.
  function binary_adding_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the right operand of a binary-adding expression.
  function binary_adding_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact relational-operator spelling.
  function relation_operator_spelling
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return String;

  --! summary: Return the relational-operator token span.
  function relation_operator_span
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the left operand of a relation node.
  function relation_left_operand
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the right operand of a relation node.
  function relation_right_operand
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function membership_range_choice_lower_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function membership_range_choice_range_span
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function membership_range_choice_upper_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function membership_tested_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function membership_operator
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Membership_Operator_Kind;

  function membership_not_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function membership_in_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function membership_choice_count
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Natural;

  function membership_choice_at
    (self       : Context;
     expression : Adac.AST.Node_ID;
     index      : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the operator kind of a short-circuit expression.
  function logical_operator
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Logical_Operator_Kind;

  function logical_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function logical_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function logical_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function short_circuit_operator
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Short_Circuit_Operator_Kind;

  --! summary: Return the first short-circuit operator-token span.
  function short_circuit_operator_first_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the second short-circuit operator-token span.
  function short_circuit_operator_second_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the left operand of a short-circuit expression.
  function short_circuit_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the right operand of a short-circuit expression.
  function short_circuit_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the symbol of an identifier-name node.
  function identifier_symbol
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the prefix of a composite current name.
  function name_prefix
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the exact `all` token span of an explicit dereference.
  function explicit_dereference_all_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the selector symbol of a selected-name node.
  function selector_symbol
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the selector source span of a selected-name node.
  function selector_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the item count of a parenthesized-name node.
  function parenthesized_item_count
    (self : Context;
     name : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one item of a parenthesized-name node.
  function parenthesized_item_at
    (self  : Context;
     name  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  function parenthesized_item_form
    (self  : Context;
     name  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Parenthesized_Name_Item_Form;

  function parenthesized_item_selector
    (self  : Context;
     name  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the lower bound of a slice name.
  function slice_lower_bound
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the explicit range delimiter span of a slice name.
  function slice_range_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the upper bound of a slice name.
  function slice_upper_bound
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return an identifier attribute designator symbol.
  function attribute_symbol
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return an identifier attribute designator source span.
  function attribute_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the defining symbol of a parameter specification.
  function aspect_mark_symbol
    (self   : Context;
     aspect : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function aspect_mark_span
    (self   : Context;
     aspect : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function aspect_definition
    (self   : Context;
     aspect : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function parameter_defining_identifier_count
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Natural;

  function parameter_defining_symbol_at
    (self      : Context;
     parameter : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID;

  function parameter_defining_span_at
    (self      : Context;
     parameter : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Source.Span;

  function parameter_symbol
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of a parameter specification.
  function parameter_defining_span
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the source-form mode of a parameter specification.
  function parameter_mode
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.AST.Parameter_Mode_Kind;

  --! summary: Return the subtype-mark name of a parameter specification.
  function parameter_subtype_mark
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the optional represented parameter default expression.
  function parameter_default_expression
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the source form of an object declaration.
  function object_form
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Object_Declaration_Form;

  --! summary: Return the defining symbol of an object declaration.
  function object_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of an object declaration.
  function object_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the subtype-mark name of an object declaration.
  function object_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function object_has_index_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  function object_index_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return whether an object declaration has an initializer.
  function object_has_initializer
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the initializer name of an object declaration.
  function object_initializer
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of an object renaming.
  function object_renaming_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of an object renaming.
  function object_renaming_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the subtype mark of an object renaming.
  function object_renaming_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the renamed-object name of an object renaming.
  function object_renaming_name
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a number declaration.
  function number_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of a number declaration.
  function number_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the initializer expression of a number declaration.
  function number_initializer
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of an exception declaration.
  function exception_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of an exception declaration.
  function exception_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the defining symbol of a procedure declaration.
  function procedure_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a procedure declaration.
  function procedure_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the formal-parameter count of a procedure declaration.
  function procedure_declaration_parameter_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one formal parameter of a procedure declaration.
  function procedure_declaration_parameter_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a procedure-body stub.
  function procedure_body_stub_symbol
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a procedure-body stub.
  function procedure_body_stub_defining_span
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the formal-parameter count of a procedure-body stub.
  function procedure_body_stub_parameter_count
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one formal parameter of a procedure-body stub.
  function procedure_body_stub_parameter_at
    (self  : Context;
     stub  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a function declaration.
  function function_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a function declaration.
  function function_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the formal-parameter count of a function declaration.
  function function_declaration_parameter_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one formal parameter of a function declaration.
  function function_declaration_parameter_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the result subtype mark of a function declaration.
  function function_declaration_result_subtype
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return whether a function declaration is an expression function.
  function function_declaration_has_expression
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the represented expression-function expression.
  function function_declaration_expression
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a private-type declaration.
  function function_declaration_has_aspect
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  function function_declaration_aspect
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function private_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a private-type declaration.
  function private_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether a private type includes `limited`.
  function private_type_is_limited
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  function private_type_discriminant_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  function private_type_discriminant_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a derived type.
  function derived_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function derived_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function derived_type_parent_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function range_constraint_lower_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function range_constraint_upper_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function index_constraint_lower_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function index_constraint_range_span
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function index_constraint_upper_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function subtype_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function subtype_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function subtype_declaration_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function subtype_declaration_has_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  function subtype_declaration_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of an enumeration type.
  function enumeration_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of an enumeration type.
  function enumeration_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the number of enumeration literal defining names.
  function enumeration_literal_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one enumeration literal defining symbol.
  function enumeration_literal_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one enumeration literal defining span.
  function enumeration_literal_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  --! summary: Return the defining symbol of a discriminant specification.
  function discriminant_symbol
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function discriminant_defining_span
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.Source.Span;

  function discriminant_subtype_mark
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function discriminant_has_default_expression
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Boolean;

  function discriminant_default_expression
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a record component.
  function record_component_symbol
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a record component.
  function record_component_defining_span
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether the component uses the `aliased` source form.
  function record_component_is_aliased
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the subtype mark of a record component.
  function record_component_subtype_mark
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return whether a record component has a default expression.
  function record_component_has_default_expression
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the default expression of a record component.
  function record_component_default_expression
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function record_variant_choice_count
    (self    : Context;
     variant : Adac.AST.Node_ID)
  return Natural;

  function record_variant_choice_at
    (self    : Context;
     variant : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID;

  function record_variant_has_null_component_list
    (self    : Context;
     variant : Adac.AST.Node_ID)
  return Boolean;

  function record_variant_component_count
    (self    : Context;
     variant : Adac.AST.Node_ID)
  return Natural;

  function record_variant_component_at
    (self    : Context;
     variant : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID;

  function record_variant_part_discriminant_name
    (self         : Context;
     variant_part : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function record_variant_part_variant_count
    (self         : Context;
     variant_part : Adac.AST.Node_ID)
  return Natural;

  function record_variant_part_variant_at
    (self         : Context;
     variant_part : Adac.AST.Node_ID;
     index        : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of a record type.
  function record_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a record type.
  function record_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether the record type uses the `limited` source form.
  function record_type_is_limited
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  function record_has_variant_part
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  function record_variant_part
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the number of record discriminants.
  function record_discriminant_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  function record_discriminant_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the number of record components.
  function record_component_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one record component.
  function record_component_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the defining symbol of an access-to-object type.
  function access_object_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of an access-to-object type.
  function access_object_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the general access modifier source form.
  function access_object_type_modifier
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.General_Access_Modifier_Kind;

  --! summary: Return the designated subtype mark.
  function access_object_type_designated_subtype
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining-name component count of a package renaming.
  function package_renaming_defining_name_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  function package_renaming_defining_name_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  function package_renaming_defining_name_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  function package_renaming_renamed_package
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the defining-name component count of a package instance.
  function package_instantiation_defining_name_count
    (self          : Context;
     instantiation : Adac.AST.Node_ID)
  return Natural;

  function package_instantiation_defining_name_symbol_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID;

  function package_instantiation_defining_name_span_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Source.Span;

  function package_instantiation_generic_name
    (self          : Context;
     instantiation : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function package_instantiation_actual_count
    (self          : Context;
     instantiation : Adac.AST.Node_ID)
  return Natural;

  function package_instantiation_actual_form_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Generic_Actual_Association_Form;

  function package_instantiation_actual_selector_symbol_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID;

  function package_instantiation_actual_selector_span_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Source.Span;

  function package_instantiation_actual_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the number of package defining-name components.
  function package_defining_name_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one package defining-name component symbol.
  function package_defining_name_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one package defining-name component span.
  function package_defining_name_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  --! summary: Return the visible-declaration count of a package node.
  function package_visible_declaration_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one visible declaration from a package node.
  function package_visible_declaration_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return whether a package has an explicit `private` boundary.
  function package_has_explicit_private_part
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the explicit `private` keyword span.
  function package_private_part_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the private-declaration count of a package node.
  function package_private_declaration_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one private declaration from a package node.
  function package_private_declaration_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return whether a package node has a closing designator.
  function package_has_end_designator
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the number of package closing-name components.
  function package_end_name_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one package closing-name component symbol.
  function package_end_name_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one package closing-name component span.
  function package_end_name_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  function package_body_stub_symbol
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function package_body_stub_defining_span
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the number of package-body defining-name components.
  function package_body_defining_name_count
    (self : Context;
     package_body : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one package-body defining-name component symbol.
  function package_body_defining_name_symbol_at
    (self  : Context;
     package_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one package-body defining-name component span.
  function package_body_defining_name_span_at
    (self  : Context;
     package_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.Source.Span;

  --! summary: Return the number of package-body declarative items.
  function package_body_declaration_count
    (self : Context;
     package_body : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one represented package-body declarative item.
  function package_body_declaration_at
    (self  : Context;
     package_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return whether a package body has a closing designator.
  function package_body_has_end_designator
    (self : Context;
     package_body : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the number of package-body closing-name components.
  function package_body_end_name_count
    (self : Context;
     package_body : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one package-body closing-name component symbol.
  function package_body_end_name_symbol_at
    (self  : Context;
     package_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one package-body closing-name component span.
  function package_body_end_name_span_at
    (self  : Context;
     package_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.Source.Span;

  --! summary: Return the number of names in a with-clause node.
  function with_clause_name_count
    (self   : Context;
     clause : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one name from a with-clause node.
  function with_clause_name_at
    (self   : Context;
     clause : Adac.AST.Node_ID;
     index  : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the subtype-mark count of a use-type clause.
  function use_type_subtype_mark_count
    (self   : Context;
     clause : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one subtype mark from a use-type clause.
  function use_type_subtype_mark_at
    (self   : Context;
     clause : Adac.AST.Node_ID;
     index  : Positive)
  return Adac.AST.Node_ID;

  function use_package_name_count
    (self   : Context;
     clause : Adac.AST.Node_ID)
  return Natural;

  function use_package_name_at
    (self   : Context;
     clause : Adac.AST.Node_ID;
     index  : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the context-item count of a compilation-unit node.
  function context_item_count
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one context item from a compilation-unit node.
  function context_item_at
    (self  : Context;
     unit  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the current library item or subunit of a compilation unit.
  function unit_item
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function library_item
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function subunit_parent_name_count
    (self    : Context;
     subunit : Adac.AST.Node_ID)
  return Natural;

  function subunit_parent_name_symbol_at
    (self    : Context;
     subunit : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.Symbols.Symbol_ID;

  function subunit_parent_name_span_at
    (self    : Context;
     subunit : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.Source.Span;

  function subunit_proper_body
    (self    : Context;
     subunit : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the opening symbol of a procedure-body node.
  function procedure_symbol
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return whether a procedure body has a closing designator.
  function has_end_designator
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Boolean;

  --! summary: Return the optional closing-designator symbol.
  function end_symbol
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the parameter count of a procedure-body node.
  function parameter_count
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one parameter from a procedure-body node.
  function parameter_at
    (self : Context;
     procedure_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the declaration count of a procedure body.
  function declaration_count
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one declaration from a procedure body.
  function declaration_at
    (self : Context;
     procedure_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Return the handled sequence of a procedure body.
  function procedure_handled_sequence
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the ordinary statement count of a procedure-body node.
  function statement_count
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one statement from a procedure-body node.
  function statement_at
    (self  : Context;
     procedure_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  function function_body_symbol
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  function function_body_parameter_count
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Natural;

  function function_body_parameter_at
    (self          : Context;
     function_body : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Node_ID;

  function function_body_declaration_count
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Natural;

  function function_body_declaration_at
    (self          : Context;
     function_body : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Node_ID;

  function function_body_result_subtype
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function function_body_handled_sequence
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.AST.Node_ID;

  function function_body_has_end_designator
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Boolean;

  function function_body_end_symbol
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Validate one numeric literal and source ownership.
  procedure validate_numeric_literal
    (self    : Context;
     literal : Adac.AST.Node_ID);

  --! summary: Validate one exception handler and context ownership links.
  procedure validate_exception_handler
    (self    : Context;
     handler : Adac.AST.Node_ID);

  --! summary: Validate one handled sequence and context ownership links.
  procedure validate_handled_sequence
    (self     : Context;
     sequence : Adac.AST.Node_ID);

  --! summary: Validate one elsif part and context ownership links.
  procedure validate_elsif_part
    (self : Context;
     part : Adac.AST.Node_ID);

  --! summary: Validate one if statement and context ownership links.
  procedure validate_if_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one extended return and context ownership links.
  procedure validate_extended_return_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one return statement and context ownership links.
  procedure validate_exit_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  procedure validate_return_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one raise statement and context ownership links.
  procedure validate_raise_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one assignment statement and context ownership links.
  procedure validate_assignment_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one explicit-range case choice and context ownership.
  procedure validate_case_range_choice
    (self   : Context;
     choice : Adac.AST.Node_ID);

  --! summary: Validate one case alternative and context ownership links.
  procedure validate_case_alternative
    (self        : Context;
     alternative : Adac.AST.Node_ID);

  --! summary: Validate one case statement and context ownership links.
  procedure validate_case_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one block statement and context ownership links.
  procedure validate_block_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one represented loop and context ownership links.
  procedure validate_loop_statement
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one procedure call and context ownership links.
  procedure validate_procedure_call
    (self      : Context;
     statement : Adac.AST.Node_ID);

  --! summary: Validate one string literal and source ownership.
  procedure validate_character_literal
    (self    : Context;
     literal : Adac.AST.Node_ID);

  procedure validate_string_literal
    (self    : Context;
     literal : Adac.AST.Node_ID);

  --! summary: Validate one null literal and source ownership.
  procedure validate_null_literal
    (self    : Context;
     literal : Adac.AST.Node_ID);

  --! summary: Validate one named record aggregate and ownership links.
  procedure validate_record_aggregate
    (self      : Context;
     aggregate : Adac.AST.Node_ID);

  --! summary: Validate one named array aggregate and ownership links.
  procedure validate_array_aggregate
    (self      : Context;
     aggregate : Adac.AST.Node_ID);

  --! summary: Validate one bounded qualified record-aggregate expression.
  procedure validate_bracket_aggregate
    (self      : Context;
     aggregate : Adac.AST.Node_ID);

  procedure validate_qualified_expression
    (self       : Context;
     expression : Adac.AST.Node_ID);

  procedure validate_allocator
    (self      : Context;
     allocator : Adac.AST.Node_ID);

  --! summary: Validate one explicit-range membership choice.
  procedure validate_membership_range_choice
    (self   : Context;
     choice : Adac.AST.Node_ID);

  --! summary: Validate one short-circuit expression and ownership links.
  procedure validate_short_circuit_expression
    (self       : Context;
     expression : Adac.AST.Node_ID);

  --! summary: Validate one represented expression and context ownership links.
  procedure validate_expression
    (self       : Context;
     expression : Adac.AST.Node_ID);

  --! summary: Validate one current name subtree and context ownership links.
  procedure validate_name
    (self : Context;
     name : Adac.AST.Node_ID);

  --! summary: Validate one exception declaration and ownership links.
  procedure validate_exception_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one bounded aspect specification and ownership links.
  procedure validate_aspect_specification
    (self   : Context;
     aspect : Adac.AST.Node_ID);

  --! summary: Validate one current parameter and ownership links.
  procedure validate_parameter
    (self      : Context;
     parameter : Adac.AST.Node_ID);

  --! summary: Validate one discriminant specification and ownership links.
  procedure validate_discriminant_specification
    (self         : Context;
     discriminant : Adac.AST.Node_ID);

  --! summary: Validate one record component and ownership links.
  procedure validate_record_component_declaration
    (self      : Context;
     component : Adac.AST.Node_ID);

  --! summary: Validate one derived-type declaration and ownership links.
  procedure validate_derived_type_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one explicit range constraint and ownership links.
  procedure validate_range_constraint
    (self       : Context;
     constraint : Adac.AST.Node_ID);

  procedure validate_index_constraint
    (self       : Context;
     constraint : Adac.AST.Node_ID);

  --! summary: Validate one subtype declaration and ownership links.
  procedure validate_subtype_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one record variant and ownership links.
  procedure validate_record_variant
    (self    : Context;
     variant : Adac.AST.Node_ID);

  --! summary: Validate one record variant part and ownership links.
  procedure validate_record_variant_part
    (self         : Context;
     variant_part : Adac.AST.Node_ID);

  --! summary: Validate one record-type declaration and ownership links.
  procedure validate_record_type_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one access-to-object type and ownership links.
  procedure validate_access_object_type_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one use-type clause and ownership links.
  procedure validate_use_type_clause
    (self   : Context;
     clause : Adac.AST.Node_ID);

  --! summary: Validate one package-use clause and ownership links.
  procedure validate_use_package_clause
    (self   : Context;
     clause : Adac.AST.Node_ID);

  --! summary: Validate one package renaming and ownership links.
  procedure validate_package_renaming_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one generic package instantiation and ownership links.
  procedure validate_package_instantiation
    (self          : Context;
     instantiation : Adac.AST.Node_ID);

  --! summary: Validate one current declaration and ownership links.
  procedure validate_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one package declaration and context ownership links.
  procedure validate_package_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID);

  --! summary: Validate one package-body stub and context ownership links.
  procedure validate_package_body_stub
    (self : Context;
     stub : Adac.AST.Node_ID);

  --! summary: Validate one package-body subtree in this compilation.
  procedure validate_package_body
    (self : Context;
     package_body : Adac.AST.Node_ID);

  --! summary: Validate one procedure body and context ownership links.
  procedure validate_procedure_body
    (self : Context;
     procedure_body : Adac.AST.Node_ID);

  --! summary: Validate one subunit and context ownership links.
  procedure validate_subunit
    (self    : Context;
     subunit : Adac.AST.Node_ID);

  --! summary: Validate one function body and context ownership links.
  procedure validate_function_body
    (self          : Context;
     function_body : Adac.AST.Node_ID);

  --! summary: Validate an AST and all compilation-context ownership links.
  procedure validate
    (self : Context;
     root : Adac.AST.Node_ID);

end Adac.Compilation.Syntax;
