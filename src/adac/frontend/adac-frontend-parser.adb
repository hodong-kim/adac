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
    scanner : Adac.Frontend.L