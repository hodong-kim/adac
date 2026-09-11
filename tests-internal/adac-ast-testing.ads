-- ============================================================================
-- adac-ast-testing.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.AST.Testing is

  function append_statement_unchecked
    (self : in out Store;
     kind : Node_Kind;
     span : Adac.Source.Span)
  return Node_ID;

  function append_exception_handler_unchecked
    (self                    : in out Store;
     choices                 : Node_List;
     statements              : Node_List;
     span                    : Adac.Source.Span;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID :=
       Adac.Symbols.INVALID_SYMBOL_ID;
     choice_parameter_span   : Adac.Source.Span := Adac.Source.INVALID_SPAN)
  return Node_ID;

  function append_handled_sequence_unchecked
    (self       : in out Store;
     statements : Node_List;
     handlers   : Node_List;
     span       : Adac.Source.Span)
  return Node_ID;

  function append_elsif_part_unchecked
    (self       : in out Store;
     condition  : Node_ID;
     statements : Node_List;
     span       : Adac.Source.Span)
  return Node_ID;

  function append_if_statement_unchecked
    (self            : in out Store;
     condition       : Node_ID;
     then_statements : Node_List;
     elsif_parts     : Node_List;
     else_statements : Node_List;
     span            : Adac.Source.Span)
  return Node_ID;

  function append_procedure_call_unchecked
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Node_List;
     span          : Adac.Source.Span)
  return Node_ID;

  function append_string_literal_unchecked
    (self     : in out Store;
     spelling : String;
     span     : Adac.Source.Span)
  return Node_ID;

  function append_binary_adding_unchecked
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span)
  return Node_ID;

  function append_relation_unchecked
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span)
  return Node_ID;

  function append_parameter_specification_unchecked
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Parameter_Mode_Kind;
     subtype_mark       : Node_ID;
     span               : Adac.Source.Span;
     default_expression : Node_ID := INVALID_NODE_ID)
  return Node_ID;

  function append_object_declaration_unchecked
    (self          : in out Store;
     form          : Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     initializer   : Node_ID;
     span          : Adac.Source.Span)
  return Node_ID;

  function append_number_declaration_unchecked
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Node_ID;
     span          : Adac.Source.Span)
  return Node_ID;

  function append_procedure_declaration_unchecked
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span)
  return Node_ID;

  function append_package_declaration_unchecked
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     declarations  : Node_List;
     end_name      : Program_Unit_Name;
     span          : Adac.Source.Span)
  return Node_ID;

  function append_with_clause_unchecked
    (self  : in out Store;
     names : Node_List;
     span  : Adac.Source.Span)
  return Node_ID;

  function append_procedure_body_unchecked
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Node_List;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Node_ID;

  function append_compilation_unit_unchecked
    (self          : in out Store;
     context_items : Node_List;
     unit_item     : Node_ID;
     span          : Adac.Source.Span)
  return Node_ID;

end Adac.AST.Testing;
