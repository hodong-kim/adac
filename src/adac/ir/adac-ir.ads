-- ============================================================================
-- adac-ir.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Adac.IR is

  type Scalar_Type_Kind is
    (Signed_Integer_32_Type,
     Boolean_Type);

  type Local_Declaration is record
    name       : Ada.Strings.Unbounded.Unbounded_String;
    value_type : Scalar_Type_Kind := Signed_Integer_32_Type;
  end record;

  package Local_Declaration_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Local_Declaration,
     "="          => "=");

  subtype Local_Declaration_List is Local_Declaration_Vectors.Vector;

  type Value_ID is new Natural;
  INVALID_VALUE_ID : constant Value_ID := 0;

  type Value_Kind is
    (Integer_Constant_Value,
     Boolean_Constant_Value,
     Local_Load_Value,
     Boolean_Not_Value,
     Boolean_Binary_Value,
     Boolean_And_Then_Value,
     Boolean_Or_Else_Value);

  type Boolean_Binary_Operator_Kind is
    (No_Boolean_Binary_Operator,
     And_Boolean_Binary_Operator,
     Or_Boolean_Binary_Operator,
     Xor_Boolean_Binary_Operator,
     Equal_Boolean_Binary_Operator,
     Not_Equal_Boolean_Binary_Operator,
     Less_Boolean_Binary_Operator,
     Less_Equal_Boolean_Binary_Operator,
     Greater_Boolean_Binary_Operator,
     Greater_Equal_Boolean_Binary_Operator);

  type Value is record
    kind          : Value_Kind := Integer_Constant_Value;
    value_type    : Scalar_Type_Kind := Signed_Integer_32_Type;
    integer_value : Long_Long_Integer := 0;
    boolean_value : Boolean := False;
    source_local       : Natural := 0;
    boolean_operator   : Boolean_Binary_Operator_Kind :=
      No_Boolean_Binary_Operator;
    operand_value      : Value_ID := INVALID_VALUE_ID;
    right_operand_value : Value_ID := INVALID_VALUE_ID;
  end record;

  package Value_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Value);

  subtype Value_List is Value_Vectors.Vector;

  type Instruction_Kind is
    (Null_Instruction,
     Return_Instruction,
     Store_Local_Instruction);

  type Instruction is record
    kind         : Instruction_Kind := Null_Instruction;
    target_local : Natural := 0;
    value        : Value_ID := INVALID_VALUE_ID;
  end record;

  package Instruction_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Instruction);

  subtype Instruction_List is Instruction_Vectors.Vector;

  type Module is record
    entry_name   : Ada.Strings.Unbounded.Unbounded_String;
    locals       : Local_Declaration_List;
    values       : Value_List;
    instructions : Instruction_List;
  end record;

  --! summary
  --!   Validates one target-independent IR module.
  --! contract
  --!   Raises `Program_Error` when an internal module invariant is violated.
  --!   Validation reports no source diagnostic and does not modify `module`.
  procedure validate (module_value : Module);

end Adac.IR;
