-- ============================================================================
-- adac-ir-builder.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.IR.Builder is

  function build (unit : Adac.AST.Compilation_Unit) return Adac.IR.Module is
    module : Adac.IR.Module;
  begin
    module.entry_name := unit.procedure_name;

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
