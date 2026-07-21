-- ============================================================================
-- adac-compilation-syntax.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;

package body Adac.Compilation.Syntax is

  function create_statement
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.append_statement
      (self.ast_store,
       kind,
       span,
       self.limits.maximum_ast_nodes);
  end create_statement;

  function create_compilation_unit
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Adac.AST.Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, procedure_symbol);
    Adac.Compilation.Symbols.validate_symbol (self, end_symbol);
    Adac.Compilation.Sources.validate_span (self, span);

    for index in 1 .. Adac.AST.list_count (statements) loop
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.node_span
           (self.ast_store, Adac.AST.list_element (statements, index)));
    end loop;

    return Adac.AST.append_compilation_unit
      (self.ast_store,
       procedure_symbol,
       statements,
       end_symbol,
       span,
       self.limits.maximum_ast_nodes);
  end create_compilation_unit;

  function node_count (self : Context) return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.node_count (self.ast_store);
  end node_count;

  function kind_of
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.AST.Node_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.kind_of (self.ast_store, node);
  end kind_of;

  function node_span
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.node_span (self.ast_store, node);
  end node_span;

  function procedure_symbol
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_symbol (self.ast_store, unit);
  end procedure_symbol;

  function end_symbol
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.end_symbol (self.ast_store, unit);
  end end_symbol;

  function statement_count
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.statement_count (self.ast_store, unit);
  end statement_count;

  function statement_at
    (self  : Context;
     unit  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.statement_at (self.ast_store, unit, index);
  end statement_at;

  procedure validate
    (self : Context;
     root : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.validate (self.ast_store, root);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.procedure_symbol (self.ast_store, root));
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.end_symbol (self.ast_store, root));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, root));

    for index in 1 .. Adac.AST.statement_count (self.ast_store, root) loop
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.node_span
           (self.ast_store,
            Adac.AST.statement_at (self.ast_store, root, index)));
    end loop;
  end validate;

end Adac.Compilation.Syntax;
