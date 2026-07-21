-- ============================================================================
-- adac-ast.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.AST is

  procedure validate (value : Compilation_Unit) is
  begin
    Adac.Symbols.validate (value.procedure_symbol);
    Adac.Symbols.validate (value.end_symbol);

    if value.statements.is_empty then
      raise Program_Error with "Adac.AST: statement list is empty";
    end if;

    Adac.Source.validate (value.span);

    for statement of value.statements loop
      Adac.Source.validate (statement.span);

      if not Adac.Source.contains (value.span, statement.span) then
        raise Program_Error with
          "Adac.AST: statement span is outside compilation unit";
      end if;
    end loop;
  end validate;

end Adac.AST;
