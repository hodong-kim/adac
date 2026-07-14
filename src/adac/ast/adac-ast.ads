-- ============================================================================
-- adac-ast.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Adac.AST is

  type Statement_Kind is
    (Null_Statement);

  type Statement is record
    kind : Statement_Kind;
  end record;

  package Statement_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Statement);

  subtype Statement_List is Statement_Vectors.Vector;

  type Compilation_Unit is record
    procedure_name : Ada.Strings.Unbounded.Unbounded_String;
    statements     : Statement_List;
    end_name       : Ada.Strings.Unbounded.Unbounded_String;
  end record;

end Adac.AST;
