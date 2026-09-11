-- ============================================================================
-- adac_internal_tests-run_bootstrap_profile_frontend.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Environment_Variables;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

separate (Adac_Internal_Tests)
procedure Run_Bootstrap_Profile_Frontend is
  MAXIMUM_PROFILE_SOURCES : constant Positive := 10_000;
  MANIFEST_VARIABLE : constant String := "ADAC_BOOTSTRAP_PROFILE_FILE";
  file : Ada.Text_IO.File_Type;
  previous_path : Ada.Strings.Unbounded.Unbounded_String;
  has_previous  : Boolean := False;
  source_count  : Natural := 0;
begin
  require
    (Ada.Environment_Variables.exists (MANIFEST_VARIABLE),
     MANIFEST_VARIABLE & " is not configured");

  Ada.Text_IO.open
    (file,
     Ada.Text_IO.In_File,
     Ada.Environment_Variables.value (MANIFEST_VARIABLE));

  while not Ada.Text_IO.end_of_file (file) loop
    declare
      path : constant String := Ada.Text_IO.get_line (file);
    begin
      require (path'length > 0, "bootstrap profile contains an empty path");
      source_count := source_count + 1;
      require
        (source_count <= MAXIMUM_PROFILE_SOURCES,
         "bootstrap profile source count exceeds test bound");

      if has_previous then
        require
          (Ada.Strings.Unbounded.to_string (previous_path) < path,
           "bootstrap profile manifest is not sorted and unique");
      end if;
      previous_path := Ada.Strings.Unbounded.to_unbounded_string (path);
      has_previous := True;

      declare
        context : Adac.Compilation.Context := new_context;
        result  : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Succeeded,
           "bootstrap profile frontend rejected member: " & path);
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 0,
           "bootstrap profile successful parse recorded diagnostics: " & path);
        Adac.Compilation.Syntax.validate (context, result.root);
      end;
    end;
  end loop;

  Ada.Text_IO.close (file);
  require (source_count > 0, "bootstrap profile manifest is empty");
exception
  when others =>
    if Ada.Text_IO.is_open (file) then
      Ada.Text_IO.close (file);
    end if;
    raise;
end Run_Bootstrap_Profile_Frontend;
