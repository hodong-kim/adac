-- ============================================================================
-- adac-style.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Text_IO;

package body Adac.Style is

  MAX_LINE_LENGTH : constant := 80;

  procedure report (path    : String;
                    line_no : Positive;
                    message : String)
  is
  begin
    Ada.Text_IO.put_line
      (path
       & ":"
       & Positive'image (line_no)
       & ": "
       & message);
  end report;

  function has_tab (line : String) return Boolean is
  begin
    for ch of line loop
      if ch = ASCII.HT then
        return True;
      end if;
    end loop;

    return False;
  end has_tab;

  function has_trailing_whitespace (line : String) return Boolean is
  begin
    if line'length = 0 then
      return False;
    end if;

    return line(line'last) = ' ' or else line(line'last) = ASCII.HT;
  end has_trailing_whitespace;

  function check_file (path : String) return Boolean is
    file    : Ada.Text_IO.File_Type;
    line_no : Positive := 1;
    ok      : Boolean := True;
  begin
    Ada.Text_IO.open (file, Ada.Text_IO.in_file, path);

    while not Ada.Text_IO.end_of_file (file) loop
      declare
        line : constant String := Ada.Text_IO.get_line (file);
      begin
        if has_tab (line) then
          report (path, line_no, "tab character");
          ok := False;
        end if;

        if has_trailing_whitespace (line) then
          report (path, line_no, "trailing whitespace");
          ok := False;
        end if;

        if line'length > MAX_LINE_LENGTH then
          report (path, line_no, "line exceeds 80 columns");
          ok := False;
        end if;
      end;

      line_no := line_no + 1;
    end loop;

    Ada.Text_IO.close (file);
    return ok;
  end check_file;

end Adac.Style;
