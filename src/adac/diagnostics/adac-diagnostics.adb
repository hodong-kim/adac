-- ============================================================================
-- adac-diagnostics.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Text_IO;

package body Adac.Diagnostics is

  total_errors : Natural := 0;

  procedure reset is
  begin
    total_errors := 0;
  end reset;

  procedure error (message : String) is
  begin
    total_errors := total_errors + 1;

    Ada.Text_IO.put_line ("adac: error: " & message);
  end error;

  procedure error (position : Adac.Source.Position;
                  message  : String) is
  begin
    total_errors := total_errors + 1;

    Ada.Text_IO.put_line ("adac: error: "
                          & Adac.Source.image (position)
                          & ": "
                          & message);
  end error;

  function has_error return Boolean is
  begin
    return total_errors /= 0;
  end has_error;

  function error_count return Natural is
  begin
    return total_errors;
  end error_count;

end Adac.Diagnostics;
