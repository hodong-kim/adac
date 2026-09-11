-- ============================================================================
-- adac-compilation-types.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation.Symbols;

package body Adac.Compilation.Types is

  use type Adac.Symbols.Symbol_ID;

  function resolve_predefined_integer_subtype_kind
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Predefined_Integer_Subtype_Kind is
    integer_symbol  : Adac.Symbols.Symbol_ID;
    natural_symbol  : Adac.Symbols.Symbol_ID;
    positive_symbol : Adac.Symbols.Symbol_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);

    integer_symbol := Adac.Compilation.Symbols.find (self, "Integer");
    if integer_symbol /= Adac.Symbols.INVALID_SYMBOL_ID and then
       integer_symbol = symbol
    then
      return Standard_Integer_Subtype;
    end if;

    natural_symbol := Adac.Compilation.Symbols.find (self, "Natural");
    if natural_symbol /= Adac.Symbols.INVALID_SYMBOL_ID and then
       natural_symbol = symbol
    then
      return Standard_Natural_Subtype;
    end if;

    positive_symbol := Adac.Compilation.Symbols.find (self, "Positive");
    if positive_symbol /= Adac.Symbols.INVALID_SYMBOL_ID and then
       positive_symbol = symbol
    then
      return Standard_Positive_Subtype;
    end if;

    return Not_Predefined_Integer_Subtype;
  end resolve_predefined_integer_subtype_kind;

  function resolve_predefined_integer_subtype_kind
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Predefined_Integer_Subtype_Kind is
    standard_symbol : Adac.Symbols.Symbol_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, package_symbol);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);

    standard_symbol := Adac.Compilation.Symbols.find (self, "Standard");
    if standard_symbol = Adac.Symbols.INVALID_SYMBOL_ID or else
       package_symbol /= standard_symbol
    then
      return Not_Predefined_Integer_Subtype;
    end if;

    return resolve_predefined_integer_subtype_kind (self, symbol);
  end resolve_predefined_integer_subtype_kind;

  function standard_integer (self : Context) return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.standard_integer (self.type_store);
  end standard_integer;

  function universal_integer (self : Context) return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.universal_integer (self.type_store);
  end universal_integer;

  function root_integer (self : Context) return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.root_integer (self.type_store);
  end root_integer;

  function universal_real (self : Context) return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.universal_real (self.type_store);
  end universal_real;

  function root_real (self : Context) return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.root_real (self.type_store);
  end root_real;

  function standard_boolean (self : Context) return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.standard_boolean (self.type_store);
  end standard_boolean;

  function resolve_predefined_unary_real_operator_type
    (self         : Context;
     operand_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.resolve_predefined_unary_real_operator_type
      (self.type_store, operand_type);
  end resolve_predefined_unary_real_operator_type;

  function resolve_predefined_homogeneous_binary_real_operator_type
    (self       : Context;
     left_type  : Adac.Types.Type_ID;
     right_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.resolve_predefined_homogeneous_binary_real_operator_type
      (self.type_store, left_type, right_type);
  end resolve_predefined_homogeneous_binary_real_operator_type;

  function resolve_predefined_mixed_real_integer_multiplying_operator_type
    (self          : Context;
     operator_kind :
       Adac.Types.Mixed_Real_Integer_Multiplying_Operator_Kind;
     left_type     : Adac.Types.Type_ID;
     right_type    : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types
      .resolve_predefined_mixed_real_integer_multiplying_operator_type
        (self.type_store, operator_kind, left_type, right_type);
  end resolve_predefined_mixed_real_integer_multiplying_operator_type;

  function resolve_predefined_real_exponentiating_operator_type
    (self       : Context;
     left_type  : Adac.Types.Type_ID;
     right_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.resolve_predefined_real_exponentiating_operator_type
      (self.type_store, left_type, right_type);
  end resolve_predefined_real_exponentiating_operator_type;

  function resolve_predefined_unary_integer_operator_type
    (self         : Context;
     operand_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.resolve_predefined_unary_integer_operator_type
      (self.type_store, operand_type);
  end resolve_predefined_unary_integer_operator_type;

  function resolve_predefined_homogeneous_binary_integer_operator_type
    (self       : Context;
     left_type  : Adac.Types.Type_ID;
     right_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
  begin
    Adac.Compilation.validate (self);
    return
      Adac.Types.resolve_predefined_homogeneous_binary_integer_operator_type
        (self.type_store, left_type, right_type);
  end resolve_predefined_homogeneous_binary_integer_operator_type;

  function resolve_predefined_type_name
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
  begin
    case resolve_predefined_integer_subtype_kind (self, symbol) is
      when Standard_Integer_Subtype |
           Standard_Natural_Subtype |
           Standard_Positive_Subtype =>
        return Adac.Types.standard_integer (self.type_store);

      when Not_Predefined_Integer_Subtype =>
        return Adac.Types.INVALID_TYPE_ID;
    end case;
  end resolve_predefined_type_name;

  function resolve_predefined_type_name
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
  begin
    case resolve_predefined_integer_subtype_kind
      (self, package_symbol, symbol)
    is
      when Standard_Integer_Subtype |
           Standard_Natural_Subtype |
           Standard_Positive_Subtype =>
        return Adac.Types.standard_integer (self.type_store);

      when Not_Predefined_Integer_Subtype =>
        return Adac.Types.INVALID_TYPE_ID;
    end case;
  end resolve_predefined_type_name;

  function resolve_predefined_boolean_literal
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Predefined_Boolean_Literal_Resolution is
    false_symbol : Adac.Symbols.Symbol_ID;
    true_symbol  : Adac.Symbols.Symbol_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);

    false_symbol := Adac.Compilation.Symbols.find (self, "False");
    if false_symbol /= Adac.Symbols.INVALID_SYMBOL_ID and then
       false_symbol = symbol
    then
      return
        (status        => Predefined_Boolean_Literal_Found,
         semantic_type => Adac.Types.standard_boolean (self.type_store),
         value         => Adac.Types.False_Boolean_Value);
    end if;

    true_symbol := Adac.Compilation.Symbols.find (self, "True");
    if true_symbol /= Adac.Symbols.INVALID_SYMBOL_ID and then
       true_symbol = symbol
    then
      return
        (status        => Predefined_Boolean_Literal_Found,
         semantic_type => Adac.Types.standard_boolean (self.type_store),
         value         => Adac.Types.True_Boolean_Value);
    end if;

    return
      (status        => Not_Predefined_Boolean_Literal,
       semantic_type => Adac.Types.INVALID_TYPE_ID,
       value         => Adac.Types.False_Boolean_Value);
  end resolve_predefined_boolean_literal;

  function resolve_predefined_boolean_type_name
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    boolean_symbol : Adac.Symbols.Symbol_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    boolean_symbol := Adac.Compilation.Symbols.find (self, "Boolean");
    if boolean_symbol /= Adac.Symbols.INVALID_SYMBOL_ID and then
       boolean_symbol = symbol
    then
      return Adac.Types.standard_boolean (self.type_store);
    end if;
    return Adac.Types.INVALID_TYPE_ID;
  end resolve_predefined_boolean_type_name;

  function resolve_predefined_boolean_type_name
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    standard_symbol : Adac.Symbols.Symbol_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, package_symbol);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    standard_symbol := Adac.Compilation.Symbols.find (self, "Standard");
    if standard_symbol = Adac.Symbols.INVALID_SYMBOL_ID or else
       package_symbol /= standard_symbol
    then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    return resolve_predefined_boolean_type_name (self, symbol);
  end resolve_predefined_boolean_type_name;

  function kind_of
    (self  : Context;
     value : Adac.Types.Type_ID)
  return Adac.Types.Type_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.kind_of (self.type_store, value);
  end kind_of;

  function signed_integer_lower_bound
    (self  : Context;
     value : Adac.Types.Type_ID)
  return Long_Long_Integer is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.signed_integer_lower_bound (self.type_store, value);
  end signed_integer_lower_bound;

  function signed_integer_upper_bound
    (self  : Context;
     value : Adac.Types.Type_ID)
  return Long_Long_Integer is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.signed_integer_upper_bound (self.type_store, value);
  end signed_integer_upper_bound;

  function type_count (self : Context) return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Types.type_count (self.type_store);
  end type_count;

  procedure validate
    (self  : Context;
     value : Adac.Types.Type_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.Types.validate (self.type_store, value);
  end validate;

end Adac.Compilation.Types;
