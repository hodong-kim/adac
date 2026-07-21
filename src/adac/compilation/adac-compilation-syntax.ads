-- ============================================================================
-- adac-compilation-syntax.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;

package Adac.Compilation.Syntax is

  --! summary: Validate an AST and all compilation-context ownership links.
  procedure validate
    (self : Context;
     unit : Adac.AST.Compilation_Unit);

end Adac.Compilation.Syntax;
