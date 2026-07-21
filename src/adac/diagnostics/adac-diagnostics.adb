-- ============================================================================
-- adac-diagnostics.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Text_IO;

package body Adac.Diagnostics is

  function create return State is
  begin
    return (total_errors => 0);
  end create;

  procedure error
    (self    : in out State;
     message : String)
  is
  begin
    self.total_errors := self.total_errors + 1;

    Ada.Text_IO.put_line ("adac: error: " & message);
  end error;

  procedure error
    (self     : in out State;
     position : Adac.Source.Position;
     message  : String)
  is
  begin
    self.total_errors := self.total_errors + 1;

    Ada.Text_IO.put_line
      ("adac: error: " &
       Adac.Source.position_image (position) &
       ": " &
       message);
  end error;

  function has_error (self : State) return Boolean is
  begin
    return self.total_errors /= 0;
  end has_error;

  function error_count (self : State) return Natural is
  begin
    return self.total_errors;
  end error_count;

end Adac.Diagnostics;
