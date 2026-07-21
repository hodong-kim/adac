-- ============================================================================
-- adac-compilation-semantics-testing.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Semantics.Testing;

package body Adac.Compilation.Semantics.Testing is

  function create_procedure_unchecked
    (self        : in out Context;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span)
  return Adac.Semantics.Entity_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.Testing.append_procedure_unchecked
      (self.semantic_store, declaration, symbol, span);
  end create_procedure_unchecked;

end Adac.Compilation.Semantics.Testing;
