-- ============================================================================
-- adac_internal_tests-run_bootstrap_resource_boundaries.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_Bootstrap_Resource_Boundaries is
begin
  declare
    path : constant String := "src/adac/ast/adac-ast.ads";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "AST package complete frontend did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "AST package complete frontend recorded diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1_040,
       "AST package complete frontend changed symbol publication:" &
         Natural'Image
           (Adac.Compilation.Symbols.symbol_count (context)));
    require
      (Adac.Compilation.Syntax.node_count (context) = 6_070,
       "AST package complete frontend changed AST publication:" &
         Natural'Image
           (Adac.Compilation.Syntax.node_count (context)));
    require
      (Adac.Compilation.Syntax.kind_of (context, result.root) =
         Adac.AST.Compilation_Unit_Node,
       "AST package complete frontend lost its compilation-unit root");
    Adac.Compilation.Syntax.validate (context, result.root);
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "AST package complete frontend published semantics");
  end;

  declare
    path : constant String := "src/adac/ast/adac-ast.ads";
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
            maximum_symbols => 1_039,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "AST package complete frontend symbol limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "AST package complete frontend symbol limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1_039,
       "AST package complete frontend symbol limit exceeded its budget");
    require
      (Adac.Compilation.Syntax.node_count (context) = 6_064,
       "AST package complete frontend symbol limit changed child syntax:" &
         Natural'Image
           (Adac.Compilation.Syntax.node_count (context)));
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "AST package complete frontend symbol limit published semantics");
  end;

  declare
    path : constant String := "src/adac/ast/adac-ast.ads";
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
            maximum_ast_nodes => 6_069));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "AST package complete frontend AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "AST package complete frontend AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1_040,
       "AST package complete frontend AST limit changed symbol publication:" &
         Natural'Image
           (Adac.Compilation.Symbols.symbol_count (context)));
    require
      (Adac.Compilation.Syntax.node_count (context) = 6_069,
       "AST package complete frontend AST limit published partial root:" &
         Natural'Image
           (Adac.Compilation.Syntax.node_count (context)));
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "AST package complete frontend AST limit published semantics");
  end;

  declare
    path : constant String := "src/adac/ast/adac-ast.ads";
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
            maximum_ast_nodes => 14));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "private-type parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "private-type parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 10,
       "private-type parent limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 14,
       "private-type parent limit published a partial declaration");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "private-type parent limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/ast/adac-ast.ads";
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
            maximum_ast_nodes => 16));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "deferred-constant parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "deferred-constant parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 11,
       "deferred-constant parent limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 16,
       "deferred-constant parent limit published a partial declaration");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "deferred-constant parent limit published a semantic entity");
  end;

  declare
    path : constant String :=
      "tests/declarations/package/" &
      "package-body-procedure-nested-actual-current/input.adb";
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
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "nested parenthesized name limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "nested parenthesized name limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 11,
       "nested parenthesized name limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 15,
       "nested parenthesized name limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "nested parenthesized name limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac.ads";
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
            maximum_ast_nodes => 6));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "package parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "package parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "package parent AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 6,
       "package parent AST limit published a partial package");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package parent AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac.ads";
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
            maximum_ast_nodes => 7));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "package root AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "package root AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "package root AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 7,
       "package root AST limit published a partial root");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package root AST limit published a semantic entity");
  end;
end Run_Bootstrap_Resource_Boundaries;
