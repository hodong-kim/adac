-- ============================================================================
-- adac_internal_tests-run_parser_and_resource_contracts.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_Parser_And_Resource_Contracts is
  use type Adac.Compilation.Types.Predefined_Boolean_Literal_Status;
  use type Adac.Compilation.Types.Predefined_Integer_Subtype_Kind;
  use type Adac.Types.Boolean_Value;
  use type Adac.Types.Universal_Real_Value;
begin
  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "nested-procedure-specification-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 1));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "parameter AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "parameter AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "parameter AST node limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "parameter AST node limit published a partial parameter node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "parameter AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "nested-procedure-specification-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "nested procedure header did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "nested procedure header did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 8,
       "nested procedure header changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 6,
       "nested procedure header changed parameter AST publication");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "nested procedure header published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/statements/if-current-calls-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "complete staged if did not reject ordinary statement parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "complete staged if did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 7,
       "complete staged if changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "complete staged if published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "complete staged if published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "staged nested procedure did not reject outer parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "staged nested procedure did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 15,
       "nested closing designator changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 48,
       "nested procedure completion changed AST publication");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "nested procedure completion published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "outer-procedure-body-completion-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "complete outer procedure did not publish a compilation root");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "complete outer procedure recorded a parser diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 28,
       "outer compilation root changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 98,
       "outer compilation root changed AST publication");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "outer compilation root published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "outer-procedure-body-closing-unpublished-designator/" &
      "input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "distinct enclosing closing designator blocked root publication");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "distinct enclosing closing designator recorded parser diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 29,
       "enclosing closing designator symbol was not represented");
    require
      (Adac.Compilation.Syntax.node_count (context) = 98,
       "enclosing closing form changed root AST publication");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "enclosing closing form published a semantic entity");
  end;

  declare
    path : constant String := "src/adac_main.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "production source did not publish a compilation root");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "production root publication recorded a parser diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 28,
       "production root publication changed distinct symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 113,
       "production compilation root changed AST publication");
    require
      (Adac.Compilation.Syntax.context_item_count
         (context, result.root) = 5,
       "production compilation root lost context items");
    require
      (Adac.Compilation.Syntax.kind_of
         (context,
          Adac.Compilation.Syntax.library_item (context, result.root)) =
         Adac.AST.Procedure_Body_Node,
       "production compilation root lost its procedure body");

    declare
      procedure_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      root_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, result.root);
      body_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, procedure_body);
    begin
      require
        (Adac.Source.first_position (root_span).line = 6 and then
         Adac.Source.first_position (root_span).column = 1 and then
         Adac.Source.first_position (body_span).line = 12 and then
         Adac.Source.first_position (body_span).column = 1 and then
         Adac.Source.last_position (root_span) =
           Adac.Source.last_position (body_span),
         "production compilation root span changed");
    end;

    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "production root publication published a semantic entity");

    declare
      analysis : constant Adac.Sema.Analysis_Result :=
        Adac.Sema.analyze (context, result.root);
    begin
      require
        (analysis.status = Adac.Sema.Analysis_Rejected,
         "production context clauses reached procedure semantics");
      require
        (Adac.Compilation.Diagnostics.error_count (context) = 1,
         "production semantic rejection did not record one diagnostic");
      require
        (Adac.Compilation.Semantics.entity_count (context) = 0,
         "production semantic rejection published an entity");
    end;
  end;

  declare
    path : constant String := "src/adac_main.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 112));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "production root AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "production root AST limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 28,
       "production root AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 112,
       "production root AST limit published a partial root");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "production root AST limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/statements/exception-handler-choice-parameter-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "choice-parameter handler did not reject unsupported semantics");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "choice-parameter handler did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "choice parameter published a defining symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "choice-parameter handler published handler syntax");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "choice-parameter handler published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/statements/" &
      "exception-handler-choice-parameter-others-unsupported/" &
      "input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "choice-parameter others handler did not reject unsupported semantics");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "choice-parameter others handler did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "choice-parameter others handler published a defining symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "choice-parameter others handler published handler syntax");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "choice-parameter others handler published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 23));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "relation AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "relation AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 23,
       "relation AST node limit published a partial relation node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "relation AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 29));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "concatenation AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "concatenation AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 29,
       "concatenation AST node limit published a partial operator node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "concatenation AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 30));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "procedure-call AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "procedure-call AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 30,
       "procedure-call AST node limit published a partial call node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "procedure-call AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 37));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "string-literal AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "string-literal AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 37,
       "string-literal AST node limit published a partial literal node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "string-literal AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 42));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "if AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "if AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 42,
       "if AST node limit published a partial parent node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "if AST node limit published a semantic entity");
  end;

  require_nested_ast_limit (43, 43, "others choice");
  require_nested_ast_limit (44, 44, "handler body statement");
  require_nested_ast_limit (45, 45, "exception handler");
  require_nested_ast_limit (46, 46, "handled sequence");
  require_nested_ast_limit (47, 47, "procedure body");
  require_outer_ast_limit (48, 48, "outer call identifier");
  require_outer_ast_limit (49, 49, "outer call first selector");
  require_outer_ast_limit (50, 50, "outer call second selector");
  require_outer_ast_limit (51, 51, "outer call parent");
  require_outer_ast_limit (52, 52, "outer first named choice");
  require_outer_ast_limit (70, 70, "outer first handler call");
  require_outer_ast_limit (81, 81, "outer first handler parent");
  require_outer_ast_limit (82, 82, "outer second others choice");
  require_outer_ast_limit (94, 94, "outer second handler parent");
  require_outer_ast_limit (95, 95, "outer handled sequence");
  require_outer_ast_limit (96, 96, "outer procedure body");

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 22));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "numeric literal AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "numeric literal AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 22,
       "numeric literal AST node limit published a partial literal node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "numeric literal AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 21));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "attribute AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "attribute AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 21,
       "attribute AST node limit published a partial attribute node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "attribute AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "procedure-nested-subprogram-unsupported/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 19));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "object declaration AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "object declaration AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 12,
       "object declaration AST node limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 19,
       "object declaration AST node limit published a partial parent node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "object declaration AST node limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/expressions/iterated/" &
      "iterated-of-access-procedure-formal-access-function-" &
      "parenthesized-unsupported/input.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting => 2,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "function result profile limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "function result profile limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "function result profile limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "function result profile limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "function result profile limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/expressions/iterated/" &
      "iterated-in-access-protected-procedure-bracket-unsupported/" &
      "input.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting => 0,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "zero profile limit did not reject a parameterless profile");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "zero profile limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "zero profile limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "zero profile limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "zero profile limit published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-digits-range-bracket-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in digits range did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in digits range did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 8,
       "digits range changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in digits range published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in digits range published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-composite-single-bracket-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "single composite constraint did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "single composite constraint did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "single composite constraint changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "single composite constraint published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "single composite constraint published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-composite-index-range-bracket-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "explicit-range composite constraint did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "explicit-range composite did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 7,
       "explicit-range composite changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "explicit-range composite constraint published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "explicit-range composite constraint published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-composite-multiple-range-bracket-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "multi-item composite constraint did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "multi-item composite did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 7,
       "multi-item composite changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "multi-item composite constraint published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "multi-item composite constraint published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-composite-named-list-bracket-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "named composite constraint did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "named composite constraint did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 9,
       "named composite constraint changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "named composite constraint published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "named composite constraint published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-composite-constrained-discrete-bracket-" &
         "unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "constrained discrete composite did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "constrained discrete composite did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 9,
       "constrained discrete composite changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "constrained discrete composite published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "constrained discrete composite published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/aggregates/" &
                  "bracket-delta-aggregate-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "bracket delta aggregate did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "bracket delta aggregate did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "bracket delta aggregate changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "bracket delta aggregate published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "bracket delta aggregate published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting => 1,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols             =>
              Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes           =>
              Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/aggregates/" &
                  "bracket-aggregate-nested-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "bracket aggregate nesting limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "bracket aggregate nesting limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "bracket aggregate nesting limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "bracket aggregate nesting limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "bracket aggregate nesting limit published a semantic entity");
  end;


  declare
    use Adac.Frontend.Tokens;

    path    : constant String := "tests-internal/aggregate-tokens.txt";
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, path);
    scanner : Adac.Frontend.Lexer.Scanner;

    procedure require_token
      (expected : Token_Kind;
       spelling : String)
    is
      current : constant Token := Adac.Frontend.Lexer.next_token (scanner);
    begin
      require
        (current.kind = expected,
         "aggregate token kind mismatch for " & spelling);
      require
        (Ada.Strings.Unbounded.to_string (current.text) = spelling,
         "aggregate token spelling mismatch for " & spelling);
    end require_token;

  begin
    Adac.Frontend.Lexer.open
      (scanner,
       path,
       file_id,
       Adac.Compilation.resource_limits
         (context).maximum_source_characters_per_file);

    require_token (Tok_Others, "OtHeRs");
    require_token (Tok_With, "WiTh");
    require_token (Tok_Record, "ReCoRd");
    require_token (Tok_Range, "RaNgE");
    require_token (Tok_Digits, "DiGiTs");
    require_token (Tok_Delta, "DeLtA");
    require_token (Tok_For, "FoR");
    require_token (Tok_Of, "oF");
    require_token (Tok_Reverse, "ReVeRsE");
    require_token (Tok_When, "WhEn");
    require_token (Tok_Use, "UsE");
    require_token (Tok_Access, "AcCeSs");
    require_token (Tok_Constant, "CoNsTaNt");
    require_token (Tok_Protected, "PrOtEcTeD");
    require_token (Tok_Function, "FuNcTiOn");
    require_token (Tok_Aliased, "AlIaSeD");
    require_token (Tok_Out, "OuT");
    require_token (Tok_Colon, ":");
    require_token (Tok_Left_Bracket, "[");
    require_token (Tok_Right_Bracket, "]");

    declare
      current : constant Token := Adac.Frontend.Lexer.next_token (scanner);
    begin
      require
        (current.kind = Tok_EOF,
         "aggregate token fixture did not reach end of file");
    end;

    Adac.Frontend.Lexer.close (scanner);
  exception
    when others =>
      Adac.Frontend.Lexer.close (scanner);
      raise;
  end;

  declare
    use Adac.Frontend.Tokens;

    path    : constant String := "tests-internal/operator-tokens.txt";
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, path);
    scanner : Adac.Frontend.Lexer.Scanner;

    procedure require_operator (spelling : String) is
      expected : constant Token_Kind := operator_kind (spelling);
      current  : constant Token := Adac.Frontend.Lexer.next_token (scanner);
    begin
      require
        (expected /= Tok_Unknown,
         "operator classifier rejected " & spelling);
      require
        (current.kind = expected,
         "operator token kind mismatch for " & spelling);
      require
        (Ada.Strings.Unbounded.to_string (current.text) = spelling,
         "operator token spelling mismatch for " & spelling);
    end require_operator;

    procedure require_unknown (spelling : String) is
      current : constant Token := Adac.Frontend.Lexer.next_token (scanner);
    begin
      require
        (current.kind = Tok_Unknown,
         "unsupported compound delimiter was not one token: " & spelling);
      require
        (Ada.Strings.Unbounded.to_string (current.text) = spelling,
         "unsupported compound delimiter spelling mismatch: " & spelling);
    end require_unknown;

  begin
    Adac.Frontend.Lexer.open
      (scanner,
       path,
       file_id,
       Adac.Compilation.resource_limits
         (context).maximum_source_characters_per_file);

    require_operator ("AND");
    require_operator ("Or");
    require_operator ("xOr");
    require_operator ("=");
    require_operator ("/=");
    require_operator ("<");
    require_operator ("<=");
    require_operator (">");
    require_operator (">=");
    require_operator ("+");
    require_operator ("-");
    require_operator ("&");
    require_operator ("*");
    require_operator ("/");
    require_operator ("MOD");
    require_operator ("ReM");
    require_operator ("**");
    require_operator ("ABS");
    require_operator ("Not");

    declare
      current : constant Token := Adac.Frontend.Lexer.next_token (scanner);
    begin
      require
        (current.kind = Tok_Box,
         "box compound delimiter did not receive TOK_BOX");
      require
        (Ada.Strings.Unbounded.to_string (current.text) = "<>",
         "box compound delimiter spelling changed");
    end;

    require_unknown ("<<");
    require_unknown (">>");

    declare
      current : constant Token := Adac.Frontend.Lexer.next_token (scanner);
    begin
      require
        (current.kind = Tok_Assign,
         "assignment delimiter did not receive TOK_ASSIGN");
      require
        (Ada.Strings.Unbounded.to_string (current.text) = ":=",
         "assignment delimiter spelling changed");
    end;

    declare
      current : constant Token := Adac.Frontend.Lexer.next_token (scanner);
    begin
      require
        (current.kind = Tok_EOF,
         "operator token fixture did not end after the comment");
    end;

    Adac.Frontend.Lexer.close (scanner);
  exception
    when others =>
      Adac.Frontend.Lexer.close (scanner);
      raise;
  end;

  declare
    path    : constant String :=
      "tests/lexing/character-literal-multiple-characters/input.adb";
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, path);
    scanner : Adac.Frontend.Lexer.Scanner;
  begin
    Adac.Frontend.Lexer.open
      (scanner,
       path,
       file_id,
       Adac.Compilation.resource_limits
         (context).maximum_source_characters_per_file);

    declare
      token : Adac.Frontend.Tokens.Token :=
        Adac.Frontend.Lexer.next_token (scanner);
    begin
      while token.kind /= Adac.Frontend.Tokens.Tok_Return loop
        require
          (token.kind /= Adac.Frontend.Tokens.Tok_EOF,
           "character delimiter test did not find return");
        token := Adac.Frontend.Lexer.next_token (scanner);
      end loop;

      token := Adac.Frontend.Lexer.next_token (scanner);
      require
        (token.kind = Adac.Frontend.Tokens.Tok_Apostrophe,
         "malformed character literal did not preserve apostrophe");

      token := Adac.Frontend.Lexer.next_token (scanner);
      require
        (token.kind = Adac.Frontend.Tokens.Tok_Identifier and then
         Ada.Strings.Unbounded.to_string (token.text) = "AB",
         "apostrophe lookahead did not restore following identifier");

      token := Adac.Frontend.Lexer.next_token (scanner);
      require
        (token.kind = Adac.Frontend.Tokens.Tok_Apostrophe,
         "character delimiter test did not preserve closing apostrophe");
    end;

    Adac.Frontend.Lexer.close (scanner);
  exception
    when others =>
      Adac.Frontend.Lexer.close (scanner);
      raise;
  end;

  declare
    context_c : constant Adac.Compilation.Context := new_context;
  begin
    require
      (Adac.Compilation.Diagnostics.error_count (context_c) = 0,
       "new context inherited diagnostics from an earlier context");
    require
      (not Adac.Compilation.Diagnostics.has_error (context_c),
       "new context started in an error state");
    require
      (Adac.Compilation.Sources.file_count (context_c) = 0,
       "new context inherited source files from an earlier context");
    require
      (Adac.Compilation.Semantics.entity_count (context_c) = 0,
       "new context inherited semantic entities from an earlier context");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file => 0,
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/pipeline/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "zero source character limit did not reject a nonempty file");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "zero source character limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 0,
       "zero source character limit published a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "zero source character limit published an AST node");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file => 20,
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/lexing/" &
                                         "line-comments/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "small source character limit did not reject a long line");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "small source character limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "small source character limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "small source character limit published an AST node");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file => 41,
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/pipeline/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "exact source character limit rejected the minimal file");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "exact source character limit recorded a diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "exact source character limit changed AST publication");
  end;

  declare
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 0));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/pipeline/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "zero AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "zero AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "zero AST node limit published a statement node");
  end;

  declare
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 0));
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "limit-contract.adb");
    span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 1, 1));
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "main");
  begin
    require
      (rejects_invalid_statement_before_limit (context, span),
       "AST limit hid an invalid statement kind");
    require
      (rejects_empty_unit_before_limit (context, symbol, span),
       "AST limit hid an empty compilation unit");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "contract rejection published a node at zero AST limit");
  end;

  declare
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 1));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/pipeline/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "one-node AST limit did not reject the procedure body");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "one-node AST limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "one-node AST limit changed the store after body rejection");
  end;

  declare
    header_context : Adac.Compilation.Context := new_context;
    calls_context  : Adac.Compilation.Context := new_context;
    if_context     : Adac.Compilation.Context := new_context;
    block_context   : Adac.Compilation.Context := new_context;
    closing_context : Adac.Compilation.Context := new_context;
    header_result   : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (header_context,
         "tests/statements/function-body-iterator-loop-header-current/" &
         "input.adb");
    calls_result   : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (calls_context,
         "tests/statements/function-body-iterator-loop-call-prefix-current/" &
         "input.adb");
    if_result      : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (if_context,
         "tests/statements/function-body-iterator-loop-if-prefix-current/" &
         "input.adb");
    block_result   : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (block_context,
         "tests/statements/function-body-iterator-loop-block-prefix-current/" &
         "input.adb");
    closing_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (closing_context,
         "tests/statements/function-body-iterator-loop-closing-current/" &
         "input.adb");
  begin
    require
      (header_result.status = Adac.Frontend.Parse_Rejected and then
       calls_result.status = Adac.Frontend.Parse_Rejected and then
       if_result.status = Adac.Frontend.Parse_Rejected and then
       block_result.status = Adac.Frontend.Parse_Rejected and then
       closing_result.status = Adac.Frontend.Parse_Rejected,
       "iterator-loop staging fixtures did not retain their support boundary");
    require
      (Adac.Compilation.Syntax.node_count (header_context) = 5 and then
       Adac.Compilation.Syntax.node_count (calls_context) = 12 and then
       Adac.Compilation.Syntax.node_count (if_context) = 13 and then
       Adac.Compilation.Syntax.node_count (block_context) = 35 and then
       Adac.Compilation.Syntax.node_count (closing_context) = 9,
       "iterator-loop syntax publication changed unexpectedly");
    require
      (Adac.Compilation.Semantics.entity_count (header_context) = 0 and then
       Adac.Compilation.Semantics.entity_count (calls_context) = 0 and then
       Adac.Compilation.Semantics.entity_count (if_context) = 0 and then
       Adac.Compilation.Semantics.entity_count (block_context) = 0 and then
       Adac.Compilation.Semantics.entity_count (closing_context) = 0,
       "iterator-loop staging published semantic state");
  end;

  for maximum_ast_nodes in 33 .. 34 loop
    declare
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
              maximum_ast_nodes => maximum_ast_nodes));
      result : constant Adac.Frontend.Parse_Result :=
        Adac.Frontend.parse_file
          (context,
           "tests/statements/" &
           "function-body-iterator-loop-block-prefix-current/input.adb");
    begin
      require
        (result.status = Adac.Frontend.Parse_Rejected,
         "iterator block parent AST limit did not reject parsing");
      require
        (Adac.Compilation.Diagnostics.error_count (context) = 1,
         "iterator block parent AST limit changed diagnostics");
      require
        (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
         "iterator block parent AST limit published a partial parent");
      require
        (Adac.Compilation.Semantics.entity_count (context) = 0,
         "iterator block parent AST limit published semantic state");
    end;
  end loop;

  declare
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
            maximum_ast_nodes => 8));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/statements/function-body-iterator-loop-closing-current/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "iterator-loop parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "iterator-loop parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Syntax.node_count (context) = 8,
       "iterator-loop parent AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "iterator-loop parent AST limit published semantic state");
  end;

  declare
    context : constant Adac.Compilation.Context := new_context;
    foreign_context : constant Adac.Compilation.Context := new_context;
    integer_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.standard_integer (context);
    universal_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.universal_integer (context);
    root_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.root_integer (context);
    universal_real_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.universal_real (context);
    root_real_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.root_real (context);
    boolean_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.standard_boolean (context);
    universal_value : constant Adac.Types.Universal_Integer_Value :=
      Adac.Types.make_universal_integer_value (Long_Long_Integer'First);
    wide_universal_value : constant Adac.Types.Universal_Integer_Value :=
      Adac.Types.make_universal_integer_value_from_decimal
        ("123456789012345678901234567890", 30);
    invalid_value_rejected : Boolean := False;
    invalid_real_value_rejected : Boolean := False;
    universal_bound_rejected : Boolean := False;
    root_bound_rejected : Boolean := False;
    universal_real_bound_rejected : Boolean := False;
    root_real_bound_rejected : Boolean := False;
    boolean_bound_rejected : Boolean := False;
    wide_conversion_rejected : Boolean := False;
    universal_digit_limit_rejected : Boolean := False;
    noncanonical_universal_rejected : Boolean := False;
    real_component_limit_rejected : Boolean := False;
    real_zero_denominator_rejected : Boolean := False;
    real_negative_denominator_rejected : Boolean := False;
    real_arithmetic_limit_rejected : Boolean := False;
    real_divide_zero_rejected : Boolean := False;
    real_power_zero_negative_rejected : Boolean := False;
    real_power_work_limit_rejected : Boolean := False;
    real_power_component_limit_rejected : Boolean := False;
  begin
    require
      (Adac.Compilation.Types.type_count (context) = 6,
       "new context did not contain all predefined semantic types");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 0,
       "predefined type creation polluted the source symbol store");
    require
      (Adac.Compilation.Types.kind_of (context, integer_type) =
         Adac.Types.Signed_Integer_Type and then
       Adac.Compilation.Types.kind_of (context, universal_type) =
         Adac.Types.Universal_Integer_Type and then
       Adac.Compilation.Types.kind_of (context, root_type) =
         Adac.Types.Root_Integer_Type and then
       Adac.Compilation.Types.kind_of (context, universal_real_type) =
         Adac.Types.Universal_Real_Type and then
       Adac.Compilation.Types.kind_of (context, root_real_type) =
         Adac.Types.Root_Real_Type and then
       Adac.Compilation.Types.kind_of (context, boolean_type) =
         Adac.Types.Boolean_Type and then
       integer_type /= universal_type and then
       integer_type /= root_type and then
       integer_type /= universal_real_type and then
       integer_type /= root_real_type and then
       universal_type /= root_type and then
       universal_type /= universal_real_type and then
       universal_type /= root_real_type and then
       root_type /= universal_real_type and then
       root_type /= root_real_type and then
       universal_real_type /= root_real_type and then
       boolean_type /= integer_type and then
       boolean_type /= universal_type and then
       boolean_type /= root_type and then
       boolean_type /= universal_real_type and then
       boolean_type /= root_real_type,
       "predefined type identities are inconsistent");
    require
      (Adac.Compilation.Types.signed_integer_lower_bound
         (context, integer_type) = -2_147_483_648,
       "Standard.Integer has the wrong lower bound");
    require
      (Adac.Compilation.Types.signed_integer_upper_bound
         (context, integer_type) = 2_147_483_647,
       "Standard.Integer has the wrong upper bound");
    require
      (Adac.Types.universal_integer_to_long_long (universal_value) =
         Long_Long_Integer'First and then
       Adac.Types.universal_integer_decimal_digits
         (universal_value) = 19 and then
       Adac.Types.universal_integer_fits_long_long (universal_value),
       "universal integer value wrapper lost its checked host value");
    require
      (Adac.Types.universal_integer_decimal_digits (wide_universal_value) =
         30 and then
       not Adac.Types.universal_integer_fits_long_long
         (wide_universal_value),
       "wide universal integer lost arbitrary-precision magnitude metadata");
    begin
      declare
        converted : constant Long_Long_Integer :=
          Adac.Types.universal_integer_to_long_long (wide_universal_value);
        pragma unreferenced (converted);
      begin
        null;
      end;
    exception
      when Program_Error =>
        wide_conversion_rejected := True;
    end;
    require
      (wide_conversion_rejected,
       "wide universal integer converted through the host boundary");
    begin
      declare
        oversized : constant Adac.Types.Universal_Integer_Value :=
          Adac.Types.make_universal_integer_value_from_decimal
            ("123456789012345678901234567890", 29);
        pragma unreferenced (oversized);
      begin
        null;
      end;
    exception
      when Adac.Resources.Limit_Exceeded =>
        universal_digit_limit_rejected := True;
    end;
    require
      (universal_digit_limit_rejected,
       "universal integer constructor ignored its decimal digit limit");
    begin
      declare
        noncanonical : constant Adac.Types.Universal_Integer_Value :=
          Adac.Types.make_universal_integer_value_from_decimal ("01", 2);
        pragma unreferenced (noncanonical);
      begin
        null;
      end;
    exception
      when Program_Error =>
        noncanonical_universal_rejected := True;
    end;
    require
      (noncanonical_universal_rejected,
       "universal integer constructor accepted noncanonical decimal text");
    declare
      one_half : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("1", "2", 8);
      two_quarters : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("2", "4", 8);
      reduced_one : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("1000", "1000", 4);
      zero_real : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("0", "7", 8);
    begin
      require
        (one_half = two_quarters and then
         Adac.Types.universal_real_numerator_decimal_digits
           (one_half) = 1 and then
         Adac.Types.universal_real_denominator_decimal_digits
           (one_half) = 1 and then
         Adac.Types.universal_real_numerator_decimal_digits
           (reduced_one) = 1 and then
         Adac.Types.universal_real_denominator_decimal_digits
           (reduced_one) = 1 and then
         not Adac.Types.universal_real_is_zero (one_half) and then
         Adac.Types.universal_real_is_zero (zero_real),
         "universal real quotient carrier lost exact reduced value metadata");
    end;
    begin
      declare
        oversized : constant Adac.Types.Universal_Real_Value :=
          Adac.Types.make_universal_real_value_from_quotient
            ("1000", "1", 3);
        pragma unreferenced (oversized);
      begin
        null;
      end;
    exception
      when Adac.Resources.Limit_Exceeded =>
        real_component_limit_rejected := True;
    end;
    require
      (real_component_limit_rejected,
       "universal real constructor ignored its input component limit");
    begin
      declare
        invalid : constant Adac.Types.Universal_Real_Value :=
          Adac.Types.make_universal_real_value_from_quotient
            ("1", "0", 8);
        pragma unreferenced (invalid);
      begin
        null;
      end;
    exception
      when Program_Error =>
        real_zero_denominator_rejected := True;
    end;
    require
      (real_zero_denominator_rejected,
       "universal real constructor accepted a zero denominator");
    begin
      declare
        invalid : constant Adac.Types.Universal_Real_Value :=
          Adac.Types.make_universal_real_value_from_quotient
            ("1", "-2", 8);
        pragma unreferenced (invalid);
      begin
        null;
      end;
    exception
      when Program_Error =>
        real_negative_denominator_rejected := True;
    end;
    require
      (real_negative_denominator_rejected,
       "universal real constructor accepted a negative denominator");
    declare
      one_half : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("1", "2", 8);
      one_third : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("1", "3", 8);
      five_sixths : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("5", "6", 8);
      two_thirds : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("2", "3", 8);
      four_fifths : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("4", "5", 8);
      negative_half : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("-1", "2", 8);
      negative_one : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("-1", "1", 8);
      two_over_999 : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("2", "999", 3);
      cross_left : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("999", "1000", 4);
      cross_right : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("1000", "999", 4);
      one : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("1", "1", 4);
      zero_real : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("0", "1", 4);
      three_halves : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("3", "2", 8);
      nine_fourths : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("9", "4", 8);
      four_ninths : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("4", "9", 8);
      ten_real : constant Adac.Types.Universal_Real_Value :=
        Adac.Types.make_universal_real_value_from_quotient
          ("10", "1", 3);
      zero_exponent : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (0);
      two_exponent : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (2);
      three_exponent : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (3);
      minus_one_exponent : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (-1);
      minus_two_exponent : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (-2);
    begin
      require
        (Adac.Types.universal_real_add (one_half, one_third, 8) =
           five_sixths and then
         Adac.Types.universal_real_subtract (five_sixths, one_third, 8) =
           one_half and then
         Adac.Types.universal_real_divide
           (two_thirds, four_fifths, 8) = five_sixths and then
         Adac.Types.universal_real_divide
           (one_half, negative_half, 8) = negative_one,
         "universal real additive/division arithmetic is incorrect");
      require
        (Adac.Types.universal_real_negate (one_half, 8) = negative_half and then
         Adac.Types.universal_real_is_negative (negative_half) and then
         not Adac.Types.universal_real_is_negative (one_half),
         "universal real sign or negation arithmetic is inconsistent");
      require
        (Adac.Types.universal_real_multiply
           (cross_left, cross_right, 4) = one,
         "universal real multiplication lost bounded cross cancellation");
      require
        (Adac.Types.universal_real_add
           (Adac.Types.make_universal_real_value_from_quotient
              ("1", "999", 3),
            Adac.Types.make_universal_real_value_from_quotient
              ("1", "999", 3),
            3) = two_over_999,
         "universal real addition lost denominator cancellation");
      require
        (Adac.Types.universal_real_power
           (three_halves, two_exponent, 8) = nine_fourths and then
         Adac.Types.universal_real_power
           (three_halves, zero_exponent, 8) = one and then
         Adac.Types.universal_real_power
           (three_halves, minus_two_exponent, 8) = four_ninths and then
         Adac.Types.universal_real_power
           (negative_one,
            Adac.Types.make_universal_integer_value (5),
            8) = negative_one and then
         Adac.Types.universal_real_power
           (negative_one, wide_universal_value, 8) = one,
         "universal real exponentiation lost exact or fast-path semantics");
      begin
        declare
          powered : constant Adac.Types.Universal_Real_Value :=
            Adac.Types.universal_real_power
              (zero_real, minus_one_exponent, 4);
          pragma unreferenced (powered);
        begin
          null;
        end;
      exception
        when Program_Error =>
          real_power_zero_negative_rejected := True;
      end;
      require
        (real_power_zero_negative_rejected,
         "universal real power accepted zero with a negative exponent");
      begin
        declare
          powered : constant Adac.Types.Universal_Real_Value :=
            Adac.Types.universal_real_power
              (one_half, wide_universal_value, 8);
          pragma unreferenced (powered);
        begin
          null;
        end;
      exception
        when Adac.Resources.Limit_Exceeded =>
          real_power_work_limit_rejected := True;
      end;
      require
        (real_power_work_limit_rejected,
         "universal real power ignored its bounded work limit");
      begin
        declare
          powered : constant Adac.Types.Universal_Real_Value :=
            Adac.Types.universal_real_power
              (ten_real, three_exponent, 3);
          pragma unreferenced (powered);
        begin
          null;
        end;
      exception
        when Adac.Resources.Limit_Exceeded =>
          real_power_component_limit_rejected := True;
      end;
      require
        (real_power_component_limit_rejected,
         "universal real power exceeded its component digit limit");
      begin
        declare
          product : constant Adac.Types.Universal_Real_Value :=
            Adac.Types.universal_real_multiply
              (Adac.Types.make_universal_real_value_from_quotient
                 ("999", "1", 3),
               Adac.Types.make_universal_real_value_from_quotient
                 ("999", "1", 3),
               3);
          pragma unreferenced (product);
        begin
          null;
        end;
      exception
        when Adac.Resources.Limit_Exceeded =>
          real_arithmetic_limit_rejected := True;
      end;
      require
        (real_arithmetic_limit_rejected,
         "universal real multiplication exceeded its component limit");
      begin
        declare
          quotient : constant Adac.Types.Universal_Real_Value :=
            Adac.Types.universal_real_divide (one_half, zero_real, 4);
          pragma unreferenced (quotient);
        begin
          null;
        end;
      exception
        when Program_Error =>
          real_divide_zero_rejected := True;
      end;
      require
        (real_divide_zero_rejected,
         "universal real division accepted a zero divisor");
    end;
    declare
      arithmetic_limit : constant
        Adac.Resources.Universal_Integer_Decimal_Digit_Limit := 64;
      minus_seventeen : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (-17);
      five : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (5);
      ten : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (10);
      hundred : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (100);
      huge_exponent : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value_from_decimal
          ("123456789012345678901234567890", 30);
      power_100 : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.universal_integer_power
          (Adac.Types.make_universal_integer_value (2),
           hundred,
           arithmetic_limit);
      multiplication_limit_rejected : Boolean := False;
      addition_limit_rejected : Boolean := False;
      huge_power_limit_rejected : Boolean := False;
      negative_power_rejected : Boolean := False;
      zero_divisor_rejected : Boolean := False;
    begin
      require
        (Adac.Types.universal_integer_is_negative (minus_seventeen) and then
         Adac.Types.universal_integer_is_odd (minus_seventeen) and then
         not Adac.Types.universal_integer_is_zero (minus_seventeen),
         "universal integer sign/parity inspection is inconsistent");
      require
        (Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_negate (five, arithmetic_limit)) =
             -5 and then
         Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_absolute
              (minus_seventeen, arithmetic_limit)) = 17 and then
         Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_add
              (minus_seventeen, five, arithmetic_limit)) = -12 and then
         Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_subtract
              (minus_seventeen, five, arithmetic_limit)) = -22,
         "universal integer unary/additive arithmetic is incorrect");
      require
        (Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_multiply
              (minus_seventeen, five, arithmetic_limit)) = -85 and then
         Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_divide
              (minus_seventeen, five, arithmetic_limit)) = -3 and then
         Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_remainder
              (minus_seventeen, five, arithmetic_limit)) = -2 and then
         Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_modulus
              (minus_seventeen, five, arithmetic_limit)) = 3,
         "universal integer multiplicative arithmetic is incorrect");
      require
        (Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_power
              (Adac.Types.make_universal_integer_value (2),
               ten,
               arithmetic_limit)) = 1_024 and then
         Adac.Types.universal_integer_decimal_digits (power_100) = 31 and then
         not Adac.Types.universal_integer_fits_long_long (power_100) and then
         Adac.Types.universal_integer_to_long_long
           (Adac.Types.universal_integer_power
              (Adac.Types.make_universal_integer_value (1),
               huge_exponent,
               arithmetic_limit)) = 1,
         "universal integer bounded exponentiation is incorrect");
      begin
        declare
          product : constant Adac.Types.Universal_Integer_Value :=
            Adac.Types.universal_integer_multiply
              (Adac.Types.make_universal_integer_value (100),
               Adac.Types.make_universal_integer_value (100),
               4);
          pragma unreferenced (product);
        begin
          null;
        end;
      exception
        when Adac.Resources.Limit_Exceeded =>
          multiplication_limit_rejected := True;
      end;
      require
        (multiplication_limit_rejected,
         "universal multiplication exceeded its result digit limit");
      begin
        declare
          sum : constant Adac.Types.Universal_Integer_Value :=
            Adac.Types.universal_integer_add
              (Adac.Types.make_universal_integer_value (999),
               Adac.Types.make_universal_integer_value (1),
               3);
          pragma unreferenced (sum);
        begin
          null;
        end;
      exception
        when Adac.Resources.Limit_Exceeded =>
          addition_limit_rejected := True;
      end;
      require
        (addition_limit_rejected,
         "universal addition exceeded its result digit limit");
      begin
        declare
          powered : constant Adac.Types.Universal_Integer_Value :=
            Adac.Types.universal_integer_power
              (Adac.Types.make_universal_integer_value (2),
               huge_exponent,
               arithmetic_limit);
          pragma unreferenced (powered);
        begin
          null;
        end;
      exception
        when Adac.Resources.Limit_Exceeded =>
          huge_power_limit_rejected := True;
      end;
      require
        (huge_power_limit_rejected,
         "universal exponentiation ignored its bounded work limit");
      begin
        declare
          powered : constant Adac.Types.Universal_Integer_Value :=
            Adac.Types.universal_integer_power
              (Adac.Types.make_universal_integer_value (2),
               Adac.Types.make_universal_integer_value (-1),
               arithmetic_limit);
          pragma unreferenced (powered);
        begin
          null;
        end;
      exception
        when Program_Error =>
          negative_power_rejected := True;
      end;
      require
        (negative_power_rejected,
         "universal exponentiation accepted a negative exponent");
      begin
        declare
          quotient : constant Adac.Types.Universal_Integer_Value :=
            Adac.Types.universal_integer_divide
              (five,
               Adac.Types.make_universal_integer_value (0),
               arithmetic_limit);
          pragma unreferenced (quotient);
        begin
          null;
        end;
      exception
        when Program_Error =>
          zero_divisor_rejected := True;
      end;
      require
        (zero_divisor_rejected,
         "universal integer division accepted a zero divisor");
    end;
    begin
      Adac.Types.validate (Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE);
    exception
      when Program_Error =>
        invalid_value_rejected := True;
    end;
    require
      (invalid_value_rejected,
       "universal integer value validator accepted the invalid value");
    begin
      Adac.Types.validate (Adac.Types.INVALID_UNIVERSAL_REAL_VALUE);
    exception
      when Program_Error =>
        invalid_real_value_rejected := True;
    end;
    require
      (invalid_real_value_rejected,
       "universal real value validator accepted the invalid value");
    begin
      declare
        bound : constant Long_Long_Integer :=
          Adac.Compilation.Types.signed_integer_lower_bound
            (context, universal_type);
        pragma unreferenced (bound);
      begin
        null;
      end;
    exception
      when Program_Error =>
        universal_bound_rejected := True;
    end;
    require
      (universal_bound_rejected,
       "universal_integer incorrectly exposed a signed runtime base range");
    begin
      declare
        bound : constant Long_Long_Integer :=
          Adac.Compilation.Types.signed_integer_lower_bound
            (context, root_type);
        pragma unreferenced (bound);
      begin
        null;
      end;
    exception
      when Program_Error =>
        root_bound_rejected := True;
    end;
    require
      (root_bound_rejected,
       "root_integer incorrectly exposed the Standard.Integer base range");
    begin
      declare
        bound : constant Long_Long_Integer :=
          Adac.Compilation.Types.signed_integer_lower_bound
            (context, universal_real_type);
        pragma unreferenced (bound);
      begin
        null;
      end;
    exception
      when Program_Error =>
        universal_real_bound_rejected := True;
    end;
    require
      (universal_real_bound_rejected,
       "universal_real incorrectly exposed a signed integer base range");
    begin
      declare
        bound : constant Long_Long_Integer :=
          Adac.Compilation.Types.signed_integer_lower_bound
            (context, root_real_type);
        pragma unreferenced (bound);
      begin
        null;
      end;
    exception
      when Program_Error =>
        root_real_bound_rejected := True;
    end;
    require
      (root_real_bound_rejected,
       "root_real incorrectly exposed a signed integer base range");
    begin
      declare
        bound : constant Long_Long_Integer :=
          Adac.Compilation.Types.signed_integer_lower_bound
            (context, boolean_type);
        pragma unreferenced (bound);
      begin
        null;
      end;
    exception
      when Program_Error =>
        boolean_bound_rejected := True;
    end;
    require
      (boolean_bound_rejected,
       "Standard.Boolean incorrectly exposed a signed integer base range");
    require
      (Adac.Compilation.Types.resolve_predefined_unary_real_operator_type
         (context, universal_real_type) = root_real_type and then
       Adac.Compilation.Types.resolve_predefined_unary_real_operator_type
         (context, root_real_type) = root_real_type and then
       Adac.Compilation.Types.resolve_predefined_unary_real_operator_type
         (context, universal_type) = Adac.Types.INVALID_TYPE_ID,
       "predefined unary real operator selection is inconsistent");
    require
      (Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_real_operator_type
           (context, universal_real_type, universal_real_type) =
             root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_real_operator_type
           (context, universal_real_type, root_real_type) =
             root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_real_operator_type
           (context, root_real_type, universal_real_type) =
             root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_real_operator_type
           (context, root_real_type, root_real_type) = root_real_type,
       "homogeneous real operator selection lost universal adaptation");
    require
      (Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_real_operator_type
           (context, universal_real_type, root_type) =
             Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_real_operator_type
           (context, root_type, universal_real_type) =
             Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_real_operator_type
           (context, root_real_type, root_type) =
             Adac.Types.INVALID_TYPE_ID,
       "homogeneous real operator resolved an integer-class pair");
    require
      (Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Multiply,
            universal_real_type,
            universal_type) = root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Multiply,
            root_real_type,
            root_type) = root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Multiply,
            universal_type,
            universal_real_type) = root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Multiply,
            root_type,
            root_real_type) = root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Divide,
            universal_real_type,
            universal_type) = root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Divide,
            root_real_type,
            root_type) = root_real_type,
       "mixed root real/integer multiplying signatures did not resolve");
    require
      (Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Divide,
            universal_type,
            universal_real_type) = Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Divide,
            root_type,
            root_real_type) = Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Multiply,
            root_real_type,
            integer_type) = Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Multiply,
            universal_real_type,
            root_real_type) = Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_mixed_real_integer_multiplying_operator_type
           (context,
            Adac.Types.Mixed_Real_Integer_Multiply,
            universal_type,
            root_type) = Adac.Types.INVALID_TYPE_ID,
       "mixed root resolver accepted an unsupported multiplying signature");
    require
      (Adac.Compilation.Types
         .resolve_predefined_real_exponentiating_operator_type
           (context, universal_real_type, integer_type) =
             root_real_type and then
       Adac.Compilation.Types
         .resolve_predefined_real_exponentiating_operator_type
           (context, root_real_type, integer_type) = root_real_type,
       "root-real exponentiating signature did not resolve");
    require
      (Adac.Compilation.Types
         .resolve_predefined_real_exponentiating_operator_type
           (context, universal_real_type, universal_type) =
             Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_real_exponentiating_operator_type
           (context, root_real_type, root_type) =
             Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_real_exponentiating_operator_type
           (context, universal_type, integer_type) = Adac.Types.INVALID_TYPE_ID,
       "root-real exponentiating resolver accepted an unsupported signature");
    require
      (Adac.Compilation.Types.resolve_predefined_unary_integer_operator_type
         (context, universal_type) = root_type and then
       Adac.Compilation.Types.resolve_predefined_unary_integer_operator_type
         (context, root_type) = root_type and then
       Adac.Compilation.Types.resolve_predefined_unary_integer_operator_type
         (context, integer_type) = integer_type,
       "predefined unary integer operator selection is inconsistent");
    require
      (Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, universal_type, universal_type) = root_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, universal_type, root_type) = root_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, root_type, universal_type) = root_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, universal_type, integer_type) = integer_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, integer_type, universal_type) = integer_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, root_type, root_type) = root_type and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, integer_type, integer_type) = integer_type,
       "homogeneous integer operator selection lost universal adaptation");
    require
      (Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, root_type, integer_type) =
             Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types
         .resolve_predefined_homogeneous_binary_integer_operator_type
           (context, integer_type, root_type) =
             Adac.Types.INVALID_TYPE_ID,
       "homogeneous integer operator resolved incompatible specific types");
    require
      (accepts_type (context, integer_type) and then
       accepts_type (context, universal_type) and then
       accepts_type (context, root_type) and then
       accepts_type (context, universal_real_type) and then
       accepts_type (context, root_real_type) and then
       accepts_type (context, boolean_type),
       "type validator rejected a context-owned predefined type");
    require
      (not accepts_type (foreign_context, integer_type) and then
       not accepts_type (foreign_context, universal_type) and then
       not accepts_type (foreign_context, root_type) and then
       not accepts_type (foreign_context, universal_real_type) and then
       not accepts_type (foreign_context, root_real_type) and then
       not accepts_type (foreign_context, boolean_type),
       "type validator accepted a foreign context type");
    require
      (not accepts_type (context, Adac.Types.INVALID_TYPE_ID),
       "type validator accepted the invalid type identifier");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    foreign_context : Adac.Compilation.Context := new_context;
    standard_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "STANDARD");
    other_package_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Other");
    integer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "INTEGER");
    natural_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Natural");
    positive_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "POSITIVE");
    other_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Boolean");
    foreign_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (foreign_context, "Integer");
    integer_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.standard_integer (context);
    boolean_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.standard_boolean (context);
    symbol_count_before_lookup : constant Natural :=
      Adac.Compilation.Symbols.symbol_count (context);
    foreign_rejected : Boolean := False;
  begin
    require
      (Adac.Compilation.Symbols.find (context, "integer") = integer_symbol,
       "existing symbol lookup lost case-insensitive canonicalization");
    require
      (Adac.Compilation.Symbols.find (context, "Missing") =
         Adac.Symbols.INVALID_SYMBOL_ID,
       "existing symbol lookup manufactured an absent symbol");
    require
      (Adac.Compilation.Types.resolve_predefined_type_name
         (context, integer_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, natural_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, positive_symbol) = integer_type,
       "predefined integer subtype lookup lost its shared type identity");
    require
      (Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, integer_symbol) =
           Adac.Compilation.Types.Standard_Integer_Subtype and then
       Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, natural_symbol) =
           Adac.Compilation.Types.Standard_Natural_Subtype and then
       Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, positive_symbol) =
           Adac.Compilation.Types.Standard_Positive_Subtype and then
       Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, other_symbol) =
           Adac.Compilation.Types.Not_Predefined_Integer_Subtype,
       "predefined integer subtype classification is inconsistent");
    require
      (Adac.Compilation.Types.resolve_predefined_type_name
         (context, standard_symbol, integer_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, standard_symbol, natural_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, standard_symbol, positive_symbol) = integer_type,
       "Standard expanded subtype lookup lost shared type identity");
    require
      (Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, standard_symbol, natural_symbol) =
           Adac.Compilation.Types.Standard_Natural_Subtype and then
       Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, other_package_symbol, natural_symbol) =
           Adac.Compilation.Types.Not_Predefined_Integer_Subtype,
       "Standard expanded subtype classification ignored its package prefix");
    require
      (Adac.Semantics.subtype_constraint_lower_bound
         (Adac.Compilation.Semantics.resolve_predefined_subtype_constraint
            (context, standard_symbol, natural_symbol)) = 0 and then
       Adac.Semantics.subtype_constraint_lower_bound
         (Adac.Compilation.Semantics.resolve_predefined_subtype_constraint
            (context, standard_symbol, positive_symbol)) = 1,
       "Standard expanded subtype lookup lost nominal constraints");
    require
      (Adac.Compilation.Types.resolve_predefined_type_name
         (context, other_symbol) = Adac.Types.INVALID_TYPE_ID,
       "predefined type lookup accepted an unsupported name");
    require
      (Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, other_symbol) = boolean_type and then
       Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, standard_symbol, other_symbol) = boolean_type and then
       Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, other_package_symbol, other_symbol) =
           Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, integer_symbol) = Adac.Types.INVALID_TYPE_ID,
       "predefined Boolean lookup is inconsistent");
    require
      (Adac.Compilation.Symbols.symbol_count (context) =
         symbol_count_before_lookup,
       "predefined type lookup interned a semantic-only symbol");

    begin
      declare
        ignored : constant Adac.Types.Type_ID :=
          Adac.Compilation.Types.resolve_predefined_type_name
            (context, foreign_symbol);
        pragma unreferenced (ignored);
      begin
        null;
      end;
    exception
      when Program_Error =>
        foreign_rejected := True;
    end;
    require
      (foreign_rejected,
       "predefined type lookup accepted a foreign symbol");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    false_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "fAlSe");
    true_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "TRUE");
    other_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Boolean");
    foreign_context : Adac.Compilation.Context := new_context;
    foreign_false_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (foreign_context, "False");
    false_resolution : constant
      Adac.Compilation.Types.Predefined_Boolean_Literal_Resolution :=
        Adac.Compilation.Types.resolve_predefined_boolean_literal
          (context, false_symbol);
    true_resolution : constant
      Adac.Compilation.Types.Predefined_Boolean_Literal_Resolution :=
        Adac.Compilation.Types.resolve_predefined_boolean_literal
          (context, true_symbol);
    other_resolution : constant
      Adac.Compilation.Types.Predefined_Boolean_Literal_Resolution :=
        Adac.Compilation.Types.resolve_predefined_boolean_literal
          (context, other_symbol);
    symbol_count_before_lookup : constant Natural :=
      Adac.Compilation.Symbols.symbol_count (context);
    foreign_rejected : Boolean := False;
  begin
    require
      (false_resolution.status =
         Adac.Compilation.Types.Predefined_Boolean_Literal_Found and then
       false_resolution.semantic_type =
         Adac.Compilation.Types.standard_boolean (context) and then
       false_resolution.value = Adac.Types.False_Boolean_Value and then
       true_resolution.status =
         Adac.Compilation.Types.Predefined_Boolean_Literal_Found and then
       true_resolution.semantic_type =
         Adac.Compilation.Types.standard_boolean (context) and then
       true_resolution.value = Adac.Types.True_Boolean_Value,
       "predefined Boolean literals lost type or value identity");
    require
      (Adac.Types.Boolean_Value'pos
         (Adac.Types.False_Boolean_Value) = 0 and then
       Adac.Types.Boolean_Value'pos
         (Adac.Types.True_Boolean_Value) = 1,
       "predefined Boolean value ordering is inconsistent");
    require
      (other_resolution.status =
         Adac.Compilation.Types.Not_Predefined_Boolean_Literal and then
       other_resolution.semantic_type = Adac.Types.INVALID_TYPE_ID,
       "Boolean literal resolver accepted a nonliteral name");
    require
      (Adac.Compilation.Symbols.symbol_count (context) =
         symbol_count_before_lookup,
       "Boolean literal lookup interned a semantic-only symbol");
    begin
      declare
        ignored : constant
          Adac.Compilation.Types.Predefined_Boolean_Literal_Resolution :=
            Adac.Compilation.Types.resolve_predefined_boolean_literal
              (context, foreign_false_symbol);
        pragma unreferenced (ignored);
      begin
        null;
      end;
    exception
      when Program_Error =>
        foreign_rejected := True;
    end;
    require
      (foreign_rejected,
       "Boolean literal resolver accepted a foreign symbol");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context (case_sensitive_identifiers => True);
    standard_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Standard");
    wrong_standard_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "STANDARD");
    canonical_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Integer");
    wrong_case_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "INTEGER");
    natural_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Natural");
    wrong_natural_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "NATURAL");
    positive_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Positive");
    wrong_positive_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "POSITIVE");
    boolean_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Boolean");
    wrong_boolean_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "BOOLEAN");
    false_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "False");
    wrong_false_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "FALSE");
    true_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "True");
    wrong_true_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "TRUE");
    integer_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.standard_integer (context);
    boolean_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.standard_boolean (context);
    symbol_count_before_lookup : constant Natural :=
      Adac.Compilation.Symbols.symbol_count (context);
  begin
    require
      (Adac.Compilation.Symbols.find (context, "Integer") =
         canonical_symbol and then
       Adac.Compilation.Symbols.find (context, "integer") =
         Adac.Symbols.INVALID_SYMBOL_ID,
       "existing symbol lookup ignored the case-sensitive policy");
    require
      (Adac.Compilation.Types.resolve_predefined_type_name
         (context, canonical_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, natural_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, positive_symbol) = integer_type,
       "case-sensitive lookup rejected canonical Standard subtype spelling");
    require
      (Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, natural_symbol) =
           Adac.Compilation.Types.Standard_Natural_Subtype and then
       Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (context, positive_symbol) =
           Adac.Compilation.Types.Standard_Positive_Subtype,
       "case-sensitive predefined subtype classification failed");
    require
      (Adac.Compilation.Types.resolve_predefined_type_name
         (context, standard_symbol, natural_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, standard_symbol, positive_symbol) = integer_type and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, wrong_standard_symbol, natural_symbol) =
           Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, standard_symbol, wrong_natural_symbol) =
           Adac.Types.INVALID_TYPE_ID,
       "case-sensitive Standard expanded-name lookup ignored spelling");
    require
      (Adac.Compilation.Types.resolve_predefined_type_name
         (context, wrong_case_symbol) = Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, wrong_natural_symbol) = Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types.resolve_predefined_type_name
         (context, wrong_positive_symbol) = Adac.Types.INVALID_TYPE_ID,
       "case-sensitive lookup accepted noncanonical Standard spelling");
    require
      (Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, boolean_symbol) = boolean_type and then
       Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, standard_symbol, boolean_symbol) = boolean_type and then
       Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, wrong_boolean_symbol) = Adac.Types.INVALID_TYPE_ID and then
       Adac.Compilation.Types.resolve_predefined_boolean_type_name
         (context, wrong_standard_symbol, boolean_symbol) =
           Adac.Types.INVALID_TYPE_ID,
       "case-sensitive Boolean lookup ignored canonical spelling");
    require
      (Adac.Compilation.Types.resolve_predefined_boolean_literal
         (context, false_symbol).status =
           Adac.Compilation.Types.Predefined_Boolean_Literal_Found and then
       Adac.Compilation.Types.resolve_predefined_boolean_literal
         (context, true_symbol).status =
           Adac.Compilation.Types.Predefined_Boolean_Literal_Found and then
       Adac.Compilation.Types.resolve_predefined_boolean_literal
         (context, wrong_false_symbol).status =
           Adac.Compilation.Types.Not_Predefined_Boolean_Literal and then
       Adac.Compilation.Types.resolve_predefined_boolean_literal
         (context, wrong_true_symbol).status =
           Adac.Compilation.Types.Not_Predefined_Boolean_Literal,
       "case-sensitive Boolean literal lookup ignored canonical spelling");
    require
      (Adac.Compilation.Symbols.symbol_count (context) =
         symbol_count_before_lookup,
       "case-sensitive predefined lookup changed symbol publication");
  end;
end Run_Parser_And_Resource_Contracts;
