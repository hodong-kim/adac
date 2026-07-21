-- ============================================================================
-- adac-ast-testing.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.AST.Testing is

  function append_statement_unchecked
    (self : in out Store;
     kind : Node_Kind;
     span : Adac.Source.Span)
  return Node_ID is
  begin
    case kind is
      when Null_Statement_Node =>
        self.nodes.append
          (Node'(kind => Null_Statement_Node, span => span));

      when Return_Statement_Node =>
        self.nodes.append
          (Node'(kind => Return_Statement_Node, span => span));

      when Compilation_Unit_Node =>
        raise Program_Error with
          "Adac.AST.Testing: invalid statement node kind";
    end case;

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_statement_unchecked;

  function append_compilation_unit_unchecked
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind             => Compilation_Unit_Node,
             span             => span,
             procedure_symbol => procedure_symbol,
             statements       => statements.nodes,
             end_symbol       => end_symbol));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_compilation_unit_unchecked;

end Adac.AST.Testing;
