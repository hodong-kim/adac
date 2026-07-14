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
      Ada