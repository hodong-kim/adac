-- ============================================================================
-- adac-style.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Text_IO;
with Adac.Support;

package body Adac.Style is

  MAX_LINE_LENGTH : constant := 80;

  HEADER_BAR : constant String :=
    "======================================" &
    "======================================";

  ADA_COMMENT_PREFIX  : constant String := "-- ";
  RUBY_COMMENT_PREFIX : constant String := "# ";

  COPYRIGHT_TEXT : constant String
                 := "Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>";
  SPDX_TEXT      : constant String := "SPDX-License-Identifier: 0BSD";

  HEADER_SEPARATOR : constant String := ADA_COMMENT_PREFIX & HEADER_BAR;
  COPYRIGHT_LINE   : constant String := ADA_COMMENT_PREFIX & COPYRIGHT_TEXT;
  SPDX_LINE        : constant String := ADA_COMMENT_PREFIX & SPDX_TEXT;

  RAKEFILE_HEADER_SEPARATOR : constant String
                            := RUBY_COMMENT_PREFIX & HEADER_BAR;
  RAKEFILE_COPYRIGHT_LINE   : constant String
                            := RUBY_COMMENT_PREFIX & COPYRIGHT_TEXT;
  RAKEFILE_SPDX_LINE        : constant String
                            := RUBY_COMMENT_PREFIX & SPDX_TEXT;

  procedure report (path    : String;
                    line_no : Positive;
                    message : String)
  is
  begin
    Ada.Text_IO.put_line
      (path
       & ":"
       & Adac.Support.image (line_no)
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

  procedure check_header_line
    (path     : String;
     line_no  : Positive;
     line     : String;
     expected : String;
     ok       : in out Boolean)
  is
  begin
    if line /= expected then
      report (path, line_no, "invalid file header");
      ok := False;
    end if;
  end check_header_line;

  function basename (path : String) return String is
    start : Positive := path'first;
  begin
    for i in path'range loop
      if path(i) = '/' or else path(i) = '\' then
        start := i + 1;
      end if;
    end loop;

    return path(start .. path'last);
  end basename;

  function is_rakefile (path : String) return Boolean is
  begin
    return basename (path) = "Rakefile";
  end is_rakefile;

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
        if line_no = 1 then
          check_header_line
            (path,
             line_no,
             line,
             (if is_rakefile (path)
                then RAKEFILE_HEADER_SEPARATOR
                else HEADER_SEPARATOR),
             ok);
        elsif line_no = 2 then
          check_header_line
            (path,
             line_no,
             line,
             (if is_rakefile (path)
                then "# "
                else "-- ")
             & basename (path),
             ok);
        elsif line_no = 3 then
          check_header_line
            (path,
             line_no,
             line,
             (if is_rakefile (path)
                then RAKEFILE_COPYRIGHT_LINE
                else COPYRIGHT_LINE),
             ok);
        elsif line_no = 4 then
          check_header_line
            (path,
             line_no,
             line,
             (if is_rakefile (path)
                then RAKEFILE_SPDX_LINE
                else SPDX_LINE),
             ok);
        elsif line_no = 5 then
          check_header_line
            (path,
             line_no,
             line,
             (if is_rakefile (path)
                then RAKEFILE_HEADER_SEPARATOR
                else HEADER_SEPARATOR),
             ok);
        end if;

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
