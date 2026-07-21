-- ============================================================================
-- adac-semantics.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;

with Adac.AST;
with Adac.Source;
with Adac.Symbols;

package Adac.Semantics is

  type Entity_ID is private;

  INVALID_ENTITY_ID : constant Entity_ID;

  type Entity_Kind is
    (Procedure_Body_Entity);

  type Store is limited private;

  --! summary: Create an empty append-only semantic entity store.
  function create return Store;

  --! summary: Append one procedure-body entity.
  function append_procedure
    (self        : in out Store;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span)
  return Entity_ID;

  --! summary: Return the number of entities owned by the store.
  function entity_count (self : Store) return Natural;

  --! summary: Return the concrete kind of an entity owned by the store.
  function kind_of
    (self   : Store;
     entity : Entity_ID)
  return Entity_Kind;

  --! summary: Return the syntax declaration associated with an entity.
  function declaration
    (self   : Store;
     entity : Entity_ID)
  return Adac.AST.Node_ID;

  --! summary: Return the declared symbol associated with an entity.
  function symbol
    (self   : Store;
     entity : Entity_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the source span associated with an entity.
  function entity_span
    (self   : Store;
     entity : Entity_ID)
  return Adac.Source.Span;

  --! summary: Validate the structural state of an entity identifier.
  procedure validate (entity : Entity_ID);

  --! summary: Validate an entity and its structurally stored references.
  procedure validate
    (self   : Store;
     entity : Entity_ID);

private

  type Store_Marker is record
    identity : Boolean := False;
  end record;
  type Store_Marker_Access is access constant Store_Marker;

  type Entity_ID is record
    owner : Store_Marker_Access := null;
    index : Natural := 0;
  end record;

  INVALID_ENTITY_ID : constant Entity_ID :=
    (owner => null,
     index => 0);

  type Entity_Record is record
    kind        : Entity_Kind := Procedure_Body_Entity;
    declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    symbol      : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    span        : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  end record;

  package Entity_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Entity_Record);

  type Store is limited record
    initialized : Boolean := False;
    marker      : aliased Store_Marker;
    entities    : Entity_Vectors.Vector;
  end record;

end Adac.Semantics;
