-- ============================================================================
-- adac-ir-builder.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
-- with Adac.IR;

package Adac.IR.Builder is

  function build (unit : Adac.AST.Compilation_Unit) return Adac.IR.Module;

end Adac.IR.Builder;
