-- ============================================================================
-- adac-compilation-types.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Symbols;
with Adac.Types;

package Adac.Compilation.Types is

  type Predefined_Boolean_Literal_Status is
    (Not_Predefined_Boolean_Literal, Predefined_Boolean_Literal_Found);

  type Predefined_Boolean_Literal_Resolution is record
    status        : Predefined_Boolean_Literal_Status :=
      Not_Predefined_Boolean_Literal;
    semantic_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    value         : Adac.Types.Boolean_Value := Adac.Types.False_Boolean_Value;
  end record;

  type Predefined_Integer_Subtype_Kind is
    (Not_Predefined_Integer_Subtype,
     Standard_Integer_Subtype,
     Standard_Natural_Subtype,
     Standard_Positive_Subtype);

  --! summary: Classify one already-interned Standard integer subtype name.
  function resolve_predefined_integer_subtype_kind
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Predefined_Integer_Subtype_Kind;

  --! summary: Classify one explicit Standard integer subtype expanded name.
  function resolve_predefined_integer_subtype_kind
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Predefined_Integer_Subtype_Kind;

  --! summary: Return the predefined Standard.Integer semantic type.
  function standard_integer (self : Context) return Adac.Types.Type_ID;

  --! summary: Return the context-owned universal_integer semantic type.
  function universal_integer (self : Context) return Adac.Types.Type_ID;

  --! summary: Return the context-owned root_integer semantic type.
  function root_integer (self : Context) return Adac.Types.Type_ID;

  --! summary: Return the context-owned universal_real semantic type.
  function universal_real (self : Context) return Adac.Types.Type_ID;

  --! summary: Return the context-owned root_real semantic type.
  function root_real (self : Context) return Adac.Types.Type_ID;

  --! summary: Return the context-owned predefined Standard.Boolean type.
  function standard_boolean (self : Context) return Adac.Types.Type_ID;

  --! summary: Resolve one predefined homogeneous unary real operator type.
  function resolve_predefined_unary_real_operator_type
    (self         : Context;
     operand_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve one homogeneous binary real operator type.
  function resolve_predefined_homogeneous_binary_real_operator_type
    (self       : Context;
     left_type  : Adac.Types.Type_ID;
     right_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve one mixed root-real/root-integer multiplying operator.
  function resolve_predefined_mixed_real_integer_multiplying_operator_type
    (self          : Context;
     operator_kind :
       Adac.Types.Mixed_Real_Integer_Multiplying_Operator_Kind;
     left_type     : Adac.Types.Type_ID;
     right_type    : Adac.Types.Type_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve predefined root-real integer exponentiation.
  function resolve_predefined_real_exponentiating_operator_type
    (self       : Context;
     left_type  : Adac.Types.Type_ID;
     right_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve one predefined homogeneous unary integer operator type.
  function resolve_predefined_unary_integer_operator_type
    (self         : Context;
     operand_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve one homogeneous binary integer operator type.
  function resolve_predefined_homogeneous_binary_integer_operator_type
    (self       : Context;
     left_type  : Adac.Types.Type_ID;
     right_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve the Integer type behind one supported Standard
  --!          subtype name.
  function resolve_predefined_type_name
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve one direct predefined False or True literal.
  function resolve_predefined_boolean_literal
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Predefined_Boolean_Literal_Resolution;

  --! summary: Resolve one supported direct Standard.Boolean type name.
  function resolve_predefined_boolean_type_name
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve one explicit Standard.Boolean expanded name.
  function resolve_predefined_boolean_type_name
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Resolve one explicit Standard integer subtype expanded name.
  function resolve_predefined_type_name
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID;

  --! summary: Return the concrete kind of a context-owned semantic type.
  function kind_of
    (self  : Context;
     value : Adac.Types.Type_ID)
  return Adac.Types.Type_Kind;

  --! summary: Return the lower bound of a context-owned signed integer type.
  function signed_integer_lower_bound
    (self  : Context;
     value : Adac.Types.Type_ID)
  return Long_Long_Integer;

  --! summary: Return the upper bound of a context-owned signed integer type.
  function signed_integer_upper_bound
    (self  : Context;
     value : Adac.Types.Type_ID)
  return Long_Long_Integer;

  --! summary: Return the number of semantic types owned by the compilation.
  function type_count (self : Context) return Natural;

  --! summary: Validate one semantic type against the compilation context.
  procedure validate
    (self  : Context;
     value : Adac.Types.Type_ID);

end Adac.Compilation.Types;
