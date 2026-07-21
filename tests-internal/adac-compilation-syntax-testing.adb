-- ============================================================================
-- adac-compilation-syntax-testing.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST.Testing;

package body Adac.Compilation.Syntax.Testing is

  function create_statement_unchecked
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_statement_unchecked
      (self.ast_store, kind, span);
  end create_statement_unchecked;

  function create_compilation_unit_unchecked
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Adac.AST.Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.Testing.append_compilation_unit_unchecked
      (self.ast_store,
       procedure_symbol,
       statements,
       end_symbol,
       span);
  end create_compilation_unit_unchecked;

end Adac.Compilation.Syntax.Testing;
