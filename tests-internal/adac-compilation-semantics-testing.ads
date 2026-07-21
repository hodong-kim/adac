-- ============================================================================
-- adac-compilation-semantics-testing.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Compilation.Semantics.Testing is

  function create_procedure_unchecked
    (self        : in out Context;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span)
  return Adac.Semantics.Entity_ID;

end Adac.Compilation.Semantics.Testing;
