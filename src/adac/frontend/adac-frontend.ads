-- ============================================================================
-- adac-frontend.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Compilation;

package Adac.Frontend is

  type Parse_Result is record
    ok   : Boolean := False;
    unit : Adac.AST.Compilation_Unit;
  end record;

  function parse_file
    (context : in out Adac.Compilation.Context;
     path    : String)
  return Parse_Result;

end Adac.Frontend;
