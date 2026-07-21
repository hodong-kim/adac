-- ============================================================================
-- adac-driver.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Command_Line;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Adac.AST;
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

  procedure compile_parsed_unit
    (context     : in out Adac.Compilation.Context;
     root        : Adac.AST.Node_ID;
     output_path : String)
  is
    module : Adac.IR.Module;
  begin
    Ada.Text_IO.put_line ("adac: parse ok");

    case Adac.Sema.analyze (context, root) is
      when Adac.Sema.Analysis_Rejected =>
        finish_with_failure (context);
        return;

      when Adac.Sema.Analysis_Succeeded =>
        null;
    end case;

    Ada.Text_IO.put_line ("adac: sema ok");

    module := Adac.IR.Builder.build (context, root);

    Ada.Text_IO.put_line ("adac: ir ok");

    declare
      result : constant Adac.Backend.Emission_Result :=
        Adac.Backend.emit (module, output_path);
    begin
      case result.status is
        when Adac.Backend.Emission_Operational_Failure =>
          Adac.Compilation.Diagnostics.error
            (context, Adac.Backend.failure_message (result));
          finish_with_failure (context);
          return;

        when Adac.Backend.Emission_Succeeded =>
          null;
      end case;
    end;

    Ada.Text_IO.put_line ("adac: backend ok");
    Ada.Text_IO.put_line
      ("adac: diagnostics " &
       Adac.Support.image
         (Adac.Compilation.Diagnostics.error_count (context)) &
       " error(s)");
  end compile_parsed_unit;

  procedure compile_file
    (context     : in out Adac.Compilation.Context;
     input_path  : String;
     output_path : String)
  is
  begin
    Ada.Text_IO.put_line ("adac: parsing " & input_path);

    begin
      declare
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, input_path);
      begin
        case result.status is
          when Adac.Frontend.Parse_Rejected =>
            finish_with_failure (context);

          when Adac.Frontend.Parse_Succeeded =>
            compile_parsed_unit (context, result.root, output_path);
        end case;
      end;
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
