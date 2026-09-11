-- ============================================================================
-- adac-sema.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;

with Adac.Compilation.Diagnostics;
with Adac.Compilation.Semantics;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;
with Adac.Compilation.Types;
with Adac.Resources;
with Adac.Source;
with Adac.Symbols;
with Adac.Types;

package body Adac.Sema is

  use type Adac.AST.Node_Kind;
  use type Adac.AST.Numeric_Literal_Kind;
  use type Adac.AST.Object_Declaration_Form;
  use type Adac.Compilation.Types.Predefined_Boolean_Literal_Status;
  use type Adac.Semantics.Boolean_Binary_Operator_Kind;
  use type Adac.Symbols.Symbol_ID;
  use type Adac.Types.Boolean_Value;
  use type Adac.Types.Type_ID;
  use type Adac.Types.Type_Kind;

  type Local_Object_Descriptor is record
    declaration             : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    semantic_type           : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    constraint              : Adac.Semantics.Subtype_Constraint :=
      Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
    has_integer_initializer : Boolean := False;
    integer_initializer     : Long_Long_Integer := 0;
    has_boolean_initializer : Boolean := False;
    boolean_initializer     : Adac.Types.Boolean_Value :=
      Adac.Types.False_Boolean_Value;
    has_defined_value       : Boolean := False;
    defined_integer_value   : Long_Long_Integer := 0;
    definition_statement    : Natural := 0;
    has_defined_boolean_value : Boolean := False;
    defined_boolean_value     : Adac.Types.Boolean_Value :=
      Adac.Types.False_Boolean_Value;
    boolean_definition_statement : Natural := 0;
  end record;

  package Local_Object_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Local_Object_Descriptor);

  procedure mark_local_defined
    (locals          : in out Local_Object_Vectors.Vector;
     local           : Positive;
     statement_index : Positive;
     value           : Long_Long_Integer)
  is
    descriptor : Local_Object_Descriptor := locals (local);
  begin
    descriptor.has_defined_value     := True;
    descriptor.defined_integer_value := value;
    descriptor.definition_statement  := statement_index;
    locals.replace_element (local, descriptor);
  end mark_local_defined;

  procedure mark_boolean_local_defined
    (locals          : in out Local_Object_Vectors.Vector;
     local           : Positive;
     statement_index : Positive;
     value           : Adac.Types.Boolean_Value)
  is
    descriptor : Local_Object_Descriptor := locals (local);
  begin
    descriptor.has_defined_boolean_value := True;
    descriptor.defined_boolean_value := value;
    descriptor.boolean_definition_statement := statement_index;
    locals.replace_element (local, descriptor);
  end mark_boolean_local_defined;

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

  function semantic_boolean_binary_operator
    (operator_kind : Adac.AST.Logical_Operator_Kind)
  return Adac.Semantics.Boolean_Binary_Operator_Kind is
  begin
    case operator_kind is
      when Adac.AST.And_Logical_Operator =>
        return Adac.Semantics.And_Boolean_Binary_Operator;
      when Adac.AST.Or_Logical_Operator =>
        return Adac.Semantics.Or_Boolean_Binary_Operator;
      when Adac.AST.Xor_Logical_Operator =>
        return Adac.Semantics.Xor_Boolean_Binary_Operator;
    end case;
  end semantic_boolean_binary_operator;

  function semantic_boolean_relation_operator
    (operator_spelling : String)
  return Adac.Semantics.Boolean_Binary_Operator_Kind is
  begin
    if operator_spelling = "=" then
      return Adac.Semantics.Equal_Boolean_Binary_Operator;
    elsif operator_spelling = "/=" then
      return Adac.Semantics.Not_Equal_Boolean_Binary_Operator;
    elsif operator_spelling = "<" then
      return Adac.Semantics.Less_Boolean_Binary_Operator;
    elsif operator_spelling = "<=" then
      return Adac.Semantics.Less_Equal_Boolean_Binary_Operator;
    elsif operator_spelling = ">" then
      return Adac.Semantics.Greater_Boolean_Binary_Operator;
    elsif operator_spelling = ">=" then
      return Adac.Semantics.Greater_Equal_Boolean_Binary_Operator;
    end if;
    return Adac.Semantics.No_Boolean_Binary_Operator;
  end semantic_boolean_relation_operator;

  function boolean_binary_value
    (operator_kind : Adac.Semantics.Boolean_Binary_Operator_Kind;
     left          : Adac.Types.Boolean_Value;
     right         : Adac.Types.Boolean_Value)
  return Adac.Types.Boolean_Value is
    left_true : constant Boolean := left = Adac.Types.True_Boolean_Value;
    right_true : constant Boolean := right = Adac.Types.True_Boolean_Value;
    result : Boolean;
  begin
    case operator_kind is
      when Adac.Semantics.No_Boolean_Binary_Operator =>
        raise Program_Error with
          "Adac.Sema: missing Boolean binary operator";
      when Adac.Semantics.And_Boolean_Binary_Operator =>
        result := left_true and right_true;
      when Adac.Semantics.Or_Boolean_Binary_Operator =>
        result := left_true or right_true;
      when Adac.Semantics.Xor_Boolean_Binary_Operator =>
        result := left_true xor right_true;
      when Adac.Semantics.Equal_Boolean_Binary_Operator =>
        result := left_true = right_true;
      when Adac.Semantics.Not_Equal_Boolean_Binary_Operator =>
        result := left_true /= right_true;
      when Adac.Semantics.Less_Boolean_Binary_Operator =>
        result := (not left_true) and right_true;
      when Adac.Semantics.Less_Equal_Boolean_Binary_Operator =>
        result := (not left_true) or right_true;
      when Adac.Semantics.Greater_Boolean_Binary_Operator =>
        result := left_true and (not right_true);
      when Adac.Semantics.Greater_Equal_Boolean_Binary_Operator =>
        result := left_true or (not right_true);
    end case;
    return
      (if result then
         Adac.Types.True_Boolean_Value
       else
         Adac.Types.False_Boolean_Value);
  end boolean_binary_value;

  type Integer_Static_Status is
    (Integer_Static_Valid,
     Integer_Static_Unsupported,
     Integer_Static_Invalid,
     Integer_Static_Zero_Divisor,
     Integer_Static_Out_Of_Range,
     Integer_Static_Resource_Limit);

  type Integer_Static_Result is record
    status : Integer_Static_Status := Integer_Static_Unsupported;
    value  : Long_Long_Integer := 0;
  end record;

  type Boolean_Static_Status is
    (Boolean_Static_Valid,
     Boolean_Static_Unsupported);

  type Boolean_Static_Result is record
    status : Boolean_Static_Status := Boolean_Static_Unsupported;
    semantic_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    value : Adac.Types.Boolean_Value := Adac.Types.False_Boolean_Value;
  end record;

  type Boolean_Static_Evaluation_Action is
    (Visit_Boolean_Static_Expression,
     Apply_Boolean_Static_Not,
     Apply_Boolean_Static_Relation,
     Apply_Boolean_Static_Logical,
     Finish_Boolean_Static_Short_Circuit_Left);

  type Boolean_Static_Evaluation_Frame is record
    action : Boolean_Static_Evaluation_Action :=
      Visit_Boolean_Static_Expression;
    node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  end record;

  package Boolean_Static_Evaluation_Frame_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Boolean_Static_Evaluation_Frame);

  package Boolean_Static_Value_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Adac.Types.Boolean_Value);

  type Boolean_Runtime_Status is
    (Boolean_Runtime_Valid,
     Boolean_Runtime_Unsupported,
     Boolean_Runtime_Type_Mismatch,
     Boolean_Runtime_Uninitialized);

  type Boolean_Runtime_Evaluation_Action is
    (Visit_Boolean_Runtime_Expression,
     Apply_Boolean_Runtime_Not,
     Apply_Boolean_Runtime_Relation,
     Apply_Boolean_Runtime_Logical);

  type Boolean_Runtime_Evaluation_Frame is record
    action : Boolean_Runtime_Evaluation_Action :=
      Visit_Boolean_Runtime_Expression;
    node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  end record;

  package Boolean_Runtime_Evaluation_Frame_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Boolean_Runtime_Evaluation_Frame);

  type Universal_Integer_Static_Status is
    (Universal_Integer_Static_Valid,
     Universal_Integer_Static_Unsupported,
     Universal_Integer_Static_Invalid,
     Universal_Integer_Static_Zero_Divisor,
     Universal_Integer_Static_Resource_Limit);

  type Universal_Integer_Static_Result is record
    status : Universal_Integer_Static_Status :=
      Universal_Integer_Static_Unsupported;
    semantic_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    value  : Adac.Types.Universal_Integer_Value :=
      Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
  end record;

  type Universal_Real_Literal_Status is
    (Universal_Real_Literal_Valid,
     Universal_Real_Literal_Invalid,
     Universal_Real_Literal_Resource_Limit);

  type Universal_Real_Literal_Result is record
    status : Universal_Real_Literal_Status := Universal_Real_Literal_Invalid;
    value : Adac.Types.Universal_Real_Value :=
      Adac.Types.INVALID_UNIVERSAL_REAL_VALUE;
  end record;

  type Universal_Real_Static_Status is
    (Universal_Real_Static_Valid,
     Universal_Real_Static_Unsupported,
     Universal_Real_Static_Invalid,
     Universal_Real_Static_Zero_Divisor,
     Universal_Real_Static_Resource_Limit);

  type Universal_Real_Static_Result is record
    status : Universal_Real_Static_Status := Universal_Real_Static_Unsupported;
    semantic_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    integer_value : Adac.Types.Universal_Integer_Value :=
      Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
    value : Adac.Types.Universal_Real_Value :=
      Adac.Types.INVALID_UNIVERSAL_REAL_VALUE;
  end record;

  type Static_Evaluation_Action is
    (Visit_Static_Expression,
     Apply_Static_Unary,
     Apply_Static_Exponentiating,
     Apply_Static_Adding,
     Apply_Static_Multiplying);

  type Exact_Static_Integer_Value is record
    semantic_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    value : Adac.Types.Universal_Integer_Value :=
      Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
  end record;

  type Exact_Static_Evaluation_Frame is record
    action        : Static_Evaluation_Action := Visit_Static_Expression;
    node          : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    expected_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
  end record;

  package Exact_Static_Evaluation_Frame_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Exact_Static_Evaluation_Frame);

  package Exact_Static_Integer_Value_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Exact_Static_Integer_Value);

  type Exact_Static_Numeric_Value is record
    semantic_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID;
    integer_value : Adac.Types.Universal_Integer_Value :=
      Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
    real_value : Adac.Types.Universal_Real_Value :=
      Adac.Types.INVALID_UNIVERSAL_REAL_VALUE;
  end record;

  package Exact_Static_Numeric_Value_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Exact_Static_Numeric_Value);

  function digit_value (value : Character) return Natural is
  begin
    case value is
      when '0' .. '9' =>
        return Character'pos (value) - Character'pos ('0');

      when 'A' .. 'F' =>
        return 10 + Character'pos (value) - Character'pos ('A');

      when 'a' .. 'f' =>
        return 10 + Character'pos (value) - Character'pos ('a');

      when others =>
        return 16;
    end case;
  end digit_value;

  procedure parse_numeral
    (spelling     : String;
     first        : Positive;
     last         : Natural;
     base         : Positive;
     maximum      : Long_Long_Integer;
     value        : out Long_Long_Integer;
     valid        : out Boolean;
     out_of_range : out Boolean)
  is
    previous_underscore : Boolean := False;
    saw_digit           : Boolean := False;
  begin
    value        := 0;
    valid        := True;
    out_of_range := False;

    if last < first then
      valid := False;
      return;
    end if;

    for index in first .. last loop
      if spelling (index) = '_' then
        if not saw_digit or else previous_underscore or else index = last then
          valid := False;
        end if;
        previous_underscore := True;
      else
        declare
          digit : constant Natural := digit_value (spelling (index));
        begin
          if digit >= base then
            valid := False;
          elsif not out_of_range then
            if value >
              (maximum - Long_Long_Integer (digit)) /
              Long_Long_Integer (base)
            then
              out_of_range := True;
            else
              value :=
                value * Long_Long_Integer (base) + Long_Long_Integer (digit);
            end if;
          end if;
        end;
        saw_digit := True;
        previous_underscore := False;
      end if;
    end loop;

    if not saw_digit or else previous_underscore then
      valid := False;
    end if;
  end parse_numeral;

  function universal_integer_decimal_digit_limit
    (context : Adac.Compilation.Context)
  return Adac.Resources.Universal_Integer_Decimal_Digit_Limit is
  begin
    return Adac.Compilation.resource_limits
      (context).maximum_universal_integer_decimal_digits;
  end universal_integer_decimal_digit_limit;

  function invalid_universal_integer_static_result
    (status : Universal_Integer_Static_Status)
  return Universal_Integer_Static_Result is
  begin
    return
      (status        => status,
       semantic_type => Adac.Types.INVALID_TYPE_ID,
       value         => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE);
  end invalid_universal_integer_static_result;

  function parse_universal_integer_numeral
    (spelling : String;
     first    : Positive;
     last     : Natural;
     base     : Positive;
     limit    : Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Static_Result is
    result : Adac.Types.Universal_Integer_Value :=
      Adac.Types.make_universal_integer_value (0);
    base_value : constant Adac.Types.Universal_Integer_Value :=
      Adac.Types.make_universal_integer_value (Long_Long_Integer (base));
    previous_underscore : Boolean := False;
    saw_digit           : Boolean := False;
    saw_nonzero         : Boolean := False;
  begin
    if limit = 0 then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer decimal digit limit exceeded";
    end if;
    if last < first then
      return invalid_universal_integer_static_result
        (Universal_Integer_Static_Invalid);
    end if;

    for index in first .. last loop
      if spelling (index) = '_' then
        if not saw_digit or else previous_underscore or else index = last then
          return
            invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
        end if;
        previous_underscore := True;
      else
        declare
          digit : constant Natural := digit_value (spelling (index));
        begin
          if digit >= base then
            return
              invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
          end if;

          if saw_nonzero or else digit /= 0 then
            if saw_nonzero then
              result := Adac.Types.universal_integer_multiply
                (result, base_value, limit);
            end if;
            if digit /= 0 then
              result := Adac.Types.universal_integer_add
                (result,
                 Adac.Types.make_universal_integer_value
                   (Long_Long_Integer (digit)),
                 limit);
            end if;
            saw_nonzero := True;
          end if;
        end;
        saw_digit := True;
        previous_underscore := False;
      end if;
    end loop;

    if not saw_digit or else previous_underscore then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;

    return
      (status        => Universal_Integer_Static_Valid,
       semantic_type => Adac.Types.INVALID_TYPE_ID,
       value         => result);
  end parse_universal_integer_numeral;

  function apply_universal_literal_exponent
    (value    : Adac.Types.Universal_Integer_Value;
     radix    : Positive;
     spelling : String;
     first    : Positive;
     limit    : Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Static_Result is
    index        : Natural := first;
    exponent     : Long_Long_Integer;
    valid        : Boolean;
    too_large    : Boolean;
    exponent_max : constant Long_Long_Integer :=
      Long_Long_Integer (limit) * 4 + 4;
  begin
    if index > spelling'last then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;

    if spelling (index) = '-' then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    elsif spelling (index) = '+' then
      index := index + 1;
    end if;

    if index > spelling'last then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;

    parse_numeral
      (spelling,
       Positive (index),
       spelling'last,
       10,
       exponent_max,
       exponent,
       valid,
       too_large);
    if not valid then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;

    if Adac.Types.universal_integer_is_zero (value) then
      return
        (status        => Universal_Integer_Static_Valid,
         semantic_type => Adac.Types.INVALID_TYPE_ID,
         value         => value);
    end if;

    if too_large then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer literal exponent exceeds bounded work limit";
    end if;

    declare
      radix_value : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (Long_Long_Integer (radix));
      exponent_value : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.make_universal_integer_value (exponent);
      scale : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.universal_integer_power
          (radix_value, exponent_value, limit);
      result : constant Adac.Types.Universal_Integer_Value :=
        Adac.Types.universal_integer_multiply (value, scale, limit);
    begin
      return
        (status        => Universal_Integer_Static_Valid,
         semantic_type => Adac.Types.INVALID_TYPE_ID,
         value         => result);
    end;
  end apply_universal_literal_exponent;

  function parse_universal_decimal_integer
    (spelling : String;
     limit    : Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Static_Result is
    exponent_index : Natural := 0;
    numeral_last   : Natural;
    result         : Universal_Integer_Static_Result;
  begin
    for index in spelling'range loop
      if spelling (index) = 'E' or else spelling (index) = 'e' then
        exponent_index := index;
        exit;
      end if;
    end loop;

    if exponent_index = 0 then
      numeral_last := spelling'last;
    else
      numeral_last := exponent_index - 1;
    end if;
    result := parse_universal_integer_numeral
      (spelling,
       spelling'first,
       numeral_last,
       10,
       limit);
    if result.status /= Universal_Integer_Static_Valid or else
       exponent_index = 0
    then
      return result;
    end if;

    return apply_universal_literal_exponent
      (result.value,
       10,
       spelling,
       Positive (exponent_index + 1),
       limit);
  end parse_universal_decimal_integer;

  function parse_universal_based_integer
    (spelling : String;
     limit    : Adac.Resources.Universal_Integer_Decimal_Digit_Limit)
  return Universal_Integer_Static_Result is
    first_hash  : Natural := 0;
    second_hash : Natural := 0;
    base_value  : Long_Long_Integer;
    valid       : Boolean;
    out_of_range : Boolean;
    result      : Universal_Integer_Static_Result;
  begin
    for index in spelling'range loop
      if spelling (index) = '#' then
        if first_hash = 0 then
          first_hash := index;
        else
          second_hash := index;
          exit;
        end if;
      end if;
    end loop;

    if first_hash <= spelling'first or else
       second_hash <= first_hash + 1
    then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;

    parse_numeral
      (spelling,
       spelling'first,
       first_hash - 1,
       10,
       16,
       base_value,
       valid,
       out_of_range);
    if not valid or else out_of_range or else
       base_value < 2 or else base_value > 16
    then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;

    result := parse_universal_integer_numeral
      (spelling,
       Positive (first_hash + 1),
       second_hash - 1,
       Positive (base_value),
       limit);
    if result.status /= Universal_Integer_Static_Valid or else
       second_hash = spelling'last
    then
      return result;
    end if;

    if spelling (second_hash + 1) /= 'E' and then
       spelling (second_hash + 1) /= 'e'
    then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;
    if second_hash + 2 > spelling'last then
      return invalid_universal_integer_static_result
              (Universal_Integer_Static_Invalid);
    end if;

    return apply_universal_literal_exponent
      (result.value,
       Positive (base_value),
       spelling,
       Positive (second_hash + 2),
       limit);
  end parse_universal_based_integer;

  function parse_universal_integer_literal
    (context : Adac.Compilation.Context;
     literal : Adac.AST.Node_ID)
  return Universal_Integer_Static_Result is
    spelling : constant String :=
      Adac.Compilation.Syntax.numeric_literal_spelling (context, literal);
    limit : constant Adac.Resources.Universal_Integer_Decimal_Digit_Limit :=
      universal_integer_decimal_digit_limit (context);
    result : Universal_Integer_Static_Result;
  begin
    case Adac.Compilation.Syntax.numeric_literal_form (context, literal) is
      when Adac.AST.Decimal_Integer_Form =>
        result := parse_universal_decimal_integer (spelling, limit);

      when Adac.AST.Based_Integer_Form =>
        result := parse_universal_based_integer (spelling, limit);

      when Adac.AST.Decimal_Real_Form | Adac.AST.Based_Real_Form =>
        raise Program_Error with
          "Adac.Sema: real literal reached universal integer evaluation";
    end case;

    if result.status = Universal_Integer_Static_Valid then
      result.semantic_type :=
        Adac.Compilation.Types.universal_integer (context);
    end if;
    return result;
  end parse_universal_integer_literal;

  function exact_static_atom_type
    (context       : Adac.Compilation.Context;
     expected_type : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
  begin
    if expected_type = Adac.Types.INVALID_TYPE_ID then
      return Adac.Compilation.Types.universal_integer (context);
    end if;

    Adac.Compilation.Types.validate (context, expected_type);
    case Adac.Compilation.Types.kind_of (context, expected_type) is
      when Adac.Types.Signed_Integer_Type |
           Adac.Types.Root_Integer_Type =>
        return expected_type;

      when Adac.Types.Universal_Integer_Type =>
        return Adac.Compilation.Types.universal_integer (context);

      when Adac.Types.Universal_Real_Type | Adac.Types.Root_Real_Type =>
        raise Program_Error with
          "Adac.Sema: exact integer atom received real expected type";

      when Adac.Types.Boolean_Type =>
        raise Program_Error with
          "Adac.Sema: exact integer atom received Boolean expected type";
    end case;
  end exact_static_atom_type;


  function universal_real_component_decimal_digit_limit
    (context : Adac.Compilation.Context)
  return Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit is
  begin
    return Adac.Compilation.resource_limits
      (context).maximum_universal_real_component_decimal_digits;
  end universal_real_component_decimal_digit_limit;

  function invalid_universal_real_literal_result
    (status : Universal_Real_Literal_Status)
  return Universal_Real_Literal_Result is
  begin
    return
      (status => status,
       value  => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE);
  end invalid_universal_real_literal_result;

  function numeral_digit_count
    (spelling : String;
     first    : Positive;
     last     : Natural)
  return Natural is
    result : Natural := 0;
  begin
    if last < first then
      return 0;
    end if;
    for index in first .. last loop
      if spelling (index) /= '_' then
        result := result + 1;
      end if;
    end loop;
    return result;
  end numeral_digit_count;

  function effective_fraction_last
    (spelling : String;
     first    : Positive;
     last     : Natural)
  return Natural is
    cursor : Natural := last;
  begin
    while cursor >= first loop
      if spelling (cursor) = '_' or else spelling (cursor) = '0' then
        if cursor = first then
          return 0;
        end if;
        cursor := cursor - 1;
      else
        return cursor;
      end if;
    end loop;
    return 0;
  end effective_fraction_last;

  procedure parse_real_literal_exponent
    (spelling  : String;
     first     : Positive;
     maximum   : Long_Long_Integer;
     value     : out Long_Long_Integer;
     valid     : out Boolean;
     too_large : out Boolean)
  is
    index     : Natural := first;
    negative  : Boolean := False;
    magnitude : Long_Long_Integer;
  begin
    value     := 0;
    valid     := False;
    too_large := False;
    if index > spelling'Last then
      return;
    end if;
    if spelling (index) = '-' then
      negative := True;
      index := index + 1;
    elsif spelling (index) = '+' then
      index := index + 1;
    end if;
    if index > spelling'Last then
      return;
    end if;

    parse_numeral
      (spelling,
       Positive (index),
       spelling'Last,
       10,
       maximum,
       magnitude,
       valid,
       too_large);
    if valid and then not too_large then
      if negative then
        value := -magnitude;
      else
        value := magnitude;
      end if;
    end if;
  end parse_real_literal_exponent;

  function parse_scaled_universal_real_literal
    (spelling       : String;
     whole_first    : Positive;
     whole_last     : Natural;
     fraction_first : Positive;
     fraction_last  : Natural;
     base           : Positive;
     exponent_first : Natural;
     limit          :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Literal_Result is
    integer_limit : constant
      Adac.Resources.Universal_Integer_Decimal_Digit_Limit :=
        Adac.Resources.Universal_Integer_Decimal_Digit_Limit (limit);
    base_value : constant Adac.Types.Universal_Integer_Value :=
      Adac.Types.make_universal_integer_value (Long_Long_Integer (base));
    one : constant Adac.Types.Universal_Integer_Value :=
      Adac.Types.make_universal_integer_value (1);
    trimmed_fraction_last : constant Natural :=
      effective_fraction_last (spelling, fraction_first, fraction_last);
    fractional_digits : Natural := 0;
    whole : Universal_Integer_Static_Result;
    fraction : Universal_Integer_Static_Result;
    significand : Adac.Types.Universal_Integer_Value :=
      Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
    exponent : Long_Long_Integer := 0;
    exponent_valid : Boolean := True;
    exponent_too_large : Boolean := False;
    exponent_maximum : Long_Long_Integer := 0;
  begin
    if limit = 0 then
      return invalid_universal_real_literal_result
        (Universal_Real_Literal_Resource_Limit);
    end if;

    if trimmed_fraction_last /= 0 then
      fractional_digits := numeral_digit_count
        (spelling, fraction_first, trimmed_fraction_last);
    end if;
    exponent_maximum :=
      Long_Long_Integer (fractional_digits) +
      Long_Long_Integer (limit) * 4 + 4;

    whole := parse_universal_integer_numeral
      (spelling, whole_first, whole_last, base, integer_limit);
    if whole.status /= Universal_Integer_Static_Valid then
      return invalid_universal_real_literal_result
        (Universal_Real_Literal_Invalid);
    end if;

    if trimmed_fraction_last = 0 then
      significand := whole.value;
    else
      fraction := parse_universal_integer_numeral
        (spelling,
         fraction_first,
         trimmed_fraction_last,
         base,
         integer_limit);
      if fraction.status /= Universal_Integer_Static_Valid then
        return invalid_universal_real_literal_result
          (Universal_Real_Literal_Invalid);
      end if;
      declare
        fraction_scale : constant Adac.Types.Universal_Integer_Value :=
          Adac.Types.universal_integer_power
            (base_value,
             Adac.Types.make_universal_integer_value
               (Long_Long_Integer (fractional_digits)),
             integer_limit);
      begin
        significand := Adac.Types.universal_integer_add
          (Adac.Types.universal_integer_multiply
             (whole.value, fraction_scale, integer_limit),
           fraction.value,
           integer_limit);
      end;
    end if;

    if exponent_first /= 0 then
      parse_real_literal_exponent
        (spelling,
         Positive (exponent_first),
         exponent_maximum,
         exponent,
         exponent_valid,
         exponent_too_large);
      if not exponent_valid then
        return invalid_universal_real_literal_result
          (Universal_Real_Literal_Invalid);
      elsif exponent_too_large then
        return invalid_universal_real_literal_result
          (Universal_Real_Literal_Resource_Limit);
      end if;
    end if;

    if Adac.Types.universal_integer_is_zero (significand) then
      return
        (status => Universal_Real_Literal_Valid,
         value  => Adac.Types.make_universal_real_value_from_integer_quotient
           (significand, one, limit));
    end if;

    declare
      net_power : constant Long_Long_Integer :=
        exponent - Long_Long_Integer (fractional_digits);
      numerator : Adac.Types.Universal_Integer_Value := significand;
      denominator : Adac.Types.Universal_Integer_Value := one;
    begin
      if net_power /= 0 then
        declare
          magnitude : Long_Long_Integer := net_power;
        begin
          if magnitude < 0 then
            magnitude := -magnitude;
          end if;
          declare
            scale : constant Adac.Types.Universal_Integer_Value :=
              Adac.Types.universal_integer_power
                (base_value,
                 Adac.Types.make_universal_integer_value (magnitude),
                 integer_limit);
          begin
            if net_power < 0 then
              denominator := scale;
            else
              numerator := Adac.Types.universal_integer_multiply
                (numerator, scale, integer_limit);
            end if;
          end;
        end;
      end if;

      return
        (status => Universal_Real_Literal_Valid,
         value  => Adac.Types.make_universal_real_value_from_integer_quotient
           (numerator, denominator, limit));
    end;
  exception
    when Adac.Resources.Limit_Exceeded =>
      return invalid_universal_real_literal_result
        (Universal_Real_Literal_Resource_Limit);
  end parse_scaled_universal_real_literal;

  function parse_universal_decimal_real_literal
    (spelling : String;
     limit    :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Literal_Result is
    point_index    : Natural := 0;
    exponent_index : Natural := 0;
    fraction_last  : Natural;
    exponent_first : Natural := 0;
  begin
    for index in spelling'Range loop
      if spelling (index) = '.' then
        point_index := index;
      elsif spelling (index) = 'E' or else spelling (index) = 'e' then
        exponent_index := index;
        exit;
      end if;
    end loop;
    if point_index <= spelling'First then
      return invalid_universal_real_literal_result
        (Universal_Real_Literal_Invalid);
    end if;
    if exponent_index = 0 then
      fraction_last := spelling'Last;
    else
      fraction_last := exponent_index - 1;
      exponent_first := exponent_index + 1;
    end if;
    if point_index + 1 > fraction_last then
      return invalid_universal_real_literal_result
        (Universal_Real_Literal_Invalid);
    end if;

    return parse_scaled_universal_real_literal
      (spelling,
       spelling'First,
       point_index - 1,
       Positive (point_index + 1),
       fraction_last,
       10,
       exponent_first,
       limit);
  end parse_universal_decimal_real_literal;

  function parse_universal_based_real_literal
    (spelling : String;
     limit    :
       Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Universal_Real_Literal_Result is
    first_hash     : Natural := 0;
    second_hash    : Natural := 0;
    point_index    : Natural := 0;
    base_value     : Long_Long_Integer;
    base_valid     : Boolean;
    base_too_large : Boolean;
    exponent_first : Natural := 0;
  begin
    for index in spelling'Range loop
      if spelling (index) = '#' then
        if first_hash = 0 then
          first_hash := index;
        else
          second_hash := index;
          exit;
        end if;
      elsif spelling (index) = '.' and then first_hash /= 0 then
        point_index := index;
      end if;
    end loop;
    if first_hash <= spelling'First or else
       point_index <= first_hash + 1 or else
       second_hash <= point_index + 1
    then
      return invalid_universal_real_literal_result
        (Universal_Real_Literal_Invalid);
    end if;

    parse_numeral
      (spelling,
       spelling'First,
       first_hash - 1,
       10,
       16,
       base_value,
       base_valid,
       base_too_large);
    if not base_valid or else base_too_large or else
       base_value < 2 or else base_value > 16
    then
      return invalid_universal_real_literal_result
        (Universal_Real_Literal_Invalid);
    end if;

    if second_hash < spelling'Last then
      if spelling (second_hash + 1) /= 'E' and then
         spelling (second_hash + 1) /= 'e'
      then
        return invalid_universal_real_literal_result
          (Universal_Real_Literal_Invalid);
      end if;
      if second_hash + 2 > spelling'Last then
        return invalid_universal_real_literal_result
          (Universal_Real_Literal_Invalid);
      end if;
      exponent_first := second_hash + 2;
    end if;

    return parse_scaled_universal_real_literal
      (spelling,
       Positive (first_hash + 1),
       point_index - 1,
       Positive (point_index + 1),
       second_hash - 1,
       Positive (base_value),
       exponent_first,
       limit);
  end parse_universal_based_real_literal;

  function parse_universal_real_literal
    (context : Adac.Compilation.Context;
     literal : Adac.AST.Node_ID)
  return Universal_Real_Literal_Result is
    spelling : constant String :=
      Adac.Compilation.Syntax.numeric_literal_spelling (context, literal);
    limit : constant
      Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit :=
        universal_real_component_decimal_digit_limit (context);
  begin
    case Adac.Compilation.Syntax.numeric_literal_form (context, literal) is
      when Adac.AST.Decimal_Real_Form =>
        return parse_universal_decimal_real_literal (spelling, limit);

      when Adac.AST.Based_Real_Form =>
        return parse_universal_based_real_literal (spelling, limit);

      when Adac.AST.Decimal_Integer_Form | Adac.AST.Based_Integer_Form =>
        return invalid_universal_real_literal_result
          (Universal_Real_Literal_Invalid);
    end case;
  end parse_universal_real_literal;

  function invalid_universal_real_static_result
    (status : Universal_Real_Static_Status)
  return Universal_Real_Static_Result is
  begin
    return
      (status        => status,
       semantic_type => Adac.Types.INVALID_TYPE_ID,
       integer_value => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
       value         => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE);
  end invalid_universal_real_static_result;

  function evaluate_static_universal_real_atom
    (context     : Adac.Compilation.Context;
     local_scope : Adac.Semantics.Lexical_Scope;
     expression  : Adac.AST.Node_ID)
  return Universal_Real_Static_Result is
  begin
    case Adac.Compilation.Syntax.kind_of (context, expression) is
      when Adac.AST.Numeric_Literal_Node =>
        case Adac.Compilation.Syntax.numeric_literal_form
          (context, expression)
        is
          when Adac.AST.Decimal_Integer_Form | Adac.AST.Based_Integer_Form =>
            declare
              parsed : constant Universal_Integer_Static_Result :=
                parse_universal_integer_literal (context, expression);
            begin
              case parsed.status is
                when Universal_Integer_Static_Valid =>
                  return
                    (status        => Universal_Real_Static_Valid,
                     semantic_type => parsed.semantic_type,
                     integer_value => parsed.value,
                     value         => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE);

                when Universal_Integer_Static_Invalid =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Invalid);

                when Universal_Integer_Static_Resource_Limit =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Resource_Limit);

                when Universal_Integer_Static_Zero_Divisor =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Zero_Divisor);

                when Universal_Integer_Static_Unsupported =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Unsupported);
              end case;
            end;

          when Adac.AST.Decimal_Real_Form | Adac.AST.Based_Real_Form =>
            declare
              parsed : constant Universal_Real_Literal_Result :=
                parse_universal_real_literal (context, expression);
            begin
              case parsed.status is
                when Universal_Real_Literal_Invalid =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Invalid);

                when Universal_Real_Literal_Resource_Limit =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Resource_Limit);

                when Universal_Real_Literal_Valid =>
                  return
                    (status        => Universal_Real_Static_Valid,
                     semantic_type =>
                       Adac.Compilation.Types.universal_real (context),
                     integer_value =>
                       Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
                     value         => parsed.value);
              end case;
            end;
        end case;

      when Adac.AST.Identifier_Name_Node =>
        declare
          symbol : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax.identifier_symbol (context, expression);
          real_type : constant Adac.Types.Type_ID :=
            Adac.Compilation.Semantics.resolve_local_real_number_type
              (context, local_scope, symbol);
        begin
          if real_type /= Adac.Types.INVALID_TYPE_ID then
            if real_type /= Adac.Compilation.Types.universal_real (context) then
              raise Program_Error with
                "Adac.Sema: real named number lost universal type";
            end if;
            return
              (status        => Universal_Real_Static_Valid,
               semantic_type => real_type,
               integer_value => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
               value         => Adac.Compilation.Semantics
                 .resolve_local_real_number_value
                   (context, local_scope, symbol));
          end if;

          declare
            integer_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics.resolve_local_integer_number_type
                (context, local_scope, symbol);
          begin
            if integer_type = Adac.Types.INVALID_TYPE_ID then
              return invalid_universal_real_static_result
                (Universal_Real_Static_Unsupported);
            end if;
            if integer_type /=
              Adac.Compilation.Types.universal_integer (context)
            then
              raise Program_Error with
                "Adac.Sema: integer named number lost universal type";
            end if;
            return
              (status        => Universal_Real_Static_Valid,
               semantic_type => integer_type,
               integer_value => Adac.Compilation.Semantics
                 .resolve_local_integer_number_value
                   (context, local_scope, symbol),
               value         => Adac.Types.INVALID_UNIVERSAL_REAL_VALUE);
          end;
        end;

      when others =>
        return invalid_universal_real_static_result
          (Universal_Real_Static_Unsupported);
    end case;
  end evaluate_static_universal_real_atom;

  function absolute_universal_real_value
    (value : Adac.Types.Universal_Real_Value;
     limit : Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Adac.Types.Universal_Real_Value is
  begin
    if Adac.Types.universal_real_is_negative (value) then
      return Adac.Types.universal_real_negate (value, limit);
    end if;
    return value;
  end absolute_universal_real_value;

  function exact_numeric_as_real
    (context : Adac.Compilation.Context;
     item    : Exact_Static_Numeric_Value;
     limit   : Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit)
  return Adac.Types.Universal_Real_Value is
  begin
    case Adac.Compilation.Types.kind_of (context, item.semantic_type) is
      when Adac.Types.Universal_Real_Type | Adac.Types.Root_Real_Type =>
        Adac.Types.validate (item.real_value);
        return item.real_value;

      when Adac.Types.Universal_Integer_Type | Adac.Types.Root_Integer_Type =>
        Adac.Types.validate (item.integer_value);
        return Adac.Types.make_universal_real_value_from_integer_quotient
          (item.integer_value,
           Adac.Types.make_universal_integer_value (1),
           limit);

      when Adac.Types.Signed_Integer_Type =>
        raise Program_Error with
          "Adac.Sema: specific Integer reached root-real conversion";

      when Adac.Types.Boolean_Type =>
        raise Program_Error with
          "Adac.Sema: Boolean reached root-real conversion";
    end case;
  end exact_numeric_as_real;

  function resolve_exact_real_multiplying_operator_type
    (context           : Adac.Compilation.Context;
     operator_spelling : String;
     left_type         : Adac.Types.Type_ID;
     right_type        : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
    homogeneous : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types
        .resolve_predefined_homogeneous_binary_real_operator_type
          (context, left_type, right_type);
  begin
    if homogeneous /= Adac.Types.INVALID_TYPE_ID then
      return homogeneous;
    end if;

    if operator_spelling = "*" then
      return Adac.Compilation.Types
        .resolve_predefined_mixed_real_integer_multiplying_operator_type
          (context,
           Adac.Types.Mixed_Real_Integer_Multiply,
           left_type,
           right_type);
    elsif operator_spelling = "/" then
      return Adac.Compilation.Types
        .resolve_predefined_mixed_real_integer_multiplying_operator_type
          (context,
           Adac.Types.Mixed_Real_Integer_Divide,
           left_type,
           right_type);
    end if;

    return Adac.Types.INVALID_TYPE_ID;
  end resolve_exact_real_multiplying_operator_type;



  function resolve_supported_subtype_mark
    (context      : Adac.Compilation.Context;
     local_scope  : Adac.Semantics.Lexical_Scope;
     subtype_mark : Adac.AST.Node_ID)
  return Adac.Types.Type_ID is
  begin
    case Adac.Compilation.Syntax.kind_of (context, subtype_mark) is
      when Adac.AST.Identifier_Name_Node =>
        declare
          symbol : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax.identifier_symbol (context, subtype_mark);
          local_type : constant Adac.Types.Type_ID :=
            Adac.Compilation.Semantics.resolve_local_subtype
              (context, local_scope, symbol);
        begin
          if local_type /= Adac.Types.INVALID_TYPE_ID then
            return local_type;
          end if;

          if Adac.Compilation.Semantics.resolve_local_object
               (context, local_scope, symbol) /= 0 or else
             Adac.Compilation.Semantics
               .resolve_local_static_integer_constant_type
                 (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
             or else Adac.Compilation.Semantics
               .resolve_local_static_boolean_constant_type
                 (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
             or else Adac.Compilation.Semantics
               .resolve_local_integer_number_type
                 (context, local_scope, symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
             Adac.Compilation.Semantics.resolve_local_real_number_type
               (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
          then
            return Adac.Types.INVALID_TYPE_ID;
          end if;

          return Adac.Compilation.Types.resolve_predefined_type_name
            (context, symbol);
        end;

      when Adac.AST.Selected_Name_Node =>
        declare
          prefix : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.name_prefix (context, subtype_mark);
        begin
          if Adac.Compilation.Syntax.kind_of (context, prefix) /=
            Adac.AST.Identifier_Name_Node
          then
            return Adac.Types.INVALID_TYPE_ID;
          end if;

          declare
            package_symbol : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.identifier_symbol (context, prefix);
            selector : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.selector_symbol (context, subtype_mark);
          begin
            if Adac.Compilation.Semantics.resolve_local_object
                 (context, local_scope, package_symbol) /= 0 or else
               Adac.Compilation.Semantics.resolve_local_subtype
                 (context, local_scope, package_symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics
                 .resolve_local_static_integer_constant_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID
               or else Adac.Compilation.Semantics
                 .resolve_local_static_boolean_constant_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID
               or else Adac.Compilation.Semantics
                 .resolve_local_integer_number_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics.resolve_local_real_number_type
                 (context, local_scope, package_symbol) /=
                   Adac.Types.INVALID_TYPE_ID
            then
              return Adac.Types.INVALID_TYPE_ID;
            end if;

            return Adac.Compilation.Types.resolve_predefined_type_name
              (context, package_symbol, selector);
          end;
        end;

      when others =>
        return Adac.Types.INVALID_TYPE_ID;
    end case;
  end resolve_supported_subtype_mark;

  function evaluate_static_boolean_atom
    (context       : Adac.Compilation.Context;
     local_scope   : Adac.Semantics.Lexical_Scope;
     expression    : Adac.AST.Node_ID;
     expected_type : Adac.Types.Type_ID)
  return Boolean_Static_Result is
  begin
    if expected_type /= Adac.Compilation.Types.standard_boolean (context) then
      raise Program_Error with
        "Adac.Sema: static Boolean atom expected Standard.Boolean";
    end if;

    if Adac.Compilation.Syntax.kind_of (context, expression) /=
      Adac.AST.Identifier_Name_Node
    then
      return (status => Boolean_Static_Unsupported, others => <>);
    end if;

    declare
      symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Syntax.identifier_symbol (context, expression);
      local_boolean_type : constant Adac.Types.Type_ID :=
        Adac.Compilation.Semantics.resolve_local_static_boolean_constant_type
          (context, local_scope, symbol);
    begin
      if local_boolean_type /= Adac.Types.INVALID_TYPE_ID then
        if local_boolean_type /= expected_type then
          raise Program_Error with
            "Adac.Sema: local Boolean constant lost expected type";
        end if;
        return
          (status        => Boolean_Static_Valid,
           semantic_type => local_boolean_type,
           value         => Adac.Compilation.Semantics
             .resolve_local_static_boolean_constant_value
               (context, local_scope, symbol));
      end if;

      if Adac.Compilation.Semantics.resolve_local_object
           (context, local_scope, symbol) /= 0 or else
         Adac.Compilation.Semantics.resolve_local_subtype
           (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID or else
         Adac.Compilation.Semantics.resolve_local_static_integer_constant_type
           (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID or else
         Adac.Compilation.Semantics.resolve_local_integer_number_type
           (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID or else
         Adac.Compilation.Semantics.resolve_local_real_number_type
           (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
      then
        return (status => Boolean_Static_Unsupported, others => <>);
      end if;

      declare
        resolution : constant Adac.Compilation.Types
          .Predefined_Boolean_Literal_Resolution :=
            Adac.Compilation.Types.resolve_predefined_boolean_literal
              (context, symbol);
      begin
        if resolution.status /=
             Adac.Compilation.Types.Predefined_Boolean_Literal_Found or else
           resolution.semantic_type /= expected_type
        then
          return (status => Boolean_Static_Unsupported, others => <>);
        end if;
        return
          (status        => Boolean_Static_Valid,
           semantic_type => resolution.semantic_type,
           value         => resolution.value);
      end;
    end;
  end evaluate_static_boolean_atom;

  function is_supported_static_boolean_expression
    (context       : Adac.Compilation.Context;
     local_scope   : Adac.Semantics.Lexical_Scope;
     expression    : Adac.AST.Node_ID;
     expected_type : Adac.Types.Type_ID)
  return Boolean is
    frames : Boolean_Static_Evaluation_Frame_Vectors.Vector;
  begin
    if expected_type /= Adac.Compilation.Types.standard_boolean (context) then
      raise Program_Error with
        "Adac.Sema: static Boolean shape expected Standard.Boolean";
    end if;

    frames.append
      (Boolean_Static_Evaluation_Frame'
         (action => Visit_Boolean_Static_Expression,
          node   => expression));
    while not frames.is_empty loop
      declare
        frame : constant Boolean_Static_Evaluation_Frame := frames.last_element;
      begin
        frames.delete_last;
        if frame.action /= Visit_Boolean_Static_Expression then
          raise Program_Error with
            "Adac.Sema: Boolean shape checker received apply frame";
        end if;

        case Adac.Compilation.Syntax.kind_of (context, frame.node) is
          when Adac.AST.Identifier_Name_Node =>
            declare
              atom : constant Boolean_Static_Result :=
                evaluate_static_boolean_atom
                  (context, local_scope, frame.node, expected_type);
            begin
              if atom.status /= Boolean_Static_Valid or else
                 atom.semantic_type /= expected_type
              then
                return False;
              end if;
            end;

          when Adac.AST.Parenthesized_Expression_Node =>
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax
                    .parenthesized_expression_child (context, frame.node)));

          when Adac.AST.Unary_Operator_Node =>
            if Adac.Compilation.Syntax.unary_operator_spelling
                 (context, frame.node) /= "not"
            then
              return False;
            end if;
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax.unary_operand
                    (context, frame.node)));

          when Adac.AST.Relation_Node =>
            declare
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.relation_operator_spelling
                  (context, frame.node);
            begin
              if operator_spelling /= "=" and then
                 operator_spelling /= "/=" and then
                 operator_spelling /= "<" and then
                 operator_spelling /= "<=" and then
                 operator_spelling /= ">" and then
                 operator_spelling /= ">="
              then
                return False;
              end if;
            end;
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax.relation_right_operand
                    (context, frame.node)));
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax.relation_left_operand
                    (context, frame.node)));

          when Adac.AST.Logical_Expression_Node =>
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax.logical_right_operand
                    (context, frame.node)));
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax.logical_left_operand
                    (context, frame.node)));

          when Adac.AST.Short_Circuit_Expression_Node =>
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax.short_circuit_right_operand
                    (context, frame.node)));
            frames.append
              (Boolean_Static_Evaluation_Frame'
                 (action => Visit_Boolean_Static_Expression,
                  node   => Adac.Compilation.Syntax.short_circuit_left_operand
                    (context, frame.node)));

          when others =>
            return False;
        end case;
      end;
    end loop;
    return True;
  end is_supported_static_boolean_expression;

  function evaluate_static_boolean_expression
    (context       : Adac.Compilation.Context;
     local_scope   : Adac.Semantics.Lexical_Scope;
     expression    : Adac.AST.Node_ID;
     expected_type : Adac.Types.Type_ID)
  return Boolean_Static_Result is
    frames : Boolean_Static_Evaluation_Frame_Vectors.Vector;
    values : Boolean_Static_Value_Vectors.Vector;
  begin
    if expected_type /= Adac.Compilation.Types.standard_boolean (context) then
      raise Program_Error with
        "Adac.Sema: static Boolean expression expected Standard.Boolean";
    end if;

    frames.append
      (Boolean_Static_Evaluation_Frame'
         (action => Visit_Boolean_Static_Expression,
          node   => expression));

    while not frames.is_empty loop
      declare
        frame : constant Boolean_Static_Evaluation_Frame :=
          frames.last_element;
      begin
        frames.delete_last;
        case frame.action is
          when Visit_Boolean_Static_Expression =>
            case Adac.Compilation.Syntax.kind_of (context, frame.node) is
              when Adac.AST.Parenthesized_Expression_Node =>
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => Adac.Compilation.Syntax
                        .parenthesized_expression_child
                          (context, frame.node)));

              when Adac.AST.Unary_Operator_Node =>
                if Adac.Compilation.Syntax.unary_operator_spelling
                     (context, frame.node) /= "not"
                then
                  return (status => Boolean_Static_Unsupported, others => <>);
                end if;
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Apply_Boolean_Static_Not,
                      node   => frame.node));
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => Adac.Compilation.Syntax.unary_operand
                        (context, frame.node)));

              when Adac.AST.Relation_Node =>
                declare
                  operator_spelling : constant String :=
                    Adac.Compilation.Syntax.relation_operator_spelling
                      (context, frame.node);
                begin
                  if operator_spelling /= "=" and then
                     operator_spelling /= "/=" and then
                     operator_spelling /= "<" and then
                     operator_spelling /= "<=" and then
                     operator_spelling /= ">" and then
                     operator_spelling /= ">="
                  then
                    return
                      (status => Boolean_Static_Unsupported, others => <>);
                  end if;
                end;
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Apply_Boolean_Static_Relation,
                      node   => frame.node));
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => Adac.Compilation.Syntax.relation_right_operand
                        (context, frame.node)));
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => Adac.Compilation.Syntax.relation_left_operand
                        (context, frame.node)));

              when Adac.AST.Logical_Expression_Node =>
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Apply_Boolean_Static_Logical,
                      node   => frame.node));
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => Adac.Compilation.Syntax.logical_right_operand
                        (context, frame.node)));
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => Adac.Compilation.Syntax.logical_left_operand
                        (context, frame.node)));

              when Adac.AST.Short_Circuit_Expression_Node =>
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Finish_Boolean_Static_Short_Circuit_Left,
                      node   => frame.node));
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => Adac.Compilation.Syntax
                        .short_circuit_left_operand (context, frame.node)));

              when Adac.AST.Identifier_Name_Node =>
                declare
                  atom : constant Boolean_Static_Result :=
                    evaluate_static_boolean_atom
                      (context, local_scope, frame.node, expected_type);
                begin
                  if atom.status /= Boolean_Static_Valid then
                    return atom;
                  end if;
                  if atom.semantic_type /= expected_type then
                    raise Program_Error with
                      "Adac.Sema: Boolean atom lost expected type";
                  end if;
                  values.append (atom.value);
                end;

              when others =>
                return (status => Boolean_Static_Unsupported, others => <>);
            end case;

          when Apply_Boolean_Static_Not =>
            if values.is_empty then
              raise Program_Error with
                "Adac.Sema: Boolean not frame lost operand value";
            end if;
            declare
              operand : constant Adac.Types.Boolean_Value :=
                values.last_element;
            begin
              values.delete_last;
              case operand is
                when Adac.Types.False_Boolean_Value =>
                  values.append (Adac.Types.True_Boolean_Value);

                when Adac.Types.True_Boolean_Value =>
                  values.append (Adac.Types.False_Boolean_Value);
              end case;
            end;

          when Apply_Boolean_Static_Relation =>
            if Natural (values.length) < 2 then
              raise Program_Error with
                "Adac.Sema: Boolean relation frame lost operand values";
            end if;
            declare
              right : constant Adac.Types.Boolean_Value := values.last_element;
              left  : Adac.Types.Boolean_Value;
              relation_holds : Boolean := False;
              result : Adac.Types.Boolean_Value :=
                Adac.Types.False_Boolean_Value;
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.relation_operator_spelling
                  (context, frame.node);
            begin
              values.delete_last;
              left := values.last_element;
              values.delete_last;
              if operator_spelling = "=" then
                relation_holds := left = right;
              elsif operator_spelling = "/=" then
                relation_holds := left /= right;
              elsif operator_spelling = "<" then
                relation_holds := left < right;
              elsif operator_spelling = "<=" then
                relation_holds := left <= right;
              elsif operator_spelling = ">" then
                relation_holds := left > right;
              elsif operator_spelling = ">=" then
                relation_holds := left >= right;
              else
                raise Program_Error with
                  "Adac.Sema: Boolean relation frame has invalid operator";
              end if;
              if relation_holds then
                result := Adac.Types.True_Boolean_Value;
              end if;
              values.append (result);
            end;

          when Apply_Boolean_Static_Logical =>
            if Natural (values.length) < 2 then
              raise Program_Error with
                "Adac.Sema: Boolean logical frame lost operand values";
            end if;
            declare
              right : constant Adac.Types.Boolean_Value := values.last_element;
              left  : Adac.Types.Boolean_Value;
              result : Adac.Types.Boolean_Value :=
                Adac.Types.False_Boolean_Value;
            begin
              values.delete_last;
              left := values.last_element;
              values.delete_last;
              case Adac.Compilation.Syntax.logical_operator
                (context, frame.node)
              is
                when Adac.AST.And_Logical_Operator =>
                  if left = Adac.Types.True_Boolean_Value and then
                     right = Adac.Types.True_Boolean_Value
                  then
                    result := Adac.Types.True_Boolean_Value;
                  end if;

                when Adac.AST.Or_Logical_Operator =>
                  if left = Adac.Types.True_Boolean_Value or else
                     right = Adac.Types.True_Boolean_Value
                  then
                    result := Adac.Types.True_Boolean_Value;
                  end if;

                when Adac.AST.Xor_Logical_Operator =>
                  if left /= right then
                    result := Adac.Types.True_Boolean_Value;
                  end if;
              end case;
              values.append (result);
            end;

          when Finish_Boolean_Static_Short_Circuit_Left =>
            if values.is_empty then
              raise Program_Error with
                "Adac.Sema: Boolean short-circuit frame lost left value";
            end if;
            declare
              left : constant Adac.Types.Boolean_Value := values.last_element;
              right_node : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.short_circuit_right_operand
                  (context, frame.node);
              skips_right : Boolean := False;
            begin
              values.delete_last;
              case Adac.Compilation.Syntax.short_circuit_operator
                (context, frame.node)
              is
                when Adac.AST.And_Then_Short_Circuit_Operator =>
                  skips_right := left = Adac.Types.False_Boolean_Value;

                when Adac.AST.Or_Else_Short_Circuit_Operator =>
                  skips_right := left = Adac.Types.True_Boolean_Value;
              end case;

              if skips_right then
                if not is_supported_static_boolean_expression
                  (context, local_scope, right_node, expected_type)
                then
                  return (status => Boolean_Static_Unsupported, others => <>);
                end if;
                values.append (left);
              else
                frames.append
                  (Boolean_Static_Evaluation_Frame'
                     (action => Visit_Boolean_Static_Expression,
                      node   => right_node));
              end if;
            end;
        end case;
      end;
    end loop;

    if Natural (values.length) /= 1 then
      raise Program_Error with
        "Adac.Sema: static Boolean evaluation lost result value";
    end if;
    return
      (status        => Boolean_Static_Valid,
       semantic_type => expected_type,
       value         => values.last_element);
  end evaluate_static_boolean_expression;

  procedure evaluate_runtime_boolean_expression
    (context       : Adac.Compilation.Context;
     local_scope   : Adac.Semantics.Lexical_Scope;
     local_objects : Local_Object_Vectors.Vector;
     expression    : Adac.AST.Node_ID;
     expected_type : Adac.Types.Type_ID;
     values        : in out Adac.Semantics.Boolean_Expression_Value_List;
     status        : out Boolean_Runtime_Status)
  is
    frames : Boolean_Runtime_Evaluation_Frame_Vectors.Vector;
  begin
    if expected_type /= Adac.Compilation.Types.standard_boolean (context) then
      raise Program_Error with
        "Adac.Sema: runtime Boolean expression expected Standard.Boolean";
    end if;

    status := Boolean_Runtime_Valid;
    frames.append
      (Boolean_Runtime_Evaluation_Frame'
         (action => Visit_Boolean_Runtime_Expression,
          node   => expression));

    while not frames.is_empty loop
      declare
        frame : constant Boolean_Runtime_Evaluation_Frame := frames.last_element;
      begin
        frames.delete_last;
        case frame.action is
          when Visit_Boolean_Runtime_Expression =>
            case Adac.Compilation.Syntax.kind_of (context, frame.node) is
              when Adac.AST.Identifier_Name_Node =>
                declare
                  atom : constant Boolean_Static_Result :=
                    evaluate_static_boolean_atom
                      (context, local_scope, frame.node, expected_type);
                begin
                  if atom.status = Boolean_Static_Valid then
                    Adac.Semantics.append_boolean_expression_constant
                      (values, frame.node, atom.value);
                  else
                    declare
                      source_symbol : constant Adac.Symbols.Symbol_ID :=
                        Adac.Compilation.Syntax.identifier_symbol
                          (context, frame.node);
                      resolved_source : constant Natural :=
                        Adac.Compilation.Semantics.resolve_local_object
                          (context, local_scope, source_symbol);
                    begin
                      if resolved_source = 0 then
                        status := Boolean_Runtime_Unsupported;
                        return;
                      end if;
                      declare
                        source_local : constant Positive :=
                          Positive (resolved_source);
                        source_descriptor : constant Local_Object_Descriptor :=
                          local_objects (source_local);
                      begin
                        if source_descriptor.semantic_type /= expected_type then
                          status := Boolean_Runtime_Type_Mismatch;
                          return;
                        end if;
                        if not source_descriptor.has_defined_boolean_value then
                          status := Boolean_Runtime_Uninitialized;
                          return;
                        end if;
                        Adac.Semantics.append_boolean_expression_local
                          (values,
                           frame.node,
                           source_local,
                           source_descriptor.boolean_definition_statement,
                           source_descriptor.defined_boolean_value);
                      end;
                    end;
                  end if;
                end;

              when Adac.AST.Parenthesized_Expression_Node =>
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Visit_Boolean_Runtime_Expression,
                      node   => Adac.Compilation.Syntax
                        .parenthesized_expression_child (context, frame.node)));

              when Adac.AST.Unary_Operator_Node =>
                if Adac.Compilation.Syntax.unary_operator_spelling
                     (context, frame.node) /= "not"
                then
                  status := Boolean_Runtime_Unsupported;
                  return;
                end if;
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Apply_Boolean_Runtime_Not,
                      node   => frame.node));
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Visit_Boolean_Runtime_Expression,
                      node   => Adac.Compilation.Syntax.unary_operand
                        (context, frame.node)));

              when Adac.AST.Logical_Expression_Node =>
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Apply_Boolean_Runtime_Logical,
                      node   => frame.node));
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Visit_Boolean_Runtime_Expression,
                      node   => Adac.Compilation.Syntax.logical_right_operand
                        (context, frame.node)));
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Visit_Boolean_Runtime_Expression,
                      node   => Adac.Compilation.Syntax.logical_left_operand
                        (context, frame.node)));

              when Adac.AST.Relation_Node =>
                if semantic_boolean_relation_operator
                     (Adac.Compilation.Syntax.relation_operator_spelling
                        (context, frame.node)) =
                     Adac.Semantics.No_Boolean_Binary_Operator
                then
                  status := Boolean_Runtime_Unsupported;
                  return;
                end if;
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Apply_Boolean_Runtime_Relation,
                      node   => frame.node));
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Visit_Boolean_Runtime_Expression,
                      node   => Adac.Compilation.Syntax.relation_right_operand
                        (context, frame.node)));
                frames.append
                  (Boolean_Runtime_Evaluation_Frame'
                     (action => Visit_Boolean_Runtime_Expression,
                      node   => Adac.Compilation.Syntax.relation_left_operand
                        (context, frame.node)));

              when Adac.AST.Short_Circuit_Expression_Node =>
                declare
                  folded : constant Boolean_Static_Result :=
                    evaluate_static_boolean_expression
                      (context, local_scope, frame.node, expected_type);
                begin
                  if folded.status /= Boolean_Static_Valid then
                    status := Boolean_Runtime_Unsupported;
                    return;
                  end if;
                  Adac.Semantics.append_boolean_expression_constant
                    (values, frame.node, folded.value);
                end;

              when others =>
                status := Boolean_Runtime_Unsupported;
                return;
            end case;

          when Apply_Boolean_Runtime_Not =>
            Adac.Semantics.append_boolean_expression_not (values, frame.node);

          when Apply_Boolean_Runtime_Relation =>
            Adac.Semantics.append_boolean_expression_binary
              (values,
               frame.node,
               semantic_boolean_relation_operator
                 (Adac.Compilation.Syntax.relation_operator_spelling
                    (context, frame.node)));

          when Apply_Boolean_Runtime_Logical =>
            Adac.Semantics.append_boolean_expression_binary
              (values,
               frame.node,
               semantic_boolean_binary_operator
                 (Adac.Compilation.Syntax.logical_operator
                    (context, frame.node)));
        end case;
      end;
    end loop;

    if not Adac.Semantics.boolean_expression_has_runtime_read (values) then
      status := Boolean_Runtime_Unsupported;
    end if;
  end evaluate_runtime_boolean_expression;

  function resolve_supported_boolean_subtype_mark
    (context      : Adac.Compilation.Context;
     local_scope  : Adac.Semantics.Lexical_Scope;
     subtype_mark : Adac.AST.Node_ID)
  return Adac.Types.Type_ID is
  begin
    case Adac.Compilation.Syntax.kind_of (context, subtype_mark) is
      when Adac.AST.Identifier_Name_Node =>
        declare
          symbol : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax.identifier_symbol (context, subtype_mark);
        begin
          if Adac.Compilation.Semantics.resolve_local_object
               (context, local_scope, symbol) /= 0 or else
             Adac.Compilation.Semantics.resolve_local_subtype
               (context, local_scope, symbol) /=
                 Adac.Types.INVALID_TYPE_ID or else
             Adac.Compilation.Semantics
               .resolve_local_static_integer_constant_type
                 (context, local_scope, symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
             Adac.Compilation.Semantics
               .resolve_local_static_boolean_constant_type
                 (context, local_scope, symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
             Adac.Compilation.Semantics.resolve_local_integer_number_type
               (context, local_scope, symbol) /=
                 Adac.Types.INVALID_TYPE_ID or else
             Adac.Compilation.Semantics.resolve_local_real_number_type
               (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
          then
            return Adac.Types.INVALID_TYPE_ID;
          end if;
          return Adac.Compilation.Types.resolve_predefined_boolean_type_name
            (context, symbol);
        end;

      when Adac.AST.Selected_Name_Node =>
        declare
          prefix : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.name_prefix (context, subtype_mark);
        begin
          if Adac.Compilation.Syntax.kind_of (context, prefix) /=
            Adac.AST.Identifier_Name_Node
          then
            return Adac.Types.INVALID_TYPE_ID;
          end if;
          declare
            package_symbol : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.identifier_symbol (context, prefix);
            selector : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.selector_symbol (context, subtype_mark);
          begin
            if Adac.Compilation.Semantics.resolve_local_object
                 (context, local_scope, package_symbol) /= 0 or else
               Adac.Compilation.Semantics.resolve_local_subtype
                 (context, local_scope, package_symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics
                 .resolve_local_static_integer_constant_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics
                 .resolve_local_static_boolean_constant_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics.resolve_local_integer_number_type
                 (context, local_scope, package_symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics.resolve_local_real_number_type
                 (context, local_scope, package_symbol) /=
                   Adac.Types.INVALID_TYPE_ID
            then
              return Adac.Types.INVALID_TYPE_ID;
            end if;
            return Adac.Compilation.Types.resolve_predefined_boolean_type_name
              (context, package_symbol, selector);
          end;
        end;

      when others =>
        return Adac.Types.INVALID_TYPE_ID;
    end case;
  end resolve_supported_boolean_subtype_mark;

  function resolve_supported_subtype_constraint
    (context      : Adac.Compilation.Context;
     local_scope  : Adac.Semantics.Lexical_Scope;
     subtype_mark : Adac.AST.Node_ID)
  return Adac.Semantics.Subtype_Constraint is
  begin
    case Adac.Compilation.Syntax.kind_of (context, subtype_mark) is
      when Adac.AST.Identifier_Name_Node =>
        declare
          symbol : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax.identifier_symbol (context, subtype_mark);
          local_type : constant Adac.Types.Type_ID :=
            Adac.Compilation.Semantics.resolve_local_subtype
              (context, local_scope, symbol);
        begin
          if local_type /= Adac.Types.INVALID_TYPE_ID then
            return Adac.Compilation.Semantics.resolve_local_subtype_constraint
              (context, local_scope, symbol);
          end if;

          if Adac.Compilation.Semantics.resolve_local_object
               (context, local_scope, symbol) /= 0 or else
             Adac.Compilation.Semantics
               .resolve_local_static_integer_constant_type
                 (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
             or else Adac.Compilation.Semantics
               .resolve_local_static_boolean_constant_type
                 (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
             or else Adac.Compilation.Semantics
               .resolve_local_integer_number_type
                 (context, local_scope, symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
             Adac.Compilation.Semantics.resolve_local_real_number_type
               (context, local_scope, symbol) /= Adac.Types.INVALID_TYPE_ID
          then
            return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
          end if;

          return Adac.Compilation.Semantics
            .resolve_predefined_subtype_constraint (context, symbol);
        end;

      when Adac.AST.Selected_Name_Node =>
        declare
          prefix : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.name_prefix (context, subtype_mark);
        begin
          if Adac.Compilation.Syntax.kind_of (context, prefix) /=
            Adac.AST.Identifier_Name_Node
          then
            return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
          end if;

          declare
            package_symbol : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.identifier_symbol (context, prefix);
            selector : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.selector_symbol (context, subtype_mark);
          begin
            if Adac.Compilation.Semantics.resolve_local_object
                 (context, local_scope, package_symbol) /= 0 or else
               Adac.Compilation.Semantics.resolve_local_subtype
                 (context, local_scope, package_symbol) /=
                   Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics
                 .resolve_local_static_integer_constant_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID
               or else Adac.Compilation.Semantics
                 .resolve_local_static_boolean_constant_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID
               or else Adac.Compilation.Semantics
                 .resolve_local_integer_number_type
                   (context, local_scope, package_symbol) /=
                     Adac.Types.INVALID_TYPE_ID or else
               Adac.Compilation.Semantics.resolve_local_real_number_type
                 (context, local_scope, package_symbol) /=
                   Adac.Types.INVALID_TYPE_ID
            then
              return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
            end if;

            return Adac.Compilation.Semantics
              .resolve_predefined_subtype_constraint
                (context, package_symbol, selector);
          end;
        end;

      when others =>
        return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
    end case;
  end resolve_supported_subtype_constraint;

  function evaluate_static_subtype_attribute
    (context     : Adac.Compilation.Context;
     local_scope : Adac.Semantics.Lexical_Scope;
     expression  : Adac.AST.Node_ID)
  return Universal_Integer_Static_Result is
    prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.name_prefix (context, expression);
    designator : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Syntax.attribute_symbol (context, expression);
    first_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.find (context, "First");
    last_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.find (context, "Last");
    subtype_type : Adac.Types.Type_ID;
    constraint   : Adac.Semantics.Subtype_Constraint;
    value        : Long_Long_Integer;
  begin
    subtype_type := resolve_supported_subtype_mark
      (context, local_scope, prefix);
    if subtype_type = Adac.Types.INVALID_TYPE_ID or else
       Adac.Compilation.Types.kind_of (context, subtype_type) /=
         Adac.Types.Signed_Integer_Type
    then
      return
        invalid_universal_integer_static_result
          (Universal_Integer_Static_Unsupported);
    end if;

    if (first_symbol = Adac.Symbols.INVALID_SYMBOL_ID or else
        designator /= first_symbol) and then
       (last_symbol = Adac.Symbols.INVALID_SYMBOL_ID or else
        designator /= last_symbol)
    then
      return
        invalid_universal_integer_static_result
          (Universal_Integer_Static_Unsupported);
    end if;

    constraint := resolve_supported_subtype_constraint
      (context, local_scope, prefix);
    case Adac.Semantics.subtype_constraint_category (constraint) is
      when Adac.Semantics.No_Constraint =>
        if designator = first_symbol then
          value := Adac.Compilation.Types.signed_integer_lower_bound
            (context, subtype_type);
        else
          value := Adac.Compilation.Types.signed_integer_upper_bound
            (context, subtype_type);
        end if;

      when Adac.Semantics.Signed_Integer_Range_Constraint =>
        if designator = first_symbol then
          value := Adac.Semantics.subtype_constraint_lower_bound (constraint);
        else
          value := Adac.Semantics.subtype_constraint_upper_bound (constraint);
        end if;
    end case;

    return
      (status        => Universal_Integer_Static_Valid,
       semantic_type => subtype_type,
       value         => Adac.Types.make_universal_integer_value (value));
  end evaluate_static_subtype_attribute;

  function evaluate_static_universal_integer_atom
    (context       : Adac.Compilation.Context;
     local_scope   : Adac.Semantics.Lexical_Scope;
     expression    : Adac.AST.Node_ID;
     expected_type : Adac.Types.Type_ID)
  return Universal_Integer_Static_Result is
    result_type : constant Adac.Types.Type_ID :=
      exact_static_atom_type (context, expected_type);
  begin
    case Adac.Compilation.Syntax.kind_of (context, expression) is
      when Adac.AST.Numeric_Literal_Node =>
        case Adac.Compilation.Syntax.numeric_literal_form
          (context, expression)
        is
          when Adac.AST.Decimal_Real_Form | Adac.AST.Based_Real_Form =>
            return
              invalid_universal_integer_static_result
                (Universal_Integer_Static_Unsupported);

          when Adac.AST.Decimal_Integer_Form | Adac.AST.Based_Integer_Form =>
            declare
              parsed : Universal_Integer_Static_Result :=
                parse_universal_integer_literal (context, expression);
            begin
              if parsed.status = Universal_Integer_Static_Valid then
                parsed.semantic_type := result_type;
              end if;
              return parsed;
            end;
        end case;

      when Adac.AST.Identifier_Name_Node =>
        declare
          symbol : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax.identifier_symbol (context, expression);
          number_type : constant Adac.Types.Type_ID :=
            Adac.Compilation.Semantics.resolve_local_integer_number_type
              (context, local_scope, symbol);
        begin
          if number_type /= Adac.Types.INVALID_TYPE_ID then
            if number_type /= Adac.Compilation.Types.universal_integer (context)
            then
              raise Program_Error with
                "Adac.Sema: integer named number lost universal type";
            end if;
            return
              (status        => Universal_Integer_Static_Valid,
               semantic_type => result_type,
               value         => Adac.Compilation.Semantics
                 .resolve_local_integer_number_value
                   (context, local_scope, symbol));
          end if;

          declare
            constant_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Semantics
                .resolve_local_static_integer_constant_type
                  (context, local_scope, symbol);
          begin
            if constant_type = Adac.Types.INVALID_TYPE_ID then
              return
                invalid_universal_integer_static_result
                  (Universal_Integer_Static_Unsupported);
            end if;
            if expected_type /= Adac.Types.INVALID_TYPE_ID and then
               constant_type /= expected_type
            then
              return
                invalid_universal_integer_static_result
                  (Universal_Integer_Static_Unsupported);
            end if;
            return
              (status        => Universal_Integer_Static_Valid,
               semantic_type => constant_type,
               value         => Adac.Types.make_universal_integer_value
                 (Adac.Compilation.Semantics
                    .resolve_local_static_integer_constant_value
                      (context, local_scope, symbol)));
          end;
        end;

      when Adac.AST.Attribute_Name_Node =>
        declare
          attribute_value : constant Universal_Integer_Static_Result :=
            evaluate_static_subtype_attribute
              (context, local_scope, expression);
        begin
          if attribute_value.status /= Universal_Integer_Static_Valid then
            return attribute_value;
          end if;
          if expected_type /= Adac.Types.INVALID_TYPE_ID and then
             attribute_value.semantic_type /= expected_type
          then
            return
              invalid_universal_integer_static_result
                (Universal_Integer_Static_Unsupported);
          end if;
          return attribute_value;
        end;

      when others =>
        return
          invalid_universal_integer_static_result
            (Universal_Integer_Static_Unsupported);
    end case;
  end evaluate_static_universal_integer_atom;

  function is_direct_integer_literal
    (context    : Adac.Compilation.Context;
     expression : Adac.AST.Node_ID)
  return Boolean is
  begin
    if Adac.Compilation.Syntax.kind_of (context, expression) /=
      Adac.AST.Numeric_Literal_Node
    then
      return False;
    end if;

    case Adac.Compilation.Syntax.numeric_literal_form (context, expression) is
      when Adac.AST.Decimal_Integer_Form | Adac.AST.Based_Integer_Form =>
        return True;

      when Adac.AST.Decimal_Real_Form | Adac.AST.Based_Real_Form =>
        return False;
    end case;
  end is_direct_integer_literal;

  function is_direct_real_literal
    (context    : Adac.Compilation.Context;
     expression : Adac.AST.Node_ID)
  return Boolean is
  begin
    if Adac.Compilation.Syntax.kind_of (context, expression) /=
      Adac.AST.Numeric_Literal_Node
    then
      return False;
    end if;

    case Adac.Compilation.Syntax.numeric_literal_form (context, expression) is
      when Adac.AST.Decimal_Real_Form | Adac.AST.Based_Real_Form =>
        return True;

      when Adac.AST.Decimal_Integer_Form | Adac.AST.Based_Integer_Form =>
        return False;
    end case;
  end is_direct_real_literal;

  function resolve_exact_unary_operator_type
    (context       : Adac.Compilation.Context;
     expected_type : Adac.Types.Type_ID;
     operand_type  : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
    resolved : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.resolve_predefined_unary_integer_operator_type
        (context, operand_type);
  begin
    if resolved = Adac.Types.INVALID_TYPE_ID then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    if expected_type /= Adac.Types.INVALID_TYPE_ID and then
       resolved /= expected_type
    then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    return resolved;
  end resolve_exact_unary_operator_type;

  function resolve_exact_homogeneous_binary_operator_type
    (context       : Adac.Compilation.Context;
     expected_type : Adac.Types.Type_ID;
     left_type     : Adac.Types.Type_ID;
     right_type    : Adac.Types.Type_ID)
  return Adac.Types.Type_ID is
    resolved : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types
        .resolve_predefined_homogeneous_binary_integer_operator_type
          (context, left_type, right_type);
  begin
    if resolved = Adac.Types.INVALID_TYPE_ID then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    if expected_type /= Adac.Types.INVALID_TYPE_ID and then
       resolved /= expected_type
    then
      return Adac.Types.INVALID_TYPE_ID;
    end if;
    return resolved;
  end resolve_exact_homogeneous_binary_operator_type;

  function exact_exponent_is_in_natural_range
    (context  : Adac.Compilation.Context;
     exponent : Exact_Static_Integer_Value)
  return Boolean is
    value : Long_Long_Integer;
  begin
    if exponent.semantic_type /=
      Adac.Compilation.Types.standard_integer (context)
    then
      raise Program_Error with
        "Adac.Sema: exact exponent lost Standard.Integer expected type";
    end if;
    if Adac.Types.universal_integer_is_negative (exponent.value) or else
       not Adac.Types.universal_integer_fits_long_long (exponent.value)
    then
      return False;
    end if;

    value := Adac.Types.universal_integer_to_long_long (exponent.value);
    return value <=
      Adac.Compilation.Types.signed_integer_upper_bound
        (context, exponent.semantic_type);
  end exact_exponent_is_in_natural_range;

  function evaluate_static_universal_integer_expression
    (context       : Adac.Compilation.Context;
     local_scope   : Adac.Semantics.Lexical_Scope;
     expression    : Adac.AST.Node_ID;
     expected_type : Adac.Types.Type_ID := Adac.Types.INVALID_TYPE_ID)
  return Universal_Integer_Static_Result is
    limit : constant Adac.Resources.Universal_Integer_Decimal_Digit_Limit :=
      universal_integer_decimal_digit_limit (context);
    frames : Exact_Static_Evaluation_Frame_Vectors.Vector;
    values : Exact_Static_Integer_Value_Vectors.Vector;
  begin
    if expected_type /= Adac.Types.INVALID_TYPE_ID then
      Adac.Compilation.Types.validate (context, expected_type);
      case Adac.Compilation.Types.kind_of (context, expected_type) is
        when Adac.Types.Signed_Integer_Type | Adac.Types.Root_Integer_Type =>
          null;

        when Adac.Types.Universal_Integer_Type =>
          raise Program_Error with
            "Adac.Sema: exact evaluator received universal expected type";

        when Adac.Types.Universal_Real_Type | Adac.Types.Root_Real_Type =>
          raise Program_Error with
            "Adac.Sema: exact integer evaluator received real expected type";

        when Adac.Types.Boolean_Type =>
          raise Program_Error with
            "Adac.Sema: exact integer evaluator received Boolean expected type";
      end case;
    end if;

    frames.append
      (Exact_Static_Evaluation_Frame'
         (action        => Visit_Static_Expression,
          node          => expression,
          expected_type => expected_type));

    while not frames.is_empty loop
      declare
        frame : constant Exact_Static_Evaluation_Frame := frames.last_element;
      begin
        frames.delete_last;

        case frame.action is
          when Visit_Static_Expression =>
            case Adac.Compilation.Syntax.kind_of (context, frame.node) is
              when Adac.AST.Parenthesized_Expression_Node =>
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          =>
                        Adac.Compilation.Syntax.parenthesized_expression_child
                          (context, frame.node),
                      expected_type => frame.expected_type));

              when Adac.AST.Unary_Operator_Node =>
                declare
                  operator_spelling : constant String :=
                    Adac.Compilation.Syntax.unary_operator_spelling
                      (context, frame.node);
                begin
                  if operator_spelling /= "+" and then
                     operator_spelling /= "-" and then
                     operator_spelling /= "abs"
                  then
                    return
                      invalid_universal_integer_static_result
                        (Universal_Integer_Static_Unsupported);
                  end if;
                end;
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Unary,
                      node          => frame.node,
                      expected_type => frame.expected_type));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax.unary_operand
                        (context, frame.node),
                      expected_type => frame.expected_type));

              when Adac.AST.Binary_Exponentiating_Node =>
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Exponentiating,
                      node          => frame.node,
                      expected_type => frame.expected_type));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          =>
                        Adac.Compilation.Syntax
                          .binary_exponentiating_right_operand
                            (context, frame.node),
                      expected_type =>
                        Adac.Compilation.Types.standard_integer (context)));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          =>
                        Adac.Compilation.Syntax
                          .binary_exponentiating_left_operand
                            (context, frame.node),
                      expected_type => frame.expected_type));

              when Adac.AST.Binary_Adding_Node =>
                declare
                  operator_spelling : constant String :=
                    Adac.Compilation.Syntax.binary_adding_operator_spelling
                      (context, frame.node);
                begin
                  if operator_spelling /= "+" and then
                     operator_spelling /= "-"
                  then
                    return
                      invalid_universal_integer_static_result
                        (Universal_Integer_Static_Unsupported);
                  end if;
                end;
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Adding,
                      node          => frame.node,
                      expected_type => frame.expected_type));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          =>
                        Adac.Compilation.Syntax.binary_adding_right_operand
                          (context, frame.node),
                      expected_type => frame.expected_type));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          =>
                        Adac.Compilation.Syntax.binary_adding_left_operand
                          (context, frame.node),
                      expected_type => frame.expected_type));

              when Adac.AST.Binary_Multiplying_Node =>
                declare
                  operator_spelling : constant String :=
                    Adac.Compilation.Syntax.binary_multiplying_operator_spelling
                      (context, frame.node);
                begin
                  if operator_spelling /= "*" and then
                     operator_spelling /= "/" and then
                     operator_spelling /= "rem" and then
                     operator_spelling /= "mod"
                  then
                    return
                      invalid_universal_integer_static_result
                        (Universal_Integer_Static_Unsupported);
                  end if;
                end;
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Multiplying,
                      node          => frame.node,
                      expected_type => frame.expected_type));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          =>
                        Adac.Compilation.Syntax.binary_multiplying_right_operand
                          (context, frame.node),
                      expected_type => frame.expected_type));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          =>
                        Adac.Compilation.Syntax.binary_multiplying_left_operand
                          (context, frame.node),
                      expected_type => frame.expected_type));

              when others =>
                declare
                  atom : constant Universal_Integer_Static_Result :=
                    evaluate_static_universal_integer_atom
                      (context,
                       local_scope,
                       frame.node,
                       frame.expected_type);
                begin
                  if atom.status /= Universal_Integer_Static_Valid then
                    return atom;
                  end if;
                  if atom.semantic_type = Adac.Types.INVALID_TYPE_ID then
                    raise Program_Error with
                      "Adac.Sema: exact atom lost semantic type";
                  end if;
                  values.append
                    (Exact_Static_Integer_Value'
                       (semantic_type => atom.semantic_type,
                        value         => atom.value));
                end;
            end case;

          when Apply_Static_Unary =>
            if values.is_empty then
              raise Program_Error with
                "Adac.Sema: exact unary frame lost operand value";
            end if;
            declare
              operand : constant Exact_Static_Integer_Value :=
                values.last_element;
              result_type : constant Adac.Types.Type_ID :=
                resolve_exact_unary_operator_type
                  (context, frame.expected_type, operand.semantic_type);
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.unary_operator_spelling
                  (context, frame.node);
              result_value : Adac.Types.Universal_Integer_Value :=
                Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
            begin
              values.delete_last;
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return
                  invalid_universal_integer_static_result
                    (Universal_Integer_Static_Unsupported);
              end if;
              if operator_spelling = "+" then
                result_value := operand.value;
              elsif operator_spelling = "-" then
                result_value := Adac.Types.universal_integer_negate
                  (operand.value, limit);
              elsif operator_spelling = "abs" then
                result_value := Adac.Types.universal_integer_absolute
                  (operand.value, limit);
              else
                raise Program_Error with
                  "Adac.Sema: exact unary frame has unsupported operator";
              end if;
              values.append
                (Exact_Static_Integer_Value'
                   (semantic_type => result_type,
                    value         => result_value));
            end;

          when Apply_Static_Exponentiating =>
            if Natural (values.length) < 2 then
              raise Program_Error with
                "Adac.Sema: exact exponentiating frame lost values";
            end if;
            declare
              exponent : constant Exact_Static_Integer_Value :=
                values.last_element;
              base : Exact_Static_Integer_Value;
              result_type : Adac.Types.Type_ID;
            begin
              values.delete_last;
              base := values.last_element;
              values.delete_last;

              if not exact_exponent_is_in_natural_range (context, exponent) then
                return
                  invalid_universal_integer_static_result
                    (Universal_Integer_Static_Invalid);
              end if;

              result_type := resolve_exact_unary_operator_type
                (context, frame.expected_type, base.semantic_type);
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return
                  invalid_universal_integer_static_result
                    (Universal_Integer_Static_Unsupported);
              end if;

              values.append
                (Exact_Static_Integer_Value'
                   (semantic_type => result_type,
                    value         => Adac.Types.universal_integer_power
                      (base.value, exponent.value, limit)));
            end;

          when Apply_Static_Adding =>
            if Natural (values.length) < 2 then
              raise Program_Error with
                "Adac.Sema: exact adding frame lost operand values";
            end if;
            declare
              right : constant Exact_Static_Integer_Value :=
                values.last_element;
              left : Exact_Static_Integer_Value;
              result_type : Adac.Types.Type_ID;
              result_value : Adac.Types.Universal_Integer_Value :=
                Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.binary_adding_operator_spelling
                  (context, frame.node);
            begin
              values.delete_last;
              left := values.last_element;
              values.delete_last;
              result_type := resolve_exact_homogeneous_binary_operator_type
                (context,
                 frame.expected_type,
                 left.semantic_type,
                 right.semantic_type);
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return
                  invalid_universal_integer_static_result
                    (Universal_Integer_Static_Unsupported);
              end if;
              if operator_spelling = "+" then
                result_value := Adac.Types.universal_integer_add
                  (left.value, right.value, limit);
              elsif operator_spelling = "-" then
                result_value := Adac.Types.universal_integer_subtract
                  (left.value, right.value, limit);
              else
                raise Program_Error with
                  "Adac.Sema: exact adding frame has unsupported operator";
              end if;
              values.append
                (Exact_Static_Integer_Value'
                   (semantic_type => result_type,
                    value         => result_value));
            end;

          when Apply_Static_Multiplying =>
            if Natural (values.length) < 2 then
              raise Program_Error with
                "Adac.Sema: exact multiplying frame lost operand values";
            end if;
            declare
              right : constant Exact_Static_Integer_Value :=
                values.last_element;
              left : Exact_Static_Integer_Value;
              result_type : Adac.Types.Type_ID;
              result_value : Adac.Types.Universal_Integer_Value :=
                Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE;
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.binary_multiplying_operator_spelling
                  (context, frame.node);
            begin
              values.delete_last;
              left := values.last_element;
              values.delete_last;
              result_type := resolve_exact_homogeneous_binary_operator_type
                (context,
                 frame.expected_type,
                 left.semantic_type,
                 right.semantic_type);
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return
                  invalid_universal_integer_static_result
                    (Universal_Integer_Static_Unsupported);
              end if;

              if operator_spelling = "*" then
                result_value := Adac.Types.universal_integer_multiply
                  (left.value, right.value, limit);
              elsif operator_spelling = "/" then
                if Adac.Types.universal_integer_is_zero (right.value) then
                  return
                    invalid_universal_integer_static_result
                      (Universal_Integer_Static_Zero_Divisor);
                end if;
                result_value := Adac.Types.universal_integer_divide
                  (left.value, right.value, limit);
              elsif operator_spelling = "rem" then
                if Adac.Types.universal_integer_is_zero (right.value) then
                  return
                    invalid_universal_integer_static_result
                      (Universal_Integer_Static_Zero_Divisor);
                end if;
                result_value := Adac.Types.universal_integer_remainder
                  (left.value, right.value, limit);
              elsif operator_spelling = "mod" then
                if Adac.Types.universal_integer_is_zero (right.value) then
                  return
                    invalid_universal_integer_static_result
                      (Universal_Integer_Static_Zero_Divisor);
                end if;
                result_value := Adac.Types.universal_integer_modulus
                  (left.value, right.value, limit);
              else
                raise Program_Error with
                  "Adac.Sema: exact multiplying frame has unsupported " &
                  "operator";
              end if;
              values.append
                (Exact_Static_Integer_Value'
                   (semantic_type => result_type,
                    value         => result_value));
            end;
        end case;
      end;
    end loop;

    if Natural (values.length) /= 1 then
      raise Program_Error with
        "Adac.Sema: exact evaluation lost result value";
    end if;
    return
      (status        => Universal_Integer_Static_Valid,
       semantic_type => values.last_element.semantic_type,
       value         => values.last_element.value);
  exception
    when Adac.Resources.Limit_Exceeded =>
      return
        invalid_universal_integer_static_result
          (Universal_Integer_Static_Resource_Limit);
  end evaluate_static_universal_integer_expression;

  function evaluate_static_specific_integer_expression_exact
    (context       : Adac.Compilation.Context;
     local_scope   : Adac.Semantics.Lexical_Scope;
     expression    : Adac.AST.Node_ID;
     expected_type : Adac.Types.Type_ID)
  return Integer_Static_Result is
    evaluated : constant Universal_Integer_Static_Result :=
      evaluate_static_universal_integer_expression
        (context, local_scope, expression, expected_type);
    value : Long_Long_Integer;
  begin
    case evaluated.status is
      when Universal_Integer_Static_Unsupported =>
        return (status => Integer_Static_Unsupported, value => 0);

      when Universal_Integer_Static_Invalid =>
        return (status => Integer_Static_Invalid, value => 0);

      when Universal_Integer_Static_Zero_Divisor =>
        return (status => Integer_Static_Zero_Divisor, value => 0);

      when Universal_Integer_Static_Resource_Limit =>
        return (status => Integer_Static_Resource_Limit, value => 0);

      when Universal_Integer_Static_Valid =>
        if evaluated.semantic_type /= expected_type then
          raise Program_Error with
            "Adac.Sema: exact specific result lost expected type";
        end if;
        if Adac.Compilation.Types.kind_of (context, expected_type) /=
          Adac.Types.Signed_Integer_Type
        then
          raise Program_Error with
            "Adac.Sema: exact specific result is not signed integer";
        end if;
        if not Adac.Types.universal_integer_fits_long_long
          (evaluated.value)
        then
          return (status => Integer_Static_Out_Of_Range, value => 0);
        end if;

        value := Adac.Types.universal_integer_to_long_long (evaluated.value);
        if value < Adac.Compilation.Types.signed_integer_lower_bound
             (context, expected_type) or else
           value > Adac.Compilation.Types.signed_integer_upper_bound
             (context, expected_type)
        then
          return (status => Integer_Static_Out_Of_Range, value => 0);
        end if;
        return (status => Integer_Static_Valid, value => value);
    end case;
  end evaluate_static_specific_integer_expression_exact;

  function evaluate_static_universal_real_expression
    (context     : Adac.Compilation.Context;
     local_scope : Adac.Semantics.Lexical_Scope;
     expression  : Adac.AST.Node_ID)
  return Universal_Real_Static_Result is
    limit : constant
      Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit :=
        universal_real_component_decimal_digit_limit (context);
    frames : Exact_Static_Evaluation_Frame_Vectors.Vector;
    values : Exact_Static_Numeric_Value_Vectors.Vector;
  begin
    frames.append
      (Exact_Static_Evaluation_Frame'
         (action        => Visit_Static_Expression,
          node          => expression,
          expected_type => Adac.Types.INVALID_TYPE_ID));

    while not frames.is_empty loop
      declare
        frame : constant Exact_Static_Evaluation_Frame := frames.last_element;
      begin
        frames.delete_last;
        case frame.action is
          when Visit_Static_Expression =>
            case Adac.Compilation.Syntax.kind_of (context, frame.node) is
              when Adac.AST.Parenthesized_Expression_Node =>
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax
                        .parenthesized_expression_child
                          (context, frame.node),
                      expected_type => Adac.Types.INVALID_TYPE_ID));

              when Adac.AST.Unary_Operator_Node =>
                declare
                  operator_spelling : constant String :=
                    Adac.Compilation.Syntax.unary_operator_spelling
                      (context, frame.node);
                begin
                  if operator_spelling /= "+" and then
                     operator_spelling /= "-" and then
                     operator_spelling /= "abs"
                  then
                    return invalid_universal_real_static_result
                      (Universal_Real_Static_Unsupported);
                  end if;
                end;
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Unary,
                      node          => frame.node,
                      expected_type => Adac.Types.INVALID_TYPE_ID));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax.unary_operand
                        (context, frame.node),
                      expected_type => Adac.Types.INVALID_TYPE_ID));

              when Adac.AST.Binary_Adding_Node =>
                declare
                  operator_spelling : constant String :=
                    Adac.Compilation.Syntax.binary_adding_operator_spelling
                      (context, frame.node);
                begin
                  if operator_spelling /= "+" and then
                     operator_spelling /= "-"
                  then
                    return invalid_universal_real_static_result
                      (Universal_Real_Static_Unsupported);
                  end if;
                end;
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Adding,
                      node          => frame.node,
                      expected_type => Adac.Types.INVALID_TYPE_ID));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax
                        .binary_adding_right_operand (context, frame.node),
                      expected_type => Adac.Types.INVALID_TYPE_ID));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax
                        .binary_adding_left_operand (context, frame.node),
                      expected_type => Adac.Types.INVALID_TYPE_ID));

              when Adac.AST.Binary_Multiplying_Node =>
                declare
                  operator_spelling : constant String :=
                    Adac.Compilation.Syntax.binary_multiplying_operator_spelling
                      (context, frame.node);
                begin
                  if operator_spelling /= "*" and then
                     operator_spelling /= "/"
                  then
                    return invalid_universal_real_static_result
                      (Universal_Real_Static_Unsupported);
                  end if;
                end;
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Multiplying,
                      node          => frame.node,
                      expected_type => Adac.Types.INVALID_TYPE_ID));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax
                        .binary_multiplying_right_operand (context, frame.node),
                      expected_type => Adac.Types.INVALID_TYPE_ID));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax
                        .binary_multiplying_left_operand (context, frame.node),
                      expected_type => Adac.Types.INVALID_TYPE_ID));

              when Adac.AST.Binary_Exponentiating_Node =>
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Apply_Static_Exponentiating,
                      node          => frame.node,
                      expected_type => Adac.Types.INVALID_TYPE_ID));
                frames.append
                  (Exact_Static_Evaluation_Frame'
                     (action        => Visit_Static_Expression,
                      node          => Adac.Compilation.Syntax
                        .binary_exponentiating_left_operand
                          (context, frame.node),
                      expected_type => Adac.Types.INVALID_TYPE_ID));

              when others =>
                declare
                  atom : constant Universal_Real_Static_Result :=
                    evaluate_static_universal_real_atom
                      (context, local_scope, frame.node);
                begin
                  if atom.status /= Universal_Real_Static_Valid then
                    return atom;
                  end if;
                  values.append
                    (Exact_Static_Numeric_Value'
                       (semantic_type => atom.semantic_type,
                        integer_value => atom.integer_value,
                        real_value    => atom.value));
                end;
            end case;

          when Apply_Static_Unary =>
            if values.is_empty then
              raise Program_Error with
                "Adac.Sema: exact real unary frame lost operand value";
            end if;
            declare
              operand : constant Exact_Static_Numeric_Value :=
                values.last_element;
              result_type : constant Adac.Types.Type_ID :=
                Adac.Compilation.Types
                  .resolve_predefined_unary_real_operator_type
                    (context, operand.semantic_type);
              result_value : Adac.Types.Universal_Real_Value :=
                operand.real_value;
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.unary_operator_spelling
                  (context, frame.node);
            begin
              values.delete_last;
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return invalid_universal_real_static_result
                  (Universal_Real_Static_Unsupported);
              elsif operator_spelling = "+" then
                result_value := operand.real_value;
              elsif operator_spelling = "-" then
                result_value := Adac.Types.universal_real_negate
                  (operand.real_value, limit);
              elsif operator_spelling = "abs" then
                result_value := absolute_universal_real_value
                  (operand.real_value, limit);
              else
                raise Program_Error with
                  "Adac.Sema: exact real unary frame has unsupported operator";
              end if;
              values.append
                (Exact_Static_Numeric_Value'
                   (semantic_type => result_type,
                    integer_value => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
                    real_value    => result_value));
            end;

          when Apply_Static_Adding =>
            if Natural (values.length) < 2 then
              raise Program_Error with
                "Adac.Sema: exact real adding frame lost operand values";
            end if;
            declare
              right : constant Exact_Static_Numeric_Value :=
                values.last_element;
              left : Exact_Static_Numeric_Value;
              result_type : Adac.Types.Type_ID;
              result_value : Adac.Types.Universal_Real_Value;
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.binary_adding_operator_spelling
                  (context, frame.node);
            begin
              values.delete_last;
              left := values.last_element;
              values.delete_last;
              result_type := Adac.Compilation.Types
                .resolve_predefined_homogeneous_binary_real_operator_type
                  (context, left.semantic_type, right.semantic_type);
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return invalid_universal_real_static_result
                  (Universal_Real_Static_Unsupported);
              elsif operator_spelling = "+" then
                result_value := Adac.Types.universal_real_add
                  (left.real_value, right.real_value, limit);
              elsif operator_spelling = "-" then
                result_value := Adac.Types.universal_real_subtract
                  (left.real_value, right.real_value, limit);
              else
                raise Program_Error with
                  "Adac.Sema: exact real adding frame has unsupported operator";
              end if;
              values.append
                (Exact_Static_Numeric_Value'
                   (semantic_type => result_type,
                    integer_value => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
                    real_value    => result_value));
            end;

          when Apply_Static_Multiplying =>
            if Natural (values.length) < 2 then
              raise Program_Error with
                "Adac.Sema: exact real multiplying frame lost operand values";
            end if;
            declare
              right : constant Exact_Static_Numeric_Value :=
                values.last_element;
              left : Exact_Static_Numeric_Value;
              result_type : Adac.Types.Type_ID;
              result_value : Adac.Types.Universal_Real_Value;
              operator_spelling : constant String :=
                Adac.Compilation.Syntax.binary_multiplying_operator_spelling
                  (context, frame.node);
            begin
              values.delete_last;
              left := values.last_element;
              values.delete_last;
              result_type := resolve_exact_real_multiplying_operator_type
                (context,
                 operator_spelling,
                 left.semantic_type,
                 right.semantic_type);
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return invalid_universal_real_static_result
                  (Universal_Real_Static_Unsupported);
              elsif operator_spelling = "*" then
                result_value := Adac.Types.universal_real_multiply
                  (exact_numeric_as_real (context, left, limit),
                   exact_numeric_as_real (context, right, limit),
                   limit);
              elsif operator_spelling = "/" then
                result_value := exact_numeric_as_real (context, right, limit);
                if Adac.Types.universal_real_is_zero (result_value) then
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Zero_Divisor);
                end if;
                result_value := Adac.Types.universal_real_divide
                  (exact_numeric_as_real (context, left, limit),
                   result_value,
                   limit);
              else
                raise Program_Error with
                  "Adac.Sema: exact real multiplying frame has unsupported " &
                  "operator";
              end if;
              values.append
                (Exact_Static_Numeric_Value'
                   (semantic_type => result_type,
                    integer_value => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
                    real_value    => result_value));
            end;

          when Apply_Static_Exponentiating =>
            if values.is_empty then
              raise Program_Error with
                "Adac.Sema: exact real exponent frame lost base value";
            end if;
            declare
              base : constant Exact_Static_Numeric_Value :=
                values.last_element;
              exponent : Integer_Static_Result;
              result_type : Adac.Types.Type_ID;
              base_value : Adac.Types.Universal_Real_Value;
              exponent_value : Adac.Types.Universal_Integer_Value;
              result_value : Adac.Types.Universal_Real_Value;
            begin
              values.delete_last;
              result_type := Adac.Compilation.Types
                .resolve_predefined_real_exponentiating_operator_type
                  (context,
                   base.semantic_type,
                   Adac.Compilation.Types.standard_integer (context));
              if result_type = Adac.Types.INVALID_TYPE_ID then
                return invalid_universal_real_static_result
                  (Universal_Real_Static_Unsupported);
              end if;

              exponent := evaluate_static_specific_integer_expression_exact
                (context,
                 local_scope,
                 Adac.Compilation.Syntax
                   .binary_exponentiating_right_operand
                     (context, frame.node),
                 Adac.Compilation.Types.standard_integer (context));
              case exponent.status is
                when Integer_Static_Unsupported =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Unsupported);

                when Integer_Static_Invalid | Integer_Static_Out_Of_Range =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Invalid);

                when Integer_Static_Zero_Divisor =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Zero_Divisor);

                when Integer_Static_Resource_Limit =>
                  return invalid_universal_real_static_result
                    (Universal_Real_Static_Resource_Limit);

                when Integer_Static_Valid =>
                  null;
              end case;

              base_value := exact_numeric_as_real (context, base, limit);
              exponent_value := Adac.Types.make_universal_integer_value
                (exponent.value);
              if Adac.Types.universal_real_is_zero (base_value) and then
                 Adac.Types.universal_integer_is_negative (exponent_value)
              then
                return invalid_universal_real_static_result
                  (Universal_Real_Static_Invalid);
              end if;

              result_value := Adac.Types.universal_real_power
                (base_value, exponent_value, limit);
              values.append
                (Exact_Static_Numeric_Value'
                   (semantic_type => result_type,
                    integer_value => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
                    real_value    => result_value));
            end;
        end case;
      end;
    end loop;

    if Natural (values.length) /= 1 then
      raise Program_Error with
        "Adac.Sema: exact real evaluation lost result value";
    end if;
    case Adac.Compilation.Types.kind_of
      (context, values.last_element.semantic_type)
    is
      when Adac.Types.Universal_Real_Type | Adac.Types.Root_Real_Type =>
        return
          (status        => Universal_Real_Static_Valid,
           semantic_type => values.last_element.semantic_type,
           integer_value => Adac.Types.INVALID_UNIVERSAL_INTEGER_VALUE,
           value         => values.last_element.real_value);

      when Adac.Types.Signed_Integer_Type |
           Adac.Types.Universal_Integer_Type |
           Adac.Types.Root_Integer_Type |
           Adac.Types.Boolean_Type =>
        return invalid_universal_real_static_result
          (Universal_Real_Static_Unsupported);
    end case;
  exception
    when Adac.Resources.Limit_Exceeded =>
      return invalid_universal_real_static_result
        (Universal_Real_Static_Resource_Limit);
  end evaluate_static_universal_real_expression;

  function resolve_direct_object_subtype
    (context     : Adac.Compilation.Context;
     local_scope : Adac.Semantics.Lexical_Scope;
     declaration : Adac.AST.Node_ID)
  return Adac.Types.Type_ID is
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.object_subtype_mark (context, declaration);
    integer_type : constant Adac.Types.Type_ID :=
      resolve_supported_subtype_mark (context, local_scope, subtype_mark);
  begin
    if integer_type /= Adac.Types.INVALID_TYPE_ID then
      return integer_type;
    end if;
    return resolve_supported_boolean_subtype_mark
      (context, local_scope, subtype_mark);
  end resolve_direct_object_subtype;

  procedure report_unsupported_declaration
    (context     : in out Adac.Compilation.Context;
     declaration : Adac.AST.Node_ID;
     message     : String)
  is
  begin
    Adac.Compilation.Diagnostics.error
      (context,
       Adac.Source.first_position
         (Adac.Compilation.Syntax.node_span (context, declaration)),
       message);
  end report_unsupported_declaration;

  function analyze
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Analysis_Result is
  begin
    Adac.Compilation.Syntax.validate (context, root);

    if Adac.Compilation.Syntax.context_item_count (context, root) /= 0 then
      declare
        first_item : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.context_item_at (context, root, 1);
      begin
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, first_item)),
           "context clauses are not semantically supported");
        return (status => Analysis_Rejected);
      end;
    end if;

    declare
      library_item : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.unit_item (context, root);
      local_objects : Local_Object_Vectors.Vector;
      local_scope   : Adac.Semantics.Lexical_Scope;
      checked_statements : Adac.Semantics.Procedure_Statement_List;
    begin
      if Adac.Compilation.Syntax.kind_of (context, library_item) =
        Adac.AST.Subunit_Node
      then
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, library_item)),
           "subunits are not semantically supported");
        return (status => Analysis_Rejected);
      end if;

      if Adac.Compilation.Syntax.kind_of (context, library_item) =
        Adac.AST.Package_Renaming_Declaration_Node
      then
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, library_item)),
           "package renamings are not semantically supported");
        return (status => Analysis_Rejected);
      end if;

      if Adac.Compilation.Syntax.kind_of (context, library_item) =
        Adac.AST.Package_Instantiation_Node
      then
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, library_item)),
           "package instantiations are not semantically supported");
        return (status => Analysis_Rejected);
      end if;

      if Adac.Compilation.Syntax.kind_of (context, library_item) =
        Adac.AST.Package_Declaration_Node
      then
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, library_item)),
           "package declarations are not semantically supported");
        return (status => Analysis_Rejected);
      end if;

      if Adac.Compilation.Syntax.kind_of (context, library_item) =
        Adac.AST.Package_Body_Node
      then
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, library_item)),
           "package bodies are not semantically supported");
        return (status => Analysis_Rejected);
      end if;

      if Adac.Compilation.Syntax.has_end_designator
           (context, library_item) and then
         Adac.Compilation.Syntax.procedure_symbol (context, library_item) /=
           Adac.Compilation.Syntax.end_symbol (context, library_item)
      then
        Adac.Compilation.Diagnostics.error
          (context, "procedure name and end name do not match");
        return (status => Analysis_Rejected);
      end if;

      for index in 1 .. Adac.Compilation.Syntax.declaration_count
        (context, library_item)
      loop
        declare
          declaration : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.declaration_at
              (context, library_item, index);
        begin
          case Adac.Compilation.Syntax.kind_of (context, declaration) is
            when Adac.AST.Number_Declaration_Node =>
              declare
                initializer : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.number_initializer
                    (context, declaration);
                number_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Syntax.number_symbol
                    (context, declaration);
                inserted : Boolean;
              begin
                declare
                  real_evaluated : constant Universal_Real_Static_Result :=
                    evaluate_static_universal_real_expression
                      (context, local_scope, initializer);
                begin
                  case real_evaluated.status is
                    when Universal_Real_Static_Valid =>
                      if real_evaluated.semantic_type =
                        Adac.Types.INVALID_TYPE_ID
                      then
                        raise Program_Error with
                          "Adac.Sema: named number evaluation lost real type";
                      end if;
                      Adac.Compilation.Types.validate
                        (context, real_evaluated.semantic_type);
                      case Adac.Compilation.Types.kind_of
                        (context, real_evaluated.semantic_type)
                      is
                        when Adac.Types.Universal_Real_Type |
                             Adac.Types.Root_Real_Type =>
                          null;

                        when others =>
                          raise Program_Error with
                            "Adac.Sema: real evaluation produced non-real type";
                      end case;
                      Adac.Compilation.Semantics.try_bind_local_real_number
                        (context,
                         local_scope,
                         number_symbol,
                         declaration,
                         Adac.Compilation.Types.universal_real (context),
                         real_evaluated.value,
                         inserted);

                    when Universal_Real_Static_Invalid =>
                      report_unsupported_declaration
                        (context,
                         declaration,
                         (if is_direct_real_literal (context, initializer) then
                            "invalid real literal in local number declaration"
                          else
                            "invalid real expression in local number " &
                            "declaration"));
                      return (status => Analysis_Rejected);

                    when Universal_Real_Static_Zero_Divisor =>
                      report_unsupported_declaration
                        (context,
                         declaration,
                         "zero divisor in local number declaration");
                      return (status => Analysis_Rejected);

                    when Universal_Real_Static_Resource_Limit =>
                      report_unsupported_declaration
                        (context,
                         declaration,
                         "universal real resource limit exceeded in local " &
                         "number declaration");
                      return (status => Analysis_Rejected);

                    when Universal_Real_Static_Unsupported =>
                      declare
                        evaluated : constant Universal_Integer_Static_Result :=
                          evaluate_static_universal_integer_expression
                            (context, local_scope, initializer);
                        universal_type : constant Adac.Types.Type_ID :=
                          Adac.Compilation.Types.universal_integer (context);
                      begin
                        case evaluated.status is
                          when Universal_Integer_Static_Unsupported =>
                            report_unsupported_declaration
                              (context,
                               declaration,
                               "local number declaration is not a supported " &
                               "static numeric expression");
                            return (status => Analysis_Rejected);

                          when Universal_Integer_Static_Invalid =>
                            report_unsupported_declaration
                              (context,
                               declaration,
                               "invalid integer expression in local number " &
                               "declaration");
                            return (status => Analysis_Rejected);

                          when Universal_Integer_Static_Zero_Divisor =>
                            report_unsupported_declaration
                              (context,
                               declaration,
                               "zero divisor in local number declaration");
                            return (status => Analysis_Rejected);

                          when Universal_Integer_Static_Resource_Limit =>
                            report_unsupported_declaration
                              (context,
                               declaration,
                               "universal integer resource limit exceeded in " &
                               "local number declaration");
                            return (status => Analysis_Rejected);

                          when Universal_Integer_Static_Valid =>
                            if evaluated.semantic_type =
                              Adac.Types.INVALID_TYPE_ID
                            then
                              raise Program_Error with
                                "Adac.Sema: named number evaluation lost " &
                                "integer type";
                            end if;
                            Adac.Compilation.Types.validate
                              (context, evaluated.semantic_type);
                            Adac.Compilation.Semantics
                              .try_bind_local_integer_number
                              (context,
                               local_scope,
                               number_symbol,
                               declaration,
                               universal_type,
                               evaluated.value,
                               inserted);
                        end case;
                      end;
                  end case;
                end;

                if not inserted then
                  report_unsupported_declaration
                    (context, declaration, "duplicate local declaration");
                  return (status => Analysis_Rejected);
                end if;
              end;

            when Adac.AST.Subtype_Declaration_Node =>
              declare
                subtype_mark : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.subtype_declaration_subtype_mark
                    (context, declaration);
                semantic_type : constant Adac.Types.Type_ID :=
                  resolve_supported_subtype_mark
                    (context, local_scope, subtype_mark);
                subtype_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Syntax.subtype_declaration_symbol
                    (context, declaration);
                constraint : Adac.Semantics.Subtype_Constraint :=
                  resolve_supported_subtype_constraint
                    (context, local_scope, subtype_mark);
                inserted : Boolean;
              begin
                if semantic_type = Adac.Types.INVALID_TYPE_ID then
                  report_unsupported_declaration
                    (context,
                     declaration,
                     "local subtype mark is not semantically supported");
                  return (status => Analysis_Rejected);
                end if;

                if Adac.Compilation.Syntax.subtype_declaration_has_constraint
                  (context, declaration)
                then
                  declare
                    range_constraint : constant Adac.AST.Node_ID :=
                      Adac.Compilation.Syntax.subtype_declaration_constraint
                        (context, declaration);
                    lower_bound : constant Adac.AST.Node_ID :=
                      Adac.Compilation.Syntax.range_constraint_lower_bound
                        (context, range_constraint);
                    upper_bound : constant Adac.AST.Node_ID :=
                      Adac.Compilation.Syntax.range_constraint_upper_bound
                        (context, range_constraint);
                  begin
                    declare
                      lower : constant Integer_Static_Result :=
                        evaluate_static_specific_integer_expression_exact
                          (context, local_scope, lower_bound, semantic_type);
                      upper : constant Integer_Static_Result :=
                        evaluate_static_specific_integer_expression_exact
                          (context, local_scope, upper_bound, semantic_type);
                    begin
                      if lower.status = Integer_Static_Unsupported or else
                         upper.status = Integer_Static_Unsupported
                      then
                        report_unsupported_declaration
                          (context,
                           declaration,
                           "local subtype range bounds are not supported " &
                           "static integer expressions");
                        return (status => Analysis_Rejected);
                      end if;

                      if lower.status = Integer_Static_Invalid or else
                         upper.status = Integer_Static_Invalid
                      then
                        report_unsupported_declaration
                          (context,
                           declaration,
                           "invalid integer expression in local subtype range");
                        return (status => Analysis_Rejected);
                      end if;

                      if lower.status = Integer_Static_Zero_Divisor or else
                         upper.status = Integer_Static_Zero_Divisor
                      then
                        report_unsupported_declaration
                          (context,
                           declaration,
                           "zero divisor in local subtype range");
                        return (status => Analysis_Rejected);
                      end if;

                      if lower.status = Integer_Static_Out_Of_Range or else
                         upper.status = Integer_Static_Out_Of_Range
                      then
                        report_unsupported_declaration
                          (context,
                           declaration,
                           "local subtype range bound is outside base " &
                           "type range");
                        return (status => Analysis_Rejected);
                      end if;

                      if lower.status = Integer_Static_Resource_Limit or else
                         upper.status = Integer_Static_Resource_Limit
                      then
                        report_unsupported_declaration
                          (context,
                           declaration,
                           "universal integer resource limit exceeded in " &
                           "local subtype range");
                        return (status => Analysis_Rejected);
                      end if;

                      if not Adac.Semantics.subtype_constraint_contains
                        (constraint, lower.value) or else
                         not Adac.Semantics.subtype_constraint_contains
                           (constraint, upper.value)
                      then
                        report_unsupported_declaration
                          (context,
                           declaration,
                           "local subtype range is outside parent " &
                           "subtype range");
                        return (status => Analysis_Rejected);
                      end if;

                      constraint :=
                        Adac.Semantics.make_signed_integer_range_constraint
                          (lower.value, upper.value);
                    end;
                  end;
                end if;

                Adac.Compilation.Semantics.try_bind_local_subtype
                  (context,
                   local_scope,
                   subtype_symbol,
                   declaration,
                   semantic_type,
                   constraint,
                   inserted);
                if not inserted then
                  report_unsupported_declaration
                    (context, declaration, "duplicate local declaration");
                  return (status => Analysis_Rejected);
                end if;
              end;

            when Adac.AST.Object_Declaration_Node =>
          declare
            object_form : constant Adac.AST.Object_Declaration_Form :=
              Adac.Compilation.Syntax.object_form (context, declaration);
            semantic_type : constant Adac.Types.Type_ID :=
              resolve_direct_object_subtype
                (context, local_scope, declaration);
            is_boolean_object : constant Boolean :=
              semantic_type /= Adac.Types.INVALID_TYPE_ID and then
              Adac.Compilation.Types.kind_of (context, semantic_type) =
                Adac.Types.Boolean_Type;
            is_boolean_constant : constant Boolean :=
              is_boolean_object and then
              object_form = Adac.AST.Constant_Object_Form;
            constraint : constant Adac.Semantics.Subtype_Constraint :=
              (if is_boolean_object then
                 Adac.Semantics.NO_SUBTYPE_CONSTRAINT
               else
                 resolve_supported_subtype_constraint
                   (context,
                    local_scope,
                    Adac.Compilation.Syntax.object_subtype_mark
                      (context, declaration)));
            has_initializer : constant Boolean :=
              Adac.Compilation.Syntax.object_has_initializer
                (context, declaration);
            integer_initializer : Long_Long_Integer := 0;
            boolean_initializer : Adac.Types.Boolean_Value :=
              Adac.Types.False_Boolean_Value;
          begin
            if semantic_type = Adac.Types.INVALID_TYPE_ID then
              report_unsupported_declaration
                (context,
                 declaration,
                 "local object subtype is not semantically supported");
              return (status => Analysis_Rejected);
            end if;

            if object_form = Adac.AST.Constant_Object_Form and then
               not has_initializer
            then
              report_unsupported_declaration
                (context,
                 declaration,
                 "deferred local constants are not semantically supported");
              return (status => Analysis_Rejected);
            end if;

            if has_initializer then
              declare
                initializer : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.object_initializer
                    (context, declaration);
              begin
                if is_boolean_object then
                  declare
                    evaluated : constant Boolean_Static_Result :=
                      evaluate_static_boolean_expression
                        (context, local_scope, initializer, semantic_type);
                  begin
                    if evaluated.status /= Boolean_Static_Valid then
                      report_unsupported_declaration
                        (context,
                         declaration,
                         (if is_boolean_constant then
                            "local Boolean constant initializer is not " &
                            "semantically supported"
                          else
                            "local Boolean object initializer is not " &
                            "semantically supported"));
                      return (status => Analysis_Rejected);
                    end if;
                    if evaluated.semantic_type /= semantic_type then
                      raise Program_Error with
                        "Adac.Sema: Boolean static atom type mismatch";
                    end if;
                    boolean_initializer := evaluated.value;
                  end;
                else
                  declare
                    direct_integer_literal : constant Boolean :=
                      is_direct_integer_literal (context, initializer);
                  begin
                    if is_direct_real_literal (context, initializer) then
                      report_unsupported_declaration
                        (context,
                         declaration,
                         "local object initializer type does not match object");
                      return (status => Analysis_Rejected);
                    end if;

                    declare
                      evaluated : constant Integer_Static_Result :=
                        evaluate_static_specific_integer_expression_exact
                          (context, local_scope, initializer, semantic_type);
                    begin
                      case evaluated.status is
                        when Integer_Static_Unsupported =>
                          report_unsupported_declaration
                            (context,
                             declaration,
                             "local object initializer is not semantically " &
                             "supported");
                          return (status => Analysis_Rejected);

                        when Integer_Static_Invalid =>
                          report_unsupported_declaration
                            (context,
                             declaration,
                             (if direct_integer_literal then
                                "invalid integer literal in object initializer"
                              else
                                "invalid integer expression in object " &
                                "initializer"));
                          return (status => Analysis_Rejected);

                        when Integer_Static_Zero_Divisor =>
                          report_unsupported_declaration
                            (context,
                             declaration,
                             "zero divisor in local object initializer");
                          return (status => Analysis_Rejected);

                        when Integer_Static_Out_Of_Range =>
                          report_unsupported_declaration
                            (context,
                             declaration,
                             (if direct_integer_literal then
                                "integer literal is outside object type range"
                              else
                                "integer expression is outside object type " &
                                "range"));
                          return (status => Analysis_Rejected);

                        when Integer_Static_Resource_Limit =>
                          report_unsupported_declaration
                            (context,
                             declaration,
                             "universal integer resource limit exceeded in " &
                             "local object initializer");
                          return (status => Analysis_Rejected);

                        when Integer_Static_Valid =>
                          if not Adac.Semantics.subtype_constraint_contains
                            (constraint, evaluated.value)
                          then
                            report_unsupported_declaration
                              (context,
                               declaration,
                               (if direct_integer_literal then
                                  "integer literal is outside object subtype " &
                                  "range"
                                else
                                  "integer expression is outside object " &
                                  "subtype range"));
                            return (status => Analysis_Rejected);
                          end if;
                          integer_initializer := evaluated.value;
                      end case;
                    end;
                  end;
                end if;
              end;
            end if;

            declare
              object_symbol : constant Adac.Symbols.Symbol_ID :=
                Adac.Compilation.Syntax.object_symbol (context, declaration);
              inserted : Boolean;
            begin
              case object_form is
                when Adac.AST.Variable_Object_Form =>
                  Adac.Compilation.Semantics.try_bind_local_object
                    (context,
                     local_scope,
                     object_symbol,
                     Positive (Natural (local_objects.length) + 1),
                     inserted);

                when Adac.AST.Constant_Object_Form =>
                  if is_boolean_constant then
                    Adac.Compilation.Semantics
                      .try_bind_local_static_boolean_constant
                        (context,
                         local_scope,
                         object_symbol,
                         declaration,
                         semantic_type,
                         boolean_initializer,
                         inserted);
                  else
                    Adac.Compilation.Semantics
                      .try_bind_local_static_integer_constant
                        (context,
                         local_scope,
                         object_symbol,
                         declaration,
                         semantic_type,
                         constraint,
                         integer_initializer,
                         inserted);
                  end if;
              end case;

              if not inserted then
                report_unsupported_declaration
                  (context, declaration, "duplicate local declaration");
                return (status => Analysis_Rejected);
              end if;
            end;

            if object_form = Adac.AST.Variable_Object_Form then
              local_objects.append
                (Local_Object_Descriptor'
                   (declaration             => declaration,
                    semantic_type           => semantic_type,
                    constraint              => constraint,
                    has_integer_initializer => has_initializer and then
                      not is_boolean_object,
                    integer_initializer     => integer_initializer,
                    has_boolean_initializer => has_initializer and then
                      is_boolean_object,
                    boolean_initializer     => boolean_initializer,
                    has_defined_value       => has_initializer and then
                      not is_boolean_object,
                    defined_integer_value   => integer_initializer,
                    definition_statement    => 0,
                    has_defined_boolean_value => has_initializer and then
                      is_boolean_object,
                    defined_boolean_value     => boolean_initializer,
                    boolean_definition_statement => 0));
            end if;
          end;

            when others =>
              report_unsupported_declaration
                (context,
                 declaration,
                 "procedure declarative item is not semantically supported");
              return (status => Analysis_Rejected);
          end case;
        end;
      end loop;

      for index in 1 .. Adac.Compilation.Syntax.statement_count
        (context, library_item)
      loop
        case Adac.Compilation.Syntax.kind_of
          (context,
           Adac.Compilation.Syntax.statement_at
             (context, library_item, index))
        is
          when Adac.AST.Null_Statement_Node =>
            Adac.Semantics.append_statement
              (checked_statements,
               Adac.Compilation.Syntax.statement_at
                 (context, library_item, index),
               Adac.Semantics.Null_Procedure_Statement);

          when Adac.AST.Return_Statement_Node =>
            declare
              statement : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.statement_at
                  (context, library_item, index);
            begin
              if Adac.Compilation.Syntax.return_has_expression
                (context, statement)
              then
                Adac.Compilation.Diagnostics.error
                  (context,
                   Adac.Source.first_position
                     (Adac.Compilation.Syntax.node_span (context, statement)),
                   "procedure return expressions are not supported");
                return (status => Analysis_Rejected);
              end if;
              Adac.Semantics.append_statement
                (checked_statements,
                 statement,
                 Adac.Semantics.Return_Procedure_Statement);
            end;

          when Adac.AST.Exit_Statement_Node =>
            declare
              statement : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.statement_at
                  (context, library_item, index);
            begin
              Adac.Compilation.Diagnostics.error
                (context,
                 Adac.Source.first_position
                   (Adac.Compilation.Syntax.node_span (context, statement)),
                 "exit statements are not semantically supported");
              return (status => Analysis_Rejected);
            end;

          when Adac.AST.Extended_Return_Statement_Node =>
            declare
              statement : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.statement_at
                  (context, library_item, index);
            begin
              Adac.Compilation.Diagnostics.error
                (context,
                 Adac.Source.first_position
                   (Adac.Compilation.Syntax.node_span (context, statement)),
                 "extended returns are not semantically supported");
              return (status => Analysis_Rejected);
            end;

          when Adac.AST.Raise_Statement_Node =>
            declare
              statement : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.statement_at
                  (context, library_item, index);
            begin
              Adac.Compilation.Diagnostics.error
                (context,
                 Adac.Source.first_position
                   (Adac.Compilation.Syntax.node_span (context, statement)),
                 "raise statements are not semantically supported");
              return (status => Analysis_Rejected);
            end;

          when Adac.AST.Compilation_Unit_Node |
               Adac.AST.Subunit_Node |
               Adac.AST.Procedure_Body_Node |
               Adac.AST.Function_Body_Node |
               Adac.AST.With_Clause_Node |
               Adac.AST.Use_Type_Clause_Node |
               Adac.AST.Use_Package_Clause_Node |
               Adac.AST.Case_Alternative_Node |
               Adac.AST.Case_Range_Choice_Node |
               Adac.AST.Case_Expression_Alternative_Node |
               Adac.AST.Raise_Expression_Node |
               Adac.AST.Others_Case_Choice_Node |
               Adac.AST.Elsif_Part_Node |
               Adac.AST.Others_Exception_Choice_Node |
               Adac.AST.Exception_Handler_Node |
               Adac.AST.Handled_Sequence_Node |
               Adac.AST.Allocator_Node |
               Adac.AST.Membership_Range_Choice_Node |
               Adac.AST.Aspect_Specification_Node |
               Adac.AST.Private_Type_Declaration_Node |
               Adac.AST.Derived_Type_Declaration_Node |
               Adac.AST.Range_Constraint_Node |
               Adac.AST.Index_Constraint_Node |
               Adac.AST.Subtype_Declaration_Node |
               Adac.AST.Enumeration_Type_Declaration_Node |
               Adac.AST.Discriminant_Specification_Node |
               Adac.AST.Record_Component_Declaration_Node |
               Adac.AST.Record_Variant_Node |
               Adac.AST.Record_Variant_Part_Node |
               Adac.AST.Record_Type_Declaration_Node |
               Adac.AST.Access_Object_Type_Declaration_Node |
               Adac.AST.Package_Renaming_Declaration_Node |
               Adac.AST.Package_Instantiation_Node |
               Adac.AST.Package_Declaration_Node |
               Adac.AST.Package_Body_Stub_Node |
               Adac.AST.Package_Body_Node =>
            raise Program_Error with
              "Adac.Sema: nonstatement syntax used as a statement";

          when Adac.AST.Assignment_Statement_Node =>
            declare
              statement : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.statement_at
                  (context, library_item, index);
              target : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.assignment_target (context, statement);
              expression : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.assignment_expression
                  (context, statement);
            begin
              if Adac.Compilation.Syntax.kind_of (context, target) /=
                Adac.AST.Identifier_Name_Node
              then
                report_unsupported_declaration
                  (context,
                   statement,
                   "assignment target is not semantically supported");
                return (status => Analysis_Rejected);
              end if;

              declare
                target_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Syntax.identifier_symbol (context, target);
                resolved_target : constant Natural :=
                  Adac.Compilation.Semantics.resolve_local_object
                    (context, local_scope, target_symbol);
              begin
                if resolved_target = 0 then
                  if Adac.Compilation.Semantics
                    .resolve_local_static_integer_constant_type
                      (context, local_scope, target_symbol) /=
                    Adac.Types.INVALID_TYPE_ID or else
                    Adac.Compilation.Semantics
                      .resolve_local_static_boolean_constant_type
                        (context, local_scope, target_symbol) /=
                      Adac.Types.INVALID_TYPE_ID
                  then
                    report_unsupported_declaration
                      (context,
                       statement,
                       "assignment target is a local constant");
                  elsif Adac.Compilation.Semantics
                    .resolve_local_integer_number_type
                      (context, local_scope, target_symbol) /=
                    Adac.Types.INVALID_TYPE_ID or else
                    Adac.Compilation.Semantics.resolve_local_real_number_type
                      (context, local_scope, target_symbol) /=
                    Adac.Types.INVALID_TYPE_ID
                  then
                    report_unsupported_declaration
                      (context,
                       statement,
                       "assignment target is a named number");
                  else
                    report_unsupported_declaration
                      (context,
                       statement,
                       "assignment target is not a declared local variable");
                  end if;
                  return (status => Analysis_Rejected);
                end if;

                declare
                  target_local : constant Positive :=
                    Positive (resolved_target);
                  expected_type : constant Adac.Types.Type_ID :=
                    local_objects (target_local).semantic_type;
                begin
                  if Adac.Compilation.Types.kind_of (context, expected_type) =
                    Adac.Types.Boolean_Type
                  then
                    declare
                      resolved_source : Natural := 0;
                      resolved_not_source : Natural := 0;
                      resolved_binary_left : Natural := 0;
                      resolved_binary_right : Natural := 0;
                      binary_operator :
                        Adac.Semantics.Boolean_Binary_Operator_Kind :=
                          Adac.Semantics.No_Boolean_Binary_Operator;
                      resolved_short_left : Natural := 0;
                      resolved_short_right : Natural := 0;
                      short_operator :
                        Adac.Semantics.Boolean_Short_Circuit_Operator_Kind :=
                          Adac.Semantics
                            .And_Then_Boolean_Short_Circuit_Operator;
                      has_short_operator : Boolean := False;
                    begin
                      if Adac.Compilation.Syntax.kind_of (context, expression) =
                        Adac.AST.Identifier_Name_Node
                      then
                        declare
                          source_symbol : constant Adac.Symbols.Symbol_ID :=
                            Adac.Compilation.Syntax.identifier_symbol
                              (context, expression);
                        begin
                          resolved_source :=
                            Adac.Compilation.Semantics.resolve_local_object
                              (context, local_scope, source_symbol);
                        end;
                      elsif Adac.Compilation.Syntax.kind_of
                        (context, expression) =
                        Adac.AST.Unary_Operator_Node and then
                        Adac.Compilation.Syntax.unary_operator_spelling
                          (context, expression) = "not"
                      then
                        declare
                          operand : constant Adac.AST.Node_ID :=
                            Adac.Compilation.Syntax.unary_operand
                              (context, expression);
                        begin
                          if Adac.Compilation.Syntax.kind_of
                            (context, operand) = Adac.AST.Identifier_Name_Node
                          then
                            resolved_not_source :=
                              Adac.Compilation.Semantics.resolve_local_object
                                (context,
                                 local_scope,
                                 Adac.Compilation.Syntax.identifier_symbol
                                   (context, operand));
                          end if;
                        end;
                      elsif Adac.Compilation.Syntax.kind_of
                        (context, expression) = Adac.AST.Logical_Expression_Node
                      then
                        declare
                          left_operand : constant Adac.AST.Node_ID :=
                            Adac.Compilation.Syntax.logical_left_operand
                              (context, expression);
                          right_operand : constant Adac.AST.Node_ID :=
                            Adac.Compilation.Syntax.logical_right_operand
                              (context, expression);
                        begin
                          if Adac.Compilation.Syntax.kind_of
                               (context, left_operand) =
                               Adac.AST.Identifier_Name_Node and then
                             Adac.Compilation.Syntax.kind_of
                               (context, right_operand) =
                               Adac.AST.Identifier_Name_Node
                          then
                            resolved_binary_left :=
                              Adac.Compilation.Semantics.resolve_local_object
                                (context,
                                 local_scope,
                                 Adac.Compilation.Syntax.identifier_symbol
                                   (context, left_operand));
                            resolved_binary_right :=
                              Adac.Compilation.Semantics.resolve_local_object
                                (context,
                                 local_scope,
                                 Adac.Compilation.Syntax.identifier_symbol
                                   (context, right_operand));
                            binary_operator := semantic_boolean_binary_operator
                              (Adac.Compilation.Syntax.logical_operator
                                 (context, expression));
                          end if;
                        end;
                      elsif Adac.Compilation.Syntax.kind_of
                        (context, expression) =
                        Adac.AST.Short_Circuit_Expression_Node
                      then
                        declare
                          left_operand : constant Adac.AST.Node_ID :=
                            Adac.Compilation.Syntax.short_circuit_left_operand
                              (context, expression);
                          right_operand : constant Adac.AST.Node_ID :=
                            Adac.Compilation.Syntax.short_circuit_right_operand
                              (context, expression);
                        begin
                          if Adac.Compilation.Syntax.kind_of
                               (context, left_operand) =
                               Adac.AST.Identifier_Name_Node and then
                             Adac.Compilation.Syntax.kind_of
                               (context, right_operand) =
                               Adac.AST.Identifier_Name_Node
                          then
                            resolved_short_left :=
                              Adac.Compilation.Semantics.resolve_local_object
                                (context,
                                 local_scope,
                                 Adac.Compilation.Syntax.identifier_symbol
                                   (context, left_operand));
                            resolved_short_right :=
                              Adac.Compilation.Semantics.resolve_local_object
                                (context,
                                 local_scope,
                                 Adac.Compilation.Syntax.identifier_symbol
                                   (context, right_operand));
                            short_operator :=
                              (case Adac.Compilation.Syntax
                                      .short_circuit_operator
                                        (context, expression) is
                                 when Adac.AST
                                        .And_Then_Short_Circuit_Operator =>
                                   Adac.Semantics
                                     .And_Then_Boolean_Short_Circuit_Operator,
                                 when Adac.AST
                                        .Or_Else_Short_Circuit_Operator =>
                                   Adac.Semantics
                                     .Or_Else_Boolean_Short_Circuit_Operator);
                            has_short_operator := True;
                          end if;
                        end;
                      elsif Adac.Compilation.Syntax.kind_of
                        (context, expression) = Adac.AST.Relation_Node
                      then
                        declare
                          operator_kind : constant
                            Adac.Semantics.Boolean_Binary_Operator_Kind :=
                              semantic_boolean_relation_operator
                                (Adac.Compilation.Syntax
                                   .relation_operator_spelling
                                     (context, expression));
                          left_operand : constant Adac.AST.Node_ID :=
                            Adac.Compilation.Syntax.relation_left_operand
                              (context, expression);
                          right_operand : constant Adac.AST.Node_ID :=
                            Adac.Compilation.Syntax.relation_right_operand
                              (context, expression);
                        begin
                          if operator_kind /=
                               Adac.Semantics.No_Boolean_Binary_Operator and
                             then
                             Adac.Compilation.Syntax.kind_of
                               (context, left_operand) =
                               Adac.AST.Identifier_Name_Node and then
                             Adac.Compilation.Syntax.kind_of
                               (context, right_operand) =
                               Adac.AST.Identifier_Name_Node
                          then
                            resolved_binary_left :=
                              Adac.Compilation.Semantics.resolve_local_object
                                (context,
                                 local_scope,
                                 Adac.Compilation.Syntax.identifier_symbol
                                   (context, left_operand));
                            resolved_binary_right :=
                              Adac.Compilation.Semantics.resolve_local_object
                                (context,
                                 local_scope,
                                 Adac.Compilation.Syntax.identifier_symbol
                                   (context, right_operand));
                            binary_operator := operator_kind;
                          end if;
                        end;
                      end if;

                      if resolved_source /= 0 then
                        declare
                          source_local : constant Positive :=
                            Positive (resolved_source);
                          source_descriptor : constant
                            Local_Object_Descriptor :=
                              local_objects (source_local);
                        begin
                          if source_descriptor.semantic_type /=
                            expected_type
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean assignment source type does not " &
                               "match target");
                            return (status => Analysis_Rejected);
                          end if;
                          if not
                            source_descriptor.has_defined_boolean_value
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean assignment source local read before " &
                               "a supported definition is not supported");
                            return (status => Analysis_Rejected);
                          end if;

                          Adac.Semantics.append_local_boolean_copy_assignment
                            (checked_statements,
                             statement,
                             target_local,
                             expected_type,
                             source_local,
                             source_descriptor.boolean_definition_statement,
                             source_descriptor.defined_boolean_value);
                          mark_boolean_local_defined
                            (local_objects,
                             target_local,
                             index,
                             source_descriptor.defined_boolean_value);
                        end;
                      elsif resolved_not_source /= 0 then
                        declare
                          source_local : constant Positive :=
                            Positive (resolved_not_source);
                          source_descriptor : constant
                            Local_Object_Descriptor :=
                              local_objects (source_local);
                          result_value : Adac.Types.Boolean_Value :=
                            Adac.Types.False_Boolean_Value;
                        begin
                          if source_descriptor.semantic_type /=
                            expected_type
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean not source type does not match target");
                            return (status => Analysis_Rejected);
                          end if;
                          if not
                            source_descriptor.has_defined_boolean_value
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean not source local read before a " &
                               "supported definition is not supported");
                            return (status => Analysis_Rejected);
                          end if;

                          result_value := boolean_not_value
                            (source_descriptor.defined_boolean_value);
                          Adac.Semantics.append_local_boolean_not_assignment
                            (checked_statements,
                             statement,
                             target_local,
                             expected_type,
                             source_local,
                             source_descriptor.boolean_definition_statement,
                             result_value);
                          mark_boolean_local_defined
                            (local_objects,
                             target_local,
                             index,
                             result_value);
                        end;
                      elsif binary_operator /=
                              Adac.Semantics.No_Boolean_Binary_Operator and then
                            resolved_binary_left /= 0 and then
                            resolved_binary_right /= 0
                      then
                        declare
                          left_local : constant Positive :=
                            Positive (resolved_binary_left);
                          right_local : constant Positive :=
                            Positive (resolved_binary_right);
                          left_descriptor : constant Local_Object_Descriptor :=
                            local_objects (left_local);
                          right_descriptor : constant Local_Object_Descriptor :=
                            local_objects (right_local);
                          result_value : Adac.Types.Boolean_Value :=
                            Adac.Types.False_Boolean_Value;
                        begin
                          if left_descriptor.semantic_type /=
                               expected_type or else
                             right_descriptor.semantic_type /= expected_type
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean binary source type does not match " &
                               "target");
                            return (status => Analysis_Rejected);
                          end if;
                          if not
                               left_descriptor.has_defined_boolean_value or else
                             not right_descriptor.has_defined_boolean_value
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean binary source local read before a " &
                               "supported definition is not supported");
                            return (status => Analysis_Rejected);
                          end if;

                          result_value := boolean_binary_value
                            (binary_operator,
                             left_descriptor.defined_boolean_value,
                             right_descriptor.defined_boolean_value);
                          Adac.Semantics.append_local_boolean_binary_assignment
                            (checked_statements,
                             statement,
                             target_local,
                             expected_type,
                             binary_operator,
                             left_local,
                             left_descriptor.boolean_definition_statement,
                             right_local,
                             right_descriptor.boolean_definition_statement,
                             result_value);
                          mark_boolean_local_defined
                            (local_objects,
                             target_local,
                             index,
                             result_value);
                        end;
                      elsif has_short_operator and then
                            resolved_short_left /= 0 and then
                            resolved_short_right /= 0
                      then
                        declare
                          left_local : constant Positive :=
                            Positive (resolved_short_left);
                          right_local : constant Positive :=
                            Positive (resolved_short_right);
                          left_descriptor : constant Local_Object_Descriptor :=
                            local_objects (left_local);
                          right_descriptor : constant Local_Object_Descriptor :=
                            local_objects (right_local);
                          eager_operator : constant
                            Adac.Semantics.Boolean_Binary_Operator_Kind :=
                              (case short_operator is
                                 when Adac.Semantics
                                        .And_Then_Boolean_Short_Circuit_Operator =>
                                   Adac.Semantics.And_Boolean_Binary_Operator,
                                 when Adac.Semantics
                                        .Or_Else_Boolean_Short_Circuit_Operator =>
                                   Adac.Semantics.Or_Boolean_Binary_Operator);
                          result_value : Adac.Types.Boolean_Value :=
                            Adac.Types.False_Boolean_Value;
                        begin
                          if left_descriptor.semantic_type /= expected_type or else
                             right_descriptor.semantic_type /= expected_type
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean short-circuit source type does not " &
                               "match target");
                            return (status => Analysis_Rejected);
                          end if;
                          if not left_descriptor.has_defined_boolean_value or else
                             not right_descriptor.has_defined_boolean_value
                          then
                            report_unsupported_declaration
                              (context,
                               statement,
                               "Boolean short-circuit source local read before " &
                               "a supported definition is not supported");
                            return (status => Analysis_Rejected);
                          end if;

                          result_value := boolean_binary_value
                            (eager_operator,
                             left_descriptor.defined_boolean_value,
                             right_descriptor.defined_boolean_value);
                          Adac.Semantics
                            .append_local_boolean_short_circuit_assignment
                              (checked_statements,
                               statement,
                               target_local,
                               expected_type,
                               short_operator,
                               left_local,
                               left_descriptor.boolean_definition_statement,
                               right_local,
                               right_descriptor.boolean_definition_statement,
                               result_value);
                          mark_boolean_local_defined
                            (local_objects,
                             target_local,
                             index,
                             result_value);
                        end;
                      else
                        declare
                          evaluated : constant Boolean_Static_Result :=
                            evaluate_static_boolean_expression
                              (context,
                               local_scope,
                               expression,
                               expected_type);
                        begin
                          if evaluated.status = Boolean_Static_Valid then
                            if evaluated.semantic_type /= expected_type then
                              raise Program_Error with
                                "Adac.Sema: Boolean assignment evaluator lost " &
                                "type";
                            end if;
                            Adac.Semantics
                              .append_local_boolean_static_assignment
                                (checked_statements,
                                 statement,
                                 target_local,
                                 expected_type,
                                 evaluated.value);
                            mark_boolean_local_defined
                              (local_objects,
                               target_local,
                               index,
                               evaluated.value);
                          else
                            declare
                              runtime_values :
                                Adac.Semantics.Boolean_Expression_Value_List;
                              runtime_status : Boolean_Runtime_Status;
                            begin
                              evaluate_runtime_boolean_expression
                                (context,
                                 local_scope,
                                 local_objects,
                                 expression,
                                 expected_type,
                                 runtime_values,
                                 runtime_status);
                              case runtime_status is
                                when Boolean_Runtime_Valid =>
                                  declare
                                    result_value : constant
                                      Adac.Types.Boolean_Value :=
                                        Adac.Semantics
                                          .boolean_expression_root_value
                                            (runtime_values);
                                  begin
                                    Adac.Semantics
                                      .append_local_boolean_expression_assignment
                                        (checked_statements,
                                         statement,
                                         target_local,
                                         expected_type,
                                         runtime_values);
                                    mark_boolean_local_defined
                                      (local_objects,
                                       target_local,
                                       index,
                                       result_value);
                                  end;

                                when Boolean_Runtime_Type_Mismatch =>
                                  report_unsupported_declaration
                                    (context,
                                     statement,
                                     "Boolean expression source type does not " &
                                     "match target");
                                  return (status => Analysis_Rejected);

                                when Boolean_Runtime_Uninitialized =>
                                  report_unsupported_declaration
                                    (context,
                                     statement,
                                     "Boolean expression source local read " &
                                     "before a supported definition is not " &
                                     "supported");
                                  return (status => Analysis_Rejected);

                                when Boolean_Runtime_Unsupported =>
                                  report_unsupported_declaration
                                    (context,
                                     statement,
                                     "Boolean assignment expression is not " &
                                     "semantically supported");
                                  return (status => Analysis_Rejected);
                              end case;
                            end;
                          end if;
                        end;
                      end if;
                    end;
                  else
                    case Adac.Compilation.Syntax.kind_of
                    (context, expression)
                  is
                    when Adac.AST.Numeric_Literal_Node |
                         Adac.AST.Parenthesized_Expression_Node |
                         Adac.AST.Unary_Operator_Node |
                         Adac.AST.Binary_Exponentiating_Node |
                         Adac.AST.Binary_Multiplying_Node |
                         Adac.AST.Binary_Adding_Node |
                         Adac.AST.Attribute_Name_Node =>
                      declare
                        direct_integer_literal : constant Boolean :=
                          is_direct_integer_literal (context, expression);
                      begin
                        if is_direct_real_literal (context, expression) then
                          report_unsupported_declaration
                            (context,
                             statement,
                             "assignment expression type does not " &
                             "match target");
                          return (status => Analysis_Rejected);
                        end if;

                        declare
                          evaluated : constant Integer_Static_Result :=
                            evaluate_static_specific_integer_expression_exact
                              (context,
                               local_scope,
                               expression,
                               expected_type);
                        begin
                          case evaluated.status is
                            when Integer_Static_Unsupported =>
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 "assignment expression is not semantically " &
                                 "supported");
                              return (status => Analysis_Rejected);

                            when Integer_Static_Invalid =>
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 (if direct_integer_literal then
                                    "invalid integer literal in assignment"
                                  else
                                    "invalid integer expression in " &
                                    "assignment"));
                              return (status => Analysis_Rejected);

                            when Integer_Static_Zero_Divisor =>
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 "zero divisor in assignment expression");
                              return (status => Analysis_Rejected);

                            when Integer_Static_Out_Of_Range =>
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 (if direct_integer_literal then
                                    "integer literal is outside target " &
                                    "type range"
                                  else
                                    "integer expression is outside target " &
                                    "type range"));
                              return (status => Analysis_Rejected);

                            when Integer_Static_Resource_Limit =>
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 "universal integer resource limit exceeded " &
                                 "in assignment expression");
                              return (status => Analysis_Rejected);

                            when Integer_Static_Valid =>
                              if not Adac.Semantics.subtype_constraint_contains
                                (local_objects (target_local).constraint,
                                 evaluated.value)
                              then
                                report_unsupported_declaration
                                  (context,
                                   statement,
                                   (if direct_integer_literal then
                                      "integer literal is outside target " &
                                      "subtype range"
                                    else
                                      "integer expression is outside target " &
                                      "subtype range"));
                                return (status => Analysis_Rejected);
                              end if;

                              Adac.Semantics
                                .append_local_integer_static_assignment
                                  (checked_statements,
                                   statement,
                                   target_local,
                                   expected_type,
                                   evaluated.value);
                              mark_local_defined
                                (local_objects,
                                 target_local,
                                 index,
                                 evaluated.value);
                          end case;
                        end;
                      end;

                    when Adac.AST.Identifier_Name_Node =>
                      declare
                        source_symbol : constant Adac.Symbols.Symbol_ID :=
                          Adac.Compilation.Syntax.identifier_symbol
                            (context, expression);
                        resolved_source : constant Natural :=
                          Adac.Compilation.Semantics.resolve_local_object
                            (context, local_scope, source_symbol);
                      begin
                        if resolved_source = 0 then
                          declare
                            number_type : constant Adac.Types.Type_ID :=
                              Adac.Compilation.Semantics
                                .resolve_local_integer_number_type
                                  (context, local_scope, source_symbol);
                            real_number_type : constant Adac.Types.Type_ID :=
                              Adac.Compilation.Semantics
                                .resolve_local_real_number_type
                                  (context, local_scope, source_symbol);
                            constant_type : constant Adac.Types.Type_ID :=
                              Adac.Compilation.Semantics
                                .resolve_local_static_integer_constant_type
                                  (context, local_scope, source_symbol);
                          begin
                            if number_type /= Adac.Types.INVALID_TYPE_ID then
                              if number_type /=
                                Adac.Compilation.Types.universal_integer
                                  (context)
                              then
                                raise Program_Error with
                                  "Adac.Sema: named number lost universal type";
                              end if;

                              declare
                                universal_value : constant
                                  Adac.Types.Universal_Integer_Value :=
                                    Adac.Compilation.Semantics
                                      .resolve_local_integer_number_value
                                        (context, local_scope, source_symbol);
                                number_value : Long_Long_Integer;
                              begin
                                if not Adac.Types
                                  .universal_integer_fits_long_long
                                    (universal_value)
                                then
                                  report_unsupported_declaration
                                    (context,
                                     statement,
                                     "named-number value is outside target " &
                                     "type range");
                                  return (status => Analysis_Rejected);
                                end if;
                                number_value :=
                                  Adac.Types.universal_integer_to_long_long
                                    (universal_value);
                                if number_value <
                                     Adac.Compilation.Types
                                       .signed_integer_lower_bound
                                         (context, expected_type) or else
                                   number_value >
                                     Adac.Compilation.Types
                                       .signed_integer_upper_bound
                                         (context, expected_type)
                                then
                                  report_unsupported_declaration
                                    (context,
                                     statement,
                                     "named-number value is outside target " &
                                     "type range");
                                  return (status => Analysis_Rejected);
                                end if;
                                if not Adac.Semantics
                                  .subtype_constraint_contains
                                  (local_objects (target_local).constraint,
                                   number_value)
                                then
                                  report_unsupported_declaration
                                    (context,
                                     statement,
                                     "named-number value is outside target " &
                                     "subtype range");
                                  return (status => Analysis_Rejected);
                                end if;
                                Adac.Semantics
                                  .append_local_integer_static_assignment
                                    (checked_statements,
                                     statement,
                                     target_local,
                                     expected_type,
                                     number_value);
                                mark_local_defined
                                  (local_objects,
                                   target_local,
                                   index,
                                   number_value);
                              end;
                            else
                              if real_number_type /=
                                Adac.Types.INVALID_TYPE_ID
                              then
                                report_unsupported_declaration
                                  (context,
                                   statement,
                                   "assignment source type does not match " &
                                   "target");
                                return (status => Analysis_Rejected);
                              elsif constant_type =
                                Adac.Types.INVALID_TYPE_ID
                              then
                                report_unsupported_declaration
                                  (context,
                                   statement,
                                   "assignment source is not a declared " &
                                   "local " &
                                   "variable");
                                return (status => Analysis_Rejected);
                              end if;
                              if constant_type /= expected_type then
                                report_unsupported_declaration
                                  (context,
                                   statement,
                                   "assignment source type does not match " &
                                   "target");
                                return (status => Analysis_Rejected);
                              end if;

                              declare
                                constant_value : constant Long_Long_Integer :=
                                  Adac.Compilation.Semantics
                                    .resolve_local_static_integer_constant_value
                                      (context, local_scope, source_symbol);
                              begin
                                if not Adac.Semantics
                                  .subtype_constraint_contains
                                  (local_objects (target_local).constraint,
                                   constant_value)
                                then
                                  report_unsupported_declaration
                                    (context,
                                     statement,
                                     "assignment source value is outside " &
                                     "target subtype range");
                                  return (status => Analysis_Rejected);
                                end if;

                                Adac.Semantics
                                  .append_local_integer_static_assignment
                                    (checked_statements,
                                     statement,
                                     target_local,
                                     expected_type,
                                     constant_value);
                                mark_local_defined
                                  (local_objects,
                                   target_local,
                                   index,
                                   constant_value);
                              end;
                            end if;
                          end;
                        else
                          declare
                            source_local : constant Positive :=
                              Positive (resolved_source);
                            source_descriptor : constant
                              Local_Object_Descriptor :=
                                local_objects (source_local);
                          begin
                            if source_descriptor.semantic_type /=
                              expected_type
                            then
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 "assignment source type does not match " &
                                 "target");
                              return (status => Analysis_Rejected);
                            end if;

                            if not source_descriptor.has_defined_value then
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 "assignment source local read before a " &
                                 "supported definition is not supported");
                              return (status => Analysis_Rejected);
                            end if;

                            if not Adac.Semantics.subtype_constraint_contains
                              (local_objects (target_local).constraint,
                               source_descriptor.defined_integer_value)
                            then
                              report_unsupported_declaration
                                (context,
                                 statement,
                                 "assignment source value is outside target " &
                                 "subtype range");
                              return (status => Analysis_Rejected);
                            end if;

                            Adac.Semantics.append_local_integer_copy_assignment
                              (checked_statements,
                               statement,
                               target_local,
                               expected_type,
                               source_local,
                               source_descriptor.definition_statement,
                               source_descriptor.defined_integer_value);
                            mark_local_defined
                              (local_objects,
                               target_local,
                               index,
                               source_descriptor.defined_integer_value);
                          end;
                        end if;
                      end;

                    when others =>
                      report_unsupported_declaration
                        (context,
                         statement,
                         "assignment expression is not semantically supported");
                      return (status => Analysis_Rejected);
                    end case;
                  end if;
                end;
              end;
            end;

          when Adac.AST.Case_Statement_Node =>
            raise Program_Error with
              "Adac.Sema: case statement reached an unsupported stage";

          when Adac.AST.Block_Statement_Node =>
            raise Program_Error with
              "Adac.Sema: block statement reached an unsupported stage";

          when Adac.AST.Loop_Statement_Node =>
            raise Program_Error with
              "Adac.Sema: loop statement reached an unsupported stage";

          when Adac.AST.Procedure_Call_Statement_Node =>
            raise Program_Error with
              "Adac.Sema: procedure call reached an unsupported stage";

          when Adac.AST.If_Statement_Node =>
            raise Program_Error with
              "Adac.Sema: if statement reached an unsupported stage";

          when Adac.AST.Numeric_Literal_Node |
               Adac.AST.Character_Literal_Node |
               Adac.AST.String_Literal_Node |
               Adac.AST.Null_Literal_Node |
               Adac.AST.Record_Aggregate_Node |
               Adac.AST.Array_Aggregate_Node |
               Adac.AST.Bracket_Aggregate_Node |
               Adac.AST.Qualified_Expression_Node |
               Adac.AST.If_Expression_Node |
               Adac.AST.Case_Expression_Node |
               Adac.AST.Parenthesized_Expression_Node |
               Adac.AST.Unary_Operator_Node |
               Adac.AST.Binary_Exponentiating_Node |
               Adac.AST.Binary_Multiplying_Node |
               Adac.AST.Binary_Adding_Node |
               Adac.AST.Relation_Node |
               Adac.AST.Membership_Expression_Node |
               Adac.AST.Logical_Expression_Node |
               Adac.AST.Short_Circuit_Expression_Node =>
            raise Program_Error with
              "Adac.Sema: expression node used as a statement";

          when Adac.AST.Identifier_Name_Node |
               Adac.AST.Selected_Name_Node |
               Adac.AST.Explicit_Dereference_Name_Node |
               Adac.AST.Selected_Component_Node |
               Adac.AST.Parenthesized_Name_Node |
               Adac.AST.Slice_Name_Node |
               Adac.AST.Attribute_Name_Node =>
            raise Program_Error with
              "Adac.Sema: name node used as a statement";

          when Adac.AST.Parameter_Specification_Node |
               Adac.AST.Object_Declaration_Node |
               Adac.AST.Object_Renaming_Declaration_Node |
               Adac.AST.Number_Declaration_Node |
               Adac.AST.Exception_Declaration_Node |
               Adac.AST.Procedure_Declaration_Node |
               Adac.AST.Procedure_Body_Stub_Node |
               Adac.AST.Function_Declaration_Node =>
            raise Program_Error with
              "Adac.Sema: declaration node used as a statement";
        end case;
      end loop;

      declare
        local_entities : Adac.Semantics.Entity_ID_List;
      begin
        for descriptor of local_objects loop
          declare
            local_entity : Adac.Semantics.Entity_ID;
          begin
            if descriptor.has_integer_initializer then
              local_entity := Adac.Compilation.Semantics.create_object
                (context,
                 descriptor.declaration,
                 descriptor.semantic_type,
                 descriptor.integer_initializer,
                 descriptor.constraint);
            elsif descriptor.has_boolean_initializer then
              local_entity := Adac.Compilation.Semantics.create_object
                (context,
                 descriptor.declaration,
                 descriptor.semantic_type,
                 descriptor.boolean_initializer,
                 descriptor.constraint);
            else
              local_entity := Adac.Compilation.Semantics.create_object
                (context,
                 descriptor.declaration,
                 descriptor.semantic_type,
                 descriptor.constraint);
            end if;

            Adac.Semantics.append (local_entities, local_entity);
          end;
        end loop;

        return
          (status => Analysis_Succeeded,
           entity => Adac.Compilation.Semantics.create_procedure
             (context,
              library_item,
              local_scope,
              local_entities,
              checked_statements));
      end;
    end;
  end analyze;

end Adac.Sema;
