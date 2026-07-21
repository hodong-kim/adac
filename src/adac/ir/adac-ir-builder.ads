-- ============================================================================
-- adac-ir-builder.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation;
with Adac.Semantics;

package Adac.IR.Builder is

  --! summary
  --!   Lower one validated semantic procedure entity to target-independent IR.
  --! ownership
  --!   The operation borrows `context` and `entity` and returns an owned
  --!   module.
  function build
    (context : Adac.Compilation.Context;
     entity  : Adac.Semantics.Entity_ID)
  return Adac.IR.Module;

end Adac.IR.Builder;
