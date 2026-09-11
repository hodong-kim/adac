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

  APOSTROPHE : constant Character := Character'Val (16#27#);
  QUOTATION_MARK : constant Character := Character'Val (16#22#);

  function is_ascii_letter (value : Character) return Boolean is
  begin
    return value in 'A' .. 'Z' or else value in 'a' .. 'z';
  end is_ascii_letter;

  function is_ascii_digit (value : Character) return Boolean is
  begin
    return value in '0' .. '9';
  end is_ascii_digit;

  function is_ascii_graphic (value : Character) return Boolean is
  begin
    return value in ' ' .. '~';
  end is_ascii_graphic;

  function is_extended_digit (value : Character) return Boolean is
  begin
    return is_ascii_digit (value) or else
      value in 'A' .. 'F' or else
      value in 'a' .. 'f';
  end is_extended_digit;

  function is_identifier_character (value : Character) return Boolean is
  begin
    return is_ascii_letter (value) or else
      is_ascii_digit (value) or else
      value = '_';
  end is_identifier_character;

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
    self.lookahead          := Ada.Characters.Latin_1.NUL;
    self.has_lookahead      := False;
    self.deferred_character := Ada.Characters.Latin_1.NUL;
    self.has_deferred       := False;
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
      self.has_deferred  := False;
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

    if matches_keyword (text, "package") then
      return Tok_Package;
    end if;

    if matches_keyword (text, "body") then
      return Tok_Body;
    end if;

    if matches_keyword (text, "type") then
      return Tok_Type;
    end if;

    if matches_keyword (text, "subtype") then
      return Tok_Subtype;
    end if;

    if matches_keyword (text, "private") then
      return Tok_Private;
    end if;

    if matches_keyword (text, "limited") then
      return Tok_Limited;
    end if;

    if matches_keyword (text, "function") then
      return Tok_Function;
    end if;

    if matches_keyword (text, "is") then
      return Tok_Is;
    end if;

    if matches_keyword (text, "new") then
      return Tok_New;
    end if;

    if matches_keyword (text, "renames") then
      return Tok_Renames;
    end if;

    if matches_keyword (text, "separate") then
      return Tok_Separate;
    end if;

    if matches_keyword (text, "declare") then
      return Tok_Declare;
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

    if matches_keyword (text, "exit") then
      return Tok_Exit;
    end if;

    if matches_keyword (text, "return") then
      return Tok_Return;
    end if;

    if matches_keyword (text, "do") then
      return Tok_Do;
    end if;

    if matches_keyword (text, "raise") then
      return Tok_Raise;
    end if;

    if matches_keyword (text, "all") then
      return Tok_All;
    end if;

    if matches_keyword (text, "in") then
      return Tok_In;
    end if;

    if matches_keyword (text, "out") then
      return Tok_Out;
    end if;

    if matches_keyword (text, "aliased") then
      return Tok_Aliased;
    end if;

    if matches_keyword (text, "if") then
      return Tok_If;
    end if;

    if matches_keyword (text, "case") then
      return Tok_Case;
    end if;

    if matches_keyword (text, "then") then
      return Tok_Then;
    end if;

    if matches_keyword (text, "elsif") then
      return Tok_Elsif;
    end if;

    if matches_keyword (text, "else") then
      return Tok_Else;
    end if;

    if matches_keyword (text, "exception") then
      return Tok_Exception;
    end if;

    if matches_keyword (text, "others") then
      return Tok_Others;
    end if;

    if matches_keyword (text, "with") then
      return Tok_With;
    end if;

    if matches_keyword (text, "record") then
      return Tok_Record;
    end if;

    if matches_keyword (text, "range") then
      return Tok_Range;
    end if;

    if matches_keyword (text, "digits") then
      return Tok_Digits;
    end if;

    if matches_keyword (text, "delta") then
      return Tok_Delta;
    end if;

    if matches_keyword (text, "for") then
      return Tok_For;
    end if;

    if matches_keyword (text, "while") then
      return Tok_While;
    end if;

    if matches_keyword (text, "of") then
      return Tok_Of;
    end if;

    if matches_keyword (text, "loop") then
      return Tok_Loop;
    end if;

    if matches_keyword (text, "reverse") then
      return Tok_Reverse;
    end if;

    if matches_keyword (text, "when") then
      return Tok_When;
    end if;

    if matches_keyword (text, "use") then
      return Tok_Use;
    end if;

    if matches_keyword (text, "access") then
      return Tok_Access;
    end if;

    if matches_keyword (text, "constant") then
      return Tok_Constant;
    end if;

    if matches_keyword (text, "protected") then
      return Tok_Protected;
    end if;

    if Ada.Strings.Unbounded.length (text) <= 3 then
      declare
        kind : constant Token_Kind :=
          operator_kind (Ada.Strings.Unbounded.to_string (text));
      begin
        if kind /= Tok_Unknown then
          return kind;
        end if;
      end;
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

    if self.has_deferred then
      self.lookahead          := self.deferred_character;
      self.lookahead_position := self.deferred_position;
      self.has_deferred       := False;
      self.has_lookahead      := True;
      return;
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
      self.lookahead := Ada.Characters.Latin_1.LF;
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

  procedure restore_lookahead
    (self     : in out Scanner;
     value    : Character;
     position : Adac.Source.Position)
  is
  begin
    if self.has_deferred then
      raise Program_Error with "scanner deferred character is occupied";
    end if;

    if self.has_lookahead then
      self.deferred_character := self.lookahead;
      self.deferred_position  := self.lookahead_position;
      self.has_deferred       := True;
    end if;

    self.lookahead          := value;
    self.lookahead_position := position;
    self.has_lookahead      := True;
  end restore_lookahead;

  function scan_identifier (self : in out Scanner) return Token is
    position         : constant Adac.Source.Position := self.lookahead_position;
    text             : Ada.Strings.Unbounded.Unbounded_String;
    kind             : Token_Kind;
    valid            : Boolean := is_ascii_letter (self.lookahead);
    after_underscore : Boolean := False;
  begin
    loop
      if self.lookahead = '_' then
        if after_underscore then
          valid := False;
        end if;

        after_underscore := True;
      else
        after_underscore := False;
      end if;

      Ada.Strings.Unbounded.append (text, self.lookahead);
      consume_lookahead (self);
      load_lookahead (self);

      exit when not self.has_lookahead or else
        not is_identifier_character (self.lookahead);
    end loop;

    if after_underscore then
      valid := False;
    end if;

    if valid then
      kind := classify_word (text);
    else
      kind := Tok_Invalid_Identifier;
    end if;

    return (kind     => kind,
            text     => text,
            position => position);
  end scan_identifier;

  function scan_apostrophe
    (self : in out Scanner) return Token
  is
    position         : constant Adac.Source.Position :=
      self.lookahead_position;
    content          : Character;
    content_position : Adac.Source.Position;
    text             : Ada.Strings.Unbounded.Unbounded_String;
  begin
    consume_lookahead (self);
    load_lookahead (self);

    if not self.has_lookahead or else
       not is_ascii_graphic (self.lookahead)
    then
      return make_token (Tok_Apostrophe, "'", position);
    end if;

    content          := self.lookahead;
    content_position := self.lookahead_position;
    consume_lookahead (self);
    load_lookahead (self);

    if self.has_lookahead and then self.lookahead = APOSTROPHE then
      consume_lookahead (self);
      Ada.Strings.Unbounded.append (text, APOSTROPHE);
      Ada.Strings.Unbounded.append (text, content);
      Ada.Strings.Unbounded.append (text, APOSTROPHE);
      return (kind     => Tok_Character_Literal,
              text     => text,
              position => position);
    end if;

    restore_lookahead (self, content, content_position);
    return make_token (Tok_Apostrophe, "'", position);
  end scan_apostrophe;

  function scan_string_literal
    (self : in out Scanner) return Token
  is
    position : constant Adac.Source.Position := self.lookahead_position;
    text     : Ada.Strings.Unbounded.Unbounded_String;
    valid    : Boolean := True;

    procedure append_lookahead is
    begin
      Ada.Strings.Unbounded.append (text, self.lookahead);
      consume_lookahead (self);
      load_lookahead (self);
    end append_lookahead;

    function invalid_token return Token is
    begin
      return (kind     => Tok_Invalid_String_Literal,
              text     => text,
              position => position);
    end invalid_token;

  begin
    append_lookahead;

    loop
      if not self.has_lookahead or else
         self.lookahead = Ada.Characters.Latin_1.LF
      then
        return invalid_token;
      end if;

      if not is_ascii_graphic (self.lookahead) then
        valid := False;
      end if;

      if self.lookahead /= QUOTATION_MARK then
        append_lookahead;
      else
        append_lookahead;

        if self.has_lookahead and then
           self.lookahead = QUOTATION_MARK
        then
          append_lookahead;
        elsif valid then
          return (kind     => Tok_String_Literal,
                  text     => text,
                  position => position);
        else
          return invalid_token;
        end if;
      end if;
    end loop;
  end scan_string_literal;

  function scan_numeric_literal (self : in out Scanner) return Token is
    position  : constant Adac.Source.Position := self.lookahead_position;
    text      : Ada.Strings.Unbounded.Unbounded_String;
    valid     : Boolean := True;
    is_based  : Boolean := False;
    has_point : Boolean := False;
    kind      : Token_Kind;

    procedure append_lookahead is
    begin
      Ada.Strings.Unbounded.append (text, self.lookahead);
      consume_lookahead (self);
      load_lookahead (self);
    end append_lookahead;

    procedure scan_decimal_numeral is
      after_underscore : Boolean := False;
    begin
      if not self.has_lookahead or else
         not is_ascii_digit (self.lookahead)
      then
        valid := False;
        return;
      end if;

      loop
        if self.lookahead = '_' then
          if after_underscore then
            valid := False;
          end if;

          after_underscore := True;
        else
          after_underscore := False;
        end if;

        append_lookahead;

        exit when not self.has_lookahead or else
          (not is_ascii_digit (self.lookahead) and then
           self.lookahead /= '_');
      end loop;

      if after_underscore then
        valid := False;
      end if;
    end scan_decimal_numeral;

    procedure scan_based_numeral is
      has_extended_digit : Boolean := False;
      after_underscore   : Boolean := False;
    begin
      if not self.has_lookahead or else
         not is_identifier_character (self.lookahead)
      then
        valid := False;
        return;
      end if;

      loop
        if self.lookahead = '_' then
          if not has_extended_digit or else after_underscore then
            valid := False;
          end if;

          after_underscore := True;
        else
          if not is_extended_digit (self.lookahead) then
            valid := False;
          end if;

          has_extended_digit := True;
          after_underscore   := False;
        end if;

        append_lookahead;

        exit when not self.has_lookahead or else
          not is_identifier_character (self.lookahead);
      end loop;

      if after_underscore then
        valid := False;
      end if;
    end scan_based_numeral;

    procedure scan_exponent is
    begin
      if not self.has_lookahead or else
         (self.lookahead /= 'E' and then self.lookahead /= 'e')
      then
        return;
      end if;

      append_lookahead;

      if self.has_lookahead and then
         (self.lookahead = '+' or else self.lookahead = '-')
      then
        append_lookahead;
      end if;

      scan_decimal_numeral;
    end scan_exponent;

    procedure consume_identifier_suffix is
    begin
      if not self.has_lookahead or else
         not is_identifier_character (self.lookahead)
      then
        return;
      end if;

      valid := False;

      loop
        append_lookahead;
        exit when not self.has_lookahead or else
          not is_identifier_character (self.lookahead);
      end loop;
    end consume_identifier_suffix;

  begin
    scan_decimal_numeral;

    if self.has_lookahead and then self.lookahead = '#' then
      is_based := True;
      append_lookahead;
      scan_based_numeral;

      if self.has_lookahead and then self.lookahead = '.' then
        has_point := True;
        append_lookahead;
        scan_based_numeral;
      end if;

      if self.has_lookahead and then self.lookahead = '#' then
        append_lookahead;
        scan_exponent;
      else
        valid := False;
      end if;
    else
      if self.has_lookahead and then self.lookahead = '.' then
        declare
          point_position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '.' then
            restore_lookahead (self, '.', point_position);
          else
            has_point := True;
            Ada.Strings.Unbounded.append (text, '.');
            scan_decimal_numeral;
          end if;
        end;
      end if;

      scan_exponent;
    end if;

    consume_identifier_suffix;

    if valid and then is_based then
      kind := (if has_point
               then Tok_Based_Real_Literal
               else Tok_Based_Integer_Literal);
    elsif valid then
      kind := (if has_point
               then Tok_Decimal_Real_Literal
               else Tok_Decimal_Integer_Literal);
    else
      kind := Tok_Invalid_Numeric_Literal;
    end if;

    return (kind     => kind,
            text     => text,
            position => position);
  end scan_numeric_literal;

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
         self.lookahead = Ada.Characters.Latin_1.HT or else
         self.lookahead = Ada.Characters.Latin_1.LF
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
                self.lookahead = Ada.Characters.Latin_1.LF;
              consume_lookahead (self);
            end loop;
          else
            return make_token (Tok_Minus, "-", position);
          end if;
        end;

      elsif self.lookahead = '+' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Plus, "+", position);
        end;

      elsif self.lookahead = '&' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Ampersand, "&", position);
        end;

      elsif self.lookahead = '*' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '*' then
            consume_lookahead (self);
            return make_token (Tok_Double_Star, "**", position);
          end if;

          return make_token (Tok_Asterisk, "*", position);
        end;

      elsif self.lookahead = '/' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '=' then
            consume_lookahead (self);
            return make_token (Tok_Not_Equal, "/=", position);
          end if;

          return make_token (Tok_Slash, "/", position);
        end;

      elsif self.lookahead = '<' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '=' then
            consume_lookahead (self);
            return make_token (Tok_Less_Than_Or_Equal, "<=", position);
          elsif self.has_lookahead and then self.lookahead = '>' then
            consume_lookahead (self);
            return make_token (Tok_Box, "<>", position);
          elsif self.has_lookahead and then self.lookahead = '<' then
            consume_lookahead (self);
            return make_token (Tok_Unknown, "<<", position);
          end if;

          return make_token (Tok_Less_Than, "<", position);
        end;

      elsif self.lookahead = '>' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '=' then
            consume_lookahead (self);
            return make_token (Tok_Greater_Than_Or_Equal, ">=", position);
          elsif self.has_lookahead and then self.lookahead = '>' then
            consume_lookahead (self);
            return make_token (Tok_Unknown, ">>", position);
          end if;

          return make_token (Tok_Greater_Than, ">", position);
        end;

      elsif self.lookahead = '(' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Left_Parenthesis, "(", position);
        end;

      elsif self.lookahead = ')' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Right_Parenthesis, ")", position);
        end;

      elsif self.lookahead = '[' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Left_Bracket, "[", position);
        end;

      elsif self.lookahead = ']' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Right_Bracket, "]", position);
        end;

      elsif self.lookahead = ',' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Comma, ",", position);
        end;

      elsif self.lookahead = '|' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Vertical_Bar, "|", position);
        end;

      elsif self.lookahead = ':' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '=' then
            consume_lookahead (self);
            return make_token (Tok_Assign, ":=", position);
          end if;

          return make_token (Tok_Colon, ":", position);
        end;

      elsif self.lookahead = ';' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          return make_token (Tok_Semicolon, ";", position);
        end;

      elsif self.lookahead = '.' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '.' then
            consume_lookahead (self);
            return make_token (Tok_Double_Dot, "..", position);
          end if;

          return make_token (Tok_Dot, ".", position);
        end;

      elsif self.lookahead = '=' then
        declare
          position : constant Adac.Source.Position :=
            self.lookahead_position;
        begin
          consume_lookahead (self);
          load_lookahead (self);

          if self.has_lookahead and then self.lookahead = '>' then
            consume_lookahead (self);
            return make_token (Tok_Arrow, "=>", position);
          end if;

          return make_token (Tok_Equal, "=", position);
        end;

      elsif self.lookahead = APOSTROPHE then
        return scan_apostrophe (self);

      elsif self.lookahead = QUOTATION_MARK then
        return scan_string_literal (self);

      elsif is_ascii_digit (self.lookahead) then
        return scan_numeric_literal (self);

      elsif is_ascii_letter (self.lookahead) or else
            self.lookahead = '_'
      then
        return scan_identifier (self);

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
