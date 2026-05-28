-- ============================================================================
-- adac-driver.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Command_Line;
with Ada.Text_IO;

with Adac.Frontend;
with Adac.Sema;
with Adac.IR;
with Adac.IR.Builder;
with Adac.Backend;
with Adac.Diagnostics;
with Adac.Support;
with Adac.Support.CLI;
with Ada.Strings.Unbounded;

package body Adac.Driver is

  procedure compile_file (input_path  : String;
                          output_path : String)
  is
    result : Adac.Frontend.Parse_Result;
    module : Adac.IR.Module;
  begin
    Adac.Diagnostics.reset;

    Ada.Text_IO.put_line ("adac: parsing " & input_path);
    result := Adac.Frontend.parse_file (input_path);

    if not result.ok then
      Ada.Text_IO.put_line ("adac: diagnostics "
                            & Adac.Support.image (Adac.Diagnostics.error_count)
                            & " error(s)");

      Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
      return;
    end if;

    Ada.Text_IO.put_line ("adac: parse ok");

    if not Adac.Sema.analyze (result.unit) then
      Ada.Text_IO.put_line ("adac: diagnostics "
                            & Adac.Support.image (Adac.Diagnostics.error_count)
                            & " error(s)");

      Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
      return;
    end if;

    Ada.Text_IO.put_line ("adac: sema ok");

    module := Adac.IR.Builder.build (result.unit);

    Ada.Text_IO.put_line ("adac: ir ok");

    if not Adac.Backend.emit (module, output_path) then
      Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
      return;
    end if;

    Ada.Text_IO.put_line ("adac: backend ok");
    Ada.Text_IO.put_line ("adac: diagnostics "
                          & Adac.Support.image (Adac.Diagnostics.error_count)
                          & " error(s)");
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
