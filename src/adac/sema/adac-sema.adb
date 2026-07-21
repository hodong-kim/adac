-- ============================================================================
-- adac-sema.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation.Diagnostics;
with Adac.Compilation.Syntax;
with Adac.Symbols;

package body Adac.Sema is

  use type Adac.Symbols.Symbol_ID;

  function analyze
    (context : in out Adac.Compilation.Context;
     unit    : Adac.AST.Compilation_Unit)
  return Analysis_Result is
  begin
    Adac.Compilation.Syntax.validate (context, unit);

    if unit.procedure_symbol /= unit.end_symbol then
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
