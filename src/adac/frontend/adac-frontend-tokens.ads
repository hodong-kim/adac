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
     Tok_Package,
     Tok_Body,
     Tok_Type,
     Tok_Subtype,
     Tok_Private,
     Tok_Limited,
     Tok_Function,
     Tok_Is,
     Tok_New,
     Tok_Renames,
     Tok_Separate,
     Tok_Declare,
     Tok_Begin,
     Tok_End,
     Tok_Null,
     Tok_Exit,
     Tok_Return,
     Tok_Do,
     Tok_Raise,
     Tok_All,
     Tok_In,
     Tok_Out,
     Tok_Aliased,
     Tok_If,
     Tok_Case,
     Tok_Then,
     Tok_Elsif,
     Tok_Else,
     Tok_Exception,
     Tok_Others,
     Tok_With,
     Tok_Record,
     Tok_Range,
     Tok_Digits,
     Tok_Delta,
     Tok_For,
     Tok_While,
     Tok_Of,
     Tok_Loop,
     Tok_Reverse,
     Tok_When,
     Tok_Use,
     Tok_Access,
     Tok_Constant,
     Tok_Protected,
     Tok_And,
     Tok_Or,
     Tok_Xor,
     Tok_Mod,
     Tok_Rem,
     Tok_Abs,
     Tok_Not,
     Tok_Invalid_Identifier,
     Tok_Decimal_Integer_Literal,
     Tok_Decimal_Real_Literal,
     Tok_Based_Integer_Literal,
     Tok_Based_Real_Literal,
     Tok_Invalid_Numeric_Literal,
     Tok_Character_Literal,
     Tok_String_Literal,
     Tok_Invalid_String_Literal,
     Tok_Identifier,
     Tok_Equal,
     Tok_Not_Equal,
     Tok_Less_Than,
     Tok_Less_Than_Or_Equal,
     Tok_Greater_Than,
     Tok_Greater_Than_Or_Equal,
     Tok_Plus,
     Tok_Minus,
     Tok_Ampersand,
     Tok_Asterisk,
     Tok_Slash,
     Tok_Double_Star,
     Tok_Dot,
     Tok_Double_Dot,
     Tok_Arrow,
     Tok_Box,
     Tok_Apostrophe,
     Tok_Left_Parenthesis,
     Tok_Right_Parenthesis,
     Tok_Left_Bracket,
     Tok_Right_Bracket,
     Tok_Comma,
     Tok_Vertical_Bar,
     Tok_Colon,
     Tok_Assign,
     Tok_Semicolon,
     Tok_Unknown);

  --! summary Return the token kind for an Ada operator spelling.
  --! returns `Tok_Unknown` when `spelling` is not a current Ada operator.
  function operator_kind (spelling : String) return Token_Kind;

  --! summary Return whether `kind` is an Ada operator token.
  function is_operator (kind : Token_Kind) return Boolean;

  function is_logical_operator (kind : Token_Kind) return Boolean;
  function is_relational_operator (kind : Token_Kind) return Boolean;
  function is_binary_adding_operator (kind : Token_Kind) return Boolean;
  function is_unary_adding_operator (kind : Token_Kind) return Boolean;
  function is_multiplying_operator (kind : Token_Kind) return Boolean;

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
