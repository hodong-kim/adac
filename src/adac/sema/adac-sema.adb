-- ============================================================================
-- adac-sema.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;
with Adac.Diagnostics;

package body Adac.Sema is

  function analyze (unit : Adac.AST.Compilation_Unit) return Boolean is
    procedure_name : constant String :=
      Ada.Strings.Unbounded.to_string (unit.procedure_name);
    end_name       : constant String :=
      Ada.Strings.Unbounded.to_string (unit.end_name);
  begin
    if procedure_name /= end_name then
      Adac.Diagnostics.error
        ("procedure name and end name do not match");
      return False;
    end if;

    for statement of unit.statements loop
      case statement.kind is
        when Adac.AST.Null_Statement =>
          null;
      end case;
    end loop;

    return True;
  end analyze;

end Adac.Sema;
