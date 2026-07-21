-- ============================================================================
-- adac-compilation-semantics.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;

package body Adac.Compilation.Semantics is

  use type Adac.Source.Span;
  use type Adac.Symbols.Symbol_ID;

  function create_procedure
    (self        : in out Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Semantics.Entity_ID is
  begin
    Adac.Compilation.Syntax.validate (self, declaration);
    return Adac.Semantics.append_procedure
      (self.semantic_store,
       declaration,
       Adac.Compilation.Syntax.procedure_symbol (self, declaration),
       Adac.Compilation.Syntax.node_span (self, declaration));
  end create_procedure;

  function entity_count (self : Context) return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.entity_count (self.semantic_store);
  end entity_count;

  function kind_of
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Semantics.Entity_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.kind_of (self.semantic_store, entity);
  end kind_of;

  function declaration
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.declaration (self.semantic_store, entity);
  end declaration;

  function symbol
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.symbol (self.semantic_store, entity);
  end symbol;

  function entity_span
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.entity_span (self.semantic_store, entity);
  end entity_span;

  procedure validate
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  is
    declaration : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Semantics.validate (self.semantic_store, entity);

    declaration := Adac.Semantics.declaration (self.semantic_store, entity);
    Adac.Compilation.Syntax.validate (self, declaration);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.Semantics.symbol (self.semantic_store, entity));
    Adac.Compilation.Sources.validate_span
      (self, Adac.Semantics.entity_span (self.semantic_store, entity));

    if Adac.Semantics.symbol (self.semantic_store, entity) /=
       Adac.Compilation.Syntax.procedure_symbol (self, declaration)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: entity symbol does not match AST";
    end if;

    if Adac.Semantics.entity_span (self.semantic_store, entity) /=
       Adac.Compilation.Syntax.node_span (self, declaration)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: entity span does not match AST";
    end if;
  end validate;

end Adac.Compilation.Semantics;
