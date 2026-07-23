-- ============================================================================
-- adac-frontend-parser.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Compilation.Diagnostics;
with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;
with Adac.Frontend.Lexer;
with Adac.Frontend.Tokens;
with Adac.Resources;
with Adac.Source;
with Adac.Symbols;

package body Adac.Frontend.Parser is

  use Adac.Frontend.Tokens;

  type Parser is limited record
    scanner : Adac.Frontend.Lexer.Scanner;
    current : Token;
    procedure_symbol : Adac.Symbols.Symbol_ID :=
      Adac.Symbols.INVALID_SYMBOL_ID;
    statements : Adac.AST.Node_List;
    end_symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    unit_span  : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    failed  : Boolean := False;
  end record;

  procedure advance
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    self.current := Adac.Frontend.Lexer.next_token (self.scanner);
  exception
    when Adac.Resources.Limit_Exceeded =>
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, "source character limit exceeded");
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

    advance (self, context);
  end expect;

  function current_text (self : Parser) return String is
  begin
    return Ada.Strings.Unbounded.to_string (self.current.text);
  end current_text;

  function parse_identifier_symbol
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  return Adac.Symbols.Symbol_ID
  is
  begin
    if self.failed then
      return Adac.Symbols.INVALID_SYMBOL_ID;
    end if;

    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return Adac.Symbols.INVALID_SYMBOL_ID;
    end if;

    declare
      position : constant Adac.Source.Position := self.current.position;
      spelling : constant String := current_text (self);
      symbol   : Adac.Symbols.Symbol_ID;
    begin
      begin
        symbol := Adac.Compilation.Symbols.intern (context, spelling);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, position, "symbol limit exceeded");
          return Adac.Symbols.INVALID_SYMBOL_ID;
      end;

      advance (self, context);
      return symbol;
    end;
  end parse_identifier_symbol;

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
    first          : constant Adac.Source.Position := self.current.position;
    last           : Adac.Source.Position;
    statement_kind : Adac.AST.Node_Kind := Adac.AST.Null_Statement_Node;
  begin
    case self.current.kind is
      when Tok_Null =>
        statement_kind := Adac.AST.Null_Statement_Node;
        expect (self, context, Tok_Null);

      when Tok_Return =>
        statement_kind := Adac.AST.Return_Statement_Node;
        expect (self, context, Tok_Return);

      when others =>
        report_expected (self, context, Tok_Null);
        return;
    end case;

    if self.failed then
      return;
    end if;

    last := self.current.position;
    expect (self, context, Tok_Semicolon);

    if not self.failed then
      begin
        Adac.AST.append
          (self.statements,
           Adac.Compilation.Syntax.create_statement
             (context,
              statement_kind,
              Adac.Source.make_span (first, last)));
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, first, "AST node limit exceeded");
      end;
    end if;
  end parse_statement;

  procedure parse_statement_sequence
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    if self.failed then
      return;
    end if;

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
    first : constant Adac.Source.Position := self.current.position;
    last  : Adac.Source.Position;
  begin
    expect (self, context, Tok_Procedure);

    self.procedure_symbol := parse_identifier_symbol (self, context);
    expect (self, context, Tok_Is);
    expect (self, context, Tok_Begin);
    parse_statement_sequence (self, context);
    expect (self, context, Tok_End);

    self.end_symbol := parse_identifier_symbol (self, context);

    if not self.failed then
      last := self.current.position;
    end if;

    expect (self, context, Tok_Semicolon);

    if not self.failed then
      self.unit_span := Adac.Source.make_span (first, last);
    end if;

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
    Adac.Frontend.Lexer.open
      (self.scanner,
       path,
       file_id,
       Adac.Compilation.resource_limits
         (context).maximum_source_characters_per_file);
    advance (self, context);

    parse_compilation_unit (self, context);

    Adac.Frontend.Lexer.close (self.scanner);

    if self.failed then
      return (status => Adac.Frontend.Parse_Rejected);
    end if;

    begin
      declare
        root : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_compilation_unit
            (context,
             self.procedure_symbol,
             self.statements,
             self.end_symbol,
             self.unit_span);
      begin
        Adac.Compilation.Syntax.validate (context, root);
        return (status => Adac.Frontend.Parse_Succeeded,
                root   => root);
      end;
    exception
      when Adac.Resources.Limit_Exceeded =>
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position (self.unit_span),
           "AST node limit exceeded");
        return (status => Adac.Frontend.Parse_Rejected);
    end;
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
