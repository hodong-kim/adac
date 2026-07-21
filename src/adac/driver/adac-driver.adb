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
with Adac.Compilation;
with Adac.Compilation.Diagnostics;
with Adac.Frontend;
with Adac.IR;
with Adac.IR.Builder;
with Adac.Sema;
with Adac.Support;
with Adac.Support.CLI;

package body Adac.Driver is

  procedure print_usage is
  begin
    Ada.Text_IO.put_line
      ("usage: adac <file> [-o output] " &
       "[--case-sensitive-identifiers]");
  end print_usage;

  procedure finish_with_failure (context : Adac.Compilation.Context) is
  begin
    Ada.Text_IO.put_line
      ("adac: diagnostics " &
       Adac.Support.image
         (Adac.Compilation.Diagnostics.error_count (context)) &
       " error(s)");

    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
  end finish_with_failure;

  procedure compile_file
    (context     : in out Adac.Compilation.Context;
     input_path  : String;
     output_path : String)
  is
    result : Adac.Frontend.Parse_Result;
    module : Adac.IR.Module;
  begin
    Ada.Text_IO.put_line ("adac: parsing " & input_path);

    begin
      result := Adac.Frontend.parse_file (context, input_path);
    exception
      when Ada.IO_Exceptions.Name_Error |
           Ada.IO_Exceptions.Use_Error |
           Ada.IO_Exceptions.Device_Error |
           Ada.IO_Exceptions.End_Error |
           Ada.IO_Exceptions.Data_Error |
           Ada.IO_Exceptions.Layout_Error =>
        Adac.Compilation.Diagnostics.error
          (context, "unable to read input file: " & input_path);
        finish_with_failure (context);
        return;
    end;

    if not result.ok then
      finish_with_failure (context);
      return;
    end if;

    Ada.Text_IO.put_line ("adac: parse ok");

    case Adac.Sema.analyze (context, result.unit) is
      when Adac.Sema.Analysis_Rejected =>
        finish_with_failure (context);
        return;

      when Adac.Sema.Analysis_Succeeded =>
        null;
    end case;

    Ada.Text_IO.put_line ("adac: sema ok");

    module := Adac.IR.Builder.build (result.unit);

    Ada.Text_IO.put_line ("adac: ir ok");

    begin
      if not Adac.Backend.emit (module, output_path) then
        Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
        return;
      end if;
    exception
      when error : Adac.Backend.Operational_Error =>
        Adac.Compilation.Diagnostics.error
          (context, Ada.Exceptions.exception_message (error));
        finish_with_failure (context);
        return;

      when Ada.IO_Exceptions.Name_Error |
           Ada.IO_Exceptions.Use_Error |
           Ada.IO_Exceptions.Device_Error =>
        Adac.Compilation.Diagnostics.error
          (context,
           "I/O failure during backend emission: " & output_path);
        finish_with_failure (context);
        return;
    end;

    Ada.Text_IO.put_line ("adac: backend ok");
    Ada.Text_IO.put_line
      ("adac: diagnostics " &
       Adac.Support.image
         (Adac.Compilation.Diagnostics.error_count (context)) &
       " error(s)");
  end compile_file;

  procedure run is
    options : constant Adac.Support.CLI.Options :=
      Adac.Support.CLI.parse;
  begin
    if not options.valid then
      Ada.Text_IO.put_line
        ("adac: error: " &
         Ada.Strings.Unbounded.to_string (options.error_message));
      print_usage;
      Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
      return;
    end if;

    if not options.has_input then
      print_usage;
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
      context : Adac.Compilation.Context :=
        Adac.Compilation.create (options.language_options);
    begin
      compile_file (context, input_path, output_path);
    end;
  end run;

end Adac.Driver;
