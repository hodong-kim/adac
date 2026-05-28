-- ============================================================================
-- adac-frontend.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Frontend.Parser;

package body Adac.Frontend is

  function parse_file (path : String) return Parse_Result is
  begin
    return Adac.Frontend.Parser.parse_file (path);
  end parse_file;

end Adac.Frontend;
