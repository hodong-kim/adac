-- ============================================================================
-- adac-backend.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Exceptions;
with Ada.IO_Exceptions;

with Adac.Backend.Dump;
with Adac.Backend.Native;

package body Adac.Backend is

  function emit
    (module      : Adac.IR.Module;
     output_path : String)
  return Emission_Result
  is
  begin
    Adac.IR.validate (module);
    Adac.Backend.Dump.emit (module);
    Adac.Backend.Native.emit (module, output_path);

    return (status => Emission_Succeeded);
  exception
    when error : Operational_Error =>
      return
        (status     => Emission_Operational_Failure,
         diagnostic => Ada.Strings.Unbounded.to_unbounded_string
                         (Ada.Exceptions.exception_message (error)));

    when Ada.IO_Exceptions.Name_Error |
         Ada.IO_Exceptions.Use_Error |
         Ada.IO_Exceptions.Device_Error =>
      return
        (status     => Emission_Operational_Failure,
         diagnostic => Ada.Strings.Unbounded.to_unbounded_string
                         ("I/O failure during backend emission: " &
                          output_path));
  end emit;

  function failure_message (result : Emission_Result) return String is
  begin
    return Ada.Strings.Unbounded.to_string (result.diagnostic);
  end failure_message;

end Adac.Backend;
