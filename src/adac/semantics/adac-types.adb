-- ============================================================================
-- adac-types.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers;

package body Adac.Types is

  use type Ada.Containers.Count_Type;
  use type Ada.Numerics.Big_Numbers.Big_Integers.Big_Integer;

  STANDARD_INTEGER_LOWER_BOUND : constant Long_Long_Integer :=
    -2_147_483_648;
  STANDARD_INTEGER_UPPER_BOUND : constant Long_Long_Integer :=
    2_147_483_647;
  STANDARD_INTEGER_INDEX : constant Positive := 1;
  UNIVERSAL_INTEGER_INDEX : constant Positive := 2;
  ROOT_INTEGER_INDEX      : constant Positive := 3;
  UNIVERSAL_REAL_INDEX    : constant Positive := 4;
  ROOT_REAL_INDEX         : constant Positive := 5;
  STANDARD_BOOLEAN_INDEX  : constant Positive := 6;

  procedure validate_store (self : Store) is
  begin
    if not self.initialized then
      raise Program_Error with "Adac.Types: store is not initialized";
    end if;
  end validate_store;

  procedure validate_predefined_type_shape (self : Store) is
  begin
    validate_store (self);
    if self.types.length /= 6 or else
       self.types (STANDARD_INTEGER_INDEX).kind /= Signed_Integer_Type or else
       self.types (UNIVERSAL_INTEGER_INDEX).kind /=
         Universal_Integer_Type or else
       self.types (ROOT_INTEGER_INDEX).kind /= Root_Integer_Type or else
       self.types (UNIVERSAL_REAL_INDEX).kind /= Universal_Real_Type or else
       self.types (ROOT_REAL_INDEX).kind /= Root_Real_Type or else
       self.types (STANDARD_BOOLEAN_INDEX).kind /= Boolean_Type
    then
      raise Program_Error with
        "Adac.Types: predefined type store shape is invalid";
    end if;
  end validate_predefined_type_shape;

  function create return Store is
  begin
    return result : Store do
      result.initialized := True;
      result.types.append
        (Type_Record'(kind        => Signed_Integer_Type,
                       lower_bound => STANDARD_INTEGER_LOWER_BOUND,
                       upper_bound => STANDARD_INTEGER_UPPER_BOUND));
      result.types.append
        (Type_Record'(kind        => Universal_Integer_Type,
                       lower_bound => 0,
                       upper_bound => 0));
      result.types.append
        (Type_Record'(kind        => Root_Integer_Type,
                       lower_bound => 0,
                       upper_bound => 0));
      result.types.append
        (Type_Record'(kind        => Universal_Real_Type,
                       lower_bound => 0,
                       upper_bound => 0));
      result.types.append
        (Type_Record'(kind        => Root_Real_Type,
                       lower_bound => 0,
                       upper_bound => 0));
      result.types.append
        (Type_Record'(kind        => Boolean_Type,
                       lower_bound => 0,
                       upper_bound => 0));
    end return;
  end create;

  function standard_integer (self : Store) return Type_ID is
  begin
    validate_predefined_type_shape (self);
    return (owner => self.marker'unchecked_access,
            index => STANDARD_INTEGER_INDEX);
  end standard_integer;

  function universal_integer (self : Store) return Type_ID is
  begin
    validate_predefined_type_shape (self);
    return (owner => self.marker'unchecked_access,
            index => UNIVERSAL_INTEGER_INDEX);
  end universal_integer;

  function root_integer (self : Store) return Type_ID is
  begin
    validate_predefined_type_shape (self);
    return (owner => self.marker'unchecked_access,
            index => ROOT_INTEGER_INDEX);
  end root_integer;

  function universal_real (self : Store) return Type_ID is
  begin
    validate_predefined_type_shape (self);
    return (owner => self.marker'unchecked_access,
            index => UNIVERSAL_REAL_INDEX);
  end universal_real;

  function root_real (self : Store) return Type_ID is
  begin
    validate_predefined_type_shape (self);
    return (owner => self.marker'unchecked_access,
            index => ROOT_REAL_INDEX);
  end root_real;

  function standard_boolean (self : Store) return Type_ID is
  begin
    validate_predefined_type_shape (self);
    return (owner => self.marker'unchecked_access,
            index => STANDARD_BOOLEAN_INDEX);
  end standard_boolean;

  function is_supported_specific_real_type
    (self  : Store;
     value : Type_ID)
  return Boolean is
  begin
    return kind_of (self, value) = Root_Real_Type;
  end is_supported_specific_real_type;

  function resolve_predefined_unary_real_operator_type
    (self         : Store;
     operand_type : Type_ID)
  return Type_ID is
    universal_type : constant Type_ID := universal_real (self);
  begin
    validate (self, operand_type);
    if operand_type = universal_type then
      return root_real (self);
    elsif is_supported_specific_real_type (self, operand_type) then
      return operand_type;
    end if;
    return INVALID_TYPE_ID;
  end resolve_predefined_unary_real_operator_type;

  function resolve_predefined_homogeneous_binary_real_operator_type
    (self       : Store;
     left_type  : Type_ID;
     right_type : Type_ID)
  return Type_ID is
    universal_type : constant Type_ID := universal_real (self);
  begin
    validate (self, left_type);
    validate (self, right_type);

    if left_type = universal_type and then right_type = universal_type then
      return root_real (self);
    elsif left_type = universal_type then
      if is_supported_specific_real_type (self, right_type) then
        return right_type;
      end if;
    elsif right_type = universal_type then
      if is_supported_specific_real_type (self, left_type) then
        return left_type;
      end if;
    elsif left_type = right_type and then
          is_supported_specific_real_type (self, left_type)
    then
      return left_type;
    end if;

    return INVALID_TYPE_ID;
  end resolve_predefined_homogeneous_binary_real_operator_type;

  function is_mixed_root_real_operand
    (self  : Store;
     value : Type_ID)
  return Boolean is
    value_kind : constant Type_Kind := kind_of (self, value);
  begin
    return value_kind = Universal_Real_Type or else
      value_kind = Root_Real_Type;
  end is_mixed_root_real_operand;

  function is_mixed_root_integer_operand
    (self  : Store;
     value : Type_ID)
  return Boolean is
    value_kind : constant Type_Kind := kind_of (self, value);
  begin
    return value_kind = Universal_Integer_Type or else
      value_kind = Root_Integer_Type;
  end is_mixed_root_integer_operand;

  function resolve_predefined_mixed_real_integer_multiplying_operator_type
    (self          : Store;
     operator_kind : Mixed_Real_Integer_Multiplying_Operator_Kind;
     left_type     : Type_ID;
     right_type    : Type_ID)
  return Type_ID is
    left_is_real : constant Boolean :=
      is_mixed_root_real_operand (self, left_type);
    right_is_real : constant Boolean :=
      is_mixed_root_real_operand (self, right_type);
    left_is_integer : constant Boolean :=
      is_mixed_root_integer_operand (self, left_type);
    right_is_integer : constant Boolean :=
      is_mixed_root_integer_operand (self, right_type);
  begin
    validate (self, left_type);
    validate (self, right_type);

    case operator_kind is
      when Mixed_Real_Integer_Multiply =>
        if (left_is_real and then right_is_integer) or else
           (left_is_integer and then right_is_real)
        then
          return root_real (self);
        end if;

      when Mixed_Real_Integer_Divide =>
        if left_is_real and then right_is_integer then
          return root_real (self);
        end if;
    end case;

    return INVALID_TYPE_ID;
  end resolve_predefined_mixed_real_integer_multiplying_operator_type;

  function resolve_predefined_real_exponentiating_operator_type
    (self       : Store;
     left_type  : Type_ID;
     right_type : Type_ID)
  return Type_ID is
  begin
    validate (self, left_type);
    validate (self, right_type);

    if right_type /= standard_integer (self) then
      return INVALID_TYPE_ID;
    end if;
    return resolve_predefined_unary_real_operator_type (self, left_type);
  end resolve_predefined_real_exponentiating_operator_type;

  function is_supported_specific_integer_type
    (self  : Store;
     value : Type_ID)
  return Boolean is
    kind : constant Type_Kind := kind_of (self, value);
  begin
    return kind = Signed_Integer_Type or else kind = Root_Integer_Type;
  end is_supported_specific_integer_type;

  function resolve_predefined_unary_integer_operator_type
    (self         : Store;
     operand_type : Type_ID)
  return Type_ID is
    universal_type : constant Type_ID := universal_integer (self);
  begin
    validate (self, operand_type);
    if operand_type = universal_type then
      return root_integer (self);
    elsif is_supported_specific_integer_type (self, operand_type) then
      return operand_type;
    end if;
    return INVALID_TYPE_ID;
  end resolve_predefined_unary_integer_operator_type;

  function resolve_predefined_homogeneous_binary_integer_operator_type
    (self       : Store;
     left_type  : Type_ID;
     right_type : Type_ID)
  return Type_ID is
    universal_type : constant Type_ID := universal_integer (self);
  begin
    validate (self, left_type);
    validate (self, right_type);

    if left_type = universal_type and then right_type = universal_type then
      return root_integer (self);
    elsif left_type = universal_type then
      if is_supported_specific_integer_type (self, right_type) then
        return right_type;
      end if;
    elsif right_type = universal_type then
      if is_supported_specific_integer_type (self, left_type) then
        return left_type;
      end if;
    elsif left_type = right_type and then
          is_supported_specific_integer_type (self, left_type)
    then
      return left_type;
    end if;

    return INVALID_TYPE_ID;
  end resolve_predefined_homogeneous_binary_integer_operator_type;

  package Long_Long_Integer_Conversions is new
    Ada.Numerics.Big_Numbers.Big_Integers.Signed_Conversions
      (Long_Long_Integer);

  BIG_ZERO : constant
    Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0);

  function host_decimal_digits
    (value : Long_Long_Integer)
  return Positive is
    cursor : Long_Long_Integer := value;
    result : Positive := 1;
  begin
    while cursor <= -10 or else cursor >= 10 loop
      cursor := cursor / 10;
      result := result + 1;
    end loop;
    return result;
  end host_decimal_digits;

  function make_universal_integer_value
    (value : Long_Long_Integer)
  return Universal_Integer_Value is
  begin
    return
      (valid          => True,
       value          => Long_Long_Integer_Conversions.To_Big_Integer (value),
       decimal_digits => host_decimal_digits (value));
  end make_universal_integer_value;

  function canonical_decimal_digit_count
    (spelling : String)
  return Positive is
    first_digit : Integer := spelling'First;
    digit_count : Natural;
  begin
    if spelling'Length = 0 then
      raise Program_Error with
        "Adac.Types: decimal integer spelling is empty";
    end if;

    if spelling (spelling'First) = '-' then
      first_digit := spelling'First + 1;
    elsif spelling (spelling'First) = '+' then
      raise Program_Error with
        "Adac.Types: decimal integer spelling is not canonical";
    end if;

    if first_digit > spelling'Last then
      raise Program_Error with
        "Adac.Types: decimal integer spelling has no digits";
    end if;

    digit_count := spelling'Last - first_digit + 1;
    if (digit_count > 1 and then spelling (first_digit) = '0') or else
       (spelling (spelling'First) = '-' and then
        digit_count = 1 and then spelling (first_digit) = '0')
    then
      raise Program_Error with
        "Adac.Types: decimal integer spelling is not canonical";
    end if;

    for index in first_digit .. spelling'Last loop
      if spelling (index) not in '0' .. '9' then
        raise Program_Error with
          "Adac.Types: decimal integer spelling is invalid";
      end if;
    end loop;

    return Positive (digit_count);
  end canonical_decimal_digit_count;

  function make_universal_integer_value_from_decimal
    (spelling               : String;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    digit_count : constant Positive :=
      canonical_decimal_digit_count (spelling);
  begin
    if digit_count > maximum_decimal_digits then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer decimal digit limit exceeded";
    end if;

    return
      (valid          => True,
       value          =>
         Ada.Numerics.Big_Numbers.Big_Integers.From_String (spelling),
       decimal_digits => digit_count);
  end make_universal_integer_value_from_decimal;

  function big_decimal_digits
    (value : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer)
  return Positive is
    image  : constant String :=
      Ada.Numerics.Big_Numbers.Big_Integers.To_String (value);
    result : Natural := 0;
  begin
    for index in image'range loop
      if image (index) in '0' .. '9' then
        result := result + 1;
      end if;
    end loop;

    if result = 0 then
      raise Program_Error with
        "Adac.Types: Big_Integer image has no decimal digits";
    end if;
    return Positive (result);
  end big_decimal_digits;

  function make_universal_real_value_from_quotient
    (numerator_spelling               : String;
     denominator_spelling             : String;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
    input_numerator_digits : constant Positive :=
      canonical_decimal_digit_count (numerator_spelling);
    input_denominator_digits : constant Positive :=
      canonical_decimal_digit_count (denominator_spelling);
  begin
    if input_numerator_digits > maximum_component_decimal_digits or else
       input_denominator_digits > maximum_component_decimal_digits
    then
      raise Adac.Resources.Limit_Exceeded with
        "universal real component decimal digit limit exceeded";
    end if;

    if denominator_spelling (denominator_spelling'First) = '-' or else
       denominator_spelling = "0"
    then
      raise Program_Error with
        "Adac.Types: universal real denominator is not positive";
    end if;

    declare
      exact_value : constant
        Ada.Numerics.Big_Numbers.Big_Reals.Valid_Big_Real :=
          Ada.Numerics.Big_Numbers.Big_Reals.From_Universal_Image
            (numerator_spelling, denominator_spelling);
      numerator_digits : constant Positive :=
        big_decimal_digits
          (Ada.Numerics.Big_Numbers.Big_Reals.Numerator (exact_value));
      denominator_digits : constant Positive :=
        big_decimal_digits
          (Ada.Numerics.Big_Numbers.Big_Reals.Denominator (exact_value));
    begin
      if numerator_digits > maximum_component_decimal_digits or else
         denominator_digits > maximum_component_decimal_digits
      then
        raise Adac.Resources.Limit_Exceeded with
          "universal real component decimal digit limit exceeded";
      end if;

      return
        (valid                      => True,
         value                      => exact_value,
         numerator_decimal_digits   => numerator_digits,
         denominator_decimal_digits => denominator_digits);
    end;
  end make_universal_real_value_from_quotient;

  function make_universal_real_value_from_integer_quotient
    (numerator                        : Universal_Integer_Value;
     denominator                      : Universal_Integer_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
  begin
    validate (numerator);
    validate (denominator);
    if numerator.decimal_digits > maximum_component_decimal_digits or else
       denominator.decimal_digits > maximum_component_decimal_digits
    then
      raise Adac.Resources.Limit_Exceeded with
        "universal real component decimal digit limit exceeded";
    end if;
    if universal_integer_is_zero (denominator) or else
       universal_integer_is_negative (denominator)
    then
      raise Program_Error with
        "Adac.Types: universal real denominator is not positive";
    end if;

    declare
      numerator_image : constant String :=
        Ada.Numerics.Big_Numbers.Big_Integers.To_String (numerator.value);
      denominator_image : constant String :=
        Ada.Numerics.Big_Numbers.Big_Integers.To_String (denominator.value);
      exact_value : constant
        Ada.Numerics.Big_Numbers.Big_Reals.Valid_Big_Real :=
          Ada.Numerics.Big_Numbers.Big_Reals.From_Universal_Image
            (numerator_image, denominator_image);
      numerator_digits : constant Positive :=
        big_decimal_digits
          (Ada.Numerics.Big_Numbers.Big_Reals.Numerator (exact_value));
      denominator_digits : constant Positive :=
        big_decimal_digits
          (Ada.Numerics.Big_Numbers.Big_Reals.Denominator (exact_value));
    begin
      if numerator_digits > maximum_component_decimal_digits or else
         denominator_digits > maximum_component_decimal_digits
      then
        raise Adac.Resources.Limit_Exceeded with
          "universal real component decimal digit limit exceeded";
      end if;
      return
        (valid                      => True,
         value                      => exact_value,
         numerator_decimal_digits   => numerator_digits,
         denominator_decimal_digits => denominator_digits);
    end;
  end make_universal_real_value_from_integer_quotient;

  function universal_real_numerator_decimal_digits
    (value : Universal_Real_Value)
  return Positive is
  begin
    validate (value);
    return Positive (value.numerator_decimal_digits);
  end universal_real_numerator_decimal_digits;

  function universal_real_denominator_decimal_digits
    (value : Universal_Real_Value)
  return Positive is
  begin
    validate (value);
    return Positive (value.denominator_decimal_digits);
  end universal_real_denominator_decimal_digits;

  function universal_real_is_zero
    (value : Universal_Real_Value)
  return Boolean is
  begin
    validate (value);
    return Ada.Numerics.Big_Numbers.Big_Reals.Numerator (value.value) =
      BIG_ZERO;
  end universal_real_is_zero;

  function universal_real_is_negative
    (value : Universal_Real_Value)
  return Boolean is
  begin
    validate (value);
    return Ada.Numerics.Big_Numbers.Big_Reals.Numerator (value.value) <
      BIG_ZERO;
  end universal_real_is_negative;

  procedure require_universal_integer_within_limit
    (value                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  is
  begin
    validate (value);
    if value.decimal_digits > maximum_decimal_digits then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer decimal digit limit exceeded";
    end if;
  end require_universal_integer_within_limit;

  function checked_universal_integer_value
    (value : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    digit_count : constant Positive := big_decimal_digits (value);
  begin
    if digit_count > maximum_decimal_digits then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer decimal digit limit exceeded";
    end if;

    return
      (valid          => True,
       value          => value,
       decimal_digits => digit_count);
  end checked_universal_integer_value;

  function universal_integer_decimal_digits
    (value : Universal_Integer_Value)
  return Positive is
  begin
    validate (value);
    return Positive (value.decimal_digits);
  end universal_integer_decimal_digits;

  function universal_integer_is_zero
    (value : Universal_Integer_Value)
  return Boolean is
  begin
    validate (value);
    return value.value =
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0);
  end universal_integer_is_zero;

  function universal_integer_is_negative
    (value : Universal_Integer_Value)
  return Boolean is
  begin
    validate (value);
    return value.value <
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0);
  end universal_integer_is_negative;

  function universal_integer_is_odd
    (value : Universal_Integer_Value)
  return Boolean is
    zero : constant Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0);
    two : constant Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (2);
  begin
    validate (value);
    return value.value mod two /= zero;
  end universal_integer_is_odd;

  function universal_integer_fits_long_long
    (value : Universal_Integer_Value)
  return Boolean is
    lower_bound : constant
      Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
        Long_Long_Integer_Conversions.To_Big_Integer
          (Long_Long_Integer'First);
    upper_bound : constant
      Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
        Long_Long_Integer_Conversions.To_Big_Integer
          (Long_Long_Integer'Last);
  begin
    validate (value);
    return Ada.Numerics.Big_Numbers.Big_Integers.In_Range
      (value.value, lower_bound, upper_bound);
  end universal_integer_fits_long_long;

  function universal_integer_negate
    (value                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit
      (value, maximum_decimal_digits);
    result := -value.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_negate;

  function universal_integer_absolute
    (value                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit
      (value, maximum_decimal_digits);
    result := abs value.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_absolute;

  function universal_integer_add
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit (left, maximum_decimal_digits);
    require_universal_integer_within_limit (right, maximum_decimal_digits);
    result := left.value + right.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_add;

  function universal_integer_subtract
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit (left, maximum_decimal_digits);
    require_universal_integer_within_limit (right, maximum_decimal_digits);
    result := left.value - right.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_subtract;

  function universal_integer_multiply
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    minimum_product_digits : Natural;
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit (left, maximum_decimal_digits);
    require_universal_integer_within_limit (right, maximum_decimal_digits);

    if universal_integer_is_zero (left) or else
       universal_integer_is_zero (right)
    then
      return checked_universal_integer_value
        (Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0),
         maximum_decimal_digits);
    end if;

    minimum_product_digits :=
      left.decimal_digits + right.decimal_digits - 1;
    if minimum_product_digits > maximum_decimal_digits then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer multiplication exceeds decimal digit limit";
    end if;

    result := left.value * right.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_multiply;

  function universal_integer_divide
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit (left, maximum_decimal_digits);
    require_universal_integer_within_limit (right, maximum_decimal_digits);
    if universal_integer_is_zero (right) then
      raise Program_Error with
        "Adac.Types: universal integer division by zero";
    end if;
    result := left.value / right.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_divide;

  function universal_integer_remainder
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit (left, maximum_decimal_digits);
    require_universal_integer_within_limit (right, maximum_decimal_digits);
    if universal_integer_is_zero (right) then
      raise Program_Error with
        "Adac.Types: universal integer remainder by zero";
    end if;
    result := left.value rem right.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_remainder;

  function universal_integer_modulus
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    result : Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      BIG_ZERO;
  begin
    require_universal_integer_within_limit (left, maximum_decimal_digits);
    require_universal_integer_within_limit (right, maximum_decimal_digits);
    if universal_integer_is_zero (right) then
      raise Program_Error with
        "Adac.Types: universal integer modulus by zero";
    end if;
    result := left.value mod right.value;
    return checked_universal_integer_value
      (result, maximum_decimal_digits);
  end universal_integer_modulus;

  function universal_integer_power
    (base                   : Universal_Integer_Value;
     exponent               : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    zero : constant Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0);
    one : constant Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer :=
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (1);
    minus_one : constant
      Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer := -one;
    exponent_value : Long_Long_Integer;
    power          : Natural;
    result         : Universal_Integer_Value;
    factor         : Universal_Integer_Value;
  begin
    require_universal_integer_within_limit (base, maximum_decimal_digits);
    require_universal_integer_within_limit (exponent, maximum_decimal_digits);
    if universal_integer_is_negative (exponent) then
      raise Program_Error with
        "Adac.Types: universal integer exponent is negative";
    end if;

    if universal_integer_is_zero (exponent) then
      return checked_universal_integer_value (one, maximum_decimal_digits);
    elsif base.value = zero then
      return checked_universal_integer_value (zero, maximum_decimal_digits);
    elsif base.value = one then
      return checked_universal_integer_value (one, maximum_decimal_digits);
    elsif base.value = minus_one then
      declare
        selected :
          Ada.Numerics.Big_Numbers.Big_Integers.Valid_Big_Integer := one;
      begin
        if universal_integer_is_odd (exponent) then
          selected := minus_one;
        else
          selected := one;
        end if;
        return checked_universal_integer_value
          (selected, maximum_decimal_digits);
      end;
    end if;

    if not universal_integer_fits_long_long (exponent) then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer exponent exceeds bounded work limit";
    end if;
    exponent_value := universal_integer_to_long_long (exponent);
    if exponent_value >
      Long_Long_Integer (maximum_decimal_digits) * 4 + 4
    then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer exponent exceeds bounded work limit";
    end if;

    power  := Natural (exponent_value);
    result := make_universal_integer_value (1);
    factor := base;
    while power > 0 loop
      if power mod 2 = 1 then
        result := universal_integer_multiply
          (result, factor, maximum_decimal_digits);
      end if;
      power := power / 2;
      if power > 0 then
        factor := universal_integer_multiply
          (factor, factor, maximum_decimal_digits);
      end if;
    end loop;
    return result;
  end universal_integer_power;

  function universal_integer_to_long_long
    (value : Universal_Integer_Value)
  return Long_Long_Integer is
  begin
    validate (value);
    if not universal_integer_fits_long_long (value) then
      raise Program_Error with
        "Adac.Types: universal integer does not fit Long_Long_Integer";
    end if;
    return Long_Long_Integer_Conversions.From_Big_Integer (value.value);
  end universal_integer_to_long_long;


  function universal_real_integer_limit
    (maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Adac.Resources.Universal_Integer_Decimal_Digit_Limit is
  begin
    return Adac.Resources.Universal_Integer_Decimal_Digit_Limit
      (maximum_component_decimal_digits);
  end universal_real_integer_limit;

  procedure require_universal_real_within_limit
    (value                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  is
  begin
    validate (value);
    if value.numerator_decimal_digits > maximum_component_decimal_digits or else
       value.denominator_decimal_digits > maximum_component_decimal_digits
    then
      raise Adac.Resources.Limit_Exceeded with
        "universal real component decimal digit limit exceeded";
    end if;
  end require_universal_real_within_limit;

  function universal_real_numerator_component
    (value : Universal_Real_Value)
  return Universal_Integer_Value is
  begin
    validate (value);
    return
      (valid          => True,
       value          => Ada.Numerics.Big_Numbers.Big_Reals.Numerator
         (value.value),
       decimal_digits => value.numerator_decimal_digits);
  end universal_real_numerator_component;

  function universal_real_denominator_component
    (value : Universal_Real_Value)
  return Universal_Integer_Value is
  begin
    validate (value);
    return
      (valid          => True,
       value          => Ada.Numerics.Big_Numbers.Big_Reals.Denominator
         (value.value),
       decimal_digits => value.denominator_decimal_digits);
  end universal_real_denominator_component;

  function universal_integer_greatest_common_divisor
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
    left_absolute : Universal_Integer_Value;
    right_absolute : Universal_Integer_Value;
  begin
    require_universal_integer_within_limit (left, maximum_decimal_digits);
    require_universal_integer_within_limit (right, maximum_decimal_digits);
    if universal_integer_is_zero (left) or else
       universal_integer_is_zero (right)
    then
      raise Program_Error with
        "Adac.Types: greatest common divisor operand is zero";
    end if;

    left_absolute := universal_integer_absolute
      (left, maximum_decimal_digits);
    right_absolute := universal_integer_absolute
      (right, maximum_decimal_digits);
    return checked_universal_integer_value
      (Ada.Numerics.Big_Numbers.Big_Integers.Greatest_Common_Divisor
         (left_absolute.value, right_absolute.value),
       maximum_decimal_digits);
  end universal_integer_greatest_common_divisor;

  function universal_integer_exact_quotient
    (value                  : Universal_Integer_Value;
     divisor                : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value is
  begin
    require_universal_integer_within_limit (value, maximum_decimal_digits);
    require_universal_integer_within_limit (divisor, maximum_decimal_digits);
    if universal_integer_is_zero (divisor) then
      raise Program_Error with
        "Adac.Types: exact quotient divisor is zero";
    end if;
    if value.value rem divisor.value /= BIG_ZERO then
      raise Program_Error with
        "Adac.Types: exact quotient has a remainder";
    end if;
    return universal_integer_divide
      (value, divisor, maximum_decimal_digits);
  end universal_integer_exact_quotient;

  function universal_real_negate
    (value                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
    integer_limit : constant
      Adac.Resources.Universal_Integer_Decimal_Digit_Limit :=
        universal_real_integer_limit (maximum_component_decimal_digits);
    numerator : Universal_Integer_Value;
    denominator : Universal_Integer_Value;
  begin
    require_universal_real_within_limit
      (value, maximum_component_decimal_digits);
    numerator := universal_real_numerator_component (value);
    denominator := universal_real_denominator_component (value);
    numerator := universal_integer_negate (numerator, integer_limit);
    return make_universal_real_value_from_integer_quotient
      (numerator, denominator, maximum_component_decimal_digits);
  end universal_real_negate;

  function universal_real_additive
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     subtract                         : Boolean;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
    integer_limit : constant
      Adac.Resources.Universal_Integer_Decimal_Digit_Limit :=
        universal_real_integer_limit (maximum_component_decimal_digits);
    left_numerator    : Universal_Integer_Value;
    left_denominator  : Universal_Integer_Value;
    right_numerator   : Universal_Integer_Value;
    right_denominator : Universal_Integer_Value;
    denominator_gcd   : Universal_Integer_Value;
    left_scale        : Universal_Integer_Value;
    right_scale       : Universal_Integer_Value;
    left_term         : Universal_Integer_Value;
    right_term        : Universal_Integer_Value;
    numerator         : Universal_Integer_Value;
    denominator       : Universal_Integer_Value;
  begin
    require_universal_real_within_limit
      (left, maximum_component_decimal_digits);
    require_universal_real_within_limit
      (right, maximum_component_decimal_digits);
    left_numerator := universal_real_numerator_component (left);
    left_denominator := universal_real_denominator_component (left);
    right_numerator := universal_real_numerator_component (right);
    right_denominator := universal_real_denominator_component (right);

    denominator_gcd := universal_integer_greatest_common_divisor
      (left_denominator, right_denominator, integer_limit);
    left_scale := universal_integer_exact_quotient
      (right_denominator, denominator_gcd, integer_limit);
    right_scale := universal_integer_exact_quotient
      (left_denominator, denominator_gcd, integer_limit);
    left_term := universal_integer_multiply
      (left_numerator, left_scale, integer_limit);
    right_term := universal_integer_multiply
      (right_numerator, right_scale, integer_limit);
    if subtract then
      numerator := universal_integer_subtract
        (left_term, right_term, integer_limit);
    else
      numerator := universal_integer_add
        (left_term, right_term, integer_limit);
    end if;
    denominator := universal_integer_multiply
      (left_denominator, left_scale, integer_limit);
    return make_universal_real_value_from_integer_quotient
      (numerator, denominator, maximum_component_decimal_digits);
  end universal_real_additive;

  function universal_real_add
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
  begin
    return universal_real_additive
      (left, right, False, maximum_component_decimal_digits);
  end universal_real_add;

  function universal_real_subtract
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
  begin
    return universal_real_additive
      (left, right, True, maximum_component_decimal_digits);
  end universal_real_subtract;

  function universal_real_multiply
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
    integer_limit : constant
      Adac.Resources.Universal_Integer_Decimal_Digit_Limit :=
        universal_real_integer_limit (maximum_component_decimal_digits);
    left_numerator    : Universal_Integer_Value;
    left_denominator  : Universal_Integer_Value;
    right_numerator   : Universal_Integer_Value;
    right_denominator : Universal_Integer_Value;
    left_gcd          : Universal_Integer_Value;
    right_gcd         : Universal_Integer_Value;
    numerator         : Universal_Integer_Value;
    denominator       : Universal_Integer_Value;
  begin
    require_universal_real_within_limit
      (left, maximum_component_decimal_digits);
    require_universal_real_within_limit
      (right, maximum_component_decimal_digits);
    if universal_real_is_zero (left) then
      return left;
    elsif universal_real_is_zero (right) then
      return right;
    end if;

    left_numerator := universal_real_numerator_component (left);
    left_denominator := universal_real_denominator_component (left);
    right_numerator := universal_real_numerator_component (right);
    right_denominator := universal_real_denominator_component (right);
    left_gcd := universal_integer_greatest_common_divisor
      (left_numerator, right_denominator, integer_limit);
    right_gcd := universal_integer_greatest_common_divisor
      (right_numerator, left_denominator, integer_limit);
    left_numerator := universal_integer_exact_quotient
      (left_numerator, left_gcd, integer_limit);
    right_denominator := universal_integer_exact_quotient
      (right_denominator, left_gcd, integer_limit);
    right_numerator := universal_integer_exact_quotient
      (right_numerator, right_gcd, integer_limit);
    left_denominator := universal_integer_exact_quotient
      (left_denominator, right_gcd, integer_limit);
    numerator := universal_integer_multiply
      (left_numerator, right_numerator, integer_limit);
    denominator := universal_integer_multiply
      (left_denominator, right_denominator, integer_limit);
    return make_universal_real_value_from_integer_quotient
      (numerator, denominator, maximum_component_decimal_digits);
  end universal_real_multiply;

  function universal_real_divide
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
    integer_limit : constant
      Adac.Resources.Universal_Integer_Decimal_Digit_Limit :=
        universal_real_integer_limit (maximum_component_decimal_digits);
    left_numerator    : Universal_Integer_Value;
    left_denominator  : Universal_Integer_Value;
    right_numerator   : Universal_Integer_Value;
    right_denominator : Universal_Integer_Value;
    numerator_gcd     : Universal_Integer_Value;
    denominator_gcd   : Universal_Integer_Value;
    numerator         : Universal_Integer_Value;
    denominator       : Universal_Integer_Value;
  begin
    require_universal_real_within_limit
      (left, maximum_component_decimal_digits);
    require_universal_real_within_limit
      (right, maximum_component_decimal_digits);
    if universal_real_is_zero (right) then
      raise Program_Error with
        "Adac.Types: universal real division by zero";
    elsif universal_real_is_zero (left) then
      return left;
    end if;

    left_numerator := universal_real_numerator_component (left);
    left_denominator := universal_real_denominator_component (left);
    right_numerator := universal_real_numerator_component (right);
    right_denominator := universal_real_denominator_component (right);
    numerator_gcd := universal_integer_greatest_common_divisor
      (left_numerator, right_numerator, integer_limit);
    denominator_gcd := universal_integer_greatest_common_divisor
      (left_denominator, right_denominator, integer_limit);
    left_numerator := universal_integer_exact_quotient
      (left_numerator, numerator_gcd, integer_limit);
    right_numerator := universal_integer_exact_quotient
      (right_numerator, numerator_gcd, integer_limit);
    left_denominator := universal_integer_exact_quotient
      (left_denominator, denominator_gcd, integer_limit);
    right_denominator := universal_integer_exact_quotient
      (right_denominator, denominator_gcd, integer_limit);
    numerator := universal_integer_multiply
      (left_numerator, right_denominator, integer_limit);
    denominator := universal_integer_multiply
      (left_denominator, right_numerator, integer_limit);
    if universal_integer_is_negative (denominator) then
      numerator := universal_integer_negate (numerator, integer_limit);
      denominator := universal_integer_negate (denominator, integer_limit);
    end if;
    return make_universal_real_value_from_integer_quotient
      (numerator, denominator, maximum_component_decimal_digits);
  end universal_real_divide;

  function universal_real_power
    (base                             : Universal_Real_Value;
     exponent                         : Universal_Integer_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value is
    one_integer : constant Universal_Integer_Value :=
      make_universal_integer_value (1);
    one_real : constant Universal_Real_Value :=
      make_universal_real_value_from_integer_quotient
        (one_integer,
         one_integer,
         maximum_component_decimal_digits);
    minus_one_real : constant Universal_Real_Value :=
      universal_real_negate
        (one_real, maximum_component_decimal_digits);
    negative_exponent : Boolean;
    absolute_exponent : Ada.Numerics.Big_Numbers.Big_Integers.Big_Integer;
    maximum_work : constant Long_Long_Integer :=
      Long_Long_Integer (maximum_component_decimal_digits) * 4 + 4;
    exponent_value : Long_Long_Integer;
    power  : Natural;
    result : Universal_Real_Value;
    factor : Universal_Real_Value;
  begin
    require_universal_real_within_limit
      (base, maximum_component_decimal_digits);
    validate (exponent);
    negative_exponent := universal_integer_is_negative (exponent);

    if universal_integer_is_zero (exponent) then
      return one_real;
    elsif universal_real_is_zero (base) then
      if negative_exponent then
        raise Program_Error with
          "Adac.Types: zero universal real has negative exponent";
      end if;
      return base;
    elsif base = one_real then
      return one_real;
    elsif base = minus_one_real then
      if universal_integer_is_odd (exponent) then
        return minus_one_real;
      end if;
      return one_real;
    end if;

    absolute_exponent := abs exponent.value;
    if absolute_exponent >
      Long_Long_Integer_Conversions.To_Big_Integer (maximum_work)
    then
      raise Adac.Resources.Limit_Exceeded with
        "universal real exponent exceeds bounded work limit";
    end if;
    exponent_value :=
      Long_Long_Integer_Conversions.From_Big_Integer (absolute_exponent);
    power := Natural (exponent_value);

    result := one_real;
    if negative_exponent then
      factor := universal_real_divide
        (one_real, base, maximum_component_decimal_digits);
    else
      factor := base;
    end if;

    while power > 0 loop
      if power mod 2 = 1 then
        result := universal_real_multiply
          (result, factor, maximum_component_decimal_digits);
      end if;
      power := power / 2;
      if power > 0 then
        factor := universal_real_multiply
          (factor, factor, maximum_component_decimal_digits);
      end if;
    end loop;
    return result;
  end universal_real_power;

  procedure validate (value : Universal_Integer_Value) is
  begin
    if not value.valid or else
       value.decimal_digits = 0 or else
       not Ada.Numerics.Big_Numbers.Big_Integers.Is_Valid (value.value)
    then
      raise Program_Error with
        "Adac.Types: invalid universal integer value";
    end if;
  end validate;

  procedure validate (value : Universal_Real_Value) is
  begin
    if not value.valid or else
       value.numerator_decimal_digits = 0 or else
       value.denominator_decimal_digits = 0 or else
       not Ada.Numerics.Big_Numbers.Big_Reals.Is_Valid (value.value)
    then
      raise Program_Error with
        "Adac.Types: invalid universal real value";
    end if;

    if big_decimal_digits
         (Ada.Numerics.Big_Numbers.Big_Reals.Numerator (value.value)) /=
       value.numerator_decimal_digits or else
       big_decimal_digits
         (Ada.Numerics.Big_Numbers.Big_Reals.Denominator (value.value)) /=
       value.denominator_decimal_digits
    then
      raise Program_Error with
        "Adac.Types: universal real digit metadata is inconsistent";
    end if;
  end validate;

  function kind_of
    (self  : Store;
     value : Type_ID)
  return Type_Kind is
  begin
    validate (self, value);
    return self.types (Positive (value.index)).kind;
  end kind_of;

  function signed_integer_lower_bound
    (self  : Store;
     value : Type_ID)
  return Long_Long_Integer is
  begin
    validate (self, value);

    if self.types (Positive (value.index)).kind /= Signed_Integer_Type then
      raise Program_Error with "Adac.Types: type is not a signed integer";
    end if;

    return self.types (Positive (value.index)).lower_bound;
  end signed_integer_lower_bound;

  function signed_integer_upper_bound
    (self  : Store;
     value : Type_ID)
  return Long_Long_Integer is
  begin
    validate (self, value);

    if self.types (Positive (value.index)).kind /= Signed_Integer_Type then
      raise Program_Error with "Adac.Types: type is not a signed integer";
    end if;

    return self.types (Positive (value.index)).upper_bound;
  end signed_integer_upper_bound;

  function type_count (self : Store) return Natural is
  begin
    validate_store (self);
    return Natural (self.types.length);
  end type_count;

  procedure validate (value : Type_ID) is
  begin
    if value.owner = null or else value.index = 0 then
      raise Program_Error with "Adac.Types: invalid Type_ID";
    end if;
  end validate;

  procedure validate
    (self  : Store;
     value : Type_ID)
  is
  begin
    validate_store (self);
    validate (value);

    if value.owner /= self.marker'unchecked_access then
      raise Program_Error with "Adac.Types: foreign Type_ID";
    end if;

    if value.index > Natural (self.types.length) then
      raise Program_Error with "Adac.Types: Type_ID is out of range";
    end if;
  end validate;

end Adac.Types;
