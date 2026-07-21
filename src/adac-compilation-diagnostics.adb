-- ============================================================================
-- adac-compilation-diagnostics.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Diagnostics;

package body Adac.Compilation.Diagnostics is

  procedure error
    (self    : in out Context;
     message : String)
  is
  begin
    Adac.Diagnostics.error (self.diagnostic_state, message);
  end error;

  procedure error
    (self     : in out Context;
     position : Adac.Source.Position;
     message  : String)
  is
  begin
    Adac.Diagnostics.error (self.diagnostic_state, position, message);
  end error;

  function has_error (self : Context) return Boolean is
  begin
    return Adac.Diagnostics.has_error (self.diagnostic_state);
  end has_error;

  function error_count (self : Context) return Natural is
  begin
    return Adac.Diagnostics.error_count (self.diagnostic_state);
  end error_count;

end Adac.Compilation.Diagnostics;
