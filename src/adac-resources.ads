-- ============================================================================
-- adac-resources.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Resources is

  subtype Source_Character_Limit is Natural range 0 .. Positive'Last - 1;

  MAXIMUM_SUPPORTED_EXPRESSION_NESTING : constant Positive := 64;
  subtype Expression_Nesting_Limit is Natural range
    0 .. MAXIMUM_SUPPORTED_EXPRESSION_NESTING;

  MAXIMUM_SUPPORTED_PROFILE_NESTING : constant Positive := 64;
  subtype Profile_Nesting_Limit is Natural range
    0 .. MAXIMUM_SUPPORTED_PROFILE_NESTING;

  MAXIMUM_SUPPORTED_UNIVERSAL_INTEGER_DECIMAL_DIGITS :
    constant Positive := 1_024;
  subtype Universal_Integer_Decimal_Digit_Limit is Natural range
    0 .. MAXIMUM_SUPPORTED_UNIVERSAL_INTEGER_DECIMAL_DIGITS;

  MAXIMUM_SUPPORTED_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS :
    constant Positive := 1_024;
  subtype Universal_Real_Component_Decimal_Digit_Limit is Natural range
    0 .. MAXIMUM_SUPPORTED_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS;

  DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE :
    constant Source_Character_Limit := 16_777_216;
  DEFAULT_MAXIMUM_EXPRESSION_NESTING :
    constant Expression_Nesting_Limit := 32;
  DEFAULT_MAXIMUM_PROFILE_NESTING :
    constant Profile_Nesting_Limit := 32;
  DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS :
    constant Universal_Integer_Decimal_Digit_Limit := 1_024;
  DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS :
    constant Universal_Real_Component_Decimal_Digit_Limit := 1_024;
  DEFAULT_MAXIMUM_SYMBOLS : constant Positive := 1_000_000;
  DEFAULT_MAXIMUM_AST_NODES : constant Positive := 1_000_000;

  type Limits is record
    maximum_source_characters_per_file : Source_Character_Limit :=
      DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE;
    maximum_expression_nesting : Expression_Nesting_Limit :=
      DEFAULT_MAXIMUM_EXPRESSION_NESTING;
    maximum_profile_nesting : Profile_Nesting_Limit :=
      DEFAULT_MAXIMUM_PROFILE_NESTING;
    maximum_universal_integer_decimal_digits :
      Universal_Integer_Decimal_Digit_Limit :=
        DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS;
    maximum_universal_real_component_decimal_digits :
      Universal_Real_Component_Decimal_Digit_Limit :=
        DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS;
    maximum_symbols   : Natural := DEFAULT_MAXIMUM_SYMBOLS;
    maximum_ast_nodes : Natural := DEFAULT_MAXIMUM_AST_NODES;
  end record;

  DEFAULT_LIMITS : constant Limits :=
    (maximum_source_characters_per_file =>
       DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
     maximum_expression_nesting => DEFAULT_MAXIMUM_EXPRESSION_NESTING,
     maximum_profile_nesting => DEFAULT_MAXIMUM_PROFILE_NESTING,
     maximum_universal_integer_decimal_digits =>
       DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
     maximum_universal_real_component_decimal_digits =>
       DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
     maximum_symbols   => DEFAULT_MAXIMUM_SYMBOLS,
     maximum_ast_nodes => DEFAULT_MAXIMUM_AST_NODES);

  Limit_Exceeded : exception;

end Adac.Resources;
