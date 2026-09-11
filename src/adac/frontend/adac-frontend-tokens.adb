-- ============================================================================
-- adac-frontend-tokens.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;

package body Adac.Frontend.Tokens is

  function matches_word
    (spelling : String;
     word     : String)
  return Boolean
  is
  begin
    if spelling'Length /= word'Length then
      return False;
    end if;

    for index in spelling'Range loop
      if Ada.Characters.Handling.to_lower (spelling(index)) /=
         word(word'First + index - spelling'First)
      then
        return False;
      end if;
    end loop;

    return True;
  end matches_word;

  function operator_kind (spelling : String) return Token_Kind is
  begin
    case spelling'Length is
      when 1 =>
        case spelling(spelling'First) is
          when '=' => return Tok_Equal;
          when '<' => return Tok_Less_Than;
          when '>' => return Tok_Greater_Than;
          when '+' => return Tok_Plus;
          when '-' => return Tok_Minus;
          when '&' => return Tok_Ampersand;
          when '*' => return Tok_Asterisk;
          when '/' => return Tok_Slash;
          when others => return Tok_Unknown;
        end case;

      when 2 =>
        if matches_word (spelling, "or") then
          return Tok_Or;
        elsif spelling = "/=" then
          return Tok_Not_Equal;
        elsif spelling = "<=" then
          return Tok_Less_Than_Or_Equal;
        elsif spelling = ">=" then
          return Tok_Greater_Than_Or_Equal;
        elsif spelling = "**" then
          return Tok_Double_Star;
        else
          return Tok_Unknown;
        end if;

      when 3 =>
        if matches_word (spelling, "and") then
          return Tok_And;
        elsif matches_word (spelling, "xor") then
          return Tok_Xor;
        elsif matches_word (spelling, "mod") then
          return Tok_Mod;
        elsif matches_word (spelling, "rem") then
          return Tok_Rem;
        elsif matches_word (spelling, "abs") then
          return Tok_Abs;
        elsif matches_word (spelling, "not") then
          return Tok_Not;
        else
          return Tok_Unknown;
        end if;

      when others =>
        return Tok_Unknown;
    end case;
  end operator_kind;

  function is_logical_operator (kind : Token_Kind) return Boolean is
  begin
    return kind = Tok_And or else kind = Tok_Or or else kind = Tok_Xor;
  end is_logical_operator;

  function is_relational_operator (kind : Token_Kind) return Boolean is
  begin
    case kind is
      when Tok_Equal |
           Tok_Not_Equal |
           Tok_Less_Than |
           Tok_Less_Than_Or_Equal |
           Tok_Greater_Than |
           Tok_Greater_Than_Or_Equal =>
        return True;

      when others =>
        return False;
    end case;
  end is_relational_operator;

  function is_binary_adding_operator (kind : Token_Kind) return Boolean is
  begin
    return kind = Tok_Plus or else
      kind = Tok_Minus or else
      kind = Tok_Ampersand;
  end is_binary_adding_operator;

  function is_unary_adding_operator (kind : Token_Kind) return Boolean is
  begin
    return kind = Tok_Plus or else kind = Tok_Minus;
  end is_unary_adding_operator;

  function is_multiplying_operator (kind : Token_Kind) return Boolean is
  begin
    return kind = Tok_Asterisk or else
      kind = Tok_Slash or else
      kind = Tok_Mod or else
      kind = Tok_Rem;
  end is_multiplying_operator;

  function is_operator (kind : Token_Kind) return Boolean is
  begin
    return is_logical_operator (kind) or else
      is_relational_operator (kind) or else
      is_binary_adding_operator (kind) or else
      is_multiplying_operator (kind) or else
      kind = Tok_Double_Star or else
      kind = Tok_Abs or else
      kind = Tok_Not;
  end is_operator;

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
