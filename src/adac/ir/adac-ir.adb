-- ============================================================================
-- adac-ir.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.IR is

  package Natural_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Natural);

  SIGNED_INTEGER_32_LOWER_BOUND : constant Long_Long_Integer :=
    -2_147_483_648;
  SIGNED_INTEGER_32_UPPER_BOUND : constant Long_Long_Integer :=
    2_147_483_647;

  procedure validate (module_value : Module) is
    consumer_counts : Natural_Vectors.Vector;

    procedure note_computed_consumer (referenced_id : Value_ID) is
      referenced : constant Value :=
        module_value.values (Positive (referenced_id));
    begin
      if referenced.kind /= Boolean_Not_Value and then
         referenced.kind /= Boolean_Binary_Value and then
         referenced.kind /= Boolean_And_Then_Value and then
         referenced.kind /= Boolean_Or_Else_Value
      then
        return;
      end if;

      if consumer_counts (Positive (referenced_id)) /= 0 then
        raise Program_Error with
          "Adac.IR: computed Boolean value has multiple consumers";
      end if;
      consumer_counts.replace_element (Positive (referenced_id), 1);
    end note_computed_consumer;
  begin
    if Ada.Strings.Unbounded.length (module_value.entry_name) = 0 then
      raise Program_Error with "Adac.IR: module entry name is empty";
    end if;

    for index in 1 .. Natural (module_value.values.length) loop
      consumer_counts.append (0);
    end loop;

    for local of module_value.locals loop
      if Ada.Strings.Unbounded.length (local.name) = 0 then
        raise Program_Error with "Adac.IR: local name is empty";
      end if;
    end loop;

    for index in 1 .. Natural (module_value.values.length) loop
      declare
        item : constant Value := module_value.values (Positive (index));
      begin
        case item.kind is
          when Integer_Constant_Value =>
            if item.value_type /= Signed_Integer_32_Type then
              raise Program_Error with
                "Adac.IR: integer constant has a non-integer type";
            end if;
            if item.source_local /= 0 or else item.boolean_value or else
               item.boolean_operator /= No_Boolean_Binary_Operator or else
               item.operand_value /= INVALID_VALUE_ID or else
               item.right_operand_value /= INVALID_VALUE_ID
            then
              raise Program_Error with
                "Adac.IR: integer constant has unrelated payload";
            end if;
            if item.integer_value < SIGNED_INTEGER_32_LOWER_BOUND or else
               item.integer_value > SIGNED_INTEGER_32_UPPER_BOUND
            then
              raise Program_Error with
                "Adac.IR: integer constant is outside i32 range";
            end if;

          when Boolean_Constant_Value =>
            if item.value_type /= Boolean_Type then
              raise Program_Error with
                "Adac.IR: Boolean constant has a non-Boolean type";
            end if;
            if item.source_local /= 0 or else item.integer_value /= 0 or else
               item.boolean_operator /= No_Boolean_Binary_Operator or else
               item.operand_value /= INVALID_VALUE_ID or else
               item.right_operand_value /= INVALID_VALUE_ID
            then
              raise Program_Error with
                "Adac.IR: Boolean constant has unrelated payload";
            end if;

          when Local_Load_Value =>
            if item.source_local = 0 or else
               item.source_local > Natural (module_value.locals.length)
            then
              raise Program_Error with
                "Adac.IR: local-load reference is out of range";
            end if;

            if item.integer_value /= 0 or else item.boolean_value or else
               item.boolean_operator /= No_Boolean_Binary_Operator or else
               item.operand_value /= INVALID_VALUE_ID or else
               item.right_operand_value /= INVALID_VALUE_ID
            then
              raise Program_Error with
                "Adac.IR: local load has unrelated payload";
            end if;

            if item.value_type /=
               module_value.locals (Positive (item.source_local)).value_type
            then
              raise Program_Error with
                "Adac.IR: local-load type does not match source local";
            end if;

          when Boolean_Not_Value =>
            if item.value_type /= Boolean_Type then
              raise Program_Error with
                "Adac.IR: Boolean not has a non-Boolean type";
            end if;
            if item.integer_value /= 0 or else item.boolean_value or else
               item.source_local /= 0 or else
               item.boolean_operator /= No_Boolean_Binary_Operator or else
               item.right_operand_value /= INVALID_VALUE_ID
            then
              raise Program_Error with
                "Adac.IR: Boolean not has unrelated payload";
            end if;
            if item.operand_value = INVALID_VALUE_ID or else
               Natural (item.operand_value) >= index
            then
              raise Program_Error with
                "Adac.IR: Boolean not operand is not an earlier value";
            end if;
            declare
              operand : constant Value :=
                module_value.values (Positive (item.operand_value));
            begin
              if operand.value_type /= Boolean_Type then
                raise Program_Error with
                  "Adac.IR: Boolean not operand is not Boolean";
              end if;
              note_computed_consumer (item.operand_value);
            end;

          when Boolean_Binary_Value =>
            if item.value_type /= Boolean_Type then
              raise Program_Error with
                "Adac.IR: Boolean binary has a non-Boolean type";
            end if;
            if item.integer_value /= 0 or else item.boolean_value or else
               item.source_local /= 0 or else
               item.boolean_operator = No_Boolean_Binary_Operator
            then
              raise Program_Error with
                "Adac.IR: Boolean binary has invalid payload";
            end if;
            if item.operand_value = INVALID_VALUE_ID or else
               item.right_operand_value = INVALID_VALUE_ID or else
               Natural (item.operand_value) >= index or else
               Natural (item.right_operand_value) >= index
            then
              raise Program_Error with
                "Adac.IR: Boolean binary operand is not an earlier value";
            end if;
            declare
              left : constant Value :=
                module_value.values (Positive (item.operand_value));
              right : constant Value :=
                module_value.values (Positive (item.right_operand_value));
            begin
              if left.value_type /= Boolean_Type or else
                 right.value_type /= Boolean_Type
              then
                raise Program_Error with
                  "Adac.IR: Boolean binary operand is not Boolean";
              end if;
              note_computed_consumer (item.operand_value);
              note_computed_consumer (item.right_operand_value);
            end;

          when Boolean_And_Then_Value | Boolean_Or_Else_Value =>
            if item.value_type /= Boolean_Type then
              raise Program_Error with
                "Adac.IR: Boolean short circuit has a non-Boolean type";
            end if;
            if item.integer_value /= 0 or else item.boolean_value or else
               item.source_local /= 0 or else
               item.boolean_operator /= No_Boolean_Binary_Operator
            then
              raise Program_Error with
                "Adac.IR: Boolean short circuit has unrelated payload";
            end if;
            if item.operand_value = INVALID_VALUE_ID or else
               item.right_operand_value = INVALID_VALUE_ID or else
               Natural (item.operand_value) >= index or else
               Natural (item.right_operand_value) >= index
            then
              raise Program_Error with
                "Adac.IR: Boolean short-circuit operand is not an earlier value";
            end if;
            declare
              left : constant Value :=
                module_value.values (Positive (item.operand_value));
              right : constant Value :=
                module_value.values (Positive (item.right_operand_value));
            begin
              if left.value_type /= Boolean_Type or else
                 right.value_type /= Boolean_Type
              then
                raise Program_Error with
                  "Adac.IR: Boolean short-circuit operand is not Boolean";
              end if;
              note_computed_consumer (item.operand_value);
              note_computed_consumer (item.right_operand_value);
            end;
        end case;
      end;
    end loop;

    if module_value.instructions.is_empty then
      raise Program_Error with "Adac.IR: module instruction list is empty";
    end if;

    for instruction of module_value.instructions loop
      case instruction.kind is
        when Null_Instruction | Return_Instruction =>
          if instruction.target_local /= 0 or else
             instruction.value /= INVALID_VALUE_ID
          then
            raise Program_Error with
              "Adac.IR: simple instruction has store operands";
          end if;

        when Store_Local_Instruction =>
          if instruction.target_local = 0 or else
             instruction.target_local > Natural (module_value.locals.length)
          then
            raise Program_Error with
              "Adac.IR: store local reference is out of range";
          end if;

          if instruction.value = INVALID_VALUE_ID or else
             Natural (instruction.value) > Natural (module_value.values.length)
          then
            raise Program_Error with
              "Adac.IR: store value reference is out of range";
          end if;

          if module_value.values
               (Positive (instruction.value)).value_type /=
             module_value.locals
               (Positive (instruction.target_local)).value_type
          then
            raise Program_Error with
              "Adac.IR: store value type does not match target local";
          end if;

          note_computed_consumer (instruction.value);
      end case;
    end loop;
  end validate;

end Adac.IR;
