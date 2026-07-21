-- ============================================================================
-- adac-ast.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;

with Adac.Source;
with Adac.Symbols;

package Adac.AST is

  type Node_ID is private;

  INVALID_NODE_ID : constant Node_ID;

  type Node_Kind is
    (Compilation_Unit_Node,
     Null_Statement_Node,
     Return_Statement_Node);

  type Node_List is private;

  --! summary: Append one node identifier to a temporary node list.
  procedure append
    (self : in out Node_List;
     node : Node_ID);

  --! summary: Return the number of identifiers in a temporary node list.
  function list_count (self : Node_List) return Natural;

  --! summary: Return one identifier from a temporary node list.
  function list_element
    (self  : Node_List;
     index : Positive)
  return Node_ID;

  type Store is limited private;

  --! summary: Create an empty append-only AST store.
  --! ownership: The returned store owns every node subsequently appended.
  function create return Store;

  --! summary: Append one structurally valid statement node.
  --! contract: `kind` must identify a statement node.
  function append_statement
    (self          : in out Store;
     kind          : Node_Kind;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one structurally valid compilation-unit root.
  --! contract
  --!   Every statement ID must identify a statement in `self`, and every
  --!   statement span must be contained by `span`.
  function append_compilation_unit
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID;

  --! summary: Return the number of nodes owned by the store.
  function node_count (self : Store) return Natural;

  --! summary: Return the concrete kind of a node owned by the store.
  function kind_of
    (self : Store;
     node : Node_ID)
  return Node_Kind;

  --! summary: Return the source span of a node owned by the store.
  function node_span
    (self : Store;
     node : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the opening name of a compilation-unit node.
  function procedure_symbol
    (self : Store;
     unit : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the closing name of a compilation-unit node.
  function end_symbol
    (self : Store;
     unit : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the number of statements in a compilation-unit node.
  function statement_count
    (self : Store;
     unit : Node_ID)
  return Natural;

  --! summary: Return one statement ID from a compilation-unit node.
  function statement_at
    (self  : Store;
     unit  : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Validate the structural state of a node identifier.
  procedure validate (node : Node_ID);

  --! summary: Validate an AST rooted at a node in this store.
  --! contract
  --!   Raises `Program_Error` when the identifier is foreign or an internal
  --!   AST invariant is violated. Validation does not modify the store.
  procedure validate
    (self : Store;
     root : Node_ID);

private

  type Store_Marker is record
    identity : Boolean := False;
  end record;
  type Store_Marker_Access is access constant Store_Marker;

  type Node_ID is record
    owner : Store_Marker_Access := null;
    index : Natural := 0;
  end record;

  INVALID_NODE_ID : constant Node_ID :=
    (owner => null,
     index => 0);

  package Node_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Node_ID);

  type Node_List is record
    nodes : Node_Vectors.Vector;
  end record;

  type Node (kind : Node_Kind := Null_Statement_Node) is record
    span : Adac.Source.Span := Adac.Source.INVALID_SPAN;

    case kind is
      when Compilation_Unit_Node =>
        procedure_symbol : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        statements : Node_Vectors.Vector;
        end_symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;

      when Null_Statement_Node | Return_Statement_Node =>
        null;
    end case;
  end record;

  package Node_Storage_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Node);

  type Store is limited record
    initialized : Boolean := False;
    marker      : aliased Store_Marker;
    nodes       : Node_Storage_Vectors.Vector;
  end record;

end Adac.AST;
