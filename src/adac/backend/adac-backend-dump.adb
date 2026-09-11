-- ============================================================================
-- adac-backend-dump.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Adac.Backend.Dump is

  use type Adac.IR.Scalar_Type_Kind;
  use type Adac.IR.Value_Kind;

  function image (value : Long_Long_Integer) return String is
    raw : constant String := Long_Long_Integer'image (value);
  begin
    if raw (raw'first) = ' ' then
      return raw (raw'first + 1 .. raw'last);
    end if;
    return raw;
  end image;

  function image (value : Natural) return String is
    raw : constant String := Natural'image (value);
  begin
    return raw (raw'first + 1 .. raw'last);
  end image;

  function image (value : Adac.IR.Value_ID) return String is
    raw : constant String := Adac.IR.Value_ID'image (value);
  begin
    return raw (raw'first + 1 .. raw'last);
  end image;

  procedure emit (module : Adac.IR.Module) is
    entry_name : constant String :=
      Ada.Strings.Unbounded.to_string (module.entry_name);
  begin
    Ada.Text_IO.put_line ("adac: ir entry " & entry_name);

    for local of module.locals loop
      case local.value_type is
        when Adac.IR.Signed_Integer_32_Type =>
          Ada.Text_IO.put_line
            ("adac: ir local " &
             Ada.Strings.Unbounded.to_string (local.name) &
             " i32");

        when Adac.IR.Boolean_Type =>
          Ada.Text_IO.put_line
            ("adac: ir local " &
             Ada.Strings.Unbounded.to_string (local.name) &
             " bool");
      end case;
    end loop;

    declare
      index : Natural := 0;
    begin
      for item of module.values loop
        index := index + 1;
        case item.kind is
          when Adac.IR.Integer_Constant_Value =>
            if item.value_type /= Adac.IR.Signed_Integer_32_Type then
              raise Program_Error with
                "Adac.Backend.Dump: integer constant has invalid type";
            end if;
            Ada.Text_IO.put_line
              ("adac: ir value " &
               image (index) &
               " i32 " & image (item.integer_value));

          when Adac.IR.Boolean_Constant_Value =>
            if item.value_type /= Adac.IR.Boolean_Type then
              raise Program_Error with
                "Adac.Backend.Dump: Boolean constant has invalid type";
            end if;
            Ada.Text_IO.put_line
              ("adac: ir value " &
               image (index) &
               " bool " & (if item.boolean_value then "true" else "false"));

          when Adac.IR.Local_Load_Value =>
            case item.value_type is
              when Adac.IR.Signed_Integer_32_Type =>
                Ada.Text_IO.put_line
                  ("adac: ir value " &
                   image (index) &
                   " i32 local " & image (item.source_local));

              when Adac.IR.Boolean_Type =>
                Ada.Text_IO.put_line
                  ("adac: ir value " &
                   image (index) &
                   " bool local " & image (item.source_local));
            end case;

          when Adac.IR.Boolean_Not_Value =>
            if item.value_type /= Adac.IR.Boolean_Type then
              raise Program_Error with
                "Adac.Backend.Dump: Boolean not has invalid type";
            end if;
            Ada.Text_IO.put_line
              ("adac: ir value " &
               image (index) &
               " bool not value " & image (item.operand_value));

          when Adac.IR.Boolean_Binary_Value =>
            if item.value_type /= Adac.IR.Boolean_Type then
              raise Program_Error with
                "Adac.Backend.Dump: Boolean binary has invalid type";
            end if;
            declare
              operator_name : constant String :=
                (case item.boolean_operator is
                   when Adac.IR.And_Boolean_Binary_Operator => "and",
                   when Adac.IR.Or_Boolean_Binary_Operator  => "or",
                   when Adac.IR.Xor_Boolean_Binary_Operator => "xor",
                   when Adac.IR.Equal_Boolean_Binary_Operator => "=",
                   when Adac.IR.Not_Equal_Boolean_Binary_Operator => "/=",
                   when Adac.IR.Less_Boolean_Binary_Operator => "<",
                   when Adac.IR.Less_Equal_Boolean_Binary_Operator => "<=",
                   when Adac.IR.Greater_Boolean_Binary_Operator => ">",
                   when Adac.IR.Greater_Equal_Boolean_Binary_Operator => ">=",
                   when Adac.IR.No_Boolean_Binary_Operator =>
                     raise Program_Error with
                       "Adac.Backend.Dump: Boolean binary has no operator");
            begin
              Ada.Text_IO.put_line
                ("adac: ir value " &
                 image (index) &
                 " bool " & operator_name &
                 " values " & image (item.operand_value) &
                 " " & image (item.right_operand_value));
            end;

          when Adac.IR.Boolean_And_Then_Value | Adac.IR.Boolean_Or_Else_Value =>
            if item.value_type /= Adac.IR.Boolean_Type then
              raise Program_Error with
                "Adac.Backend.Dump: Boolean short circuit has invalid type";
            end if;
            Ada.Text_IO.put_line
              ("adac: ir value " &
               image (index) &
               " bool " &
               (if item.kind = Adac.IR.Boolean_And_Then_Value
                then "and then"
                else "or else") &
               " values " & image (item.operand_value) &
               " " & image (item.right_operand_value));
        end case;
      end loop;
    end;

    for instruction of module.instructions loop
      case instruction.kind is
        when Adac.IR.Null_Instruction =>
          Ada.Text_IO.put_line ("adac: ir null");

        when Adac.IR.Return_Instruction =>
          Ada.Text_IO.put_line ("adac: ir return");

        when Adac.IR.Store_Local_Instruction =>
          Ada.Text_IO.put_line
            ("adac: ir store local " &
             image (instruction.target_local) &
             " value " & image (instruction.value));
      end case;
    end loop;

  end emit;

end Adac.Backend.Dump;
