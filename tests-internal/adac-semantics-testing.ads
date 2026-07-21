-- ============================================================================
-- adac-semantics-testing.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Semantics.Testing is

  function append_procedure_unchecked
    (self        : in out Store;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span)
  return Entity_ID;

end Adac.Semantics.Testing;
