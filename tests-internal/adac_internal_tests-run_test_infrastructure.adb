-- ============================================================================
-- adac_internal_tests-run_test_infrastructure.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_Test_Infrastructure is
begin
  require
    (Adac_Assembly_Patterns.matches
       ("+ frame" & Ada.Characters.Latin_1.LF &
        "+ store" & Ada.Characters.Latin_1.LF,
        "header" & Ada.Characters.Latin_1.LF &
        "frame setup" & Ada.Characters.Latin_1.LF &
        "unrelated" & Ada.Characters.Latin_1.LF &
        "store value" & Ada.Characters.Latin_1.LF),
     "assembly patterns rejected ordered required fragments");
  require
    (not Adac_Assembly_Patterns.matches
       ("+ store" & Ada.Characters.Latin_1.LF &
        "+ frame" & Ada.Characters.Latin_1.LF,
        "frame setup" & Ada.Characters.Latin_1.LF &
        "store value" & Ada.Characters.Latin_1.LF),
     "assembly patterns accepted reversed required fragments");
  require
    (not Adac_Assembly_Patterns.matches
       ("! forbidden" & Ada.Characters.Latin_1.LF,
        "allowed" & Ada.Characters.Latin_1.LF &
        "forbidden instruction" & Ada.Characters.Latin_1.LF),
     "assembly patterns accepted a forbidden fragment");
  require
    (Adac_Assembly_Patterns.matches
       ("# comment" & Ada.Characters.Latin_1.LF &
        Ada.Characters.Latin_1.LF &
        "! forbidden" & Ada.Characters.Latin_1.LF &
        "+ allowed" & Ada.Characters.Latin_1.LF,
        "allowed instruction" & Ada.Characters.Latin_1.LF),
     "assembly patterns mishandled comments or absent forbidden fragments");
  require
    (not accepts_assembly_patterns
       ("required without directive" & Ada.Characters.Latin_1.LF, "assembly"),
     "assembly patterns accepted an invalid directive");
  require
    (not accepts_assembly_patterns
       ("+ " & Ada.Characters.Latin_1.LF, "assembly"),
     "assembly patterns accepted an empty operand");
  require
    (not accepts_assembly_patterns
       ("# comments only" & Ada.Characters.Latin_1.LF, "assembly"),
     "assembly patterns accepted a directive-free oracle");
end Run_Test_Infrastructure;
