-- ============================================================================
-- adac-compilation-diagnostics.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Source;

package Adac.Compilation.Diagnostics is

  procedure error
    (self    : in out Context;
     message : String);

  procedure error
    (self     : in out Context;
     position : Adac.Source.Position;
     message  : String);

  function has_error (self : Context) return Boolean;

  function error_count (self : Context) return Natural;

end Adac.Compilation.Diagnostics;
