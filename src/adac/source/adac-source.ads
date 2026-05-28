-- ============================================================================
-- adac-source.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

package Adac.Source is

  type Position is record
    file   : Ada.Strings.Unbounded.Unbounded_String;
    line   : Positive := 1;
    column : Positive := 1;
  end record;

  function make_position (file   : String;
                          line   : Positive;
                          column : Positive) return Position;

  function image (pos : Position) return String;

end Adac.Source;
