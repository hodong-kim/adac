-- ============================================================================
-- adac_test_runner.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Ada.Command_Line;
with Ada.Exceptions;

with Adac_Compiler_Fixtures;
with Adac_Internal_Test_Case;
with Clair.Test.Reporter;

procedure adac_test_runner is
  reporter : Clair.Test.Reporter.Context;
begin
  Clair.Test.Reporter.configure_from_command_line (reporter);
  Clair.Test.Reporter.print_header (reporter);
  Clair.Test.Reporter.set_suite_count (reporter, 2);

  Adac_Compiler_Fixtures.run (reporter);
  Adac_Internal_Test_Case.run (reporter);

  Clair.Test.Reporter.print_summary (reporter);

  if Clair.Test.Reporter.has_failures (reporter) then
    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
  else
    Ada.Command_Line.set_exit_status (Ada.Command_Line.Success);
  end if;
exception
  when e : others =>
    Clair.Test.Reporter.print_exception
      (reporter,
       Ada.Exceptions.exception_name (e),
       Ada.Exceptions.exception_message (e),
       Ada.Exceptions.exception_information (e));

    Ada.Command_Line.set_exit_status (Ada.Command_Line.Failure);
end adac_test_runner;
