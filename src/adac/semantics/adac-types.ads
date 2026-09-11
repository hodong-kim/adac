-- ============================================================================
-- adac-types.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Numerics.Big_Numbers.Big_Reals;

with Adac.Resources;

package Adac.Types is

  type Type_ID is private;

  INVALID_TYPE_ID : constant Type_ID;

  type Type_Kind is
    (Signed_Integer_Type,
     Universal_Integer_Type,
     Root_Integer_Type,
     Universal_Real_Type,
     Root_Real_Type,
     Boolean_Type);

  type Mixed_Real_Integer_Multiplying_Operator_Kind is
    (Mixed_Real_Integer_Multiply,
     Mixed_Real_Integer_Divide);

  type Boolean_Value is (False_Boolean_Value, True_Boolean_Value);

  type Universal_Integer_Value is private;
  type Universal_Real_Value is private;

  INVALID_UNIVERSAL_INTEGER_VALUE : constant Universal_Integer_Value;
  INVALID_UNIVERSAL_REAL_VALUE : constant Universal_Real_Value;

  type Store is limited private;

  --! summary: Create the semantic type store with predefined integer types.
  function create return Store;

  --! summary: Return the context-local predefined Standard.Integer type.
  function standard_integer (self : Store) return Type_ID;

  --! summary: Return the context-local universal_integer semantic type.
  function universal_integer (self : Store) return Type_ID;

  --! summary: Return the context-local root_integer semantic type.
  function root_integer (self : Store) return Type_ID;

  --! summary: Return the context-local universal_real semantic type.
  function universal_real (self : Store) return Type_ID;

  --! summary: Return the context-local root_real semantic type.
  function root_real (self : Store) return Type_ID;

  --! summary: Return the context-local predefined Standard.Boolean type.
  function standard_boolean (self : Store) return Type_ID;

  --! summary: Resolve one predefined homogeneous unary real operator type.
  function resolve_predefined_unary_real_operator_type
    (self         : Store;
     operand_type : Type_ID)
  return Type_ID;

  --! summary: Resolve one homogeneous binary real operator type.
  function resolve_predefined_homogeneous_binary_real_operator_type
    (self       : Store;
     left_type  : Type_ID;
     right_type : Type_ID)
  return Type_ID;

  --! summary: Resolve one mixed root-real/root-integer multiplying operator.
  function resolve_predefined_mixed_real_integer_multiplying_operator_type
    (self          : Store;
     operator_kind : Mixed_Real_Integer_Multiplying_Operator_Kind;
     left_type     : Type_ID;
     right_type    : Type_ID)
  return Type_ID;

  --! summary: Resolve predefined root-real integer exponentiation.
  function resolve_predefined_real_exponentiating_operator_type
    (self       : Store;
     left_type  : Type_ID;
     right_type : Type_ID)
  return Type_ID;

  --! summary: Resolve one predefined homogeneous unary integer operator type.
  function resolve_predefined_unary_integer_operator_type
    (self         : Store;
     operand_type : Type_ID)
  return Type_ID;

  --! summary: Resolve one homogeneous binary integer operator type.
  function resolve_predefined_homogeneous_binary_integer_operator_type
    (self       : Store;
     left_type  : Type_ID;
     right_type : Type_ID)
  return Type_ID;

  --! summary: Wrap one currently representable universal integer value.
  function make_universal_integer_value
    (value : Long_Long_Integer)
  return Universal_Integer_Value;

  --! summary: Build one bounded universal integer from canonical decimal text.
  function make_universal_integer_value_from_decimal
    (spelling               : String;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Return the decimal magnitude digit count of one universal value.
  function universal_integer_decimal_digits
    (value : Universal_Integer_Value)
  return Positive;

  --! summary: Return whether one universal integer value is zero.
  function universal_integer_is_zero
    (value : Universal_Integer_Value)
  return Boolean;

  --! summary: Return whether one universal integer value is negative.
  function universal_integer_is_negative
    (value : Universal_Integer_Value)
  return Boolean;

  --! summary: Return whether one universal integer value is odd.
  function universal_integer_is_odd
    (value : Universal_Integer_Value)
  return Boolean;

  --! summary: Return whether one universal value fits Long_Long_Integer.
  function universal_integer_fits_long_long
    (value : Universal_Integer_Value)
  return Boolean;

  --! summary: Negate one universal value within the supplied digit limit.
  function universal_integer_negate
    (value                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Take the absolute value within the supplied digit limit.
  function universal_integer_absolute
    (value                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Add two universal values within the supplied digit limit.
  function universal_integer_add
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Subtract two universal values within the supplied digit limit.
  function universal_integer_subtract
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Multiply two universal values within the supplied digit limit.
  function universal_integer_multiply
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Divide two nonzero-divisor universal integer values exactly.
  function universal_integer_divide
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Compute Ada rem for two universal integer values.
  function universal_integer_remainder
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Compute Ada mod for two universal integer values.
  function universal_integer_modulus
    (left                   : Universal_Integer_Value;
     right                  : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Raise one universal base to a nonnegative universal exponent.
  function universal_integer_power
    (base                   : Universal_Integer_Value;
     exponent               : Universal_Integer_Value;
     maximum_decimal_digits :
       Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Value;

  --! summary: Return the host integer when one universal value is
  --!          representable.
  function universal_integer_to_long_long
    (value : Universal_Integer_Value)
  return Long_Long_Integer;

  --! summary: Validate one universal integer value wrapper.
  procedure validate (value : Universal_Integer_Value);

  --! summary: Build one bounded exact universal real from a quotient.
  function make_universal_real_value_from_quotient
    (numerator_spelling               : String;
     denominator_spelling             : String;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Build one bounded exact universal real from integer carriers.
  function make_universal_real_value_from_integer_quotient
    (numerator                        : Universal_Integer_Value;
     denominator                      : Universal_Integer_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Return the reduced numerator magnitude digit count.
  function universal_real_numerator_decimal_digits
    (value : Universal_Real_Value)
  return Positive;

  --! summary: Return the reduced denominator magnitude digit count.
  function universal_real_denominator_decimal_digits
    (value : Universal_Real_Value)
  return Positive;

  --! summary: Return whether one universal real value is zero.
  function universal_real_is_zero
    (value : Universal_Real_Value)
  return Boolean;

  --! summary: Return whether one universal real value is negative.
  function universal_real_is_negative
    (value : Universal_Real_Value)
  return Boolean;

  --! summary: Negate one exact universal real within the component limit.
  function universal_real_negate
    (value                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Add two exact universal reals within the component limit.
  function universal_real_add
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Subtract two exact universal reals within the component limit.
  function universal_real_subtract
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Multiply two exact universal reals within the component limit.
  function universal_real_multiply
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Divide by one nonzero universal real within the component limit.
  function universal_real_divide
    (left                             : Universal_Real_Value;
     right                            : Universal_Real_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Raise one exact universal real to an integer exponent.
  function universal_real_power
    (base                             : Universal_Real_Value;
     exponent                         : Universal_Integer_Value;
     maximum_component_decimal_digits :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Value;

  --! summary: Validate one universal real value wrapper.
  procedure validate (value : Universal_Real_Value);


  --! summary: Return the concrete kind of one context-owned semantic type.
  function kind_of
    (self  : Store;
     value : Type_ID)
  return Type_Kind;

  --! summary: Return the lower bound of one signed integer type.
  function signed_integer_lower_bound
    (self  : Store;
     value : Type_ID)
  return Long_Long_Integer;

  --! summary: Return the upper bound of one signed integer type.
  function signed_integer_upper_bound
    (self  : Store;
     value : Type_ID)
  return Long_Long_Integer;

  --! summary: Return the number of semantic types owned by the store.
  function type_count (self : Store) return Natural;

  --! summary: Validate the structural state of a semantic type identifier.
  procedure validate (value : Type_ID);

  --! summary: Validate a semantic type identifier against its owning store.
  procedure validate
    (self  : Store;
     value : Type_ID);

private

  type Store_Marker is record
    identity : Boolean := False;
  end record;
  type Store_Marker_Access is access constant Store_Marker;

  type Type_ID is record
    owner : Store_Marker_Access := null;
    index : Natural := 0;
  end record;

  INVALID_TYPE_ID : constant Type_ID :=
    (owner => null,
     index => 0);

  type Universal_Integer_Value is record
    valid          : Boolean := False;
    value          : Ada.Numerics.Big_Numbers.Big_Integers.Big_Integer :=
      Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0);
    decimal_digits : Natural := 0;
  end record;

  INVALID_UNIVERSAL_INTEGER_VALUE : constant Universal_Integer_Value :=
    (valid          => False,
     value          => Ada.Numerics.Big_Numbers.Big_Integers.To_Big_Integer (0),
     decimal_digits => 0);

  type Universal_Real_Value is record
    valid                      : Boolean := False;
    value                      : Ada.Numerics.Big_Numbers.Big_Reals.Big_Real :=
      Ada.Numerics.Big_Numbers.Big_Reals.To_Real (0);
    numerator_decimal_digits   : Natural := 0;
    denominator_decimal_digits : Natural := 0;
  end record;

  INVALID_UNIVERSAL_REAL_VALUE : constant Universal_Real_Value :=
    (valid                      => False,
     value                      =>
       Ada.Numerics.Big_Numbers.Big_Reals.To_Real (0),
     numerator_decimal_digits   => 0,
     denominator_decimal_digits => 0);

  type Type_Record is record
    kind        : Type_Kind := Signed_Integer_Type;
    lower_bound : Long_Long_Integer := 0;
    upper_bound : Long_Long_Integer := 0;
  end record;

  package Type_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Type_Record);

  type Store is limited record
    initialized : Boolean := False;
    marker      : aliased Store_Marker;
    types       : Type_Vectors.Vector;
  end record;

end Adac.Types;
