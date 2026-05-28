-- ============================================================================
-- adac-source.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Support;

package body Adac.Source is

  function make_position (file   : String;
                          line   : Positive;
                          column : Positive) return Position
  is
  begin
    return
      (file   => Ada.Strings.Unbounded.to_unbounded_string (file),
       line   => line,
       column => column);
  end make_position;

  function image (pos : Position) return String is
    file : constant String := Ada.Strings.Unbounded.to_string (pos.file);
  begin
    return file & ":"
                & Adac.Support.image (pos.line)
                & ":"
                & Adac.Support.image (pos.column);
  end image;

end Adac.Source;
