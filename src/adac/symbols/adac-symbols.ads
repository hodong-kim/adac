-- ============================================================================
-- adac-symbols.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Adac.Symbols is

  type Symbol_ID is private;

  INVALID_SYMBOL_ID : constant Symbol_ID;

  type Store is limited private;

  --! summary: Create an empty symbol store with one fixed case policy.
  function create
    (case_sensitive_identifiers : Boolean)
  return Store;

  --! summary: Intern one non-empty identifier spelling.
  function intern
    (self     : in out Store;
     spelling : String)
  return Symbol_ID;

  --! summary: Return the first spelling stored for a symbol.
  function spelling
    (self   : Store;
     symbol : Symbol_ID)
  return String;

  --! summary: Return the number of distinct interned symbols.
  function symbol_count (self : Store) return Natural;

  --! summary: Validate the structural state of a symbol identifier.
  procedure validate (symbol : Symbol_ID);

  --! summary: Validate a symbol identifier against its owning store.
  procedure validate
    (self   : Store;
     symbol : Symbol_ID);

private

  type Store_Marker is record
    identity : Boolean := False;
  end record;
  type Store_Marker_Access is access constant Store_Marker;

  type Symbol_ID is record
    owner : Store_Marker_Access := null;
    index : Natural := 0;
  end record;

  INVALID_SYMBOL_ID : constant Symbol_ID :=
    (owner => null,
     index => 0);

  package Spelling_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Ada.Strings.Unbounded.Unbounded_String,
     "="          => Ada.Strings.Unbounded."=");

  package Symbol_Maps is new Ada.Containers.Indefinite_Ordered_Maps
    (Key_Type     => String,
     Element_Type => Symbol_ID);

  type Store is limited record
    initialized : Boolean := False;
    case_sensitive_identifiers : Boolean := False;
    marker    : aliased Store_Marker;
    spellings : Spelling_Vectors.Vector;
    symbols   : Symbol_Maps.Map;
  end record;

end Adac.Symbols;
