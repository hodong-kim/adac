-- ============================================================================
-- adac_test_files.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Ada.Characters.Latin_1;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;

package body Adac_Test_Files is

  use type Ada.Directories.File_Kind;
  use type Ada.Streams.Stream_Element_Array;
  use type Ada.Streams.Stream_Element_Offset;
  use type Ada.Streams.Stream_IO.Count;

  CONFIGURATION_FILE_LIMIT : constant Natural := 1_024 * 1_024;
  COMPARISON_BUFFER_BYTES : constant Ada.Streams.Stream_Element_Offset
                          := 8 * 1_024;
  APOSTROPHE : constant Character := Character'val (39);
  BACKSLASH : constant Character := Character'val (92);

  package Stream_IO renames Ada.Streams.Stream_IO;

  procedure close_after_failure (file : in out Stream_IO.File_Type) is
  begin
    if not Stream_IO.is_open (file) then
      return;
    end if;

    begin
      Stream_IO.close (file);
    exception
      when others =>
        null;
    end;
  end close_after_failure;

  function fixture_path
    (directory : String;
     name      : String)
  return String is
  begin
    return Ada.Directories.compose (directory, name);
  end fixture_path;

  function is_ascii_whitespace (value : Character) return Boolean is
  begin
    return value = ' ' or else
      value = Ada.Characters.Latin_1.HT or else
      value = Ada.Characters.Latin_1.LF or else
      value = Ada.Characters.Latin_1.VT or else
      value = Ada.Characters.Latin_1.FF or else
      value = Ada.Characters.Latin_1.CR;
  end is_ascii_whitespace;

  function trim_ascii_whitespace (value : String) return String is
    first : Integer := value'first;
    last  : Integer := value'last;
  begin
    while first <= value'last and then
          is_ascii_whitespace (value(first))
    loop
      first := first + 1;
    end loop;

    while last >= first and then is_ascii_whitespace (value(last)) loop
      last := last - 1;
    end loop;

    if first > last then
      return "";
    end if;

    return value(first .. last);
  end trim_ascii_whitespace;

  function read_file (path : String) return String is
    file : Stream_IO.File_Type;
  begin
    Stream_IO.open (file, Stream_IO.In_File, path);

    declare
      size : constant Stream_IO.Count := Stream_IO.size (file);
    begin
      if size > Stream_IO.Count (CONFIGURATION_FILE_LIMIT) then
        raise Program_Error with path & " exceeds the configured file limit";
      end if;

      if size = 0 then
        Stream_IO.close (file);
        return "";
      end if;

      declare
        length : constant Natural := Natural (size);
        bytes  : Ada.Streams.Stream_Element_Array
          (1 .. Ada.Streams.Stream_Element_Offset (length));
        last   : Ada.Streams.Stream_Element_Offset;
        result : String (1 .. length);
      begin
        Stream_IO.read (file, bytes, last);
        Stream_IO.close (file);

        if last /= bytes'last then
          raise Program_Error with "short read from " & path;
        end if;

        for i in result'range loop
          result(i) := Character'val
            (Ada.Streams.Stream_Element'pos
               (bytes(Ada.Streams.Stream_Element_Offset (i))));
        end loop;

        return result;
      end;
    end;
  exception
    when others =>
      close_after_failure (file);
      raise;
  end read_file;

  procedure write_file
    (path  : String;
     value : String)
  is
    file : Stream_IO.File_Type;
  begin
    Stream_IO.create (file, Stream_IO.Out_File, path);

    if value'length > 0 then
      declare
        bytes : Ada.Streams.Stream_Element_Array
          (1 .. Ada.Streams.Stream_Element_Offset (value'length));
      begin
        for i in value'range loop
          bytes
            (Ada.Streams.Stream_Element_Offset
               (i - value'first + 1)) :=
            Ada.Streams.Stream_Element (Character'pos (value(i)));
        end loop;

        Stream_IO.write (file, bytes);
      end;
    end if;

    Stream_IO.close (file);
  exception
    when others =>
      close_after_failure (file);
      raise;
  end write_file;

  function files_equal
    (left_path  : String;
     right_path : String)
  return Boolean
  is
    left_file  : Stream_IO.File_Type;
    right_file : Stream_IO.File_Type;
  begin
    Stream_IO.open (left_file, Stream_IO.In_File, left_path);
    Stream_IO.open (right_file, Stream_IO.In_File, right_path);

    if Stream_IO.size (left_file) /= Stream_IO.size (right_file) then
      Stream_IO.close (left_file);
      Stream_IO.close (right_file);
      return False;
    end if;

    declare
      remaining : Stream_IO.Count := Stream_IO.size (left_file);
    begin
      while remaining > 0 loop
        declare
          chunk_size : constant Ada.Streams.Stream_Element_Offset :=
            (if remaining > Stream_IO.Count (COMPARISON_BUFFER_BYTES)
             then COMPARISON_BUFFER_BYTES
             else Ada.Streams.Stream_Element_Offset (remaining));
          left_bytes : Ada.Streams.Stream_Element_Array (1 .. chunk_size);
          right_bytes : Ada.Streams.Stream_Element_Array (1 .. chunk_size);
          left_last  : Ada.Streams.Stream_Element_Offset;
          right_last : Ada.Streams.Stream_Element_Offset;
        begin
          Stream_IO.read (left_file, left_bytes, left_last);
          Stream_IO.read (right_file, right_bytes, right_last);

          if left_last /= left_bytes'last or else
             right_last /= right_bytes'last or else
             left_bytes /= right_bytes
          then
            Stream_IO.close (left_file);
            Stream_IO.close (right_file);
            return False;
          end if;

          remaining := remaining - Stream_IO.Count (chunk_size);
        end;
      end loop;
    end;

    Stream_IO.close (left_file);
    Stream_IO.close (right_file);
    return True;
  exception
    when others =>
      close_after_failure (left_file);
      close_after_failure (right_file);
      raise;
  end files_equal;

  procedure remove_path (path : String) is
  begin
    if not Ada.Directories.exists (path) then
      return;
    end if;

    if Ada.Directories.kind (path) = Ada.Directories.Directory then
      Ada.Directories.delete_tree (path);
    else
      Ada.Directories.delete_file (path);
    end if;
  end remove_path;

  function has_matching_entry
    (directory : String;
     pattern   : String)
  return Boolean
  is
    search  : Ada.Directories.Search_Type;
    started : Boolean := False;
  begin
    Ada.Directories.start_search
      (search,
       directory,
       pattern,
       [others => True]);
    started := True;

    if Ada.Directories.more_entries (search) then
      Ada.Directories.end_search (search);
      started := False;
      return True;
    end if;

    Ada.Directories.end_search (search);
    started := False;
    return False;
  exception
    when others =>
      if started then
        Ada.Directories.end_search (search);
      end if;

      raise;
  end has_matching_entry;

  function has_backend_work_files
    (output_path : String;
     asm_path    : String)
  return Boolean
  is
    directory : constant String := Ada.Directories.containing_directory
      (output_path);
    output_name : constant String := Ada.Directories.simple_name (output_path);
    asm_name : constant String := Ada.Directories.simple_name (asm_path);
  begin
    return has_matching_entry (directory, asm_name & ".tmp.*") or else
      has_matching_entry (directory, asm_name & ".backup.*") or else
      has_matching_entry (directory, output_name & ".tmp.*") or else
      has_matching_entry (directory, output_name & ".backup.*");
  end has_backend_work_files;

  function discover_directories (root : String) return Path_Sets.Set is
    result          : Path_Sets.Set;
    search          : Ada.Directories.Search_Type;
    directory_entry : Ada.Directories.Directory_Entry_Type;
    started         : Boolean := False;
  begin
    Ada.Directories.start_search
      (search,
       root,
       "*",
       [Ada.Directories.Ordinary_File => False,
        Ada.Directories.Directory     => True,
        Ada.Directories.Special_File  => False]);
    started := True;

    while Ada.Directories.more_entries (search) loop
      Ada.Directories.get_next_entry (search, directory_entry);

      declare
        name : constant String :=
          Ada.Directories.simple_name (directory_entry);
      begin
        if name /= "." and then name /= ".." and then
           name(name'first) /= '.'
        then
          result.include
            (Ada.Directories.full_name (directory_entry));
        end if;
      end;
    end loop;

    Ada.Directories.end_search (search);
    started := False;
    return result;
  exception
    when others =>
      if started then
        Ada.Directories.end_search (search);
      end if;

      raise;
  end discover_directories;

  function shell_words (value : String) return String_Vectors.Vector is
    type Parser_State is (Unquoted, Single_Quoted, Double_Quoted);

    result        : String_Vectors.Vector;
    current       : Ada.Strings.Unbounded.Unbounded_String;
    state         : Parser_State := Unquoted;
    token_started : Boolean := False;
    index         : Integer := value'first;

    procedure finish_token is
    begin
      if token_started then
        result.append (Ada.Strings.Unbounded.to_string (current));
        current := Ada.Strings.Unbounded.Null_Unbounded_String;
        token_started := False;
      end if;
    end finish_token;

    procedure append_character (item : Character) is
    begin
      Ada.Strings.Unbounded.append (current, item);
      token_started := True;
    end append_character;

  begin
    while index <= value'last loop
      case state is
        when Unquoted =>
          if is_ascii_whitespace (value(index)) then
            finish_token;
          elsif value(index) = APOSTROPHE then
            state := Single_Quoted;
            token_started := True;
          elsif value(index) = '"' then
            state := Double_Quoted;
            token_started := True;
          elsif value(index) = BACKSLASH then
            index := index + 1;

            if index > value'last then
              raise Program_Error with "trailing escape in arguments.txt";
            end if;

            if value(index) /= Ada.Characters.Latin_1.LF then
              append_character (value(index));
            end if;
          else
            append_character (value(index));
          end if;

        when Single_Quoted =>
          if value(index) = APOSTROPHE then
            state := Unquoted;
          else
            append_character (value(index));
          end if;

        when Double_Quoted =>
          if value(index) = '"' then
            state := Unquoted;
          elsif value(index) = BACKSLASH then
            index := index + 1;

            if index > value'last then
              raise Program_Error with "trailing escape in arguments.txt";
            end if;

            if value(index) = Ada.Characters.Latin_1.LF then
              null;
            elsif value(index) = '$' or else
                  value(index) = '`' or else
                  value(index) = '"' or else
                  value(index) = BACKSLASH
            then
              append_character (value(index));
            else
              append_character (BACKSLASH);
              append_character (value(index));
            end if;
          else
            append_character (value(index));
          end if;
      end case;

      index := index + 1;
    end loop;

    if state /= Unquoted then
      raise Program_Error with "unterminated quote in arguments.txt";
    end if;

    finish_token;
    return result;
  end shell_words;

end Adac_Test_Files;
