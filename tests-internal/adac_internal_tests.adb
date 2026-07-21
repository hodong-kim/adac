-- ============================================================================
-- adac_internal_tests.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Compilation;
with Adac.Compilation.Diagnostics;
with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;
with Adac.Frontend;
with Adac.IR;
with Adac.IR.Builder;
with Adac.Language;
with Adac.Sema;
with Adac.Source;
with Adac.Symbols;

procedure adac_internal_tests is

  use type Adac.Source.Source_File_ID;
  use type Adac.Source.Position;
  use type Adac.Symbols.Symbol_ID;
  use type Adac.Frontend.Parse_Status;
  use type Adac.Sema.Analysis_Result;

  function new_context
    (case_sensitive_identifiers : Boolean := False)
  return Adac.Compilation.Context
  is
    options : constant Adac.Language.Options :=
      (case_sensitive_identifiers => case_sensitive_identifiers);
  begin
    return Adac.Compilation.create (options);
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

  procedure initialize_minimal_unit
    (context        : in out Adac.Compilation.Context;
     value          : in out Adac.AST.Compilation_Unit;
     procedure_name : String;
     end_name       : String;
     unit_span      : Adac.Source.Span;
     statement_span : Adac.Source.Span)
  is
  begin
    value.procedure_symbol :=
      Adac.Compilation.Symbols.intern (context, procedure_name);
    value.end_symbol :=
      Adac.Compilation.Symbols.intern (context, end_name);
    value.span := unit_span;
    value.statements.append
      (Adac.AST.Statement'
         (kind => Adac.AST.Null_Statement,
          span => statement_span));
  end initialize_minimal_unit;

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
    (value : Adac.AST.Compilation_Unit) return Boolean
  is
  begin
    Adac.AST.validate (value);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_unit;

  function accepts_analysis
    (context : in out Adac.Compilation.Context;
     unit    : Adac.AST.Compilation_Unit)
  return Boolean is
    result : Adac.Sema.Analysis_Result;
    pragma unreferenced (result);
  begin
    result := Adac.Sema.analyze (context, unit);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_analysis;

  function accepts_lowering
    (context : Adac.Compilation.Context;
     unit    : Adac.AST.Compilation_Unit)
  return Boolean
  is
    module : Adac.IR.Module;
    pragma unreferenced (module);
  begin
    module := Adac.IR.Builder.build (context, unit);
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

  context_a : Adac.Compilation.Context := new_context;
  context_b : Adac.Compilation.Context := new_context;

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
  end;

  require
    (Adac.Compilation.Diagnostics.error_count (context_a) = 0,
     "context A did not start with zero diagnostics");
  require
    (Adac.Compilation.Diagnostics.error_count (context_b) = 0,
     "context B did not start with zero diagnostics");

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
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "matching.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    unit    : Adac.AST.Compilation_Unit;
  begin
    initialize_minimal_unit
      (context, unit, "Main", "main", unit_span, statement_span);

    require
      (Adac.Sema.analyze (context, unit) =
       Adac.Sema.Analysis_Succeeded,
       "semantic analysis rejected matching Ada identifiers");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "successful semantic analysis recorded a diagnostic");
  end;

  declare
    context : Adac.Compilation.Context := new_context (True);
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "case-sensitive.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    unit    : Adac.AST.Compilation_Unit;
  begin
    initialize_minimal_unit
      (context, unit, "Main", "main", unit_span, statement_span);

    require
      (Adac.Sema.analyze (context, unit) =
       Adac.Sema.Analysis_Rejected,
       "semantic analysis accepted mismatched case-sensitive identifiers");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "rejected semantic analysis did not record one diagnostic");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "ast-validation.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    outside_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 5, 1),
       Adac.Source.make_position (file_id, 5, 5));
    valid_unit      : Adac.AST.Compilation_Unit;
    invalid_procedure : Adac.AST.Compilation_Unit;
    invalid_end       : Adac.AST.Compilation_Unit;
    empty_body      : Adac.AST.Compilation_Unit;
    invalid_span    : Adac.AST.Compilation_Unit;
    outside_child   : Adac.AST.Compilation_Unit;
  begin
    initialize_minimal_unit
      (context, valid_unit, "main", "main", unit_span, statement_span);
    initialize_minimal_unit
      (context,
       invalid_procedure,
       "main",
       "main",
       unit_span,
       statement_span);
    initialize_minimal_unit
      (context, invalid_end, "main", "main", unit_span, statement_span);
    invalid_procedure.procedure_symbol := Adac.Symbols.INVALID_SYMBOL_ID;
    invalid_end.end_symbol := Adac.Symbols.INVALID_SYMBOL_ID;

    initialize_minimal_unit
      (context, empty_body, "main", "main", unit_span, statement_span);
    empty_body.statements.clear;

    initialize_minimal_unit
      (context,
       invalid_span,
       "main",
       "main",
       Adac.Source.INVALID_SPAN,
       statement_span);
    initialize_minimal_unit
      (context,
       outside_child,
       "main",
       "main",
       unit_span,
       outside_span);

    require
      (accepts_unit (valid_unit),
       "AST validator rejected a valid minimal compilation unit");
    require
      (not accepts_unit (invalid_procedure),
       "AST validator accepted an invalid procedure symbol");
    require
      (not accepts_unit (invalid_end),
       "AST validator accepted an invalid end symbol");
    require
      (not accepts_unit (empty_body),
       "AST validator accepted an empty statement list");
    require
      (not accepts_unit (invalid_span),
       "AST validator accepted an invalid unit span");
    require
      (not accepts_lowering (context, invalid_span),
       "IR builder accepted an invalid AST span");
    require
      (not accepts_unit (outside_child),
       "AST validator accepted a statement outside its unit span");
  end;

  declare
    owner_context   : Adac.Compilation.Context := new_context;
    foreign_context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (owner_context, "foreign-span.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    foreign_symbol_unit : Adac.AST.Compilation_Unit;
    foreign_span_unit   : Adac.AST.Compilation_Unit;
  begin
    initialize_minimal_unit
      (owner_context,
       foreign_symbol_unit,
       "main",
       "main",
       unit_span,
       statement_span);
    initialize_minimal_unit
      (foreign_context,
       foreign_span_unit,
       "main",
       "main",
       unit_span,
       statement_span);

    require
      (not accepts_analysis (foreign_context, foreign_symbol_unit),
       "semantic analysis accepted a foreign symbol");
    require
      (not accepts_analysis (foreign_context, foreign_span_unit),
       "semantic analysis accepted a foreign source span");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected the valid minimal compilation unit");

    case result.status is
      when Adac.Frontend.Parse_Rejected =>
        raise Program_Error with "successful parse has no AST payload";

      when Adac.Frontend.Parse_Succeeded =>
        require
          (Adac.Compilation.Symbols.spelling
             (context, result.unit.procedure_symbol) =
           "main",
           "successful parse returned the wrong AST payload");

        declare
          unit_first : constant Adac.Source.Position :=
            Adac.Source.first_position (result.unit.span);
          unit_last : constant Adac.Source.Position :=
            Adac.Source.last_position (result.unit.span);
          statement : constant Adac.AST.Statement :=
            result.unit.statements.first_element;
          statement_first : constant Adac.Source.Position :=
            Adac.Source.first_position (statement.span);
          statement_last : constant Adac.Source.Position :=
            Adac.Source.last_position (statement.span);
        begin
          require
            (unit_first.line = 1 and then unit_first.column = 1 and then
             unit_last.line = 4 and then unit_last.column = 9,
             "parser returned the wrong compilation-unit span");
          require
            (statement_first.line = 3 and then
             statement_first.column = 3 and then
             statement_last.line = 3 and then
             statement_last.column = 7,
             "parser returned the wrong statement span");
        end;
    end case;
  end;

  declare
    valid_module : Adac.IR.Module;
    empty_name   : Adac.IR.Module;
    empty_code   : Adac.IR.Module;
  begin
    valid_module.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_module.instructions.append
      (Adac.IR.Instruction'(kind => Adac.IR.Null_Instruction));

    empty_name.instructions.append
      (Adac.IR.Instruction'(kind => Adac.IR.Null_Instruction));

    empty_code.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");

    require
      (accepts_module (valid_module),
       "IR validator rejected a valid minimal module");
    require
      (not accepts_module (empty_name),
       "IR validator accepted an empty entry name");
    require
      (not accepts_module (empty_code),
       "IR validator accepted an empty instruction list");
  end;

end adac_internal_tests;
