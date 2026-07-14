-- ============================================================================
-- adac-frontend-lexer.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;

with Adac.Source;

package body Adac.Frontend.Lexer is

  use Adac.Frontend.Tokens;

  procedure open (self : in out Scanner;
                  path : String) is
  begin
    Ada.Text_IO.open (self.file, Ada.Text_IO.in_file, path);
    self.is_open     := True;
    self.index       := 0;
    self.end_of_line := True;

    self.file_name := Ada.Strings.Unbounded.to_unbounded_string (path);
    self.line_no   := 1;
  end open;

  procedure close (self : in out Scanner) is
  begin
    if self.is_open then
      Ada.Text_IO.close (self.file);
      self.is_open := False;
    end if;
  end close;

  function classify_word (text : String) return Token_Kind is
    lower_text : constant String := Ada.Characters.Handling.To_Lower (text);
  begin
    if lower_text = "procedure" then
      return Tok_Procedure;
    end if;

    if lower_text = "is" then
      return Tok_Is;
    end if;

    if lower_text = "begin" then
      return Tok_Begin;
    end if;

    if lower_text = "end" then
      return Tok_End;
    end if;

    if lower_text = "null" then
      return Tok_Null;
    end if;

    if lower_text = "return" then
      return Tok_Return;
    end if;

    return Tok_Identifier;
  end classify_word;

  procedure load_next_line (self : in out Scanner) is
  begin
    if Ada.Text_IO.end_of_file (self.file) then
      self.end_of_line := True;
      return;
    end if;

    if self.index /= 0 then
      self.line_no := self.line_no + 1;
    end if;

    self.current :=
      Ada.Strings.Unbounded.to_unbounded_string
        (Ada.Text_IO.get_line (self.file));

    self.index       := 1;
    self.end_of_line := False;
  end load_next_line;

function next_token (self : in out Scanner) return Token is
  function token_position (self   : Scanner;
                           column : Positive)
  return Adac.Source.Position is
  begin
    return Adac.Source.make_position
      (Ada.Strings.Unbounded.to_string (self.file_name),
       self.line_no,
       column);
  end token_position;

  start : Natural;
begin
  loop
    if self.end_of_line then
      if Ada.Text_IO.end_of_file (self.file) then
        return make_token (Tok_EOF,
                           "",
                           token_position (self, 1));
      end if;

      load_next_line (self);
    end if;

    declare
      line : constant String :=
        Ada.Strings.Unbounded.to_string (self.current);
    begin
      while self.index <= line'last loop
        if line(self.index) = ' ' or else line(self.index) = ASCII.HT then
          self.index := self.index + 1;

        elsif line(self.index) = ';' then
          declare
            column : constant Positive := self.index;
          begin
            self.index := self.index + 1;

            return make_token (Tok_Semicolon,
                               ";",
                               token_position (self, column));
          end;

        elsif Ada.Characters.Handling.is_letter (line(self.index)) then
          start := self.index;

          while self.index <= line'last
            and then
              (Ada.Characters.Handling.is_letter (line(self.index))
               or else line(self.index) = '_')
          loop
            self.index := self.index + 1;
          end loop;

          declare
            text : constant String := line(start .. self.index - 1);
          begin
            return make_token (classify_word (text),
                               text,
                               token_position (self, start));
          end;

        else
          declare
            column : constant Positive := self.index;
            text   : constant String := String'(1 => line(self.index));
          begin
            self.index := self.index + 1;

            return make_token (Tok_Unknown,
                               text,
                               token_position (self, column));
          end;
        end if;
      end loop;
    end;

    self.end_of_line := True;
  end loop;
end next_token;

end Adac.Frontend.Lexer;
