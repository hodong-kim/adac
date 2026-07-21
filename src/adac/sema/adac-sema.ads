-- ============================================================================
-- adac-sema.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Compilation;
with Adac.Semantics;

package Adac.Sema is

  type Analysis_Status is
    (Analysis_Rejected,
     Analysis_Succeeded);

  type Analysis_Result
    (status : Analysis_Status := Analysis_Rejected)
  is record
    case status is
      when Analysis_Rejected =>
        null;

      when Analysis_Succeeded =>
        entity : Adac.Semantics.Entity_ID;
    end case;
  end record;

  --! summary
  --!   Checks whether one parsed compilation unit is valid for IR lowering.
  --! contract
  --!   `Analysis_Rejected` has no entity payload and means that ordinary source
  --!   diagnostics were recorded in `context`. Internal contract violations
  --!   propagate as exceptions rather than being converted into a rejection.
  --! ownership
  --!   A successful result borrows one entity owned by `context`. The
  --!   operation borrows `root` and transfers no ownership.
  function analyze
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Analysis_Result;

end Adac.Sema;
