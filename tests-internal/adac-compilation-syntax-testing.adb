-- ============================================================================
-- adac-compilation-syntax-testing.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST.Testing;

package body Adac.Compilation.Syntax.Testing is

  function create_statement_unchecked
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_statement_unchecked
      (self.ast_store, kind, span);
  end create_statement_unchecked;

  function create_exception_handler_unchecked
    (self                    : in out Context;
     choices                 : Adac.AST.Node_List;
     statements              : Adac.AST.Node_List;
     span                    : Adac.Source.Span;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID :=
       Adac.Symbols.INVALID_SYMBOL_ID;
     choice_parameter_span   : Adac.Source.Span := Adac.Source.INVALID_SPAN)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_exception_handler_unchecked
      (self.ast_store, choices, statements, span,
       choice_parameter_symbol, choice_parameter_span);
  end create_exception_handler_unchecked;

  function create_handled_sequence_unchecked
    (self       : in out Context;
     statements : Adac.AST.Node_List;
     handlers   : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_handled_sequence_unchecked
      (self.ast_store, statements, handlers, span);
  end create_handled_sequence_unchecked;

  function create_elsif_part_unchecked
    (self       : in out Context;
     condition  : Adac.AST.Node_ID;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_elsif_part_unchecked
      (self.ast_store, condition, statements, span);
  end create_elsif_part_unchecked;

  function create_if_statement_unchecked
    (self            : in out Context;
     condition       : Adac.AST.Node_ID;
     then_statements : Adac.AST.Node_List;
     elsif_parts     : Adac.AST.Node_List;
     else_statements : Adac.AST.Node_List;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_if_statement_unchecked
      (self.ast_store,
       condition,
       then_statements,
       elsif_parts,
       else_statements,
       span);
  end create_if_statement_unchecked;

  function create_procedure_call_unchecked
    (self          : in out Context;
     callable_name : Adac.AST.Node_ID;
     actuals       : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_procedure_call_unchecked
      (self.ast_store, callable_name, actuals, span);
  end create_procedure_call_unchecked;

  function create_string_literal_unchecked
    (self     : in out Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_string_literal_unchecked
      (self.ast_store, spelling, span);
  end create_string_literal_unchecked;

  function create_binary_adding_unchecked
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_binary_adding_unchecked
      (self.ast_store,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span);
  end create_binary_adding_unchecked;

  function create_relation_unchecked
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_relation_unchecked
      (self.ast_store,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span);
  end create_relation_unchecked;

  function create_parameter_specification_unchecked
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Adac.AST.Parameter_Mode_Kind;
     subtype_mark       : Adac.AST.Node_ID;
     span               : Adac.Source.Span;
     default_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_parameter_specification_unchecked
      (self.ast_store,
       symbol,
       defining_span,
       mode,
       subtype_mark,
       span,
       default_expression);
  end create_parameter_specification_unchecked;

  function create_object_declaration_unchecked
    (self          : in out Context;
     form          : Adac.AST.Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_object_declaration_unchecked
      (self.ast_store,
       form,
       symbol,
       defining_span,
       subtype_mark,
       initializer,
       span);
  end create_object_declaration_unchecked;

  function create_number_declaration_unchecked
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_number_declaration_unchecked
      (self.ast_store, symbol, defining_span, initializer, span);
  end create_number_declaration_unchecked;

  function create_procedure_declaration_unchecked
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_procedure_declaration_unchecked
      (self.ast_store, symbol, defining_span, parameters, span);
  end create_procedure_declaration_unchecked;

  function create_package_declaration_unchecked
    (self          : in out Context;
     defining_name : Adac.AST.Program_Unit_Name;
     declarations  : Adac.AST.Node_List;
     end_name      : Adac.AST.Program_Unit_Name;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_package_declaration_unchecked
      (self.ast_store, defining_name, declarations, end_name, span);
  end create_package_declaration_unchecked;

  function create_with_clause_unchecked
    (self  : in out Context;
     names : Adac.AST.Node_List;
     span  : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_with_clause_unchecked
      (self.ast_store, names, span);
  end create_with_clause_unchecked;

  function create_procedure_body_unchecked
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Adac.AST.Node_List;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_procedure_body_unchecked
      (self.ast_store,
       procedure_symbol,
       parameters,
       declarations,
       handled_sequence,
       end_symbol,
       span);
  end create_procedure_body_unchecked;

  function create_compilation_unit_unchecked
    (self          : in out Context;
     context_items : Adac.AST.Node_List;
     library_item  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_compilation_unit_unchecked
      (self.ast_store, context_items, library_item, span);
  end create_compilation_unit_unchecked;

end Adac.Compilation.Syntax.Testing;
