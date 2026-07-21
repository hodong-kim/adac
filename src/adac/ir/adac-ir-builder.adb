-- ============================================================================
-- adac-ir-builder.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Compilation.Semantics;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;

package body Adac.IR.Builder is

  function build
    (context : Adac.Compilation.Context;
     entity  : Adac.Semantics.Entity_ID)
  return Adac.IR.Module is
    module : Adac.IR.Module;
  begin
    Adac.Compilation.Semantics.validate (context, entity);

    declare
      root : constant Adac.AST.Node_ID :=
        Adac.Compilation.Semantics.declaration (context, entity);
    begin
      module.entry_name := Ada.Strings.Unbounded.to_unbounded_string
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Semantics.symbol (context, entity)));

      for index in 1 .. Adac.Compilation.Syntax.statement_count
        (context, root)
      loop
        case Adac.Compilation.Syntax.kind_of
          (context,
           Adac.Compilation.Syntax.statement_at (context, root, index))
        is
          when Adac.AST.Null_Statement_Node =>
            module.instructions.append
              (Adac.IR.Instruction'(kind => Adac.IR.Null_Instruction));

          when Adac.AST.Return_Statement_Node =>
            module.instructions.append
              (Adac.IR.Instruction'(kind => Adac.IR.Return_Instruction));

          when Adac.AST.Compilation_Unit_Node =>
            raise Program_Error with
              "Adac.IR.Builder: compilation unit used as a statement";
        end case;
      end loop;
    end;

    Adac.IR.validate (module);
    return module;
  end build;

end Adac.IR.Builder;
