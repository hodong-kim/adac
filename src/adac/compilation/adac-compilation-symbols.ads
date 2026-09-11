-- ============================================================================
-- adac-compilation-symbols.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Symbols;

package Adac.Compilation.Symbols is

  --! summary: Intern one identifier spelling in this compilation context.
  function intern
    (self     : in out Context;
     spelling : String)
  return Adac.Symbols.Symbol_ID;

  --! summary: Find an existing symbol without changing this context.
  function find
    (self     : Context;
     spelling : String)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the first spelling stored for a context-owned symbol.
  function spelling
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return String;

  --! summary: Return the number of symbols interned by this context.
  function symbol_count (self : Context) return Natural;

  --! summary: Validate a symbol owned by this compilation context.
  procedure validate_symbol
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID);

end Adac.Compilation.Symbols;
