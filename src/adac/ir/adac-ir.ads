-- ============================================================================
-- adac-ir.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Adac.IR is

  type Instruction_Kind is
    (Null_Instruction,
     Return_Instruction);

  type Instruction is record
    kind : Instruction_Kind;
  end record;

  package Instruction_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Instruction);

  subtype Instruction_List is Instruction_Vectors.Vector;

  type Module is record
    entry_name   : Ada.Strings.Unbounded.Unbounded_String;
    instructions : Instruction_List;
  end record;

end Adac.IR;
