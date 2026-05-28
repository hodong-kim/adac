-- ============================================================================
-- adac_style_main.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Command_Line;
with Ada.Text_IO;

with Adac.Style;

procedure adac_style_main is
  ok : Boolean := True;
begin
  if Ada.Command_Line.argument_count = 0 then
    Ada.Text_IO.put_line ("usage: adac-style <file>...");
    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
    return;
  end if;

  for i in 1 .. Ada.Command_Line.argument_count loop
    if not Adac.Style.check_file (Ada.Command_Line.argument (i)) then
      ok := False;
    end if;
  end loop;

  if not ok then
    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
  end if;
end adac_style_main;
