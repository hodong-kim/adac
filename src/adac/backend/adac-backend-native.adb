-- ============================================================================
-- adac-backend-native.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Latin_1;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.IO_Exceptions;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with Adac.Build_Config;
with Adac.Support;

package body Adac.Backend.Native is

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

  function make_assembly (module : Adac.IR.Module) return String is
    content    : Unbounded.Unbounded_String
               := Unbounded.to_unbounded_string (ASSEMBLY_HEADER);
    terminated : Boolean := False;
  begin
    for instruction of module.instructions loop
      exit when terminated;

      case instruction.kind is
        when Adac.IR.Null_Instruction =>
          null;

        when Adac.IR.Return_Instruction =>
          Unbounded.append (content, RETURN_SEQUENCE);
          terminated := True;
      end case;
    end loop;

    if not terminated then
      Unbounded.append (content, RETURN_SEQUENCE);
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

  function emit
    (module      : Adac.IR.Module;
     output_path : String)
  return Boolean
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

    return True;
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
