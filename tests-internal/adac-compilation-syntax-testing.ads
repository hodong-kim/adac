-- ============================================================================
-- adac-compilation-syntax-testing.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Compilation.Syntax.Testing is

  function create_statement_unchecked
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  function create_compilation_unit_unchecked
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Adac.AST.Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

end Adac.Compilation.Syntax.Testing;
