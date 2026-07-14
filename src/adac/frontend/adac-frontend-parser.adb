-- ============================================================================
-- adac-frontend-parser.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Frontend.Lexer;
with Adac.Frontend.Tokens;
with Adac.Diagnostics;

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

  procedure report_expected (self     : in out Parser;
                             expected : Token_Kind)
  is
    text : constant String :=
      Ada.Strings.Unbounded.to_string (self.current.text);
  begin
    self.failed := True;

    Adac.Diagnostics.error (self.current.position,
                            "expected "
                            & Token_Kind'image (expected)
                            & ", got "
                            & Token_Kind'image (self.current.kind)
                            & " "
                            & text);
  end report_expected;

  procedure expect (self : in out Parser;
                    kind : Token_Kind)
  is
  begin
    if self.failed then
      return;
    end if;

    if self.current.kind /= kind then
      report_expected (self, kind);
      return;
    end if;

    advance (self);
  end expect;

  function current_text (self : Parser) return String is
  begin
    return Ada.Strings.Unbounded.to_string (self.current.text);
  end current_text;

  procedure parse_statement (self : in out Parser) is
  begin
    expect (self, Tok_Null);

    if not self.failed then
      self.unit.statements.append
        (Adac.AST.Statement'(kind => Adac.AST.Null_Statement));
    end if;

    expect (self, Tok_Semicolon);
  end parse_statement;

  procedure parse_statement_sequence (self : in out Parser) is
  begin
    if self.current.kind /= Tok_Null then
      report_expected (self, Tok_Null);
      return;
    end if;

    while not self.failed and then self.current.kind = Tok_Null loop
      parse_statement (self);
    end loop;
  end parse_statement_sequence;

  procedure parse_compilation_unit (self : in out Parser) is
  begin
    expect (self, Tok_Procedure);

    if not self.failed then
      self.unit.procedure_name :=
        Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    end if;

    expect (self, Tok_Identifier);
    expect (self, Tok_Is);
    expect (self, Tok_Begin);
    parse_statement_sequence (self);
    expect (self, Tok_End);

    if not self.failed then
      self.unit.end_name :=
        Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    end if;

    expect (self, Tok_Identifier);
    expect (self, Tok_Semicolon);
    expect (self, Tok_EOF);
  end parse_compilation_unit;

  function parse_file (path : String) return Adac.Frontend.Parse_Result is
    self : Parser;
  begin
    Adac.Frontend.Lexer.open (self.scanner, path);
    advance (self);

    parse_compilation_unit (self);

    Adac.Frontend.Lexer.close (self.scanner);
    return (ok   => not self.failed,
            unit => self.unit);
  end parse_file;

end Adac.Frontend.Parser;
