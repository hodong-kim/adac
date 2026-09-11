-- ============================================================================
-- adac-symbols.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;
with Ada.Containers;

with Adac.Resources;

package body Adac.Symbols is

  use type Ada.Containers.Count_Type;

  procedure validate_store (self : Store) is
  begin
    if not self.initialized then
      raise Program_Error with "Adac.Symbols: store is not initialized";
    end if;
  end validate_store;

  function canonical_spelling
    (self     : Store;
     spelling : String)
  return String is
  begin
    if self.case_sensitive_identifiers then
      return spelling;
    end if;

    return Ada.Characters.Handling.To_Lower (spelling);
  end canonical_spelling;

  function create
    (case_sensitive_identifiers : Boolean)
  return Store is
  begin
    return result : Store do
      result.initialized := True;
      result.case_sensitive_identifiers := case_sensitive_identifiers;
    end return;
  end create;

  procedure validate (symbol : Symbol_ID) is
  begin
    if symbol.owner = null or else symbol.index = 0 then
      raise Program_Error with "Adac.Symbols: invalid symbol identifier";
    end if;
  end validate;

  procedure validate
    (self   : Store;
     symbol : Symbol_ID)
  is
  begin
    validate_store (self);
    validate (symbol);

    if symbol.owner /= self.marker'Unchecked_Access then
      raise Program_Error with
        "Adac.Symbols: symbol belongs to another store";
    end if;

    if symbol.index > Natural(self.spellings.length) then
      raise Program_Error with "Adac.Symbols: symbol is out of range";
    end if;
  end validate;

  function intern
    (self            : in out Store;
     spelling        : String;
     maximum_symbols : Natural := Natural'Last)
  return Symbol_ID is
  begin
    validate_store (self);

    if spelling'length = 0 then
      raise Program_Error with "Adac.Symbols: empty symbol spelling";
    end if;

    declare
      key    : constant String := canonical_spelling (self, spelling);
      cursor : constant Symbol_Maps.Cursor := self.symbols.find (key);
      symbol : Symbol_ID;
    begin
      if Symbol_Maps.has_element (cursor) then
        return Symbol_Maps.element (cursor);
      end if;

      if self.spellings.length >= Ada.Containers.Count_Type(Positive'Last) then
        raise Storage_Error with "Adac.Symbols: symbol capacity exhausted";
      end if;

      if Natural(self.spellings.length) >= maximum_symbols then
        raise Adac.Resources.Limit_Exceeded with
          "Adac.Symbols: symbol limit exceeded";
      end if;

      symbol :=
        (owner => self.marker'Unchecked_Access,
         index => Natural(self.spellings.length) + 1);

      self.spellings.append
        (Ada.Strings.Unbounded.to_unbounded_string (spelling));

      begin
        self.symbols.insert (key, symbol);
      exception
        when others =>
          self.spellings.delete_last;
          raise;
      end;

      return symbol;
    end;
  end intern;

  function find
    (self     : Store;
     spelling : String)
  return Symbol_ID is
  begin
    validate_store (self);

    if spelling'length = 0 then
      raise Program_Error with "Adac.Symbols: empty symbol spelling";
    end if;

    declare
      key    : constant String := canonical_spelling (self, spelling);
      cursor : constant Symbol_Maps.Cursor := self.symbols.find (key);
    begin
      if Symbol_Maps.has_element (cursor) then
        return Symbol_Maps.element (cursor);
      end if;

      return INVALID_SYMBOL_ID;
    end;
  end find;

  function spelling
    (self   : Store;
     symbol : Symbol_ID)
  return String is
  begin
    validate (self, symbol);
    return Ada.Strings.Unbounded.to_string
      (self.spellings(Positive(symbol.index)));
  end spelling;

  function ordinal
    (self   : Store;
     symbol : Symbol_ID)
  return Positive is
  begin
    validate (self, symbol);
    return Positive (symbol.index);
  end ordinal;

  function symbol_count (self : Store) return Natural is
  begin
    validate_store (self);
    return Natural(self.spellings.length);
  end symbol_count;

end Adac.Symbols;
