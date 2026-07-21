-- ============================================================================
-- adac-sema.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Compilation;

package Adac.Sema is

  function analyze
    (context : in out Adac.Compilation.Context;
     unit    : Adac.AST.Compilation_Unit)
  return Boolean;

end Adac.Sema;
