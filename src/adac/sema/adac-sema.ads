-- ============================================================================
-- adac-sema.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Compilation;

package Adac.Sema is

  type Analysis_Result is
    (Analysis_Rejected,
     Analysis_Succeeded);

  --! summary
  --!   Checks whether one parsed compilation unit is valid for IR lowering.
  --! contract
  --!   `Analysis_Rejected` means that ordinary source diagnostics were
  --!   recorded in `context`. Internal contract violations propagate as
  --!   exceptions rather than being converted into a rejection.
  --! ownership
  --!   The operation borrows `context` and `root` and transfers no ownership.
  function analyze
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Analysis_Result;

end Adac.Sema;
