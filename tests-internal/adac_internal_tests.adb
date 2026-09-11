-- ============================================================================
-- adac_internal_tests.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Latin_1;
with Ada.Command_Line;
with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Compilation;
with Adac.Compilation.Diagnostics;
with Adac.Compilation.Semantics;
with Adac.Compilation.Semantics.Testing;
with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;
with Adac.Compilation.Syntax.Testing;
with Adac.Compilation.Types;
with Adac.Frontend;
with Adac.Frontend.Lexer;
with Adac.Frontend.Tokens;
with Adac.IR;
with Adac.IR.Builder;
with Adac.Language;
with Adac.Resources;
with Adac.Sema;
with Adac.Semantics;
with Adac.Source;
with Adac.Symbols;
with Adac.Types;

with Adac_Assembly_Patterns;
with Adac_Internal_Test_Catalog;

procedure adac_internal_tests is

  use type Adac.Source.Source_File_ID;
  use type Adac.Source.Position;
  use type Adac.Source.Span;
  use type Adac.Symbols.Symbol_ID;
  use type Adac.AST.Node_ID;
  use type Adac.AST.Node_Kind;
  use type Adac.AST.Numeric_Literal_Kind;
  use type Adac.AST.Parameter_Mode_Kind;
  use type Adac.AST.Object_Declaration_Form;
  use type Adac.AST.Parenthesized_Name_Item_Form;
  use type Adac.Frontend.Parse_Status;
  use type Adac.IR.Instruction_Kind;
  use type Adac.IR.Scalar_Type_Kind;
  use type Adac.IR.Value_ID;
  use type Adac.IR.Value_Kind;
  use type Adac.Frontend.Tokens.Token_Kind;
  use type Adac.Sema.Analysis_Status;
  use type Adac.Semantics.Entity_Kind;
  use type Adac.Semantics.Procedure_Statement_Kind;
  use type Adac.Semantics.Scope_Binding_Kind;
  use type Adac.Types.Type_ID;
  use type Adac.Types.Type_Kind;

  function new_context
    (case_sensitive_identifiers : Boolean := False;
     resource_limits : Adac.Resources.Limits :=
       Adac.Resources.DEFAULT_LIMITS)
  return Adac.Compilation.Context
  is
    options : constant Adac.Language.Options :=
      (case_sensitive_identifiers => case_sensitive_identifiers);
  begin
    return Adac.Compilation.create (options, resource_limits);
  end new_context;

  procedure require
    (condition : Boolean;
     message   : String)
  is
  begin
    if not condition then
      raise Program_Error with message;
    end if;
  end require;

  function accepts_assembly_patterns
    (patterns : String;
     assembly : String)
  return Boolean is
  begin
    return Adac_Assembly_Patterns.matches (patterns, assembly);
  exception
    when Program_Error =>
      return False;
  end accepts_assembly_patterns;

  function create_minimal_unit
    (context        : in out Adac.Compilation.Context;
     procedure_name : String;
     end_name       : String;
     unit_span      : Adac.Source.Span;
     statement_span : Adac.Source.Span)
  return Adac.AST.Node_ID is
    context_items  : Adac.AST.Node_List;
    parameters     : Adac.AST.Node_List;
    declarations   : Adac.AST.Node_List;
    statements     : Adac.AST.Node_List;
    handlers       : Adac.AST.Node_List;
    handled_sequence : Adac.AST.Node_ID;
    procedure_node : Adac.AST.Node_ID;
  begin
    Adac.AST.append
      (statements,
       Adac.Compilation.Syntax.create_statement
         (context, Adac.AST.Null_Statement_Node, statement_span));
    handled_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, statements, handlers, statement_span);
    procedure_node := Adac.Compilation.Syntax.create_procedure_body
      (context,
       Adac.Compilation.Symbols.intern (context, procedure_name),
       parameters,
       declarations,
       handled_sequence,
       Adac.Compilation.Symbols.intern (context, end_name),
       unit_span);
    return Adac.Compilation.Syntax.create_compilation_unit
      (context, context_items, procedure_node, unit_span);
  end create_minimal_unit;

  function create_unchecked_unit
    (context          : in out Adac.Compilation.Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     unit_span        : Adac.Source.Span;
     statement_span   : Adac.Source.Span;
     has_statement    : Boolean := True)
  return Adac.AST.Node_ID is
    context_items  : Adac.AST.Node_List;
    parameters     : Adac.AST.Node_List;
    declarations   : Adac.AST.Node_List;
    statements     : Adac.AST.Node_List;
    handlers       : Adac.AST.Node_List;
    handled_sequence : Adac.AST.Node_ID;
    procedure_node : Adac.AST.Node_ID;
  begin
    if has_statement then
      Adac.AST.append
        (statements,
         Adac.Compilation.Syntax.Testing.create_statement_unchecked
           (context, Adac.AST.Null_Statement_Node, statement_span));
    end if;
    handled_sequence :=
      Adac.Compilation.Syntax.Testing.create_handled_sequence_unchecked
        (context, statements, handlers, statement_span);
    procedure_node :=
      Adac.Compilation.Syntax.Testing.create_procedure_body_unchecked
        (context,
         procedure_symbol,
         parameters,
         declarations,
         handled_sequence,
         end_symbol,
         unit_span);
    return Adac.Compilation.Syntax.Testing.create_compilation_unit_unchecked
      (context, context_items, procedure_node, unit_span);
  end create_unchecked_unit;

  function accepts_language_options
    (context : Adac.Compilation.Context) return Boolean
  is
  begin
    declare
      options : constant Adac.Language.Options :=
        Adac.Compilation.language_options (context);
      pragma unreferenced (options);
    begin
      null;
    end;

    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_language_options;

  function accepts_diagnostic_write
    (context : in out Adac.Compilation.Context) return Boolean
  is
  begin
    Adac.Compilation.Diagnostics.error (context, "uninitialized context");
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_diagnostic_write;

  function accepts_source_registration
    (context : in out Adac.Compilation.Context) return Boolean
  is
    file_id : Adac.Source.Source_File_ID;
  begin
    file_id := Adac.Compilation.Sources.register_file
      (context, "uninitialized.adb");
    return file_id /= Adac.Source.INVALID_SOURCE_FILE_ID;
  exception
    when Program_Error =>
      return False;
  end accepts_source_registration;

  function accepts_symbol_interning
    (context  : in out Adac.Compilation.Context;
     spelling : String)
  return Boolean is
    symbol : Adac.Symbols.Symbol_ID;
  begin
    symbol := Adac.Compilation.Symbols.intern (context, spelling);
    return symbol /= Adac.Symbols.INVALID_SYMBOL_ID;
  exception
    when Program_Error =>
      return False;
  end accepts_symbol_interning;

  function rejects_new_symbol_at_limit
    (context  : in out Adac.Compilation.Context;
     spelling : String)
  return Boolean
  is
  begin
    declare
      symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Symbols.intern (context, spelling);
      pragma unreferenced (symbol);
    begin
      null;
    end;

    return False;
  exception
    when Adac.Resources.Limit_Exceeded =>
      return True;
  end rejects_new_symbol_at_limit;

  function accepts_ast_query
    (context : Adac.Compilation.Context) return Boolean
  is
    count : Natural;
    pragma unreferenced (count);
  begin
    count := Adac.Compilation.Syntax.node_count (context);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_ast_query;

  function accepts_semantic_query
    (context : Adac.Compilation.Context) return Boolean
  is
    count : Natural;
    pragma unreferenced (count);
  begin
    count := Adac.Compilation.Semantics.entity_count (context);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_semantic_query;

  function accepts_type
    (context : Adac.Compilation.Context;
     value   : Adac.Types.Type_ID)
  return Boolean is
  begin
    Adac.Compilation.Types.validate (context, value);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_type;

  function rejects_numeric_literal_shape_before_limit
    (context  : in out Adac.Compilation.Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Boolean
  is
    node : Adac.AST.Node_ID;
    pragma unreferenced (node);
  begin
    node := Adac.Compilation.Syntax.create_numeric_literal
      (context, Adac.AST.Decimal_Integer_Form, spelling, span);
    return False;
  exception
    when Program_Error =>
      return True;

    when Adac.Resources.Limit_Exceeded =>
      return False;
  end rejects_numeric_literal_shape_before_limit;

  function rejects_character_literal_shape_before_limit
    (context  : in out Adac.Compilation.Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Boolean
  is
    node : Adac.AST.Node_ID;
    pragma unreferenced (node);
  begin
    node := Adac.Compilation.Syntax.create_character_literal
      (context, spelling, span);
    return False;
  exception
    when Program_Error =>
      return True;

    when Adac.Resources.Limit_Exceeded =>
      return False;
  end rejects_character_literal_shape_before_limit;

  function rejects_string_literal_shape_before_limit
    (context  : in out Adac.Compilation.Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Boolean
  is
    node : Adac.AST.Node_ID;
    pragma unreferenced (node);
  begin
    node := Adac.Compilation.Syntax.create_string_literal
      (context, spelling, span);
    return False;
  exception
    when Program_Error =>
      return True;

    when Adac.Resources.Limit_Exceeded =>
      return False;
  end rejects_string_literal_shape_before_limit;

  function rejects_invalid_statement_before_limit
    (context : in out Adac.Compilation.Context;
     span    : Adac.Source.Span)
  return Boolean
  is
    node : Adac.AST.Node_ID;
    pragma unreferenced (node);
  begin
    node := Adac.Compilation.Syntax.create_statement
      (context, Adac.AST.Compilation_Unit_Node, span);
    return False;
  exception
    when Program_Error =>
      return True;

    when Adac.Resources.Limit_Exceeded =>
      return False;
  end rejects_invalid_statement_before_limit;

  function rejects_empty_unit_before_limit
    (context : in out Adac.Compilation.Context;
     symbol  : Adac.Symbols.Symbol_ID;
     span    : Adac.Source.Span)
  return Boolean
  is
    parameters   : Adac.AST.Node_List;
    declarations : Adac.AST.Node_List;
    node         : Adac.AST.Node_ID;
    pragma unreferenced (node);
  begin
    node := Adac.Compilation.Syntax.create_procedure_body
      (context,
       symbol,
       parameters,
       declarations,
       Adac.AST.INVALID_NODE_ID,
       symbol,
       span);
    return False;
  exception
    when Program_Error =>
      return True;

    when Adac.Resources.Limit_Exceeded =>
      return False;
  end rejects_empty_unit_before_limit;

  function accepts_symbol
    (context : Adac.Compilation.Context;
     symbol  : Adac.Symbols.Symbol_ID)
  return Boolean is
  begin
    Adac.Compilation.Symbols.validate_symbol (context, symbol);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_symbol;

  function accepts_file_id
    (context : Adac.Compilation.Context;
     file_id : Adac.Source.Source_File_ID)
  return Boolean is
  begin
    declare
      path : constant String
           := Adac.Compilation.Sources.file_path (context, file_id);
      pragma unreferenced (path);
    begin
      return True;
    end;
  exception
    when Program_Error =>
      return False;
  end accepts_file_id;

  function accepts_span
    (first : Adac.Source.Position;
     last  : Adac.Source.Position)
  return Boolean is
  begin
    declare
      span : constant Adac.Source.Span :=
        Adac.Source.make_span (first, last);
      pragma unreferenced (span);
    begin
      null;
    end;

    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_span;

  function accepts_character_literal
    (context : Adac.Compilation.Context;
     literal : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_character_literal (context, literal);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_character_literal;

  function accepts_numeric_literal
    (context : Adac.Compilation.Context;
     literal : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_numeric_literal (context, literal);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_numeric_literal;

  function accepts_exception_handler
    (context : Adac.Compilation.Context;
     handler : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_exception_handler (context, handler);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_exception_handler;

  function accepts_handled_sequence
    (context  : Adac.Compilation.Context;
     sequence : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_handled_sequence (context, sequence);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_handled_sequence;

  function accepts_if_statement
    (context   : Adac.Compilation.Context;
     statement : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_if_statement (context, statement);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_if_statement;

  function accepts_assignment_statement
    (context   : Adac.Compilation.Context;
     statement : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_assignment_statement (context, statement);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_assignment_statement;

  function accepts_case_alternative
    (context     : Adac.Compilation.Context;
     alternative : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_case_alternative
      (context, alternative);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_case_alternative;

  function accepts_case_statement
    (context   : Adac.Compilation.Context;
     statement : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_case_statement (context, statement);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_case_statement;

  function accepts_block_statement
    (context   : Adac.Compilation.Context;
     statement : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_block_statement (context, statement);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_block_statement;

  function accepts_loop_statement
    (context   : Adac.Compilation.Context;
     statement : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_loop_statement (context, statement);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_loop_statement;

  function accepts_procedure_call
    (context   : Adac.Compilation.Context;
     statement : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_procedure_call (context, statement);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_procedure_call;

  function accepts_expression
    (context    : Adac.Compilation.Context;
     expression : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_expression (context, expression);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_expression;

  function rejects_exception_handler_construction
    (context                 : in out Adac.Compilation.Context;
     choices                 : Adac.AST.Node_List;
     statements              : Adac.AST.Node_List;
     span                    : Adac.Source.Span;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID :=
       Adac.Symbols.INVALID_SYMBOL_ID;
     choice_parameter_span   : Adac.Source.Span := Adac.Source.INVALID_SPAN)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_exception_handler
      (context,
       choice_parameter_symbol,
       choice_parameter_span,
       choices,
       statements,
       span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_exception_handler_construction;

  function rejects_handled_sequence_construction
    (context    : in out Adac.Compilation.Context;
     statements : Adac.AST.Node_List;
     handlers   : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_handled_sequence
      (context, statements, handlers, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_handled_sequence_construction;

  function rejects_if_statement_construction
    (context         : in out Adac.Compilation.Context;
     condition       : Adac.AST.Node_ID;
     then_statements : Adac.AST.Node_List;
     else_statements : Adac.AST.Node_List;
     span            : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
    elsif_parts : Adac.AST.Node_List;
  begin
    node := Adac.Compilation.Syntax.create_if_statement
      (context, condition, then_statements, elsif_parts, else_statements, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_if_statement_construction;

  function rejects_case_alternative_construction
    (context    : in out Adac.Compilation.Context;
     choices    : Adac.AST.Node_List;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_case_alternative
      (context, choices, statements, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_case_alternative_construction;

  function rejects_case_statement_construction
    (context              : in out Adac.Compilation.Context;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     span                 : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_case_statement
      (context, selecting_expression, alternatives, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_case_statement_construction;

  function rejects_block_statement_construction
    (context          : in out Adac.Compilation.Context;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_block_statement
      (context, declarations, handled_sequence, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_block_statement_construction;

  function rejects_loop_statement_construction
    (context          : in out Adac.Compilation.Context;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     iterable_name    : Adac.AST.Node_ID;
     statements       : Adac.AST.Node_List;
     span             : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_loop_statement
      (context,
       parameter_symbol,
       parameter_span,
       reverse_present,
       iterable_name,
       statements,
       span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_loop_statement_construction;

  function rejects_procedure_call_construction
    (context       : in out Adac.Compilation.Context;
     callable_name : Adac.AST.Node_ID;
     actuals       : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_procedure_call_statement
      (context, callable_name, actuals, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_procedure_call_construction;

  function rejects_if_expression_construction
    (context         : in out Adac.Compilation.Context;
     condition       : Adac.AST.Node_ID;
     then_expression : Adac.AST.Node_ID;
     else_expression : Adac.AST.Node_ID;
     span            : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_if_expression
      (context, condition, then_expression, else_expression, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_if_expression_construction;

  function rejects_parenthesized_expression_construction
    (context    : in out Adac.Compilation.Context;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_parenthesized_expression
      (context, expression, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_parenthesized_expression_construction;

  function rejects_unary_operator_construction
    (context           : in out Adac.Compilation.Context;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     operand           : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_unary_operator
      (context, operator_spelling, operator_span, operand, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_unary_operator_construction;

  function rejects_binary_adding_construction
    (context           : in out Adac.Compilation.Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_binary_adding
      (context,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_binary_adding_construction;

  function rejects_relation_construction
    (context           : in out Adac.Compilation.Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural := Adac.Compilation.Syntax.node_count (context);
    node   : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_relation
      (context,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_relation_construction;

  function accepts_name
    (context : Adac.Compilation.Context;
     name    : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_name (context, name);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_name;

  function accepts_parameter
    (context   : Adac.Compilation.Context;
     parameter : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_parameter (context, parameter);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_parameter;

  function accepts_declaration
    (context     : Adac.Compilation.Context;
     declaration : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_declaration;

  function accepts_package_declaration
    (context     : Adac.Compilation.Context;
     declaration : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_package_declaration
      (context, declaration);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_package_declaration;

  function accepts_package_body
    (context      : Adac.Compilation.Context;
     package_body : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate_package_body (context, package_body);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_package_body;

  function rejects_package_body_construction
    (context       : in out Adac.Compilation.Context;
     defining_name : Adac.AST.Program_Unit_Name;
     declarations  : Adac.AST.Node_List;
     end_name      : Adac.AST.Program_Unit_Name;
     span          : Adac.Source.Span)
  return Boolean
  is
    before : constant Natural :=
      Adac.Compilation.Syntax.node_count (context);
    node : Adac.AST.Node_ID;
  begin
    node := Adac.Compilation.Syntax.create_package_body
      (context, defining_name, declarations, end_name, span);
    return node = Adac.AST.INVALID_NODE_ID;
  exception
    when Program_Error =>
      return Adac.Compilation.Syntax.node_count (context) = before;
  end rejects_package_body_construction;

  function accepts_span
    (context : Adac.Compilation.Context;
     value   : Adac.Source.Span)
  return Boolean is
  begin
    Adac.Compilation.Sources.validate_span (context, value);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_span;

  function accepts_unit
    (context : Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate (context, root);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_unit;

  function accepts_analysis
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Boolean is
    result : Adac.Sema.Analysis_Result;
    pragma unreferenced (result);
  begin
    result := Adac.Sema.analyze (context, root);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_analysis;

  function analyze_entity
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Adac.Semantics.Entity_ID
  is
    result : constant Adac.Sema.Analysis_Result :=
      Adac.Sema.analyze (context, root);
  begin
    case result.status is
      when Adac.Sema.Analysis_Rejected =>
        raise Program_Error with
          "adac_internal_tests: expected semantic success";

      when Adac.Sema.Analysis_Succeeded =>
        return result.entity;
    end case;
  end analyze_entity;

  function accepts_lowering
    (context : Adac.Compilation.Context;
     entity  : Adac.Semantics.Entity_ID)
  return Boolean
  is
    module : Adac.IR.Module;
    pragma unreferenced (module);
  begin
    module := Adac.IR.Builder.build (context, entity);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_lowering;

  function accepts_module (module : Adac.IR.Module) return Boolean is
  begin
    Adac.IR.validate (module);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_module;

  procedure require_semantic_rejection_without_entities
    (path  : String;
     label : String)
  is
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       label & " did not reach semantic analysis");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Rejected,
             label & " was not rejected by semantic analysis");
          require
            (Adac.Compilation.Semantics.entity_count (context) = 0,
             label & " published semantic entities after rejection");
        end;
    end case;
  end require_semantic_rejection_without_entities;

  procedure require_nested_ast_limit
    (maximum_nodes  : Natural;
     expected_nodes : Natural;
     label_text     : String)
  is
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => maximum_nodes));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/declarations/subprograms/" &
                  "procedure-nested-subprogram-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       label_text & " AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       label_text & " AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = expected_nodes,
       label_text & " AST node limit published a partial node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       label_text & " AST node limit published a semantic entity");
  end require_nested_ast_limit;

  procedure require_outer_ast_limit
    (maximum_nodes  : Natural;
     expected_nodes : Natural;
     label_text     : String)
  is
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => maximum_nodes));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/declarations/subprograms/" &
         "outer-procedure-body-completion-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       label_text & " AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       label_text & " AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = expected_nodes,
       label_text & " AST node limit published a partial node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       label_text & " AST node limit published a semantic entity");
  end require_outer_ast_limit;

  context_a : Adac.Compilation.Context := new_context;
  context_b : Adac.Compilation.Context := new_context;

  procedure Run_Context_And_Identifiers is separate;
  procedure Run_AST_Expressions_And_Statements is separate;
  procedure Run_AST_Declarations_And_Packages is separate;
  procedure Run_Frontend_Rejections is separate;
  procedure Run_Bootstrap_Package_Ownership is separate;
  procedure Run_Bootstrap_Resource_Boundaries is separate;
  procedure Run_Bootstrap_Profile_Frontend is separate;
  procedure Run_Parser_And_Resource_Contracts is separate;
  procedure Run_Semantic_And_Pipeline is separate;
  procedure Run_IR_Validation is separate;
  procedure Run_Test_Infrastructure is separate;

begin
  if Ada.Command_Line.argument_count /= 1 then
    raise Program_Error with
      "adac-internal-tests requires exactly one scenario";
  end if;

  declare
    scenario : constant Adac_Internal_Test_Catalog.Scenario :=
      Adac_Internal_Test_Catalog.scenario_from_name
        (Ada.Command_Line.argument (1));
  begin
    case scenario is
      when Adac_Internal_Test_Catalog.Context_And_Identifiers =>
        Run_Context_And_Identifiers;
      when Adac_Internal_Test_Catalog.AST_Expressions_And_Statements =>
        Run_AST_Expressions_And_Statements;
      when Adac_Internal_Test_Catalog.AST_Declarations_And_Packages =>
        Run_AST_Declarations_And_Packages;
      when Adac_Internal_Test_Catalog.Frontend_Rejections =>
        Run_Frontend_Rejections;
      when Adac_Internal_Test_Catalog.Bootstrap_Package_Ownership =>
        Run_Bootstrap_Package_Ownership;
      when Adac_Internal_Test_Catalog.Bootstrap_Resource_Boundaries =>
        Run_Bootstrap_Resource_Boundaries;
      when Adac_Internal_Test_Catalog.Bootstrap_Profile_Frontend =>
        Run_Bootstrap_Profile_Frontend;
      when Adac_Internal_Test_Catalog.Parser_And_Resource_Contracts =>
        Run_Parser_And_Resource_Contracts;
      when Adac_Internal_Test_Catalog.Semantic_And_Pipeline =>
        Run_Semantic_And_Pipeline;
      when Adac_Internal_Test_Catalog.IR_Validation =>
        Run_IR_Validation;
      when Adac_Internal_Test_Catalog.Test_Infrastructure =>
        Run_Test_Infrastructure;
    end case;
  end;

end adac_internal_tests;
