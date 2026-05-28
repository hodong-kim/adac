-- ============================================================================
-- adac-ast.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

package Adac.AST is

  type Compilation_Unit is record
    procedure_name : Ada.Strings.Unbounded.Unbounded_String;
    end_name       : Ada.Strings.Unbounded.Unbounded_String;
  end record;

end Adac.AST;
