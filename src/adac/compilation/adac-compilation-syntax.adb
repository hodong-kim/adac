-- ============================================================================
-- adac-compilation-syntax.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;

package body Adac.Compilation.Syntax is

  procedure validate
    (self : Context;
     unit : Adac.AST.Compilation_Unit)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.validate (unit);
    Adac.Compilation.Symbols.validate_symbol (self, unit.procedure_symbol);
    Adac.Compilation.Symbols.validate_symbol (self, unit.end_symbol);
    Adac.Compilation.Sources.validate_span (self, unit.span);

    for statement of unit.statements loop
      Adac.Compilation.Sources.validate_span (self, statement.span);
    end loop;
  end validate;

end Adac.Compilation.Syntax;
