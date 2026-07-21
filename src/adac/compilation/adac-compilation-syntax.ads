-- ============================================================================
-- adac-compilation-syntax.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Source;
with Adac.Symbols;

package Adac.Compilation.Syntax is

  --! summary: Append one statement to this compilation's AST store.
  function create_statement
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Append one compilation-unit root to this compilation's AST store.
  function create_compilation_unit
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Adac.AST.Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID;

  --! summary: Return the number of AST nodes owned by this compilation.
  function node_count (self : Context) return Natural;

  --! summary: Return the concrete kind of a context-owned AST node.
  function kind_of
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.AST.Node_Kind;

  --! summary: Return the source span of a context-owned AST node.
  function node_span
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.Source.Span;

  --! summary: Return the opening symbol of a compilation-unit node.
  function procedure_symbol
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the closing symbol of a compilation-unit node.
  function end_symbol
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the statement count of a compilation-unit node.
  function statement_count
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Natural;

  --! summary: Return one statement from a compilation-unit node.
  function statement_at
    (self  : Context;
     unit  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID;

  --! summary: Validate an AST and all compilation-context ownership links.
  procedure validate
    (self : Context;
     root : Adac.AST.Node_ID);

end Adac.Compilation.Syntax;
