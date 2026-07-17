-- ============================================================================
-- adac_main.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Ada.Command_Line;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Text_IO;
with Adac.Driver;

procedure adac_main is

  procedure report_exception
    (prefix : String;
     error  : Ada.Exceptions.Exception_Occurrence)
  is
    name    : constant String := Ada.Exceptions.exception_name (error);
    message : constant String := Ada.Exceptions.exception_message (error);
  begin
    if message'length = 0 then
      Ada.Text_IO.put_line (prefix & name);
    else
      Ada.Text_IO.put_line (prefix & name & ": " & message);
    end if;
  exception
    -- Preserve the primary failure if diagnostic output is unavailable.
    when others =>
      null;
  end report_exception;

begin
  Adac.Driver.run;
exception
  when error : Ada.IO_Exceptions.Name_Error |
               Ada.IO_Exceptions.Use_Error |
               Ada.IO_Exceptions.Device_Error |
               Ada.IO_Exceptions.End_Error |
               Ada.IO_Exceptions.Data_Error |
               Ada.IO_Exceptions.Layout_Error =>
    report_exception ("adac: error: unhandled I/O failure: ", error);
    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);

  when error : others =>
    report_exception ("adac: internal compiler error: ", error);
    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
end adac_main;
