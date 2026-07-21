-- ============================================================================
-- adac-frontend-lexer.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Adac.Frontend.Tokens;
with Adac.Source;

package Adac.Frontend.Lexer is

  type Scanner is limited private;

  --! summary: Open a registered source file for tokenization.
  --! contract: The scanner must be closed and the file ID must be valid.
  procedure open
    (self    : in out Scanner;
     path    : String;
     file_id : Adac.Source.Source_File_ID);

  --  Closing a scanner that is not open is a no-op.
  procedure close (self : in out Scanner);

  function next_token
    (self : in out Scanner) return Adac.Frontend.Tokens.Token;

private

  type Scanner is limited record
    file        : Ada.Text_IO.File_Type;
    is_open     : Boolean := False;
    current     : Ada.Strings.Unbounded.Unbounded_String;
    index       : Natural := 0;
    end_of_line : Boolean := True;

    file_id : Adac.Source.Source_File_ID := Adac.Source.INVALID_SOURCE_FILE_ID;
    line_no : Positive := 1;
  end record;

end Adac.Frontend.Lexer;
