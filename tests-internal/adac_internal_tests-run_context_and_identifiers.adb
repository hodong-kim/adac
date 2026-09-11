-- ============================================================================
-- adac_internal_tests-run_context_and_identifiers.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_Context_And_Identifiers is
begin
  declare
    uninitialized : Adac.Compilation.Context;
  begin
    require
      (not accepts_language_options (uninitialized),
       "default-initialized context exposed language options");
    require
      (not accepts_diagnostic_write (uninitialized),
       "default-initialized context accepted a diagnostic");
    require
      (not accepts_source_registration (uninitialized),
       "default-initialized context accepted a source path");
    require
      (not accepts_symbol_interning (uninitialized, "main"),
       "default-initialized context accepted a symbol");
    require
      (not accepts_ast_query (uninitialized),
       "default-initialized context exposed AST storage");
    require
      (not accepts_semantic_query (uninitialized),
       "default-initialized context exposed semantic storage");
  end;

  require
    (Adac.Compilation.Diagnostics.error_count (context_a) = 0,
     "context A did not start with zero diagnostics");
  require
    (Adac.Compilation.Diagnostics.error_count (context_b) = 0,
     "context B did not start with zero diagnostics");
  require
    (Adac.Compilation.resource_limits
       (context_a).maximum_source_characters_per_file =
     Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
     "context A did not receive the default source character limit");
  require
    (Adac.Compilation.resource_limits
       (context_a).maximum_expression_nesting =
     Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
     "context A did not receive the default expression nesting limit");
  require
    (Adac.Compilation.resource_limits
       (context_a).maximum_profile_nesting =
     Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
     "context A did not receive the default profile nesting limit");
  require
    (Adac.Compilation.resource_limits (context_a).maximum_symbols =
     Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
     "context A did not receive the default symbol limit");
  require
    (Adac.Compilation.resource_limits (context_a).maximum_ast_nodes =
     Adac.Resources.DEFAULT_MAXIMUM_AST_NODES,
     "context A did not receive the default AST node limit");

  Adac.Compilation.Diagnostics.error (context_a, "context A first error");

  require
    (Adac.Compilation.Diagnostics.error_count (context_a) = 1,
     "context A did not record its first diagnostic");
  require
    (Adac.Compilation.Diagnostics.error_count (context_b) = 0,
     "context A diagnostic leaked into context B");

  Adac.Compilation.Diagnostics.error (context_a, "context A second error");
  Adac.Compilation.Diagnostics.error (context_b, "context B error");

  require
    (Adac.Compilation.Diagnostics.error_count (context_a) = 2,
     "context A diagnostic count is incorrect");
  require
    (Adac.Compilation.Diagnostics.error_count (context_b) = 1,
     "context B diagnostic count is incorrect");
  require
    (Adac.Compilation.Diagnostics.has_error (context_a),
     "context A did not report an error state");
  require
    (Adac.Compilation.Diagnostics.has_error (context_b),
     "context B did not report an error state");

  require
    (Adac.Compilation.Sources.file_count (context_a) = 0,
     "context A did not start with an empty source registry");
  require
    (Adac.Compilation.Sources.file_count (context_b) = 0,
     "context B did not start with an empty source registry");

  declare
    source_a : constant Adac.Source.Source_File_ID
             := Adac.Compilation.Sources.register_file
                  (context_a, "alpha.adb");
    source_a_again : constant Adac.Source.Source_File_ID
                   := Adac.Compilation.Sources.register_file
                        (context_a, "alpha.adb");
    source_a_second : constant Adac.Source.Source_File_ID
                    := Adac.Compilation.Sources.register_file
                         (context_a, "second.adb");
    source_b : constant Adac.Source.Source_File_ID
             := Adac.Compilation.Sources.register_file
                  (context_b, "alpha.adb");
    position : constant Adac.Source.Position
             := Adac.Source.make_position (source_a, 7, 9);
    last_position : constant Adac.Source.Position
                  := Adac.Source.make_position (source_a, 8, 2);
    foreign_position : constant Adac.Source.Position
                     := Adac.Source.make_position (source_b, 8, 2);
    span : constant Adac.Source.Span :=
      Adac.Source.make_span (position, last_position);
  begin
    require
      (source_a = source_a_again,
       "duplicate source path received a different identifier");
    require
      (source_a /= source_a_second,
       "different source paths received the same identifier");
    require
      (Adac.Compilation.Sources.file_count (context_a) = 2,
       "context A source file count is incorrect");
    require
      (Adac.Compilation.Sources.file_count (context_b) = 1,
       "context B source file count is incorrect");
    require
      (source_a /= source_b,
       "different contexts received the same source identifier");
    require
      (Adac.Compilation.Sources.file_path (context_a, source_a) =
       "alpha.adb",
       "context A source path lookup failed");
    require
      (Adac.Compilation.Sources.file_path (context_b, source_b) =
       "alpha.adb",
       "context B source path lookup failed");
    require
      (Adac.Compilation.Sources.position_image (context_a, position) =
       "alpha.adb:7:9",
       "source position image is incorrect");
    require
      (not accepts_file_id (context_b, source_a),
       "context B accepted a source identifier owned by context A");
    require
      (not accepts_file_id
         (context_a, Adac.Source.INVALID_SOURCE_FILE_ID),
       "context A accepted the invalid source identifier");
    require
      (Adac.Source.first_position (span) = position and then
       Adac.Source.last_position (span) = last_position,
       "source span endpoints changed during construction");
    require
      (accepts_span (context_a, span),
       "source registry rejected its own span");
    require
      (not accepts_span (context_b, span),
       "source registry accepted a foreign span");
    require
      (not accepts_span (last_position, position),
       "source span accepted reversed endpoints");
    require
      (not accepts_span (position, foreign_position),
       "source span accepted endpoints from different files");
  end;

  declare
    symbol_a : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context_a, "Main");
    symbol_a_again : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context_a, "main");
    symbol_b : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context_b, "main");
  begin
    require
      (symbol_a = symbol_a_again,
       "case-insensitive context assigned different symbol IDs");
    require
      (symbol_a /= symbol_b,
       "different contexts assigned the same owned symbol ID");
    require
      (Adac.Compilation.Symbols.spelling (context_a, symbol_a) = "Main",
       "symbol store did not preserve the first spelling");
    require
      (Adac.Compilation.Symbols.symbol_count (context_a) = 1,
       "case-insensitive symbol store retained a duplicate");
    require
      (not accepts_symbol (context_b, symbol_a),
       "symbol store accepted a foreign symbol identifier");
    require
      (not accepts_symbol_interning (context_a, ""),
       "symbol store accepted an empty spelling");
  end;
end Run_Context_And_Identifiers;
