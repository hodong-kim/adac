-- ============================================================================
-- adac-support-cli.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Command_Line;

package body Adac.Support.CLI is

  function parse return Options is
    opts : Options;
  begin
    if Ada.Command_Line.argument_count < 1 then
      return opts;
    end if;

    opts.has_input  := True;
    opts.input_path :=
      Ada.Strings.Unbounded.to_unbounded_string
        (Ada.Command_Line.argument (1));

    declare
      i : Positive := 2;
    begin
      while i <= Ada.Command_Line.argument_count loop
        declare
          arg : constant String :=
            Ada.Command_Line.argument (i);
        begin
          if arg = "-o" then
            i := i + 1;

            if i <= Ada.Command_Line.argument_count then
              opts.has_output  := True;
              opts.output_path :=
                Ada.Strings.Unbounded.to_unbounded_string
                  (Ada.Command_Line.argument (i));
            end if;
          end if;
        end;

        i := i + 1;
      end loop;
    end;

    return opts;
  end parse;

end Adac.Support.CLI;
