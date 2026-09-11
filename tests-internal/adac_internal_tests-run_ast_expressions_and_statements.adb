-- ============================================================================
-- adac_internal_tests-run_ast_expressions_and_statements.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_AST_Expressions_And_Statements is
  use type Adac.AST.Loop_Statement_Form;
  use type Adac.AST.Membership_Operator_Kind;
  use type Adac.AST.Procedure_Call_Actual_Association_Form;
  function empty_elsif_parts return Adac.AST.Node_List is
    result : Adac.AST.Node_List;
  begin
    return result;
  end empty_elsif_parts;
begin
  declare
    context : Adac.Compilation.Context := new_context (True);
    upper   : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Main");
    lower   : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "main");
  begin
    require
      (upper /= lower,
       "case-sensitive context merged distinct symbol spellings");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "case-sensitive symbol count is incorrect");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "numeric-literals.adb");
    decimal_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 10));
    real_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 2, 7));
    based_integer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 1),
         Adac.Source.make_position (file_id, 3, 6));
    based_real_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 1),
         Adac.Source.make_position (file_id, 4, 6));
    decimal_literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "123_456E+2", decimal_span);
    real_literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Real_Form, "12.5E-1", real_span);
    based_integer : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Based_Integer_Form, "16#FF#", based_integer_span);
    based_real : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Based_Real_Form, "2#1.1#", based_real_span);
  begin
    Adac.Compilation.Syntax.validate_numeric_literal (context, decimal_literal);
    Adac.Compilation.Syntax.validate_numeric_literal (context, real_literal);
    Adac.Compilation.Syntax.validate_numeric_literal (context, based_integer);
    Adac.Compilation.Syntax.validate_numeric_literal (context, based_real);
    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "numeric literal construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, decimal_literal) =
       Adac.AST.Numeric_Literal_Node,
       "numeric literal has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.numeric_literal_form (context, decimal_literal) =
       Adac.AST.Decimal_Integer_Form,
       "decimal integer literal lost its lexical form");
    require
      (Adac.Compilation.Syntax.numeric_literal_spelling
         (context, decimal_literal) = "123_456E+2",
       "decimal integer literal lost its exact spelling");
    require
      (Adac.Compilation.Syntax.numeric_literal_form (context, real_literal) =
       Adac.AST.Decimal_Real_Form and then
       Adac.Compilation.Syntax.numeric_literal_form (context, based_integer) =
         Adac.AST.Based_Integer_Form and then
       Adac.Compilation.Syntax.numeric_literal_form (context, based_real) =
         Adac.AST.Based_Real_Form,
       "numeric literal forms were not preserved");
    require
      (Adac.Compilation.Syntax.node_span (context, based_real) =
       based_real_span,
       "numeric literal lost its source span");
    require
      (not accepts_numeric_literal (context_b, decimal_literal),
       "numeric literal validator accepted a node from another context");
    require
      (rejects_numeric_literal_shape_before_limit
         (context, "", decimal_span),
       "numeric literal accepted an empty spelling");
    require
      (rejects_numeric_literal_shape_before_limit
         (context, "1", decimal_span),
       "numeric literal accepted a mismatched span");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "character-literals.adb");
    letter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    space_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 2, 3));
    apostrophe_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 1),
         Adac.Source.make_position (file_id, 3, 3));
    mismatched_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 1),
         Adac.Source.make_position (file_id, 4, 4));
    letter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "'A'", letter_span);
    space : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "' '", space_span);
    apostrophe : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "'''", apostrophe_span);
  begin
    Adac.Compilation.Syntax.validate_character_literal (context, letter);
    Adac.Compilation.Syntax.validate_character_literal (context, space);
    Adac.Compilation.Syntax.validate_character_literal (context, apostrophe);
    require
      (Adac.Compilation.Syntax.node_count (context) = 3 and then
       Adac.Compilation.Syntax.kind_of (context, letter) =
         Adac.AST.Character_Literal_Node,
       "character literal construction lost its AST kind/count");
    require
      (Adac.Compilation.Syntax.character_literal_spelling (context, letter) =
         "'A'" and then
       Adac.Compilation.Syntax.character_literal_spelling (context, space) =
         "' '" and then
       Adac.Compilation.Syntax.character_literal_spelling
         (context, apostrophe) = "'''",
       "character literal construction lost exact spellings");
    require
      (Adac.Compilation.Syntax.node_span (context, apostrophe) =
         apostrophe_span,
       "character literal construction lost its source span");
    require
      (not accepts_character_literal (context_b, letter),
       "character literal validator accepted a foreign-context node");
    require
      (rejects_character_literal_shape_before_limit
         (context, "A", letter_span),
       "character literal accepted unbracketed spelling");
    require
      (rejects_character_literal_shape_before_limit
         (context, "'A'", mismatched_span),
       "character literal accepted a mismatched span");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    context_b : constant Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID
            := Adac.Compilation.Sources.register_file
                 (context, "if-expression-tree.adb");
    condition_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    then_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value");
    condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 9));
    then_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 16),
         Adac.Source.make_position (file_id, 1, 20));
    else_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 29));
    conditional_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 29));
    parenthesized_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 30));
    condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, condition_symbol, condition_span);
    then_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, then_symbol, then_span);
    else_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_string_literal
        (context, """x""", else_span);
    conditional : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_if_expression
        (context,
         condition,
         then_expression,
         else_expression,
         conditional_span);
    expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parenthesized_expression
        (context, conditional, parenthesized_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.node_count (context) = 5,
       "conditional expression published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, conditional) =
       Adac.AST.If_Expression_Node,
       "conditional expression has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.kind_of (context, expression) =
       Adac.AST.Parenthesized_Expression_Node,
       "conditional wrapper has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.if_expression_condition
         (context, conditional) = condition,
       "conditional expression lost its condition");
    require
      (Adac.Compilation.Syntax.if_expression_then_expression
         (context, conditional) = then_expression,
       "conditional expression lost its then expression");
    require
      (Adac.Compilation.Syntax.if_expression_else_expression
         (context, conditional) = else_expression,
       "conditional expression lost its else expression");
    require
      (Adac.Compilation.Syntax.parenthesized_expression_child
         (context, expression) = conditional,
       "conditional wrapper lost its child");
    require
      (Adac.Compilation.Syntax.node_span (context, conditional) =
       conditional_span,
       "conditional expression lost its span");
    require
      (Adac.Compilation.Syntax.node_span (context, expression) =
       parenthesized_span,
       "conditional wrapper lost its span");
    require
      (not accepts_expression (context_b, expression),
       "expression validator accepted conditional syntax from another context");
    require
      (rejects_if_expression_construction
         (context,
          condition,
          else_expression,
          then_expression,
          conditional_span),
       "conditional expression accepted out-of-order children");
    declare
      simple_wrapper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_parenthesized_expression
          (context, condition, parenthesized_span);
      invalid_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_statement
          (context, Adac.AST.Null_Statement_Node, condition_span);
    begin
      Adac.Compilation.Syntax.validate_expression (context, simple_wrapper);
      require
        (Adac.Compilation.Syntax.parenthesized_expression_child
           (context, simple_wrapper) = condition,
         "parenthesized simple expression lost its child");
      require
        (rejects_parenthesized_expression_construction
           (context, invalid_statement, parenthesized_span),
         "parenthesized expression accepted a statement child");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    context_b : constant Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "case-expression-tree.adb");
    selecting_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Kind");
    alpha_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Alpha");
    beta_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Beta");
    selecting_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 10));
    alpha_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 20),
         Adac.Source.make_position (file_id, 1, 24));
    beta_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 28),
         Adac.Source.make_position (file_id, 1, 31));
    first_value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 36),
         Adac.Source.make_position (file_id, 1, 36));
    first_alternative_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 15),
         Adac.Source.make_position (file_id, 1, 36));
    others_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 44),
         Adac.Source.make_position (file_id, 1, 49));
    second_value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 54),
         Adac.Source.make_position (file_id, 1, 54));
    second_alternative_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 39),
         Adac.Source.make_position (file_id, 1, 54));
    conditional_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 54));
    parenthesized_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 55));
    selecting : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, selecting_symbol, selecting_span);
    alpha : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, alpha_symbol, alpha_span);
    beta : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, beta_symbol, beta_span);
    first_value : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "1", first_value_span);
    first_choices : Adac.AST.Node_List;
    first_alternative : Adac.AST.Node_ID;
    others_choice : Adac.AST.Node_ID;
    second_value : Adac.AST.Node_ID;
    second_choices : Adac.AST.Node_List;
    second_alternative : Adac.AST.Node_ID;
    alternatives : Adac.AST.Node_List;
    conditional : Adac.AST.Node_ID;
    expression : Adac.AST.Node_ID;
  begin
    Adac.AST.append (first_choices, alpha);
    Adac.AST.append (first_choices, beta);
    first_alternative :=
      Adac.Compilation.Syntax.create_case_expression_alternative
        (context,
         first_choices,
         first_value,
         first_alternative_span);
    others_choice :=
      Adac.Compilation.Syntax.create_others_case_choice
        (context, others_span);
    second_value :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "2", second_value_span);
    Adac.AST.append (second_choices, others_choice);
    second_alternative :=
      Adac.Compilation.Syntax.create_case_expression_alternative
        (context,
         second_choices,
         second_value,
         second_alternative_span);
    Adac.AST.append (alternatives, first_alternative);
    Adac.AST.append (alternatives, second_alternative);
    conditional := Adac.Compilation.Syntax.create_case_expression
      (context, selecting, alternatives, conditional_span);
    expression := Adac.Compilation.Syntax.create_parenthesized_expression
      (context, conditional, parenthesized_span);

    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.node_count (context) = 10 and then
       Adac.Compilation.Syntax.kind_of (context, conditional) =
         Adac.AST.Case_Expression_Node and then
       Adac.Compilation.Syntax.case_expression_selecting_expression
         (context, conditional) = selecting and then
       Adac.Compilation.Syntax.case_expression_alternative_count
         (context, conditional) = 2 and then
       Adac.Compilation.Syntax.case_expression_alternative_at
         (context, conditional, 1) = first_alternative and then
       Adac.Compilation.Syntax.case_expression_alternative_at
         (context, conditional, 2) = second_alternative and then
       Adac.Compilation.Syntax.case_expression_alternative_choice_count
         (context, first_alternative) = 2 and then
       Adac.Compilation.Syntax.case_expression_alternative_choice_at
         (context, first_alternative, 1) = alpha and then
       Adac.Compilation.Syntax.case_expression_alternative_choice_at
         (context, first_alternative, 2) = beta and then
       Adac.Compilation.Syntax.case_expression_alternative_expression
         (context, first_alternative) = first_value and then
       Adac.Compilation.Syntax.case_expression_alternative_choice_count
         (context, second_alternative) = 1 and then
       Adac.Compilation.Syntax.case_expression_alternative_choice_at
         (context, second_alternative, 1) = others_choice and then
       Adac.Compilation.Syntax.case_expression_alternative_expression
         (context, second_alternative) = second_value and then
       Adac.Compilation.Syntax.parenthesized_expression_child
         (context, expression) = conditional,
       "case expression lost ordered syntax ownership");
    require
      (not accepts_expression (context_b, expression),
       "expression validator accepted case syntax from another context");

    declare
      empty_alternatives : Adac.AST.Node_List;
      before : constant Natural := Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
    begin
      begin
        conditional := Adac.Compilation.Syntax.create_case_expression
          (context, selecting, empty_alternatives, conditional_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then
         Adac.Compilation.Syntax.node_count (context) = before,
         "empty case-expression alternative list was published");
    end;

    declare
      empty_choices : Adac.AST.Node_List;
      before : constant Natural := Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
    begin
      begin
        first_alternative :=
          Adac.Compilation.Syntax.create_case_expression_alternative
            (context,
             empty_choices,
             first_value,
             first_alternative_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then
         Adac.Compilation.Syntax.node_count (context) = before,
         "empty case-expression choice list was published");
    end;

    declare
      reversed_choices : Adac.AST.Node_List;
      before : constant Natural := Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
    begin
      Adac.AST.append (reversed_choices, beta);
      Adac.AST.append (reversed_choices, alpha);
      begin
        first_alternative :=
          Adac.Compilation.Syntax.create_case_expression_alternative
            (context,
             reversed_choices,
             first_value,
             first_alternative_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then
         Adac.Compilation.Syntax.node_count (context) = before,
         "out-of-order case-expression choices were published");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    context_b : constant Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "raise-expression-tree.adb");
    exception_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Parse_Error");
    exception_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 17));
    bare_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 17));
    named_exception_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 7),
         Adac.Source.make_position (file_id, 2, 17));
    message_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 24),
         Adac.Source.make_position (file_id, 2, 33));
    named_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 2, 33));
    exception_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, exception_symbol, exception_span);
    bare_raise : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_raise_expression
        (context,
         exception_name,
         Adac.AST.INVALID_NODE_ID,
         bare_span);
    named_exception_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, exception_symbol, named_exception_span);
    message : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_string_literal
        (context, """bad kind""", message_span);
    named_raise : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_raise_expression
        (context, named_exception_name, message, named_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, bare_raise);
    Adac.Compilation.Syntax.validate_expression (context, named_raise);
    require
      (Adac.Compilation.Syntax.kind_of (context, bare_raise) =
         Adac.AST.Raise_Expression_Node and then
       Adac.Compilation.Syntax.raise_expression_exception_name
         (context, bare_raise) = exception_name and then
       not Adac.Compilation.Syntax.raise_expression_has_message
         (context, bare_raise) and then
       Adac.Compilation.Syntax.raise_expression_message
         (context, bare_raise) = Adac.AST.INVALID_NODE_ID and then
       Adac.Compilation.Syntax.raise_expression_has_message
         (context, named_raise) and then
       Adac.Compilation.Syntax.raise_expression_message
         (context, named_raise) = message,
       "raise expression lost optional message ownership");
    require
      (not accepts_expression (context_b, named_raise),
       "expression validator accepted raise syntax from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "if-expression-relation-condition.adb");
    stack_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Stack_Size");
    then_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Return_Sequence");
    else_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Framed_Return_Sequence");
    stack_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 14));
    equal_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 16),
         Adac.Source.make_position (file_id, 1, 16));
    zero_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 18),
         Adac.Source.make_position (file_id, 1, 18));
    condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 18));
    then_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 25),
         Adac.Source.make_position (file_id, 1, 39));
    else_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 46),
         Adac.Source.make_position (file_id, 1, 67));
    conditional_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 67));
    stack_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, stack_symbol, stack_span);
    zero : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "0", zero_span);
    condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_relation
        (context,
         stack_name,
         "=",
         equal_span,
         zero,
         condition_span);
    then_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, then_symbol, then_span);
    else_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, else_symbol, else_span);
    conditional : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_if_expression
        (context,
         condition,
         then_expression,
         else_expression,
         conditional_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, conditional);
    require
      (Adac.Compilation.Syntax.kind_of (context, condition) =
         Adac.AST.Relation_Node and then
       Adac.Compilation.Syntax.if_expression_condition
         (context, conditional) = condition,
       "conditional expression lost its relation condition");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "parenthesized-short-circuit.adb");
    left_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Left");
    right_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Right");
    other_left_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Other_Left");
    other_right_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Other_Right");
    left_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 5));
    first_operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 8));
    right_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 14));
    and_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 16),
         Adac.Source.make_position (file_id, 1, 18));
    then_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 20),
         Adac.Source.make_position (file_id, 1, 23));
    other_left_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 25),
         Adac.Source.make_position (file_id, 1, 34));
    second_operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 36),
         Adac.Source.make_position (file_id, 1, 37));
    other_right_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 39),
         Adac.Source.make_position (file_id, 1, 49));
    first_relation_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.first_position (left_span),
         Adac.Source.last_position (right_span));
    second_relation_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.first_position (other_left_span),
         Adac.Source.last_position (other_right_span));
    short_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.first_position (first_relation_span),
         Adac.Source.last_position (second_relation_span));
    wrapper_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 50));
    left_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, left_symbol, left_span);
    right_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, right_symbol, right_span);
    other_left_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, other_left_symbol, other_left_span);
    other_right_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, other_right_symbol, other_right_span);
    first_relation : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_relation
        (context,
         left_name,
         "/=",
         first_operator_span,
         right_name,
         first_relation_span);
    second_relation : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_relation
        (context,
         other_left_name,
         "/=",
         second_operator_span,
         other_right_name,
         second_relation_span);
    short_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_short_circuit_expression
        (context,
         first_relation,
         Adac.AST.And_Then_Short_Circuit_Operator,
         and_span,
         then_span,
         second_relation,
         short_span);
    expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parenthesized_expression
        (context, short_expression, wrapper_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.kind_of (context, expression) =
         Adac.AST.Parenthesized_Expression_Node and then
       Adac.Compilation.Syntax.parenthesized_expression_child
         (context, expression) = short_expression and then
       Adac.Compilation.Syntax.kind_of (context, short_expression) =
         Adac.AST.Short_Circuit_Expression_Node,
       "parenthesized expression lost its short-circuit child");
  end;

  declare
    depth : constant Positive := 256;
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "deep-parenthesized-expression.adb");
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    base_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, depth + 1),
         Adac.Source.make_position (file_id, 1, depth + 5));
    expression : Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, symbol, base_span);
  begin
    for level in reverse 1 .. depth loop
      declare
        wrapper_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, 1, level),
             Adac.Source.make_position
               (file_id, 1, 2 * depth - level + 6));
      begin
        expression :=
          Adac.Compilation.Syntax.create_parenthesized_expression
            (context, expression, wrapper_span);
      end;
    end loop;

    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.node_count (context) = depth + 1 and then
       Adac.Compilation.Syntax.kind_of (context, expression) =
         Adac.AST.Parenthesized_Expression_Node,
       "deep parenthesized expression lost iterative ownership");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    context_b : constant Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "unary-tree.adb");
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    operand_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 9));
    expression_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 9));
    operand : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, symbol, operand_span);
    expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_unary_operator
        (context, "NoT", operator_span, operand, expression_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.kind_of (context, expression) =
       Adac.AST.Unary_Operator_Node,
       "unary operator has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.unary_operator_spelling
         (context, expression) = "NoT",
       "unary operator lost exact spelling");
    require
      (Adac.Compilation.Syntax.unary_operator_span
         (context, expression) = operator_span,
       "unary operator lost its operator span");
    require
      (Adac.Compilation.Syntax.unary_operand (context, expression) = operand,
       "unary operator lost its operand");
    require
      (Adac.Compilation.Syntax.node_span
         (context, expression) = expression_span,
       "unary operator lost its complete span");
    require
      (not accepts_expression (context_b, expression),
       "expression validator accepted unary syntax from another context");
    declare
      absolute_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_unary_operator
          (context, "AbS", operator_span, operand, expression_span);
    begin
      Adac.Compilation.Syntax.validate_expression
        (context, absolute_expression);
      require
        (Adac.Compilation.Syntax.unary_operator_spelling
           (context, absolute_expression) = "AbS" and then
         Adac.Compilation.Syntax.unary_operand
           (context, absolute_expression) = operand,
         "absolute unary operator lost spelling or operand");
    end;
    require
      (rejects_unary_operator_construction
         (context, "xor", operator_span, operand, expression_span),
       "unary operator accepted an unrepresented spelling");
    require
      (rejects_unary_operator_construction
         (context, "not", operator_span, operand, operand_span),
       "unary operator accepted a span that excludes its operator");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "relation-tree.adb");
    message_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "message");
    length_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "length");
    message_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 7));
    length_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 14));
    attribute_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 14));
    operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 16),
         Adac.Source.make_position (file_id, 1, 16));
    misplaced_operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 8),
         Adac.Source.make_position (file_id, 1, 8));
    literal_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 18),
         Adac.Source.make_position (file_id, 1, 18));
    relation_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 18));
    message_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, message_symbol, message_span);
    attribute_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_attribute_name
        (context,
         message_name,
         length_symbol,
         length_span,
         attribute_span);
    literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "0", literal_span);
    relation : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_relation
        (context,
         attribute_name,
         "=",
         operator_span,
         literal,
         relation_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, relation);
    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "relation construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, relation) =
       Adac.AST.Relation_Node,
       "relation has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.relation_left_operand (context, relation) =
       attribute_name,
       "relation lost its left operand");
    require
      (Adac.Compilation.Syntax.relation_right_operand (context, relation) =
       literal,
       "relation lost its right operand");
    require
      (Adac.Compilation.Syntax.relation_operator_spelling
         (context, relation) = "=",
       "relation lost its operator spelling");
    require
      (Adac.Compilation.Syntax.relation_operator_span (context, relation) =
       operator_span,
       "relation lost its operator span");
    require
      (Adac.Compilation.Syntax.node_span (context, relation) = relation_span,
       "relation lost its complete span");
    require
      (not accepts_expression (context_b, relation),
       "expression validator accepted a relation from another context");
    require
      (rejects_relation_construction
         (context,
          attribute_name,
          "+",
          operator_span,
          literal,
          relation_span),
       "relation accepted a non-relational operator spelling");

    declare
      malformed : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.Testing.create_relation_unchecked
          (context,
           attribute_name,
           "=",
           misplaced_operator_span,
           literal,
           relation_span);
    begin
      require
        (not accepts_expression (context, malformed),
         "expression validator accepted an out-of-order operator span");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "membership-expression.adb");
    form_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Form");
    a_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "A");
    b_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "B");
    form_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 4));
    not_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 8));
    in_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 11));
    a_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 13),
         Adac.Source.make_position (file_id, 1, 13));
    b_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 17));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 17));
    form_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, form_symbol, form_span);
    a_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, a_symbol, a_span);
    b_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, b_symbol, b_span);
    choices : Adac.AST.Node_List;
    membership : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (choices, a_name);
    Adac.AST.append (choices, b_name);
    membership := Adac.Compilation.Syntax.create_membership_expression
      (context,
       form_name,
       Adac.AST.Not_In_Membership_Operator,
       not_span,
       in_span,
       choices,
       whole_span);
    Adac.Compilation.Syntax.validate_expression (context, membership);
    require
      (Adac.Compilation.Syntax.kind_of (context, membership) =
         Adac.AST.Membership_Expression_Node and then
       Adac.Compilation.Syntax.membership_tested_expression
         (context, membership) = form_name and then
       Adac.Compilation.Syntax.membership_operator (context, membership) =
         Adac.AST.Not_In_Membership_Operator and then
       Adac.Compilation.Syntax.membership_not_span (context, membership) =
         not_span and then
       Adac.Compilation.Syntax.membership_in_span (context, membership) =
         in_span and then
       Adac.Compilation.Syntax.membership_choice_count
         (context, membership) = 2 and then
       Adac.Compilation.Syntax.membership_choice_at
         (context, membership, 1) = a_name and then
       Adac.Compilation.Syntax.membership_choice_at
         (context, membership, 2) = b_name and then
       Adac.Compilation.Syntax.node_span (context, membership) = whole_span,
       "membership expression lost tested/operator/choice ownership");
    require
      (not accepts_expression (context_b, membership),
       "membership validator accepted a foreign expression");

    declare
      single_choices : Adac.AST.Node_List;
      simple_in_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 6),
           Adac.Source.make_position (file_id, 2, 7));
      tested_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 1),
           Adac.Source.make_position (file_id, 2, 4));
      choice_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 9),
           Adac.Source.make_position (file_id, 2, 9));
      simple_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 1),
           Adac.Source.make_position (file_id, 2, 9));
      tested_symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Symbols.intern (context, "Test");
      choice_symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Symbols.intern (context, "C");
      tested_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, tested_symbol, tested_span);
      choice_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, choice_symbol, choice_span);
      simple_membership : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      Adac.AST.append (single_choices, choice_name);
      simple_membership := Adac.Compilation.Syntax.create_membership_expression
        (context,
         tested_name,
         Adac.AST.In_Membership_Operator,
         Adac.Source.INVALID_SPAN,
         simple_in_span,
         single_choices,
         simple_span);
      Adac.Compilation.Syntax.validate_expression (context, simple_membership);
      require
        (Adac.Compilation.Syntax.membership_operator
           (context, simple_membership) =
             Adac.AST.In_Membership_Operator and then
         Adac.Compilation.Syntax.membership_not_span
           (context, simple_membership) = Adac.Source.INVALID_SPAN and then
         Adac.Compilation.Syntax.membership_choice_count
           (context, simple_membership) = 1,
         "plain in membership lost its source-form contract");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "membership-range-choice.adb");
    value_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "V");
    value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 1));
    in_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 3),
         Adac.Source.make_position (file_id, 1, 4));
    lower_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 8));
    range_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 11));
    upper_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 13),
         Adac.Source.make_position (file_id, 1, 15));
    choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 15));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 15));
    value_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, value_symbol, value_span);
    lower_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "'A'", lower_span);
    upper_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "'Z'", upper_span);
    range_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_membership_range_choice
        (context, lower_bound, range_span, upper_bound, choice_span);
    choices : Adac.AST.Node_List;
    membership : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.Compilation.Syntax.validate_membership_range_choice
      (context, range_choice);
    Adac.AST.append (choices, range_choice);
    membership := Adac.Compilation.Syntax.create_membership_expression
      (context,
       value_name,
       Adac.AST.In_Membership_Operator,
       Adac.Source.INVALID_SPAN,
       in_span,
       choices,
       whole_span);
    Adac.Compilation.Syntax.validate_expression (context, membership);
    require
      (Adac.Compilation.Syntax.kind_of (context, range_choice) =
         Adac.AST.Membership_Range_Choice_Node and then
       Adac.Compilation.Syntax.membership_range_choice_lower_bound
         (context, range_choice) = lower_bound and then
       Adac.Compilation.Syntax.membership_range_choice_range_span
         (context, range_choice) = range_span and then
       Adac.Compilation.Syntax.membership_range_choice_upper_bound
         (context, range_choice) = upper_bound and then
       Adac.Compilation.Syntax.node_span (context, range_choice) = choice_span,
       "membership range choice lost bound/delimiter ownership");
    require
      (Adac.Compilation.Syntax.membership_choice_count
         (context, membership) = 1 and then
       Adac.Compilation.Syntax.membership_choice_at
         (context, membership, 1) = range_choice and then
       Adac.Compilation.Syntax.node_span (context, membership) = whole_span,
       "membership expression lost explicit-range choice ownership");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "if-tree.adb");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 4),
         Adac.Source.make_position (file_id, 1, 8));
    then_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 7));
    no_else_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 7));
    else_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 3),
         Adac.Source.make_position (file_id, 4, 9));
    if_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 5, 7));
    condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, condition_span);
    then_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, then_span);
    else_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Return_Statement_Node, else_span);
    then_statements : Adac.AST.Node_List;
    else_statements : Adac.AST.Node_List;
    reversed_then : Adac.AST.Node_List;
    reversed_else : Adac.AST.Node_List;
    empty_then : Adac.AST.Node_List;
    statement : Adac.AST.Node_ID;
    no_else_statement : Adac.AST.Node_ID;
  begin
    require
      (not Adac.Compilation.Syntax.return_has_expression
         (context, else_statement),
       "bare return statement unexpectedly acquired an expression");
    Adac.AST.append (then_statements, then_statement);
    Adac.AST.append (else_statements, else_statement);
    statement := Adac.Compilation.Syntax.create_if_statement
      (context, condition, then_statements, empty_elsif_parts,
       else_statements, if_span);
    Adac.Compilation.Syntax.validate_if_statement (context, statement);
    require
      (Adac.Compilation.Syntax.kind_of (context, statement) =
       Adac.AST.If_Statement_Node,
       "if statement has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.if_condition (context, statement) = condition,
       "if statement lost its condition");
    require
      (Adac.Compilation.Syntax.if_then_statement_count
         (context, statement) = 1 and then
       Adac.Compilation.Syntax.if_then_statement_at
         (context, statement, 1) = then_statement,
       "if statement lost its then branch");
    require
      (Adac.Compilation.Syntax.if_else_statement_count
         (context, statement) = 1 and then
       Adac.Compilation.Syntax.if_else_statement_at
         (context, statement, 1) = else_statement,
       "if statement lost its else branch");
    require
      (Adac.Compilation.Syntax.node_span (context, statement) = if_span,
       "if statement lost its complete span");
    require
      (not accepts_if_statement (context_b, statement),
       "if validator accepted another context's node");

    declare
      no_else : Adac.AST.Node_List;
    begin
      no_else_statement := Adac.Compilation.Syntax.create_if_statement
        (context, condition, then_statements, empty_elsif_parts,
         no_else, no_else_span);
    end;
    Adac.Compilation.Syntax.validate_if_statement
      (context, no_else_statement);
    require
      (Adac.Compilation.Syntax.if_else_statement_count
         (context, no_else_statement) = 0,
       "if without else gained an else branch");
    require
      (rejects_if_statement_construction
         (context, condition, empty_then, else_statements, if_span),
       "if statement accepted an empty then branch");

    Adac.AST.append (reversed_then, else_statement);
    Adac.AST.append (reversed_else, then_statement);
    declare
      malformed : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.Testing.create_if_statement_unchecked
          (context, condition, reversed_then, empty_elsif_parts,
           reversed_else, if_span);
    begin
      require
        (not accepts_if_statement (context, malformed),
         "if validator accepted out-of-order branches");
    end;

    declare
      foreign_file : constant Adac.Source.Source_File_ID :=
        Adac.Compilation.Sources.register_file (context_b, "foreign-if.adb");
      foreign_symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Symbols.intern (context_b, "Foreign");
      foreign_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (foreign_file, 1, 1),
           Adac.Source.make_position (foreign_file, 1, 7));
      foreign_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context_b, foreign_symbol, foreign_span);
      no_else : Adac.AST.Node_List;
    begin
      require
        (rejects_if_statement_construction
           (context,
            foreign_condition,
            then_statements,
            no_else,
            no_else_span),
         "if statement accepted a condition from another context");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "elsif-tree.adb");
    first_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "First");
    second_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Second");
    first_condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 4),
         Adac.Source.make_position (file_id, 1, 8));
    then_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 7));
    elsif_condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 7),
         Adac.Source.make_position (file_id, 3, 12));
    elsif_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 3),
         Adac.Source.make_position (file_id, 4, 9));
    elsif_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 1),
         Adac.Source.make_position (file_id, 4, 9));
    if_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 5, 7));
    first_condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, first_symbol, first_condition_span);
    then_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, then_span);
    elsif_condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, second_symbol, elsif_condition_span);
    elsif_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Return_Statement_Node, elsif_statement_span);
    then_statements : Adac.AST.Node_List;
    elsif_statements : Adac.AST.Node_List;
    elsif_parts : Adac.AST.Node_List;
    no_else : Adac.AST.Node_List;
    part : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (then_statements, then_statement);
    Adac.AST.append (elsif_statements, elsif_statement);
    part := Adac.Compilation.Syntax.create_elsif_part
      (context, elsif_condition, elsif_statements, elsif_span);
    Adac.Compilation.Syntax.validate_elsif_part (context, part);
    Adac.AST.append (elsif_parts, part);
    statement := Adac.Compilation.Syntax.create_if_statement
      (context,
       first_condition,
       then_statements,
       elsif_parts,
       no_else,
       if_span);
    Adac.Compilation.Syntax.validate_if_statement (context, statement);
    require
      (Adac.Compilation.Syntax.kind_of (context, part) =
         Adac.AST.Elsif_Part_Node and then
       Adac.Compilation.Syntax.elsif_condition (context, part) =
         elsif_condition and then
       Adac.Compilation.Syntax.elsif_statement_count
         (context, part) = 1 and then
       Adac.Compilation.Syntax.elsif_statement_at (context, part, 1) =
         elsif_statement and then
       Adac.Compilation.Syntax.if_elsif_part_count
         (context, statement) = 1 and then
       Adac.Compilation.Syntax.if_elsif_part_at (context, statement, 1) = part,
       "elsif syntax ownership was not preserved");

    declare
      empty_statements : Adac.AST.Node_List;
      before : constant Natural := Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
    begin
      begin
        part := Adac.Compilation.Syntax.create_elsif_part
          (context, elsif_condition, empty_statements, elsif_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then
         Adac.Compilation.Syntax.node_count (context) = before,
         "empty elsif part was published");
    end;

    declare
      empty_statements : Adac.AST.Node_List;
      malformed_parts : Adac.AST.Node_List;
      malformed_part : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.Testing.create_elsif_part_unchecked
          (context, elsif_condition, empty_statements, elsif_span);
      malformed_if : Adac.AST.Node_ID;
    begin
      Adac.AST.append (malformed_parts, malformed_part);
      malformed_if := Adac.Compilation.Syntax.create_if_statement
        (context,
         first_condition,
         then_statements,
         malformed_parts,
         no_else,
         if_span);
      require
        (not accepts_if_statement (context, malformed_if),
         "if validation did not traverse an invalid elsif part");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "nested-if-tree.adb");
    outer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    inner_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Inner");
    outer_condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 4),
         Adac.Source.make_position (file_id, 1, 8));
    inner_condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 6),
         Adac.Source.make_position (file_id, 2, 10));
    inner_child_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 5),
         Adac.Source.make_position (file_id, 3, 9));
    inner_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 4, 9));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 5, 7));
    outer_condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, outer_symbol, outer_condition_span);
    inner_condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, inner_symbol, inner_condition_span);
    inner_child : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, inner_child_span);
    inner_then : Adac.AST.Node_List;
    no_else : Adac.AST.Node_List;
    outer_then : Adac.AST.Node_List;
    inner_if : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    outer_if : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (inner_then, inner_child);
    inner_if := Adac.Compilation.Syntax.create_if_statement
      (context, inner_condition, inner_then, empty_elsif_parts,
       no_else, inner_span);
    Adac.AST.append (outer_then, inner_if);
    outer_if := Adac.Compilation.Syntax.create_if_statement
      (context, outer_condition, outer_then, empty_elsif_parts,
       no_else, outer_span);
    Adac.Compilation.Syntax.validate_if_statement (context, outer_if);

    require
      (Adac.Compilation.Syntax.if_then_statement_count
         (context, outer_if) = 1 and then
       Adac.Compilation.Syntax.if_then_statement_at
         (context, outer_if, 1) = inner_if and then
       Adac.Compilation.Syntax.kind_of (context, inner_if) =
         Adac.AST.If_Statement_Node,
       "nested if lost its inner statement ownership");
    require
      (not accepts_if_statement (context_b, outer_if),
       "nested if validator accepted another context's tree");

    declare
      malformed_condition_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 7, 6),
           Adac.Source.make_position (file_id, 7, 10));
      malformed_child_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 6, 10),
           Adac.Source.make_position (file_id, 6, 14));
      malformed_inner_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 7, 3),
           Adac.Source.make_position (file_id, 9, 9));
      malformed_outer_condition_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 6, 4),
           Adac.Source.make_position (file_id, 6, 8));
      malformed_outer_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 6, 1),
           Adac.Source.make_position (file_id, 10, 7));
      malformed_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, inner_symbol, malformed_condition_span);
      malformed_child : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_statement
          (context, Adac.AST.Null_Statement_Node, malformed_child_span);
      malformed_then : Adac.AST.Node_List;
      malformed_inner : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      malformed_outer_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, outer_symbol, malformed_outer_condition_span);
      malformed_outer_then : Adac.AST.Node_List;
      malformed_outer : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      Adac.AST.append (malformed_then, malformed_child);
      malformed_inner :=
        Adac.Compilation.Syntax.Testing.create_if_statement_unchecked
          (context,
           malformed_condition,
           malformed_then,
           empty_elsif_parts,
           no_else,
           malformed_inner_span);
      Adac.AST.append (malformed_outer_then, malformed_inner);
      malformed_outer := Adac.Compilation.Syntax.create_if_statement
        (context,
         malformed_outer_condition,
         malformed_outer_then,
         empty_elsif_parts,
         no_else,
         malformed_outer_span);
      require
        (not accepts_if_statement (context, malformed_outer),
         "nested if validation did not traverse an invalid inner node");
    end;
  end;

  declare
    depth : constant Positive := 128;
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "deep-if-tree.adb");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    conditions : Adac.AST.Node_List;
    no_else : Adac.AST.Node_List;
    child : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    for level in 1 .. depth loop
      declare
        condition_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, level, 4),
             Adac.Source.make_position (file_id, level, 8));
      begin
        Adac.AST.append
          (conditions,
           Adac.Compilation.Syntax.create_identifier_name
             (context, ready_symbol, condition_span));
      end;
    end loop;

    declare
      null_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, depth + 1, 3),
           Adac.Source.make_position (file_id, depth + 1, 7));
    begin
      child := Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, null_span);
    end;

    for level in reverse 1 .. depth loop
      declare
        then_statements : Adac.AST.Node_List;
        condition : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (conditions, level);
        end_line : constant Positive := 2 * depth - level + 2;
        if_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, level, 1),
             Adac.Source.make_position (file_id, end_line, 7));
      begin
        Adac.AST.append (then_statements, child);
        child := Adac.Compilation.Syntax.create_if_statement
          (context, condition, then_statements, empty_elsif_parts,
           no_else, if_span);
      end;
    end loop;

    Adac.Compilation.Syntax.validate_if_statement (context, child);
    require
      (Adac.Compilation.Syntax.kind_of (context, child) =
         Adac.AST.If_Statement_Node,
       "deep nested-if validation lost the root node");
  end;

  declare
    depth : constant Positive := 128;
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "deep-if-block-tree.adb");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    conditions : Adac.AST.Node_List;
    no_else : Adac.AST.Node_List;
    no_declarations : Adac.AST.Node_List;
    no_handlers : Adac.AST.Node_List;
    child : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    for level in 1 .. depth loop
      declare
        line : constant Positive := 3 * level - 2;
        condition_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, line, 4),
             Adac.Source.make_position (file_id, line, 8));
      begin
        Adac.AST.append
          (conditions,
           Adac.Compilation.Syntax.create_identifier_name
             (context, ready_symbol, condition_span));
      end;
    end loop;

    declare
      null_line : constant Positive := 3 * depth - 1;
      null_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, null_line, 3),
           Adac.Source.make_position (file_id, null_line, 7));
      deepest_then : Adac.AST.Node_List;
      deepest_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3 * depth - 2, 1),
           Adac.Source.make_position (file_id, 3 * depth, 7));
    begin
      Adac.AST.append
        (deepest_then,
         Adac.Compilation.Syntax.create_statement
           (context, Adac.AST.Null_Statement_Node, null_span));
      child := Adac.Compilation.Syntax.create_if_statement
        (context,
         Adac.AST.list_element (conditions, depth),
         deepest_then,
         empty_elsif_parts,
         no_else,
         deepest_span);
    end;

    for level in reverse 1 .. depth - 1 loop
      declare
        block_statements : Adac.AST.Node_List;
        then_statements : Adac.AST.Node_List;
        sequence : Adac.AST.Node_ID;
        block_statement : Adac.AST.Node_ID;
        child_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, child);
        block_start : constant Positive := 3 * level - 1;
        block_end : constant Positive :=
          3 * depth + 2 * (depth - level) - 1;
        if_start : constant Positive := 3 * level - 2;
        if_end : constant Positive :=
          3 * depth + 2 * (depth - level);
        block_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, block_start, 1),
             Adac.Source.make_position (file_id, block_end, 4));
        if_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, if_start, 1),
             Adac.Source.make_position (file_id, if_end, 7));
      begin
        Adac.AST.append (block_statements, child);
        sequence := Adac.Compilation.Syntax.create_handled_sequence
          (context, block_statements, no_handlers, child_span);
        block_statement := Adac.Compilation.Syntax.create_block_statement
          (context,
           no_declarations,
           sequence,
           block_span);
        Adac.AST.append (then_statements, block_statement);
        child := Adac.Compilation.Syntax.create_if_statement
          (context,
           Adac.AST.list_element (conditions, level),
           then_statements,
           empty_elsif_parts,
           no_else,
           if_span);
      end;
    end loop;

    Adac.Compilation.Syntax.validate_if_statement (context, child);
    require
      (Adac.Compilation.Syntax.kind_of (context, child) =
         Adac.AST.If_Statement_Node,
       "deep alternating if/block validation lost the root node");
  end;

  declare
    depth : constant Positive := 96;
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "deep-if-loop-case-tree.adb");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    items_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Items");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item");
    no_else : Adac.AST.Node_List;
    child : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    leaf_line : constant Positive := 4 * depth + 1;
  begin
    declare
      leaf_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, leaf_line, 3),
           Adac.Source.make_position (file_id, leaf_line, 7));
    begin
      child := Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, leaf_span);
    end;

    for level in reverse 1 .. depth loop
      declare
        base_line : constant Positive := 4 * (level - 1) + 1;
        case_end_line : constant Positive :=
          leaf_line + 3 * (depth - level) + 1;
        loop_end_line : constant Positive := case_end_line + 1;
        if_end_line : constant Positive := case_end_line + 2;
        condition_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line, 4),
             Adac.Source.make_position (file_id, base_line, 8));
        parameter_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line + 1, 5),
             Adac.Source.make_position (file_id, base_line + 1, 8));
        iterable_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line + 1, 12),
             Adac.Source.make_position (file_id, base_line + 1, 16));
        selecting_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line + 2, 6),
             Adac.Source.make_position (file_id, base_line + 2, 10));
        choice_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line + 3, 6),
             Adac.Source.make_position (file_id, base_line + 3, 10));
        child_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, child);
        alternative_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line + 3, 1),
             Adac.Source.last_position (child_span));
        case_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line + 2, 1),
             Adac.Source.make_position (file_id, case_end_line, 9));
        loop_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line + 1, 1),
             Adac.Source.make_position (file_id, loop_end_line, 9));
        if_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, base_line, 1),
             Adac.Source.make_position (file_id, if_end_line, 7));
        condition : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_identifier_name
            (context, ready_symbol, condition_span);
        iterable : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_identifier_name
            (context, items_symbol, iterable_span);
        selecting_expression : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_identifier_name
            (context, ready_symbol, selecting_span);
        choice : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_identifier_name
            (context, ready_symbol, choice_span);
        choices : Adac.AST.Node_List;
        alternative_statements : Adac.AST.Node_List;
        alternatives : Adac.AST.Node_List;
        loop_statements : Adac.AST.Node_List;
        then_statements : Adac.AST.Node_List;
        alternative : Adac.AST.Node_ID;
        case_statement : Adac.AST.Node_ID;
        loop_statement : Adac.AST.Node_ID;
      begin
        Adac.AST.append (choices, choice);
        Adac.AST.append (alternative_statements, child);
        alternative := Adac.Compilation.Syntax.create_case_alternative
          (context, choices, alternative_statements, alternative_span);
        Adac.AST.append (alternatives, alternative);
        case_statement := Adac.Compilation.Syntax.create_case_statement
          (context, selecting_expression, alternatives, case_span);
        Adac.AST.append (loop_statements, case_statement);
        loop_statement := Adac.Compilation.Syntax.create_loop_statement
          (context,
           parameter_symbol,
           parameter_span,
           False,
           iterable,
           loop_statements,
           loop_span);
        Adac.AST.append (then_statements, loop_statement);
        child := Adac.Compilation.Syntax.create_if_statement
          (context,
           condition,
           then_statements,
           empty_elsif_parts,
           no_else,
           if_span);
      end;
    end loop;

    Adac.Compilation.Syntax.validate_if_statement (context, child);
    require
      (Adac.Compilation.Syntax.kind_of (context, child) =
         Adac.AST.If_Statement_Node,
       "deep if/loop/case validation lost the root node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-if-loop-case-tree.adb");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    items_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Items");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item");
    bad_condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 5, 4),
         Adac.Source.make_position (file_id, 5, 8));
    bad_child_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 3),
         Adac.Source.make_position (file_id, 6, 7));
    bad_if_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 5, 1),
         Adac.Source.make_position (file_id, 7, 7));
    choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 6),
         Adac.Source.make_position (file_id, 4, 10));
    alternative_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 1),
         Adac.Source.make_position (file_id, 7, 7));
    selecting_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 6),
         Adac.Source.make_position (file_id, 3, 10));
    case_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 1),
         Adac.Source.make_position (file_id, 8, 9));
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 5),
         Adac.Source.make_position (file_id, 2, 8));
    iterable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 12),
         Adac.Source.make_position (file_id, 2, 16));
    loop_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 9, 9));
    outer_condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 4),
         Adac.Source.make_position (file_id, 1, 8));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 10, 7));
    bad_condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_statement_unchecked
        (context, Adac.AST.Null_Statement_Node, bad_condition_span);
    bad_child : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, bad_child_span);
    bad_then : Adac.AST.Node_List;
    no_else : Adac.AST.Node_List;
    bad_if : Adac.AST.Node_ID;
    choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, choice_span);
    choices : Adac.AST.Node_List;
    alternative_statements : Adac.AST.Node_List;
    alternative : Adac.AST.Node_ID;
    alternatives : Adac.AST.Node_List;
    selecting_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, selecting_span);
    case_statement : Adac.AST.Node_ID;
    iterable : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, items_symbol, iterable_span);
    loop_statements : Adac.AST.Node_List;
    loop_statement : Adac.AST.Node_ID;
    outer_condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, outer_condition_span);
    outer_then : Adac.AST.Node_List;
    outer_if : Adac.AST.Node_ID;
  begin
    Adac.AST.append (bad_then, bad_child);
    bad_if := Adac.Compilation.Syntax.Testing.create_if_statement_unchecked
      (context,
       bad_condition,
       bad_then,
       empty_elsif_parts,
       no_else,
       bad_if_span);
    Adac.AST.append (choices, choice);
    Adac.AST.append (alternative_statements, bad_if);
    alternative := Adac.Compilation.Syntax.create_case_alternative
      (context, choices, alternative_statements, alternative_span);
    Adac.AST.append (alternatives, alternative);
    case_statement := Adac.Compilation.Syntax.create_case_statement
      (context, selecting_expression, alternatives, case_span);
    Adac.AST.append (loop_statements, case_statement);
    loop_statement := Adac.Compilation.Syntax.create_loop_statement
      (context,
       parameter_symbol,
       parameter_span,
       False,
       iterable,
       loop_statements,
       loop_span);
    Adac.AST.append (outer_then, loop_statement);
    outer_if := Adac.Compilation.Syntax.create_if_statement
      (context,
       outer_condition,
       outer_then,
       empty_elsif_parts,
       no_else,
       outer_span);
    require
      (not accepts_if_statement (context, outer_if),
       "mixed compound validator missed a malformed nested if");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "handled-tree.adb");
    ordinary_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 8),
         Adac.Source.make_position (file_id, 3, 13));
    body_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 5),
         Adac.Source.make_position (file_id, 4, 9));
    bare_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 5, 5),
         Adac.Source.make_position (file_id, 5, 10));
    handler_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 3),
         Adac.Source.make_position (file_id, 5, 10));
    sequence_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 5, 10));
    ordinary : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, ordinary_span);
    choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_others_exception_choice
        (context, choice_span);
    body_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, body_span);
    bare_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_bare_raise_statement
        (context, bare_span);
    choices, body_statements : Adac.AST.Node_List;
    ordinary_statements, handlers : Adac.AST.Node_List;
    handler, sequence : Adac.AST.Node_ID;
    empty : Adac.AST.Node_List;
  begin
    Adac.AST.append (choices, choice);
    Adac.AST.append (body_statements, body_statement);
    Adac.AST.append (body_statements, bare_statement);
    handler := Adac.Compilation.Syntax.create_exception_handler
      (context,
       Adac.Symbols.INVALID_SYMBOL_ID,
       Adac.Source.INVALID_SPAN,
       choices,
       body_statements,
       handler_span);
    Adac.AST.append (ordinary_statements, ordinary);
    Adac.AST.append (handlers, handler);
    sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, ordinary_statements, handlers, sequence_span);
    Adac.Compilation.Syntax.validate_exception_handler (context, handler);
    Adac.Compilation.Syntax.validate_handled_sequence (context, sequence);
    require
      (not Adac.Compilation.Syntax.exception_handler_has_choice_parameter
         (context, handler) and then
       Adac.Compilation.Syntax.exception_handler_choice_parameter_symbol
         (context, handler) = Adac.Symbols.INVALID_SYMBOL_ID,
       "handler without a choice parameter gained one");
    require
      (Adac.Compilation.Syntax.kind_of (context, choice) =
         Adac.AST.Others_Exception_Choice_Node and then
       Adac.Compilation.Syntax.exception_handler_choice_count
         (context, handler) = 1 and then
       Adac.Compilation.Syntax.exception_handler_choice_at
         (context, handler, 1) = choice,
       "exception handler lost its others choice");
    require
      (Adac.Compilation.Syntax.exception_handler_statement_count
         (context, handler) = 2 and then
       Adac.Compilation.Syntax.exception_handler_statement_at
         (context, handler, 1) = body_statement and then
       Adac.Compilation.Syntax.exception_handler_statement_at
         (context, handler, 2) = bare_statement,
       "exception handler lost its body statements");
    case Adac.Compilation.Syntax.raise_form (context, bare_statement) is
      when Adac.AST.Bare_Reraise_Form =>
        null;
      when Adac.AST.Named_With_Message_Raise_Form =>
        raise Program_Error with "handler bare re-raise lost source form";
    end case;
    require
      (Adac.Compilation.Syntax.handled_sequence_statement_count
         (context, sequence) = 1 and then
       Adac.Compilation.Syntax.handled_sequence_statement_at
         (context, sequence, 1) = ordinary and then
       Adac.Compilation.Syntax.handled_sequence_handler_count
         (context, sequence) = 1 and then
       Adac.Compilation.Syntax.handled_sequence_handler_at
         (context, sequence, 1) = handler,
       "handled sequence lost ordered children");
    require
      (not accepts_exception_handler (context_b, handler) and then
       not accepts_handled_sequence (context_b, sequence),
       "handler syntax crossed compilation contexts");
    require
      (rejects_exception_handler_construction
         (context, empty, body_statements, handler_span) and then
       rejects_exception_handler_construction
         (context, choices, empty, handler_span),
       "exception handler accepted an empty required list");
    require
      (rejects_handled_sequence_construction
         (context, empty, handlers, sequence_span),
       "handled sequence accepted an empty statement list");
    declare
      wrong_body : Adac.AST.Node_List;
      malformed_handler : Adac.AST.Node_ID;
      malformed_sequence : Adac.AST.Node_ID;
    begin
      Adac.AST.append (wrong_body, ordinary);
      malformed_handler :=
        Adac.Compilation.Syntax.Testing.create_exception_handler_unchecked
          (context, choices, wrong_body, handler_span);
      require
        (not accepts_exception_handler (context, malformed_handler),
         "handler validator accepted an out-of-span body");
      malformed_sequence :=
        Adac.Compilation.Syntax.Testing.create_handled_sequence_unchecked
          (context, body_statements, handlers, sequence_span);
      require
        (not accepts_handled_sequence (context, malformed_sequence),
         "handled validator accepted children in reverse source order");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "choice-parameter-handler.adb");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Error");
    ada_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ada");
    io_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "IO_Exceptions");
    name_error_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Name_Error");
    other_error_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Other_Error");
    foreign_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context_b, "Foreign_Error");
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 10));
    ada_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 14),
         Adac.Source.make_position (file_id, 1, 16));
    io_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 18),
         Adac.Source.make_position (file_id, 1, 30));
    first_choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 14),
         Adac.Source.make_position (file_id, 1, 41));
    first_selector_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 32),
         Adac.Source.make_position (file_id, 1, 41));
    second_choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 45),
         Adac.Source.make_position (file_id, 1, 55));
    body_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 5),
         Adac.Source.make_position (file_id, 2, 9));
    handler_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 2, 9));
    ada_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ada_symbol, ada_span);
    io_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_selected_name
        (context,
         ada_name,
         io_symbol,
         io_span,
         Adac.Source.make_span
           (Adac.Source.first_position (ada_span),
            Adac.Source.last_position (io_span)));
    first_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_selected_name
        (context,
         io_name,
         name_error_symbol,
         first_selector_span,
         first_choice_span);
    second_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, other_error_symbol, second_choice_span);
    body_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, body_span);
    choices, statements : Adac.AST.Node_List;
    handler : Adac.AST.Node_ID;
  begin
    Adac.AST.append (choices, first_choice);
    Adac.AST.append (choices, second_choice);
    Adac.AST.append (statements, body_statement);
    handler := Adac.Compilation.Syntax.create_exception_handler
      (context,
       parameter_symbol,
       parameter_span,
       choices,
       statements,
       handler_span);
    Adac.Compilation.Syntax.validate_exception_handler (context, handler);
    require
      (Adac.Compilation.Syntax.exception_handler_has_choice_parameter
         (context, handler) and then
       Adac.Compilation.Syntax.exception_handler_choice_parameter_symbol
         (context, handler) = parameter_symbol and then
       Adac.Compilation.Syntax.exception_handler_choice_parameter_span
         (context, handler) = parameter_span,
       "exception handler lost its choice parameter");
    require
      (Adac.Compilation.Syntax.exception_handler_choice_count
         (context, handler) = 2 and then
       Adac.Compilation.Syntax.exception_handler_choice_at
         (context, handler, 1) = first_choice and then
       Adac.Compilation.Syntax.exception_handler_choice_at
         (context, handler, 2) = second_choice,
       "exception handler lost ordered named choices");
    require
      (rejects_exception_handler_construction
         (context,
          choices,
          statements,
          handler_span,
          foreign_symbol,
          parameter_span),
       "exception handler accepted a foreign choice-parameter symbol");
    require
      (rejects_exception_handler_construction
         (context,
          choices,
          statements,
          handler_span,
          Adac.Symbols.INVALID_SYMBOL_ID,
          parameter_span),
       "absent choice parameter accepted a defining span");
    declare
      wrong_choices : Adac.AST.Node_List;
    begin
      Adac.AST.append (wrong_choices, body_statement);
      require
        (rejects_exception_handler_construction
           (context, wrong_choices, statements, handler_span),
         "exception handler accepted a statement as a choice");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "assignment-statement-tree.adb");
    target_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "module");
    expression_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value");
    target_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    expression_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 11),
         Adac.Source.make_position (file_id, 1, 15));
    statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 16));
    target : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, target_symbol, target_span);
    expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, expression_symbol, expression_span);
    statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_assignment_statement
        (context, target, expression, statement_span);
  begin
    Adac.Compilation.Syntax.validate_assignment_statement (context, statement);
    require
      (Adac.Compilation.Syntax.node_count (context) = 3,
       "assignment construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, statement) =
       Adac.AST.Assignment_Statement_Node,
       "assignment has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.assignment_target (context, statement) = target,
       "assignment lost its target");
    require
      (Adac.Compilation.Syntax.assignment_expression (context, statement) =
       expression,
       "assignment lost its RHS expression");
    require
      (Adac.Compilation.Syntax.node_span (context, statement) = statement_span,
       "assignment lost its complete statement span");
    require
      (not accepts_assignment_statement (context_b, statement),
       "assignment validator accepted another context's node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "case-block-tree.adb");
    local_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "local");
    type_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Type");
    selecting_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Status");
    first_choice_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Rejected");
    second_choice_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Succeeded");
    local_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 13));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 20));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 21));
    selecting_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 6),
         Adac.Source.make_position (file_id, 2, 11));
    first_choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 6),
         Adac.Source.make_position (file_id, 3, 13));
    first_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 18),
         Adac.Source.make_position (file_id, 3, 22));
    first_alternative_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 1),
         Adac.Source.make_position (file_id, 3, 22));
    second_choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 6),
         Adac.Source.make_position (file_id, 4, 14));
    second_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 19),
         Adac.Source.make_position (file_id, 4, 25));
    second_alternative_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 1),
         Adac.Source.make_position (file_id, 4, 25));
    case_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 5, 9));
    block_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 6, 4));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, type_symbol, subtype_span);
    block_declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_object_declaration
        (context,
         Adac.AST.Variable_Object_Form,
         local_symbol,
         local_defining_span,
         subtype_mark,
         Adac.AST.INVALID_NODE_ID,
         declaration_span);
    selecting_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, selecting_symbol, selecting_span);
    first_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, first_choice_symbol, first_choice_span);
    first_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, first_statement_span);
    second_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, second_choice_symbol, second_choice_span);
    second_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Return_Statement_Node, second_statement_span);
    first_choices : Adac.AST.Node_List;
    first_statements : Adac.AST.Node_List;
    second_choices : Adac.AST.Node_List;
    second_statements : Adac.AST.Node_List;
    alternatives : Adac.AST.Node_List;
    handled_statements : Adac.AST.Node_List;
    handlers : Adac.AST.Node_List;
    declarations : Adac.AST.Node_List;
    first_alternative : Adac.AST.Node_ID;
    second_alternative : Adac.AST.Node_ID;
    case_statement : Adac.AST.Node_ID;
    handled_sequence : Adac.AST.Node_ID;
    block_statement : Adac.AST.Node_ID;
  begin
    Adac.AST.append (first_choices, first_choice);
    Adac.AST.append (first_statements, first_statement);
    first_alternative := Adac.Compilation.Syntax.create_case_alternative
      (context, first_choices, first_statements, first_alternative_span);
    Adac.AST.append (second_choices, second_choice);
    Adac.AST.append (second_statements, second_statement);
    second_alternative := Adac.Compilation.Syntax.create_case_alternative
      (context, second_choices, second_statements, second_alternative_span);
    Adac.AST.append (alternatives, first_alternative);
    Adac.AST.append (alternatives, second_alternative);
    case_statement := Adac.Compilation.Syntax.create_case_statement
      (context, selecting_expression, alternatives, case_span);
    Adac.AST.append (handled_statements, case_statement);
    handled_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, handled_statements, handlers, case_span);
    Adac.AST.append (declarations, block_declaration);
    block_statement := Adac.Compilation.Syntax.create_block_statement
      (context, declarations, handled_sequence, block_span);

    Adac.Compilation.Syntax.validate_case_alternative
      (context, first_alternative);
    Adac.Compilation.Syntax.validate_case_statement (context, case_statement);
    Adac.Compilation.Syntax.validate_block_statement (context, block_statement);
    require
      (Adac.Compilation.Syntax.node_count (context) = 12,
       "case/block construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.case_alternative_choice_count
         (context, first_alternative) = 1 and then
       Adac.Compilation.Syntax.case_alternative_choice_at
         (context, first_alternative, 1) = first_choice and then
       Adac.Compilation.Syntax.case_alternative_statement_count
         (context, first_alternative) = 1 and then
       Adac.Compilation.Syntax.case_alternative_statement_at
         (context, first_alternative, 1) = first_statement,
       "case alternative lost its ordered children");
    require
      (Adac.Compilation.Syntax.case_selecting_expression
         (context, case_statement) = selecting_expression and then
       Adac.Compilation.Syntax.case_alternative_count
         (context, case_statement) = 2 and then
       Adac.Compilation.Syntax.case_alternative_at
         (context, case_statement, 1) = first_alternative and then
       Adac.Compilation.Syntax.case_alternative_at
         (context, case_statement, 2) = second_alternative,
       "case statement lost its selecting expression or alternatives");
    require
      (Adac.Compilation.Syntax.block_declaration_count
         (context, block_statement) = 1 and then
       Adac.Compilation.Syntax.block_declaration_at
         (context, block_statement, 1) = block_declaration and then
       Adac.Compilation.Syntax.block_handled_sequence
         (context, block_statement) = handled_sequence,
       "block statement lost its declaration or handled sequence");
    require
      (Adac.Compilation.Syntax.node_span
         (context, block_statement) = block_span,
       "block statement lost its complete span");
    require
      (not accepts_case_alternative (context_b, first_alternative) and then
       not accepts_case_statement (context_b, case_statement) and then
       not accepts_block_statement (context_b, block_statement),
       "case/block validators accepted another context's nodes");
    declare
      no_choices : Adac.AST.Node_List;
      no_alternatives : Adac.AST.Node_List;
      wrong_declarations : Adac.AST.Node_List;
      wrong_handled_statements : Adac.AST.Node_List;
      wrong_sequence : Adac.AST.Node_ID;
    begin
      Adac.AST.append (wrong_declarations, selecting_expression);
      Adac.AST.append (wrong_handled_statements, first_statement);
      wrong_sequence := Adac.Compilation.Syntax.create_handled_sequence
        (context,
         wrong_handled_statements,
         handlers,
         first_statement_span);
      require
        (rejects_case_alternative_construction
           (context, no_choices, first_statements, first_alternative_span),
         "case alternative accepted an empty choice list");
      require
        (rejects_case_statement_construction
           (context, selecting_expression, no_alternatives, case_span),
         "case statement accepted an empty alternative list");
      require
        (rejects_block_statement_construction
           (context, wrong_declarations, handled_sequence, block_span),
         "block statement accepted a nondeclaration child");
      require
        (rejects_block_statement_construction
           (context, declarations, wrong_sequence, block_span),
         "block statement accepted a non-case-or-call handled body");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "case-choices-and-raise.adb");
    selecting_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Kind");
    first_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "First");
    second_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Second");
    error_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Program_Error");
    selecting_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 9));
    first_choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 6),
         Adac.Source.make_position (file_id, 2, 10));
    second_choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 14),
         Adac.Source.make_position (file_id, 2, 19));
    first_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 24),
         Adac.Source.make_position (file_id, 2, 28));
    first_alternative_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.last_position (first_statement_span));
    others_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 6),
         Adac.Source.make_position (file_id, 3, 11));
    error_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 22),
         Adac.Source.make_position (file_id, 3, 34));
    message_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 41),
         Adac.Source.make_position (file_id, 3, 45));
    raise_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 16),
         Adac.Source.make_position (file_id, 3, 46));
    second_alternative_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 1),
         Adac.Source.last_position (raise_span));
    case_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 4, 9));
    selecting_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, selecting_symbol, selecting_span);
    first_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, first_symbol, first_choice_span);
    second_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, second_symbol, second_choice_span);
    first_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, first_statement_span);
    others_choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_others_case_choice
        (context, others_span);
    error_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, error_symbol, error_span);
    message : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_string_literal
        (context, """bad""", message_span);
    raise_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_raise_statement
        (context, error_name, message, raise_span);
    first_choices : Adac.AST.Node_List;
    first_statements : Adac.AST.Node_List;
    second_choices : Adac.AST.Node_List;
    second_statements : Adac.AST.Node_List;
    alternatives : Adac.AST.Node_List;
    first_alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    second_alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (first_choices, first_choice);
    Adac.AST.append (first_choices, second_choice);
    Adac.AST.append (first_statements, first_statement);
    first_alternative := Adac.Compilation.Syntax.create_case_alternative
      (context, first_choices, first_statements, first_alternative_span);

    Adac.AST.append (second_choices, others_choice);
    Adac.AST.append (second_statements, raise_statement);
    second_alternative := Adac.Compilation.Syntax.create_case_alternative
      (context, second_choices, second_statements, second_alternative_span);
    Adac.AST.append (alternatives, first_alternative);
    Adac.AST.append (alternatives, second_alternative);
    statement := Adac.Compilation.Syntax.create_case_statement
      (context, selecting_expression, alternatives, case_span);

    Adac.Compilation.Syntax.validate_case_statement (context, statement);
    require
      (Adac.Compilation.Syntax.case_alternative_choice_count
         (context, first_alternative) = 2 and then
       Adac.Compilation.Syntax.kind_of (context, others_choice) =
         Adac.AST.Others_Case_Choice_Node and then
       Adac.Compilation.Syntax.kind_of
         (context,
          Adac.Compilation.Syntax.case_alternative_statement_at
            (context, second_alternative, 1)) = Adac.AST.Raise_Statement_Node,
       "case alternative lost multiple choices, others, or raise syntax");

    declare
      invalid_choices : Adac.AST.Node_List;
    begin
      Adac.AST.append (invalid_choices, others_choice);
      Adac.AST.append (invalid_choices, first_choice);
      require
        (rejects_case_alternative_construction
           (context,
            invalid_choices,
            first_statements,
            first_alternative_span),
         "case alternative accepted non-sole others choice");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "call-block-tree.adb");
    call_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    callable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 5));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 6));
    block_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 4));
    callable_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, call_symbol, callable_span);
    actuals : Adac.AST.Node_List;
    statements : Adac.AST.Node_List;
    handlers : Adac.AST.Node_List;
    declarations : Adac.AST.Node_List;
    call_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_call_statement
        (context, callable_name, actuals, call_span);
    handled_sequence : Adac.AST.Node_ID;
    block_statement : Adac.AST.Node_ID;
  begin
    Adac.AST.append (statements, call_statement);
    handled_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, statements, handlers, call_span);
    block_statement := Adac.Compilation.Syntax.create_block_statement
      (context, declarations, handled_sequence, block_span);
    Adac.Compilation.Syntax.validate_block_statement (context, block_statement);
    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "call block construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.block_handled_sequence
         (context, block_statement) = handled_sequence and then
       Adac.Compilation.Syntax.handled_sequence_statement_count
         (context, handled_sequence) = 1 and then
       Adac.Compilation.Syntax.handled_sequence_statement_at
         (context, handled_sequence, 1) = call_statement,
       "call block lost its represented body statement");
    require
      (Adac.Compilation.Syntax.node_span
         (context, block_statement) = block_span,
       "call block lost its complete span");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "mixed-block-tree.adb");
    run_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    target_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "X");
    value_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Y");
    call_name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 5));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 6));
    condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 6),
         Adac.Source.make_position (file_id, 3, 10));
    null_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 5),
         Adac.Source.make_position (file_id, 4, 9));
    if_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 3),
         Adac.Source.make_position (file_id, 5, 9));
    target_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 3),
         Adac.Source.make_position (file_id, 6, 3));
    value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 8),
         Adac.Source.make_position (file_id, 6, 8));
    assignment_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 3),
         Adac.Source.make_position (file_id, 6, 9));
    sequence_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 6, 9));
    block_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 7, 4));
    call_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, run_symbol, call_name_span);
    actuals : Adac.AST.Node_List;
    call_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_call_statement
        (context, call_name, actuals, call_span);
    condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, condition_span);
    null_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, null_span);
    then_statements : Adac.AST.Node_List;
    else_statements : Adac.AST.Node_List;
    if_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    target : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, target_symbol, target_span);
    value : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, value_symbol, value_span);
    assignment : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_assignment_statement
        (context, target, value, assignment_span);
    statements : Adac.AST.Node_List;
    handlers : Adac.AST.Node_List;
    declarations : Adac.AST.Node_List;
    handled_sequence : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    block_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (then_statements, null_statement);
    if_statement := Adac.Compilation.Syntax.create_if_statement
      (context,
       condition,
       then_statements,
       empty_elsif_parts,
       else_statements,
       if_span);
    Adac.AST.append (statements, call_statement);
    Adac.AST.append (statements, if_statement);
    Adac.AST.append (statements, assignment);
    handled_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, statements, handlers, sequence_span);
    block_statement := Adac.Compilation.Syntax.create_block_statement
      (context, declarations, handled_sequence, block_span);
    Adac.Compilation.Syntax.validate_block_statement (context, block_statement);

    require
      (Adac.Compilation.Syntax.node_count (context) = 10,
       "mixed block construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.handled_sequence_statement_count
         (context, handled_sequence) = 3 and then
       Adac.Compilation.Syntax.handled_sequence_statement_at
         (context, handled_sequence, 1) = call_statement and then
       Adac.Compilation.Syntax.handled_sequence_statement_at
         (context, handled_sequence, 2) = if_statement and then
       Adac.Compilation.Syntax.handled_sequence_statement_at
         (context, handled_sequence, 3) = assignment,
       "mixed block lost call, if, or assignment statement order");
    require
      (Adac.Compilation.Syntax.block_handled_sequence
         (context, block_statement) = handled_sequence,
       "mixed block lost its handled sequence");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "iterator-loop-tree.adb");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item");
    items_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Items");
    values_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Values");
    run_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    check_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Check");
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 8));
    items_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 25));
    values_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 32));
    iterable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 32));
    call_name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 5));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 6));
    condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 6),
         Adac.Source.make_position (file_id, 3, 10));
    null_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 5),
         Adac.Source.make_position (file_id, 4, 9));
    if_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 3),
         Adac.Source.make_position (file_id, 5, 9));
    block_call_name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 8, 5),
         Adac.Source.make_position (file_id, 8, 9));
    block_call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 8, 5),
         Adac.Source.make_position (file_id, 8, 10));
    block_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 3),
         Adac.Source.make_position (file_id, 9, 6));
    assignment_target_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 10, 3),
         Adac.Source.make_position (file_id, 10, 7));
    assignment_value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 10, 12),
         Adac.Source.make_position (file_id, 10, 14));
    assignment_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 10, 3),
         Adac.Source.make_position (file_id, 10, 15));
    loop_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 11, 9));
    items_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, items_symbol, items_span);
    iterable_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_selected_name
        (context,
         items_name,
         values_symbol,
         values_span,
         iterable_span);
    call_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, run_symbol, call_name_span);
    no_actuals : Adac.AST.Node_List;
    call_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_call_statement
        (context, call_name, no_actuals, call_span);
    condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, condition_span);
    null_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, null_span);
    then_statements : Adac.AST.Node_List;
    else_statements : Adac.AST.Node_List;
    if_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    block_call_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, check_symbol, block_call_name_span);
    block_call : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_call_statement
        (context, block_call_name, no_actuals, block_call_span);
    block_statements : Adac.AST.Node_List;
    block_handlers : Adac.AST.Node_List;
    block_declarations : Adac.AST.Node_List;
    block_sequence : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    block_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    assignment_target : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, assignment_target_span);
    assignment_value : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, run_symbol, assignment_value_span);
    assignment : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_assignment_statement
        (context, assignment_target, assignment_value, assignment_span);
    loop_statements : Adac.AST.Node_List;
    loop_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (then_statements, null_statement);
    if_statement := Adac.Compilation.Syntax.create_if_statement
      (context, condition, then_statements, empty_elsif_parts,
       else_statements, if_span);
    Adac.AST.append (block_statements, block_call);
    block_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, block_statements, block_handlers, block_call_span);
    block_statement := Adac.Compilation.Syntax.create_block_statement
      (context, block_declarations, block_sequence, block_span);
    Adac.AST.append (loop_statements, call_statement);
    Adac.AST.append (loop_statements, if_statement);
    Adac.AST.append (loop_statements, block_statement);
    Adac.AST.append (loop_statements, assignment);
    loop_statement := Adac.Compilation.Syntax.create_loop_statement
      (context,
       parameter_symbol,
       parameter_span,
       True,
       iterable_name,
       loop_statements,
       loop_span);
    Adac.Compilation.Syntax.validate_loop_statement (context, loop_statement);

    require
      (Adac.Compilation.Syntax.node_count (context) = 15,
       "iterator-loop construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, loop_statement) =
         Adac.AST.Loop_Statement_Node and then
       Adac.Compilation.Syntax.loop_form (context, loop_statement) =
         Adac.AST.Generalized_Iterator_Loop_Form and then
       Adac.Compilation.Syntax.loop_parameter_symbol
         (context, loop_statement) = parameter_symbol and then
       Adac.Compilation.Syntax.loop_parameter_span
         (context, loop_statement) = parameter_span and then
       Adac.Compilation.Syntax.loop_is_reverse
         (context, loop_statement) and then
       Adac.Compilation.Syntax.loop_iterable_name
         (context, loop_statement) = iterable_name,
       "iterator loop lost its header syntax");
    require
      (Adac.Compilation.Syntax.loop_statement_count
         (context, loop_statement) = 4 and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, loop_statement, 1) = call_statement and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, loop_statement, 2) = if_statement and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, loop_statement, 3) = block_statement and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, loop_statement, 4) = assignment and then
       Adac.Compilation.Syntax.node_span (context, loop_statement) = loop_span,
       "iterator loop lost its ordered body or complete span");
    require
      (not accepts_loop_statement (context_b, loop_statement),
       "iterator-loop validator accepted another context's node");

    declare
      empty_body : Adac.AST.Node_List;
      wrong_body : Adac.AST.Node_List;
    begin
      Adac.AST.append (wrong_body, null_statement);
      require
        (rejects_loop_statement_construction
           (context,
            parameter_symbol,
            parameter_span,
            False,
            iterable_name,
            empty_body,
            loop_span),
         "iterator loop accepted an empty body");
      require
        (rejects_loop_statement_construction
           (context,
            parameter_symbol,
            parameter_span,
            False,
            iterable_name,
            wrong_body,
            loop_span),
         "iterator loop accepted a noncurrent body statement");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "discrete-range-loop-tree.adb");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Index");
    upper_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Limit");
    run_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 9));
    lower_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 22));
    upper_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 31));
    call_name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 5));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 6));
    loop_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 11));
    lower_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "1", lower_span);
    upper_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, upper_symbol, upper_span);
    call_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, run_symbol, call_name_span);
    no_actuals : Adac.AST.Node_List;
    call_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_call_statement
        (context, call_name, no_actuals, call_span);
    statements : Adac.AST.Node_List;
    loop_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (statements, call_statement);
    loop_statement :=
      Adac.Compilation.Syntax.create_discrete_range_loop_statement
        (context,
         parameter_symbol,
         parameter_span,
         True,
         lower_bound,
         upper_bound,
         statements,
         loop_span);
    Adac.Compilation.Syntax.validate_loop_statement (context, loop_statement);

    require
      (Adac.Compilation.Syntax.node_count (context) = 5 and then
       Adac.Compilation.Syntax.loop_form (context, loop_statement) =
         Adac.AST.Discrete_Range_Loop_Form and then
       Adac.Compilation.Syntax.loop_parameter_symbol
         (context, loop_statement) = parameter_symbol and then
       Adac.Compilation.Syntax.loop_parameter_span
         (context, loop_statement) = parameter_span and then
       Adac.Compilation.Syntax.loop_is_reverse
         (context, loop_statement) and then
       Adac.Compilation.Syntax.loop_range_lower_bound
         (context, loop_statement) = lower_bound and then
       Adac.Compilation.Syntax.loop_range_upper_bound
         (context, loop_statement) = upper_bound and then
       Adac.Compilation.Syntax.loop_statement_count
         (context, loop_statement) = 1 and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, loop_statement, 1) = call_statement,
       "discrete-range loop lost its header/body syntax");
    require
      (not accepts_loop_statement (context_b, loop_statement),
       "discrete-range loop validator accepted another context's node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "range-attribute-loop-tree.adb");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Index");
    arguments_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Arguments");
    range_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Range");
    run_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 9));
    arguments_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 30));
    range_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 32),
         Adac.Source.make_position (file_id, 1, 36));
    attribute_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 36));
    call_name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 5));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 6));
    loop_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 11));
    arguments_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, arguments_symbol, arguments_span);
    range_attribute : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_attribute_name
        (context,
         arguments_name,
         range_symbol,
         range_span,
         attribute_span);
    call_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, run_symbol, call_name_span);
    no_actuals : Adac.AST.Node_List;
    call_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_call_statement
        (context, call_name, no_actuals, call_span);
    statements : Adac.AST.Node_List;
    loop_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (statements, call_statement);
    loop_statement :=
      Adac.Compilation.Syntax.create_range_attribute_loop_statement
        (context,
         parameter_symbol,
         parameter_span,
         True,
         range_attribute,
         statements,
         loop_span);
    Adac.Compilation.Syntax.validate_loop_statement (context, loop_statement);

    require
      (Adac.Compilation.Syntax.loop_form (context, loop_statement) =
         Adac.AST.Range_Attribute_Loop_Form and then
       Adac.Compilation.Syntax.loop_parameter_symbol
         (context, loop_statement) = parameter_symbol and then
       Adac.Compilation.Syntax.loop_is_reverse
         (context, loop_statement) and then
       Adac.Compilation.Syntax.loop_range_attribute
         (context, loop_statement) = range_attribute and then
       Adac.Compilation.Syntax.loop_statement_count
         (context, loop_statement) = 1 and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, loop_statement, 1) = call_statement,
       "range-attribute loop lost its header/body syntax");
    require
      (not accepts_loop_statement (context_b, loop_statement),
       "range-attribute loop validator accepted another context's node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "exit-tree.adb");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    outer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    when_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 9));
    condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 11),
         Adac.Source.make_position (file_id, 1, 15));
    exit_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 16));
    loop_name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 6),
         Adac.Source.make_position (file_id, 2, 10));
    named_when_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 12),
         Adac.Source.make_position (file_id, 2, 15));
    named_condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 17),
         Adac.Source.make_position (file_id, 2, 21));
    named_exit_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 2, 22));
    malformed_when_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 8));
    condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, condition_span);
    unnamed_exit : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_exit_statement
        (context,
         Adac.Symbols.INVALID_SYMBOL_ID,
         Adac.Source.INVALID_SPAN,
         when_span,
         condition,
         exit_span);
    named_condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, named_condition_span);
    named_exit : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_exit_statement
        (context,
         outer_symbol,
         loop_name_span,
         named_when_span,
         named_condition,
         named_exit_span);
  begin
    Adac.Compilation.Syntax.validate_exit_statement (context, unnamed_exit);
    Adac.Compilation.Syntax.validate_exit_statement (context, named_exit);
    require
      (Adac.Compilation.Syntax.kind_of (context, unnamed_exit) =
         Adac.AST.Exit_Statement_Node and then
       not Adac.Compilation.Syntax.exit_has_loop_name
         (context, unnamed_exit) and then
       Adac.Compilation.Syntax.exit_has_condition
         (context, unnamed_exit) and then
       Adac.Compilation.Syntax.exit_when_span (context, unnamed_exit) =
         when_span and then
       Adac.Compilation.Syntax.exit_condition (context, unnamed_exit) =
         condition,
       "unnamed exit lost its when condition syntax");
    require
      (Adac.Compilation.Syntax.exit_has_loop_name
         (context, named_exit) and then
       Adac.Compilation.Syntax.exit_loop_name_symbol (context, named_exit) =
         outer_symbol and then
       Adac.Compilation.Syntax.exit_loop_name_span (context, named_exit) =
         loop_name_span and then
       Adac.Compilation.Syntax.exit_has_condition (context, named_exit) and then
       Adac.Compilation.Syntax.exit_condition (context, named_exit) =
         named_condition,
       "named exit lost its loop-name/condition syntax contract");

    declare
      accepted : Boolean := True;
    begin
      begin
        Adac.Compilation.Syntax.validate_exit_statement
          (context_b, unnamed_exit);
      exception
        when Program_Error =>
          accepted := False;
      end;
      require
        (not accepted,
         "exit validator accepted another context's node");
    end;

    declare
      count_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
    begin
      begin
        declare
          invalid : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_exit_statement
              (context,
               Adac.Symbols.INVALID_SYMBOL_ID,
               Adac.Source.INVALID_SPAN,
               malformed_when_span,
               condition,
               exit_span);
        begin
          pragma Unreferenced (invalid);
          null;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then
         Adac.Compilation.Syntax.node_count (context) = count_before,
         "exit accepted malformed when span or published a partial parent");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "while-loop-tree.adb");
    ready_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ready");
    run_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    condition_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 11));
    call_name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 18),
         Adac.Source.make_position (file_id, 1, 20));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 18),
         Adac.Source.make_position (file_id, 1, 21));
    loop_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 31));
    condition : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ready_symbol, condition_span);
    call_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, run_symbol, call_name_span);
    no_actuals : Adac.AST.Node_List;
    call_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_call_statement
        (context, call_name, no_actuals, call_span);
    statements : Adac.AST.Node_List;
    loop_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    simple_loop_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (statements, call_statement);
    loop_statement := Adac.Compilation.Syntax.create_while_loop_statement
      (context, condition, statements, loop_span);
    Adac.Compilation.Syntax.validate_loop_statement (context, loop_statement);

    require
      (Adac.Compilation.Syntax.kind_of (context, loop_statement) =
         Adac.AST.Loop_Statement_Node and then
       Adac.Compilation.Syntax.loop_form (context, loop_statement) =
         Adac.AST.While_Loop_Form and then
       Adac.Compilation.Syntax.loop_condition (context, loop_statement) =
         condition and then
       Adac.Compilation.Syntax.loop_statement_count
         (context, loop_statement) = 1 and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, loop_statement, 1) = call_statement and then
       Adac.Compilation.Syntax.node_span (context, loop_statement) = loop_span,
       "while loop lost its condition, body, form, or complete span");
    require
      (not accepts_loop_statement (context_b, loop_statement),
       "while-loop validator accepted another context's node");

    simple_loop_statement :=
      Adac.Compilation.Syntax.create_simple_loop_statement
        (context, statements, loop_span);
    Adac.Compilation.Syntax.validate_loop_statement
      (context, simple_loop_statement);
    require
      (Adac.Compilation.Syntax.loop_form (context, simple_loop_statement) =
         Adac.AST.Simple_Loop_Form and then
       Adac.Compilation.Syntax.loop_statement_count
         (context, simple_loop_statement) = 1 and then
       Adac.Compilation.Syntax.loop_statement_at
         (context, simple_loop_statement, 1) = call_statement and then
       Adac.Compilation.Syntax.node_span (context, simple_loop_statement) =
         loop_span,
       "simple loop lost its form, body, or complete span");
    require
      (not accepts_loop_statement (context_b, simple_loop_statement),
       "simple-loop validator accepted another context's node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "call-tree.adb");
    pkg_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Pkg");
    put_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Put");
    x_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "X");
    y_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Y");
    run_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    pkg_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    put_selector_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 7));
    callable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 7));
    x_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 10));
    y_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 13),
         Adac.Source.make_position (file_id, 1, 13));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 15));
    run_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 2, 3));
    parameterless_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 2, 4));
    pkg_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, pkg_symbol, pkg_span);
    callable_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_selected_name
        (context,
         pkg_name,
         put_symbol,
         put_selector_span,
         callable_span);
    x_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, x_symbol, x_span);
    y_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, y_symbol, y_span);
    actuals : Adac.AST.Node_List;
    reverse_actuals : Adac.AST.Node_List;
    call : Adac.AST.Node_ID;
    run_name : Adac.AST.Node_ID;
    parameterless_call : Adac.AST.Node_ID;
  begin
    Adac.AST.append (actuals, x_name);
    Adac.AST.append (actuals, y_name);
    call := Adac.Compilation.Syntax.create_procedure_call_statement
      (context, callable_name, actuals, call_span);
    Adac.Compilation.Syntax.validate_procedure_call (context, call);
    require
      (Adac.Compilation.Syntax.kind_of (context, call) =
       Adac.AST.Procedure_Call_Statement_Node,
       "procedure call has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.procedure_call_callable_name
         (context, call) = callable_name,
       "procedure call lost its callable name");
    require
      (Adac.Compilation.Syntax.procedure_call_actual_count (context, call) = 2,
       "procedure call has the wrong actual count");
    require
      (Adac.Compilation.Syntax.procedure_call_actual_at
         (context, call, 1) = x_name and then
       Adac.Compilation.Syntax.procedure_call_actual_at
         (context, call, 2) = y_name,
       "procedure call lost positional actual order");
    require
      (Adac.Compilation.Syntax.node_span (context, call) = call_span,
       "procedure call lost its complete statement span");
    require
      (not accepts_procedure_call (context_b, call),
       "procedure-call validator accepted another context's node");

    run_name := Adac.Compilation.Syntax.create_identifier_name
      (context, run_symbol, run_span);
    declare
      no_actuals : Adac.AST.Node_List;
    begin
      parameterless_call :=
        Adac.Compilation.Syntax.create_procedure_call_statement
          (context, run_name, no_actuals, parameterless_span);
    end;
    Adac.Compilation.Syntax.validate_procedure_call
      (context, parameterless_call);
    require
      (Adac.Compilation.Syntax.procedure_call_actual_count
         (context, parameterless_call) = 0,
       "parameterless procedure call gained an actual");

    Adac.AST.append (reverse_actuals, y_name);
    Adac.AST.append (reverse_actuals, x_name);
    declare
      malformed : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.Testing.create_procedure_call_unchecked
          (context, callable_name, reverse_actuals, call_span);
    begin
      require
        (not accepts_procedure_call (context, malformed),
         "procedure-call validator accepted out-of-order actuals");
    end;

    declare
      foreign_file : constant Adac.Source.Source_File_ID :=
        Adac.Compilation.Sources.register_file (context_b, "foreign-call.adb");
      foreign_symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Symbols.intern (context_b, "Foreign");
      foreign_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (foreign_file, 1, 1),
           Adac.Source.make_position (foreign_file, 1, 7));
      foreign_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context_b, foreign_symbol, foreign_span);
      foreign_actuals : Adac.AST.Node_List;
    begin
      Adac.AST.append (foreign_actuals, foreign_name);
      require
        (rejects_procedure_call_construction
           (context, callable_name, foreign_actuals, call_span),
         "procedure call accepted an actual from another context");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "named-call-tree.adb");
    pkg_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Pkg");
    put_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Put");
    x_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "X");
    left_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Left");
    y_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Y");
    z_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Z");
    pkg_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    put_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 7));
    callable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 7));
    x_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 10));
    left_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 13),
         Adac.Source.make_position (file_id, 1, 16));
    y_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 21));
    z_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 24),
         Adac.Source.make_position (file_id, 1, 24));
    call_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 26));
    pkg_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, pkg_symbol, pkg_span);
    callable_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_selected_name
        (context, pkg_name, put_symbol, put_span, callable_span);
    x_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, x_symbol, x_span);
    left_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, left_symbol, left_span);
    y_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, y_symbol, y_span);
    z_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, z_symbol, z_span);
    actuals : Adac.AST.Procedure_Call_Actual_Association_List;
    call : Adac.AST.Node_ID;
  begin
    Adac.AST.append (actuals, x_name);
    Adac.AST.append (actuals, left_name, y_name);
    call := Adac.Compilation.Syntax.create_procedure_call_statement
      (context, callable_name, actuals, call_span);
    Adac.Compilation.Syntax.validate_procedure_call (context, call);
    require
      (Adac.Compilation.Syntax.procedure_call_actual_count (context, call) = 2
       and then
       Adac.Compilation.Syntax.procedure_call_actual_form (context, call, 1) =
         Adac.AST.Positional_Procedure_Call_Actual_Form
       and then
       Adac.Compilation.Syntax.procedure_call_actual_form (context, call, 2) =
         Adac.AST.Named_Procedure_Call_Actual_Form,
       "procedure call lost positional/named association forms");
    require
      (Adac.Compilation.Syntax.procedure_call_actual_at (context, call, 1) =
         x_name
       and then
       Adac.Compilation.Syntax.procedure_call_actual_selector_at
         (context, call, 2) = left_name
       and then
       Adac.Compilation.Syntax.procedure_call_actual_at (context, call, 2) =
         y_name,
       "procedure call lost named selector or actual ownership");

    declare
      invalid_actuals : Adac.AST.Procedure_Call_Actual_Association_List;
      rejected : Boolean := False;
    begin
      Adac.AST.append (invalid_actuals, left_name, y_name);
      Adac.AST.append (invalid_actuals, z_name);
      begin
        declare
          invalid : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_procedure_call_statement
              (context, callable_name, invalid_actuals, call_span);
        begin
          pragma Unreferenced (invalid);
          null;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected,
         "procedure call accepted positional actual after named association");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "exponentiating-tree.adb");
    left_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "A");
    right_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "B");
    left_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 1));
    operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 3),
         Adac.Source.make_position (file_id, 1, 4));
    right_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 6));
    expression_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    left_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, left_symbol, left_span);
    right_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, right_symbol, right_span);
    expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_exponentiating
        (context,
         left_name,
         "**",
         operator_span,
         right_name,
         expression_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.kind_of (context, expression) =
         Adac.AST.Binary_Exponentiating_Node and then
       Adac.Compilation.Syntax.binary_exponentiating_left_operand
         (context, expression) = left_name and then
       Adac.Compilation.Syntax.binary_exponentiating_right_operand
         (context, expression) = right_name and then
       Adac.Compilation.Syntax.binary_exponentiating_operator_spelling
         (context, expression) = "**" and then
       Adac.Compilation.Syntax.binary_exponentiating_operator_span
         (context, expression) = operator_span,
       "exponentiating factor lost operands or operator syntax");

    declare
      rejected : Boolean := False;
    begin
      begin
        declare
          invalid : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_binary_exponentiating
              (context,
               left_name,
               "^^",
               operator_span,
               right_name,
               expression_span);
        begin
          pragma Unreferenced (invalid);
          null;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected,
         "binary exponentiating accepted an invalid operator spelling");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "multiplying-tree.adb");
    a_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "A");
    b_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "B");
    c_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "C");
    d_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "D");
    a_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 1));
    slash_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 3),
         Adac.Source.make_position (file_id, 1, 3));
    b_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 5));
    first_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    mod_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 9));
    c_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 11),
         Adac.Source.make_position (file_id, 1, 11));
    second_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 11));
    rem_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 13),
         Adac.Source.make_position (file_id, 1, 15));
    d_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 17));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 17));
    a_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, a_symbol, a_span);
    b_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, b_symbol, b_span);
    first_term : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_multiplying
        (context, a_name, "/", slash_span, b_name, first_span);
    c_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, c_symbol, c_span);
    second_term : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_multiplying
        (context, first_term, "mod", mod_span, c_name, second_span);
    d_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, d_symbol, d_span);
    expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_multiplying
        (context, second_term, "rem", rem_span, d_name, whole_span);
  begin
    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.kind_of (context, expression) =
         Adac.AST.Binary_Multiplying_Node and then
       Adac.Compilation.Syntax.binary_multiplying_left_operand
         (context, expression) = second_term and then
       Adac.Compilation.Syntax.binary_multiplying_right_operand
         (context, expression) = d_name and then
       Adac.Compilation.Syntax.binary_multiplying_operator_spelling
         (context, first_term) = "/" and then
       Adac.Compilation.Syntax.binary_multiplying_operator_spelling
         (context, second_term) = "mod" and then
       Adac.Compilation.Syntax.binary_multiplying_operator_spelling
         (context, expression) = "rem" and then
       Adac.Compilation.Syntax.binary_multiplying_operator_span
         (context, expression) = rem_span,
       "multiplying chain lost left association or operator syntax");

    declare
      rejected : Boolean := False;
    begin
      begin
        declare
          invalid : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_binary_multiplying
              (context, a_name, "+", slash_span, b_name, first_span);
        begin
          pragma Unreferenced (invalid);
          null;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected,
         "binary multiplying accepted a binary-adding operator spelling");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "concatenation-tree.adb");
    prefix_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "prefix");
    name_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "name");
    message_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "message");
    prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    first_operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 8),
         Adac.Source.make_position (file_id, 1, 8));
    name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 13));
    first_expression_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 13));
    second_operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 15),
         Adac.Source.make_position (file_id, 1, 15));
    string_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 20));
    second_expression_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 20));
    third_operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 22));
    misplaced_operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 20),
         Adac.Source.make_position (file_id, 1, 20));
    message_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 24),
         Adac.Source.make_position (file_id, 1, 30));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 30));
    quoted_colon : constant String := """: """;
    prefix_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, prefix_symbol, prefix_span);
    name_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, name_symbol, name_span);
    first_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_adding
        (context,
         prefix_name,
         "&",
         first_operator_span,
         name_name,
         first_expression_span);
    string_literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_string_literal
        (context, quoted_colon, string_span);
    second_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_adding
        (context,
         first_expression,
         "&",
         second_operator_span,
         string_literal,
         second_expression_span);
    message_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, message_symbol, message_span);
    expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_adding
        (context,
         second_expression,
         "&",
         third_operator_span,
         message_name,
         whole_span);
  begin
    Adac.Compilation.Syntax.validate_string_literal (context, string_literal);
    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.node_count (context) = 7,
       "concatenation construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, string_literal) =
       Adac.AST.String_Literal_Node and then
       Adac.Compilation.Syntax.string_literal_spelling
         (context, string_literal) = quoted_colon,
       "string literal did not preserve its syntax");
    require
      (Adac.Compilation.Syntax.kind_of (context, expression) =
       Adac.AST.Binary_Adding_Node,
       "concatenation has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.binary_adding_left_operand
         (context, expression) = second_expression and then
       Adac.Compilation.Syntax.binary_adding_left_operand
         (context, second_expression) = first_expression,
       "concatenation did not preserve left association");
    require
      (Adac.Compilation.Syntax.binary_adding_right_operand
         (context, expression) = message_name and then
       Adac.Compilation.Syntax.binary_adding_right_operand
         (context, second_expression) = string_literal,
       "concatenation lost an ordered right operand");
    require
      (Adac.Compilation.Syntax.binary_adding_operator_spelling
         (context, expression) = "&" and then
       Adac.Compilation.Syntax.binary_adding_operator_span
         (context, expression) = third_operator_span,
       "concatenation lost its operator syntax");
    require
      (Adac.Compilation.Syntax.node_span (context, expression) = whole_span,
       "concatenation lost its complete span");
    require
      (not accepts_expression (context_b, expression),
       "expression validator accepted concatenation from another context");
    require
      (rejects_string_literal_shape_before_limit
         (context, "colon", string_span),
       "string literal accepted an unquoted spelling");
    require
      (rejects_binary_adding_construction
         (context,
          prefix_name,
          "*",
          first_operator_span,
          name_name,
          first_expression_span),
       "binary adding accepted a multiplying operator spelling");

    declare
      malformed : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.Testing.create_binary_adding_unchecked
          (context,
           second_expression,
           "&",
           misplaced_operator_span,
           message_name,
           whole_span);
    begin
      require
        (not accepts_expression (context, malformed),
         "expression validator accepted an out-of-order concatenation");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "long-concatenation-tree.adb");
    item_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "x");
    first_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 1));
    expression : Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, item_symbol, first_span);
  begin
    for index in 2 .. 512 loop
      declare
        operator_column : constant Positive := 4 * index - 5;
        item_column : constant Positive := operator_column + 2;
        operator_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position
               (file_id, 1, operator_column),
             Adac.Source.make_position
               (file_id, 1, operator_column));
        item_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, 1, item_column),
             Adac.Source.make_position (file_id, 1, item_column));
        expression_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, 1, 1),
             Adac.Source.make_position (file_id, 1, item_column));
        item : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_identifier_name
            (context, item_symbol, item_span);
      begin
        expression := Adac.Compilation.Syntax.create_binary_adding
          (context,
           expression,
           "&",
           operator_span,
           item,
           expression_span);
      end;
    end loop;

    Adac.Compilation.Syntax.validate_expression (context, expression);
    require
      (Adac.Compilation.Syntax.node_count (context) = 1_023,
       "long concatenation published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, expression) =
       Adac.AST.Binary_Adding_Node,
       "long concatenation lost its root expression kind");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "name-tree.adb");
    ada_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Ada");
    exceptions_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Exceptions");
    function_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "exception_name");
    error_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "error");
    ada_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    exceptions_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 14));
    prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 14));
    function_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 16),
         Adac.Source.make_position (file_id, 1, 29));
    callable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 29));
    error_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 31),
         Adac.Source.make_position (file_id, 1, 35));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 36));
    ada_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, ada_symbol, ada_span);
    exceptions_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_selected_name
        (context,
         ada_name,
         exceptions_symbol,
         exceptions_span,
         prefix_span);
    callable_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_selected_name
        (context,
         exceptions_name,
         function_symbol,
         function_span,
         callable_span);
    error_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, error_symbol, error_span);
    items : Adac.AST.Node_List;
    name  : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (items, error_name);
    name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, callable_name, items, whole_span);
    Adac.Compilation.Syntax.validate_name (context, name);

    require
      (Adac.Compilation.Syntax.node_count (context) = 5,
       "name syntax construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, ada_name) =
       Adac.AST.Identifier_Name_Node,
       "identifier name has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.identifier_symbol (context, ada_name) =
       ada_symbol,
       "identifier name lost its symbol");
    require
      (Adac.Compilation.Syntax.kind_of (context, callable_name) =
       Adac.AST.Selected_Name_Node,
       "selected name has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.name_prefix (context, callable_name) =
       exceptions_name,
       "selected name lost its prefix");
    require
      (Adac.Compilation.Syntax.selector_symbol (context, callable_name) =
       function_symbol,
       "selected name lost its selector symbol");
    require
      (Adac.Compilation.Syntax.selector_span (context, callable_name) =
       function_span,
       "selected name lost its selector span");
    require
      (Adac.Compilation.Syntax.kind_of (context, name) =
       Adac.AST.Parenthesized_Name_Node,
       "parenthesized name has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.name_prefix (context, name) = callable_name,
       "parenthesized name lost its prefix");
    require
      (Adac.Compilation.Syntax.parenthesized_item_count (context, name) = 1,
       "parenthesized name has the wrong item count");
    require
      (Adac.Compilation.Syntax.parenthesized_item_at (context, name, 1) =
       error_name,
       "parenthesized name lost its item");
    require
      (Adac.Compilation.Syntax.node_span (context, name) = whole_span,
       "parenthesized name lost its complete span");
    require
      (not accepts_name (context_b, name),
       "name validator accepted a node from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "selected-component-name-tree.adb");
    a_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "A");
    b_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "B");
    c_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "C");
    d_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "D");
    e_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "E");
    a_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 1));
    b_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 3),
         Adac.Source.make_position (file_id, 1, 3));
    parenthesized_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 4));
    c_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 6));
    first_selected_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    d_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 8),
         Adac.Source.make_position (file_id, 1, 8));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 8));
    e_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 10));
    repeated_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 11));
    a_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, a_symbol, a_span);
    b_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, b_symbol, b_span);
    items : Adac.AST.Node_List;
    repeated_items : Adac.AST.Node_List;
    parenthesized_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    first_selected : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    selected_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    e_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    repeated_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (items, b_name);
    parenthesized_name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, a_name, items, parenthesized_span);
    first_selected := Adac.Compilation.Syntax.create_selected_component
      (context,
       parenthesized_name,
       c_symbol,
       c_span,
       first_selected_span);
    selected_name := Adac.Compilation.Syntax.create_selected_component
      (context, first_selected, d_symbol, d_span, whole_span);
    e_name := Adac.Compilation.Syntax.create_identifier_name
      (context, e_symbol, e_span);
    Adac.AST.append (repeated_items, e_name);
    repeated_name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, selected_name, repeated_items, repeated_span);
    Adac.Compilation.Syntax.validate_name (context, repeated_name);

    require
      (Adac.Compilation.Syntax.node_count (context) = 7,
       "repeated parenthesized construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, selected_name) =
         Adac.AST.Selected_Component_Node and then
       Adac.Compilation.Syntax.name_prefix (context, selected_name) =
         first_selected,
       "selected-component construction lost chained ownership");
    require
      (Adac.Compilation.Syntax.selector_symbol (context, first_selected) =
         c_symbol and then
       Adac.Compilation.Syntax.selector_span (context, first_selected) =
         c_span and then
       Adac.Compilation.Syntax.selector_symbol (context, selected_name) =
         d_symbol and then
       Adac.Compilation.Syntax.selector_span (context, selected_name) = d_span,
       "selected-component construction lost selector syntax");
    require
      (Adac.Compilation.Syntax.node_span (context, selected_name) = whole_span,
       "selected-component construction lost its complete span");
    require
      (Adac.Compilation.Syntax.kind_of (context, repeated_name) =
         Adac.AST.Parenthesized_Name_Node and then
       Adac.Compilation.Syntax.name_prefix (context, repeated_name) =
         selected_name and then
       Adac.Compilation.Syntax.parenthesized_item_count
         (context, repeated_name) = 1 and then
       Adac.Compilation.Syntax.parenthesized_item_at
         (context, repeated_name, 1) = e_name and then
       Adac.Compilation.Syntax.node_span (context, repeated_name) =
         repeated_span,
       "repeated parenthesized construction lost prefix/item ownership");
    require
      (not accepts_name (context_b, repeated_name),
       "repeated parenthesized validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "explicit-dereference-name-tree.adb");
    spawn_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Spawn");
    access_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "compiler_path");
    spawn_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    access_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 19));
    all_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 23));
    short_all_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 22));
    dereference_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 23));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 24));
    spawn_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, spawn_symbol, spawn_span);
    access_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, access_symbol, access_span);
    dereference : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_explicit_dereference_name
        (context, access_name, all_span, dereference_span);
    items : Adac.AST.Node_List;
  begin
    Adac.Compilation.Syntax.validate_name (context, dereference);
    require
      (Adac.Compilation.Syntax.kind_of (context, dereference) =
         Adac.AST.Explicit_Dereference_Name_Node and then
       Adac.Compilation.Syntax.name_prefix (context, dereference) =
         access_name and then
       Adac.Compilation.Syntax.explicit_dereference_all_span
         (context, dereference) = all_span and then
       Adac.Compilation.Syntax.node_span (context, dereference) =
         dereference_span,
       "explicit dereference lost prefix/all/whole span ownership");
    require
      (not accepts_name (context_b, dereference),
       "explicit dereference validator accepted a foreign node");

    Adac.AST.append (items, dereference);
    declare
      parenthesized : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_parenthesized_name
          (context, spawn_name, items, whole_span);
    begin
      Adac.Compilation.Syntax.validate_name (context, parenthesized);
      require
        (Adac.Compilation.Syntax.parenthesized_item_count
           (context, parenthesized) = 1 and then
         Adac.Compilation.Syntax.parenthesized_item_at
           (context, parenthesized, 1) = dereference,
         "parenthesized name lost its explicit-dereference item");
    end;

    declare
      nodes_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.create_explicit_dereference_name
          (context, access_name, short_all_span, dereference_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then ignored = Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.node_count (context) = nodes_before,
         "explicit dereference accepted a malformed all span");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "nested-parenthesized-name-tree.adb");
    outer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    inner_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Inner");
    item_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "context");
    outer_prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    inner_prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 11));
    item_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 13),
         Adac.Source.make_position (file_id, 1, 19));
    inner_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 20));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 21));
    outer_prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, outer_symbol, outer_prefix_span);
    inner_prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, inner_symbol, inner_prefix_span);
    item_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, item_symbol, item_span);
    inner_items : Adac.AST.Node_List;
    outer_items : Adac.AST.Node_List;
    inner_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    outer_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (inner_items, item_name);
    inner_name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, inner_prefix, inner_items, inner_span);
    Adac.AST.append (outer_items, inner_name);
    outer_name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, outer_prefix, outer_items, outer_span);
    Adac.Compilation.Syntax.validate_name (context, outer_name);

    require
      (Adac.Compilation.Syntax.node_count (context) = 5,
       "nested parenthesized name published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, inner_name) =
       Adac.AST.Parenthesized_Name_Node and then
       Adac.Compilation.Syntax.kind_of (context, outer_name) =
         Adac.AST.Parenthesized_Name_Node,
       "nested parenthesized name has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.parenthesized_item_at
         (context, inner_name, 1) = item_name and then
       Adac.Compilation.Syntax.parenthesized_item_at
         (context, outer_name, 1) = inner_name,
       "nested parenthesized name lost its item ownership");
    require
      (Adac.Compilation.Syntax.node_span (context, inner_name) =
         inner_span and then
       Adac.Compilation.Syntax.node_span (context, outer_name) = outer_span,
       "nested parenthesized name lost its spans");
    require
      (not accepts_name (context_b, outer_name),
       "nested name validator accepted a node from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "attribute-name-tree.adb");
    prefix_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "message");
    attribute_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "length");
    prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 7));
    attribute_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 14));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 14));
    prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, prefix_symbol, prefix_span);
    name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_attribute_name
        (context, prefix, attribute_symbol, attribute_span, whole_span);
  begin
    Adac.Compilation.Syntax.validate_name (context, name);
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "attribute name construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, name) =
       Adac.AST.Attribute_Name_Node,
       "attribute name has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.name_prefix (context, name) = prefix,
       "attribute name lost its prefix");
    require
      (Adac.Compilation.Syntax.attribute_symbol (context, name) =
       attribute_symbol,
       "attribute name lost its designator symbol");
    require
      (Adac.Compilation.Syntax.attribute_span (context, name) = attribute_span,
       "attribute name lost its designator span");
    require
      (Adac.Compilation.Syntax.node_span (context, name) = whole_span,
       "attribute name lost its complete span");
    require
      (not accepts_name (context_b, name),
       "name validator accepted an attribute from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "attribute-parenthesized-name-tree.adb");
    type_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "T");
    image_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Image");
    value_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "value");
    type_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 1));
    image_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 3),
         Adac.Source.make_position (file_id, 1, 7));
    attribute_whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 7));
    value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 13));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 14));
    type_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, type_symbol, type_span);
    attribute_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_attribute_name
        (context,
         type_name,
         image_symbol,
         image_span,
         attribute_whole_span);
    value_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, value_symbol, value_span);
    items : Adac.AST.Node_List;
    parenthesized_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (items, value_name);
    parenthesized_name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, attribute_name, items, whole_span);
    Adac.Compilation.Syntax.validate_name (context, parenthesized_name);
    require
      (Adac.Compilation.Syntax.node_count (context) = 4 and then
       Adac.Compilation.Syntax.kind_of (context, parenthesized_name) =
         Adac.AST.Parenthesized_Name_Node and then
       Adac.Compilation.Syntax.name_prefix (context, parenthesized_name) =
         attribute_name and then
       Adac.Compilation.Syntax.parenthesized_item_at
         (context, parenthesized_name, 1) = value_name,
       "attribute-prefixed parenthesized name lost ownership");
    require
      (not accepts_name (context_b, parenthesized_name),
       "attribute-prefixed name validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "parenthesized-binary-actual-tree.adb");
    outer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    left_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Left");
    right_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Right");
    inner_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Inner");
    value_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value");
    address_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Address");
    reject_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Reject");
    tail_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Tail");
    outer_prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    left_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 10));
    plus_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 12),
         Adac.Source.make_position (file_id, 1, 12));
    right_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 14),
         Adac.Source.make_position (file_id, 1, 18));
    binary_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 18));
    inner_prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 25));
    value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 31));
    inner_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 32));
    address_designator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 34),
         Adac.Source.make_position (file_id, 1, 40));
    address_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 40));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 41));
    outer_prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, outer_symbol, outer_prefix_span);
    left_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, left_symbol, left_span);
    right_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, right_symbol, right_span);
    binary_actual : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_adding
        (context, left_name, "+", plus_span, right_name, binary_span);
    inner_prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, inner_symbol, inner_prefix_span);
    value_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, value_symbol, value_span);
    inner_items : Adac.AST.Node_List;
    outer_items : Adac.AST.Node_List;
    inner_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    address_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    outer_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (inner_items, value_name);
    inner_name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, inner_prefix, inner_items, inner_span);
    address_name := Adac.Compilation.Syntax.create_attribute_name
      (context,
       inner_name,
       address_symbol,
       address_designator_span,
       address_span);
    Adac.AST.append (outer_items, binary_actual);
    Adac.AST.append (outer_items, address_name);
    outer_name := Adac.Compilation.Syntax.create_parenthesized_name
      (context, outer_prefix, outer_items, outer_span);
    Adac.Compilation.Syntax.validate_name (context, outer_name);

    require
      (Adac.Compilation.Syntax.parenthesized_item_count
         (context, outer_name) = 2 and then
       Adac.Compilation.Syntax.parenthesized_item_at
         (context, outer_name, 1) = binary_actual and then
       Adac.Compilation.Syntax.parenthesized_item_at
         (context, outer_name, 2) = address_name and then
       Adac.Compilation.Syntax.name_prefix (context, address_name) = inner_name,
       "parenthesized binary/attribute actual construction lost ownership");

    declare
      reject_prefix_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 1),
           Adac.Source.make_position (file_id, 2, 6));
      reject_inner_prefix_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 8),
           Adac.Source.make_position (file_id, 2, 12));
      reject_value_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 14),
           Adac.Source.make_position (file_id, 2, 18));
      reject_inner_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 8),
           Adac.Source.make_position (file_id, 2, 19));
      reject_plus_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 21),
           Adac.Source.make_position (file_id, 2, 21));
      tail_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 23),
           Adac.Source.make_position (file_id, 2, 26));
      reject_binary_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 8),
           Adac.Source.make_position (file_id, 2, 26));
      reject_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 2, 1),
           Adac.Source.make_position (file_id, 2, 27));
      reject_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, reject_symbol, reject_prefix_span);
      reject_inner_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, inner_symbol, reject_inner_prefix_span);
      reject_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, value_symbol, reject_value_span);
      reject_inner_items : Adac.AST.Node_List;
      reject_inner : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      tail_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, tail_symbol, tail_span);
      reject_binary : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      reject_items : Adac.AST.Node_List;
      accepted : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      Adac.AST.append (reject_inner_items, reject_value);
      reject_inner := Adac.Compilation.Syntax.create_parenthesized_name
        (context, reject_inner_prefix, reject_inner_items, reject_inner_span);
      reject_binary := Adac.Compilation.Syntax.create_binary_adding
        (context,
         reject_inner,
         "+",
         reject_plus_span,
         tail_name,
         reject_binary_span);
      Adac.AST.append (reject_items, reject_binary);
      accepted := Adac.Compilation.Syntax.create_parenthesized_name
        (context, reject_prefix, reject_items, reject_span);
      Adac.Compilation.Syntax.validate_name (context, accepted);
      require
        (Adac.Compilation.Syntax.parenthesized_item_at
           (context, accepted, 1) = reject_binary and then
         Adac.Compilation.Syntax.binary_adding_left_operand
           (context, reject_binary) = reject_inner,
         "parenthesized binary actual lost nested name ownership");
    end;

    declare
      deep_prefix_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 1),
           Adac.Source.make_position (file_id, 3, 4));
      deep_inner_prefix_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 6),
           Adac.Source.make_position (file_id, 3, 10));
      deep_left_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 12),
           Adac.Source.make_position (file_id, 3, 15));
      deep_inner_plus_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 17),
           Adac.Source.make_position (file_id, 3, 17));
      deep_right_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 19),
           Adac.Source.make_position (file_id, 3, 23));
      deep_inner_binary_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 12),
           Adac.Source.make_position (file_id, 3, 23));
      deep_inner_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 6),
           Adac.Source.make_position (file_id, 3, 24));
      deep_outer_plus_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 26),
           Adac.Source.make_position (file_id, 3, 26));
      deep_tail_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 28),
           Adac.Source.make_position (file_id, 3, 31));
      deep_binary_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 6),
           Adac.Source.make_position (file_id, 3, 31));
      deep_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 3, 1),
           Adac.Source.make_position (file_id, 3, 32));
      deep_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, reject_symbol, deep_prefix_span);
      deep_inner_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, inner_symbol, deep_inner_prefix_span);
      deep_left : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, left_symbol, deep_left_span);
      deep_right : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, right_symbol, deep_right_span);
      deep_inner_binary : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_binary_adding
          (context,
           deep_left,
           "+",
           deep_inner_plus_span,
           deep_right,
           deep_inner_binary_span);
      deep_inner_items : Adac.AST.Node_List;
      deep_inner : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      deep_tail : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_identifier_name
          (context, tail_symbol, deep_tail_span);
      deep_binary : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      deep_items : Adac.AST.Node_List;
      rejected : Boolean := False;
    begin
      Adac.AST.append (deep_inner_items, deep_inner_binary);
      deep_inner := Adac.Compilation.Syntax.create_parenthesized_name
        (context, deep_inner_prefix, deep_inner_items, deep_inner_span);
      deep_binary := Adac.Compilation.Syntax.create_binary_adding
        (context,
         deep_inner,
         "+",
         deep_outer_plus_span,
         deep_tail,
         deep_binary_span);
      Adac.AST.append (deep_items, deep_binary);
      begin
        declare
          ignored : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_parenthesized_name
              (context, deep_prefix, deep_items, deep_span);
        begin
          null;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected,
         "parenthesized binary actual accepted alternating expression nesting");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "parenthesized-string-actual-tree.adb");
    callable_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Exists");
    callable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    string_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 8),
         Adac.Source.make_position (file_id, 1, 16));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 17));
    callable : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, callable_symbol, callable_span);
    literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_string_literal
        (context, """ADAC_CC""", string_span);
    items : Adac.AST.Node_List;
    parenthesized : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (items, literal);
    parenthesized := Adac.Compilation.Syntax.create_parenthesized_name
      (context, callable, items, whole_span);
    Adac.Compilation.Syntax.validate_name (context, parenthesized);
    require
      (Adac.Compilation.Syntax.kind_of (context, parenthesized) =
         Adac.AST.Parenthesized_Name_Node and then
       Adac.Compilation.Syntax.parenthesized_item_count
         (context, parenthesized) = 1 and then
       Adac.Compilation.Syntax.parenthesized_item_at
         (context, parenthesized, 1) = literal and then
       Adac.Compilation.Syntax.string_literal_spelling (context, literal) =
         """ADAC_CC""",
       "parenthesized string actual lost literal ownership");
    require
      (not accepts_name (context_b, parenthesized),
       "parenthesized string actual validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "parenthesized-character-actual-tree.adb");
    callable_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Pos");
    callable_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    character_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 8));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 9));
    callable : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, callable_symbol, callable_span);
    literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "'0'", character_span);
    items : Adac.AST.Node_List;
    parenthesized : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (items, literal);
    parenthesized := Adac.Compilation.Syntax.create_parenthesized_name
      (context, callable, items, whole_span);
    Adac.Compilation.Syntax.validate_name (context, parenthesized);
    require
      (Adac.Compilation.Syntax.kind_of (context, parenthesized) =
         Adac.AST.Parenthesized_Name_Node and then
       Adac.Compilation.Syntax.parenthesized_item_count
         (context, parenthesized) = 1 and then
       Adac.Compilation.Syntax.parenthesized_item_at
         (context, parenthesized, 1) = literal and then
       Adac.Compilation.Syntax.kind_of (context, literal) =
         Adac.AST.Character_Literal_Node and then
       Adac.Compilation.Syntax.character_literal_spelling (context, literal) =
         "'0'",
       "parenthesized character actual lost literal ownership");
    require
      (not accepts_name (context_b, parenthesized),
       "parenthesized character actual validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "slice-name-tree.adb");
    raw_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "raw");
    first_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "first");
    last_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "last");
    prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    lower_prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 7));
    first_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 13));
    lower_attribute_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 13));
    plus_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 15),
         Adac.Source.make_position (file_id, 1, 15));
    one_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 17));
    lower_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 17));
    range_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 19),
         Adac.Source.make_position (file_id, 1, 20));
    short_range_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 19),
         Adac.Source.make_position (file_id, 1, 19));
    upper_prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 24));
    last_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 26),
         Adac.Source.make_position (file_id, 1, 29));
    upper_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 29));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 30));
    prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, raw_symbol, prefix_span);
    lower_prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, raw_symbol, lower_prefix_span);
    lower_attribute : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_attribute_name
        (context,
         lower_prefix,
         first_symbol,
         first_span,
         lower_attribute_span);
    one : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "1", one_span);
    lower_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_binary_adding
        (context,
         lower_attribute,
         "+",
         plus_span,
         one,
         lower_span);
    upper_prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, raw_symbol, upper_prefix_span);
    upper_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_attribute_name
        (context,
         upper_prefix,
         last_symbol,
         last_span,
         upper_span);
    slice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_slice_name
        (context, prefix, lower_bound, range_span, upper_bound, whole_span);
  begin
    Adac.Compilation.Syntax.validate_name (context, slice);
    require
      (Adac.Compilation.Syntax.kind_of (context, slice) =
         Adac.AST.Slice_Name_Node and then
       Adac.Compilation.Syntax.name_prefix (context, slice) = prefix and then
       Adac.Compilation.Syntax.slice_lower_bound (context, slice) =
         lower_bound and then
       Adac.Compilation.Syntax.slice_range_span (context, slice) =
         range_span and then
       Adac.Compilation.Syntax.slice_upper_bound (context, slice) =
         upper_bound,
       "slice construction lost prefix/range-bound ownership");
    require
      (not accepts_name (context_b, slice),
       "slice name validator accepted a foreign node");

    declare
      rejected : Boolean := False;
    begin
      begin
        declare
          malformed : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_slice_name
              (context,
               prefix,
               lower_bound,
               short_range_span,
               upper_bound,
               whole_span);
        begin
          if malformed /= Adac.AST.INVALID_NODE_ID then
            null;
          end if;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected,
         "slice construction accepted a non-double-dot range span");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "bare-reraise-tree.adb");
    span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_bare_raise_statement (context, span);
  begin
    Adac.Compilation.Syntax.validate_raise_statement (context, statement);
    require
      (Adac.Compilation.Syntax.kind_of (context, statement) =
         Adac.AST.Raise_Statement_Node and then
       Adac.Compilation.Syntax.node_span (context, statement) = span,
       "bare re-raise lost kind or complete span");
    case Adac.Compilation.Syntax.raise_form (context, statement) is
      when Adac.AST.Bare_Reraise_Form =>
        null;
      when Adac.AST.Named_With_Message_Raise_Form =>
        raise Program_Error with "bare re-raise lost source form";
    end case;

    declare
      rejected_name : Boolean := False;
      rejected_message : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.raise_exception_name
          (context, statement);
      exception
        when Program_Error =>
          rejected_name := True;
      end;
      begin
        ignored := Adac.Compilation.Syntax.raise_message_expression
          (context, statement);
      exception
        when Program_Error =>
          rejected_message := True;
      end;
      require
        (rejected_name and then rejected_message and then
         ignored = Adac.AST.INVALID_NODE_ID,
         "bare re-raise manufactured named children");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "qualified-direct-expression-tree.adb");
    outer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    inner_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Inner");
    outer_mark_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    inner_mark_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 13));
    string_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 16),
         Adac.Source.make_position (file_id, 1, 18));
    inner_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 19));
    wrapped_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 8),
         Adac.Source.make_position (file_id, 1, 20));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 21));
    outer_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, outer_symbol, outer_mark_span);
    inner_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, inner_symbol, inner_mark_span);
    string_value : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_string_literal
        (context, """x""", string_span);
    inner_qualified : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_qualified_expression
        (context, inner_mark, string_value, inner_span);
    wrapped_inner : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parenthesized_expression
        (context, inner_qualified, wrapped_span);
  begin
    Adac.Compilation.Syntax.validate_qualified_expression
      (context, inner_qualified);
    require
      (Adac.Compilation.Syntax.kind_of (context, inner_qualified) =
         Adac.AST.Qualified_Expression_Node and then
       Adac.Compilation.Syntax.qualified_expression_operand
         (context, inner_qualified) = string_value,
       "qualified direct expression lost its string operand");

    declare
      nodes_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.create_qualified_expression
          (context, outer_mark, wrapped_inner, outer_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then ignored = Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.node_count (context) = nodes_before,
         "qualified direct operand accepted transitive qualification");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "allocator-tree.adb");
    string_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "String");
    new_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 4));
    short_new_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 3));
    mark_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 11));
    string_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 14),
         Adac.Source.make_position (file_id, 1, 16));
    qualified_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 17));
    whole_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 17));
    bracket_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 18));
    mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, string_symbol, mark_span);
    value : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_string_literal
        (context, """x""", string_span);
    qualified : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_qualified_expression
        (context, mark, value, qualified_span);
    allocator : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_allocator
        (context, new_span, qualified, whole_span);
  begin
    Adac.Compilation.Syntax.validate_allocator (context, allocator);
    require
      (Adac.Compilation.Syntax.kind_of (context, allocator) =
         Adac.AST.Allocator_Node and then
       Adac.Compilation.Syntax.allocator_new_span (context, allocator) =
         new_span and then
       Adac.Compilation.Syntax.allocator_expression (context, allocator) =
         qualified,
       "allocator construction lost new span or qualified child");
    require
      (not accepts_expression (context_b, allocator),
       "allocator expression validator accepted a foreign node");

    declare
      expressions : Adac.AST.Node_List;
    begin
      Adac.AST.append (expressions, allocator);
      declare
        aggregate : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_bracket_aggregate
            (context, expressions, bracket_span);
      begin
        Adac.Compilation.Syntax.validate_bracket_aggregate
          (context, aggregate);
        require
          (Adac.Compilation.Syntax.kind_of (context, aggregate) =
             Adac.AST.Bracket_Aggregate_Node and then
           Adac.Compilation.Syntax.bracket_aggregate_expression_count
             (context, aggregate) = 1 and then
           Adac.Compilation.Syntax.bracket_aggregate_expression_at
             (context, aggregate, 1) = allocator,
           "bracket aggregate lost its allocator child");
        require
          (not accepts_expression (context_b, aggregate),
           "bracket aggregate expression validator accepted a foreign node");
      end;
    end;

    declare
      empty : Adac.AST.Node_List;
      nodes_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.create_bracket_aggregate
          (context, empty, bracket_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then ignored = Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.node_count (context) = nodes_before,
         "bracket aggregate accepted an empty element list");
    end;

    declare
      nodes_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.create_allocator
          (context, short_new_span, qualified, whole_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then ignored = Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.node_count (context) = nodes_before,
         "allocator accepted a malformed new keyword span");
    end;
  end;
  declare
    context : Adac.Compilation.Context := new_context;
    context_b : constant Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "case-range-choice.adb");
    lower_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    range_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 5),
         Adac.Source.make_position (file_id, 1, 6));
    upper_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 8),
         Adac.Source.make_position (file_id, 1, 10));
    choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 10));
    lower : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "'0'", lower_span);
    upper : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_character_literal
        (context, "'9'", upper_span);
    choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_case_range_choice
        (context, lower, range_span, upper, choice_span);
  begin
    Adac.Compilation.Syntax.validate_case_range_choice (context, choice);
    require
      (Adac.Compilation.Syntax.kind_of (context, choice) =
         Adac.AST.Case_Range_Choice_Node and then
       Adac.Compilation.Syntax.case_range_choice_lower_bound
         (context, choice) = lower and then
       Adac.Compilation.Syntax.case_range_choice_range_span
         (context, choice) = range_span and then
       Adac.Compilation.Syntax.case_range_choice_upper_bound
         (context, choice) = upper and then
       Adac.Compilation.Syntax.node_span (context, choice) = choice_span,
       "case range choice lost bounds or delimiter span");

    declare
      rejected : Boolean := False;
    begin
      begin
        Adac.Compilation.Syntax.validate_case_range_choice (context_b, choice);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected,
         "case range choice validator accepted another context's node");
    end;

    declare
      numeric_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 1, 8),
           Adac.Source.make_position (file_id, 1, 8));
      numeric : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_numeric_literal
          (context, Adac.AST.Decimal_Integer_Form, "9", numeric_span);
      nodes_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.create_case_range_choice
          (context, lower, range_span, numeric, choice_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then ignored = Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.node_count (context) = nodes_before,
         "case range choice accepted a non-character upper bound");
    end;
  end;
end Run_AST_Expressions_And_Statements;
