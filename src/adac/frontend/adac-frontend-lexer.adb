-- ============================================================================
-- adac-frontend-lexer.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;
with Ada.Strings.Unbounded;

package body Adac.Frontend.Lexer is

  use Adac.Frontend.Tokens;
  use type Adac.Source.Source_File_ID;

  procedure open
    (self               : in out Scanner;
     path               : String;
     file_id            : Adac.Source.Source_File_ID;
     maximum_characters : Adac.Resources.Source_Character_Limit)
  is
  begin
    if self.is_open then
      raise Program_Error with "scanner is already open";
    end if;

    if file_id = Adac.Source.INVALID_SOURCE_FILE_ID then
      raise Program_Error with "scanner requires a valid source file ID";
    end if;

    self.file_id := Adac.Source.INVALID_SOURCE_FILE_ID;
    Ada.Text_IO.open (self.file, Ada.Text_IO.in_file, path);

    self.is_open            := True;
    self.lookahead          := ASCII.NUL;
    self.has_lookahead      := False;
    self.file_id            := file_id;
    self.line_no            := 1;
    self.column_no          := 1;
    self.maximum_characters := maximum_characters;
    self.characters_read    := 0;
  end open;

  procedure close (self : in out Scanner) is
  begin
    if self.is_open then
      Ada.Text_IO.close (self.file);
      self.is_open       := False;
      self.has_lookahead := False;
      self.file_id       := Adac.Source.INVALID_SOURCE_FILE_ID;
    end if;
  end close;

  function matches_keyword
    (text    : Ada.Strings.Unbounded.Unbounded_String;
     keyword : String)
  return Boolean
  is
  begin
    if Ada.Strings.Unbounded.length (text) /= keyword'Length then
      return False;
    end if;

    for index in 1 .. keyword'Length loop
      if Ada.Characters.Handling.to_lower
           (Ada.Strings.Unbounded.element (text, index)) /=
         keyword(keyword'First + index - 1)
      then
        return False;
      end if;
    end loop;

    return True;
  end matches_keyword;

  function classify_word
    (text : Ada.Strings.Unbounded.Unbounded_String) return Token_Kind
  is
  begin
    if matches_keyword (text, "procedure") then
      return Tok_Procedure;
    end if;

    if matches_keyword (text, "is") then
      return Tok_Is;
    end if;

    if matches_keyword (text, "begin") then
      return Tok_Begin;
    end if;

    if matches_keyword (text, "end") then
      return Tok_End;
    end if;

    if matches_keyword (text, "null") then
      return Tok_Null;
    end if;

    if matches_keyword (text, "return") then
      return Tok_Return;
    end if;

    return Tok_Identifier;
  end classify_word;

  procedure load_lookahead (self : in out Scanner) is
  begin
    if self.has_lookahead then
      return;
    end if;

    if not self.is_open then
      raise Program_Error with "scanner is not open";
    end if;

    if Ada.Text_IO.end_of_file (self.file) then
      return;
    end if;

    if self.characters_read >= self.maximum_characters then
      raise Adac.Resources.Limit_Exceeded with
        "source character limit exceeded";
    end if;

    self.lookahead_position :=
      Adac.Source.make_position
        (self.file_id, self.line_no, self.column_no);
    self.characters_read := self.characters_read + 1;

    if Ada.Text_IO.end_of_line (self.file) then
      self.lookahead := ASCII.LF;
      Ada.Text_IO.skip_line (self.file);
      self.line_no   := self.line_no + 1;
      self.column_no := 1;
    else
      Ada.Text_IO.get (self.file, self.lookahead);
      self.column_no := self.column_no + 1;
    end if;

    self.has_lookahead := True;
  end load_lookahead;

  procedure consume_lookahead (self : in out Scanner) is
  begin
    if not self.has_lookahead then
      raise Program_Error with "scanner has no lookahead character";
    end if;

    self.has_lookahead := False;
  end consume_lookahead;

  function next_token (self : in out Scanner) return Token is
  begin
    loop
      load_lookahead (self);

      if not self.has_lookahead then
        return make_token
          (Tok_EOF,
           "",
           Adac.Source.make_position (self.file_id, self.line_no, 1));
      end if;

      if self.lookahead = ' ' or else
         self.lookahead = ASCII.HT or else
         self.lookahead = ASCII.LF
      then
        consume_lookahead (self);

      elsif self.lookahead = '-' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '-' then
            consume_lookahead (self);

            loop
              load_lookahead (self);
              exit when not self.has_lookahead or else
                self.lookahead = ASCII.LF;
              consume_lookahead (self);
            end loop;
          else
            return make_token (Tok_Unknown, "-", position);
          end if;
        end;

      elsif self.lookahead = ';' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Semicolon, ";", position);
        end;

      elsif Ada.Characters.Handling.is_letter (self.lookahead) then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
          text : Ada.Strings.Unbounded.Unbounded_String;
        begin
          loop
            Ada.Strings.Unbounded.append (text, self.lookahead);
            consume_lookahead (self);
            load_lookahead (self);

            exit when not self.has_lookahead or else
              (not Ada.Characters.Handling.is_letter (self.lookahead)
               and then self.lookahead /= '_');
          end loop;

          return (kind     => classify_word (text),
                  text     => text,
                  position => position);
        end;

      else
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
          text : constant String := String'(1 => self.lookahead);
        begin
          consume_lookahead (self);
          return make_token (Tok_Unknown, text, position);
        end;
      end if;
    end loop;
  end next_token;

end Adac.Frontend.Lexer;
