-- ============================================================================
-- adac-ir-builder.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Compilation;

package Adac.IR.Builder is

  --! summary: Lower one validated AST root to target-independent IR.
  --! ownership
  --!   The operation borrows `context` and `root` and returns an owned module.
  function build
    (context : Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Adac.IR.Module;

end Adac.IR.Builder;
