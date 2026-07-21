-- ============================================================================
-- adac-ir-builder.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;

package body Adac.IR.Builder is

  function build
    (context : Adac.Compilation.Context;
     unit    : Adac.AST.Compilation_Unit)
  return Adac.IR.Module is
    module : Adac.IR.Module;
  begin
    Adac.Compilation.Syntax.validate (context, unit);
    module.entry_name := Ada.Strings.Unbounded.to_unbounded_string
      (Adac.Compilation.Symbols.spelling (context, unit.procedure_symbol));

    for statement of unit.statements loop
      case statement.kind is
        when Adac.AST.Null_Statement =>
          module.instructions.append
            (Adac.IR.Instruction'(kind => Adac.IR.Null_Instruction));

        when Adac.AST.Return_Statement =>
          module.instructions.append
            (Adac.IR.Instruction'(kind => Adac.IR.Return_Instruction));
      end case;
    end loop;

    Adac.IR.validate (module);
    return module;
  end build;

end Adac.IR.Builder;
