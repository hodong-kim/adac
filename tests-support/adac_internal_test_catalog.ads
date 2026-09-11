-- ============================================================================
-- adac_internal_test_catalog.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac_Internal_Test_Catalog is

  type Scenario is
    (Context_And_Identifiers,
     AST_Expressions_And_Statements,
     AST_Declarations_And_Packages,
     Frontend_Rejections,
     Bootstrap_Package_Ownership,
     Bootstrap_Resource_Boundaries,
     Bootstrap_Profile_Frontend,
     Parser_And_Resource_Contracts,
     Semantic_And_Pipeline,
     IR_Validation,
     Test_Infrastructure);

  function scenario_name (item : Scenario) return String;

  function scenario_from_name (name : String) return Scenario;

end Adac_Internal_Test_Catalog;
