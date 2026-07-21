-- ============================================================================
-- adac-semantics.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers;

package body Adac.Semantics is

  use type Ada.Containers.Count_Type;

  procedure validate_store (self : Store) is
  begin
    if not self.initialized then
      raise Program_Error with "Adac.Semantics: store is not initialized";
    end if;
  end validate_store;

  procedure validate_entity_id
    (self   : Store;
     entity : Entity_ID)
  is
  begin
    validate_store (self);
    validate (entity);

    if entity.owner /= self.marker'Unchecked_Access then
      raise Program_Error with
        "Adac.Semantics: entity belongs to another store";
    end if;

    if entity.index > Natural(self.entities.length) then
      raise Program_Error with
        "Adac.Semantics: entity identifier is out of range";
    end if;
  end validate_entity_id;

  function next_entity_id (self : Store) return Entity_ID is
  begin
    if self.entities.length >= Ada.Containers.Count_Type(Positive'Last) then
      raise Storage_Error with "Adac.Semantics: entity capacity exhausted";
    end if;

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.entities.length) + 1);
  end next_entity_id;

  function create return Store is
  begin
    return result : Store do
      result.initialized := True;
    end return;
  end create;

  function append_procedure
    (self        : in out Store;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span)
  return Entity_ID is
    result : Entity_ID;
  begin
    validate_store (self);
    Adac.AST.validate (declaration);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (span);

    result := next_entity_id (self);
    self.entities.append
      (Entity_Record'(kind        => Procedure_Body_Entity,
                      declaration => declaration,
                      symbol      => symbol,
                      span        => span));
    return result;
  end append_procedure;

  function entity_count (self : Store) return Natural is
  begin
    validate_store (self);
    return Natural(self.entities.length);
  end entity_count;

  function kind_of
    (self   : Store;
     entity : Entity_ID)
  return Entity_Kind is
  begin
    validate_entity_id (self, entity);
    return self.entities(Positive(entity.index)).kind;
  end kind_of;

  function declaration
    (self   : Store;
     entity : Entity_ID)
  return Adac.AST.Node_ID is
  begin
    validate_entity_id (self, entity);
    return self.entities(Positive(entity.index)).declaration;
  end declaration;

  function symbol
    (self   : Store;
     entity : Entity_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    validate_entity_id (self, entity);
    return self.entities(Positive(entity.index)).symbol;
  end symbol;

  function entity_span
    (self   : Store;
     entity : Entity_ID)
  return Adac.Source.Span is
  begin
    validate_entity_id (self, entity);
    return self.entities(Positive(entity.index)).span;
  end entity_span;

  procedure validate (entity : Entity_ID) is
  begin
    if entity.owner = null or else entity.index = 0 then
      raise Program_Error with "Adac.Semantics: invalid entity identifier";
    end if;
  end validate;

  procedure validate
    (self   : Store;
     entity : Entity_ID)
  is
  begin
    validate_entity_id (self, entity);

    declare
      value : Entity_Record renames self.entities(Positive(entity.index));
    begin
      Adac.AST.validate (value.declaration);
      Adac.Symbols.validate (value.symbol);
      Adac.Source.validate (value.span);
    end;
  end validate;

end Adac.Semantics;
