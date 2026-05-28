-- ============================================================================
-- adac-frontend-lexer.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Adac.Frontend.Tokens;

package Adac.Frontend.Lexer is

  type Scanner is limited private;

  procedure open (self : in out Scanner;
                  path : String);

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

    file_name : Ada.Strings.Unbounded.Unbounded_String;
    line_no   : Positive := 1;
  end record;

end Adac.Frontend.Lexer;
