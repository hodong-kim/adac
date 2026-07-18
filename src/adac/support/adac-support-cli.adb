-- ============================================================================
-- adac-support-cli.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Command_Line;

package body Adac.Support.CLI is

  procedure reject
    (opts    : in out Options;
     message : String)
  is
  begin
    opts.valid := False;
    opts.error_message :=
      Ada.Strings.Unbounded.to_unbounded_string (message);
  end reject;

  function parse return Options is
    opts : Options;
    i    : Positive := 1;
  begin
    while i <= Ada.Command_Line.argument_count loop
      declare
        arg : constant String := Ada.Command_Line.argument (i);
      begin
        if arg = "-o" then
          if opts.has_output then
            reject (opts, "duplicate -o option");
            return opts;
          end if;

          if i = Ada.Command_Line.argument_count then
            reject (opts, "missing output path after -o");
            return opts;
          end if;

          i := i + 1;
          opts.has_output  := True;
          opts.output_path :=
            Ada.Strings.Unbounded.to_unbounded_string
              (Ada.Command_Line.argument (i));
        elsif arg = "--case-sensitive-identifiers" then
          opts.language_options.case_sensitive_identifiers := True;
        elsif arg'length > 0 and then arg(arg'first) = '-' then
          reject (opts, "unknown option: " & arg);
          return opts;
        elsif not opts.has_input then
          opts.has_input  := True;
          opts.input_path :=
            Ada.Strings.Unbounded.to_unbounded_string (arg);
        else
          reject (opts, "unexpected argument: " & arg);
          return opts;
        end if;
      end;

      i := i + 1;
    end loop;

    return opts;
  end parse;

end Adac.Support.CLI;
