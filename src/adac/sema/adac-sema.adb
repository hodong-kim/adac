-- ============================================================================
-- adac-sema.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation.Diagnostics;
with Adac.Compilation.Semantics;
with Adac.Compilation.Syntax;
with Adac.Symbols;

package body Adac.Sema is

  use type Adac.Symbols.Symbol_ID;

  function analyze
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Analysis_Result is
  begin
    Adac.Compilation.Syntax.validate (context, root);

    if Adac.Compilation.Syntax.procedure_symbol (context, root) /=
       Adac.Compilation.Syntax.end_symbol (context, root)
    then
      Adac.Compilation.Diagnostics.error
        (context, "procedure name and end name do not match");
      return (status => Analysis_Rejected);
    end if;

    for index in 1 .. Adac.Compilation.Syntax.statement_count
      (context, root)
    loop
      case Adac.Compilation.Syntax.kind_of
        (context,
         Adac.Compilation.Syntax.statement_at (context, root, index))
      is
        when Adac.AST.Null_Statement_Node |
             Adac.AST.Return_Statement_Node =>
          null;

        when Adac.AST.Compilation_Unit_Node =>
          raise Program_Error with
            "Adac.Sema: compilation unit used as a statement";
      end case;
    end loop;

    return
      (status => Analysis_Succeeded,
       entity => Adac.Compilation.Semantics.create_procedure
         (context, root));
  end analyze;

end Adac.Sema;
