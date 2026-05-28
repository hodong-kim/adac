-- ============================================================================
-- adac-backend-dump.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Adac.Backend.Dump is

  function emit (module : Adac.IR.Module) return Boolean is
    entry_name : constant String :=
      Ada.Strings.Unbounded.to_string (module.entry_name);
  begin
    Ada.Text_IO.put_line ("adac: ir entry " & entry_name);
    return True;
  end emit;

end Adac.Backend.Dump;
