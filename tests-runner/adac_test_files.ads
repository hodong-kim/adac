-- ============================================================================
-- adac_test_files.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Containers.Indefinite_Vectors;

package Adac_Test_Files is

  package Path_Sets is new Ada.Containers.Indefinite_Ordered_Sets
    (Element_Type => String);

  package String_Vectors is new Ada.Containers.Indefinite_Vectors
    (Index_Type   => Positive,
     Element_Type => String);

  function fixture_path
    (directory : String;
     name      : String)
  return String;

  function trim_ascii_whitespace (value : String) return String;

  function read_file (path : String) return String;

  procedure write_file
    (path  : String;
     value : String);

  function files_equal
    (left_path  : String;
     right_path : String)
  return Boolean;

  procedure remove_path (path : String);

  function has_backend_work_files
    (output_path : String;
     asm_path    : String)
  return Boolean;

  function discover_directories (root : String) return Path_Sets.Set;

  function shell_words (value : String) return String_Vectors.Vector;

end Adac_Test_Files;
