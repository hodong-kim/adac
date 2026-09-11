-- ============================================================================
-- adac-compilation-syntax.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;

with Adac.AST.Construction;
with Adac.AST.Validation;

with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;

package body Adac.Compilation.Syntax is

  use type Adac.AST.Node_Kind;
  use type Adac.AST.Node_ID;
  use type Adac.AST.Membership_Operator_Kind;
  use type Adac.AST.Generic_Actual_Association_Form;
  use type Adac.AST.Parenthesized_Name_Item_Form;
  use type Adac.AST.Procedure_Call_Actual_Association_Form;
  use type Adac.Symbols.Symbol_ID;
  use type Adac.Source.Span;

  procedure validate_current_block_handled_sequence
    (self     : Context;
     sequence : Adac.AST.Node_ID)
  is
    has_handlers : constant Boolean :=
      Adac.AST.handled_sequence_handler_count
        (self.ast_store, sequence) /= 0;
  begin
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, sequence));
    if Adac.AST.handled_sequence_statement_count
      (self.ast_store, sequence) = 0
    then
      raise Program_Error with
        "Adac.Compilation.Syntax: current block sequence is empty";
    end if;

    for index in 1 .. Adac.AST.handled_sequence_statement_count
      (self.ast_store, sequence)
    loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.handled_sequence_statement_at
            (self.ast_store, sequence, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Assignment_Statement_Node |
               Adac.AST.Case_Statement_Node |
               Adac.AST.Exit_Statement_Node |
               Adac.AST.Loop_Statement_Node |
               Adac.AST.Procedure_Call_Statement_Node |
               Adac.AST.Return_Statement_Node |
               Adac.AST.If_Statement_Node =>
            null;

          when Adac.AST.Block_Statement_Node =>
            if has_handlers then
              declare
                nested_sequence : constant Adac.AST.Node_ID :=
                  Adac.AST.block_handled_sequence
                    (self.ast_store, statement);
              begin
                if Adac.AST.handled_sequence_handler_count
                  (self.ast_store, nested_sequence) /= 0
                then
                  raise Program_Error with
                    "Adac.Compilation.Syntax: handler-bearing block owns a " &
                    "handled block child";
                end if;
              end;
            end if;

          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid current block statement";
        end case;
      end;
    end loop;

    for index in 1 .. Adac.AST.handled_sequence_handler_count
      (self.ast_store, sequence)
    loop
      validate_exception_handler
        (self,
         Adac.AST.handled_sequence_handler_at
           (self.ast_store, sequence, index));
    end loop;
  end validate_current_block_handled_sequence;

  procedure validate_if_branch_child_for_construction
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    case Adac.AST.kind_of (self.ast_store, statement) is
      when Adac.AST.Null_Statement_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, statement));
      when Adac.AST.Exit_Statement_Node =>
        validate_exit_statement (self, statement);
      when Adac.AST.Return_Statement_Node =>
        validate_return_statement (self, statement);
      when Adac.AST.Raise_Statement_Node =>
        validate_raise_statement (self, statement);
      when Adac.AST.Assignment_Statement_Node =>
        validate_assignment_statement (self, statement);
      when Adac.AST.Procedure_Call_Statement_Node =>
        validate_procedure_call (self, statement);
      when Adac.AST.If_Statement_Node | Adac.AST.Loop_Statement_Node |
           Adac.AST.Case_Statement_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, statement));
      when Adac.AST.Block_Statement_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, statement));
      when others =>
        raise Program_Error with
          "Adac.Compilation.Syntax: invalid if branch statement";
    end case;
  end validate_if_branch_child_for_construction;

  function create_numeric_literal
    (self     : in out Context;
     form     : Adac.AST.Numeric_Literal_Kind;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_numeric_literal
      (self.ast_store,
       form,
       spelling,
       span,
       self.limits.maximum_ast_nodes);
  end create_numeric_literal;

  function create_character_literal
    (self     : in out Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_character_literal
      (self.ast_store,
       spelling,
       span,
       self.limits.maximum_ast_nodes);
  end create_character_literal;

  function create_string_literal
    (self     : in out Context;
     spelling : String;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_string_literal
      (self.ast_store,
       spelling,
       span,
       self.limits.maximum_ast_nodes);
  end create_string_literal;

  function create_null_literal
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_null_literal
      (self.ast_store, span, self.limits.maximum_ast_nodes);
  end create_null_literal;

  function create_record_aggregate
    (self         : in out Context;
     associations : Adac.AST.Record_Component_Association_List;
     span         : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    if Adac.AST.record_component_association_list_count (associations) = 0 then
      raise Program_Error with
        "Adac.Compilation.Syntax: record aggregate association list is empty";
    end if;

    for index in 1 .. Adac.AST.record_component_association_list_count
      (associations)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self,
         Adac.AST.record_component_association_list_selector_symbol
           (associations, index));
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.record_component_association_list_selector_span
           (associations, index));
      declare
        expression : constant Adac.AST.Node_ID :=
          Adac.AST.record_component_association_list_expression
            (associations, index);
      begin
        if Adac.AST.kind_of (self.ast_store, expression) =
           Adac.AST.Record_Aggregate_Node
        then
          Adac.Compilation.Sources.validate_span
            (self, Adac.AST.node_span (self.ast_store, expression));
        else
          Adac.AST.Validation.validate_nonaggregate_simple_expression_shape
            (self.ast_store, expression);
          validate_expression (self, expression);
        end if;
      end;
    end loop;

    return Adac.AST.Construction.append_record_aggregate
      (self.ast_store, associations, span, self.limits.maximum_ast_nodes);
  end create_record_aggregate;

  function create_array_aggregate
    (self         : in out Context;
     associations : Adac.AST.Array_Component_Association_List;
     span         : Adac.Source.Span)
  return Adac.AST.Node_ID is
    procedure validate_choices (association_index : Positive) is
    begin
      if Adac.AST.array_component_association_list_choice_count
        (associations, association_index) = 0
      then
        raise Program_Error with
          "Adac.Compilation.Syntax: array aggregate choice list is empty";
      end if;

      for choice_index in 1 ..
        Adac.AST.array_component_association_list_choice_count
          (associations, association_index)
      loop
        declare
          choice : constant Adac.AST.Node_ID :=
            Adac.AST.array_component_association_list_choice
              (associations, association_index, choice_index);
        begin
          Adac.AST.Validation.validate_nonaggregate_simple_expression_shape
            (self.ast_store, choice);
          validate_expression (self, choice);
        end;
      end loop;
    end validate_choices;
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    if Adac.AST.array_component_association_list_count (associations) = 0 then
      raise Program_Error with
        "Adac.Compilation.Syntax: array aggregate association list is empty";
    end if;

    for association_index in 1 ..
      Adac.AST.array_component_association_list_count (associations)
    loop
      validate_choices (association_index);
      declare
        expression : constant Adac.AST.Node_ID :=
          Adac.AST.array_component_association_list_expression
            (associations, association_index);
      begin
        Adac.AST.Validation.validate_nonaggregate_simple_expression_shape
          (self.ast_store, expression);
        validate_expression (self, expression);
      end;
    end loop;

    return Adac.AST.Construction.append_array_aggregate
      (self.ast_store, associations, span, self.limits.maximum_ast_nodes);
  end create_array_aggregate;

  function create_bracket_aggregate
    (self        : in out Context;
     expressions : Adac.AST.Node_List;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    if Adac.AST.list_count (expressions) = 0 then
      raise Program_Error with
        "Adac.Compilation.Syntax: bracket aggregate expression list is empty";
    end if;
    for index in 1 .. Adac.AST.list_count (expressions) loop
      validate_allocator (self, Adac.AST.list_element (expressions, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_bracket_aggregate
      (self.ast_store,
       expressions,
       span,
       self.limits.maximum_ast_nodes);
  end create_bracket_aggregate;

  function create_qualified_expression
    (self         : in out Context;
     subtype_mark : Adac.AST.Node_ID;
     operand      : Adac.AST.Node_ID;
     span         : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, subtype_mark);
    if Adac.AST.kind_of (self.ast_store, operand) =
       Adac.AST.Record_Aggregate_Node
    then
      validate_record_aggregate (self, operand);
    elsif Adac.AST.kind_of (self.ast_store, operand) =
       Adac.AST.Array_Aggregate_Node
    then
      validate_array_aggregate (self, operand);
    else
      validate_expression (self, operand);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_qualified_expression
      (self.ast_store,
       subtype_mark,
       operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_qualified_expression;

  function create_allocator
    (self       : in out Context;
     new_span   : Adac.Source.Span;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, new_span);
    validate_qualified_expression (self, expression);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_allocator
      (self.ast_store,
       new_span,
       expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_allocator;

  function create_if_expression
    (self            : in out Context;
     condition       : Adac.AST.Node_ID;
     then_expression : Adac.AST.Node_ID;
     else_expression : Adac.AST.Node_ID;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, condition);
    validate_expression (self, then_expression);
    validate_expression (self, else_expression);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_if_expression
      (self.ast_store,
       condition,
       then_expression,
       else_expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_if_expression;

  function create_case_expression_alternative
    (self       : in out Context;
     choices    : Adac.AST.Node_List;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    for index in 1 .. Adac.AST.list_count (choices) loop
      declare
        choice : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (choices, index);
      begin
        case Adac.AST.kind_of (self.ast_store, choice) is
          when Adac.AST.Identifier_Name_Node | Adac.AST.Selected_Name_Node =>
            validate_name (self, choice);
          when Adac.AST.Others_Case_Choice_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, choice));
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid case-expression choice";
        end case;
      end;
    end loop;
    validate_expression (self, expression);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_case_expression_alternative
      (self.ast_store,
       choices,
       expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_case_expression_alternative;

  function create_raise_expression
    (self           : in out Context;
     exception_name : Adac.AST.Node_ID;
     message        : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, exception_name);
    if message /= Adac.AST.INVALID_NODE_ID then
      validate_expression (self, message);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_raise_expression
      (self.ast_store,
       exception_name,
       message,
       span,
       self.limits.maximum_ast_nodes);
  end create_raise_expression;

  function create_case_expression
    (self                 : in out Context;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, selecting_expression);
    for index in 1 .. Adac.AST.list_count (alternatives) loop
      declare
        alternative : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (alternatives, index);
      begin
        if Adac.AST.kind_of (self.ast_store, alternative) /=
           Adac.AST.Case_Expression_Alternative_Node
        then
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid case-expression alternative";
        end if;
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, alternative));
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_case_expression
      (self.ast_store,
       selecting_expression,
       alternatives,
       span,
       self.limits.maximum_ast_nodes);
  end create_case_expression;

  function create_parenthesized_expression
    (self       : in out Context;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, expression));
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_parenthesized_expression
      (self.ast_store,
       expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_parenthesized_expression;

  function create_unary_operator
    (self              : in out Context;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     operand           : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, operator_span);
    validate_expression (self, operand);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_unary_operator
      (self.ast_store,
       operator_spelling,
       operator_span,
       operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_unary_operator;

  function create_binary_exponentiating
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, left_operand);
    Adac.Compilation.Sources.validate_span (self, operator_span);
    validate_expression (self, right_operand);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_binary_exponentiating
      (self.ast_store,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_binary_exponentiating;

  function create_binary_multiplying
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, left_operand);
    Adac.Compilation.Sources.validate_span (self, operator_span);
    validate_expression (self, right_operand);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_binary_multiplying
      (self.ast_store,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_binary_multiplying;

  function create_binary_adding
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, left_operand));
    Adac.Compilation.Sources.validate_span (self, operator_span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, right_operand));
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_binary_adding
      (self.ast_store,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_binary_adding;

  function create_relation
    (self              : in out Context;
     left_operand      : Adac.AST.Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Adac.AST.Node_ID;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, left_operand);
    validate_expression (self, right_operand);
    Adac.Compilation.Sources.validate_span (self, operator_span);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_relation
      (self.ast_store,
       left_operand,
       operator_spelling,
       operator_span,
       right_operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_relation;

  function create_membership_range_choice
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, lower_bound);
    Adac.Compilation.Sources.validate_span (self, range_span);
    validate_expression (self, upper_bound);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_membership_range_choice
      (self.ast_store,
       lower_bound,
       range_span,
       upper_bound,
       span,
       self.limits.maximum_ast_nodes);
  end create_membership_range_choice;

  function create_membership_expression
    (self          : in out Context;
     tested        : Adac.AST.Node_ID;
     operator_kind : Adac.AST.Membership_Operator_Kind;
     not_span      : Adac.Source.Span;
     in_span       : Adac.Source.Span;
     choices       : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, tested);
    if operator_kind = Adac.AST.Not_In_Membership_Operator then
      Adac.Compilation.Sources.validate_span (self, not_span);
    end if;
    Adac.Compilation.Sources.validate_span (self, in_span);
    for index in 1 .. Adac.AST.list_count (choices) loop
      declare
        choice : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (choices, index);
      begin
        if Adac.AST.kind_of (self.ast_store, choice) =
           Adac.AST.Membership_Range_Choice_Node
        then
          validate_membership_range_choice (self, choice);
        else
          validate_expression (self, choice);
        end if;
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_membership_expression
      (self.ast_store,
       tested,
       operator_kind,
       not_span,
       in_span,
       choices,
       span,
       self.limits.maximum_ast_nodes);
  end create_membership_expression;

  function create_logical_expression
    (self          : in out Context;
     left_operand  : Adac.AST.Node_ID;
     operator_kind : Adac.AST.Logical_Operator_Kind;
     operator_span : Adac.Source.Span;
     right_operand : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, left_operand);
    validate_expression (self, right_operand);
    Adac.Compilation.Sources.validate_span (self, operator_span);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_logical_expression
      (self.ast_store,
       left_operand,
       operator_kind,
       operator_span,
       right_operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_logical_expression;

  function create_short_circuit_expression
    (self                 : in out Context;
     left_operand         : Adac.AST.Node_ID;
     operator_kind        : Adac.AST.Short_Circuit_Operator_Kind;
     operator_first_span  : Adac.Source.Span;
     operator_second_span : Adac.Source.Span;
     right_operand        : Adac.AST.Node_ID;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, left_operand);
    validate_expression (self, right_operand);
    Adac.Compilation.Sources.validate_span (self, operator_first_span);
    Adac.Compilation.Sources.validate_span (self, operator_second_span);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_short_circuit_expression
      (self.ast_store,
       left_operand,
       operator_kind,
       operator_first_span,
       operator_second_span,
       right_operand,
       span,
       self.limits.maximum_ast_nodes);
  end create_short_circuit_expression;

  function create_identifier_name
    (self   : in out Context;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_identifier_name
      (self.ast_store,
       symbol,
       span,
       self.limits.maximum_ast_nodes);
  end create_identifier_name;

  function create_selected_name
    (self          : in out Context;
     prefix        : Adac.AST.Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, selector);
    Adac.Compilation.Sources.validate_span (self, selector_span);
    Adac.Compilation.Sources.validate_span (self, span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, prefix));
    return Adac.AST.Construction.append_selected_name
      (self.ast_store,
       prefix,
       selector,
       selector_span,
       span,
       self.limits.maximum_ast_nodes);
  end create_selected_name;

  function create_explicit_dereference_name
    (self     : in out Context;
     prefix   : Adac.AST.Node_ID;
     all_span : Adac.Source.Span;
     span     : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, prefix);
    Adac.Compilation.Sources.validate_span (self, all_span);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_explicit_dereference_name
      (self.ast_store,
       prefix,
       all_span,
       span,
       self.limits.maximum_ast_nodes);
  end create_explicit_dereference_name;

  function create_selected_component
    (self          : in out Context;
     prefix        : Adac.AST.Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, selector);
    Adac.Compilation.Sources.validate_span (self, selector_span);
    Adac.Compilation.Sources.validate_span (self, span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, prefix));
    return Adac.AST.Construction.append_selected_component
      (self.ast_store,
       prefix,
       selector,
       selector_span,
       span,
       self.limits.maximum_ast_nodes);
  end create_selected_component;

  function create_parenthesized_name
    (self   : in out Context;
     prefix : Adac.AST.Node_ID;
     items  : Adac.AST.Node_List;
     span   : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, prefix));

    for index in 1 .. Adac.AST.list_count (items) loop
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.node_span
           (self.ast_store, Adac.AST.list_element (items, index)));
    end loop;

    return Adac.AST.Construction.append_parenthesized_name
      (self.ast_store,
       prefix,
       items,
       span,
       self.limits.maximum_ast_nodes);
  end create_parenthesized_name;

  function create_parenthesized_name
    (self   : in out Context;
     prefix : Adac.AST.Node_ID;
     items  : Adac.AST.Parenthesized_Name_Item_List;
     span   : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, prefix));

    for index in 1 .. Adac.AST.parenthesized_name_item_list_count (items) loop
      if Adac.AST.parenthesized_name_item_list_form (items, index) =
         Adac.AST.Named_Parenthesized_Name_Item_Form
      then
        Adac.Compilation.Sources.validate_span
          (self,
           Adac.AST.node_span
             (self.ast_store,
              Adac.AST.parenthesized_name_item_list_selector (items, index)));
      end if;
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.node_span
           (self.ast_store,
            Adac.AST.parenthesized_name_item_list_actual (items, index)));
    end loop;

    return Adac.AST.Construction.append_parenthesized_name
      (self.ast_store,
       prefix,
       items,
       span,
       self.limits.maximum_ast_nodes);
  end create_parenthesized_name;

  function create_slice_name
    (self        : in out Context;
     prefix      : Adac.AST.Node_ID;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, prefix);
    validate_expression (self, lower_bound);
    Adac.Compilation.Sources.validate_span (self, range_span);
    validate_expression (self, upper_bound);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_slice_name
      (self.ast_store,
       prefix,
       lower_bound,
       range_span,
       upper_bound,
       span,
       self.limits.maximum_ast_nodes);
  end create_slice_name;

  function create_attribute_name
    (self            : in out Context;
     prefix          : Adac.AST.Node_ID;
     designator      : Adac.Symbols.Symbol_ID;
     designator_span : Adac.Source.Span;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, prefix);
    Adac.Compilation.Symbols.validate_symbol (self, designator);
    Adac.Compilation.Sources.validate_span (self, designator_span);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_attribute_name
      (self.ast_store,
       prefix,
       designator,
       designator_span,
       span,
       self.limits.maximum_ast_nodes);
  end create_attribute_name;

  function create_aspect_specification
    (self        : in out Context;
     mark_symbol : Adac.Symbols.Symbol_ID;
     mark_span   : Adac.Source.Span;
     definition  : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, mark_symbol);
    Adac.Compilation.Sources.validate_span (self, mark_span);
    validate_expression (self, definition);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_aspect_specification
      (self.ast_store,
       mark_symbol,
       mark_span,
       definition,
       span,
       self.limits.maximum_ast_nodes);
  end create_aspect_specification;

  function create_parameter_specification
    (self                 : in out Context;
     defining_identifiers : Adac.AST.Defining_Identifier_List;
     mode                 : Adac.AST.Parameter_Mode_Kind;
     subtype_mark         : Adac.AST.Node_ID;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    return create_parameter_specification
      (self,
       defining_identifiers,
       mode,
       subtype_mark,
       Adac.AST.INVALID_NODE_ID,
       span);
  end create_parameter_specification;

  function create_parameter_specification
    (self                 : in out Context;
     defining_identifiers : Adac.AST.Defining_Identifier_List;
     mode                 : Adac.AST.Parameter_Mode_Kind;
     subtype_mark         : Adac.AST.Node_ID;
     default_expression   : Adac.AST.Node_ID;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    if Adac.AST.defining_identifier_list_count (defining_identifiers) = 0 then
      raise Program_Error with
        "Adac.Compilation.Syntax: empty parameter defining identifier list";
    end if;
    for index in 1 ..
      Adac.AST.defining_identifier_list_count (defining_identifiers)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.defining_identifier_list_symbol
           (defining_identifiers, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.defining_identifier_list_span
           (defining_identifiers, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    validate_name (self, subtype_mark);
    if default_expression /= Adac.AST.INVALID_NODE_ID then
      validate_expression (self, default_expression);
    end if;
    return Adac.AST.Construction.append_parameter_specification
      (self.ast_store,
       defining_identifiers,
       mode,
       subtype_mark,
       default_expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_parameter_specification;

  function create_parameter_specification
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     mode          : Adac.AST.Parameter_Mode_Kind;
     subtype_mark  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    return create_parameter_specification
      (self,
       symbol,
       defining_span,
       mode,
       subtype_mark,
       Adac.AST.INVALID_NODE_ID,
       span);
  end create_parameter_specification;

  function create_parameter_specification
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Adac.AST.Parameter_Mode_Kind;
     subtype_mark       : Adac.AST.Node_ID;
     default_expression : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    validate_name (self, subtype_mark);
    if default_expression /= Adac.AST.INVALID_NODE_ID then
      validate_expression (self, default_expression);
    end if;
    return Adac.AST.Construction.append_parameter_specification
      (self.ast_store,
       symbol,
       defining_span,
       mode,
       subtype_mark,
       default_expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_parameter_specification;

  function create_object_declaration
    (self          : in out Context;
     form          : Adac.AST.Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, subtype_mark));
    if initializer /= Adac.AST.INVALID_NODE_ID then
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, initializer));
    end if;
    return Adac.AST.Construction.append_object_declaration
      (self.ast_store,
       form,
       symbol,
       defining_span,
       subtype_mark,
       initializer,
       span,
       self.limits.maximum_ast_nodes);
  end create_object_declaration;

  function create_constrained_object_declaration
    (self             : in out Context;
     form             : Adac.AST.Object_Declaration_Form;
     symbol           : Adac.Symbols.Symbol_ID;
     defining_span    : Adac.Source.Span;
     subtype_mark     : Adac.AST.Node_ID;
     index_constraint : Adac.AST.Node_ID;
     initializer      : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    validate_name (self, subtype_mark);
    validate_index_constraint (self, index_constraint);
    if initializer /= Adac.AST.INVALID_NODE_ID then
      validate_expression (self, initializer);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_constrained_object_declaration
      (self.ast_store,
       form,
       symbol,
       defining_span,
       subtype_mark,
       index_constraint,
       initializer,
       span,
       self.limits.maximum_ast_nodes);
  end create_constrained_object_declaration;

  function create_object_renaming_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     renamed_name  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    validate_name (self, subtype_mark);
    validate_name (self, renamed_name);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_object_renaming_declaration
      (self.ast_store,
       symbol,
       defining_span,
       subtype_mark,
       renamed_name,
       span,
       self.limits.maximum_ast_nodes);
  end create_object_renaming_declaration;

  function create_number_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, initializer));
    validate_expression (self, initializer);
    return Adac.AST.Construction.append_number_declaration
      (self.ast_store,
       symbol,
       defining_span,
       initializer,
       span,
       self.limits.maximum_ast_nodes);
  end create_number_declaration;

  function create_exception_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_exception_declaration
      (self.ast_store,
       symbol,
       defining_span,
       span,
       self.limits.maximum_ast_nodes);
  end create_exception_declaration;

  function create_procedure_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 .. Adac.AST.list_count (parameters) loop
      validate_parameter (self, Adac.AST.list_element (parameters, index));
    end loop;
    return Adac.AST.Construction.append_procedure_declaration
      (self.ast_store,
       symbol,
       defining_span,
       parameters,
       span,
       self.limits.maximum_ast_nodes);
  end create_procedure_declaration;

  function create_procedure_body_stub
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 .. Adac.AST.list_count (parameters) loop
      validate_parameter (self, Adac.AST.list_element (parameters, index));
    end loop;
    return Adac.AST.Construction.append_procedure_body_stub
      (self.ast_store,
       symbol,
       defining_span,
       parameters,
       span,
       self.limits.maximum_ast_nodes);
  end create_procedure_body_stub;

  function create_function_declaration
    (self           : in out Context;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Adac.AST.Node_List;
     result_subtype : Adac.AST.Node_ID;
     aspect         : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 .. Adac.AST.list_count (parameters) loop
      validate_parameter (self, Adac.AST.list_element (parameters, index));
    end loop;
    validate_name (self, result_subtype);
    if aspect /= Adac.AST.INVALID_NODE_ID then
      validate_aspect_specification (self, aspect);
    end if;
    return Adac.AST.Construction.append_function_declaration
      (self.ast_store,
       symbol,
       defining_span,
       parameters,
       result_subtype,
       aspect,
       span,
       self.limits.maximum_ast_nodes);
  end create_function_declaration;

  function create_function_declaration
    (self           : in out Context;
     symbol         : Adac.Symbols.Symbol_ID;
     defining_span  : Adac.Source.Span;
     parameters     : Adac.AST.Node_List;
     result_subtype : Adac.AST.Node_ID;
     expression     : Adac.AST.Node_ID;
     aspect         : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 .. Adac.AST.list_count (parameters) loop
      validate_parameter (self, Adac.AST.list_element (parameters, index));
    end loop;
    validate_name (self, result_subtype);
    validate_expression (self, expression);
    if aspect /= Adac.AST.INVALID_NODE_ID then
      validate_aspect_specification (self, aspect);
    end if;
    return Adac.AST.Construction.append_function_declaration
      (self.ast_store,
       symbol,
       defining_span,
       parameters,
       result_subtype,
       expression,
       aspect,
       span,
       self.limits.maximum_ast_nodes);
  end create_function_declaration;

  function create_private_type_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     discriminants : Adac.AST.Node_List;
     span          : Adac.Source.Span;
     limited_form  : Boolean := False)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    for index in 1 .. Adac.AST.list_count (discriminants) loop
      validate_discriminant_specification
        (self, Adac.AST.list_element (discriminants, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_private_type_declaration
      (self.ast_store,
       symbol,
       defining_span,
       discriminants,
       span,
       limited_form  => limited_form,
       maximum_nodes => self.limits.maximum_ast_nodes);
  end create_private_type_declaration;

  function create_derived_type_declaration
    (self                : in out Context;
     symbol              : Adac.Symbols.Symbol_ID;
     defining_span       : Adac.Source.Span;
     parent_subtype_mark : Adac.AST.Node_ID;
     span                : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    validate_name (self, parent_subtype_mark);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_derived_type_declaration
      (self.ast_store,
       symbol,
       defining_span,
       parent_subtype_mark,
       span,
       self.limits.maximum_ast_nodes);
  end create_derived_type_declaration;

  function create_range_constraint
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, lower_bound);
    validate_expression (self, upper_bound);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_range_constraint
      (self.ast_store,
       lower_bound,
       upper_bound,
       span,
       self.limits.maximum_ast_nodes);
  end create_range_constraint;

  function create_index_constraint
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, lower_bound);
    Adac.Compilation.Sources.validate_span (self, range_span);
    validate_expression (self, upper_bound);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_index_constraint
      (self.ast_store,
       lower_bound,
       range_span,
       upper_bound,
       span,
       self.limits.maximum_ast_nodes);
  end create_index_constraint;

  function create_subtype_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     constraint    : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    validate_name (self, subtype_mark);
    if constraint /= Adac.AST.INVALID_NODE_ID then
      validate_range_constraint (self, constraint);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_subtype_declaration
      (self.ast_store,
       symbol,
       defining_span,
       subtype_mark,
       constraint,
       span,
       self.limits.maximum_ast_nodes);
  end create_subtype_declaration;

  function create_enumeration_type_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     literals      : Adac.AST.Enumeration_Literal_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 .. Adac.AST.enumeration_literal_list_count (literals) loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.enumeration_literal_list_symbol (literals, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.enumeration_literal_list_span (literals, index));
    end loop;
    return Adac.AST.Construction.append_enumeration_type_declaration
      (self.ast_store,
       symbol,
       defining_span,
       literals,
       span,
       self.limits.maximum_ast_nodes);
  end create_enumeration_type_declaration;

  function create_discriminant_specification
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     subtype_mark       : Adac.AST.Node_ID;
     default_expression : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    validate_name (self, subtype_mark);
    if default_expression /= Adac.AST.INVALID_NODE_ID then
      validate_expression (self, default_expression);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_discriminant_specification
      (self.ast_store,
       symbol,
       defining_span,
       subtype_mark,
       default_expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_discriminant_specification;

  function create_record_component_declaration
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     aliased_form       : Boolean;
     subtype_mark       : Adac.AST.Node_ID;
     default_expression : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    validate_name (self, subtype_mark);
    if default_expression /= Adac.AST.INVALID_NODE_ID then
      validate_expression (self, default_expression);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_record_component_declaration
      (self.ast_store,
       symbol,
       defining_span,
       aliased_form,
       subtype_mark,
       default_expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_record_component_declaration;

  function create_record_variant
    (self                : in out Context;
     choices             : Adac.AST.Node_List;
     components          : Adac.AST.Node_List;
     null_component_list : Boolean;
     span                : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    for index in 1 .. Adac.AST.list_count (choices) loop
      declare
        choice : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (choices, index);
      begin
        validate_name (self, choice);
        if Adac.AST.kind_of (self.ast_store, choice) /=
           Adac.AST.Identifier_Name_Node
        then
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid record variant choice";
        end if;
      end;
    end loop;
    for index in 1 .. Adac.AST.list_count (components) loop
      validate_record_component_declaration
        (self, Adac.AST.list_element (components, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_record_variant
      (self.ast_store,
       choices,
       components,
       null_component_list,
       span,
       self.limits.maximum_ast_nodes);
  end create_record_variant;

  function create_record_variant_part
    (self              : in out Context;
     discriminant_name : Adac.AST.Node_ID;
     variants          : Adac.AST.Node_List;
     span              : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, discriminant_name);
    if Adac.AST.kind_of (self.ast_store, discriminant_name) /=
       Adac.AST.Identifier_Name_Node
    then
      raise Program_Error with
        "Adac.Compilation.Syntax: invalid variant-part discriminant";
    end if;
    for index in 1 .. Adac.AST.list_count (variants) loop
      validate_record_variant
        (self, Adac.AST.list_element (variants, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_record_variant_part
      (self.ast_store,
       discriminant_name,
       variants,
       span,
       self.limits.maximum_ast_nodes);
  end create_record_variant_part;

  function create_record_type_declaration
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     limited_form  : Boolean;
     discriminants : Adac.AST.Node_List;
     components    : Adac.AST.Node_List;
     variant_part  : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    for index in 1 .. Adac.AST.list_count (discriminants) loop
      validate_discriminant_specification
        (self, Adac.AST.list_element (discriminants, index));
    end loop;
    for index in 1 .. Adac.AST.list_count (components) loop
      validate_record_component_declaration
        (self, Adac.AST.list_element (components, index));
    end loop;
    if variant_part /= Adac.AST.INVALID_NODE_ID then
      validate_record_variant_part (self, variant_part);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_record_type_declaration
      (self.ast_store,
       symbol,
       defining_span,
       limited_form,
       discriminants,
       components,
       variant_part,
       span,
       self.limits.maximum_ast_nodes);
  end create_record_type_declaration;

  function create_access_object_type_declaration
    (self               : in out Context;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     modifier           : Adac.AST.General_Access_Modifier_Kind;
     designated_subtype : Adac.AST.Node_ID;
     span               : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    validate_name (self, designated_subtype);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_access_object_type_declaration
      (self.ast_store,
       symbol,
       defining_span,
       modifier,
       designated_subtype,
       span,
       self.limits.maximum_ast_nodes);
  end create_access_object_type_declaration;

  function create_others_exception_choice
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_others_exception_choice
      (self.ast_store, span, self.limits.maximum_ast_nodes);
  end create_others_exception_choice;

  function create_exception_handler
    (self                    : in out Context;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID;
     choice_parameter_span   : Adac.Source.Span;
     choices                 : Adac.AST.Node_List;
     statements              : Adac.AST.Node_List;
     span                    : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    if choice_parameter_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
      Adac.Compilation.Symbols.validate_symbol
        (self, choice_parameter_symbol);
      Adac.Compilation.Sources.validate_span (self, choice_parameter_span);
    end if;
    for index in 1 .. Adac.AST.list_count (choices) loop
      declare
        choice : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (choices, index);
      begin
        case Adac.AST.kind_of (self.ast_store, choice) is
          when Adac.AST.Others_Exception_Choice_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, choice));
          when Adac.AST.Identifier_Name_Node | Adac.AST.Selected_Name_Node =>
            validate_name (self, choice);
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid exception choice";
        end case;
      end;
    end loop;
    for index in 1 .. Adac.AST.list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (statements, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Null_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));

          when Adac.AST.Return_Statement_Node =>
            validate_return_statement (self, statement);
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.Raise_Statement_Node =>
            validate_raise_statement (self, statement);
          when Adac.AST.Block_Statement_Node =>
            Adac.AST.Validation.validate_exception_handler_block_statement
              (self.ast_store, statement);
            validate_block_statement (self, statement);
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid handler statement";
        end case;
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_exception_handler
      (self.ast_store,
       choice_parameter_symbol,
       choice_parameter_span,
       choices,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_exception_handler;

  function create_handled_sequence
    (self       : in out Context;
     statements : Adac.AST.Node_List;
     handlers   : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    for index in 1 .. Adac.AST.list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (statements, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Null_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));

          when Adac.AST.Exit_Statement_Node =>
            validate_exit_statement (self, statement);
          when Adac.AST.Return_Statement_Node =>
            validate_return_statement (self, statement);
          when Adac.AST.Extended_Return_Statement_Node =>
            validate_extended_return_statement (self, statement);
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Raise_Statement_Node =>
            validate_raise_statement (self, statement);
          when Adac.AST.Case_Statement_Node |
               Adac.AST.Block_Statement_Node |
               Adac.AST.Loop_Statement_Node |
               Adac.AST.If_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid handled statement " &
              Adac.AST.Node_Kind'image
                (Adac.AST.kind_of (self.ast_store, statement));
        end case;
      end;
    end loop;
    for index in 1 .. Adac.AST.list_count (handlers) loop
      validate_exception_handler
        (self, Adac.AST.list_element (handlers, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_handled_sequence
      (self.ast_store, statements, handlers, span,
       self.limits.maximum_ast_nodes);
  end create_handled_sequence;

  function create_elsif_part
    (self       : in out Context;
     condition  : Adac.AST.Node_ID;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, condition);
    for index in 1 .. Adac.AST.list_count (statements) loop
      validate_if_branch_child_for_construction
        (self, Adac.AST.list_element (statements, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_elsif_part
      (self.ast_store,
       condition,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_elsif_part;

  function create_if_statement
    (self            : in out Context;
     condition       : Adac.AST.Node_ID;
     then_statements : Adac.AST.Node_List;
     elsif_parts     : Adac.AST.Node_List;
     else_statements : Adac.AST.Node_List;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, condition);
    for index in 1 .. Adac.AST.list_count (then_statements) loop
      validate_if_branch_child_for_construction
        (self, Adac.AST.list_element (then_statements, index));
    end loop;
    for index in 1 .. Adac.AST.list_count (elsif_parts) loop
      declare
        part : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (elsif_parts, index);
      begin
        if Adac.AST.kind_of (self.ast_store, part) /= Adac.AST.Elsif_Part_Node
        then
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid elsif part";
        end if;
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, part));
      end;
    end loop;
    for index in 1 .. Adac.AST.list_count (else_statements) loop
      validate_if_branch_child_for_construction
        (self, Adac.AST.list_element (else_statements, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_if_statement
      (self.ast_store,
       condition,
       then_statements,
       elsif_parts,
       else_statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_if_statement;

  function create_assignment_statement
    (self       : in out Context;
     target     : Adac.AST.Node_ID;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, target);
    validate_expression (self, expression);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_assignment_statement
      (self.ast_store,
       target,
       expression,
       span,
       self.limits.maximum_ast_nodes);
  end create_assignment_statement;

  function create_case_range_choice
    (self        : in out Context;
     lower_bound : Adac.AST.Node_ID;
     range_span  : Adac.Source.Span;
     upper_bound : Adac.AST.Node_ID;
     span        : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_character_literal (self, lower_bound);
    Adac.Compilation.Sources.validate_span (self, range_span);
    validate_character_literal (self, upper_bound);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_case_range_choice
      (self.ast_store,
       lower_bound,
       range_span,
       upper_bound,
       span,
       self.limits.maximum_ast_nodes);
  end create_case_range_choice;

  function create_others_case_choice
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_others_case_choice
      (self.ast_store, span, self.limits.maximum_ast_nodes);
  end create_others_case_choice;

  function create_case_alternative
    (self       : in out Context;
     choices    : Adac.AST.Node_List;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    for index in 1 .. Adac.AST.list_count (choices) loop
      declare
        choice : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (choices, index);
      begin
        case Adac.AST.kind_of (self.ast_store, choice) is
          when Adac.AST.Identifier_Name_Node | Adac.AST.Selected_Name_Node =>
            validate_name (self, choice);
          when Adac.AST.Numeric_Literal_Node =>
            validate_numeric_literal (self, choice);
          when Adac.AST.Character_Literal_Node =>
            validate_character_literal (self, choice);
          when Adac.AST.Case_Range_Choice_Node =>
            validate_case_range_choice (self, choice);
          when Adac.AST.Others_Case_Choice_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, choice));
            if Adac.AST.list_count (choices) /= 1 then
              raise Program_Error with
                "Adac.Compilation.Syntax: others case choice is not sole";
            end if;
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid case choice";
        end case;
      end;
    end loop;
    for index in 1 .. Adac.AST.list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (statements, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Null_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));

          when Adac.AST.Exit_Statement_Node =>
            validate_exit_statement (self, statement);
          when Adac.AST.Return_Statement_Node =>
            validate_return_statement (self, statement);
          when Adac.AST.Raise_Statement_Node =>
            validate_raise_statement (self, statement);
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.If_Statement_Node |
               Adac.AST.Block_Statement_Node |
               Adac.AST.Loop_Statement_Node |
               Adac.AST.Case_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid case-alternative statement";
        end case;
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_case_alternative
      (self.ast_store,
       choices,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_case_alternative;

  function create_case_statement
    (self                 : in out Context;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, selecting_expression);
    for index in 1 .. Adac.AST.list_count (alternatives) loop
      declare
        alternative : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (alternatives, index);
      begin
        if Adac.AST.kind_of (self.ast_store, alternative) /=
           Adac.AST.Case_Alternative_Node
        then
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid case alternative";
        end if;
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, alternative));
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_case_statement
      (self.ast_store,
       selecting_expression,
       alternatives,
       span,
       self.limits.maximum_ast_nodes);
  end create_case_statement;

  function create_block_statement
    (self             : in out Context;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    for index in 1 .. Adac.AST.list_count (declarations) loop
      declare
        declaration : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (declarations, index);
      begin
        if Adac.AST.kind_of (self.ast_store, declaration) /=
             Adac.AST.Object_Declaration_Node and then
           Adac.AST.kind_of (self.ast_store, declaration) /=
             Adac.AST.Object_Renaming_Declaration_Node
        then
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid block declaration";
        end if;
        validate_declaration (self, declaration);
      end;
    end loop;
    validate_current_block_handled_sequence (self, handled_sequence);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_block_statement
      (self.ast_store,
       declarations,
       handled_sequence,
       span,
       self.limits.maximum_ast_nodes);
  end create_block_statement;

  function create_simple_loop_statement
    (self       : in out Context;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    for index in 1 .. Adac.AST.list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (statements, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Exit_Statement_Node =>
            validate_exit_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.Case_Statement_Node |
               Adac.AST.If_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
          when Adac.AST.Block_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
            declare
              sequence : constant Adac.AST.Node_ID :=
                Adac.AST.block_handled_sequence (self.ast_store, statement);
            begin
              if Adac.AST.handled_sequence_handler_count
                (self.ast_store, sequence) /= 0
              then
                raise Program_Error with
                  "Adac.Compilation.Syntax: simple-loop block has handlers";
              end if;
            end;
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid simple-loop statement";
        end case;
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_simple_loop_statement
      (self.ast_store,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_simple_loop_statement;

  function create_while_loop_statement
    (self       : in out Context;
     condition  : Adac.AST.Node_ID;
     statements : Adac.AST.Node_List;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_expression (self, condition);
    for index in 1 .. Adac.AST.list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (statements, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Exit_Statement_Node =>
            validate_exit_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.Case_Statement_Node |
               Adac.AST.If_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
          when Adac.AST.Block_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
            declare
              sequence : constant Adac.AST.Node_ID :=
                Adac.AST.block_handled_sequence (self.ast_store, statement);
            begin
              if Adac.AST.handled_sequence_handler_count
                (self.ast_store, sequence) /= 0
              then
                raise Program_Error with
                  "Adac.Compilation.Syntax: while-loop block has handlers";
              end if;
            end;
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid while-loop statement";
        end case;
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_while_loop_statement
      (self.ast_store,
       condition,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_while_loop_statement;

  function create_discrete_range_loop_statement
    (self             : in out Context;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     lower_bound      : Adac.AST.Node_ID;
     upper_bound      : Adac.AST.Node_ID;
     statements       : Adac.AST.Node_List;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, parameter_symbol);
    Adac.Compilation.Sources.validate_span (self, parameter_span);
    validate_expression (self, lower_bound);
    validate_expression (self, upper_bound);
    for index in 1 .. Adac.AST.list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (statements, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Exit_Statement_Node =>
            validate_exit_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.Case_Statement_Node |
               Adac.AST.If_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
          when Adac.AST.Block_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
            declare
              sequence : constant Adac.AST.Node_ID :=
                Adac.AST.block_handled_sequence (self.ast_store, statement);
            begin
              if Adac.AST.handled_sequence_handler_count
                (self.ast_store, sequence) /= 0
              then
                raise Program_Error with
                  "Adac.Compilation.Syntax: range-loop block has handlers";
              end if;
            end;
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid range-loop statement";
        end case;
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_discrete_range_loop_statement
      (self.ast_store,
       parameter_symbol,
       parameter_span,
       reverse_present,
       lower_bound,
       upper_bound,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_discrete_range_loop_statement;

  function create_range_attribute_loop_statement
    (self             : in out Context;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     range_attribute  : Adac.AST.Node_ID;
     statements       : Adac.AST.Node_List;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, parameter_symbol);
    Adac.Compilation.Sources.validate_span (self, parameter_span);
    validate_name (self, range_attribute);
    if Adac.AST.kind_of (self.ast_store, range_attribute) /=
         Adac.AST.Attribute_Name_Node or else
       Ada.Characters.Handling.To_Lower
         (Adac.Compilation.Symbols.spelling
            (self,
             Adac.AST.attribute_symbol
               (self.ast_store, range_attribute))) /= "range"
    then
      raise Program_Error with
        "Adac.Compilation.Syntax: range loop requires a Range attribute";
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_range_attribute_loop_statement
      (self.ast_store,
       parameter_symbol,
       parameter_span,
       reverse_present,
       range_attribute,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_range_attribute_loop_statement;

  function create_loop_statement
    (self             : in out Context;
     parameter_symbol : Adac.Symbols.Symbol_ID;
     parameter_span   : Adac.Source.Span;
     reverse_present  : Boolean;
     iterable_name    : Adac.AST.Node_ID;
     statements       : Adac.AST.Node_List;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, parameter_symbol);
    Adac.Compilation.Sources.validate_span (self, parameter_span);
    validate_name (self, iterable_name);
    for index in 1 .. Adac.AST.list_count (statements) loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (statements, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Exit_Statement_Node =>
            validate_exit_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.Case_Statement_Node |
               Adac.AST.If_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
          when Adac.AST.Block_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));
            declare
              sequence : constant Adac.AST.Node_ID :=
                Adac.AST.block_handled_sequence (self.ast_store, statement);
            begin
              if Adac.AST.handled_sequence_handler_count
                (self.ast_store, sequence) /= 0
              then
                raise Program_Error with
                  "Adac.Compilation.Syntax: iterator-loop block has handlers";
              end if;
            end;
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid iterator-loop statement";
        end case;
      end;
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_loop_statement
      (self.ast_store,
       parameter_symbol,
       parameter_span,
       reverse_present,
       iterable_name,
       statements,
       span,
       self.limits.maximum_ast_nodes);
  end create_loop_statement;

  function create_procedure_call_statement
    (self          : in out Context;
     callable_name : Adac.AST.Node_ID;
     actuals       : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, callable_name);

    for index in 1 .. Adac.AST.list_count (actuals) loop
      validate_expression (self, Adac.AST.list_element (actuals, index));
    end loop;

    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_procedure_call_statement
      (self.ast_store,
       callable_name,
       actuals,
       span,
       self.limits.maximum_ast_nodes);
  end create_procedure_call_statement;

  function create_procedure_call_statement
    (self          : in out Context;
     callable_name : Adac.AST.Node_ID;
     actuals       : Adac.AST.Procedure_Call_Actual_Association_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, callable_name);

    for index in 1 ..
      Adac.AST.procedure_call_actual_association_list_count (actuals)
    loop
      if Adac.AST.procedure_call_actual_association_list_form
           (actuals, index) = Adac.AST.Named_Procedure_Call_Actual_Form
      then
        validate_name
          (self,
           Adac.AST.procedure_call_actual_association_list_selector
             (actuals, index));
      end if;
      validate_expression
        (self,
         Adac.AST.procedure_call_actual_association_list_actual
           (actuals, index));
    end loop;

    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_procedure_call_statement
      (self.ast_store,
       callable_name,
       actuals,
       span,
       self.limits.maximum_ast_nodes);
  end create_procedure_call_statement;

  function create_extended_return_statement
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Adac.AST.Node_ID;
     sequence      : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);
    validate_name (self, subtype_mark);
    validate_handled_sequence (self, sequence);
    return Adac.AST.Construction.append_extended_return_statement
      (self.ast_store,
       symbol,
       defining_span,
       subtype_mark,
       sequence,
       span,
       self.limits.maximum_ast_nodes);
  end create_extended_return_statement;

  function create_exit_statement
    (self             : in out Context;
     loop_name_symbol : Adac.Symbols.Symbol_ID;
     loop_name_span   : Adac.Source.Span;
     when_span        : Adac.Source.Span;
     condition        : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    if loop_name_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
      Adac.Compilation.Symbols.validate_symbol (self, loop_name_symbol);
      Adac.Compilation.Sources.validate_span (self, loop_name_span);
    end if;
    if condition /= Adac.AST.INVALID_NODE_ID then
      Adac.Compilation.Sources.validate_span (self, when_span);
      validate_expression (self, condition);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_exit_statement
      (self.ast_store,
       loop_name_symbol,
       loop_name_span,
       when_span,
       condition,
       span,
       self.limits.maximum_ast_nodes);
  end create_exit_statement;

  function create_return_statement
    (self       : in out Context;
     expression : Adac.AST.Node_ID;
     span       : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    if expression /= Adac.AST.INVALID_NODE_ID then
      validate_expression (self, expression);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_return_statement
      (self.ast_store, expression, span, self.limits.maximum_ast_nodes);
  end create_return_statement;

  function create_bare_raise_statement
    (self : in out Context;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_bare_raise_statement
      (self.ast_store, span, self.limits.maximum_ast_nodes);
  end create_bare_raise_statement;

  function create_raise_statement
    (self           : in out Context;
     exception_name : Adac.AST.Node_ID;
     message        : Adac.AST.Node_ID;
     span           : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    validate_name (self, exception_name);
    validate_expression (self, message);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_raise_statement
      (self.ast_store,
       exception_name,
       message,
       span,
       self.limits.maximum_ast_nodes);
  end create_raise_statement;

  function create_statement
    (self : in out Context;
     kind : Adac.AST.Node_Kind;
     span : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_statement
      (self.ast_store,
       kind,
       span,
       self.limits.maximum_ast_nodes);
  end create_statement;

  function create_with_clause
    (self  : in out Context;
     names : Adac.AST.Node_List;
     span  : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);

    for index in 1 .. Adac.AST.list_count (names) loop
      validate_name (self, Adac.AST.list_element (names, index));
    end loop;

    return Adac.AST.Construction.append_with_clause
      (self.ast_store, names, span, self.limits.maximum_ast_nodes);
  end create_with_clause;

  function create_use_type_clause
    (self          : in out Context;
     subtype_marks : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 .. Adac.AST.list_count (subtype_marks) loop
      validate_name (self, Adac.AST.list_element (subtype_marks, index));
    end loop;
    return Adac.AST.Construction.append_use_type_clause
      (self.ast_store, subtype_marks, span, self.limits.maximum_ast_nodes);
  end create_use_type_clause;

  function create_use_package_clause
    (self          : in out Context;
     package_names : Adac.AST.Node_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    for index in 1 .. Adac.AST.list_count (package_names) loop
      validate_name (self, Adac.AST.list_element (package_names, index));
    end loop;
    Adac.Compilation.Sources.validate_span (self, span);
    return Adac.AST.Construction.append_use_package_clause
      (self.ast_store,
       package_names,
       span,
       self.limits.maximum_ast_nodes);
  end create_use_package_clause;

  function create_package_renaming_declaration
    (self            : in out Context;
     defining_name   : Adac.AST.Program_Unit_Name;
     renamed_package : Adac.AST.Node_ID;
     span            : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 ..
      Adac.AST.program_unit_name_component_count (defining_name)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.program_unit_name_component_symbol
          (defining_name, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.program_unit_name_component_span
          (defining_name, index));
    end loop;
    validate_name (self, renamed_package);
    return Adac.AST.Construction.append_package_renaming_declaration
      (self.ast_store,
       defining_name,
       renamed_package,
       span,
       self.limits.maximum_ast_nodes);
  end create_package_renaming_declaration;

  function create_package_instantiation
    (self          : in out Context;
     defining_name : Adac.AST.Program_Unit_Name;
     generic_name  : Adac.AST.Node_ID;
     actuals       : Adac.AST.Generic_Actual_Association_List;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);

    for index in 1 ..
      Adac.AST.program_unit_name_component_count (defining_name)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.program_unit_name_component_symbol
          (defining_name, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.program_unit_name_component_span
          (defining_name, index));
    end loop;

    validate_name (self, generic_name);

    for index in 1 .. Adac.AST.generic_actual_association_list_count (actuals)
    loop
      if Adac.AST.generic_actual_association_list_form (actuals, index) =
         Adac.AST.Named_Generic_Actual_Form
      then
        Adac.Compilation.Symbols.validate_symbol
          (self, Adac.AST.generic_actual_association_list_selector_symbol
            (actuals, index));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.generic_actual_association_list_selector_span
            (actuals, index));
      end if;
      declare
        actual : constant Adac.AST.Node_ID :=
          Adac.AST.generic_actual_association_list_actual (actuals, index);
      begin
        case Adac.AST.kind_of (self.ast_store, actual) is
          when Adac.AST.String_Literal_Node =>
            validate_string_literal (self, actual);
          when others =>
            validate_name (self, actual);
        end case;
      end;
    end loop;

    return Adac.AST.Construction.append_package_instantiation
      (self.ast_store,
       defining_name,
       generic_name,
       actuals,
       span,
       self.limits.maximum_ast_nodes);
  end create_package_instantiation;

  function create_package_declaration
    (self                 : in out Context;
     defining_name        : Adac.AST.Program_Unit_Name;
     visible_declarations : Adac.AST.Node_List;
     private_part_span    : Adac.Source.Span;
     private_declarations : Adac.AST.Node_List;
     end_name             : Adac.AST.Program_Unit_Name;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);

    for index in 1 ..
      Adac.AST.program_unit_name_component_count (defining_name)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.program_unit_name_component_symbol
          (defining_name, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.program_unit_name_component_span
          (defining_name, index));
    end loop;

    for index in 1 .. Adac.AST.list_count (visible_declarations) loop
      declare
        child : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (visible_declarations, index);
      begin
        if kind_of (self, child) = Adac.AST.Package_Declaration_Node then
          Adac.Compilation.Sources.validate_span
            (self, node_span (self, child));
        else
          validate_declaration (self, child);
        end if;
      end;
    end loop;

    if private_part_span /= Adac.Source.INVALID_SPAN then
      Adac.Compilation.Sources.validate_span (self, private_part_span);
    end if;

    for index in 1 .. Adac.AST.list_count (private_declarations) loop
      declare
        child : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (private_declarations, index);
      begin
        if kind_of (self, child) = Adac.AST.Package_Declaration_Node then
          Adac.Compilation.Sources.validate_span
            (self, node_span (self, child));
        else
          validate_declaration (self, child);
        end if;
      end;
    end loop;

    for index in 1 .. Adac.AST.program_unit_name_component_count (end_name) loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.program_unit_name_component_symbol (end_name, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.program_unit_name_component_span (end_name, index));
    end loop;

    return Adac.AST.Construction.append_package_declaration
      (self.ast_store,
       defining_name,
       visible_declarations,
       private_part_span,
       private_declarations,
       end_name,
       span,
       self.limits.maximum_ast_nodes);
  end create_package_declaration;

  function create_package_declaration
    (self                 : in out Context;
     defining_name        : Adac.AST.Program_Unit_Name;
     visible_declarations : Adac.AST.Node_List;
     end_name             : Adac.AST.Program_Unit_Name;
     span                 : Adac.Source.Span)
  return Adac.AST.Node_ID is
    private_declarations : Adac.AST.Node_List;
  begin
    return create_package_declaration
      (self,
       defining_name,
       visible_declarations,
       Adac.Source.INVALID_SPAN,
       private_declarations,
       end_name,
       span);
  end create_package_declaration;

  function create_package_body_stub
    (self          : in out Context;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, symbol);
    Adac.Compilation.Sources.validate_span (self, defining_span);
    Adac.Compilation.Sources.validate_span (self, span);

    return Adac.AST.Construction.append_package_body_stub
      (self.ast_store,
       symbol,
       defining_span,
       span,
       self.limits.maximum_ast_nodes);
  end create_package_body_stub;

  function create_package_body
    (self          : in out Context;
     defining_name : Adac.AST.Program_Unit_Name;
     declarations  : Adac.AST.Node_List;
     end_name      : Adac.AST.Program_Unit_Name;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);

    for index in 1 ..
      Adac.AST.program_unit_name_component_count (defining_name)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.program_unit_name_component_symbol
          (defining_name, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.program_unit_name_component_span
          (defining_name, index));
    end loop;

    for index in 1 .. Adac.AST.list_count (declarations) loop
      declare
        declaration : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (declarations, index);
      begin
        case kind_of (self, declaration) is
          when Adac.AST.Procedure_Body_Node =>
            validate_procedure_body (self, declaration);
          when Adac.AST.Function_Body_Node =>
            validate_function_body (self, declaration);
          when Adac.AST.Use_Type_Clause_Node =>
            validate_use_type_clause (self, declaration);

          when Adac.AST.Use_Package_Clause_Node =>
            validate_use_package_clause (self, declaration);
          when Adac.AST.Package_Body_Stub_Node =>
            validate_package_body_stub (self, declaration);
          when others =>
            validate_declaration (self, declaration);
        end case;
      end;
    end loop;

    for index in 1 .. Adac.AST.program_unit_name_component_count (end_name) loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.program_unit_name_component_symbol (end_name, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.program_unit_name_component_span (end_name, index));
    end loop;

    return Adac.AST.Construction.append_package_body
      (self.ast_store,
       defining_name,
       declarations,
       end_name,
       span,
       self.limits.maximum_ast_nodes);
  end create_package_body;

  function create_procedure_body
    (self             : in out Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Adac.AST.Node_List;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, procedure_symbol);
    if end_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
      Adac.Compilation.Symbols.validate_symbol (self, end_symbol);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);

    for index in 1 .. Adac.AST.list_count (parameters) loop
      validate_parameter (self, Adac.AST.list_element (parameters, index));
    end loop;
    for index in 1 .. Adac.AST.list_count (declarations) loop
      declare
        declaration : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (declarations, index);
      begin
        case Adac.AST.kind_of (self.ast_store, declaration) is
          when Adac.AST.Object_Declaration_Node |
               Adac.AST.Number_Declaration_Node |
               Adac.AST.Object_Renaming_Declaration_Node |
               Adac.AST.Procedure_Declaration_Node |
               Adac.AST.Function_Declaration_Node |
               Adac.AST.Enumeration_Type_Declaration_Node |
               Adac.AST.Record_Type_Declaration_Node |
               Adac.AST.Subtype_Declaration_Node |
               Adac.AST.Package_Instantiation_Node =>
            validate_declaration (self, declaration);
          when Adac.AST.Use_Type_Clause_Node =>
            validate_use_type_clause (self, declaration);
          when Adac.AST.Use_Package_Clause_Node =>
            validate_use_package_clause (self, declaration);
          when Adac.AST.Procedure_Body_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, declaration));
          when Adac.AST.Function_Body_Node =>
            for function_index in 1 ..
              function_body_declaration_count (self, declaration)
            loop
              declare
                function_declaration : constant Adac.AST.Node_ID :=
                  function_body_declaration_at
                    (self, declaration, function_index);
              begin
                case kind_of (self, function_declaration) is
                  when Adac.AST.Object_Declaration_Node =>
                    validate_declaration (self, function_declaration);

                  when Adac.AST.Procedure_Body_Node =>
                    for nested_index in 1 ..
                      Adac.AST.declaration_count
                        (self.ast_store, function_declaration)
                    loop
                      declare
                        nested : constant Adac.AST.Node_ID :=
                          Adac.AST.declaration_at
                            (self.ast_store,
                             function_declaration,
                             nested_index);
                      begin
                        case kind_of (self, nested) is
                          when Adac.AST.Procedure_Body_Node |
                               Adac.AST.Function_Body_Node =>
                            raise Program_Error with
                              "Adac.Compilation.Syntax: bounded " &
                              "procedure-owned function procedure contains " &
                              "a subprogram body";
                          when others =>
                            null;
                        end case;
                      end;
                    end loop;
                    validate_procedure_body (self, function_declaration);

                  when others =>
                    raise Program_Error with
                      "Adac.Compilation.Syntax: procedure-owned function has " &
                      "unsupported declarative item";
                end case;
              end;
            end loop;
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, declaration));
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid procedure declarative item";
        end case;
      end;
    end loop;
    validate_handled_sequence (self, handled_sequence);

    return Adac.AST.Construction.append_procedure_body
      (self.ast_store,
       procedure_symbol,
       parameters,
       declarations,
       handled_sequence,
       end_symbol,
       span,
       self.limits.maximum_ast_nodes);
  end create_procedure_body;

  function create_subunit
    (self             : in out Context;
     parent_unit_name : Adac.AST.Program_Unit_Name;
     proper_body      : Adac.AST.Node_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 ..
      Adac.AST.program_unit_name_component_count (parent_unit_name)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self,
         Adac.AST.program_unit_name_component_symbol (parent_unit_name, index));
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.program_unit_name_component_span (parent_unit_name, index));
    end loop;

    case kind_of (self, proper_body) is
      when Adac.AST.Procedure_Body_Node =>
        validate_procedure_body (self, proper_body);
      when Adac.AST.Function_Body_Node =>
        validate_function_body (self, proper_body);
      when Adac.AST.Package_Body_Node =>
        validate_package_body (self, proper_body);
      when others =>
        raise Program_Error with
          "Adac.Compilation.Syntax: invalid subunit proper body";
    end case;

    return Adac.AST.Construction.append_subunit
      (self.ast_store,
       parent_unit_name,
       proper_body,
       span,
       self.limits.maximum_ast_nodes);
  end create_subunit;

  function create_function_body
    (self             : in out Context;
     function_symbol  : Adac.Symbols.Symbol_ID;
     parameters       : Adac.AST.Node_List;
     result_subtype   : Adac.AST.Node_ID;
     declarations     : Adac.AST.Node_List;
     handled_sequence : Adac.AST.Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Symbols.validate_symbol (self, function_symbol);
    if end_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
      Adac.Compilation.Symbols.validate_symbol (self, end_symbol);
    end if;
    Adac.Compilation.Sources.validate_span (self, span);
    for index in 1 .. Adac.AST.list_count (parameters) loop
      validate_parameter (self, Adac.AST.list_element (parameters, index));
    end loop;
    validate_name (self, result_subtype);
    for index in 1 .. Adac.AST.list_count (declarations) loop
      declare
        declaration : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (declarations, index);
      begin
        case Adac.AST.kind_of (self.ast_store, declaration) is
          when Adac.AST.Procedure_Body_Node | Adac.AST.Function_Body_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, declaration));
          when others =>
            validate_declaration (self, declaration);
        end case;
      end;
    end loop;
    validate_handled_sequence (self, handled_sequence);
    return Adac.AST.Construction.append_function_body
      (self.ast_store,
       function_symbol,
       parameters,
       result_subtype,
       declarations,
       handled_sequence,
       end_symbol,
       span,
       self.limits.maximum_ast_nodes);
  end create_function_body;

  function create_compilation_unit
    (self          : in out Context;
     context_items : Adac.AST.Node_List;
     unit_item     : Adac.AST.Node_ID;
     span          : Adac.Source.Span)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    Adac.Compilation.Sources.validate_span (self, span);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, unit_item));

    for index in 1 .. Adac.AST.list_count (context_items) loop
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.node_span
           (self.ast_store, Adac.AST.list_element (context_items, index)));
    end loop;

    return Adac.AST.Construction.append_compilation_unit
      (self.ast_store,
       context_items,
       unit_item,
       span,
       self.limits.maximum_ast_nodes);
  end create_compilation_unit;

  function node_count (self : Context) return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.node_count (self.ast_store);
  end node_count;

  function kind_of
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.AST.Node_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.kind_of (self.ast_store, node);
  end kind_of;

  function node_span
    (self : Context;
     node : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.node_span (self.ast_store, node);
  end node_span;

  function exception_handler_has_choice_parameter
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_handler_has_choice_parameter
      (self.ast_store, handler);
  end exception_handler_has_choice_parameter;

  function exception_handler_choice_parameter_symbol
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_handler_choice_parameter_symbol
      (self.ast_store, handler);
  end exception_handler_choice_parameter_symbol;

  function exception_handler_choice_parameter_span
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_handler_choice_parameter_span
      (self.ast_store, handler);
  end exception_handler_choice_parameter_span;

  function exception_handler_choice_count
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_handler_choice_count
      (self.ast_store, handler);
  end exception_handler_choice_count;

  function exception_handler_choice_at
    (self    : Context;
     handler : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_handler_choice_at
      (self.ast_store, handler, index);
  end exception_handler_choice_at;

  function exception_handler_statement_count
    (self    : Context;
     handler : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_handler_statement_count
      (self.ast_store, handler);
  end exception_handler_statement_count;

  function exception_handler_statement_at
    (self    : Context;
     handler : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_handler_statement_at
      (self.ast_store, handler, index);
  end exception_handler_statement_at;

  function handled_sequence_statement_count
    (self     : Context;
     sequence : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.handled_sequence_statement_count
      (self.ast_store, sequence);
  end handled_sequence_statement_count;

  function handled_sequence_statement_at
    (self     : Context;
     sequence : Adac.AST.Node_ID;
     index    : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.handled_sequence_statement_at
      (self.ast_store, sequence, index);
  end handled_sequence_statement_at;

  function handled_sequence_handler_count
    (self     : Context;
     sequence : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.handled_sequence_handler_count
      (self.ast_store, sequence);
  end handled_sequence_handler_count;

  function handled_sequence_handler_at
    (self     : Context;
     sequence : Adac.AST.Node_ID;
     index    : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.handled_sequence_handler_at
      (self.ast_store, sequence, index);
  end handled_sequence_handler_at;

  function if_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_condition (self.ast_store, statement);
  end if_condition;

  function elsif_condition
    (self : Context;
     part : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.elsif_condition (self.ast_store, part);
  end elsif_condition;

  function elsif_statement_count
    (self : Context;
     part : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.elsif_statement_count (self.ast_store, part);
  end elsif_statement_count;

  function elsif_statement_at
    (self  : Context;
     part  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.elsif_statement_at (self.ast_store, part, index);
  end elsif_statement_at;

  function if_then_statement_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_then_statement_count (self.ast_store, statement);
  end if_then_statement_count;

  function if_then_statement_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_then_statement_at (self.ast_store, statement, index);
  end if_then_statement_at;

  function if_elsif_part_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_elsif_part_count (self.ast_store, statement);
  end if_elsif_part_count;

  function if_elsif_part_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_elsif_part_at (self.ast_store, statement, index);
  end if_elsif_part_at;

  function if_else_statement_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_else_statement_count (self.ast_store, statement);
  end if_else_statement_count;

  function if_else_statement_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_else_statement_at (self.ast_store, statement, index);
  end if_else_statement_at;

  function exit_has_loop_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exit_has_loop_name (self.ast_store, statement);
  end exit_has_loop_name;

  function exit_loop_name_symbol
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exit_loop_name_symbol (self.ast_store, statement);
  end exit_loop_name_symbol;

  function exit_loop_name_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exit_loop_name_span (self.ast_store, statement);
  end exit_loop_name_span;

  function exit_has_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exit_has_condition (self.ast_store, statement);
  end exit_has_condition;

  function exit_when_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exit_when_span (self.ast_store, statement);
  end exit_when_span;

  function exit_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exit_condition (self.ast_store, statement);
  end exit_condition;

  function return_has_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.return_has_expression (self.ast_store, statement);
  end return_has_expression;

  function return_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.return_expression (self.ast_store, statement);
  end return_expression;

  function extended_return_symbol
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.extended_return_symbol (self.ast_store, statement);
  end extended_return_symbol;

  function extended_return_defining_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.extended_return_defining_span
      (self.ast_store, statement);
  end extended_return_defining_span;

  function extended_return_subtype_mark
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.extended_return_subtype_mark (self.ast_store, statement);
  end extended_return_subtype_mark;

  function extended_return_handled_sequence
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.extended_return_handled_sequence
      (self.ast_store, statement);
  end extended_return_handled_sequence;

  function raise_form
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Raise_Statement_Form is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.raise_form (self.ast_store, statement);
  end raise_form;

  function raise_exception_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.raise_exception_name (self.ast_store, statement);
  end raise_exception_name;

  function raise_message_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.raise_message_expression (self.ast_store, statement);
  end raise_message_expression;

  function assignment_target
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.assignment_target (self.ast_store, statement);
  end assignment_target;

  function assignment_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.assignment_expression (self.ast_store, statement);
  end assignment_expression;

  function case_alternative_choice_count
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_alternative_choice_count
      (self.ast_store, alternative);
  end case_alternative_choice_count;

  function case_alternative_choice_at
    (self        : Context;
     alternative : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_alternative_choice_at
      (self.ast_store, alternative, index);
  end case_alternative_choice_at;

  function case_range_choice_lower_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_range_choice_lower_bound (self.ast_store, choice);
  end case_range_choice_lower_bound;

  function case_range_choice_range_span
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_range_choice_range_span (self.ast_store, choice);
  end case_range_choice_range_span;

  function case_range_choice_upper_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_range_choice_upper_bound (self.ast_store, choice);
  end case_range_choice_upper_bound;

  function case_alternative_statement_count
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_alternative_statement_count
      (self.ast_store, alternative);
  end case_alternative_statement_count;

  function case_alternative_statement_at
    (self        : Context;
     alternative : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_alternative_statement_at
      (self.ast_store, alternative, index);
  end case_alternative_statement_at;

  function case_selecting_expression
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_selecting_expression (self.ast_store, statement);
  end case_selecting_expression;

  function case_alternative_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_alternative_count (self.ast_store, statement);
  end case_alternative_count;

  function case_alternative_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_alternative_at (self.ast_store, statement, index);
  end case_alternative_at;

  function block_declaration_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.block_declaration_count (self.ast_store, statement);
  end block_declaration_count;

  function block_declaration_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.block_declaration_at
      (self.ast_store, statement, index);
  end block_declaration_at;

  function block_handled_sequence
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.block_handled_sequence (self.ast_store, statement);
  end block_handled_sequence;

  function loop_form
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Loop_Statement_Form is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_form (self.ast_store, statement);
  end loop_form;

  function loop_condition
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_condition (self.ast_store, statement);
  end loop_condition;

  function loop_parameter_symbol
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_parameter_symbol (self.ast_store, statement);
  end loop_parameter_symbol;

  function loop_parameter_span
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_parameter_span (self.ast_store, statement);
  end loop_parameter_span;

  function loop_is_reverse
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_is_reverse (self.ast_store, statement);
  end loop_is_reverse;

  function loop_iterable_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_iterable_name (self.ast_store, statement);
  end loop_iterable_name;

  function loop_range_attribute
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_range_attribute (self.ast_store, statement);
  end loop_range_attribute;

  function loop_range_lower_bound
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_range_lower_bound (self.ast_store, statement);
  end loop_range_lower_bound;

  function loop_range_upper_bound
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_range_upper_bound (self.ast_store, statement);
  end loop_range_upper_bound;

  function loop_statement_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_statement_count (self.ast_store, statement);
  end loop_statement_count;

  function loop_statement_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.loop_statement_at (self.ast_store, statement, index);
  end loop_statement_at;

  function procedure_call_callable_name
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_call_callable_name
      (self.ast_store, statement);
  end procedure_call_callable_name;

  function procedure_call_actual_count
    (self      : Context;
     statement : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_call_actual_count
      (self.ast_store, statement);
  end procedure_call_actual_count;

  function procedure_call_actual_form
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Procedure_Call_Actual_Association_Form is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_call_actual_form
      (self.ast_store, statement, index);
  end procedure_call_actual_form;

  function procedure_call_actual_selector_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_call_actual_selector_at
      (self.ast_store, statement, index);
  end procedure_call_actual_selector_at;

  function procedure_call_actual_at
    (self      : Context;
     statement : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_call_actual_at
      (self.ast_store, statement, index);
  end procedure_call_actual_at;

  function numeric_literal_form
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return Adac.AST.Numeric_Literal_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.numeric_literal_form (self.ast_store, literal);
  end numeric_literal_form;

  function numeric_literal_spelling
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.numeric_literal_spelling (self.ast_store, literal);
  end numeric_literal_spelling;

  function character_literal_spelling
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.character_literal_spelling (self.ast_store, literal);
  end character_literal_spelling;

  function string_literal_spelling
    (self    : Context;
     literal : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.string_literal_spelling (self.ast_store, literal);
  end string_literal_spelling;

  function record_aggregate_association_count
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_aggregate_association_count
      (self.ast_store, aggregate);
  end record_aggregate_association_count;

  function record_aggregate_selector_symbol_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_aggregate_selector_symbol_at
      (self.ast_store, aggregate, index);
  end record_aggregate_selector_symbol_at;

  function record_aggregate_selector_span_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_aggregate_selector_span_at
      (self.ast_store, aggregate, index);
  end record_aggregate_selector_span_at;

  function record_aggregate_expression_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_aggregate_expression_at
      (self.ast_store, aggregate, index);
  end record_aggregate_expression_at;

  function array_aggregate_association_count
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.array_aggregate_association_count
      (self.ast_store, aggregate);
  end array_aggregate_association_count;

  function array_aggregate_choice_count
    (self              : Context;
     aggregate         : Adac.AST.Node_ID;
     association_index : Positive)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.array_aggregate_choice_count
      (self.ast_store, aggregate, association_index);
  end array_aggregate_choice_count;

  function array_aggregate_choice_at
    (self              : Context;
     aggregate         : Adac.AST.Node_ID;
     association_index : Positive;
     choice_index      : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.array_aggregate_choice_at
      (self.ast_store, aggregate, association_index, choice_index);
  end array_aggregate_choice_at;

  function array_aggregate_expression_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.array_aggregate_expression_at
      (self.ast_store, aggregate, index);
  end array_aggregate_expression_at;

  function bracket_aggregate_expression_count
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.bracket_aggregate_expression_count
      (self.ast_store, aggregate);
  end bracket_aggregate_expression_count;

  function bracket_aggregate_expression_at
    (self      : Context;
     aggregate : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.bracket_aggregate_expression_at
      (self.ast_store, aggregate, index);
  end bracket_aggregate_expression_at;

  function qualified_expression_subtype_mark
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.qualified_expression_subtype_mark
      (self.ast_store, expression);
  end qualified_expression_subtype_mark;

  function qualified_expression_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.qualified_expression_operand
      (self.ast_store, expression);
  end qualified_expression_operand;

  function if_expression_condition
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_expression_condition (self.ast_store, expression);
  end if_expression_condition;

  function if_expression_then_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_expression_then_expression
      (self.ast_store, expression);
  end if_expression_then_expression;

  function if_expression_else_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.if_expression_else_expression
      (self.ast_store, expression);
  end if_expression_else_expression;

  function case_expression_selecting_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_expression_selecting_expression
      (self.ast_store, expression);
  end case_expression_selecting_expression;

  function case_expression_alternative_count
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_expression_alternative_count
      (self.ast_store, expression);
  end case_expression_alternative_count;

  function case_expression_alternative_at
    (self       : Context;
     expression : Adac.AST.Node_ID;
     index      : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_expression_alternative_at
      (self.ast_store, expression, index);
  end case_expression_alternative_at;

  function case_expression_alternative_choice_count
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_expression_alternative_choice_count
      (self.ast_store, alternative);
  end case_expression_alternative_choice_count;

  function case_expression_alternative_choice_at
    (self        : Context;
     alternative : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_expression_alternative_choice_at
      (self.ast_store, alternative, index);
  end case_expression_alternative_choice_at;

  function case_expression_alternative_expression
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.case_expression_alternative_expression
      (self.ast_store, alternative);
  end case_expression_alternative_expression;

  function allocator_new_span
    (self      : Context;
     allocator : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.allocator_new_span (self.ast_store, allocator);
  end allocator_new_span;

  function allocator_expression
    (self      : Context;
     allocator : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.allocator_expression (self.ast_store, allocator);
  end allocator_expression;

  function raise_expression_exception_name
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.raise_expression_exception_name
      (self.ast_store, expression);
  end raise_expression_exception_name;

  function raise_expression_has_message
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.raise_expression_has_message
      (self.ast_store, expression);
  end raise_expression_has_message;

  function raise_expression_message
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.raise_expression_message
      (self.ast_store, expression);
  end raise_expression_message;

  function parenthesized_expression_child
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parenthesized_expression_child
      (self.ast_store, expression);
  end parenthesized_expression_child;

  function unary_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.unary_operator_spelling (self.ast_store, expression);
  end unary_operator_spelling;

  function unary_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.unary_operator_span (self.ast_store, expression);
  end unary_operator_span;

  function unary_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.unary_operand (self.ast_store, expression);
  end unary_operand;

  function binary_exponentiating_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_exponentiating_operator_spelling
      (self.ast_store, expression);
  end binary_exponentiating_operator_spelling;

  function binary_exponentiating_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
    result : Adac.Source.Span;
  begin
    Adac.Compilation.validate (self);
    result := Adac.AST.binary_exponentiating_operator_span
      (self.ast_store, expression);
    Adac.Compilation.Sources.validate_span (self, result);
    return result;
  end binary_exponentiating_operator_span;

  function binary_exponentiating_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_exponentiating_left_operand
      (self.ast_store, expression);
  end binary_exponentiating_left_operand;

  function binary_exponentiating_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_exponentiating_right_operand
      (self.ast_store, expression);
  end binary_exponentiating_right_operand;

  function binary_multiplying_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_multiplying_operator_spelling
      (self.ast_store, expression);
  end binary_multiplying_operator_spelling;

  function binary_multiplying_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_multiplying_operator_span
      (self.ast_store, expression);
  end binary_multiplying_operator_span;

  function binary_multiplying_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_multiplying_left_operand
      (self.ast_store, expression);
  end binary_multiplying_left_operand;

  function binary_multiplying_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_multiplying_right_operand
      (self.ast_store, expression);
  end binary_multiplying_right_operand;

  function binary_adding_operator_spelling
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_adding_operator_spelling
      (self.ast_store, expression);
  end binary_adding_operator_spelling;

  function binary_adding_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_adding_operator_span (self.ast_store, expression);
  end binary_adding_operator_span;

  function binary_adding_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_adding_left_operand (self.ast_store, expression);
  end binary_adding_left_operand;

  function binary_adding_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.binary_adding_right_operand (self.ast_store, expression);
  end binary_adding_right_operand;

  function relation_operator_spelling
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return String is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.relation_operator_spelling (self.ast_store, relation);
  end relation_operator_spelling;

  function relation_operator_span
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.relation_operator_span (self.ast_store, relation);
  end relation_operator_span;

  function relation_left_operand
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.relation_left_operand (self.ast_store, relation);
  end relation_left_operand;

  function relation_right_operand
    (self     : Context;
     relation : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.relation_right_operand (self.ast_store, relation);
  end relation_right_operand;

  function membership_range_choice_lower_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_range_choice_lower_bound
      (self.ast_store, choice);
  end membership_range_choice_lower_bound;

  function membership_range_choice_range_span
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_range_choice_range_span
      (self.ast_store, choice);
  end membership_range_choice_range_span;

  function membership_range_choice_upper_bound
    (self   : Context;
     choice : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_range_choice_upper_bound
      (self.ast_store, choice);
  end membership_range_choice_upper_bound;

  function membership_tested_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_tested_expression (self.ast_store, expression);
  end membership_tested_expression;

  function membership_operator
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Membership_Operator_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_operator (self.ast_store, expression);
  end membership_operator;

  function membership_not_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_not_span (self.ast_store, expression);
  end membership_not_span;

  function membership_in_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_in_span (self.ast_store, expression);
  end membership_in_span;

  function membership_choice_count
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_choice_count (self.ast_store, expression);
  end membership_choice_count;

  function membership_choice_at
    (self       : Context;
     expression : Adac.AST.Node_ID;
     index      : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.membership_choice_at (self.ast_store, expression, index);
  end membership_choice_at;

  function logical_operator
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Logical_Operator_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.logical_operator (self.ast_store, expression);
  end logical_operator;

  function logical_operator_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.logical_operator_span (self.ast_store, expression);
  end logical_operator_span;

  function logical_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.logical_left_operand (self.ast_store, expression);
  end logical_left_operand;

  function logical_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.logical_right_operand (self.ast_store, expression);
  end logical_right_operand;

  function short_circuit_operator
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Short_Circuit_Operator_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.short_circuit_operator (self.ast_store, expression);
  end short_circuit_operator;

  function short_circuit_operator_first_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.short_circuit_operator_first_span
      (self.ast_store, expression);
  end short_circuit_operator_first_span;

  function short_circuit_operator_second_span
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.short_circuit_operator_second_span
      (self.ast_store, expression);
  end short_circuit_operator_second_span;

  function short_circuit_left_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.short_circuit_left_operand (self.ast_store, expression);
  end short_circuit_left_operand;

  function short_circuit_right_operand
    (self       : Context;
     expression : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.short_circuit_right_operand (self.ast_store, expression);
  end short_circuit_right_operand;

  function identifier_symbol
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.identifier_symbol (self.ast_store, name);
  end identifier_symbol;

  function name_prefix
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.name_prefix (self.ast_store, name);
  end name_prefix;

  function explicit_dereference_all_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.explicit_dereference_all_span (self.ast_store, name);
  end explicit_dereference_all_span;

  function selector_symbol
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.selector_symbol (self.ast_store, name);
  end selector_symbol;

  function selector_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.selector_span (self.ast_store, name);
  end selector_span;

  function parenthesized_item_count
    (self : Context;
     name : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parenthesized_item_count (self.ast_store, name);
  end parenthesized_item_count;

  function parenthesized_item_at
    (self  : Context;
     name  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parenthesized_item_at
      (self.ast_store, name, index);
  end parenthesized_item_at;

  function parenthesized_item_form
    (self  : Context;
     name  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Parenthesized_Name_Item_Form is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parenthesized_item_form (self.ast_store, name, index);
  end parenthesized_item_form;

  function parenthesized_item_selector
    (self  : Context;
     name  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parenthesized_item_selector
      (self.ast_store, name, index);
  end parenthesized_item_selector;

  function slice_lower_bound
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.slice_lower_bound (self.ast_store, name);
  end slice_lower_bound;

  function slice_range_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.slice_range_span (self.ast_store, name);
  end slice_range_span;

  function slice_upper_bound
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.slice_upper_bound (self.ast_store, name);
  end slice_upper_bound;

  function attribute_symbol
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.attribute_symbol (self.ast_store, name);
  end attribute_symbol;

  function attribute_span
    (self : Context;
     name : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.attribute_span (self.ast_store, name);
  end attribute_span;

  function aspect_mark_symbol
    (self   : Context;
     aspect : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.aspect_mark_symbol (self.ast_store, aspect);
  end aspect_mark_symbol;

  function aspect_mark_span
    (self   : Context;
     aspect : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.aspect_mark_span (self.ast_store, aspect);
  end aspect_mark_span;

  function aspect_definition
    (self   : Context;
     aspect : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.aspect_definition (self.ast_store, aspect);
  end aspect_definition;

  function parameter_defining_identifier_count
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_defining_identifier_count
      (self.ast_store, parameter);
  end parameter_defining_identifier_count;

  function parameter_defining_symbol_at
    (self      : Context;
     parameter : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_defining_symbol_at
      (self.ast_store, parameter, index);
  end parameter_defining_symbol_at;

  function parameter_defining_span_at
    (self      : Context;
     parameter : Adac.AST.Node_ID;
     index     : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_defining_span_at
      (self.ast_store, parameter, index);
  end parameter_defining_span_at;

  function parameter_symbol
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_symbol (self.ast_store, parameter);
  end parameter_symbol;

  function parameter_defining_span
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_defining_span (self.ast_store, parameter);
  end parameter_defining_span;

  function parameter_mode
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.AST.Parameter_Mode_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_mode (self.ast_store, parameter);
  end parameter_mode;

  function parameter_subtype_mark
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_subtype_mark (self.ast_store, parameter);
  end parameter_subtype_mark;

  function parameter_default_expression
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_default_expression (self.ast_store, parameter);
  end parameter_default_expression;

  function object_form
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Object_Declaration_Form is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_form (self.ast_store, declaration);
  end object_form;

  function object_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_symbol (self.ast_store, declaration);
  end object_symbol;

  function object_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_defining_span (self.ast_store, declaration);
  end object_defining_span;

  function object_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_subtype_mark (self.ast_store, declaration);
  end object_subtype_mark;

  function object_has_index_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_has_index_constraint
      (self.ast_store, declaration);
  end object_has_index_constraint;

  function object_index_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_index_constraint (self.ast_store, declaration);
  end object_index_constraint;

  function object_has_initializer
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_has_initializer (self.ast_store, declaration);
  end object_has_initializer;

  function object_initializer
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_initializer (self.ast_store, declaration);
  end object_initializer;

  function object_renaming_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_renaming_symbol (self.ast_store, declaration);
  end object_renaming_symbol;

  function object_renaming_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_renaming_defining_span
      (self.ast_store, declaration);
  end object_renaming_defining_span;

  function object_renaming_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_renaming_subtype_mark
      (self.ast_store, declaration);
  end object_renaming_subtype_mark;

  function object_renaming_name
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.object_renaming_name (self.ast_store, declaration);
  end object_renaming_name;

  function number_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.number_symbol (self.ast_store, declaration);
  end number_symbol;

  function number_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.number_defining_span (self.ast_store, declaration);
  end number_defining_span;

  function number_initializer
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.number_initializer (self.ast_store, declaration);
  end number_initializer;

  function exception_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_declaration_symbol
      (self.ast_store, declaration);
  end exception_declaration_symbol;

  function exception_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.exception_declaration_defining_span
      (self.ast_store, declaration);
  end exception_declaration_defining_span;

  function procedure_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_declaration_symbol
      (self.ast_store, declaration);
  end procedure_declaration_symbol;

  function procedure_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_declaration_defining_span
      (self.ast_store, declaration);
  end procedure_declaration_defining_span;

  function procedure_declaration_parameter_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_declaration_parameter_count
      (self.ast_store, declaration);
  end procedure_declaration_parameter_count;

  function procedure_declaration_parameter_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_declaration_parameter_at
      (self.ast_store, declaration, index);
  end procedure_declaration_parameter_at;

  function procedure_body_stub_symbol
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_body_stub_symbol (self.ast_store, stub);
  end procedure_body_stub_symbol;

  function procedure_body_stub_defining_span
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_body_stub_defining_span (self.ast_store, stub);
  end procedure_body_stub_defining_span;

  function procedure_body_stub_parameter_count
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_body_stub_parameter_count (self.ast_store, stub);
  end procedure_body_stub_parameter_count;

  function procedure_body_stub_parameter_at
    (self  : Context;
     stub  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_body_stub_parameter_at
      (self.ast_store, stub, index);
  end procedure_body_stub_parameter_at;

  function function_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_symbol
      (self.ast_store, declaration);
  end function_declaration_symbol;

  function function_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_defining_span
      (self.ast_store, declaration);
  end function_declaration_defining_span;

  function function_declaration_parameter_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_parameter_count
      (self.ast_store, declaration);
  end function_declaration_parameter_count;

  function function_declaration_parameter_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_parameter_at
      (self.ast_store, declaration, index);
  end function_declaration_parameter_at;

  function function_declaration_result_subtype
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_result_subtype
      (self.ast_store, declaration);
  end function_declaration_result_subtype;

  function function_declaration_has_expression
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_has_expression
      (self.ast_store, declaration);
  end function_declaration_has_expression;

  function function_declaration_expression
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_expression
      (self.ast_store, declaration);
  end function_declaration_expression;

  function function_declaration_has_aspect
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_has_aspect
      (self.ast_store, declaration);
  end function_declaration_has_aspect;

  function function_declaration_aspect
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_declaration_aspect
      (self.ast_store, declaration);
  end function_declaration_aspect;

  function private_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.private_type_symbol (self.ast_store, declaration);
  end private_type_symbol;

  function private_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.private_type_defining_span (self.ast_store, declaration);
  end private_type_defining_span;

  function private_type_is_limited
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.private_type_is_limited (self.ast_store, declaration);
  end private_type_is_limited;

  function private_type_discriminant_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.private_type_discriminant_count
      (self.ast_store, declaration);
  end private_type_discriminant_count;

  function private_type_discriminant_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.private_type_discriminant_at
      (self.ast_store, declaration, index);
  end private_type_discriminant_at;

  function derived_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.derived_type_symbol (self.ast_store, declaration);
  end derived_type_symbol;

  function derived_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.derived_type_defining_span (self.ast_store, declaration);
  end derived_type_defining_span;

  function derived_type_parent_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.derived_type_parent_subtype_mark
      (self.ast_store, declaration);
  end derived_type_parent_subtype_mark;

  function range_constraint_lower_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.range_constraint_lower_bound
      (self.ast_store, constraint);
  end range_constraint_lower_bound;

  function range_constraint_upper_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.range_constraint_upper_bound
      (self.ast_store, constraint);
  end range_constraint_upper_bound;

  function index_constraint_lower_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.index_constraint_lower_bound
      (self.ast_store, constraint);
  end index_constraint_lower_bound;

  function index_constraint_range_span
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.index_constraint_range_span
      (self.ast_store, constraint);
  end index_constraint_range_span;

  function index_constraint_upper_bound
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.index_constraint_upper_bound
      (self.ast_store, constraint);
  end index_constraint_upper_bound;

  function subtype_declaration_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subtype_declaration_symbol
      (self.ast_store, declaration);
  end subtype_declaration_symbol;

  function subtype_declaration_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subtype_declaration_defining_span
      (self.ast_store, declaration);
  end subtype_declaration_defining_span;

  function subtype_declaration_subtype_mark
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subtype_declaration_subtype_mark
      (self.ast_store, declaration);
  end subtype_declaration_subtype_mark;

  function subtype_declaration_has_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subtype_declaration_has_constraint
      (self.ast_store, declaration);
  end subtype_declaration_has_constraint;

  function subtype_declaration_constraint
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subtype_declaration_constraint
      (self.ast_store, declaration);
  end subtype_declaration_constraint;

  function enumeration_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.enumeration_type_symbol (self.ast_store, declaration);
  end enumeration_type_symbol;

  function enumeration_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.enumeration_type_defining_span
      (self.ast_store, declaration);
  end enumeration_type_defining_span;

  function enumeration_literal_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.enumeration_literal_count (self.ast_store, declaration);
  end enumeration_literal_count;

  function enumeration_literal_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.enumeration_literal_symbol_at
      (self.ast_store, declaration, index);
  end enumeration_literal_symbol_at;

  function enumeration_literal_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.enumeration_literal_span_at
      (self.ast_store, declaration, index);
  end enumeration_literal_span_at;

  function discriminant_symbol
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.discriminant_symbol (self.ast_store, discriminant);
  end discriminant_symbol;

  function discriminant_defining_span
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.discriminant_defining_span
      (self.ast_store, discriminant);
  end discriminant_defining_span;

  function discriminant_subtype_mark
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.discriminant_subtype_mark
      (self.ast_store, discriminant);
  end discriminant_subtype_mark;

  function discriminant_has_default_expression
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.discriminant_has_default_expression
      (self.ast_store, discriminant);
  end discriminant_has_default_expression;

  function discriminant_default_expression
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.discriminant_default_expression
      (self.ast_store, discriminant);
  end discriminant_default_expression;

  function record_component_symbol
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_symbol (self.ast_store, component);
  end record_component_symbol;

  function record_component_defining_span
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_defining_span
      (self.ast_store, component);
  end record_component_defining_span;

  function record_component_is_aliased
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_is_aliased (self.ast_store, component);
  end record_component_is_aliased;

  function record_component_subtype_mark
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_subtype_mark
      (self.ast_store, component);
  end record_component_subtype_mark;

  function record_component_has_default_expression
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_has_default_expression
      (self.ast_store, component);
  end record_component_has_default_expression;

  function record_component_default_expression
    (self      : Context;
     component : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_default_expression
      (self.ast_store, component);
  end record_component_default_expression;

  function record_variant_choice_count
    (self    : Context;
     variant : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_choice_count (self.ast_store, variant);
  end record_variant_choice_count;

  function record_variant_choice_at
    (self    : Context;
     variant : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_choice_at
      (self.ast_store, variant, index);
  end record_variant_choice_at;

  function record_variant_has_null_component_list
    (self    : Context;
     variant : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_has_null_component_list
      (self.ast_store, variant);
  end record_variant_has_null_component_list;

  function record_variant_component_count
    (self    : Context;
     variant : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_component_count (self.ast_store, variant);
  end record_variant_component_count;

  function record_variant_component_at
    (self    : Context;
     variant : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_component_at
      (self.ast_store, variant, index);
  end record_variant_component_at;

  function record_variant_part_discriminant_name
    (self         : Context;
     variant_part : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_part_discriminant_name
      (self.ast_store, variant_part);
  end record_variant_part_discriminant_name;

  function record_variant_part_variant_count
    (self         : Context;
     variant_part : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_part_variant_count
      (self.ast_store, variant_part);
  end record_variant_part_variant_count;

  function record_variant_part_variant_at
    (self         : Context;
     variant_part : Adac.AST.Node_ID;
     index        : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_part_variant_at
      (self.ast_store, variant_part, index);
  end record_variant_part_variant_at;

  function record_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_type_symbol (self.ast_store, declaration);
  end record_type_symbol;

  function record_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_type_defining_span (self.ast_store, declaration);
  end record_type_defining_span;

  function record_type_is_limited
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_type_is_limited (self.ast_store, declaration);
  end record_type_is_limited;

  function record_has_variant_part
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_has_variant_part (self.ast_store, declaration);
  end record_has_variant_part;

  function record_variant_part
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_variant_part (self.ast_store, declaration);
  end record_variant_part;

  function record_discriminant_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_discriminant_count (self.ast_store, declaration);
  end record_discriminant_count;

  function record_discriminant_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_discriminant_at
      (self.ast_store, declaration, index);
  end record_discriminant_at;

  function record_component_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_count
      (self.ast_store, declaration);
  end record_component_count;

  function record_component_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.record_component_at
      (self.ast_store, declaration, index);
  end record_component_at;

  function access_object_type_symbol
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.access_object_type_symbol (self.ast_store, declaration);
  end access_object_type_symbol;

  function access_object_type_defining_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.access_object_type_defining_span
      (self.ast_store, declaration);
  end access_object_type_defining_span;

  function access_object_type_modifier
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.General_Access_Modifier_Kind is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.access_object_type_modifier
      (self.ast_store, declaration);
  end access_object_type_modifier;

  function access_object_type_designated_subtype
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.access_object_type_designated_subtype
      (self.ast_store, declaration);
  end access_object_type_designated_subtype;

  function package_renaming_defining_name_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_renaming_defining_name_count
      (self.ast_store, declaration);
  end package_renaming_defining_name_count;

  function package_renaming_defining_name_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_renaming_defining_name_symbol_at
      (self.ast_store, declaration, index);
  end package_renaming_defining_name_symbol_at;

  function package_renaming_defining_name_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_renaming_defining_name_span_at
      (self.ast_store, declaration, index);
  end package_renaming_defining_name_span_at;

  function package_renaming_renamed_package
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_renaming_renamed_package
      (self.ast_store, declaration);
  end package_renaming_renamed_package;

  function package_instantiation_defining_name_count
    (self          : Context;
     instantiation : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_defining_name_count
      (self.ast_store, instantiation);
  end package_instantiation_defining_name_count;

  function package_instantiation_defining_name_symbol_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_defining_name_symbol_at
      (self.ast_store, instantiation, index);
  end package_instantiation_defining_name_symbol_at;

  function package_instantiation_defining_name_span_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_defining_name_span_at
      (self.ast_store, instantiation, index);
  end package_instantiation_defining_name_span_at;

  function package_instantiation_generic_name
    (self          : Context;
     instantiation : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_generic_name
      (self.ast_store, instantiation);
  end package_instantiation_generic_name;

  function package_instantiation_actual_count
    (self          : Context;
     instantiation : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_actual_count
      (self.ast_store, instantiation);
  end package_instantiation_actual_count;

  function package_instantiation_actual_form_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Generic_Actual_Association_Form is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_actual_form_at
      (self.ast_store, instantiation, index);
  end package_instantiation_actual_form_at;

  function package_instantiation_actual_selector_symbol_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_actual_selector_symbol_at
      (self.ast_store, instantiation, index);
  end package_instantiation_actual_selector_symbol_at;

  function package_instantiation_actual_selector_span_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_actual_selector_span_at
      (self.ast_store, instantiation, index);
  end package_instantiation_actual_selector_span_at;

  function package_instantiation_actual_at
    (self          : Context;
     instantiation : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_instantiation_actual_at
      (self.ast_store, instantiation, index);
  end package_instantiation_actual_at;

  function package_defining_name_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_defining_name_count
      (self.ast_store, declaration);
  end package_defining_name_count;

  function package_defining_name_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_defining_name_symbol_at
      (self.ast_store, declaration, index);
  end package_defining_name_symbol_at;

  function package_defining_name_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_defining_name_span_at
      (self.ast_store, declaration, index);
  end package_defining_name_span_at;

  function package_visible_declaration_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_visible_declaration_count
      (self.ast_store, declaration);
  end package_visible_declaration_count;

  function package_visible_declaration_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_visible_declaration_at
      (self.ast_store, declaration, index);
  end package_visible_declaration_at;

  function package_has_explicit_private_part
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_has_explicit_private_part
      (self.ast_store, declaration);
  end package_has_explicit_private_part;

  function package_private_part_span
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_private_part_span (self.ast_store, declaration);
  end package_private_part_span;

  function package_private_declaration_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_private_declaration_count
      (self.ast_store, declaration);
  end package_private_declaration_count;

  function package_private_declaration_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_private_declaration_at
      (self.ast_store, declaration, index);
  end package_private_declaration_at;

  function package_has_end_designator
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_has_end_designator
      (self.ast_store, declaration);
  end package_has_end_designator;

  function package_end_name_count
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_end_name_count (self.ast_store, declaration);
  end package_end_name_count;

  function package_end_name_symbol_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_end_name_symbol_at
      (self.ast_store, declaration, index);
  end package_end_name_symbol_at;

  function package_end_name_span_at
    (self        : Context;
     declaration : Adac.AST.Node_ID;
     index       : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_end_name_span_at
      (self.ast_store, declaration, index);
  end package_end_name_span_at;

  function package_body_stub_symbol
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_stub_symbol (self.ast_store, stub);
  end package_body_stub_symbol;

  function package_body_stub_defining_span
    (self : Context;
     stub : Adac.AST.Node_ID)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_stub_defining_span (self.ast_store, stub);
  end package_body_stub_defining_span;

  function package_body_defining_name_count
    (self         : Context;
     package_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_defining_name_count
      (self.ast_store, package_body);
  end package_body_defining_name_count;

  function package_body_defining_name_symbol_at
    (self         : Context;
     package_body : Adac.AST.Node_ID;
     index        : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_defining_name_symbol_at
      (self.ast_store, package_body, index);
  end package_body_defining_name_symbol_at;

  function package_body_defining_name_span_at
    (self         : Context;
     package_body : Adac.AST.Node_ID;
     index        : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_defining_name_span_at
      (self.ast_store, package_body, index);
  end package_body_defining_name_span_at;

  function package_body_declaration_count
    (self         : Context;
     package_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_declaration_count
      (self.ast_store, package_body);
  end package_body_declaration_count;

  function package_body_declaration_at
    (self         : Context;
     package_body : Adac.AST.Node_ID;
     index        : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_declaration_at
      (self.ast_store, package_body, index);
  end package_body_declaration_at;

  function package_body_has_end_designator
    (self         : Context;
     package_body : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_has_end_designator
      (self.ast_store, package_body);
  end package_body_has_end_designator;

  function package_body_end_name_count
    (self : Context;
     package_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_end_name_count (self.ast_store, package_body);
  end package_body_end_name_count;

  function package_body_end_name_symbol_at
    (self  : Context;
     package_body  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_end_name_symbol_at
      (self.ast_store, package_body, index);
  end package_body_end_name_symbol_at;

  function package_body_end_name_span_at
    (self  : Context;
     package_body  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.package_body_end_name_span_at
      (self.ast_store, package_body, index);
  end package_body_end_name_span_at;

  function with_clause_name_count
    (self   : Context;
     clause : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.with_clause_name_count (self.ast_store, clause);
  end with_clause_name_count;

  function with_clause_name_at
    (self   : Context;
     clause : Adac.AST.Node_ID;
     index  : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.with_clause_name_at
      (self.ast_store, clause, index);
  end with_clause_name_at;

  function use_type_subtype_mark_count
    (self   : Context;
     clause : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.use_type_subtype_mark_count (self.ast_store, clause);
  end use_type_subtype_mark_count;

  function use_type_subtype_mark_at
    (self   : Context;
     clause : Adac.AST.Node_ID;
     index  : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.use_type_subtype_mark_at
      (self.ast_store, clause, index);
  end use_type_subtype_mark_at;

  function use_package_name_count
    (self   : Context;
     clause : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.use_package_name_count (self.ast_store, clause);
  end use_package_name_count;

  function use_package_name_at
    (self   : Context;
     clause : Adac.AST.Node_ID;
     index  : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.use_package_name_at (self.ast_store, clause, index);
  end use_package_name_at;

  function context_item_count
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.context_item_count (self.ast_store, unit);
  end context_item_count;

  function context_item_at
    (self  : Context;
     unit  : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.context_item_at (self.ast_store, unit, index);
  end context_item_at;

  function unit_item
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.unit_item (self.ast_store, unit);
  end unit_item;

  function library_item
    (self : Context;
     unit : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.library_item (self.ast_store, unit);
  end library_item;

  function subunit_parent_name_count
    (self    : Context;
     subunit : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subunit_parent_name_count (self.ast_store, subunit);
  end subunit_parent_name_count;

  function subunit_parent_name_symbol_at
    (self    : Context;
     subunit : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subunit_parent_name_symbol_at
      (self.ast_store, subunit, index);
  end subunit_parent_name_symbol_at;

  function subunit_parent_name_span_at
    (self    : Context;
     subunit : Adac.AST.Node_ID;
     index   : Positive)
  return Adac.Source.Span is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subunit_parent_name_span_at
      (self.ast_store, subunit, index);
  end subunit_parent_name_span_at;

  function subunit_proper_body
    (self    : Context;
     subunit : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.subunit_proper_body (self.ast_store, subunit);
  end subunit_proper_body;

  function procedure_symbol
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_symbol (self.ast_store, procedure_body);
  end procedure_symbol;

  function has_end_designator
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.has_end_designator (self.ast_store, procedure_body);
  end has_end_designator;

  function end_symbol
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.end_symbol (self.ast_store, procedure_body);
  end end_symbol;

  function parameter_count
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_count (self.ast_store, procedure_body);
  end parameter_count;

  function parameter_at
    (self : Context;
     procedure_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.parameter_at (self.ast_store, procedure_body, index);
  end parameter_at;

  function declaration_count
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.declaration_count (self.ast_store, procedure_body);
  end declaration_count;

  function declaration_at
    (self : Context;
     procedure_body : Adac.AST.Node_ID;
     index : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.declaration_at
      (self.ast_store, procedure_body, index);
  end declaration_at;

  function procedure_handled_sequence
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.procedure_handled_sequence
      (self.ast_store, procedure_body);
  end procedure_handled_sequence;

  function statement_count
    (self : Context;
     procedure_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.statement_count (self.ast_store, procedure_body);
  end statement_count;

  function statement_at
    (self           : Context;
     procedure_body : Adac.AST.Node_ID;
     index          : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.statement_at
      (self.ast_store, procedure_body, index);
  end statement_at;

  function function_body_symbol
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_symbol (self.ast_store, function_body);
  end function_body_symbol;

  function function_body_parameter_count
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_parameter_count
      (self.ast_store, function_body);
  end function_body_parameter_count;

  function function_body_parameter_at
    (self          : Context;
     function_body : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_parameter_at
      (self.ast_store, function_body, index);
  end function_body_parameter_at;

  function function_body_declaration_count
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Natural is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_declaration_count
      (self.ast_store, function_body);
  end function_body_declaration_count;

  function function_body_declaration_at
    (self          : Context;
     function_body : Adac.AST.Node_ID;
     index         : Positive)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_declaration_at
      (self.ast_store, function_body, index);
  end function_body_declaration_at;

  function function_body_result_subtype
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_result_subtype
      (self.ast_store, function_body);
  end function_body_result_subtype;

  function function_body_handled_sequence
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.AST.Node_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_handled_sequence
      (self.ast_store, function_body);
  end function_body_handled_sequence;

  function function_body_has_end_designator
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Boolean is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_has_end_designator
      (self.ast_store, function_body);
  end function_body_has_end_designator;

  function function_body_end_symbol
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    Adac.Compilation.validate (self);
    return Adac.AST.function_body_end_symbol
      (self.ast_store, function_body);
  end function_body_end_symbol;

  procedure validate_numeric_literal
    (self    : Context;
     literal : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_numeric_literal (self.ast_store, literal);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, literal));
  end validate_numeric_literal;

  procedure validate_exception_handler
    (self    : Context;
     handler : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_exception_handler (self.ast_store, handler);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, handler));
    if Adac.AST.exception_handler_has_choice_parameter
      (self.ast_store, handler)
    then
      Adac.Compilation.Symbols.validate_symbol
        (self,
         Adac.AST.exception_handler_choice_parameter_symbol
           (self.ast_store, handler));
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.exception_handler_choice_parameter_span
           (self.ast_store, handler));
    end if;
    for index in 1 .. Adac.AST.exception_handler_choice_count
      (self.ast_store, handler)
    loop
      declare
        choice : constant Adac.AST.Node_ID :=
          Adac.AST.exception_handler_choice_at
            (self.ast_store, handler, index);
      begin
        case Adac.AST.kind_of (self.ast_store, choice) is
          when Adac.AST.Others_Exception_Choice_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, choice));
          when Adac.AST.Identifier_Name_Node | Adac.AST.Selected_Name_Node =>
            validate_name (self, choice);
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid exception choice";
        end case;
      end;
    end loop;
    for index in 1 .. Adac.AST.exception_handler_statement_count
      (self.ast_store, handler)
    loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.exception_handler_statement_at
            (self.ast_store, handler, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Null_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));

          when Adac.AST.Return_Statement_Node =>
            validate_return_statement (self, statement);
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.Raise_Statement_Node =>
            validate_raise_statement (self, statement);
          when Adac.AST.Block_Statement_Node =>
            Adac.AST.Validation.validate_exception_handler_block_statement
              (self.ast_store, statement);
            validate_block_statement (self, statement);
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid handler statement";
        end case;
      end;
    end loop;
  end validate_exception_handler;

  procedure validate_handled_sequence
    (self     : Context;
     sequence : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_handled_sequence (self.ast_store, sequence);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, sequence));
    for index in 1 .. Adac.AST.handled_sequence_statement_count
      (self.ast_store, sequence)
    loop
      declare
        statement : constant Adac.AST.Node_ID :=
          Adac.AST.handled_sequence_statement_at
            (self.ast_store, sequence, index);
      begin
        case Adac.AST.kind_of (self.ast_store, statement) is
          when Adac.AST.Null_Statement_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, statement));

          when Adac.AST.Exit_Statement_Node =>
            validate_exit_statement (self, statement);
          when Adac.AST.Return_Statement_Node =>
            validate_return_statement (self, statement);
          when Adac.AST.Extended_Return_Statement_Node =>
            validate_extended_return_statement (self, statement);
          when Adac.AST.Assignment_Statement_Node =>
            validate_assignment_statement (self, statement);
          when Adac.AST.Raise_Statement_Node =>
            validate_raise_statement (self, statement);
          when Adac.AST.Case_Statement_Node =>
            validate_case_statement (self, statement);
          when Adac.AST.Block_Statement_Node =>
            validate_block_statement (self, statement);
          when Adac.AST.Loop_Statement_Node =>
            validate_loop_statement (self, statement);
          when Adac.AST.Procedure_Call_Statement_Node =>
            validate_procedure_call (self, statement);
          when Adac.AST.If_Statement_Node =>
            validate_if_statement (self, statement);
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid handled statement " &
              Adac.AST.Node_Kind'image
                (Adac.AST.kind_of (self.ast_store, statement));
        end case;
      end;
    end loop;
    for index in 1 .. Adac.AST.handled_sequence_handler_count
      (self.ast_store, sequence)
    loop
      validate_exception_handler
        (self,
         Adac.AST.handled_sequence_handler_at
           (self.ast_store, sequence, index));
    end loop;
  end validate_handled_sequence;

  procedure validate_compound_statement_graph_context
    (self : Context;
     root : Adac.AST.Node_ID)
  is
    pending : Adac.AST.Node_List;
    next    : Positive := 1;

    procedure validate_child (child : Adac.AST.Node_ID) is
      child_kind : constant Adac.AST.Node_Kind :=
        Adac.AST.kind_of (self.ast_store, child);
    begin
      case child_kind is
        when Adac.AST.Null_Statement_Node =>
          Adac.Compilation.Sources.validate_span
            (self, Adac.AST.node_span (self.ast_store, child));
        when Adac.AST.Exit_Statement_Node =>
          validate_exit_statement (self, child);
        when Adac.AST.Return_Statement_Node =>
          validate_return_statement (self, child);
        when Adac.AST.Raise_Statement_Node =>
          validate_raise_statement (self, child);
        when Adac.AST.Assignment_Statement_Node =>
          validate_assignment_statement (self, child);
        when Adac.AST.Procedure_Call_Statement_Node =>
          validate_procedure_call (self, child);
        when Adac.AST.If_Statement_Node |
             Adac.AST.Block_Statement_Node |
             Adac.AST.Loop_Statement_Node |
             Adac.AST.Case_Statement_Node =>
          Adac.Compilation.Sources.validate_span
            (self, Adac.AST.node_span (self.ast_store, child));
          Adac.AST.append (pending, child);
        when others =>
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid if branch statement";
      end case;
    end validate_child;

    procedure validate_elsif_node (part : Adac.AST.Node_ID) is
    begin
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, part));
      validate_expression
        (self, Adac.AST.elsif_condition (self.ast_store, part));
      for index in 1 .. Adac.AST.elsif_statement_count
        (self.ast_store, part)
      loop
        validate_child
          (Adac.AST.elsif_statement_at (self.ast_store, part, index));
      end loop;
    end validate_elsif_node;

    procedure validate_if_node (if_statement : Adac.AST.Node_ID) is
    begin
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, if_statement));
      validate_expression
        (self, Adac.AST.if_condition (self.ast_store, if_statement));

      for index in 1 .. Adac.AST.if_then_statement_count
        (self.ast_store, if_statement)
      loop
        validate_child
          (Adac.AST.if_then_statement_at
             (self.ast_store, if_statement, index));
      end loop;

      for index in 1 .. Adac.AST.if_elsif_part_count
        (self.ast_store, if_statement)
      loop
        declare
          part : constant Adac.AST.Node_ID :=
            Adac.AST.if_elsif_part_at (self.ast_store, if_statement, index);
        begin
          Adac.Compilation.Sources.validate_span
            (self, Adac.AST.node_span (self.ast_store, part));
          Adac.AST.append (pending, part);
        end;
      end loop;

      for index in 1 .. Adac.AST.if_else_statement_count
        (self.ast_store, if_statement)
      loop
        validate_child
          (Adac.AST.if_else_statement_at
             (self.ast_store, if_statement, index));
      end loop;
    end validate_if_node;

    procedure validate_block_node (block_statement : Adac.AST.Node_ID) is
      sequence : constant Adac.AST.Node_ID :=
        Adac.AST.block_handled_sequence (self.ast_store, block_statement);
    begin
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, block_statement));

      for index in 1 .. Adac.AST.block_declaration_count
        (self.ast_store, block_statement)
      loop
        validate_declaration
          (self,
           Adac.AST.block_declaration_at
             (self.ast_store, block_statement, index));
      end loop;

      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, sequence));

      for index in 1 .. Adac.AST.handled_sequence_statement_count
        (self.ast_store, sequence)
      loop
        declare
          child : constant Adac.AST.Node_ID :=
            Adac.AST.handled_sequence_statement_at
              (self.ast_store, sequence, index);
        begin
          case Adac.AST.kind_of (self.ast_store, child) is
            when Adac.AST.Assignment_Statement_Node =>
              validate_assignment_statement (self, child);
            when Adac.AST.Exit_Statement_Node =>
              validate_exit_statement (self, child);
            when Adac.AST.Block_Statement_Node |
                 Adac.AST.Case_Statement_Node |
                 Adac.AST.If_Statement_Node |
                 Adac.AST.Loop_Statement_Node =>
              Adac.Compilation.Sources.validate_span
                (self, Adac.AST.node_span (self.ast_store, child));
              Adac.AST.append (pending, child);
            when Adac.AST.Procedure_Call_Statement_Node =>
              validate_procedure_call (self, child);
            when Adac.AST.Return_Statement_Node =>
              validate_return_statement (self, child);
            when others =>
              raise Program_Error with
                "Adac.Compilation.Syntax: invalid if-branch block statement";
          end case;
        end;
      end loop;

      for index in 1 .. Adac.AST.handled_sequence_handler_count
        (self.ast_store, sequence)
      loop
        validate_exception_handler
          (self,
           Adac.AST.handled_sequence_handler_at
             (self.ast_store, sequence, index));
      end loop;
    end validate_block_node;

    procedure validate_loop_node (loop_statement : Adac.AST.Node_ID) is
    begin
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, loop_statement));

      case Adac.AST.loop_form (self.ast_store, loop_statement) is
        when Adac.AST.Discrete_Range_Loop_Form =>
          Adac.Compilation.Symbols.validate_symbol
            (self,
             Adac.AST.loop_parameter_symbol
               (self.ast_store, loop_statement));
          Adac.Compilation.Sources.validate_span
            (self,
             Adac.AST.loop_parameter_span
               (self.ast_store, loop_statement));
          validate_expression
            (self,
             Adac.AST.loop_range_lower_bound
               (self.ast_store, loop_statement));
          validate_expression
            (self,
             Adac.AST.loop_range_upper_bound
               (self.ast_store, loop_statement));

        when Adac.AST.Range_Attribute_Loop_Form =>
          Adac.Compilation.Symbols.validate_symbol
            (self,
             Adac.AST.loop_parameter_symbol
               (self.ast_store, loop_statement));
          Adac.Compilation.Sources.validate_span
            (self,
             Adac.AST.loop_parameter_span
               (self.ast_store, loop_statement));
          validate_name
            (self,
             Adac.AST.loop_range_attribute
               (self.ast_store, loop_statement));

        when Adac.AST.Generalized_Iterator_Loop_Form =>
          Adac.Compilation.Symbols.validate_symbol
            (self,
             Adac.AST.loop_parameter_symbol
               (self.ast_store, loop_statement));
          Adac.Compilation.Sources.validate_span
            (self,
             Adac.AST.loop_parameter_span
               (self.ast_store, loop_statement));
          validate_name
            (self,
             Adac.AST.loop_iterable_name (self.ast_store, loop_statement));

        when Adac.AST.While_Loop_Form =>
          validate_expression
            (self, Adac.AST.loop_condition (self.ast_store, loop_statement));

        when Adac.AST.Simple_Loop_Form =>
          null;
      end case;

      for index in 1 .. Adac.AST.loop_statement_count
        (self.ast_store, loop_statement)
      loop
        declare
          child : constant Adac.AST.Node_ID :=
            Adac.AST.loop_statement_at (self.ast_store, loop_statement, index);
        begin
          case Adac.AST.kind_of (self.ast_store, child) is
            when Adac.AST.Assignment_Statement_Node =>
              validate_assignment_statement (self, child);
            when Adac.AST.Exit_Statement_Node =>
              validate_exit_statement (self, child);
            when Adac.AST.Procedure_Call_Statement_Node =>
              validate_procedure_call (self, child);
            when Adac.AST.Case_Statement_Node |
                 Adac.AST.If_Statement_Node |
                 Adac.AST.Block_Statement_Node =>
              Adac.Compilation.Sources.validate_span
                (self, Adac.AST.node_span (self.ast_store, child));
              Adac.AST.append (pending, child);
            when others =>
              raise Program_Error with
                "Adac.Compilation.Syntax: invalid loop statement";
          end case;
        end;
      end loop;
    end validate_loop_node;

    procedure validate_case_alternative_node
      (alternative : Adac.AST.Node_ID)
    is
    begin
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, alternative));
      for index in 1 .. Adac.AST.case_alternative_choice_count
        (self.ast_store, alternative)
      loop
        declare
          choice : constant Adac.AST.Node_ID :=
            Adac.AST.case_alternative_choice_at
              (self.ast_store, alternative, index);
        begin
          case Adac.AST.kind_of (self.ast_store, choice) is
            when Adac.AST.Identifier_Name_Node | Adac.AST.Selected_Name_Node =>
              validate_name (self, choice);
            when Adac.AST.Numeric_Literal_Node =>
              validate_numeric_literal (self, choice);
            when Adac.AST.Character_Literal_Node =>
              validate_character_literal (self, choice);
            when Adac.AST.Case_Range_Choice_Node =>
              validate_case_range_choice (self, choice);
            when Adac.AST.Others_Case_Choice_Node =>
              Adac.Compilation.Sources.validate_span
                (self, Adac.AST.node_span (self.ast_store, choice));
            when others =>
              raise Program_Error with
                "Adac.Compilation.Syntax: invalid case choice";
          end case;
        end;
      end loop;

      for index in 1 .. Adac.AST.case_alternative_statement_count
        (self.ast_store, alternative)
      loop
        declare
          child : constant Adac.AST.Node_ID :=
            Adac.AST.case_alternative_statement_at
              (self.ast_store, alternative, index);
        begin
          case Adac.AST.kind_of (self.ast_store, child) is
            when Adac.AST.Null_Statement_Node =>
              Adac.Compilation.Sources.validate_span
                (self, Adac.AST.node_span (self.ast_store, child));
            when Adac.AST.Exit_Statement_Node =>
              validate_exit_statement (self, child);
            when Adac.AST.Return_Statement_Node =>
              validate_return_statement (self, child);
            when Adac.AST.Raise_Statement_Node =>
              validate_raise_statement (self, child);
            when Adac.AST.Assignment_Statement_Node =>
              validate_assignment_statement (self, child);
            when Adac.AST.Procedure_Call_Statement_Node =>
              validate_procedure_call (self, child);
            when Adac.AST.If_Statement_Node |
                 Adac.AST.Block_Statement_Node |
                 Adac.AST.Loop_Statement_Node |
                 Adac.AST.Case_Statement_Node =>
              Adac.Compilation.Sources.validate_span
                (self, Adac.AST.node_span (self.ast_store, child));
              Adac.AST.append (pending, child);
            when others =>
              raise Program_Error with
                "Adac.Compilation.Syntax: invalid case-alternative statement";
          end case;
        end;
      end loop;
    end validate_case_alternative_node;

    procedure validate_case_node (case_statement : Adac.AST.Node_ID) is
    begin
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, case_statement));
      validate_expression
        (self, Adac.AST.case_selecting_expression
          (self.ast_store, case_statement));
      for index in 1 .. Adac.AST.case_alternative_count
        (self.ast_store, case_statement)
      loop
        declare
          alternative : constant Adac.AST.Node_ID :=
            Adac.AST.case_alternative_at
              (self.ast_store, case_statement, index);
        begin
          Adac.Compilation.Sources.validate_span
            (self, Adac.AST.node_span (self.ast_store, alternative));
          Adac.AST.append (pending, alternative);
        end;
      end loop;
    end validate_case_node;

  begin
    Adac.Compilation.validate (self);
    case Adac.AST.kind_of (self.ast_store, root) is
      when Adac.AST.If_Statement_Node =>
        Adac.AST.Validation.validate_if_statement (self.ast_store, root);
      when Adac.AST.Block_Statement_Node =>
        Adac.AST.Validation.validate_block_statement (self.ast_store, root);
      when Adac.AST.Elsif_Part_Node =>
        Adac.AST.Validation.validate_elsif_part (self.ast_store, root);
      when Adac.AST.Loop_Statement_Node =>
        Adac.AST.Validation.validate_loop_statement (self.ast_store, root);
      when Adac.AST.Case_Statement_Node =>
        Adac.AST.Validation.validate_case_statement (self.ast_store, root);
      when Adac.AST.Case_Alternative_Node =>
        Adac.AST.Validation.validate_case_alternative (self.ast_store, root);
      when others =>
        raise Program_Error with
          "Adac.Compilation.Syntax: invalid compound validation root";
    end case;
    Adac.AST.append (pending, root);

    while next <= Adac.AST.list_count (pending) loop
      declare
        current : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (pending, next);
      begin
        case Adac.AST.kind_of (self.ast_store, current) is
          when Adac.AST.If_Statement_Node =>
            validate_if_node (current);
          when Adac.AST.Elsif_Part_Node =>
            validate_elsif_node (current);
          when Adac.AST.Block_Statement_Node =>
            validate_block_node (current);
          when Adac.AST.Loop_Statement_Node =>
            validate_loop_node (current);
          when Adac.AST.Case_Statement_Node =>
            validate_case_node (current);
          when Adac.AST.Case_Alternative_Node =>
            validate_case_alternative_node (current);
          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: invalid compound validation node";
        end case;
      end;
      next := next + 1;
    end loop;
  end validate_compound_statement_graph_context;

  procedure validate_elsif_part
    (self : Context;
     part : Adac.AST.Node_ID)
  is
  begin
    validate_compound_statement_graph_context (self, part);
  end validate_elsif_part;

  procedure validate_if_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    validate_compound_statement_graph_context (self, statement);
  end validate_if_statement;

  procedure validate_extended_return_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_extended_return_statement
      (self.ast_store, statement);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.extended_return_symbol (self.ast_store, statement));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.extended_return_defining_span
        (self.ast_store, statement));
    validate_name
      (self, Adac.AST.extended_return_subtype_mark
        (self.ast_store, statement));
    validate_handled_sequence
      (self, Adac.AST.extended_return_handled_sequence
        (self.ast_store, statement));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, statement));
  end validate_extended_return_statement;

  procedure validate_exit_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_exit_statement (self.ast_store, statement);
    if Adac.AST.exit_has_loop_name (self.ast_store, statement) then
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.exit_loop_name_symbol (self.ast_store, statement));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.exit_loop_name_span (self.ast_store, statement));
    end if;
    if Adac.AST.exit_has_condition (self.ast_store, statement) then
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.exit_when_span (self.ast_store, statement));
      validate_expression
        (self, Adac.AST.exit_condition (self.ast_store, statement));
    end if;
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, statement));
  end validate_exit_statement;

  procedure validate_return_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_return_statement (self.ast_store, statement);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, statement));
    if Adac.AST.return_has_expression (self.ast_store, statement) then
      validate_expression
        (self, Adac.AST.return_expression (self.ast_store, statement));
    end if;
  end validate_return_statement;

  procedure validate_raise_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_raise_statement (self.ast_store, statement);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, statement));
    case Adac.AST.raise_form (self.ast_store, statement) is
      when Adac.AST.Bare_Reraise_Form =>
        null;
      when Adac.AST.Named_With_Message_Raise_Form =>
        validate_name
          (self, Adac.AST.raise_exception_name (self.ast_store, statement));
        validate_expression
          (self, Adac.AST.raise_message_expression (self.ast_store, statement));
    end case;
  end validate_raise_statement;

  procedure validate_assignment_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_assignment_statement
      (self.ast_store, statement);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, statement));
    validate_name
      (self, Adac.AST.assignment_target (self.ast_store, statement));
    validate_expression
      (self, Adac.AST.assignment_expression (self.ast_store, statement));
  end validate_assignment_statement;

  procedure validate_case_range_choice
    (self   : Context;
     choice : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_case_range_choice (self.ast_store, choice);
    validate_character_literal
      (self, Adac.AST.case_range_choice_lower_bound (self.ast_store, choice));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.case_range_choice_range_span (self.ast_store, choice));
    validate_character_literal
      (self, Adac.AST.case_range_choice_upper_bound (self.ast_store, choice));
  end validate_case_range_choice;

  procedure validate_case_alternative
    (self        : Context;
     alternative : Adac.AST.Node_ID)
  is
  begin
    validate_compound_statement_graph_context (self, alternative);
  end validate_case_alternative;

  procedure validate_case_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    validate_compound_statement_graph_context (self, statement);
  end validate_case_statement;

  procedure validate_block_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    declare
      sequence : constant Adac.AST.Node_ID :=
        Adac.AST.block_handled_sequence (self.ast_store, statement);
    begin
      if Adac.AST.handled_sequence_handler_count
        (self.ast_store, sequence) = 0
      then
        validate_compound_statement_graph_context (self, statement);
        return;
      end if;
    end;
    Adac.AST.Validation.validate_block_statement (self.ast_store, statement);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, statement));
    for index in 1 .. Adac.AST.block_declaration_count
      (self.ast_store, statement)
    loop
      declare
        declaration : constant Adac.AST.Node_ID :=
          Adac.AST.block_declaration_at (self.ast_store, statement, index);
      begin
        if Adac.AST.kind_of (self.ast_store, declaration) /=
             Adac.AST.Object_Declaration_Node and then
           Adac.AST.kind_of (self.ast_store, declaration) /=
             Adac.AST.Object_Renaming_Declaration_Node
        then
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid block declaration";
        end if;
        validate_declaration (self, declaration);
      end;
    end loop;
    declare
      sequence : constant Adac.AST.Node_ID :=
        Adac.AST.block_handled_sequence (self.ast_store, statement);
    begin
      validate_current_block_handled_sequence (self, sequence);
      validate_handled_sequence (self, sequence);
    end;
  end validate_block_statement;

  procedure validate_loop_statement
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    validate_compound_statement_graph_context (self, statement);
  end validate_loop_statement;

  procedure validate_procedure_call
    (self      : Context;
     statement : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_procedure_call (self.ast_store, statement);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, statement));

    declare
      callable_name : constant Adac.AST.Node_ID :=
        Adac.AST.procedure_call_callable_name (self.ast_store, statement);
    begin
      validate_name (self, callable_name);
    end;

    for index in 1 .. Adac.AST.procedure_call_actual_count
      (self.ast_store, statement)
    loop
      if Adac.AST.procedure_call_actual_form
           (self.ast_store, statement, index) =
         Adac.AST.Named_Procedure_Call_Actual_Form
      then
        validate_name
          (self,
           Adac.AST.procedure_call_actual_selector_at
             (self.ast_store, statement, index));
      end if;
      validate_expression
        (self,
         Adac.AST.procedure_call_actual_at
           (self.ast_store, statement, index));
    end loop;
  end validate_procedure_call;

  procedure validate_character_literal
    (self    : Context;
     literal : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_character_literal (self.ast_store, literal);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, literal));
  end validate_character_literal;

  procedure validate_string_literal
    (self    : Context;
     literal : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_string_literal (self.ast_store, literal);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, literal));
  end validate_string_literal;

  procedure validate_null_literal
    (self    : Context;
     literal : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_null_literal (self.ast_store, literal);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, literal));
  end validate_null_literal;

  procedure validate_record_aggregate
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  is
    pending    : Adac.AST.Node_List;
    next_index : Natural := 1;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_record_aggregate
      (self.ast_store, aggregate);
    Adac.AST.append (pending, aggregate);

    while next_index <= Adac.AST.list_count (pending) loop
      declare
        current : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (pending, Positive(next_index));
      begin
        next_index := next_index + 1;
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, current));

        for index in 1 .. Adac.AST.record_aggregate_association_count
          (self.ast_store, current)
        loop
          Adac.Compilation.Symbols.validate_symbol
            (self,
             Adac.AST.record_aggregate_selector_symbol_at
               (self.ast_store, current, index));
          Adac.Compilation.Sources.validate_span
            (self,
             Adac.AST.record_aggregate_selector_span_at
               (self.ast_store, current, index));
          declare
            expression : constant Adac.AST.Node_ID :=
              Adac.AST.record_aggregate_expression_at
                (self.ast_store, current, index);
          begin
            if Adac.AST.kind_of (self.ast_store, expression) =
               Adac.AST.Record_Aggregate_Node
            then
              Adac.AST.append (pending, expression);
            else
              validate_expression (self, expression);
            end if;
          end;
        end loop;
      end;
    end loop;
  end validate_record_aggregate;

  procedure validate_array_aggregate
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  is
    procedure validate_choices (association_index : Positive) is
    begin
      for choice_index in 1 ..
        Adac.AST.array_aggregate_choice_count
          (self.ast_store, aggregate, association_index)
      loop
        validate_expression
          (self,
           Adac.AST.array_aggregate_choice_at
             (self.ast_store, aggregate, association_index, choice_index));
      end loop;
    end validate_choices;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_array_aggregate
      (self.ast_store, aggregate);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, aggregate));
    for association_index in 1 ..
      Adac.AST.array_aggregate_association_count (self.ast_store, aggregate)
    loop
      validate_choices (association_index);
      validate_expression
        (self,
         Adac.AST.array_aggregate_expression_at
           (self.ast_store, aggregate, association_index));
    end loop;
  end validate_array_aggregate;

  procedure validate_bracket_aggregate
    (self      : Context;
     aggregate : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_bracket_aggregate
      (self.ast_store, aggregate);
    for index in 1 .. Adac.AST.bracket_aggregate_expression_count
      (self.ast_store, aggregate)
    loop
      validate_allocator
        (self,
         Adac.AST.bracket_aggregate_expression_at
           (self.ast_store, aggregate, index));
    end loop;
  end validate_bracket_aggregate;

  procedure validate_qualified_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_qualified_expression
      (self.ast_store, expression);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, expression));
    validate_name
      (self,
       Adac.AST.qualified_expression_subtype_mark
         (self.ast_store, expression));
    declare
      operand : constant Adac.AST.Node_ID :=
        Adac.AST.qualified_expression_operand (self.ast_store, expression);
    begin
      if Adac.AST.kind_of (self.ast_store, operand) =
         Adac.AST.Record_Aggregate_Node
      then
        validate_record_aggregate (self, operand);
      elsif Adac.AST.kind_of (self.ast_store, operand) =
         Adac.AST.Array_Aggregate_Node
      then
        validate_array_aggregate (self, operand);
      else
        validate_expression (self, operand);
      end if;
    end;
  end validate_qualified_expression;

  procedure validate_allocator
    (self      : Context;
     allocator : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_allocator (self.ast_store, allocator);
    validate_qualified_expression
      (self, Adac.AST.allocator_expression (self.ast_store, allocator));
  end validate_allocator;

  procedure validate_membership_range_choice
    (self   : Context;
     choice : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_membership_range_choice
      (self.ast_store, choice);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, choice));
    validate_expression
      (self, Adac.AST.membership_range_choice_lower_bound
         (self.ast_store, choice));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.membership_range_choice_range_span
         (self.ast_store, choice));
    validate_expression
      (self, Adac.AST.membership_range_choice_upper_bound
         (self.ast_store, choice));
  end validate_membership_range_choice;

  procedure validate_logical_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  is
    current : Adac.AST.Node_ID := expression;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_expression (self.ast_store, expression);

    loop
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, current));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.logical_operator_span (self.ast_store, current));

      declare
        left_operand : constant Adac.AST.Node_ID :=
          Adac.AST.logical_left_operand (self.ast_store, current);
        right_operand : constant Adac.AST.Node_ID :=
          Adac.AST.logical_right_operand (self.ast_store, current);
      begin
        validate_expression (self, right_operand);
        if Adac.AST.kind_of (self.ast_store, left_operand) =
           Adac.AST.Logical_Expression_Node
        then
          current := left_operand;
        else
          validate_expression (self, left_operand);
          exit;
        end if;
      end;
    end loop;
  end validate_logical_expression;

  procedure validate_short_circuit_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  is
    current : Adac.AST.Node_ID := expression;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_short_circuit_expression
      (self.ast_store, expression);

    loop
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, current));
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.short_circuit_operator_first_span
           (self.ast_store, current));
      Adac.Compilation.Sources.validate_span
        (self,
         Adac.AST.short_circuit_operator_second_span
           (self.ast_store, current));

      declare
        left_operand : constant Adac.AST.Node_ID :=
          Adac.AST.short_circuit_left_operand (self.ast_store, current);
        right_operand : constant Adac.AST.Node_ID :=
          Adac.AST.short_circuit_right_operand (self.ast_store, current);
      begin
        validate_expression (self, right_operand);
        if Adac.AST.kind_of (self.ast_store, left_operand) =
           Adac.AST.Short_Circuit_Expression_Node
        then
          current := left_operand;
        else
          validate_expression (self, left_operand);
          exit;
        end if;
      end;
    end loop;
  end validate_short_circuit_expression;

  procedure validate_expression
    (self       : Context;
     expression : Adac.AST.Node_ID)
  is
    pending    : Adac.AST.Node_List;
    next_index : Natural := 1;

    procedure validate_one_expression (node : Adac.AST.Node_ID);
    procedure validate_slice_expression_node (slice : Adac.AST.Node_ID);

    procedure validate_direct_expression (node : Adac.AST.Node_ID) is
    begin
      case Adac.AST.kind_of (self.ast_store, node) is
        when Adac.AST.Numeric_Literal_Node =>
          validate_numeric_literal (self, node);

        when Adac.AST.Character_Literal_Node =>
          validate_character_literal (self, node);

        when Adac.AST.String_Literal_Node =>
          validate_string_literal (self, node);

        when Adac.AST.Null_Literal_Node =>
          validate_null_literal (self, node);

        when Adac.AST.Record_Aggregate_Node =>
          validate_record_aggregate (self, node);

        when Adac.AST.Array_Aggregate_Node =>
          validate_array_aggregate (self, node);

        when Adac.AST.Bracket_Aggregate_Node =>
          validate_bracket_aggregate (self, node);

        when Adac.AST.Qualified_Expression_Node =>
          validate_qualified_expression (self, node);

        when Adac.AST.Allocator_Node =>
          validate_allocator (self, node);

        when Adac.AST.Identifier_Name_Node |
             Adac.AST.Selected_Name_Node |
             Adac.AST.Explicit_Dereference_Name_Node |
             Adac.AST.Selected_Component_Node |
             Adac.AST.Parenthesized_Name_Node |
             Adac.AST.Attribute_Name_Node =>
          validate_name (self, node);

        when Adac.AST.Slice_Name_Node =>
          validate_slice_expression_node (node);

        when Adac.AST.Parenthesized_Expression_Node =>
          Adac.Compilation.Sources.validate_span
            (self, Adac.AST.node_span (self.ast_store, node));
          Adac.AST.append
            (pending,
             Adac.AST.parenthesized_expression_child (self.ast_store, node));

        when others =>
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid direct expression";
      end case;
    end validate_direct_expression;

    procedure validate_factor_expression (node : Adac.AST.Node_ID) is
    begin
      if Adac.AST.kind_of (self.ast_store, node) =
           Adac.AST.Unary_Operator_Node or else
         Adac.AST.kind_of (self.ast_store, node) =
           Adac.AST.Binary_Exponentiating_Node
      then
        Adac.AST.append (pending, node);
      else
        validate_direct_expression (node);
      end if;
    end validate_factor_expression;

    procedure validate_binary_multiplying_chain
      (root : Adac.AST.Node_ID)
    is
      current : Adac.AST.Node_ID := root;
    begin
      loop
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, current));
        Adac.Compilation.Sources.validate_span
          (self,
           Adac.AST.binary_multiplying_operator_span
             (self.ast_store, current));

        declare
          left_operand : constant Adac.AST.Node_ID :=
            Adac.AST.binary_multiplying_left_operand
              (self.ast_store, current);
          right_operand : constant Adac.AST.Node_ID :=
            Adac.AST.binary_multiplying_right_operand
              (self.ast_store, current);
        begin
          validate_factor_expression (right_operand);
          if Adac.AST.kind_of (self.ast_store, left_operand) =
             Adac.AST.Binary_Multiplying_Node
          then
            current := left_operand;
          else
            validate_factor_expression (left_operand);
            exit;
          end if;
        end;
      end loop;
    end validate_binary_multiplying_chain;

    procedure validate_term_expression (node : Adac.AST.Node_ID) is
    begin
      if Adac.AST.kind_of (self.ast_store, node) =
         Adac.AST.Binary_Multiplying_Node
      then
        validate_binary_multiplying_chain (node);
      else
        validate_factor_expression (node);
      end if;
    end validate_term_expression;

    procedure validate_binary_adding_chain (root : Adac.AST.Node_ID) is
      current : Adac.AST.Node_ID := root;
    begin
      loop
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, current));
        Adac.Compilation.Sources.validate_span
          (self,
           Adac.AST.binary_adding_operator_span (self.ast_store, current));

        declare
          left_operand : constant Adac.AST.Node_ID :=
            Adac.AST.binary_adding_left_operand (self.ast_store, current);
          right_operand : constant Adac.AST.Node_ID :=
            Adac.AST.binary_adding_right_operand (self.ast_store, current);
        begin
          validate_term_expression (right_operand);
          if Adac.AST.kind_of (self.ast_store, left_operand) =
               Adac.AST.Binary_Adding_Node
          then
            current := left_operand;
          else
            validate_term_expression (left_operand);
            exit;
          end if;
        end;
      end loop;
    end validate_binary_adding_chain;

    procedure validate_simple_expression (node : Adac.AST.Node_ID) is
    begin
      if Adac.AST.kind_of (self.ast_store, node) =
           Adac.AST.Binary_Adding_Node
      then
        validate_binary_adding_chain (node);
      else
        validate_term_expression (node);
      end if;
    end validate_simple_expression;

    procedure validate_slice_expression_node
      (slice : Adac.AST.Node_ID)
    is
      prefix : constant Adac.AST.Node_ID :=
        Adac.AST.name_prefix (self.ast_store, slice);
      lower_bound : constant Adac.AST.Node_ID :=
        Adac.AST.slice_lower_bound (self.ast_store, slice);
      upper_bound : constant Adac.AST.Node_ID :=
        Adac.AST.slice_upper_bound (self.ast_store, slice);
    begin
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, slice));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.slice_range_span (self.ast_store, slice));
      validate_name (self, prefix);
      Adac.AST.append (pending, lower_bound);
      Adac.AST.append (pending, upper_bound);
    end validate_slice_expression_node;

    procedure validate_one_expression (node : Adac.AST.Node_ID) is
    begin
    case Adac.AST.kind_of (self.ast_store, node) is
      when Adac.AST.Numeric_Literal_Node |
           Adac.AST.Character_Literal_Node |
           Adac.AST.String_Literal_Node |
           Adac.AST.Null_Literal_Node |
           Adac.AST.Record_Aggregate_Node |
           Adac.AST.Bracket_Aggregate_Node |
           Adac.AST.Qualified_Expression_Node |
           Adac.AST.Allocator_Node |
           Adac.AST.Parenthesized_Expression_Node |
           Adac.AST.Identifier_Name_Node |
           Adac.AST.Selected_Name_Node |
           Adac.AST.Explicit_Dereference_Name_Node |
           Adac.AST.Selected_Component_Node |
           Adac.AST.Parenthesized_Name_Node |
           Adac.AST.Slice_Name_Node |
           Adac.AST.Attribute_Name_Node =>
        validate_direct_expression (node);

      when Adac.AST.If_Expression_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, node));
        declare
          condition : constant Adac.AST.Node_ID :=
            Adac.AST.if_expression_condition (self.ast_store, node);
        begin
          if Adac.AST.kind_of (self.ast_store, condition) in
               Adac.AST.Relation_Node | Adac.AST.Short_Circuit_Expression_Node
          then
            validate_one_expression (condition);
          else
            validate_simple_expression (condition);
          end if;
        end;
        validate_simple_expression
          (Adac.AST.if_expression_then_expression
             (self.ast_store, node));
        validate_simple_expression
          (Adac.AST.if_expression_else_expression
             (self.ast_store, node));

      when Adac.AST.Raise_Expression_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, node));
        validate_name
          (self, Adac.AST.raise_expression_exception_name
             (self.ast_store, node));
        if Adac.AST.raise_expression_has_message (self.ast_store, node) then
          validate_simple_expression
            (Adac.AST.raise_expression_message (self.ast_store, node));
        end if;

      when Adac.AST.Case_Expression_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, node));
        validate_simple_expression
          (Adac.AST.case_expression_selecting_expression
             (self.ast_store, node));
        for alternative_index in 1 ..
          Adac.AST.case_expression_alternative_count (self.ast_store, node)
        loop
          declare
            alternative : constant Adac.AST.Node_ID :=
              Adac.AST.case_expression_alternative_at
                (self.ast_store, node, alternative_index);
          begin
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, alternative));
            for choice_index in 1 ..
              Adac.AST.case_expression_alternative_choice_count
                (self.ast_store, alternative)
            loop
              declare
                choice : constant Adac.AST.Node_ID :=
                  Adac.AST.case_expression_alternative_choice_at
                    (self.ast_store, alternative, choice_index);
              begin
                case Adac.AST.kind_of (self.ast_store, choice) is
                  when Adac.AST.Identifier_Name_Node |
                       Adac.AST.Selected_Name_Node =>
                    validate_name (self, choice);
                  when Adac.AST.Others_Case_Choice_Node =>
                    Adac.Compilation.Sources.validate_span
                      (self, Adac.AST.node_span (self.ast_store, choice));
                  when others =>
                    raise Program_Error with
                      "Adac.Compilation.Syntax: invalid case-expression choice";
                end case;
              end;
            end loop;
            declare
              dependent : constant Adac.AST.Node_ID :=
                Adac.AST.case_expression_alternative_expression
                  (self.ast_store, alternative);
            begin
              if Adac.AST.kind_of (self.ast_store, dependent) =
                 Adac.AST.Raise_Expression_Node
              then
                validate_one_expression (dependent);
              else
                validate_simple_expression (dependent);
              end if;
            end;
          end;
        end loop;

      when Adac.AST.Unary_Operator_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, node));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.unary_operator_span (self.ast_store, node));
        declare
          operator_spelling : constant String :=
            Adac.AST.unary_operator_spelling (self.ast_store, node);
          operand : constant Adac.AST.Node_ID :=
            Adac.AST.unary_operand (self.ast_store, node);
        begin
          if operator_spelling = "+" or else operator_spelling = "-" then
            validate_term_expression (operand);
          else
            validate_direct_expression (operand);
          end if;
        end;

      when Adac.AST.Binary_Exponentiating_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, node));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.binary_exponentiating_operator_span
             (self.ast_store, node));
        validate_direct_expression
          (Adac.AST.binary_exponentiating_left_operand
             (self.ast_store, node));
        validate_direct_expression
          (Adac.AST.binary_exponentiating_right_operand
             (self.ast_store, node));

      when Adac.AST.Binary_Multiplying_Node =>
        validate_binary_multiplying_chain (node);

      when Adac.AST.Binary_Adding_Node =>
        validate_binary_adding_chain (node);

      when Adac.AST.Membership_Expression_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, node));
        if Adac.AST.membership_operator (self.ast_store, node) =
           Adac.AST.Not_In_Membership_Operator
        then
          Adac.Compilation.Sources.validate_span
            (self, Adac.AST.membership_not_span (self.ast_store, node));
        end if;
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.membership_in_span (self.ast_store, node));
        validate_simple_expression
          (Adac.AST.membership_tested_expression (self.ast_store, node));
        for index in 1 ..
          Adac.AST.membership_choice_count (self.ast_store, node)
        loop
          declare
            choice : constant Adac.AST.Node_ID :=
              Adac.AST.membership_choice_at
                (self.ast_store, node, index);
          begin
            if Adac.AST.kind_of (self.ast_store, choice) =
               Adac.AST.Membership_Range_Choice_Node
            then
              validate_membership_range_choice (self, choice);
            else
              validate_simple_expression (choice);
            end if;
          end;
        end loop;

      when Adac.AST.Logical_Expression_Node =>
        validate_logical_expression (self, node);

      when Adac.AST.Short_Circuit_Expression_Node =>
        validate_short_circuit_expression (self, node);

      when Adac.AST.Relation_Node =>
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, node));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.relation_operator_span (self.ast_store, node));
        validate_simple_expression
          (Adac.AST.relation_left_operand (self.ast_store, node));
        validate_simple_expression
          (Adac.AST.relation_right_operand (self.ast_store, node));

      when others =>
        raise Program_Error with
          "Adac.Compilation.Syntax: node is not a represented node";
    end case;
    end validate_one_expression;

  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_expression (self.ast_store, expression);
    Adac.AST.append (pending, expression);

    while next_index <= Adac.AST.list_count (pending) loop
      validate_one_expression
        (Adac.AST.list_element (pending, Positive(next_index)));
      next_index := next_index + 1;
    end loop;
  end validate_expression;

  procedure validate_name
    (self : Context;
     name : Adac.AST.Node_ID)
  is
    procedure validate_simple_name (node : Adac.AST.Node_ID) is
      current : Adac.AST.Node_ID := node;
    begin
      loop
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, current));

        case Adac.AST.kind_of (self.ast_store, current) is
          when Adac.AST.Identifier_Name_Node =>
            Adac.Compilation.Symbols.validate_symbol
              (self, Adac.AST.identifier_symbol (self.ast_store, current));
            return;

          when Adac.AST.Selected_Name_Node =>
            Adac.Compilation.Symbols.validate_symbol
              (self, Adac.AST.selector_symbol (self.ast_store, current));
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.selector_span (self.ast_store, current));
            current := Adac.AST.name_prefix (self.ast_store, current);

          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: node is not a simple name";
        end case;
      end loop;
    end validate_simple_name;

    pending    : Adac.AST.Node_List;
    next_index : Natural := 1;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_name (self.ast_store, name);
    Adac.AST.append (pending, name);

    while next_index <= Adac.AST.list_count (pending) loop
      declare
        current : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (pending, Positive(next_index));
      begin
        next_index := next_index + 1;

        case Adac.AST.kind_of (self.ast_store, current) is
          when Adac.AST.Identifier_Name_Node | Adac.AST.Selected_Name_Node =>
            validate_simple_name (current);

          when Adac.AST.Explicit_Dereference_Name_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, current));
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.explicit_dereference_all_span
                (self.ast_store, current));
            Adac.AST.append
              (pending, Adac.AST.name_prefix (self.ast_store, current));

          when Adac.AST.Selected_Component_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, current));
            Adac.Compilation.Symbols.validate_symbol
              (self, Adac.AST.selector_symbol (self.ast_store, current));
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.selector_span (self.ast_store, current));
            Adac.AST.append
              (pending, Adac.AST.name_prefix (self.ast_store, current));

          when Adac.AST.Slice_Name_Node =>
            validate_expression (self, current);

          when Adac.AST.Attribute_Name_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, current));
            Adac.AST.append
              (pending, Adac.AST.name_prefix (self.ast_store, current));
            Adac.Compilation.Symbols.validate_symbol
              (self, Adac.AST.attribute_symbol (self.ast_store, current));
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.attribute_span (self.ast_store, current));

          when Adac.AST.Parenthesized_Name_Node =>
            Adac.Compilation.Sources.validate_span
              (self, Adac.AST.node_span (self.ast_store, current));
            Adac.AST.append
              (pending, Adac.AST.name_prefix (self.ast_store, current));

            for index in 1 ..
              Adac.AST.parenthesized_item_count (self.ast_store, current)
            loop
              declare
                item : constant Adac.AST.Node_ID :=
                  Adac.AST.parenthesized_item_at
                    (self.ast_store, current, index);
              begin
                case Adac.AST.kind_of (self.ast_store, item) is
                  when Adac.AST.Numeric_Literal_Node |
                       Adac.AST.Character_Literal_Node |
                       Adac.AST.Binary_Adding_Node |
                       Adac.AST.String_Literal_Node =>
                    validate_expression (self, item);
                  when others =>
                    Adac.AST.append (pending, item);
                end case;
              end;
            end loop;

          when others =>
            raise Program_Error with
              "Adac.Compilation.Syntax: node is not a current name";
        end case;
      end;
    end loop;
  end validate_name;

  procedure validate_exception_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_exception_declaration
      (self.ast_store, declaration);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.exception_declaration_symbol
        (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.exception_declaration_defining_span
        (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, declaration));
  end validate_exception_declaration;

  procedure validate_aspect_specification
    (self   : Context;
     aspect : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_aspect_specification
      (self.ast_store, aspect);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.aspect_mark_symbol (self.ast_store, aspect));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.aspect_mark_span (self.ast_store, aspect));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, aspect));
    validate_expression
      (self, Adac.AST.aspect_definition (self.ast_store, aspect));
  end validate_aspect_specification;

  procedure validate_parameter
    (self      : Context;
     parameter : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_parameter (self.ast_store, parameter);
    for index in 1 ..
      Adac.AST.parameter_defining_identifier_count (self.ast_store, parameter)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.parameter_defining_symbol_at
           (self.ast_store, parameter, index));
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.parameter_defining_span_at
           (self.ast_store, parameter, index));
    end loop;
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, parameter));
    validate_name
      (self, Adac.AST.parameter_subtype_mark (self.ast_store, parameter));
    declare
      default_expression : constant Adac.AST.Node_ID :=
        Adac.AST.parameter_default_expression (self.ast_store, parameter);
    begin
      if default_expression /= Adac.AST.INVALID_NODE_ID then
        validate_expression (self, default_expression);
      end if;
    end;
  end validate_parameter;

  procedure validate_discriminant_specification
    (self         : Context;
     discriminant : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_discriminant_specification
      (self.ast_store, discriminant);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.discriminant_symbol (self.ast_store, discriminant));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.discriminant_defining_span
        (self.ast_store, discriminant));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, discriminant));
    validate_name
      (self, Adac.AST.discriminant_subtype_mark
        (self.ast_store, discriminant));
    if Adac.AST.discriminant_has_default_expression
      (self.ast_store, discriminant)
    then
      validate_expression
        (self, Adac.AST.discriminant_default_expression
          (self.ast_store, discriminant));
    end if;
  end validate_discriminant_specification;

  procedure validate_record_component_declaration
    (self      : Context;
     component : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_record_component_declaration
      (self.ast_store, component);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.record_component_symbol (self.ast_store, component));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.record_component_defining_span
        (self.ast_store, component));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, component));
    validate_name
      (self, Adac.AST.record_component_subtype_mark
        (self.ast_store, component));
    if Adac.AST.record_component_has_default_expression
      (self.ast_store, component)
    then
      validate_expression
        (self, Adac.AST.record_component_default_expression
          (self.ast_store, component));
    end if;
  end validate_record_component_declaration;

  procedure validate_derived_type_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_derived_type_declaration
      (self.ast_store, declaration);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.derived_type_symbol (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.derived_type_defining_span
        (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, declaration));
    validate_name
      (self, Adac.AST.derived_type_parent_subtype_mark
        (self.ast_store, declaration));
  end validate_derived_type_declaration;

  procedure validate_range_constraint
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_range_constraint
      (self.ast_store, constraint);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, constraint));
    validate_expression
      (self, Adac.AST.range_constraint_lower_bound
        (self.ast_store, constraint));
    validate_expression
      (self, Adac.AST.range_constraint_upper_bound
        (self.ast_store, constraint));
  end validate_range_constraint;

  procedure validate_index_constraint
    (self       : Context;
     constraint : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_index_constraint
      (self.ast_store, constraint);
    validate_expression
      (self, Adac.AST.index_constraint_lower_bound
        (self.ast_store, constraint));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.index_constraint_range_span
        (self.ast_store, constraint));
    validate_expression
      (self, Adac.AST.index_constraint_upper_bound
        (self.ast_store, constraint));
  end validate_index_constraint;

  procedure validate_subtype_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_subtype_declaration
      (self.ast_store, declaration);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.subtype_declaration_symbol
        (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.subtype_declaration_defining_span
        (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, declaration));
    validate_name
      (self, Adac.AST.subtype_declaration_subtype_mark
        (self.ast_store, declaration));
    if Adac.AST.subtype_declaration_has_constraint
      (self.ast_store, declaration)
    then
      validate_range_constraint
        (self, Adac.AST.subtype_declaration_constraint
          (self.ast_store, declaration));
    end if;
  end validate_subtype_declaration;

  procedure validate_record_variant
    (self    : Context;
     variant : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_record_variant (self.ast_store, variant);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, variant));
    for index in 1 .. record_variant_choice_count (self, variant) loop
      validate_name (self, record_variant_choice_at (self, variant, index));
    end loop;
    for index in 1 .. record_variant_component_count (self, variant) loop
      validate_record_component_declaration
        (self, record_variant_component_at (self, variant, index));
    end loop;
  end validate_record_variant;

  procedure validate_record_variant_part
    (self         : Context;
     variant_part : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_record_variant_part
      (self.ast_store, variant_part);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, variant_part));
    validate_name
      (self, record_variant_part_discriminant_name (self, variant_part));
    for index in 1 ..
      record_variant_part_variant_count (self, variant_part)
    loop
      validate_record_variant
        (self, record_variant_part_variant_at (self, variant_part, index));
    end loop;
  end validate_record_variant_part;

  procedure validate_record_type_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_record_type_declaration
      (self.ast_store, declaration);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.record_type_symbol (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.record_type_defining_span (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, declaration));
    for index in 1 .. record_discriminant_count (self, declaration) loop
      validate_discriminant_specification
        (self, record_discriminant_at (self, declaration, index));
    end loop;
    for index in 1 .. record_component_count (self, declaration) loop
      validate_record_component_declaration
        (self, record_component_at (self, declaration, index));
    end loop;
    if record_has_variant_part (self, declaration) then
      validate_record_variant_part
        (self, record_variant_part (self, declaration));
    end if;
  end validate_record_type_declaration;

  procedure validate_access_object_type_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
    designated_subtype : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_access_object_type_declaration
      (self.ast_store, declaration);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.access_object_type_symbol
        (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.access_object_type_defining_span
        (self.ast_store, declaration));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, declaration));
    designated_subtype :=
      Adac.AST.access_object_type_designated_subtype
        (self.ast_store, declaration);
    validate_name (self, designated_subtype);
  end validate_access_object_type_declaration;

  procedure validate_use_type_clause
    (self   : Context;
     clause : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_use_type_clause (self.ast_store, clause);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, clause));
    for index in 1 .. use_type_subtype_mark_count (self, clause) loop
      validate_name (self, use_type_subtype_mark_at (self, clause, index));
    end loop;
  end validate_use_type_clause;

  procedure validate_use_package_clause
    (self   : Context;
     clause : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_use_package_clause (self.ast_store, clause);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, clause));
    for index in 1 .. use_package_name_count (self, clause) loop
      validate_name (self, use_package_name_at (self, clause, index));
    end loop;
  end validate_use_package_clause;

  procedure validate_package_renaming_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_package_renaming_declaration
      (self.ast_store, declaration);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, declaration));
    for index in 1 .. package_renaming_defining_name_count
      (self, declaration)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, package_renaming_defining_name_symbol_at
          (self, declaration, index));
      Adac.Compilation.Sources.validate_span
        (self, package_renaming_defining_name_span_at
          (self, declaration, index));
    end loop;
    validate_name (self, package_renaming_renamed_package (self, declaration));
  end validate_package_renaming_declaration;

  procedure validate_package_instantiation
    (self          : Context;
     instantiation : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_package_instantiation
      (self.ast_store, instantiation);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, instantiation));

    for index in 1 .. package_instantiation_defining_name_count
      (self, instantiation)
    loop
      Adac.Compilation.Symbols.validate_symbol
        (self, package_instantiation_defining_name_symbol_at
          (self, instantiation, index));
      Adac.Compilation.Sources.validate_span
        (self, package_instantiation_defining_name_span_at
          (self, instantiation, index));
    end loop;

    validate_name
      (self, package_instantiation_generic_name (self, instantiation));

    for index in 1 .. package_instantiation_actual_count (self, instantiation)
    loop
      if package_instantiation_actual_form_at (self, instantiation, index) =
         Adac.AST.Named_Generic_Actual_Form
      then
        Adac.Compilation.Symbols.validate_symbol
          (self, package_instantiation_actual_selector_symbol_at
            (self, instantiation, index));
        Adac.Compilation.Sources.validate_span
          (self, package_instantiation_actual_selector_span_at
            (self, instantiation, index));
      end if;
      declare
        actual : constant Adac.AST.Node_ID :=
          package_instantiation_actual_at (self, instantiation, index);
      begin
        case Adac.AST.kind_of (self.ast_store, actual) is
          when Adac.AST.String_Literal_Node =>
            validate_string_literal (self, actual);
          when others =>
            validate_name (self, actual);
        end case;
      end;
    end loop;
  end validate_package_instantiation;

  procedure validate_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_declaration (self.ast_store, declaration);

    case Adac.AST.kind_of (self.ast_store, declaration) is
      when Adac.AST.Object_Declaration_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self, Adac.AST.object_symbol (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.object_defining_span (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));
        validate_name
          (self, Adac.AST.object_subtype_mark (self.ast_store, declaration));
        if Adac.AST.object_has_index_constraint
          (self.ast_store, declaration)
        then
          validate_index_constraint
            (self,
             Adac.AST.object_index_constraint
               (self.ast_store, declaration));
        end if;
        if Adac.AST.object_has_initializer (self.ast_store, declaration) then
          validate_expression
            (self, Adac.AST.object_initializer (self.ast_store, declaration));
        end if;

      when Adac.AST.Object_Renaming_Declaration_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self, Adac.AST.object_renaming_symbol (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self,
           Adac.AST.object_renaming_defining_span
             (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));
        validate_name
          (self,
           Adac.AST.object_renaming_subtype_mark
             (self.ast_store, declaration));
        validate_name
          (self, Adac.AST.object_renaming_name (self.ast_store, declaration));

      when Adac.AST.Exception_Declaration_Node =>
        validate_exception_declaration (self, declaration);

      when Adac.AST.Number_Declaration_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self, Adac.AST.number_symbol (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.number_defining_span (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));
        validate_expression
          (self, Adac.AST.number_initializer (self.ast_store, declaration));

      when Adac.AST.Procedure_Declaration_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self,
           Adac.AST.procedure_declaration_symbol
             (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self,
           Adac.AST.procedure_declaration_defining_span
             (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));
        for index in
          1 .. procedure_declaration_parameter_count (self, declaration)
        loop
          validate_parameter
            (self,
             procedure_declaration_parameter_at
               (self, declaration, index));
        end loop;

      when Adac.AST.Procedure_Body_Stub_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self, procedure_body_stub_symbol (self, declaration));
        Adac.Compilation.Sources.validate_span
          (self, procedure_body_stub_defining_span (self, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));
        for index in 1 .. procedure_body_stub_parameter_count
          (self, declaration)
        loop
          validate_parameter
            (self, procedure_body_stub_parameter_at
               (self, declaration, index));
        end loop;

      when Adac.AST.Function_Declaration_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self,
           function_declaration_symbol (self, declaration));
        Adac.Compilation.Sources.validate_span
          (self, function_declaration_defining_span (self, declaration));
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));
        for index in
          1 .. function_declaration_parameter_count (self, declaration)
        loop
          validate_parameter
            (self,
             function_declaration_parameter_at
               (self, declaration, index));
        end loop;
        validate_name
          (self, function_declaration_result_subtype (self, declaration));
        if function_declaration_has_aspect (self, declaration) then
          validate_aspect_specification
            (self, function_declaration_aspect (self, declaration));
        end if;

      when Adac.AST.Private_Type_Declaration_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self, Adac.AST.private_type_symbol (self.ast_store, declaration));
        Adac.Compilation.Sources.validate_span
          (self,
           Adac.AST.private_type_defining_span
             (self.ast_store, declaration));
        for index in 1 .. private_type_discriminant_count
          (self, declaration)
        loop
          validate_discriminant_specification
            (self, private_type_discriminant_at (self, declaration, index));
        end loop;
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));

      when Adac.AST.Derived_Type_Declaration_Node =>
        validate_derived_type_declaration (self, declaration);

      when Adac.AST.Subtype_Declaration_Node =>
        validate_subtype_declaration (self, declaration);

      when Adac.AST.Record_Type_Declaration_Node =>
        validate_record_type_declaration (self, declaration);

      when Adac.AST.Access_Object_Type_Declaration_Node =>
        validate_access_object_type_declaration (self, declaration);

      when Adac.AST.Package_Renaming_Declaration_Node =>
        validate_package_renaming_declaration (self, declaration);

      when Adac.AST.Package_Instantiation_Node =>
        validate_package_instantiation (self, declaration);

      when Adac.AST.Package_Declaration_Node =>
        validate_package_declaration (self, declaration);

      when Adac.AST.Enumeration_Type_Declaration_Node =>
        Adac.Compilation.Symbols.validate_symbol
          (self, enumeration_type_symbol (self, declaration));
        Adac.Compilation.Sources.validate_span
          (self, enumeration_type_defining_span (self, declaration));
        for index in 1 .. enumeration_literal_count (self, declaration) loop
          Adac.Compilation.Symbols.validate_symbol
            (self, enumeration_literal_symbol_at (self, declaration, index));
          Adac.Compilation.Sources.validate_span
            (self, enumeration_literal_span_at (self, declaration, index));
        end loop;
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, declaration));

      when others =>
        raise Program_Error with
          "Adac.Compilation.Syntax: node is not a declaration";
    end case;
  end validate_declaration;

  procedure validate_package_declaration
    (self        : Context;
     declaration : Adac.AST.Node_ID)
  is
    pending : Adac.AST.Node_List;
    next    : Positive := 1;

    procedure validate_one (package_node : Adac.AST.Node_ID) is
      procedure validate_child (child : Adac.AST.Node_ID) is
      begin
        if kind_of (self, child) = Adac.AST.Package_Declaration_Node then
          Adac.AST.append (pending, child);
        else
          validate_declaration (self, child);
        end if;
      end validate_child;
    begin
      for index in 1 .. package_defining_name_count (self, package_node) loop
        Adac.Compilation.Symbols.validate_symbol
          (self, package_defining_name_symbol_at (self, package_node, index));
        Adac.Compilation.Sources.validate_span
          (self, package_defining_name_span_at (self, package_node, index));
      end loop;

      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, package_node));

      for index in 1 .. package_visible_declaration_count
        (self, package_node)
      loop
        validate_child
          (package_visible_declaration_at (self, package_node, index));
      end loop;

      if package_has_explicit_private_part (self, package_node) then
        Adac.Compilation.Sources.validate_span
          (self, package_private_part_span (self, package_node));
      end if;

      for index in 1 .. package_private_declaration_count
        (self, package_node)
      loop
        validate_child
          (package_private_declaration_at (self, package_node, index));
      end loop;

      for index in 1 .. package_end_name_count (self, package_node) loop
        Adac.Compilation.Symbols.validate_symbol
          (self, package_end_name_symbol_at (self, package_node, index));
        Adac.Compilation.Sources.validate_span
          (self, package_end_name_span_at (self, package_node, index));
      end loop;
    end validate_one;

  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_package_declaration
      (self.ast_store, declaration);
    Adac.AST.append (pending, declaration);

    while next <= Adac.AST.list_count (pending) loop
      validate_one (Adac.AST.list_element (pending, next));
      next := next + 1;
    end loop;
  end validate_package_declaration;

  procedure validate_package_body_stub
    (self : Context;
     stub : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_package_body_stub (self.ast_store, stub);
    Adac.Compilation.Symbols.validate_symbol
      (self, Adac.AST.package_body_stub_symbol (self.ast_store, stub));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.package_body_stub_defining_span (self.ast_store, stub));
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, stub));
  end validate_package_body_stub;

  procedure validate_package_body
    (self : Context;
     package_body : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_package_body (self.ast_store, package_body);

    for index in 1 .. package_body_defining_name_count (self, package_body) loop
      Adac.Compilation.Symbols.validate_symbol
        (self,
         package_body_defining_name_symbol_at (self, package_body, index));
      Adac.Compilation.Sources.validate_span
        (self,
         package_body_defining_name_span_at (self, package_body, index));
    end loop;

    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, package_body));

    for index in 1 .. package_body_declaration_count (self, package_body) loop
      declare
        declaration : constant Adac.AST.Node_ID :=
          package_body_declaration_at (self, package_body, index);
      begin
        case kind_of (self, declaration) is
          when Adac.AST.Procedure_Body_Node =>
            validate_procedure_body (self, declaration);
          when Adac.AST.Function_Body_Node =>
            validate_function_body (self, declaration);
          when Adac.AST.Use_Type_Clause_Node =>
            validate_use_type_clause (self, declaration);
          when Adac.AST.Use_Package_Clause_Node =>
            validate_use_package_clause (self, declaration);
          when Adac.AST.Package_Body_Stub_Node =>
            validate_package_body_stub (self, declaration);
          when others =>
            validate_declaration (self, declaration);
        end case;
      end;
    end loop;

    for index in 1 .. package_body_end_name_count (self, package_body) loop
      Adac.Compilation.Symbols.validate_symbol
        (self, package_body_end_name_symbol_at (self, package_body, index));
      Adac.Compilation.Sources.validate_span
        (self, package_body_end_name_span_at (self, package_body, index));
    end loop;
  end validate_package_body;

  procedure validate_procedure_body
    (self           : Context;
     procedure_body : Adac.AST.Node_ID)
  is
    pending : Adac.AST.Node_List;
    next    : Positive := 1;

    procedure validate_one (item : Adac.AST.Node_ID) is
    begin
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.procedure_symbol (self.ast_store, item));
      if Adac.AST.end_symbol (self.ast_store, item) /=
         Adac.Symbols.INVALID_SYMBOL_ID
      then
        Adac.Compilation.Symbols.validate_symbol
          (self, Adac.AST.end_symbol (self.ast_store, item));
      end if;
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, item));

      for index in 1 .. Adac.AST.parameter_count
        (self.ast_store, item)
      loop
        validate_parameter
          (self, Adac.AST.parameter_at (self.ast_store, item, index));
      end loop;

      for index in 1 .. Adac.AST.declaration_count
        (self.ast_store, item)
      loop
        declare
          declaration : constant Adac.AST.Node_ID :=
            Adac.AST.declaration_at (self.ast_store, item, index);
        begin
          case Adac.AST.kind_of (self.ast_store, declaration) is
            when Adac.AST.Object_Declaration_Node |
                 Adac.AST.Number_Declaration_Node |
                 Adac.AST.Object_Renaming_Declaration_Node |
                 Adac.AST.Procedure_Declaration_Node |
                 Adac.AST.Function_Declaration_Node |
                 Adac.AST.Enumeration_Type_Declaration_Node |
                 Adac.AST.Record_Type_Declaration_Node |
                 Adac.AST.Subtype_Declaration_Node |
                 Adac.AST.Package_Instantiation_Node =>
              validate_declaration (self, declaration);
            when Adac.AST.Use_Type_Clause_Node =>
              validate_use_type_clause (self, declaration);
            when Adac.AST.Use_Package_Clause_Node =>
              validate_use_package_clause (self, declaration);
            when Adac.AST.Procedure_Body_Node =>
              Adac.AST.append (pending, declaration);
            when Adac.AST.Function_Body_Node =>
              for function_index in 1 ..
                function_body_declaration_count (self, declaration)
              loop
                declare
                  function_declaration : constant Adac.AST.Node_ID :=
                    function_body_declaration_at
                      (self, declaration, function_index);
                begin
                  case kind_of (self, function_declaration) is
                    when Adac.AST.Object_Declaration_Node =>
                      validate_declaration (self, function_declaration);

                    when Adac.AST.Procedure_Body_Node =>
                      for nested_index in 1 ..
                        Adac.AST.declaration_count
                          (self.ast_store, function_declaration)
                      loop
                        declare
                          nested : constant Adac.AST.Node_ID :=
                            Adac.AST.declaration_at
                              (self.ast_store,
                               function_declaration,
                               nested_index);
                        begin
                          case kind_of (self, nested) is
                            when Adac.AST.Procedure_Body_Node |
                                 Adac.AST.Function_Body_Node =>
                              raise Program_Error with
                                "Adac.Compilation.Syntax: bounded " &
                                "procedure-owned function procedure contains " &
                                "a subprogram body";
                            when others =>
                              null;
                          end case;
                        end;
                      end loop;
                      validate_procedure_body (self, function_declaration);

                    when others =>
                      raise Program_Error with
                        "Adac.Compilation.Syntax: procedure-owned function " &
                        "has unsupported declarative item";
                  end case;
                end;
              end loop;
              validate_function_body (self, declaration);
            when others =>
              raise Program_Error with
                "Adac.Compilation.Syntax: invalid procedure declarative item";
          end case;
        end;
      end loop;

      validate_handled_sequence
        (self, Adac.AST.procedure_handled_sequence (self.ast_store, item));
    end validate_one;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_procedure_body
      (self.ast_store, procedure_body);
    Adac.AST.append (pending, procedure_body);

    while next <= Adac.AST.list_count (pending) loop
      validate_one (Adac.AST.list_element (pending, next));
      next := next + 1;
    end loop;
  end validate_procedure_body;

  procedure validate_subunit
    (self    : Context;
     subunit : Adac.AST.Node_ID)
  is
    proper_body : Adac.AST.Node_ID;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_subunit (self.ast_store, subunit);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, subunit));
    for index in 1 .. subunit_parent_name_count (self, subunit) loop
      Adac.Compilation.Symbols.validate_symbol
        (self, subunit_parent_name_symbol_at (self, subunit, index));
      Adac.Compilation.Sources.validate_span
        (self, subunit_parent_name_span_at (self, subunit, index));
    end loop;
    proper_body := subunit_proper_body (self, subunit);
    case kind_of (self, proper_body) is
      when Adac.AST.Procedure_Body_Node =>
        validate_procedure_body (self, proper_body);
      when Adac.AST.Function_Body_Node =>
        validate_function_body (self, proper_body);
      when Adac.AST.Package_Body_Node =>
        validate_package_body (self, proper_body);
      when others =>
        raise Program_Error with
          "Adac.Compilation.Syntax: invalid subunit proper body";
    end case;
  end validate_subunit;

  procedure validate_function_body
    (self          : Context;
     function_body : Adac.AST.Node_ID)
  is
    pending_functions : Adac.AST.Node_List;
    next_function     : Natural := 1;

    procedure validate_one (item : Adac.AST.Node_ID) is
    begin
      Adac.Compilation.Symbols.validate_symbol
        (self, Adac.AST.function_body_symbol (self.ast_store, item));
      if Adac.AST.function_body_has_end_designator (self.ast_store, item) then
        Adac.Compilation.Symbols.validate_symbol
          (self, Adac.AST.function_body_end_symbol (self.ast_store, item));
      end if;
      Adac.Compilation.Sources.validate_span
        (self, Adac.AST.node_span (self.ast_store, item));
      for index in 1 .. function_body_parameter_count (self, item) loop
        validate_parameter
          (self, function_body_parameter_at (self, item, index));
      end loop;
      validate_name (self, function_body_result_subtype (self, item));
      for index in 1 .. function_body_declaration_count (self, item) loop
        declare
          declaration : constant Adac.AST.Node_ID :=
            function_body_declaration_at (self, item, index);
        begin
          case Adac.AST.kind_of (self.ast_store, declaration) is
            when Adac.AST.Procedure_Body_Node =>
              validate_procedure_body (self, declaration);
            when Adac.AST.Function_Body_Node =>
              Adac.AST.append (pending_functions, declaration);
            when others =>
              validate_declaration (self, declaration);
          end case;
        end;
      end loop;
      validate_handled_sequence
        (self, function_body_handled_sequence (self, item));
    end validate_one;
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate_function_body (self.ast_store, function_body);
    Adac.AST.append (pending_functions, function_body);
    while next_function <= Adac.AST.list_count (pending_functions) loop
      validate_one
        (Adac.AST.list_element (pending_functions, next_function));
      next_function := next_function + 1;
    end loop;
  end validate_function_body;

  procedure validate
    (self : Context;
     root : Adac.AST.Node_ID)
  is
  begin
    Adac.Compilation.validate (self);
    Adac.AST.Validation.validate (self.ast_store, root);
    Adac.Compilation.Sources.validate_span
      (self, Adac.AST.node_span (self.ast_store, root));

    for item_index in 1 .. Adac.AST.context_item_count (self.ast_store, root)
    loop
      declare
        item : constant Adac.AST.Node_ID :=
          Adac.AST.context_item_at (self.ast_store, root, item_index);
      begin
        Adac.Compilation.Sources.validate_span
          (self, Adac.AST.node_span (self.ast_store, item));

        for name_index in 1 ..
          Adac.AST.with_clause_name_count (self.ast_store, item)
        loop
          validate_name
            (self,
             Adac.AST.with_clause_name_at
               (self.ast_store, item, name_index));
        end loop;
      end;
    end loop;

    declare
      item : constant Adac.AST.Node_ID :=
        Adac.AST.unit_item (self.ast_store, root);
    begin
      case Adac.AST.kind_of (self.ast_store, item) is
        when Adac.AST.Subunit_Node =>
          validate_subunit (self, item);
        when Adac.AST.Procedure_Body_Node =>
          validate_procedure_body (self, item);
        when Adac.AST.Package_Renaming_Declaration_Node =>
          validate_package_renaming_declaration (self, item);
        when Adac.AST.Package_Instantiation_Node =>
          validate_package_instantiation (self, item);
        when Adac.AST.Package_Declaration_Node =>
          validate_package_declaration (self, item);
        when Adac.AST.Package_Body_Node =>
          validate_package_body (self, item);
        when others =>
          raise Program_Error with
            "Adac.Compilation.Syntax: invalid unit item";
      end case;
    end;
  end validate;

end Adac.Compilation.Syntax;
