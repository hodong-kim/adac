-- ============================================================================
-- adac_assembly_patterns.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac_Assembly_Patterns is

  function matches
    (patterns : String;
     assembly : String)
  return Boolean;

end Adac_Assembly_Patterns;
