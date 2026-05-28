-- ============================================================================
-- adac-frontend-parser.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Frontend.Parser is

  function parse_file (path : String) return Adac.Frontend.Parse_Result;

end Adac.Frontend.Parser;
