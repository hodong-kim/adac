-- ============================================================================
-- adac-ast-testing.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

package body Adac.AST.Testing is

  function append_statement_unchecked
    (self : in out Store;
     kind : Node_Kind;
     span : Adac.Source.Span)
  return Node_ID is
  begin
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
           Short_Circuit_Expression_Node |
           Logical_Expression_Node |
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
        raise Program_Error with
          "Adac.AST.Testing: invalid statement node kind";
    end case;

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_statement_unchecked;

  function append_exception_handler_unchecked
    (self                    : in out Store;
     choices                 : Node_List;
     statements              : Node_List;
     span                    : Adac.Source.Span;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID :=
       Adac.Symbols.INVALID_SYMBOL_ID;
     choice_parameter_span   : Adac.Source.Span := Adac.Source.INVALID_SPAN)
  return Node_ID is
  begin
    self.nodes.append
      (Node'
        (kind => Exception_Handler_Node,
         span => span,
         exception_handler_choice_parameter_symbol_value =>
           choice_parameter_symbol,
         exception_handler_choice_parameter_span_value => choice_parameter_span,
         exception_handler_choices_value => choices.nodes,
         exception_handler_statements_value => statements.nodes));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_exception_handler_unchecked;

  function append_handled_sequence_unchecked
    (self       : in out Store;
     statements : Node_List;
     handlers   : Node_List;
     span       : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'
        (kind                               => Handled_Sequence_Node,
         span                               => span,
         handled_sequence_statements_value => statements.nodes,
         handled_sequence_handlers_value   => handlers.nodes));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_handled_sequence_unchecked;

  function append_elsif_part_unchecked
    (self       : in out Store;
     condition  : Node_ID;
     statements : Node_List;
     span       : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'
        (kind                   => Elsif_Part_Node,
         span                   => span,
         elsif_condition_value  => condition,
         elsif_statements_value => statements.nodes));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_elsif_part_unchecked;

  function append_if_statement_unchecked
    (self            : in out Store;
     condition       : Node_ID;
     then_statements : Node_List;
     elsif_parts     : Node_List;
     else_statements : Node_List;
     span            : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'
        (kind                     => If_Statement_Node,
         span                     => span,
         if_condition_value       => condition,
         if_then_statements_value => then_statements.nodes,
         if_elsif_parts_value     => elsif_parts.nodes,
         if_else_statements_value => else_statements.nodes));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_if_statement_unchecked;

  function append_procedure_call_unchecked
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Node_List;
     span          : Adac.Source.Span)
  return Node_ID is
    associations : Procedure_Call_Actual_Association_Vectors.Vector;
  begin
    for actual of actuals.nodes loop
      associations.append
        (Procedure_Call_Actual_Association'
          (form     => Positional_Procedure_Call_Actual_Form,
           selector => INVALID_NODE_ID,
           actual   => actual));
    end loop;

    self.nodes.append
      (Node'
        (kind                               => Procedure_Call_Statement_Node,
         span                               => span,
         procedure_call_callable_name_value => callable_name,
         procedure_call_actuals_value       => associations));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_procedure_call_unchecked;

  function append_string_literal_unchecked
    (self     : in out Store;
     spelling : String;
     span     : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind            => String_Literal_Node,
             span            => span,
             string_spelling =>
               Ada.Strings.Unbounded.to_unbounded_string (spelling)));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_string_literal_unchecked;

  function append_binary_adding_unchecked
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'
        (kind                                  => Binary_Adding_Node,
         span                                  => span,
         binary_adding_left_operand_value      => left_operand,
         binary_adding_operator_spelling_value =>
           Ada.Strings.Unbounded.to_unbounded_string (operator_spelling),
         binary_adding_operator_span_value     => operator_span,
         binary_adding_right_operand_value     => right_operand));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_binary_adding_unchecked;

  function append_relation_unchecked
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'
        (kind                             => Relation_Node,
         span                             => span,
         relation_left_operand_value      => left_operand,
         relation_operator_spelling_value =>
           Ada.Strings.Unbounded.to_unbounded_string (operator_spelling),
         relation_operator_span_value     => operator_span,
         relation_right_operand_value     => right_operand));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_relation_unchecked;

  function append_parameter_specification_unchecked
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     mode               : Parameter_Mode_Kind;
     subtype_mark       : Node_ID;
     span               : Adac.Source.Span;
     default_expression : Node_ID := INVALID_NODE_ID)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind                               => Parameter_Specification_Node,
             span                               => span,
             parameter_symbol_value             => symbol,
             parameter_defining_span_value      => defining_span,
             parameter_additional_defining_names_index_value => 0,
             parameter_mode_value               => mode,
             parameter_subtype_mark_value       => subtype_mark,
             parameter_default_expression_value => default_expression));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_parameter_specification_unchecked;

  function append_object_declaration_unchecked
    (self          : in out Store;
     form          : Object_Declaration_Form;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     initializer   : Node_ID;
     span          : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind                       => Object_Declaration_Node,
             span                       => span,
             object_form_value          => form,
             object_symbol_value        => symbol,
             object_defining_span_value => defining_span,
             object_subtype_mark_value  => subtype_mark,
             object_index_constraint_value => INVALID_NODE_ID,
             object_initializer_value   => initializer));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_object_declaration_unchecked;

  function append_number_declaration_unchecked
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Node_ID;
     span          : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind                       => Number_Declaration_Node,
             span                       => span,
             number_symbol_value        => symbol,
             number_defining_span_value => defining_span,
             number_initializer_value   => initializer));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_number_declaration_unchecked;

  function append_procedure_declaration_unchecked
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind => Procedure_Declaration_Node,
             span => span,
             procedure_declaration_symbol_value => symbol,
             procedure_declaration_defining_span_value => defining_span,
             procedure_declaration_parameters_value => parameters.nodes));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_procedure_declaration_unchecked;

  function append_package_declaration_unchecked
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     declarations  : Node_List;
     end_name      : Program_Unit_Name;
     span          : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind                        => Package_Declaration_Node,
             span                        => span,
             package_defining_name_value        => defining_name.components,
             package_visible_declarations_value => declarations.nodes,
             package_private_part_span_value    => Adac.Source.INVALID_SPAN,
             package_private_declarations_value => Node_Vectors.Empty_Vector,
             package_end_name_value             => end_name.components));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_package_declaration_unchecked;

  function append_with_clause_unchecked
    (self  : in out Store;
     names : Node_List;
     span  : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind          => With_Clause_Node,
             span          => span,
             library_names => names.nodes));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_with_clause_unchecked;

  function append_procedure_body_unchecked
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     parameters       : Node_List;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind                             => Procedure_Body_Node,
             span                             => span,
             procedure_symbol                 => procedure_symbol,
             parameters                       => parameters.nodes,
             declarations                     => declarations.nodes,
             procedure_handled_sequence_value => handled_sequence,
             end_symbol                       => end_symbol));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_procedure_body_unchecked;

  function append_compilation_unit_unchecked
    (self          : in out Store;
     context_items : Node_List;
     unit_item     : Node_ID;
     span          : Adac.Source.Span)
  return Node_ID is
  begin
    self.nodes.append
      (Node'(kind          => Compilation_Unit_Node,
             span          => span,
             context_items => context_items.nodes,
             unit_item_value => unit_item));
    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length));
  end append_compilation_unit_unchecked;

end Adac.AST.Testing;
