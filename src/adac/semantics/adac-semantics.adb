-- ============================================================================
-- adac-semantics.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers;

package body Adac.Semantics is

  use type Ada.Containers.Count_Type;
  use type Adac.AST.Node_ID;
  use type Adac.Symbols.Symbol_ID;
  use type Adac.Types.Type_ID;
  use type Adac.Types.Boolean_Value;
  use type Adac.Types.Universal_Integer_Value;
  use type Adac.Types.Universal_Real_Value;

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

    if entity.owner /= self.marker'unchecked_access then
      raise Program_Error with
        "Adac.Semantics: entity belongs to another store";
    end if;

    if entity.index > Natural (self.entities.length) then
      raise Program_Error with
        "Adac.Semantics: entity identifier is out of range";
    end if;
  end validate_entity_id;

  procedure require_kind
    (self     : Store;
     entity   : Entity_ID;
     expected : Entity_Kind)
  is
  begin
    validate_entity_id (self, entity);

    if self.entities (Positive (entity.index)).kind /= expected then
      raise Program_Error with "Adac.Semantics: unexpected entity kind";
    end if;
  end require_kind;

  function is_integer_assignment_kind
    (kind : Procedure_Statement_Kind)
  return Boolean is
  begin
    return kind = Local_Integer_Static_Assignment_Statement or else
      kind = Local_Integer_Copy_Assignment_Statement;
  end is_integer_assignment_kind;

  function is_boolean_assignment_kind
    (kind : Procedure_Statement_Kind)
  return Boolean is
  begin
    return kind = Local_Boolean_Static_Assignment_Statement or else
      kind = Local_Boolean_Copy_Assignment_Statement or else
      kind = Local_Boolean_Not_Assignment_Statement or else
      kind = Local_Boolean_Binary_Assignment_Statement or else
      kind = Local_Boolean_And_Then_Assignment_Statement or else
      kind = Local_Boolean_Or_Else_Assignment_Statement or else
      kind = Local_Boolean_Expression_Assignment_Statement;
  end is_boolean_assignment_kind;

  function is_copy_assignment_kind
    (kind : Procedure_Statement_Kind)
  return Boolean is
  begin
    return kind = Local_Integer_Copy_Assignment_Statement or else
      kind = Local_Boolean_Copy_Assignment_Statement;
  end is_copy_assignment_kind;

  function is_source_reading_assignment_kind
    (kind : Procedure_Statement_Kind)
  return Boolean is
  begin
    return is_copy_assignment_kind (kind) or else
      kind = Local_Boolean_Not_Assignment_Statement or else
      kind = Local_Boolean_Binary_Assignment_Statement or else
      kind = Local_Boolean_And_Then_Assignment_Statement or else
      kind = Local_Boolean_Or_Else_Assignment_Statement;
  end is_source_reading_assignment_kind;

  function boolean_not_value
    (value : Adac.Types.Boolean_Value)
  return Adac.Types.Boolean_Value is
  begin
    case value is
      when Adac.Types.False_Boolean_Value =>
        return Adac.Types.True_Boolean_Value;
      when Adac.Types.True_Boolean_Value =>
        return Adac.Types.False_Boolean_Value;
    end case;
  end boolean_not_value;

  function boolean_binary_value
    (operator_kind : Boolean_Binary_Operator_Kind;
     left          : Adac.Types.Boolean_Value;
     right         : Adac.Types.Boolean_Value)
  return Adac.Types.Boolean_Value is
    left_true : constant Boolean := left = Adac.Types.True_Boolean_Value;
    right_true : constant Boolean := right = Adac.Types.True_Boolean_Value;
    result : Boolean;
  begin
    case operator_kind is
      when No_Boolean_Binary_Operator =>
        raise Program_Error with
          "Adac.Semantics: missing Boolean binary operator";
      when And_Boolean_Binary_Operator =>
        result := left_true and right_true;
      when Or_Boolean_Binary_Operator =>
        result := left_true or right_true;
      when Xor_Boolean_Binary_Operator =>
        result := left_true xor right_true;
      when Equal_Boolean_Binary_Operator =>
        result := left_true = right_true;
      when Not_Equal_Boolean_Binary_Operator =>
        result := left_true /= right_true;
      when Less_Boolean_Binary_Operator =>
        result := (not left_true) and right_true;
      when Less_Equal_Boolean_Binary_Operator =>
        result := (not left_true) or right_true;
      when Greater_Boolean_Binary_Operator =>
        result := left_true and (not right_true);
      when Greater_Equal_Boolean_Binary_Operator =>
        result := left_true or (not right_true);
    end case;
    return
      (if result then
         Adac.Types.True_Boolean_Value
       else
         Adac.Types.False_Boolean_Value);
  end boolean_binary_value;

  function boolean_short_circuit_value
    (kind        : Procedure_Statement_Kind;
     left_value  : Adac.Types.Boolean_Value;
     right_value : Adac.Types.Boolean_Value)
  return Adac.Types.Boolean_Value is
  begin
    case kind is
      when Local_Boolean_And_Then_Assignment_Statement =>
        return boolean_binary_value
          (And_Boolean_Binary_Operator, left_value, right_value);
      when Local_Boolean_Or_Else_Assignment_Statement =>
        return boolean_binary_value
          (Or_Boolean_Binary_Operator, left_value, right_value);
      when others =>
        raise Program_Error with
          "Adac.Semantics: statement is not a Boolean short circuit";
    end case;
  end boolean_short_circuit_value;

  function is_assignment_kind
    (kind : Procedure_Statement_Kind)
  return Boolean is
  begin
    return is_integer_assignment_kind (kind) or else
      is_boolean_assignment_kind (kind);
  end is_assignment_kind;

  function procedure_scope_key_less
    (left  : Procedure_Scope_Lookup_Key;
     right : Procedure_Scope_Lookup_Key)
  return Boolean is
  begin
    return left.procedure_entity_index < right.procedure_entity_index or else
      (left.procedure_entity_index = right.procedure_entity_index and then
       left.symbol_ordinal < right.symbol_ordinal);
  end procedure_scope_key_less;

  function make_signed_integer_range_constraint
    (lower_bound : Long_Long_Integer;
     upper_bound : Long_Long_Integer)
  return Subtype_Constraint is
  begin
    return
      (kind        => Signed_Integer_Range_Constraint,
       lower_bound => lower_bound,
       upper_bound => upper_bound);
  end make_signed_integer_range_constraint;

  function subtype_constraint_category
    (constraint : Subtype_Constraint)
  return Subtype_Constraint_Kind is
  begin
    validate (constraint);
    return constraint.kind;
  end subtype_constraint_category;

  function subtype_constraint_lower_bound
    (constraint : Subtype_Constraint)
  return Long_Long_Integer is
  begin
    validate (constraint);
    if constraint.kind /= Signed_Integer_Range_Constraint then
      raise Program_Error with
        "Adac.Semantics: subtype constraint has no integer range";
    end if;
    return constraint.lower_bound;
  end subtype_constraint_lower_bound;

  function subtype_constraint_upper_bound
    (constraint : Subtype_Constraint)
  return Long_Long_Integer is
  begin
    validate (constraint);
    if constraint.kind /= Signed_Integer_Range_Constraint then
      raise Program_Error with
        "Adac.Semantics: subtype constraint has no integer range";
    end if;
    return constraint.upper_bound;
  end subtype_constraint_upper_bound;

  function subtype_constraint_contains
    (constraint : Subtype_Constraint;
     value      : Long_Long_Integer)
  return Boolean is
  begin
    validate (constraint);
    case constraint.kind is
      when No_Constraint =>
        return True;

      when Signed_Integer_Range_Constraint =>
        return value >= constraint.lower_bound and then
          value <= constraint.upper_bound;
    end case;
  end subtype_constraint_contains;

  procedure validate (constraint : Subtype_Constraint) is
  begin
    case constraint.kind is
      when No_Constraint =>
        if constraint.lower_bound /= 0 or else constraint.upper_bound /= 0 then
          raise Program_Error with
            "Adac.Semantics: null subtype constraint has range metadata";
        end if;

      when Signed_Integer_Range_Constraint =>
        null;
    end case;
  end validate;

  function next_entity_id (self : Store) return Entity_ID is
  begin
    if self.entities.length >= Ada.Containers.Count_Type (Positive'Last) then
      raise Storage_Error with "Adac.Semantics: entity capacity exhausted";
    end if;

    return (owner => self.marker'unchecked_access,
            index => Natural (self.entities.length) + 1);
  end next_entity_id;

  procedure try_bind_local_object
    (self     : in out Lexical_Scope;
     symbols  : Adac.Symbols.Store;
     symbol   : Adac.Symbols.Symbol_ID;
     local    : Positive;
     inserted : out Boolean)
  is
    symbol_ordinal : Positive;
    binding_index  : Positive;
  begin
    Adac.Symbols.validate (symbols, symbol);

    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    symbol_ordinal := Adac.Symbols.ordinal (symbols, symbol);
    if self.lookup.contains (symbol_ordinal) then
      inserted := False;
      return;
    end if;

    if self.bindings.length >= Ada.Containers.Count_Type (Positive'Last) then
      raise Storage_Error with
        "Adac.Semantics: lexical scope capacity exhausted";
    end if;

    if local /= self.local_object_count + 1 then
      raise Program_Error with
        "Adac.Semantics: local object binding is not in source order";
    end if;

    binding_index := Positive (Natural (self.bindings.length) + 1);
    self.lookup.insert (symbol_ordinal, binding_index);
    begin
      self.bindings.append
        (Scope_Binding_Record'
           (kind                => Local_Object_Binding,
            symbol              => symbol,
            symbol_ordinal      => Natural (symbol_ordinal),
            local_ordinal       => local,
            subtype_declaration  => Adac.AST.INVALID_NODE_ID,
            static_constant_declaration => Adac.AST.INVALID_NODE_ID,
            number_declaration   => Adac.AST.INVALID_NODE_ID,
            semantic_type        => Adac.Types.INVALID_TYPE_ID,
            constraint_value     => NO_SUBTYPE_CONSTRAINT,
            static_constant_value => 0,
            static_boolean_constant_value =>
              Adac.Types.False_Boolean_Value,
            integer_number_value =>
              Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
            real_number_value => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE));
    exception
      when others =>
        self.lookup.delete (symbol_ordinal);
        raise;
    end;

    self.local_object_count := self.local_object_count + 1;
    inserted := True;
  end try_bind_local_object;

  procedure try_bind_local_subtype
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Subtype_Constraint;
     inserted      : out Boolean)
  is
    symbol_ordinal : Positive;
    binding_index  : Positive;
  begin
    Adac.Symbols.validate (symbols, symbol);
    Adac.AST.validate (declaration);
    Adac.Types.validate (semantic_type);
    validate (constraint);

    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    symbol_ordinal := Adac.Symbols.ordinal (symbols, symbol);
    if self.lookup.contains (symbol_ordinal) then
      inserted := False;
      return;
    end if;

    if self.bindings.length >= Ada.Containers.Count_Type (Positive'Last) then
      raise Storage_Error with
        "Adac.Semantics: lexical scope capacity exhausted";
    end if;

    binding_index := Positive (Natural (self.bindings.length) + 1);
    self.lookup.insert (symbol_ordinal, binding_index);
    begin
      self.bindings.append
        (Scope_Binding_Record'
           (kind                => Local_Subtype_Binding,
            symbol              => symbol,
            symbol_ordinal      => Natural (symbol_ordinal),
            local_ordinal       => 0,
            subtype_declaration  => declaration,
            static_constant_declaration => Adac.AST.INVALID_NODE_ID,
            number_declaration   => Adac.AST.INVALID_NODE_ID,
            semantic_type        => semantic_type,
            constraint_value     => constraint,
            static_constant_value => 0,
            static_boolean_constant_value =>
              Adac.Types.False_Boolean_Value,
            integer_number_value =>
              Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
            real_number_value => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE));
    exception
      when others =>
        self.lookup.delete (symbol_ordinal);
        raise;
    end;

    inserted := True;
  end try_bind_local_subtype;

  procedure try_bind_local_static_integer_constant
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Subtype_Constraint;
     value         : Long_Long_Integer;
     inserted      : out Boolean)
  is
    symbol_ordinal : Positive;
    binding_index  : Positive;
  begin
    Adac.Symbols.validate (symbols, symbol);
    Adac.AST.validate (declaration);
    Adac.Types.validate (semantic_type);
    validate (constraint);
    if not subtype_constraint_contains (constraint, value) then
      raise Program_Error with
        "Adac.Semantics: static constant violates nominal constraint";
    end if;

    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    symbol_ordinal := Adac.Symbols.ordinal (symbols, symbol);
    if self.lookup.contains (symbol_ordinal) then
      inserted := False;
      return;
    end if;

    if self.bindings.length >= Ada.Containers.Count_Type (Positive'Last) then
      raise Storage_Error with
        "Adac.Semantics: lexical scope capacity exhausted";
    end if;

    binding_index := Positive (Natural (self.bindings.length) + 1);
    self.lookup.insert (symbol_ordinal, binding_index);
    begin
      self.bindings.append
        (Scope_Binding_Record'
           (kind                => Local_Static_Integer_Constant_Binding,
            symbol              => symbol,
            symbol_ordinal      => Natural (symbol_ordinal),
            local_ordinal       => 0,
            subtype_declaration => Adac.AST.INVALID_NODE_ID,
            static_constant_declaration => declaration,
            number_declaration  => Adac.AST.INVALID_NODE_ID,
            semantic_type       => semantic_type,
            constraint_value    => constraint,
            static_constant_value => value,
            static_boolean_constant_value =>
              Adac.Types.False_Boolean_Value,
            integer_number_value =>
              Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
            real_number_value => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE));
    exception
      when others =>
        self.lookup.delete (symbol_ordinal);
        raise;
    end;

    inserted := True;
  end try_bind_local_static_integer_constant;

  procedure try_bind_local_static_boolean_constant
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Boolean_Value;
     inserted      : out Boolean)
  is
    symbol_ordinal : Positive;
    binding_index  : Positive;
  begin
    Adac.Symbols.validate (symbols, symbol);
    Adac.AST.validate (declaration);
    Adac.Types.validate (semantic_type);

    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    symbol_ordinal := Adac.Symbols.ordinal (symbols, symbol);
    if self.lookup.contains (symbol_ordinal) then
      inserted := False;
      return;
    end if;

    if self.bindings.length >= Ada.Containers.Count_Type (Positive'Last) then
      raise Storage_Error with
        "Adac.Semantics: lexical scope capacity exhausted";
    end if;

    binding_index := Positive (Natural (self.bindings.length) + 1);
    self.lookup.insert (symbol_ordinal, binding_index);
    begin
      self.bindings.append
        (Scope_Binding_Record'
           (kind                => Local_Static_Boolean_Constant_Binding,
            symbol              => symbol,
            symbol_ordinal      => Natural (symbol_ordinal),
            local_ordinal       => 0,
            subtype_declaration => Adac.AST.INVALID_NODE_ID,
            static_constant_declaration => declaration,
            number_declaration  => Adac.AST.INVALID_NODE_ID,
            semantic_type       => semantic_type,
            constraint_value    => NO_SUBTYPE_CONSTRAINT,
            static_constant_value => 0,
            static_boolean_constant_value => value,
            integer_number_value =>
              Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
            real_number_value => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE));
    exception
      when others =>
        self.lookup.delete (symbol_ordinal);
        raise;
    end;

    inserted := True;
  end try_bind_local_static_boolean_constant;

  procedure try_bind_local_integer_number
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Integer_Value;
     inserted      : out Boolean)
  is
    symbol_ordinal : Positive;
    binding_index  : Positive;
  begin
    Adac.Symbols.validate (symbols, symbol);
    Adac.AST.validate (declaration);
    Adac.Types.validate (semantic_type);
    Adac.Types.validate (value);

    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    symbol_ordinal := Adac.Symbols.ordinal (symbols, symbol);
    if self.lookup.contains (symbol_ordinal) then
      inserted := False;
      return;
    end if;

    if self.bindings.length >= Ada.Containers.Count_Type (Positive'Last) then
      raise Storage_Error with
        "Adac.Semantics: lexical scope capacity exhausted";
    end if;

    binding_index := Positive (Natural (self.bindings.length) + 1);
    self.lookup.insert (symbol_ordinal, binding_index);
    begin
      self.bindings.append
        (Scope_Binding_Record'
           (kind                => Local_Integer_Number_Binding,
            symbol              => symbol,
            symbol_ordinal      => Natural (symbol_ordinal),
            local_ordinal       => 0,
            subtype_declaration => Adac.AST.INVALID_NODE_ID,
            static_constant_declaration => Adac.AST.INVALID_NODE_ID,
            number_declaration  => declaration,
            semantic_type       => semantic_type,
            constraint_value    => NO_SUBTYPE_CONSTRAINT,
            static_constant_value => 0,
            static_boolean_constant_value =>
              Adac.Types.False_Boolean_Value,
            integer_number_value => value,
            real_number_value => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE));
    exception
      when others =>
        self.lookup.delete (symbol_ordinal);
        raise;
    end;

    inserted := True;
  end try_bind_local_integer_number;

  procedure try_bind_local_real_number
    (self          : in out Lexical_Scope;
     symbols       : Adac.Symbols.Store;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Real_Value;
     inserted      : out Boolean)
  is
    symbol_ordinal : Positive;
    binding_index  : Positive;
  begin
    Adac.Symbols.validate (symbols, symbol);
    Adac.AST.validate (declaration);
    Adac.Types.validate (semantic_type);
    Adac.Types.validate (value);

    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    symbol_ordinal := Adac.Symbols.ordinal (symbols, symbol);
    if self.lookup.contains (symbol_ordinal) then
      inserted := False;
      return;
    end if;

    if self.bindings.length >= Ada.Containers.Count_Type (Positive'Last) then
      raise Storage_Error with
        "Adac.Semantics: lexical scope capacity exhausted";
    end if;

    binding_index := Positive (Natural (self.bindings.length) + 1);
    self.lookup.insert (symbol_ordinal, binding_index);
    begin
      self.bindings.append
        (Scope_Binding_Record'
           (kind                => Local_Real_Number_Binding,
            symbol              => symbol,
            symbol_ordinal      => Natural (symbol_ordinal),
            local_ordinal       => 0,
            subtype_declaration => Adac.AST.INVALID_NODE_ID,
            static_constant_declaration => Adac.AST.INVALID_NODE_ID,
            number_declaration  => declaration,
            semantic_type       => semantic_type,
            constraint_value    => NO_SUBTYPE_CONSTRAINT,
            static_constant_value => 0,
            static_boolean_constant_value =>
              Adac.Types.False_Boolean_Value,
            integer_number_value =>
              Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
            real_number_value => value));
    exception
      when others =>
        self.lookup.delete (symbol_ordinal);
        raise;
    end;

    inserted := True;
  end try_bind_local_real_number;

  function resolve_local_object
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Natural is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    if not self.lookup.contains (symbol_ordinal) then
      return 0;
    end if;

    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /= Local_Object_Binding then
      return 0;
    end if;

    return self.bindings (binding_index).local_ordinal;
  end resolve_local_object;

  function resolve_local_subtype
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;

    if not self.lookup.contains (symbol_ordinal) then
      return Adac.Types.INVALID_TYPE_ID;
    end if;

    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /= Local_Subtype_Binding then
      return Adac.Types.INVALID_TYPE_ID;
    end if;

    return self.bindings (binding_index).semantic_type;
  end resolve_local_subtype;

  function resolve_local_subtype_constraint
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Subtype_Constraint is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      raise Program_Error with
        "Adac.Semantics: local subtype constraint symbol is absent";
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /= Local_Subtype_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a local subtype";
    end if;
    validate (self.bindings (binding_index).constraint_value);
    return self.bindings (binding_index).constraint_value;
  end resolve_local_subtype_constraint;

  function resolve_local_static_integer_constant_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /=
      Local_Static_Integer_Constant_Binding
    then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    return self.bindings (binding_index).semantic_type;
  end resolve_local_static_integer_constant_type;

  function resolve_local_static_integer_constant_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Long_Long_Integer is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      raise Program_Error with
        "Adac.Semantics: local static constant symbol is absent";
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /=
      Local_Static_Integer_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a static constant";
    end if;
    return self.bindings (binding_index).static_constant_value;
  end resolve_local_static_integer_constant_value;

  function resolve_local_static_boolean_constant_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /=
      Local_Static_Boolean_Constant_Binding
    then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    return self.bindings (binding_index).semantic_type;
  end resolve_local_static_boolean_constant_type;

  function resolve_local_static_boolean_constant_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Boolean_Value is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      raise Program_Error with
        "Adac.Semantics: local static Boolean constant symbol is absent";
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /=
      Local_Static_Boolean_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a static Boolean constant";
    end if;
    return self.bindings (binding_index).static_boolean_constant_value;
  end resolve_local_static_boolean_constant_value;

  function resolve_local_integer_number_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /= Local_Integer_Number_Binding then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    return self.bindings (binding_index).semantic_type;
  end resolve_local_integer_number_type;

  function resolve_local_integer_number_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Integer_Value is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
    result : Adac.Types.Universal_Integer_Value;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      raise Program_Error with
        "Adac.Semantics: local integer number symbol is absent";
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /= Local_Integer_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not an integer named number";
    end if;
    result := self.bindings (binding_index).integer_number_value;
    Adac.Types.validate (result);
    return result;
  end resolve_local_integer_number_value;

  function resolve_local_real_number_type
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /= Local_Real_Number_Binding then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    return self.bindings (binding_index).semantic_type;
  end resolve_local_real_number_type;

  function resolve_local_real_number_value
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store;
     symbol  : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Real_Value is
    symbol_ordinal : constant Positive :=
      Adac.Symbols.ordinal (symbols, symbol);
    binding_index : Positive;
    result : Adac.Types.Universal_Real_Value;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup is inconsistent";
    end if;
    if not self.lookup.contains (symbol_ordinal) then
      raise Program_Error with
        "Adac.Semantics: local real number symbol is absent";
    end if;
    binding_index := self.lookup.element (symbol_ordinal);
    if self.bindings (binding_index).kind /= Local_Real_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a real named number";
    end if;
    result := self.bindings (binding_index).real_number_value;
    Adac.Types.validate (result);
    return result;
  end resolve_local_real_number_value;

  function scope_binding_count (self : Lexical_Scope) return Natural is
  begin
    return Natural (self.bindings.length);
  end scope_binding_count;

  function scope_local_object_count (self : Lexical_Scope) return Natural is
  begin
    return self.local_object_count;
  end scope_local_object_count;

  function scope_binding_kind_at
    (self  : Lexical_Scope;
     index : Positive)
  return Scope_Binding_Kind is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;

    return self.bindings (index).kind;
  end scope_binding_kind_at;

  function scope_binding_symbol_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;

    return self.bindings (index).symbol;
  end scope_binding_symbol_at;

  function scope_binding_local_at
    (self  : Lexical_Scope;
     index : Positive)
  return Positive is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Object_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a local object";
    end if;

    return Positive (self.bindings (index).local_ordinal);
  end scope_binding_local_at;

  function scope_binding_subtype_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Subtype_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a local subtype";
    end if;

    return self.bindings (index).subtype_declaration;
  end scope_binding_subtype_declaration_at;

  function scope_binding_subtype_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Subtype_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a local subtype";
    end if;

    return self.bindings (index).semantic_type;
  end scope_binding_subtype_type_at;

  function scope_binding_subtype_constraint_at
    (self  : Lexical_Scope;
     index : Positive)
  return Subtype_Constraint is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Subtype_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a local subtype";
    end if;
    validate (self.bindings (index).constraint_value);
    return self.bindings (index).constraint_value;
  end scope_binding_subtype_constraint_at;

  function scope_binding_static_constant_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /=
         Local_Static_Integer_Constant_Binding and then
       self.bindings (index).kind /= Local_Static_Boolean_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a static constant";
    end if;
    return self.bindings (index).static_constant_declaration;
  end scope_binding_static_constant_declaration_at;

  function scope_binding_static_constant_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /=
         Local_Static_Integer_Constant_Binding and then
       self.bindings (index).kind /= Local_Static_Boolean_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a static constant";
    end if;
    return self.bindings (index).semantic_type;
  end scope_binding_static_constant_type_at;

  function scope_binding_static_constant_constraint_at
    (self  : Lexical_Scope;
     index : Positive)
  return Subtype_Constraint is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /=
         Local_Static_Integer_Constant_Binding and then
       self.bindings (index).kind /= Local_Static_Boolean_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a static constant";
    end if;
    validate (self.bindings (index).constraint_value);
    return self.bindings (index).constraint_value;
  end scope_binding_static_constant_constraint_at;

  function scope_binding_static_constant_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Long_Long_Integer is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /=
      Local_Static_Integer_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a static constant";
    end if;
    return self.bindings (index).static_constant_value;
  end scope_binding_static_constant_value_at;

  function scope_binding_static_boolean_constant_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Boolean_Value is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Static_Boolean_Constant_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a static Boolean constant";
    end if;
    return self.bindings (index).static_boolean_constant_value;
  end scope_binding_static_boolean_constant_value_at;

  function scope_binding_integer_number_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Integer_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not an integer named number";
    end if;
    return self.bindings (index).number_declaration;
  end scope_binding_integer_number_declaration_at;

  function scope_binding_integer_number_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Integer_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not an integer named number";
    end if;
    return self.bindings (index).semantic_type;
  end scope_binding_integer_number_type_at;

  function scope_binding_integer_number_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Universal_Integer_Value is
    result : Adac.Types.Universal_Integer_Value;
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Integer_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not an integer named number";
    end if;
    result := self.bindings (index).integer_number_value;
    Adac.Types.validate (result);
    return result;
  end scope_binding_integer_number_value_at;

  function scope_binding_real_number_declaration_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Real_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a real named number";
    end if;
    return self.bindings (index).number_declaration;
  end scope_binding_real_number_declaration_at;

  function scope_binding_real_number_type_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Type_ID is
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Real_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a real named number";
    end if;
    return self.bindings (index).semantic_type;
  end scope_binding_real_number_type_at;

  function scope_binding_real_number_value_at
    (self  : Lexical_Scope;
     index : Positive)
  return Adac.Types.Universal_Real_Value is
    result : Adac.Types.Universal_Real_Value;
  begin
    if index > Natural (self.bindings.length) then
      raise Program_Error with
        "Adac.Semantics: lexical binding index out of range";
    end if;
    if self.bindings (index).kind /= Local_Real_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: lexical binding is not a real named number";
    end if;
    result := self.bindings (index).real_number_value;
    Adac.Types.validate (result);
    return result;
  end scope_binding_real_number_value_at;

  procedure validate (self : Lexical_Scope) is
    object_count : Natural := 0;
  begin
    if self.lookup.length /= self.bindings.length then
      raise Program_Error with
        "Adac.Semantics: lexical scope lookup count mismatch";
    end if;

    for index in 1 .. Natural (self.bindings.length) loop
      declare
        binding : constant Scope_Binding_Record := self.bindings (index);
      begin
        Adac.Symbols.validate (binding.symbol);
        if binding.symbol_ordinal = 0 or else
           not self.lookup.contains (Positive (binding.symbol_ordinal)) or else
           self.lookup.element (Positive (binding.symbol_ordinal)) /= index
        then
          raise Program_Error with
            "Adac.Semantics: lexical binding is inconsistent";
        end if;

        case binding.kind is
          when Local_Object_Binding =>
            object_count := object_count + 1;
            if binding.local_ordinal /= object_count or else
               binding.subtype_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.static_constant_declaration /=
                 Adac.AST.INVALID_NODE_ID or else
               binding.number_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.semantic_type /= Adac.Types.INVALID_TYPE_ID or else
               binding.constraint_value /= NO_SUBTYPE_CONSTRAINT or else
               binding.static_constant_value /= 0 or else
               binding.integer_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
               binding.real_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
            then
              raise Program_Error with
                "Adac.Semantics: local object binding metadata is invalid";
            end if;

          when Local_Subtype_Binding =>
            if binding.local_ordinal /= 0 or else
               binding.static_constant_declaration /=
                 Adac.AST.INVALID_NODE_ID or else
               binding.number_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.static_constant_value /= 0 or else
               binding.integer_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
               binding.real_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
            then
              raise Program_Error with
                "Adac.Semantics: local subtype binding metadata is invalid";
            end if;
            Adac.AST.validate (binding.subtype_declaration);
            Adac.Types.validate (binding.semantic_type);
            validate (binding.constraint_value);

          when Local_Static_Integer_Constant_Binding =>
            if binding.local_ordinal /= 0 or else
               binding.subtype_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.number_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.integer_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
               binding.real_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
            then
              raise Program_Error with
                "Adac.Semantics: static constant binding metadata is invalid";
            end if;
            Adac.AST.validate (binding.static_constant_declaration);
            Adac.Types.validate (binding.semantic_type);
            validate (binding.constraint_value);
            if not subtype_constraint_contains
              (binding.constraint_value, binding.static_constant_value)
            then
              raise Program_Error with
                "Adac.Semantics: static constant violates nominal constraint";
            end if;

          when Local_Static_Boolean_Constant_Binding =>
            if binding.local_ordinal /= 0 or else
               binding.subtype_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.number_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.constraint_value /= NO_SUBTYPE_CONSTRAINT or else
               binding.static_constant_value /= 0 or else
               binding.integer_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
               binding.real_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
            then
              raise Program_Error with
                "Adac.Semantics: static Boolean constant metadata is invalid";
            end if;
            Adac.AST.validate (binding.static_constant_declaration);
            Adac.Types.validate (binding.semantic_type);

          when Local_Integer_Number_Binding =>
            if binding.local_ordinal /= 0 or else
               binding.subtype_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.static_constant_declaration /=
                 Adac.AST.INVALID_NODE_ID or else
               binding.constraint_value /= NO_SUBTYPE_CONSTRAINT or else
               binding.static_constant_value /= 0 or else
               binding.real_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
            then
              raise Program_Error with
                "Adac.Semantics: integer named-number metadata is invalid";
            end if;
            Adac.AST.validate (binding.number_declaration);
            Adac.Types.validate (binding.semantic_type);
            Adac.Types.validate (binding.integer_number_value);

          when Local_Real_Number_Binding =>
            if binding.local_ordinal /= 0 or else
               binding.subtype_declaration /= Adac.AST.INVALID_NODE_ID or else
               binding.static_constant_declaration /=
                 Adac.AST.INVALID_NODE_ID or else
               binding.constraint_value /= NO_SUBTYPE_CONSTRAINT or else
               binding.static_constant_value /= 0 or else
               binding.integer_number_value /=
                 Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE
            then
              raise Program_Error with
                "Adac.Semantics: real named-number metadata is invalid";
            end if;
            Adac.AST.validate (binding.number_declaration);
            Adac.Types.validate (binding.semantic_type);
            Adac.Types.validate (binding.real_number_value);
        end case;
      end;
    end loop;

    if object_count /= self.local_object_count then
      raise Program_Error with
        "Adac.Semantics: lexical local-object count mismatch";
    end if;
  end validate;

  procedure validate
    (self    : Lexical_Scope;
     symbols : Adac.Symbols.Store)
  is
  begin
    validate (self);
    for binding of self.bindings loop
      Adac.Symbols.validate (symbols, binding.symbol);
      if Adac.Symbols.ordinal (symbols, binding.symbol) /=
         Positive (binding.symbol_ordinal)
      then
        raise Program_Error with
          "Adac.Semantics: lexical binding symbol ordinal mismatch";
      end if;
    end loop;
  end validate;

  procedure append
    (self   : in out Entity_ID_List;
     entity : Entity_ID)
  is
  begin
    validate (entity);
    self.items.append (entity);
  end append;

  function entity_list_count (self : Entity_ID_List) return Natural is
  begin
    return Natural (self.items.length);
  end entity_list_count;

  function entity_list_element
    (self  : Entity_ID_List;
     index : Positive)
  return Entity_ID is
  begin
    if index > Natural (self.items.length) then
      raise Program_Error with "Adac.Semantics: entity list index out of range";
    end if;

    return self.items (index);
  end entity_list_element;

  procedure append_boolean_expression_constant
    (self   : in out Boolean_Expression_Value_List;
     syntax : Adac.AST.Node_ID;
     value  : Adac.Types.Boolean_Value)
  is
  begin
    Adac.AST.validate (syntax);
    self.items.append
      (Boolean_Expression_Value_Record'
         (kind                        => Boolean_Expression_Constant_Value,
          syntax                      => syntax,
          boolean_value               => value,
          source_local                => 0,
          source_definition_statement => 0,
          boolean_operator            => No_Boolean_Binary_Operator,
          operand_value               => 0,
          right_operand_value         => 0,
          subtree_value_count         => 1));
  end append_boolean_expression_constant;

  procedure append_boolean_expression_local
    (self                        : in out Boolean_Expression_Value_List;
     syntax                      : Adac.AST.Node_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     value                       : Adac.Types.Boolean_Value)
  is
  begin
    Adac.AST.validate (syntax);
    self.items.append
      (Boolean_Expression_Value_Record'
         (kind                        => Boolean_Expression_Local_Value,
          syntax                      => syntax,
          boolean_value               => value,
          source_local                => source_local,
          source_definition_statement => source_definition_statement,
          boolean_operator            => No_Boolean_Binary_Operator,
          operand_value               => 0,
          right_operand_value         => 0,
          subtree_value_count         => 1));
  end append_boolean_expression_local;

  procedure append_boolean_expression_not
    (self   : in out Boolean_Expression_Value_List;
     syntax : Adac.AST.Node_ID)
  is
  begin
    Adac.AST.validate (syntax);
    if self.items.is_empty then
      raise Program_Error with
        "Adac.Semantics: Boolean expression not has no operand";
    end if;

    declare
      operand_index : constant Positive := Positive (self.items.length);
      operand : constant Boolean_Expression_Value_Record :=
        self.items (operand_index);
      result_value : constant Adac.Types.Boolean_Value :=
        boolean_not_value (operand.boolean_value);
    begin
      if operand.kind = Boolean_Expression_Constant_Value then
        self.items.replace_element
          (operand_index,
           Boolean_Expression_Value_Record'
             (kind                        => Boolean_Expression_Constant_Value,
              syntax                      => syntax,
              boolean_value               => result_value,
              source_local                => 0,
              source_definition_statement => 0,
              boolean_operator            => No_Boolean_Binary_Operator,
              operand_value               => 0,
              right_operand_value         => 0,
              subtree_value_count         => 1));
        return;
      end if;

      self.items.append
        (Boolean_Expression_Value_Record'
           (kind                        => Boolean_Expression_Not_Value,
            syntax                      => syntax,
            boolean_value               => result_value,
            source_local                => 0,
            source_definition_statement => 0,
            boolean_operator            => No_Boolean_Binary_Operator,
            operand_value               => operand_index,
            right_operand_value         => 0,
            subtree_value_count         => operand.subtree_value_count + 1));
    end;
  end append_boolean_expression_not;

  procedure append_boolean_expression_binary
    (self          : in out Boolean_Expression_Value_List;
     syntax        : Adac.AST.Node_ID;
     operator_kind : Boolean_Binary_Operator_Kind)
  is
  begin
    Adac.AST.validate (syntax);
    if operator_kind = No_Boolean_Binary_Operator then
      raise Program_Error with
        "Adac.Semantics: Boolean expression binary has no operator";
    end if;
    if Natural (self.items.length) < 2 then
      raise Program_Error with
        "Adac.Semantics: Boolean expression binary lacks operands";
    end if;

    declare
      right_index : constant Positive := Positive (self.items.length);
      right : constant Boolean_Expression_Value_Record :=
        self.items (right_index);
      left_index_value : constant Integer :=
        Integer (right_index) - Integer (right.subtree_value_count);
    begin
      if left_index_value < 1 then
        raise Program_Error with
          "Adac.Semantics: Boolean expression binary left root is invalid";
      end if;
      declare
        left_index : constant Positive := Positive (left_index_value);
        left : constant Boolean_Expression_Value_Record :=
          self.items (left_index);
        result_value : constant Adac.Types.Boolean_Value :=
          boolean_binary_value
            (operator_kind, left.boolean_value, right.boolean_value);
      begin
        if left.kind = Boolean_Expression_Constant_Value and then
           right.kind = Boolean_Expression_Constant_Value
        then
          self.items.delete_last;
          self.items.delete_last;
          append_boolean_expression_constant (self, syntax, result_value);
          return;
        end if;

        self.items.append
          (Boolean_Expression_Value_Record'
             (kind                        => Boolean_Expression_Binary_Value,
              syntax                      => syntax,
              boolean_value               => result_value,
              source_local                => 0,
              source_definition_statement => 0,
              boolean_operator            => operator_kind,
              operand_value               => left_index,
              right_operand_value         => right_index,
              subtree_value_count         =>
                left.subtree_value_count + right.subtree_value_count + 1));
      end;
    end;
  end append_boolean_expression_binary;

  function boolean_expression_root_value
    (self : Boolean_Expression_Value_List)
  return Adac.Types.Boolean_Value is
  begin
    if self.items.is_empty then
      raise Program_Error with
        "Adac.Semantics: Boolean expression tree is empty";
    end if;
    return self.items.last_element.boolean_value;
  end boolean_expression_root_value;

  function boolean_expression_has_runtime_read
    (self : Boolean_Expression_Value_List)
  return Boolean is
  begin
    if self.items.is_empty then
      raise Program_Error with
        "Adac.Semantics: Boolean expression tree is empty";
    end if;
    return self.items.last_element.kind /= Boolean_Expression_Constant_Value;
  end boolean_expression_has_runtime_read;

  procedure validate_boolean_expression_structure
    (values         : Boolean_Expression_Value_Vectors.Vector;
     first_value    : Natural;
     value_count    : Natural;
     expected_value : Adac.Types.Boolean_Value)
  is
    total : constant Natural := Natural (values.length);
  begin
    if first_value = 0 or else value_count = 0 or else
       first_value > total or else value_count > total - first_value + 1
    then
      raise Program_Error with
        "Adac.Semantics: Boolean expression range is invalid";
    end if;

    for relative_index in 1 .. value_count loop
      declare
        absolute_index : constant Positive :=
          Positive (first_value + relative_index - 1);
        item : constant Boolean_Expression_Value_Record :=
          values (absolute_index);
      begin
        Adac.AST.validate (item.syntax);
        case item.kind is
          when Boolean_Expression_Constant_Value =>
            if item.source_local /= 0 or else
               item.source_definition_statement /= 0 or else
               item.boolean_operator /= No_Boolean_Binary_Operator or else
               item.operand_value /= 0 or else
               item.right_operand_value /= 0 or else
               item.subtree_value_count /= 1
            then
              raise Program_Error with
                "Adac.Semantics: Boolean expression constant is invalid";
            end if;

          when Boolean_Expression_Local_Value =>
            if item.source_local = 0 or else
               item.boolean_operator /= No_Boolean_Binary_Operator or else
               item.operand_value /= 0 or else
               item.right_operand_value /= 0 or else
               item.subtree_value_count /= 1
            then
              raise Program_Error with
                "Adac.Semantics: Boolean expression local is invalid";
            end if;

          when Boolean_Expression_Not_Value =>
            if relative_index = 1 or else
               item.source_local /= 0 or else
               item.source_definition_statement /= 0 or else
               item.boolean_operator /= No_Boolean_Binary_Operator or else
               item.right_operand_value /= 0 or else
               item.operand_value /= Natural (absolute_index) - 1
            then
              raise Program_Error with
                "Adac.Semantics: Boolean expression not metadata is invalid";
            end if;
            declare
              operand : constant Boolean_Expression_Value_Record :=
                values (Positive (item.operand_value));
            begin
              if item.subtree_value_count /=
                   operand.subtree_value_count + 1 or else
                 item.boolean_value /= boolean_not_value (operand.boolean_value)
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean expression not result is invalid";
              end if;
            end;

          when Boolean_Expression_Binary_Value =>
            if relative_index <= 2 or else
               item.source_local /= 0 or else
               item.source_definition_statement /= 0 or else
               item.boolean_operator = No_Boolean_Binary_Operator or else
               item.right_operand_value /= Natural (absolute_index) - 1
            then
              raise Program_Error with
                "Adac.Semantics: Boolean expression binary metadata is invalid";
            end if;
            declare
              right : constant Boolean_Expression_Value_Record :=
                values (Positive (item.right_operand_value));
              left_index : constant Integer :=
                Integer (item.right_operand_value) -
                Integer (right.subtree_value_count);
            begin
              if left_index < Integer (first_value) or else
                 item.operand_value /= Natural (left_index)
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean expression binary shape is invalid";
              end if;
              declare
                left : constant Boolean_Expression_Value_Record :=
                  values (Positive (left_index));
              begin
                if item.subtree_value_count /=
                     left.subtree_value_count + right.subtree_value_count + 1 or else
                   item.boolean_value /= boolean_binary_value
                     (item.boolean_operator,
                      left.boolean_value,
                      right.boolean_value)
                then
                  raise Program_Error with
                    "Adac.Semantics: Boolean expression binary result is invalid";
                end if;
              end;
            end;
        end case;
      end;
    end loop;

    declare
      root : constant Boolean_Expression_Value_Record :=
        values (Positive (first_value + value_count - 1));
    begin
      if root.subtree_value_count /= value_count or else
         root.boolean_value /= expected_value
      then
        raise Program_Error with
          "Adac.Semantics: Boolean expression root is invalid";
      end if;
    end;
  end validate_boolean_expression_structure;

  procedure append_statement
    (self      : in out Procedure_Statement_List;
     statement : Adac.AST.Node_ID;
     kind      : Procedure_Statement_Kind)
  is
  begin
    Adac.AST.validate (statement);

    if is_assignment_kind (kind) then
      raise Program_Error with
        "Adac.Semantics: assignment requires assignment metadata";
    end if;

    self.items.append
      (Procedure_Statement_Record'
         (kind                        => kind,
          syntax                      => statement,
          target_local                => 0,
          expected_type               => Adac.Types.INVALID_TYPE_ID,
          integer_value               => 0,
          boolean_value               => Adac.Types.False_Boolean_Value,
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => 0,
          source_definition_statement => 0,
          right_source_local          => 0,
          right_source_definition_statement => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_statement;

  procedure append_local_integer_static_assignment
    (self          : in out Procedure_Statement_List;
     statement     : Adac.AST.Node_ID;
     target_local  : Positive;
     expected_type : Adac.Types.Type_ID;
     integer_value : Long_Long_Integer)
  is
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);
    self.items.append
      (Procedure_Statement_Record'
         (kind                        =>
            Local_Integer_Static_Assignment_Statement,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => integer_value,
          boolean_value               => Adac.Types.False_Boolean_Value,
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => 0,
          source_definition_statement => 0,
          right_source_local          => 0,
          right_source_definition_statement => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_local_integer_static_assignment;

  procedure append_local_boolean_static_assignment
    (self          : in out Procedure_Statement_List;
     statement     : Adac.AST.Node_ID;
     target_local  : Positive;
     expected_type : Adac.Types.Type_ID;
     boolean_value : Adac.Types.Boolean_Value)
  is
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);
    self.items.append
      (Procedure_Statement_Record'
         (kind                        =>
            Local_Boolean_Static_Assignment_Statement,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => 0,
          boolean_value               => boolean_value,
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => 0,
          source_definition_statement => 0,
          right_source_local          => 0,
          right_source_definition_statement => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_local_boolean_static_assignment;

  procedure append_local_boolean_copy_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     boolean_value               : Adac.Types.Boolean_Value)
  is
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);

    if source_definition_statement > Natural (self.items.length) then
      raise Program_Error with
        "Adac.Semantics: Boolean source definition is not earlier";
    end if;
    if source_definition_statement /= 0 then
      declare
        definition : constant Procedure_Statement_Record :=
          self.items (Positive (source_definition_statement));
      begin
        if not is_boolean_assignment_kind (definition.kind) or else
           definition.target_local /= source_local or else
           definition.boolean_value /= boolean_value
        then
          raise Program_Error with
            "Adac.Semantics: Boolean source definition is invalid";
        end if;
      end;
    end if;

    self.items.append
      (Procedure_Statement_Record'
         (kind                        =>
            Local_Boolean_Copy_Assignment_Statement,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => 0,
          boolean_value               => boolean_value,
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => source_local,
          source_definition_statement => source_definition_statement,
          right_source_local          => 0,
          right_source_definition_statement => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_local_boolean_copy_assignment;

  procedure append_local_boolean_not_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     boolean_value               : Adac.Types.Boolean_Value)
  is
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);

    if source_definition_statement > Natural (self.items.length) then
      raise Program_Error with
        "Adac.Semantics: Boolean not source definition is not earlier";
    end if;
    if source_definition_statement /= 0 then
      declare
        definition : constant Procedure_Statement_Record :=
          self.items (Positive (source_definition_statement));
      begin
        if not is_boolean_assignment_kind (definition.kind) or else
           definition.target_local /= source_local or else
           definition.boolean_value /= boolean_not_value (boolean_value)
        then
          raise Program_Error with
            "Adac.Semantics: Boolean not source definition is invalid";
        end if;
      end;
    end if;

    self.items.append
      (Procedure_Statement_Record'
         (kind                        =>
            Local_Boolean_Not_Assignment_Statement,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => 0,
          boolean_value               => boolean_value,
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => source_local,
          source_definition_statement => source_definition_statement,
          right_source_local          => 0,
          right_source_definition_statement => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_local_boolean_not_assignment;

  procedure append_local_boolean_binary_assignment
    (self                              : in out Procedure_Statement_List;
     statement                         : Adac.AST.Node_ID;
     target_local                      : Positive;
     expected_type                     : Adac.Types.Type_ID;
     operator_kind                     : Boolean_Binary_Operator_Kind;
     left_source_local                 : Positive;
     left_source_definition_statement  : Natural;
     right_source_local                : Positive;
     right_source_definition_statement : Natural;
     boolean_value                     : Adac.Types.Boolean_Value)
  is
    procedure validate_source_definition
      (source_local      : Positive;
       definition_index  : Natural)
    is
    begin
      if definition_index > Natural (self.items.length) then
        raise Program_Error with
          "Adac.Semantics: Boolean binary source definition is not earlier";
      end if;
      if definition_index /= 0 then
        declare
          definition : constant Procedure_Statement_Record :=
            self.items (Positive (definition_index));
        begin
          if not is_boolean_assignment_kind (definition.kind) or else
             definition.target_local /= source_local
          then
            raise Program_Error with
              "Adac.Semantics: Boolean binary source definition is invalid";
          end if;
        end;
      end if;
    end validate_source_definition;
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);
    if operator_kind = No_Boolean_Binary_Operator then
      raise Program_Error with
        "Adac.Semantics: Boolean binary assignment has no operator";
    end if;
    validate_source_definition
      (left_source_local, left_source_definition_statement);
    validate_source_definition
      (right_source_local, right_source_definition_statement);

    self.items.append
      (Procedure_Statement_Record'
         (kind                        =>
            Local_Boolean_Binary_Assignment_Statement,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => 0,
          boolean_value               => boolean_value,
          boolean_operator            => operator_kind,
          source_local                => left_source_local,
          source_definition_statement => left_source_definition_statement,
          right_source_local          => right_source_local,
          right_source_definition_statement =>
            right_source_definition_statement,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_local_boolean_binary_assignment;

  procedure append_local_boolean_short_circuit_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     operator_kind               : Boolean_Short_Circuit_Operator_Kind;
     left_source_local           : Positive;
     left_definition_statement   : Natural;
     right_source_local          : Positive;
     right_definition_statement  : Natural;
     boolean_value               : Adac.Types.Boolean_Value)
  is
    procedure validate_source_definition
      (source_local     : Positive;
       definition_index : Natural)
    is
    begin
      if definition_index > Natural (self.items.length) then
        raise Program_Error with
          "Adac.Semantics: short-circuit source definition is not earlier";
      end if;
      if definition_index /= 0 then
        declare
          definition : constant Procedure_Statement_Record :=
            self.items (Positive (definition_index));
        begin
          if not is_boolean_assignment_kind (definition.kind) or else
             definition.target_local /= source_local
          then
            raise Program_Error with
              "Adac.Semantics: short-circuit source definition is invalid";
          end if;
        end;
      end if;
    end validate_source_definition;

    statement_kind : constant Procedure_Statement_Kind :=
      (case operator_kind is
         when And_Then_Boolean_Short_Circuit_Operator =>
           Local_Boolean_And_Then_Assignment_Statement,
         when Or_Else_Boolean_Short_Circuit_Operator =>
           Local_Boolean_Or_Else_Assignment_Statement);
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);
    validate_source_definition
      (left_source_local, left_definition_statement);
    validate_source_definition
      (right_source_local, right_definition_statement);

    self.items.append
      (Procedure_Statement_Record'
         (kind                        => statement_kind,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => 0,
          boolean_value               => boolean_value,
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => left_source_local,
          source_definition_statement => left_definition_statement,
          right_source_local          => right_source_local,
          right_source_definition_statement => right_definition_statement,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_local_boolean_short_circuit_assignment;

  procedure append_local_boolean_expression_assignment
    (self          : in out Procedure_Statement_List;
     statement     : Adac.AST.Node_ID;
     target_local  : Positive;
     expected_type : Adac.Types.Type_ID;
     expression    : Boolean_Expression_Value_List)
  is
    first_value : Natural;
    value_count : constant Natural := Natural (expression.items.length);
    offset      : constant Natural := Natural (self.boolean_expression_values.length);
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);
    if value_count = 0 or else
       not boolean_expression_has_runtime_read (expression)
    then
      raise Program_Error with
        "Adac.Semantics: Boolean expression assignment tree is invalid";
    end if;
    validate_boolean_expression_structure
      (expression.items,
       1,
       value_count,
       boolean_expression_root_value (expression));
    if self.boolean_expression_values.length >
      Ada.Containers.Count_Type (Positive'Last - value_count)
    then
      raise Storage_Error with
        "Adac.Semantics: Boolean expression value capacity exhausted";
    end if;

    first_value := offset + 1;
    for index in 1 .. value_count loop
      declare
        item : Boolean_Expression_Value_Record := expression.items (index);
      begin
        if item.operand_value /= 0 then
          item.operand_value := item.operand_value + offset;
        end if;
        if item.right_operand_value /= 0 then
          item.right_operand_value := item.right_operand_value + offset;
        end if;
        self.boolean_expression_values.append (item);
      end;
    end loop;

    self.items.append
      (Procedure_Statement_Record'
         (kind                        =>
            Local_Boolean_Expression_Assignment_Statement,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => 0,
          boolean_value               => boolean_expression_root_value (expression),
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => 0,
          source_definition_statement => 0,
          right_source_local          => 0,
          right_source_definition_statement => 0,
          first_boolean_expression_value => first_value,
          boolean_expression_value_count => value_count));
  end append_local_boolean_expression_assignment;

  procedure append_local_integer_copy_assignment
    (self                        : in out Procedure_Statement_List;
     statement                   : Adac.AST.Node_ID;
     target_local                : Positive;
     expected_type               : Adac.Types.Type_ID;
     source_local                : Positive;
     source_definition_statement : Natural;
     integer_value               : Long_Long_Integer)
  is
  begin
    Adac.AST.validate (statement);
    Adac.Types.validate (expected_type);

    if source_definition_statement > Natural (self.items.length) then
      raise Program_Error with
        "Adac.Semantics: copy source definition is not an earlier statement";
    end if;

    if source_definition_statement /= 0 then
      declare
        definition : constant Procedure_Statement_Record :=
          self.items (Positive (source_definition_statement));
      begin
        if not is_integer_assignment_kind (definition.kind) or else
           definition.target_local /= source_local
        then
          raise Program_Error with
            "Adac.Semantics: copy source definition targets another local";
        end if;
      end;
    end if;

    self.items.append
      (Procedure_Statement_Record'
         (kind                        =>
            Local_Integer_Copy_Assignment_Statement,
          syntax                      => statement,
          target_local                => target_local,
          expected_type               => expected_type,
          integer_value               => integer_value,
          boolean_value               => Adac.Types.False_Boolean_Value,
          boolean_operator            => No_Boolean_Binary_Operator,
          source_local                => source_local,
          source_definition_statement => source_definition_statement,
          right_source_local          => 0,
          right_source_definition_statement => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
  end append_local_integer_copy_assignment;

  function statement_list_count
    (self : Procedure_Statement_List)
  return Natural is
  begin
    return Natural (self.items.length);
  end statement_list_count;

  function temporary_statement_at
    (self  : Procedure_Statement_List;
     index : Positive)
  return Procedure_Statement_Record is
  begin
    if index > Natural (self.items.length) then
      raise Program_Error with
        "Adac.Semantics: statement list index out of range";
    end if;
    return self.items (index);
  end temporary_statement_at;

  function statement_list_kind_at
    (self  : Procedure_Statement_List;
     index : Positive)
  return Procedure_Statement_Kind is
  begin
    return temporary_statement_at (self, index).kind;
  end statement_list_kind_at;

  function statement_list_syntax
    (self  : Procedure_Statement_List;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    return temporary_statement_at (self, index).syntax;
  end statement_list_syntax;

  function statement_list_expected_type
    (self  : Procedure_Statement_List;
     index : Positive)
  return Adac.Types.Type_ID is
    checked : constant Procedure_Statement_Record :=
      temporary_statement_at (self, index);
  begin
    if not is_assignment_kind (checked.kind) then
      raise Program_Error with
        "Adac.Semantics: temporary statement is not an assignment";
    end if;
    return checked.expected_type;
  end statement_list_expected_type;

  function create return Store is
  begin
    return result : Store do
      result.initialized := True;
    end return;
  end create;

  function append_object_internal
    (self                : in out Store;
     declaration         : Adac.AST.Node_ID;
     symbol              : Adac.Symbols.Symbol_ID;
     span                : Adac.Source.Span;
     semantic_type       : Adac.Types.Type_ID;
     has_integer_initializer : Boolean;
     integer_initializer : Long_Long_Integer;
     has_boolean_initializer : Boolean;
     boolean_initializer : Adac.Types.Boolean_Value;
     constraint          : Subtype_Constraint)
  return Entity_ID is
    result : Entity_ID;
  begin
    validate_store (self);
    Adac.AST.validate (declaration);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (span);
    Adac.Types.validate (semantic_type);
    validate (constraint);

    if has_integer_initializer and then has_boolean_initializer then
      raise Program_Error with
        "Adac.Semantics: object has multiple initializer kinds";
    end if;
    if not has_integer_initializer and then integer_initializer /= 0 then
      raise Program_Error with
        "Adac.Semantics: object has stray integer initializer value";
    end if;
    if not has_boolean_initializer and then
       boolean_initializer /= Adac.Types.False_Boolean_Value
    then
      raise Program_Error with
        "Adac.Semantics: object has stray Boolean initializer value";
    end if;

    if has_integer_initializer and then
       not subtype_constraint_contains (constraint, integer_initializer)
    then
      raise Program_Error with
        "Adac.Semantics: object initializer violates subtype constraint";
    end if;
    if has_boolean_initializer and then constraint /= NO_SUBTYPE_CONSTRAINT then
      raise Program_Error with
        "Adac.Semantics: Boolean object has subtype constraint";
    end if;

    result := next_entity_id (self);
    self.entities.append
      (Entity_Record'
         (kind                    => Object_Entity,
          declaration             => declaration,
          symbol                  => symbol,
          span                    => span,
          semantic_type           => semantic_type,
          has_integer_initializer => has_integer_initializer,
          integer_initializer     => integer_initializer,
          has_boolean_initializer => has_boolean_initializer,
          boolean_initializer     => boolean_initializer,
          constraint_value        => constraint,
          first_scope_binding     => 0,
          scope_binding_count     => 0,
          first_local_relation    => 0,
          local_count             => 0,
          first_statement         => 0,
          statement_count         => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));
    return result;
  end append_object_internal;

  function append_object
    (self          : in out Store;
     declaration   : Adac.AST.Node_ID;
     symbol        : Adac.Symbols.Symbol_ID;
     span          : Adac.Source.Span;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Subtype_Constraint)
  return Entity_ID is
  begin
    return append_object_internal
      (self,
       declaration,
       symbol,
       span,
       semantic_type,
       has_integer_initializer => False,
       integer_initializer     => 0,
       has_boolean_initializer => False,
       boolean_initializer     => Adac.Types.False_Boolean_Value,
       constraint              => constraint);
  end append_object;

  function append_object
    (self                : in out Store;
     declaration         : Adac.AST.Node_ID;
     symbol              : Adac.Symbols.Symbol_ID;
     span                : Adac.Source.Span;
     semantic_type       : Adac.Types.Type_ID;
     integer_initializer : Long_Long_Integer;
     constraint          : Subtype_Constraint)
  return Entity_ID is
  begin
    return append_object_internal
      (self,
       declaration,
       symbol,
       span,
       semantic_type,
       has_integer_initializer => True,
       integer_initializer     => integer_initializer,
       has_boolean_initializer => False,
       boolean_initializer     => Adac.Types.False_Boolean_Value,
       constraint              => constraint);
  end append_object;

  function append_object
    (self                : in out Store;
     declaration         : Adac.AST.Node_ID;
     symbol              : Adac.Symbols.Symbol_ID;
     span                : Adac.Source.Span;
     semantic_type       : Adac.Types.Type_ID;
     boolean_initializer : Adac.Types.Boolean_Value;
     constraint          : Subtype_Constraint)
  return Entity_ID is
  begin
    return append_object_internal
      (self,
       declaration,
       symbol,
       span,
       semantic_type,
       has_integer_initializer => False,
       integer_initializer     => 0,
       has_boolean_initializer => True,
       boolean_initializer     => boolean_initializer,
       constraint              => constraint);
  end append_object;

  function temporary_boolean_source_value
    (self              : Store;
     statements        : Procedure_Statement_List;
     current_statement : Positive;
     source_entity     : Entity_ID;
     source_local      : Positive;
     definition_index  : Natural)
  return Adac.Types.Boolean_Value is
  begin
    require_kind (self, source_entity, Object_Entity);
    if definition_index = 0 then
      declare
        source : constant Entity_Record :=
          self.entities (Positive (source_entity.index));
      begin
        if not source.has_boolean_initializer then
          raise Program_Error with
            "Adac.Semantics: Boolean source lacks initializer";
        end if;
        return source.boolean_initializer;
      end;
    end if;
    if definition_index >= current_statement or else
       definition_index > Natural (statements.items.length)
    then
      raise Program_Error with
        "Adac.Semantics: Boolean source definition is not earlier";
    end if;
    declare
      definition : constant Procedure_Statement_Record :=
        statements.items (Positive (definition_index));
    begin
      if not is_boolean_assignment_kind (definition.kind) or else
         definition.target_local /= source_local
      then
        raise Program_Error with
          "Adac.Semantics: Boolean source definition is invalid";
      end if;
      return definition.boolean_value;
    end;
  end temporary_boolean_source_value;

  function append_procedure
    (self        : in out Store;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span;
     scope       : Lexical_Scope;
     locals      : Entity_ID_List;
     statements  : Procedure_Statement_List)
  return Entity_ID is
    result : Entity_ID;
    binding_count : constant Natural := scope_binding_count (scope);
    relation_count : constant Natural := entity_list_count (locals);
    checked_statement_count : constant Natural :=
      statement_list_count (statements);
    checked_expression_value_count : constant Natural :=
      Natural (statements.boolean_expression_values.length);
    original_scope_binding_length : constant Ada.Containers.Count_Type :=
      self.scope_bindings.length;
    original_relation_length : constant Ada.Containers.Count_Type :=
      self.relations.length;
    original_statement_length : constant Ada.Containers.Count_Type :=
      self.statements.length;
    original_boolean_expression_length : constant Ada.Containers.Count_Type :=
      self.boolean_expression_values.length;
    first_scope_binding : Natural := 0;
    first_relation      : Natural := 0;
    first_statement     : Natural := 0;
    first_boolean_expression_value : Natural := 0;

    procedure rollback_publication is
    begin
      for index in 1 .. binding_count loop
        declare
          binding : constant Scope_Binding_Record := scope.bindings (index);
          key : constant Procedure_Scope_Lookup_Key :=
            (procedure_entity_index => Positive (result.index),
             symbol_ordinal         => Positive (binding.symbol_ordinal));
        begin
          if self.scope_lookup.contains (key) then
            self.scope_lookup.delete (key);
          end if;
        end;
      end loop;
      self.scope_bindings.set_length (original_scope_binding_length);
      self.relations.set_length (original_relation_length);
      self.statements.set_length (original_statement_length);
      self.boolean_expression_values.set_length
        (original_boolean_expression_length);
    end rollback_publication;
  begin
    validate_store (self);
    Adac.AST.validate (declaration);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (span);
    validate (scope);

    if scope_local_object_count (scope) /= relation_count then
      raise Program_Error with
        "Adac.Semantics: procedure scope/local count mismatch";
    end if;

    for index in 1 .. binding_count loop
      if scope_binding_kind_at (scope, index) = Local_Object_Binding then
        declare
          local_ordinal : constant Positive :=
            scope_binding_local_at (scope, index);
          local : constant Entity_ID :=
            entity_list_element (locals, local_ordinal);
        begin
          require_kind (self, local, Object_Entity);
          if scope_binding_symbol_at (scope, index) /=
            Adac.Semantics.symbol (self, local)
          then
            raise Program_Error with
              "Adac.Semantics: procedure scope/local binding mismatch";
          end if;
        end;
      end if;
    end loop;

    declare
      next_expression_value : Natural := 1;
    begin
    for index in 1 .. checked_statement_count loop
      declare
        checked : constant Procedure_Statement_Record :=
          statements.items (index);
      begin
        Adac.AST.validate (checked.syntax);
        if checked.kind = Local_Boolean_Binary_Assignment_Statement then
          if checked.boolean_operator = No_Boolean_Binary_Operator or else
             checked.right_source_local = 0
          then
            raise Program_Error with
              "Adac.Semantics: Boolean binary metadata is incomplete";
          end if;
        elsif checked.kind = Local_Boolean_And_Then_Assignment_Statement or else
              checked.kind = Local_Boolean_Or_Else_Assignment_Statement
        then
          if checked.boolean_operator /= No_Boolean_Binary_Operator or else
             checked.right_source_local = 0
          then
            raise Program_Error with
              "Adac.Semantics: Boolean short-circuit metadata is incomplete";
          end if;
        elsif checked.boolean_operator /= No_Boolean_Binary_Operator or else
              checked.right_source_local /= 0 or else
              checked.right_source_definition_statement /= 0
        then
          raise Program_Error with
            "Adac.Semantics: statement has unexpected Boolean binary metadata";
        end if;
        if checked.kind = Local_Boolean_Expression_Assignment_Statement then
          if checked.first_boolean_expression_value /= next_expression_value or else
             checked.boolean_expression_value_count = 0 or else
             next_expression_value > checked_expression_value_count or else
             checked.boolean_expression_value_count >
               checked_expression_value_count - next_expression_value + 1
          then
            raise Program_Error with
              "Adac.Semantics: Boolean expression statement range is invalid";
          end if;
          validate_boolean_expression_structure
            (statements.boolean_expression_values,
             checked.first_boolean_expression_value,
             checked.boolean_expression_value_count,
             checked.boolean_value);
          next_expression_value :=
            next_expression_value + checked.boolean_expression_value_count;
        elsif checked.first_boolean_expression_value /= 0 or else
              checked.boolean_expression_value_count /= 0
        then
          raise Program_Error with
            "Adac.Semantics: non-expression statement has expression values";
        end if;

        case checked.kind is
          when Null_Procedure_Statement | Return_Procedure_Statement =>
            if checked.target_local /= 0 or else
               checked.expected_type /= Adac.Types.INVALID_TYPE_ID or else
               checked.integer_value /= 0 or else
               checked.boolean_value /= Adac.Types.False_Boolean_Value or else
               checked.source_local /= 0 or else
               checked.source_definition_statement /= 0
            then
              raise Program_Error with
                "Adac.Semantics: simple statement has assignment metadata";
            end if;

          when Local_Integer_Static_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count
            then
              raise Program_Error with
                "Adac.Semantics: assignment target local is out of range";
            end if;

            if checked.boolean_value /= Adac.Types.False_Boolean_Value or else
               checked.source_local /= 0 or else
               checked.source_definition_statement /= 0
            then
              raise Program_Error with
                "Adac.Semantics: integer static assignment metadata is invalid";
            end if;

            Adac.Types.validate (checked.expected_type);
            if checked.expected_type /=
               object_type
                 (self,
                  entity_list_element
                    (locals, Positive (checked.target_local)))
            then
              raise Program_Error with
                "Adac.Semantics: assignment target type is invalid";
            end if;
            if not subtype_constraint_contains
              (object_subtype_constraint
                 (self,
                  entity_list_element
                    (locals, Positive (checked.target_local))),
               checked.integer_value)
            then
              raise Program_Error with
                "Adac.Semantics: assignment violates target subtype constraint";
            end if;

          when Local_Boolean_Static_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count
            then
              raise Program_Error with
                "Adac.Semantics: Boolean assignment target is out of range";
            end if;
            if checked.integer_value /= 0 or else
               checked.source_local /= 0 or else
               checked.source_definition_statement /= 0
            then
              raise Program_Error with
                "Adac.Semantics: Boolean static assignment metadata is invalid";
            end if;

            Adac.Types.validate (checked.expected_type);
            declare
              target_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.target_local));
            begin
              if checked.expected_type /= object_type (self, target_entity) then
                raise Program_Error with
                  "Adac.Semantics: Boolean assignment target type is invalid";
              end if;
              if object_subtype_constraint (self, target_entity) /=
                NO_SUBTYPE_CONSTRAINT
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean assignment target has constraint";
              end if;
            end;

          when Local_Boolean_Copy_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count or else
               checked.source_local = 0 or else
               checked.source_local > relation_count
            then
              raise Program_Error with
                "Adac.Semantics: Boolean copy local is out of range";
            end if;
            if checked.integer_value /= 0 then
              raise Program_Error with
                "Adac.Semantics: Boolean copy has Integer payload";
            end if;

            Adac.Types.validate (checked.expected_type);
            declare
              target_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.target_local));
              source_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.source_local));
            begin
              if checked.expected_type /=
                   object_type (self, target_entity) or else
                 checked.expected_type /= object_type (self, source_entity)
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean copy type is invalid";
              end if;
              if object_subtype_constraint (self, target_entity) /=
                   NO_SUBTYPE_CONSTRAINT or else
                 object_subtype_constraint (self, source_entity) /=
                   NO_SUBTYPE_CONSTRAINT
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean copy object has constraint";
              end if;

              if checked.source_definition_statement = 0 then
                if not object_has_boolean_initializer
                  (self, source_entity) or else
                   object_boolean_initializer (self, source_entity) /=
                     checked.boolean_value
                then
                  raise Program_Error with
                    "Adac.Semantics: Boolean copy source initializer mismatch";
                end if;
              else
                if checked.source_definition_statement >= index then
                  raise Program_Error with
                    "Adac.Semantics: Boolean copy source definition is not " &
                    "earlier";
                end if;
                declare
                  definition : constant Procedure_Statement_Record :=
                    statements.items
                      (Positive (checked.source_definition_statement));
                begin
                  if not is_boolean_assignment_kind (definition.kind) or else
                     definition.target_local /= checked.source_local or else
                     definition.boolean_value /= checked.boolean_value
                  then
                    raise Program_Error with
                      "Adac.Semantics: Boolean copy source definition is " &
                      "invalid";
                  end if;
                end;
              end if;
            end;

          when Local_Boolean_Not_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count or else
               checked.source_local = 0 or else
               checked.source_local > relation_count
            then
              raise Program_Error with
                "Adac.Semantics: Boolean not local is out of range";
            end if;
            if checked.integer_value /= 0 then
              raise Program_Error with
                "Adac.Semantics: Boolean not has Integer payload";
            end if;

            Adac.Types.validate (checked.expected_type);
            declare
              target_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.target_local));
              source_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.source_local));
              source_value : constant Adac.Types.Boolean_Value :=
                boolean_not_value (checked.boolean_value);
            begin
              if checked.expected_type /=
                   object_type (self, target_entity) or else
                 checked.expected_type /= object_type (self, source_entity)
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean not type is invalid";
              end if;
              if object_subtype_constraint (self, target_entity) /=
                   NO_SUBTYPE_CONSTRAINT or else
                 object_subtype_constraint (self, source_entity) /=
                   NO_SUBTYPE_CONSTRAINT
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean not object has constraint";
              end if;

              if checked.source_definition_statement = 0 then
                if not object_has_boolean_initializer
                  (self, source_entity) or else
                   object_boolean_initializer (self, source_entity) /=
                     source_value
                then
                  raise Program_Error with
                    "Adac.Semantics: Boolean not source initializer mismatch";
                end if;
              else
                if checked.source_definition_statement >= index then
                  raise Program_Error with
                    "Adac.Semantics: Boolean not source definition is not " &
                    "earlier";
                end if;
                declare
                  definition : constant Procedure_Statement_Record :=
                    statements.items
                      (Positive (checked.source_definition_statement));
                begin
                  if not is_boolean_assignment_kind (definition.kind) or else
                     definition.target_local /= checked.source_local or else
                     definition.boolean_value /= source_value
                  then
                    raise Program_Error with
                      "Adac.Semantics: Boolean not source definition is " &
                      "invalid";
                  end if;
                end;
              end if;
            end;

          when Local_Boolean_Binary_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count or else
               checked.source_local = 0 or else
               checked.source_local > relation_count or else
               checked.right_source_local > relation_count
            then
              raise Program_Error with
                "Adac.Semantics: Boolean binary local is out of range";
            end if;
            if checked.integer_value /= 0 then
              raise Program_Error with
                "Adac.Semantics: Boolean binary has Integer payload";
            end if;

            Adac.Types.validate (checked.expected_type);
            declare
              target_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.target_local));
              left_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.source_local));
              right_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.right_source_local));


              left_value : Adac.Types.Boolean_Value;
              right_value : Adac.Types.Boolean_Value;
            begin
              if checked.expected_type /=
                   object_type (self, target_entity) or else
                 checked.expected_type /=
                   object_type (self, left_entity) or else
                 checked.expected_type /= object_type (self, right_entity)
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean binary type is invalid";
              end if;
              if object_subtype_constraint (self, target_entity) /=
                   NO_SUBTYPE_CONSTRAINT or else
                 object_subtype_constraint (self, left_entity) /=
                   NO_SUBTYPE_CONSTRAINT or else
                 object_subtype_constraint (self, right_entity) /=
                   NO_SUBTYPE_CONSTRAINT
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean binary object has constraint";
              end if;

              left_value := temporary_boolean_source_value
                (self,
                 statements,
                 index,
                 left_entity,
                 Positive (checked.source_local),
                 checked.source_definition_statement);
              right_value := temporary_boolean_source_value
                (self,
                 statements,
                 index,
                 right_entity,
                 Positive (checked.right_source_local),
                 checked.right_source_definition_statement);
              if boolean_binary_value
                (checked.boolean_operator, left_value, right_value) /=
                checked.boolean_value
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean binary known result is invalid";
              end if;
            end;

          when Local_Boolean_And_Then_Assignment_Statement |
               Local_Boolean_Or_Else_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count or else
               checked.source_local = 0 or else
               checked.source_local > relation_count or else
               checked.right_source_local = 0 or else
               checked.right_source_local > relation_count or else
               checked.integer_value /= 0
            then
              raise Program_Error with
                "Adac.Semantics: Boolean short-circuit local is invalid";
            end if;

            Adac.Types.validate (checked.expected_type);
            declare
              target_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.target_local));
              left_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.source_local));
              right_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.right_source_local));
              left_value : Adac.Types.Boolean_Value;
              right_value : Adac.Types.Boolean_Value;
            begin
              if checked.expected_type /= object_type (self, target_entity) or else
                 checked.expected_type /= object_type (self, left_entity) or else
                 checked.expected_type /= object_type (self, right_entity)
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean short-circuit type is invalid";
              end if;
              if object_subtype_constraint (self, target_entity) /=
                   NO_SUBTYPE_CONSTRAINT or else
                 object_subtype_constraint (self, left_entity) /=
                   NO_SUBTYPE_CONSTRAINT or else
                 object_subtype_constraint (self, right_entity) /=
                   NO_SUBTYPE_CONSTRAINT
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean short-circuit object has constraint";
              end if;

              left_value := temporary_boolean_source_value
                (self,
                 statements,
                 index,
                 left_entity,
                 Positive (checked.source_local),
                 checked.source_definition_statement);
              right_value := temporary_boolean_source_value
                (self,
                 statements,
                 index,
                 right_entity,
                 Positive (checked.right_source_local),
                 checked.right_source_definition_statement);
              if boolean_short_circuit_value
                   (checked.kind, left_value, right_value) /=
                 checked.boolean_value
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean short-circuit known result is " &
                  "invalid";
              end if;
            end;

                  when Local_Boolean_Expression_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count or else
               checked.integer_value /= 0 or else
               checked.boolean_operator /= No_Boolean_Binary_Operator or else
               checked.source_local /= 0 or else
               checked.source_definition_statement /= 0 or else
               checked.right_source_local /= 0 or else
               checked.right_source_definition_statement /= 0
            then
              raise Program_Error with
                "Adac.Semantics: Boolean expression assignment metadata is invalid";
            end if;
            Adac.Types.validate (checked.expected_type);
            declare
              target_entity : constant Entity_ID :=
                entity_list_element
                  (locals, Positive (checked.target_local));
            begin
              if checked.expected_type /= object_type (self, target_entity) or else
                 object_subtype_constraint (self, target_entity) /=
                   NO_SUBTYPE_CONSTRAINT
              then
                raise Program_Error with
                  "Adac.Semantics: Boolean expression target type is invalid";
              end if;
            end;

            for value_index in 1 .. checked.boolean_expression_value_count loop
              declare
                expression_value : constant Boolean_Expression_Value_Record :=
                  statements.boolean_expression_values
                    (Positive
                       (checked.first_boolean_expression_value +
                        value_index - 1));
              begin
                if expression_value.kind = Boolean_Expression_Local_Value then
                  if expression_value.source_local > relation_count then
                    raise Program_Error with
                      "Adac.Semantics: Boolean expression source is out of range";
                  end if;
                  declare
                    source_entity : constant Entity_ID :=
                      entity_list_element
                        (locals, Positive (expression_value.source_local));
                    source_value : constant Adac.Types.Boolean_Value :=
                      temporary_boolean_source_value
                        (self,
                         statements,
                         index,
                         source_entity,
                         Positive (expression_value.source_local),
                         expression_value.source_definition_statement);
                  begin
                    if checked.expected_type /= object_type (self, source_entity) or else
                       object_subtype_constraint (self, source_entity) /=
                         NO_SUBTYPE_CONSTRAINT or else
                       source_value /= expression_value.boolean_value
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean expression source is invalid";
                    end if;
                  end;
                end if;
              end;
            end loop;

          when Local_Integer_Copy_Assignment_Statement =>
            if checked.target_local = 0 or else
               checked.target_local > relation_count or else
               checked.source_local = 0 or else
               checked.source_local > relation_count
            then
              raise Program_Error with
                "Adac.Semantics: copy assignment local is out of range";
            end if;
            if checked.boolean_value /= Adac.Types.False_Boolean_Value then
              raise Program_Error with
                "Adac.Semantics: Integer copy has Boolean payload";
            end if;

            Adac.Types.validate (checked.expected_type);
            if checked.expected_type /=
                 object_type
                   (self,
                    entity_list_element
                      (locals, Positive (checked.target_local))) or else
               checked.expected_type /=
                 object_type
                   (self,
                    entity_list_element
                      (locals, Positive (checked.source_local)))
            then
              raise Program_Error with
                "Adac.Semantics: copy assignment type is invalid";
            end if;
            if not subtype_constraint_contains
              (object_subtype_constraint
                 (self,
                  entity_list_element
                    (locals, Positive (checked.target_local))),
               checked.integer_value)
            then
              raise Program_Error with
                "Adac.Semantics: copy assignment violates target constraint";
            end if;

            if checked.source_definition_statement = 0 then
              if not object_has_integer_initializer
                (self,
                 entity_list_element
                   (locals, Positive (checked.source_local)))
              then
                raise Program_Error with
                  "Adac.Semantics: copy source has no defining initializer";
              end if;
              if object_integer_initializer
                   (self,
                    entity_list_element
                      (locals, Positive (checked.source_local))) /=
                 checked.integer_value
              then
                raise Program_Error with
                  "Adac.Semantics: copy source value disagrees with " &
                  "initializer";
              end if;
            else
              if checked.source_definition_statement >= index then
                raise Program_Error with
                  "Adac.Semantics: copy source definition is not earlier";
              end if;

              declare
                definition : constant Procedure_Statement_Record :=
                  statements.items
                    (Positive (checked.source_definition_statement));
              begin
                if not is_integer_assignment_kind (definition.kind) or else
                   definition.target_local /= checked.source_local or else
                   definition.integer_value /= checked.integer_value
                then
                  raise Program_Error with
                    "Adac.Semantics: copy source definition is invalid";
                end if;
              end;
            end if;
        end case;
      end;
    end loop;
    if next_expression_value /= checked_expression_value_count + 1 then
      raise Program_Error with
        "Adac.Semantics: Boolean expression values are not fully owned";
    end if;
    end;

    if binding_count > 0 then
      if self.scope_bindings.length >
           Ada.Containers.Count_Type (Positive'Last - binding_count)
      then
        raise Storage_Error with
          "Adac.Semantics: lexical scope binding capacity exhausted";
      end if;
      first_scope_binding := Natural (self.scope_bindings.length) + 1;
    end if;

    if relation_count > 0 then
      if self.relations.length >
           Ada.Containers.Count_Type (Positive'Last - relation_count)
      then
        raise Storage_Error with
          "Adac.Semantics: entity relation capacity exhausted";
      end if;
      first_relation := Natural (self.relations.length) + 1;
    end if;

    if checked_statement_count > 0 then
      if self.statements.length >
           Ada.Containers.Count_Type (Positive'Last - checked_statement_count)
      then
        raise Storage_Error with
          "Adac.Semantics: statement capacity exhausted";
      end if;
      first_statement := Natural (self.statements.length) + 1;
    end if;

    if checked_expression_value_count > 0 then
      if self.boolean_expression_values.length >
           Ada.Containers.Count_Type
             (Positive'Last - checked_expression_value_count)
      then
        raise Storage_Error with
          "Adac.Semantics: Boolean expression value capacity exhausted";
      end if;
      first_boolean_expression_value :=
        Natural (self.boolean_expression_values.length) + 1;
    end if;

    result := next_entity_id (self);

    begin
      for index in 1 .. binding_count loop
        declare
          binding : constant Scope_Binding_Record := scope.bindings (index);
          key : constant Procedure_Scope_Lookup_Key :=
            (procedure_entity_index => Positive (result.index),
             symbol_ordinal         => Positive (binding.symbol_ordinal));
        begin
          self.scope_bindings.append (binding);
          self.scope_lookup.insert (key, Positive (index));
        end;
      end loop;

      for index in 1 .. relation_count loop
        self.relations.append
          (Positive (entity_list_element (locals, index).index));
      end loop;

      for index in 1 .. checked_expression_value_count loop
        declare
          item : Boolean_Expression_Value_Record :=
            statements.boolean_expression_values (index);
          offset : constant Natural := first_boolean_expression_value - 1;
        begin
          if item.operand_value /= 0 then
            item.operand_value := item.operand_value + offset;
          end if;
          if item.right_operand_value /= 0 then
            item.right_operand_value := item.right_operand_value + offset;
          end if;
          self.boolean_expression_values.append (item);
        end;
      end loop;

      for index in 1 .. checked_statement_count loop
        declare
          item : Procedure_Statement_Record := statements.items (index);
        begin
          if item.first_boolean_expression_value /= 0 then
            item.first_boolean_expression_value :=
              item.first_boolean_expression_value +
              first_boolean_expression_value - 1;
          end if;
          self.statements.append (item);
        end;
      end loop;

      self.entities.append
        (Entity_Record'
           (kind                    => Procedure_Body_Entity,
            declaration             => declaration,
            symbol                  => symbol,
            span                    => span,
            semantic_type           => Adac.Types.INVALID_TYPE_ID,
            has_integer_initializer => False,
            integer_initializer     => 0,
            has_boolean_initializer => False,
            boolean_initializer     => Adac.Types.False_Boolean_Value,
            constraint_value        => NO_SUBTYPE_CONSTRAINT,
            first_scope_binding     => first_scope_binding,
            scope_binding_count     => binding_count,
            first_local_relation    => first_relation,
            local_count             => relation_count,
            first_statement         => first_statement,
            statement_count         => checked_statement_count,
            first_boolean_expression_value => first_boolean_expression_value,
            boolean_expression_value_count => checked_expression_value_count));
    exception
      when others =>
        rollback_publication;
        raise;
    end;

    return result;
  end append_procedure;

  function entity_count (self : Store) return Natural is
  begin
    validate_store (self);
    return Natural (self.entities.length);
  end entity_count;

  function kind_of
    (self   : Store;
     entity : Entity_ID)
  return Entity_Kind is
  begin
    validate_entity_id (self, entity);
    return self.entities (Positive (entity.index)).kind;
  end kind_of;

  function declaration
    (self   : Store;
     entity : Entity_ID)
  return Adac.AST.Node_ID is
  begin
    validate_entity_id (self, entity);
    return self.entities (Positive (entity.index)).declaration;
  end declaration;

  function symbol
    (self   : Store;
     entity : Entity_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    validate_entity_id (self, entity);
    return self.entities (Positive (entity.index)).symbol;
  end symbol;

  function entity_span
    (self   : Store;
     entity : Entity_ID)
  return Adac.Source.Span is
  begin
    validate_entity_id (self, entity);
    return self.entities (Positive (entity.index)).span;
  end entity_span;

  function object_type
    (self   : Store;
     entity : Entity_ID)
  return Adac.Types.Type_ID is
  begin
    require_kind (self, entity, Object_Entity);
    return self.entities (Positive (entity.index)).semantic_type;
  end object_type;

  function object_subtype_constraint
    (self   : Store;
     entity : Entity_ID)
  return Subtype_Constraint is
    result : Subtype_Constraint;
  begin
    require_kind (self, entity, Object_Entity);
    result := self.entities (Positive (entity.index)).constraint_value;
    validate (result);
    return result;
  end object_subtype_constraint;

  function object_has_integer_initializer
    (self   : Store;
     entity : Entity_ID)
  return Boolean is
  begin
    require_kind (self, entity, Object_Entity);
    return self.entities (Positive (entity.index)).has_integer_initializer;
  end object_has_integer_initializer;

  function object_integer_initializer
    (self   : Store;
     entity : Entity_ID)
  return Long_Long_Integer is
  begin
    require_kind (self, entity, Object_Entity);

    if not self.entities (Positive (entity.index)).has_integer_initializer then
      raise Program_Error with
        "Adac.Semantics: object has no integer initializer";
    end if;

    return self.entities (Positive (entity.index)).integer_initializer;
  end object_integer_initializer;

  function object_has_boolean_initializer
    (self   : Store;
     entity : Entity_ID)
  return Boolean is
  begin
    require_kind (self, entity, Object_Entity);
    return self.entities (Positive (entity.index)).has_boolean_initializer;
  end object_has_boolean_initializer;

  function object_boolean_initializer
    (self   : Store;
     entity : Entity_ID)
  return Adac.Types.Boolean_Value is
  begin
    require_kind (self, entity, Object_Entity);
    if not self.entities (Positive (entity.index)).has_boolean_initializer then
      raise Program_Error with
        "Adac.Semantics: object has no Boolean initializer";
    end if;
    return self.entities (Positive (entity.index)).boolean_initializer;
  end object_boolean_initializer;

  function procedure_local_count
    (self             : Store;
     procedure_entity : Entity_ID)
  return Natural is
  begin
    require_kind (self, procedure_entity, Procedure_Body_Entity);
    return self.entities (Positive (procedure_entity.index)).local_count;
  end procedure_local_count;

  function procedure_local_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Entity_ID is
    value : Entity_Record;
    relation_index : Natural;
    local_index : Positive;
  begin
    require_kind (self, procedure_entity, Procedure_Body_Entity);
    value := self.entities (Positive (procedure_entity.index));

    if index > value.local_count then
      raise Program_Error with
        "Adac.Semantics: procedure local index out of range";
    end if;

    relation_index := value.first_local_relation + index - 1;
    if relation_index = 0 or else
       relation_index > Natural (self.relations.length)
    then
      raise Program_Error with
        "Adac.Semantics: procedure local relation is invalid";
    end if;

    local_index := self.relations (Positive (relation_index));
    if local_index >= procedure_entity.index then
      raise Program_Error with
        "Adac.Semantics: procedure local is not an earlier entity";
    end if;

    return (owner => self.marker'unchecked_access,
            index => Natural (local_index));
  end procedure_local_at;

  function procedure_scope_binding_count
    (self             : Store;
     procedure_entity : Entity_ID)
  return Natural is
  begin
    require_kind (self, procedure_entity, Procedure_Body_Entity);
    return self.entities
      (Positive (procedure_entity.index)).scope_binding_count;
  end procedure_scope_binding_count;

  function procedure_scope_binding_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Scope_Binding_Record is
    value : Entity_Record;
    binding_index : Natural;
  begin
    require_kind (self, procedure_entity, Procedure_Body_Entity);
    value := self.entities (Positive (procedure_entity.index));
    if index > value.scope_binding_count then
      raise Program_Error with
        "Adac.Semantics: procedure scope binding index out of range";
    end if;

    binding_index := value.first_scope_binding + index - 1;
    if binding_index = 0 or else
       binding_index > Natural (self.scope_bindings.length)
    then
      raise Program_Error with
        "Adac.Semantics: procedure scope binding range is invalid";
    end if;

    return self.scope_bindings (Positive (binding_index));
  end procedure_scope_binding_at;

  function procedure_scope_binding_kind_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Scope_Binding_Kind is
  begin
    return procedure_scope_binding_at (self, procedure_entity, index).kind;
  end procedure_scope_binding_kind_at;

  function procedure_scope_binding_symbol_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    return procedure_scope_binding_at (self, procedure_entity, index).symbol;
  end procedure_scope_binding_symbol_at;

  function procedure_scope_binding_local_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Object_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a local object";
    end if;
    return Positive (binding.local_ordinal);
  end procedure_scope_binding_local_at;

  function procedure_scope_binding_subtype_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Subtype_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a local subtype";
    end if;
    return binding.subtype_declaration;
  end procedure_scope_binding_subtype_declaration_at;

  function procedure_scope_binding_subtype_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Subtype_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a local subtype";
    end if;
    return binding.semantic_type;
  end procedure_scope_binding_subtype_type_at;

  function procedure_scope_binding_subtype_constraint_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Subtype_Constraint is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Subtype_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a local subtype";
    end if;
    validate (binding.constraint_value);
    return binding.constraint_value;
  end procedure_scope_binding_subtype_constraint_at;

  function procedure_scope_binding_static_constant_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Static_Integer_Constant_Binding and then
       binding.kind /= Local_Static_Boolean_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a static constant";
    end if;
    return binding.static_constant_declaration;
  end procedure_scope_binding_static_constant_declaration_at;

  function procedure_scope_binding_static_constant_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Static_Integer_Constant_Binding and then
       binding.kind /= Local_Static_Boolean_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a static constant";
    end if;
    return binding.semantic_type;
  end procedure_scope_binding_static_constant_type_at;

  function procedure_scope_binding_static_constant_constraint_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Subtype_Constraint is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Static_Integer_Constant_Binding and then
       binding.kind /= Local_Static_Boolean_Constant_Binding
    then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a static constant";
    end if;
    validate (binding.constraint_value);
    return binding.constraint_value;
  end procedure_scope_binding_static_constant_constraint_at;

  function procedure_scope_binding_static_constant_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Long_Long_Integer is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Static_Integer_Constant_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a static constant";
    end if;
    return binding.static_constant_value;
  end procedure_scope_binding_static_constant_value_at;

  function procedure_scope_binding_static_boolean_constant_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Static_Boolean_Constant_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a static Boolean constant";
    end if;
    return binding.static_boolean_constant_value;
  end procedure_scope_binding_static_boolean_constant_value_at;

  function procedure_scope_binding_integer_number_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Integer_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not an integer named number";
    end if;
    return binding.number_declaration;
  end procedure_scope_binding_integer_number_declaration_at;

  function procedure_scope_binding_integer_number_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Integer_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not an integer named number";
    end if;
    return binding.semantic_type;
  end procedure_scope_binding_integer_number_type_at;

  function procedure_scope_binding_integer_number_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Integer_Value is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
    result : Adac.Types.Universal_Integer_Value;
  begin
    if binding.kind /= Local_Integer_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not an integer named number";
    end if;
    result := binding.integer_number_value;
    Adac.Types.validate (result);
    return result;
  end procedure_scope_binding_integer_number_value_at;

  function procedure_scope_binding_real_number_declaration_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Real_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a real named number";
    end if;
    return binding.number_declaration;
  end procedure_scope_binding_real_number_declaration_at;

  function procedure_scope_binding_real_number_type_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
  begin
    if binding.kind /= Local_Real_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a real named number";
    end if;
    return binding.semantic_type;
  end procedure_scope_binding_real_number_type_at;

  function procedure_scope_binding_real_number_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Real_Value is
    binding : constant Scope_Binding_Record :=
      procedure_scope_binding_at (self, procedure_entity, index);
    result : Adac.Types.Universal_Real_Value;
  begin
    if binding.kind /= Local_Real_Number_Binding then
      raise Program_Error with
        "Adac.Semantics: procedure binding is not a real named number";
    end if;
    result := binding.real_number_value;
    Adac.Types.validate (result);
    return result;
  end procedure_scope_binding_real_number_value_at;

  function procedure_scope_binding_index_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural is
    value : Entity_Record;
    symbol_ordinal : Positive;
    key : Procedure_Scope_Lookup_Key;
    binding_index : Positive;
  begin
    require_kind (self, procedure_entity, Procedure_Body_Entity);
    value := self.entities (Positive (procedure_entity.index));
    symbol_ordinal := Adac.Symbols.ordinal (symbols, symbol);
    key :=
      (procedure_entity_index => Positive (procedure_entity.index),
       symbol_ordinal         => symbol_ordinal);

    if not self.scope_lookup.contains (key) then
      return 0;
    end if;

    binding_index := self.scope_lookup.element (key);
    if binding_index > value.scope_binding_count then
      raise Program_Error with
        "Adac.Semantics: procedure scope lookup index is invalid";
    end if;
    return Natural (binding_index);
  end procedure_scope_binding_index_for_symbol;

  function procedure_local_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural is
    binding_index : constant Natural :=
      procedure_scope_binding_index_for_symbol
        (self, procedure_entity, symbols, symbol);
  begin
    if binding_index = 0 then
      return 0;
    end if;

    declare
      binding : constant Scope_Binding_Record :=
        procedure_scope_binding_at
          (self, procedure_entity, Positive (binding_index));
    begin
      if binding.kind /= Local_Object_Binding then
        return 0;
      end if;
      return binding.local_ordinal;
    end;
  end procedure_local_for_symbol;

  function procedure_subtype_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    binding_index : constant Natural :=
      procedure_scope_binding_index_for_symbol
        (self, procedure_entity, symbols, symbol);
  begin
    if binding_index = 0 then
      return Adac.Types.INVALID_TYPE_ID;
    end if;

    declare
      binding : constant Scope_Binding_Record :=
        procedure_scope_binding_at
          (self, procedure_entity, Positive (binding_index));
    begin
      if binding.kind /= Local_Subtype_Binding then
        return Adac.Types.INVALID_TYPE_ID;
      end if;
      return binding.semantic_type;
    end;
  end procedure_subtype_for_symbol;

  function procedure_subtype_constraint_for_symbol
    (self             : Store;
     procedure_entity : Entity_ID;
     symbols          : Adac.Symbols.Store;
     symbol           : Adac.Symbols.Symbol_ID)
  return Subtype_Constraint is
    binding_index : constant Natural :=
      procedure_scope_binding_index_for_symbol
        (self, procedure_entity, symbols, symbol);
  begin
    if binding_index = 0 then
      raise Program_Error with
        "Adac.Semantics: procedure subtype constraint symbol is absent";
    end if;

    declare
      binding : constant Scope_Binding_Record :=
        procedure_scope_binding_at
          (self, procedure_entity, Positive (binding_index));
    begin
      if binding.kind /= Local_Subtype_Binding then
        raise Program_Error with
          "Adac.Semantics: procedure binding is not a local subtype";
      end if;
      validate (binding.constraint_value);
      return binding.constraint_value;
    end;
  end procedure_subtype_constraint_for_symbol;

  function statement_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Procedure_Statement_Record is
    value           : Entity_Record;
    statement_index : Natural;
  begin
    require_kind (self, procedure_entity, Procedure_Body_Entity);
    value := self.entities (Positive (procedure_entity.index));

    if index > value.statement_count then
      raise Program_Error with
        "Adac.Semantics: procedure statement index out of range";
    end if;

    statement_index := value.first_statement + index - 1;
    if statement_index = 0 or else
       statement_index > Natural (self.statements.length)
    then
      raise Program_Error with
        "Adac.Semantics: procedure statement range is invalid";
    end if;

    return self.statements (Positive (statement_index));
  end statement_at;

  function stored_boolean_source_value
    (self              : Store;
     procedure_entity  : Entity_ID;
     current_statement : Positive;
     source_entity     : Entity_ID;
     source_local      : Positive;
     definition_index  : Natural)
  return Adac.Types.Boolean_Value is
  begin
    if definition_index = 0 then
      if not object_has_boolean_initializer (self, source_entity) then
        raise Program_Error with
          "Adac.Semantics: Boolean source lacks initializer";
      end if;
      return object_boolean_initializer (self, source_entity);
    end if;
    if definition_index >= current_statement then
      raise Program_Error with
        "Adac.Semantics: Boolean source definition is not earlier";
    end if;
    declare
      definition : constant Procedure_Statement_Record :=
        statement_at
          (self, procedure_entity, Positive (definition_index));
    begin
      if not is_boolean_assignment_kind (definition.kind) or else
         definition.target_local /= source_local
      then
        raise Program_Error with
          "Adac.Semantics: Boolean source definition is invalid";
      end if;
      return definition.boolean_value;
    end;
  end stored_boolean_source_value;

  function procedure_statement_count
    (self             : Store;
     procedure_entity : Entity_ID)
  return Natural is
  begin
    require_kind (self, procedure_entity, Procedure_Body_Entity);
    return self.entities (Positive (procedure_entity.index)).statement_count;
  end procedure_statement_count;

  function procedure_statement_kind_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Procedure_Statement_Kind is
  begin
    return statement_at (self, procedure_entity, index).kind;
  end procedure_statement_kind_at;

  function procedure_statement_syntax
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
  begin
    return statement_at (self, procedure_entity, index).syntax;
  end procedure_statement_syntax;

  function assignment_target_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if not is_assignment_kind (checked.kind) then
      raise Program_Error with
        "Adac.Semantics: statement is not a local assignment";
    end if;
    return Positive (checked.target_local);
  end assignment_target_local;

  function assignment_expected_type
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if not is_assignment_kind (checked.kind) then
      raise Program_Error with
        "Adac.Semantics: statement is not a local assignment";
    end if;
    return checked.expected_type;
  end assignment_expected_type;

  function assignment_integer_value
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Long_Long_Integer is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if not is_integer_assignment_kind (checked.kind) then
      raise Program_Error with
        "Adac.Semantics: statement is not an Integer assignment";
    end if;
    return checked.integer_value;
  end assignment_integer_value;

  function assignment_boolean_value
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if not is_boolean_assignment_kind (checked.kind) then
      raise Program_Error with
        "Adac.Semantics: statement is not a Boolean assignment";
    end if;
    return checked.boolean_value;
  end assignment_boolean_value;

  function assignment_boolean_operator
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Boolean_Binary_Operator_Kind is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if checked.kind /= Local_Boolean_Binary_Assignment_Statement then
      raise Program_Error with
        "Adac.Semantics: statement is not a Boolean binary assignment";
    end if;
    if checked.boolean_operator = No_Boolean_Binary_Operator then
      raise Program_Error with
        "Adac.Semantics: Boolean binary assignment has no operator";
    end if;
    return checked.boolean_operator;
  end assignment_boolean_operator;

  function assignment_source_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if not is_source_reading_assignment_kind (checked.kind) then
      raise Program_Error with
        "Adac.Semantics: statement has no local source read";
    end if;
    return Positive (checked.source_local);
  end assignment_source_local;

  function assignment_source_definition_statement
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Natural is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if not is_source_reading_assignment_kind (checked.kind) then
      raise Program_Error with
        "Adac.Semantics: statement has no local source read";
    end if;
    return checked.source_definition_statement;
  end assignment_source_definition_statement;

  function assignment_right_source_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Positive is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if checked.kind /= Local_Boolean_Binary_Assignment_Statement and then
       checked.kind /= Local_Boolean_And_Then_Assignment_Statement and then
       checked.kind /= Local_Boolean_Or_Else_Assignment_Statement
    then
      raise Program_Error with
        "Adac.Semantics: statement has no right local source read";
    end if;
    return Positive (checked.right_source_local);
  end assignment_right_source_local;

  function assignment_right_source_definition_statement
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Natural is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if checked.kind /= Local_Boolean_Binary_Assignment_Statement and then
       checked.kind /= Local_Boolean_And_Then_Assignment_Statement and then
       checked.kind /= Local_Boolean_Or_Else_Assignment_Statement
    then
      raise Program_Error with
        "Adac.Semantics: statement has no right source definition";
    end if;
    return checked.right_source_definition_statement;
  end assignment_right_source_definition_statement;

  function assignment_boolean_expression_value_at
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Boolean_Expression_Value_Record is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if checked.kind /= Local_Boolean_Expression_Assignment_Statement or else
       value_index > checked.boolean_expression_value_count
    then
      raise Program_Error with
        "Adac.Semantics: Boolean expression value index is invalid";
    end if;
    return self.boolean_expression_values
      (Positive (checked.first_boolean_expression_value + value_index - 1));
  end assignment_boolean_expression_value_at;

  function assignment_boolean_expression_value_count
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive)
  return Natural is
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if checked.kind /= Local_Boolean_Expression_Assignment_Statement then
      raise Program_Error with
        "Adac.Semantics: statement has no Boolean expression tree";
    end if;
    return checked.boolean_expression_value_count;
  end assignment_boolean_expression_value_count;

  function assignment_boolean_expression_value_kind
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Boolean_Expression_Value_Kind is
  begin
    return assignment_boolean_expression_value_at
      (self, procedure_entity, index, value_index).kind;
  end assignment_boolean_expression_value_kind;

  function assignment_boolean_expression_syntax
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.AST.Node_ID is
  begin
    return assignment_boolean_expression_value_at
      (self, procedure_entity, index, value_index).syntax;
  end assignment_boolean_expression_syntax;

  function assignment_boolean_expression_known_value
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Types.Boolean_Value is
  begin
    return assignment_boolean_expression_value_at
      (self, procedure_entity, index, value_index).boolean_value;
  end assignment_boolean_expression_known_value;

  function assignment_boolean_expression_source_local
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive is
    item : constant Boolean_Expression_Value_Record :=
      assignment_boolean_expression_value_at
        (self, procedure_entity, index, value_index);
  begin
    if item.kind /= Boolean_Expression_Local_Value then
      raise Program_Error with
        "Adac.Semantics: Boolean expression value is not a local read";
    end if;
    return Positive (item.source_local);
  end assignment_boolean_expression_source_local;

  function assignment_boolean_expression_source_definition
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Natural is
    item : constant Boolean_Expression_Value_Record :=
      assignment_boolean_expression_value_at
        (self, procedure_entity, index, value_index);
  begin
    if item.kind /= Boolean_Expression_Local_Value then
      raise Program_Error with
        "Adac.Semantics: Boolean expression value is not a local read";
    end if;
    return item.source_definition_statement;
  end assignment_boolean_expression_source_definition;

  function assignment_boolean_expression_operator
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Boolean_Binary_Operator_Kind is
    item : constant Boolean_Expression_Value_Record :=
      assignment_boolean_expression_value_at
        (self, procedure_entity, index, value_index);
  begin
    if item.kind /= Boolean_Expression_Binary_Value then
      raise Program_Error with
        "Adac.Semantics: Boolean expression value is not binary";
    end if;
    return item.boolean_operator;
  end assignment_boolean_expression_operator;

  function assignment_boolean_expression_operand
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive is
    item : constant Boolean_Expression_Value_Record :=
      assignment_boolean_expression_value_at
        (self, procedure_entity, index, value_index);
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if item.kind /= Boolean_Expression_Not_Value and then
       item.kind /= Boolean_Expression_Binary_Value
    then
      raise Program_Error with
        "Adac.Semantics: Boolean expression value has no operand";
    end if;
    return Positive
      (item.operand_value - checked.first_boolean_expression_value + 1);
  end assignment_boolean_expression_operand;

  function assignment_boolean_expression_right_operand
    (self             : Store;
     procedure_entity : Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive is
    item : constant Boolean_Expression_Value_Record :=
      assignment_boolean_expression_value_at
        (self, procedure_entity, index, value_index);
    checked : constant Procedure_Statement_Record :=
      statement_at (self, procedure_entity, index);
  begin
    if item.kind /= Boolean_Expression_Binary_Value then
      raise Program_Error with
        "Adac.Semantics: Boolean expression value has no right operand";
    end if;
    return Positive
      (item.right_operand_value - checked.first_boolean_expression_value + 1);
  end assignment_boolean_expression_right_operand;

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
      value : Entity_Record renames self.entities (Positive (entity.index));
    begin
      Adac.AST.validate (value.declaration);
      Adac.Symbols.validate (value.symbol);
      Adac.Source.validate (value.span);

      case value.kind is
        when Object_Entity =>
          Adac.Types.validate (value.semantic_type);
          validate (value.constraint_value);
          if value.has_integer_initializer and then
             value.has_boolean_initializer
          then
            raise Program_Error with
              "Adac.Semantics: object has multiple initializer kinds";
          end if;
          if not value.has_integer_initializer and then
             value.integer_initializer /= 0
          then
            raise Program_Error with
              "Adac.Semantics: object has stray integer initializer value";
          end if;
          if not value.has_boolean_initializer and then
             value.boolean_initializer /= Adac.Types.False_Boolean_Value
          then
            raise Program_Error with
              "Adac.Semantics: object has stray Boolean initializer value";
          end if;

          if value.has_integer_initializer and then
             not subtype_constraint_contains
               (value.constraint_value, value.integer_initializer)
          then
            raise Program_Error with
              "Adac.Semantics: object initializer violates subtype constraint";
          end if;
          if value.has_boolean_initializer and then
             value.constraint_value /= NO_SUBTYPE_CONSTRAINT
          then
            raise Program_Error with
              "Adac.Semantics: Boolean object has subtype constraint";
          end if;

          if value.first_scope_binding /= 0 or else
             value.scope_binding_count /= 0 or else
             value.first_local_relation /= 0 or else
             value.local_count /= 0 or else
             value.first_statement /= 0 or else
             value.statement_count /= 0 or else
             value.first_boolean_expression_value /= 0 or else
             value.boolean_expression_value_count /= 0
          then
            raise Program_Error with
              "Adac.Semantics: object entity owns procedure state";
          end if;

        when Procedure_Body_Entity =>
          if value.semantic_type /= Adac.Types.INVALID_TYPE_ID or else
             value.has_integer_initializer or else
             value.integer_initializer /= 0 or else
             value.has_boolean_initializer or else
             value.boolean_initializer /= Adac.Types.False_Boolean_Value or else
             value.constraint_value /= NO_SUBTYPE_CONSTRAINT
          then
            raise Program_Error with
              "Adac.Semantics: procedure entity has object state";
          end if;

          if value.local_count = 0 then
            if value.first_local_relation /= 0 then
              raise Program_Error with
                "Adac.Semantics: empty procedure local range is invalid";
            end if;
          else
            if value.first_local_relation = 0 or else
               value.first_local_relation >
                 Natural (self.relations.length) or else
               value.local_count >
                 Natural (self.relations.length) -
                 value.first_local_relation + 1
            then
              raise Program_Error with
                "Adac.Semantics: procedure local range is invalid";
            end if;
          end if;

          if value.scope_binding_count = 0 then
            if value.first_scope_binding /= 0 then
              raise Program_Error with
                "Adac.Semantics: empty procedure scope range is invalid";
            end if;
          else
            if value.first_scope_binding = 0 or else
               value.first_scope_binding >
                 Natural (self.scope_bindings.length) or else
               value.scope_binding_count >
                 Natural (self.scope_bindings.length) -
                 value.first_scope_binding + 1
            then
              raise Program_Error with
                "Adac.Semantics: procedure scope binding range is invalid";
            end if;

            declare
              object_binding_count : Natural := 0;
            begin
              for index in 1 .. value.scope_binding_count loop
                declare
                  binding_index : constant Positive :=
                    Positive (value.first_scope_binding + index - 1);
                  binding : constant Scope_Binding_Record :=
                    self.scope_bindings (binding_index);
                  key : Procedure_Scope_Lookup_Key;
                begin
                  Adac.Symbols.validate (binding.symbol);
                  if binding.symbol_ordinal = 0 then
                    raise Program_Error with
                      "Adac.Semantics: procedure scope symbol ordinal " &
                      "is invalid";
                  end if;
                  key :=
                    (procedure_entity_index => Positive (entity.index),
                     symbol_ordinal => Positive (binding.symbol_ordinal));
                  if not self.scope_lookup.contains (key) or else
                     self.scope_lookup.element (key) /= index
                  then
                    raise Program_Error with
                      "Adac.Semantics: procedure scope lookup mismatch";
                  end if;

                  case binding.kind is
                    when Local_Object_Binding =>
                      object_binding_count := object_binding_count + 1;
                      if binding.local_ordinal /= object_binding_count or else
                         binding.subtype_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.static_constant_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.number_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.semantic_type /=
                           Adac.Types.INVALID_TYPE_ID or else
                         binding.constraint_value /=
                           NO_SUBTYPE_CONSTRAINT or else
                         binding.static_constant_value /= 0 or else
                         binding.integer_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
                         binding.real_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
                      then
                        raise Program_Error with
                          "Adac.Semantics: procedure object binding is invalid";
                      end if;
                      declare
                        local : constant Entity_ID :=
                          procedure_local_at
                            (self, entity, Positive (binding.local_ordinal));
                      begin
                        require_kind (self, local, Object_Entity);
                        if binding.symbol /= symbol (self, local) then
                          raise Program_Error with
                            "Adac.Semantics: procedure scope/local binding " &
                            "mismatch";
                        end if;
                      end;

                    when Local_Subtype_Binding =>
                      if binding.local_ordinal /= 0 or else
                         binding.static_constant_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.number_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.static_constant_value /= 0 or else
                         binding.integer_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
                         binding.real_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
                      then
                        raise Program_Error with
                          "Adac.Semantics: procedure subtype binding " &
                          "metadata " &
                          "is invalid";
                      end if;
                      Adac.AST.validate (binding.subtype_declaration);
                      Adac.Types.validate (binding.semantic_type);
                      validate (binding.constraint_value);

                    when Local_Static_Integer_Constant_Binding =>
                      if binding.local_ordinal /= 0 or else
                         binding.subtype_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.number_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.integer_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
                         binding.real_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
                      then
                        raise Program_Error with
                          "Adac.Semantics: procedure static constant binding " &
                          "metadata is invalid";
                      end if;
                      Adac.AST.validate (binding.static_constant_declaration);
                      Adac.Types.validate (binding.semantic_type);
                      validate (binding.constraint_value);
                      if not subtype_constraint_contains
                        (binding.constraint_value,
                         binding.static_constant_value)
                      then
                        raise Program_Error with
                          "Adac.Semantics: procedure static constant " &
                          "violates " &
                          "nominal constraint";
                      end if;

                    when Local_Static_Boolean_Constant_Binding =>
                      if binding.local_ordinal /= 0 or else
                         binding.subtype_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.number_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.constraint_value /=
                           NO_SUBTYPE_CONSTRAINT or else
                         binding.static_constant_value /= 0 or else
                         binding.integer_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE or else
                         binding.real_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
                      then
                        raise Program_Error with
                          "Adac.Semantics: procedure static Boolean constant " &
                          "metadata is invalid";
                      end if;
                      Adac.AST.validate (binding.static_constant_declaration);
                      Adac.Types.validate (binding.semantic_type);

                    when Local_Integer_Number_Binding =>
                      if binding.local_ordinal /= 0 or else
                         binding.subtype_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.static_constant_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.constraint_value /=
                           NO_SUBTYPE_CONSTRAINT or else
                         binding.static_constant_value /= 0 or else
                         binding.real_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_REAL_VALUE
                      then
                        raise Program_Error with
                          "Adac.Semantics: procedure integer named-number " &
                          "metadata is invalid";
                      end if;
                      Adac.AST.validate (binding.number_declaration);
                      Adac.Types.validate (binding.semantic_type);
                      Adac.Types.validate (binding.integer_number_value);

                    when Local_Real_Number_Binding =>
                      if binding.local_ordinal /= 0 or else
                         binding.subtype_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.static_constant_declaration /=
                           Adac.AST.INVALID_NODE_ID or else
                         binding.constraint_value /=
                           NO_SUBTYPE_CONSTRAINT or else
                         binding.static_constant_value /= 0 or else
                         binding.integer_number_value /=
                           Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE
                      then
                        raise Program_Error with
                          "Adac.Semantics: procedure real named-number " &
                          "metadata is invalid";
                      end if;
                      Adac.AST.validate (binding.number_declaration);
                      Adac.Types.validate (binding.semantic_type);
                      Adac.Types.validate (binding.real_number_value);
                  end case;
                end;
              end loop;

              if object_binding_count /= value.local_count then
                raise Program_Error with
                  "Adac.Semantics: procedure object binding count mismatch";
              end if;
            end;
          end if;

          if value.boolean_expression_value_count = 0 then
            if value.first_boolean_expression_value /= 0 then
              raise Program_Error with
                "Adac.Semantics: empty Boolean expression range is invalid";
            end if;
          else
            if value.first_boolean_expression_value = 0 or else
               value.first_boolean_expression_value >
                 Natural (self.boolean_expression_values.length) or else
               value.boolean_expression_value_count >
                 Natural (self.boolean_expression_values.length) -
                 value.first_boolean_expression_value + 1
            then
              raise Program_Error with
                "Adac.Semantics: procedure Boolean expression range is invalid";
            end if;
          end if;

          if value.statement_count = 0 then
            if value.first_statement /= 0 then
              raise Program_Error with
                "Adac.Semantics: empty procedure statement range is invalid";
            end if;
          else
            if value.first_statement = 0 or else
               value.first_statement > Natural (self.statements.length) or else
               value.statement_count >
                 Natural (self.statements.length) -
                 value.first_statement + 1
            then
              raise Program_Error with
                "Adac.Semantics: procedure statement range is invalid";
            end if;

            declare
              next_expression_value : Natural :=
                value.first_boolean_expression_value;
            begin
            for index in 1 .. value.statement_count loop
              declare
                checked : constant Procedure_Statement_Record :=
                  statement_at (self, entity, index);
              begin
                if checked.kind =
                     Local_Boolean_Expression_Assignment_Statement
                then
                  if checked.first_boolean_expression_value /=
                       next_expression_value or else
                     checked.boolean_expression_value_count = 0
                  then
                    raise Program_Error with
                      "Adac.Semantics: Boolean expression statement range is " &
                      "invalid";
                  end if;
                  validate_boolean_expression_structure
                    (self.boolean_expression_values,
                     checked.first_boolean_expression_value,
                     checked.boolean_expression_value_count,
                     checked.boolean_value);
                  next_expression_value :=
                    next_expression_value +
                    checked.boolean_expression_value_count;
                elsif checked.first_boolean_expression_value /= 0 or else
                      checked.boolean_expression_value_count /= 0
                then
                  raise Program_Error with
                    "Adac.Semantics: non-expression statement owns Boolean " &
                    "expression values";
                end if;
                Adac.AST.validate (checked.syntax);
                if checked.kind = Local_Boolean_Binary_Assignment_Statement then
                  if checked.boolean_operator =
                       No_Boolean_Binary_Operator or else
                     checked.right_source_local = 0
                  then
                    raise Program_Error with
                      "Adac.Semantics: Boolean binary metadata is incomplete";
                  end if;
                elsif checked.kind =
                        Local_Boolean_And_Then_Assignment_Statement or else
                      checked.kind =
                        Local_Boolean_Or_Else_Assignment_Statement
                then
                  if checked.boolean_operator /=
                       No_Boolean_Binary_Operator or else
                     checked.right_source_local = 0
                  then
                    raise Program_Error with
                      "Adac.Semantics: Boolean short-circuit metadata is " &
                      "incomplete";
                  end if;
                elsif checked.boolean_operator /=
                        No_Boolean_Binary_Operator or else
                      checked.right_source_local /= 0 or else
                      checked.right_source_definition_statement /= 0
                then
                  raise Program_Error with
                    "Adac.Semantics: statement has unexpected Boolean binary " &
                    "metadata";
                end if;
                case checked.kind is
                  when Null_Procedure_Statement | Return_Procedure_Statement =>
                    if checked.target_local /= 0 or else
                       checked.expected_type /=
                         Adac.Types.INVALID_TYPE_ID or else
                       checked.integer_value /= 0 or else
                       checked.boolean_value /=
                         Adac.Types.False_Boolean_Value or else
                       checked.source_local /= 0 or else
                       checked.source_definition_statement /= 0
                    then
                      raise Program_Error with
                        "Adac.Semantics: simple statement metadata is invalid";
                    end if;

                  when Local_Integer_Static_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count
                    then
                      raise Program_Error with
                        "Adac.Semantics: assignment target local is invalid";
                    end if;

                    if checked.boolean_value /=
                         Adac.Types.False_Boolean_Value or else
                       checked.source_local /= 0 or else
                       checked.source_definition_statement /= 0
                    then
                      raise Program_Error with
                        "Adac.Semantics: Integer static metadata is invalid";
                    end if;

                    Adac.Types.validate (checked.expected_type);
                    if checked.expected_type /=
                       object_type
                         (self,
                          procedure_local_at
                            (self, entity, Positive (checked.target_local)))
                    then
                      raise Program_Error with
                        "Adac.Semantics: assignment expected type is invalid";
                    end if;
                    if not subtype_constraint_contains
                      (object_subtype_constraint
                         (self,
                          procedure_local_at
                            (self, entity, Positive (checked.target_local))),
                       checked.integer_value)
                    then
                      raise Program_Error with
                        "Adac.Semantics: assignment violates subtype " &
                        "constraint";
                    end if;

                  when Local_Boolean_Static_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean assignment target is invalid";
                    end if;
                    if checked.integer_value /= 0 or else
                       checked.source_local /= 0 or else
                       checked.source_definition_statement /= 0
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean static metadata is invalid";
                    end if;

                    Adac.Types.validate (checked.expected_type);
                    declare
                      target_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.target_local));
                    begin
                      if checked.expected_type /=
                        object_type (self, target_entity)
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean expected type is invalid";
                      end if;
                      if object_subtype_constraint (self, target_entity) /=
                        NO_SUBTYPE_CONSTRAINT
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean target has constraint";
                      end if;
                    end;

                  when Local_Boolean_Copy_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count or else
                       checked.source_local = 0 or else
                       checked.source_local > value.local_count
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean copy local is invalid";
                    end if;
                    if checked.integer_value /= 0 then
                      raise Program_Error with
                        "Adac.Semantics: Boolean copy has Integer payload";
                    end if;

                    Adac.Types.validate (checked.expected_type);
                    declare
                      target_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.target_local));
                      source_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.source_local));
                    begin
                      if checked.expected_type /=
                           object_type (self, target_entity) or else
                         checked.expected_type /=
                           object_type (self, source_entity)
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean copy type is invalid";
                      end if;
                      if object_subtype_constraint (self, target_entity) /=
                           NO_SUBTYPE_CONSTRAINT or else
                         object_subtype_constraint (self, source_entity) /=
                           NO_SUBTYPE_CONSTRAINT
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean copy object has constraint";
                      end if;

                      if checked.source_definition_statement = 0 then
                        if not object_has_boolean_initializer
                          (self, source_entity) or else
                           object_boolean_initializer (self, source_entity) /=
                             checked.boolean_value
                        then
                          raise Program_Error with
                            "Adac.Semantics: Boolean source initializer " &
                            "mismatch";
                        end if;
                      else
                        if checked.source_definition_statement >= index then
                          raise Program_Error with
                            "Adac.Semantics: Boolean source definition is " &
                            "not earlier";
                        end if;
                        declare
                          definition : constant Procedure_Statement_Record :=
                            statement_at
                              (self,
                               entity,
                               Positive
                                 (checked.source_definition_statement));
                        begin
                          if not is_boolean_assignment_kind
                               (definition.kind) or else
                             definition.target_local /=
                               checked.source_local or else
                             definition.boolean_value /= checked.boolean_value
                          then
                            raise Program_Error with
                              "Adac.Semantics: Boolean source definition is " &
                              "invalid";
                          end if;
                        end;
                      end if;
                    end;

                  when Local_Boolean_Not_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count or else
                       checked.source_local = 0 or else
                       checked.source_local > value.local_count
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean not local is invalid";
                    end if;
                    if checked.integer_value /= 0 then
                      raise Program_Error with
                        "Adac.Semantics: Boolean not has Integer payload";
                    end if;

                    Adac.Types.validate (checked.expected_type);
                    declare
                      target_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.target_local));
                      source_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.source_local));
                      source_value : constant Adac.Types.Boolean_Value :=
                        boolean_not_value (checked.boolean_value);
                    begin
                      if checked.expected_type /=
                           object_type (self, target_entity) or else
                         checked.expected_type /=
                           object_type (self, source_entity)
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean not type is invalid";
                      end if;
                      if object_subtype_constraint (self, target_entity) /=
                           NO_SUBTYPE_CONSTRAINT or else
                         object_subtype_constraint (self, source_entity) /=
                           NO_SUBTYPE_CONSTRAINT
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean not object has constraint";
                      end if;

                      if checked.source_definition_statement = 0 then
                        if not object_has_boolean_initializer
                          (self, source_entity) or else
                           object_boolean_initializer (self, source_entity) /=
                             source_value
                        then
                          raise Program_Error with
                            "Adac.Semantics: Boolean not source initializer " &
                            "mismatch";
                        end if;
                      else
                        if checked.source_definition_statement >=
                          index
                        then
                          raise Program_Error with
                            "Adac.Semantics: Boolean not source " &
                            "definition is not earlier";
                        end if;
                        declare
                          definition : constant Procedure_Statement_Record :=
                            statement_at
                              (self,
                               entity,
                               Positive
                                 (checked.source_definition_statement));
                        begin
                          if not is_boolean_assignment_kind
                               (definition.kind) or else
                             definition.target_local /=
                               checked.source_local or else
                             definition.boolean_value /= source_value
                          then
                            raise Program_Error with
                              "Adac.Semantics: Boolean not source definition " &
                              "is invalid";
                          end if;
                        end;
                      end if;
                    end;

                  when Local_Boolean_Binary_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count or else
                       checked.source_local = 0 or else
                       checked.source_local > value.local_count or else
                       checked.right_source_local > value.local_count
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean binary local is invalid";
                    end if;
                    if checked.integer_value /= 0 then
                      raise Program_Error with
                        "Adac.Semantics: Boolean binary has Integer payload";
                    end if;

                    Adac.Types.validate (checked.expected_type);
                    declare
                      target_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.target_local));
                      left_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.source_local));
                      right_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.right_source_local));
                      left_value : Adac.Types.Boolean_Value;
                      right_value : Adac.Types.Boolean_Value;
                    begin
                      if checked.expected_type /=
                           object_type (self, target_entity) or else
                         checked.expected_type /=
                           object_type (self, left_entity) or else
                         checked.expected_type /=
                           object_type (self, right_entity)
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean binary type is invalid";
                      end if;
                      if object_subtype_constraint (self, target_entity) /=
                           NO_SUBTYPE_CONSTRAINT or else
                         object_subtype_constraint (self, left_entity) /=
                           NO_SUBTYPE_CONSTRAINT or else
                         object_subtype_constraint (self, right_entity) /=
                           NO_SUBTYPE_CONSTRAINT
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean binary object has " &
                          "constraint";
                      end if;

                      left_value := stored_boolean_source_value
                        (self,
                         entity,
                         index,
                         left_entity,
                         Positive (checked.source_local),
                         checked.source_definition_statement);
                      right_value := stored_boolean_source_value
                        (self,
                         entity,
                         index,
                         right_entity,
                         Positive (checked.right_source_local),
                         checked.right_source_definition_statement);
                      if boolean_binary_value
                        (checked.boolean_operator, left_value, right_value) /=
                        checked.boolean_value
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean binary known result is " &
                          "invalid";
                      end if;
                    end;

                  when Local_Boolean_And_Then_Assignment_Statement |
                       Local_Boolean_Or_Else_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count or else
                       checked.source_local = 0 or else
                       checked.source_local > value.local_count or else
                       checked.right_source_local = 0 or else
                       checked.right_source_local > value.local_count or else
                       checked.integer_value /= 0
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean short-circuit local is invalid";
                    end if;

                    Adac.Types.validate (checked.expected_type);
                    declare
                      target_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.target_local));
                      left_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.source_local));
                      right_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.right_source_local));
                      left_value : Adac.Types.Boolean_Value;
                      right_value : Adac.Types.Boolean_Value;
                    begin
                      if checked.expected_type /=
                           object_type (self, target_entity) or else
                         checked.expected_type /=
                           object_type (self, left_entity) or else
                         checked.expected_type /=
                           object_type (self, right_entity)
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean short-circuit type is invalid";
                      end if;
                      if object_subtype_constraint (self, target_entity) /=
                           NO_SUBTYPE_CONSTRAINT or else
                         object_subtype_constraint (self, left_entity) /=
                           NO_SUBTYPE_CONSTRAINT or else
                         object_subtype_constraint (self, right_entity) /=
                           NO_SUBTYPE_CONSTRAINT
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean short-circuit object has " &
                          "constraint";
                      end if;

                      left_value := stored_boolean_source_value
                        (self,
                         entity,
                         index,
                         left_entity,
                         Positive (checked.source_local),
                         checked.source_definition_statement);
                      right_value := stored_boolean_source_value
                        (self,
                         entity,
                         index,
                         right_entity,
                         Positive (checked.right_source_local),
                         checked.right_source_definition_statement);
                      if boolean_short_circuit_value
                           (checked.kind, left_value, right_value) /=
                         checked.boolean_value
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean short-circuit known result is " &
                          "invalid";
                      end if;
                    end;

                  when Local_Boolean_Expression_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count or else
                       checked.integer_value /= 0 or else
                       checked.boolean_operator /= No_Boolean_Binary_Operator or else
                       checked.source_local /= 0 or else
                       checked.source_definition_statement /= 0 or else
                       checked.right_source_local /= 0 or else
                       checked.right_source_definition_statement /= 0
                    then
                      raise Program_Error with
                        "Adac.Semantics: Boolean expression assignment " &
                        "metadata is invalid";
                    end if;
                    Adac.Types.validate (checked.expected_type);
                    declare
                      target_entity : constant Entity_ID :=
                        procedure_local_at
                          (self, entity, Positive (checked.target_local));
                    begin
                      if checked.expected_type /=
                           object_type (self, target_entity) or else
                         object_subtype_constraint (self, target_entity) /=
                           NO_SUBTYPE_CONSTRAINT
                      then
                        raise Program_Error with
                          "Adac.Semantics: Boolean expression target is " &
                          "invalid";
                      end if;
                    end;

                    for expression_index in
                      1 .. checked.boolean_expression_value_count
                    loop
                      declare
                        item : constant Boolean_Expression_Value_Record :=
                          self.boolean_expression_values
                            (Positive
                               (checked.first_boolean_expression_value +
                                expression_index - 1));
                      begin
                        if item.kind = Boolean_Expression_Local_Value then
                          if item.source_local > value.local_count then
                            raise Program_Error with
                              "Adac.Semantics: Boolean expression source is " &
                              "out of range";
                          end if;
                          declare
                            source_entity : constant Entity_ID :=
                              procedure_local_at
                                (self, entity, Positive (item.source_local));
                            source_value : constant Adac.Types.Boolean_Value :=
                              stored_boolean_source_value
                                (self,
                                 entity,
                                 index,
                                 source_entity,
                                 Positive (item.source_local),
                                 item.source_definition_statement);
                          begin
                            if checked.expected_type /=
                                 object_type (self, source_entity) or else
                               object_subtype_constraint (self, source_entity) /=
                                 NO_SUBTYPE_CONSTRAINT or else
                               source_value /= item.boolean_value
                            then
                              raise Program_Error with
                                "Adac.Semantics: Boolean expression source is " &
                                "invalid";
                            end if;
                          end;
                        end if;
                      end;
                    end loop;

                  when Local_Integer_Copy_Assignment_Statement =>
                    if checked.target_local = 0 or else
                       checked.target_local > value.local_count or else
                       checked.source_local = 0 or else
                       checked.source_local > value.local_count
                    then
                      raise Program_Error with
                        "Adac.Semantics: copy assignment local is invalid";
                    end if;
                    if checked.boolean_value /=
                      Adac.Types.False_Boolean_Value
                    then
                      raise Program_Error with
                        "Adac.Semantics: Integer copy has Boolean payload";
                    end if;

                    Adac.Types.validate (checked.expected_type);
                    if checked.expected_type /=
                         object_type
                           (self,
                            procedure_local_at
                              (self,
                               entity,
                               Positive (checked.target_local))) or else
                       checked.expected_type /=
                         object_type
                           (self,
                            procedure_local_at
                              (self,
                               entity,
                               Positive (checked.source_local)))
                    then
                      raise Program_Error with
                        "Adac.Semantics: copy assignment type is invalid";
                    end if;
                    if not subtype_constraint_contains
                      (object_subtype_constraint
                         (self,
                          procedure_local_at
                            (self, entity, Positive (checked.target_local))),
                       checked.integer_value)
                    then
                      raise Program_Error with
                        "Adac.Semantics: copy violates target subtype " &
                        "constraint";
                    end if;

                    if checked.source_definition_statement = 0 then
                      if not object_has_integer_initializer
                        (self,
                         procedure_local_at
                           (self,
                            entity,
                            Positive (checked.source_local)))
                      then
                        raise Program_Error with
                          "Adac.Semantics: copy source is not initialized";
                      end if;
                      if object_integer_initializer
                           (self,
                            procedure_local_at
                              (self,
                               entity,
                               Positive (checked.source_local))) /=
                         checked.integer_value
                      then
                        raise Program_Error with
                          "Adac.Semantics: copy source value mismatch";
                      end if;
                    else
                      if checked.source_definition_statement >= index then
                        raise Program_Error with
                          "Adac.Semantics: " &
                          "copy source definition is not earlier";
                      end if;

                      declare
                        definition : constant Procedure_Statement_Record :=
                          statement_at
                            (self,
                             entity,
                             Positive
                               (checked.source_definition_statement));
                      begin
                        if not is_integer_assignment_kind
                          (definition.kind) or else
                           definition.target_local /=
                             checked.source_local or else
                           definition.integer_value /= checked.integer_value
                        then
                          raise Program_Error with
                            "Adac.Semantics: copy source definition is invalid";
                        end if;
                      end;
                    end if;
                end case;
              end;
            end loop;
            if next_expression_value /=
                 value.first_boolean_expression_value +
                 value.boolean_expression_value_count
            then
              raise Program_Error with
                "Adac.Semantics: Boolean expression values are not fully owned";
            end if;
            end;
          end if;
      end case;
    end;
  end validate;

end Adac.Semantics;
