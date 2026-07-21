-- ============================================================================
-- adac-sema.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;
with Ada.Strings.Unbounded;

with Adac.Compilation.Diagnostics;
with Adac.Language;

package body Adac.Sema is

  function identifiers_match
    (left             : String;
     right            : String;
     language_options : Adac.Language.Options)
  return Boolean is
  begin
    if language_options.case_sensitive_identifiers then
      return left = right;
    end if;

    return Ada.Characters.Handling.To_Lower (left) =
           Ada.Characters.Handling.To_Lower (right);
  end identifiers_match;

  function analyze
    (context : in out Adac.Compilation.Context;
     unit    : Adac.AST.Compilation_Unit)
  return Analysis_Result is
    language_options : constant Adac.Language.Options
                     := Adac.Compilation.language_options (context);
    procedure_name : constant String :=
      Ada.Strings.Unbounded.to_string (unit.procedure_name);
    end_name       : constant String :=
      Ada.Strings.Unbounded.to_string (unit.end_name);
  begin
    if not identifiers_match (procedure_name, end_name, language_options) then
      Adac.Compilation.Diagnostics.error
        (context, "procedure name and end name do not match");
      return Analysis_Rejected;
    end if;

    for statement of unit.statements loop
      case statement.kind is
        when Adac.AST.Null_Statement |
             Adac.AST.Return_Statement =>
          null;
      end case;
    end loop;

    return Analysis_Succeeded;
  end analyze;

end Adac.Sema;
