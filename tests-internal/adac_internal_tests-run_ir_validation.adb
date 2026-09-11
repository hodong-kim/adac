-- ============================================================================
-- adac_internal_tests-run_ir_validation.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_IR_Validation is

begin
  declare
    valid_module     : Adac.IR.Module;
    valid_local      : Adac.IR.Module;
    valid_store      : Adac.IR.Module;
    valid_load       : Adac.IR.Module;
    valid_boolean_true  : Adac.IR.Module;
    valid_boolean_false : Adac.IR.Module;
    valid_boolean_load  : Adac.IR.Module;
    valid_boolean_not   : Adac.IR.Module;
    valid_boolean_nested_not : Adac.IR.Module;
    bad_boolean_not_type : Adac.IR.Module;
    bad_boolean_not_operand : Adac.IR.Module;
    bad_boolean_not_kind : Adac.IR.Module;
    bad_boolean_not_payload : Adac.IR.Module;
    valid_boolean_and : Adac.IR.Module;
    valid_boolean_or : Adac.IR.Module;
    valid_boolean_xor : Adac.IR.Module;
    valid_boolean_equal : Adac.IR.Module;
    valid_boolean_not_equal : Adac.IR.Module;
    valid_boolean_less : Adac.IR.Module;
    valid_boolean_less_equal : Adac.IR.Module;
    valid_boolean_greater : Adac.IR.Module;
    valid_boolean_greater_equal : Adac.IR.Module;
    valid_boolean_nested_binary : Adac.IR.Module;
    valid_boolean_and_then : Adac.IR.Module;
    valid_boolean_or_else : Adac.IR.Module;
    bad_boolean_short_type : Adac.IR.Module;
    bad_boolean_short_left : Adac.IR.Module;
    bad_boolean_short_right : Adac.IR.Module;
    bad_boolean_short_kind : Adac.IR.Module;
    bad_boolean_short_payload : Adac.IR.Module;
    bad_boolean_short_reused : Adac.IR.Module;
    bad_boolean_reused_computed : Adac.IR.Module;
    bad_boolean_binary_operator : Adac.IR.Module;
    bad_boolean_binary_type : Adac.IR.Module;
    bad_boolean_binary_left : Adac.IR.Module;
    bad_boolean_binary_right : Adac.IR.Module;
    bad_boolean_binary_kind : Adac.IR.Module;
    bad_boolean_binary_payload : Adac.IR.Module;
    bad_integer_type    : Adac.IR.Module;
    bad_boolean_type    : Adac.IR.Module;
    bad_boolean_payload : Adac.IR.Module;
    bad_boolean_load_payload : Adac.IR.Module;
    empty_name       : Adac.IR.Module;
    empty_local_name : Adac.IR.Module;
    empty_code       : Adac.IR.Module;
    bad_local_ref    : Adac.IR.Module;
    bad_value_ref    : Adac.IR.Module;
    bad_value_range  : Adac.IR.Module;
    bad_load_ref     : Adac.IR.Module;
    bad_load_payload : Adac.IR.Module;
    bad_const_source : Adac.IR.Module;
    bad_simple       : Adac.IR.Module;
  begin
    valid_module.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_module.instructions.append
      (Adac.IR.Instruction'(kind         => Adac.IR.Null_Instruction,
                            target_local => 0,
                            value        => Adac.IR.INVALID_VALUE_ID));

    valid_local.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_local.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("value"),
          value_type => Adac.IR.Signed_Integer_32_Type));
    valid_local.instructions.append
      (Adac.IR.Instruction'(kind         => Adac.IR.Null_Instruction,
                            target_local => 0,
                            value        => Adac.IR.INVALID_VALUE_ID));

    valid_store.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_store.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("value"),
          value_type => Adac.IR.Signed_Integer_32_Type));
    valid_store.values.append
      (Adac.IR.Value'
         (kind          => Adac.IR.Integer_Constant_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 1,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    valid_store.instructions.append
      (Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 1,
          value        => Adac.IR.Value_ID (1)));

    valid_load.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_load.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("source"),
          value_type => Adac.IR.Signed_Integer_32_Type));
    valid_load.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("target"),
          value_type => Adac.IR.Signed_Integer_32_Type));
    valid_load.values.append
      (Adac.IR.Value'
         (kind          => Adac.IR.Local_Load_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 1,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    valid_load.instructions.append
      (Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 2,
          value        => Adac.IR.Value_ID (1)));

    valid_boolean_true.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_boolean_true.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("flag"),
          value_type => Adac.IR.Boolean_Type));
    valid_boolean_true.values.append
      (Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Constant_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 0,
          boolean_value => True,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    valid_boolean_true.instructions.append
      (Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 1,
          value        => Adac.IR.Value_ID (1)));

    valid_boolean_false := valid_boolean_true;
    valid_boolean_false.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Constant_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    valid_boolean_load.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_boolean_load.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("source"),
          value_type => Adac.IR.Boolean_Type));
    valid_boolean_load.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("target"),
          value_type => Adac.IR.Boolean_Type));
    valid_boolean_load.values.append
      (Adac.IR.Value'
         (kind          => Adac.IR.Local_Load_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 1,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    valid_boolean_load.instructions.append
      (Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 2,
          value        => Adac.IR.Value_ID (1)));

    valid_boolean_not := valid_boolean_load;
    valid_boolean_not.values.append
      (Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Not_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.Value_ID (1),
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    valid_boolean_not.instructions.replace_element
      (1,
       Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 2,
          value        => Adac.IR.Value_ID (2)));

    bad_boolean_not_type := valid_boolean_not;
    bad_boolean_not_type.values.replace_element
      (2,
       Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Not_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.Value_ID (1),
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_boolean_not_operand := valid_boolean_not;
    bad_boolean_not_operand.values.replace_element
      (2,
       Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Not_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.Value_ID (2),
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_boolean_not_kind := valid_boolean_not;
    bad_boolean_not_kind.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Integer_Constant_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 1,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    valid_boolean_nested_not := valid_boolean_not;
    valid_boolean_nested_not.values.append
      (Adac.IR.Value'
         (kind                => Adac.IR.Boolean_Not_Value,
          value_type          => Adac.IR.Boolean_Type,
          integer_value       => 0,
          boolean_value       => False,
          source_local        => 0,
          boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
          operand_value       => Adac.IR.Value_ID (2),
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    valid_boolean_nested_not.instructions (1).value := Adac.IR.Value_ID (3);

    bad_boolean_not_payload := valid_boolean_not;
    bad_boolean_not_payload.values.replace_element
      (2,
       Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Not_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 1,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.Value_ID (1),
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    valid_boolean_and.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_boolean_and.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("left"),
          value_type => Adac.IR.Boolean_Type));
    valid_boolean_and.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("right"),
          value_type => Adac.IR.Boolean_Type));
    valid_boolean_and.locals.append
      (Adac.IR.Local_Declaration'
         (name => Ada.Strings.Unbounded.to_unbounded_string ("target"),
          value_type => Adac.IR.Boolean_Type));
    for source_local in 1 .. 2 loop
      valid_boolean_and.values.append
        (Adac.IR.Value'
           (kind                => Adac.IR.Local_Load_Value,
            value_type          => Adac.IR.Boolean_Type,
            integer_value       => 0,
            boolean_value       => False,
            source_local        => source_local,
            boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
            operand_value       => Adac.IR.INVALID_VALUE_ID,
            right_operand_value => Adac.IR.INVALID_VALUE_ID));
    end loop;
    valid_boolean_and.values.append
      (Adac.IR.Value'
         (kind                => Adac.IR.Boolean_Binary_Value,
          value_type          => Adac.IR.Boolean_Type,
          integer_value       => 0,
          boolean_value       => False,
          source_local        => 0,
          boolean_operator    => Adac.IR.And_Boolean_Binary_Operator,
          operand_value       => Adac.IR.Value_ID (1),
          right_operand_value => Adac.IR.Value_ID (2)));
    valid_boolean_and.instructions.append
      (Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 3,
          value        => Adac.IR.Value_ID (3)));

    valid_boolean_or := valid_boolean_and;
    valid_boolean_or.values (3).boolean_operator :=
      Adac.IR.Or_Boolean_Binary_Operator;
    valid_boolean_xor := valid_boolean_and;
    valid_boolean_xor.values (3).boolean_operator :=
      Adac.IR.Xor_Boolean_Binary_Operator;
    valid_boolean_equal := valid_boolean_and;
    valid_boolean_equal.values (3).boolean_operator :=
      Adac.IR.Equal_Boolean_Binary_Operator;
    valid_boolean_not_equal := valid_boolean_and;
    valid_boolean_not_equal.values (3).boolean_operator :=
      Adac.IR.Not_Equal_Boolean_Binary_Operator;
    valid_boolean_less := valid_boolean_and;
    valid_boolean_less.values (3).boolean_operator :=
      Adac.IR.Less_Boolean_Binary_Operator;
    valid_boolean_less_equal := valid_boolean_and;
    valid_boolean_less_equal.values (3).boolean_operator :=
      Adac.IR.Less_Equal_Boolean_Binary_Operator;
    valid_boolean_greater := valid_boolean_and;
    valid_boolean_greater.values (3).boolean_operator :=
      Adac.IR.Greater_Boolean_Binary_Operator;
    valid_boolean_greater_equal := valid_boolean_and;
    valid_boolean_greater_equal.values (3).boolean_operator :=
      Adac.IR.Greater_Equal_Boolean_Binary_Operator;

    valid_boolean_nested_binary := valid_boolean_and;
    valid_boolean_nested_binary.values.append
      (Adac.IR.Value'
         (kind                => Adac.IR.Boolean_Not_Value,
          value_type          => Adac.IR.Boolean_Type,
          integer_value       => 0,
          boolean_value       => False,
          source_local        => 0,
          boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
          operand_value       => Adac.IR.Value_ID (1),
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    valid_boolean_nested_binary.values.append
      (Adac.IR.Value'
         (kind                => Adac.IR.Boolean_Binary_Value,
          value_type          => Adac.IR.Boolean_Type,
          integer_value       => 0,
          boolean_value       => False,
          source_local        => 0,
          boolean_operator    => Adac.IR.Xor_Boolean_Binary_Operator,
          operand_value       => Adac.IR.Value_ID (3),
          right_operand_value => Adac.IR.Value_ID (4)));
    valid_boolean_nested_binary.instructions (1).value := Adac.IR.Value_ID (5);

    valid_boolean_and_then := valid_boolean_and;
    valid_boolean_and_then.values (3).kind := Adac.IR.Boolean_And_Then_Value;
    valid_boolean_and_then.values (3).boolean_operator :=
      Adac.IR.No_Boolean_Binary_Operator;
    valid_boolean_or_else := valid_boolean_and_then;
    valid_boolean_or_else.values (3).kind := Adac.IR.Boolean_Or_Else_Value;

    bad_boolean_short_type := valid_boolean_and_then;
    bad_boolean_short_type.values (3).value_type :=
      Adac.IR.Signed_Integer_32_Type;
    bad_boolean_short_left := valid_boolean_and_then;
    bad_boolean_short_left.values (3).operand_value := Adac.IR.Value_ID (3);
    bad_boolean_short_right := valid_boolean_and_then;
    bad_boolean_short_right.values (3).right_operand_value :=
      Adac.IR.Value_ID (3);
    bad_boolean_short_kind := valid_boolean_and_then;
    bad_boolean_short_kind.values.replace_element
      (2,
       Adac.IR.Value'
         (kind                => Adac.IR.Integer_Constant_Value,
          value_type          => Adac.IR.Signed_Integer_32_Type,
          integer_value       => 1,
          boolean_value       => False,
          source_local        => 0,
          boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
          operand_value       => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    bad_boolean_short_payload := valid_boolean_and_then;
    bad_boolean_short_payload.values (3).boolean_operator :=
      Adac.IR.And_Boolean_Binary_Operator;
    bad_boolean_short_reused := valid_boolean_and_then;
    bad_boolean_short_reused.values.append
      (Adac.IR.Value'
         (kind                => Adac.IR.Boolean_Not_Value,
          value_type          => Adac.IR.Boolean_Type,
          integer_value       => 0,
          boolean_value       => False,
          source_local        => 0,
          boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
          operand_value       => Adac.IR.Value_ID (3),
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_boolean_reused_computed := valid_boolean_nested_binary;
    bad_boolean_reused_computed.values (5).right_operand_value :=
      Adac.IR.Value_ID (3);

    bad_boolean_binary_operator := valid_boolean_and;
    bad_boolean_binary_operator.values (3).boolean_operator :=
      Adac.IR.No_Boolean_Binary_Operator;
    bad_boolean_binary_type := valid_boolean_and;
    bad_boolean_binary_type.values (3).value_type :=
      Adac.IR.Signed_Integer_32_Type;
    bad_boolean_binary_left := valid_boolean_and;
    bad_boolean_binary_left.values (3).operand_value := Adac.IR.Value_ID (3);
    bad_boolean_binary_right := valid_boolean_and;
    bad_boolean_binary_right.values (3).right_operand_value :=
      Adac.IR.Value_ID (3);
    bad_boolean_binary_kind := valid_boolean_and;
    bad_boolean_binary_kind.values.replace_element
      (2,
       Adac.IR.Value'
         (kind                => Adac.IR.Integer_Constant_Value,
          value_type          => Adac.IR.Signed_Integer_32_Type,
          integer_value       => 1,
          boolean_value       => False,
          source_local        => 0,
          boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
          operand_value       => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
    bad_boolean_binary_payload := valid_boolean_and;
    bad_boolean_binary_payload.values (3).source_local := 1;

    bad_integer_type := valid_store;
    bad_integer_type.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Integer_Constant_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 1,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_boolean_type := valid_boolean_true;
    bad_boolean_type.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Constant_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 0,
          boolean_value => True,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_boolean_payload := valid_boolean_true;
    bad_boolean_payload.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Boolean_Constant_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 1,
          boolean_value => True,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_boolean_load_payload := valid_boolean_load;
    bad_boolean_load_payload.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Local_Load_Value,
          value_type    => Adac.IR.Boolean_Type,
          integer_value => 0,
          boolean_value => True,
          source_local  => 1,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_load_ref := valid_load;
    bad_load_ref.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Local_Load_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 0,
          boolean_value => False,
          source_local  => 3,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_load_payload := valid_load;
    bad_load_payload.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Local_Load_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 1,
          boolean_value => False,
          source_local  => 1,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_const_source := valid_store;
    bad_const_source.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Integer_Constant_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 1,
          boolean_value => False,
          source_local  => 1,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_local_ref := valid_store;
    bad_local_ref.instructions.replace_element
      (1,
       Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 2,
          value        => Adac.IR.Value_ID (1)));

    bad_value_ref := valid_store;
    bad_value_ref.instructions.replace_element
      (1,
       Adac.IR.Instruction'
         (kind         => Adac.IR.Store_Local_Instruction,
          target_local => 1,
          value        => Adac.IR.Value_ID (2)));

    bad_value_range := valid_store;
    bad_value_range.values.replace_element
      (1,
       Adac.IR.Value'
         (kind          => Adac.IR.Integer_Constant_Value,
          value_type    => Adac.IR.Signed_Integer_32_Type,
          integer_value => 2_147_483_648,
          boolean_value => False,
          source_local  => 0,
          boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

    bad_simple.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    bad_simple.instructions.append
      (Adac.IR.Instruction'
         (kind         => Adac.IR.Null_Instruction,
          target_local => 1,
          value        => Adac.IR.INVALID_VALUE_ID));

    empty_name.instructions.append
      (Adac.IR.Instruction'(kind         => Adac.IR.Null_Instruction,
                            target_local => 0,
                            value        => Adac.IR.INVALID_VALUE_ID));

    empty_local_name.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    empty_local_name.locals.append
      (Adac.IR.Local_Declaration'
         (name       => Ada.Strings.Unbounded.Null_Unbounded_String,
          value_type => Adac.IR.Signed_Integer_32_Type));
    empty_local_name.instructions.append
      (Adac.IR.Instruction'(kind         => Adac.IR.Null_Instruction,
                            target_local => 0,
                            value        => Adac.IR.INVALID_VALUE_ID));

    empty_code.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");

    require
      (accepts_module (valid_module),
       "IR validator rejected a valid minimal module");
    require
      (accepts_module (valid_local),
       "IR validator rejected a valid local declaration");
    require
      (accepts_module (valid_store),
       "IR validator rejected a valid local integer store");
    require
      (accepts_module (valid_load),
       "IR validator rejected a valid direct local load");
    require
      (accepts_module (valid_boolean_true),
       "IR validator rejected a valid True Boolean store");
    require
      (accepts_module (valid_boolean_false),
       "IR validator rejected a valid False Boolean store");
    require
      (accepts_module (valid_boolean_load),
       "IR validator rejected a valid Boolean local load");
    require
      (accepts_module (valid_boolean_not) and then
       accepts_module (valid_boolean_nested_not),
       "IR validator rejected a valid Boolean not value graph");
    require
      (accepts_module (valid_boolean_and) and then
       accepts_module (valid_boolean_or) and then
       accepts_module (valid_boolean_xor) and then
       accepts_module (valid_boolean_equal) and then
       accepts_module (valid_boolean_not_equal) and then
       accepts_module (valid_boolean_less) and then
       accepts_module (valid_boolean_less_equal) and then
       accepts_module (valid_boolean_greater) and then
       accepts_module (valid_boolean_greater_equal) and then
       accepts_module (valid_boolean_nested_binary),
       "IR validator rejected a valid Boolean binary value graph");
    require
      (accepts_module (valid_boolean_and_then) and then
       accepts_module (valid_boolean_or_else),
       "IR validator rejected a valid Boolean short-circuit value");
    require
      (not accepts_module (bad_boolean_short_type),
       "IR validator accepted short circuit with integer type");
    require
      (not accepts_module (bad_boolean_short_left),
       "IR validator accepted non-earlier short-circuit left operand");
    require
      (not accepts_module (bad_boolean_short_right),
       "IR validator accepted non-earlier short-circuit right operand");
    require
      (not accepts_module (bad_boolean_short_kind),
       "IR validator accepted non-Boolean short-circuit operand");
    require
      (not accepts_module (bad_boolean_short_payload),
       "IR validator accepted eager operator payload on short circuit");
    require
      (not accepts_module (bad_boolean_short_reused),
       "IR validator accepted multiply-consumed short-circuit value");
    require
      (not accepts_module (bad_boolean_binary_operator),
       "IR validator accepted Boolean binary without operator");
    require
      (not accepts_module (bad_boolean_binary_type),
       "IR validator accepted Boolean binary with integer type");
    require
      (not accepts_module (bad_boolean_binary_left),
       "IR validator accepted non-earlier Boolean binary left operand");
    require
      (not accepts_module (bad_boolean_binary_right),
       "IR validator accepted non-earlier Boolean binary right operand");
    require
      (not accepts_module (bad_boolean_binary_kind),
       "IR validator accepted non-Boolean binary operand");
    require
      (not accepts_module (bad_boolean_reused_computed),
       "IR validator accepted a multiply-consumed Boolean operator value");
    require
      (not accepts_module (bad_boolean_binary_payload),
       "IR validator accepted Boolean binary with local payload");
    require
      (not accepts_module (bad_boolean_not_type),
       "IR validator accepted Boolean not with integer type");
    require
      (not accepts_module (bad_boolean_not_operand),
       "IR validator accepted a non-earlier Boolean not operand");
    require
      (not accepts_module (bad_boolean_not_kind),
       "IR validator accepted a non-load Boolean not operand");
    require
      (not accepts_module (bad_boolean_not_payload),
       "IR validator accepted Boolean not with local payload");
    require
      (not accepts_module (bad_integer_type),
       "IR validator accepted an integer constant tagged as Boolean");
    require
      (not accepts_module (bad_boolean_type),
       "IR validator accepted a Boolean constant tagged as integer");
    require
      (not accepts_module (bad_boolean_payload),
       "IR validator accepted a Boolean constant with integer payload");
    require
      (not accepts_module (bad_boolean_load_payload),
       "IR validator accepted a Boolean load with constant payload");
    require
      (not accepts_module (bad_load_ref),
       "IR validator accepted an invalid local-load reference");
    require
      (not accepts_module (bad_load_payload),
       "IR validator accepted a local load with constant payload");
    require
      (not accepts_module (bad_const_source),
       "IR validator accepted a constant with local-load reference");
    require
      (not accepts_module (bad_local_ref),
       "IR validator accepted an invalid store local reference");
    require
      (not accepts_module (bad_value_ref),
       "IR validator accepted an invalid store value reference");
    require
      (not accepts_module (bad_value_range),
       "IR validator accepted an out-of-range i32 constant");
    require
      (not accepts_module (bad_simple),
       "IR validator accepted store operands on a null instruction");
    require
      (not accepts_module (empty_name),
       "IR validator accepted an empty entry name");
    require
      (not accepts_module (empty_local_name),
       "IR validator accepted an empty local name");
    require
      (not accepts_module (empty_code),
       "IR validator accepted an empty instruction list");
  end;
end Run_IR_Validation;
