-- ============================================================================
-- adac-compilation-semantics.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;
with Adac.Compilation.Types;
with Adac.Resources;

package body Adac.Compilation.Semantics is

  use type Adac.AST.Node_ID;
  use type Adac.AST.Node_Kind;
  use type Adac.AST.Object_Declaration_Form;
  use type Adac.AST.Short_Circuit_Operator_Kind;
  use type Adac.Semantics.Boolean_Binary_Operator_Kind;
  use type Adac.Semantics.Procedure_Statement_Kind;
  use type Adac.Semantics.Entity_Kind;
  use type Adac.Semantics.Scope_Binding_Kind;
  use type Adac.Semantics.Subtype_Constraint;
  use type Adac.Semantics.Subtype_Constraint_Kind;
  use type Adac.Source.Span;
  use type Adac.Symbols.Symbol_ID;
  use type Adac.Types.Boolean_Value;
  use type Adac.Types.Type_ID;
  use type Adac.Types.Type_Kind;

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

  procedure resolve_boolean_binary_expression_syntax
    (self          : Context;
     expression    : Adac.AST.Node_ID;
     operator_kind : out Adac.Semantics.Boolean_Binary_Operator_Kind;
     left_operand  : out Adac.AST.Node_ID;
     right_operand : out Adac.AST.Node_ID)
  is
  begin
    case Adac.Compilation.Syntax.kind_of (self, expression) is
      when Adac.AST.Logical_Expression_Node =>
        operator_kind := semantic_boolean_binary_operator
          (Adac.Compilation.Syntax.logical_operator (self, expression));
        left_operand := Adac.Compilation.Syntax.logical_left_operand
          (self, expression);
        right_operand := Adac.Compilation.Syntax.logical_right_operand
          (self, expression);

      when Adac.AST.Relation_Node =>
        operator_kind := semantic_boolean_relation_operator
          (Adac.Compilation.Syntax.relation_operator_spelling
             (self, expression));
        if operator_kind = Adac.Semantics.No_Boolean_Binary_Operator then
          raise Program_Error with
            "Adac.Compilation.Semantics: unsupported Boolean binary relation";
        end if;
        left_operand := Adac.Compilation.Syntax.relation_left_operand
          (self, expression);
        right_operand := Adac.Compilation.Syntax.relation_right_operand
          (self, expression);

      when others =>
        raise Program_Error with
          "Adac.Compilation.Semantics: Boolean binary expression is invalid";
    end case;
  end resolve_boolean_binary_expression_syntax;

  function unparenthesized_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
    result : Adac.AST.Node_ID := expression;
  begin
    while Adac.Compilation.Syntax.kind_of (self, result) =
      Adac.AST.Parenthesized_Expression_Node
    loop
      result := Adac.Compilation.Syntax.parenthesized_expression_child
        (self, result);
    end loop;
    return result;
  end unparenthesized_expression;

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
          "Adac.Compilation.Semantics: missing Boolean binary operator";
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

  procedure try_bind_local_object
    (self     : Context;
     scope    : in out Adac.Semantics.Lexical_Scope;
     symbol   : Adac.Symbols.Symbol_ID;
     local    : Positive;
     inserted : out Boolean)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Semantics.try_bind_local_object
      (scope, self.symbol_store, symbol, local, inserted);
  end try_bind_local_object;

  procedure try_bind_local_subtype
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Adac.Semantics.Subtype_Constraint;
     inserted      : out Boolean)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Syntax.validate_subtype_declaration (self, declaration);
    Adac.Compilation.Types.validate (self, semantic_type);
    Adac.Semantics.validate (constraint);
    Adac.Semantics.try_bind_local_subtype
      (scope,
       self.symbol_store,
       symbol,
       declaration,
       semantic_type,
       constraint,
       inserted);
  end try_bind_local_subtype;

  function resolve_local_object
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    return Adac.Semantics.resolve_local_object
      (scope, self.symbol_store, symbol);
  end resolve_local_object;

  function resolve_local_subtype
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_subtype
      (scope, self.symbol_store, symbol);
    if result /= Adac.Types.INVALID_TYPE_ID then
      Adac.Compilation.Types.validate (self, result);
    end if;
    return result;
  end resolve_local_subtype;

  function resolve_local_subtype_constraint
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint is
    result : Adac.Semantics.Subtype_Constraint;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_subtype_constraint
      (scope, self.symbol_store, symbol);
    Adac.Semantics.validate (result);
    return result;
  end resolve_local_subtype_constraint;

  function resolve_local_static_integer_constant_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_static_integer_constant_type
      (scope, self.symbol_store, symbol);
    if result /= Adac.Types.INVALID_TYPE_ID then
      Adac.Compilation.Types.validate (self, result);
    end if;
    return result;
  end resolve_local_static_integer_constant_type;

  function resolve_local_static_integer_constant_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Long_Long_Integer is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    return Adac.Semantics.resolve_local_static_integer_constant_value
      (scope, self.symbol_store, symbol);
  end resolve_local_static_integer_constant_value;

  function resolve_local_static_boolean_constant_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_static_boolean_constant_type
      (scope, self.symbol_store, symbol);
    if result /= Adac.Types.INVALID_TYPE_ID then
      Adac.Compilation.Types.validate (self, result);
    end if;
    return result;
  end resolve_local_static_boolean_constant_type;

  function resolve_local_static_boolean_constant_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Boolean_Value is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    return Adac.Semantics.resolve_local_static_boolean_constant_value
      (scope, self.symbol_store, symbol);
  end resolve_local_static_boolean_constant_value;

  function resolve_local_integer_number_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_integer_number_type
      (scope, self.symbol_store, symbol);
    if result /= Adac.Types.INVALID_TYPE_ID then
      Adac.Compilation.Types.validate (self, result);
    end if;
    return result;
  end resolve_local_integer_number_type;

  function resolve_local_integer_number_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Integer_Value is
    result : Adac.Types.Universal_Integer_Value;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_integer_number_value
      (scope, self.symbol_store, symbol);
    Adac.Types.validate (result);
    return result;
  end resolve_local_integer_number_value;

  function resolve_local_real_number_type
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_real_number_type
      (scope, self.symbol_store, symbol);
    if result /= Adac.Types.INVALID_TYPE_ID then
      Adac.Compilation.Types.validate (self, result);
    end if;
    return result;
  end resolve_local_real_number_type;

  function resolve_local_real_number_value
    (self   : Context;
     scope  : Adac.Semantics.Lexical_Scope;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Types.Universal_Real_Value is
    result : Adac.Types.Universal_Real_Value;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.resolve_local_real_number_value
      (scope, self.symbol_store, symbol);
    Adac.Types.validate (result);
    return result;
  end resolve_local_real_number_value;

  function predefined_subtype_constraint
    (self : Context;
     kind : Adac.Compilation.Types.Predefined_Integer_Subtype_Kind)
  return Adac.Semantics.Subtype_Constraint is
    integer_type : constant Adac.Types.Type_ID :=
      Adac.Compilation.Types.standard_integer (self);
    integer_upper_bound : constant Long_Long_Integer :=
      Adac.Compilation.Types.signed_integer_upper_bound
        (self, integer_type);
  begin
    case kind is
      when Adac.Compilation.Types.Standard_Integer_Subtype =>
        return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;

      when Adac.Compilation.Types.Standard_Natural_Subtype =>
        return Adac.Semantics.make_signed_integer_range_constraint
          (0, integer_upper_bound);

      when Adac.Compilation.Types.Standard_Positive_Subtype =>
        return Adac.Semantics.make_signed_integer_range_constraint
          (1, integer_upper_bound);

      when Adac.Compilation.Types.Not_Predefined_Integer_Subtype =>
        return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
    end case;
  end predefined_subtype_constraint;

  function resolve_predefined_subtype_constraint
    (self   : Context;
     symbol : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint is
  begin
    return predefined_subtype_constraint
      (self,
       Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (self, symbol));
  end resolve_predefined_subtype_constraint;

  function resolve_predefined_subtype_constraint
    (self           : Context;
     package_symbol : Adac.Symbols.Symbol_ID;
     symbol         : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint is
  begin
    return predefined_subtype_constraint
      (self,
       Adac.Compilation.Types.resolve_predefined_integer_subtype_kind
         (self, package_symbol, symbol));
  end resolve_predefined_subtype_constraint;

  procedure validate_variable_object
    (self          : Context;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID)
  is
  begin
    Adac.Compilation.Syntax.validate_declaration (self, declaration);
    Adac.Compilation.Types.validate (self, semantic_type);

    if Adac.Compilation.Syntax.kind_of (self, declaration) /=
      Adac.AST.Object_Declaration_Node or else
       Adac.Compilation.Syntax.object_form (self, declaration) /=
         Adac.AST.Variable_Object_Form
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: object is not a variable declaration";
    end if;
  end validate_variable_object;

  procedure validate_static_integer_expression_syntax
    (self       : Context;
     expression : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.Syntax.validate_expression (self, expression);

    case Adac.Compilation.Syntax.kind_of (self, expression) is
      when Adac.AST.Numeric_Literal_Node |
           Adac.AST.Identifier_Name_Node |
           Adac.AST.Attribute_Name_Node |
           Adac.AST.Parenthesized_Expression_Node |
           Adac.AST.Unary_Operator_Node |
           Adac.AST.Binary_Exponentiating_Node |
           Adac.AST.Binary_Multiplying_Node |
           Adac.AST.Binary_Adding_Node =>
        null;

      when others =>
        raise Program_Error with
          "Adac.Compilation.Semantics: expression is not a supported static " &
          "integer form";
    end case;
  end validate_static_integer_expression_syntax;

  procedure validate_static_real_expression_syntax
    (self       : Context;
     expression : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.Syntax.validate_expression (self, expression);

    case Adac.Compilation.Syntax.kind_of (self, expression) is
      when Adac.AST.Numeric_Literal_Node |
           Adac.AST.Identifier_Name_Node |
           Adac.AST.Parenthesized_Expression_Node |
           Adac.AST.Unary_Operator_Node |
           Adac.AST.Binary_Exponentiating_Node |
           Adac.AST.Binary_Multiplying_Node |
           Adac.AST.Binary_Adding_Node =>
        null;

      when others =>
        raise Program_Error with
          "Adac.Compilation.Semantics: expression is not a supported static " &
          "real form";
    end case;
  end validate_static_real_expression_syntax;

  procedure validate_static_boolean_expression_syntax
    (self       : Context;
     expression : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.Syntax.validate_expression (self, expression);
    case Adac.Compilation.Syntax.kind_of (self, expression) is
      when Adac.AST.Identifier_Name_Node |
           Adac.AST.Parenthesized_Expression_Node |
           Adac.AST.Relation_Node |
           Adac.AST.Logical_Expression_Node |
           Adac.AST.Short_Circuit_Expression_Node =>
        null;

      when Adac.AST.Unary_Operator_Node =>
        if Adac.Compilation.Syntax.unary_operator_spelling
             (self, expression) /= "not"
        then
          raise Program_Error with
            "Adac.Compilation.Semantics: Boolean unary operator is invalid";
        end if;

      when others =>
        raise Program_Error with
          "Adac.Compilation.Semantics: Boolean expression is not static";
    end case;
  end validate_static_boolean_expression_syntax;

  procedure validate_boolean_initializer
    (self          : Context;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID)
  is
  begin
    if not Adac.Compilation.Syntax.object_has_initializer
      (self, declaration)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: Boolean object has no AST initializer";
    end if;
    if semantic_type /= Adac.Compilation.Types.standard_boolean (self) then
      raise Program_Error with
        "Adac.Compilation.Semantics: Boolean initializer type is invalid";
    end if;

    validate_static_boolean_expression_syntax
      (self, Adac.Compilation.Syntax.object_initializer (self, declaration));
  end validate_boolean_initializer;

  procedure validate_static_boolean_constant_declaration
    (self          : Context;
     declaration   : Adac.AST.Node_ID;
     symbol        : Adac.Symbols.Symbol_ID;
     semantic_type : Adac.Types.Type_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Syntax.validate_declaration (self, declaration);
    Adac.Compilation.Types.validate (self, semantic_type);

    if Adac.Compilation.Syntax.kind_of (self, declaration) /=
         Adac.AST.Object_Declaration_Node or else
       Adac.Compilation.Syntax.object_form (self, declaration) /=
         Adac.AST.Constant_Object_Form or else
       Adac.Compilation.Syntax.object_symbol
         (self, declaration) /= symbol
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: static Boolean constant is invalid";
    end if;

    validate_boolean_initializer (self, declaration, semantic_type);
  end validate_static_boolean_constant_declaration;

  procedure try_bind_local_static_integer_constant
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Adac.Semantics.Subtype_Constraint;
     value         : Long_Long_Integer;
     inserted      : out Boolean)
  is
    initializer : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Syntax.validate_declaration (self, declaration);
    Adac.Compilation.Types.validate (self, semantic_type);
    Adac.Semantics.validate (constraint);

    if Adac.Compilation.Syntax.kind_of (self, declaration) /=
         Adac.AST.Object_Declaration_Node or else
       Adac.Compilation.Syntax.object_form (self, declaration) /=
         Adac.AST.Constant_Object_Form or else
       not Adac.Compilation.Syntax.object_has_initializer (self, declaration)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: static constant declaration is invalid";
    end if;

    if Adac.Compilation.Syntax.object_symbol (self, declaration) /= symbol then
      raise Program_Error with
        "Adac.Compilation.Semantics: static constant symbol mismatch";
    end if;

    initializer := Adac.Compilation.Syntax.object_initializer
      (self, declaration);
    validate_static_integer_expression_syntax (self, initializer);

    if Adac.Compilation.Types.kind_of (self, semantic_type) /=
         Adac.Types.Signed_Integer_Type or else
       value < Adac.Compilation.Types.signed_integer_lower_bound
         (self, semantic_type) or else
       value > Adac.Compilation.Types.signed_integer_upper_bound
         (self, semantic_type) or else
       not Adac.Semantics.subtype_constraint_contains (constraint, value)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: static constant value is invalid";
    end if;

    Adac.Semantics.try_bind_local_static_integer_constant
      (scope,
       self.symbol_store,
       symbol,
       declaration,
       semantic_type,
       constraint,
       value,
       inserted);
  end try_bind_local_static_integer_constant;

  procedure try_bind_local_static_boolean_constant
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Boolean_Value;
     inserted      : out Boolean)
  is
  begin
    validate_static_boolean_constant_declaration
      (self, declaration, symbol, semantic_type);
    Adac.Semantics.try_bind_local_static_boolean_constant
      (scope,
       self.symbol_store,
       symbol,
       declaration,
       semantic_type,
       value,
       inserted);
  end try_bind_local_static_boolean_constant;

  procedure try_bind_local_integer_number
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Integer_Value;
     inserted      : out Boolean)
  is
    initializer : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Syntax.validate_declaration (self, declaration);
    Adac.Compilation.Types.validate (self, semantic_type);
    Adac.Types.validate (value);

    if Adac.Compilation.Syntax.kind_of (self, declaration) /=
         Adac.AST.Number_Declaration_Node or else
       Adac.Compilation.Syntax.number_symbol
         (self, declaration) /= symbol or else
       semantic_type /= Adac.Compilation.Types.universal_integer (self)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: integer named-number binding is invalid";
    end if;

    initializer := Adac.Compilation.Syntax.number_initializer
      (self, declaration);
    validate_static_integer_expression_syntax (self, initializer);
    if Adac.Types.universal_integer_decimal_digits (value) >
       Adac.Compilation.resource_limits
         (self).maximum_universal_integer_decimal_digits
    then
      raise Adac.Resources.Limit_Exceeded with
        "universal integer decimal digit limit exceeded";
    end if;

    Adac.Semantics.try_bind_local_integer_number
      (scope,
       self.symbol_store,
       symbol,
       declaration,
       semantic_type,
       value,
       inserted);
  end try_bind_local_integer_number;

  procedure validate_static_real_number_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID)
  is
    initializer : Adac.AST.Node_ID;
  begin
    Adac.Compilation.Syntax.validate_declaration (self, declaration);
    if Adac.Compilation.Syntax.kind_of (self, declaration) /=
         Adac.AST.Number_Declaration_Node or else
       Adac.Compilation.Syntax.number_symbol (self, declaration) /= symbol
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: real number declaration is invalid";
    end if;

    initializer := Adac.Compilation.Syntax.number_initializer
      (self, declaration);
    validate_static_real_expression_syntax (self, initializer);
  end validate_static_real_number_declaration;

  procedure try_bind_local_real_number
    (self          : Context;
     scope         : in out Adac.Semantics.Lexical_Scope;
     symbol        : Adac.Symbols.Symbol_ID;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     value         : Adac.Types.Universal_Real_Value;
     inserted      : out Boolean)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    validate_static_real_number_declaration (self, declaration, symbol);
    Adac.Compilation.Types.validate (self, semantic_type);
    Adac.Types.validate (value);

    if semantic_type /= Adac.Compilation.Types.universal_real (self) then
      raise Program_Error with
        "Adac.Compilation.Semantics: real named-number binding is invalid";
    end if;

    if Adac.Types.universal_real_numerator_decimal_digits (value) >
         Adac.Compilation.resource_limits
           (self).maximum_universal_real_component_decimal_digits or else
       Adac.Types.universal_real_denominator_decimal_digits (value) >
         Adac.Compilation.resource_limits
           (self).maximum_universal_real_component_decimal_digits
    then
      raise Adac.Resources.Limit_Exceeded with
        "universal real component decimal digit limit exceeded";
    end if;

    Adac.Semantics.try_bind_local_real_number
      (scope,
       self.symbol_store,
       symbol,
       declaration,
       semantic_type,
       value,
       inserted);
  end try_bind_local_real_number;

  procedure validate_integer_initializer
    (self                : Context;
     declaration         : Adac.AST.Node_ID;
     semantic_type       : Adac.Types.Type_ID;
     integer_initializer : Long_Long_Integer)
  is
    initializer : Adac.AST.Node_ID;
  begin
    if not Adac.Compilation.Syntax.object_has_initializer
      (self, declaration)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: initialized object has no AST initializer";
    end if;

    initializer := Adac.Compilation.Syntax.object_initializer
      (self, declaration);
    validate_static_integer_expression_syntax (self, initializer);

    if Adac.Compilation.Types.kind_of (self, semantic_type) /=
      Adac.Types.Signed_Integer_Type
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: initializer type is not signed integer";
    end if;

    if integer_initializer <
         Adac.Compilation.Types.signed_integer_lower_bound
           (self, semantic_type) or else
       integer_initializer >
         Adac.Compilation.Types.signed_integer_upper_bound
           (self, semantic_type)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: initializer value is out of range";
    end if;
  end validate_integer_initializer;

  function create_object
    (self          : in out Context;
     declaration   : Adac.AST.Node_ID;
     semantic_type : Adac.Types.Type_ID;
     constraint    : Adac.Semantics.Subtype_Constraint)
  return Adac.Semantics.Entity_ID is
  begin
    validate_variable_object (self, declaration, semantic_type);
    Adac.Semantics.validate (constraint);

    if Adac.Compilation.Syntax.object_has_initializer (self, declaration) then
      raise Program_Error with
        "Adac.Compilation.Semantics: uninitialized object has AST initializer";
    end if;

    return Adac.Semantics.append_object
      (self.semantic_store,
       declaration,
       Adac.Compilation.Syntax.object_symbol (self, declaration),
       Adac.Compilation.Syntax.node_span (self, declaration),
       semantic_type,
       constraint);
  end create_object;

  function create_object
    (self                : in out Context;
     declaration         : Adac.AST.Node_ID;
     semantic_type       : Adac.Types.Type_ID;
     integer_initializer : Long_Long_Integer;
     constraint          : Adac.Semantics.Subtype_Constraint)
  return Adac.Semantics.Entity_ID is
  begin
    validate_variable_object (self, declaration, semantic_type);
    Adac.Semantics.validate (constraint);
    validate_integer_initializer
      (self, declaration, semantic_type, integer_initializer);
    if not Adac.Semantics.subtype_constraint_contains
      (constraint, integer_initializer)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: initializer violates subtype constraint";
    end if;

    return Adac.Semantics.append_object
      (self.semantic_store,
       declaration,
       Adac.Compilation.Syntax.object_symbol (self, declaration),
       Adac.Compilation.Syntax.node_span (self, declaration),
       semantic_type,
       integer_initializer,
       constraint);
  end create_object;

  function create_object
    (self                : in out Context;
     declaration         : Adac.AST.Node_ID;
     semantic_type       : Adac.Types.Type_ID;
     boolean_initializer : Adac.Types.Boolean_Value;
     constraint          : Adac.Semantics.Subtype_Constraint)
  return Adac.Semantics.Entity_ID is
  begin
    validate_variable_object (self, declaration, semantic_type);
    Adac.Semantics.validate (constraint);
    if constraint /= Adac.Semantics.NO_SUBTYPE_CONSTRAINT then
      raise Program_Error with
        "Adac.Compilation.Semantics: Boolean object has subtype constraint";
    end if;
    validate_boolean_initializer (self, declaration, semantic_type);

    return Adac.Semantics.append_object
      (self.semantic_store,
       declaration,
       Adac.Compilation.Syntax.object_symbol (self, declaration),
       Adac.Compilation.Syntax.node_span (self, declaration),
       semantic_type,
       boolean_initializer,
       constraint);
  end create_object;

  function create_procedure
    (self        : in out Context;
     declaration : Adac.AST.Node_ID;
     scope       : Adac.Semantics.Lexical_Scope;
     locals      : Adac.Semantics.Entity_ID_List;
     statements  : Adac.Semantics.Procedure_Statement_List)
  return Adac.Semantics.Entity_ID is
  begin
    Adac.Compilation.Syntax.validate_procedure_body (self, declaration);
    Adac.Semantics.validate (scope, self.symbol_store);

    if Adac.Semantics.scope_local_object_count (scope) /=
       Adac.Semantics.entity_list_count (locals)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: procedure scope/local count mismatch";
    end if;

    if Adac.Semantics.scope_binding_count (scope) /=
       Adac.Compilation.Syntax.declaration_count (self, declaration)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: procedure binding/declaration count " &
        "mismatch";
    end if;

    for index in 1 .. Adac.Semantics.scope_binding_count (scope) loop
      declare
        syntax_declaration : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.declaration_at (self, declaration, index);
      begin
      case Adac.Semantics.scope_binding_kind_at (scope, index) is
        when Adac.Semantics.Local_Object_Binding =>
          declare
            local_ordinal : constant Positive :=
              Adac.Semantics.scope_binding_local_at (scope, index);
            local : constant Adac.Semantics.Entity_ID :=
              Adac.Semantics.entity_list_element (locals, local_ordinal);
          begin
            validate (self, local);
            if kind_of (self, local) /= Adac.Semantics.Object_Entity then
              raise Program_Error with
                "Adac.Compilation.Semantics: procedure local is not an object";
            end if;
            if Adac.Semantics.declaration (self.semantic_store, local) /=
                 syntax_declaration or else
               Adac.Semantics.scope_binding_symbol_at (scope, index) /=
                 symbol (self, local)
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: procedure scope/local mismatch";
            end if;
          end;

        when Adac.Semantics.Local_Subtype_Binding =>
          declare
            subtype_declaration : constant Adac.AST.Node_ID :=
              Adac.Semantics.scope_binding_subtype_declaration_at
                (scope, index);
            subtype_type : constant Adac.Types.Type_ID :=
              Adac.Semantics.scope_binding_subtype_type_at (scope, index);
            constraint : constant Adac.Semantics.Subtype_Constraint :=
              Adac.Semantics.scope_binding_subtype_constraint_at (scope, index);
            has_constraint : constant Boolean :=
              Adac.Compilation.Syntax.subtype_declaration_has_constraint
                (self, subtype_declaration);
          begin
            Adac.Compilation.Syntax.validate_subtype_declaration
              (self, subtype_declaration);
            Adac.Compilation.Types.validate (self, subtype_type);
            Adac.Semantics.validate (constraint);
            if subtype_declaration /= syntax_declaration or else
               Adac.Compilation.Syntax.subtype_declaration_symbol
                 (self, subtype_declaration) /=
               Adac.Semantics.scope_binding_symbol_at (scope, index) or else
               (has_constraint and then
                Adac.Semantics.subtype_constraint_category (constraint) /=
                  Adac.Semantics.Signed_Integer_Range_Constraint)
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: local subtype binding mismatch";
            end if;
          end;

        when Adac.Semantics.Local_Static_Integer_Constant_Binding =>
          declare
            constant_declaration : constant Adac.AST.Node_ID :=
              Adac.Semantics.scope_binding_static_constant_declaration_at
                (scope, index);
            constant_type : constant Adac.Types.Type_ID :=
              Adac.Semantics.scope_binding_static_constant_type_at
                (scope, index);
            constraint : constant Adac.Semantics.Subtype_Constraint :=
              Adac.Semantics.scope_binding_static_constant_constraint_at
                (scope, index);
            value : constant Long_Long_Integer :=
              Adac.Semantics.scope_binding_static_constant_value_at
                (scope, index);
          begin
            Adac.Compilation.Syntax.validate_declaration
              (self, constant_declaration);
            Adac.Compilation.Types.validate (self, constant_type);
            Adac.Semantics.validate (constraint);
            if constant_declaration /= syntax_declaration or else
               Adac.Compilation.Syntax.kind_of (self, constant_declaration) /=
                 Adac.AST.Object_Declaration_Node or else
               Adac.Compilation.Syntax.object_form
                 (self, constant_declaration) /=
                 Adac.AST.Constant_Object_Form or else
               not Adac.Compilation.Syntax.object_has_initializer
                 (self, constant_declaration) or else
               Adac.Compilation.Syntax.object_symbol
                 (self, constant_declaration) /=
               Adac.Semantics.scope_binding_symbol_at (scope, index) or else
               Adac.Compilation.Types.kind_of (self, constant_type) /=
                 Adac.Types.Signed_Integer_Type or else
               value < Adac.Compilation.Types.signed_integer_lower_bound
                 (self, constant_type) or else
               value > Adac.Compilation.Types.signed_integer_upper_bound
                 (self, constant_type) or else
               not Adac.Semantics.subtype_constraint_contains
                 (constraint, value)
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: static constant binding mismatch";
            end if;
            validate_static_integer_expression_syntax
              (self,
               Adac.Compilation.Syntax.object_initializer
                 (self, constant_declaration));
          end;

        when Adac.Semantics.Local_Static_Boolean_Constant_Binding =>
          declare
            constant_declaration : constant Adac.AST.Node_ID :=
              Adac.Semantics.scope_binding_static_constant_declaration_at
                (scope, index);
            constant_type : constant Adac.Types.Type_ID :=
              Adac.Semantics.scope_binding_static_constant_type_at
                (scope, index);
          begin
            if constant_declaration /= syntax_declaration then
              raise Program_Error with
                "Adac.Compilation.Semantics: Boolean constant declaration " &
                "mismatch";
            end if;
            validate_static_boolean_constant_declaration
              (self,
               constant_declaration,
               Adac.Semantics.scope_binding_symbol_at (scope, index),
               constant_type);
          end;

        when Adac.Semantics.Local_Integer_Number_Binding =>
          declare
            number_declaration : constant Adac.AST.Node_ID :=
              Adac.Semantics.scope_binding_integer_number_declaration_at
                (scope, index);
            number_type : constant Adac.Types.Type_ID :=
              Adac.Semantics.scope_binding_integer_number_type_at
                (scope, index);
            number_value : constant Adac.Types.Universal_Integer_Value :=
              Adac.Semantics.scope_binding_integer_number_value_at
                (scope, index);
          begin
            Adac.Compilation.Syntax.validate_declaration
              (self, number_declaration);
            Adac.Compilation.Types.validate (self, number_type);
            Adac.Types.validate (number_value);
            if number_declaration /= syntax_declaration or else
               Adac.Compilation.Syntax.kind_of (self, number_declaration) /=
                 Adac.AST.Number_Declaration_Node or else
               Adac.Compilation.Syntax.number_symbol
                 (self, number_declaration) /=
               Adac.Semantics.scope_binding_symbol_at (scope, index) or else
               number_type /=
                 Adac.Compilation.Types.universal_integer (self) or else
               Adac.Types.universal_integer_decimal_digits (number_value) >
                 Adac.Compilation.resource_limits
                   (self).maximum_universal_integer_decimal_digits
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: integer named-number binding " &
                "mismatch";
            end if;
            validate_static_integer_expression_syntax
              (self,
               Adac.Compilation.Syntax.number_initializer
                 (self, number_declaration));
          end;

        when Adac.Semantics.Local_Real_Number_Binding =>
          declare
            number_declaration : constant Adac.AST.Node_ID :=
              Adac.Semantics.scope_binding_real_number_declaration_at
                (scope, index);
            number_type : constant Adac.Types.Type_ID :=
              Adac.Semantics.scope_binding_real_number_type_at
                (scope, index);
            number_value : constant Adac.Types.Universal_Real_Value :=
              Adac.Semantics.scope_binding_real_number_value_at
                (scope, index);
            maximum_component_digits : constant
              Adac.Resources.Universal_Real_Component_Decimal_Digit_Limit :=
                Adac.Compilation.resource_limits
                  (self).maximum_universal_real_component_decimal_digits;
          begin
            validate_static_real_number_declaration
              (self,
               number_declaration,
               Adac.Semantics.scope_binding_symbol_at (scope, index));
            Adac.Compilation.Types.validate (self, number_type);
            Adac.Types.validate (number_value);
            if number_declaration /= syntax_declaration or else
               number_type /=
                 Adac.Compilation.Types.universal_real (self) or else
               Adac.Types.universal_real_numerator_decimal_digits
                 (number_value) > maximum_component_digits or else
               Adac.Types.universal_real_denominator_decimal_digits
                 (number_value) > maximum_component_digits
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: real named-number binding " &
                "mismatch";
            end if;
          end;
      end case;
      end;
    end loop;

    for index in 1 .. Adac.Semantics.statement_list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.Semantics.statement_list_syntax (statements, index);
        kind : constant Adac.Semantics.Procedure_Statement_Kind :=
          Adac.Semantics.statement_list_kind_at (statements, index);
      begin
        case kind is
          when Adac.Semantics.Null_Procedure_Statement =>
            if Adac.Compilation.Syntax.kind_of (self, statement) /=
              Adac.AST.Null_Statement_Node
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: null statement kind mismatch";
            end if;

          when Adac.Semantics.Return_Procedure_Statement =>
            if Adac.Compilation.Syntax.kind_of (self, statement) /=
              Adac.AST.Return_Statement_Node
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: return statement kind mismatch";
            end if;

          when Adac.Semantics.Local_Integer_Static_Assignment_Statement |
               Adac.Semantics.Local_Integer_Copy_Assignment_Statement =>
            Adac.Compilation.Syntax.validate_assignment_statement
              (self, statement);
            Adac.Compilation.Types.validate
              (self, Adac.Semantics.statement_list_expected_type
                       (statements, index));

          when Adac.Semantics.Local_Boolean_Static_Assignment_Statement =>
            Adac.Compilation.Syntax.validate_assignment_statement
              (self, statement);
            declare
              expected_type : constant Adac.Types.Type_ID :=
                Adac.Semantics.statement_list_expected_type
                  (statements, index);
            begin
              Adac.Compilation.Types.validate (self, expected_type);
              if expected_type /= Adac.Compilation.Types.standard_boolean (self)
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean assignment type is " &
                  "invalid";
              end if;
              validate_static_boolean_expression_syntax
                (self,
                 Adac.Compilation.Syntax.assignment_expression
                   (self, statement));
            end;

          when Adac.Semantics.Local_Boolean_Copy_Assignment_Statement =>
            Adac.Compilation.Syntax.validate_assignment_statement
              (self, statement);
            declare
              expected_type : constant Adac.Types.Type_ID :=
                Adac.Semantics.statement_list_expected_type
                  (statements, index);
            begin
              Adac.Compilation.Types.validate (self, expected_type);
              if expected_type /= Adac.Compilation.Types.standard_boolean (self)
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean copy type is invalid";
              end if;
            end;

          when Adac.Semantics.Local_Boolean_Not_Assignment_Statement =>
            Adac.Compilation.Syntax.validate_assignment_statement
              (self, statement);
            declare
              expected_type : constant Adac.Types.Type_ID :=
                Adac.Semantics.statement_list_expected_type
                  (statements, index);
              expression : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.assignment_expression
                  (self, statement);
            begin
              Adac.Compilation.Types.validate (self, expected_type);
              if expected_type /= Adac.Compilation.Types.standard_boolean (self)
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean not type is invalid";
              end if;
              if Adac.Compilation.Syntax.kind_of (self, expression) /=
                   Adac.AST.Unary_Operator_Node or else
                 Adac.Compilation.Syntax.unary_operator_spelling
                   (self, expression) /= "not" or else
                 Adac.Compilation.Syntax.kind_of
                   (self, Adac.Compilation.Syntax.unary_operand
                            (self, expression)) /=
                   Adac.AST.Identifier_Name_Node
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean not syntax is invalid";
              end if;
            end;

          when Adac.Semantics.Local_Boolean_And_Then_Assignment_Statement |
               Adac.Semantics.Local_Boolean_Or_Else_Assignment_Statement =>
            Adac.Compilation.Syntax.validate_assignment_statement
              (self, statement);
            declare
              expected_type : constant Adac.Types.Type_ID :=
                Adac.Semantics.statement_list_expected_type
                  (statements, index);
              expression : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.assignment_expression
                  (self, statement);
            begin
              Adac.Compilation.Types.validate (self, expected_type);
              if expected_type /= Adac.Compilation.Types.standard_boolean (self)
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean short-circuit type is " &
                  "invalid";
              end if;
              if Adac.Compilation.Syntax.kind_of (self, expression) /=
                   Adac.AST.Short_Circuit_Expression_Node or else
                 Adac.Compilation.Syntax.kind_of
                   (self,
                    Adac.Compilation.Syntax.short_circuit_left_operand
                      (self, expression)) /= Adac.AST.Identifier_Name_Node or else
                 Adac.Compilation.Syntax.kind_of
                   (self,
                    Adac.Compilation.Syntax.short_circuit_right_operand
                      (self, expression)) /= Adac.AST.Identifier_Name_Node
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean short-circuit syntax is " &
                  "invalid";
              end if;
              declare
                syntax_operator : constant Adac.AST.Short_Circuit_Operator_Kind :=
                  Adac.Compilation.Syntax.short_circuit_operator
                    (self, expression);
              begin
                if (kind =
                      Adac.Semantics.Local_Boolean_And_Then_Assignment_Statement
                    and then syntax_operator /=
                      Adac.AST.And_Then_Short_Circuit_Operator) or else
                   (kind =
                      Adac.Semantics.Local_Boolean_Or_Else_Assignment_Statement
                    and then syntax_operator /=
                      Adac.AST.Or_Else_Short_Circuit_Operator)
                then
                  raise Program_Error with
                    "Adac.Compilation.Semantics: Boolean short-circuit operator " &
                    "mismatch";
                end if;
              end;
            end;

          when Adac.Semantics.Local_Boolean_Expression_Assignment_Statement =>
            Adac.Compilation.Syntax.validate_assignment_statement
              (self, statement);
            declare
              expected_type : constant Adac.Types.Type_ID :=
                Adac.Semantics.statement_list_expected_type
                  (statements, index);
            begin
              Adac.Compilation.Types.validate (self, expected_type);
              if expected_type /= Adac.Compilation.Types.standard_boolean (self)
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean expression type is " &
                  "invalid";
              end if;
              Adac.Compilation.Syntax.validate_expression
                (self,
                 Adac.Compilation.Syntax.assignment_expression
                   (self, statement));
            end;

          when Adac.Semantics.Local_Boolean_Binary_Assignment_Statement =>
            Adac.Compilation.Syntax.validate_assignment_statement
              (self, statement);
            declare
              expected_type : constant Adac.Types.Type_ID :=
                Adac.Semantics.statement_list_expected_type
                  (statements, index);
              expression : constant Adac.AST.Node_ID :=
                Adac.Compilation.Syntax.assignment_expression
                  (self, statement);
            begin
              Adac.Compilation.Types.validate (self, expected_type);
              if expected_type /= Adac.Compilation.Types.standard_boolean (self)
              then
                raise Program_Error with
                  "Adac.Compilation.Semantics: Boolean binary type is invalid";
              end if;
              declare
                operator_kind : Adac.Semantics.Boolean_Binary_Operator_Kind;
                left_operand : Adac.AST.Node_ID;
                right_operand : Adac.AST.Node_ID;
              begin
                resolve_boolean_binary_expression_syntax
                  (self,
                   expression,
                   operator_kind,
                   left_operand,
                   right_operand);
                if Adac.Compilation.Syntax.kind_of (self, left_operand) /=
                     Adac.AST.Identifier_Name_Node or else
                   Adac.Compilation.Syntax.kind_of (self, right_operand) /=
                     Adac.AST.Identifier_Name_Node
                then
                  raise Program_Error with
                    "Adac.Compilation.Semantics: Boolean binary syntax is " &
                    "invalid";
                end if;
              end;
            end;
        end case;
      end;
    end loop;

    return Adac.Semantics.append_procedure
      (self.semantic_store,
       declaration,
       Adac.Compilation.Syntax.procedure_symbol (self, declaration),
       Adac.Compilation.Syntax.node_span (self, declaration),
       scope,
       locals,
       statements);
  end create_procedure;

  function entity_count (self : Context) return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.entity_count (self.semantic_store);
  end entity_count;

  function kind_of
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Semantics.Entity_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.kind_of (self.semantic_store, entity);
  end kind_of;

  function declaration
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.declaration (self.semantic_store, entity);
  end declaration;

  function symbol
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.symbol (self.semantic_store, entity);
  end symbol;

  function entity_span
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.entity_span (self.semantic_store, entity);
  end entity_span;

  function object_type
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.object_type (self.semantic_store, entity);
    Adac.Compilation.Types.validate (self, result);
    return result;
  end object_type;

  function object_subtype_constraint
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Semantics.Subtype_Constraint is
    result : Adac.Semantics.Subtype_Constraint;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.object_subtype_constraint
      (self.semantic_store, entity);
    Adac.Semantics.validate (result);
    return result;
  end object_subtype_constraint;

  function object_has_integer_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.object_has_integer_initializer
      (self.semantic_store, entity);
  end object_has_integer_initializer;

  function object_integer_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Long_Long_Integer is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.object_integer_initializer
      (self.semantic_store, entity);
  end object_integer_initializer;

  function object_has_boolean_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.object_has_boolean_initializer
      (self.semantic_store, entity);
  end object_has_boolean_initializer;

  function object_boolean_initializer
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  return Adac.Types.Boolean_Value is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.object_boolean_initializer
      (self.semantic_store, entity);
  end object_boolean_initializer;

  function procedure_local_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_local_count
      (self.semantic_store, procedure_entity);
  end procedure_local_count;

  function procedure_local_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Entity_ID is
    result : Adac.Semantics.Entity_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_local_at
      (self.semantic_store, procedure_entity, index);
    validate (self, result);
    return result;
  end procedure_local_at;

  function procedure_scope_binding_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_scope_binding_count
      (self.semantic_store, procedure_entity);
  end procedure_scope_binding_count;

  function procedure_scope_binding_kind_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Scope_Binding_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_scope_binding_kind_at
      (self.semantic_store, procedure_entity, index);
  end procedure_scope_binding_kind_at;

  function procedure_scope_binding_symbol_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Symbols.Symbol_ID is
    result : Adac.Symbols.Symbol_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_symbol_at
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Symbols.validate_symbol (self, result);
    return result;
  end procedure_scope_binding_symbol_at;

  function procedure_scope_binding_local_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_scope_binding_local_at
      (self.semantic_store, procedure_entity, index);
  end procedure_scope_binding_local_at;

  function procedure_scope_binding_subtype_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    result : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_subtype_declaration_at
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Syntax.validate_subtype_declaration (self, result);
    return result;
  end procedure_scope_binding_subtype_declaration_at;

  function procedure_scope_binding_subtype_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_subtype_type_at
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Types.validate (self, result);
    return result;
  end procedure_scope_binding_subtype_type_at;

  function procedure_scope_binding_subtype_constraint_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Subtype_Constraint is
    result : Adac.Semantics.Subtype_Constraint;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_subtype_constraint_at
      (self.semantic_store, procedure_entity, index);
    Adac.Semantics.validate (result);
    return result;
  end procedure_scope_binding_subtype_constraint_at;

  function procedure_scope_binding_static_constant_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    result : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    result :=
      Adac.Semantics.procedure_scope_binding_static_constant_declaration_at
        (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Syntax.validate_declaration (self, result);
    return result;
  end procedure_scope_binding_static_constant_declaration_at;

  function procedure_scope_binding_static_constant_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_static_constant_type_at
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Types.validate (self, result);
    return result;
  end procedure_scope_binding_static_constant_type_at;

  function procedure_scope_binding_static_constant_constraint_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Subtype_Constraint is
    result : Adac.Semantics.Subtype_Constraint;
  begin
    Adac.Compilation.validate (self);
    result :=
      Adac.Semantics.procedure_scope_binding_static_constant_constraint_at
        (self.semantic_store, procedure_entity, index);
    Adac.Semantics.validate (result);
    return result;
  end procedure_scope_binding_static_constant_constraint_at;

  function procedure_scope_binding_static_constant_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Long_Long_Integer is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_scope_binding_static_constant_value_at
      (self.semantic_store, procedure_entity, index);
  end procedure_scope_binding_static_constant_value_at;

  function procedure_scope_binding_static_boolean_constant_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics
      .procedure_scope_binding_static_boolean_constant_value_at
        (self.semantic_store, procedure_entity, index);
  end procedure_scope_binding_static_boolean_constant_value_at;

  function procedure_scope_binding_integer_number_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    result : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    result :=
      Adac.Semantics.procedure_scope_binding_integer_number_declaration_at
        (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Syntax.validate_declaration (self, result);
    return result;
  end procedure_scope_binding_integer_number_declaration_at;

  function procedure_scope_binding_integer_number_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_integer_number_type_at
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Types.validate (self, result);
    return result;
  end procedure_scope_binding_integer_number_type_at;

  function procedure_scope_binding_integer_number_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Integer_Value is
    result : Adac.Types.Universal_Integer_Value;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_integer_number_value_at
      (self.semantic_store, procedure_entity, index);
    Adac.Types.validate (result);
    return result;
  end procedure_scope_binding_integer_number_value_at;

  function procedure_scope_binding_real_number_declaration_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
    result : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_real_number_declaration_at
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Syntax.validate_declaration (self, result);
    return result;
  end procedure_scope_binding_real_number_declaration_at;

  function procedure_scope_binding_real_number_type_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_real_number_type_at
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Types.validate (self, result);
    return result;
  end procedure_scope_binding_real_number_type_at;

  function procedure_scope_binding_real_number_value_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Universal_Real_Value is
    result : Adac.Types.Universal_Real_Value;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.procedure_scope_binding_real_number_value_at
      (self.semantic_store, procedure_entity, index);
    Adac.Types.validate (result);
    return result;
  end procedure_scope_binding_real_number_value_at;

  function procedure_scope_binding_index_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    return Adac.Semantics.procedure_scope_binding_index_for_symbol
      (self.semantic_store, procedure_entity, self.symbol_store, symbol);
  end procedure_scope_binding_index_for_symbol;

  function procedure_local_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    return Adac.Semantics.procedure_local_for_symbol
      (self.semantic_store, procedure_entity, self.symbol_store, symbol);
  end procedure_local_for_symbol;

  function procedure_subtype_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.procedure_subtype_for_symbol
      (self.semantic_store, procedure_entity, self.symbol_store, symbol);
    if result /= Adac.Types.INVALID_TYPE_ID then
      Adac.Compilation.Types.validate (self, result);
    end if;
    return result;
  end procedure_subtype_for_symbol;

  function procedure_subtype_constraint_for_symbol
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     symbol           : Adac.Symbols.Symbol_ID)
  return Adac.Semantics.Subtype_Constraint is
    result : Adac.Semantics.Subtype_Constraint;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    result := Adac.Semantics.procedure_subtype_constraint_for_symbol
      (self.semantic_store, procedure_entity, self.symbol_store, symbol);
    Adac.Semantics.validate (result);
    return result;
  end procedure_subtype_constraint_for_symbol;

  function procedure_statement_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_statement_count
      (self.semantic_store, procedure_entity);
  end procedure_statement_count;

  function procedure_statement_kind_at
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Procedure_Statement_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_statement_kind_at
      (self.semantic_store, procedure_entity, index);
  end procedure_statement_kind_at;

  function procedure_statement_syntax
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.procedure_statement_syntax
      (self.semantic_store, procedure_entity, index);
  end procedure_statement_syntax;

  function assignment_target_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_target_local
      (self.semantic_store, procedure_entity, index);
  end assignment_target_local;

  function assignment_expected_type
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Type_ID is
    result : Adac.Types.Type_ID;
  begin
    Adac.Compilation.validate (self);
    result := Adac.Semantics.assignment_expected_type
      (self.semantic_store, procedure_entity, index);
    Adac.Compilation.Types.validate (self, result);
    return result;
  end assignment_expected_type;

  function assignment_integer_value
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Long_Long_Integer is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_integer_value
      (self.semantic_store, procedure_entity, index);
  end assignment_integer_value;

  function assignment_boolean_value
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Types.Boolean_Value is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_value
      (self.semantic_store, procedure_entity, index);
  end assignment_boolean_value;

  function assignment_boolean_operator
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Adac.Semantics.Boolean_Binary_Operator_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_operator
      (self.semantic_store, procedure_entity, index);
  end assignment_boolean_operator;

  function assignment_source_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_source_local
      (self.semantic_store, procedure_entity, index);
  end assignment_source_local;

  function assignment_source_definition_statement
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_source_definition_statement
      (self.semantic_store, procedure_entity, index);
  end assignment_source_definition_statement;

  function assignment_right_source_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Positive is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_right_source_local
      (self.semantic_store, procedure_entity, index);
  end assignment_right_source_local;

  function assignment_right_source_definition_statement
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_right_source_definition_statement
      (self.semantic_store, procedure_entity, index);
  end assignment_right_source_definition_statement;

  function assignment_boolean_expression_value_count
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_value_count
      (self.semantic_store, procedure_entity, index);
  end assignment_boolean_expression_value_count;

  function assignment_boolean_expression_value_kind
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Semantics.Boolean_Expression_Value_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_value_kind
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_value_kind;

  function assignment_boolean_expression_syntax
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_syntax
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_syntax;

  function assignment_boolean_expression_known_value
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Types.Boolean_Value is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_known_value
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_known_value;

  function assignment_boolean_expression_source_local
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_source_local
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_source_local;

  function assignment_boolean_expression_source_definition
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_source_definition
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_source_definition;

  function assignment_boolean_expression_operator
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Adac.Semantics.Boolean_Binary_Operator_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_operator
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_operator;

  function assignment_boolean_expression_operand
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_operand
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_operand;

  function assignment_boolean_expression_right_operand
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     index            : Positive;
     value_index      : Positive)
  return Positive is
  begin
    Adac.Compilation.validate (self);
    return Adac.Semantics.assignment_boolean_expression_right_operand
      (self.semantic_store, procedure_entity, index, value_index);
  end assignment_boolean_expression_right_operand;

  function stored_boolean_source_value
    (self              : Context;
     procedure_entity  : Adac.Semantics.Entity_ID;
     current_statement : Positive;
     source_entity     : Adac.Semantics.Entity_ID;
     source_local      : Positive;
     definition_index  : Natural)
  return Adac.Types.Boolean_Value is
  begin
    if definition_index = 0 then
      if not Adac.Semantics.object_has_boolean_initializer
        (self.semantic_store, source_entity)
      then
        raise Program_Error with
          "Adac.Compilation.Semantics: Boolean source lacks initializer";
      end if;
      return Adac.Semantics.object_boolean_initializer
        (self.semantic_store, source_entity);
    end if;
    if definition_index >= current_statement then
      raise Program_Error with
        "Adac.Compilation.Semantics: Boolean source definition is not earlier";
    end if;
    case Adac.Semantics.procedure_statement_kind_at
      (self.semantic_store, procedure_entity, Positive (definition_index))
    is
      when Adac.Semantics.Local_Boolean_Static_Assignment_Statement |
           Adac.Semantics.Local_Boolean_Copy_Assignment_Statement |
           Adac.Semantics.Local_Boolean_Not_Assignment_Statement |
           Adac.Semantics.Local_Boolean_Binary_Assignment_Statement |
           Adac.Semantics.Local_Boolean_And_Then_Assignment_Statement |
           Adac.Semantics.Local_Boolean_Or_Else_Assignment_Statement |
           Adac.Semantics.Local_Boolean_Expression_Assignment_Statement =>
        if Adac.Semantics.assignment_target_local
          (self.semantic_store,
           procedure_entity,
           Positive (definition_index)) /= source_local
        then
          raise Program_Error with
            "Adac.Compilation.Semantics: Boolean source definition mismatch";
        end if;
        return Adac.Semantics.assignment_boolean_value
          (self.semantic_store,
           procedure_entity,
           Positive (definition_index));

      when others =>
        raise Program_Error with
          "Adac.Compilation.Semantics: Boolean source definition kind is " &
          "invalid";
    end case;
  end stored_boolean_source_value;

  function resolve_stored_supported_subtype_mark
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     subtype_mark     : Adac.AST.Node_ID;
     before_binding   : Positive)
  return Adac.Types.Type_ID is
  begin
    case Adac.Compilation.Syntax.kind_of (self, subtype_mark) is
      when Adac.AST.Identifier_Name_Node =>
        declare
          symbol : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax.identifier_symbol (self, subtype_mark);
          binding_index : constant Natural :=
            Adac.Semantics.procedure_scope_binding_index_for_symbol
              (self.semantic_store,
               procedure_entity,
               self.symbol_store,
               symbol);
        begin
          if binding_index /= 0 and then binding_index < before_binding then
            if Adac.Semantics.procedure_scope_binding_kind_at
                 (self.semantic_store,
                  procedure_entity,
                  Positive (binding_index)) /=
                    Adac.Semantics.Local_Subtype_Binding
            then
              return Adac.Types.INVALID_TYPE_ID;
            end if;
            return Adac.Semantics.procedure_scope_binding_subtype_type_at
              (self.semantic_store,
               procedure_entity,
               Positive (binding_index));
          end if;

          declare
            integer_type : constant Adac.Types.Type_ID :=
              Adac.Compilation.Types.resolve_predefined_type_name
                (self, symbol);
          begin
            if integer_type /= Adac.Types.INVALID_TYPE_ID then
              return integer_type;
            end if;
            return Adac.Compilation.Types.resolve_predefined_boolean_type_name
              (self, symbol);
          end;
        end;

      when Adac.AST.Selected_Name_Node =>
        declare
          prefix : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.name_prefix (self, subtype_mark);
        begin
          if Adac.Compilation.Syntax.kind_of (self, prefix) /=
            Adac.AST.Identifier_Name_Node
          then
            return Adac.Types.INVALID_TYPE_ID;
          end if;

          declare
            package_symbol : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.identifier_symbol (self, prefix);
            package_binding : constant Natural :=
              Adac.Semantics.procedure_scope_binding_index_for_symbol
                (self.semantic_store,
                 procedure_entity,
                 self.symbol_store,
                 package_symbol);
          begin
            if package_binding /= 0 and then
               package_binding < before_binding
            then
              return Adac.Types.INVALID_TYPE_ID;
            end if;

            declare
              selector_symbol : constant Adac.Symbols.Symbol_ID :=
                Adac.Compilation.Syntax.selector_symbol (self, subtype_mark);
              integer_type : constant Adac.Types.Type_ID :=
                Adac.Compilation.Types.resolve_predefined_type_name
                  (self, package_symbol, selector_symbol);
            begin
              if integer_type /= Adac.Types.INVALID_TYPE_ID then
                return integer_type;
              end if;
              return
                Adac.Compilation.Types.resolve_predefined_boolean_type_name
                  (self, package_symbol, selector_symbol);
            end;
          end;
        end;

      when others =>
        return Adac.Types.INVALID_TYPE_ID;
    end case;
  end resolve_stored_supported_subtype_mark;

  function resolve_stored_supported_subtype_constraint
    (self             : Context;
     procedure_entity : Adac.Semantics.Entity_ID;
     subtype_mark     : Adac.AST.Node_ID;
     before_binding   : Positive)
  return Adac.Semantics.Subtype_Constraint is
  begin
    case Adac.Compilation.Syntax.kind_of (self, subtype_mark) is
      when Adac.AST.Identifier_Name_Node =>
        declare
          symbol : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax.identifier_symbol (self, subtype_mark);
          binding_index : constant Natural :=
            Adac.Semantics.procedure_scope_binding_index_for_symbol
              (self.semantic_store,
               procedure_entity,
               self.symbol_store,
               symbol);
        begin
          if binding_index /= 0 and then binding_index < before_binding then
            if Adac.Semantics.procedure_scope_binding_kind_at
                 (self.semantic_store,
                  procedure_entity,
                  Positive (binding_index)) /=
                    Adac.Semantics.Local_Subtype_Binding
            then
              return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
            end if;
            return Adac.Semantics.procedure_scope_binding_subtype_constraint_at
              (self.semantic_store,
               procedure_entity,
               Positive (binding_index));
          end if;

          return Adac.Compilation.Semantics
            .resolve_predefined_subtype_constraint (self, symbol);
        end;

      when Adac.AST.Selected_Name_Node =>
        declare
          prefix : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.name_prefix (self, subtype_mark);
        begin
          if Adac.Compilation.Syntax.kind_of (self, prefix) /=
            Adac.AST.Identifier_Name_Node
          then
            return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
          end if;

          declare
            package_symbol : constant Adac.Symbols.Symbol_ID :=
              Adac.Compilation.Syntax.identifier_symbol (self, prefix);
            package_binding : constant Natural :=
              Adac.Semantics.procedure_scope_binding_index_for_symbol
                (self.semantic_store,
                 procedure_entity,
                 self.symbol_store,
                 package_symbol);
          begin
            if package_binding /= 0 and then
               package_binding < before_binding
            then
              return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
            end if;

            return Adac.Compilation.Semantics
              .resolve_predefined_subtype_constraint
                (self,
               package_symbol,
               Adac.Compilation.Syntax.selector_symbol (self, subtype_mark));
          end;
        end;

      when others =>
        return Adac.Semantics.NO_SUBTYPE_CONSTRAINT;
    end case;
  end resolve_stored_supported_subtype_constraint;

  procedure validate
    (self   : Context;
     entity : Adac.Semantics.Entity_ID)
  is
    declaration : Adac.AST.Node_ID;
    entity_kind : Adac.Semantics.Entity_Kind;
  begin
    Adac.Compilation.validate (self);
    Adac.Semantics.validate (self.semantic_store, entity);

    declaration := Adac.Semantics.declaration (self.semantic_store, entity);
    entity_kind := Adac.Semantics.kind_of (self.semantic_store, entity);

    case entity_kind is
      when Adac.Semantics.Object_Entity =>
        Adac.Compilation.Syntax.validate_declaration
          (self, declaration);
        Adac.Compilation.Types.validate
          (self, Adac.Semantics.object_type (self.semantic_store, entity));

        if Adac.Semantics.symbol (self.semantic_store, entity) /=
           Adac.Compilation.Syntax.object_symbol (self, declaration)
        then
          raise Program_Error with
            "Adac.Compilation.Semantics: object symbol does not match AST";
        end if;

        if Adac.Compilation.Syntax.object_form (self, declaration) /=
          Adac.AST.Variable_Object_Form
        then
          raise Program_Error with
            "Adac.Compilation.Semantics: object entity is not a variable";
        end if;

        declare
          has_ast_initializer : constant Boolean :=
            Adac.Compilation.Syntax.object_has_initializer
              (self, declaration);
          has_integer_initializer : constant Boolean :=
            Adac.Semantics.object_has_integer_initializer
              (self.semantic_store, entity);
          has_boolean_initializer : constant Boolean :=
            Adac.Semantics.object_has_boolean_initializer
              (self.semantic_store, entity);
          has_semantic_initializer : constant Boolean :=
            has_integer_initializer or else has_boolean_initializer;
          semantic_type : constant Adac.Types.Type_ID :=
            Adac.Semantics.object_type (self.semantic_store, entity);
          constraint : constant Adac.Semantics.Subtype_Constraint :=
            Adac.Semantics.object_subtype_constraint
              (self.semantic_store, entity);
        begin
          Adac.Semantics.validate (constraint);
          if has_ast_initializer /= has_semantic_initializer then
            raise Program_Error with
              "Adac.Compilation.Semantics: object initializer state mismatch";
          end if;
          if has_integer_initializer and then has_boolean_initializer then
            raise Program_Error with
              "Adac.Compilation.Semantics: object has multiple initializers";
          end if;

          if has_integer_initializer then
            validate_integer_initializer
              (self,
               declaration,
               semantic_type,
               Adac.Semantics.object_integer_initializer
                 (self.semantic_store, entity));
            if not Adac.Semantics.subtype_constraint_contains
              (constraint,
               Adac.Semantics.object_integer_initializer
                 (self.semantic_store, entity))
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: object initializer violates " &
                "subtype constraint";
            end if;
          elsif has_boolean_initializer then
            validate_boolean_initializer (self, declaration, semantic_type);
            if constraint /= Adac.Semantics.NO_SUBTYPE_CONSTRAINT then
              raise Program_Error with
                "Adac.Compilation.Semantics: Boolean object has constraint";
            end if;
          elsif Adac.Compilation.Types.kind_of (self, semantic_type) =
            Adac.Types.Boolean_Type and then
            constraint /= Adac.Semantics.NO_SUBTYPE_CONSTRAINT
          then
            raise Program_Error with
              "Adac.Compilation.Semantics: Boolean object has constraint";
          end if;
        end;

      when Adac.Semantics.Procedure_Body_Entity =>
        Adac.Compilation.Syntax.validate_procedure_body (self, declaration);

        if Adac.Semantics.procedure_scope_binding_count
             (self.semantic_store, entity) /=
           Adac.Compilation.Syntax.declaration_count (self, declaration)
        then
          raise Program_Error with
            "Adac.Compilation.Semantics: procedure binding/declaration " &
            "count mismatch";
        end if;

        for index in 1 .. Adac.Semantics.procedure_scope_binding_count
          (self.semantic_store, entity)
        loop
          declare
            binding_symbol : constant Adac.Symbols.Symbol_ID :=
              Adac.Semantics.procedure_scope_binding_symbol_at
                (self.semantic_store, entity, index);
            syntax_declaration : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.declaration_at
                (self, declaration, index);
          begin
            Adac.Compilation.Symbols.validate_symbol (self, binding_symbol);
            if Adac.Semantics.procedure_scope_binding_index_for_symbol
                 (self.semantic_store,
                  entity,
                  self.symbol_store,
                  binding_symbol) /= index
            then
              raise Program_Error with
                "Adac.Compilation.Semantics: procedure scope lookup mismatch";
            end if;

            case Adac.Semantics.procedure_scope_binding_kind_at
              (self.semantic_store, entity, index)
            is
              when Adac.Semantics.Local_Object_Binding =>
                declare
                  binding_local : constant Positive :=
                    Adac.Semantics.procedure_scope_binding_local_at
                      (self.semantic_store, entity, index);
                  local : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, binding_local);
                  subtype_mark : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.object_subtype_mark
                      (self, syntax_declaration);
                begin
                  if Adac.Semantics.declaration
                       (self.semantic_store, local) /=
                     syntax_declaration or else
                     Adac.Semantics.symbol (self.semantic_store, local) /=
                       binding_symbol or else
                     Adac.Semantics.procedure_local_for_symbol
                       (self.semantic_store,
                        entity,
                        self.symbol_store,
                        binding_symbol) /= binding_local or else
                     resolve_stored_supported_subtype_mark
                       (self, entity, subtype_mark, index) /=
                       Adac.Semantics.object_type
                         (self.semantic_store, local) or else
                     resolve_stored_supported_subtype_constraint
                       (self, entity, subtype_mark, index) /=
                       Adac.Semantics.object_subtype_constraint
                         (self.semantic_store, local)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: procedure object binding " &
                      "mismatch";
                  end if;
                end;

              when Adac.Semantics.Local_Subtype_Binding =>
                declare
                  subtype_declaration : constant Adac.AST.Node_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_subtype_declaration_at
                        (self.semantic_store, entity, index);
                  subtype_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.procedure_scope_binding_subtype_type_at
                      (self.semantic_store, entity, index);
                  constraint : constant Adac.Semantics.Subtype_Constraint :=
                    Adac.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (self.semantic_store, entity, index);
                  has_constraint : constant Boolean :=
                    Adac.Compilation.Syntax.subtype_declaration_has_constraint
                      (self, subtype_declaration);
                  subtype_mark : Adac.AST.Node_ID;
                begin
                  if subtype_declaration /= syntax_declaration then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: subtype binding " &
                      "declaration mismatch";
                  end if;
                  Adac.Compilation.Syntax.validate_subtype_declaration
                    (self, subtype_declaration);
                  Adac.Compilation.Types.validate (self, subtype_type);
                  Adac.Semantics.validate (constraint);
                  if Adac.Compilation.Syntax.subtype_declaration_symbol
                       (self, subtype_declaration) /= binding_symbol
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: subtype binding syntax " &
                      "mismatch";
                  end if;
                  subtype_mark :=
                    Adac.Compilation.Syntax.subtype_declaration_subtype_mark
                      (self, subtype_declaration);
                  if resolve_stored_supported_subtype_mark
                       (self, entity, subtype_mark, index) /=
                     subtype_type or else
                     Adac.Semantics.procedure_subtype_for_symbol
                       (self.semantic_store,
                        entity,
                        self.symbol_store,
                        binding_symbol) /= subtype_type or else
                     Adac.Semantics.procedure_subtype_constraint_for_symbol
                       (self.semantic_store,
                        entity,
                        self.symbol_store,
                        binding_symbol) /= constraint
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: subtype binding " &
                      "resolution mismatch";
                  end if;

                  declare
                    parent_constraint : constant
                      Adac.Semantics.Subtype_Constraint :=
                        resolve_stored_supported_subtype_constraint
                          (self, entity, subtype_mark, index);
                  begin
                    if has_constraint then
                      if Adac.Semantics.subtype_constraint_category
                           (constraint) /=
                         Adac.Semantics.Signed_Integer_Range_Constraint or else
                         not Adac.Semantics.subtype_constraint_contains
                           (parent_constraint,
                            Adac.Semantics.subtype_constraint_lower_bound
                              (constraint)) or else
                         not Adac.Semantics.subtype_constraint_contains
                           (parent_constraint,
                            Adac.Semantics.subtype_constraint_upper_bound
                              (constraint))
                      then
                        raise Program_Error with
                          "Adac.Compilation.Semantics: constrained subtype " &
                          "metadata mismatch";
                      end if;
                    elsif constraint /= parent_constraint then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: inherited subtype " &
                        "constraint mismatch";
                    end if;
                  end;
                end;

              when Adac.Semantics.Local_Static_Integer_Constant_Binding =>
                declare
                  constant_declaration : constant Adac.AST.Node_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_static_constant_declaration_at
                        (self.semantic_store, entity, index);
                  constant_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_static_constant_type_at
                        (self.semantic_store, entity, index);
                  constraint : constant Adac.Semantics.Subtype_Constraint :=
                    Adac.Semantics
                      .procedure_scope_binding_static_constant_constraint_at
                        (self.semantic_store, entity, index);
                  value : constant Long_Long_Integer :=
                    Adac.Semantics
                      .procedure_scope_binding_static_constant_value_at
                        (self.semantic_store, entity, index);
                  subtype_mark : Adac.AST.Node_ID;
                begin
                  if constant_declaration /= syntax_declaration then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: static constant binding " &
                      "declaration mismatch";
                  end if;
                  Adac.Compilation.Syntax.validate_declaration
                    (self, constant_declaration);
                  Adac.Compilation.Types.validate (self, constant_type);
                  Adac.Semantics.validate (constraint);
                  if Adac.Compilation.Syntax.kind_of
                       (self, constant_declaration) /=
                         Adac.AST.Object_Declaration_Node or else
                     Adac.Compilation.Syntax.object_form
                       (self, constant_declaration) /=
                         Adac.AST.Constant_Object_Form or else
                     not Adac.Compilation.Syntax.object_has_initializer
                       (self, constant_declaration) or else
                     Adac.Compilation.Syntax.object_symbol
                       (self, constant_declaration) /= binding_symbol
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: static constant syntax " &
                      "mismatch";
                  end if;
                  subtype_mark := Adac.Compilation.Syntax.object_subtype_mark
                    (self, constant_declaration);
                  if resolve_stored_supported_subtype_mark
                       (self, entity, subtype_mark, index) /=
                         constant_type or else
                     resolve_stored_supported_subtype_constraint
                       (self, entity, subtype_mark, index) /= constraint or else
                     Adac.Compilation.Types.kind_of (self, constant_type) /=
                       Adac.Types.Signed_Integer_Type or else
                     value < Adac.Compilation.Types.signed_integer_lower_bound
                       (self, constant_type) or else
                     value > Adac.Compilation.Types.signed_integer_upper_bound
                       (self, constant_type) or else
                     not Adac.Semantics.subtype_constraint_contains
                       (constraint, value)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: static constant metadata " &
                      "mismatch";
                  end if;
                  validate_static_integer_expression_syntax
                    (self,
                     Adac.Compilation.Syntax.object_initializer
                       (self, constant_declaration));
                end;

              when Adac.Semantics.Local_Static_Boolean_Constant_Binding =>
                declare
                  constant_declaration : constant Adac.AST.Node_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_static_constant_declaration_at
                        (self.semantic_store, entity, index);
                  constant_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_static_constant_type_at
                        (self.semantic_store, entity, index);
                begin
                  if constant_declaration /= syntax_declaration then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean constant binding " &
                      "declaration mismatch";
                  end if;
                  validate_static_boolean_constant_declaration
                    (self,
                     constant_declaration,
                     binding_symbol,
                     constant_type);
                end;

              when Adac.Semantics.Local_Integer_Number_Binding =>
                declare
                  number_declaration : constant Adac.AST.Node_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_integer_number_declaration_at
                        (self.semantic_store, entity, index);
                  number_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_integer_number_type_at
                      (self.semantic_store, entity, index);
                  number_value : constant Adac.Types.Universal_Integer_Value :=
                    Adac.Semantics
                      .procedure_scope_binding_integer_number_value_at
                        (self.semantic_store, entity, index);
                begin
                  if number_declaration /= syntax_declaration then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: integer named-number " &
                      "declaration mismatch";
                  end if;
                  Adac.Compilation.Syntax.validate_declaration
                    (self, number_declaration);
                  Adac.Compilation.Types.validate (self, number_type);
                  Adac.Types.validate (number_value);
                  if Adac.Compilation.Syntax.kind_of
                       (self, number_declaration) /=
                         Adac.AST.Number_Declaration_Node or else
                     Adac.Compilation.Syntax.number_symbol
                       (self, number_declaration) /= binding_symbol or else
                     number_type /=
                       Adac.Compilation.Types.universal_integer (self) or else
                     Adac.Types.universal_integer_decimal_digits
                       (number_value) >
                       Adac.Compilation.resource_limits
                         (self).maximum_universal_integer_decimal_digits
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: integer named-number " &
                      "metadata mismatch";
                  end if;
                  validate_static_integer_expression_syntax
                    (self,
                     Adac.Compilation.Syntax.number_initializer
                       (self, number_declaration));
                end;

              when Adac.Semantics.Local_Real_Number_Binding =>
                declare
                  number_declaration : constant Adac.AST.Node_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_real_number_declaration_at
                        (self.semantic_store, entity, index);
                  number_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics
                      .procedure_scope_binding_real_number_type_at
                        (self.semantic_store, entity, index);
                  number_value : constant Adac.Types.Universal_Real_Value :=
                    Adac.Semantics
                      .procedure_scope_binding_real_number_value_at
                        (self.semantic_store, entity, index);
                  maximum_component_digits : constant
                    Adac.Resources
                      .Universal_Real_Component_Decimal_Digit_Limit :=
                        Adac.Compilation.resource_limits (self)
                          .maximum_universal_real_component_decimal_digits;
                begin
                  if number_declaration /= syntax_declaration then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: real named-number " &
                      "declaration mismatch";
                  end if;
                  validate_static_real_number_declaration
                    (self, number_declaration, binding_symbol);
                  Adac.Compilation.Types.validate (self, number_type);
                  Adac.Types.validate (number_value);
                  if number_type /=
                       Adac.Compilation.Types.universal_real (self) or else
                     Adac.Types.universal_real_numerator_decimal_digits
                       (number_value) > maximum_component_digits or else
                     Adac.Types.universal_real_denominator_decimal_digits
                       (number_value) > maximum_component_digits
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: real named-number " &
                      "metadata mismatch";
                  end if;
                end;
            end case;
          end;
        end loop;

        if Adac.Semantics.symbol (self.semantic_store, entity) /=
           Adac.Compilation.Syntax.procedure_symbol (self, declaration)
        then
          raise Program_Error with
            "Adac.Compilation.Semantics: procedure symbol does not match AST";
        end if;

        for index in 1 .. Adac.Semantics.procedure_local_count
          (self.semantic_store, entity)
        loop
          declare
            local : constant Adac.Semantics.Entity_ID :=
              Adac.Semantics.procedure_local_at
                (self.semantic_store, entity, index);
          begin
            validate (self, local);
          end;
        end loop;

        if Adac.Semantics.procedure_statement_count
             (self.semantic_store, entity) /=
           Adac.Compilation.Syntax.statement_count (self, declaration)
        then
          raise Program_Error with
            "Adac.Compilation.Semantics: procedure statement count mismatch";
        end if;

        for index in 1 .. Adac.Semantics.procedure_statement_count
          (self.semantic_store, entity)
        loop
          declare
            statement : constant Adac.AST.Node_ID :=
              Adac.Semantics.procedure_statement_syntax
                (self.semantic_store, entity, index);
            canonical_statement : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.statement_at
                (self, declaration, index);
          begin
            if statement /= canonical_statement then
              raise Program_Error with
                "Adac.Compilation.Semantics: procedure statement AST mismatch";
            end if;

            case Adac.Semantics.procedure_statement_kind_at
              (self.semantic_store, entity, index)
            is
              when Adac.Semantics.Null_Procedure_Statement =>
                if Adac.Compilation.Syntax.kind_of (self, statement) /=
                  Adac.AST.Null_Statement_Node
                then
                  raise Program_Error with
                    "Adac.Compilation.Semantics: null statement mismatch";
                end if;

              when Adac.Semantics.Return_Procedure_Statement =>
                if Adac.Compilation.Syntax.kind_of (self, statement) /=
                  Adac.AST.Return_Statement_Node
                then
                  raise Program_Error with
                    "Adac.Compilation.Semantics: return statement mismatch";
                end if;

              when Adac.Semantics.Local_Integer_Static_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  local_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                  integer_value : constant Long_Long_Integer :=
                    Adac.Semantics.assignment_integer_value
                      (self.semantic_store, entity, index);
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                     Adac.Semantics.object_type
                       (self.semantic_store, local_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: assignment type mismatch";
                  end if;

                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, target) /=
                     Adac.Semantics.symbol (self.semantic_store, local_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: assignment target mismatch";
                  end if;

                  validate_static_integer_expression_syntax
                    (self, expression);

                  if integer_value <
                       Adac.Compilation.Types.signed_integer_lower_bound
                         (self, expected_type) or else
                     integer_value >
                       Adac.Compilation.Types.signed_integer_upper_bound
                         (self, expected_type)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: " &
                      "assignment value out of range";
                  end if;
                end;

              when Adac.Semantics.Local_Boolean_Static_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  local_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                       Adac.Compilation.Types.standard_boolean (self) or else
                     expected_type /=
                       Adac.Semantics.object_type
                         (self.semantic_store, local_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean assignment type " &
                      "mismatch";
                  end if;

                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, target) /=
                     Adac.Semantics.symbol (self.semantic_store, local_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean assignment target " &
                      "mismatch";
                  end if;

                  validate_static_boolean_expression_syntax (self, expression);
                end;

              when Adac.Semantics.Local_Boolean_Copy_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  source_local : constant Positive :=
                    Adac.Semantics.assignment_source_local
                      (self.semantic_store, entity, index);
                  target_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  source_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, source_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                  source_definition : constant Natural :=
                    Adac.Semantics.assignment_source_definition_statement
                      (self.semantic_store, entity, index);
                  boolean_value : constant Adac.Types.Boolean_Value :=
                    Adac.Semantics.assignment_boolean_value
                      (self.semantic_store, entity, index);
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                       Adac.Compilation.Types.standard_boolean (self) or else
                     expected_type /=
                       Adac.Semantics.object_type
                         (self.semantic_store, target_entity) or else
                     expected_type /=
                       Adac.Semantics.object_type
                         (self.semantic_store, source_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean copy type mismatch";
                  end if;

                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, target) /=
                     Adac.Semantics.symbol (self.semantic_store, target_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean copy target " &
                      "mismatch";
                  end if;
                  if Adac.Compilation.Syntax.kind_of (self, expression) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, expression) /=
                     Adac.Semantics.symbol (self.semantic_store, source_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean copy source " &
                      "mismatch";
                  end if;

                  if source_definition = 0 then
                    if not Adac.Semantics.object_has_boolean_initializer
                      (self.semantic_store, source_entity) or else
                       Adac.Semantics.object_boolean_initializer
                         (self.semantic_store, source_entity) /= boolean_value
                    then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: Boolean source " &
                        "initializer mismatch";
                    end if;
                  else
                    if source_definition >= index then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: Boolean source " &
                        "definition is not earlier";
                    end if;
                    case Adac.Semantics.procedure_statement_kind_at
                      (self.semantic_store,
                       entity,
                       Positive (source_definition))
                    is
                      when Adac.Semantics.
                             Local_Boolean_Static_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Copy_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Not_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Binary_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_And_Then_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Or_Else_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Expression_Assignment_Statement =>
                        if Adac.Semantics.assignment_target_local
                          (self.semantic_store,
                           entity,
                           Positive (source_definition)) /= source_local or else
                           Adac.Semantics.assignment_boolean_value
                             (self.semantic_store,
                              entity,
                              Positive (source_definition)) /= boolean_value
                        then
                          raise Program_Error with
                            "Adac.Compilation.Semantics: Boolean source " &
                            "definition mismatch";
                        end if;

                      when others =>
                        raise Program_Error with
                          "Adac.Compilation.Semantics: Boolean source " &
                          "definition is not Boolean assignment";
                    end case;
                  end if;
                end;

              when Adac.Semantics.Local_Boolean_Not_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  source_local : constant Positive :=
                    Adac.Semantics.assignment_source_local
                      (self.semantic_store, entity, index);
                  target_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  source_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, source_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                  source_definition : constant Natural :=
                    Adac.Semantics.assignment_source_definition_statement
                      (self.semantic_store, entity, index);
                  boolean_value : constant Adac.Types.Boolean_Value :=
                    Adac.Semantics.assignment_boolean_value
                      (self.semantic_store, entity, index);
                  source_value : constant Adac.Types.Boolean_Value :=
                    boolean_not_value (boolean_value);
                  operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                       Adac.Compilation.Types.standard_boolean (self) or else
                     expected_type /=
                       Adac.Semantics.object_type
                         (self.semantic_store, target_entity) or else
                     expected_type /=
                       Adac.Semantics.object_type
                         (self.semantic_store, source_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean not type mismatch";
                  end if;

                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, target) /=
                     Adac.Semantics.symbol (self.semantic_store, target_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean not target mismatch";
                  end if;
                  if Adac.Compilation.Syntax.kind_of (self, expression) /=
                    Adac.AST.Unary_Operator_Node or else
                     Adac.Compilation.Syntax.unary_operator_spelling
                       (self, expression) /= "not"
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean not expression " &
                      "mismatch";
                  end if;
                  operand := Adac.Compilation.Syntax.unary_operand
                    (self, expression);
                  if Adac.Compilation.Syntax.kind_of (self, operand) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, operand) /=
                     Adac.Semantics.symbol (self.semantic_store, source_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean not source mismatch";
                  end if;

                  if source_definition = 0 then
                    if not Adac.Semantics.object_has_boolean_initializer
                      (self.semantic_store, source_entity) or else
                       Adac.Semantics.object_boolean_initializer
                         (self.semantic_store, source_entity) /= source_value
                    then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: Boolean not source " &
                        "initializer mismatch";
                    end if;
                  else
                    if source_definition >= index then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: Boolean not source " &
                        "definition is not earlier";
                    end if;
                    case Adac.Semantics.procedure_statement_kind_at
                      (self.semantic_store,
                       entity,
                       Positive (source_definition))
                    is
                      when Adac.Semantics.
                             Local_Boolean_Static_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Copy_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Not_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Binary_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_And_Then_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Or_Else_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Expression_Assignment_Statement =>
                        if Adac.Semantics.assignment_target_local
                          (self.semantic_store,
                           entity,
                           Positive (source_definition)) /= source_local or else
                           Adac.Semantics.assignment_boolean_value
                             (self.semantic_store,
                              entity,
                              Positive (source_definition)) /= source_value
                        then
                          raise Program_Error with
                            "Adac.Compilation.Semantics: Boolean not source " &
                            "definition mismatch";
                        end if;

                      when others =>
                        raise Program_Error with
                          "Adac.Compilation.Semantics: Boolean not source " &
                          "definition is not Boolean assignment";
                    end case;
                  end if;
                end;

              when Adac.Semantics.Local_Boolean_Binary_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  left_source_local : constant Positive :=
                    Adac.Semantics.assignment_source_local
                      (self.semantic_store, entity, index);
                  right_source_local : constant Positive :=
                    Adac.Semantics.assignment_right_source_local
                      (self.semantic_store, entity, index);
                  target_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  left_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, left_source_local);
                  right_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, right_source_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                  left_definition : constant Natural :=
                    Adac.Semantics.assignment_source_definition_statement
                      (self.semantic_store, entity, index);
                  right_definition : constant Natural :=
                    Adac.Semantics
                      .assignment_right_source_definition_statement
                        (self.semantic_store, entity, index);
                  operator_kind : constant
                    Adac.Semantics.Boolean_Binary_Operator_Kind :=
                      Adac.Semantics.assignment_boolean_operator
                        (self.semantic_store, entity, index);
                  boolean_value : constant Adac.Types.Boolean_Value :=
                    Adac.Semantics.assignment_boolean_value
                      (self.semantic_store, entity, index);
                  left_operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
                  right_operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;


                  left_value : Adac.Types.Boolean_Value;
                  right_value : Adac.Types.Boolean_Value;
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                       Adac.Compilation.Types.standard_boolean (self) or else
                     expected_type /= Adac.Semantics.object_type
                       (self.semantic_store, target_entity) or else
                     expected_type /= Adac.Semantics.object_type
                       (self.semantic_store, left_entity) or else
                     expected_type /= Adac.Semantics.object_type
                       (self.semantic_store, right_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean binary type " &
                      "mismatch";
                  end if;
                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, target) /=
                     Adac.Semantics.symbol (self.semantic_store, target_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean binary target " &
                      "mismatch";
                  end if;
                  declare
                    syntax_operator :
                      Adac.Semantics.Boolean_Binary_Operator_Kind;
                  begin
                    resolve_boolean_binary_expression_syntax
                      (self,
                       expression,
                       syntax_operator,
                       left_operand,
                       right_operand);
                    if syntax_operator /= operator_kind then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: Boolean binary operator " &
                        "mismatch";
                    end if;
                  end;
                  if Adac.Compilation.Syntax.kind_of (self, left_operand) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, left_operand) /=
                     Adac.Semantics.symbol
                       (self.semantic_store, left_entity) or else
                     Adac.Compilation.Syntax.kind_of (self, right_operand) /=
                       Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, right_operand) /=
                     Adac.Semantics.symbol (self.semantic_store, right_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean binary source " &
                      "mismatch";
                  end if;

                  left_value := stored_boolean_source_value
                    (self,
                     entity,
                     index,
                     left_entity,
                     left_source_local,
                     left_definition);
                  right_value := stored_boolean_source_value
                    (self,
                     entity,
                     index,
                     right_entity,
                     right_source_local,
                     right_definition);
                  if boolean_binary_value
                    (operator_kind, left_value, right_value) /= boolean_value
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean binary result " &
                      "mismatch";
                  end if;
                end;

              when Adac.Semantics.Local_Boolean_And_Then_Assignment_Statement |
                   Adac.Semantics.Local_Boolean_Or_Else_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  statement_kind : constant
                    Adac.Semantics.Procedure_Statement_Kind :=
                      Adac.Semantics.procedure_statement_kind_at
                        (self.semantic_store, entity, index);
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  left_source_local : constant Positive :=
                    Adac.Semantics.assignment_source_local
                      (self.semantic_store, entity, index);
                  right_source_local : constant Positive :=
                    Adac.Semantics.assignment_right_source_local
                      (self.semantic_store, entity, index);
                  target_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  left_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, left_source_local);
                  right_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, right_source_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                  left_definition : constant Natural :=
                    Adac.Semantics.assignment_source_definition_statement
                      (self.semantic_store, entity, index);
                  right_definition : constant Natural :=
                    Adac.Semantics
                      .assignment_right_source_definition_statement
                        (self.semantic_store, entity, index);
                  boolean_value : constant Adac.Types.Boolean_Value :=
                    Adac.Semantics.assignment_boolean_value
                      (self.semantic_store, entity, index);
                  known_operator : Adac.Semantics.Boolean_Binary_Operator_Kind;
                  left_value : Adac.Types.Boolean_Value;
                  right_value : Adac.Types.Boolean_Value;
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                       Adac.Compilation.Types.standard_boolean (self) or else
                     expected_type /= Adac.Semantics.object_type
                       (self.semantic_store, target_entity) or else
                     expected_type /= Adac.Semantics.object_type
                       (self.semantic_store, left_entity) or else
                     expected_type /= Adac.Semantics.object_type
                       (self.semantic_store, right_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean short-circuit type " &
                      "mismatch";
                  end if;
                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                       Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol (self, target) /=
                       Adac.Semantics.symbol
                         (self.semantic_store, target_entity) or else
                     Adac.Compilation.Syntax.kind_of (self, expression) /=
                       Adac.AST.Short_Circuit_Expression_Node
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean short-circuit target " &
                      "or expression mismatch";
                  end if;

                  declare
                    syntax_operator : constant
                      Adac.AST.Short_Circuit_Operator_Kind :=
                        Adac.Compilation.Syntax.short_circuit_operator
                          (self, expression);
                    left_operand : constant Adac.AST.Node_ID :=
                      Adac.Compilation.Syntax.short_circuit_left_operand
                        (self, expression);
                    right_operand : constant Adac.AST.Node_ID :=
                      Adac.Compilation.Syntax.short_circuit_right_operand
                        (self, expression);
                  begin
                    if (statement_kind =
                          Adac.Semantics
                            .Local_Boolean_And_Then_Assignment_Statement
                        and then syntax_operator /=
                          Adac.AST.And_Then_Short_Circuit_Operator) or else
                       (statement_kind =
                          Adac.Semantics
                            .Local_Boolean_Or_Else_Assignment_Statement
                        and then syntax_operator /=
                          Adac.AST.Or_Else_Short_Circuit_Operator) or else
                       Adac.Compilation.Syntax.kind_of (self, left_operand) /=
                         Adac.AST.Identifier_Name_Node or else
                       Adac.Compilation.Syntax.identifier_symbol
                         (self, left_operand) /=
                         Adac.Semantics.symbol
                           (self.semantic_store, left_entity) or else
                       Adac.Compilation.Syntax.kind_of (self, right_operand) /=
                         Adac.AST.Identifier_Name_Node or else
                       Adac.Compilation.Syntax.identifier_symbol
                         (self, right_operand) /=
                         Adac.Semantics.symbol
                           (self.semantic_store, right_entity)
                    then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: Boolean short-circuit " &
                        "source mismatch";
                    end if;
                  end;

                  left_value := stored_boolean_source_value
                    (self,
                     entity,
                     index,
                     left_entity,
                     left_source_local,
                     left_definition);
                  right_value := stored_boolean_source_value
                    (self,
                     entity,
                     index,
                     right_entity,
                     right_source_local,
                     right_definition);
                  if statement_kind =
                       Adac.Semantics.Local_Boolean_And_Then_Assignment_Statement
                  then
                    known_operator := Adac.Semantics.And_Boolean_Binary_Operator;
                  else
                    known_operator := Adac.Semantics.Or_Boolean_Binary_Operator;
                  end if;

                  if boolean_binary_value
                       (known_operator, left_value, right_value) /= boolean_value
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean short-circuit result " &
                      "mismatch";
                  end if;
                end;

              when Adac.Semantics.
                     Local_Boolean_Expression_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  target_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                  value_count : constant Natural :=
                    Adac.Semantics.assignment_boolean_expression_value_count
                      (self.semantic_store, entity, index);
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                       Adac.Compilation.Types.standard_boolean (self) or else
                     expected_type /= Adac.Semantics.object_type
                       (self.semantic_store, target_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean expression type " &
                      "mismatch";
                  end if;
                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                       Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol (self, target) /=
                       Adac.Semantics.symbol
                         (self.semantic_store, target_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean expression target " &
                      "mismatch";
                  end if;
                  if value_count = 0 then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean expression is empty";
                  end if;

                  for value_index in 1 .. value_count loop
                    declare
                      value_kind : constant
                        Adac.Semantics.Boolean_Expression_Value_Kind :=
                          Adac.Semantics
                            .assignment_boolean_expression_value_kind
                              (self.semantic_store,
                               entity,
                               index,
                               value_index);
                      value_syntax : constant Adac.AST.Node_ID :=
                        Adac.Semantics.assignment_boolean_expression_syntax
                          (self.semantic_store, entity, index, value_index);
                      known_value : constant Adac.Types.Boolean_Value :=
                        Adac.Semantics
                          .assignment_boolean_expression_known_value
                            (self.semantic_store,
                             entity,
                             index,
                             value_index);
                    begin
                      Adac.Compilation.Syntax.validate_expression
                        (self, value_syntax);
                      case value_kind is
                        when Adac.Semantics.Boolean_Expression_Constant_Value =>
                          validate_static_boolean_expression_syntax
                            (self, value_syntax);

                        when Adac.Semantics.Boolean_Expression_Local_Value =>
                          declare
                            source_local : constant Positive :=
                              Adac.Semantics
                                .assignment_boolean_expression_source_local
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   value_index);
                            source_entity : constant Adac.Semantics.Entity_ID :=
                              Adac.Semantics.procedure_local_at
                                (self.semantic_store, entity, source_local);
                            source_definition : constant Natural :=
                              Adac.Semantics
                                .assignment_boolean_expression_source_definition
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   value_index);
                          begin
                            if expected_type /= Adac.Semantics.object_type
                                 (self.semantic_store, source_entity) or else
                               Adac.Compilation.Syntax.kind_of
                                 (self, value_syntax) /=
                                   Adac.AST.Identifier_Name_Node or else
                               Adac.Compilation.Syntax.identifier_symbol
                                 (self, value_syntax) /=
                                   Adac.Semantics.symbol
                                     (self.semantic_store, source_entity)
                            then
                              raise Program_Error with
                                "Adac.Compilation.Semantics: Boolean " &
                                "expression source mismatch";
                            end if;
                            if stored_boolean_source_value
                              (self,
                               entity,
                               index,
                               source_entity,
                               source_local,
                               source_definition) /= known_value
                            then
                              raise Program_Error with
                                "Adac.Compilation.Semantics: Boolean " &
                                "expression source value mismatch";
                            end if;
                          end;

                        when Adac.Semantics.Boolean_Expression_Not_Value =>
                          declare
                            syntax_root : constant Adac.AST.Node_ID :=
                              unparenthesized_expression (self, value_syntax);
                            operand_index : constant Positive :=
                              Adac.Semantics
                                .assignment_boolean_expression_operand
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   value_index);
                            operand_syntax : constant Adac.AST.Node_ID :=
                              Adac.Semantics
                                .assignment_boolean_expression_syntax
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   operand_index);
                            operand_value : constant Adac.Types.Boolean_Value :=
                              Adac.Semantics
                                .assignment_boolean_expression_known_value
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   operand_index);
                          begin
                            if Adac.Compilation.Syntax.kind_of
                                 (self, syntax_root) /=
                                   Adac.AST.Unary_Operator_Node or else
                               Adac.Compilation.Syntax.unary_operator_spelling
                                 (self, syntax_root) /= "not" or else
                               unparenthesized_expression
                                 (self,
                                  Adac.Compilation.Syntax.unary_operand
                                    (self, syntax_root)) /=
                               unparenthesized_expression
                                 (self, operand_syntax) or else
                               boolean_not_value (operand_value) /= known_value
                            then
                              raise Program_Error with
                                "Adac.Compilation.Semantics: Boolean " &
                                "expression not mismatch";
                            end if;
                          end;

                        when Adac.Semantics.Boolean_Expression_Binary_Value =>
                          declare
                            syntax_root : constant Adac.AST.Node_ID :=
                              unparenthesized_expression (self, value_syntax);
                            operator_kind : constant
                              Adac.Semantics.Boolean_Binary_Operator_Kind :=
                                Adac.Semantics
                                  .assignment_boolean_expression_operator
                                    (self.semantic_store,
                                     entity,
                                     index,
                                     value_index);
                            left_index : constant Positive :=
                              Adac.Semantics
                                .assignment_boolean_expression_operand
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   value_index);
                            right_index : constant Positive :=
                              Adac.Semantics
                                .assignment_boolean_expression_right_operand
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   value_index);
                            left_syntax : constant Adac.AST.Node_ID :=
                              Adac.Semantics
                                .assignment_boolean_expression_syntax
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   left_index);
                            right_syntax : constant Adac.AST.Node_ID :=
                              Adac.Semantics
                                .assignment_boolean_expression_syntax
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   right_index);
                            left_value : constant Adac.Types.Boolean_Value :=
                              Adac.Semantics
                                .assignment_boolean_expression_known_value
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   left_index);
                            right_value : constant Adac.Types.Boolean_Value :=
                              Adac.Semantics
                                .assignment_boolean_expression_known_value
                                  (self.semantic_store,
                                   entity,
                                   index,
                                   right_index);
                            syntax_operator :
                              Adac.Semantics.Boolean_Binary_Operator_Kind;
                            left_operand : Adac.AST.Node_ID;
                            right_operand : Adac.AST.Node_ID;
                          begin
                            resolve_boolean_binary_expression_syntax
                              (self,
                               syntax_root,
                               syntax_operator,
                               left_operand,
                               right_operand);
                            if syntax_operator /= operator_kind or else
                               unparenthesized_expression
                                 (self, left_operand) /=
                               unparenthesized_expression
                                 (self, left_syntax) or else
                               unparenthesized_expression
                                 (self, right_operand) /=
                               unparenthesized_expression
                                 (self, right_syntax) or else
                               boolean_binary_value
                                 (operator_kind, left_value, right_value) /=
                                   known_value
                            then
                              raise Program_Error with
                                "Adac.Compilation.Semantics: Boolean " &
                                "expression binary mismatch";
                            end if;
                          end;
                      end case;
                    end;
                  end loop;

                  if unparenthesized_expression
                       (self,
                        Adac.Semantics.assignment_boolean_expression_syntax
                          (self.semantic_store, entity, index, value_count)) /=
                     unparenthesized_expression (self, expression) or else
                     Adac.Semantics.assignment_boolean_expression_known_value
                       (self.semantic_store, entity, index, value_count) /=
                     Adac.Semantics.assignment_boolean_value
                       (self.semantic_store, entity, index)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: Boolean expression root " &
                      "mismatch";
                  end if;
                end;

              when Adac.Semantics.Local_Integer_Copy_Assignment_Statement =>
                Adac.Compilation.Syntax.validate_assignment_statement
                  (self, statement);

                declare
                  target_local : constant Positive :=
                    Adac.Semantics.assignment_target_local
                      (self.semantic_store, entity, index);
                  source_local : constant Positive :=
                    Adac.Semantics.assignment_source_local
                      (self.semantic_store, entity, index);
                  target_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, target_local);
                  source_entity : constant Adac.Semantics.Entity_ID :=
                    Adac.Semantics.procedure_local_at
                      (self.semantic_store, entity, source_local);
                  expected_type : constant Adac.Types.Type_ID :=
                    Adac.Semantics.assignment_expected_type
                      (self.semantic_store, entity, index);
                  target : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_target
                      (self, statement);
                  expression : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.assignment_expression
                      (self, statement);
                  source_definition : constant Natural :=
                    Adac.Semantics.assignment_source_definition_statement
                      (self.semantic_store, entity, index);
                  integer_value : constant Long_Long_Integer :=
                    Adac.Semantics.assignment_integer_value
                      (self.semantic_store, entity, index);
                begin
                  Adac.Compilation.Types.validate (self, expected_type);
                  if expected_type /=
                       Adac.Semantics.object_type
                         (self.semantic_store, target_entity) or else
                     expected_type /=
                       Adac.Semantics.object_type
                         (self.semantic_store, source_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: " &
                      "copy assignment type mismatch";
                  end if;

                  if not Adac.Semantics.subtype_constraint_contains
                    (Adac.Semantics.object_subtype_constraint
                       (self.semantic_store, target_entity),
                     integer_value)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: " &
                      "copy value violates target " &
                      "subtype constraint";
                  end if;

                  if Adac.Compilation.Syntax.kind_of (self, target) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, target) /=
                     Adac.Semantics.symbol (self.semantic_store, target_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: copy target mismatch";
                  end if;

                  if Adac.Compilation.Syntax.kind_of (self, expression) /=
                    Adac.AST.Identifier_Name_Node or else
                     Adac.Compilation.Syntax.identifier_symbol
                       (self, expression) /=
                     Adac.Semantics.symbol (self.semantic_store, source_entity)
                  then
                    raise Program_Error with
                      "Adac.Compilation.Semantics: copy source mismatch";
                  end if;

                  if source_definition = 0 then
                    if not Adac.Semantics.object_has_integer_initializer
                      (self.semantic_store, source_entity) or else
                       Adac.Semantics.object_integer_initializer
                         (self.semantic_store, source_entity) /= integer_value
                    then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: " &
                        "copy source definition mismatch";
                    end if;
                  else
                    if source_definition >= index then
                      raise Program_Error with
                        "Adac.Compilation.Semantics: " &
                        "copy source definition is not earlier";
                    end if;

                    case Adac.Semantics.procedure_statement_kind_at
                      (self.semantic_store,
                       entity,
                       Positive (source_definition))
                    is
                      when Adac.Semantics.
                             Local_Integer_Static_Assignment_Statement |
                           Adac.Semantics.
                             Local_Integer_Copy_Assignment_Statement =>
                        if Adac.Semantics.assignment_target_local
                          (self.semantic_store,
                           entity,
                           Positive (source_definition)) /= source_local or else
                           Adac.Semantics.assignment_integer_value
                             (self.semantic_store,
                              entity,
                              Positive (source_definition)) /= integer_value
                        then
                          raise Program_Error with
                            "Adac.Compilation.Semantics: " &
                            "copy source definition target mismatch";
                        end if;

                      when Adac.Semantics.Null_Procedure_Statement |
                           Adac.Semantics.Return_Procedure_Statement |
                           Adac.Semantics.
                             Local_Boolean_Static_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Copy_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Not_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Binary_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_And_Then_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Or_Else_Assignment_Statement |
                           Adac.Semantics.
                             Local_Boolean_Expression_Assignment_Statement =>
                        raise Program_Error with
                          "Adac.Compilation.Semantics: " &
                          "copy source definition is not an Integer " &
                          "assignment";
                    end case;
                  end if;
                end;
            end case;
          end;
        end loop;
    end case;

    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.Semantics.symbol (self.semantic_store, entity));
    Adac.Compilation.Sources.validate_span
      (self, Adac.Semantics.entity_span (self.semantic_store, entity));

    if Adac.Semantics.entity_span (self.semantic_store, entity) /=
       Adac.Compilation.Syntax.node_span (self, declaration)
    then
      raise Program_Error with
        "Adac.Compilation.Semantics: entity span does not match AST";
    end if;
  end validate;

end Adac.Compilation.Semantics;
