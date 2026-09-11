-- ============================================================================
-- adac-ast.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;
with Ada.Containers;

with Adac.Resources;

package body Adac.AST is

  use type Ada.Containers.Count_Type;
  use type Adac.Source.Position;
  use type Adac.Source.Span;
  use type Adac.Symbols.Symbol_ID;

  package Structural_Validation renames Validation_Implementation;

  procedure validate_store (self : Store) is
  begin
    if not self.initialized then
      raise Program_Error with "Adac.AST: store is not initialized";
    end if;
  end validate_store;

  procedure validate_node_id
    (self : Store;
     node : Node_ID)
  is
  begin
    validate_store (self);
    validate (node);

    if node.owner /= self.marker'Unchecked_Access then
      raise Program_Error with "Adac.AST: node belongs to another store";
    end if;

    if node.index > Natural(self.nodes.length) then
      raise Program_Error with "Adac.AST: node identifier is out of range";
    end if;
  end validate_node_id;

  function next_node_id (self : Store) return Node_ID is
  begin
    if self.nodes.length >= Ada.Containers.Count_Type(Positive'Last) then
      raise Storage_Error with "Adac.AST: node capacity exhausted";
    end if;

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length) + 1);
  end next_node_id;

  procedure require_node_capacity
    (self          : Store;
     maximum_nodes : Natural)
  is
  begin
    if Natural(self.nodes.length) >= maximum_nodes then
      raise Adac.Resources.Limit_Exceeded with
        "Adac.AST: node limit exceeded";
    end if;
  end require_node_capacity;

  procedure validate_numeric_literal_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);

    if spelling'length = 0 then
      raise Program_Error with "Adac.AST: numeric literal spelling is empty";
    end if;

    first := Adac.Source.first_position (span);
    last  := Adac.Source.last_position (span);

    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'length
    then
      raise Program_Error with
        "Adac.AST: numeric literal span does not match spelling";
    end if;
  end validate_numeric_literal_shape;

  procedure validate_character_literal_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first        : Adac.Source.Position;
    last         : Adac.Source.Position;
    middle_index : Positive;
  begin
    Adac.Source.validate (span);

    if spelling'Length /= 3 or else
       spelling(spelling'First) /= ''' or else
       spelling(spelling'Last) /= '''
    then
      raise Program_Error with
        "Adac.AST: invalid character literal spelling";
    end if;

    middle_index := spelling'First + 1;
    if spelling(middle_index) < ' ' or else spelling(middle_index) > '~' then
      raise Program_Error with
        "Adac.AST: invalid character literal spelling";
    end if;

    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);

    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'Length
    then
      raise Program_Error with
        "Adac.AST: character literal span does not match spelling";
    end if;
  end validate_character_literal_shape;

  procedure validate_string_literal_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);

    if spelling'length < 2 or else
       spelling(spelling'first) /= '"' or else
       spelling(spelling'last) /= '"'
    then
      raise Program_Error with
        "Adac.AST: invalid string literal spelling";
    end if;

    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);

    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'length
    then
      raise Program_Error with
        "Adac.AST: string literal span does not match spelling";
    end if;
  end validate_string_literal_shape;

  procedure validate_unary_operator_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);

    if spelling /= "+" and then
       spelling /= "-" and then
       Ada.Characters.Handling.to_lower (spelling) /= "not" and then
       Ada.Characters.Handling.to_lower (spelling) /= "abs"
    then
      raise Program_Error with
        "Adac.AST: invalid unary operator spelling";
    end if;

    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);

    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'length
    then
      raise Program_Error with
        "Adac.AST: unary operator span does not match spelling";
    end if;
  end validate_unary_operator_shape;

  procedure validate_binary_exponentiating_operator_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);

    if spelling /= "**" then
      raise Program_Error with
        "Adac.AST: invalid binary-exponentiating operator spelling";
    end if;

    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);
    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'length
    then
      raise Program_Error with
        "Adac.AST: binary-exponentiating operator span does not match spelling";
    end if;
  end validate_binary_exponentiating_operator_shape;

  procedure validate_binary_multiplying_operator_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first      : Adac.Source.Position;
    last       : Adac.Source.Position;
    normalized : constant String := Ada.Characters.Handling.to_lower (spelling);
  begin
    Adac.Source.validate (span);

    if normalized /= "*" and then
       normalized /= "/" and then
       normalized /= "mod" and then
       normalized /= "rem"
    then
      raise Program_Error with
        "Adac.AST: invalid binary-multiplying operator spelling";
    end if;

    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);
    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'length
    then
      raise Program_Error with
        "Adac.AST: binary-multiplying operator span does not match spelling";
    end if;
  end validate_binary_multiplying_operator_shape;

  procedure validate_binary_adding_operator_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);

    if spelling /= "+" and then spelling /= "-" and then spelling /= "&" then
      raise Program_Error with
        "Adac.AST: invalid binary-adding operator spelling";
    end if;

    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);

    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'length
    then
      raise Program_Error with
        "Adac.AST: binary-adding operator span does not match spelling";
    end if;
  end validate_binary_adding_operator_shape;

  procedure validate_relation_operator_shape
    (spelling : String;
     span     : Adac.Source.Span)
  is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);

    if spelling /= "=" and then
       spelling /= "/=" and then
       spelling /= "<" and then
       spelling /= "<=" and then
       spelling /= ">" and then
       spelling /= ">="
    then
      raise Program_Error with
        "Adac.AST: invalid relational operator spelling";
    end if;

    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);

    if first.line /= last.line or else
       last.column - first.column + 1 /= spelling'length
    then
      raise Program_Error with
        "Adac.AST: relational operator span does not match spelling";
    end if;
  end validate_relation_operator_shape;

  procedure validate_double_dot_span (span : Adac.Source.Span) is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);
    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);
    if first.line /= last.line or else last.column /= first.column + 1 then
      raise Program_Error with
        "Adac.AST: double-dot span does not cover exactly two columns";
    end if;
  end validate_double_dot_span;

  procedure validate_all_span (span : Adac.Source.Span) is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);
    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);
    if first.line /= last.line or else last.column /= first.column + 2 then
      raise Program_Error with
        "Adac.AST: all span does not cover exactly three columns";
    end if;
  end validate_all_span;

  procedure validate_new_span (span : Adac.Source.Span) is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);
    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);
    if first.line /= last.line or else last.column /= first.column + 2 then
      raise Program_Error with
        "Adac.AST: new span does not cover exactly three columns";
    end if;
  end validate_new_span;

  procedure validate_when_span (span : Adac.Source.Span) is
    first : Adac.Source.Position;
    last  : Adac.Source.Position;
  begin
    Adac.Source.validate (span);
    first := Adac.Source.first_position (span);
    last := Adac.Source.last_position (span);
    if first.line /= last.line or else last.column /= first.column + 3 then
      raise Program_Error with
        "Adac.AST: when span does not cover exactly four columns";
    end if;
  end validate_when_span;

  function is_simple_name_kind (kind : Node_Kind) return Boolean is
  begin
    return kind = Identifier_Name_Node or else kind = Selected_Name_Node;
  end is_simple_name_kind;

  function is_current_name_kind (kind : Node_Kind) return Boolean is
  begin
    return is_simple_name_kind (kind) or else
      kind = Explicit_Dereference_Name_Node or else
      kind = Selected_Component_Node or else
      kind = Parenthesized_Name_Node or else
      kind = Slice_Name_Node or else
      kind = Attribute_Name_Node;
  end is_current_name_kind;

  function is_current_parenthesized_prefix_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return is_simple_name_kind (kind) or else
      kind = Explicit_Dereference_Name_Node or else
      kind = Selected_Component_Node or else
      kind = Parenthesized_Name_Node or else
      kind = Attribute_Name_Node;
  end is_current_parenthesized_prefix_kind;

  function is_current_slice_prefix_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return is_simple_name_kind (kind) or else kind = Attribute_Name_Node;
  end is_current_slice_prefix_kind;

  function is_current_parenthesized_item_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return is_current_name_kind (kind) or else
      kind = Numeric_Literal_Node or else
      kind = Character_Literal_Node or else
      kind = Binary_Adding_Node or else
      kind = String_Literal_Node;
  end is_current_parenthesized_item_kind;

  procedure require_current_parenthesized_item
    (self : Store;
     item : Node_ID)
  is
    pending    : Node_List;
    next_index : Natural := 1;
  begin
    validate_node_id (self, item);
    if is_current_name_kind (self.nodes(Positive(item.index)).kind) then
      return;
    end if;
    if not is_current_parenthesized_item_kind
      (self.nodes(Positive(item.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: node is not a current parenthesized-name item";
    end if;

    append (pending, item);
    while next_index <= list_count (pending) loop
      declare
        current : constant Node_ID :=
          list_element (pending, Positive(next_index));
        kind : Node_Kind;
      begin
        next_index := next_index + 1;
        validate_node_id (self, current);
        kind := self.nodes(Positive(current.index)).kind;
        case kind is
          when Binary_Adding_Node =>
            append
              (pending,
               self.nodes
                 (Positive(current.index)).binary_adding_left_operand_value);
            append
              (pending,
               self.nodes
                 (Positive(current.index)).binary_adding_right_operand_value);

          when Binary_Multiplying_Node =>
            append
              (pending,
               self.nodes(Positive(current.index)).
                 binary_multiplying_left_operand_value);
            append
              (pending,
               self.nodes(Positive(current.index)).
                 binary_multiplying_right_operand_value);

          when Unary_Operator_Node =>
            append
              (pending,
               self.nodes(Positive(current.index)).unary_operand_value);

          when Binary_Exponentiating_Node =>
            append
              (pending,
               self.nodes(Positive(current.index)).
                 binary_exponentiating_left_operand_value);
            append
              (pending,
               self.nodes(Positive(current.index)).
                 binary_exponentiating_right_operand_value);

          when Parenthesized_Name_Node =>
            declare
              value : Node renames self.nodes(Positive(current.index));
            begin
              validate_node_id (self, value.parenthesized_prefix);
              if not is_current_parenthesized_prefix_kind
                (self.nodes(Positive(value.parenthesized_prefix.index)).kind)
              then
                raise Program_Error with
                  "Adac.AST: nested parenthesized-name binary operand has " &
                  "the wrong prefix kind";
              end if;
              if value.parenthesized_prefix.index >= current.index then
                raise Program_Error with
                  "Adac.AST: nested parenthesized-name prefix is not earlier";
              end if;
              if value.parenthesized_items.is_empty then
                raise Program_Error with
                  "Adac.AST: nested parenthesized-name item list is empty";
              end if;

              append (pending, value.parenthesized_prefix);
              for association of value.parenthesized_items loop
                if association.form = Named_Parenthesized_Name_Item_Form then
                  validate_node_id (self, association.selector);
                  if self.nodes(Positive(association.selector.index)).kind /=
                     Identifier_Name_Node or else
                     association.selector.index >= current.index
                  then
                    raise Program_Error with
                      "Adac.AST: nested parenthesized-name selector is invalid";
                  end if;
                  append (pending, association.selector);
                end if;

                validate_node_id (self, association.actual);
                if association.actual.index >= current.index then
                  raise Program_Error with
                    "Adac.AST: nested parenthesized-name actual is not earlier";
                end if;
                if not is_current_name_kind
                  (self.nodes(Positive(association.actual.index)).kind) and then
                   self.nodes(Positive(association.actual.index)).kind not in
                     Numeric_Literal_Node |
                     Character_Literal_Node |
                     String_Literal_Node
                then
                  raise Program_Error with
                    "Adac.AST: nested parenthesized-name binary operand owns " &
                    "an expression actual";
                end if;
                append (pending, association.actual);
              end loop;
            end;

          when Attribute_Name_Node =>
            validate_node_id
              (self, self.nodes(Positive(current.index)).attribute_prefix);
            if not is_simple_name_kind
              (self.nodes
                 (Positive
                    (self.nodes
                       (Positive(current.index)).attribute_prefix.index)).kind)
            then
              raise Program_Error with
                "Adac.AST: parenthesized-name binary item has a " &
                "non-simple attribute prefix";
            end if;

          when Numeric_Literal_Node |
               Character_Literal_Node |
               String_Literal_Node |
               Null_Literal_Node |
               Identifier_Name_Node |
               Selected_Name_Node =>
            null;

          when others =>
            raise Program_Error with
              "Adac.AST: parenthesized-name binary item exceeds " &
              "the current bounded subset";
        end case;
      end;
    end loop;
  end require_current_parenthesized_item;

  function is_current_direct_expression_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return kind = Numeric_Literal_Node or else
      kind = Character_Literal_Node or else
      kind = String_Literal_Node or else
      kind = Null_Literal_Node or else
      kind = Record_Aggregate_Node or else
      kind = Array_Aggregate_Node or else
      kind = Bracket_Aggregate_Node or else
      kind = Qualified_Expression_Node or else
      kind = Allocator_Node or else
      kind = Parenthesized_Expression_Node or else
      is_current_name_kind (kind);
  end is_current_direct_expression_kind;

  function is_current_qualified_operand_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return kind = Numeric_Literal_Node or else
      kind = Character_Literal_Node or else
      kind = String_Literal_Node or else
      kind = Null_Literal_Node or else
      kind = Identifier_Name_Node or else
      kind = Selected_Name_Node or else
      kind = Selected_Component_Node or else
      kind = Parenthesized_Name_Node or else
      kind = Attribute_Name_Node or else
      kind = Parenthesized_Expression_Node;
  end is_current_qualified_operand_kind;

  function is_current_factor_expression_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return is_current_direct_expression_kind (kind) or else
      kind = Unary_Operator_Node or else
      kind = Binary_Exponentiating_Node;
  end is_current_factor_expression_kind;

  function is_current_term_expression_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return is_current_factor_expression_kind (kind) or else
      kind = Binary_Multiplying_Node;
  end is_current_term_expression_kind;

  function is_current_simple_expression_kind
    (kind : Node_Kind)
  return Boolean is
  begin
    return is_current_term_expression_kind (kind) or else
      kind = Binary_Adding_Node;
  end is_current_simple_expression_kind;

  function is_current_expression_kind (kind : Node_Kind) return Boolean is
  begin
    return is_current_simple_expression_kind (kind) or else
      kind = Relation_Node or else
      kind = Membership_Expression_Node or else
      kind = Logical_Expression_Node or else
      kind = Short_Circuit_Expression_Node;
  end is_current_expression_kind;

  procedure require_nonaggregate_simple_expression
    (self       : Store;
     expression : Node_ID)
  is
    pending    : Node_List;
    next_index : Natural := 1;
    root_kind  : Node_Kind;

    procedure append_earlier_child
      (parent : Node_ID;
       child  : Node_ID)
    is
    begin
      validate_node_id (self, child);
      if child.index >= parent.index then
        raise Program_Error with
          "Adac.AST: nonaggregate expression child is not earlier";
      end if;
      append (pending, child);
    end append_earlier_child;
  begin
    validate_node_id (self, expression);
    root_kind := self.nodes(Positive(expression.index)).kind;
    if not is_current_simple_expression_kind (root_kind) or else
       root_kind = Record_Aggregate_Node or else
       root_kind = Array_Aggregate_Node or else
       root_kind = Qualified_Expression_Node
    then
      raise Program_Error with
        "Adac.AST: expression is not a " &
        "nonaggregate simple expression";
    end if;

    append (pending, expression);
    while next_index <= list_count (pending) loop
      declare
        current : constant Node_ID :=
          list_element (pending, Positive(next_index));
      begin
        next_index := next_index + 1;
        validate_node_id (self, current);
        declare
          current_value : Node renames self.nodes(Positive(current.index));
        begin
          case current_value.kind is
            when Record_Aggregate_Node |
                 Array_Aggregate_Node |
                 Qualified_Expression_Node =>
              raise Program_Error with
                "Adac.AST: aggregate value contains nested aggregate syntax";

            when Numeric_Literal_Node |
                 Character_Literal_Node |
                 String_Literal_Node |
                 Null_Literal_Node |
                 Identifier_Name_Node |
                 Selected_Name_Node |
                 Explicit_Dereference_Name_Node |
                 Selected_Component_Node |
                 Parenthesized_Name_Node |
                 Attribute_Name_Node =>
              null;

            when Parenthesized_Expression_Node =>
              append_earlier_child
                (current,
                 current_value.parenthesized_expression_child_value);

            when Unary_Operator_Node =>
              append_earlier_child
                (current, current_value.unary_operand_value);

            when Binary_Exponentiating_Node =>
              append_earlier_child
                (current,
                 current_value.binary_exponentiating_left_operand_value);
              append_earlier_child
                (current,
                 current_value.binary_exponentiating_right_operand_value);

            when Binary_Multiplying_Node =>
              append_earlier_child
                (current,
                 current_value.binary_multiplying_left_operand_value);
              append_earlier_child
                (current,
                 current_value.binary_multiplying_right_operand_value);

            when Binary_Adding_Node =>
              append_earlier_child
                (current,
                 current_value.binary_adding_left_operand_value);
              append_earlier_child
                (current,
                 current_value.binary_adding_right_operand_value);

            when Relation_Node =>
              append_earlier_child
                (current,
                 current_value.relation_left_operand_value);
              append_earlier_child
                (current,
                 current_value.relation_right_operand_value);

            when Logical_Expression_Node =>
              append_earlier_child
                (current, current_value.logical_left_operand_value);
              append_earlier_child
                (current, current_value.logical_right_operand_value);

            when Short_Circuit_Expression_Node =>
              append_earlier_child
                (current,
                 current_value.short_circuit_left_operand_value);
              append_earlier_child
                (current,
                 current_value.short_circuit_right_operand_value);

            when If_Expression_Node =>
              append_earlier_child
                (current,
                 current_value.if_expression_condition_value);
              append_earlier_child
                (current,
                 current_value.if_expression_then_value);
              append_earlier_child
                (current,
                 current_value.if_expression_else_value);

            when Case_Expression_Node =>
              append_earlier_child
                (current,
                 current_value.case_expression_selecting_expression_value);
              for alternative of
                current_value.case_expression_alternatives_value
              loop
                validate_node_id (self, alternative);
                if self.nodes(Positive(alternative.index)).kind /=
                   Case_Expression_Alternative_Node
                then
                  raise Program_Error with
                    "Adac.AST: node is not a case-expression alternative";
                end if;
                if alternative.index >= current.index then
                  raise Program_Error with
                    "Adac.AST: case-expression alternative is not earlier";
                end if;
                append_earlier_child
                  (current,
                   self.nodes(Positive(alternative.index))
                     .case_expression_alternative_expression_value);
              end loop;

            when others =>
              raise Program_Error with
                "Adac.AST: nonaggregate expression contains unsupported syntax";
          end case;
        end;
      end;
    end loop;
  end require_nonaggregate_simple_expression;

  procedure require_record_aggregate_value
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind = Record_Aggregate_Node then
      return;
    end if;

    require_nonaggregate_simple_expression (self, expression);
  end require_record_aggregate_value;

  function precedes
    (left  : Adac.Source.Position;
     right : Adac.Source.Position)
  return Boolean is
  begin
    return left.line < right.line or else
      (left.line = right.line and then left.column < right.column);
  end precedes;

  procedure require_numeric_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    validate_node_id (self, literal);

    if self.nodes(Positive(literal.index)).kind /= Numeric_Literal_Node then
      raise Program_Error with "Adac.AST: node is not a numeric literal";
    end if;
  end require_numeric_literal;

  procedure require_character_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    validate_node_id (self, literal);

    if self.nodes(Positive(literal.index)).kind /= Character_Literal_Node then
      raise Program_Error with "Adac.AST: node is not a character literal";
    end if;
  end require_character_literal;

  procedure require_string_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    validate_node_id (self, literal);

    if self.nodes(Positive(literal.index)).kind /= String_Literal_Node then
      raise Program_Error with "Adac.AST: node is not a string literal";
    end if;
  end require_string_literal;

  procedure require_null_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    validate_node_id (self, literal);

    if self.nodes(Positive(literal.index)).kind /= Null_Literal_Node then
      raise Program_Error with "Adac.AST: node is not a null literal";
    end if;
  end require_null_literal;

  procedure require_record_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
  begin
    validate_node_id (self, aggregate);

    if self.nodes(Positive(aggregate.index)).kind /= Record_Aggregate_Node then
      raise Program_Error with "Adac.AST: node is not a record aggregate";
    end if;
  end require_record_aggregate;

  procedure require_array_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
  begin
    validate_node_id (self, aggregate);

    if self.nodes(Positive(aggregate.index)).kind /= Array_Aggregate_Node then
      raise Program_Error with "Adac.AST: node is not an array aggregate";
    end if;
  end require_array_aggregate;

  procedure require_bracket_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
  begin
    validate_node_id (self, aggregate);
    if self.nodes(Positive(aggregate.index)).kind /= Bracket_Aggregate_Node then
      raise Program_Error with "Adac.AST: node is not a bracket aggregate";
    end if;
  end require_bracket_aggregate;

  procedure require_qualified_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind /=
       Qualified_Expression_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a qualified expression";
    end if;
  end require_qualified_expression;

  procedure require_allocator
    (self      : Store;
     allocator : Node_ID)
  is
  begin
    validate_node_id (self, allocator);
    if self.nodes(Positive(allocator.index)).kind /= Allocator_Node then
      raise Program_Error with "Adac.AST: node is not an allocator";
    end if;
  end require_allocator;

  procedure require_if_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if self.nodes(Positive(expression.index)).kind /= If_Expression_Node then
      raise Program_Error with "Adac.AST: node is not an if expression";
    end if;
  end require_if_expression;

  procedure require_case_expression_alternative
    (self        : Store;
     alternative : Node_ID)
  is
  begin
    validate_node_id (self, alternative);

    if self.nodes(Positive(alternative.index)).kind /=
       Case_Expression_Alternative_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a case-expression alternative";
    end if;
  end require_case_expression_alternative;

  procedure require_case_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if self.nodes(Positive(expression.index)).kind /= Case_Expression_Node then
      raise Program_Error with "Adac.AST: node is not a case expression";
    end if;
  end require_case_expression;

  procedure require_current_case_expression_choice
    (self   : Store;
     choice : Node_ID)
  is
  begin
    validate_node_id (self, choice);
    case self.nodes(Positive(choice.index)).kind is
      when Identifier_Name_Node |
           Selected_Name_Node |
           Others_Case_Choice_Node =>
        null;
      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current case-expression choice";
    end case;
  end require_current_case_expression_choice;

  procedure require_raise_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if self.nodes(Positive(expression.index)).kind /= Raise_Expression_Node then
      raise Program_Error with "Adac.AST: node is not a raise expression";
    end if;
  end require_raise_expression;

  procedure require_parenthesized_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if self.nodes(Positive(expression.index)).kind /=
         Parenthesized_Expression_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a parenthesized expression";
    end if;
  end require_parenthesized_expression;

  procedure require_current_if_expression_condition
    (self  : Store;
     child : Node_ID)
  is
    kind : Node_Kind;
  begin
    validate_node_id (self, child);
    kind := self.nodes(Positive(child.index)).kind;

    if kind /= Relation_Node and then
       kind /= Short_Circuit_Expression_Node and then
       (kind = Parenthesized_Expression_Node or else
        not is_current_simple_expression_kind (kind))
    then
      raise Program_Error with
        "Adac.AST: node is not a current if-expression condition";
    end if;
  end require_current_if_expression_condition;

  procedure require_current_conditional_expression_child
    (self : Store;
     child : Node_ID)
  is
    kind : Node_Kind;
  begin
    validate_node_id (self, child);
    kind := self.nodes(Positive(child.index)).kind;

    if kind = Parenthesized_Expression_Node or else
       not is_current_simple_expression_kind (kind)
    then
      raise Program_Error with
        "Adac.AST: node is not a current conditional-expression child";
    end if;
  end require_current_conditional_expression_child;

  procedure require_unary_operator
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if self.nodes(Positive(expression.index)).kind /= Unary_Operator_Node then
      raise Program_Error with
        "Adac.AST: node is not a unary operator expression";
    end if;
  end require_unary_operator;

  procedure require_binary_exponentiating
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind /=
       Binary_Exponentiating_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a binary-exponentiating expression";
    end if;
  end require_binary_exponentiating;

  procedure require_binary_multiplying
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind /=
       Binary_Multiplying_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a binary-multiplying expression";
    end if;
  end require_binary_multiplying;

  procedure require_binary_adding
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if self.nodes(Positive(expression.index)).kind /= Binary_Adding_Node then
      raise Program_Error with
        "Adac.AST: node is not a binary-adding expression";
    end if;
  end require_binary_adding;

  procedure require_relation
    (self     : Store;
     relation : Node_ID)
  is
  begin
    validate_node_id (self, relation);

    if self.nodes(Positive(relation.index)).kind /= Relation_Node then
      raise Program_Error with "Adac.AST: node is not a relation";
    end if;
  end require_relation;

  procedure require_case_range_choice
    (self   : Store;
     choice : Node_ID)
  is
  begin
    validate_node_id (self, choice);
    if self.nodes(Positive(choice.index)).kind /= Case_Range_Choice_Node then
      raise Program_Error with "Adac.AST: node is not a case range choice";
    end if;
  end require_case_range_choice;

  procedure require_membership_range_choice
    (self   : Store;
     choice : Node_ID)
  is
  begin
    validate_node_id (self, choice);
    if self.nodes(Positive(choice.index)).kind /=
       Membership_Range_Choice_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a membership range choice";
    end if;
  end require_membership_range_choice;

  procedure require_membership_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind /=
       Membership_Expression_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a membership expression";
    end if;
  end require_membership_expression;

  procedure require_logical_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind /=
       Logical_Expression_Node
    then
      raise Program_Error with "Adac.AST: node is not a logical expression";
    end if;
  end require_logical_expression;

  procedure require_short_circuit_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if self.nodes(Positive(expression.index)).kind /=
       Short_Circuit_Expression_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a short-circuit expression";
    end if;
  end require_short_circuit_expression;

  procedure require_current_direct_expression
    (self    : Store;
     operand : Node_ID)
  is
  begin
    validate_node_id (self, operand);

    if not is_current_direct_expression_kind
      (self.nodes(Positive(operand.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: node is not a current direct expression";
    end if;
  end require_current_direct_expression;

  procedure require_current_factor_expression
    (self    : Store;
     operand : Node_ID)
  is
  begin
    validate_node_id (self, operand);
    if not is_current_factor_expression_kind
      (self.nodes(Positive(operand.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: node is not a current factor expression";
    end if;
  end require_current_factor_expression;

  procedure require_current_term_expression
    (self    : Store;
     operand : Node_ID)
  is
  begin
    validate_node_id (self, operand);
    if not is_current_term_expression_kind
      (self.nodes(Positive(operand.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: node is not a current term expression";
    end if;
  end require_current_term_expression;

  procedure require_current_simple_expression
    (self    : Store;
     operand : Node_ID)
  is
  begin
    validate_node_id (self, operand);

    if not is_current_simple_expression_kind
      (self.nodes(Positive(operand.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: node is not a current simple expression";
    end if;
  end require_current_simple_expression;

  procedure require_current_expression
    (self       : Store;
     expression : Node_ID)
  is
  begin
    validate_node_id (self, expression);

    if not is_current_expression_kind
      (self.nodes(Positive(expression.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: node is not a current represented expression";
    end if;
  end require_current_expression;

  procedure require_simple_name
    (self : Store;
     name : Node_ID)
  is
  begin
    validate_node_id (self, name);

    if not is_simple_name_kind (self.nodes(Positive(name.index)).kind) then
      raise Program_Error with "Adac.AST: node is not a simple name";
    end if;
  end require_simple_name;

  procedure require_parenthesized_name
    (self : Store;
     name : Node_ID)
  is
  begin
    validate_node_id (self, name);

    if self.nodes(Positive(name.index)).kind /= Parenthesized_Name_Node then
      raise Program_Error with "Adac.AST: node is not a parenthesized name";
    end if;
  end require_parenthesized_name;

  procedure require_slice_name
    (self : Store;
     name : Node_ID)
  is
  begin
    validate_node_id (self, name);

    if self.nodes(Positive(name.index)).kind /= Slice_Name_Node then
      raise Program_Error with "Adac.AST: node is not a slice name";
    end if;
  end require_slice_name;

  procedure require_attribute_name
    (self : Store;
     name : Node_ID)
  is
  begin
    validate_node_id (self, name);

    if self.nodes(Positive(name.index)).kind /= Attribute_Name_Node then
      raise Program_Error with "Adac.AST: node is not an attribute name";
    end if;
  end require_attribute_name;

  procedure require_current_name
    (self : Store;
     name : Node_ID)
  is
  begin
    validate_node_id (self, name);

    if not is_current_name_kind (self.nodes(Positive(name.index)).kind) then
      raise Program_Error with "Adac.AST: node is not a current name";
    end if;
  end require_current_name;

  procedure require_aspect_specification
    (self   : Store;
     aspect : Node_ID)
  is
  begin
    validate_node_id (self, aspect);

    if self.nodes(Positive(aspect.index)).kind /= Aspect_Specification_Node then
      raise Program_Error with "Adac.AST: node is not an aspect specification";
    end if;
  end require_aspect_specification;

  procedure require_parameter_specification
    (self      : Store;
     parameter : Node_ID)
  is
  begin
    validate_node_id (self, parameter);

    if self.nodes(Positive(parameter.index)).kind /=
       Parameter_Specification_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a parameter specification";
    end if;
  end require_parameter_specification;

  procedure require_object_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Object_Declaration_Node
    then
      raise Program_Error with "Adac.AST: node is not an object declaration";
    end if;
  end require_object_declaration;

  procedure require_object_renaming_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Object_Renaming_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not an object-renaming declaration";
    end if;
  end require_object_renaming_declaration;

  procedure require_number_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Number_Declaration_Node
    then
      raise Program_Error with "Adac.AST: node is not a number declaration";
    end if;
  end require_number_declaration;

  procedure require_exception_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Exception_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not an exception declaration";
    end if;
  end require_exception_declaration;

  procedure require_procedure_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Procedure_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a procedure declaration";
    end if;
  end require_procedure_declaration;

  procedure require_procedure_body_stub
    (self : Store;
     stub : Node_ID)
  is
  begin
    validate_node_id (self, stub);
    if self.nodes(Positive(stub.index)).kind /= Procedure_Body_Stub_Node then
      raise Program_Error with
        "Adac.AST: node is not a procedure-body stub";
    end if;
  end require_procedure_body_stub;

  procedure require_function_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /= Function_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a function declaration";
    end if;
  end require_function_declaration;

  procedure require_private_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Private_Type_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a private-type declaration";
    end if;
  end require_private_type_declaration;

  procedure require_derived_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);
    if self.nodes(Positive(declaration.index)).kind /=
       Derived_Type_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a derived-type declaration";
    end if;
  end require_derived_type_declaration;

  procedure require_range_constraint
    (self       : Store;
     constraint : Node_ID)
  is
  begin
    validate_node_id (self, constraint);
    if self.nodes(Positive(constraint.index)).kind /= Range_Constraint_Node then
      raise Program_Error with "Adac.AST: node is not a range constraint";
    end if;
  end require_range_constraint;

  procedure require_index_constraint
    (self       : Store;
     constraint : Node_ID)
  is
  begin
    validate_node_id (self, constraint);
    if self.nodes(Positive(constraint.index)).kind /= Index_Constraint_Node then
      raise Program_Error with "Adac.AST: node is not an index constraint";
    end if;
  end require_index_constraint;

  procedure require_subtype_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);
    if self.nodes(Positive(declaration.index)).kind /= Subtype_Declaration_Node
    then
      raise Program_Error with "Adac.AST: node is not a subtype declaration";
    end if;
  end require_subtype_declaration;

  procedure require_enumeration_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Enumeration_Type_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not an enumeration-type declaration";
    end if;
  end require_enumeration_type_declaration;

  procedure require_discriminant_specification
    (self         : Store;
     discriminant : Node_ID)
  is
  begin
    validate_node_id (self, discriminant);
    if self.nodes(Positive(discriminant.index)).kind /=
       Discriminant_Specification_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a discriminant specification";
    end if;
  end require_discriminant_specification;

  procedure require_record_component_declaration
    (self      : Store;
     component : Node_ID)
  is
  begin
    validate_node_id (self, component);

    if self.nodes(Positive(component.index)).kind /=
       Record_Component_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a record-component declaration";
    end if;
  end require_record_component_declaration;

  procedure require_record_variant
    (self    : Store;
     variant : Node_ID)
  is
  begin
    validate_node_id (self, variant);
    if self.nodes(Positive(variant.index)).kind /= Record_Variant_Node then
      raise Program_Error with "Adac.AST: node is not a record variant";
    end if;
  end require_record_variant;

  procedure require_record_variant_part
    (self         : Store;
     variant_part : Node_ID)
  is
  begin
    validate_node_id (self, variant_part);
    if self.nodes(Positive(variant_part.index)).kind /= Record_Variant_Part_Node
    then
      raise Program_Error with "Adac.AST: node is not a record variant part";
    end if;
  end require_record_variant_part;

  procedure require_record_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Record_Type_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a record-type declaration";
    end if;
  end require_record_type_declaration;

  procedure require_access_object_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Access_Object_Type_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not an access-to-object type declaration";
    end if;
  end require_access_object_type_declaration;

  procedure require_with_clause
    (self   : Store;
     clause : Node_ID)
  is
  begin
    validate_node_id (self, clause);

    if self.nodes(Positive(clause.index)).kind /= With_Clause_Node then
      raise Program_Error with "Adac.AST: node is not a with clause";
    end if;
  end require_with_clause;

  procedure require_use_type_clause
    (self   : Store;
     clause : Node_ID)
  is
  begin
    validate_node_id (self, clause);

    if self.nodes(Positive(clause.index)).kind /= Use_Type_Clause_Node then
      raise Program_Error with "Adac.AST: node is not a use-type clause";
    end if;
  end require_use_type_clause;

  procedure require_use_package_clause
    (self   : Store;
     clause : Node_ID)
  is
  begin
    validate_node_id (self, clause);

    if self.nodes(Positive(clause.index)).kind /= Use_Package_Clause_Node then
      raise Program_Error with "Adac.AST: node is not a package-use clause";
    end if;
  end require_use_package_clause;


  procedure validate_current_exception_choice
    (self   : Store;
     choice : Node_ID)
  is
  begin
    validate_node_id (self, choice);
    case self.nodes(Positive(choice.index)).kind is
      when Others_Exception_Choice_Node =>
        Adac.Source.validate (node_span (self, choice));
      when Identifier_Name_Node | Selected_Name_Node =>
        Structural_Validation.validate_name (self, choice);
      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current exception choice";
    end case;
  end validate_current_exception_choice;

  procedure require_exception_handler
    (self    : Store;
     handler : Node_ID)
  is
  begin
    validate_node_id (self, handler);

    if self.nodes(Positive(handler.index)).kind /= Exception_Handler_Node then
      raise Program_Error with "Adac.AST: node is not an exception handler";
    end if;
  end require_exception_handler;

  procedure require_handled_sequence
    (self     : Store;
     sequence : Node_ID)
  is
  begin
    validate_node_id (self, sequence);

    if self.nodes(Positive(sequence.index)).kind /= Handled_Sequence_Node then
      raise Program_Error with "Adac.AST: node is not a handled sequence";
    end if;
  end require_handled_sequence;

  procedure validate_current_handled_statement_shallow
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);

    case self.nodes(Positive(statement.index)).kind is
      when Null_Statement_Node =>
        Adac.Source.validate (self.nodes(Positive(statement.index)).span);
      when Exit_Statement_Node =>
        Structural_Validation.validate_exit_statement (self, statement);
      when Return_Statement_Node =>
        Structural_Validation.validate_return_statement (self, statement);
      when Extended_Return_Statement_Node =>
        Structural_Validation.validate_extended_return_statement
          (self, statement);
      when Assignment_Statement_Node =>
        Structural_Validation.validate_assignment_statement (self, statement);
      when Raise_Statement_Node =>
        Structural_Validation.validate_raise_statement (self, statement);
      when Procedure_Call_Statement_Node =>
        Structural_Validation.validate_procedure_call (self, statement);
      when Case_Statement_Node |
           Block_Statement_Node |
           Loop_Statement_Node |
           If_Statement_Node =>
        Adac.Source.validate (self.nodes(Positive(statement.index)).span);
      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current handled statement";
    end case;
  end validate_current_handled_statement_shallow;

  procedure validate_current_handled_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);

    case self.nodes(Positive(statement.index)).kind is
      when Null_Statement_Node =>
        Adac.Source.validate (self.nodes(Positive(statement.index)).span);

      when Exit_Statement_Node =>
        Structural_Validation.validate_exit_statement (self, statement);

      when Return_Statement_Node =>
        Structural_Validation.validate_return_statement (self, statement);

      when Extended_Return_Statement_Node =>
        Structural_Validation.validate_extended_return_statement
          (self, statement);

      when Assignment_Statement_Node =>
        Structural_Validation.validate_assignment_statement (self, statement);

      when Raise_Statement_Node =>
        Structural_Validation.validate_raise_statement (self, statement);

      when Case_Statement_Node =>
        Structural_Validation.validate_case_statement (self, statement);

      when Block_Statement_Node =>
        Structural_Validation.validate_block_statement (self, statement);

      when Loop_Statement_Node =>
        Structural_Validation.validate_loop_statement (self, statement);

      when Procedure_Call_Statement_Node =>
        Structural_Validation.validate_procedure_call (self, statement);

      when If_Statement_Node =>
        Structural_Validation.validate_if_statement (self, statement);

      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current handled statement";
    end case;
  end validate_current_handled_statement;

  procedure validate_current_exception_handler_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);

    case self.nodes(Positive(statement.index)).kind is
      when Null_Statement_Node =>
        Adac.Source.validate (self.nodes(Positive(statement.index)).span);

      when Return_Statement_Node =>
        Structural_Validation.validate_return_statement (self, statement);

      when Assignment_Statement_Node =>
        Structural_Validation.validate_assignment_statement (self, statement);

      when Procedure_Call_Statement_Node =>
        Structural_Validation.validate_procedure_call (self, statement);

      when Raise_Statement_Node =>
        Structural_Validation.validate_raise_statement (self, statement);

      when Block_Statement_Node =>
        Validation_Implementation.validate_exception_handler_block_statement
          (self, statement);

      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current exception-handler statement";
    end case;
  end validate_current_exception_handler_statement;

  procedure require_if_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);

    if self.nodes(Positive(statement.index)).kind /= If_Statement_Node then
      raise Program_Error with "Adac.AST: node is not an if statement";
    end if;
  end require_if_statement;

  procedure require_elsif_part
    (self : Store;
     part : Node_ID)
  is
  begin
    validate_node_id (self, part);
    if self.nodes(Positive(part.index)).kind /= Elsif_Part_Node then
      raise Program_Error with "Adac.AST: node is not an elsif part";
    end if;
  end require_elsif_part;

  procedure validate_current_if_child_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);

    case self.nodes(Positive(statement.index)).kind is
      when Null_Statement_Node =>
        Adac.Source.validate (self.nodes(Positive(statement.index)).span);

      when Exit_Statement_Node =>
        Structural_Validation.validate_exit_statement (self, statement);

      when Return_Statement_Node =>
        Structural_Validation.validate_return_statement (self, statement);

      when Raise_Statement_Node =>
        Structural_Validation.validate_raise_statement (self, statement);

      when Assignment_Statement_Node =>
        Structural_Validation.validate_assignment_statement (self, statement);

      when Procedure_Call_Statement_Node =>
        Structural_Validation.validate_procedure_call (self, statement);

      when If_Statement_Node | Loop_Statement_Node | Case_Statement_Node =>
        null;

      when Block_Statement_Node =>
        require_handled_sequence
          (self,
           self.nodes(Positive(statement.index)).block_handled_sequence_value);

      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current if-branch statement";
    end case;
  end validate_current_if_child_statement;

  procedure require_exit_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    if self.nodes(Positive(statement.index)).kind /= Exit_Statement_Node then
      raise Program_Error with "Adac.AST: node is not an exit statement";
    end if;
  end require_exit_statement;

  procedure require_return_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    if self.nodes(Positive(statement.index)).kind /= Return_Statement_Node then
      raise Program_Error with "Adac.AST: node is not a return statement";
    end if;
  end require_return_statement;

  procedure require_extended_return_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    if self.nodes(Positive(statement.index)).kind /=
       Extended_Return_Statement_Node
    then
      raise Program_Error with
        "Adac.AST: node is not an extended return statement";
    end if;
  end require_extended_return_statement;

  procedure require_raise_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    if self.nodes(Positive(statement.index)).kind /= Raise_Statement_Node then
      raise Program_Error with "Adac.AST: node is not a raise statement";
    end if;
  end require_raise_statement;

  procedure require_assignment_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);

    if self.nodes(Positive(statement.index)).kind /=
       Assignment_Statement_Node
    then
      raise Program_Error with "Adac.AST: node is not an assignment statement";
    end if;
  end require_assignment_statement;

  procedure require_case_alternative
    (self        : Store;
     alternative : Node_ID)
  is
  begin
    validate_node_id (self, alternative);
    if self.nodes(Positive(alternative.index)).kind /=
       Case_Alternative_Node
    then
      raise Program_Error with "Adac.AST: node is not a case alternative";
    end if;
  end require_case_alternative;

  procedure require_case_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    if self.nodes(Positive(statement.index)).kind /= Case_Statement_Node then
      raise Program_Error with "Adac.AST: node is not a case statement";
    end if;
  end require_case_statement;

  procedure require_block_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    if self.nodes(Positive(statement.index)).kind /= Block_Statement_Node then
      raise Program_Error with "Adac.AST: node is not a block statement";
    end if;
  end require_block_statement;

  procedure require_loop_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    if self.nodes(Positive(statement.index)).kind /= Loop_Statement_Node then
      raise Program_Error with "Adac.AST: node is not a loop statement";
    end if;
  end require_loop_statement;

  procedure validate_current_loop_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    case self.nodes(Positive(statement.index)).kind is
      when Assignment_Statement_Node =>
        Structural_Validation.validate_assignment_statement (self, statement);
      when Exit_Statement_Node =>
        Structural_Validation.validate_exit_statement (self, statement);
      when Procedure_Call_Statement_Node =>
        Structural_Validation.validate_procedure_call (self, statement);
      when Case_Statement_Node | If_Statement_Node =>
        null;
      when Block_Statement_Node =>
        declare
          sequence : constant Node_ID :=
            self.nodes(Positive(statement.index)).block_handled_sequence_value;
        begin
          require_handled_sequence (self, sequence);
          if not self.nodes(Positive(sequence.index)).
            handled_sequence_handlers_value.is_empty
          then
            raise Program_Error with
              "Adac.AST: iterator-loop block has exception handlers";
          end if;
        end;
      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current iterator-loop statement";
    end case;
  end validate_current_loop_statement;

  procedure validate_current_case_alternative_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);
    case self.nodes(Positive(statement.index)).kind is
      when Null_Statement_Node =>
        Adac.Source.validate (self.nodes(Positive(statement.index)).span);

      when Exit_Statement_Node =>
        Structural_Validation.validate_exit_statement (self, statement);
      when Return_Statement_Node =>
        Structural_Validation.validate_return_statement (self, statement);
      when Raise_Statement_Node =>
        Structural_Validation.validate_raise_statement (self, statement);
      when Assignment_Statement_Node =>
        Structural_Validation.validate_assignment_statement (self, statement);
      when Procedure_Call_Statement_Node =>
        Structural_Validation.validate_procedure_call (self, statement);
      when If_Statement_Node | Block_Statement_Node | Loop_Statement_Node |
           Case_Statement_Node =>
        null;
      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current case-alternative statement";
    end case;
  end validate_current_case_alternative_statement;

  procedure validate_current_block_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);
    if self.nodes(Positive(declaration.index)).kind /=
         Object_Declaration_Node and then
       self.nodes(Positive(declaration.index)).kind /=
         Object_Renaming_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a current block declaration";
    end if;
    Structural_Validation.validate_declaration (self, declaration);
  end validate_current_block_declaration;

  procedure validate_current_block_handled_sequence
    (self     : Store;
     sequence : Node_ID)
  is
    procedure require_handler_free_block_child (statement : Node_ID) is
      nested_sequence : Node_ID;
    begin
      require_block_statement (self, statement);
      nested_sequence :=
        self.nodes(Positive(statement.index)).block_handled_sequence_value;
      require_handled_sequence (self, nested_sequence);
      if not self.nodes
        (Positive(nested_sequence.index))
          .handled_sequence_handlers_value.is_empty
      then
        raise Program_Error with
          "Adac.AST: handler-bearing block owns a handled block child";
      end if;
    end require_handler_free_block_child;
  begin
    require_handled_sequence (self, sequence);
    declare
      value : Node renames self.nodes(Positive(sequence.index));
    begin
      Adac.Source.validate (value.span);
      if value.handled_sequence_statements_value.is_empty then
        raise Program_Error with
          "Adac.AST: current block handled sequence is empty";
      end if;

      for child of value.handled_sequence_statements_value loop
        validate_node_id (self, child);
        case self.nodes(Positive(child.index)).kind is
          when Assignment_Statement_Node |
               Case_Statement_Node |
               Exit_Statement_Node |
               Loop_Statement_Node |
               Procedure_Call_Statement_Node |
               Return_Statement_Node |
               If_Statement_Node =>
            null;
          when Block_Statement_Node =>
            if not value.handled_sequence_handlers_value.is_empty then
              require_handler_free_block_child (child);
            end if;
          when others =>
            raise Program_Error with
              "Adac.AST: current block body is not a bounded block statement";
        end case;
      end loop;

      for handler of value.handled_sequence_handlers_value loop
        Structural_Validation.validate_exception_handler (self, handler);
      end loop;
    end;
  end validate_current_block_handled_sequence;

  procedure require_procedure_call
    (self      : Store;
     statement : Node_ID)
  is
  begin
    validate_node_id (self, statement);

    if self.nodes(Positive(statement.index)).kind /=
       Procedure_Call_Statement_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a procedure-call statement";
    end if;
  end require_procedure_call;

  procedure require_package_renaming_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);
    if self.nodes(Positive(declaration.index)).kind /=
       Package_Renaming_Declaration_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a package-renaming declaration";
    end if;
  end require_package_renaming_declaration;

  procedure require_package_instantiation
    (self          : Store;
     instantiation : Node_ID)
  is
  begin
    validate_node_id (self, instantiation);

    if self.nodes(Positive(instantiation.index)).kind /=
       Package_Instantiation_Node
    then
      raise Program_Error with
        "Adac.AST: node is not a package instantiation";
    end if;
  end require_package_instantiation;

  procedure require_package_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    if self.nodes(Positive(declaration.index)).kind /=
       Package_Declaration_Node
    then
      raise Program_Error with "Adac.AST: node is not a package declaration";
    end if;
  end require_package_declaration;

  procedure require_package_body_stub
    (self : Store;
     stub : Node_ID)
  is
  begin
    validate_node_id (self, stub);

    if self.nodes(Positive(stub.index)).kind /= Package_Body_Stub_Node then
      raise Program_Error with "Adac.AST: node is not a package body stub";
    end if;
  end require_package_body_stub;

  procedure require_package_body
    (self : Store;
     package_body : Node_ID)
  is
  begin
    validate_node_id (self, package_body);

    if self.nodes(Positive(package_body.index)).kind /= Package_Body_Node then
      raise Program_Error with "Adac.AST: node is not a package body";
    end if;
  end require_package_body;

  procedure require_procedure_body
    (self : Store;
     procedure_body : Node_ID)
  is
  begin
    validate_node_id (self, procedure_body);

    if self.nodes(Positive(procedure_body.index)).kind /=
       Procedure_Body_Node
    then
      raise Program_Error with "Adac.AST: node is not a procedure body";
    end if;
  end require_procedure_body;

  procedure require_function_body
    (self          : Store;
     function_body : Node_ID)
  is
  begin
    validate_node_id (self, function_body);
    if self.nodes(Positive(function_body.index)).kind /= Function_Body_Node then
      raise Program_Error with "Adac.AST: node is not a function body";
    end if;
  end require_function_body;

  procedure require_subunit
    (self    : Store;
     subunit : Node_ID)
  is
  begin
    validate_node_id (self, subunit);
    if self.nodes(Positive(subunit.index)).kind /= Subunit_Node then
      raise Program_Error with "Adac.AST: node is not a subunit";
    end if;
  end require_subunit;

  procedure require_compilation_unit
    (self : Store;
     unit : Node_ID)
  is
  begin
    validate_node_id (self, unit);

    if self.nodes(Positive(unit.index)).kind /= Compilation_Unit_Node then
      raise Program_Error with "Adac.AST: node is not a compilation unit";
    end if;
  end require_compilation_unit;

  procedure validate_simple_name
    (self : Store;
     name : Node_ID)
  is
    current : Node_ID := name;
  begin
    loop
      require_simple_name (self, current);

      declare
        value : Node renames self.nodes(Positive(current.index));
      begin
        Adac.Source.validate (value.span);

        case value.kind is
          when Identifier_Name_Node =>
            Adac.Symbols.validate (value.name_symbol);
            return;

          when Selected_Name_Node =>
            Adac.Symbols.validate (value.selected_symbol);
            Adac.Source.validate (value.selected_span);
            require_simple_name (self, value.selected_prefix);

            if value.selected_prefix.index >= current.index then
              raise Program_Error with
                "Adac.AST: selected-name prefix is not earlier";
            end if;

            declare
              prefix_span : constant Adac.Source.Span :=
                self.nodes(Positive(value.selected_prefix.index)).span;
            begin
              Adac.Source.validate (prefix_span);

              if not Adac.Source.contains (value.span, prefix_span) or else
                 not Adac.Source.contains
                   (value.span, value.selected_span)
              then
                raise Program_Error with
                  "Adac.AST: selected-name child span is outside name";
              end if;

              if Adac.Source.first_position (value.span) /=
                   Adac.Source.first_position (prefix_span) or else
                 Adac.Source.last_position (value.span) /=
                   Adac.Source.last_position (value.selected_span)
              then
                raise Program_Error with
                  "Adac.AST: selected-name span does not match components";
              end if;
            end;

            current := value.selected_prefix;

          when others =>
            raise Program_Error with
              "Adac.AST: unreachable simple-name node kind";
        end case;
      end;
    end loop;
  end validate_simple_name;

  procedure validate_with_clause
    (self   : Store;
     clause : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_with_clause (self, clause);

    declare
      value : Node renames self.nodes(Positive(clause.index));
    begin
      Adac.Source.validate (value.span);

      if value.library_names.is_empty then
        raise Program_Error with "Adac.AST: with-clause name list is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for name of value.library_names loop
        require_simple_name (self, name);

        if name.index >= clause.index then
          raise Program_Error with
            "Adac.AST: with-clause name is not earlier";
        end if;

        validate_simple_name (self, name);
        declare
          name_span : constant Adac.Source.Span :=
            self.nodes(Positive(name.index)).span;
        begin
          if not Adac.Source.contains (value.span, name_span) then
            raise Program_Error with
              "Adac.AST: with-clause name span is outside clause";
          end if;

          if not precedes
            (previous_last, Adac.Source.first_position (name_span))
          then
            raise Program_Error with
              "Adac.AST: with-clause names are out of source order";
          end if;

          previous_last := Adac.Source.last_position (name_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: with-clause span does not include its terminator";
      end if;
    end;
  end validate_with_clause;

  function create return Store is
  begin
    return result : Store do
      result.initialized := True;
    end return;
  end create;

  procedure append
    (self : in out Node_List;
     node : Node_ID)
  is
  begin
    validate (node);
    self.nodes.append (node);
  end append;

  function list_count (self : Node_List) return Natural is
  begin
    return Natural(self.nodes.length);
  end list_count;

  function list_element
    (self  : Node_List;
     index : Positive)
  return Node_ID is
  begin
    if index > Natural(self.nodes.length) then
      raise Program_Error with "Adac.AST: node list index is out of range";
    end if;

    return self.nodes(index);
  end list_element;

  procedure append
    (self   : in out Parenthesized_Name_Item_List;
     actual : Node_ID)
  is
  begin
    validate (actual);
    self.items.append
      (Parenthesized_Name_Item'
        (form     => Positional_Parenthesized_Name_Item_Form,
         selector => INVALID_NODE_ID,
         actual   => actual));
  end append;

  procedure append
    (self     : in out Parenthesized_Name_Item_List;
     selector : Node_ID;
     actual   : Node_ID)
  is
  begin
    validate (selector);
    validate (actual);
    self.items.append
      (Parenthesized_Name_Item'
        (form     => Named_Parenthesized_Name_Item_Form,
         selector => selector,
         actual   => actual));
  end append;

  function parenthesized_name_item_list_count
    (self : Parenthesized_Name_Item_List)
  return Natural is
  begin
    return Natural(self.items.length);
  end parenthesized_name_item_list_count;

  function parenthesized_name_item_list_form
    (self  : Parenthesized_Name_Item_List;
     index : Positive)
  return Parenthesized_Name_Item_Form is
  begin
    if index > parenthesized_name_item_list_count (self) then
      raise Program_Error with
        "Adac.AST: parenthesized-name item list index is out of range";
    end if;
    return self.items(index).form;
  end parenthesized_name_item_list_form;

  function parenthesized_name_item_list_selector
    (self  : Parenthesized_Name_Item_List;
     index : Positive)
  return Node_ID is
  begin
    if index > parenthesized_name_item_list_count (self) then
      raise Program_Error with
        "Adac.AST: parenthesized-name item list index is out of range";
    end if;
    if self.items(index).form /= Named_Parenthesized_Name_Item_Form then
      raise Program_Error with
        "Adac.AST: positional parenthesized-name item has no selector";
    end if;
    return self.items(index).selector;
  end parenthesized_name_item_list_selector;

  function parenthesized_name_item_list_actual
    (self  : Parenthesized_Name_Item_List;
     index : Positive)
  return Node_ID is
  begin
    if index > parenthesized_name_item_list_count (self) then
      raise Program_Error with
        "Adac.AST: parenthesized-name item list index is out of range";
    end if;
    return self.items(index).actual;
  end parenthesized_name_item_list_actual;

  procedure append
    (self   : in out Procedure_Call_Actual_Association_List;
     actual : Node_ID)
  is
  begin
    validate (actual);
    self.associations.append
      (Procedure_Call_Actual_Association'
        (form     => Positional_Procedure_Call_Actual_Form,
         selector => INVALID_NODE_ID,
         actual   => actual));
  end append;

  procedure append
    (self     : in out Procedure_Call_Actual_Association_List;
     selector : Node_ID;
     actual   : Node_ID)
  is
  begin
    validate (selector);
    validate (actual);
    self.associations.append
      (Procedure_Call_Actual_Association'
        (form     => Named_Procedure_Call_Actual_Form,
         selector => selector,
         actual   => actual));
  end append;

  function procedure_call_actual_association_list_count
    (self : Procedure_Call_Actual_Association_List)
  return Natural is
  begin
    return Natural(self.associations.length);
  end procedure_call_actual_association_list_count;

  function procedure_call_actual_association_list_form
    (self  : Procedure_Call_Actual_Association_List;
     index : Positive)
  return Procedure_Call_Actual_Association_Form is
  begin
    if index > procedure_call_actual_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: procedure-call actual list index is out of range";
    end if;
    return self.associations(index).form;
  end procedure_call_actual_association_list_form;

  function procedure_call_actual_association_list_selector
    (self  : Procedure_Call_Actual_Association_List;
     index : Positive)
  return Node_ID is
  begin
    if index > procedure_call_actual_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: procedure-call actual list index is out of range";
    end if;
    if self.associations(index).form /= Named_Procedure_Call_Actual_Form then
      raise Program_Error with
        "Adac.AST: positional procedure-call actual has no selector";
    end if;
    return self.associations(index).selector;
  end procedure_call_actual_association_list_selector;

  function procedure_call_actual_association_list_actual
    (self  : Procedure_Call_Actual_Association_List;
     index : Positive)
  return Node_ID is
  begin
    if index > procedure_call_actual_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: procedure-call actual list index is out of range";
    end if;
    return self.associations(index).actual;
  end procedure_call_actual_association_list_actual;

  procedure append
    (self   : in out Program_Unit_Name;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span)
  is
  begin
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (span);
    self.components.append
      (Program_Unit_Name_Component'(symbol => symbol, span => span));
  end append;

  function program_unit_name_component_count
    (self : Program_Unit_Name)
  return Natural is
  begin
    return Natural(self.components.length);
  end program_unit_name_component_count;

  function program_unit_name_component_symbol
    (self  : Program_Unit_Name;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    if index > Natural(self.components.length) then
      raise Program_Error with
        "Adac.AST: program-unit-name component index is out of range";
    end if;
    return self.components(index).symbol;
  end program_unit_name_component_symbol;

  function program_unit_name_component_span
    (self  : Program_Unit_Name;
     index : Positive)
  return Adac.Source.Span is
  begin
    if index > Natural(self.components.length) then
      raise Program_Error with
        "Adac.AST: program-unit-name component index is out of range";
    end if;
    return self.components(index).span;
  end program_unit_name_component_span;

  procedure append
    (self   : in out Defining_Identifier_List;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span)
  is
  begin
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (span);
    self.components.append
      (Program_Unit_Name_Component'(symbol => symbol, span => span));
  end append;

  function defining_identifier_list_count
    (self : Defining_Identifier_List)
  return Natural is
  begin
    return Natural(self.components.length);
  end defining_identifier_list_count;

  function defining_identifier_list_symbol
    (self  : Defining_Identifier_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    if index > defining_identifier_list_count (self) then
      raise Program_Error with
        "Adac.AST: defining identifier index is out of range";
    end if;
    return self.components(index).symbol;
  end defining_identifier_list_symbol;

  function defining_identifier_list_span
    (self  : Defining_Identifier_List;
     index : Positive)
  return Adac.Source.Span is
  begin
    if index > defining_identifier_list_count (self) then
      raise Program_Error with
        "Adac.AST: defining identifier index is out of range";
    end if;
    return self.components(index).span;
  end defining_identifier_list_span;

  procedure append
    (self   : in out Enumeration_Literal_List;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span)
  is
  begin
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (span);
    self.components.append
      (Program_Unit_Name_Component'(symbol => symbol, span => span));
  end append;

  function enumeration_literal_list_count
    (self : Enumeration_Literal_List)
  return Natural is
  begin
    return Natural(self.components.length);
  end enumeration_literal_list_count;

  function enumeration_literal_list_symbol
    (self  : Enumeration_Literal_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    if index > enumeration_literal_list_count (self) then
      raise Program_Error with
        "Adac.AST: enumeration literal index is out of range";
    end if;
    return self.components(index).symbol;
  end enumeration_literal_list_symbol;

  function enumeration_literal_list_span
    (self  : Enumeration_Literal_List;
     index : Positive)
  return Adac.Source.Span is
  begin
    if index > enumeration_literal_list_count (self) then
      raise Program_Error with
        "Adac.AST: enumeration literal index is out of range";
    end if;
    return self.components(index).span;
  end enumeration_literal_list_span;

  procedure append
    (self          : in out Record_Component_Association_List;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     expression    : Node_ID)
  is
  begin
    Adac.Symbols.validate (selector);
    Adac.Source.validate (selector_span);
    validate (expression);
    self.associations.append
      (Record_Component_Association'
        (selector      => selector,
         selector_span => selector_span,
         expression    => expression));
  end append;

  function record_component_association_list_count
    (self : Record_Component_Association_List)
  return Natural is
  begin
    return Natural(self.associations.length);
  end record_component_association_list_count;

  function record_component_association_list_selector_symbol
    (self  : Record_Component_Association_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    if index > record_component_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: record association list index is out of range";
    end if;
    return self.associations(index).selector;
  end record_component_association_list_selector_symbol;

  function record_component_association_list_selector_span
    (self  : Record_Component_Association_List;
     index : Positive)
  return Adac.Source.Span is
  begin
    if index > record_component_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: record association list index is out of range";
    end if;
    return self.associations(index).selector_span;
  end record_component_association_list_selector_span;

  function record_component_association_list_expression
    (self  : Record_Component_Association_List;
     index : Positive)
  return Node_ID is
  begin
    if index > record_component_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: record association list index is out of range";
    end if;
    return self.associations(index).expression;
  end record_component_association_list_expression;

  procedure append
    (self       : in out Array_Component_Association_List;
     choices    : Node_List;
     expression : Node_ID)
  is
  begin
    if choices.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: array association choice list is empty";
    end if;
    for choice of choices.nodes loop
      validate (choice);
    end loop;
    validate (expression);
    self.associations.append
      (Array_Component_Association'
        (choices    => choices.nodes,
         expression => expression));
  end append;

  function array_component_association_list_count
    (self : Array_Component_Association_List)
  return Natural is
  begin
    return Natural(self.associations.length);
  end array_component_association_list_count;

  function array_component_association_list_choice_count
    (self  : Array_Component_Association_List;
     index : Positive)
  return Natural is
  begin
    if index > array_component_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: array association list index is out of range";
    end if;
    return Natural(self.associations(index).choices.length);
  end array_component_association_list_choice_count;

  function array_component_association_list_choice
    (self              : Array_Component_Association_List;
     association_index : Positive;
     choice_index      : Positive)
  return Node_ID is
  begin
    if association_index > array_component_association_list_count (self) or else
       choice_index > array_component_association_list_choice_count
         (self, association_index)
    then
      raise Program_Error with
        "Adac.AST: array association choice index is out of range";
    end if;
    return self.associations(association_index).choices(choice_index);
  end array_component_association_list_choice;

  function array_component_association_list_expression
    (self  : Array_Component_Association_List;
     index : Positive)
  return Node_ID is
  begin
    if index > array_component_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: array association list index is out of range";
    end if;
    return self.associations(index).expression;
  end array_component_association_list_expression;

  procedure append
    (self   : in out Generic_Actual_Association_List;
     actual : Node_ID)
  is
  begin
    validate (actual);
    self.associations.append
      (Generic_Actual_Association'
        (form          => Positional_Generic_Actual_Form,
         selector      => Adac.Symbols.INVALID_SYMBOL_ID,
         selector_span => Adac.Source.INVALID_SPAN,
         actual        => actual));
  end append;

  procedure append
    (self          : in out Generic_Actual_Association_List;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     actual        : Node_ID)
  is
  begin
    Adac.Symbols.validate (selector);
    Adac.Source.validate (selector_span);
    validate (actual);
    self.associations.append
      (Generic_Actual_Association'
        (form          => Named_Generic_Actual_Form,
         selector      => selector,
         selector_span => selector_span,
         actual        => actual));
  end append;

  function generic_actual_association_list_count
    (self : Generic_Actual_Association_List)
  return Natural is
  begin
    return Natural(self.associations.length);
  end generic_actual_association_list_count;

  function generic_actual_association_list_form
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Generic_Actual_Association_Form is
  begin
    if index > generic_actual_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: generic actual list index is out of range";
    end if;
    return self.associations(index).form;
  end generic_actual_association_list_form;

  function generic_actual_association_list_selector_symbol
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    if index > generic_actual_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: generic actual list index is out of range";
    end if;
    if self.associations(index).form /= Named_Generic_Actual_Form then
      raise Program_Error with
        "Adac.AST: positional generic actual has no selector symbol";
    end if;
    return self.associations(index).selector;
  end generic_actual_association_list_selector_symbol;

  function generic_actual_association_list_selector_span
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Adac.Source.Span is
  begin
    if index > generic_actual_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: generic actual list index is out of range";
    end if;
    if self.associations(index).form /= Named_Generic_Actual_Form then
      raise Program_Error with
        "Adac.AST: positional generic actual has no selector span";
    end if;
    return self.associations(index).selector_span;
  end generic_actual_association_list_selector_span;

  function generic_actual_association_list_actual
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Node_ID is
  begin
    if index > generic_actual_association_list_count (self) then
      raise Program_Error with
        "Adac.AST: generic actual list index is out of range";
    end if;
    return self.associations(index).actual;
  end generic_actual_association_list_actual;

  package body Construction_Implementation is separate;

  function node_count (self : Store) return Natural is
  begin
    validate_store (self);
    return Natural(self.nodes.length);
  end node_count;

  function kind_of
    (self : Store;
     node : Node_ID)
  return Node_Kind is
  begin
    validate_node_id (self, node);
    return self.nodes(Positive(node.index)).kind;
  end kind_of;

  function node_span
    (self : Store;
     node : Node_ID)
  return Adac.Source.Span is
  begin
    validate_node_id (self, node);
    return self.nodes(Positive(node.index)).span;
  end node_span;

  function exception_handler_has_choice_parameter
    (self    : Store;
     handler : Node_ID)
  return Boolean is
  begin
    require_exception_handler (self, handler);
    return self.nodes
      (Positive(handler.index)).exception_handler_choice_parameter_symbol_value
        /= Adac.Symbols.INVALID_SYMBOL_ID;
  end exception_handler_has_choice_parameter;

  function exception_handler_choice_parameter_symbol
    (self    : Store;
     handler : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_exception_handler (self, handler);
    return self.nodes
      (Positive(handler.index)).exception_handler_choice_parameter_symbol_value;
  end exception_handler_choice_parameter_symbol;

  function exception_handler_choice_parameter_span
    (self    : Store;
     handler : Node_ID)
  return Adac.Source.Span is
  begin
    require_exception_handler (self, handler);
    return self.nodes
      (Positive(handler.index)).exception_handler_choice_parameter_span_value;
  end exception_handler_choice_parameter_span;

  function exception_handler_choice_count
    (self    : Store;
     handler : Node_ID)
  return Natural is
  begin
    require_exception_handler (self, handler);
    return Natural
      (self.nodes
         (Positive(handler.index)).exception_handler_choices_value.length);
  end exception_handler_choice_count;

  function exception_handler_choice_at
    (self    : Store;
     handler : Node_ID;
     index   : Positive)
  return Node_ID is
  begin
    require_exception_handler (self, handler);
    if index > exception_handler_choice_count (self, handler) then
      raise Program_Error with "Adac.AST: exception choice index out of range";
    end if;
    return self.nodes
      (Positive(handler.index)).exception_handler_choices_value(index);
  end exception_handler_choice_at;

  function exception_handler_statement_count
    (self    : Store;
     handler : Node_ID)
  return Natural is
  begin
    require_exception_handler (self, handler);
    return Natural
      (self.nodes
         (Positive(handler.index)).exception_handler_statements_value.length);
  end exception_handler_statement_count;

  function exception_handler_statement_at
    (self    : Store;
     handler : Node_ID;
     index   : Positive)
  return Node_ID is
  begin
    require_exception_handler (self, handler);
    if index > exception_handler_statement_count (self, handler) then
      raise Program_Error with "Adac.AST: handler statement index out of range";
    end if;
    return self.nodes
      (Positive(handler.index)).exception_handler_statements_value(index);
  end exception_handler_statement_at;

  function handled_sequence_statement_count
    (self     : Store;
     sequence : Node_ID)
  return Natural is
  begin
    require_handled_sequence (self, sequence);
    return Natural
      (self.nodes
         (Positive(sequence.index)).handled_sequence_statements_value.length);
  end handled_sequence_statement_count;

  function handled_sequence_statement_at
    (self     : Store;
     sequence : Node_ID;
     index    : Positive)
  return Node_ID is
  begin
    require_handled_sequence (self, sequence);
    if index > handled_sequence_statement_count (self, sequence) then
      raise Program_Error with "Adac.AST: handled statement index out of range";
    end if;
    return self.nodes
      (Positive(sequence.index)).handled_sequence_statements_value(index);
  end handled_sequence_statement_at;

  function handled_sequence_handler_count
    (self     : Store;
     sequence : Node_ID)
  return Natural is
  begin
    require_handled_sequence (self, sequence);
    return Natural
      (self.nodes
         (Positive(sequence.index)).handled_sequence_handlers_value.length);
  end handled_sequence_handler_count;

  function handled_sequence_handler_at
    (self     : Store;
     sequence : Node_ID;
     index    : Positive)
  return Node_ID is
  begin
    require_handled_sequence (self, sequence);
    if index > handled_sequence_handler_count (self, sequence) then
      raise Program_Error with "Adac.AST: handled handler index out of range";
    end if;
    return self.nodes
      (Positive(sequence.index)).handled_sequence_handlers_value(index);
  end handled_sequence_handler_at;

  function if_condition
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_if_statement (self, statement);
    return self.nodes(Positive(statement.index)).if_condition_value;
  end if_condition;

  function elsif_condition
    (self : Store;
     part : Node_ID)
  return Node_ID is
  begin
    require_elsif_part (self, part);
    return self.nodes(Positive(part.index)).elsif_condition_value;
  end elsif_condition;

  function elsif_statement_count
    (self : Store;
     part : Node_ID)
  return Natural is
  begin
    require_elsif_part (self, part);
    return Natural
      (self.nodes(Positive(part.index)).elsif_statements_value.length);
  end elsif_statement_count;

  function elsif_statement_at
    (self  : Store;
     part  : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_elsif_part (self, part);
    if index > elsif_statement_count (self, part) then
      raise Program_Error with "Adac.AST: elsif statement index out of range";
    end if;
    return self.nodes(Positive(part.index)).elsif_statements_value(index);
  end elsif_statement_at;

  function if_then_statement_count
    (self      : Store;
     statement : Node_ID)
  return Natural is
  begin
    require_if_statement (self, statement);
    return Natural
      (self.nodes(Positive(statement.index)).if_then_statements_value.length);
  end if_then_statement_count;

  function if_then_statement_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_if_statement (self, statement);

    if index > if_then_statement_count (self, statement) then
      raise Program_Error with "Adac.AST: if then index out of range";
    end if;

    return self.nodes
      (Positive(statement.index)).if_then_statements_value(index);
  end if_then_statement_at;

  function if_elsif_part_count
    (self      : Store;
     statement : Node_ID)
  return Natural is
  begin
    require_if_statement (self, statement);
    return Natural
      (self.nodes(Positive(statement.index)).if_elsif_parts_value.length);
  end if_elsif_part_count;

  function if_elsif_part_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_if_statement (self, statement);
    if index > if_elsif_part_count (self, statement) then
      raise Program_Error with "Adac.AST: if elsif index out of range";
    end if;
    return self.nodes(Positive(statement.index)).if_elsif_parts_value(index);
  end if_elsif_part_at;

  function if_else_statement_count
    (self      : Store;
     statement : Node_ID)
  return Natural is
  begin
    require_if_statement (self, statement);
    return Natural
      (self.nodes
         (Positive(statement.index)).if_else_statements_value.length);
  end if_else_statement_count;

  function if_else_statement_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_if_statement (self, statement);

    if index > if_else_statement_count (self, statement) then
      raise Program_Error with "Adac.AST: if else index out of range";
    end if;

    return self.nodes
      (Positive(statement.index)).if_else_statements_value(index);
  end if_else_statement_at;

  function exit_has_loop_name
    (self      : Store;
     statement : Node_ID)
  return Boolean is
  begin
    require_exit_statement (self, statement);
    return self.nodes(Positive(statement.index)).exit_loop_name_symbol_value /=
      Adac.Symbols.INVALID_SYMBOL_ID;
  end exit_has_loop_name;

  function exit_loop_name_symbol
    (self      : Store;
     statement : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_exit_statement (self, statement);
    if not exit_has_loop_name (self, statement) then
      raise Program_Error with "Adac.AST: exit statement has no loop name";
    end if;
    return self.nodes(Positive(statement.index)).exit_loop_name_symbol_value;
  end exit_loop_name_symbol;

  function exit_loop_name_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span is
  begin
    require_exit_statement (self, statement);
    if not exit_has_loop_name (self, statement) then
      raise Program_Error with "Adac.AST: exit statement has no loop name";
    end if;
    return self.nodes(Positive(statement.index)).exit_loop_name_span_value;
  end exit_loop_name_span;

  function exit_has_condition
    (self      : Store;
     statement : Node_ID)
  return Boolean is
  begin
    require_exit_statement (self, statement);
    return self.nodes(Positive(statement.index)).exit_condition_value /=
      INVALID_NODE_ID;
  end exit_has_condition;

  function exit_when_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span is
  begin
    require_exit_statement (self, statement);
    if not exit_has_condition (self, statement) then
      raise Program_Error with "Adac.AST: exit statement has no condition";
    end if;
    return self.nodes(Positive(statement.index)).exit_when_span_value;
  end exit_when_span;

  function exit_condition
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_exit_statement (self, statement);
    if not exit_has_condition (self, statement) then
      raise Program_Error with "Adac.AST: exit statement has no condition";
    end if;
    return self.nodes(Positive(statement.index)).exit_condition_value;
  end exit_condition;

  function return_has_expression
    (self      : Store;
     statement : Node_ID)
  return Boolean is
  begin
    require_return_statement (self, statement);
    return self.nodes(Positive(statement.index)).return_expression_value /=
      INVALID_NODE_ID;
  end return_has_expression;

  function return_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_return_statement (self, statement);
    if not return_has_expression (self, statement) then
      raise Program_Error with "Adac.AST: return statement has no expression";
    end if;
    return self.nodes(Positive(statement.index)).return_expression_value;
  end return_expression;

  function extended_return_symbol
    (self      : Store;
     statement : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_extended_return_statement (self, statement);
    return self.nodes(Positive(statement.index)).extended_return_symbol_value;
  end extended_return_symbol;

  function extended_return_defining_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span is
  begin
    require_extended_return_statement (self, statement);
    return self.nodes
      (Positive(statement.index)).extended_return_defining_span_value;
  end extended_return_defining_span;

  function extended_return_subtype_mark
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_extended_return_statement (self, statement);
    return self.nodes
      (Positive(statement.index)).extended_return_subtype_mark_value;
  end extended_return_subtype_mark;

  function extended_return_handled_sequence
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_extended_return_statement (self, statement);
    return self.nodes
      (Positive(statement.index)).extended_return_handled_sequence_value;
  end extended_return_handled_sequence;

  function raise_form
    (self      : Store;
     statement : Node_ID)
  return Raise_Statement_Form is
  begin
    require_raise_statement (self, statement);
    return self.nodes(Positive(statement.index)).raise_form_value;
  end raise_form;

  function raise_exception_name
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_raise_statement (self, statement);
    if raise_form (self, statement) /= Named_With_Message_Raise_Form then
      raise Program_Error with
        "Adac.AST: bare re-raise has no exception name";
    end if;
    return self.nodes(Positive(statement.index)).raise_exception_name_value;
  end raise_exception_name;

  function raise_message_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_raise_statement (self, statement);
    if raise_form (self, statement) /= Named_With_Message_Raise_Form then
      raise Program_Error with
        "Adac.AST: bare re-raise has no message expression";
    end if;
    return self.nodes(Positive(statement.index)).raise_message_expression_value;
  end raise_message_expression;

  function assignment_target
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_assignment_statement (self, statement);
    return self.nodes(Positive(statement.index)).assignment_target_value;
  end assignment_target;

  function assignment_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_assignment_statement (self, statement);
    return self.nodes(Positive(statement.index)).assignment_expression_value;
  end assignment_expression;

  function case_alternative_choice_count
    (self        : Store;
     alternative : Node_ID)
  return Natural is
  begin
    require_case_alternative (self, alternative);
    return Natural
      (self.nodes
         (Positive(alternative.index)).case_alternative_choices_value.length);
  end case_alternative_choice_count;

  function case_alternative_choice_at
    (self        : Store;
     alternative : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_case_alternative (self, alternative);
    if index > case_alternative_choice_count (self, alternative) then
      raise Program_Error with "Adac.AST: case choice index out of range";
    end if;
    return self.nodes
      (Positive(alternative.index)).case_alternative_choices_value(index);
  end case_alternative_choice_at;

  function case_alternative_statement_count
    (self        : Store;
     alternative : Node_ID)
  return Natural is
    value : Node renames self.nodes(Positive(alternative.index));
  begin
    require_case_alternative (self, alternative);
    return Natural(value.case_alternative_statements_value.length);
  end case_alternative_statement_count;

  function case_alternative_statement_at
    (self        : Store;
     alternative : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_case_alternative (self, alternative);
    if index > case_alternative_statement_count (self, alternative) then
      raise Program_Error with "Adac.AST: case statement index out of range";
    end if;
    return self.nodes
      (Positive(alternative.index)).case_alternative_statements_value(index);
  end case_alternative_statement_at;

  function case_selecting_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_case_statement (self, statement);
    return self.nodes
      (Positive(statement.index)).case_selecting_expression_value;
  end case_selecting_expression;

  function case_alternative_count
    (self      : Store;
     statement : Node_ID)
  return Natural is
  begin
    require_case_statement (self, statement);
    return Natural
      (self.nodes(Positive(statement.index)).case_alternatives_value.length);
  end case_alternative_count;

  function case_alternative_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_case_statement (self, statement);
    if index > case_alternative_count (self, statement) then
      raise Program_Error with "Adac.AST: case alternative index out of range";
    end if;
    return self.nodes(Positive(statement.index)).case_alternatives_value(index);
  end case_alternative_at;

  function block_declaration_count
    (self      : Store;
     statement : Node_ID)
  return Natural is
  begin
    require_block_statement (self, statement);
    return Natural
      (self.nodes(Positive(statement.index)).block_declarations_value.length);
  end block_declaration_count;

  function block_declaration_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_block_statement (self, statement);
    if index > block_declaration_count (self, statement) then
      raise Program_Error with "Adac.AST: block declaration index out of range";
    end if;
    return self.nodes
      (Positive(statement.index)).block_declarations_value(index);
  end block_declaration_at;

  function block_handled_sequence
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_block_statement (self, statement);
    return self.nodes(Positive(statement.index)).block_handled_sequence_value;
  end block_handled_sequence;

  function loop_form
    (self      : Store;
     statement : Node_ID)
  return Loop_Statement_Form is
  begin
    require_loop_statement (self, statement);
    return self.nodes(Positive(statement.index)).loop_form_value;
  end loop_form;

  function loop_condition
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value /=
       While_Loop_Form
    then
      raise Program_Error with "Adac.AST: loop is not a while loop";
    end if;
    return self.nodes(Positive(statement.index)).loop_condition_value;
  end loop_condition;

  function loop_parameter_symbol
    (self      : Store;
     statement : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value not in
      Discrete_Range_Loop_Form | Range_Attribute_Loop_Form |
      Generalized_Iterator_Loop_Form
    then
      raise Program_Error with "Adac.AST: loop has no loop parameter";
    end if;
    return self.nodes(Positive(statement.index)).loop_parameter_symbol_value;
  end loop_parameter_symbol;

  function loop_parameter_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value not in
      Discrete_Range_Loop_Form | Range_Attribute_Loop_Form |
      Generalized_Iterator_Loop_Form
    then
      raise Program_Error with "Adac.AST: loop has no loop parameter";
    end if;
    return self.nodes(Positive(statement.index)).loop_parameter_span_value;
  end loop_parameter_span;

  function loop_is_reverse
    (self      : Store;
     statement : Node_ID)
  return Boolean is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value not in
      Discrete_Range_Loop_Form | Range_Attribute_Loop_Form |
      Generalized_Iterator_Loop_Form
    then
      raise Program_Error with "Adac.AST: loop has no `reverse` form";
    end if;
    return self.nodes(Positive(statement.index)).loop_reverse_value;
  end loop_is_reverse;

  function loop_iterable_name
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value /=
       Generalized_Iterator_Loop_Form
    then
      raise Program_Error with "Adac.AST: loop is not an iterator loop";
    end if;
    return self.nodes(Positive(statement.index)).loop_iterable_name_value;
  end loop_iterable_name;

  function loop_range_attribute
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value /=
       Range_Attribute_Loop_Form
    then
      raise Program_Error with
        "Adac.AST: loop is not a range-attribute loop";
    end if;
    return self.nodes(Positive(statement.index)).loop_range_attribute_value;
  end loop_range_attribute;

  function loop_range_lower_bound
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value /=
       Discrete_Range_Loop_Form
    then
      raise Program_Error with "Adac.AST: loop is not a discrete-range loop";
    end if;
    return self.nodes(Positive(statement.index)).loop_range_lower_bound_value;
  end loop_range_lower_bound;

  function loop_range_upper_bound
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_loop_statement (self, statement);
    if self.nodes(Positive(statement.index)).loop_form_value /=
       Discrete_Range_Loop_Form
    then
      raise Program_Error with "Adac.AST: loop is not a discrete-range loop";
    end if;
    return self.nodes(Positive(statement.index)).loop_range_upper_bound_value;
  end loop_range_upper_bound;

  function loop_statement_count
    (self      : Store;
     statement : Node_ID)
  return Natural is
  begin
    require_loop_statement (self, statement);
    return Natural
      (self.nodes(Positive(statement.index)).loop_statements_value.length);
  end loop_statement_count;

  function loop_statement_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_loop_statement (self, statement);
    if index > loop_statement_count (self, statement) then
      raise Program_Error with "Adac.AST: loop statement index out of range";
    end if;
    return self.nodes(Positive(statement.index)).loop_statements_value(index);
  end loop_statement_at;

  function procedure_call_callable_name
    (self      : Store;
     statement : Node_ID)
  return Node_ID is
  begin
    require_procedure_call (self, statement);
    return self.nodes
      (Positive(statement.index)).procedure_call_callable_name_value;
  end procedure_call_callable_name;

  function procedure_call_actual_count
    (self      : Store;
     statement : Node_ID)
  return Natural is
  begin
    require_procedure_call (self, statement);
    return Natural
      (self.nodes
         (Positive(statement.index)).procedure_call_actuals_value.length);
  end procedure_call_actual_count;

  function procedure_call_actual_form
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Procedure_Call_Actual_Association_Form is
  begin
    require_procedure_call (self, statement);

    if index > procedure_call_actual_count (self, statement) then
      raise Program_Error with
        "Adac.AST: procedure-call actual index out of range";
    end if;

    return self.nodes
      (Positive(statement.index)).procedure_call_actuals_value(index).form;
  end procedure_call_actual_form;

  function procedure_call_actual_selector_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_procedure_call (self, statement);

    if index > procedure_call_actual_count (self, statement) then
      raise Program_Error with
        "Adac.AST: procedure-call actual index out of range";
    end if;
    if self.nodes
      (Positive(statement.index)).procedure_call_actuals_value(index).form /=
       Named_Procedure_Call_Actual_Form
    then
      raise Program_Error with
        "Adac.AST: positional procedure-call actual has no selector";
    end if;

    return self.nodes
      (Positive(statement.index)).procedure_call_actuals_value(index).selector;
  end procedure_call_actual_selector_at;

  function procedure_call_actual_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_procedure_call (self, statement);

    if index > procedure_call_actual_count (self, statement) then
      raise Program_Error with
        "Adac.AST: procedure-call actual index out of range";
    end if;

    return self.nodes
      (Positive(statement.index)).procedure_call_actuals_value(index).actual;
  end procedure_call_actual_at;

  function numeric_literal_form
    (self    : Store;
     literal : Node_ID)
  return Numeric_Literal_Kind is
  begin
    require_numeric_literal (self, literal);
    return self.nodes(Positive(literal.index)).numeric_form;
  end numeric_literal_form;

  function numeric_literal_spelling
    (self    : Store;
     literal : Node_ID)
  return String is
  begin
    require_numeric_literal (self, literal);
    return Ada.Strings.Unbounded.to_string
      (self.nodes(Positive(literal.index)).numeric_spelling);
  end numeric_literal_spelling;

  function character_literal_spelling
    (self    : Store;
     literal : Node_ID)
  return String is
  begin
    require_character_literal (self, literal);
    return Ada.Strings.Unbounded.to_string
      (self.nodes(Positive(literal.index)).character_spelling);
  end character_literal_spelling;

  function string_literal_spelling
    (self    : Store;
     literal : Node_ID)
  return String is
  begin
    require_string_literal (self, literal);
    return Ada.Strings.Unbounded.to_string
      (self.nodes(Positive(literal.index)).string_spelling);
  end string_literal_spelling;

  function record_aggregate_association_count
    (self      : Store;
     aggregate : Node_ID)
  return Natural is
  begin
    require_record_aggregate (self, aggregate);
    return Natural
      (self.nodes(Positive(aggregate.index))
         .record_aggregate_associations_value.length);
  end record_aggregate_association_count;

  function record_aggregate_selector_symbol_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_record_aggregate (self, aggregate);
    if index > record_aggregate_association_count (self, aggregate) then
      raise Program_Error with
        "Adac.AST: record aggregate association index is out of range";
    end if;
    return self.nodes(Positive(aggregate.index))
      .record_aggregate_associations_value(index).selector;
  end record_aggregate_selector_symbol_at;

  function record_aggregate_selector_span_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Adac.Source.Span is
  begin
    require_record_aggregate (self, aggregate);
    if index > record_aggregate_association_count (self, aggregate) then
      raise Program_Error with
        "Adac.AST: record aggregate association index is out of range";
    end if;
    return self.nodes(Positive(aggregate.index))
      .record_aggregate_associations_value(index).selector_span;
  end record_aggregate_selector_span_at;

  function record_aggregate_expression_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_record_aggregate (self, aggregate);
    if index > record_aggregate_association_count (self, aggregate) then
      raise Program_Error with
        "Adac.AST: record aggregate association index is out of range";
    end if;
    return self.nodes(Positive(aggregate.index))
      .record_aggregate_associations_value(index).expression;
  end record_aggregate_expression_at;

  function array_aggregate_association_count
    (self      : Store;
     aggregate : Node_ID)
  return Natural is
  begin
    require_array_aggregate (self, aggregate);
    return Natural
      (self.nodes(Positive(aggregate.index))
         .array_aggregate_associations_value.length);
  end array_aggregate_association_count;

  function array_aggregate_choice_count
    (self              : Store;
     aggregate         : Node_ID;
     association_index : Positive)
  return Natural is
  begin
    require_array_aggregate (self, aggregate);
    if association_index >
      array_aggregate_association_count (self, aggregate)
    then
      raise Program_Error with
        "Adac.AST: array aggregate association index is out of range";
    end if;
    declare
      association : Array_Component_Association renames
        self.nodes(Positive(aggregate.index))
          .array_aggregate_associations_value(association_index);
    begin
      return Natural(association.choices.length);
    end;
  end array_aggregate_choice_count;

  function array_aggregate_choice_at
    (self              : Store;
     aggregate         : Node_ID;
     association_index : Positive;
     choice_index      : Positive)
  return Node_ID is
  begin
    require_array_aggregate (self, aggregate);
    if association_index >
         array_aggregate_association_count (self, aggregate) or else
       choice_index > array_aggregate_choice_count
         (self, aggregate, association_index)
    then
      raise Program_Error with
        "Adac.AST: array aggregate choice index is out of range";
    end if;
    declare
      association : Array_Component_Association renames
        self.nodes(Positive(aggregate.index))
          .array_aggregate_associations_value(association_index);
    begin
      return association.choices(choice_index);
    end;
  end array_aggregate_choice_at;

  function array_aggregate_expression_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_array_aggregate (self, aggregate);
    if index > array_aggregate_association_count (self, aggregate) then
      raise Program_Error with
        "Adac.AST: array aggregate association index is out of range";
    end if;
    declare
      association : Array_Component_Association renames
        self.nodes(Positive(aggregate.index))
          .array_aggregate_associations_value(index);
    begin
      return association.expression;
    end;
  end array_aggregate_expression_at;

  function bracket_aggregate_expression_count
    (self      : Store;
     aggregate : Node_ID)
  return Natural is
  begin
    require_bracket_aggregate (self, aggregate);
    return Natural
      (self.nodes(Positive(aggregate.index))
         .bracket_aggregate_expressions_value.length);
  end bracket_aggregate_expression_count;

  function bracket_aggregate_expression_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Node_ID is
  begin
    require_bracket_aggregate (self, aggregate);
    if index > bracket_aggregate_expression_count (self, aggregate) then
      raise Program_Error with
        "Adac.AST: bracket aggregate expression index is out of range";
    end if;
    return self.nodes(Positive(aggregate.index))
      .bracket_aggregate_expressions_value(index);
  end bracket_aggregate_expression_at;

  function qualified_expression_subtype_mark
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_qualified_expression (self, expression);
    return self.nodes(Positive(expression.index))
      .qualified_expression_subtype_mark_value;
  end qualified_expression_subtype_mark;

  function qualified_expression_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_qualified_expression (self, expression);
    return self.nodes(Positive(expression.index))
      .qualified_expression_operand_value;
  end qualified_expression_operand;

  function allocator_new_span
    (self      : Store;
     allocator : Node_ID)
  return Adac.Source.Span is
  begin
    require_allocator (self, allocator);
    return self.nodes(Positive(allocator.index)).allocator_new_span_value;
  end allocator_new_span;

  function allocator_expression
    (self      : Store;
     allocator : Node_ID)
  return Node_ID is
  begin
    require_allocator (self, allocator);
    return self.nodes(Positive(allocator.index)).allocator_expression_value;
  end allocator_expression;

  function if_expression_condition
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_if_expression (self, expression);
    return self.nodes(Positive(expression.index)).if_expression_condition_value;
  end if_expression_condition;

  function if_expression_then_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_if_expression (self, expression);
    return self.nodes(Positive(expression.index)).if_expression_then_value;
  end if_expression_then_expression;

  function if_expression_else_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_if_expression (self, expression);
    return self.nodes(Positive(expression.index)).if_expression_else_value;
  end if_expression_else_expression;

  function case_expression_selecting_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_case_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).case_expression_selecting_expression_value;
  end case_expression_selecting_expression;

  function case_expression_alternative_count
    (self       : Store;
     expression : Node_ID)
  return Natural is
  begin
    require_case_expression (self, expression);
    return Natural
      (self.nodes(Positive(expression.index))
         .case_expression_alternatives_value.length);
  end case_expression_alternative_count;

  function case_expression_alternative_at
    (self       : Store;
     expression : Node_ID;
     index      : Positive)
  return Node_ID is
  begin
    require_case_expression (self, expression);
    if index > case_expression_alternative_count (self, expression) then
      raise Program_Error with
        "Adac.AST: case-expression alternative index out of range";
    end if;
    return self.nodes
      (Positive(expression.index)).case_expression_alternatives_value(index);
  end case_expression_alternative_at;

  function case_expression_alternative_choice_count
    (self        : Store;
     alternative : Node_ID)
  return Natural is
  begin
    require_case_expression_alternative (self, alternative);
    return Natural
      (self.nodes
         (Positive(alternative.index))
           .case_expression_alternative_choices_value.length);
  end case_expression_alternative_choice_count;

  function case_expression_alternative_choice_at
    (self        : Store;
     alternative : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_case_expression_alternative (self, alternative);
    if index > case_expression_alternative_choice_count (self, alternative) then
      raise Program_Error with
        "Adac.AST: case-expression choice index out of range";
    end if;
    return self.nodes
      (Positive(alternative.index))
        .case_expression_alternative_choices_value(index);
  end case_expression_alternative_choice_at;

  function case_expression_alternative_expression
    (self        : Store;
     alternative : Node_ID)
  return Node_ID is
  begin
    require_case_expression_alternative (self, alternative);
    return self.nodes
      (Positive(alternative.index))
        .case_expression_alternative_expression_value;
  end case_expression_alternative_expression;

  function raise_expression_exception_name
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_raise_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).raise_expression_exception_name_value;
  end raise_expression_exception_name;

  function raise_expression_has_message
    (self       : Store;
     expression : Node_ID)
  return Boolean is
  begin
    require_raise_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).raise_expression_message_value /=
        INVALID_NODE_ID;
  end raise_expression_has_message;

  function raise_expression_message
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_raise_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).raise_expression_message_value;
  end raise_expression_message;

  function parenthesized_expression_child
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_parenthesized_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).parenthesized_expression_child_value;
  end parenthesized_expression_child;

  function unary_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String is
  begin
    require_unary_operator (self, expression);
    return Ada.Strings.Unbounded.to_string
      (self.nodes(Positive(expression.index)).unary_operator_spelling_value);
  end unary_operator_spelling;

  function unary_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_unary_operator (self, expression);
    return self.nodes(Positive(expression.index)).unary_operator_span_value;
  end unary_operator_span;

  function unary_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_unary_operator (self, expression);
    return self.nodes(Positive(expression.index)).unary_operand_value;
  end unary_operand;

  function binary_exponentiating_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String is
  begin
    require_binary_exponentiating (self, expression);
    return Ada.Strings.Unbounded.to_string
      (self.nodes (Positive(expression.index)).
         binary_exponentiating_operator_spelling_value);
  end binary_exponentiating_operator_spelling;

  function binary_exponentiating_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_binary_exponentiating (self, expression);
    return self.nodes (Positive(expression.index)).
      binary_exponentiating_operator_span_value;
  end binary_exponentiating_operator_span;

  function binary_exponentiating_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_binary_exponentiating (self, expression);
    return self.nodes (Positive(expression.index)).
      binary_exponentiating_left_operand_value;
  end binary_exponentiating_left_operand;

  function binary_exponentiating_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_binary_exponentiating (self, expression);
    return self.nodes (Positive(expression.index)).
      binary_exponentiating_right_operand_value;
  end binary_exponentiating_right_operand;

  function binary_multiplying_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String is
  begin
    require_binary_multiplying (self, expression);
    return Ada.Strings.Unbounded.to_string
      (self.nodes (Positive(expression.index)).
         binary_multiplying_operator_spelling_value);
  end binary_multiplying_operator_spelling;

  function binary_multiplying_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_binary_multiplying (self, expression);
    return self.nodes (Positive(expression.index)).
      binary_multiplying_operator_span_value;
  end binary_multiplying_operator_span;

  function binary_multiplying_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_binary_multiplying (self, expression);
    return self.nodes (Positive(expression.index)).
      binary_multiplying_left_operand_value;
  end binary_multiplying_left_operand;

  function binary_multiplying_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_binary_multiplying (self, expression);
    return self.nodes (Positive(expression.index)).
      binary_multiplying_right_operand_value;
  end binary_multiplying_right_operand;

  function binary_adding_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String is
  begin
    require_binary_adding (self, expression);
    return Ada.Strings.Unbounded.to_string
      (self.nodes
         (Positive(expression.index)).binary_adding_operator_spelling_value);
  end binary_adding_operator_spelling;

  function binary_adding_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_binary_adding (self, expression);
    return self.nodes
      (Positive(expression.index)).binary_adding_operator_span_value;
  end binary_adding_operator_span;

  function binary_adding_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_binary_adding (self, expression);
    return self.nodes
      (Positive(expression.index)).binary_adding_left_operand_value;
  end binary_adding_left_operand;

  function binary_adding_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_binary_adding (self, expression);
    return self.nodes
      (Positive(expression.index)).binary_adding_right_operand_value;
  end binary_adding_right_operand;

  function relation_operator_spelling
    (self     : Store;
     relation : Node_ID)
  return String is
  begin
    require_relation (self, relation);
    return Ada.Strings.Unbounded.to_string
      (self.nodes(Positive(relation.index)).relation_operator_spelling_value);
  end relation_operator_spelling;

  function relation_operator_span
    (self     : Store;
     relation : Node_ID)
  return Adac.Source.Span is
  begin
    require_relation (self, relation);
    return self.nodes(Positive(relation.index)).relation_operator_span_value;
  end relation_operator_span;

  function relation_left_operand
    (self     : Store;
     relation : Node_ID)
  return Node_ID is
  begin
    require_relation (self, relation);
    return self.nodes(Positive(relation.index)).relation_left_operand_value;
  end relation_left_operand;

  function relation_right_operand
    (self     : Store;
     relation : Node_ID)
  return Node_ID is
  begin
    require_relation (self, relation);
    return self.nodes(Positive(relation.index)).relation_right_operand_value;
  end relation_right_operand;

  function case_range_choice_lower_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID is
  begin
    require_case_range_choice (self, choice);
    return self.nodes
      (Positive(choice.index)).case_range_choice_lower_bound_value;
  end case_range_choice_lower_bound;

  function case_range_choice_range_span
    (self   : Store;
     choice : Node_ID)
  return Adac.Source.Span is
  begin
    require_case_range_choice (self, choice);
    return self.nodes
      (Positive(choice.index)).case_range_choice_range_span_value;
  end case_range_choice_range_span;

  function case_range_choice_upper_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID is
  begin
    require_case_range_choice (self, choice);
    return self.nodes
      (Positive(choice.index)).case_range_choice_upper_bound_value;
  end case_range_choice_upper_bound;

  function membership_range_choice_lower_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID is
  begin
    require_membership_range_choice (self, choice);
    return self.nodes
      (Positive(choice.index)).membership_range_choice_lower_bound_value;
  end membership_range_choice_lower_bound;

  function membership_range_choice_range_span
    (self   : Store;
     choice : Node_ID)
  return Adac.Source.Span is
  begin
    require_membership_range_choice (self, choice);
    return self.nodes
      (Positive(choice.index)).membership_range_choice_range_span_value;
  end membership_range_choice_range_span;

  function membership_range_choice_upper_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID is
  begin
    require_membership_range_choice (self, choice);
    return self.nodes
      (Positive(choice.index)).membership_range_choice_upper_bound_value;
  end membership_range_choice_upper_bound;

  function membership_tested_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_membership_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).membership_tested_expression_value;
  end membership_tested_expression;

  function membership_operator
    (self       : Store;
     expression : Node_ID)
  return Membership_Operator_Kind is
  begin
    require_membership_expression (self, expression);
    return self.nodes(Positive(expression.index)).membership_operator_value;
  end membership_operator;

  function membership_not_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_membership_expression (self, expression);
    return self.nodes(Positive(expression.index)).membership_not_span_value;
  end membership_not_span;

  function membership_in_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_membership_expression (self, expression);
    return self.nodes(Positive(expression.index)).membership_in_span_value;
  end membership_in_span;

  function membership_choice_count
    (self       : Store;
     expression : Node_ID)
  return Natural is
  begin
    require_membership_expression (self, expression);
    return Natural
      (self.nodes(Positive(expression.index)).membership_choices_value.length);
  end membership_choice_count;

  function membership_choice_at
    (self       : Store;
     expression : Node_ID;
     index      : Positive)
  return Node_ID is
  begin
    require_membership_expression (self, expression);
    if index > membership_choice_count (self, expression) then
      raise Program_Error with
        "Adac.AST: membership choice index is out of range";
    end if;
    return self.nodes
      (Positive(expression.index)).membership_choices_value(index);
  end membership_choice_at;

  function logical_operator
    (self       : Store;
     expression : Node_ID)
  return Logical_Operator_Kind is
  begin
    require_logical_expression (self, expression);
    return self.nodes(Positive(expression.index)).logical_operator_value;
  end logical_operator;

  function logical_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_logical_expression (self, expression);
    return self.nodes(Positive(expression.index)).logical_operator_span_value;
  end logical_operator_span;

  function logical_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_logical_expression (self, expression);
    return self.nodes(Positive(expression.index)).logical_left_operand_value;
  end logical_left_operand;

  function logical_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_logical_expression (self, expression);
    return self.nodes(Positive(expression.index)).logical_right_operand_value;
  end logical_right_operand;

  function short_circuit_operator
    (self       : Store;
     expression : Node_ID)
  return Short_Circuit_Operator_Kind is
  begin
    require_short_circuit_expression (self, expression);
    return self.nodes(Positive(expression.index)).short_circuit_operator_value;
  end short_circuit_operator;

  function short_circuit_operator_first_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_short_circuit_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).short_circuit_operator_first_span_value;
  end short_circuit_operator_first_span;

  function short_circuit_operator_second_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span is
  begin
    require_short_circuit_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).short_circuit_operator_second_span_value;
  end short_circuit_operator_second_span;

  function short_circuit_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_short_circuit_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).short_circuit_left_operand_value;
  end short_circuit_left_operand;

  function short_circuit_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID is
  begin
    require_short_circuit_expression (self, expression);
    return self.nodes
      (Positive(expression.index)).short_circuit_right_operand_value;
  end short_circuit_right_operand;

  function identifier_symbol
    (self : Store;
     name : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    validate_node_id (self, name);

    if self.nodes(Positive(name.index)).kind /= Identifier_Name_Node then
      raise Program_Error with "Adac.AST: node is not an identifier name";
    end if;

    return self.nodes(Positive(name.index)).name_symbol;
  end identifier_symbol;

  function name_prefix
    (self : Store;
     name : Node_ID)
  return Node_ID is
  begin
    validate_node_id (self, name);

    case self.nodes(Positive(name.index)).kind is
      when Selected_Name_Node | Selected_Component_Node =>
        return self.nodes(Positive(name.index)).selected_prefix;

      when Explicit_Dereference_Name_Node =>
        return self.nodes(Positive(name.index))
          .explicit_dereference_prefix_value;

      when Parenthesized_Name_Node =>
        return self.nodes(Positive(name.index)).parenthesized_prefix;

      when Slice_Name_Node =>
        return self.nodes(Positive(name.index)).slice_prefix_value;

      when Attribute_Name_Node =>
        return self.nodes(Positive(name.index)).attribute_prefix;

      when others =>
        raise Program_Error with "Adac.AST: node has no name prefix";
    end case;
  end name_prefix;

  function explicit_dereference_all_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span is
  begin
    validate_node_id (self, name);
    if self.nodes(Positive(name.index)).kind /=
       Explicit_Dereference_Name_Node
    then
      raise Program_Error with
        "Adac.AST: node is not an explicit dereference name";
    end if;
    return self.nodes(Positive(name.index))
      .explicit_dereference_all_span_value;
  end explicit_dereference_all_span;

  function selector_symbol
    (self : Store;
     name : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    validate_node_id (self, name);

    if self.nodes(Positive(name.index)).kind /= Selected_Name_Node and then
       self.nodes(Positive(name.index)).kind /= Selected_Component_Node
    then
      raise Program_Error with "Adac.AST: node has no selector symbol";
    end if;

    return self.nodes(Positive(name.index)).selected_symbol;
  end selector_symbol;

  function selector_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span is
  begin
    validate_node_id (self, name);

    if self.nodes(Positive(name.index)).kind /= Selected_Name_Node and then
       self.nodes(Positive(name.index)).kind /= Selected_Component_Node
    then
      raise Program_Error with "Adac.AST: node has no selector span";
    end if;

    return self.nodes(Positive(name.index)).selected_span;
  end selector_span;

  function parenthesized_item_count
    (self : Store;
     name : Node_ID)
  return Natural is
  begin
    require_parenthesized_name (self, name);
    return Natural
      (self.nodes(Positive(name.index)).parenthesized_items.length);
  end parenthesized_item_count;

  function parenthesized_item_at
    (self  : Store;
     name  : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_parenthesized_name (self, name);

    if index > parenthesized_item_count (self, name) then
      raise Program_Error with
        "Adac.AST: parenthesized-name item index is out of range";
    end if;

    return self.nodes(Positive(name.index)).parenthesized_items(index).actual;
  end parenthesized_item_at;

  function parenthesized_item_form
    (self  : Store;
     name  : Node_ID;
     index : Positive)
  return Parenthesized_Name_Item_Form is
  begin
    require_parenthesized_name (self, name);
    if index > parenthesized_item_count (self, name) then
      raise Program_Error with
        "Adac.AST: parenthesized-name item index is out of range";
    end if;
    return self.nodes(Positive(name.index)).parenthesized_items(index).form;
  end parenthesized_item_form;

  function parenthesized_item_selector
    (self  : Store;
     name  : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_parenthesized_name (self, name);
    if index > parenthesized_item_count (self, name) then
      raise Program_Error with
        "Adac.AST: parenthesized-name item index is out of range";
    end if;
    if parenthesized_item_form (self, name, index) /=
       Named_Parenthesized_Name_Item_Form
    then
      raise Program_Error with
        "Adac.AST: positional parenthesized-name item has no selector";
    end if;
    return self.nodes(Positive(name.index)).parenthesized_items(index).selector;
  end parenthesized_item_selector;

  function slice_lower_bound
    (self : Store;
     name : Node_ID)
  return Node_ID is
  begin
    require_slice_name (self, name);
    return self.nodes(Positive(name.index)).slice_lower_bound_value;
  end slice_lower_bound;

  function slice_range_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span is
  begin
    require_slice_name (self, name);
    return self.nodes(Positive(name.index)).slice_range_span_value;
  end slice_range_span;

  function slice_upper_bound
    (self : Store;
     name : Node_ID)
  return Node_ID is
  begin
    require_slice_name (self, name);
    return self.nodes(Positive(name.index)).slice_upper_bound_value;
  end slice_upper_bound;

  function attribute_symbol
    (self : Store;
     name : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_attribute_name (self, name);
    return self.nodes(Positive(name.index)).attribute_symbol_value;
  end attribute_symbol;

  function attribute_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span is
  begin
    require_attribute_name (self, name);
    return self.nodes(Positive(name.index)).attribute_span_value;
  end attribute_span;

  function aspect_mark_symbol
    (self   : Store;
     aspect : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_aspect_specification (self, aspect);
    return self.nodes(Positive(aspect.index)).aspect_mark_symbol_value;
  end aspect_mark_symbol;

  function aspect_mark_span
    (self   : Store;
     aspect : Node_ID)
  return Adac.Source.Span is
  begin
    require_aspect_specification (self, aspect);
    return self.nodes(Positive(aspect.index)).aspect_mark_span_value;
  end aspect_mark_span;

  function aspect_definition
    (self   : Store;
     aspect : Node_ID)
  return Node_ID is
  begin
    require_aspect_specification (self, aspect);
    return self.nodes(Positive(aspect.index)).aspect_definition_value;
  end aspect_definition;

  function parameter_defining_identifier_count
    (self      : Store;
     parameter : Node_ID)
  return Natural is
    list_index : Natural;
  begin
    require_parameter_specification (self, parameter);
    list_index :=
      self.nodes(Positive(parameter.index)).
        parameter_additional_defining_names_index_value;
    if list_index = 0 then
      return 1;
    end if;
    return 1 + program_unit_name_component_count
      (self.parameter_additional_defining_names (Positive(list_index)));
  end parameter_defining_identifier_count;

  function parameter_defining_symbol_at
    (self      : Store;
     parameter : Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID is
    list_index : Natural;
  begin
    require_parameter_specification (self, parameter);
    if index > parameter_defining_identifier_count (self, parameter) then
      raise Program_Error with
        "Adac.AST: parameter defining identifier index is out of range";
    end if;
    if index = 1 then
      return self.nodes(Positive(parameter.index)).parameter_symbol_value;
    end if;
    list_index :=
      self.nodes(Positive(parameter.index)).
        parameter_additional_defining_names_index_value;
    return program_unit_name_component_symbol
      (self.parameter_additional_defining_names (Positive(list_index)),
       index - 1);
  end parameter_defining_symbol_at;

  function parameter_defining_span_at
    (self      : Store;
     parameter : Node_ID;
     index     : Positive)
  return Adac.Source.Span is
    list_index : Natural;
  begin
    require_parameter_specification (self, parameter);
    if index > parameter_defining_identifier_count (self, parameter) then
      raise Program_Error with
        "Adac.AST: parameter defining identifier index is out of range";
    end if;
    if index = 1 then
      return
        self.nodes(Positive(parameter.index)).parameter_defining_span_value;
    end if;
    list_index :=
      self.nodes(Positive(parameter.index)).
        parameter_additional_defining_names_index_value;
    return program_unit_name_component_span
      (self.parameter_additional_defining_names (Positive(list_index)),
       index - 1);
  end parameter_defining_span_at;

  function parameter_symbol
    (self      : Store;
     parameter : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_parameter_specification (self, parameter);
    return self.nodes(Positive(parameter.index)).parameter_symbol_value;
  end parameter_symbol;

  function parameter_defining_span
    (self      : Store;
     parameter : Node_ID)
  return Adac.Source.Span is
  begin
    require_parameter_specification (self, parameter);
    return self.nodes
      (Positive(parameter.index)).parameter_defining_span_value;
  end parameter_defining_span;

  function parameter_mode
    (self      : Store;
     parameter : Node_ID)
  return Parameter_Mode_Kind is
  begin
    require_parameter_specification (self, parameter);
    return self.nodes(Positive(parameter.index)).parameter_mode_value;
  end parameter_mode;

  function parameter_subtype_mark
    (self      : Store;
     parameter : Node_ID)
  return Node_ID is
  begin
    require_parameter_specification (self, parameter);
    return self.nodes
      (Positive(parameter.index)).parameter_subtype_mark_value;
  end parameter_subtype_mark;

  function parameter_default_expression
    (self      : Store;
     parameter : Node_ID)
  return Node_ID is
  begin
    require_parameter_specification (self, parameter);
    return self.nodes
      (Positive(parameter.index)).parameter_default_expression_value;
  end parameter_default_expression;

  function object_form
    (self        : Store;
     declaration : Node_ID)
  return Object_Declaration_Form is
  begin
    require_object_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).object_form_value;
  end object_form;

  function object_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_object_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).object_symbol_value;
  end object_symbol;

  function object_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_object_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_defining_span_value;
  end object_defining_span;

  function object_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_object_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_subtype_mark_value;
  end object_subtype_mark;

  function object_has_index_constraint
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_object_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_index_constraint_value /=
      INVALID_NODE_ID;
  end object_has_index_constraint;

  function object_index_constraint
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_object_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_index_constraint_value;
  end object_index_constraint;

  function object_has_initializer
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_object_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).object_initializer_value /=
      INVALID_NODE_ID;
  end object_has_initializer;

  function object_initializer
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_object_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_initializer_value;
  end object_initializer;

  function object_renaming_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_object_renaming_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_renaming_symbol_value;
  end object_renaming_symbol;

  function object_renaming_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_object_renaming_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_renaming_defining_span_value;
  end object_renaming_defining_span;

  function object_renaming_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_object_renaming_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_renaming_subtype_mark_value;
  end object_renaming_subtype_mark;

  function object_renaming_name
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_object_renaming_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).object_renaming_name_value;
  end object_renaming_name;

  function number_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_number_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).number_symbol_value;
  end number_symbol;

  function number_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_number_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).number_defining_span_value;
  end number_defining_span;

  function number_initializer
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_number_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).number_initializer_value;
  end number_initializer;

  function exception_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_exception_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).exception_declaration_symbol_value;
  end exception_declaration_symbol;

  function exception_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_exception_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).exception_declaration_defining_span_value;
  end exception_declaration_defining_span;

  function procedure_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_procedure_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).procedure_declaration_symbol_value;
  end procedure_declaration_symbol;

  function procedure_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_procedure_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).procedure_declaration_defining_span_value;
  end procedure_declaration_defining_span;

  function procedure_declaration_parameter_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_procedure_declaration (self, declaration);
    return Natural
      (self.nodes
         (Positive(declaration.index)).procedure_declaration_parameters_value
           .length);
  end procedure_declaration_parameter_count;

  function procedure_declaration_parameter_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_procedure_declaration (self, declaration);
    if index > procedure_declaration_parameter_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: procedure parameter index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).procedure_declaration_parameters_value
        (index);
  end procedure_declaration_parameter_at;

  function procedure_body_stub_symbol
    (self : Store;
     stub : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_procedure_body_stub (self, stub);
    return self.nodes(Positive(stub.index)).procedure_body_stub_symbol_value;
  end procedure_body_stub_symbol;

  function procedure_body_stub_defining_span
    (self : Store;
     stub : Node_ID)
  return Adac.Source.Span is
  begin
    require_procedure_body_stub (self, stub);
    return self.nodes
      (Positive(stub.index)).procedure_body_stub_defining_span_value;
  end procedure_body_stub_defining_span;

  function procedure_body_stub_parameter_count
    (self : Store;
     stub : Node_ID)
  return Natural is
  begin
    require_procedure_body_stub (self, stub);
    return Natural
      (self.nodes(Positive(stub.index)).procedure_body_stub_parameters_value
         .length);
  end procedure_body_stub_parameter_count;

  function procedure_body_stub_parameter_at
    (self  : Store;
     stub  : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_procedure_body_stub (self, stub);
    if index > procedure_body_stub_parameter_count (self, stub) then
      raise Program_Error with
        "Adac.AST: procedure-body-stub parameter index is out of range";
    end if;
    return self.nodes(Positive(stub.index)).procedure_body_stub_parameters_value
      (index);
  end procedure_body_stub_parameter_at;

  function function_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_function_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).function_declaration_symbol_value;
  end function_declaration_symbol;

  function function_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_function_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).function_declaration_defining_span_value;
  end function_declaration_defining_span;

  function function_declaration_parameter_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_function_declaration (self, declaration);
    return Natural
      (self.nodes
         (Positive(declaration.index)).function_declaration_parameters_value
           .length);
  end function_declaration_parameter_count;

  function function_declaration_parameter_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_function_declaration (self, declaration);
    if index > function_declaration_parameter_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: function parameter index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).function_declaration_parameters_value
        (index);
  end function_declaration_parameter_at;

  function function_declaration_result_subtype
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_function_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).function_declaration_result_subtype_value;
  end function_declaration_result_subtype;

  function function_declaration_has_expression
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_function_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).function_declaration_expression_value /=
        INVALID_NODE_ID;
  end function_declaration_has_expression;

  function function_declaration_expression
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_function_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).function_declaration_expression_value;
  end function_declaration_expression;

  function function_declaration_has_aspect
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_function_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).function_declaration_aspect_value /=
        INVALID_NODE_ID;
  end function_declaration_has_aspect;

  function function_declaration_aspect
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_function_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).function_declaration_aspect_value;
  end function_declaration_aspect;

  function private_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_private_type_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).private_type_symbol_value;
  end private_type_symbol;

  function private_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_private_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).private_type_defining_span_value;
  end private_type_defining_span;

  function private_type_is_limited
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_private_type_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).private_type_limited_value;
  end private_type_is_limited;

  function private_type_discriminant_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_private_type_declaration (self, declaration);
    return Natural
      (self.nodes
         (Positive(declaration.index)).private_type_discriminants_value.length);
  end private_type_discriminant_count;

  function private_type_discriminant_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_private_type_declaration (self, declaration);
    if index > private_type_discriminant_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: private-type discriminant index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).private_type_discriminants_value(index);
  end private_type_discriminant_at;

  function derived_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_derived_type_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).derived_type_symbol_value;
  end derived_type_symbol;

  function derived_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_derived_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).derived_type_defining_span_value;
  end derived_type_defining_span;

  function derived_type_parent_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_derived_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).derived_type_parent_subtype_mark_value;
  end derived_type_parent_subtype_mark;

  function range_constraint_lower_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID is
  begin
    require_range_constraint (self, constraint);
    return self.nodes
      (Positive(constraint.index)).range_constraint_lower_bound_value;
  end range_constraint_lower_bound;

  function range_constraint_upper_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID is
  begin
    require_range_constraint (self, constraint);
    return self.nodes
      (Positive(constraint.index)).range_constraint_upper_bound_value;
  end range_constraint_upper_bound;

  function index_constraint_lower_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID is
  begin
    require_index_constraint (self, constraint);
    return self.nodes
      (Positive(constraint.index)).index_constraint_lower_bound_value;
  end index_constraint_lower_bound;

  function index_constraint_range_span
    (self       : Store;
     constraint : Node_ID)
  return Adac.Source.Span is
  begin
    require_index_constraint (self, constraint);
    return self.nodes
      (Positive(constraint.index)).index_constraint_range_span_value;
  end index_constraint_range_span;

  function index_constraint_upper_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID is
  begin
    require_index_constraint (self, constraint);
    return self.nodes
      (Positive(constraint.index)).index_constraint_upper_bound_value;
  end index_constraint_upper_bound;

  function subtype_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_subtype_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).subtype_declaration_symbol_value;
  end subtype_declaration_symbol;

  function subtype_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_subtype_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).subtype_declaration_defining_span_value;
  end subtype_declaration_defining_span;

  function subtype_declaration_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_subtype_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).subtype_declaration_subtype_mark_value;
  end subtype_declaration_subtype_mark;

  function subtype_declaration_has_constraint
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_subtype_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).subtype_declaration_constraint_value /=
      INVALID_NODE_ID;
  end subtype_declaration_has_constraint;

  function subtype_declaration_constraint
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_subtype_declaration (self, declaration);
    if not subtype_declaration_has_constraint (self, declaration) then
      raise Program_Error with
        "Adac.AST: subtype declaration has no constraint";
    end if;
    return self.nodes
      (Positive(declaration.index)).subtype_declaration_constraint_value;
  end subtype_declaration_constraint;

  function enumeration_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_enumeration_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).enumeration_type_symbol_value;
  end enumeration_type_symbol;

  function enumeration_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_enumeration_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).enumeration_type_defining_span_value;
  end enumeration_type_defining_span;

  function enumeration_literal_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_enumeration_type_declaration (self, declaration);
    return Natural
      (self.nodes
         (Positive(declaration.index)).enumeration_literals_value.length);
  end enumeration_literal_count;

  function enumeration_literal_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_enumeration_type_declaration (self, declaration);
    if index > enumeration_literal_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: enumeration literal index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).enumeration_literals_value(index).symbol;
  end enumeration_literal_symbol_at;

  function enumeration_literal_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    require_enumeration_type_declaration (self, declaration);
    if index > enumeration_literal_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: enumeration literal index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).enumeration_literals_value(index).span;
  end enumeration_literal_span_at;

  function discriminant_symbol
    (self         : Store;
     discriminant : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_discriminant_specification (self, discriminant);
    return self.nodes(Positive(discriminant.index)).discriminant_symbol_value;
  end discriminant_symbol;

  function discriminant_defining_span
    (self         : Store;
     discriminant : Node_ID)
  return Adac.Source.Span is
  begin
    require_discriminant_specification (self, discriminant);
    return self.nodes
      (Positive(discriminant.index)).discriminant_defining_span_value;
  end discriminant_defining_span;

  function discriminant_subtype_mark
    (self         : Store;
     discriminant : Node_ID)
  return Node_ID is
  begin
    require_discriminant_specification (self, discriminant);
    return self.nodes
      (Positive(discriminant.index)).discriminant_subtype_mark_value;
  end discriminant_subtype_mark;

  function discriminant_has_default_expression
    (self         : Store;
     discriminant : Node_ID)
  return Boolean is
  begin
    require_discriminant_specification (self, discriminant);
    return self.nodes(Positive(discriminant.index))
      .discriminant_default_expression_value /= INVALID_NODE_ID;
  end discriminant_has_default_expression;

  function discriminant_default_expression
    (self         : Store;
     discriminant : Node_ID)
  return Node_ID is
  begin
    require_discriminant_specification (self, discriminant);
    if not discriminant_has_default_expression (self, discriminant) then
      raise Program_Error with
        "Adac.AST: discriminant has no default expression";
    end if;
    return self.nodes(Positive(discriminant.index))
      .discriminant_default_expression_value;
  end discriminant_default_expression;

  function record_component_symbol
    (self      : Store;
     component : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_record_component_declaration (self, component);
    return self.nodes
      (Positive(component.index)).record_component_symbol_value;
  end record_component_symbol;

  function record_component_defining_span
    (self      : Store;
     component : Node_ID)
  return Adac.Source.Span is
  begin
    require_record_component_declaration (self, component);
    return self.nodes
      (Positive(component.index)).record_component_defining_span_value;
  end record_component_defining_span;

  function record_component_is_aliased
    (self      : Store;
     component : Node_ID)
  return Boolean is
  begin
    require_record_component_declaration (self, component);
    return self.nodes(Positive(component.index)).record_component_aliased_value;
  end record_component_is_aliased;

  function record_component_subtype_mark
    (self      : Store;
     component : Node_ID)
  return Node_ID is
  begin
    require_record_component_declaration (self, component);
    return self.nodes
      (Positive(component.index)).record_component_subtype_mark_value;
  end record_component_subtype_mark;

  function record_component_has_default_expression
    (self      : Store;
     component : Node_ID)
  return Boolean is
  begin
    require_record_component_declaration (self, component);
    return self.nodes
      (Positive(component.index)).record_component_default_expression_value /=
        INVALID_NODE_ID;
  end record_component_has_default_expression;

  function record_component_default_expression
    (self      : Store;
     component : Node_ID)
  return Node_ID is
  begin
    require_record_component_declaration (self, component);
    if not record_component_has_default_expression (self, component) then
      raise Program_Error with
        "Adac.AST: record component has no default expression";
    end if;
    return self.nodes
      (Positive(component.index)).record_component_default_expression_value;
  end record_component_default_expression;

  function record_variant_choice_count
    (self    : Store;
     variant : Node_ID)
  return Natural is
  begin
    require_record_variant (self, variant);
    return Natural
      (self.nodes(Positive(variant.index)).record_variant_choices_value.length);
  end record_variant_choice_count;

  function record_variant_choice_at
    (self    : Store;
     variant : Node_ID;
     index   : Positive)
  return Node_ID is
  begin
    require_record_variant (self, variant);
    if index > record_variant_choice_count (self, variant) then
      raise Program_Error with
        "Adac.AST: record variant choice index out of range";
    end if;
    return self.nodes(Positive(variant.index))
      .record_variant_choices_value(index);
  end record_variant_choice_at;

  function record_variant_has_null_component_list
    (self    : Store;
     variant : Node_ID)
  return Boolean is
  begin
    require_record_variant (self, variant);
    return self.nodes(Positive(variant.index))
      .record_variant_null_component_list_value;
  end record_variant_has_null_component_list;

  function record_variant_component_count
    (self    : Store;
     variant : Node_ID)
  return Natural is
  begin
    require_record_variant (self, variant);
    return Natural
      (self.nodes(Positive(variant.index))
         .record_variant_components_value.length);
  end record_variant_component_count;

  function record_variant_component_at
    (self    : Store;
     variant : Node_ID;
     index   : Positive)
  return Node_ID is
  begin
    require_record_variant (self, variant);
    if index > record_variant_component_count (self, variant) then
      raise Program_Error with
        "Adac.AST: record variant component index out of range";
    end if;
    return self.nodes(Positive(variant.index))
      .record_variant_components_value(index);
  end record_variant_component_at;

  function record_variant_part_discriminant_name
    (self         : Store;
     variant_part : Node_ID)
  return Node_ID is
  begin
    require_record_variant_part (self, variant_part);
    return self.nodes(Positive(variant_part.index))
      .record_variant_part_discriminant_name_value;
  end record_variant_part_discriminant_name;

  function record_variant_part_variant_count
    (self         : Store;
     variant_part : Node_ID)
  return Natural is
  begin
    require_record_variant_part (self, variant_part);
    return Natural
      (self.nodes(Positive(variant_part.index))
         .record_variant_part_variants_value.length);
  end record_variant_part_variant_count;

  function record_variant_part_variant_at
    (self         : Store;
     variant_part : Node_ID;
     index        : Positive)
  return Node_ID is
  begin
    require_record_variant_part (self, variant_part);
    if index > record_variant_part_variant_count (self, variant_part) then
      raise Program_Error with "Adac.AST: record variant index out of range";
    end if;
    return self.nodes(Positive(variant_part.index))
      .record_variant_part_variants_value(index);
  end record_variant_part_variant_at;

  function record_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_record_type_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).record_type_symbol_value;
  end record_type_symbol;

  function record_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_record_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).record_type_defining_span_value;
  end record_type_defining_span;

  function record_type_is_limited
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_record_type_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).record_type_limited_value;
  end record_type_is_limited;

  function record_has_variant_part
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_record_type_declaration (self, declaration);
    return self.nodes(Positive(declaration.index)).record_variant_part_value /=
      INVALID_NODE_ID;
  end record_has_variant_part;

  function record_variant_part
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_record_type_declaration (self, declaration);
    if not record_has_variant_part (self, declaration) then
      raise Program_Error with "Adac.AST: record has no variant part";
    end if;
    return self.nodes(Positive(declaration.index)).record_variant_part_value;
  end record_variant_part;

  function record_discriminant_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_record_type_declaration (self, declaration);
    return Natural
      (self.nodes(Positive(declaration.index))
         .record_discriminants_value.length);
  end record_discriminant_count;

  function record_discriminant_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_record_type_declaration (self, declaration);
    if index > record_discriminant_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: record discriminant index is out of range";
    end if;
    return self.nodes(Positive(declaration.index))
      .record_discriminants_value(index);
  end record_discriminant_at;

  function record_component_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_record_type_declaration (self, declaration);
    return Natural
      (self.nodes(Positive(declaration.index)).record_components_value.length);
  end record_component_count;

  function record_component_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_record_type_declaration (self, declaration);
    if index > record_component_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: record component index is out of range";
    end if;
    return self.nodes(Positive(declaration.index))
      .record_components_value(index);
  end record_component_at;

  function access_object_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_access_object_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).access_object_type_symbol_value;
  end access_object_type_symbol;

  function access_object_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_access_object_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).access_object_type_defining_span_value;
  end access_object_type_defining_span;

  function access_object_type_modifier
    (self        : Store;
     declaration : Node_ID)
  return General_Access_Modifier_Kind is
  begin
    require_access_object_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).access_object_type_modifier_value;
  end access_object_type_modifier;

  function access_object_type_designated_subtype
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_access_object_type_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).access_object_type_designated_subtype_value;
  end access_object_type_designated_subtype;

  function package_renaming_defining_name_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_package_renaming_declaration (self, declaration);
    return Natural
      (self.nodes(Positive(declaration.index))
         .package_renaming_defining_name_value.length);
  end package_renaming_defining_name_count;

  function package_renaming_defining_name_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_renaming_declaration (self, declaration);
    if index > package_renaming_defining_name_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package renaming defining-name index is out of range";
    end if;
    return self.nodes(Positive(declaration.index))
      .package_renaming_defining_name_value(index).symbol;
  end package_renaming_defining_name_symbol_at;

  function package_renaming_defining_name_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    require_package_renaming_declaration (self, declaration);
    if index > package_renaming_defining_name_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package renaming defining-name index is out of range";
    end if;
    return self.nodes(Positive(declaration.index))
      .package_renaming_defining_name_value(index).span;
  end package_renaming_defining_name_span_at;

  function package_renaming_renamed_package
    (self        : Store;
     declaration : Node_ID)
  return Node_ID is
  begin
    require_package_renaming_declaration (self, declaration);
    return self.nodes(Positive(declaration.index))
      .package_renaming_renamed_package_value;
  end package_renaming_renamed_package;

  function package_instantiation_defining_name_count
    (self          : Store;
     instantiation : Node_ID)
  return Natural is
  begin
    require_package_instantiation (self, instantiation);
    return Natural
      (self.nodes(Positive(instantiation.index))
         .package_instantiation_defining_name_value.length);
  end package_instantiation_defining_name_count;

  function package_instantiation_defining_name_symbol_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_instantiation (self, instantiation);
    if index > package_instantiation_defining_name_count
      (self, instantiation)
    then
      raise Program_Error with
        "Adac.AST: package instantiation defining-name index is out of range";
    end if;
    return self.nodes(Positive(instantiation.index))
      .package_instantiation_defining_name_value(index).symbol;
  end package_instantiation_defining_name_symbol_at;

  function package_instantiation_defining_name_span_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Source.Span is
  begin
    require_package_instantiation (self, instantiation);
    if index > package_instantiation_defining_name_count
      (self, instantiation)
    then
      raise Program_Error with
        "Adac.AST: package instantiation defining-name index is out of range";
    end if;
    return self.nodes(Positive(instantiation.index))
      .package_instantiation_defining_name_value(index).span;
  end package_instantiation_defining_name_span_at;

  function package_instantiation_generic_name
    (self          : Store;
     instantiation : Node_ID)
  return Node_ID is
  begin
    require_package_instantiation (self, instantiation);
    return self.nodes(Positive(instantiation.index))
      .package_instantiation_generic_name_value;
  end package_instantiation_generic_name;

  function package_instantiation_actual_count
    (self          : Store;
     instantiation : Node_ID)
  return Natural is
  begin
    require_package_instantiation (self, instantiation);
    return Natural
      (self.nodes(Positive(instantiation.index))
         .package_instantiation_actuals_value.length);
  end package_instantiation_actual_count;

  function package_instantiation_actual_form_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Generic_Actual_Association_Form is
  begin
    require_package_instantiation (self, instantiation);
    if index > package_instantiation_actual_count (self, instantiation) then
      raise Program_Error with
        "Adac.AST: package instantiation actual index is out of range";
    end if;
    return self.nodes(Positive(instantiation.index))
      .package_instantiation_actuals_value(index).form;
  end package_instantiation_actual_form_at;

  function package_instantiation_actual_selector_symbol_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_instantiation (self, instantiation);
    if index > package_instantiation_actual_count (self, instantiation) then
      raise Program_Error with
        "Adac.AST: package instantiation actual index is out of range";
    end if;
    if self.nodes(Positive(instantiation.index))
      .package_instantiation_actuals_value(index).form /=
        Named_Generic_Actual_Form
    then
      raise Program_Error with
        "Adac.AST: positional package actual has no selector symbol";
    end if;
    return self.nodes(Positive(instantiation.index))
      .package_instantiation_actuals_value(index).selector;
  end package_instantiation_actual_selector_symbol_at;

  function package_instantiation_actual_selector_span_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Source.Span is
  begin
    require_package_instantiation (self, instantiation);
    if index > package_instantiation_actual_count (self, instantiation) then
      raise Program_Error with
        "Adac.AST: package instantiation actual index is out of range";
    end if;
    if self.nodes(Positive(instantiation.index))
      .package_instantiation_actuals_value(index).form /=
        Named_Generic_Actual_Form
    then
      raise Program_Error with
        "Adac.AST: positional package actual has no selector span";
    end if;
    return self.nodes(Positive(instantiation.index))
      .package_instantiation_actuals_value(index).selector_span;
  end package_instantiation_actual_selector_span_at;

  function package_instantiation_actual_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Node_ID is
  begin
    require_package_instantiation (self, instantiation);
    if index > package_instantiation_actual_count (self, instantiation) then
      raise Program_Error with
        "Adac.AST: package instantiation actual index is out of range";
    end if;
    return self.nodes(Positive(instantiation.index))
      .package_instantiation_actuals_value(index).actual;
  end package_instantiation_actual_at;

  function package_defining_name_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_package_declaration (self, declaration);
    return Natural
      (self.nodes
         (Positive(declaration.index)).package_defining_name_value.length);
  end package_defining_name_count;

  function package_defining_name_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_declaration (self, declaration);
    if index > package_defining_name_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package defining-name index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).package_defining_name_value(index).symbol;
  end package_defining_name_symbol_at;

  function package_defining_name_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    require_package_declaration (self, declaration);
    if index > package_defining_name_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package defining-name index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).package_defining_name_value(index).span;
  end package_defining_name_span_at;

  function package_visible_declaration_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_package_declaration (self, declaration);
    return Natural
      (self.nodes(Positive(declaration.index))
         .package_visible_declarations_value.length);
  end package_visible_declaration_count;

  function package_visible_declaration_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_package_declaration (self, declaration);
    if index > package_visible_declaration_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package visible declaration index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).package_visible_declarations_value(index);
  end package_visible_declaration_at;

  function package_has_explicit_private_part
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    require_package_declaration (self, declaration);
    return self.nodes
      (Positive(declaration.index)).package_private_part_span_value /=
        Adac.Source.INVALID_SPAN;
  end package_has_explicit_private_part;

  function package_private_part_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span is
  begin
    require_package_declaration (self, declaration);
    if not package_has_explicit_private_part (self, declaration) then
      raise Program_Error with
        "Adac.AST: package has no explicit private part";
    end if;
    return self.nodes
      (Positive(declaration.index)).package_private_part_span_value;
  end package_private_part_span;

  function package_private_declaration_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_package_declaration (self, declaration);
    return Natural
      (self.nodes(Positive(declaration.index))
         .package_private_declarations_value.length);
  end package_private_declaration_count;

  function package_private_declaration_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID is
  begin
    require_package_declaration (self, declaration);
    if index > package_private_declaration_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package private declaration index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).package_private_declarations_value(index);
  end package_private_declaration_at;

  function package_has_end_designator
    (self        : Store;
     declaration : Node_ID)
  return Boolean is
  begin
    return package_end_name_count (self, declaration) /= 0;
  end package_has_end_designator;

  function package_end_name_count
    (self        : Store;
     declaration : Node_ID)
  return Natural is
  begin
    require_package_declaration (self, declaration);
    return Natural
      (self.nodes(Positive(declaration.index)).package_end_name_value.length);
  end package_end_name_count;

  function package_end_name_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_declaration (self, declaration);
    if index > package_end_name_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package closing-name index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).package_end_name_value(index).symbol;
  end package_end_name_symbol_at;

  function package_end_name_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    require_package_declaration (self, declaration);
    if index > package_end_name_count (self, declaration) then
      raise Program_Error with
        "Adac.AST: package closing-name index is out of range";
    end if;
    return self.nodes
      (Positive(declaration.index)).package_end_name_value(index).span;
  end package_end_name_span_at;

  function package_body_stub_symbol
    (self : Store;
     stub : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_body_stub (self, stub);
    return self.nodes(Positive(stub.index)).package_body_stub_symbol_value;
  end package_body_stub_symbol;

  function package_body_stub_defining_span
    (self : Store;
     stub : Node_ID)
  return Adac.Source.Span is
  begin
    require_package_body_stub (self, stub);
    return self.nodes
      (Positive(stub.index)).package_body_stub_defining_span_value;
  end package_body_stub_defining_span;

  function package_body_defining_name_count
    (self : Store;
     package_body : Node_ID)
  return Natural is
  begin
    require_package_body (self, package_body);
    return Natural
      (self.nodes
         (Positive(package_body.index)).body_defining_name_value.length);
  end package_body_defining_name_count;

  function package_body_defining_name_symbol_at
    (self  : Store;
     package_body  : Node_ID;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_body (self, package_body);
    if index > package_body_defining_name_count (self, package_body) then
      raise Program_Error with
        "Adac.AST: package-body defining-name index is out of range";
    end if;
    return self.nodes
      (Positive(package_body.index)).body_defining_name_value(index).symbol;
  end package_body_defining_name_symbol_at;

  function package_body_defining_name_span_at
    (self  : Store;
     package_body  : Node_ID;
     index : Positive)
  return Adac.Source.Span is
  begin
    require_package_body (self, package_body);
    if index > package_body_defining_name_count (self, package_body) then
      raise Program_Error with
        "Adac.AST: package-body defining-name index is out of range";
    end if;
    return self.nodes
      (Positive(package_body.index)).body_defining_name_value(index).span;
  end package_body_defining_name_span_at;

  function package_body_declaration_count
    (self : Store;
     package_body : Node_ID)
  return Natural is
  begin
    require_package_body (self, package_body);
    return Natural
      (self.nodes
         (Positive(package_body.index)).body_declarations_value.length);
  end package_body_declaration_count;

  function package_body_declaration_at
    (self  : Store;
     package_body  : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_package_body (self, package_body);
    if index > package_body_declaration_count (self, package_body) then
      raise Program_Error with
        "Adac.AST: package-body declaration index is out of range";
    end if;
    return self.nodes
      (Positive(package_body.index)).body_declarations_value(index);
  end package_body_declaration_at;

  function package_body_has_end_designator
    (self : Store;
     package_body : Node_ID)
  return Boolean is
  begin
    return package_body_end_name_count (self, package_body) /= 0;
  end package_body_has_end_designator;

  function package_body_end_name_count
    (self : Store;
     package_body : Node_ID)
  return Natural is
  begin
    require_package_body (self, package_body);
    return Natural
      (self.nodes(Positive(package_body.index)).body_end_name_value.length);
  end package_body_end_name_count;

  function package_body_end_name_symbol_at
    (self  : Store;
     package_body  : Node_ID;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_package_body (self, package_body);
    if index > package_body_end_name_count (self, package_body) then
      raise Program_Error with
        "Adac.AST: package-body closing-name index is out of range";
    end if;
    return self.nodes
      (Positive(package_body.index)).body_end_name_value(index).symbol;
  end package_body_end_name_symbol_at;

  function package_body_end_name_span_at
    (self  : Store;
     package_body  : Node_ID;
     index : Positive)
  return Adac.Source.Span is
  begin
    require_package_body (self, package_body);
    if index > package_body_end_name_count (self, package_body) then
      raise Program_Error with
        "Adac.AST: package-body closing-name index is out of range";
    end if;
    return self.nodes
      (Positive(package_body.index)).body_end_name_value(index).span;
  end package_body_end_name_span_at;

  function with_clause_name_count
    (self   : Store;
     clause : Node_ID)
  return Natural is
  begin
    require_with_clause (self, clause);
    return Natural(self.nodes(Positive(clause.index)).library_names.length);
  end with_clause_name_count;

  function with_clause_name_at
    (self   : Store;
     clause : Node_ID;
     index  : Positive)
  return Node_ID is
  begin
    require_with_clause (self, clause);

    if index > with_clause_name_count (self, clause) then
      raise Program_Error with
        "Adac.AST: with-clause name index is out of range";
    end if;

    return self.nodes(Positive(clause.index)).library_names(index);
  end with_clause_name_at;

  function use_type_subtype_mark_count
    (self   : Store;
     clause : Node_ID)
  return Natural is
  begin
    require_use_type_clause (self, clause);
    return Natural
      (self.nodes
         (Positive(clause.index)).use_type_subtype_marks_value.length);
  end use_type_subtype_mark_count;

  function use_type_subtype_mark_at
    (self   : Store;
     clause : Node_ID;
     index  : Positive)
  return Node_ID is
  begin
    require_use_type_clause (self, clause);
    if index > use_type_subtype_mark_count (self, clause) then
      raise Program_Error with
        "Adac.AST: use-type subtype-mark index is out of range";
    end if;
    return self.nodes
      (Positive(clause.index)).use_type_subtype_marks_value(index);
  end use_type_subtype_mark_at;

  function use_package_name_count
    (self   : Store;
     clause : Node_ID)
  return Natural is
  begin
    require_use_package_clause (self, clause);
    return Natural
      (self.nodes(Positive(clause.index)).use_package_names_value.length);
  end use_package_name_count;

  function use_package_name_at
    (self   : Store;
     clause : Node_ID;
     index  : Positive)
  return Node_ID is
  begin
    require_use_package_clause (self, clause);
    if index > use_package_name_count (self, clause) then
      raise Program_Error with
        "Adac.AST: package-use name index is out of range";
    end if;
    return self.nodes(Positive(clause.index)).use_package_names_value(index);
  end use_package_name_at;

  function context_item_count
    (self : Store;
     unit : Node_ID)
  return Natural is
  begin
    require_compilation_unit (self, unit);
    return Natural(self.nodes(Positive(unit.index)).context_items.length);
  end context_item_count;

  function context_item_at
    (self  : Store;
     unit  : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_compilation_unit (self, unit);

    if index > context_item_count (self, unit) then
      raise Program_Error with "Adac.AST: context-item index is out of range";
    end if;

    return self.nodes(Positive(unit.index)).context_items(index);
  end context_item_at;

  function unit_item
    (self : Store;
     unit : Node_ID)
  return Node_ID is
  begin
    require_compilation_unit (self, unit);
    return self.nodes(Positive(unit.index)).unit_item_value;
  end unit_item;

  function library_item
    (self : Store;
     unit : Node_ID)
  return Node_ID is
    item : constant Node_ID := unit_item (self, unit);
  begin
    if self.nodes(Positive(item.index)).kind = Subunit_Node then
      raise Program_Error with
        "Adac.AST: compilation unit contains a subunit, not a library item";
    end if;
    return item;
  end library_item;

  function subunit_parent_name_count
    (self    : Store;
     subunit : Node_ID)
  return Natural is
  begin
    require_subunit (self, subunit);
    return Natural
      (self.nodes(Positive(subunit.index)).subunit_parent_name_value.length);
  end subunit_parent_name_count;

  function subunit_parent_name_symbol_at
    (self    : Store;
     subunit : Node_ID;
     index   : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    require_subunit (self, subunit);
    if index > subunit_parent_name_count (self, subunit) then
      raise Program_Error with
        "Adac.AST: subunit parent-name index is out of range";
    end if;
    return self.nodes(Positive(subunit.index))
      .subunit_parent_name_value(index).symbol;
  end subunit_parent_name_symbol_at;

  function subunit_parent_name_span_at
    (self    : Store;
     subunit : Node_ID;
     index   : Positive)
  return Adac.Source.Span is
  begin
    require_subunit (self, subunit);
    if index > subunit_parent_name_count (self, subunit) then
      raise Program_Error with
        "Adac.AST: subunit parent-name index is out of range";
    end if;
    return self.nodes(Positive(subunit.index))
      .subunit_parent_name_value(index).span;
  end subunit_parent_name_span_at;

  function subunit_proper_body
    (self    : Store;
     subunit : Node_ID)
  return Node_ID is
  begin
    require_subunit (self, subunit);
    return self.nodes(Positive(subunit.index)).subunit_proper_body_value;
  end subunit_proper_body;

  function procedure_symbol
    (self : Store;
     procedure_body : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_procedure_body (self, procedure_body);
    return self.nodes(Positive(procedure_body.index)).procedure_symbol;
  end procedure_symbol;

  function has_end_designator
    (self : Store;
     procedure_body : Node_ID)
  return Boolean is
  begin
    require_procedure_body (self, procedure_body);
    return self.nodes(Positive(procedure_body.index)).end_symbol /=
      Adac.Symbols.INVALID_SYMBOL_ID;
  end has_end_designator;

  function end_symbol
    (self : Store;
     procedure_body : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_procedure_body (self, procedure_body);
    return self.nodes(Positive(procedure_body.index)).end_symbol;
  end end_symbol;

  function parameter_count
    (self : Store;
     procedure_body : Node_ID)
  return Natural is
  begin
    require_procedure_body (self, procedure_body);
    return Natural
      (self.nodes(Positive(procedure_body.index)).parameters.length);
  end parameter_count;

  function parameter_at
    (self : Store;
     procedure_body : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_procedure_body (self, procedure_body);
    if index > parameter_count (self, procedure_body) then
      raise Program_Error with "Adac.AST: parameter index is out of range";
    end if;
    return self.nodes(Positive(procedure_body.index)).parameters(index);
  end parameter_at;

  function declaration_count
    (self : Store;
     procedure_body : Node_ID)
  return Natural is
  begin
    require_procedure_body (self, procedure_body);
    return Natural
      (self.nodes(Positive(procedure_body.index)).declarations.length);
  end declaration_count;

  function declaration_at
    (self : Store;
     procedure_body : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_procedure_body (self, procedure_body);
    if index > declaration_count (self, procedure_body) then
      raise Program_Error with "Adac.AST: declaration index is out of range";
    end if;
    return self.nodes(Positive(procedure_body.index)).declarations(index);
  end declaration_at;

  function procedure_handled_sequence
    (self : Store;
     procedure_body : Node_ID)
  return Node_ID is
  begin
    require_procedure_body (self, procedure_body);
    return self.nodes
      (Positive(procedure_body.index)).procedure_handled_sequence_value;
  end procedure_handled_sequence;

  function statement_count
    (self : Store;
     procedure_body : Node_ID)
  return Natural is
  begin
    return handled_sequence_statement_count
      (self, procedure_handled_sequence (self, procedure_body));
  end statement_count;

  function statement_at
    (self  : Store;
     procedure_body : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    return handled_sequence_statement_at
      (self, procedure_handled_sequence (self, procedure_body), index);
  end statement_at;

  function function_body_symbol
    (self          : Store;
     function_body : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_function_body (self, function_body);
    return self.nodes(Positive(function_body.index)).function_body_symbol_value;
  end function_body_symbol;

  function function_body_parameter_count
    (self          : Store;
     function_body : Node_ID)
  return Natural is
  begin
    require_function_body (self, function_body);
    return Natural
      (self.nodes(Positive(function_body.index))
         .function_body_parameters_value.length);
  end function_body_parameter_count;

  function function_body_parameter_at
    (self          : Store;
     function_body : Node_ID;
     index         : Positive)
  return Node_ID is
  begin
    require_function_body (self, function_body);
    if index > function_body_parameter_count (self, function_body) then
      raise Program_Error with
        "Adac.AST: function parameter index is out of range";
    end if;
    return self.nodes(Positive(function_body.index))
      .function_body_parameters_value(index);
  end function_body_parameter_at;

  function function_body_declaration_count
    (self          : Store;
     function_body : Node_ID)
  return Natural is
  begin
    require_function_body (self, function_body);
    return Natural
      (self.nodes(Positive(function_body.index))
         .function_body_declarations_value.length);
  end function_body_declaration_count;

  function function_body_declaration_at
    (self          : Store;
     function_body : Node_ID;
     index         : Positive)
  return Node_ID is
  begin
    require_function_body (self, function_body);
    if index > function_body_declaration_count (self, function_body) then
      raise Program_Error with
        "Adac.AST: function declaration index is out of range";
    end if;
    return self.nodes(Positive(function_body.index))
      .function_body_declarations_value(index);
  end function_body_declaration_at;

  function function_body_result_subtype
    (self          : Store;
     function_body : Node_ID)
  return Node_ID is
  begin
    require_function_body (self, function_body);
    return self.nodes(Positive(function_body.index))
      .function_body_result_subtype_value;
  end function_body_result_subtype;

  function function_body_handled_sequence
    (self          : Store;
     function_body : Node_ID)
  return Node_ID is
  begin
    require_function_body (self, function_body);
    return self.nodes(Positive(function_body.index))
      .function_body_handled_sequence_value;
  end function_body_handled_sequence;

  function function_body_has_end_designator
    (self          : Store;
     function_body : Node_ID)
  return Boolean is
  begin
    require_function_body (self, function_body);
    return self.nodes(Positive(function_body.index))
      .function_body_end_symbol_value /= Adac.Symbols.INVALID_SYMBOL_ID;
  end function_body_has_end_designator;

  function function_body_end_symbol
    (self          : Store;
     function_body : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_function_body (self, function_body);
    return self.nodes(Positive(function_body.index))
      .function_body_end_symbol_value;
  end function_body_end_symbol;

  procedure validate (node : Node_ID) is
  begin
    if node.owner = null or else node.index = 0 then
      raise Program_Error with "Adac.AST: invalid node identifier";
    end if;
  end validate;

  package body Validation_Implementation is separate;

end Adac.AST;
