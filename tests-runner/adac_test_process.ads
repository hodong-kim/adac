-- ============================================================================
-- adac_test_process.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Clair.Process.Execution;
with Clair.Test.Reporter;

package Adac_Test_Process is

  type Expected_Process_Status is (Expect_Success, Expect_Failure);

  function required_environment_value (name : String) return String;

  function optional_environment_value (name : String) return String;

  function read_expected_process_result
    (path : String)
  return Expected_Process_Status;

  procedure configure_command
    (command    : in out Clair.Process.Execution.Command;
     executable : String;
     root       : String);

  procedure add_argument
    (command : in out Clair.Process.Execution.Command;
     value   : String);

  procedure report_diagnostic
    (reporter : in out Clair.Test.Reporter.Context;
     failed   : in out Boolean;
     message  : String);

  procedure report_assertion
    (reporter : in out Clair.Test.Reporter.Context;
     failed   : in out Boolean;
     message  : String);

  procedure run_process
    (reporter          : in out Clair.Test.Reporter.Context;
     failed            : in out Boolean;
     label_text        : String;
     command           : Clair.Process.Execution.Command;
     expected_status       : Expected_Process_Status;
     actual_stdout         : String := "";
     compare_stdout_to     : String := "";
     actual_stderr         : String := "";
     compare_stderr_to     : String := "";
     require_empty_stderr  : Boolean := False;
     normalize_stdout_from : String := "";
     normalize_stdout_to   : String := "");

  procedure complete_fixture
    (reporter : in out Clair.Test.Reporter.Context;
     failed   : Boolean;
     name     : String);

end Adac_Test_Process;
