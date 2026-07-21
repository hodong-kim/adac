-- ============================================================================
-- adac-backend-dump.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Adac.Backend.Dump is

  procedure emit (module : Adac.IR.Module) is
    entry_name : constant String :=
      Ada.Strings.Unbounded.to_string (module.entry_name);
  begin
    Ada.Text_IO.put_line ("adac: ir entry " & entry_name);

    for instruction of module.instructions loop
      case instruction.kind is
        when Adac.IR.Null_Instruction =>
          Ada.Text_IO.put_line ("adac: ir null");

        when Adac.IR.Return_Instruction =>
          Ada.Text_IO.put_line ("adac: ir return");
      end case;
    end loop;

  end emit;

end Adac.Backend.Dump;
