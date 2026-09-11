-- ============================================================================
-- adac-compilation-syntax-testing.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Compilation.Syntax.Testing is

  function create_statement_unchecked
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_exception_handler_unchecked
    (self                    : in out Context;
     choices                 : Adac.AST.Node_List;
     statements              : Adac.AST.Node_List;
     span                    : Adac.Source.Span;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID :=
       Adac.Symbols.INVALID_SYMBOL_ID;
     choice_parameter_span   : Adac.Source.Span := Adac.Source.INVALID_SPAN)
  return Adac.AST.Node_ID;

  function create_handled_sequence_unchecked
    (self       : in out Context;
     statements : Adac.AST.Node_List;
     handlers   : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_elsif_part_unchecked
    (self       : in out Context;
     condition  : Adac.AST.Node_ID;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_if_statement_unchecked
    (self            : in out Context;
     condition       : Adac.AST.Node_ID;
     then_statements : Adac.AST.Node_List;
     elsif_parts     : Adac.AST.Node_List;
     else_statements : Adac.AST.Node_List;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_procedure_call_unchecked
    (self          : in out Context;
     callable_name : Adac.AST.Node_ID;
     actuals       : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_string_literal_unchecked
    (self     : in out Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_binary_adding_unchecked
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_relation_unchecked
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_parameter_specification_unchecked
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Adac.AST.Parameter_Mode_Kind;
     subtype_mark       : Adac.AST.Node_ID;
     span               : Adac.Source.Span;
     default_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID)
  return Adac.AST.Node_ID;

  function create_object_declaration_unchecked
    (self          : in out Context;
     form          : Adac.AST.Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_number_declaration_unchecked
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_procedure_declaration_unchecked
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_package_declaration_unchecked
    (self          : in out Context;
     defining_name : Adac.AST.Program_Unit_Name;
     declarations  : Adac.AST.Node_List;
     end_name      : Adac.AST.Program_Unit_Name;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_with_clause_unchecked
    (self  : in out Context;
     names : Adac.AST.Node_List;
     span  : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_procedure_body_unchecked
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Adac.AST.Node_List;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_compilation_unit_unchecked
    (self          : in out Context;
     context_items : Adac.AST.Node_List;
     library_item  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID;

end Adac.Compilation.Syntax.Testing;
