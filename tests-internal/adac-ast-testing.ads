-- ============================================================================
-- adac-ast-testing.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.AST.Testing is

  function append_statement_unchecked
    (self : in out Store;
     kind : Node_Kind;
     span : Adac.Source.Span)
  return Node_ID;

  function append_compilation_unit_unchecked
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Node_ID;

end Adac.AST.Testing;
