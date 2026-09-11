-- ============================================================================
-- adac-frontend-lexer.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Latin_1;
with Ada.Text_IO;

with Adac.Frontend.Tokens;
with Adac.Resources;
with Adac.Source;

package Adac.Frontend.Lexer is

  type Scanner is limited private;

  --! summary: Open a registered source file for tokenization.
  --! contract
  --!   The scanner must be closed. The file ID must be valid, and the source
  --!   character budget applies before each character is read.
  procedure open
    (self               : in out Scanner;
     path               : String;
     file_id            : Adac.Source.Source_File_ID;
     maximum_characters : Adac.Resources.Source_Character_Limit);

  --  Closing a scanner that is not open is a no-op.
  procedure close (self : in out Scanner);

  --! summary: Return the next token from the bounded source stream.
  --! contract
  --!   The scanner must be open. Budget exhaustion raises `Limit_Exceeded`
  --!   before an incomplete token is returned.
  function next_token
    (self : in out Scanner) return Adac.Frontend.Tokens.Token;

private

  type Scanner is limited record
    file               : Ada.Text_IO.File_Type;
    is_open            : Boolean := False;
    lookahead          : Character := Ada.Characters.Latin_1.NUL;
    has_lookahead      : Boolean := False;
    lookahead_position : Adac.Source.Position;
    deferred_character : Character := Ada.Characters.Latin_1.NUL;
    has_deferred       : Boolean := False;
    deferred_position  : Adac.Source.Position;

    file_id            : Adac.Source.Source_File_ID :=
      Adac.Source.INVALID_SOURCE_FILE_ID;
    line_no            : Positive := 1;
    column_no          : Positive := 1;
    maximum_characters : Adac.Resources.Source_Character_Limit := 0;
    characters_read    : Adac.Resources.Source_Character_Limit := 0;
  end record;

end Adac.Frontend.Lexer;
