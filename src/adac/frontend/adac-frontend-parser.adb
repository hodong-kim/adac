-- ============================================================================
-- adac-frontend-parser.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Compilation.Diagnostics;
with Adac.Compilation.Sources;
with Adac.Frontend.Lexer;
with Adac.Frontend.Tokens;
with Adac.Source;

package body Adac.Frontend.Parser is

  use Adac.Frontend.Tokens;

  type Parser is limited record
    scanner : Adac.Frontend.Lexer.Scanner;
    current : Token;
    unit    : Adac.AST.Compilation_Unit;
    failed  : Boolean := False;
  end record;

  procedure advance (self : in out Parser) is
  begin
    self.current := Adac.Frontend.Lexer.next_token (self.scanner);
  end advance;

  procedure report_expected
    (self     : in out Parser;
     context  : in out Adac.Compilation.Context;
     expected : Token_Kind)
  is
    text : constant String :=
      Ada.Strings.Unbounded.to_string (self.current.text);
  begin
    self.failed := True;

    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "expected " &
       Token_Kind'image (expected) &
       ", got " &
       Token_Kind'image (self.current.kind) &
       " " &
       text);
  end report_expected;

  procedure expect
    (self    : in out Parser;
     context : in out Adac.Compilation.Context;
     kind    : Token_Kind)
  is
  begin
    if self.failed then
      return;
    end if;

    if self.current.kind /= kind then
      report_expected (self, context, kind);
      return;
    end if;

    advance (self);
  end expect;

  function current_text (self : Parser) return String is
  begin
    return Ada.Strings.Unbounded.to_string (self.current.text);
  end current_text;

  function starts_statement (kind : Token_Kind) return Boolean is
  begin
    case kind is
      when Tok_Null | Tok_Return =>
        return True;

      when others =>
        return False;
    end case;
  end starts_statement;

  procedure parse_statement
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    case self.current.kind is
      when Tok_Null =>
        expect (self, context, Tok_Null);

        if not self.failed then
          self.unit.statements.append
            (Adac.AST.Statement'(kind => Adac.AST.Null_Statement));
        end if;

      when Tok_Return =>
        expect (self, context, Tok_Return);

        if not self.failed then
          self.unit.statements.append
            (Adac.AST.Statement'(kind => Adac.AST.Return_Statement));
        end if;

      when others =>
        report_expected (self, context, Tok_Null);
        return;
    end case;

    expect (self, context, Tok_Semicolon);
  end parse_statement;

  procedure parse_statement_sequence
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    if not starts_statement (self.current.kind) then
      report_expected (self, context, Tok_Null);
      return;
    end if;

    while not self.failed and then starts_statement (self.current.kind) loop
      parse_statement (self, context);
    end loop;
  end parse_statement_sequence;

  procedure parse_compilation_unit
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    expect (self, context, Tok_Procedure);

    if not self.failed then
      self.unit.procedure_name :=
        Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    end if;

    expect (self, context, Tok_Identifier);
    expect (self, context, Tok_Is);
    expect (self, context, Tok_Begin);
    parse_statement_sequence (self, context);
    expect (self, context, Tok_End);

    if not self.failed then
      self.unit.end_name :=
        Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    end if;

    expect (self, context, Tok_Identifier);
    expect (self, context, Tok_Semicolon);
    expect (self, context, Tok_EOF);
  end parse_compilation_unit;

  function parse_file
    (context : in out Adac.Compilation.Context;
     path    : String)
  return Adac.Frontend.Parse_Result is
    self    : Parser;
    file_id : constant Adac.Source.Source_File_ID
            := Adac.Compilation.Sources.register_file (context, path);
  begin
    Adac.Frontend.Lexer.open (self.scanner, path, file_id);
    advance (self);

    parse_compilation_unit (self, context);

    Adac.Frontend.Lexer.close (self.scanner);

    if self.failed then
      return (status => Adac.Frontend.Parse_Rejected);
    end if;

    Adac.AST.validate (self.unit);
    return (status => Adac.Frontend.Parse_Succeeded,
            unit   => self.unit);
  exception
    when others =>
      begin
        Adac.Frontend.Lexer.close (self.scanner);
      exception
        when others =>
          null;
      end;

      raise;
  end parse_file;

end Adac.Frontend.Parser;
