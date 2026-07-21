-- ============================================================================
-- adac-frontend-parser.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation;

package Adac.Frontend.Parser is

  function parse_file
    (context : in out Adac.Compilation.Context;
     path    : String)
  return Adac.Frontend.Parse_Result;

end Adac.Frontend.Parser;
