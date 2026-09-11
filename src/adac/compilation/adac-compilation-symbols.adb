-- ============================================================================
-- adac-compilation-symbols.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.Compilation.Symbols is

  function intern
    (self     : in out Context;
     spelling : String)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Symbols.intern
      (self.symbol_store,
       spelling,
       self.limits.maximum_symbols);
  end intern;

  function find
    (self     : Context;
     spelling : String)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Symbols.find (self.symbol_store, spelling);
  end find;

  function spelling
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.Symbols.spelling (self.symbol_store, symbol);
  end spelling;

  function symbol_count (self : Context) return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Symbols.symbol_count (self.symbol_store);
  end symbol_count;

  procedure validate_symbol
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.Symbols.validate (self.symbol_store, symbol);
  end validate_symbol;

end Adac.Compilation.Symbols;
