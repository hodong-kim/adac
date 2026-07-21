-- ============================================================================
-- adac-source.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Adac.Source is

  type Source_File_ID is private;

  --! summary: Invalid sentinel for an unassigned source file.
  INVALID_SOURCE_FILE_ID : constant Source_File_ID;

  type Registry is limited private;

  --! summary: Create an empty source file registry.
  --! ownership: The returned registry owns its file paths and identity marker.
  function create return Registry;

  --! summary: Register a source path and return its context-local identifier.
  --! contract: Re-registering the same exact path returns the existing ID.
  function register_file
    (self : in out Registry;
     path : String)
  return Source_File_ID;

  --! summary: Return the path associated with a source file identifier.
  --! contract: The identifier must belong to this registry.
  function file_path
    (self    : Registry;
     file_id : Source_File_ID)
  return String;

  --! summary: Return the number of registered source paths.
  function file_count (self : Registry) return Natural;

  type Position is record
    file_id : Source_File_ID := INVALID_SOURCE_FILE_ID;
    line    : Positive := 1;
    column  : Positive := 1;
  end record;

  --! summary: Create a one-based position for a registered source file.
  function make_position
    (file_id : Source_File_ID;
     line    : Positive;
     column  : Positive)
  return Position;

  type Span is private;

  INVALID_SPAN : constant Span;

  --! summary: Construct a structurally valid closed source span.
  --! contract
  --!   Both endpoints must identify the same valid source file, and `first`
  --!   must not follow `last`.
  function make_span
    (first : Position;
     last  : Position)
  return Span;

  --! summary: Return the inclusive first position of a valid span.
  function first_position (value : Span) return Position;

  --! summary: Return the inclusive last position of a valid span.
  function last_position (value : Span) return Position;

  --! summary: Validate the structural invariants of a source span.
  procedure validate (value : Span);

  --! summary: Validate a source span against its owning registry.
  procedure validate
    (self  : Registry;
     value : Span);

  --! summary: Return whether one valid span contains another valid span.
  function contains
    (container : Span;
     value     : Span)
  return Boolean;

  --! summary: Render a source position using this registry.
  --! contract: The position file ID must belong to this registry.
  function position_image
    (self     : Registry;
     pos      : Position)
  return String;

private

  type Registry_Marker is record
    identity : Boolean := False;
  end record;
  type Registry_Marker_Access is access constant Registry_Marker;

  type Source_File_ID is record
    owner : Registry_Marker_Access := null;
    index : Natural := 0;
  end record;

  INVALID_SOURCE_FILE_ID : constant Source_File_ID
                         := (owner => null,
                             index => 0);

  type Span is record
    first : Position;
    last  : Position;
  end record;

  INVALID_SPAN : constant Span :=
    (first => (file_id => INVALID_SOURCE_FILE_ID,
               line    => 1,
               column  => 1),
     last  => (file_id => INVALID_SOURCE_FILE_ID,
               line    => 1,
               column  => 1));

  package File_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Ada.Strings.Unbounded.Unbounded_String,
     "="          => Ada.Strings.Unbounded."=");

  package Path_Maps is new Ada.Containers.Indefinite_Ordered_Maps
    (Key_Type     => String,
     Element_Type => Source_File_ID);

  type Registry is limited record
    marker   : aliased Registry_Marker;
    files    : File_Vectors.Vector;
    file_ids : Path_Maps.Map;
  end record;

end Adac.Source;
