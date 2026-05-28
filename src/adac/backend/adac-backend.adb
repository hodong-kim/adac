-- ============================================================================
-- adac-backend.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Backend.Dump;
with Adac.Backend.Native;

package body Adac.Backend is

  function emit (module      : Adac.IR.Module;
                 output_path : String) return Boolean is
  begin
    if not Adac.Backend.Dump.emit (module) then
      return False;
    end if;

    return Adac.Backend.Native.emit (module, output_path);
  end emit;

end Adac.Backend;
