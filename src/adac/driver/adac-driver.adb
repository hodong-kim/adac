-- ============================================================================
-- adac-driver.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Adac.Backend;
with Adac.Diagnostics;
with Adac.Frontend;
with Adac.IR;
with Adac.IR.Builder;
with Adac.Sema;
with Adac.Support;
with Adac.Support.CLI;

package body Adac.Driver is

  procedure finish_with_failure is
  begin
    Ada.Text_IO.put_line
      ("adac: diagnostics " &
       Adac.Support.image (Adac.Diagnostics.error_count) &
       " error(s)");

    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
  end finish_with_failure;

  procedure compile_file
    (input_path  : String;
     output_path : String)
  is
    result : Adac.Frontend.Parse_Result;
    module : Adac.IR.Module;
  begin
    Adac.Diagnostics.reset;

    Ada.Text_IO.put_line ("adac: parsing " & input_path);

    begin
      result := Adac.Frontend.parse_file (input_path);
    exception
      when error : Adac.Backend.Operational_Error =>
        Adac.Diagnostics.error
          (Ada.Exceptions.exception_message (error));
        finish_with_failure;
        return;

      when Ada.IO_Exceptions.Name_Error |
           Ada.IO_Exceptions.Use_Error |
           Ada.IO_Exceptions.Device_Error |
           Ada.IO_Exceptions.End_Error |
           Ada.IO_Exceptions.Data_Error |
           Ada.IO_Exceptions.Layout_Error =>
        Adac.Diagnostics.error
          ("unable to read input file: " & input_path);
        finish_with_failure;
        return;
    end;

    if not result.ok then
      finish_with_failure;
      return;
    end if;

    Ada.Text_IO.put_line ("adac: parse ok");

    if not Adac.Sema.analyze (result.unit) then
      finish_with_failure;
      return;
    end if;

    Ada.Text_IO.put_line ("adac: sema ok");

    module := Adac.IR.Builder.build (result.unit);

    Ada.Text_IO.put_line ("adac: ir ok");

    begin
      if not Adac.Backend.emit (module, output_path) then
        Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
        return;
      end if;
    exception
      when Ada.IO_Exceptions.Name_Error |
           Ada.IO_Exceptions.Use_Error |
           Ada.IO_Exceptions.Device_Error =>
        Adac.Diagnostics.error
          ("I/O failure during backend emission: " & output_path);
        finish_with_failure;
        return;
    end;

    Ada.Text_IO.put_line ("adac: backend ok");
    Ada.Text_IO.put_line
      ("adac: diagnostics " &
       Adac.Support.image (Adac.Diagnostics.error_count) &
       " error(s)");
  end compile_file;

  procedure run is
    options : constant Adac.Support.CLI.Options :=
      Adac.Support.CLI.parse;
  begin
    if not options.has_input then
      Ada.Text_IO.put_line ("usage: adac <file> [-o output]");
      Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
      return;
    end if;

    declare
      input_path : constant String :=
        Ada.Strings.Unbounded.to_string (options.input_path);
      output_path : constant String :=
        (if options.has_output
         then Ada.Strings.Unbounded.to_string (options.output_path)
         else "a.out");
    begin
      compile_file (input_path, output_path);
    end;
  end run;

end Adac.Driver;
