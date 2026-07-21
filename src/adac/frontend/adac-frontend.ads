-- ============================================================================
-- adac-frontend.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Compilation;

package Adac.Frontend is

  type Parse_Status is
    (Parse_Rejected,
     Parse_Succeeded);

  type Parse_Result (status : Parse_Status := Parse_Rejected) is record
    case status is
      when Parse_Rejected =>
        null;

      when Parse_Succeeded =>
        unit : Adac.AST.Compilation_Unit;
    end case;
  end record;

  --! summary
  --!   Parses one source file into a compilation unit.
  --! contract
  --!   `Parse_Rejected` means that ordinary source diagnostics were recorded
  --!   in `context` and no AST payload is available. External input failures
  --!   and internal contract violations propagate as exceptions.
  --! ownership
  --!   A successful result owns its compilation-unit payload. The operation
  --!   borrows `context` and does not retain `path`.
  function parse_file
    (context : in out Adac.Compilation.Context;
     path    : String)
  return Parse_Result;

end Adac.Frontend;
