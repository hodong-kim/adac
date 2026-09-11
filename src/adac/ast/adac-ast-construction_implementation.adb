-- ============================================================================
-- adac-ast-construction_implementation.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.AST)
package body Construction_Implementation is

  function append_numeric_literal
    (self          : in out Store;
     form          : Numeric_Literal_Kind;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    validate_numeric_literal_shape (spelling, span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind             => Numeric_Literal_Node,
             span             => span,
             numeric_form     => form,
             numeric_spelling =>
               Ada.Strings.Unbounded.to_unbounded_string (spelling)));
    return result;
  end append_numeric_literal;

  function append_character_literal
    (self          : in out Store;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    validate_character_literal_shape (spelling, span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind               => Character_Literal_Node,
             span               => span,
             character_spelling =>
               Ada.Strings.Unbounded.to_unbounded_string (spelling)));
    return result;
  end append_character_literal;

  function append_string_literal
    (self          : in out Store;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    validate_string_literal_shape (spelling, span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind            => String_Literal_Node,
             span            => span,
             string_spelling =>
               Ada.Strings.Unbounded.to_unbounded_string (spelling)));
    return result;
  end append_string_literal;

  function append_null_literal
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append (Node'(kind => Null_Literal_Node, span => span));
    return result;
  end append_null_literal;

  function append_record_aggregate
    (self          : in out Store;
     associations  : Record_Component_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position := Adac.Source.first_position (span);
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if associations.associations.is_empty then
      raise Program_Error with
        "Adac.AST: record aggregate association list is empty";
    end if;

    for association of associations.associations loop
      Adac.Symbols.validate (association.selector);
      Adac.Source.validate (association.selector_span);
      require_record_aggregate_value (self, association.expression);

      declare
        expression_span : constant Adac.Source.Span :=
          self.nodes(Positive(association.expression.index)).span;
      begin
        Adac.Source.validate (expression_span);
        if not Adac.Source.contains (span, association.selector_span) or else
           not Adac.Source.contains (span, expression_span) or else
           not precedes
             (previous_last,
              Adac.Source.first_position (association.selector_span)) or else
           not precedes
             (Adac.Source.last_position (association.selector_span),
              Adac.Source.first_position (expression_span))
        then
          raise Program_Error with
            "Adac.AST: record aggregate association is out of source order";
        end if;
        previous_last := Adac.Source.last_position (expression_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: record aggregate span misses its closing delimiter";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Record_Aggregate_Node,
             span => span,
             record_aggregate_associations_value => associations.associations));
    return result;
  end append_record_aggregate;

  function append_array_aggregate
    (self          : in out Store;
     associations  : Array_Component_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position := Adac.Source.first_position (span);

    procedure validate_choices (association : Array_Component_Association) is
    begin
      if association.choices.is_empty then
        raise Program_Error with
          "Adac.AST: array aggregate choice list is empty";
      end if;

      for choice of association.choices loop
        require_nonaggregate_simple_expression (self, choice);
        declare
          choice_span : constant Adac.Source.Span :=
            self.nodes(Positive(choice.index)).span;
        begin
          Adac.Source.validate (choice_span);
          if not Adac.Source.contains (span, choice_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (choice_span))
          then
            raise Program_Error with
              "Adac.AST: array aggregate choice is out of source order";
          end if;
          previous_last := Adac.Source.last_position (choice_span);
        end;
      end loop;
    end validate_choices;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if associations.associations.is_empty then
      raise Program_Error with
        "Adac.AST: array aggregate association list is empty";
    end if;

    for association of associations.associations loop
      validate_choices (association);
      require_nonaggregate_simple_expression (self, association.expression);
      declare
        expression_span : constant Adac.Source.Span :=
          self.nodes(Positive(association.expression.index)).span;
      begin
        Adac.Source.validate (expression_span);
        if not Adac.Source.contains (span, expression_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (expression_span))
        then
          raise Program_Error with
            "Adac.AST: array aggregate value is out of source order";
        end if;
        previous_last := Adac.Source.last_position (expression_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: array aggregate span misses its closing delimiter";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Array_Aggregate_Node,
             span => span,
             array_aggregate_associations_value => associations.associations));
    return result;
  end append_array_aggregate;

  function append_bracket_aggregate
    (self          : in out Store;
     expressions   : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
    first_child   : Boolean := True;
  begin
    validate_store (self);
    if expressions.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: bracket aggregate expression list is empty";
    end if;
    Adac.Source.validate (span);
    previous_last := Adac.Source.first_position (span);

    for expression of expressions.nodes loop
      require_allocator (self, expression);
      Structural_Validation.validate_allocator (self, expression);
      declare
        child_span : constant Adac.Source.Span := node_span (self, expression);
      begin
        if not Adac.Source.contains (span, child_span) or else
           (if first_child then
              not precedes
                (Adac.Source.first_position (span),
                 Adac.Source.first_position (child_span))
            else
              not precedes
                (previous_last, Adac.Source.first_position (child_span)))
        then
          raise Program_Error with
            "Adac.AST: bracket aggregate expressions are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
        first_child := False;
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: bracket aggregate span misses its closing delimiter";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Bracket_Aggregate_Node,
             span => span,
             bracket_aggregate_expressions_value => expressions.nodes));
    return result;
  end append_bracket_aggregate;

  function append_qualified_expression
    (self          : in out Store;
     subtype_mark  : Node_ID;
     operand       : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result       : Node_ID;
    subtype_span : Adac.Source.Span;
    operand_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_simple_name (self, subtype_mark);
    validate_node_id (self, operand);
    Structural_Validation.validate_name (self, subtype_mark);
    declare
      operand_kind : constant Node_Kind :=
        self.nodes(Positive(operand.index)).kind;
    begin
      if operand_kind = Record_Aggregate_Node then
        Structural_Validation.validate_record_aggregate (self, operand);
      elsif operand_kind = Array_Aggregate_Node then
        Structural_Validation.validate_array_aggregate (self, operand);
      elsif is_current_qualified_operand_kind (operand_kind)
      then
        require_nonaggregate_simple_expression (self, operand);
        Structural_Validation.validate_expression (self, operand);
      else
        raise Program_Error with
          "Adac.AST: qualified-expression operand is outside current subset";
      end if;
    end;
    Adac.Source.validate (span);
    subtype_span := node_span (self, subtype_mark);
    operand_span := node_span (self, operand);

    if subtype_mark.index >= operand.index then
      raise Program_Error with
        "Adac.AST: qualified-expression children are not ordered";
    end if;
    if not Adac.Source.contains (span, subtype_span) or else
       not Adac.Source.contains (span, operand_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (subtype_span) or else
       not precedes
         (Adac.Source.last_position (subtype_span),
          Adac.Source.first_position (operand_span))
    then
      raise Program_Error with
        "Adac.AST: qualified-expression children are out of source order";
    end if;

    if self.nodes(Positive(operand.index)).kind in
      Record_Aggregate_Node | Array_Aggregate_Node
    then
      if Adac.Source.last_position (span) /=
         Adac.Source.last_position (operand_span)
      then
        raise Program_Error with
          "Adac.AST: qualified aggregate does not end at its operand";
      end if;
    elsif not precedes
      (Adac.Source.last_position (operand_span),
       Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: qualified direct operand does not precede " &
          "its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Qualified_Expression_Node,
             span => span,
             qualified_expression_subtype_mark_value => subtype_mark,
             qualified_expression_operand_value => operand));
    return result;
  end append_qualified_expression;

  function append_allocator
    (self          : in out Store;
     new_span      : Adac.Source.Span;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    child_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_qualified_expression (self, expression);
    Structural_Validation.validate_qualified_expression (self, expression);
    validate_new_span (new_span);
    Adac.Source.validate (span);
    child_span := node_span (self, expression);

    if expression.index >= next_node_id (self).index or else
       not Adac.Source.contains (span, new_span) or else
       not Adac.Source.contains (span, child_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (new_span) or else
       not precedes
         (Adac.Source.last_position (new_span),
          Adac.Source.first_position (child_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (child_span)
    then
      raise Program_Error with
        "Adac.AST: allocator child is out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Allocator_Node,
             span => span,
             allocator_new_span_value => new_span,
             allocator_expression_value => expression));
    return result;
  end append_allocator;

  function append_if_expression
    (self            : in out Store;
     condition       : Node_ID;
     then_expression : Node_ID;
     else_expression : Node_ID;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
    result    : Node_ID;
    cond_span : Adac.Source.Span;
    then_span : Adac.Source.Span;
    else_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_if_expression_condition (self, condition);
    require_current_conditional_expression_child (self, then_expression);
    require_current_conditional_expression_child (self, else_expression);
    Adac.Source.validate (span);
    cond_span := node_span (self, condition);
    then_span := node_span (self, then_expression);
    else_span := node_span (self, else_expression);

    if not Adac.Source.contains (span, cond_span) or else
       not Adac.Source.contains (span, then_span) or else
       not Adac.Source.contains (span, else_span)
    then
      raise Program_Error with
        "Adac.AST: if-expression child span is outside expression";
    end if;

    if not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (cond_span)) or else
       not precedes
         (Adac.Source.last_position (cond_span),
          Adac.Source.first_position (then_span)) or else
       not precedes
         (Adac.Source.last_position (then_span),
          Adac.Source.first_position (else_span)) or else
       Adac.Source.last_position (span) /= Adac.Source.last_position (else_span)
    then
      raise Program_Error with
        "Adac.AST: if-expression spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                          => If_Expression_Node,
             span                          => span,
             if_expression_condition_value => condition,
             if_expression_then_value      => then_expression,
             if_expression_else_value      => else_expression));
    return result;
  end append_if_expression;

  function append_case_expression_alternative
    (self          : in out Store;
     choices       : Node_List;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
    expression_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if choices.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: case-expression alternative choice list is empty";
    end if;
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind = Raise_Expression_Node then
      require_raise_expression (self, expression);
    else
      require_current_conditional_expression_child (self, expression);
    end if;

    previous_last := Adac.Source.first_position (span);
    for choice of choices.nodes loop
      require_current_case_expression_choice (self, choice);
      case self.nodes(Positive(choice.index)).kind is
        when Identifier_Name_Node | Selected_Name_Node =>
          Structural_Validation.validate_name (self, choice);
        when Others_Case_Choice_Node =>
          Adac.Source.validate (self.nodes(Positive(choice.index)).span);
        when others =>
          raise Program_Error with
            "Adac.AST: invalid case-expression choice";
      end case;
      declare
        child_span : constant Adac.Source.Span := node_span (self, choice);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: case-expression choices are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    expression_span := node_span (self, expression);
    if not Adac.Source.contains (span, expression_span) or else
       not precedes
         (previous_last, Adac.Source.first_position (expression_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (expression_span)
    then
      raise Program_Error with
        "Adac.AST: case-expression dependent expression is out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind => Case_Expression_Alternative_Node,
         span => span,
         case_expression_alternative_choices_value => choices.nodes,
         case_expression_alternative_expression_value => expression));
    return result;
  end append_case_expression_alternative;

  function append_raise_expression
    (self           : in out Store;
     exception_name : Node_ID;
     message        : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    exception_span : Adac.Source.Span;
    final_span     : Adac.Source.Span;
  begin
    validate_store (self);
    require_simple_name (self, exception_name);
    Structural_Validation.validate_name (self, exception_name);
    if message /= INVALID_NODE_ID then
      require_current_conditional_expression_child (self, message);
      Structural_Validation.validate_expression (self, message);
      if exception_name.index >= message.index then
        raise Program_Error with
          "Adac.AST: raise-expression children are not ordered";
      end if;
    end if;
    Adac.Source.validate (span);
    exception_span := node_span (self, exception_name);
    final_span :=
      (if message = INVALID_NODE_ID
       then exception_span
       else node_span (self, message));

    if not Adac.Source.contains (span, exception_span) or else
       not Adac.Source.contains (span, final_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (exception_span)) or else
       (message /= INVALID_NODE_ID and then
        not precedes
          (Adac.Source.last_position (exception_span),
           Adac.Source.first_position (final_span))) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (final_span)
    then
      raise Program_Error with
        "Adac.AST: raise-expression children are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Raise_Expression_Node,
             span => span,
             raise_expression_exception_name_value => exception_name,
             raise_expression_message_value => message));
    return result;
  end append_raise_expression;

  function append_case_expression
    (self                 : in out Store;
     selecting_expression : Node_ID;
     alternatives         : Node_List;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    selecting_span : Adac.Source.Span;
    previous_last  : Adac.Source.Position;
  begin
    validate_store (self);
    require_current_conditional_expression_child (self, selecting_expression);
    Adac.Source.validate (span);
    if alternatives.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: case-expression alternative list is empty";
    end if;

    selecting_span := node_span (self, selecting_expression);
    if not Adac.Source.contains (span, selecting_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (selecting_span))
    then
      raise Program_Error with
        "Adac.AST: case-expression selector is outside expression";
    end if;
    previous_last := Adac.Source.last_position (selecting_span);

    for alternative of alternatives.nodes loop
      require_case_expression_alternative (self, alternative);
      declare
        child_span : constant Adac.Source.Span := node_span (self, alternative);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: case-expression alternatives are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if previous_last /= Adac.Source.last_position (span) then
      raise Program_Error with
        "Adac.AST: case-expression span does not end at final alternative";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind => Case_Expression_Node,
         span => span,
         case_expression_selecting_expression_value => selecting_expression,
         case_expression_alternatives_value => alternatives.nodes));
    return result;
  end append_case_expression;

  function append_parenthesized_expression
    (self          : in out Store;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    child_span : Adac.Source.Span;
  begin
    validate_store (self);
    validate_node_id (self, expression);
    if self.nodes(Positive(expression.index)).kind /=
         If_Expression_Node and then
       self.nodes(Positive(expression.index)).kind /= Case_Expression_Node
    then
      require_current_expression (self, expression);
    end if;
    Adac.Source.validate (span);
    child_span := node_span (self, expression);

    if not Adac.Source.contains (span, child_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (child_span)) or else
       not precedes
         (Adac.Source.last_position (child_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: parenthesized-expression span does not bracket its child";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Parenthesized_Expression_Node,
             span => span,
             parenthesized_expression_child_value => expression));
    return result;
  end append_parenthesized_expression;

  function append_unary_operator
    (self              : in out Store;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     operand           : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
    result       : Node_ID;
    operand_span : Adac.Source.Span;
  begin
    validate_store (self);
    validate_unary_operator_shape (operator_spelling, operator_span);
    if operator_spelling = "+" or else operator_spelling = "-" then
      require_current_term_expression (self, operand);
    else
      require_current_direct_expression (self, operand);
    end if;
    Adac.Source.validate (span);
    operand_span := node_span (self, operand);

    if not Adac.Source.contains (span, operator_span) or else
       not Adac.Source.contains (span, operand_span)
    then
      raise Program_Error with
        "Adac.AST: unary operator child span is outside expression";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (operator_span) or else
       not precedes
         (Adac.Source.last_position (operator_span),
          Adac.Source.first_position (operand_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (operand_span)
    then
      raise Program_Error with
        "Adac.AST: unary operator spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                          => Unary_Operator_Node,
         span                          => span,
         unary_operator_spelling_value =>
           Ada.Strings.Unbounded.to_unbounded_string (operator_spelling),
         unary_operator_span_value     => operator_span,
         unary_operand_value           => operand));
    return result;
  end append_unary_operator;

  function append_binary_exponentiating
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    left_span  : Adac.Source.Span;
    right_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_direct_expression (self, left_operand);
    require_current_direct_expression (self, right_operand);
    validate_binary_exponentiating_operator_shape
      (operator_spelling, operator_span);
    Adac.Source.validate (span);
    left_span := node_span (self, left_operand);
    right_span := node_span (self, right_operand);

    if not Adac.Source.contains (span, left_span) or else
       not Adac.Source.contains (span, operator_span) or else
       not Adac.Source.contains (span, right_span)
    then
      raise Program_Error with
        "Adac.AST: binary-exponentiating child span is outside expression";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (left_span) or else
       not precedes
         (Adac.Source.last_position (left_span),
          Adac.Source.first_position (operator_span)) or else
       not precedes
         (Adac.Source.last_position (operator_span),
          Adac.Source.first_position (right_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (right_span)
    then
      raise Program_Error with
        "Adac.AST: binary-exponentiating spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind => Binary_Exponentiating_Node,
         span => span,
         binary_exponentiating_left_operand_value => left_operand,
         binary_exponentiating_operator_spelling_value =>
           Ada.Strings.Unbounded.to_unbounded_string (operator_spelling),
         binary_exponentiating_operator_span_value => operator_span,
         binary_exponentiating_right_operand_value => right_operand));
    return result;
  end append_binary_exponentiating;

  function append_binary_multiplying
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    left_span  : Adac.Source.Span;
    right_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_term_expression (self, left_operand);
    require_current_factor_expression (self, right_operand);
    validate_binary_multiplying_operator_shape
      (operator_spelling, operator_span);
    Adac.Source.validate (span);
    left_span := node_span (self, left_operand);
    right_span := node_span (self, right_operand);

    if not Adac.Source.contains (span, left_span) or else
       not Adac.Source.contains (span, operator_span) or else
       not Adac.Source.contains (span, right_span)
    then
      raise Program_Error with
        "Adac.AST: binary-multiplying child span is outside expression";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (left_span) or else
       not precedes
         (Adac.Source.last_position (left_span),
          Adac.Source.first_position (operator_span)) or else
       not precedes
         (Adac.Source.last_position (operator_span),
          Adac.Source.first_position (right_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (right_span)
    then
      raise Program_Error with
        "Adac.AST: binary-multiplying spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind => Binary_Multiplying_Node,
         span => span,
         binary_multiplying_left_operand_value => left_operand,
         binary_multiplying_operator_spelling_value =>
           Ada.Strings.Unbounded.to_unbounded_string (operator_spelling),
         binary_multiplying_operator_span_value => operator_span,
         binary_multiplying_right_operand_value => right_operand));
    return result;
  end append_binary_multiplying;

  function append_binary_adding
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    left_span  : Adac.Source.Span;
    right_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_simple_expression (self, left_operand);
    require_current_term_expression (self, right_operand);
    validate_binary_adding_operator_shape (operator_spelling, operator_span);
    Adac.Source.validate (span);
    left_span := node_span (self, left_operand);
    right_span := node_span (self, right_operand);

    if not Adac.Source.contains (span, left_span) or else
       not Adac.Source.contains (span, operator_span) or else
       not Adac.Source.contains (span, right_span)
    then
      raise Program_Error with
        "Adac.AST: binary-adding child span is outside expression";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (left_span) or else
       not precedes
         (Adac.Source.last_position (left_span),
          Adac.Source.first_position (operator_span)) or else
       not precedes
         (Adac.Source.last_position (operator_span),
          Adac.Source.first_position (right_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (right_span)
    then
      raise Program_Error with
        "Adac.AST: binary-adding spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                                  => Binary_Adding_Node,
         span                                  => span,
         binary_adding_left_operand_value      => left_operand,
         binary_adding_operator_spelling_value =>
           Ada.Strings.Unbounded.to_unbounded_string (operator_spelling),
         binary_adding_operator_span_value     => operator_span,
         binary_adding_right_operand_value     => right_operand));
    return result;
  end append_binary_adding;

  function append_relation
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    left_span  : Adac.Source.Span;
    right_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_simple_expression (self, left_operand);
    require_current_simple_expression (self, right_operand);
    validate_relation_operator_shape (operator_spelling, operator_span);
    Adac.Source.validate (span);
    left_span := node_span (self, left_operand);
    right_span := node_span (self, right_operand);

    if not Adac.Source.contains (span, left_span) or else
       not Adac.Source.contains (span, operator_span) or else
       not Adac.Source.contains (span, right_span)
    then
      raise Program_Error with
        "Adac.AST: relation child span is outside relation";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (left_span) or else
       not precedes
         (Adac.Source.last_position (left_span),
          Adac.Source.first_position (operator_span)) or else
       not precedes
         (Adac.Source.last_position (operator_span),
          Adac.Source.first_position (right_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (right_span)
    then
      raise Program_Error with
        "Adac.AST: relation spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                             => Relation_Node,
         span                             => span,
         relation_left_operand_value      => left_operand,
         relation_operator_spelling_value =>
           Ada.Strings.Unbounded.to_unbounded_string (operator_spelling),
         relation_operator_span_value     => operator_span,
         relation_right_operand_value     => right_operand));
    return result;
  end append_relation;

  function append_membership_range_choice
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    lower_span : Adac.Source.Span;
    upper_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_simple_expression (self, lower_bound);
    require_current_simple_expression (self, upper_bound);
    Adac.Source.validate (range_span);
    Adac.Source.validate (span);
    lower_span := node_span (self, lower_bound);
    upper_span := node_span (self, upper_bound);

    if lower_bound.index >= upper_bound.index then
      raise Program_Error with
        "Adac.AST: membership range bounds are not ordered";
    end if;

    if not Adac.Source.contains (span, lower_span) or else
       not Adac.Source.contains (span, range_span) or else
       not Adac.Source.contains (span, upper_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (lower_span) or else
       not precedes
         (Adac.Source.last_position (lower_span),
          Adac.Source.first_position (range_span)) or else
       not precedes
         (Adac.Source.last_position (range_span),
          Adac.Source.first_position (upper_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (upper_span)
    then
      raise Program_Error with
        "Adac.AST: membership range spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind => Membership_Range_Choice_Node,
         span => span,
         membership_range_choice_lower_bound_value => lower_bound,
         membership_range_choice_range_span_value => range_span,
         membership_range_choice_upper_bound_value => upper_bound));
    return result;
  end append_membership_range_choice;

  function append_membership_expression
    (self          : in out Store;
     tested        : Node_ID;
     operator_kind : Membership_Operator_Kind;
     not_span      : Adac.Source.Span;
     in_span       : Adac.Source.Span;
     choices       : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    tested_span   : Adac.Source.Span;
    previous_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_simple_expression (self, tested);
    Adac.Source.validate (in_span);
    Adac.Source.validate (span);
    tested_span := node_span (self, tested);

    if choices.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: membership choice list is empty";
    end if;

    case operator_kind is
      when In_Membership_Operator =>
        if not_span /= Adac.Source.INVALID_SPAN then
          raise Program_Error with
            "Adac.AST: in membership has a not token span";
        end if;

        if not precedes
          (Adac.Source.last_position (tested_span),
           Adac.Source.first_position (in_span))
        then
          raise Program_Error with
            "Adac.AST: membership operator is out of source order";
        end if;

      when Not_In_Membership_Operator =>
        Adac.Source.validate (not_span);
        if not precedes
          (Adac.Source.last_position (tested_span),
           Adac.Source.first_position (not_span)) or else
           not precedes
             (Adac.Source.last_position (not_span),
              Adac.Source.first_position (in_span))
        then
          raise Program_Error with
            "Adac.AST: membership operator is out of source order";
        end if;
    end case;

    if not Adac.Source.contains (span, tested_span) or else
       not Adac.Source.contains (span, in_span) or else
       (operator_kind = Not_In_Membership_Operator and then
        not Adac.Source.contains (span, not_span)) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (tested_span)
    then
      raise Program_Error with
        "Adac.AST: membership source span is inconsistent";
    end if;

    previous_span := in_span;
    for choice of choices.nodes loop
      validate_node_id (self, choice);
      if self.nodes(Positive(choice.index)).kind =
         Membership_Range_Choice_Node
      then
        Structural_Validation.validate_membership_range_choice
          (self, choice);
      else
        require_current_simple_expression (self, choice);
      end if;
      declare
        choice_span : constant Adac.Source.Span := node_span (self, choice);
      begin
        if not Adac.Source.contains (span, choice_span) or else
           not precedes
             (Adac.Source.last_position (previous_span),
              Adac.Source.first_position (choice_span))
        then
          raise Program_Error with
            "Adac.AST: membership choices are out of source order";
        end if;
        previous_span := choice_span;
      end;
    end loop;

    if Adac.Source.last_position (span) /=
       Adac.Source.last_position (previous_span)
    then
      raise Program_Error with
        "Adac.AST: membership span does not end at its last choice";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                               => Membership_Expression_Node,
             span                               => span,
             membership_tested_expression_value => tested,
             membership_operator_value          => operator_kind,
             membership_not_span_value          => not_span,
             membership_in_span_value           => in_span,
             membership_choices_value           => choices.nodes));
    return result;
  end append_membership_expression;

  function append_logical_expression
    (self          : in out Store;
     left_operand  : Node_ID;
     operator_kind : Logical_Operator_Kind;
     operator_span : Adac.Source.Span;
     right_operand : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    left_span  : Adac.Source.Span;
    right_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_expression (self, left_operand);
    require_current_expression (self, right_operand);
    if self.nodes(Positive(right_operand.index)).kind =
       Logical_Expression_Node
    then
      raise Program_Error with
        "Adac.AST: logical right operand must not be a chain";
    end if;
    if self.nodes(Positive(left_operand.index)).kind =
       Logical_Expression_Node
    then
      Structural_Validation.validate_logical_expression (self, left_operand);
    else
      Structural_Validation.validate_expression (self, left_operand);
    end if;
    Structural_Validation.validate_expression (self, right_operand);
    Adac.Source.validate (operator_span);
    Adac.Source.validate (span);
    left_span := node_span (self, left_operand);
    right_span := node_span (self, right_operand);
    if not Adac.Source.contains (span, left_span) or else
       not Adac.Source.contains (span, operator_span) or else
       not Adac.Source.contains (span, right_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (left_span) or else
       not precedes
         (Adac.Source.last_position (left_span),
          Adac.Source.first_position (operator_span)) or else
       not precedes
         (Adac.Source.last_position (operator_span),
          Adac.Source.first_position (right_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (right_span)
    then
      raise Program_Error with
        "Adac.AST: logical expression is out of source order";
    end if;
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Logical_Expression_Node,
             span => span,
             logical_left_operand_value => left_operand,
             logical_operator_value => operator_kind,
             logical_operator_span_value => operator_span,
             logical_right_operand_value => right_operand));
    return result;
  end append_logical_expression;

  function append_short_circuit_expression
    (self                 : in out Store;
     left_operand         : Node_ID;
     operator_kind        : Short_Circuit_Operator_Kind;
     operator_first_span  : Adac.Source.Span;
     operator_second_span : Adac.Source.Span;
     right_operand        : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    left_span  : Adac.Source.Span;
    right_span : Adac.Source.Span;
  begin
    validate_store (self);
    validate_node_id (self, left_operand);
    validate_node_id (self, right_operand);
    if not is_current_expression_kind
      (self.nodes(Positive(left_operand.index)).kind) or else
       not is_current_expression_kind
         (self.nodes(Positive(right_operand.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: short-circuit operand is not a current expression";
    end if;
    if self.nodes(Positive(right_operand.index)).kind =
       Short_Circuit_Expression_Node
    then
      raise Program_Error with
        "Adac.AST: short-circuit right operand must not be a chain";
    end if;

    if self.nodes(Positive(left_operand.index)).kind =
       Short_Circuit_Expression_Node
    then
      Structural_Validation.validate_short_circuit_expression
        (self, left_operand);
    else
      Structural_Validation.validate_expression (self, left_operand);
    end if;
    Structural_Validation.validate_expression (self, right_operand);
    Adac.Source.validate (operator_first_span);
    Adac.Source.validate (operator_second_span);
    Adac.Source.validate (span);

    left_span := node_span (self, left_operand);
    right_span := node_span (self, right_operand);
    if not Adac.Source.contains (span, left_span) or else
       not Adac.Source.contains (span, operator_first_span) or else
       not Adac.Source.contains (span, operator_second_span) or else
       not Adac.Source.contains (span, right_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (left_span) or else
       not precedes
         (Adac.Source.last_position (left_span),
          Adac.Source.first_position (operator_first_span)) or else
       not precedes
         (Adac.Source.last_position (operator_first_span),
          Adac.Source.first_position (operator_second_span)) or else
       not precedes
         (Adac.Source.last_position (operator_second_span),
          Adac.Source.first_position (right_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (right_span)
    then
      raise Program_Error with
        "Adac.AST: short-circuit expression is out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Short_Circuit_Expression_Node,
             span => span,
             short_circuit_left_operand_value => left_operand,
             short_circuit_operator_value => operator_kind,
             short_circuit_operator_first_span_value => operator_first_span,
             short_circuit_operator_second_span_value => operator_second_span,
             short_circuit_right_operand_value => right_operand));
    return result;
  end append_short_circuit_expression;

  function append_identifier_name
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind        => Identifier_Name_Node,
             span        => span,
             name_symbol => symbol));
    return result;
  end append_identifier_name;

  function append_selected_name
    (self          : in out Store;
     prefix        : Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    require_simple_name (self, prefix);
    Adac.Symbols.validate (selector);
    Adac.Source.validate (selector_span);
    Adac.Source.validate (span);

    if not Adac.Source.contains (span, node_span (self, prefix)) or else
       not Adac.Source.contains (span, selector_span)
    then
      raise Program_Error with
        "Adac.AST: selected-name child span is outside name";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (node_span (self, prefix)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (selector_span)
    then
      raise Program_Error with
        "Adac.AST: selected-name span does not match components";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind            => Selected_Name_Node,
             span            => span,
             selected_prefix => prefix,
             selected_symbol => selector,
             selected_span   => selector_span));
    return result;
  end append_selected_name;

  function append_explicit_dereference_name
    (self          : in out Store;
     prefix        : Node_ID;
     all_span      : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result      : Node_ID;
    prefix_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_name (self, prefix);
    validate_all_span (all_span);
    Adac.Source.validate (span);
    prefix_span := node_span (self, prefix);

    if not Adac.Source.contains (span, prefix_span) or else
       not Adac.Source.contains (span, all_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (prefix_span) or else
       not precedes
         (Adac.Source.last_position (prefix_span),
          Adac.Source.first_position (all_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (all_span)
    then
      raise Program_Error with
        "Adac.AST: explicit-dereference span does not match components";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Explicit_Dereference_Name_Node,
             span => span,
             explicit_dereference_prefix_value => prefix,
             explicit_dereference_all_span_value => all_span));
    return result;
  end append_explicit_dereference_name;

  function append_selected_component
    (self          : in out Store;
     prefix        : Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result      : Node_ID;
    prefix_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_name (self, prefix);
    if self.nodes(Positive(prefix.index)).kind /=
         Parenthesized_Name_Node and then
       self.nodes(Positive(prefix.index)).kind /=
         Explicit_Dereference_Name_Node and then
       self.nodes(Positive(prefix.index)).kind /= Selected_Component_Node
    then
      raise Program_Error with
        "Adac.AST: selected-component prefix is not a current non-simple name";
    end if;
    Adac.Symbols.validate (selector);
    Adac.Source.validate (selector_span);
    Adac.Source.validate (span);
    prefix_span := node_span (self, prefix);

    if not Adac.Source.contains (span, prefix_span) or else
       not Adac.Source.contains (span, selector_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (prefix_span) or else
       not precedes
         (Adac.Source.last_position (prefix_span),
          Adac.Source.first_position (selector_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (selector_span)
    then
      raise Program_Error with
        "Adac.AST: selected-component span does not match components";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind            => Selected_Component_Node,
             span            => span,
             selected_prefix => prefix,
             selected_symbol => selector,
             selected_span   => selector_span));
    return result;
  end append_selected_component;

  function append_parenthesized_name
    (self          : in out Store;
     prefix        : Node_ID;
     items         : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    associations : Parenthesized_Name_Item_List;
  begin
    for item of items.nodes loop
      append (associations, item);
    end loop;
    return append_parenthesized_name
      (self, prefix, associations, span, maximum_nodes);
  end append_parenthesized_name;

  function append_parenthesized_name
    (self          : in out Store;
     prefix        : Node_ID;
     items         : Parenthesized_Name_Item_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    previous_last  : Adac.Source.Position;
    saw_named_item : Boolean := False;
  begin
    validate_store (self);
    require_current_name (self, prefix);
    if not is_current_parenthesized_prefix_kind
      (self.nodes(Positive(prefix.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: parenthesized-name prefix has the wrong kind";
    end if;
    Adac.Source.validate (span);

    if items.items.is_empty then
      raise Program_Error with
        "Adac.AST: parenthesized-name item list is empty";
    end if;

    if not Adac.Source.contains (span, node_span (self, prefix)) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (node_span (self, prefix))
    then
      raise Program_Error with
        "Adac.AST: parenthesized-name prefix span is outside name";
    end if;

    previous_last := Adac.Source.last_position (node_span (self, prefix));
    for item of items.items loop
      if item.form = Named_Parenthesized_Name_Item_Form then
        saw_named_item := True;
        validate_node_id (self, item.selector);
        if self.nodes(Positive(item.selector.index)).kind /=
           Identifier_Name_Node
        then
          raise Program_Error with
            "Adac.AST: named parenthesized selector is not an identifier";
        end if;
        if not Adac.Source.contains
          (span, node_span (self, item.selector)) or else
           not precedes
             (previous_last,
              Adac.Source.first_position (node_span (self, item.selector)))
        then
          raise Program_Error with
            "Adac.AST: named parenthesized selector is out of source order";
        end if;
        previous_last :=
          Adac.Source.last_position (node_span (self, item.selector));
      elsif saw_named_item then
        raise Program_Error with
          "Adac.AST: positional parenthesized item follows named item";
      end if;

      require_current_parenthesized_item (self, item.actual);
      if not Adac.Source.contains
        (span, node_span (self, item.actual)) or else
         not precedes
           (previous_last,
            Adac.Source.first_position (node_span (self, item.actual)))
      then
        raise Program_Error with
          "Adac.AST: parenthesized-name item is out of source order";
      end if;
      previous_last :=
        Adac.Source.last_position (node_span (self, item.actual));
    end loop;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                 => Parenthesized_Name_Node,
             span                 => span,
             parenthesized_prefix => prefix,
             parenthesized_items  => items.items));
    return result;
  end append_parenthesized_name;

  function append_slice_name
    (self          : in out Store;
     prefix        : Node_ID;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result      : Node_ID;
    prefix_span : Adac.Source.Span;
    lower_span  : Adac.Source.Span;
    upper_span  : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_name (self, prefix);
    if not is_current_slice_prefix_kind
      (self.nodes(Positive(prefix.index)).kind)
    then
      raise Program_Error with
        "Adac.AST: slice prefix has the wrong kind";
    end if;
    require_current_simple_expression (self, lower_bound);
    require_current_simple_expression (self, upper_bound);
    validate_double_dot_span (range_span);
    Adac.Source.validate (span);
    prefix_span := node_span (self, prefix);
    lower_span := node_span (self, lower_bound);
    upper_span := node_span (self, upper_bound);

    if prefix.index >= lower_bound.index or else
       lower_bound.index >= upper_bound.index
    then
      raise Program_Error with "Adac.AST: slice children are not earlier";
    end if;

    if not Adac.Source.contains (span, prefix_span) or else
       not Adac.Source.contains (span, lower_span) or else
       not Adac.Source.contains (span, range_span) or else
       not Adac.Source.contains (span, upper_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (prefix_span) or else
       not precedes
         (Adac.Source.last_position (prefix_span),
          Adac.Source.first_position (lower_span)) or else
       not precedes
         (Adac.Source.last_position (lower_span),
          Adac.Source.first_position (range_span)) or else
       not precedes
         (Adac.Source.last_position (range_span),
          Adac.Source.first_position (upper_span)) or else
       not precedes
         (Adac.Source.last_position (upper_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: slice spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                    => Slice_Name_Node,
             span                    => span,
             slice_prefix_value      => prefix,
             slice_lower_bound_value => lower_bound,
             slice_range_span_value  => range_span,
             slice_upper_bound_value => upper_bound));
    return result;
  end append_slice_name;

  function append_attribute_name
    (self            : in out Store;
     prefix          : Node_ID;
     designator      : Adac.Symbols.Symbol_ID;
     designator_span : Adac.Source.Span;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
    result      : Node_ID;
    prefix_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_current_name (self, prefix);
    Adac.Symbols.validate (designator);
    Adac.Source.validate (designator_span);
    Adac.Source.validate (span);
    prefix_span := node_span (self, prefix);

    if not Adac.Source.contains (span, prefix_span) or else
       not Adac.Source.contains (span, designator_span)
    then
      raise Program_Error with
        "Adac.AST: attribute-name child span is outside name";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (prefix_span) or else
       not precedes
         (Adac.Source.last_position (prefix_span),
          Adac.Source.first_position (designator_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (designator_span)
    then
      raise Program_Error with
        "Adac.AST: attribute-name spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                   => Attribute_Name_Node,
             span                   => span,
             attribute_prefix       => prefix,
             attribute_symbol_value => designator,
             attribute_span_value   => designator_span));
    return result;
  end append_attribute_name;

  function append_aspect_specification
    (self          : in out Store;
     mark_symbol   : Adac.Symbols.Symbol_ID;
     mark_span     : Adac.Source.Span;
     definition    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result          : Node_ID;
    definition_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (mark_symbol);
    Adac.Source.validate (mark_span);
    Adac.Source.validate (span);
    require_current_expression (self, definition);
    Structural_Validation.validate_expression (self, definition);
    definition_span := node_span (self, definition);

    if not Adac.Source.contains (span, mark_span) or else
       not Adac.Source.contains (span, definition_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (mark_span)) or else
       not precedes
         (Adac.Source.last_position (mark_span),
          Adac.Source.first_position (definition_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (definition_span)
    then
      raise Program_Error with
        "Adac.AST: aspect specification is out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                     => Aspect_Specification_Node,
             span                     => span,
             aspect_mark_symbol_value => mark_symbol,
             aspect_mark_span_value   => mark_span,
             aspect_definition_value  => definition));
    return result;
  end append_aspect_specification;

  function append_parameter_specification
    (self                 : in out Store;
     defining_identifiers : Defining_Identifier_List;
     mode                 : Parameter_Mode_Kind;
     subtype_mark         : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
  begin
    return append_parameter_specification
      (self,
       defining_identifiers,
       mode,
       subtype_mark,
       INVALID_NODE_ID,
       span,
       maximum_nodes);
  end append_parameter_specification;

  function append_parameter_specification
    (self                 : in out Store;
     defining_identifiers : Defining_Identifier_List;
     mode                 : Parameter_Mode_Kind;
     subtype_mark         : Node_ID;
     default_expression   : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
    result       : Node_ID;
    subtype_span : Adac.Source.Span;
    previous_last : Adac.Source.Position;
    first_symbol : Adac.Symbols.Symbol_ID;
    first_span   : Adac.Source.Span;
    additional   : Program_Unit_Name;
    additional_index : Natural := 0;
  begin
    validate_store (self);
    if defining_identifier_list_count (defining_identifiers) = 0 then
      raise Program_Error with
        "Adac.AST: parameter defining identifier list is empty";
    end if;
    Adac.Source.validate (span);
    require_simple_name (self, subtype_mark);
    subtype_span := self.nodes(Positive(subtype_mark.index)).span;

    first_symbol := defining_identifier_list_symbol (defining_identifiers, 1);
    first_span := defining_identifier_list_span (defining_identifiers, 1);
    previous_last := Adac.Source.last_position (first_span);

    for index in 1 .. defining_identifier_list_count (defining_identifiers) loop
      declare
        symbol_value : constant Adac.Symbols.Symbol_ID :=
          defining_identifier_list_symbol (defining_identifiers, index);
        defining_span : constant Adac.Source.Span :=
          defining_identifier_list_span (defining_identifiers, index);
      begin
        Adac.Symbols.validate (symbol_value);
        Adac.Source.validate (defining_span);
        if not Adac.Source.contains (span, defining_span) then
          raise Program_Error with
            "Adac.AST: parameter defining span is outside specification";
        end if;
        if index = 1 then
          if Adac.Source.first_position (span) /=
             Adac.Source.first_position (defining_span)
          then
            raise Program_Error with
              "Adac.AST: parameter defining identifiers are out of " &
                "source order";
          end if;
        else
          if not precedes
            (previous_last, Adac.Source.first_position (defining_span))
          then
            raise Program_Error with
              "Adac.AST: parameter defining identifiers are out of " &
                "source order";
          end if;
          append (additional, symbol_value, defining_span);
          previous_last := Adac.Source.last_position (defining_span);
        end if;
      end;
    end loop;

    if not Adac.Source.contains (span, subtype_span) or else
       not precedes (previous_last, Adac.Source.first_position (subtype_span))
    then
      raise Program_Error with
        "Adac.AST: parameter subtype span is out of source order";
    end if;

    if default_expression /= INVALID_NODE_ID then
      require_current_expression (self, default_expression);
    end if;

    if default_expression = INVALID_NODE_ID then
      if Adac.Source.last_position (span) /=
         Adac.Source.last_position (subtype_span)
      then
        raise Program_Error with
          "Adac.AST: parameter spans are out of source order";
      end if;
    else
      declare
        default_span : constant Adac.Source.Span :=
          node_span (self, default_expression);
      begin
        if subtype_mark.index >= default_expression.index or else
           not Adac.Source.contains (span, default_span) or else
           not precedes
             (Adac.Source.last_position (subtype_span),
              Adac.Source.first_position (default_span)) or else
           Adac.Source.last_position (span) /=
             Adac.Source.last_position (default_span)
        then
          raise Program_Error with
            "Adac.AST: parameter default is out of source order";
        end if;
      end;
    end if;

    require_node_capacity (self, maximum_nodes);
    if program_unit_name_component_count (additional) > 0 then
      self.parameter_additional_defining_names.append (additional);
      additional_index := Natural
        (self.parameter_additional_defining_names.last_index);
    end if;
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Parameter_Specification_Node,
             span => span,
             parameter_symbol_value => first_symbol,
             parameter_defining_span_value => first_span,
             parameter_additional_defining_names_index_value =>
               additional_index,
             parameter_mode_value => mode,
             parameter_subtype_mark_value => subtype_mark,
             parameter_default_expression_value => default_expression));
    return result;
  end append_parameter_specification;

  function append_parameter_specification
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     mode          : Parameter_Mode_Kind;
     subtype_mark  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    defining_identifiers : Defining_Identifier_List;
  begin
    append (defining_identifiers, symbol, defining_span);
    return append_parameter_specification
      (self,
       defining_identifiers,
       mode,
       subtype_mark,
       span,
       maximum_nodes);
  end append_parameter_specification;

  function append_parameter_specification
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Parameter_Mode_Kind;
     subtype_mark       : Node_ID;
     default_expression : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
    defining_identifiers : Defining_Identifier_List;
  begin
    append (defining_identifiers, symbol, defining_span);
    return append_parameter_specification
      (self,
       defining_identifiers,
       mode,
       subtype_mark,
       default_expression,
       span,
       maximum_nodes);
  end append_parameter_specification;

  function append_object_declaration_common
    (self             : in out Store;
     form             : Object_Declaration_Form;
     symbol           : Adac.Symbols.Symbol_ID;
     defining_span    : Adac.Source.Span;
     subtype_mark     : Node_ID;
     index_constraint : Node_ID;
     initializer      : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural)
  return Node_ID is
    result       : Node_ID;
    subtype_span : Adac.Source.Span;
    subtype_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, subtype_mark);

    if index_constraint /= INVALID_NODE_ID then
      require_index_constraint (self, index_constraint);
      Structural_Validation.validate_index_constraint
        (self, index_constraint);
    end if;
    if initializer /= INVALID_NODE_ID then
      require_current_expression (self, initializer);
    end if;

    subtype_span := node_span (self, subtype_mark);
    subtype_last := Adac.Source.last_position (subtype_span);

    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, subtype_span)
    then
      raise Program_Error with
        "Adac.AST: object-declaration child span is outside declaration";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (defining_span) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (subtype_span))
    then
      raise Program_Error with
        "Adac.AST: object-declaration spans are out of source order";
    end if;

    if index_constraint /= INVALID_NODE_ID then
      declare
        constraint_span : constant Adac.Source.Span :=
          node_span (self, index_constraint);
      begin
        if not Adac.Source.contains (span, constraint_span) or else
           not precedes
             (subtype_last, Adac.Source.first_position (constraint_span))
        then
          raise Program_Error with
            "Adac.AST: object index constraint is out of source order";
        end if;
        subtype_last := Adac.Source.last_position (constraint_span);
      end;
    end if;

    if initializer = INVALID_NODE_ID then
      if not precedes (subtype_last, Adac.Source.last_position (span)) then
        raise Program_Error with
          "Adac.AST: object-declaration span omits its terminator";
      end if;
    else
      declare
        initializer_span : constant Adac.Source.Span :=
          node_span (self, initializer);
      begin
        if not Adac.Source.contains (span, initializer_span) or else
           not precedes
             (subtype_last,
              Adac.Source.first_position (initializer_span)) or else
           not precedes
             (Adac.Source.last_position (initializer_span),
              Adac.Source.last_position (span))
        then
          raise Program_Error with
            "Adac.AST: object-declaration initializer is out of source order";
        end if;
      end;
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                          => Object_Declaration_Node,
             span                          => span,
             object_form_value             => form,
             object_symbol_value           => symbol,
             object_defining_span_value    => defining_span,
             object_subtype_mark_value     => subtype_mark,
             object_index_constraint_value => index_constraint,
             object_initializer_value      => initializer));
    return result;
  end append_object_declaration_common;

  function append_object_declaration
    (self          : in out Store;
     form          : Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     initializer   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
  begin
    return append_object_declaration_common
      (self,
       form,
       symbol,
       defining_span,
       subtype_mark,
       INVALID_NODE_ID,
       initializer,
       span,
       maximum_nodes);
  end append_object_declaration;

  function append_constrained_object_declaration
    (self             : in out Store;
     form             : Object_Declaration_Form;
     symbol           : Adac.Symbols.Symbol_ID;
     defining_span    : Adac.Source.Span;
     subtype_mark     : Node_ID;
     index_constraint : Node_ID;
     initializer      : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
  begin
    if index_constraint = INVALID_NODE_ID then
      raise Program_Error with
        "Adac.AST: constrained object requires an index constraint";
    end if;
    return append_object_declaration_common
      (self,
       form,
       symbol,
       defining_span,
       subtype_mark,
       index_constraint,
       initializer,
       span,
       maximum_nodes);
  end append_constrained_object_declaration;

  function append_object_renaming_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     renamed_name  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result       : Node_ID;
    subtype_span : Adac.Source.Span;
    renamed_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, subtype_mark);
    require_current_name (self, renamed_name);

    if subtype_mark.index >= renamed_name.index then
      raise Program_Error with
        "Adac.AST: object-renaming children are not earlier and ordered";
    end if;

    subtype_span := node_span (self, subtype_mark);
    renamed_span := node_span (self, renamed_name);
    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, subtype_span) or else
       not Adac.Source.contains (span, renamed_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (defining_span) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (subtype_span)) or else
       not precedes
         (Adac.Source.last_position (subtype_span),
          Adac.Source.first_position (renamed_span)) or else
       not precedes
         (Adac.Source.last_position (renamed_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: object-renaming children are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                               => Object_Renaming_Declaration_Node,
         span                               => span,
         object_renaming_symbol_value        => symbol,
         object_renaming_defining_span_value => defining_span,
         object_renaming_subtype_mark_value  => subtype_mark,
         object_renaming_name_value          => renamed_name));
    return result;
  end append_object_renaming_declaration;

  function append_number_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result           : Node_ID;
    initializer_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_current_expression (self, initializer);
    initializer_span := node_span (self, initializer);

    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, initializer_span)
    then
      raise Program_Error with
        "Adac.AST: number-declaration child span is outside declaration";
    end if;

    if Adac.Source.first_position (span) /=
         Adac.Source.first_position (defining_span) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (initializer_span)) or else
       not precedes
         (Adac.Source.last_position (initializer_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: number-declaration spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                       => Number_Declaration_Node,
             span                       => span,
             number_symbol_value        => symbol,
             number_defining_span_value => defining_span,
             number_initializer_value   => initializer));
    return result;
  end append_number_declaration;

  function append_exception_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if not Adac.Source.contains (span, defining_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (defining_span) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: exception-declaration spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Exception_Declaration_Node,
             span => span,
             exception_declaration_symbol_value => symbol,
             exception_declaration_defining_span_value => defining_span));
    return result;
  end append_exception_declaration;

  function append_procedure_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if not Adac.Source.contains (span, defining_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span))
    then
      raise Program_Error with
        "Adac.AST: procedure-declaration spans are out of source order";
    end if;

    previous_last := Adac.Source.last_position (defining_span);
    for parameter of parameters.nodes loop
      Structural_Validation.validate_parameter (self, parameter);
      declare
        child_span : constant Adac.Source.Span := node_span (self, parameter);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: procedure parameters are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: procedure-declaration spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
         (kind =>
            Procedure_Declaration_Node,
          span                                      => span,
          procedure_declaration_symbol_value        => symbol,
          procedure_declaration_defining_span_value => defining_span,
          procedure_declaration_parameters_value    => parameters.nodes));
    return result;
  end append_procedure_declaration;

  function append_procedure_body_stub
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if not Adac.Source.contains (span, defining_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span))
    then
      raise Program_Error with
        "Adac.AST: procedure-body-stub spans are out of source order";
    end if;

    previous_last := Adac.Source.last_position (defining_span);
    for parameter of parameters.nodes loop
      Structural_Validation.validate_parameter (self, parameter);
      declare
        child_span : constant Adac.Source.Span := node_span (self, parameter);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: procedure-body-stub parameters are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: procedure-body-stub span omits its completion";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Procedure_Body_Stub_Node,
             span => span,
             procedure_body_stub_symbol_value => symbol,
             procedure_body_stub_defining_span_value => defining_span,
             procedure_body_stub_parameters_value => parameters.nodes));
    return result;
  end append_procedure_body_stub;

  function append_function_declaration
    (self           : in out Store;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Node_List;
     result_subtype : Node_ID;
     aspect         : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
  begin
    return append_function_declaration
      (self,
       symbol,
       defining_span,
       parameters,
       result_subtype,
       INVALID_NODE_ID,
       aspect,
       span,
       maximum_nodes);
  end append_function_declaration;

  function append_function_declaration
    (self           : in out Store;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Node_List;
     result_subtype : Node_ID;
     expression     : Node_ID;
     aspect         : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
    result_span   : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if not Adac.Source.contains (span, defining_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span))
    then
      raise Program_Error with
        "Adac.AST: function-declaration spans are out of source order";
    end if;

    previous_last := Adac.Source.last_position (defining_span);
    for parameter of parameters.nodes loop
      Structural_Validation.validate_parameter (self, parameter);
      declare
        child_span : constant Adac.Source.Span := node_span (self, parameter);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: function parameters are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    require_simple_name (self, result_subtype);
    validate_simple_name (self, result_subtype);
    result_span := node_span (self, result_subtype);
    if not Adac.Source.contains (span, result_span) or else
       not precedes
         (previous_last, Adac.Source.first_position (result_span))
    then
      raise Program_Error with
        "Adac.AST: function result is out of source order";
    end if;
    previous_last := Adac.Source.last_position (result_span);

    if expression /= INVALID_NODE_ID then
      require_current_expression (self, expression);
      Structural_Validation.validate_expression (self, expression);
      declare
        expression_span : constant Adac.Source.Span :=
          node_span (self, expression);
      begin
        if not Adac.Source.contains (span, expression_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (expression_span))
        then
          raise Program_Error with
            "Adac.AST: function expression is out of source order";
        end if;
        previous_last := Adac.Source.last_position (expression_span);
      end;
    end if;

    if aspect /= INVALID_NODE_ID then
      require_aspect_specification (self, aspect);
      Structural_Validation.validate_aspect_specification (self, aspect);
      declare
        aspect_span : constant Adac.Source.Span := node_span (self, aspect);
      begin
        if not Adac.Source.contains (span, aspect_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (aspect_span))
        then
          raise Program_Error with
            "Adac.AST: function aspect is out of source order";
        end if;
        previous_last := Adac.Source.last_position (aspect_span);
      end;
    end if;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: function declaration span omits its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
         (kind                                     => Function_Declaration_Node,
          span                                     => span,
          function_declaration_symbol_value        => symbol,
          function_declaration_defining_span_value => defining_span,
          function_declaration_parameters_value    => parameters.nodes,
          function_declaration_result_subtype_value => result_subtype,
          function_declaration_expression_value     => expression,
          function_declaration_aspect_value         => aspect));
    return result;
  end append_function_declaration;

  function append_private_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     discriminants : Node_List;
     span          : Adac.Source.Span;
     limited_form  : Boolean := False;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if not Adac.Source.contains (span, defining_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span))
    then
      raise Program_Error with
        "Adac.AST: private-type defining span is out of source order";
    end if;

    previous_last := Adac.Source.last_position (defining_span);
    for discriminant of discriminants.nodes loop
      require_discriminant_specification (self, discriminant);
      Structural_Validation.validate_discriminant_specification
        (self, discriminant);
      declare
        discriminant_span : constant Adac.Source.Span :=
          node_span (self, discriminant);
      begin
        if not Adac.Source.contains (span, discriminant_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (discriminant_span))
        then
          raise Program_Error with
            "Adac.AST: private-type discriminants are out of source order";
        end if;
        previous_last := Adac.Source.last_position (discriminant_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: private-type declaration span omits its completion";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                             => Private_Type_Declaration_Node,
             span                             => span,
             private_type_symbol_value        => symbol,
             private_type_defining_span_value => defining_span,
             private_type_discriminants_value => discriminants.nodes,
             private_type_limited_value       => limited_form));
    return result;
  end append_private_type_declaration;

  function append_derived_type_declaration
    (self                : in out Store;
     symbol              : Adac.Symbols.Symbol_ID;
     defining_span       : Adac.Source.Span;
     parent_subtype_mark : Node_ID;
     span                : Adac.Source.Span;
     maximum_nodes       : Natural := Natural'Last)
  return Node_ID is
    result      : Node_ID;
    parent_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, parent_subtype_mark);
    Structural_Validation.validate_name (self, parent_subtype_mark);
    parent_span := node_span (self, parent_subtype_mark);

    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, parent_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span)) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (parent_span)) or else
       not precedes
         (Adac.Source.last_position (parent_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: derived-type declaration spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Derived_Type_Declaration_Node,
             span => span,
             derived_type_symbol_value => symbol,
             derived_type_defining_span_value => defining_span,
             derived_type_parent_subtype_mark_value => parent_subtype_mark));
    return result;
  end append_derived_type_declaration;

  function append_range_constraint
    (self          : in out Store;
     lower_bound   : Node_ID;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    lower_span : Adac.Source.Span;
    upper_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    require_current_expression (self, lower_bound);
    require_current_expression (self, upper_bound);
    Structural_Validation.validate_expression (self, lower_bound);
    Structural_Validation.validate_expression (self, upper_bound);
    lower_span := node_span (self, lower_bound);
    upper_span := node_span (self, upper_bound);

    if lower_bound.index >= upper_bound.index or else
       not Adac.Source.contains (span, lower_span) or else
       not Adac.Source.contains (span, upper_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (lower_span)) or else
       not precedes
         (Adac.Source.last_position (lower_span),
          Adac.Source.first_position (upper_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (upper_span)
    then
      raise Program_Error with
        "Adac.AST: range-constraint bounds are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Range_Constraint_Node,
             span => span,
             range_constraint_lower_bound_value => lower_bound,
             range_constraint_upper_bound_value => upper_bound));
    return result;
  end append_range_constraint;

  function append_index_constraint
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    lower_span : Adac.Source.Span;
    upper_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    validate_double_dot_span (range_span);
    require_current_simple_expression (self, lower_bound);
    require_current_simple_expression (self, upper_bound);
    Structural_Validation.validate_expression (self, lower_bound);
    Structural_Validation.validate_expression (self, upper_bound);
    lower_span := node_span (self, lower_bound);
    upper_span := node_span (self, upper_bound);

    if lower_bound.index >= upper_bound.index or else
       not Adac.Source.contains (span, lower_span) or else
       not Adac.Source.contains (span, range_span) or else
       not Adac.Source.contains (span, upper_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (lower_span)) or else
       not precedes
         (Adac.Source.last_position (lower_span),
          Adac.Source.first_position (range_span)) or else
       not precedes
         (Adac.Source.last_position (range_span),
          Adac.Source.first_position (upper_span)) or else
       not precedes
         (Adac.Source.last_position (upper_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: index-constraint bounds are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Index_Constraint_Node,
             span => span,
             index_constraint_lower_bound_value => lower_bound,
             index_constraint_range_span_value => range_span,
             index_constraint_upper_bound_value => upper_bound));
    return result;
  end append_index_constraint;

  function append_subtype_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     constraint    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result       : Node_ID;
    subtype_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, subtype_mark);
    Structural_Validation.validate_name (self, subtype_mark);
    subtype_span := node_span (self, subtype_mark);

    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, subtype_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span)) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (subtype_span))
    then
      raise Program_Error with
        "Adac.AST: subtype declaration children are out of source order";
    end if;

    if constraint = INVALID_NODE_ID then
      if not precedes
        (Adac.Source.last_position (subtype_span),
         Adac.Source.last_position (span))
      then
        raise Program_Error with
          "Adac.AST: subtype declaration span omits its terminator";
      end if;
    else
      require_range_constraint (self, constraint);
      Structural_Validation.validate_range_constraint (self, constraint);
      declare
        constraint_span : constant Adac.Source.Span :=
          node_span (self, constraint);
      begin
        if subtype_mark.index >= constraint.index or else
           not Adac.Source.contains (span, constraint_span) or else
           not precedes
             (Adac.Source.last_position (subtype_span),
              Adac.Source.first_position (constraint_span)) or else
           not precedes
             (Adac.Source.last_position (constraint_span),
              Adac.Source.last_position (span))
        then
          raise Program_Error with
            "Adac.AST: subtype constraint is out of source order";
        end if;
      end;
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Subtype_Declaration_Node,
             span => span,
             subtype_declaration_symbol_value => symbol,
             subtype_declaration_defining_span_value => defining_span,
             subtype_declaration_subtype_mark_value => subtype_mark,
             subtype_declaration_constraint_value => constraint));
    return result;
  end append_subtype_declaration;

  function append_enumeration_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     literals      : Enumeration_Literal_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if literals.components.is_empty then
      raise Program_Error with
        "Adac.AST: enumeration type has no defining literals";
    end if;
    if not Adac.Source.contains (span, defining_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span))
    then
      raise Program_Error with
        "Adac.AST: enumeration type defining span is out of source order";
    end if;

    previous_last := Adac.Source.last_position (defining_span);
    for literal of literals.components loop
      Adac.Symbols.validate (literal.symbol);
      Adac.Source.validate (literal.span);
      if not Adac.Source.contains (span, literal.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (literal.span))
      then
        raise Program_Error with
          "Adac.AST: enumeration literals are out of source order";
      end if;
      previous_last := Adac.Source.last_position (literal.span);
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: enumeration span does not include its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                                =>
               Enumeration_Type_Declaration_Node,
             span                                => span,
             enumeration_type_symbol_value       => symbol,
             enumeration_type_defining_span_value => defining_span,
             enumeration_literals_value          => literals.components));
    return result;
  end append_enumeration_type_declaration;

  function append_discriminant_specification
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     subtype_mark       : Node_ID;
     default_expression : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
    result       : Node_ID;
    subtype_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, subtype_mark);
    Structural_Validation.validate_name (self, subtype_mark);
    if default_expression /= INVALID_NODE_ID then
      require_current_expression (self, default_expression);
      Structural_Validation.validate_expression (self, default_expression);
    end if;

    subtype_span := node_span (self, subtype_mark);
    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, subtype_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (defining_span) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (subtype_span))
    then
      raise Program_Error with
        "Adac.AST: discriminant children are out of source order";
    end if;

    if default_expression = INVALID_NODE_ID then
      if Adac.Source.last_position (span) /=
         Adac.Source.last_position (subtype_span)
      then
        raise Program_Error with
          "Adac.AST: discriminant span does not end at its subtype mark";
      end if;
    else
      declare
        default_span : constant Adac.Source.Span :=
          node_span (self, default_expression);
      begin
        if not Adac.Source.contains (span, default_span) or else
           not precedes
             (Adac.Source.last_position (subtype_span),
              Adac.Source.first_position (default_span)) or else
           Adac.Source.last_position (span) /=
             Adac.Source.last_position (default_span)
        then
          raise Program_Error with
            "Adac.AST: discriminant default is out of source order";
        end if;
      end;
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                                  =>
               Discriminant_Specification_Node,
             span                                  => span,
             discriminant_symbol_value             => symbol,
             discriminant_defining_span_value      => defining_span,
             discriminant_subtype_mark_value       => subtype_mark,
             discriminant_default_expression_value => default_expression));
    return result;
  end append_discriminant_specification;

  function append_record_component_declaration
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     aliased_form       : Boolean;
     subtype_mark       : Node_ID;
     default_expression : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
    result       : Node_ID;
    subtype_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, subtype_mark);
    if default_expression /= INVALID_NODE_ID then
      require_current_expression (self, default_expression);
    end if;

    subtype_span := node_span (self, subtype_mark);
    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, subtype_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (defining_span) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (subtype_span))
    then
      raise Program_Error with
        "Adac.AST: record component children are out of source order";
    end if;

    if default_expression = INVALID_NODE_ID then
      if not precedes
        (Adac.Source.last_position (subtype_span),
         Adac.Source.last_position (span))
      then
        raise Program_Error with
          "Adac.AST: record component span omits its terminator";
      end if;
    else
      declare
        default_span : constant Adac.Source.Span :=
          node_span (self, default_expression);
      begin
        if not Adac.Source.contains (span, default_span) or else
           not precedes
             (Adac.Source.last_position (subtype_span),
              Adac.Source.first_position (default_span)) or else
           not precedes
             (Adac.Source.last_position (default_span),
              Adac.Source.last_position (span))
        then
          raise Program_Error with
            "Adac.AST: record component default is out of source order";
        end if;
      end;
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                                      =>
               Record_Component_Declaration_Node,
             span                                      => span,
             record_component_symbol_value             => symbol,
             record_component_defining_span_value      => defining_span,
             record_component_aliased_value            => aliased_form,
             record_component_subtype_mark_value       => subtype_mark,
             record_component_default_expression_value => default_expression));
    return result;
  end append_record_component_declaration;

  function append_record_variant
    (self                : in out Store;
     choices             : Node_List;
     components          : Node_List;
     null_component_list : Boolean;
     span                : Adac.Source.Span;
     maximum_nodes       : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if choices.nodes.is_empty then
      raise Program_Error with "Adac.AST: record variant has no choices";
    end if;
    if null_component_list = (not components.nodes.is_empty) then
      raise Program_Error with
        "Adac.AST: record variant component-list form is inconsistent";
    end if;

    previous_last := Adac.Source.first_position (span);
    for choice of choices.nodes loop
      validate_node_id (self, choice);
      if self.nodes(Positive(choice.index)).kind /= Identifier_Name_Node then
        raise Program_Error with
          "Adac.AST: record variant choice is not an identifier name";
      end if;
      Structural_Validation.validate_name (self, choice);
      declare
        choice_span : constant Adac.Source.Span := node_span (self, choice);
      begin
        if not Adac.Source.contains (span, choice_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (choice_span))
        then
          raise Program_Error with
            "Adac.AST: record variant choices are out of source order";
        end if;
        previous_last := Adac.Source.last_position (choice_span);
      end;
    end loop;

    for component of components.nodes loop
      require_record_component_declaration (self, component);
      Structural_Validation.validate_record_component_declaration
        (self, component);
      declare
        component_span : constant Adac.Source.Span :=
          node_span (self, component);
      begin
        if not Adac.Source.contains (span, component_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component_span))
        then
          raise Program_Error with
            "Adac.AST: record variant components are out of source order";
        end if;
        previous_last := Adac.Source.last_position (component_span);
      end;
    end loop;

    if null_component_list then
      if not precedes (previous_last, Adac.Source.last_position (span)) then
        raise Program_Error with
          "Adac.AST: null record variant span omits its terminator";
      end if;
    elsif previous_last /= Adac.Source.last_position (span) then
      raise Program_Error with
        "Adac.AST: record variant span does not end with its last component";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Record_Variant_Node,
             span => span,
             record_variant_choices_value => choices.nodes,
             record_variant_components_value => components.nodes,
             record_variant_null_component_list_value => null_component_list));
    return result;
  end append_record_variant;

  function append_record_variant_part
    (self              : in out Store;
     discriminant_name : Node_ID;
     variants          : Node_List;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    validate_node_id (self, discriminant_name);
    if self.nodes(Positive(discriminant_name.index)).kind /=
       Identifier_Name_Node
    then
      raise Program_Error with
        "Adac.AST: variant-part discriminant is not an identifier name";
    end if;
    Structural_Validation.validate_name (self, discriminant_name);
    if variants.nodes.is_empty then
      raise Program_Error with "Adac.AST: record variant part has no variants";
    end if;

    declare
      name_span : constant Adac.Source.Span :=
        node_span (self, discriminant_name);
    begin
      if not Adac.Source.contains (span, name_span) or else
         not precedes
           (Adac.Source.first_position (span),
            Adac.Source.first_position (name_span))
      then
        raise Program_Error with
          "Adac.AST: variant-part discriminant is out of source order";
      end if;
      previous_last := Adac.Source.last_position (name_span);
    end;

    for variant of variants.nodes loop
      require_record_variant (self, variant);
      Structural_Validation.validate_record_variant (self, variant);
      declare
        variant_span : constant Adac.Source.Span := node_span (self, variant);
      begin
        if not Adac.Source.contains (span, variant_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (variant_span))
        then
          raise Program_Error with
            "Adac.AST: record variants are out of source order";
        end if;
        previous_last := Adac.Source.last_position (variant_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: record variant-part span omits end case";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Record_Variant_Part_Node,
             span => span,
             record_variant_part_discriminant_name_value => discriminant_name,
             record_variant_part_variants_value => variants.nodes));
    return result;
  end append_record_variant_part;

  function append_record_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     limited_form  : Boolean;
     discriminants : Node_List;
     components    : Node_List;
     variant_part  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if components.nodes.is_empty and then variant_part = INVALID_NODE_ID then
      raise Program_Error with
        "Adac.AST: record type has no represented components";
    end if;

    if not Adac.Source.contains (span, defining_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span))
    then
      raise Program_Error with
        "Adac.AST: record type defining span is out of source order";
    end if;

    previous_last := Adac.Source.last_position (defining_span);
    for discriminant of discriminants.nodes loop
      require_discriminant_specification (self, discriminant);
      Structural_Validation.validate_discriminant_specification
        (self, discriminant);
      declare
        discriminant_span : constant Adac.Source.Span :=
          node_span (self, discriminant);
      begin
        if not Adac.Source.contains (span, discriminant_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (discriminant_span))
        then
          raise Program_Error with
            "Adac.AST: record discriminants are out of source order";
        end if;
        previous_last := Adac.Source.last_position (discriminant_span);
      end;
    end loop;

    for component of components.nodes loop
      require_record_component_declaration (self, component);
      Structural_Validation.validate_record_component_declaration
        (self, component);
      declare
        component_span : constant Adac.Source.Span :=
          node_span (self, component);
      begin
        if not Adac.Source.contains (span, component_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component_span))
        then
          raise Program_Error with
            "Adac.AST: record components are out of source order";
        end if;
        previous_last := Adac.Source.last_position (component_span);
      end;
    end loop;

    if variant_part /= INVALID_NODE_ID then
      require_record_variant_part (self, variant_part);
      Structural_Validation.validate_record_variant_part (self, variant_part);
      declare
        variant_span : constant Adac.Source.Span :=
          node_span (self, variant_part);
      begin
        if not Adac.Source.contains (span, variant_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (variant_span))
        then
          raise Program_Error with
            "Adac.AST: record variant part is out of source order";
        end if;
        previous_last := Adac.Source.last_position (variant_span);
      end;
    end if;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: record type span omits end record";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                       => Record_Type_Declaration_Node,
             span                       => span,
             record_type_symbol_value   => symbol,
             record_type_defining_span_value => defining_span,
             record_type_limited_value  => limited_form,
             record_discriminants_value => discriminants.nodes,
             record_components_value    => components.nodes,
             record_variant_part_value  => variant_part));
    return result;
  end append_record_type_declaration;

  function append_access_object_type_declaration
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     modifier           : General_Access_Modifier_Kind;
     designated_subtype : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    designated_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, designated_subtype);
    designated_span := node_span (self, designated_subtype);

    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, designated_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span)) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (designated_span)) or else
       not precedes
         (Adac.Source.last_position (designated_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: access-to-object type children are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Access_Object_Type_Declaration_Node,
             span => span,
             access_object_type_symbol_value => symbol,
             access_object_type_defining_span_value => defining_span,
             access_object_type_modifier_value => modifier,
             access_object_type_designated_subtype_value =>
               designated_subtype));
    return result;
  end append_access_object_type_declaration;

  function append_others_exception_choice
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Others_Exception_Choice_Node, span => span));
    return result;
  end append_others_exception_choice;

  function append_exception_handler
    (self                    : in out Store;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID;
     choice_parameter_span   : Adac.Source.Span;
     choices                 : Node_List;
     statements              : Node_List;
     span                    : Adac.Source.Span;
     maximum_nodes           : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);

    if choice_parameter_symbol = Adac.Symbols.INVALID_SYMBOL_ID then
      if choice_parameter_span /= Adac.Source.INVALID_SPAN then
        raise Program_Error with
          "Adac.AST: absent choice parameter has a source span";
      end if;
      previous_last := Adac.Source.first_position (span);
    else
      Adac.Symbols.validate (choice_parameter_symbol);
      Adac.Source.validate (choice_parameter_span);
      if not Adac.Source.contains (span, choice_parameter_span) or else
         not precedes
           (Adac.Source.first_position (span),
            Adac.Source.first_position (choice_parameter_span))
      then
        raise Program_Error with
          "Adac.AST: choice parameter is outside handler span";
      end if;
      previous_last := Adac.Source.last_position (choice_parameter_span);
    end if;

    if choices.nodes.is_empty then
      raise Program_Error with "Adac.AST: exception handler has no choices";
    end if;
    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: exception handler body is empty";
    end if;

    for choice of choices.nodes loop
      validate_current_exception_choice (self, choice);
      declare
        choice_span : constant Adac.Source.Span := node_span (self, choice);
      begin
        if not Adac.Source.contains (span, choice_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (choice_span))
        then
          raise Program_Error with
            "Adac.AST: exception choices are out of source order";
        end if;
        previous_last := Adac.Source.last_position (choice_span);
      end;
    end loop;

    for statement of statements.nodes loop
      validate_current_exception_handler_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: exception-handler body is out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if previous_last /= Adac.Source.last_position (span) then
      raise Program_Error with
        "Adac.AST: exception-handler span does not end with its body";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind => Exception_Handler_Node,
         span => span,
         exception_handler_choice_parameter_symbol_value =>
           choice_parameter_symbol,
         exception_handler_choice_parameter_span_value => choice_parameter_span,
         exception_handler_choices_value => choices.nodes,
         exception_handler_statements_value => statements.nodes));
    return result;
  end append_exception_handler;

  function append_handled_sequence
    (self          : in out Store;
     statements    : Node_List;
     handlers      : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);

    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: handled sequence is empty";
    end if;

    declare
      first_statement : constant Node_ID := statements.nodes.first_element;
    begin
      validate_current_handled_statement_shallow (self, first_statement);

      if Adac.Source.first_position (span) /=
           Adac.Source.first_position (node_span (self, first_statement))
      then
        raise Program_Error with
          "Adac.AST: handled-sequence span does not start at first statement";
      end if;
    end;

    previous_last := Adac.Source.first_position (span);

    for statement of statements.nodes loop
      validate_current_handled_statement_shallow (self, statement);

      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           (previous_last /= Adac.Source.first_position (span) and then
            not precedes
              (previous_last, Adac.Source.first_position (child_span)))
        then
          raise Program_Error with
            "Adac.AST: handled statements are out of source order";
        end if;

        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    for handler of handlers.nodes loop
      Structural_Validation.validate_exception_handler (self, handler);

      declare
        child_span : constant Adac.Source.Span := node_span (self, handler);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: exception handlers are out of source order";
        end if;

        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if previous_last /= Adac.Source.last_position (span) then
      raise Program_Error with
        "Adac.AST: handled-sequence span does not end at its final child";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                              => Handled_Sequence_Node,
         span                              => span,
         handled_sequence_statements_value => statements.nodes,
         handled_sequence_handlers_value   => handlers.nodes));
    return result;
  end append_handled_sequence;

  function append_elsif_part
    (self          : in out Store;
     condition     : Node_ID;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    condition_span : Adac.Source.Span;
    previous_last  : Adac.Source.Position;
  begin
    validate_store (self);
    Structural_Validation.validate_expression (self, condition);
    Adac.Source.validate (span);
    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: elsif statement list is empty";
    end if;

    condition_span := node_span (self, condition);
    if not Adac.Source.contains (span, condition_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (condition_span))
    then
      raise Program_Error with
        "Adac.AST: elsif condition span is outside part";
    end if;

    previous_last := Adac.Source.last_position (condition_span);
    for statement of statements.nodes loop
      validate_current_if_child_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: elsif statements are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if previous_last /= Adac.Source.last_position (span) then
      raise Program_Error with
        "Adac.AST: elsif span does not end at its final statement";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                   => Elsif_Part_Node,
         span                   => span,
         elsif_condition_value  => condition,
         elsif_statements_value => statements.nodes));
    return result;
  end append_elsif_part;

  function append_if_statement
    (self            : in out Store;
     condition       : Node_ID;
     then_statements : Node_List;
     elsif_parts     : Node_List;
     else_statements : Node_List;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    condition_span : Adac.Source.Span;
    previous_last  : Adac.Source.Position;
  begin
    validate_store (self);
    Structural_Validation.validate_expression (self, condition);
    Adac.Source.validate (span);

    if then_statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: if then branch is empty";
    end if;

    condition_span := node_span (self, condition);
    if not Adac.Source.contains (span, condition_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (condition_span))
    then
      raise Program_Error with
        "Adac.AST: if condition span is outside statement";
    end if;

    previous_last := Adac.Source.last_position (condition_span);
    for statement of then_statements.nodes loop
      validate_current_if_child_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: if then statements are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    for part of elsif_parts.nodes loop
      require_elsif_part (self, part);
      declare
        part_span : constant Adac.Source.Span := node_span (self, part);
      begin
        Adac.Source.validate (part_span);
        if not Adac.Source.contains (span, part_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (part_span))
        then
          raise Program_Error with
            "Adac.AST: elsif parts are out of source order";
        end if;
        previous_last := Adac.Source.last_position (part_span);
      end;
    end loop;

    for statement of else_statements.nodes loop
      validate_current_if_child_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: if else statements are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: if span does not include its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                     => If_Statement_Node,
         span                     => span,
         if_condition_value       => condition,
         if_then_statements_value => then_statements.nodes,
         if_elsif_parts_value     => elsif_parts.nodes,
         if_else_statements_value => else_statements.nodes));
    return result;
  end append_if_statement;

  function append_assignment_statement
    (self          : in out Store;
     target        : Node_ID;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result          : Node_ID;
    target_span     : Adac.Source.Span;
    expression_span : Adac.Source.Span;
  begin
    validate_store (self);
    Structural_Validation.validate_name (self, target);
    Structural_Validation.validate_expression (self, expression);
    Adac.Source.validate (span);

    target_span := node_span (self, target);
    expression_span := node_span (self, expression);

    if not Adac.Source.contains (span, target_span) or else
       not Adac.Source.contains (span, expression_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (target_span)
    then
      raise Program_Error with
        "Adac.AST: assignment child span is outside statement";
    end if;

    if not precedes
      (Adac.Source.last_position (target_span),
       Adac.Source.first_position (expression_span)) or else
       not precedes
         (Adac.Source.last_position (expression_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: assignment children are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                        => Assignment_Statement_Node,
         span                        => span,
         assignment_target_value     => target,
         assignment_expression_value => expression));
    return result;
  end append_assignment_statement;

  function append_case_range_choice
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result     : Node_ID;
    lower_span : Adac.Source.Span;
    upper_span : Adac.Source.Span;
  begin
    validate_store (self);
    Structural_Validation.validate_character_literal (self, lower_bound);
    Structural_Validation.validate_character_literal (self, upper_bound);
    Adac.Source.validate (range_span);
    Adac.Source.validate (span);
    lower_span := node_span (self, lower_bound);
    upper_span := node_span (self, upper_bound);

    if lower_bound.index >= upper_bound.index then
      raise Program_Error with "Adac.AST: case range bounds are not ordered";
    end if;

    if not Adac.Source.contains (span, lower_span) or else
       not Adac.Source.contains (span, range_span) or else
       not Adac.Source.contains (span, upper_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (lower_span) or else
       not precedes
         (Adac.Source.last_position (lower_span),
          Adac.Source.first_position (range_span)) or else
       not precedes
         (Adac.Source.last_position (range_span),
          Adac.Source.first_position (upper_span)) or else
       Adac.Source.last_position (span) /=
         Adac.Source.last_position (upper_span)
    then
      raise Program_Error with
        "Adac.AST: case range spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind => Case_Range_Choice_Node,
         span => span,
         case_range_choice_lower_bound_value => lower_bound,
         case_range_choice_range_span_value => range_span,
         case_range_choice_upper_bound_value => upper_bound));
    return result;
  end append_case_range_choice;

  function append_others_case_choice
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Others_Case_Choice_Node, span => span));
    return result;
  end append_others_case_choice;

  function append_case_alternative
    (self          : in out Store;
     choices       : Node_List;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if choices.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: case alternative choice list is empty";
    end if;
    if statements.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: case alternative statement list is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for choice of choices.nodes loop
      validate_node_id (self, choice);
      case self.nodes(Positive(choice.index)).kind is
        when Identifier_Name_Node | Selected_Name_Node =>
          Structural_Validation.validate_name (self, choice);
        when Numeric_Literal_Node =>
          Structural_Validation.validate_numeric_literal (self, choice);
        when Character_Literal_Node =>
          Structural_Validation.validate_character_literal (self, choice);
        when Case_Range_Choice_Node =>
          Structural_Validation.validate_case_range_choice (self, choice);
        when Others_Case_Choice_Node =>
          Adac.Source.validate (self.nodes(Positive(choice.index)).span);
          if Natural(choices.nodes.length) /= 1 then
            raise Program_Error with
              "Adac.AST: others case choice is not sole";
          end if;
        when others =>
          raise Program_Error with
            "Adac.AST: node is not a current case choice";
      end case;
      declare
        child_span : constant Adac.Source.Span := node_span (self, choice);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: case choices are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    for statement of statements.nodes loop
      validate_current_case_alternative_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: case alternative statements are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if previous_last /= Adac.Source.last_position (span) then
      raise Program_Error with
        "Adac.AST: case alternative span does not end at its final statement";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                              => Case_Alternative_Node,
         span                              => span,
         case_alternative_choices_value    => choices.nodes,
         case_alternative_statements_value => statements.nodes));
    return result;
  end append_case_alternative;

  function append_case_statement
    (self                 : in out Store;
     selecting_expression : Node_ID;
     alternatives         : Node_List;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    selecting_span : Adac.Source.Span;
    previous_last  : Adac.Source.Position;
  begin
    validate_store (self);
    Structural_Validation.validate_expression (self, selecting_expression);
    Adac.Source.validate (span);
    if alternatives.nodes.is_empty then
      raise Program_Error with "Adac.AST: case alternative list is empty";
    end if;

    selecting_span := node_span (self, selecting_expression);
    if not Adac.Source.contains (span, selecting_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (selecting_span))
    then
      raise Program_Error with
        "Adac.AST: case selecting expression is outside statement";
    end if;
    previous_last := Adac.Source.last_position (selecting_span);

    for alternative of alternatives.nodes loop
      require_case_alternative (self, alternative);
      Adac.Source.validate (node_span (self, alternative));
      declare
        child_span : constant Adac.Source.Span := node_span (self, alternative);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: case alternatives are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: case span does not include its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                             => Case_Statement_Node,
         span                             => span,
         case_selecting_expression_value  => selecting_expression,
         case_alternatives_value          => alternatives.nodes));
    return result;
  end append_case_statement;

  function append_block_statement
    (self             : in out Store;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position := Adac.Source.first_position (span);
  begin
    validate_store (self);
    Adac.Source.validate (span);

    for declaration of declarations.nodes loop
      validate_current_block_declaration (self, declaration);
      declare
        child_span : constant Adac.Source.Span := node_span (self, declaration);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: block declarations are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    validate_current_block_handled_sequence (self, handled_sequence);
    declare
      sequence_span : constant Adac.Source.Span :=
        node_span (self, handled_sequence);
    begin
      if not Adac.Source.contains (span, sequence_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (sequence_span)) or else
         not precedes
           (Adac.Source.last_position (sequence_span),
            Adac.Source.last_position (span))
      then
        raise Program_Error with
          "Adac.AST: block handled sequence is outside statement";
      end if;
    end;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                         => Block_Statement_Node,
         span                         => span,
         block_declarations_value     => declarations.nodes,
         block_handled_sequence_value => handled_sequence));
    return result;
  end append_block_statement;

  function append_simple_loop_statement
    (self          : in out Store;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);

    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: simple-loop body is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for statement of statements.nodes loop
      validate_current_loop_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: simple-loop body is out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: simple-loop span misses its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Loop_Statement_Node,
             span => span,
             loop_form_value => Simple_Loop_Form,
             loop_condition_value => INVALID_NODE_ID,
             loop_parameter_symbol_value => Adac.Symbols.INVALID_SYMBOL_ID,
             loop_parameter_span_value => Adac.Source.INVALID_SPAN,
             loop_reverse_value => False,
             loop_iterable_name_value => INVALID_NODE_ID,
             loop_range_attribute_value => INVALID_NODE_ID,
             loop_range_lower_bound_value => INVALID_NODE_ID,
             loop_range_upper_bound_value => INVALID_NODE_ID,
             loop_statements_value => statements.nodes));
    return result;
  end append_simple_loop_statement;

  function append_while_loop_statement
    (self          : in out Store;
     condition     : Node_ID;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    condition_span : Adac.Source.Span;
    previous_last  : Adac.Source.Position;
  begin
    validate_store (self);
    require_current_expression (self, condition);
    Structural_Validation.validate_expression (self, condition);
    Adac.Source.validate (span);

    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: while-loop body is empty";
    end if;

    condition_span := node_span (self, condition);
    if not Adac.Source.contains (span, condition_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (condition_span))
    then
      raise Program_Error with
        "Adac.AST: while-loop condition is out of source order";
    end if;

    previous_last := Adac.Source.last_position (condition_span);
    for statement of statements.nodes loop
      validate_current_loop_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: while-loop body is out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: while-loop span misses its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Loop_Statement_Node,
             span => span,
             loop_form_value => While_Loop_Form,
             loop_condition_value => condition,
             loop_parameter_symbol_value => Adac.Symbols.INVALID_SYMBOL_ID,
             loop_parameter_span_value => Adac.Source.INVALID_SPAN,
             loop_reverse_value => False,
             loop_iterable_name_value => INVALID_NODE_ID,
             loop_range_attribute_value => INVALID_NODE_ID,
             loop_range_lower_bound_value => INVALID_NODE_ID,
             loop_range_upper_bound_value => INVALID_NODE_ID,
             loop_statements_value => statements.nodes));
    return result;
  end append_while_loop_statement;

  function append_discrete_range_loop_statement
    (self             : in out Store;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     lower_bound      : Node_ID;
     upper_bound      : Node_ID;
     statements       : Node_List;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    lower_span    : Adac.Source.Span;
    upper_span    : Adac.Source.Span;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (parameter_symbol);
    Adac.Source.validate (parameter_span);
    require_current_simple_expression (self, lower_bound);
    require_current_simple_expression (self, upper_bound);
    Structural_Validation.validate_expression (self, lower_bound);
    Structural_Validation.validate_expression (self, upper_bound);
    Adac.Source.validate (span);

    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: discrete-range loop body is empty";
    end if;
    if lower_bound.index >= upper_bound.index then
      raise Program_Error with
        "Adac.AST: discrete-range loop bounds are not earlier/in order";
    end if;

    lower_span := node_span (self, lower_bound);
    upper_span := node_span (self, upper_bound);
    if not Adac.Source.contains (span, parameter_span) or else
       not Adac.Source.contains (span, lower_span) or else
       not Adac.Source.contains (span, upper_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (parameter_span)) or else
       not precedes
         (Adac.Source.last_position (parameter_span),
          Adac.Source.first_position (lower_span)) or else
       not precedes
         (Adac.Source.last_position (lower_span),
          Adac.Source.first_position (upper_span))
    then
      raise Program_Error with
        "Adac.AST: discrete-range loop header is out of source order";
    end if;

    previous_last := Adac.Source.last_position (upper_span);
    for statement of statements.nodes loop
      validate_current_loop_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: discrete-range loop body is out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: discrete-range loop span misses its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Loop_Statement_Node,
             span => span,
             loop_form_value => Discrete_Range_Loop_Form,
             loop_condition_value => INVALID_NODE_ID,
             loop_parameter_symbol_value => parameter_symbol,
             loop_parameter_span_value => parameter_span,
             loop_reverse_value => reverse_present,
             loop_iterable_name_value => INVALID_NODE_ID,
             loop_range_attribute_value => INVALID_NODE_ID,
             loop_range_lower_bound_value => lower_bound,
             loop_range_upper_bound_value => upper_bound,
             loop_statements_value => statements.nodes));
    return result;
  end append_discrete_range_loop_statement;

  function append_range_attribute_loop_statement
    (self             : in out Store;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     range_attribute  : Node_ID;
     statements       : Node_List;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    attribute_span : Adac.Source.Span;
    previous_last  : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (parameter_symbol);
    Adac.Source.validate (parameter_span);
    require_attribute_name (self, range_attribute);
    Structural_Validation.validate_name (self, range_attribute);
    Adac.Source.validate (span);

    if statements.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: range-attribute loop body is empty";
    end if;

    attribute_span := node_span (self, range_attribute);
    if not Adac.Source.contains (span, parameter_span) or else
       not Adac.Source.contains (span, attribute_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (parameter_span)) or else
       not precedes
         (Adac.Source.last_position (parameter_span),
          Adac.Source.first_position (attribute_span))
    then
      raise Program_Error with
        "Adac.AST: range-attribute loop header is out of source order";
    end if;

    previous_last := Adac.Source.last_position (attribute_span);
    for statement of statements.nodes loop
      validate_current_loop_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: range-attribute loop body is out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: range-attribute loop span misses its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Loop_Statement_Node,
             span => span,
             loop_form_value => Range_Attribute_Loop_Form,
             loop_condition_value => INVALID_NODE_ID,
             loop_parameter_symbol_value => parameter_symbol,
             loop_parameter_span_value => parameter_span,
             loop_reverse_value => reverse_present,
             loop_iterable_name_value => INVALID_NODE_ID,
             loop_range_attribute_value => range_attribute,
             loop_range_lower_bound_value => INVALID_NODE_ID,
             loop_range_upper_bound_value => INVALID_NODE_ID,
             loop_statements_value => statements.nodes));
    return result;
  end append_range_attribute_loop_statement;

  function append_loop_statement
    (self             : in out Store;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     iterable_name    : Node_ID;
     statements       : Node_List;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    iterable_span : Adac.Source.Span;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (parameter_symbol);
    Adac.Source.validate (parameter_span);
    require_simple_name (self, iterable_name);
    Structural_Validation.validate_name (self, iterable_name);
    Adac.Source.validate (span);

    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: iterator-loop body is empty";
    end if;

    iterable_span := node_span (self, iterable_name);
    if not Adac.Source.contains (span, parameter_span) or else
       not Adac.Source.contains (span, iterable_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (parameter_span)) or else
       not precedes
         (Adac.Source.last_position (parameter_span),
          Adac.Source.first_position (iterable_span))
    then
      raise Program_Error with
        "Adac.AST: iterator-loop header is out of source order";
    end if;

    previous_last := Adac.Source.last_position (iterable_span);
    for statement of statements.nodes loop
      validate_current_loop_statement (self, statement);
      declare
        child_span : constant Adac.Source.Span := node_span (self, statement);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: iterator-loop body is out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: iterator-loop span misses its closing syntax";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Loop_Statement_Node,
             span => span,
             loop_form_value => Generalized_Iterator_Loop_Form,
             loop_condition_value => INVALID_NODE_ID,
             loop_parameter_symbol_value => parameter_symbol,
             loop_parameter_span_value => parameter_span,
             loop_reverse_value => reverse_present,
             loop_iterable_name_value => iterable_name,
             loop_range_attribute_value => INVALID_NODE_ID,
             loop_range_lower_bound_value => INVALID_NODE_ID,
             loop_range_upper_bound_value => INVALID_NODE_ID,
             loop_statements_value => statements.nodes));
    return result;
  end append_loop_statement;

  function append_procedure_call_statement
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    associations : Procedure_Call_Actual_Association_List;
  begin
    for actual of actuals.nodes loop
      append (associations, actual);
    end loop;

    return append_procedure_call_statement
      (self, callable_name, associations, span, maximum_nodes);
  end append_procedure_call_statement;

  function append_procedure_call_statement
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Procedure_Call_Actual_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result           : Node_ID;
    callable_span    : Adac.Source.Span;
    previous_last    : Adac.Source.Position;
    saw_named_actual : Boolean := False;
  begin
    validate_store (self);
    Structural_Validation.validate_name (self, callable_name);
    Adac.Source.validate (span);
    callable_span := node_span (self, callable_name);

    if not Adac.Source.contains (span, callable_span) or else
       Adac.Source.first_position (span) /=
         Adac.Source.first_position (callable_span)
    then
      raise Program_Error with
        "Adac.AST: callable-name span is outside procedure call";
    end if;

    previous_last := Adac.Source.last_position (callable_span);

    for item of actuals.associations loop
      if item.form = Named_Procedure_Call_Actual_Form then
        saw_named_actual := True;
        validate_node_id (self, item.selector);
        if self.nodes(Positive(item.selector.index)).kind /=
           Identifier_Name_Node
        then
          raise Program_Error with
            "Adac.AST: named procedure-call selector is not an identifier";
        end if;

        declare
          selector_span : constant Adac.Source.Span :=
            node_span (self, item.selector);
        begin
          if not Adac.Source.contains (span, selector_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (selector_span))
          then
            raise Program_Error with
              "Adac.AST: procedure-call selector is out of source order";
          end if;
          previous_last := Adac.Source.last_position (selector_span);
        end;
      elsif saw_named_actual then
        raise Program_Error with
          "Adac.AST: positional procedure-call actual follows named actual";
      end if;

      Structural_Validation.validate_expression (self, item.actual);

      declare
        actual_span : constant Adac.Source.Span :=
          node_span (self, item.actual);
      begin
        if not Adac.Source.contains (span, actual_span) then
          raise Program_Error with
            "Adac.AST: actual span is outside procedure call";
        end if;

        if not precedes
          (previous_last, Adac.Source.first_position (actual_span))
        then
          raise Program_Error with
            "Adac.AST: procedure-call actuals are out of source order";
        end if;

        previous_last := Adac.Source.last_position (actual_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: procedure-call span does not include its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'
        (kind                               => Procedure_Call_Statement_Node,
         span                               => span,
         procedure_call_callable_name_value => callable_name,
         procedure_call_actuals_value       => actuals.associations));
    return result;
  end append_procedure_call_statement;

  function append_extended_return_statement
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     sequence      : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    subtype_span  : Adac.Source.Span;
    sequence_span : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);
    require_simple_name (self, subtype_mark);
    require_handled_sequence (self, sequence);
    Structural_Validation.validate_name (self, subtype_mark);

    declare
      sequence_value : Node renames self.nodes(Positive(sequence.index));
    begin
      if sequence_value.handled_sequence_statements_value.is_empty or else
         not sequence_value.handled_sequence_handlers_value.is_empty
      then
        raise Program_Error with
          "Adac.AST: extended return requires a handler-free body";
      end if;

      for child of sequence_value.handled_sequence_statements_value loop
        validate_node_id (self, child);
        if self.nodes(Positive(child.index)).kind not in
          Null_Statement_Node |
          Assignment_Statement_Node | Procedure_Call_Statement_Node
        then
          raise Program_Error with
            "Adac.AST: extended return body statement is not supported";
        end if;
      end loop;
    end;
    Structural_Validation.validate_handled_sequence (self, sequence);

    subtype_span := node_span (self, subtype_mark);
    sequence_span := node_span (self, sequence);
    if subtype_mark.index >= sequence.index then
      raise Program_Error with
        "Adac.AST: extended return children are out of publication order";
    end if;

    if not Adac.Source.contains (span, defining_span) or else
       not Adac.Source.contains (span, subtype_span) or else
       not Adac.Source.contains (span, sequence_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span)) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.first_position (subtype_span)) or else
       not precedes
         (Adac.Source.last_position (subtype_span),
          Adac.Source.first_position (sequence_span)) or else
       not precedes
         (Adac.Source.last_position (sequence_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: extended return children are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Extended_Return_Statement_Node,
             span => span,
             extended_return_symbol_value => symbol,
             extended_return_defining_span_value => defining_span,
             extended_return_subtype_mark_value => subtype_mark,
             extended_return_handled_sequence_value => sequence));
    return result;
  end append_extended_return_statement;

  function append_exit_statement
    (self             : in out Store;
     loop_name_symbol : Adac.Symbols.Symbol_ID;
     loop_name_span   : Adac.Source.Span;
     when_span        : Adac.Source.Span;
     condition        : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Source.validate (span);

    if (loop_name_symbol = Adac.Symbols.INVALID_SYMBOL_ID) /=
       (loop_name_span = Adac.Source.INVALID_SPAN)
    then
      raise Program_Error with
        "Adac.AST: exit loop-name symbol/span presence disagrees";
    end if;

    if loop_name_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
      Adac.Symbols.validate (loop_name_symbol);
      Adac.Source.validate (loop_name_span);
      if not Adac.Source.contains (span, loop_name_span) or else
         not precedes
           (Adac.Source.first_position (span),
            Adac.Source.first_position (loop_name_span))
      then
        raise Program_Error with
          "Adac.AST: exit loop name is out of source order";
      end if;
    end if;

    if (condition = INVALID_NODE_ID) /=
       (when_span = Adac.Source.INVALID_SPAN)
    then
      raise Program_Error with
        "Adac.AST: exit when/condition presence disagrees";
    end if;

    if condition /= INVALID_NODE_ID then
      validate_when_span (when_span);
      require_current_expression (self, condition);
      Structural_Validation.validate_expression (self, condition);
      declare
        condition_span : constant Adac.Source.Span :=
          node_span (self, condition);
        previous_last : Adac.Source.Position;
      begin
        if loop_name_symbol = Adac.Symbols.INVALID_SYMBOL_ID then
          previous_last := Adac.Source.first_position (span);
        else
          previous_last := Adac.Source.last_position (loop_name_span);
        end if;
        if not Adac.Source.contains (span, when_span) or else
           not Adac.Source.contains (span, condition_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (when_span)) or else
           not precedes
             (Adac.Source.last_position (when_span),
              Adac.Source.first_position (condition_span)) or else
           not precedes
             (Adac.Source.last_position (condition_span),
              Adac.Source.last_position (span))
        then
          raise Program_Error with
            "Adac.AST: exit condition is out of source order";
        end if;
      end;
    elsif loop_name_symbol /= Adac.Symbols.INVALID_SYMBOL_ID and then
          not precedes
            (Adac.Source.last_position (loop_name_span),
             Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: exit span omits its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Exit_Statement_Node,
             span => span,
             exit_loop_name_symbol_value => loop_name_symbol,
             exit_loop_name_span_value => loop_name_span,
             exit_when_span_value => when_span,
             exit_condition_value => condition));
    return result;
  end append_exit_statement;

  function append_return_statement
    (self          : in out Store;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if expression /= INVALID_NODE_ID then
      require_current_expression (self, expression);
      Structural_Validation.validate_expression (self, expression);
      declare
        expression_span : constant Adac.Source.Span :=
          node_span (self, expression);
      begin
        if not Adac.Source.contains (span, expression_span) or else
           not precedes
             (Adac.Source.first_position (span),
              Adac.Source.first_position (expression_span)) or else
           not precedes
             (Adac.Source.last_position (expression_span),
              Adac.Source.last_position (span))
        then
          raise Program_Error with
            "Adac.AST: return expression is out of source order";
        end if;
      end;
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Return_Statement_Node,
             span => span,
             return_expression_value => expression));
    return result;
  end append_return_statement;

  function append_bare_raise_statement
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Raise_Statement_Node,
             span => span,
             raise_form_value => Bare_Reraise_Form,
             raise_exception_name_value => INVALID_NODE_ID,
             raise_message_expression_value => INVALID_NODE_ID));
    return result;
  end append_bare_raise_statement;

  function append_raise_statement
    (self           : in out Store;
     exception_name : Node_ID;
     message        : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID is
    result         : Node_ID;
    exception_span : Adac.Source.Span;
    message_span   : Adac.Source.Span;
  begin
    validate_store (self);
    require_simple_name (self, exception_name);
    require_current_expression (self, message);
    Structural_Validation.validate_name (self, exception_name);
    Structural_Validation.validate_expression (self, message);
    Adac.Source.validate (span);
    exception_span := node_span (self, exception_name);
    message_span := node_span (self, message);

    if exception_name.index >= message.index then
      raise Program_Error with
        "Adac.AST: raise-statement children are not ordered";
    end if;
    if not Adac.Source.contains (span, exception_span) or else
       not Adac.Source.contains (span, message_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (exception_span)) or else
       not precedes
         (Adac.Source.last_position (exception_span),
          Adac.Source.first_position (message_span)) or else
       not precedes
         (Adac.Source.last_position (message_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: raise-statement children are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Raise_Statement_Node,
             span => span,
             raise_form_value => Named_With_Message_Raise_Form,
             raise_exception_name_value => exception_name,
             raise_message_expression_value => message));
    return result;
  end append_raise_statement;

  function append_statement
    (self          : in out Store;
     kind          : Node_Kind;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);

    Adac.Source.validate (span);

    case kind is
      when Null_Statement_Node | Return_Statement_Node =>
        null;

      when Compilation_Unit_Node |
           Subunit_Node |
           Procedure_Body_Node |
           Function_Body_Node |
           With_Clause_Node |
           Use_Type_Clause_Node |
           Use_Package_Clause_Node |
           Exit_Statement_Node |
           Extended_Return_Statement_Node |
           Raise_Statement_Node |
           Assignment_Statement_Node |
           Case_Alternative_Node |
           Case_Range_Choice_Node |
           Others_Case_Choice_Node |
           Case_Statement_Node |
           Block_Statement_Node |
           Loop_Statement_Node |
           Procedure_Call_Statement_Node |
           If_Statement_Node |
           Elsif_Part_Node |
           Others_Exception_Choice_Node |
           Exception_Handler_Node |
           Handled_Sequence_Node |
           Numeric_Literal_Node |
           Character_Literal_Node |
           String_Literal_Node |
           Null_Literal_Node |
           Record_Aggregate_Node |
           Array_Aggregate_Node |
           Bracket_Aggregate_Node |
           Qualified_Expression_Node |
           Allocator_Node |
           If_Expression_Node |
           Case_Expression_Alternative_Node |
           Case_Expression_Node |
           Raise_Expression_Node |
           Parenthesized_Expression_Node |
           Unary_Operator_Node |
           Binary_Exponentiating_Node |
           Binary_Multiplying_Node |
           Binary_Adding_Node |
           Relation_Node |
           Membership_Range_Choice_Node |
           Membership_Expression_Node |
           Logical_Expression_Node |
           Short_Circuit_Expression_Node |
           Identifier_Name_Node |
           Selected_Name_Node |
           Explicit_Dereference_Name_Node |
           Selected_Component_Node |
           Parenthesized_Name_Node |
           Slice_Name_Node |
           Attribute_Name_Node |
           Aspect_Specification_Node |
           Parameter_Specification_Node |
           Object_Declaration_Node |
           Object_Renaming_Declaration_Node |
           Number_Declaration_Node |
           Exception_Declaration_Node |
           Procedure_Declaration_Node |
           Procedure_Body_Stub_Node |
           Function_Declaration_Node |
           Private_Type_Declaration_Node |
           Derived_Type_Declaration_Node |
           Range_Constraint_Node |
           Index_Constraint_Node |
           Subtype_Declaration_Node |
           Enumeration_Type_Declaration_Node |
           Discriminant_Specification_Node |
           Record_Component_Declaration_Node |
           Record_Variant_Node |
           Record_Variant_Part_Node |
           Record_Type_Declaration_Node |
           Access_Object_Type_Declaration_Node |
           Package_Renaming_Declaration_Node |
           Package_Instantiation_Node |
           Package_Declaration_Node |
           Package_Body_Stub_Node |
           Package_Body_Node =>
        raise Program_Error with "Adac.AST: invalid statement node kind";
    end case;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);

    case kind is
      when Null_Statement_Node =>
        self.nodes.append
          (Node'(kind => Null_Statement_Node, span => span));

      when Return_Statement_Node =>
        self.nodes.append
          (Node'(kind => Return_Statement_Node,
                 span => span,
                 return_expression_value => INVALID_NODE_ID));

      when Compilation_Unit_Node |
           Subunit_Node |
           Procedure_Body_Node |
           Function_Body_Node |
           With_Clause_Node |
           Use_Type_Clause_Node |
           Use_Package_Clause_Node |
           Exit_Statement_Node |
           Extended_Return_Statement_Node |
           Raise_Statement_Node |
           Assignment_Statement_Node |
           Case_Alternative_Node |
           Case_Range_Choice_Node |
           Others_Case_Choice_Node |
           Case_Statement_Node |
           Block_Statement_Node |
           Loop_Statement_Node |
           Procedure_Call_Statement_Node |
           If_Statement_Node |
           Elsif_Part_Node |
           Others_Exception_Choice_Node |
           Exception_Handler_Node |
           Handled_Sequence_Node |
           Numeric_Literal_Node |
           Character_Literal_Node |
           String_Literal_Node |
           Null_Literal_Node |
           Record_Aggregate_Node |
           Array_Aggregate_Node |
           Bracket_Aggregate_Node |
           Qualified_Expression_Node |
           Allocator_Node |
           If_Expression_Node |
           Case_Expression_Alternative_Node |
           Case_Expression_Node |
           Raise_Expression_Node |
           Parenthesized_Expression_Node |
           Unary_Operator_Node |
           Binary_Exponentiating_Node |
           Binary_Multiplying_Node |
           Binary_Adding_Node |
           Relation_Node |
           Membership_Range_Choice_Node |
           Membership_Expression_Node |
           Logical_Expression_Node |
           Short_Circuit_Expression_Node |
           Identifier_Name_Node |
           Selected_Name_Node |
           Explicit_Dereference_Name_Node |
           Selected_Component_Node |
           Parenthesized_Name_Node |
           Slice_Name_Node |
           Attribute_Name_Node |
           Aspect_Specification_Node |
           Parameter_Specification_Node |
           Object_Declaration_Node |
           Object_Renaming_Declaration_Node |
           Number_Declaration_Node |
           Exception_Declaration_Node |
           Procedure_Declaration_Node |
           Procedure_Body_Stub_Node |
           Function_Declaration_Node |
           Private_Type_Declaration_Node |
           Derived_Type_Declaration_Node |
           Range_Constraint_Node |
           Index_Constraint_Node |
           Subtype_Declaration_Node |
           Enumeration_Type_Declaration_Node |
           Discriminant_Specification_Node |
           Record_Component_Declaration_Node |
           Record_Variant_Node |
           Record_Variant_Part_Node |
           Record_Type_Declaration_Node |
           Access_Object_Type_Declaration_Node |
           Package_Renaming_Declaration_Node |
           Package_Instantiation_Node |
           Package_Declaration_Node |
           Package_Body_Stub_Node |
           Package_Body_Node =>
        raise Program_Error with "Adac.AST: unreachable statement node kind";
    end case;

    return result;
  end append_statement;

  function append_with_clause
    (self          : in out Store;
     names         : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);

    if names.nodes.is_empty then
      raise Program_Error with "Adac.AST: with-clause name list is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for name of names.nodes loop
      require_simple_name (self, name);
      validate_simple_name (self, name);

      declare
        name_span : constant Adac.Source.Span :=
          self.nodes(Positive(name.index)).span;
      begin
        if not Adac.Source.contains (span, name_span) then
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

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: with-clause span does not include its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind          => With_Clause_Node,
             span          => span,
             library_names => names.nodes));
    return result;
  end append_with_clause;

  function append_use_type_clause
    (self          : in out Store;
     subtype_marks : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if subtype_marks.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: use-type subtype-mark list is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for subtype_mark of subtype_marks.nodes loop
      require_simple_name (self, subtype_mark);
      Structural_Validation.validate_name (self, subtype_mark);
      declare
        mark_span : constant Adac.Source.Span :=
          node_span (self, subtype_mark);
      begin
        if not Adac.Source.contains (span, mark_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (mark_span))
        then
          raise Program_Error with
            "Adac.AST: use-type subtype marks are out of source order";
        end if;
        previous_last := Adac.Source.last_position (mark_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: use-type clause span omits its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                         => Use_Type_Clause_Node,
             span                         => span,
             use_type_subtype_marks_value => subtype_marks.nodes));
    return result;
  end append_use_type_clause;

  function append_use_package_clause
    (self          : in out Store;
     package_names : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if package_names.nodes.is_empty then
      raise Program_Error with
        "Adac.AST: package-use name list is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for package_name of package_names.nodes loop
      require_simple_name (self, package_name);
      Structural_Validation.validate_name (self, package_name);
      declare
        name_span : constant Adac.Source.Span :=
          node_span (self, package_name);
      begin
        if not Adac.Source.contains (span, name_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (name_span))
        then
          raise Program_Error with
            "Adac.AST: package-use names are out of source order";
        end if;
        previous_last := Adac.Source.last_position (name_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: package-use clause span omits its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                    => Use_Package_Clause_Node,
             span                    => span,
             use_package_names_value => package_names.nodes));
    return result;
  end append_use_package_clause;

  function append_package_renaming_declaration
    (self            : in out Store;
     defining_name   : Program_Unit_Name;
     renamed_package : Node_ID;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
    renamed_span  : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if defining_name.components.is_empty then
      raise Program_Error with
        "Adac.AST: package renaming defining name is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for component of defining_name.components loop
      Adac.Symbols.validate (component.symbol);
      Adac.Source.validate (component.span);
      if not Adac.Source.contains (span, component.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (component.span))
      then
        raise Program_Error with
          "Adac.AST: package renaming defining name is out of source order";
      end if;
      previous_last := Adac.Source.last_position (component.span);
    end loop;

    require_simple_name (self, renamed_package);
    Structural_Validation.validate_name (self, renamed_package);
    renamed_span := node_span (self, renamed_package);
    if not Adac.Source.contains (span, renamed_span) or else
       not precedes
         (previous_last, Adac.Source.first_position (renamed_span)) or else
       not precedes
         (Adac.Source.last_position (renamed_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: renamed package name is out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Package_Renaming_Declaration_Node,
             span => span,
             package_renaming_defining_name_value => defining_name.components,
             package_renaming_renamed_package_value => renamed_package));
    return result;
  end append_package_renaming_declaration;

  function append_package_instantiation
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     generic_name  : Node_ID;
     actuals       : Generic_Actual_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
    generic_span  : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Source.validate (span);

    if defining_name.components.is_empty then
      raise Program_Error with
        "Adac.AST: package instantiation defining name is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for component of defining_name.components loop
      Adac.Symbols.validate (component.symbol);
      Adac.Source.validate (component.span);
      if not Adac.Source.contains (span, component.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (component.span))
      then
        raise Program_Error with
          "Adac.AST: package instantiation defining name is out of " &
          "source order";
      end if;
      previous_last := Adac.Source.last_position (component.span);
    end loop;

    require_simple_name (self, generic_name);
    Structural_Validation.validate_name (self, generic_name);
    generic_span := node_span (self, generic_name);
    if not Adac.Source.contains (span, generic_span) or else
       not precedes
         (previous_last, Adac.Source.first_position (generic_span))
    then
      raise Program_Error with
        "Adac.AST: generic package name is out of source order";
    end if;
    previous_last := Adac.Source.last_position (generic_span);

    for association of actuals.associations loop
      case kind_of (self, association.actual) is
        when String_Literal_Node =>
          Structural_Validation.validate_expression (self, association.actual);
        when others =>
          require_current_name (self, association.actual);
          Structural_Validation.validate_name (self, association.actual);
      end case;
      declare
        actual_span : constant Adac.Source.Span :=
          node_span (self, association.actual);
      begin
        case association.form is
          when Positional_Generic_Actual_Form =>
            if association.selector /= Adac.Symbols.INVALID_SYMBOL_ID or else
               association.selector_span /= Adac.Source.INVALID_SPAN or else
               not Adac.Source.contains (span, actual_span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (actual_span))
            then
              raise Program_Error with
                "Adac.AST: positional generic actual is out of source order";
            end if;

          when Named_Generic_Actual_Form =>
            Adac.Symbols.validate (association.selector);
            Adac.Source.validate (association.selector_span);
            if not Adac.Source.contains
              (span, association.selector_span) or else
               not Adac.Source.contains (span, actual_span) or else
               not precedes
                 (previous_last,
                  Adac.Source.first_position
                    (association.selector_span)) or else
               not precedes
                 (Adac.Source.last_position (association.selector_span),
                  Adac.Source.first_position (actual_span))
            then
              raise Program_Error with
                "Adac.AST: named generic actual is out of source order";
            end if;
        end case;
        previous_last := Adac.Source.last_position (actual_span);
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: package instantiation span omits its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Package_Instantiation_Node,
             span => span,
             package_instantiation_defining_name_value =>
               defining_name.components,
             package_instantiation_generic_name_value => generic_name,
             package_instantiation_actuals_value => actuals.associations));
    return result;
  end append_package_instantiation;

  function append_package_declaration
    (self                 : in out Store;
     defining_name        : Program_Unit_Name;
     visible_declarations : Node_List;
     private_part_span    : Adac.Source.Span;
     private_declarations : Node_List;
     end_name             : Program_Unit_Name;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;

    procedure validate_child
      (declaration : Node_ID;
       part_name   : String)
    is
      child_span : Adac.Source.Span;
    begin
      validate_node_id (self, declaration);
      case self.nodes(Positive(declaration.index)).kind is
        when Object_Declaration_Node |
             Object_Renaming_Declaration_Node |
             Number_Declaration_Node |
             Exception_Declaration_Node |
             Procedure_Declaration_Node |
             Function_Declaration_Node |
             Private_Type_Declaration_Node |
             Derived_Type_Declaration_Node |
             Subtype_Declaration_Node |
             Enumeration_Type_Declaration_Node |
             Record_Type_Declaration_Node |
             Access_Object_Type_Declaration_Node |
             Package_Renaming_Declaration_Node |
             Package_Instantiation_Node =>
          Structural_Validation.validate_declaration (self, declaration);

        when Package_Declaration_Node =>
          require_package_declaration (self, declaration);

        when others =>
          raise Program_Error with
            "Adac.AST: node is not a current package declaration";
      end case;

      child_span := node_span (self, declaration);
      if not Adac.Source.contains (span, child_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (child_span))
      then
        raise Program_Error with
          "Adac.AST: package " & part_name &
          " declarations are out of source order";
      end if;
      previous_last := Adac.Source.last_position (child_span);
    end validate_child;

  begin
    validate_store (self);
    Adac.Source.validate (span);

    if defining_name.components.is_empty then
      raise Program_Error with
        "Adac.AST: package defining program-unit name is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for component of defining_name.components loop
      Adac.Symbols.validate (component.symbol);
      Adac.Source.validate (component.span);
      if not Adac.Source.contains (span, component.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (component.span))
      then
        raise Program_Error with
          "Adac.AST: package defining name is out of source order";
      end if;
      previous_last := Adac.Source.last_position (component.span);
    end loop;

    for declaration of visible_declarations.nodes loop
      validate_child (declaration, "visible");
    end loop;

    if private_part_span = Adac.Source.INVALID_SPAN then
      if not private_declarations.nodes.is_empty then
        raise Program_Error with
          "Adac.AST: package private declarations lack a private boundary";
      end if;
    else
      Adac.Source.validate (private_part_span);
      if not Adac.Source.contains (span, private_part_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (private_part_span))
      then
        raise Program_Error with
          "Adac.AST: package private boundary is out of source order";
      end if;
      previous_last := Adac.Source.last_position (private_part_span);

      for declaration of private_declarations.nodes loop
        validate_child (declaration, "private");
      end loop;
    end if;

    for component of end_name.components loop
      Adac.Symbols.validate (component.symbol);
      Adac.Source.validate (component.span);
      if not Adac.Source.contains (span, component.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (component.span))
      then
        raise Program_Error with
          "Adac.AST: package closing name is out of source order";
      end if;
      previous_last := Adac.Source.last_position (component.span);
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: package span does not include its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                               => Package_Declaration_Node,
             span                               => span,
             package_defining_name_value        => defining_name.components,
             package_visible_declarations_value => visible_declarations.nodes,
             package_private_part_span_value    => private_part_span,
             package_private_declarations_value => private_declarations.nodes,
             package_end_name_value             => end_name.components));
    return result;
  end append_package_declaration;

  function append_package_body_stub
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Symbols.validate (symbol);
    Adac.Source.validate (defining_span);
    Adac.Source.validate (span);

    if not Adac.Source.contains (span, defining_span) or else
       not precedes
         (Adac.Source.first_position (span),
          Adac.Source.first_position (defining_span)) or else
       not precedes
         (Adac.Source.last_position (defining_span),
          Adac.Source.last_position (span))
    then
      raise Program_Error with
        "Adac.AST: package-body-stub spans are out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Package_Body_Stub_Node,
             span => span,
             package_body_stub_symbol_value => symbol,
             package_body_stub_defining_span_value => defining_span));
    return result;
  end append_package_body_stub;

  function append_package_body
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     declarations  : Node_List;
     end_name      : Program_Unit_Name;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Source.validate (span);

    if defining_name.components.is_empty then
      raise Program_Error with
        "Adac.AST: package-body defining program-unit name is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for component of defining_name.components loop
      Adac.Symbols.validate (component.symbol);
      Adac.Source.validate (component.span);
      if not Adac.Source.contains (span, component.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (component.span))
      then
        raise Program_Error with
          "Adac.AST: package-body defining name is out of source order";
      end if;
      previous_last := Adac.Source.last_position (component.span);
    end loop;

    for declaration of declarations.nodes loop
      validate_node_id (self, declaration);
      case self.nodes(Positive(declaration.index)).kind is
        when Procedure_Body_Node =>
          Structural_Validation.validate_procedure_body (self, declaration);

        when Function_Body_Node =>
          Structural_Validation.validate_function_body (self, declaration);

        when Use_Type_Clause_Node =>
          Structural_Validation.validate_use_type_clause (self, declaration);

        when Use_Package_Clause_Node =>
          Structural_Validation.validate_use_package_clause (self, declaration);

        when Package_Body_Stub_Node =>
          Structural_Validation.validate_package_body_stub (self, declaration);

        when Object_Declaration_Node |
             Object_Renaming_Declaration_Node |
             Number_Declaration_Node |
             Exception_Declaration_Node |
             Procedure_Declaration_Node |
             Procedure_Body_Stub_Node |
             Function_Declaration_Node |
             Private_Type_Declaration_Node |
             Derived_Type_Declaration_Node |
             Subtype_Declaration_Node |
             Enumeration_Type_Declaration_Node |
             Record_Type_Declaration_Node |
             Access_Object_Type_Declaration_Node |
             Package_Renaming_Declaration_Node |
             Package_Instantiation_Node |
             Package_Declaration_Node =>
          Structural_Validation.validate_declaration (self, declaration);

        when others =>
          raise Program_Error with
            "Adac.AST: node is not a package-body declarative item";
      end case;
      declare
        child_span : constant Adac.Source.Span :=
          node_span (self, declaration);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: package-body declarations are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    for component of end_name.components loop
      Adac.Symbols.validate (component.symbol);
      Adac.Source.validate (component.span);
      if not Adac.Source.contains (span, component.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (component.span))
      then
        raise Program_Error with
          "Adac.AST: package-body closing name is out of source order";
      end if;
      previous_last := Adac.Source.last_position (component.span);
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (span)) then
      raise Program_Error with
        "Adac.AST: package-body span does not include its terminator";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                             => Package_Body_Node,
             span                             => span,
             body_defining_name_value => defining_name.components,
             body_declarations_value  => declarations.nodes,
             body_end_name_value      => end_name.components));
    return result;
  end append_package_body;

  function append_procedure_body
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Node_List;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (procedure_symbol);
    if end_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
      Adac.Symbols.validate (end_symbol);
    end if;
    Adac.Source.validate (span);
    previous_last := Adac.Source.first_position (span);

    for parameter of parameters.nodes loop
      require_parameter_specification (self, parameter);
      Structural_Validation.validate_parameter (self, parameter);
      declare
        child_span : constant Adac.Source.Span := node_span (self, parameter);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: procedure parameters are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    for declaration of declarations.nodes loop
      validate_node_id (self, declaration);
      case self.nodes(Positive(declaration.index)).kind is
        when Object_Declaration_Node |
             Number_Declaration_Node |
             Object_Renaming_Declaration_Node |
             Procedure_Declaration_Node |
             Function_Declaration_Node |
             Enumeration_Type_Declaration_Node |
             Record_Type_Declaration_Node |
             Subtype_Declaration_Node |
             Package_Instantiation_Node =>
          Structural_Validation.validate_declaration (self, declaration);
        when Use_Type_Clause_Node =>
          Structural_Validation.validate_use_type_clause (self, declaration);
        when Use_Package_Clause_Node =>
          Structural_Validation.validate_use_package_clause (self, declaration);
        when Procedure_Body_Node =>
          require_procedure_body (self, declaration);
          Adac.Source.validate (node_span (self, declaration));
        when Function_Body_Node =>
          require_function_body (self, declaration);
          for function_index in 1 ..
            function_body_declaration_count (self, declaration)
          loop
            declare
              function_declaration : constant Node_ID :=
                function_body_declaration_at
                  (self, declaration, function_index);
            begin
              validate_node_id (self, function_declaration);
              case self.nodes(Positive(function_declaration.index)).kind is
                when Object_Declaration_Node =>
                  Structural_Validation.validate_declaration
                    (self, function_declaration);

                when Procedure_Body_Node =>
                  require_procedure_body (self, function_declaration);
                  if declaration_count (self, function_declaration) /= 0 then
                    for nested_index in 1 ..
                      declaration_count (self, function_declaration)
                    loop
                      declare
                        nested : constant Node_ID := declaration_at
                          (self, function_declaration, nested_index);
                      begin
                        case self.nodes(Positive(nested.index)).kind is
                          when Procedure_Body_Node | Function_Body_Node =>
                            raise Program_Error with
                              "Adac.AST: bounded procedure-owned function " &
                              "procedure contains a subprogram body";
                          when others =>
                            null;
                        end case;
                      end;
                    end loop;
                  end if;
                  Adac.Source.validate
                    (node_span (self, function_declaration));

                when others =>
                  raise Program_Error with
                    "Adac.AST: procedure-owned function has unsupported " &
                    "declarative item";
              end case;
            end;
          end loop;
          Adac.Source.validate (node_span (self, declaration));
        when others =>
          raise Program_Error with
            "Adac.AST: node is not a procedure declarative item";
      end case;
      declare
        child_span : constant Adac.Source.Span := node_span (self, declaration);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: procedure declarations are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    Structural_Validation.validate_handled_sequence (self, handled_sequence);
    declare
      handled_span : constant Adac.Source.Span :=
        node_span (self, handled_sequence);
    begin
      if not Adac.Source.contains (span, handled_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (handled_span)) or else
         not precedes
           (Adac.Source.last_position (handled_span),
            Adac.Source.last_position (span))
      then
        raise Program_Error with
          "Adac.AST: handled sequence is out of procedure-body order";
      end if;
    end;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind                             => Procedure_Body_Node,
             span                             => span,
             procedure_symbol                 => procedure_symbol,
             parameters                       => parameters.nodes,
             declarations                     => declarations.nodes,
             procedure_handled_sequence_value => handled_sequence,
             end_symbol                       => end_symbol));
    return result;
  end append_procedure_body;

  function append_function_body
    (self             : in out Store;
     function_symbol  : Adac.Symbols.Symbol_ID;
     parameters       : Node_List;
     result_subtype   : Node_ID;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
  begin
    validate_store (self);
    Adac.Symbols.validate (function_symbol);
    if end_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
      Adac.Symbols.validate (end_symbol);
    end if;
    Adac.Source.validate (span);
    previous_last := Adac.Source.first_position (span);

    for parameter of parameters.nodes loop
      require_parameter_specification (self, parameter);
      Structural_Validation.validate_parameter (self, parameter);
      declare
        child_span : constant Adac.Source.Span := node_span (self, parameter);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: function parameters are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    require_simple_name (self, result_subtype);
    Structural_Validation.validate_name (self, result_subtype);
    declare
      result_span : constant Adac.Source.Span :=
        node_span (self, result_subtype);
    begin
      if not Adac.Source.contains (span, result_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (result_span))
      then
        raise Program_Error with
          "Adac.AST: function result subtype is out of source order";
      end if;
      previous_last := Adac.Source.last_position (result_span);
    end;

    for declaration of declarations.nodes loop
      validate_node_id (self, declaration);
      case self.nodes(Positive(declaration.index)).kind is
        when Procedure_Body_Node =>
          require_procedure_body (self, declaration);
          Adac.Source.validate (node_span (self, declaration));
        when Function_Body_Node =>
          require_function_body (self, declaration);
          Adac.Source.validate (node_span (self, declaration));
        when others =>
          Structural_Validation.validate_declaration (self, declaration);
      end case;
      declare
        child_span : constant Adac.Source.Span := node_span (self, declaration);
      begin
        if not Adac.Source.contains (span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: function declarations are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end;
    end loop;

    Structural_Validation.validate_handled_sequence (self, handled_sequence);
    declare
      handled_span : constant Adac.Source.Span :=
        node_span (self, handled_sequence);
    begin
      if not Adac.Source.contains (span, handled_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (handled_span)) or else
         not precedes
           (Adac.Source.last_position (handled_span),
            Adac.Source.last_position (span))
      then
        raise Program_Error with
          "Adac.AST: handled sequence is out of function-body order";
      end if;
    end;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Function_Body_Node,
             span => span,
             function_body_symbol_value => function_symbol,
             function_body_parameters_value => parameters.nodes,
             function_body_result_subtype_value => result_subtype,
             function_body_declarations_value => declarations.nodes,
             function_body_handled_sequence_value => handled_sequence,
             function_body_end_symbol_value => end_symbol));
    return result;
  end append_function_body;

  function append_subunit
    (self             : in out Store;
     parent_unit_name : Program_Unit_Name;
     proper_body      : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
    body_span     : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    if parent_unit_name.components.is_empty then
      raise Program_Error with "Adac.AST: subunit parent unit name is empty";
    end if;

    previous_last := Adac.Source.first_position (span);
    for component of parent_unit_name.components loop
      Adac.Symbols.validate (component.symbol);
      Adac.Source.validate (component.span);
      if not Adac.Source.contains (span, component.span) or else
         not precedes
           (previous_last, Adac.Source.first_position (component.span))
      then
        raise Program_Error with
          "Adac.AST: subunit parent unit name is out of source order";
      end if;
      previous_last := Adac.Source.last_position (component.span);
    end loop;

    validate_node_id (self, proper_body);
    case self.nodes(Positive(proper_body.index)).kind is
      when Procedure_Body_Node =>
        Structural_Validation.validate_procedure_body (self, proper_body);
      when Function_Body_Node =>
        Structural_Validation.validate_function_body (self, proper_body);
      when Package_Body_Node =>
        Structural_Validation.validate_package_body (self, proper_body);
      when others =>
        raise Program_Error with "Adac.AST: node is not a current proper body";
    end case;
    body_span := node_span (self, proper_body);
    if not Adac.Source.contains (span, body_span) or else
       not precedes
         (previous_last, Adac.Source.first_position (body_span)) or else
       Adac.Source.last_position (span) /= Adac.Source.last_position (body_span)
    then
      raise Program_Error with
        "Adac.AST: subunit proper body is out of source order";
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind => Subunit_Node,
             span => span,
             subunit_parent_name_value => parent_unit_name.components,
             subunit_proper_body_value => proper_body));
    return result;
  end append_subunit;

  function append_compilation_unit
    (self          : in out Store;
     context_items : Node_List;
     unit_item     : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID is
    result        : Node_ID;
    previous_last : Adac.Source.Position;
    item_span     : Adac.Source.Span;
  begin
    validate_store (self);
    Adac.Source.validate (span);
    validate_node_id (self, unit_item);
    case self.nodes(Positive(unit_item.index)).kind is
      when Subunit_Node =>
        Structural_Validation.validate_subunit (self, unit_item);
      when Procedure_Body_Node =>
        require_procedure_body (self, unit_item);
      when Package_Renaming_Declaration_Node =>
        require_package_renaming_declaration (self, unit_item);
      when Package_Instantiation_Node =>
        require_package_instantiation (self, unit_item);
      when Package_Declaration_Node =>
        require_package_declaration (self, unit_item);
      when Package_Body_Node =>
        require_package_body (self, unit_item);
      when others =>
        raise Program_Error with "Adac.AST: node is not a current unit item";
    end case;
    item_span := self.nodes(Positive(unit_item.index)).span;

    if not Adac.Source.contains (span, item_span) or else
       Adac.Source.last_position (span) /= Adac.Source.last_position (item_span)
    then
      raise Program_Error with
        "Adac.AST: unit-item span is outside compilation unit";
    end if;

    if context_items.nodes.is_empty then
      if Adac.Source.first_position (span) /=
         Adac.Source.first_position (item_span)
      then
        raise Program_Error with
          "Adac.AST: context-free unit span does not start at unit item";
      end if;
    else
      previous_last := Adac.Source.first_position (span);
      for item of context_items.nodes loop
        require_with_clause (self, item);

        if item.index >= unit_item.index then
          raise Program_Error with
            "Adac.AST: context item does not precede unit item";
        end if;

        declare
          item_span : constant Adac.Source.Span :=
            self.nodes(Positive(item.index)).span;
        begin
          if not Adac.Source.contains (span, item_span) then
            raise Program_Error with
              "Adac.AST: context-item span is outside compilation unit";
          end if;

          if item = context_items.nodes.first_element then
            if Adac.Source.first_position (item_span) /=
               Adac.Source.first_position (span)
            then
              raise Program_Error with
                "Adac.AST: compilation-unit span misses first context item";
            end if;
          elsif not precedes
            (previous_last, Adac.Source.first_position (item_span))
          then
            raise Program_Error with
              "Adac.AST: context items are out of source order";
          end if;

          previous_last := Adac.Source.last_position (item_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.first_position (item_span))
      then
        raise Program_Error with
          "Adac.AST: context clause does not precede unit item";
      end if;
    end if;

    require_node_capacity (self, maximum_nodes);
    result := next_node_id (self);
    self.nodes.append
      (Node'(kind          => Compilation_Unit_Node,
             span          => span,
             context_items => context_items.nodes,
             unit_item_value => unit_item));
    return result;
  end append_compilation_unit;

end Construction_Implementation;
