-- ============================================================================
-- adac-ast-construction.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.AST.Construction is

  package Implementation renames Adac.AST.Construction_Implementation;

  function append_numeric_literal
    (self          : in out Store;
     form          : Numeric_Literal_Kind;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_numeric_literal
      (self,
       form,
       spelling,
       span,
       maximum_nodes);
  end append_numeric_literal;

  function append_character_literal
    (self          : in out Store;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_character_literal
      (self, spelling, span, maximum_nodes);
  end append_character_literal;

  function append_string_literal
    (self          : in out Store;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_string_literal
      (self,
       spelling,
       span,
       maximum_nodes);
  end append_string_literal;

  function append_null_literal
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_null_literal (self, span, maximum_nodes);
  end append_null_literal;

  function append_record_aggregate
    (self          : in out Store;
     associations  : Record_Component_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_record_aggregate
      (self, associations, span, maximum_nodes);
  end append_record_aggregate;

  function append_array_aggregate
    (self          : in out Store;
     associations  : Array_Component_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_array_aggregate
      (self, associations, span, maximum_nodes);
  end append_array_aggregate;

  function append_bracket_aggregate
    (self          : in out Store;
     expressions   : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_bracket_aggregate
      (self, expressions, span, maximum_nodes);
  end append_bracket_aggregate;

  function append_qualified_expression
    (self          : in out Store;
     subtype_mark  : Node_ID;
     operand       : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_qualified_expression
      (self, subtype_mark, operand, span, maximum_nodes);
  end append_qualified_expression;

  function append_allocator
    (self          : in out Store;
     new_span      : Adac.Source.Span;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_allocator
      (self, new_span, expression, span, maximum_nodes);
  end append_allocator;

  function append_if_expression
    (self            : in out Store;
     condition       : Node_ID;
     then_expression : Node_ID;
     else_expression : Node_ID;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_if_expression
      (self,
       condition,
       then_expression,
       else_expression,
       span,
       maximum_nodes);
  end append_if_expression;

  function append_case_expression_alternative
    (self          : in out Store;
     choices       : Node_List;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_case_expression_alternative
      (self, choices, expression, span, maximum_nodes);
  end append_case_expression_alternative;

  function append_raise_expression
    (self           : in out Store;
     exception_name : Node_ID;
     message        : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_raise_expression
      (self, exception_name, message, span, maximum_nodes);
  end append_raise_expression;

  function append_case_expression
    (self                 : in out Store;
     selecting_expression : Node_ID;
     alternatives         : Node_List;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_case_expression
      (self,
       selecting_expression,
       alternatives,
       span,
       maximum_nodes);
  end append_case_expression;

  function append_parenthesized_expression
    (self          : in out Store;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_parenthesized_expression
      (self,
       expression,
       span,
       maximum_nodes);
  end append_parenthesized_expression;

  function append_unary_operator
    (self              : in out Store;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     operand           : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_unary_operator
      (self,
       operator_spelling,
       operator_span,
       operand,
       span,
       maximum_nodes);
  end append_unary_operator;

  function append_binary_exponentiating
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_binary_exponentiating
      (self,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       maximum_nodes);
  end append_binary_exponentiating;

  function append_binary_multiplying
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_binary_multiplying
      (self,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       maximum_nodes);
  end append_binary_multiplying;

  function append_binary_adding
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_binary_adding
      (self,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       maximum_nodes);
  end append_binary_adding;

  function append_relation
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_relation
      (self,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       maximum_nodes);
  end append_relation;

  function append_membership_range_choice
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_membership_range_choice
      (self,
       lower_bound,
       range_span,
       upper_bound,
       span,
       maximum_nodes);
  end append_membership_range_choice;

  function append_membership_expression
    (self          : in out Store;
     tested        : Node_ID;
     operator_kind : Membership_Operator_Kind;
     not_span      : Adac.Source.Span;
     in_span       : Adac.Source.Span;
     choices       : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_membership_expression
      (self,
       tested,
       operator_kind,
       not_span,
       in_span,
       choices,
       span,
       maximum_nodes);
  end append_membership_expression;

  function append_logical_expression
    (self          : in out Store;
     left_operand  : Node_ID;
     operator_kind : Logical_Operator_Kind;
     operator_span : Adac.Source.Span;
     right_operand : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_logical_expression
      (self, left_operand, operator_kind, operator_span, right_operand, span,
       maximum_nodes);
  end append_logical_expression;

  function append_short_circuit_expression
    (self                 : in out Store;
     left_operand         : Node_ID;
     operator_kind        : Short_Circuit_Operator_Kind;
     operator_first_span  : Adac.Source.Span;
     operator_second_span : Adac.Source.Span;
     right_operand        : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_short_circuit_expression
      (self,
       left_operand,
       operator_kind,
       operator_first_span,
       operator_second_span,
       right_operand,
       span,
       maximum_nodes);
  end append_short_circuit_expression;

  function append_identifier_name
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_identifier_name
      (self,
       symbol,
       span,
       maximum_nodes);
  end append_identifier_name;

  function append_selected_name
    (self          : in out Store;
     prefix        : Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_selected_name
      (self,
       prefix,
       selector,
       selector_span,
       span,
       maximum_nodes);
  end append_selected_name;

  function append_explicit_dereference_name
    (self          : in out Store;
     prefix        : Node_ID;
     all_span      : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_explicit_dereference_name
      (self, prefix, all_span, span, maximum_nodes);
  end append_explicit_dereference_name;

  function append_selected_component
    (self          : in out Store;
     prefix        : Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_selected_component
      (self,
       prefix,
       selector,
       selector_span,
       span,
       maximum_nodes);
  end append_selected_component;

  function append_parenthesized_name
    (self          : in out Store;
     prefix        : Node_ID;
     items         : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_parenthesized_name
      (self,
       prefix,
       items,
       span,
       maximum_nodes);
  end append_parenthesized_name;

  function append_parenthesized_name
    (self          : in out Store;
     prefix        : Node_ID;
     items         : Parenthesized_Name_Item_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_parenthesized_name
      (self,
       prefix,
       items,
       span,
       maximum_nodes);
  end append_parenthesized_name;

  function append_slice_name
    (self          : in out Store;
     prefix        : Node_ID;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_slice_name
      (self,
       prefix,
       lower_bound,
       range_span,
       upper_bound,
       span,
       maximum_nodes);
  end append_slice_name;

  function append_attribute_name
    (self            : in out Store;
     prefix          : Node_ID;
     designator      : Adac.Symbols.Symbol_ID;
     designator_span : Adac.Source.Span;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_attribute_name
      (self,
       prefix,
       designator,
       designator_span,
       span,
       maximum_nodes);
  end append_attribute_name;

  function append_aspect_specification
    (self          : in out Store;
     mark_symbol   : Adac.Symbols.Symbol_ID;
     mark_span     : Adac.Source.Span;
     definition    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_aspect_specification
      (self,
       mark_symbol,
       mark_span,
       definition,
       span,
       maximum_nodes);
  end append_aspect_specification;

  function append_parameter_specification
    (self                 : in out Store;
     defining_identifiers : Defining_Identifier_List;
     mode                 : Parameter_Mode_Kind;
     subtype_mark         : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_parameter_specification
      (self,
       defining_identifiers,
       mode,
       subtype_mark,
       span,
       maximum_nodes);
  end append_parameter_specification;

  function append_parameter_specification
    (self                 : in out Store;
     defining_identifiers : Defining_Identifier_List;
     mode                 : Parameter_Mode_Kind;
     subtype_mark         : Node_ID;
     default_expression   : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_parameter_specification
      (self,
       defining_identifiers,
       mode,
       subtype_mark,
       default_expression,
       span,
       maximum_nodes);
  end append_parameter_specification;

  function append_parameter_specification
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     mode          : Parameter_Mode_Kind;
     subtype_mark  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_parameter_specification
      (self,
       symbol,
       defining_span,
       mode,
       subtype_mark,
       span,
       maximum_nodes);
  end append_parameter_specification;

  function append_parameter_specification
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Parameter_Mode_Kind;
     subtype_mark       : Node_ID;
     default_expression : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_parameter_specification
      (self,
       symbol,
       defining_span,
       mode,
       subtype_mark,
       default_expression,
       span,
       maximum_nodes);
  end append_parameter_specification;

  function append_object_declaration
    (self          : in out Store;
     form          : Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     initializer   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_object_declaration
      (self,
       form,
       symbol,
       defining_span,
       subtype_mark,
       initializer,
       span,
       maximum_nodes);
  end append_object_declaration;

  function append_constrained_object_declaration
    (self             : in out Store;
     form             : Object_Declaration_Form;
     symbol           : Adac.Symbols.Symbol_ID;
     defining_span    : Adac.Source.Span;
     subtype_mark     : Node_ID;
     index_constraint : Node_ID;
     initializer      : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_constrained_object_declaration
      (self,
       form,
       symbol,
       defining_span,
       subtype_mark,
       index_constraint,
       initializer,
       span,
       maximum_nodes);
  end append_constrained_object_declaration;

  function append_object_renaming_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     renamed_name  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_object_renaming_declaration
      (self,
       symbol,
       defining_span,
       subtype_mark,
       renamed_name,
       span,
       maximum_nodes);
  end append_object_renaming_declaration;

  function append_number_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_number_declaration
      (self,
       symbol,
       defining_span,
       initializer,
       span,
       maximum_nodes);
  end append_number_declaration;

  function append_exception_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_exception_declaration
      (self, symbol, defining_span, span, maximum_nodes);
  end append_exception_declaration;

  function append_procedure_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_procedure_declaration
      (self,
       symbol,
       defining_span,
       parameters,
       span,
       maximum_nodes);
  end append_procedure_declaration;

  function append_procedure_body_stub
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_procedure_body_stub
      (self, symbol, defining_span, parameters, span, maximum_nodes);
  end append_procedure_body_stub;

  function append_function_declaration
    (self           : in out Store;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Node_List;
     result_subtype : Node_ID;
     aspect         : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_function_declaration
      (self,
       symbol,
       defining_span,
       parameters,
       result_subtype,
       aspect,
       span,
       maximum_nodes);
  end append_function_declaration;

  function append_function_declaration
    (self           : in out Store;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Node_List;
     result_subtype : Node_ID;
     expression     : Node_ID;
     aspect         : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_function_declaration
      (self,
       symbol,
       defining_span,
       parameters,
       result_subtype,
       expression,
       aspect,
       span,
       maximum_nodes);
  end append_function_declaration;

  function append_private_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     discriminants : Node_List;
     span          : Adac.Source.Span;
     limited_form  : Boolean := False;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_private_type_declaration
      (self,
       symbol,
       defining_span,
       discriminants,
       span,
       limited_form,
       maximum_nodes);
  end append_private_type_declaration;

  function append_derived_type_declaration
    (self                : in out Store;
     symbol              : Adac.Symbols.Symbol_ID;
     defining_span       : Adac.Source.Span;
     parent_subtype_mark : Node_ID;
     span                : Adac.Source.Span;
     maximum_nodes       : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_derived_type_declaration
      (self,
       symbol,
       defining_span,
       parent_subtype_mark,
       span,
       maximum_nodes);
  end append_derived_type_declaration;

  function append_range_constraint
    (self          : in out Store;
     lower_bound   : Node_ID;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_range_constraint
      (self, lower_bound, upper_bound, span, maximum_nodes);
  end append_range_constraint;

  function append_index_constraint
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_index_constraint
      (self,
       lower_bound,
       range_span,
       upper_bound,
       span,
       maximum_nodes);
  end append_index_constraint;

  function append_subtype_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     constraint    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_subtype_declaration
      (self,
       symbol,
       defining_span,
       subtype_mark,
       constraint,
       span,
       maximum_nodes);
  end append_subtype_declaration;

  function append_enumeration_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     literals      : Enumeration_Literal_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_enumeration_type_declaration
      (self,
       symbol,
       defining_span,
       literals,
       span,
       maximum_nodes);
  end append_enumeration_type_declaration;

  function append_discriminant_specification
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     subtype_mark       : Node_ID;
     default_expression : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_discriminant_specification
      (self,
       symbol,
       defining_span,
       subtype_mark,
       default_expression,
       span,
       maximum_nodes);
  end append_discriminant_specification;

  function append_record_component_declaration
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     aliased_form       : Boolean;
     subtype_mark       : Node_ID;
     default_expression : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_record_component_declaration
      (self,
       symbol,
       defining_span,
       aliased_form,
       subtype_mark,
       default_expression,
       span,
       maximum_nodes);
  end append_record_component_declaration;

  function append_record_variant
    (self                : in out Store;
     choices             : Node_List;
     components          : Node_List;
     null_component_list : Boolean;
     span                : Adac.Source.Span;
     maximum_nodes       : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_record_variant
      (self,
       choices,
       components,
       null_component_list,
       span,
       maximum_nodes);
  end append_record_variant;

  function append_record_variant_part
    (self              : in out Store;
     discriminant_name : Node_ID;
     variants          : Node_List;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_record_variant_part
      (self, discriminant_name, variants, span, maximum_nodes);
  end append_record_variant_part;

  function append_record_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     limited_form  : Boolean;
     discriminants : Node_List;
     components    : Node_List;
     variant_part  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_record_type_declaration
      (self,
       symbol,
       defining_span,
       limited_form,
       discriminants,
       components,
       variant_part,
       span,
       maximum_nodes);
  end append_record_type_declaration;

  function append_access_object_type_declaration
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     modifier           : General_Access_Modifier_Kind;
     designated_subtype : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_access_object_type_declaration
      (self,
       symbol,
       defining_span,
       modifier,
       designated_subtype,
       span,
       maximum_nodes);
  end append_access_object_type_declaration;

  function append_others_exception_choice
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_others_exception_choice
      (self,
       span,
       maximum_nodes);
  end append_others_exception_choice;

  function append_exception_handler
    (self                    : in out Store;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID;
     choice_parameter_span   : Adac.Source.Span;
     choices                 : Node_List;
     statements              : Node_List;
     span                    : Adac.Source.Span;
     maximum_nodes           : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_exception_handler
      (self,
       choice_parameter_symbol,
       choice_parameter_span,
       choices,
       statements,
       span,
       maximum_nodes);
  end append_exception_handler;

  function append_handled_sequence
    (self          : in out Store;
     statements    : Node_List;
     handlers      : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_handled_sequence
      (self,
       statements,
       handlers,
       span,
       maximum_nodes);
  end append_handled_sequence;

  function append_elsif_part
    (self          : in out Store;
     condition     : Node_ID;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_elsif_part
      (self, condition, statements, span, maximum_nodes);
  end append_elsif_part;

  function append_if_statement
    (self            : in out Store;
     condition       : Node_ID;
     then_statements : Node_List;
     elsif_parts     : Node_List;
     else_statements : Node_List;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_if_statement
      (self,
       condition,
       then_statements,
       elsif_parts,
       else_statements,
       span,
       maximum_nodes);
  end append_if_statement;

  function append_assignment_statement
    (self          : in out Store;
     target        : Node_ID;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_assignment_statement
      (self,
       target,
       expression,
       span,
       maximum_nodes);
  end append_assignment_statement;

  function append_case_range_choice
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_case_range_choice
      (self, lower_bound, range_span, upper_bound, span, maximum_nodes);
  end append_case_range_choice;

  function append_others_case_choice
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_others_case_choice
      (self, span, maximum_nodes);
  end append_others_case_choice;

  function append_case_alternative
    (self          : in out Store;
     choices       : Node_List;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_case_alternative
      (self,
       choices,
       statements,
       span,
       maximum_nodes);
  end append_case_alternative;

  function append_case_statement
    (self                 : in out Store;
     selecting_expression : Node_ID;
     alternatives         : Node_List;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_case_statement
      (self,
       selecting_expression,
       alternatives,
       span,
       maximum_nodes);
  end append_case_statement;

  function append_block_statement
    (self             : in out Store;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_block_statement
      (self,
       declarations,
       handled_sequence,
       span,
       maximum_nodes);
  end append_block_statement;

  function append_simple_loop_statement
    (self          : in out Store;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_simple_loop_statement
      (self, statements, span, maximum_nodes);
  end append_simple_loop_statement;

  function append_while_loop_statement
    (self          : in out Store;
     condition     : Node_ID;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_while_loop_statement
      (self, condition, statements, span, maximum_nodes);
  end append_while_loop_statement;

  function append_discrete_range_loop_statement
    (self             : in out Store;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     lower_bound      : Node_ID;
     upper_bound      : Node_ID;
     statements       : Node_List;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_discrete_range_loop_statement
      (self,
       parameter_symbol,
       parameter_span,
       reverse_present,
       lower_bound,
       upper_bound,
       statements,
       span,
       maximum_nodes);
  end append_discrete_range_loop_statement;

  function append_range_attribute_loop_statement
    (self             : in out Store;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     range_attribute  : Node_ID;
     statements       : Node_List;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_range_attribute_loop_statement
      (self,
       parameter_symbol,
       parameter_span,
       reverse_present,
       range_attribute,
       statements,
       span,
       maximum_nodes);
  end append_range_attribute_loop_statement;

  function append_loop_statement
    (self             : in out Store;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     iterable_name    : Node_ID;
     statements       : Node_List;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_loop_statement
      (self,
       parameter_symbol,
       parameter_span,
       reverse_present,
       iterable_name,
       statements,
       span,
       maximum_nodes);
  end append_loop_statement;

  function append_procedure_call_statement
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_procedure_call_statement
      (self,
       callable_name,
       actuals,
       span,
       maximum_nodes);
  end append_procedure_call_statement;

  function append_procedure_call_statement
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Procedure_Call_Actual_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_procedure_call_statement
      (self,
       callable_name,
       actuals,
       span,
       maximum_nodes);
  end append_procedure_call_statement;

  function append_extended_return_statement
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     sequence      : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_extended_return_statement
      (self,
       symbol,
       defining_span,
       subtype_mark,
       sequence,
       span,
       maximum_nodes);
  end append_extended_return_statement;

  function append_exit_statement
    (self             : in out Store;
     loop_name_symbol : Adac.Symbols.Symbol_ID;
     loop_name_span   : Adac.Source.Span;
     when_span        : Adac.Source.Span;
     condition        : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_exit_statement
      (self,
       loop_name_symbol,
       loop_name_span,
       when_span,
       condition,
       span,
       maximum_nodes);
  end append_exit_statement;

  function append_return_statement
    (self          : in out Store;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_return_statement
      (self, expression, span, maximum_nodes);
  end append_return_statement;

  function append_bare_raise_statement
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_bare_raise_statement
      (self, span, maximum_nodes);
  end append_bare_raise_statement;

  function append_raise_statement
    (self           : in out Store;
     exception_name : Node_ID;
     message        : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_raise_statement
      (self, exception_name, message, span, maximum_nodes);
  end append_raise_statement;

  function append_statement
    (self          : in out Store;
     kind          : Node_Kind;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_statement
      (self,
       kind,
       span,
       maximum_nodes);
  end append_statement;

  function append_with_clause
    (self          : in out Store;
     names         : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_with_clause
      (self,
       names,
       span,
       maximum_nodes);
  end append_with_clause;

  function append_use_type_clause
    (self          : in out Store;
     subtype_marks : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_use_type_clause
      (self, subtype_marks, span, maximum_nodes);
  end append_use_type_clause;

  function append_use_package_clause
    (self          : in out Store;
     package_names : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_use_package_clause
      (self, package_names, span, maximum_nodes);
  end append_use_package_clause;

  function append_package_renaming_declaration
    (self            : in out Store;
     defining_name   : Program_Unit_Name;
     renamed_package : Node_ID;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_package_renaming_declaration
      (self, defining_name, renamed_package, span, maximum_nodes);
  end append_package_renaming_declaration;

  function append_package_instantiation
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     generic_name  : Node_ID;
     actuals       : Generic_Actual_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_package_instantiation
      (self, defining_name, generic_name, actuals, span, maximum_nodes);
  end append_package_instantiation;

  function append_package_declaration
    (self                 : in out Store;
     defining_name        : Program_Unit_Name;
     visible_declarations : Node_List;
     private_part_span    : Adac.Source.Span;
     private_declarations : Node_List;
     end_name             : Program_Unit_Name;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_package_declaration
      (self,
       defining_name,
       visible_declarations,
       private_part_span,
       private_declarations,
       end_name,
       span,
       maximum_nodes);
  end append_package_declaration;

  function append_package_declaration
    (self                 : in out Store;
     defining_name        : Program_Unit_Name;
     visible_declarations : Node_List;
     end_name             : Program_Unit_Name;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
    private_declarations : Node_List;
  begin
    return append_package_declaration
      (self,
       defining_name,
       visible_declarations,
       Adac.Source.INVALID_SPAN,
       private_declarations,
       end_name,
       span,
       maximum_nodes);
  end append_package_declaration;

  function append_package_body_stub
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_package_body_stub
      (self, symbol, defining_span, span, maximum_nodes);
  end append_package_body_stub;

  function append_package_body
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     declarations  : Node_List;
     end_name      : Program_Unit_Name;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_package_body
      (self,
       defining_name,
       declarations,
       end_name,
       span,
       maximum_nodes);
  end append_package_body;

  function append_procedure_body
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Node_List;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_procedure_body
      (self,
       procedure_symbol,
       parameters,
       declarations,
       handled_sequence,
       end_symbol,
       span,
       maximum_nodes);
  end append_procedure_body;

  function append_function_body
    (self             : in out Store;
     function_symbol  : Adac.Symbols.Symbol_ID;
     parameters       : Node_List;
     result_subtype   : Node_ID;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_function_body
      (self,
       function_symbol,
       parameters,
       result_subtype,
       declarations,
       handled_sequence,
       end_symbol,
       span,
       maximum_nodes);
  end append_function_body;

  function append_subunit
    (self             : in out Store;
     parent_unit_name : Program_Unit_Name;
     proper_body      : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_subunit
      (self, parent_unit_name, proper_body, span, maximum_nodes);
  end append_subunit;

  function append_compilation_unit
    (self          : in out Store;
     context_items : Node_List;
     unit_item     : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return Implementation.append_compilation_unit
      (self,
       context_items,
       unit_item,
       span,
       maximum_nodes);
  end append_compilation_unit;

end Adac.AST.Construction;
