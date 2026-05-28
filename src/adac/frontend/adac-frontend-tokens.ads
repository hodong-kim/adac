-- ============================================================================
-- adac-frontend-tokens.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.Source;

package Adac.Frontend.Tokens is

  type Token_Kind is
    (Tok_EOF,
     Tok_Procedure,
     Tok_Is,
     Tok_Begin,
     Tok_End,
     Tok_Null,
     Tok_Identifier,
     Tok_Semicolon,
     Tok_Unknown);

  type Token is record
    kind     : Token_Kind;
    text     : Ada.Strings.Unbounded.Unbounded_String;
    position : Adac.Source.Position;
  end record;

function make_token (kind     : Token_Kind;
                     text     : String := "";
                     position : Adac.Source.Position)
return Token;

end Adac.Frontend.Tokens;
