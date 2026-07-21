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
with Adac.Frontend;
with Adac.Language;
with Adac.Sema;
with Adac.Source;

procedure adac_internal_tests is

  use type Adac.Source.Source_File_ID;
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

  context_a : Adac.Compilation.Context := new_context;
  context_b : Adac.Compilation.Context := new_context;

begin
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
    unit    : Adac.AST.Compilation_Unit;
  begin
    unit.procedure_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("Main");
    unit.end_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");

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
    unit    : Adac.AST.Compilation_Unit;
  begin
    unit.procedure_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("Main");
    unit.end_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");

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
          (Ada.Strings.Unbounded.to_string (result.unit.procedure_name) =
           "main",
           "successful parse returned the wrong AST payload");
    end case;
  end;

end adac_internal_tests;
