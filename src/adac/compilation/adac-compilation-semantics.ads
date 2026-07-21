-- ============================================================================
-- adac-compilation-semantics.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Semantics;
with Adac.Source;
with Adac.Symbols;

package Adac.Compilation.Semantics is

  --! summary: Publish the procedure entity for one validated AST declaration.
  function create_procedure
    (self        : in out Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Semantics.Entity_ID;

  --! summary: Return the number of semantic entities in this compilation.
  function entity_count (self : Context) return Natural;

  --! summary: Return the concrete kind of a context-owned semantic entity.
  function kind_of
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Semantics.Entity_Kind;

  --! summary: Return the syntax declaration associated with an entity.
  function declaration
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the declared symbol associated with an entity.
  function symbol
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the source span associated with an entity.
  function entity_span
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Source.Span;

  --! summary: Validate an entity and all compilation-context ownership links.
  procedure validate
    (self   : Context;
     entity : Adac.Semantics.Entity_ID);

end Adac.Compilation.Semantics;
