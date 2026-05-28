-- ============================================================================
-- adac-diagnostics.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Source;

package Adac.Diagnostics is

  procedure reset;

  procedure error (message : String);

  procedure error (position : Adac.Source.Position;
                   message  : String);

  function has_error return Boolean;

  function error_count return Natural;

end Adac.Diagnostics;
