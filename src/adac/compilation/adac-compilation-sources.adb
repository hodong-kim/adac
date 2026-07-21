-- ============================================================================
-- adac-compilation-sources.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.Compilation.Sources is

  function register_file
    (self : in out Context;
     path : String)
  return Adac.Source.Source_File_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Source.register_file (self.source_registry, path);
  end register_file;

  function file_path
    (self    : Context;
     file_id : Adac.Source.Source_File_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.Source.file_path (self.source_registry, file_id);
  end file_path;

  function file_count (self : Context) return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Source.file_count (self.source_registry);
  end file_count;

  function position_image
    (self     : Context;
     pos      : Adac.Source.Position)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.Source.position_image (self.source_registry, pos);
  end position_image;

  procedure validate_span
    (self  : Context;
     value : Adac.Source.Span)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.Source.validate (self.source_registry, value);
  end validate_span;

end Adac.Compilation.Sources;
