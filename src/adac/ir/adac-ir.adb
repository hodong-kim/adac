-- ============================================================================
-- adac-ir.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.IR is

  procedure validate (value : Module) is
  begin
    if Ada.Strings.Unbounded.length (value.entry_name) = 0 then
      raise Program_Error with "Adac.IR: module entry name is empty";
    end if;

    if value.instructions.is_empty then
      raise Program_Error with "Adac.IR: module instruction list is empty";
    end if;
  end validate;

end Adac.IR;
