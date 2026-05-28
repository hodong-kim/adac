-- ============================================================================
-- adac-frontend-tokens.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.Frontend.Tokens is

  function make_token (kind     : Token_Kind;
                       text     : String := "";
                       position : Adac.Source.Position)
  return Token is
  begin
    return (kind     => kind,
            text     => Ada.Strings.Unbounded.to_unbounded_string (text),
            position => position);
  end make_token;

end Adac.Frontend.Tokens;
