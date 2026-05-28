-- ============================================================================
-- adac-backend-native.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Text_IO;

package body Adac.Backend.Native is

  function emit (module      : Adac.IR.Module;
                 output_path : String) return Boolean
  is
    pragma unreferenced (module);
    file : Ada.Text_IO.File_Type;
  begin
    Ada.Text_IO.create (file, Ada.Text_IO.out_file, output_path & ".s");

    Ada.Text_IO.put_line (file, ".global main");
    Ada.Text_IO.put_line (file, "main:");
    Ada.Text_IO.put_line (file, "  xorl %eax, %eax");
    Ada.Text_IO.put_line (file, "  ret");

    Ada.Text_IO.close (file);

    return True;
  end emit;

end Adac.Backend.Native;
