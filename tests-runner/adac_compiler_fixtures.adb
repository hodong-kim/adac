-- ============================================================================
-- adac_compiler_fixtures.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Ada.Characters.Latin_1;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Strings.Unbounded;

with Adac_Assembly_Patterns;
with Adac_Test_Files;
with Adac_Test_Process;
with Clair.Process.Execution;
with Clair.Status;

package body Adac_Compiler_Fixtures is

  use type Ada.Directories.File_Kind;
  use type Adac_Test_Process.Expected_Process_Status;
  use type Clair.Status.Code;

  DIAGNOSTIC_PREFIX : constant String := "adac: error:";
  MAXIMUM_FIXTURE_DIRECTORY_DEPTH : constant Natural := 8;

  function diagnostic_output (value : String) return String is
    result     : Ada.Strings.Unbounded.Unbounded_String;
    line_first : Integer := value'first;
  begin
    while line_first <= value'last loop
      declare
        line_after : Integer := line_first;
      begin
        while line_after <= value'last and then
              value(line_after) /= Ada.Characters.Latin_1.LF
        loop
          line_after := line_after + 1;
        end loop;

        if line_after - line_first >= DIAGNOSTIC_PREFIX'length and then
           value
             (line_first .. line_first + DIAGNOSTIC_PREFIX'length - 1) =
           DIAGNOSTIC_PREFIX
        then
          Ada.Strings.Unbounded.append
            (result, value(line_first .. line_after - 1));

          if line_after <= value'last then
            Ada.Strings.Unbounded.append
              (result, String'(1 => Ada.Characters.Latin_1.LF));
          end if;
        end if;

        line_first := line_after + 1;
      end;
    end loop;

    return Ada.Strings.Unbounded.to_string (result);
  end diagnostic_output;

  function compiler_fixture_directory (path : String) return Boolean is
    input_file : constant String :=
      Adac_Test_Files.fixture_path (path, "input.adb");
    input_path_file : constant String :=
      Adac_Test_Files.fixture_path (path, "input-path.txt");
  begin
    return Ada.Directories.exists (input_file) or else
      Ada.Directories.exists (input_path_file);
  end compiler_fixture_directory;

  function discover_compiler_fixtures
    (root : String)
  return Adac_Test_Files.Path_Sets.Set
  is
    result : Adac_Test_Files.Path_Sets.Set;

    procedure visit
      (directory : String;
       depth     : Natural)
    is
      children : constant Adac_Test_Files.Path_Sets.Set :=
        Adac_Test_Files.discover_directories (directory);
    begin
      for child of children loop
        if compiler_fixture_directory (child) then
          result.include (child);
        elsif depth >= MAXIMUM_FIXTURE_DIRECTORY_DEPTH then
          raise Program_Error with
            "compiler fixture directory nesting limit exceeded at " & child;
        else
          visit (child, depth + 1);
        end if;
      end loop;
    end visit;

  begin
    if not Ada.Directories.exists (root) or else
       Ada.Directories.kind (root) /= Ada.Directories.Directory
    then
      raise Program_Error with "compiler fixture root is not a directory";
    end if;

    visit (root, 0);
    return result;
  end discover_compiler_fixtures;

  procedure run_fixture
    (reporter      : in out Clair.Test.Reporter.Context;
     root          : String;
     fixtures_root : String;
     compiler      : String;
     exe_ext       : String;
     work_root     : String;
     fixture       : String)
  is
    function relative_suffix return String is
      prefix_last : constant Integer :=
        fixture'first + fixtures_root'length - 1;
    begin
      if fixture'length <= fixtures_root'length or else
         fixture(fixture'first .. prefix_last) /= fixtures_root
      then
        raise Program_Error with
          "compiler fixture is outside the configured fixture root";
      end if;

      return fixture(prefix_last + 1 .. fixture'last);
    end relative_suffix;

    suffix : constant String := relative_suffix;
    input_file : constant String :=
      Adac_Test_Files.fixture_path (fixture, "input.adb");
    input_path_file : constant String :=
      Adac_Test_Files.fixture_path (fixture, "input-path.txt");
    arguments_file : constant String :=
      Adac_Test_Files.fixture_path (fixture, "arguments.txt");
    fixture_name : constant String := "tests" & suffix;
    command_input_path : constant String :=
      Ada.Directories.compose (fixture_name, "input.adb");
    display_output_path : constant String :=
      Ada.Directories.compose (fixture_name, "main" & exe_ext);
    work_directory : constant String :=
      Adac_Test_Files.fixture_path (work_root, "compiler") & suffix;
    output_path : constant String :=
      Adac_Test_Files.fixture_path (work_directory, "main" & exe_ext);
    asm_path : constant String := output_path & ".s";
    actual_stdout_path : constant String :=
      Adac_Test_Files.fixture_path (work_directory, "stdout.txt");
    actual_stderr_path : constant String :=
      Adac_Test_Files.fixture_path (work_directory, "stderr.txt");
    actual_diagnostics_path : constant String :=
      Adac_Test_Files.fixture_path (work_directory, "diagnostics.txt");
    expected_stdout_path : constant String :=
      Adac_Test_Files.fixture_path (fixture, "expected-stdout.txt");
    expected_diagnostics_path : constant String :=
      Adac_Test_Files.fixture_path (fixture, "expected-diagnostics.txt");
    expected_stderr_path : constant String :=
      Adac_Test_Files.fixture_path (fixture, "expected-stderr.txt");
    result_path : constant String :=
      Adac_Test_Files.fixture_path (fixture, "expected-result.txt");
    assembly_expected_path : constant String :=
      Adac_Test_Files.fixture_path (fixture, "expected-assembly.txt");
    assembly_patterns_path : constant String :=
      Adac_Test_Files.fixture_path
        (fixture, "expected-assembly-patterns.txt");
    omit_output_option : constant Boolean := Ada.Directories.exists
      (Adac_Test_Files.fixture_path
         (fixture, "omit-output-option.txt"));
    output_is_directory : constant Boolean := Ada.Directories.exists
      (Adac_Test_Files.fixture_path
         (fixture, "output-is-directory.txt"));
    missing_toolchain : constant Boolean := Ada.Directories.exists
      (Adac_Test_Files.fixture_path (fixture, "missing-toolchain.txt"));
    preserve_output : constant Boolean := Ada.Directories.exists
      (Adac_Test_Files.fixture_path (fixture, "preserve-output.txt"));
    failed : Boolean := False;

    procedure execute_fixture is
      input : Ada.Strings.Unbounded.Unbounded_String;
      arguments : Adac_Test_Files.String_Vectors.Vector;
      expected_status : Adac_Test_Process.Expected_Process_Status;
      command : Clair.Process.Execution.Command :=
        Clair.Process.Execution.empty_command;
      retval : Clair.Status.Code;
    begin
      if Ada.Directories.exists (input_file) and then
         Ada.Directories.exists (input_path_file)
      then
        raise Program_Error with
          "both input.adb and input-path.txt exist";
      elsif Ada.Directories.exists (input_path_file) then
        input := Ada.Strings.Unbounded.to_unbounded_string
          (Adac_Test_Files.trim_ascii_whitespace
             (Adac_Test_Files.read_file (input_path_file)));
      elsif Ada.Directories.exists (input_file) then
        input := Ada.Strings.Unbounded.to_unbounded_string
          (command_input_path);
      else
        raise Program_Error with "compiler fixture has no input";
      end if;

      if Ada.Strings.Unbounded.length (input) = 0 then
        raise Program_Error with "compiler fixture has an empty input path";
      end if;

      if not Ada.Directories.exists (result_path) then
        raise Program_Error with
          "compiler fixture is missing expected-result.txt";
      end if;

      if Ada.Directories.exists (expected_stdout_path) =
         Ada.Directories.exists (expected_diagnostics_path)
      then
        raise Program_Error with
          "compiler fixture requires exactly one stdout oracle";
      end if;

      if Ada.Directories.exists (assembly_expected_path) and then
         Ada.Directories.exists (assembly_patterns_path)
      then
        raise Program_Error with
          "compiler fixture has multiple assembly oracles";
      end if;

      expected_status :=
        Adac_Test_Process.read_expected_process_result (result_path);

      if output_is_directory and then
         expected_status = Adac_Test_Process.Expect_Success
      then
        raise Program_Error with
          "output directory fixture must expect failure";
      elsif missing_toolchain and then
            expected_status = Adac_Test_Process.Expect_Success
      then
        raise Program_Error with
          "missing toolchain fixture must expect failure";
      elsif preserve_output and then
            expected_status = Adac_Test_Process.Expect_Success
      then
        raise Program_Error with
          "preserved output fixture must expect failure";
      end if;

      if Ada.Directories.exists (arguments_file) then
        arguments := Adac_Test_Files.shell_words
          (Adac_Test_Files.read_file (arguments_file));
      end if;

      if Adac_Test_Files.has_backend_work_files (output_path, asm_path) then
        raise Program_Error with "stale backend work files exist";
      end if;

      Adac_Test_Files.remove_path (asm_path);
      Adac_Test_Files.remove_path (output_path);

      if output_is_directory then
        Ada.Directories.create_directory (output_path);
      elsif preserve_output then
        Adac_Test_Files.write_file
          (output_path, "previous-output" & Ada.Characters.Latin_1.LF);
      end if;

      Adac_Test_Process.configure_command (command, compiler, root);
      Adac_Test_Process.add_argument
        (command, Ada.Strings.Unbounded.to_string (input));

      if not omit_output_option then
        Adac_Test_Process.add_argument (command, "-o");
        Adac_Test_Process.add_argument (command, output_path);
      end if;

      for argument of arguments loop
        Adac_Test_Process.add_argument (command, argument);
      end loop;

      if missing_toolchain then
        retval := Clair.Process.Execution.set_environment_value
          (command,
           "ADAC_CC",
           "adac-native-toolchain-does-not-exist");

        if retval /= Clair.Status.OK then
          raise Program_Error with "failed to configure missing toolchain";
        end if;
      end if;

      Adac_Test_Process.run_process
        (reporter              => reporter,
         failed                => failed,
         label_text            => fixture_name,
         command               => command,
         expected_status       => expected_status,
         actual_stdout         => actual_stdout_path,
         compare_stdout_to     =>
           (if Ada.Directories.exists (expected_stdout_path)
            then expected_stdout_path
            else ""),
         actual_stderr         => actual_stderr_path,
         compare_stderr_to     =>
           (if Ada.Directories.exists (expected_stderr_path)
            then expected_stderr_path
            else ""),
         require_empty_stderr  =>
           not Ada.Directories.exists (expected_stderr_path),
         normalize_stdout_from => output_path,
         normalize_stdout_to   => display_output_path);

      if not failed and then
         Ada.Directories.exists (expected_diagnostics_path)
      then
        begin
          Adac_Test_Files.write_file
            (actual_diagnostics_path,
             diagnostic_output
               (Adac_Test_Files.read_file (actual_stdout_path)));

          if not Adac_Test_Files.files_equal
            (expected_diagnostics_path, actual_diagnostics_path)
          then
            Adac_Test_Process.report_assertion
              (reporter,
               failed,
               fixture_name &
               ": diagnostic mismatch; compare " &
               expected_diagnostics_path & " with " &
               actual_diagnostics_path);
          end if;
        exception
          when e : others =>
            Adac_Test_Process.report_diagnostic
              (reporter,
               failed,
               fixture_name & ": diagnostic comparison failure: " &
               Ada.Exceptions.exception_name (e) & ": " &
               Ada.Exceptions.exception_message (e));
        end;
      end if;

      if Ada.Directories.exists (assembly_expected_path) or else
         Ada.Directories.exists (assembly_patterns_path)
      then
        if not Ada.Directories.exists (asm_path) then
          Adac_Test_Process.report_assertion
            (reporter,
             failed,
             fixture_name & ": expected assembly output is missing");
        elsif Ada.Directories.exists (assembly_expected_path) and then
              not Adac_Test_Files.files_equal
                (assembly_expected_path, asm_path)
        then
          Adac_Test_Process.report_assertion
            (reporter,
             failed,
             fixture_name & ": assembly mismatch; compare " &
             assembly_expected_path & " with " & asm_path);
        elsif Ada.Directories.exists (assembly_patterns_path) and then
              not Adac_Assembly_Patterns.matches
                (Adac_Test_Files.read_file (assembly_patterns_path),
                 Adac_Test_Files.read_file (asm_path))
        then
          Adac_Test_Process.report_assertion
            (reporter,
             failed,
             fixture_name & ": assembly pattern mismatch; compare " &
             assembly_patterns_path & " with " & asm_path);
        end if;
      end if;

      if Adac_Test_Files.has_backend_work_files (output_path, asm_path) then
        Adac_Test_Process.report_assertion
          (reporter,
           failed,
           fixture_name & ": backend work files remain");
      end if;

      if expected_status = Adac_Test_Process.Expect_Success then
        if not Ada.Directories.exists (asm_path) then
          Adac_Test_Process.report_assertion
            (reporter,
             failed,
             fixture_name & ": assembly output is missing");
        end if;

        if not Ada.Directories.exists (output_path) then
          Adac_Test_Process.report_assertion
            (reporter,
             failed,
             fixture_name & ": executable output is missing");
        elsif Ada.Directories.kind (output_path) =
              Ada.Directories.Directory
        then
          Adac_Test_Process.report_assertion
            (reporter,
             failed,
             fixture_name & ": executable output is a directory");
        else
          declare
            program_command : Clair.Process.Execution.Command :=
              Clair.Process.Execution.empty_command;
          begin
            Adac_Test_Process.configure_command
              (program_command, output_path, root);
            Adac_Test_Process.run_process
              (reporter,
               failed,
               fixture_name & " generated executable",
               program_command,
               Adac_Test_Process.Expect_Success);
          end;
        end if;
      elsif preserve_output then
        if not Ada.Directories.exists (output_path) or else
           Ada.Directories.kind (output_path) =
             Ada.Directories.Directory or else
           Adac_Test_Files.read_file (output_path) /=
             "previous-output" & Ada.Characters.Latin_1.LF
        then
          Adac_Test_Process.report_assertion
            (reporter,
             failed,
             fixture_name & ": failed compilation replaced prior output");
        end if;
      elsif not output_is_directory and then
            Ada.Directories.exists (output_path)
      then
        Adac_Test_Process.report_assertion
          (reporter,
           failed,
           fixture_name & ": failed compilation published an executable");
      end if;
    end execute_fixture;

  begin
    Clair.Test.Reporter.info (reporter, fixture_name);

    begin
      Ada.Directories.create_path (work_directory);
      execute_fixture;
    exception
      when e : others =>
        Adac_Test_Process.report_diagnostic
          (reporter,
           failed,
           fixture_name & ": adapter failure: " &
           Ada.Exceptions.exception_name (e) & ": " &
           Ada.Exceptions.exception_message (e));
    end;

    if output_is_directory and then Ada.Directories.exists (output_path) then
      begin
        Adac_Test_Files.remove_path (output_path);
      exception
        when e : others =>
          Adac_Test_Process.report_diagnostic
            (reporter,
             failed,
             fixture_name & ": cleanup failure: " &
             Ada.Exceptions.exception_name (e) & ": " &
             Ada.Exceptions.exception_message (e));
      end;
    end if;

    Adac_Test_Process.complete_fixture (reporter, failed, fixture_name);
  end run_fixture;

  procedure run_case
    (reporter : in out Clair.Test.Reporter.Context)
  is
    root : constant String :=
      Adac_Test_Process.required_environment_value ("ADAC_TEST_ROOT");
    compiler : constant String :=
      Adac_Test_Process.required_environment_value
        ("ADAC_TEST_COMPILER_EXECUTABLE");
    exe_ext : constant String :=
      Adac_Test_Process.optional_environment_value
        ("ADAC_TEST_EXECUTABLE_EXTENSION");
    work_root : constant String :=
      Adac_Test_Process.required_environment_value ("ADAC_TEST_WORK_ROOT");
    fixtures_root : constant String :=
      Adac_Test_Files.fixture_path (root, "tests");
    fixtures : constant Adac_Test_Files.Path_Sets.Set :=
      discover_compiler_fixtures (fixtures_root);
    found_fixture : Boolean := False;
  begin
    for fixture of fixtures loop
      found_fixture := True;
      run_fixture
        (reporter, root, fixtures_root, compiler, exe_ext, work_root, fixture);
    end loop;

    if not found_fixture then
      Clair.Test.Reporter.diagnostic_failure
        (reporter, "no compiler fixtures were discovered");
    end if;
  end run_case;

  procedure run_suite
    (reporter : in out Clair.Test.Reporter.Context)
  is
  begin
    Clair.Test.Reporter.run_scenario
      (reporter,
       "all compiler fixtures",
       run_case'access);
  end run_suite;

  procedure run
    (reporter : in out Clair.Test.Reporter.Context)
  is
  begin
    Clair.Test.Reporter.run_suite
      (reporter,
       "Adac compiler fixtures",
       run_suite'access);
  end run;

end Adac_Compiler_Fixtures;
