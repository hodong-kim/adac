-- ============================================================================
-- adac_internal_tests-run_frontend_rejections.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_Frontend_Rejections is
begin
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
            maximum_symbols   => 1,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    first     : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Main");
    duplicate : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "main");
  begin
    require
      (first = duplicate,
       "full symbol budget rejected an existing canonical spelling");
    require
      (rejects_new_symbol_at_limit (context, "other"),
       "full symbol budget accepted a distinct spelling");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "rejected symbol insertion changed the symbol store");
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
            maximum_symbols   => 0,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/pipeline/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "zero symbol limit did not reject the first identifier");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "zero symbol limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 0,
       "zero symbol limit published a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "zero symbol limit published an AST node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/lexing/identifier-leading-underscore/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "invalid identifier spelling did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "invalid identifier spelling did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 0,
       "invalid identifier spelling published a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "invalid identifier spelling published an AST node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/lexing/decimal-integer-literal-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "decimal integer literal expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "decimal integer literal did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "decimal integer literal changed procedure symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "decimal integer literal published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "decimal integer literal published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/lexing/decimal-real-literal-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "decimal real literal expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "decimal real literal did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "decimal real literal changed procedure symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "decimal real literal published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "decimal real literal published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/lexing/based-real-literal-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "based real literal expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "based real literal did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "based real literal changed procedure symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "based real literal published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "based real literal published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/lexing/character-literal-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "character literal expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "character literal did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "character literal changed procedure symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "character literal published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "character literal published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/lexing/string-literal-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "string literal expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "string literal did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "string literal changed procedure symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "string literal published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "string literal published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/names/selected-name-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "selected name expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "selected name did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "selected name did not intern each identifier component");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "selected name published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "selected name published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/names/attribute-name-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "attribute reference did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "attribute reference did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "attribute reference did not intern identifier components");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "attribute reference published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "attribute reference published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/names/selected-name-character-selector-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "character selector did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "character selector did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "character selector was interned as an identifier");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "character selector published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "character selector published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/names/selected-name-operator-selector-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "operator selector did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "operator selector did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "operator selector was interned as an identifier");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "operator selector published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "operator selector published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/names/" &
         "selected-name-word-operator-selector-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "word operator selector did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "word operator selector did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "word operator selector was interned as an identifier");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "word operator selector published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "word operator selector published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/names/selected-name-invalid-operator-selector/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "invalid operator selector did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "invalid operator selector did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "invalid operator selector published a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "invalid operator selector published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "invalid operator selector published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/names/selected-name-malformed-operator-selector/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "malformed operator selector did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "malformed operator selector did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "malformed operator selector published a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "malformed operator selector published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "malformed operator selector published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/names/explicit-dereference-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "explicit dereference did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "explicit dereference did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "explicit dereference changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "explicit dereference published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "explicit dereference published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/names/parenthesized-name-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "parenthesized name form did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "parenthesized name form did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "parenthesized content changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "parenthesized name form published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "parenthesized name form published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/aggregates/" &
         "parenthesized-range-association-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "range and association staging did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "range and association staging did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "range and association content changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "range and association staging published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "range and association staging published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/general/" &
                  "operator-expression-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "operator expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "operator expression did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "operator expression changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "operator expression published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "operator expression published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/general/" &
                  "membership-expression-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "membership expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "membership expression did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "membership expression changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "membership expression published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "membership expression published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/general/" &
                  "short-circuit-and-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "short-circuit expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "short-circuit expression did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "short-circuit expression changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "short-circuit expression published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "short-circuit expression published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/general/" &
         "parenthesized-expression-nested-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "parenthesized expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "parenthesized expression did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "parenthesized expression changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "parenthesized expression published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "parenthesized expression published a semantic entity");
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
        (context,
         "tests/expressions/general/" &
         "parenthesized-expression-nested-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "expression nesting limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "expression nesting limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "expression nesting limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "expression nesting limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "expression nesting limit published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/general/" &
                  "qualified-expression-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "qualified expression did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "qualified expression did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "qualified expression changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "qualified expression published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "qualified expression published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting => 0,
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
        (context, "tests/expressions/general/" &
                  "qualified-expression-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "qualified expression nesting limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "qualified expression nesting limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "qualified expression nesting limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "qualified expression nesting limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "qualified expression nesting limit published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/aggregates/" &
                  "aggregate-named-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "classic aggregate did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "classic aggregate did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "classic aggregate changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "classic aggregate published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "classic aggregate published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/aggregates/" &
         "aggregate-discrete-subtype-choice-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "discrete subtype aggregate choice did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "discrete subtype aggregate choice did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "discrete subtype aggregate choice changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "discrete subtype aggregate choice published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "discrete subtype aggregate choice published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/names/attribute-range-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "Range attribute did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "Range attribute did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "Range attribute was interned as an identifier");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "Range attribute published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "Range attribute published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/aggregates/" &
                  "delta-aggregate-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "delta aggregate did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "delta aggregate did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "delta aggregate changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "delta aggregate published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "delta aggregate published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/names/attribute-delta-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "Delta attribute did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "Delta attribute did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "Delta attribute was interned as an identifier");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "Delta attribute published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "Delta attribute published a semantic entity");
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
                  "aggregate-nested-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "aggregate nesting limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "aggregate nesting limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "aggregate nesting limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "aggregate nesting limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "aggregate nesting limit published a semantic entity");
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
                  "delta-aggregate-nested-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "delta aggregate nesting limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "delta aggregate nesting limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "delta aggregate nesting limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "delta aggregate nesting limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "delta aggregate nesting limit published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/aggregates/" &
                  "bracket-aggregate-positional-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "bracket aggregate did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "bracket aggregate did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "bracket aggregate changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "bracket aggregate published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "bracket aggregate published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/expressions/iterated/" &
                  "iterated-bracket-association-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "iterated bracket association did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "iterated bracket association did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "iterated defining identifier was published as a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "iterated bracket association published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "iterated bracket association published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-bracket-association-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "iterated of bracket association did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "iterated of bracket association did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "iterated of defining identifier was published as a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "iterated of bracket association published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "iterated of bracket association published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-reverse-bracket-association-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "of reverse bracket association did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "of reverse bracket association did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "of reverse defining identifier was published as a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "of reverse bracket association published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "of reverse bracket association published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-reverse-filter-bracket-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "of reverse filter bracket association did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "of reverse filter bracket did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "of reverse filter changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "of reverse filter bracket association published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "of reverse filter bracket association published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-reverse-bracket-range-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in reverse bracket range did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in reverse bracket range did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "in reverse defining identifier was published as a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in reverse bracket range published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in reverse bracket range published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-filter-bracket-range-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in filter bracket range did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in filter bracket range did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "in filter changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in filter bracket range published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in filter bracket range published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-subtype-mark-reverse-filter-bracket-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in subtype reverse filter bracket did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in subtype reverse filter bracket did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "in subtype reverse filter changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in subtype reverse filter bracket published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in subtype reverse filter bracket published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-null-exclusion-bracket-operator-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in null exclusion bracket did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in null exclusion bracket did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "in null exclusion changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in null exclusion bracket published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in null exclusion bracket published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-range-constraint-bracket-operator-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in range constraint bracket did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in range constraint bracket did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 7,
       "in range constraint changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in range constraint bracket published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in range constraint bracket published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-use-key-bracket-operator-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in use-key bracket did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in use-key bracket did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "use-key expression changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in use-key bracket published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in use-key bracket published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-access-null-exclusion-bracket-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in access null exclusion bracket did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in access null exclusion did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "access subtype changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in access null exclusion published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in access null exclusion published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-access-protected-procedure-bracket-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in protected procedure access did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in protected procedure access did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "protected procedure access changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in protected procedure access published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in protected procedure access published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-access-protected-function-bracket-unsupported/" &
         "input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in protected function access did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in protected function access did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "protected function access changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in protected function access published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in protected function access published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-access-function-result-access-bracket-" &
         "unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in function access result did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in function access result did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "function access result changed name symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in function access result published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in function access result published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-access-function-result-protected-procedure-" &
         "bracket-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in function procedure result did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in function procedure result did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "function procedure result changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in function procedure result published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in function procedure result published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-access-function-basic-formal-part-bracket-" &
         "unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "in function basic formal part did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "in function basic formal part did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "basic formal part changed defining identifier publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "in function basic formal part published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "in function basic formal part published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-in-access-function-defining-identifier-list-" &
         "bracket-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "defining-identifier list did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "defining-identifier list did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "defining-identifier list changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "defining-identifier list published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "defining-identifier list published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-access-procedure-multiple-formals-" &
         "parenthesized-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "multiple formal specifications did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "multiple formal specifications did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "multiple formal specifications changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "multiple formal specifications published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "multiple formal specifications published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-access-procedure-formal-null-exclusion-" &
         "parenthesized-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal null exclusion did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal null exclusion did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "formal null exclusion changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal null exclusion published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal null exclusion published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-access-procedure-formal-in-mode-" &
         "parenthesized-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal explicit in mode did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal explicit in mode did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "formal explicit in mode changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal explicit in mode published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal explicit in mode published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-access-procedure-formal-aliased-" &
         "parenthesized-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal aliased modifier did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal aliased modifier did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "formal aliased modifier changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal aliased modifier published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal aliased modifier published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-access-procedure-formal-modes-" &
         "parenthesized-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal parameter modes did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal parameter modes did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "formal parameter modes changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal parameter modes published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal parameter modes published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-access-procedure-formal-defaults-" &
         "parenthesized-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal parameter defaults did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal parameter defaults did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 7,
       "formal parameter defaults changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal parameter defaults published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal parameter defaults published a semantic entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/expressions/iterated/" &
         "iterated-of-access-procedure-formal-access-object-" &
         "parenthesized-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal access-object parameters did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal access-object parameters did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 7,
       "formal access-object parameters changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal access-object parameters published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal access-object parameters published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/expressions/iterated/" &
      "iterated-of-access-procedure-formal-access-procedure-" &
      "parenthesized-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal access-procedure parameter did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal access-procedure parameter did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 5,
       "formal access-procedure parameter changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal access-procedure parameter published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal access-procedure parameter published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/expressions/iterated/" &
      "iterated-of-access-procedure-formal-access-procedure-" &
      "parenthesized-unsupported/input.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting => 1,
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
       "profile nesting limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "profile nesting limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "profile nesting limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "profile nesting limit published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "profile nesting limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/expressions/iterated/" &
      "iterated-of-access-procedure-formal-access-function-" &
      "parenthesized-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal access-function parameter did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal access-function parameter did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 6,
       "formal access-function parameter changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal access-function parameter published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal access-function parameter published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/expressions/iterated/" &
      "iterated-of-access-procedure-formal-aspects-" &
      "parenthesized-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "formal parameter aspects did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "formal parameter aspects did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 8,
       "formal parameter aspects changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "formal parameter aspects published an AST node");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "formal parameter aspects published a semantic entity");
  end;
  declare
    path : constant String :=
      "tests/declarations/package/" &
      "package-body-declarative-recovery-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "package-body declarative recovery accepted invalid source");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 2,
       "package-body declarative recovery lost independent diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 0,
       "package-body declarative recovery published defining symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "package-body declarative recovery published a partial AST");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package-body declarative recovery published semantic state");
  end;
  declare
    path : constant String :=
      "tests/statements/" &
      "procedure-body-statement-recovery-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "statement-sequence recovery accepted invalid source");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 2,
       "statement-sequence recovery lost independent diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "statement-sequence recovery changed procedure symbol ownership");
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "statement-sequence recovery lost resumed valid statements or " &
         "published a parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "statement-sequence recovery published semantic state");
  end;
  declare
    path : constant String :=
      "tests/context/context-empty-with-recovery-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "context-item recovery accepted invalid source");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 2,
       "context-item recovery lost independent diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "context-item recovery changed unit symbol ownership");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "context-item recovery lost resumed unit syntax or published a root");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "context-item recovery published semantic state");
  end;
end Run_Frontend_Rejections;
