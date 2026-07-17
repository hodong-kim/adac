-- ============================================================================
-- adac-backend-native.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Latin_1;
with Ada.Directories;
with Ada.IO_Exceptions;
with Ada.Numerics.Discrete_Random;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with Adac.Support;

package body Adac.Backend.Native is

  package OS renames GNAT.OS_Lib;
  package Unbounded renames Ada.Strings.Unbounded;
  package Random_Naturals is new Ada.Numerics.Discrete_Random (Natural);

  use type OS.File_Descriptor;

  MAX_NAME_ATTEMPTS : constant := 16;

  ASSEMBLY : constant String
           := ".global main" & Ada.Characters.Latin_1.LF &
              "main:" & Ada.Characters.Latin_1.LF &
              "  xorl %eax, %eax" & Ada.Characters.Latin_1.LF &
              "  ret" & Ada.Characters.Latin_1.LF;

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
                     Adac.Support.image (attempt);
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
    pragma Unreferenced (module);

    final_path : constant String := output_path & ".s";
    file       : OS.File_Descriptor := OS.Invalid_FD;
    temp_path  : Unbounded.Unbounded_String;
    generator  : Random_Naturals.Generator;
  begin
    Random_Naturals.reset (generator);

    create_unique_file
      (final_path & ".tmp.", generator, file, temp_path);

    write_all (file, ASSEMBLY);
    close_checked (file);

    publish_temp_file
      (Unbounded.to_string (temp_path), final_path, generator);

    return True;
  exception
    when others =>
      begin
        discard_temp (file, temp_path);
      exception
        when others =>
          null;
      end;

      raise;
  end emit;

end Adac.Backend.Native;
