-- ============================================================================
-- adac-semantics-testing.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.Semantics.Testing is

  function append_procedure_unchecked
    (self        : in out Store;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span)
  return Entity_ID is
  begin
    self.entities.append
      (Entity_Record'(kind        => Procedure_Body_Entity,
                      declaration => declaration,
                      symbol      => symbol,
                      span        => span));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.entities.length));
  end append_procedure_unchecked;

end Adac.Semantics.Testing;
