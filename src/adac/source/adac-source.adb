-- ============================================================================
-- adac-source.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers;

with Adac.Support;

package body Adac.Source is

  use type Ada.Containers.Count_Type;

  function create return Registry is
  begin
    return result : Registry do
      null;
    end return;
  end create;

  function register_file
    (self : in out Registry;
     path : String)
  return Source_File_ID is
    cursor  : constant Path_Maps.Cursor := self.file_ids.find (path);
    file_id : Source_File_ID;
  begin
    if Path_Maps.has_element (cursor) then
      return Path_Maps.element (cursor);
    end if;

    if self.files.length >= Ada.Containers.Count_Type(Positive'Last) then
      raise Storage_Error with "source file registry capacity exhausted";
    end if;

    file_id :=
      (owner => self.marker'Unchecked_Access,
       index => Natural(self.files.length) + 1);

    self.files.append
      (Ada.Strings.Unbounded.to_unbounded_string (path));

    begin
      self.file_ids.insert (path, file_id);
    exception
      when others =>
        self.files.delete_last;
        raise;
    end;

    return file_id;
  end register_file;

  function file_path
    (self    : Registry;
     file_id : Source_File_ID)
  return String is
  begin
    if file_id.owner = null then
      raise Program_Error with "invalid source file identifier";
    end if;

    if file_id.owner /= self.marker'Unchecked_Access then
      raise Program_Error with
        "source file identifier belongs to another registry";
    end if;

    if file_id.index = 0 or else file_id.index > Natural(self.files.length) then
      raise Program_Error with "source file identifier is out of range";
    end if;

    return Ada.Strings.Unbounded.to_string
      (self.files(Positive(file_id.index)));
  end file_path;

  function file_count (self : Registry) return Natural is
  begin
    return Natural(self.files.length);
  end file_count;

  function make_position
    (file_id : Source_File_ID;
     line    : Positive;
     column  : Positive)
  return Position is
  begin
    return (file_id => file_id,
            line    => line,
            column  => column);
  end make_position;

  function position_image
    (self     : Registry;
     pos      : Position)
  return String is
  begin
    return file_path (self, pos.file_id) &
           ":" &
           Adac.Support.image (pos.line) &
           ":" &
           Adac.Support.image (pos.column);
  end position_image;

end Adac.Source;
