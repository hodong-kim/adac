-- ============================================================================
-- adac_internal_test_catalog.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac_Internal_Test_Catalog is

  function scenario_name (item : Scenario) return String is
  begin
    case item is
      when Context_And_Identifiers =>
        return "context-and-identifiers";
      when AST_Expressions_And_Statements =>
        return "ast-expressions-and-statements";
      when AST_Declarations_And_Packages =>
        return "ast-declarations-and-packages";
      when Frontend_Rejections =>
        return "frontend-rejections";
      when Bootstrap_Package_Ownership =>
        return "bootstrap-package-ownership";
      when Bootstrap_Resource_Boundaries =>
        return "bootstrap-resource-boundaries";
      when Bootstrap_Profile_Frontend =>
        return "bootstrap-profile-frontend";
      when Parser_And_Resource_Contracts =>
        return "parser-and-resource-contracts";
      when Semantic_And_Pipeline =>
        return "semantic-and-pipeline";
      when IR_Validation =>
        return "ir-validation";
      when Test_Infrastructure =>
        return "test-infrastructure";
    end case;
  end scenario_name;

  function scenario_from_name (name : String) return Scenario is
  begin
    for item in Scenario loop
      if name = scenario_name (item) then
        return item;
      end if;
    end loop;

    raise Constraint_Error with "unknown internal test scenario: " & name;
  end scenario_from_name;

end Adac_Internal_Test_Catalog;
