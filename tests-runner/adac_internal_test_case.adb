-- ============================================================================
-- adac_internal_test_case.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Adac_Internal_Test_Catalog;
with Adac_Test_Process;
with Clair.Process.Execution;

package body Adac_Internal_Test_Case is

  procedure run_internal_scenario
    (reporter : in out Clair.Test.Reporter.Context;
     scenario : Adac_Internal_Test_Catalog.Scenario)
  is
    root : constant String :=
      Adac_Test_Process.required_environment_value ("ADAC_TEST_ROOT");
    executable : constant String :=
      Adac_Test_Process.required_environment_value
        ("ADAC_TEST_INTERNAL_EXECUTABLE");
    name : constant String :=
      Adac_Internal_Test_Catalog.scenario_name (scenario);
    command : Clair.Process.Execution.Command :=
      Clair.Process.Execution.empty_command;
  begin
    Adac_Test_Process.configure_command (command, executable, root);
    Adac_Test_Process.add_argument (command, name);
    Clair.Test.Reporter.run_process_case
      (reporter, "internal/" & name, command);
  end run_internal_scenario;

  procedure run_suite
    (reporter : in out Clair.Test.Reporter.Context)
  is
  begin
    for scenario in Adac_Internal_Test_Catalog.Scenario loop
      run_internal_scenario (reporter, scenario);
    end loop;
  end run_suite;

  procedure run
    (reporter : in out Clair.Test.Reporter.Context)
  is
  begin
    Clair.Test.Reporter.run_suite
      (reporter,
       "Adac internal compiler tests",
       run_suite'access);
  end run;

end Adac_Internal_Test_Case;
