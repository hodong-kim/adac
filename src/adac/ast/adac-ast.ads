-- ============================================================================
-- adac-ast.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with Adac.Source;
with Adac.Symbols;

package Adac.AST is

  type Node_ID is private;

  INVALID_NODE_ID : constant Node_ID;

  type Node_Kind is
    (Compilation_Unit_Node,
     Subunit_Node,
     Procedure_Body_Node,
     Function_Body_Node,
     With_Clause_Node,
     Use_Type_Clause_Node,
     Use_Package_Clause_Node,
     Null_Statement_Node,
     Exit_Statement_Node,
     Return_Statement_Node,
     Extended_Return_Statement_Node,
     Raise_Statement_Node,
     Assignment_Statement_Node,
     Case_Alternative_Node,
     Case_Range_Choice_Node,
     Others_Case_Choice_Node,
     Case_Statement_Node,
     Block_Statement_Node,
     Loop_Statement_Node,
     Procedure_Call_Statement_Node,
     If_Statement_Node,
     Elsif_Part_Node,
     Others_Exception_Choice_Node,
     Exception_Handler_Node,
     Handled_Sequence_Node,
     Numeric_Literal_Node,
     Character_Literal_Node,
     String_Literal_Node,
     Null_Literal_Node,
     Record_Aggregate_Node,
     Array_Aggregate_Node,
     Bracket_Aggregate_Node,
     Qualified_Expression_Node,
     Allocator_Node,
     If_Expression_Node,
     Case_Expression_Alternative_Node,
     Case_Expression_Node,
     Raise_Expression_Node,
     Parenthesized_Expression_Node,
     Unary_Operator_Node,
     Binary_Exponentiating_Node,
     Binary_Multiplying_Node,
     Binary_Adding_Node,
     Relation_Node,
     Membership_Range_Choice_Node,
     Membership_Expression_Node,
     Logical_Expression_Node,
     Short_Circuit_Expression_Node,
     Identifier_Name_Node,
     Selected_Name_Node,
     Explicit_Dereference_Name_Node,
     Selected_Component_Node,
     Parenthesized_Name_Node,
     Slice_Name_Node,
     Attribute_Name_Node,
     Aspect_Specification_Node,
     Parameter_Specification_Node,
     Object_Declaration_Node,
     Object_Renaming_Declaration_Node,
     Number_Declaration_Node,
     Exception_Declaration_Node,
     Procedure_Declaration_Node,
     Procedure_Body_Stub_Node,
     Function_Declaration_Node,
     Private_Type_Declaration_Node,
     Derived_Type_Declaration_Node,
     Range_Constraint_Node,
     Index_Constraint_Node,
     Subtype_Declaration_Node,
     Enumeration_Type_Declaration_Node,
     Discriminant_Specification_Node,
     Record_Component_Declaration_Node,
     Record_Variant_Node,
     Record_Variant_Part_Node,
     Record_Type_Declaration_Node,
     Access_Object_Type_Declaration_Node,
     Package_Renaming_Declaration_Node,
     Package_Instantiation_Node,
     Package_Declaration_Node,
     Package_Body_Stub_Node,
     Package_Body_Node);

  type Numeric_Literal_Kind is
    (Decimal_Integer_Form,
     Decimal_Real_Form,
     Based_Integer_Form,
     Based_Real_Form);

  type Membership_Operator_Kind is
    (In_Membership_Operator,
     Not_In_Membership_Operator);

  type Generic_Actual_Association_Form is
    (Positional_Generic_Actual_Form,
     Named_Generic_Actual_Form);

  type Parenthesized_Name_Item_Form is
    (Positional_Parenthesized_Name_Item_Form,
     Named_Parenthesized_Name_Item_Form);

  type Procedure_Call_Actual_Association_Form is
    (Positional_Procedure_Call_Actual_Form,
     Named_Procedure_Call_Actual_Form);

  type Logical_Operator_Kind is
    (And_Logical_Operator,
     Or_Logical_Operator,
     Xor_Logical_Operator);

  type Short_Circuit_Operator_Kind is
    (And_Then_Short_Circuit_Operator,
     Or_Else_Short_Circuit_Operator);

  type Loop_Statement_Form is
    (Discrete_Range_Loop_Form,
     Range_Attribute_Loop_Form,
     Generalized_Iterator_Loop_Form,
     While_Loop_Form,
     Simple_Loop_Form);

  type Parameter_Mode_Kind is
    (Default_In_Parameter_Mode,
     Explicit_In_Parameter_Mode,
     In_Out_Parameter_Mode,
     Out_Parameter_Mode);

  type Object_Declaration_Form is
    (Variable_Object_Form,
     Constant_Object_Form);

  type General_Access_Modifier_Kind is
    (No_General_Access_Modifier,
     All_General_Access_Modifier,
     Constant_General_Access_Modifier);

  type Raise_Statement_Form is
    (Bare_Reraise_Form,
     Named_With_Message_Raise_Form);

  type Node_List is private;
  type Parenthesized_Name_Item_List is private;
  type Procedure_Call_Actual_Association_List is private;
  type Program_Unit_Name is private;
  type Defining_Identifier_List is private;
  type Enumeration_Literal_List is private;
  type Record_Component_Association_List is private;
  type Array_Component_Association_List is private;
  type Generic_Actual_Association_List is private;

  --! summary: Append one node identifier to a temporary node list.
  procedure append
    (self : in out Node_List;
     node : Node_ID);

  --! summary: Return the number of identifiers in a temporary node list.
  function list_count (self : Node_List) return Natural;

  --! summary: Return one identifier from a temporary node list.
  function list_element
    (self  : Node_List;
     index : Positive)
  return Node_ID;

  --! summary: Append one positional parenthesized-name item.
  procedure append
    (self   : in out Parenthesized_Name_Item_List;
     actual : Node_ID);

  --! summary: Append one named parenthesized-name item.
  procedure append
    (self     : in out Parenthesized_Name_Item_List;
     selector : Node_ID;
     actual   : Node_ID);

  function parenthesized_name_item_list_count
    (self : Parenthesized_Name_Item_List)
  return Natural;

  function parenthesized_name_item_list_form
    (self  : Parenthesized_Name_Item_List;
     index : Positive)
  return Parenthesized_Name_Item_Form;

  function parenthesized_name_item_list_selector
    (self  : Parenthesized_Name_Item_List;
     index : Positive)
  return Node_ID;

  function parenthesized_name_item_list_actual
    (self  : Parenthesized_Name_Item_List;
     index : Positive)
  return Node_ID;

  --! summary: Append one positional procedure-call actual association.
  procedure append
    (self   : in out Procedure_Call_Actual_Association_List;
     actual : Node_ID);

  --! summary: Append one named procedure-call actual association.
  procedure append
    (self     : in out Procedure_Call_Actual_Association_List;
     selector : Node_ID;
     actual   : Node_ID);

  function procedure_call_actual_association_list_count
    (self : Procedure_Call_Actual_Association_List)
  return Natural;

  function procedure_call_actual_association_list_form
    (self  : Procedure_Call_Actual_Association_List;
     index : Positive)
  return Procedure_Call_Actual_Association_Form;

  function procedure_call_actual_association_list_selector
    (self  : Procedure_Call_Actual_Association_List;
     index : Positive)
  return Node_ID;

  function procedure_call_actual_association_list_actual
    (self  : Procedure_Call_Actual_Association_List;
     index : Positive)
  return Node_ID;

  --! summary: Append one identifier component to a program-unit name.
  procedure append
    (self   : in out Program_Unit_Name;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span);

  --! summary: Return the number of program-unit-name components.
  function program_unit_name_component_count
    (self : Program_Unit_Name)
  return Natural;

  --! summary: Return one program-unit-name component symbol.
  function program_unit_name_component_symbol
    (self  : Program_Unit_Name;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one program-unit-name component span.
  function program_unit_name_component_span
    (self  : Program_Unit_Name;
     index : Positive)
  return Adac.Source.Span;

  --! summary: Append one defining identifier to a temporary identifier list.
  procedure append
    (self   : in out Defining_Identifier_List;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span);

  --! summary: Return the number of defining identifiers in a temporary list.
  function defining_identifier_list_count
    (self : Defining_Identifier_List)
  return Natural;

  --! summary: Return one temporary defining-identifier symbol.
  function defining_identifier_list_symbol
    (self  : Defining_Identifier_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one temporary defining-identifier span.
  function defining_identifier_list_span
    (self  : Defining_Identifier_List;
     index : Positive)
  return Adac.Source.Span;

  --! summary: Append one identifier enumeration literal definition.
  procedure append
    (self   : in out Enumeration_Literal_List;
     symbol : Adac.Symbols.Symbol_ID;
     span   : Adac.Source.Span);

  --! summary: Return the number of temporary enumeration literals.
  function enumeration_literal_list_count
    (self : Enumeration_Literal_List)
  return Natural;

  --! summary: Return one temporary enumeration literal symbol.
  function enumeration_literal_list_symbol
    (self  : Enumeration_Literal_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one temporary enumeration literal span.
  function enumeration_literal_list_span
    (self  : Enumeration_Literal_List;
     index : Positive)
  return Adac.Source.Span;

  --! summary: Append one temporary named record-component association.
  procedure append
    (self          : in out Record_Component_Association_List;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     expression    : Node_ID);

  --! summary: Return the number of temporary record-component associations.
  function record_component_association_list_count
    (self : Record_Component_Association_List)
  return Natural;

  function record_component_association_list_selector_symbol
    (self  : Record_Component_Association_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  function record_component_association_list_selector_span
    (self  : Record_Component_Association_List;
     index : Positive)
  return Adac.Source.Span;

  function record_component_association_list_expression
    (self  : Record_Component_Association_List;
     index : Positive)
  return Node_ID;

  --! summary: Append one temporary named array-component association.
  procedure append
    (self       : in out Array_Component_Association_List;
     choices    : Node_List;
     expression : Node_ID);

  --! summary: Return the number of temporary array-component associations.
  function array_component_association_list_count
    (self : Array_Component_Association_List)
  return Natural;

  function array_component_association_list_choice_count
    (self  : Array_Component_Association_List;
     index : Positive)
  return Natural;

  function array_component_association_list_choice
    (self              : Array_Component_Association_List;
     association_index : Positive;
     choice_index      : Positive)
  return Node_ID;

  function array_component_association_list_expression
    (self  : Array_Component_Association_List;
     index : Positive)
  return Node_ID;

  --! summary: Append one temporary positional generic actual association.
  procedure append
    (self   : in out Generic_Actual_Association_List;
     actual : Node_ID);

  --! summary: Append one temporary named generic actual association.
  procedure append
    (self          : in out Generic_Actual_Association_List;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     actual        : Node_ID);

  function generic_actual_association_list_form
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Generic_Actual_Association_Form;

  function generic_actual_association_list_count
    (self : Generic_Actual_Association_List)
  return Natural;

  function generic_actual_association_list_selector_symbol
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  function generic_actual_association_list_selector_span
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Adac.Source.Span;

  function generic_actual_association_list_actual
    (self  : Generic_Actual_Association_List;
     index : Positive)
  return Node_ID;

  type Store is limited private;

  --! summary: Create an empty append-only AST store.
  --! ownership: The returned store owns every node subsequently appended.
  function create return Store;

  --! summary: Return the number of nodes owned by the store.
  function node_count (self : Store) return Natural;

  --! summary: Return the concrete kind of a node owned by the store.
  function kind_of
    (self : Store;
     node : Node_ID)
  return Node_Kind;

  --! summary: Return the source span of a node owned by the store.
  function node_span
    (self : Store;
     node : Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether a handler has a choice parameter.
  function exception_handler_has_choice_parameter
    (self    : Store;
     handler : Node_ID)
  return Boolean;

  --! summary: Return the optional choice-parameter defining symbol.
  function exception_handler_choice_parameter_symbol
    (self    : Store;
     handler : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the optional choice-parameter defining span.
  function exception_handler_choice_parameter_span
    (self    : Store;
     handler : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the exception-choice count of a handler.
  function exception_handler_choice_count
    (self    : Store;
     handler : Node_ID)
  return Natural;

  --! summary: Return one exception choice of a handler.
  function exception_handler_choice_at
    (self    : Store;
     handler : Node_ID;
     index   : Positive)
  return Node_ID;

  --! summary: Return the statement count of an exception handler.
  function exception_handler_statement_count
    (self    : Store;
     handler : Node_ID)
  return Natural;

  --! summary: Return one body statement of an exception handler.
  function exception_handler_statement_at
    (self    : Store;
     handler : Node_ID;
     index   : Positive)
  return Node_ID;

  --! summary: Return the ordinary statement count of a handled sequence.
  function handled_sequence_statement_count
    (self     : Store;
     sequence : Node_ID)
  return Natural;

  --! summary: Return one ordinary statement of a handled sequence.
  function handled_sequence_statement_at
    (self     : Store;
     sequence : Node_ID;
     index    : Positive)
  return Node_ID;

  --! summary: Return the handler count of a handled sequence.
  function handled_sequence_handler_count
    (self     : Store;
     sequence : Node_ID)
  return Natural;

  --! summary: Return one exception handler of a handled sequence.
  function handled_sequence_handler_at
    (self     : Store;
     sequence : Node_ID;
     index    : Positive)
  return Node_ID;

  --! summary: Return the condition expression of an if statement.
  function if_condition
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the condition expression of one elsif part.
  function elsif_condition
    (self : Store;
     part : Node_ID)
  return Node_ID;

  --! summary: Return the statement count of one elsif part.
  function elsif_statement_count
    (self : Store;
     part : Node_ID)
  return Natural;

  --! summary: Return one statement of an elsif part.
  function elsif_statement_at
    (self  : Store;
     part  : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the then-branch statement count of an if statement.
  function if_then_statement_count
    (self      : Store;
     statement : Node_ID)
  return Natural;

  --! summary: Return one then-branch statement of an if statement.
  function if_then_statement_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the elsif-part count of an if statement.
  function if_elsif_part_count
    (self      : Store;
     statement : Node_ID)
  return Natural;

  --! summary: Return one elsif part of an if statement.
  function if_elsif_part_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the else-branch statement count of an if statement.
  function if_else_statement_count
    (self      : Store;
     statement : Node_ID)
  return Natural;

  --! summary: Return one else-branch statement of an if statement.
  function if_else_statement_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return whether an exit statement names its target loop.
  function exit_has_loop_name
    (self      : Store;
     statement : Node_ID)
  return Boolean;

  --! summary: Return the optional loop-name symbol of an exit statement.
  function exit_loop_name_symbol
    (self      : Store;
     statement : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the optional loop-name span of an exit statement.
  function exit_loop_name_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether an exit statement carries a when condition.
  function exit_has_condition
    (self      : Store;
     statement : Node_ID)
  return Boolean;

  --! summary: Return the optional when-token span of an exit statement.
  function exit_when_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the optional condition of an exit statement.
  function exit_condition
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return whether a return statement carries an expression.
  function return_has_expression
    (self      : Store;
     statement : Node_ID)
  return Boolean;

  --! summary: Return the expression carried by a return statement.
  function return_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of an extended return.
  function extended_return_symbol
    (self      : Store;
     statement : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of an extended return.
  function extended_return_defining_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the subtype mark of an extended return.
  function extended_return_subtype_mark
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the handled sequence owned by an extended return.
  function extended_return_handled_sequence
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the source form of a raise statement.
  function raise_form
    (self      : Store;
     statement : Node_ID)
  return Raise_Statement_Form;

  --! summary: Return the exception name of a raise statement.
  function raise_exception_name
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the message string of a raise statement.
  function raise_message_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the target name of an assignment statement.
  function assignment_target
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the RHS expression of an assignment statement.
  function assignment_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the discrete-choice count of a case alternative.
  function case_alternative_choice_count
    (self        : Store;
     alternative : Node_ID)
  return Natural;

  --! summary: Return one discrete choice of a case alternative.
  function case_alternative_choice_at
    (self        : Store;
     alternative : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the lower bound of an explicit case range choice.
  function case_range_choice_lower_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID;

  --! summary: Return the exact `..` span of an explicit case range choice.
  function case_range_choice_range_span
    (self   : Store;
     choice : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the upper bound of an explicit case range choice.
  function case_range_choice_upper_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID;

  --! summary: Return the statement count of a case alternative.
  function case_alternative_statement_count
    (self        : Store;
     alternative : Node_ID)
  return Natural;

  --! summary: Return one statement of a case alternative.
  function case_alternative_statement_at
    (self        : Store;
     alternative : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the selecting expression of a case statement.
  function case_selecting_expression
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the alternative count of a case statement.
  function case_alternative_count
    (self      : Store;
     statement : Node_ID)
  return Natural;

  --! summary: Return one alternative of a case statement.
  function case_alternative_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the declaration count of a block statement.
  function block_declaration_count
    (self      : Store;
     statement : Node_ID)
  return Natural;

  --! summary: Return one declaration of a block statement.
  function block_declaration_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the handled sequence of a block statement.
  function block_handled_sequence
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the source form of a represented loop statement.
  function loop_form
    (self      : Store;
     statement : Node_ID)
  return Loop_Statement_Form;

  --! summary: Return the represented condition of a `while` loop.
  function loop_condition
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of a represented `for` loop parameter.
  function loop_parameter_symbol
    (self      : Store;
     statement : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a represented `for` loop parameter.
  function loop_parameter_span
    (self      : Store;
     statement : Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether a represented `for` loop uses `reverse`.
  function loop_is_reverse
    (self      : Store;
     statement : Node_ID)
  return Boolean;

  --! summary: Return the iterable name of an iterator loop.
  function loop_iterable_name
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the `Range` attribute name of a range-attribute loop.
  function loop_range_attribute
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the lower bound of an ordinary discrete-range loop.
  function loop_range_lower_bound
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the upper bound of an ordinary discrete-range loop.
  function loop_range_upper_bound
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the body-statement count of a represented loop.
  function loop_statement_count
    (self      : Store;
     statement : Node_ID)
  return Natural;

  --! summary: Return one body statement of a represented loop.
  function loop_statement_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the callable name of a procedure-call statement.
  function procedure_call_callable_name
    (self      : Store;
     statement : Node_ID)
  return Node_ID;

  --! summary: Return the actual-association count of a procedure call.
  function procedure_call_actual_count
    (self      : Store;
     statement : Node_ID)
  return Natural;

  --! summary: Return one procedure-call actual association form.
  function procedure_call_actual_form
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Procedure_Call_Actual_Association_Form;

  --! summary: Return the selector of one named procedure-call actual.
  function procedure_call_actual_selector_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return one procedure-call actual expression.
  function procedure_call_actual_at
    (self      : Store;
     statement : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the lexical form of a numeric-literal node.
  function numeric_literal_form
    (self    : Store;
     literal : Node_ID)
  return Numeric_Literal_Kind;

  --! summary: Return the exact source spelling of a numeric-literal node.
  function numeric_literal_spelling
    (self    : Store;
     literal : Node_ID)
  return String;

  --! summary: Return the exact source spelling of a character-literal node.
  function character_literal_spelling
    (self    : Store;
     literal : Node_ID)
  return String;

  --! summary: Return the exact source spelling of a string-literal node.
  function string_literal_spelling
    (self    : Store;
     literal : Node_ID)
  return String;

  --! summary: Return the number of named associations in a record aggregate.
  function record_aggregate_association_count
    (self      : Store;
     aggregate : Node_ID)
  return Natural;

  --! summary: Return one record-aggregate association selector symbol.
  function record_aggregate_selector_symbol_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one record-aggregate association selector span.
  function record_aggregate_selector_span_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Adac.Source.Span;

  --! summary: Return one record-aggregate association value expression.
  function record_aggregate_expression_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the number of associations in a named array aggregate.
  function array_aggregate_association_count
    (self      : Store;
     aggregate : Node_ID)
  return Natural;

  --! summary: Return the number of choices in one array association.
  function array_aggregate_choice_count
    (self              : Store;
     aggregate         : Node_ID;
     association_index : Positive)
  return Natural;

  --! summary: Return one represented array-association choice expression.
  function array_aggregate_choice_at
    (self              : Store;
     aggregate         : Node_ID;
     association_index : Positive;
     choice_index      : Positive)
  return Node_ID;

  --! summary: Return one named array-association value expression.
  function array_aggregate_expression_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the number of elements in a bracket aggregate.
  function bracket_aggregate_expression_count
    (self      : Store;
     aggregate : Node_ID)
  return Natural;

  --! summary: Return one positional bracket-aggregate expression.
  function bracket_aggregate_expression_at
    (self      : Store;
     aggregate : Node_ID;
     index     : Positive)
  return Node_ID;

  --! summary: Return the subtype-mark qualifier of a qualified expression.
  function qualified_expression_subtype_mark
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the operand of a qualified expression.
  function qualified_expression_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the exact `new` keyword span of an allocator.
  function allocator_new_span
    (self      : Store;
     allocator : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the qualified expression allocated by an allocator.
  function allocator_expression
    (self      : Store;
     allocator : Node_ID)
  return Node_ID;

  --! summary: Return the condition of a current if expression.
  function if_expression_condition
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the then-dependent expression.
  function if_expression_then_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the else-dependent expression.
  function if_expression_else_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the selecting expression of a current case expression.
  function case_expression_selecting_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the number of ordered case-expression alternatives.
  function case_expression_alternative_count
    (self       : Store;
     expression : Node_ID)
  return Natural;

  --! summary: Return one ordered case-expression alternative.
  function case_expression_alternative_at
    (self       : Store;
     expression : Node_ID;
     index      : Positive)
  return Node_ID;

  --! summary: Return the number of choices in one case-expression alternative.
  function case_expression_alternative_choice_count
    (self        : Store;
     alternative : Node_ID)
  return Natural;

  --! summary: Return one ordered case-expression choice.
  function case_expression_alternative_choice_at
    (self        : Store;
     alternative : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the dependent expression of one case alternative.
  function case_expression_alternative_expression
    (self        : Store;
     alternative : Node_ID)
  return Node_ID;

  --! summary: Return the exception name of a raise expression.
  function raise_expression_exception_name
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return whether a raise expression has a message.
  function raise_expression_has_message
    (self       : Store;
     expression : Node_ID)
  return Boolean;

  --! summary: Return the optional message expression or `INVALID_NODE_ID`.
  function raise_expression_message
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the child of a parenthesized expression.
  function parenthesized_expression_child
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the exact unary operator spelling.
  function unary_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String;

  function unary_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  function unary_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the exact exponentiating operator spelling.
  function binary_exponentiating_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String;

  function binary_exponentiating_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  function binary_exponentiating_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  function binary_exponentiating_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the exact binary-multiplying operator spelling.
  function binary_multiplying_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String;

  function binary_multiplying_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  function binary_multiplying_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  function binary_multiplying_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  function binary_adding_operator_spelling
    (self       : Store;
     expression : Node_ID)
  return String;

  --! summary: Return the binary-adding operator token span.
  function binary_adding_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the left operand of a binary-adding node.
  function binary_adding_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the right operand of a binary-adding node.
  function binary_adding_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the exact relational-operator spelling.
  function relation_operator_spelling
    (self     : Store;
     relation : Node_ID)
  return String;

  --! summary: Return the relational-operator token span.
  function relation_operator_span
    (self     : Store;
     relation : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the left operand of a relation node.
  function relation_left_operand
    (self     : Store;
     relation : Node_ID)
  return Node_ID;

  --! summary: Return the right operand of a relation node.
  function relation_right_operand
    (self     : Store;
     relation : Node_ID)
  return Node_ID;

  --! summary: Return the lower bound of an explicit membership range choice.
  function membership_range_choice_lower_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID;

  --! summary: Return the exact `..` span of an explicit membership range.
  function membership_range_choice_range_span
    (self   : Store;
     choice : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the upper bound of an explicit membership range choice.
  function membership_range_choice_upper_bound
    (self   : Store;
     choice : Node_ID)
  return Node_ID;

  --! summary: Return the tested operand of a membership expression.
  function membership_tested_expression
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the source form of a membership operator.
  function membership_operator
    (self       : Store;
     expression : Node_ID)
  return Membership_Operator_Kind;

  --! summary: Return the optional `not` token span of a membership expression.
  function membership_not_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the `in` token span of a membership expression.
  function membership_in_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the membership-choice count.
  function membership_choice_count
    (self       : Store;
     expression : Node_ID)
  return Natural;

  --! summary: Return one represented membership choice.
  function membership_choice_at
    (self       : Store;
     expression : Node_ID;
     index      : Positive)
  return Node_ID;

  --! summary: Return the operator of a logical expression.
  function logical_operator
    (self       : Store;
     expression : Node_ID)
  return Logical_Operator_Kind;

  function logical_operator_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  function logical_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  function logical_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  function short_circuit_operator
    (self       : Store;
     expression : Node_ID)
  return Short_Circuit_Operator_Kind;

  --! summary: Return the first reserved-word token span.
  function short_circuit_operator_first_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the second reserved-word token span.
  function short_circuit_operator_second_span
    (self       : Store;
     expression : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the left operand of a short-circuit expression.
  function short_circuit_left_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the right operand of a short-circuit expression.
  function short_circuit_right_operand
    (self       : Store;
     expression : Node_ID)
  return Node_ID;

  --! summary: Return the symbol of an identifier-name node.
  function identifier_symbol
    (self : Store;
     name : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the prefix of a composite current name.
  function name_prefix
    (self : Store;
     name : Node_ID)
  return Node_ID;

  --! summary: Return the exact `all` token span of an explicit dereference.
  function explicit_dereference_all_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the selector symbol of a selector-bearing name node.
  function selector_symbol
    (self : Store;
     name : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the selector source span of a selector-bearing name node.
  function selector_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the item count of a parenthesized-name node.
  function parenthesized_item_count
    (self : Store;
     name : Node_ID)
  return Natural;

  --! summary: Return one item of a parenthesized-name node.
  function parenthesized_item_at
    (self  : Store;
     name  : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the association form of one parenthesized-name item.
  function parenthesized_item_form
    (self  : Store;
     name  : Node_ID;
     index : Positive)
  return Parenthesized_Name_Item_Form;

  --! summary: Return the selector node of one named parenthesized-name item.
  function parenthesized_item_selector
    (self  : Store;
     name  : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the lower bound of a slice name.
  function slice_lower_bound
    (self : Store;
     name : Node_ID)
  return Node_ID;

  --! summary: Return the explicit range delimiter span of a slice name.
  function slice_range_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the upper bound of a slice name.
  function slice_upper_bound
    (self : Store;
     name : Node_ID)
  return Node_ID;

  --! summary: Return the identifier attribute designator symbol.
  function attribute_symbol
    (self : Store;
     name : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the identifier attribute designator source span.
  function attribute_span
    (self : Store;
     name : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the aspect-mark symbol of an aspect specification.
  function aspect_mark_symbol
    (self   : Store;
     aspect : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the exact aspect-mark source span.
  function aspect_mark_span
    (self   : Store;
     aspect : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the represented definition of an aspect specification.
  function aspect_definition
    (self   : Store;
     aspect : Node_ID)
  return Node_ID;

  --! summary: Return the defining-identifier count of a parameter
  --!          specification.
  function parameter_defining_identifier_count
    (self      : Store;
     parameter : Node_ID)
  return Natural;

  --! summary: Return one defining symbol of a parameter specification.
  function parameter_defining_symbol_at
    (self      : Store;
     parameter : Node_ID;
     index     : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one defining-identifier span of a parameter specification.
  function parameter_defining_span_at
    (self      : Store;
     parameter : Node_ID;
     index     : Positive)
  return Adac.Source.Span;

  --! summary: Return the defining symbol of a parameter-specification node.
  function parameter_symbol
    (self      : Store;
     parameter : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of a parameter specification.
  function parameter_defining_span
    (self      : Store;
     parameter : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the source-form mode of a parameter specification.
  function parameter_mode
    (self      : Store;
     parameter : Node_ID)
  return Parameter_Mode_Kind;

  --! summary: Return the subtype-mark name of a parameter specification.
  function parameter_subtype_mark
    (self      : Store;
     parameter : Node_ID)
  return Node_ID;

  --! summary: Return the optional represented parameter default expression.
  function parameter_default_expression
    (self      : Store;
     parameter : Node_ID)
  return Node_ID;

  --! summary: Return the source form of an object declaration.
  function object_form
    (self        : Store;
     declaration : Node_ID)
  return Object_Declaration_Form;

  --! summary: Return the defining symbol of an object-declaration node.
  function object_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of an object declaration.
  function object_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the subtype-mark name of an object declaration.
  function object_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return whether an object declaration has an index constraint.
  function object_has_index_constraint
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the index constraint of an object declaration.
  function object_index_constraint
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return whether an object declaration has an initializer.
  function object_has_initializer
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the initializer expression of an object declaration.
  function object_initializer
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of an object-renaming declaration.
  function object_renaming_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of an object renaming.
  function object_renaming_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the subtype mark of an object-renaming declaration.
  function object_renaming_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the renamed-object name of an object renaming.
  function object_renaming_name
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of a number declaration.
  function number_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of a number declaration.
  function number_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the initializer expression of a number declaration.
  function number_initializer
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of an exception declaration.
  function exception_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of an exception declaration.
  function exception_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the defining symbol of a procedure declaration.
  function procedure_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a procedure declaration.
  function procedure_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the formal-parameter count of a procedure declaration.
  function procedure_declaration_parameter_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one formal parameter of a procedure declaration.
  function procedure_declaration_parameter_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the defining symbol of a procedure-body stub.
  function procedure_body_stub_symbol
    (self : Store;
     stub : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a procedure-body stub.
  function procedure_body_stub_defining_span
    (self : Store;
     stub : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the formal-parameter count of a procedure-body stub.
  function procedure_body_stub_parameter_count
    (self : Store;
     stub : Node_ID)
  return Natural;

  --! summary: Return one formal parameter of a procedure-body stub.
  function procedure_body_stub_parameter_at
    (self  : Store;
     stub  : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the defining symbol of a function declaration.
  function function_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a function declaration.
  function function_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the formal-parameter count of a function declaration.
  function function_declaration_parameter_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one formal parameter of a function declaration.
  function function_declaration_parameter_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the result subtype mark of a function declaration.
  function function_declaration_result_subtype
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return whether a function declaration is an expression function.
  function function_declaration_has_expression
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the represented expression-function expression.
  function function_declaration_expression
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return whether a function declaration has an aspect.
  function function_declaration_has_aspect
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the optional aspect specification of a function.
  function function_declaration_aspect
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of a private-type declaration.
  function private_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a private-type declaration.
  function private_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether a private type includes `limited`.
  function private_type_is_limited
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the discriminant count of a private-type declaration.
  function private_type_discriminant_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one discriminant of a private-type declaration.
  function private_type_discriminant_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the defining symbol of a derived type.
  function derived_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a derived type.
  function derived_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the parent subtype mark of a derived type.
  function derived_type_parent_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the lower bound of a range constraint.
  function range_constraint_lower_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID;

  --! summary: Return the upper bound of a range constraint.
  function range_constraint_upper_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID;

  --! summary: Return the lower bound of a current index constraint.
  function index_constraint_lower_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID;

  --! summary: Return the exact `..` span of a current index constraint.
  function index_constraint_range_span
    (self       : Store;
     constraint : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the upper bound of a current index constraint.
  function index_constraint_upper_bound
    (self       : Store;
     constraint : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of a subtype declaration.
  function subtype_declaration_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a subtype declaration.
  function subtype_declaration_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the subtype mark of a subtype declaration.
  function subtype_declaration_subtype_mark
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return whether a subtype declaration has a range constraint.
  function subtype_declaration_has_constraint
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the range constraint of a subtype declaration.
  function subtype_declaration_constraint
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of an enumeration type.
  function enumeration_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining identifier span of an enumeration type.
  function enumeration_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the number of enumeration literal defining names.
  function enumeration_literal_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one enumeration literal defining symbol.
  function enumeration_literal_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one enumeration literal defining span.
  function enumeration_literal_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  --! summary: Return the defining symbol of a discriminant specification.
  function discriminant_symbol
    (self         : Store;
     discriminant : Node_ID)
  return Adac.Symbols.Symbol_ID;

  function discriminant_defining_span
    (self         : Store;
     discriminant : Node_ID)
  return Adac.Source.Span;

  function discriminant_subtype_mark
    (self         : Store;
     discriminant : Node_ID)
  return Node_ID;

  function discriminant_has_default_expression
    (self         : Store;
     discriminant : Node_ID)
  return Boolean;

  function discriminant_default_expression
    (self         : Store;
     discriminant : Node_ID)
  return Node_ID;

  --! summary: Return the defining symbol of a record component.
  function record_component_symbol
    (self      : Store;
     component : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a record component.
  function record_component_defining_span
    (self      : Store;
     component : Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether the component uses the `aliased` source form.
  function record_component_is_aliased
    (self      : Store;
     component : Node_ID)
  return Boolean;

  --! summary: Return the subtype mark of a record component.
  function record_component_subtype_mark
    (self      : Store;
     component : Node_ID)
  return Node_ID;

  --! summary: Return whether a record component has a default expression.
  function record_component_has_default_expression
    (self      : Store;
     component : Node_ID)
  return Boolean;

  --! summary: Return the default expression of a record component.
  --! contract: The component must have a default expression.
  function record_component_default_expression
    (self      : Store;
     component : Node_ID)
  return Node_ID;

  --! summary: Return the number of discrete choices in one record variant.
  function record_variant_choice_count
    (self    : Store;
     variant : Node_ID)
  return Natural;

  function record_variant_choice_at
    (self    : Store;
     variant : Node_ID;
     index   : Positive)
  return Node_ID;

  function record_variant_has_null_component_list
    (self    : Store;
     variant : Node_ID)
  return Boolean;

  function record_variant_component_count
    (self    : Store;
     variant : Node_ID)
  return Natural;

  function record_variant_component_at
    (self    : Store;
     variant : Node_ID;
     index   : Positive)
  return Node_ID;

  function record_variant_part_discriminant_name
    (self         : Store;
     variant_part : Node_ID)
  return Node_ID;

  function record_variant_part_variant_count
    (self         : Store;
     variant_part : Node_ID)
  return Natural;

  function record_variant_part_variant_at
    (self         : Store;
     variant_part : Node_ID;
     index        : Positive)
  return Node_ID;

  --! summary: Return the defining symbol of a record type.
  function record_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of a record type.
  function record_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return whether the record type uses the `limited` source form.
  function record_type_is_limited
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  function record_has_variant_part
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  function record_variant_part
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the number of record discriminant specifications.
  function record_discriminant_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  function record_discriminant_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the number of record components.
  function record_component_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one record component declaration.
  function record_component_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return the defining symbol of an access-to-object type.
  function access_object_type_symbol
    (self        : Store;
     declaration : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining span of an access-to-object type.
  function access_object_type_defining_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the general access modifier source form.
  function access_object_type_modifier
    (self        : Store;
     declaration : Node_ID)
  return General_Access_Modifier_Kind;

  --! summary: Return the designated subtype mark of an access-to-object type.
  function access_object_type_designated_subtype
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the defining-name component count of a package renaming.
  function package_renaming_defining_name_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  function package_renaming_defining_name_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  function package_renaming_defining_name_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  --! summary: Return the identifier/selected package name being renamed.
  function package_renaming_renamed_package
    (self        : Store;
     declaration : Node_ID)
  return Node_ID;

  --! summary: Return the defining-name component count of a package instance.
  function package_instantiation_defining_name_count
    (self          : Store;
     instantiation : Node_ID)
  return Natural;

  function package_instantiation_defining_name_symbol_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID;

  function package_instantiation_defining_name_span_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Source.Span;

  --! summary: Return the selected generic package name.
  function package_instantiation_generic_name
    (self          : Store;
     instantiation : Node_ID)
  return Node_ID;

  function package_instantiation_actual_count
    (self          : Store;
     instantiation : Node_ID)
  return Natural;

  function package_instantiation_actual_form_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Generic_Actual_Association_Form;

  function package_instantiation_actual_selector_symbol_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Symbols.Symbol_ID;

  function package_instantiation_actual_selector_span_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Adac.Source.Span;

  function package_instantiation_actual_at
    (self          : Store;
     instantiation : Node_ID;
     index         : Positive)
  return Node_ID;

  --! summary: Return the number of names in a with-clause node.
  function with_clause_name_count
    (self   : Store;
     clause : Node_ID)
  return Natural;

  --! summary: Return one library-unit name from a with-clause node.
  function with_clause_name_at
    (self   : Store;
     clause : Node_ID;
     index  : Positive)
  return Node_ID;

  --! summary: Return the subtype-mark count of a use-type clause.
  function use_type_subtype_mark_count
    (self   : Store;
     clause : Node_ID)
  return Natural;

  --! summary: Return one subtype mark from a use-type clause.
  function use_type_subtype_mark_at
    (self   : Store;
     clause : Node_ID;
     index  : Positive)
  return Node_ID;

  --! summary: Return the package-name count of a package-use clause.
  function use_package_name_count
    (self   : Store;
     clause : Node_ID)
  return Natural;

  --! summary: Return one package name from a package-use clause.
  function use_package_name_at
    (self   : Store;
     clause : Node_ID;
     index  : Positive)
  return Node_ID;

  --! summary: Return the number of defining-name components.
  function package_defining_name_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one defining-name component symbol.
  function package_defining_name_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one defining-name component span.
  function package_defining_name_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  --! summary: Return the number of visible declarations in a package node.
  function package_visible_declaration_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one visible declaration from a package node.
  function package_visible_declaration_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return whether the package has an explicit `private` boundary.
  function package_has_explicit_private_part
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the explicit `private` keyword span.
  --! contract: The package must have an explicit private part.
  function package_private_part_span
    (self        : Store;
     declaration : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the number of private declarations in a package node.
  function package_private_declaration_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one private declaration from a package node.
  function package_private_declaration_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Node_ID;

  --! summary: Return whether a package declaration has a closing designator.
  function package_has_end_designator
    (self        : Store;
     declaration : Node_ID)
  return Boolean;

  --! summary: Return the number of closing-name components.
  function package_end_name_count
    (self        : Store;
     declaration : Node_ID)
  return Natural;

  --! summary: Return one closing-name component symbol.
  function package_end_name_symbol_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one closing-name component span.
  function package_end_name_span_at
    (self        : Store;
     declaration : Node_ID;
     index       : Positive)
  return Adac.Source.Span;

  --! summary: Return the defining symbol of a package-body stub.
  function package_body_stub_symbol
    (self : Store;
     stub : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the defining-identifier span of a package-body stub.
  function package_body_stub_defining_span
    (self : Store;
     stub : Node_ID)
  return Adac.Source.Span;

  --! summary: Return the number of package-body defining-name components.
  function package_body_defining_name_count
    (self : Store;
     package_body : Node_ID)
  return Natural;

  --! summary: Return one package-body defining-name component symbol.
  function package_body_defining_name_symbol_at
    (self  : Store;
     package_body : Node_ID;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one package-body defining-name component span.
  function package_body_defining_name_span_at
    (self  : Store;
     package_body : Node_ID;
     index : Positive)
  return Adac.Source.Span;

  --! summary: Return the number of package-body declarative items.
  function package_body_declaration_count
    (self : Store;
     package_body : Node_ID)
  return Natural;

  --! summary: Return one represented package-body declarative item.
  function package_body_declaration_at
    (self  : Store;
     package_body : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return whether a package body has a closing designator.
  function package_body_has_end_designator
    (self : Store;
     package_body : Node_ID)
  return Boolean;

  --! summary: Return the number of package-body closing-name components.
  function package_body_end_name_count
    (self : Store;
     package_body : Node_ID)
  return Natural;

  --! summary: Return one package-body closing-name component symbol.
  function package_body_end_name_symbol_at
    (self  : Store;
     package_body : Node_ID;
     index : Positive)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return one package-body closing-name component span.
  function package_body_end_name_span_at
    (self  : Store;
     package_body : Node_ID;
     index : Positive)
  return Adac.Source.Span;

  --! summary: Return the number of context items in a compilation-unit node.
  function context_item_count
    (self : Store;
     unit : Node_ID)
  return Natural;

  --! summary: Return one context item from a compilation-unit node.
  function context_item_at
    (self  : Store;
     unit  : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the syntactic unit item of a compilation-unit node.
  --! contract: The result may be a current library item or `Subunit_Node`.
  function unit_item
    (self : Store;
     unit : Node_ID)
  return Node_ID;

  --! summary: Return the library item of a compilation-unit node.
  function library_item
    (self : Store;
     unit : Node_ID)
  return Node_ID;

  --! summary: Return the parent-unit-name component count of a subunit.
  function subunit_parent_name_count
    (self    : Store;
     subunit : Node_ID)
  return Natural;

  function subunit_parent_name_symbol_at
    (self    : Store;
     subunit : Node_ID;
     index   : Positive)
  return Adac.Symbols.Symbol_ID;

  function subunit_parent_name_span_at
    (self    : Store;
     subunit : Node_ID;
     index   : Positive)
  return Adac.Source.Span;

  --! summary: Return the proper body owned by a subunit.
  function subunit_proper_body
    (self    : Store;
     subunit : Node_ID)
  return Node_ID;

  --! summary: Return the opening name of a procedure-body node.
  function procedure_symbol
    (self : Store;
     procedure_body : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return whether a procedure body has a closing designator.
  function has_end_designator
    (self : Store;
     procedure_body : Node_ID)
  return Boolean;

  --! summary: Return the optional closing-designator symbol.
  --! contract: Returns `INVALID_SYMBOL_ID` when no designator is present.
  function end_symbol
    (self : Store;
     procedure_body : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Return the number of parameters in a procedure-body node.
  function parameter_count
    (self : Store;
     procedure_body : Node_ID)
  return Natural;

  --! summary: Return one parameter ID from a procedure-body node.
  function parameter_at
    (self : Store;
     procedure_body : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the number of declarative items in a procedure body.
  function declaration_count
    (self : Store;
     procedure_body : Node_ID)
  return Natural;

  --! summary: Return one declarative item from a procedure body.
  function declaration_at
    (self : Store;
     procedure_body : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the handled sequence owned by a procedure body.
  function procedure_handled_sequence
    (self : Store;
     procedure_body : Node_ID)
  return Node_ID;

  --! summary: Return the number of ordinary handled statements.
  function statement_count
    (self : Store;
     procedure_body : Node_ID)
  return Natural;

  --! summary: Return one ordinary handled statement from a procedure body.
  function statement_at
    (self  : Store;
     procedure_body : Node_ID;
     index : Positive)
  return Node_ID;

  --! summary: Return the opening name of a function-body node.
  function function_body_symbol
    (self          : Store;
     function_body : Node_ID)
  return Adac.Symbols.Symbol_ID;

  function function_body_parameter_count
    (self          : Store;
     function_body : Node_ID)
  return Natural;

  function function_body_parameter_at
    (self          : Store;
     function_body : Node_ID;
     index         : Positive)
  return Node_ID;

  function function_body_declaration_count
    (self          : Store;
     function_body : Node_ID)
  return Natural;

  function function_body_declaration_at
    (self          : Store;
     function_body : Node_ID;
     index         : Positive)
  return Node_ID;

  function function_body_result_subtype
    (self          : Store;
     function_body : Node_ID)
  return Node_ID;

  function function_body_handled_sequence
    (self          : Store;
     function_body : Node_ID)
  return Node_ID;

  function function_body_has_end_designator
    (self          : Store;
     function_body : Node_ID)
  return Boolean;

  function function_body_end_symbol
    (self          : Store;
     function_body : Node_ID)
  return Adac.Symbols.Symbol_ID;

  --! summary: Validate the structural state of a node identifier.
  procedure validate (node : Node_ID);


private

  package Construction_Implementation is

    function append_numeric_literal
      (self          : in out Store;
       form          : Numeric_Literal_Kind;
       spelling      : String;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_character_literal
      (self          : in out Store;
       spelling      : String;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_string_literal
      (self          : in out Store;
       spelling      : String;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_null_literal
      (self          : in out Store;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_record_aggregate
      (self          : in out Store;
       associations  : Record_Component_Association_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_array_aggregate
      (self          : in out Store;
       associations  : Array_Component_Association_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_bracket_aggregate
      (self          : in out Store;
       expressions   : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_qualified_expression
      (self          : in out Store;
       subtype_mark  : Node_ID;
       operand       : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_allocator
      (self          : in out Store;
       new_span      : Adac.Source.Span;
       expression    : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_if_expression
      (self            : in out Store;
       condition       : Node_ID;
       then_expression : Node_ID;
       else_expression : Node_ID;
       span            : Adac.Source.Span;
       maximum_nodes   : Natural := Natural'Last)
    return Node_ID;

    function append_case_expression_alternative
      (self          : in out Store;
       choices       : Node_List;
       expression    : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_raise_expression
      (self           : in out Store;
       exception_name : Node_ID;
       message        : Node_ID;
       span           : Adac.Source.Span;
       maximum_nodes  : Natural := Natural'Last)
    return Node_ID;

    function append_case_expression
      (self                 : in out Store;
       selecting_expression : Node_ID;
       alternatives         : Node_List;
       span                 : Adac.Source.Span;
       maximum_nodes        : Natural := Natural'Last)
    return Node_ID;

    function append_parenthesized_expression
      (self          : in out Store;
       expression    : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_unary_operator
      (self              : in out Store;
       operator_spelling : String;
       operator_span     : Adac.Source.Span;
       operand           : Node_ID;
       span              : Adac.Source.Span;
       maximum_nodes     : Natural := Natural'Last)
    return Node_ID;

    function append_binary_exponentiating
      (self              : in out Store;
       left_operand      : Node_ID;
       operator_spelling : String;
       operator_span     : Adac.Source.Span;
       right_operand     : Node_ID;
       span              : Adac.Source.Span;
       maximum_nodes     : Natural := Natural'Last)
    return Node_ID;

    function append_binary_multiplying
      (self              : in out Store;
       left_operand      : Node_ID;
       operator_spelling : String;
       operator_span     : Adac.Source.Span;
       right_operand     : Node_ID;
       span              : Adac.Source.Span;
       maximum_nodes     : Natural := Natural'Last)
    return Node_ID;

    function append_binary_adding
      (self              : in out Store;
       left_operand      : Node_ID;
       operator_spelling : String;
       operator_span     : Adac.Source.Span;
       right_operand     : Node_ID;
       span              : Adac.Source.Span;
       maximum_nodes     : Natural := Natural'Last)
    return Node_ID;

    function append_relation
      (self              : in out Store;
       left_operand      : Node_ID;
       operator_spelling : String;
       operator_span     : Adac.Source.Span;
       right_operand     : Node_ID;
       span              : Adac.Source.Span;
       maximum_nodes     : Natural := Natural'Last)
    return Node_ID;

    function append_membership_range_choice
      (self          : in out Store;
       lower_bound   : Node_ID;
       range_span    : Adac.Source.Span;
       upper_bound   : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_membership_expression
      (self          : in out Store;
       tested        : Node_ID;
       operator_kind : Membership_Operator_Kind;
       not_span      : Adac.Source.Span;
       in_span       : Adac.Source.Span;
       choices       : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_logical_expression
      (self          : in out Store;
       left_operand  : Node_ID;
       operator_kind : Logical_Operator_Kind;
       operator_span : Adac.Source.Span;
       right_operand : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_short_circuit_expression
      (self                 : in out Store;
       left_operand         : Node_ID;
       operator_kind        : Short_Circuit_Operator_Kind;
       operator_first_span  : Adac.Source.Span;
       operator_second_span : Adac.Source.Span;
       right_operand        : Node_ID;
       span                 : Adac.Source.Span;
       maximum_nodes        : Natural := Natural'Last)
    return Node_ID;

    function append_identifier_name
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_selected_name
      (self          : in out Store;
       prefix        : Node_ID;
       selector      : Adac.Symbols.Symbol_ID;
       selector_span : Adac.Source.Span;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_explicit_dereference_name
      (self          : in out Store;
       prefix        : Node_ID;
       all_span      : Adac.Source.Span;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_selected_component
      (self          : in out Store;
       prefix        : Node_ID;
       selector      : Adac.Symbols.Symbol_ID;
       selector_span : Adac.Source.Span;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_parenthesized_name
      (self          : in out Store;
       prefix        : Node_ID;
       items         : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_parenthesized_name
      (self          : in out Store;
       prefix        : Node_ID;
       items         : Parenthesized_Name_Item_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_slice_name
      (self          : in out Store;
       prefix        : Node_ID;
       lower_bound   : Node_ID;
       range_span    : Adac.Source.Span;
       upper_bound   : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_attribute_name
      (self            : in out Store;
       prefix          : Node_ID;
       designator      : Adac.Symbols.Symbol_ID;
       designator_span : Adac.Source.Span;
       span            : Adac.Source.Span;
       maximum_nodes   : Natural := Natural'Last)
    return Node_ID;

    function append_aspect_specification
      (self          : in out Store;
       mark_symbol   : Adac.Symbols.Symbol_ID;
       mark_span     : Adac.Source.Span;
       definition    : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_parameter_specification
      (self                 : in out Store;
       defining_identifiers : Defining_Identifier_List;
       mode                 : Parameter_Mode_Kind;
       subtype_mark         : Node_ID;
       span                 : Adac.Source.Span;
       maximum_nodes        : Natural := Natural'Last)
    return Node_ID;

    function append_parameter_specification
      (self                 : in out Store;
       defining_identifiers : Defining_Identifier_List;
       mode                 : Parameter_Mode_Kind;
       subtype_mark         : Node_ID;
       default_expression   : Node_ID;
       span                 : Adac.Source.Span;
       maximum_nodes        : Natural := Natural'Last)
    return Node_ID;

    function append_parameter_specification
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       mode          : Parameter_Mode_Kind;
       subtype_mark  : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_parameter_specification
      (self               : in out Store;
       symbol             : Adac.Symbols.Symbol_ID;
       defining_span      : Adac.Source.Span;
       mode               : Parameter_Mode_Kind;
       subtype_mark       : Node_ID;
       default_expression : Node_ID;
       span               : Adac.Source.Span;
       maximum_nodes      : Natural := Natural'Last)
    return Node_ID;

    function append_object_declaration
      (self          : in out Store;
       form          : Object_Declaration_Form;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       subtype_mark  : Node_ID;
       initializer   : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

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
    return Node_ID;

    function append_object_renaming_declaration
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       subtype_mark  : Node_ID;
       renamed_name  : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_number_declaration
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       initializer   : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_exception_declaration
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_procedure_declaration
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       parameters    : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_procedure_body_stub
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       parameters    : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_function_declaration
      (self           : in out Store;
       symbol         : Adac.Symbols.Symbol_ID;
       defining_span  : Adac.Source.Span;
       parameters     : Node_List;
       result_subtype : Node_ID;
       aspect         : Node_ID;
       span           : Adac.Source.Span;
       maximum_nodes  : Natural := Natural'Last)
    return Node_ID;

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
    return Node_ID;

    function append_private_type_declaration
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       discriminants : Node_List;
       span          : Adac.Source.Span;
       limited_form  : Boolean := False;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_derived_type_declaration
      (self                : in out Store;
       symbol              : Adac.Symbols.Symbol_ID;
       defining_span       : Adac.Source.Span;
       parent_subtype_mark : Node_ID;
       span                : Adac.Source.Span;
       maximum_nodes       : Natural := Natural'Last)
    return Node_ID;

    function append_range_constraint
      (self          : in out Store;
       lower_bound   : Node_ID;
       upper_bound   : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_index_constraint
      (self          : in out Store;
       lower_bound   : Node_ID;
       range_span    : Adac.Source.Span;
       upper_bound   : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_subtype_declaration
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       subtype_mark  : Node_ID;
       constraint    : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_enumeration_type_declaration
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       literals      : Enumeration_Literal_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_discriminant_specification
      (self               : in out Store;
       symbol             : Adac.Symbols.Symbol_ID;
       defining_span      : Adac.Source.Span;
       subtype_mark       : Node_ID;
       default_expression : Node_ID;
       span               : Adac.Source.Span;
       maximum_nodes      : Natural := Natural'Last)
    return Node_ID;

    function append_record_component_declaration
      (self               : in out Store;
       symbol             : Adac.Symbols.Symbol_ID;
       defining_span      : Adac.Source.Span;
       aliased_form       : Boolean;
       subtype_mark       : Node_ID;
       default_expression : Node_ID;
       span               : Adac.Source.Span;
       maximum_nodes      : Natural := Natural'Last)
    return Node_ID;

    function append_record_variant
      (self                : in out Store;
       choices             : Node_List;
       components          : Node_List;
       null_component_list : Boolean;
       span                : Adac.Source.Span;
       maximum_nodes       : Natural := Natural'Last)
    return Node_ID;

    function append_record_variant_part
      (self              : in out Store;
       discriminant_name : Node_ID;
       variants          : Node_List;
       span              : Adac.Source.Span;
       maximum_nodes     : Natural := Natural'Last)
    return Node_ID;

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
    return Node_ID;

    function append_access_object_type_declaration
      (self               : in out Store;
       symbol             : Adac.Symbols.Symbol_ID;
       defining_span      : Adac.Source.Span;
       modifier           : General_Access_Modifier_Kind;
       designated_subtype : Node_ID;
       span               : Adac.Source.Span;
       maximum_nodes      : Natural := Natural'Last)
    return Node_ID;

    function append_others_exception_choice
      (self          : in out Store;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_exception_handler
      (self                    : in out Store;
       choice_parameter_symbol : Adac.Symbols.Symbol_ID;
       choice_parameter_span   : Adac.Source.Span;
       choices                 : Node_List;
       statements              : Node_List;
       span                    : Adac.Source.Span;
       maximum_nodes           : Natural := Natural'Last)
    return Node_ID;

    function append_handled_sequence
      (self          : in out Store;
       statements    : Node_List;
       handlers      : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_elsif_part
      (self          : in out Store;
       condition     : Node_ID;
       statements    : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_if_statement
      (self            : in out Store;
       condition       : Node_ID;
       then_statements : Node_List;
       elsif_parts     : Node_List;
       else_statements : Node_List;
       span            : Adac.Source.Span;
       maximum_nodes   : Natural := Natural'Last)
    return Node_ID;

    function append_assignment_statement
      (self          : in out Store;
       target        : Node_ID;
       expression    : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_case_range_choice
      (self          : in out Store;
       lower_bound   : Node_ID;
       range_span    : Adac.Source.Span;
       upper_bound   : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_others_case_choice
      (self          : in out Store;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_case_alternative
      (self          : in out Store;
       choices       : Node_List;
       statements    : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_case_statement
      (self                 : in out Store;
       selecting_expression : Node_ID;
       alternatives         : Node_List;
       span                 : Adac.Source.Span;
       maximum_nodes        : Natural := Natural'Last)
    return Node_ID;

    function append_block_statement
      (self             : in out Store;
       declarations     : Node_List;
       handled_sequence : Node_ID;
       span             : Adac.Source.Span;
       maximum_nodes    : Natural := Natural'Last)
    return Node_ID;

    function append_simple_loop_statement
      (self          : in out Store;
       statements    : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_while_loop_statement
      (self          : in out Store;
       condition     : Node_ID;
       statements    : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

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
    return Node_ID;

    function append_range_attribute_loop_statement
      (self             : in out Store;
       parameter_symbol : Adac.Symbols.Symbol_ID;
       parameter_span   : Adac.Source.Span;
       reverse_present  : Boolean;
       range_attribute  : Node_ID;
       statements       : Node_List;
       span             : Adac.Source.Span;
       maximum_nodes    : Natural := Natural'Last)
    return Node_ID;

    function append_loop_statement
      (self             : in out Store;
       parameter_symbol : Adac.Symbols.Symbol_ID;
       parameter_span   : Adac.Source.Span;
       reverse_present  : Boolean;
       iterable_name    : Node_ID;
       statements       : Node_List;
       span             : Adac.Source.Span;
       maximum_nodes    : Natural := Natural'Last)
    return Node_ID;

    function append_procedure_call_statement
      (self          : in out Store;
       callable_name : Node_ID;
       actuals       : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_procedure_call_statement
      (self          : in out Store;
       callable_name : Node_ID;
       actuals       : Procedure_Call_Actual_Association_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_extended_return_statement
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       subtype_mark  : Node_ID;
       sequence      : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_exit_statement
      (self             : in out Store;
       loop_name_symbol : Adac.Symbols.Symbol_ID;
       loop_name_span   : Adac.Source.Span;
       when_span        : Adac.Source.Span;
       condition        : Node_ID;
       span             : Adac.Source.Span;
       maximum_nodes    : Natural := Natural'Last)
    return Node_ID;

    function append_return_statement
      (self          : in out Store;
       expression    : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_bare_raise_statement
      (self          : in out Store;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_raise_statement
      (self           : in out Store;
       exception_name : Node_ID;
       message        : Node_ID;
       span           : Adac.Source.Span;
       maximum_nodes  : Natural := Natural'Last)
    return Node_ID;

    function append_statement
      (self          : in out Store;
       kind          : Node_Kind;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_with_clause
      (self          : in out Store;
       names         : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_use_type_clause
      (self          : in out Store;
       subtype_marks : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_use_package_clause
      (self          : in out Store;
       package_names : Node_List;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_package_renaming_declaration
      (self            : in out Store;
       defining_name   : Program_Unit_Name;
       renamed_package : Node_ID;
       span            : Adac.Source.Span;
       maximum_nodes   : Natural := Natural'Last)
    return Node_ID;

    function append_package_instantiation
      (self           : in out Store;
       defining_name  : Program_Unit_Name;
       generic_name   : Node_ID;
       actuals        : Generic_Actual_Association_List;
       span           : Adac.Source.Span;
       maximum_nodes  : Natural := Natural'Last)
    return Node_ID;

    function append_package_declaration
      (self                 : in out Store;
       defining_name        : Program_Unit_Name;
       visible_declarations : Node_List;
       private_part_span    : Adac.Source.Span;
       private_declarations : Node_List;
       end_name             : Program_Unit_Name;
       span                 : Adac.Source.Span;
       maximum_nodes        : Natural := Natural'Last)
    return Node_ID;

    function append_package_body_stub
      (self          : in out Store;
       symbol        : Adac.Symbols.Symbol_ID;
       defining_span : Adac.Source.Span;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_package_body
      (self          : in out Store;
       defining_name : Program_Unit_Name;
       declarations  : Node_List;
       end_name      : Program_Unit_Name;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

    function append_procedure_body
      (self             : in out Store;
       procedure_symbol : Adac.Symbols.Symbol_ID;
       parameters       : Node_List;
       declarations     : Node_List;
       handled_sequence : Node_ID;
       end_symbol       : Adac.Symbols.Symbol_ID;
       span             : Adac.Source.Span;
       maximum_nodes    : Natural := Natural'Last)
    return Node_ID;

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
    return Node_ID;

    function append_subunit
      (self             : in out Store;
       parent_unit_name : Program_Unit_Name;
       proper_body      : Node_ID;
       span             : Adac.Source.Span;
       maximum_nodes    : Natural := Natural'Last)
    return Node_ID;

    function append_compilation_unit
      (self          : in out Store;
       context_items : Node_List;
       unit_item     : Node_ID;
       span          : Adac.Source.Span;
       maximum_nodes : Natural := Natural'Last)
    return Node_ID;

  end Construction_Implementation;

  package Validation_Implementation is

    procedure validate_numeric_literal
      (self    : Store;
       literal : Node_ID);

    procedure validate_derived_type_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_range_constraint
      (self       : Store;
       constraint : Node_ID);

    procedure validate_index_constraint
      (self       : Store;
       constraint : Node_ID);

    procedure validate_subtype_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_discriminant_specification
      (self         : Store;
       discriminant : Node_ID);

    procedure validate_record_component_declaration
      (self      : Store;
       component : Node_ID);

    procedure validate_record_variant
      (self    : Store;
       variant : Node_ID);

    procedure validate_record_variant_part
      (self         : Store;
       variant_part : Node_ID);

    procedure validate_record_type_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_access_object_type_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_exception_handler
      (self    : Store;
       handler : Node_ID);

    procedure validate_exception_handler_block_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_handled_sequence
      (self     : Store;
       sequence : Node_ID);

    procedure validate_elsif_part
      (self : Store;
       part : Node_ID);

    procedure validate_if_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_extended_return_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_exit_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_return_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_raise_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_assignment_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_case_alternative
      (self        : Store;
       alternative : Node_ID);

    procedure validate_case_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_block_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_loop_statement
      (self      : Store;
       statement : Node_ID);

    procedure validate_procedure_call
      (self      : Store;
       statement : Node_ID);

    procedure validate_character_literal
      (self    : Store;
       literal : Node_ID);

    procedure validate_string_literal
      (self    : Store;
       literal : Node_ID);

    procedure validate_null_literal
      (self    : Store;
       literal : Node_ID);

    procedure validate_nonaggregate_simple_expression_shape
      (self       : Store;
       expression : Node_ID);

    procedure validate_record_aggregate
      (self      : Store;
       aggregate : Node_ID);

    procedure validate_array_aggregate
      (self      : Store;
       aggregate : Node_ID);

    procedure validate_bracket_aggregate
      (self      : Store;
       aggregate : Node_ID);

    procedure validate_qualified_expression
      (self       : Store;
       expression : Node_ID);

    procedure validate_allocator
      (self      : Store;
       allocator : Node_ID);

    procedure validate_case_range_choice
      (self   : Store;
       choice : Node_ID);

    procedure validate_membership_range_choice
      (self   : Store;
       choice : Node_ID);

    procedure validate_logical_expression
      (self       : Store;
       expression : Node_ID);

    procedure validate_short_circuit_expression
      (self       : Store;
       expression : Node_ID);

    procedure validate_expression
      (self       : Store;
       expression : Node_ID);

    procedure validate_name
      (self : Store;
       name : Node_ID);

    procedure validate_aspect_specification
      (self   : Store;
       aspect : Node_ID);

    procedure validate_parameter
      (self      : Store;
       parameter : Node_ID);

    procedure validate_exception_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_use_type_clause
      (self   : Store;
       clause : Node_ID);

    procedure validate_use_package_clause
      (self   : Store;
       clause : Node_ID);

    procedure validate_package_renaming_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_package_instantiation
      (self          : Store;
       instantiation : Node_ID);

    procedure validate_package_declaration
      (self        : Store;
       declaration : Node_ID);

    procedure validate_package_body_stub
      (self : Store;
       stub : Node_ID);

    procedure validate_package_body
      (self : Store;
       package_body : Node_ID);

    procedure validate_procedure_body
      (self : Store;
       procedure_body : Node_ID);

    procedure validate_subunit
      (self    : Store;
       subunit : Node_ID);

    procedure validate_function_body
      (self          : Store;
       function_body : Node_ID);

    procedure validate
      (self : Store;
       root : Node_ID);

  end Validation_Implementation;

  type Store_Marker is record
    identity : Boolean := False;
  end record;
  type Store_Marker_Access is access constant Store_Marker;

  type Node_ID is record
    owner : Store_Marker_Access := null;
    index : Natural := 0;
  end record;

  INVALID_NODE_ID : constant Node_ID :=
    (owner => null,
     index => 0);

  type Program_Unit_Name_Component is record
    symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    span   : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  end record;

  package Program_Unit_Name_Component_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Program_Unit_Name_Component);

  type Program_Unit_Name is record
    components : Program_Unit_Name_Component_Vectors.Vector;
  end record;

  type Defining_Identifier_List is new Program_Unit_Name;
  type Enumeration_Literal_List is new Program_Unit_Name;

  package Node_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Node_ID);

  type Node_List is record
    nodes : Node_Vectors.Vector;
  end record;

  type Record_Component_Association is record
    selector      : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    selector_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    expression    : Node_ID := INVALID_NODE_ID;
  end record;

  package Record_Component_Association_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Record_Component_Association);

  type Record_Component_Association_List is record
    associations : Record_Component_Association_Vectors.Vector;
  end record;

  type Array_Component_Association is record
    choices    : Node_Vectors.Vector;
    expression : Node_ID := INVALID_NODE_ID;
  end record;

  package Array_Component_Association_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Array_Component_Association);

  type Array_Component_Association_List is record
    associations : Array_Component_Association_Vectors.Vector;
  end record;

  type Parenthesized_Name_Item is record
    form : Parenthesized_Name_Item_Form :=
      Positional_Parenthesized_Name_Item_Form;
    selector : Node_ID := INVALID_NODE_ID;
    actual   : Node_ID := INVALID_NODE_ID;
  end record;

  package Parenthesized_Name_Item_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Parenthesized_Name_Item);

  type Parenthesized_Name_Item_List is record
    items : Parenthesized_Name_Item_Vectors.Vector;
  end record;

  type Procedure_Call_Actual_Association is record
    form : Procedure_Call_Actual_Association_Form :=
      Positional_Procedure_Call_Actual_Form;
    selector : Node_ID := INVALID_NODE_ID;
    actual   : Node_ID := INVALID_NODE_ID;
  end record;

  package Procedure_Call_Actual_Association_Vectors is new
    Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Procedure_Call_Actual_Association);

  type Procedure_Call_Actual_Association_List is record
    associations : Procedure_Call_Actual_Association_Vectors.Vector;
  end record;

  type Generic_Actual_Association is record
    form : Generic_Actual_Association_Form :=
      Named_Generic_Actual_Form;
    selector      : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    selector_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    actual        : Node_ID := INVALID_NODE_ID;
  end record;

  package Generic_Actual_Association_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Generic_Actual_Association);

  type Generic_Actual_Association_List is record
    associations : Generic_Actual_Association_Vectors.Vector;
  end record;

  type Node (kind : Node_Kind := Null_Statement_Node) is record
    span : Adac.Source.Span := Adac.Source.INVALID_SPAN;

    case kind is
      when Compilation_Unit_Node =>
        context_items : Node_Vectors.Vector;
        unit_item_value : Node_ID := INVALID_NODE_ID;

      when Subunit_Node =>
        subunit_parent_name_value :
          Program_Unit_Name_Component_Vectors.Vector;
        subunit_proper_body_value : Node_ID := INVALID_NODE_ID;

      when Procedure_Body_Node =>
        procedure_symbol : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        parameters : Node_Vectors.Vector;
        declarations : Node_Vectors.Vector;
        procedure_handled_sequence_value : Node_ID := INVALID_NODE_ID;
        end_symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;

      when Function_Body_Node =>
        function_body_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        function_body_parameters_value : Node_Vectors.Vector;
        function_body_result_subtype_value : Node_ID := INVALID_NODE_ID;
        function_body_declarations_value : Node_Vectors.Vector;
        function_body_handled_sequence_value : Node_ID := INVALID_NODE_ID;
        function_body_end_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;

      when With_Clause_Node =>
        library_names : Node_Vectors.Vector;

      when Use_Type_Clause_Node =>
        use_type_subtype_marks_value : Node_Vectors.Vector;

      when Use_Package_Clause_Node =>
        use_package_names_value : Node_Vectors.Vector;

      when Assignment_Statement_Node =>
        assignment_target_value : Node_ID := INVALID_NODE_ID;
        assignment_expression_value : Node_ID := INVALID_NODE_ID;

      when Case_Range_Choice_Node =>
        case_range_choice_lower_bound_value : Node_ID := INVALID_NODE_ID;
        case_range_choice_range_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        case_range_choice_upper_bound_value : Node_ID := INVALID_NODE_ID;

      when Case_Alternative_Node =>
        case_alternative_choices_value : Node_Vectors.Vector;
        case_alternative_statements_value : Node_Vectors.Vector;

      when Case_Statement_Node =>
        case_selecting_expression_value : Node_ID := INVALID_NODE_ID;
        case_alternatives_value : Node_Vectors.Vector;

      when Block_Statement_Node =>
        block_declarations_value : Node_Vectors.Vector;
        block_handled_sequence_value : Node_ID := INVALID_NODE_ID;

      when Loop_Statement_Node =>
        loop_form_value : Loop_Statement_Form := Generalized_Iterator_Loop_Form;
        loop_condition_value : Node_ID := INVALID_NODE_ID;
        loop_parameter_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        loop_parameter_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        loop_reverse_value : Boolean := False;
        loop_iterable_name_value : Node_ID := INVALID_NODE_ID;
        loop_range_attribute_value : Node_ID := INVALID_NODE_ID;
        loop_range_lower_bound_value : Node_ID := INVALID_NODE_ID;
        loop_range_upper_bound_value : Node_ID := INVALID_NODE_ID;
        loop_statements_value : Node_Vectors.Vector;

      when Procedure_Call_Statement_Node =>
        procedure_call_callable_name_value : Node_ID := INVALID_NODE_ID;
        procedure_call_actuals_value :
          Procedure_Call_Actual_Association_Vectors.Vector;

      when If_Statement_Node =>
        if_condition_value : Node_ID := INVALID_NODE_ID;
        if_then_statements_value : Node_Vectors.Vector;
        if_elsif_parts_value : Node_Vectors.Vector;
        if_else_statements_value : Node_Vectors.Vector;

      when Elsif_Part_Node =>
        elsif_condition_value : Node_ID := INVALID_NODE_ID;
        elsif_statements_value : Node_Vectors.Vector;

      when Others_Case_Choice_Node |
           Others_Exception_Choice_Node |
           Null_Literal_Node =>
        null;

      when Record_Aggregate_Node =>
        record_aggregate_associations_value :
          Record_Component_Association_Vectors.Vector;

      when Array_Aggregate_Node =>
        array_aggregate_associations_value :
          Array_Component_Association_Vectors.Vector;

      when Bracket_Aggregate_Node =>
        bracket_aggregate_expressions_value : Node_Vectors.Vector;

      when Qualified_Expression_Node =>
        qualified_expression_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        qualified_expression_operand_value : Node_ID := INVALID_NODE_ID;

      when Allocator_Node =>
        allocator_new_span_value : Adac.Source.Span := Adac.Source.INVALID_SPAN;
        allocator_expression_value : Node_ID := INVALID_NODE_ID;

      when Exception_Handler_Node =>
        exception_handler_choice_parameter_symbol_value :
          Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
        exception_handler_choice_parameter_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        exception_handler_choices_value : Node_Vectors.Vector;
        exception_handler_statements_value : Node_Vectors.Vector;

      when Handled_Sequence_Node =>
        handled_sequence_statements_value : Node_Vectors.Vector;
        handled_sequence_handlers_value : Node_Vectors.Vector;

      when Numeric_Literal_Node =>
        numeric_form : Numeric_Literal_Kind := Decimal_Integer_Form;
        numeric_spelling : Ada.Strings.Unbounded.Unbounded_String;

      when Character_Literal_Node =>
        character_spelling : Ada.Strings.Unbounded.Unbounded_String;

      when String_Literal_Node =>
        string_spelling : Ada.Strings.Unbounded.Unbounded_String;

      when If_Expression_Node =>
        if_expression_condition_value : Node_ID := INVALID_NODE_ID;
        if_expression_then_value : Node_ID := INVALID_NODE_ID;
        if_expression_else_value : Node_ID := INVALID_NODE_ID;

      when Case_Expression_Alternative_Node =>
        case_expression_alternative_choices_value : Node_Vectors.Vector;
        case_expression_alternative_expression_value : Node_ID :=
          INVALID_NODE_ID;

      when Case_Expression_Node =>
        case_expression_selecting_expression_value : Node_ID := INVALID_NODE_ID;
        case_expression_alternatives_value : Node_Vectors.Vector;

      when Raise_Expression_Node =>
        raise_expression_exception_name_value : Node_ID := INVALID_NODE_ID;
        raise_expression_message_value : Node_ID := INVALID_NODE_ID;

      when Parenthesized_Expression_Node =>
        parenthesized_expression_child_value : Node_ID := INVALID_NODE_ID;

      when Unary_Operator_Node =>
        unary_operator_spelling_value :
          Ada.Strings.Unbounded.Unbounded_String;
        unary_operator_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        unary_operand_value : Node_ID := INVALID_NODE_ID;

      when Binary_Exponentiating_Node =>
        binary_exponentiating_left_operand_value : Node_ID := INVALID_NODE_ID;
        binary_exponentiating_operator_spelling_value :
          Ada.Strings.Unbounded.Unbounded_String;
        binary_exponentiating_operator_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        binary_exponentiating_right_operand_value : Node_ID := INVALID_NODE_ID;

      when Binary_Multiplying_Node =>
        binary_multiplying_left_operand_value : Node_ID := INVALID_NODE_ID;
        binary_multiplying_operator_spelling_value :
          Ada.Strings.Unbounded.Unbounded_String;
        binary_multiplying_operator_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        binary_multiplying_right_operand_value : Node_ID := INVALID_NODE_ID;

      when Binary_Adding_Node =>
        binary_adding_left_operand_value : Node_ID := INVALID_NODE_ID;
        binary_adding_operator_spelling_value :
          Ada.Strings.Unbounded.Unbounded_String;
        binary_adding_operator_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        binary_adding_right_operand_value : Node_ID := INVALID_NODE_ID;

      when Relation_Node =>
        relation_left_operand_value : Node_ID := INVALID_NODE_ID;
        relation_operator_spelling_value :
          Ada.Strings.Unbounded.Unbounded_String;
        relation_operator_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        relation_right_operand_value : Node_ID := INVALID_NODE_ID;

      when Membership_Range_Choice_Node =>
        membership_range_choice_lower_bound_value : Node_ID := INVALID_NODE_ID;
        membership_range_choice_range_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        membership_range_choice_upper_bound_value : Node_ID := INVALID_NODE_ID;

      when Membership_Expression_Node =>
        membership_tested_expression_value : Node_ID := INVALID_NODE_ID;
        membership_operator_value : Membership_Operator_Kind :=
          In_Membership_Operator;
        membership_not_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        membership_in_span_value : Adac.Source.Span := Adac.Source.INVALID_SPAN;
        membership_choices_value : Node_Vectors.Vector;

      when Logical_Expression_Node =>
        logical_left_operand_value : Node_ID := INVALID_NODE_ID;
        logical_operator_value : Logical_Operator_Kind := And_Logical_Operator;
        logical_operator_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        logical_right_operand_value : Node_ID := INVALID_NODE_ID;

      when Short_Circuit_Expression_Node =>
        short_circuit_left_operand_value : Node_ID := INVALID_NODE_ID;
        short_circuit_operator_value : Short_Circuit_Operator_Kind :=
          And_Then_Short_Circuit_Operator;
        short_circuit_operator_first_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        short_circuit_operator_second_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        short_circuit_right_operand_value : Node_ID := INVALID_NODE_ID;

      when Identifier_Name_Node =>
        name_symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;

      when Explicit_Dereference_Name_Node =>
        explicit_dereference_prefix_value : Node_ID := INVALID_NODE_ID;
        explicit_dereference_all_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;

      when Selected_Name_Node | Selected_Component_Node =>
        selected_prefix : Node_ID := INVALID_NODE_ID;
        selected_symbol : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        selected_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;

      when Parenthesized_Name_Node =>
        parenthesized_prefix : Node_ID := INVALID_NODE_ID;
        parenthesized_items  : Parenthesized_Name_Item_Vectors.Vector;

      when Slice_Name_Node =>
        slice_prefix_value : Node_ID := INVALID_NODE_ID;
        slice_lower_bound_value : Node_ID := INVALID_NODE_ID;
        slice_range_span_value : Adac.Source.Span := Adac.Source.INVALID_SPAN;
        slice_upper_bound_value : Node_ID := INVALID_NODE_ID;

      when Attribute_Name_Node =>
        attribute_prefix : Node_ID := INVALID_NODE_ID;
        attribute_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        attribute_span_value : Adac.Source.Span := Adac.Source.INVALID_SPAN;

      when Aspect_Specification_Node =>
        aspect_mark_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        aspect_mark_span_value : Adac.Source.Span := Adac.Source.INVALID_SPAN;
        aspect_definition_value : Node_ID := INVALID_NODE_ID;

      when Parameter_Specification_Node =>
        parameter_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        parameter_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        parameter_additional_defining_names_index_value : Natural := 0;
        parameter_mode_value : Parameter_Mode_Kind := Default_In_Parameter_Mode;
        parameter_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        parameter_default_expression_value : Node_ID := INVALID_NODE_ID;

      when Object_Declaration_Node =>
        object_form_value : Object_Declaration_Form := Variable_Object_Form;
        object_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        object_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        object_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        object_index_constraint_value : Node_ID := INVALID_NODE_ID;
        object_initializer_value  : Node_ID := INVALID_NODE_ID;

      when Object_Renaming_Declaration_Node =>
        object_renaming_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        object_renaming_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        object_renaming_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        object_renaming_name_value : Node_ID := INVALID_NODE_ID;

      when Number_Declaration_Node =>
        number_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        number_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        number_initializer_value : Node_ID := INVALID_NODE_ID;

      when Exception_Declaration_Node =>
        exception_declaration_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        exception_declaration_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;

      when Procedure_Declaration_Node =>
        procedure_declaration_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        procedure_declaration_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        procedure_declaration_parameters_value : Node_Vectors.Vector;

      when Procedure_Body_Stub_Node =>
        procedure_body_stub_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        procedure_body_stub_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        procedure_body_stub_parameters_value : Node_Vectors.Vector;

      when Function_Declaration_Node =>
        function_declaration_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        function_declaration_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        function_declaration_parameters_value : Node_Vectors.Vector;
        function_declaration_result_subtype_value : Node_ID := INVALID_NODE_ID;
        function_declaration_expression_value : Node_ID := INVALID_NODE_ID;
        function_declaration_aspect_value : Node_ID := INVALID_NODE_ID;

      when Private_Type_Declaration_Node =>
        private_type_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        private_type_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        private_type_discriminants_value : Node_Vectors.Vector;
        private_type_limited_value : Boolean := False;

      when Derived_Type_Declaration_Node =>
        derived_type_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        derived_type_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        derived_type_parent_subtype_mark_value : Node_ID := INVALID_NODE_ID;

      when Range_Constraint_Node =>
        range_constraint_lower_bound_value : Node_ID := INVALID_NODE_ID;
        range_constraint_upper_bound_value : Node_ID := INVALID_NODE_ID;

      when Index_Constraint_Node =>
        index_constraint_lower_bound_value : Node_ID := INVALID_NODE_ID;
        index_constraint_range_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        index_constraint_upper_bound_value : Node_ID := INVALID_NODE_ID;

      when Subtype_Declaration_Node =>
        subtype_declaration_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        subtype_declaration_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        subtype_declaration_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        subtype_declaration_constraint_value : Node_ID := INVALID_NODE_ID;

      when Enumeration_Type_Declaration_Node =>
        enumeration_type_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        enumeration_type_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        enumeration_literals_value :
          Program_Unit_Name_Component_Vectors.Vector;

      when Discriminant_Specification_Node =>
        discriminant_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        discriminant_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        discriminant_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        discriminant_default_expression_value : Node_ID := INVALID_NODE_ID;

      when Record_Component_Declaration_Node =>
        record_component_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        record_component_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        record_component_aliased_value : Boolean := False;
        record_component_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        record_component_default_expression_value : Node_ID := INVALID_NODE_ID;

      when Record_Variant_Node =>
        record_variant_choices_value : Node_Vectors.Vector;
        record_variant_components_value : Node_Vectors.Vector;
        record_variant_null_component_list_value : Boolean := False;

      when Record_Variant_Part_Node =>
        record_variant_part_discriminant_name_value : Node_ID :=
          INVALID_NODE_ID;
        record_variant_part_variants_value : Node_Vectors.Vector;

      when Record_Type_Declaration_Node =>
        record_type_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        record_type_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        record_type_limited_value : Boolean := False;
        record_discriminants_value : Node_Vectors.Vector;
        record_components_value : Node_Vectors.Vector;
        record_variant_part_value : Node_ID := INVALID_NODE_ID;

      when Access_Object_Type_Declaration_Node =>
        access_object_type_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        access_object_type_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        access_object_type_modifier_value : General_Access_Modifier_Kind :=
          No_General_Access_Modifier;
        access_object_type_designated_subtype_value : Node_ID :=
          INVALID_NODE_ID;

      when Package_Renaming_Declaration_Node =>
        package_renaming_defining_name_value :
          Program_Unit_Name_Component_Vectors.Vector;
        package_renaming_renamed_package_value : Node_ID := INVALID_NODE_ID;

      when Package_Instantiation_Node =>
        package_instantiation_defining_name_value :
          Program_Unit_Name_Component_Vectors.Vector;
        package_instantiation_generic_name_value : Node_ID := INVALID_NODE_ID;
        package_instantiation_actuals_value :
          Generic_Actual_Association_Vectors.Vector;

      when Package_Declaration_Node =>
        package_defining_name_value :
          Program_Unit_Name_Component_Vectors.Vector;
        package_visible_declarations_value : Node_Vectors.Vector;
        package_private_part_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        package_private_declarations_value : Node_Vectors.Vector;
        package_end_name_value : Program_Unit_Name_Component_Vectors.Vector;

      when Package_Body_Stub_Node =>
        package_body_stub_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        package_body_stub_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;

      when Package_Body_Node =>
        body_defining_name_value :
          Program_Unit_Name_Component_Vectors.Vector;
        body_declarations_value : Node_Vectors.Vector;
        body_end_name_value : Program_Unit_Name_Component_Vectors.Vector;

      when Exit_Statement_Node =>
        exit_loop_name_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        exit_loop_name_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        exit_when_span_value : Adac.Source.Span := Adac.Source.INVALID_SPAN;
        exit_condition_value : Node_ID := INVALID_NODE_ID;

      when Return_Statement_Node =>
        return_expression_value : Node_ID := INVALID_NODE_ID;

      when Extended_Return_Statement_Node =>
        extended_return_symbol_value : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        extended_return_defining_span_value : Adac.Source.Span :=
          Adac.Source.INVALID_SPAN;
        extended_return_subtype_mark_value : Node_ID := INVALID_NODE_ID;
        extended_return_handled_sequence_value : Node_ID := INVALID_NODE_ID;

      when Raise_Statement_Node =>
        raise_form_value : Raise_Statement_Form :=
          Named_With_Message_Raise_Form;
        raise_exception_name_value : Node_ID := INVALID_NODE_ID;
        raise_message_expression_value : Node_ID := INVALID_NODE_ID;

      when Null_Statement_Node =>
        null;
    end case;
  end record;

  package Node_Storage_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Node);

  package Parameter_Defining_Name_List_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Program_Unit_Name);

  type Store is limited record
    initialized : Boolean := False;
    marker      : aliased Store_Marker;
    nodes       : Node_Storage_Vectors.Vector;
    parameter_additional_defining_names :
      Parameter_Defining_Name_List_Vectors.Vector;
  end record;

end Adac.AST;
