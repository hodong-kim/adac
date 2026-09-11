-- ============================================================================
-- adac-backend-native.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Latin_1;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.IO_Exceptions;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with Adac.Build_Config;
with Adac.Support;

package body Adac.Backend.Native is

  use type Adac.IR.Boolean_Binary_Operator_Kind;
  use type Adac.IR.Scalar_Type_Kind;
  use type Adac.IR.Value_Kind;

  package OS renames GNAT.OS_Lib;
  package Unbounded renames Ada.Strings.Unbounded;
  package Random_Naturals is new Ada.Numerics.Discrete_Random (Natural);

  use type OS.File_Descriptor;
  use type OS.String_Access;

  MAX_NAME_ATTEMPTS : constant := 16;

  procedure require_supported_target is
  begin
    if Adac.Build_Config.NATIVE_BACKEND_SUPPORTED then
      return;
    end if;

    raise Adac.Backend.Operational_Error with
      "native backend does not support compiler target: " &
      Adac.Build_Config.COMPILER_TARGET;
  end require_supported_target;

  ASSEMBLY_HEADER : constant String
                  := ".global main" & Ada.Characters.Latin_1.LF &
                     "main:" & Ada.Characters.Latin_1.LF;

  RETURN_SEQUENCE : constant String
                  := "  xorl %eax, %eax" & Ada.Characters.Latin_1.LF &
                     "  ret" & Ada.Characters.Latin_1.LF;

  FRAMED_RETURN_SEQUENCE : constant String
                         := "  leave" & Ada.Characters.Latin_1.LF &
                            RETURN_SEQUENCE;

  LOCAL_STORAGE_BYTES : constant Natural := 4;
  STACK_ALIGNMENT     : constant Natural := 16;
  MAX_FRAME_BYTES     : constant Natural := 2_147_483_632;

  function signed_image (value : Long_Long_Integer) return String is
    raw : constant String := Long_Long_Integer'image (value);
  begin
    if raw (raw'first) = ' ' then
      return raw (raw'first + 1 .. raw'last);
    end if;
    return raw;
  end signed_image;

  type Boolean_Evaluation_Action is
    (Visit_Boolean_Value,
     Save_Boolean_Left,
     Apply_Boolean_Not,
     Apply_Boolean_Binary,
     Branch_Boolean_Short_Circuit,
     Finish_Boolean_Short_Circuit);

  type Boolean_Evaluation_Frame is record
    action : Boolean_Evaluation_Action := Visit_Boolean_Value;
    value  : Adac.IR.Value_ID := Adac.IR.INVALID_VALUE_ID;
  end record;

  package Boolean_Evaluation_Frame_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Boolean_Evaluation_Frame);

  function frame_size (module : Adac.IR.Module) return Natural is
    local_count : constant Natural := Natural (module.locals.length);
    raw_size    : Natural;
  begin
    if local_count = 0 then
      return 0;
    end if;

    if local_count > MAX_FRAME_BYTES / LOCAL_STORAGE_BYTES then
      raise Adac.Backend.Operational_Error with
        "native stack frame exceeds supported x86-64 size";
    end if;

    raw_size := local_count * LOCAL_STORAGE_BYTES;
    return
      ((raw_size + STACK_ALIGNMENT - 1) / STACK_ALIGNMENT) *
      STACK_ALIGNMENT;
  end frame_size;

  function boolean_short_circuit_label
    (value : Adac.IR.Value_ID)
  return String is
  begin
    return ".Ladac_bool_short_" & Adac.Support.image (Natural (value));
  end boolean_short_circuit_label;

  procedure append_boolean_evaluation
    (content : in out Unbounded.Unbounded_String;
     module  : Adac.IR.Module;
     root    : Adac.IR.Value_ID)
  is
    frames : Boolean_Evaluation_Frame_Vectors.Vector;

    procedure append_boolean_binary_operation
      (operator_kind : Adac.IR.Boolean_Binary_Operator_Kind)
    is
      set_instruction : Unbounded.Unbounded_String;
    begin
      case operator_kind is
        when Adac.IR.And_Boolean_Binary_Operator =>
          Unbounded.append
            (content,
             "  andl %ecx, %eax" & Ada.Characters.Latin_1.LF);

        when Adac.IR.Or_Boolean_Binary_Operator =>
          Unbounded.append
            (content,
             "  orl %ecx, %eax" & Ada.Characters.Latin_1.LF);

        when Adac.IR.Xor_Boolean_Binary_Operator =>
          Unbounded.append
            (content,
             "  xorl %ecx, %eax" & Ada.Characters.Latin_1.LF);

        when Adac.IR.Equal_Boolean_Binary_Operator =>
          set_instruction := Unbounded.to_unbounded_string ("sete");

        when Adac.IR.Not_Equal_Boolean_Binary_Operator =>
          set_instruction := Unbounded.to_unbounded_string ("setne");

        when Adac.IR.Less_Boolean_Binary_Operator =>
          set_instruction := Unbounded.to_unbounded_string ("setb");

        when Adac.IR.Less_Equal_Boolean_Binary_Operator =>
          set_instruction := Unbounded.to_unbounded_string ("setbe");

        when Adac.IR.Greater_Boolean_Binary_Operator =>
          set_instruction := Unbounded.to_unbounded_string ("seta");

        when Adac.IR.Greater_Equal_Boolean_Binary_Operator =>
          set_instruction := Unbounded.to_unbounded_string ("setae");

        when Adac.IR.No_Boolean_Binary_Operator =>
          raise Program_Error with
            "Adac.Backend.Native: Boolean binary has no operator";
      end case;

      if Unbounded.length (set_instruction) /= 0 then
        Unbounded.append
          (content,
           "  cmpl %ecx, %eax" & Ada.Characters.Latin_1.LF &
           "  " & Unbounded.to_string (set_instruction) & " %al" &
           Ada.Characters.Latin_1.LF &
           "  movzbl %al, %eax" & Ada.Characters.Latin_1.LF);
      end if;
    end append_boolean_binary_operation;
  begin
    frames.append
      (Boolean_Evaluation_Frame'
         (action => Visit_Boolean_Value,
          value  => root));

    while not frames.is_empty loop
      declare
        frame : constant Boolean_Evaluation_Frame := frames.last_element;
      begin
        frames.delete_last;

        case frame.action is
          when Visit_Boolean_Value =>
            declare
              value : constant Adac.IR.Value :=
                module.values (Positive (frame.value));
            begin
              if value.value_type /= Adac.IR.Boolean_Type then
                raise Program_Error with
                  "Adac.Backend.Native: Boolean expression type is invalid";
              end if;

              case value.kind is
                when Adac.IR.Boolean_Constant_Value =>
                  Unbounded.append
                    (content,
                     "  movl $" &
                     (if value.boolean_value then "1" else "0") &
                     ", %eax" & Ada.Characters.Latin_1.LF);

                when Adac.IR.Local_Load_Value =>
                  declare
                    source_offset : constant Natural :=
                      value.source_local * LOCAL_STORAGE_BYTES;
                  begin
                    Unbounded.append
                      (content,
                       "  movl -" & Adac.Support.image (source_offset) &
                       "(%rbp), %eax" & Ada.Characters.Latin_1.LF);
                  end;

                when Adac.IR.Boolean_Not_Value =>
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Apply_Boolean_Not,
                        value  => frame.value));
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Visit_Boolean_Value,
                        value  => value.operand_value));

                when Adac.IR.Boolean_Binary_Value =>
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Apply_Boolean_Binary,
                        value  => frame.value));
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Visit_Boolean_Value,
                        value  => value.right_operand_value));
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Save_Boolean_Left,
                        value  => frame.value));
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Visit_Boolean_Value,
                        value  => value.operand_value));

                when Adac.IR.Boolean_And_Then_Value |
                     Adac.IR.Boolean_Or_Else_Value =>
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Finish_Boolean_Short_Circuit,
                        value  => frame.value));
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Visit_Boolean_Value,
                        value  => value.right_operand_value));
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Branch_Boolean_Short_Circuit,
                        value  => frame.value));
                  frames.append
                    (Boolean_Evaluation_Frame'
                       (action => Visit_Boolean_Value,
                        value  => value.operand_value));

                when Adac.IR.Integer_Constant_Value =>
                  raise Program_Error with
                    "Adac.Backend.Native: integer reached Boolean evaluation";
              end case;
            end;

          when Save_Boolean_Left =>
            Unbounded.append
              (content,
               "  pushq %rax" & Ada.Characters.Latin_1.LF);

          when Apply_Boolean_Not =>
            Unbounded.append
              (content,
               "  xorl $1, %eax" & Ada.Characters.Latin_1.LF);

          when Apply_Boolean_Binary =>
            declare
              value : constant Adac.IR.Value :=
                module.values (Positive (frame.value));
            begin
              if value.kind /= Adac.IR.Boolean_Binary_Value then
                raise Program_Error with
                  "Adac.Backend.Native: Boolean binary frame is invalid";
              end if;
              Unbounded.append
                (content,
                 "  movl %eax, %ecx" & Ada.Characters.Latin_1.LF &
                 "  popq %rax" & Ada.Characters.Latin_1.LF);
              append_boolean_binary_operation (value.boolean_operator);
            end;

          when Branch_Boolean_Short_Circuit =>
            declare
              value : constant Adac.IR.Value :=
                module.values (Positive (frame.value));
              jump : constant String :=
                (case value.kind is
                   when Adac.IR.Boolean_And_Then_Value => "je",
                   when Adac.IR.Boolean_Or_Else_Value  => "jne",
                   when others =>
                     raise Program_Error with
                       "Adac.Backend.Native: short-circuit frame is invalid");
            begin
              Unbounded.append
                (content,
                 "  cmpl $0, %eax" & Ada.Characters.Latin_1.LF &
                 "  " & jump & " " & boolean_short_circuit_label (frame.value) &
                 Ada.Characters.Latin_1.LF);
            end;

          when Finish_Boolean_Short_Circuit =>
            declare
              value : constant Adac.IR.Value :=
                module.values (Positive (frame.value));
            begin
              if value.kind /= Adac.IR.Boolean_And_Then_Value and then
                 value.kind /= Adac.IR.Boolean_Or_Else_Value
              then
                raise Program_Error with
                  "Adac.Backend.Native: short-circuit finish is invalid";
              end if;
              Unbounded.append
                (content,
                 boolean_short_circuit_label (frame.value) & ":" &
                 Ada.Characters.Latin_1.LF);
            end;
        end case;
      end;
    end loop;
  end append_boolean_evaluation;

  function make_assembly (module : Adac.IR.Module) return String is
    content    : Unbounded.Unbounded_String
               := Unbounded.to_unbounded_string (ASSEMBLY_HEADER);
    stack_size : constant Natural := frame_size (module);
    terminated : Boolean := False;
  begin
    if stack_size /= 0 then
      Unbounded.append
        (content,
         "  pushq %rbp" & Ada.Characters.Latin_1.LF &
         "  movq %rsp, %rbp" & Ada.Characters.Latin_1.LF &
         "  subq $" & Adac.Support.image (stack_size) &
         ", %rsp" & Ada.Characters.Latin_1.LF);
    end if;

    for instruction of module.instructions loop
      exit when terminated;

      case instruction.kind is
        when Adac.IR.Null_Instruction =>
          null;

        when Adac.IR.Return_Instruction =>
          Unbounded.append
            (content,
             (if stack_size = 0
              then RETURN_SEQUENCE
              else FRAMED_RETURN_SEQUENCE));
          terminated := True;

        when Adac.IR.Store_Local_Instruction =>
          declare
            stored_value : constant Adac.IR.Value :=
              module.values (Positive (instruction.value));
            offset : constant Natural :=
              instruction.target_local * LOCAL_STORAGE_BYTES;
          begin
            case stored_value.kind is
              when Adac.IR.Integer_Constant_Value =>
                if stored_value.value_type /=
                  Adac.IR.Signed_Integer_32_Type
                then
                  raise Program_Error with
                    "Adac.Backend.Native: integer constant has invalid type";
                end if;
                Unbounded.append
                  (content,
                   "  movl $" &
                   signed_image (stored_value.integer_value) &
                   ", -" &
                   Adac.Support.image (offset) &
                   "(%rbp)" & Ada.Characters.Latin_1.LF);

              when Adac.IR.Boolean_Constant_Value =>
                if stored_value.value_type /= Adac.IR.Boolean_Type then
                  raise Program_Error with
                    "Adac.Backend.Native: Boolean constant has invalid type";
                end if;
                Unbounded.append
                  (content,
                   "  movl $" &
                   (if stored_value.boolean_value then "1" else "0") &
                   ", -" &
                   Adac.Support.image (offset) &
                   "(%rbp)" & Ada.Characters.Latin_1.LF);

              when Adac.IR.Local_Load_Value =>
                declare
                  source_offset : constant Natural :=
                    stored_value.source_local * LOCAL_STORAGE_BYTES;
                begin
                  case stored_value.value_type is
                    when Adac.IR.Signed_Integer_32_Type |
                         Adac.IR.Boolean_Type =>
                      Unbounded.append
                        (content,
                         "  movl -" &
                         Adac.Support.image (source_offset) &
                         "(%rbp), %eax" & Ada.Characters.Latin_1.LF &
                         "  movl %eax, -" &
                         Adac.Support.image (offset) &
                         "(%rbp)" & Ada.Characters.Latin_1.LF);
                  end case;
                end;

              when Adac.IR.Boolean_Not_Value =>
                declare
                  operand : constant Adac.IR.Value :=
                    module.values (Positive (stored_value.operand_value));
                begin
                  if stored_value.value_type /= Adac.IR.Boolean_Type then
                    raise Program_Error with
                      "Adac.Backend.Native: Boolean not value is invalid";
                  end if;

                  if operand.kind = Adac.IR.Local_Load_Value and then
                     operand.value_type = Adac.IR.Boolean_Type
                  then
                    declare
                      source_offset : constant Natural :=
                        operand.source_local * LOCAL_STORAGE_BYTES;
                    begin
                      Unbounded.append
                        (content,
                         "  movl -" &
                         Adac.Support.image (source_offset) &
                         "(%rbp), %eax" & Ada.Characters.Latin_1.LF &
                         "  xorl $1, %eax" & Ada.Characters.Latin_1.LF);
                    end;
                  else
                    append_boolean_evaluation
                      (content, module, instruction.value);
                  end if;

                  Unbounded.append
                    (content,
                     "  movl %eax, -" &
                     Adac.Support.image (offset) &
                     "(%rbp)" & Ada.Characters.Latin_1.LF);
                end;

              when Adac.IR.Boolean_Binary_Value =>
                declare
                  left : constant Adac.IR.Value :=
                    module.values (Positive (stored_value.operand_value));
                  right : constant Adac.IR.Value :=
                    module.values
                      (Positive (stored_value.right_operand_value));
                begin
                  if stored_value.value_type /= Adac.IR.Boolean_Type then
                    raise Program_Error with
                      "Adac.Backend.Native: Boolean binary value is invalid";
                  end if;

                  if left.kind = Adac.IR.Local_Load_Value and then
                     left.value_type = Adac.IR.Boolean_Type and then
                     right.kind = Adac.IR.Local_Load_Value and then
                     right.value_type = Adac.IR.Boolean_Type
                  then
                    declare
                      left_offset : constant Natural :=
                        left.source_local * LOCAL_STORAGE_BYTES;
                      right_offset : constant Natural :=
                        right.source_local * LOCAL_STORAGE_BYTES;
                    begin
                      case stored_value.boolean_operator is
                        when Adac.IR.And_Boolean_Binary_Operator |
                             Adac.IR.Or_Boolean_Binary_Operator |
                             Adac.IR.Xor_Boolean_Binary_Operator =>
                          declare
                            operation : constant String :=
                              (case stored_value.boolean_operator is
                                 when Adac.IR.And_Boolean_Binary_Operator =>
                                   "andl",
                                 when Adac.IR.Or_Boolean_Binary_Operator =>
                                   "orl",
                                 when Adac.IR.Xor_Boolean_Binary_Operator =>
                                   "xorl",
                                 when others =>
                                   raise Program_Error);
                          begin
                            Unbounded.append
                              (content,
                               "  movl -" &
                               Adac.Support.image (left_offset) &
                               "(%rbp), %eax" & Ada.Characters.Latin_1.LF &
                               "  " & operation & " -" &
                               Adac.Support.image (right_offset) &
                               "(%rbp), %eax" & Ada.Characters.Latin_1.LF);
                          end;

                        when Adac.IR.Equal_Boolean_Binary_Operator |
                             Adac.IR.Not_Equal_Boolean_Binary_Operator |
                             Adac.IR.Less_Boolean_Binary_Operator |
                             Adac.IR.Less_Equal_Boolean_Binary_Operator |
                             Adac.IR.Greater_Boolean_Binary_Operator |
                             Adac.IR.Greater_Equal_Boolean_Binary_Operator =>
                          declare
                            set_instruction : constant String :=
                              (case stored_value.boolean_operator is
                                 when Adac.IR.Equal_Boolean_Binary_Operator =>
                                   "sete",
                                 when Adac.IR.
                                        Not_Equal_Boolean_Binary_Operator =>
                                   "setne",
                                 when Adac.IR.Less_Boolean_Binary_Operator =>
                                   "setb",
                                 when Adac.IR.
                                        Less_Equal_Boolean_Binary_Operator =>
                                   "setbe",
                                 when Adac.IR.Greater_Boolean_Binary_Operator =>
                                   "seta",
                                 when Adac.IR.
                                        Greater_Equal_Boolean_Binary_Operator =>
                                   "setae",
                                 when others =>
                                   raise Program_Error);
                          begin
                            Unbounded.append
                              (content,
                               "  movl -" &
                               Adac.Support.image (left_offset) &
                               "(%rbp), %eax" & Ada.Characters.Latin_1.LF &
                               "  cmpl -" &
                               Adac.Support.image (right_offset) &
                               "(%rbp), %eax" & Ada.Characters.Latin_1.LF &
                               "  " & set_instruction & " %al" &
                               Ada.Characters.Latin_1.LF &
                               "  movzbl %al, %eax" &
                               Ada.Characters.Latin_1.LF);
                          end;

                        when Adac.IR.No_Boolean_Binary_Operator =>
                          raise Program_Error with
                            "Adac.Backend.Native: Boolean binary has no " &
                            "operator";
                      end case;
                    end;
                  else
                    append_boolean_evaluation
                      (content, module, instruction.value);
                  end if;

                  Unbounded.append
                    (content,
                     "  movl %eax, -" & Adac.Support.image (offset) &
                     "(%rbp)" & Ada.Characters.Latin_1.LF);
                end;

              when Adac.IR.Boolean_And_Then_Value |
                   Adac.IR.Boolean_Or_Else_Value =>
                if stored_value.value_type /= Adac.IR.Boolean_Type then
                  raise Program_Error with
                    "Adac.Backend.Native: Boolean short circuit is invalid";
                end if;
                append_boolean_evaluation
                  (content, module, instruction.value);
                Unbounded.append
                  (content,
                   "  movl %eax, -" & Adac.Support.image (offset) &
                   "(%rbp)" & Ada.Characters.Latin_1.LF);
            end case;
          end;
      end case;
    end loop;

    if not terminated then
      Unbounded.append
        (content,
         (if stack_size = 0
          then RETURN_SEQUENCE
          else FRAMED_RETURN_SEQUENCE));
    end if;

    return Unbounded.to_string (content);
  end make_assembly;

  function random_suffix
    (generator : in out Random_Naturals.Generator)
  return String
  is
    first  : constant Natural := Random_Naturals.random (generator);
    second : constant Natural := Random_Naturals.random (generator);
  begin
    return Adac.Support.image (first) & "." &
      Adac.Support.image (second);
  end random_suffix;

  procedure create_unique_file
    (prefix    : String;
     suffix    : String;
     generator : in out Random_Naturals.Generator;
     file      : out OS.File_Descriptor;
     path      : out Unbounded.Unbounded_String)
  is
  begin
    file := OS.Invalid_FD;
    path := Unbounded.Null_Unbounded_String;

    for attempt in 1 .. MAX_NAME_ATTEMPTS loop
      declare
        candidate : constant String
                  := prefix &
                     random_suffix (generator) &
                     "." &
                     Adac.Support.image (attempt) &
                     suffix;
      begin
        path := Unbounded.to_unbounded_string (candidate);
        file := OS.Create_New_File (candidate, OS.Text);

        if file /= OS.Invalid_FD then
          return;
        end if;

        path := Unbounded.Null_Unbounded_String;
      end;
    end loop;

    raise Ada.IO_Exceptions.Use_Error with
      "unable to create a unique temporary output file";
  end create_unique_file;

  procedure write_all
    (file    : OS.File_Descriptor;
     content : String)
  is
    offset : Natural := 0;
  begin
    while offset < content'length loop
      declare
        written : constant Integer :=
          OS.Write
            (file,
             content(content'first + offset)'address,
             content'length - offset);
      begin
        if written <= 0 then
          raise Ada.IO_Exceptions.Device_Error with
            "unable to write temporary output file";
        end if;

        offset := offset + Natural(written);
      end;
    end loop;
  end write_all;

  procedure close_checked (file : in out OS.File_Descriptor) is
    success : Boolean;
  begin
    if file = OS.Invalid_FD then
      return;
    end if;

    OS.Close (file, success);
    file := OS.Invalid_FD;

    if not success then
      raise Ada.IO_Exceptions.Device_Error with
        "unable to close temporary output file";
    end if;
  end close_checked;

  procedure discard_temp
    (file : in out OS.File_Descriptor;
     path : Unbounded.Unbounded_String)
  is
    ignored : Boolean;
  begin
    if file /= OS.Invalid_FD then
      OS.Close (file);
      file := OS.Invalid_FD;
    end if;

    if Unbounded.length (path) /= 0 then
      OS.Delete_File (Unbounded.to_string (path), ignored);
    end if;
  end discard_temp;

  procedure remove_file (path : String) is
    ignored : Boolean;
  begin
    OS.Delete_File (path, ignored);
  end remove_file;

  procedure free_arguments (arguments : in out OS.Argument_List) is
  begin
    for index in arguments'Range loop
      OS.Free (arguments(index));
    end loop;
  end free_arguments;

  function native_compiler_name return String is
  begin
    if Ada.Environment_Variables.exists ("ADAC_CC") then
      return Ada.Environment_Variables.value ("ADAC_CC");
    end if;

    return "cc";
  end native_compiler_name;

  procedure link_executable
    (assembly_path   : String;
     executable_path : String;
     output_path     : String)
  is
    compiler_name : constant String := native_compiler_name;
    compiler_path : OS.String_Access := null;
  begin
    if compiler_name'length = 0 then
      raise Adac.Backend.Operational_Error with
        "ADAC_CC names an empty native toolchain command";
    end if;

    compiler_path := OS.Locate_Exec_On_Path (compiler_name);

    if compiler_path = null then
      raise Adac.Backend.Operational_Error with
        "native toolchain executable not found: " & compiler_name;
    end if;

    declare
      arguments : OS.Argument_List (1 .. 3)
                := [new String'("-o"),
                    new String'(executable_path),
                    new String'(assembly_path)];
      return_code : Integer;
    begin
      OS.Normalize_Arguments (arguments);
      return_code := OS.Spawn (compiler_path.all, arguments);

      if return_code /= 0 then
        raise Adac.Backend.Operational_Error with
          "native toolchain failed while linking " &
          output_path &
          " (exit status " &
          Adac.Support.image (return_code) &
          ")";
      end if;

      free_arguments (arguments);
    exception
      when others =>
        free_arguments (arguments);
        raise;
    end;

    OS.Free (compiler_path);
  exception
    when others =>
      OS.Free (compiler_path);
      raise;
  end link_executable;

  procedure publish_temp_file
    (temp_path  : String;
     final_path : String;
     generator  : in out Random_Naturals.Generator)
  is
    backup_path : Unbounded.Unbounded_String;
    moved_old   : Boolean := False;
    published   : Boolean;
    restored    : Boolean;
  begin
    OS.Rename_File (temp_path, final_path, published);

    if published then
      return;
    end if;

    if not OS.Is_Regular_File (final_path) then
      raise Ada.IO_Exceptions.Use_Error with
        "unable to publish backend output";
    end if;

    -- Windows rename cannot replace an existing target. Preserve the old
    -- output while publishing the new file, and restore it if publishing fails.
    for attempt in 1 .. MAX_NAME_ATTEMPTS loop
      declare
        candidate : constant String
                  := final_path &
                     ".backup." &
                     random_suffix (generator) &
                     "." &
                     Adac.Support.image (attempt);
      begin
        if not Ada.Directories.exists (candidate) then
          backup_path := Unbounded.to_unbounded_string (candidate);
          OS.Rename_File (final_path, candidate, moved_old);
          exit when moved_old;
          backup_path := Unbounded.Null_Unbounded_String;
        end if;
      end;
    end loop;

    if not moved_old then
      raise Ada.IO_Exceptions.Use_Error with
        "unable to preserve the previous backend output";
    end if;

    OS.Rename_File (temp_path, final_path, published);

    if published then
      remove_file (Unbounded.to_string (backup_path));
      return;
    end if;

    OS.Rename_File
      (Unbounded.to_string (backup_path), final_path, restored);

    if not restored then
      raise Ada.IO_Exceptions.Device_Error with
        "unable to publish backend output or restore the previous output";
    end if;

    raise Ada.IO_Exceptions.Use_Error with
      "unable to publish backend output";
  exception
    when others =>
      begin
        if Unbounded.length (backup_path) /= 0 and then
           not OS.Is_Regular_File (final_path)
        then
          OS.Rename_File
            (Unbounded.to_string (backup_path), final_path, restored);
        end if;
      exception
        when others =>
          null;
      end;

      raise;
  end publish_temp_file;

  procedure emit
    (module      : Adac.IR.Module;
     output_path : String)
  is
    assembly             : constant String := make_assembly (module);
    assembly_path        : constant String := output_path & ".s";
    assembly_file        : OS.File_Descriptor := OS.Invalid_FD;
    assembly_temp_path   : Unbounded.Unbounded_String;
    executable_file      : OS.File_Descriptor := OS.Invalid_FD;
    executable_temp_path : Unbounded.Unbounded_String;
    generator            : Random_Naturals.Generator;
  begin
    require_supported_target;

    Random_Naturals.reset (generator);

    create_unique_file
      (assembly_path & ".tmp.",
       "",
       generator,
       assembly_file,
       assembly_temp_path);

    write_all (assembly_file, assembly);
    close_checked (assembly_file);

    publish_temp_file
      (Unbounded.to_string (assembly_temp_path),
       assembly_path,
       generator);

    create_unique_file
      (output_path & ".tmp.",
       ".exe",
       generator,
       executable_file,
       executable_temp_path);
    close_checked (executable_file);

    link_executable
      (assembly_path,
       Unbounded.to_string (executable_temp_path),
       output_path);

    publish_temp_file
      (Unbounded.to_string (executable_temp_path),
       output_path,
       generator);

  exception
    when others =>
      begin
        discard_temp (assembly_file, assembly_temp_path);
        discard_temp (executable_file, executable_temp_path);
      exception
        when others =>
          null;
      end;

      raise;
  end emit;

end Adac.Backend.Native;
