-- ============================================================================
-- adac-ir-builder.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.Compilation.Semantics;
with Adac.Compilation.Symbols;
with Adac.Compilation.Types;
with Adac.Types;

package body Adac.IR.Builder is

  use type Adac.Semantics.Entity_Kind;
  use type Adac.Types.Type_Kind;

  function lower_scalar_type
    (context       : Adac.Compilation.Context;
     semantic_type : Adac.Types.Type_ID)
  return Adac.IR.Scalar_Type_Kind is
  begin
    case Adac.Compilation.Types.kind_of (context, semantic_type) is
      when Adac.Types.Signed_Integer_Type =>
        return Adac.IR.Signed_Integer_32_Type;

      when Adac.Types.Universal_Integer_Type |
           Adac.Types.Root_Integer_Type |
           Adac.Types.Universal_Real_Type |
           Adac.Types.Root_Real_Type =>
        raise Program_Error with
          "Adac.IR.Builder: compile-time scalar has no runtime scalar type";

      when Adac.Types.Boolean_Type =>
        return Adac.IR.Boolean_Type;
    end case;
  end lower_scalar_type;

  function lower_boolean_binary_operator
    (operator_kind : Adac.Semantics.Boolean_Binary_Operator_Kind)
  return Adac.IR.Boolean_Binary_Operator_Kind is
  begin
    case operator_kind is
      when Adac.Semantics.No_Boolean_Binary_Operator =>
        raise Program_Error with
          "Adac.IR.Builder: Boolean binary assignment has no operator";
      when Adac.Semantics.And_Boolean_Binary_Operator =>
        return Adac.IR.And_Boolean_Binary_Operator;
      when Adac.Semantics.Or_Boolean_Binary_Operator =>
        return Adac.IR.Or_Boolean_Binary_Operator;
      when Adac.Semantics.Xor_Boolean_Binary_Operator =>
        return Adac.IR.Xor_Boolean_Binary_Operator;
      when Adac.Semantics.Equal_Boolean_Binary_Operator =>
        return Adac.IR.Equal_Boolean_Binary_Operator;
      when Adac.Semantics.Not_Equal_Boolean_Binary_Operator =>
        return Adac.IR.Not_Equal_Boolean_Binary_Operator;
      when Adac.Semantics.Less_Boolean_Binary_Operator =>
        return Adac.IR.Less_Boolean_Binary_Operator;
      when Adac.Semantics.Less_Equal_Boolean_Binary_Operator =>
        return Adac.IR.Less_Equal_Boolean_Binary_Operator;
      when Adac.Semantics.Greater_Boolean_Binary_Operator =>
        return Adac.IR.Greater_Boolean_Binary_Operator;
      when Adac.Semantics.Greater_Equal_Boolean_Binary_Operator =>
        return Adac.IR.Greater_Equal_Boolean_Binary_Operator;
    end case;
  end lower_boolean_binary_operator;

  function build
    (context : Adac.Compilation.Context;
     entity  : Adac.Semantics.Entity_ID)
  return Adac.IR.Module is
    module : Adac.IR.Module;
  begin
    Adac.Compilation.Semantics.validate (context, entity);

    if Adac.Compilation.Semantics.kind_of (context, entity) /=
      Adac.Semantics.Procedure_Body_Entity
    then
      raise Program_Error with
        "Adac.IR.Builder: entry entity is not a procedure body";
    end if;

    module.entry_name := Ada.Strings.Unbounded.to_unbounded_string
      (Adac.Compilation.Symbols.spelling
         (context, Adac.Compilation.Semantics.symbol (context, entity)));

    for index in 1 .. Adac.Compilation.Semantics.procedure_local_count
      (context, entity)
    loop
      declare
        local_entity : constant Adac.Semantics.Entity_ID :=
          Adac.Compilation.Semantics.procedure_local_at
            (context, entity, index);
        local_type : constant Adac.Types.Type_ID :=
          Adac.Compilation.Semantics.object_type (context, local_entity);
      begin
        module.locals.append
          (Adac.IR.Local_Declaration'
             (name => Ada.Strings.Unbounded.to_unbounded_string
                (Adac.Compilation.Symbols.spelling
                   (context,
                    Adac.Compilation.Semantics.symbol
                      (context, local_entity))),
              value_type => lower_scalar_type (context, local_type)));
      end;
    end loop;

    for index in 1 .. Adac.Compilation.Semantics.procedure_local_count
      (context, entity)
    loop
      declare
        local_entity : constant Adac.Semantics.Entity_ID :=
          Adac.Compilation.Semantics.procedure_local_at
            (context, entity, index);
      begin
        if Adac.Compilation.Semantics.object_has_integer_initializer
          (context, local_entity)
        then
          declare
            local_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.object_type
                (context, local_entity);
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Integer_Constant_Value,
                  value_type    => lower_scalar_type (context, local_type),
                  integer_value =>
                    Adac.Compilation.Semantics.object_integer_initializer
                      (context, local_entity),
                  boolean_value => False,
                  source_local  => 0,
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local => index,
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;
        elsif Adac.Compilation.Semantics.object_has_boolean_initializer
          (context, local_entity)
        then
          declare
            local_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.object_type
                (context, local_entity);
            initializer : constant Adac.Types.Boolean_Value :=
              Adac.Compilation.Semantics.object_boolean_initializer
                (context, local_entity);
            boolean_value : constant Boolean :=
              (case initializer is
                 when Adac.Types.False_Boolean_Value => False,
                 when Adac.Types.True_Boolean_Value  => True);
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Boolean_Constant_Value,
                  value_type    => lower_scalar_type (context, local_type),
                  integer_value => 0,
                  boolean_value => boolean_value,
                  source_local  => 0,
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local => index,
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;
        end if;
      end;
    end loop;

    for index in 1 .. Adac.Compilation.Semantics.procedure_statement_count
      (context, entity)
    loop
      case Adac.Compilation.Semantics.procedure_statement_kind_at
        (context, entity, index)
      is
        when Adac.Semantics.Null_Procedure_Statement =>
          module.instructions.append
            (Adac.IR.Instruction'(kind         => Adac.IR.Null_Instruction,
                                  target_local => 0,
                                  value        => Adac.IR.INVALID_VALUE_ID));

        when Adac.Semantics.Return_Procedure_Statement =>
          module.instructions.append
            (Adac.IR.Instruction'(kind         => Adac.IR.Return_Instruction,
                                  target_local => 0,
                                  value        => Adac.IR.INVALID_VALUE_ID));

        when Adac.Semantics.Local_Integer_Static_Assignment_Statement =>
          declare
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Integer_Constant_Value,
                  value_type    => lower_scalar_type (context, semantic_type),
                  integer_value =>
                    Adac.Compilation.Semantics.assignment_integer_value
                      (context, entity, index),
                  boolean_value => False,
                  source_local  => 0,
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;

        when Adac.Semantics.Local_Boolean_Static_Assignment_Statement =>
          declare
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
            semantic_value : constant Adac.Types.Boolean_Value :=
              Adac.Compilation.Semantics.assignment_boolean_value
                (context, entity, index);
            boolean_value : constant Boolean :=
              (case semantic_value is
                 when Adac.Types.False_Boolean_Value => False,
                 when Adac.Types.True_Boolean_Value  => True);
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Boolean_Constant_Value,
                  value_type    => lower_scalar_type (context, semantic_type),
                  integer_value => 0,
                  boolean_value => boolean_value,
                  source_local  => 0,
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;

        when Adac.Semantics.Local_Boolean_Copy_Assignment_Statement =>
          declare
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Local_Load_Value,
                  value_type    => lower_scalar_type (context, semantic_type),
                  integer_value => 0,
                  boolean_value => False,
                  source_local  =>
                    Adac.Compilation.Semantics.assignment_source_local
                      (context, entity, index),
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;

        when Adac.Semantics.Local_Boolean_Not_Assignment_Statement =>
          declare
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
            load_value : Adac.IR.Value_ID;
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Local_Load_Value,
                  value_type    => lower_scalar_type (context, semantic_type),
                  integer_value => 0,
                  boolean_value => False,
                  source_local  =>
                    Adac.Compilation.Semantics.assignment_source_local
                      (context, entity, index),
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));
            load_value := Adac.IR.Value_ID (module.values.length);

            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Boolean_Not_Value,
                  value_type    => Adac.IR.Boolean_Type,
                  integer_value => 0,
                  boolean_value => False,
                  source_local  => 0,
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
                  operand_value => load_value,
                  right_operand_value => Adac.IR.INVALID_VALUE_ID));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;

        when Adac.Semantics.Local_Boolean_Binary_Assignment_Statement =>
          declare
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
            left_load : Adac.IR.Value_ID;
            right_load : Adac.IR.Value_ID;
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind                => Adac.IR.Local_Load_Value,
                  value_type          => lower_scalar_type
                    (context, semantic_type),
                  integer_value       => 0,
                  boolean_value       => False,
                  source_local        =>
                    Adac.Compilation.Semantics.assignment_source_local
                      (context, entity, index),
                  boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
                  operand_value       => Adac.IR.INVALID_VALUE_ID,
                  right_operand_value => Adac.IR.INVALID_VALUE_ID));
            left_load := Adac.IR.Value_ID (module.values.length);

            module.values.append
              (Adac.IR.Value'
                 (kind                => Adac.IR.Local_Load_Value,
                  value_type          => lower_scalar_type
                    (context, semantic_type),
                  integer_value       => 0,
                  boolean_value       => False,
                  source_local        => Adac.Compilation.Semantics
                    .assignment_right_source_local (context, entity, index),
                  boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
                  operand_value       => Adac.IR.INVALID_VALUE_ID,
                  right_operand_value => Adac.IR.INVALID_VALUE_ID));
            right_load := Adac.IR.Value_ID (module.values.length);

            module.values.append
              (Adac.IR.Value'
                 (kind                => Adac.IR.Boolean_Binary_Value,
                  value_type          => Adac.IR.Boolean_Type,
                  integer_value       => 0,
                  boolean_value       => False,
                  source_local        => 0,
                  boolean_operator    => lower_boolean_binary_operator
                    (Adac.Compilation.Semantics.assignment_boolean_operator
                       (context, entity, index)),
                  operand_value       => left_load,
                  right_operand_value => right_load));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;

        when Adac.Semantics.Local_Boolean_And_Then_Assignment_Statement |
             Adac.Semantics.Local_Boolean_Or_Else_Assignment_Statement =>
          declare
            statement_kind : constant Adac.Semantics.Procedure_Statement_Kind :=
              Adac.Compilation.Semantics.procedure_statement_kind_at
                (context, entity, index);
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
            left_load : Adac.IR.Value_ID;
            right_load : Adac.IR.Value_ID;
            short_kind : constant Adac.IR.Value_Kind :=
              (case statement_kind is
                 when Adac.Semantics
                        .Local_Boolean_And_Then_Assignment_Statement =>
                   Adac.IR.Boolean_And_Then_Value,
                 when Adac.Semantics
                        .Local_Boolean_Or_Else_Assignment_Statement =>
                   Adac.IR.Boolean_Or_Else_Value,
                 when others =>
                   raise Program_Error with
                     "Adac.IR.Builder: unexpected short-circuit statement");
          begin
            if lower_scalar_type (context, semantic_type) /= Adac.IR.Boolean_Type
            then
              raise Program_Error with
                "Adac.IR.Builder: Boolean short-circuit type did not lower to " &
                "Boolean";
            end if;

            module.values.append
              (Adac.IR.Value'
                 (kind                => Adac.IR.Local_Load_Value,
                  value_type          => Adac.IR.Boolean_Type,
                  integer_value       => 0,
                  boolean_value       => False,
                  source_local        =>
                    Adac.Compilation.Semantics.assignment_source_local
                      (context, entity, index),
                  boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
                  operand_value       => Adac.IR.INVALID_VALUE_ID,
                  right_operand_value => Adac.IR.INVALID_VALUE_ID));
            left_load := Adac.IR.Value_ID (module.values.length);

            module.values.append
              (Adac.IR.Value'
                 (kind                => Adac.IR.Local_Load_Value,
                  value_type          => Adac.IR.Boolean_Type,
                  integer_value       => 0,
                  boolean_value       => False,
                  source_local        => Adac.Compilation.Semantics
                    .assignment_right_source_local (context, entity, index),
                  boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
                  operand_value       => Adac.IR.INVALID_VALUE_ID,
                  right_operand_value => Adac.IR.INVALID_VALUE_ID));
            right_load := Adac.IR.Value_ID (module.values.length);

            module.values.append
              (Adac.IR.Value'
                 (kind                => short_kind,
                  value_type          => Adac.IR.Boolean_Type,
                  integer_value       => 0,
                  boolean_value       => False,
                  source_local        => 0,
                  boolean_operator    => Adac.IR.No_Boolean_Binary_Operator,
                  operand_value       => left_load,
                  right_operand_value => right_load));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;

        when Adac.Semantics.Local_Boolean_Expression_Assignment_Statement =>
          declare
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
            value_count : constant Natural :=
              Adac.Compilation.Semantics
                .assignment_boolean_expression_value_count
                  (context, entity, index);
            first_ir_value : constant Natural :=
              Natural (module.values.length) + 1;
          begin
            if lower_scalar_type (context, semantic_type) /= Adac.IR.Boolean_Type
            then
              raise Program_Error with
                "Adac.IR.Builder: Boolean expression type did not lower to " &
                "Boolean";
            end if;
            if value_count = 0 then
              raise Program_Error with
                "Adac.IR.Builder: Boolean expression has no values";
            end if;

            for value_index in 1 .. value_count loop
              case Adac.Compilation.Semantics
                .assignment_boolean_expression_value_kind
                  (context, entity, index, value_index)
              is
                when Adac.Semantics.Boolean_Expression_Constant_Value =>
                  declare
                    semantic_value : constant Adac.Types.Boolean_Value :=
                      Adac.Compilation.Semantics
                        .assignment_boolean_expression_known_value
                          (context, entity, index, value_index);
                  begin
                    module.values.append
                      (Adac.IR.Value'
                         (kind          => Adac.IR.Boolean_Constant_Value,
                          value_type    => Adac.IR.Boolean_Type,
                          integer_value => 0,
                          boolean_value =>
                            (case semantic_value is
                               when Adac.Types.False_Boolean_Value => False,
                               when Adac.Types.True_Boolean_Value  => True),
                          source_local  => 0,
                          boolean_operator =>
                            Adac.IR.No_Boolean_Binary_Operator,
                          operand_value => Adac.IR.INVALID_VALUE_ID,
                          right_operand_value => Adac.IR.INVALID_VALUE_ID));
                  end;

                when Adac.Semantics.Boolean_Expression_Local_Value =>
                  module.values.append
                    (Adac.IR.Value'
                       (kind          => Adac.IR.Local_Load_Value,
                        value_type    => Adac.IR.Boolean_Type,
                        integer_value => 0,
                        boolean_value => False,
                        source_local  =>
                          Adac.Compilation.Semantics
                            .assignment_boolean_expression_source_local
                              (context, entity, index, value_index),
                        boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
                        operand_value => Adac.IR.INVALID_VALUE_ID,
                        right_operand_value => Adac.IR.INVALID_VALUE_ID));

                when Adac.Semantics.Boolean_Expression_Not_Value =>
                  declare
                    operand_index : constant Positive :=
                      Adac.Compilation.Semantics
                        .assignment_boolean_expression_operand
                          (context, entity, index, value_index);
                  begin
                    module.values.append
                      (Adac.IR.Value'
                         (kind          => Adac.IR.Boolean_Not_Value,
                          value_type    => Adac.IR.Boolean_Type,
                          integer_value => 0,
                          boolean_value => False,
                          source_local  => 0,
                          boolean_operator =>
                            Adac.IR.No_Boolean_Binary_Operator,
                          operand_value =>
                            Adac.IR.Value_ID
                              (first_ir_value + operand_index - 1),
                          right_operand_value => Adac.IR.INVALID_VALUE_ID));
                  end;

                when Adac.Semantics.Boolean_Expression_Binary_Value =>
                  declare
                    left_index : constant Positive :=
                      Adac.Compilation.Semantics
                        .assignment_boolean_expression_operand
                          (context, entity, index, value_index);
                    right_index : constant Positive :=
                      Adac.Compilation.Semantics
                        .assignment_boolean_expression_right_operand
                          (context, entity, index, value_index);
                  begin
                    module.values.append
                      (Adac.IR.Value'
                         (kind                => Adac.IR.Boolean_Binary_Value,
                          value_type          => Adac.IR.Boolean_Type,
                          integer_value       => 0,
                          boolean_value       => False,
                          source_local        => 0,
                          boolean_operator    => lower_boolean_binary_operator
                            (Adac.Compilation.Semantics
                               .assignment_boolean_expression_operator
                                 (context, entity, index, value_index)),
                          operand_value       => Adac.IR.Value_ID
                            (first_ir_value + left_index - 1),
                          right_operand_value => Adac.IR.Value_ID
                            (first_ir_value + right_index - 1)));
                  end;
              end case;
            end loop;

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;

        when Adac.Semantics.Local_Integer_Copy_Assignment_Statement =>
          declare
            semantic_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.assignment_expected_type
                (context, entity, index);
          begin
            module.values.append
              (Adac.IR.Value'
                 (kind          => Adac.IR.Local_Load_Value,
                  value_type    => lower_scalar_type (context, semantic_type),
                  integer_value => 0,
                  boolean_value => False,
                  source_local  =>
                    Adac.Compilation.Semantics.assignment_source_local
                      (context, entity, index),
                  boolean_operator => Adac.IR.No_Boolean_Binary_Operator,
          operand_value => Adac.IR.INVALID_VALUE_ID,
          right_operand_value => Adac.IR.INVALID_VALUE_ID));

            module.instructions.append
              (Adac.IR.Instruction'
                 (kind         => Adac.IR.Store_Local_Instruction,
                  target_local =>
                    Adac.Compilation.Semantics.assignment_target_local
                      (context, entity, index),
                  value        => Adac.IR.Value_ID (module.values.length)));
          end;
      end case;
    end loop;

    Adac.IR.validate (module);
    return module;
  end build;

end Adac.IR.Builder;
