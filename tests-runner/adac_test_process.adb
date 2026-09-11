-- ============================================================================
-- adac_test_process.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Ada.Characters.Latin_1;
with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Real_Time;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with Adac_Test_Files;
with Clair.Process;
with Clair.Status;
with System.Storage_Elements;

package body Adac_Test_Process is

  use type Clair.Process.Exit_Code;
  use type Clair.Status.Code;

  PROCESS_CAPTURE_BYTES : constant Natural := 1_024 * 1_024;
  PROCESS_TIMEOUT : constant Ada.Real_Time.Time_Span
                  := Ada.Real_Time.Seconds (120);
  FAILURE_OUTPUT_BYTES : constant Natural := 8 * 1_024;

  function required_environment_value (name : String) return String is
  begin
    if not Ada.Environment_Variables.exists (name) then
      raise Program_Error with name & " is not configured";
    end if;

    declare
      value : constant String := Ada.Environment_Variables.value (name);
    begin
      if value'length = 0 then
        raise Program_Error with name & " is empty";
      end if;

      return value;
    end;
  end required_environment_value;

  function optional_environment_value (name : String) return String is
  begin
    if Ada.Environment_Variables.exists (name) then
      return Ada.Environment_Variables.value (name);
    end if;

    return "";
  end optional_environment_value;

  function read_expected_process_result
    (path : String)
  return Expected_Process_Status
  is
    text : constant String := Adac_Test_Files.trim_ascii_whitespace
      (Adac_Test_Files.read_file (path));
  begin
    if text = "success" then
      return Expect_Success;
    elsif text = "failure" then
      return Expect_Failure;
    end if;

    raise Program_Error with
      "expected result must be success or failure: " & path;
  end read_expected_process_result;

  function output_text
    (item           : Clair.Process.Execution.Result;
     standard_error : Boolean)
  return String
  is
    length : constant Natural :=
      (if standard_error
       then Clair.Process.Execution.standard_error_length (item)
       else Clair.Process.Execution.standard_output_length (item));
  begin
    if length = 0 then
      return "";
    end if;

    declare
      bytes : System.Storage_Elements.Storage_Array
        (1 .. System.Storage_Elements.Storage_Offset (length));
      copied : Natural;
      status : Clair.Status.Code;
      result : String (1 .. length);
    begin
      if standard_error then
        status := Clair.Process.Execution.copy_standard_error
          (item, 0, bytes, copied);
      else
        status := Clair.Process.Execution.copy_standard_output
          (item, 0, bytes, copied);
      end if;

      if status /= Clair.Status.OK or else copied /= length then
        raise Program_Error with "failed to copy retained process output";
      end if;

      for i in result'range loop
        result(i) := Character'val
          (System.Storage_Elements.Storage_Element'pos
             (bytes(System.Storage_Elements.Storage_Offset (i))));
      end loop;

      return result;
    end;
  end output_text;

  function bounded_output (value : String) return String is
  begin
    if value'length <= FAILURE_OUTPUT_BYTES then
      return value;
    end if;

    return value(value'first .. value'first + FAILURE_OUTPUT_BYTES - 1) &
      Ada.Characters.Latin_1.LF &
      "[output detail truncated by Adac test adapter]";
  end bounded_output;

  function replace_all
    (value       : String;
     old_spelling : String;
     new_spelling : String)
  return String
  is
    result : Ada.Strings.Unbounded.Unbounded_String;
    cursor : Natural := value'first;
  begin
    if old_spelling'length = 0 or else value'length = 0 then
      return value;
    end if;

    while cursor <= value'last loop
      declare
        found : constant Natural := Ada.Strings.Fixed.index
          (value(cursor .. value'last), old_spelling);
      begin
        if found = 0 then
          Ada.Strings.Unbounded.append
            (result, value(cursor .. value'last));
          exit;
        end if;

        if found > cursor then
          Ada.Strings.Unbounded.append
            (result, value(cursor .. found - 1));
        end if;
        Ada.Strings.Unbounded.append (result, new_spelling);
        cursor := found + old_spelling'length;
      end;
    end loop;

    return Ada.Strings.Unbounded.to_string (result);
  end replace_all;

  procedure configure_command
    (command    : in out Clair.Process.Execution.Command;
     executable : String;
     root       : String)
  is
    limits : Clair.Process.Execution.Resource_Limits
           := Clair.Process.Execution.default_resource_limits;
    policy : constant Clair.Process.Execution.Timeout_Policy
           := (mode            => Clair.Process.Execution.Timeout_Enabled,
               interval        => PROCESS_TIMEOUT,
               graceful_period => Ada.Real_Time.Seconds (1),
               scope           => Clair.Process.Execution.Process_Tree);
    retval : Clair.Status.Code;
  begin
    limits.stdout_capture_bytes := PROCESS_CAPTURE_BYTES;
    limits.stderr_capture_bytes := PROCESS_CAPTURE_BYTES;

    retval := Clair.Process.Execution.set_resource_limits (command, limits);

    if retval /= Clair.Status.OK then
      raise Program_Error with "set_resource_limits failed";
    end if;

    retval := Clair.Process.Execution.set_executable (command, executable);

    if retval /= Clair.Status.OK then
      raise Program_Error with "set_executable failed";
    end if;

    retval := Clair.Process.Execution.set_working_directory (command, root);

    if retval /= Clair.Status.OK then
      raise Program_Error with "set_working_directory failed";
    end if;

    retval := Clair.Process.Execution.set_timeout_policy (command, policy);

    if retval /= Clair.Status.OK then
      raise Program_Error with "set_timeout_policy failed";
    end if;
  end configure_command;

  procedure add_argument
    (command : in out Clair.Process.Execution.Command;
     value   : String)
  is
    retval : constant Clair.Status.Code :=
      Clair.Process.Execution.add_argument (command, value);
  begin
    if retval /= Clair.Status.OK then
      raise Program_Error with "add_argument failed";
    end if;
  end add_argument;

  procedure report_diagnostic
    (reporter : in out Clair.Test.Reporter.Context;
     failed   : in out Boolean;
     message  : String)
  is
  begin
    failed := True;
    Clair.Test.Reporter.diagnostic_failure (reporter, message);
  end report_diagnostic;

  procedure report_assertion
    (reporter : in out Clair.Test.Reporter.Context;
     failed   : in out Boolean;
     message  : String)
  is
  begin
    failed := True;
    Clair.Test.Reporter.assertion_failure (reporter, message);
  end report_assertion;

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
     normalize_stdout_to   : String := "")
  is
    item : Clair.Process.Execution.Result :=
      Clair.Process.Execution.empty_result;
    retval      : Clair.Status.Code;
    stdout_text : Ada.Strings.Unbounded.Unbounded_String;
    stderr_text : Ada.Strings.Unbounded.Unbounded_String;
    process_ok  : Boolean := True;
  begin
    retval := Clair.Process.Execution.execute (command, item);

    if retval /= Clair.Status.OK then
      process_ok := False;
      report_diagnostic
        (reporter,
         failed,
         label_text & ": execution infrastructure status " &
         Clair.Status.Code'image (retval));
    end if;

    if Clair.Process.Execution.has_infrastructure_failure (item) then
      process_ok := False;
      report_diagnostic
        (reporter,
         failed,
         label_text & ": infrastructure stage " &
         Clair.Process.Execution.Infrastructure_Stage'image
           (Clair.Process.Execution.infrastructure_stage_of (item)) &
         ", status " &
         Clair.Status.Code'image
           (Clair.Process.Execution.infrastructure_status_of (item)));
    end if;

    if not Clair.Process.Execution.has_completion (item) then
      process_ok := False;
      report_diagnostic
        (reporter, failed, label_text & ": no process completion");
    else
      case Clair.Process.Execution.completion_of (item) is
        when Clair.Process.Execution.Exited =>
          declare
            actual_success : constant Boolean :=
              Clair.Process.Execution.exit_code_of (item) =
                Clair.Process.EXIT_SUCCESS;
            expected_success : constant Boolean :=
              expected_status = Expect_Success;
          begin
            if actual_success /= expected_success then
              process_ok := False;
              report_assertion
                (reporter,
                 failed,
                 label_text & ": expected " &
                 (if expected_success then "success" else "failure") &
                 ", got exit status" &
                 Clair.Process.Exit_Code'image
                   (Clair.Process.Execution.exit_code_of (item)));
            end if;
          end;

        when Clair.Process.Execution.Signaled =>
          process_ok := False;
          report_diagnostic
            (reporter,
             failed,
             label_text & ": process terminated by signal" &
             Integer'image
               (Clair.Process.Execution.signal_number_of (item)));

        when Clair.Process.Execution.Timed_Out =>
          process_ok := False;
          report_diagnostic
            (reporter, failed, label_text & ": process timed out");

        when Clair.Process.Execution.Launch_Failed =>
          process_ok := False;
          report_diagnostic
            (reporter,
             failed,
             label_text & ": launch failed at " &
             Clair.Process.Execution.Launch_Stage'image
               (Clair.Process.Execution.launch_stage_of (item)) &
             " with status " &
             Clair.Status.Code'image
               (Clair.Process.Execution.launch_status_of (item)));
      end case;
    end if;

    if Clair.Process.Execution.is_available (item) then
      if Clair.Process.Execution.standard_output_truncated (item) then
        process_ok := False;
        report_diagnostic
          (reporter, failed, label_text & ": stdout exceeded capture limit");
      end if;

      if Clair.Process.Execution.standard_error_truncated (item) then
        process_ok := False;
        report_diagnostic
          (reporter, failed, label_text & ": stderr exceeded capture limit");
      end if;
    end if;

    if Clair.Process.Execution.is_available (item) and then
       Clair.Process.Execution.cleanup_status_of (item) /= Clair.Status.OK
    then
      declare
        prefix : constant String :=
          (if process_ok then ": cleanup status "
           else ": secondary cleanup status ");
      begin
        process_ok := False;
        report_diagnostic
          (reporter,
           failed,
           label_text & prefix &
           Clair.Status.Code'image
             (Clair.Process.Execution.cleanup_status_of (item)));
      end;
    end if;

    if Clair.Process.Execution.is_available (item) then
      declare
        prefix : constant String :=
          (if process_ok then ": retained output read failure: "
           else ": secondary retained output read failure: ");
      begin
        declare
          raw_stdout : constant String :=
            output_text (item, standard_error => False);
          normalized_stdout : constant String :=
            (if normalize_stdout_from'length = 0
             then raw_stdout
             else replace_all
               (raw_stdout,
                normalize_stdout_from,
                normalize_stdout_to));
        begin
          stdout_text := Ada.Strings.Unbounded.to_unbounded_string
            (normalized_stdout);
        end;
        stderr_text := Ada.Strings.Unbounded.to_unbounded_string
          (output_text (item, standard_error => True));
      exception
        when e : others =>
          process_ok := False;
          report_diagnostic
            (reporter,
             failed,
             label_text & prefix &
             Ada.Exceptions.exception_name (e) & ": " &
             Ada.Exceptions.exception_message (e));
      end;
    end if;

    if actual_stdout'length > 0 then
      declare
        prefix : constant String :=
          (if process_ok then ": actual output write failure: "
           else ": secondary actual output write failure: ");
      begin
        Adac_Test_Files.write_file
          (actual_stdout,
           Ada.Strings.Unbounded.to_string (stdout_text));
      exception
        when e : others =>
          process_ok := False;
          report_diagnostic
            (reporter,
             failed,
             label_text & prefix &
             Ada.Exceptions.exception_name (e) & ": " &
             Ada.Exceptions.exception_message (e));
      end;
    end if;

    if actual_stderr'length > 0 then
      declare
        prefix : constant String :=
          (if process_ok then ": actual stderr write failure: "
           else ": secondary actual stderr write failure: ");
      begin
        Adac_Test_Files.write_file
          (actual_stderr,
           Ada.Strings.Unbounded.to_string (stderr_text));
      exception
        when e : others =>
          process_ok := False;
          report_diagnostic
            (reporter,
             failed,
             label_text & prefix &
             Ada.Exceptions.exception_name (e) & ": " &
             Ada.Exceptions.exception_message (e));
      end;
    end if;

    if process_ok and then compare_stderr_to'length > 0 then
      begin
        if not Adac_Test_Files.files_equal
          (compare_stderr_to, actual_stderr)
        then
          report_assertion
            (reporter,
             failed,
             label_text & ": stderr mismatch; compare " &
             compare_stderr_to & " with " & actual_stderr);
        end if;
      exception
        when e : others =>
          report_diagnostic
            (reporter,
             failed,
             label_text & ": stderr comparison failure: " &
             Ada.Exceptions.exception_name (e) & ": " &
             Ada.Exceptions.exception_message (e));
      end;
    elsif process_ok and then require_empty_stderr and then
          Ada.Strings.Unbounded.length (stderr_text) > 0
    then
      report_assertion
        (reporter, failed, label_text & ": unexpected stderr output");
    end if;

    if not process_ok and then
       Ada.Strings.Unbounded.length (stderr_text) > 0
    then
      report_diagnostic
        (reporter,
         failed,
         label_text & " stderr:" & Ada.Characters.Latin_1.LF &
         bounded_output (Ada.Strings.Unbounded.to_string (stderr_text)));
    end if;

    if process_ok and then compare_stdout_to'length > 0 then
      begin
        if not Adac_Test_Files.files_equal
          (compare_stdout_to, actual_stdout)
        then
          report_assertion
            (reporter,
             failed,
             label_text & ": output mismatch; compare " &
             compare_stdout_to & " with " & actual_stdout);
        end if;
      exception
        when e : others =>
          report_diagnostic
            (reporter,
             failed,
             label_text & ": output comparison failure: " &
             Ada.Exceptions.exception_name (e) & ": " &
             Ada.Exceptions.exception_message (e));
      end;
    end if;
  end run_process;

  procedure complete_fixture
    (reporter : in out Clair.Test.Reporter.Context;
     failed   : Boolean;
     name     : String)
  is
  begin
    if not failed then
      Clair.Test.Reporter.record_assertion_pass (reporter, name);
      Clair.Test.Reporter.pass (reporter, name);
    end if;
  end complete_fixture;

end Adac_Test_Process;
