-- ============================================================================
-- adac-sema.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;

package Adac.Sema is

  function analyze (unit : Adac.AST.Compilation_Unit) return Boolean;

end Adac.Sema;
