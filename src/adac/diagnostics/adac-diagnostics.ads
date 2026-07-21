-- ============================================================================
-- adac-diagnostics.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Diagnostics is

  type State is private;

  --! summary: Create empty diagnostic state for one compilation.
  function create return State;

  procedure error
    (self    : in out State;
     message : String);

  procedure error
    (self     : in out State;
     location : String;
     message  : String);

  function has_error (self : State) return Boolean;

  function error_count (self : State) return Natural;

private

  type State is record
    total_errors : Natural := 0;
  end record;

end Adac.Diagnostics;
