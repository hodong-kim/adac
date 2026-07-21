-- ============================================================================
-- adac-compilation-sources.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Source;

package Adac.Compilation.Sources is

  --! summary: Register a source path in this compilation context.
  function register_file
    (self : in out Context;
     path : String)
  return Adac.Source.Source_File_ID;

  --! summary: Return a registered path from this compilation context.
  --! contract: The identifier must belong to this context.
  function file_path
    (self    : Context;
     file_id : Adac.Source.Source_File_ID)
  return String;

  --! summary: Return the number of paths registered in this context.
  function file_count (self : Context) return Natural;

  --! summary: Render a source position through this context.
  --! contract: The position file ID must belong to this context.
  function position_image
    (self     : Context;
     pos      : Adac.Source.Position)
  return String;

end Adac.Compilation.Sources;
