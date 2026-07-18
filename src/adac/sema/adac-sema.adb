-- ============================================================================
-- adac-sema.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;
with Ada.Strings.Unbounded;
with Adac.Diagnostics;

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
    (unit             : Adac.AST.Compilation_Unit;
     language_options : Adac.Language.Options)
  return Boolean is
    procedure_name : constant String :=
      Ada.Strings.Unbounded.to_string (unit.procedure_name);
    end_name       : constant String :=
      Ada.Strings.Unbounded.to_string (unit.end_name);
  begin
    if not identifiers_match (procedure_name, end_name, language_options) then
      Adac.Diagnostics.error
        ("procedure name and end name do not match");
      return False;
    end if;

    for statement of unit.statements loop
      case statement.kind is
        when Adac.AST.Null_Statement |
             Adac.AST.Return_Statement =>
          null;
      end case;
    end loop;

    return True;
  end analyze;

end Adac.Sema;
