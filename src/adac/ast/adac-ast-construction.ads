-- ============================================================================
-- adac-ast-construction.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Source;
with Adac.Symbols;

package Adac.AST.Construction is

  --! summary: Append one lexically validated numeric-literal node.
  --! contract
  --!   `spelling` must be nonempty and `span` must cover exactly that ASCII
  --!   token spelling on one source line.
  function append_numeric_literal
    (self          : in out Store;
     form          : Numeric_Literal_Kind;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one lexically validated character-literal node.
  --! contract
  --!   `spelling` must be exactly one current ASCII graphic character between
  --!   apostrophes and `span` must cover exactly those three source columns.
  function append_character_literal
    (self          : in out Store;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one lexically validated string-literal node.
  --! contract
  --!   `spelling` must include its quotation-mark brackets and `span` must
  --!   cover exactly that ASCII token spelling on one source line.
  function append_string_literal
    (self          : in out Store;
     spelling      : String;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current `null` literal expression.
  function append_null_literal
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current named record aggregate.
  --! contract
  --!   Each association value must be an earlier nonaggregate simple
  --!   expression whose transitive expression subtree contains no record
  --!   aggregate or qualified expression.
  function append_record_aggregate
    (self          : in out Store;
     associations  : Record_Component_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current named array aggregate.
  --! contract
  --!   Each association owns a nonempty source-ordered choice list and one
  --!   later nonaggregate simple-expression value.
  function append_array_aggregate
    (self          : in out Store;
     associations  : Array_Component_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one bounded positional bracket aggregate.
  --! contract
  --!   `expressions` is a nonempty source-ordered list of earlier current
  --!   allocator expressions contained by `span`.
  function append_bracket_aggregate
    (self          : in out Store;
     expressions   : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one bounded qualified expression.
  --! contract
  --!   `subtype_mark` must be an earlier simple name. `operand` must be an
  --!   earlier unqualified record/array aggregate or current qualified-direct
  --!   operand whose transitive expression graph contains no aggregate or
  --!   qualified expression. `span` includes the complete qualification.
  function append_qualified_expression
    (self          : in out Store;
     subtype_mark  : Node_ID;
     operand       : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current `new qualified_expression` allocator.
  function append_allocator
    (self          : in out Store;
     new_span      : Adac.Source.Span;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current `if ... then ... else ...` expression.
  --! contract
  --!   `condition`, `then_expression`, and `else_expression` must identify
  --!   earlier current simple expressions in source order within `span`.
  function append_if_expression
    (self            : in out Store;
     condition       : Node_ID;
     then_expression : Node_ID;
     else_expression : Node_ID;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one bounded case-expression alternative.
  --! contract
  --!   `choices` must be a nonempty ordered list of earlier identifier or
  --!   `others` choices, followed in source order by one earlier represented
  --!   simple dependent expression.
  function append_case_expression_alternative
    (self          : in out Store;
     choices       : Node_List;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one bounded Ada 2022 raise expression.
  --! contract
  --!   `exception_name` must be an earlier current simple name. `message` may
  --!   be `INVALID_NODE_ID` or a later earlier represented simple expression.
  function append_raise_expression
    (self           : in out Store;
     exception_name : Node_ID;
     message        : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one bounded Ada case conditional expression.
  --! contract
  --!   `selecting_expression` must be an earlier represented simple expression;
  --!   `alternatives` must be a nonempty ordered list of earlier current
  --!   `Case_Expression_Alternative_Node` values.
  function append_case_expression
    (self                 : in out Store;
     selecting_expression : Node_ID;
     alternatives         : Node_List;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current parenthesized expression primary.
  --! contract
  --!   `expression` must identify an earlier represented simple expression or
  --!   current `If_Expression_Node` / `Case_Expression_Node`; `span` must
  --!   bracket the complete child span.
  function append_parenthesized_expression
    (self          : in out Store;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current unary operator node.
  --! contract
  --!   The represented spellings are unary `+`/`-` and `abs`/`not`; the
  --!   operand must satisfy the corresponding term/primary boundary and follow
  --!   the operator in source order.
  function append_unary_operator
    (self              : in out Store;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     operand           : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current binary-exponentiating node.
  --! contract
  --!   Both operands must identify earlier represented primaries; the exact
  --!   `**` operator must lie between them in source order.
  function append_binary_exponentiating
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current binary-multiplying node.
  --! contract
  --!   `left_operand` must identify an earlier represented current term and
  --!   `right_operand` an earlier represented current factor; the operator
  --!   must lie between them.
  function append_binary_multiplying
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current binary-adding node.
  --! contract
  --!   `left_operand` must identify an earlier represented simple expression
  --!   and `right_operand` an earlier represented current term; the operator
  --!   must lie between them.
  function append_binary_adding
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current binary relation node.
  --! contract
  --!   `left_operand` and `right_operand` must identify earlier represented
  --!   expression operands in `self`; the operator must lie between them.
  function append_relation
    (self              : in out Store;
     left_operand      : Node_ID;
     operator_spelling : String;
     operator_span     : Adac.Source.Span;
     right_operand     : Node_ID;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one explicit-range membership choice.
  --! contract
  --!   Both bounds must be earlier represented simple expressions;
  --!   `range_span` is the exact `..` delimiter between them.
  function append_membership_range_choice
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current membership expression.
  --! contract
  --!   `tested` must be an earlier represented simple expression; every
  --!   choice must be either an earlier represented simple expression or an
  --!   explicit-range membership choice.
  --!   `not_span` is valid only for `Not_In_Membership_Operator`; `in_span` is
  --!   always required and all children must remain in source order.
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

  --! summary: Append one current logical operator expression.
  function append_logical_expression
    (self          : in out Store;
     left_operand  : Node_ID;
     operator_kind : Logical_Operator_Kind;
     operator_span : Adac.Source.Span;
     right_operand : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current short-circuit control form.
  --! contract
  --!   The operands must be earlier represented expressions in source order;
  --!   repeated operators form a left-associated chain.
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

  --! summary: Append one identifier-name node.
  function append_identifier_name
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one selected-name node.
  --! contract
  --!   `prefix` must identify an earlier identifier or selected name in
  --!   `self`; `span` must contain both the prefix and selector spans.
  function append_selected_name
    (self          : in out Store;
     prefix        : Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one explicit-dereference name node.
  --! contract
  --!   `prefix` must identify an earlier current name in `self`; `all_span`
  --!   is the exact reserved-word token span and `span` covers `name.all`.
  function append_explicit_dereference_name
    (self          : in out Store;
     prefix        : Node_ID;
     all_span      : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one selected-component node after a non-simple name.
  --! contract
  --!   `prefix` must identify an earlier parenthesized name or selected
  --!   component in `self`; `span` must contain both prefix and selector.
  function append_selected_component
    (self          : in out Store;
     prefix        : Node_ID;
     selector      : Adac.Symbols.Symbol_ID;
     selector_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one parenthesized-name staging node.
  --! contract
  --!   `prefix` must identify an earlier current parenthesized-prefix name and
  --!   every item an earlier current name in `self`; `items` must be nonempty
  --!   and contained by `span`.
  function append_parenthesized_name
    (self          : in out Store;
     prefix        : Node_ID;
     items         : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one parenthesized name with association metadata.
  function append_parenthesized_name
    (self          : in out Store;
     prefix        : Node_ID;
     items         : Parenthesized_Name_Item_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current explicit-range slice name.
  --! contract
  --!   `prefix` must be an earlier simple or identifier-attribute name. Both
  --!   bounds must be
  --!   earlier represented simple expressions surrounding `range_span`.
  function append_slice_name
    (self          : in out Store;
     prefix        : Node_ID;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current identifier-attribute name node.
  --! contract
  --!   `prefix` must identify an earlier simple name in `self`; the designator
  --!   span must follow the prefix and close `span`.
  function append_attribute_name
    (self            : in out Store;
     prefix          : Node_ID;
     designator      : Adac.Symbols.Symbol_ID;
     designator_span : Adac.Source.Span;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one bounded aspect specification node.
  --! contract
  --!   `mark_span` identifies the aspect identifier after `with` and
  --!   `definition` is an earlier represented expression following it. `span`
  --!   covers the complete selected `with mark => definition` syntax.
  function append_aspect_specification
    (self          : in out Store;
     mark_symbol   : Adac.Symbols.Symbol_ID;
     mark_span     : Adac.Source.Span;
     definition    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one parameter specification with defining identifiers.
  --! contract
  --!   `defining_identifiers` is nonempty and source-ordered before the earlier
  --!   simple-name `subtype_mark`; all child spans are contained by `span`.
  function append_parameter_specification
    (self                 : in out Store;
     defining_identifiers : Defining_Identifier_List;
     mode                 : Parameter_Mode_Kind;
     subtype_mark         : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append an identifier-list parameter with a default expression.
  function append_parameter_specification
    (self                 : in out Store;
     defining_identifiers : Defining_Identifier_List;
     mode                 : Parameter_Mode_Kind;
     subtype_mark         : Node_ID;
     default_expression   : Node_ID;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current parameter-specification node.
  --! contract
  --!   `subtype_mark` must identify an earlier identifier or selected name in
  --!   `self`; defining and subtype spans must be contained by `span`.
  function append_parameter_specification
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     mode          : Parameter_Mode_Kind;
     subtype_mark  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one parameter with a represented default expression.
  --! contract
  --!   `default_expression` must identify an earlier current expression after
  --!   `subtype_mark`; the parameter span ends with that expression.
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

  --! summary: Append one current object-declaration node.
  --! contract
  --!   `subtype_mark` must identify an earlier identifier or selected name.
  --!   A present `initializer` must identify an earlier current represented
  --!   expression. A missing initializer represents either a variable without
  --!   initialization or a caller-selected deferred constant.
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

  --! summary: Append one object declaration with an index constraint.
  --! contract
  --!   `index_constraint` must identify an earlier current index constraint
  --!   following `subtype_mark`; all other object-declaration rules are shared.
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

  --! summary: Append one current object-renaming declaration.
  --! contract
  --!   `subtype_mark` must identify an earlier simple name and `renamed_name`
  --!   an earlier current name following it in source order.
  function append_object_renaming_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     renamed_name  : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current number-declaration node.
  --! contract
  --!   `initializer` must identify an earlier current expression in `self`;
  --!   defining and initializer spans must be contained by `span`.
  function append_number_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     initializer   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current exception declaration.
  --! contract
  --!   `defining_span` identifies the single defining identifier inside the
  --!   complete declaration `span`, which includes the terminating semicolon.
  function append_exception_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current procedure declaration.
  --! contract
  --!   `defining_span` must identify the defining identifier and `parameters`
  --!   must contain earlier parameter specifications in source order inside the
  --!   complete `procedure ...;` declaration `span`.
  function append_procedure_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current procedure-body stub.
  --! contract
  --!   `defining_span` identifies the procedure defining identifier;
  --!   `parameters` contains earlier parameter specifications in source order
  --!   and `span` covers the complete `procedure ... is separate;` form.
  function append_procedure_body_stub
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     parameters    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current function declaration.
  --! contract
  --!   `defining_span` identifies the function defining identifier;
  --!   `parameters` contains earlier current parameter specifications and
  --!   `result_subtype` an earlier simple result subtype mark. `aspect` may be
  --!   invalid or one later-but-earlier bounded aspect specification.
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

  --! summary: Append one current expression-function declaration.
  --! contract
  --!   `expression` identifies an earlier represented expression after the
  --!   result subtype and before the optional `aspect`.
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

  --! summary: Append one current private-type declaration.
  --! contract
  --!   `defining_span` must identify the defining identifier inside the
  --!   complete `type ... is [limited] private;` declaration `span`;
  --!   `discriminants` may be empty and otherwise contains earlier current
  --!   discriminant specifications in source order before `is`;
  --!   `limited_form` records whether the reserved word is present.
  function append_private_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     discriminants : Node_List;
     span          : Adac.Source.Span;
     limited_form  : Boolean := False;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current unconstrained derived-type declaration.
  --! contract
  --!   `parent_subtype_mark` must identify an earlier simple name after the
  --!   defining identifier and inside the complete declaration `span`.
  function append_derived_type_declaration
    (self                : in out Store;
     symbol              : Adac.Symbols.Symbol_ID;
     defining_span       : Adac.Source.Span;
     parent_subtype_mark : Node_ID;
     span                : Adac.Source.Span;
     maximum_nodes       : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one explicit scalar range constraint.
  --! contract
  --!   `lower_bound` and `upper_bound` must be earlier represented expressions
  --!   in source order inside `span`, whose first position is the `range`
  --!   token.
  function append_range_constraint
    (self          : in out Store;
     lower_bound   : Node_ID;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one single-range index constraint.
  --! contract
  --!   Both bounds must be earlier represented simple expressions surrounding
  --!   the exact `range_span`; `span` includes the enclosing parentheses.
  function append_index_constraint
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current subtype declaration.
  --! contract
  --!   `subtype_mark` must be an earlier simple name after `defining_span`. An
  --!   optional `constraint` must be an earlier range constraint after that
  --!   mark.
  function append_subtype_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     constraint    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current identifier-only enumeration type.
  --! contract
  --!   `literals` must be nonempty and every defining span must follow the type
  --!   defining identifier in source order within the declaration `span`.
  function append_enumeration_type_declaration
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     literals      : Enumeration_Literal_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current discriminant specification.
  --! contract
  --!   `aliased_form` preserves the optional `aliased` source modifier.
  --!   `subtype_mark` must identify an earlier simple name. A present default
  --!   expression must identify an earlier represented expression after the
  --!   subtype mark. `span` begins at the defining identifier and ends at the
  --!   subtype mark or default expression.
  function append_discriminant_specification
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     subtype_mark       : Node_ID;
     default_expression : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current record-component declaration.
  --! contract
  --!   `subtype_mark` must identify an earlier simple name. A present default
  --!   expression must identify an earlier represented expression after the
  --!   subtype mark. Every child span must be contained by `span`.
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

  --! summary: Append one current record variant.
  --! contract
  --!   `choices` must be nonempty earlier identifier-name nodes. Exactly one of
  --!   a nonempty `components` list or `null_component_list=True` represents
  --!   the
  --!   variant component list.
  function append_record_variant
    (self                : in out Store;
     choices             : Node_List;
     components          : Node_List;
     null_component_list : Boolean;
     span                : Adac.Source.Span;
     maximum_nodes       : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current record variant part.
  function append_record_variant_part
    (self              : in out Store;
     discriminant_name : Node_ID;
     variants          : Node_List;
     span              : Adac.Source.Span;
     maximum_nodes     : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current record-type declaration.
  --! contract
  --!   `limited_form` preserves the optional `limited` source modifier.
  --!   `discriminants` contains earlier discriminant specifications in source
  --!   order. `components` contains earlier ordinary record components after
  --!   them. `variant_part`, when present, follows the ordinary components. At
  --!   least one ordinary component or a variant part must be present.
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

  --! summary: Append one current access-to-object type declaration.
  --! contract
  --!   `designated_subtype` must identify an earlier simple name after the
  --!   defining identifier. `modifier` preserves the optional general access
  --!   modifier source form.
  function append_access_object_type_declaration
    (self               : in out Store;
     symbol             : Adac.Symbols.Symbol_ID;
     defining_span      : Adac.Source.Span;
     modifier           : General_Access_Modifier_Kind;
     designated_subtype : Node_ID;
     span               : Adac.Source.Span;
     maximum_nodes      : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current `others` exception-choice node.
  function append_others_exception_choice
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current exception-handler node.
  --! contract
  --!   `choice_parameter_symbol` is `INVALID_SYMBOL_ID` exactly when the
  --!   optional choice parameter is absent; otherwise its defining span is
  --!   valid and contained by `span`. `choices` and `statements` must be
  --!   nonempty, ordered lists of earlier current choices and statements.
  function append_exception_handler
    (self                    : in out Store;
     choice_parameter_symbol : Adac.Symbols.Symbol_ID;
     choice_parameter_span   : Adac.Source.Span;
     choices                 : Node_List;
     statements              : Node_List;
     span                    : Adac.Source.Span;
     maximum_nodes           : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current handled-sequence node.
  --! contract
  --!   `statements` must be nonempty; every statement and handler must be an
  --!   earlier current node in source order and contained by `span`.
  function append_handled_sequence
    (self          : in out Store;
     statements    : Node_List;
     handlers      : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current elsif-part node.
  --! contract
  --!   `condition` must identify an earlier represented expression and
  --!   `statements` a nonempty ordered list of earlier current branch
  --!   statements.
  --!   `span` begins at `elsif` and ends at the final statement.
  function append_elsif_part
    (self          : in out Store;
     condition     : Node_ID;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current if-statement node.
  --! contract
  --!   `condition` must identify an earlier represented expression.
  --!   `then_statements` must be nonempty; both branch lists must contain
  --!   earlier represented current statements in source order within `span`.
  function append_if_statement
    (self            : in out Store;
     condition       : Node_ID;
     then_statements : Node_List;
     elsif_parts     : Node_List;
     else_statements : Node_List;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current assignment statement node.
  --! contract
  --!   `target` must identify an earlier represented current name and
  --!   `expression` an earlier represented expression. `span` must contain
  --!   both children in source order and include the terminating semicolon.
  function append_assignment_statement
    (self          : in out Store;
     target        : Node_ID;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current explicit-range case-choice node.
  --! contract
  --!   Both bounds must be earlier represented character literals. `range_span`
  --!   is the exact `..` delimiter and `span` runs from the lower through upper
  --!   bound with all three parts in source order.
  function append_case_range_choice
    (self          : in out Store;
     lower_bound   : Node_ID;
     range_span    : Adac.Source.Span;
     upper_bound   : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current `others` case-choice node.
  function append_others_case_choice
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current case-alternative node.
  --! contract
  --!   `choices` and `statements` must be nonempty ordered lists of earlier
  --!   current choice and statement nodes contained by `span`; `others`, when
  --!   present, must be the sole choice.
  function append_case_alternative
    (self          : in out Store;
     choices       : Node_List;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current case-statement node.
  --! contract
  --!   `selecting_expression` must be an earlier represented expression and
  --!   `alternatives` a nonempty ordered list of earlier case alternatives.
  function append_case_statement
    (self                 : in out Store;
     selecting_expression : Node_ID;
     alternatives         : Node_List;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current unlabeled block-statement node.
  --! contract
  --!   `declarations` contains earlier current object declarations in source
  --!   order and `handled_sequence` identifies the earlier current block body
  --!   under the bounded block-shape contract documented in ast-model.md.
  function append_block_statement
    (self             : in out Store;
     declarations     : Node_List;
     handled_sequence : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current unlabeled loop without an iteration scheme.
  --! contract
  --!   `statements` must be a nonempty ordered current loop-body statement
  --!   list. The loop owns no condition or iterator-header syntax.
  function append_simple_loop_statement
    (self          : in out Store;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current unlabeled `while` loop statement.
  --! contract
  --!   `condition` must identify an earlier represented expression and
  --!   `statements` a nonempty ordered current loop-body statement list.
  function append_while_loop_statement
    (self          : in out Store;
     condition     : Node_ID;
     statements    : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one ordinary unlabeled discrete-range `for` loop.
  --! contract
  --!   `parameter_symbol` and `parameter_span` preserve the defining
  --!   identifier. `lower_bound` and `upper_bound` are earlier represented
  --!   simple expressions in source order and `statements` is nonempty.
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

  --! summary: Append one ordinary `for` loop using a `Range` attribute.
  --! contract
  --!   `parameter_symbol` and `parameter_span` preserve the defining
  --!   identifier. `range_attribute` is an earlier represented `Range`
  --!   attribute name and `statements` is nonempty.
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

  --! summary: Append one current unlabeled iterator-loop statement.
  --! contract
  --!   `parameter_symbol` and `parameter_span` preserve the defining
  --!   identifier. `iterable_name` is an earlier simple name and `statements`
  --!   is a nonempty ordered list of current call, if, or block statements.
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

  --! summary: Append one positional-only procedure-call statement node.
  --! contract
  --!   `callable_name` must identify an earlier represented current name and
  --!   every item in `actuals` an earlier represented expression in source
  --!   order. `span` must contain all children and end after the final child.
  function append_procedure_call_statement
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one association-aware procedure-call statement node.
  --! contract
  --!   Positional actuals may precede named actuals. A named actual must own an
  --!   earlier identifier selector followed by an earlier represented actual
  --!   expression. No positional actual may follow a named association.
  function append_procedure_call_statement
    (self          : in out Store;
     callable_name : Node_ID;
     actuals       : Procedure_Call_Actual_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one selected extended-return statement.
  --! contract
  --!   The defining symbol/span and earlier simple subtype mark must precede an
  --!   earlier handler-free handled sequence containing only assignments;
  --!   `span` must contain all children and the exact closing syntax.
  function append_extended_return_statement
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     subtype_mark  : Node_ID;
     sequence      : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current Ada 2022 exit statement.
  --! contract
  --!   Loop-name symbol/span presence must agree. `when_span` is present
  --!   exactly when `condition` is present; the condition must be an earlier
  --!   represented expression following the optional loop name.
  function append_exit_statement
    (self             : in out Store;
     loop_name_symbol : Adac.Symbols.Symbol_ID;
     loop_name_span   : Adac.Source.Span;
     when_span        : Adac.Source.Span;
     condition        : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current return statement.
  --! contract
  --!   `expression` may be invalid for a bare return; when present it must be
  --!   an earlier represented expression contained by `span`.
  function append_return_statement
    (self          : in out Store;
     expression    : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one bare `raise;` re-raise statement.
  --! contract
  --!   `span` covers the complete statement through its semicolon. The node
  --!   owns no exception-name or message child.
  function append_bare_raise_statement
    (self          : in out Store;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current raise-with-message statement.
  --! contract
  --!   `exception_name` must identify an earlier identifier/selected name and
  --!   `message` an earlier represented expression. Both children must be
  --!   source ordered inside the complete statement `span`.
  function append_raise_statement
    (self           : in out Store;
     exception_name : Node_ID;
     message        : Node_ID;
     span           : Adac.Source.Span;
     maximum_nodes  : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one structurally valid statement node.
  --! contract: `kind` must identify a statement node.
  function append_statement
    (self          : in out Store;
     kind          : Node_Kind;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current plain with-clause node.
  --! contract
  --!   `names` must be nonempty and every item must identify an earlier simple
  --!   name contained by `span`.
  function append_with_clause
    (self          : in out Store;
     names         : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current `use type` clause.
  --! contract
  --!   `subtype_marks` must be a nonempty ordered list of earlier represented
  --!   simple names contained by `span`; the span includes the semicolon.
  function append_use_type_clause
    (self          : in out Store;
     subtype_marks : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current package `use` clause.
  --! contract
  --!   `package_names` must be a nonempty ordered list of earlier represented
  --!   simple names contained by `span`; the span includes the semicolon.
  function append_use_package_clause
    (self          : in out Store;
     package_names : Node_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current package-renaming declaration.
  --! contract
  --!   `defining_name` must be nonempty and source ordered; `renamed_package`
  --!   must identify an earlier identifier/selected name inside `span`.
  function append_package_renaming_declaration
    (self            : in out Store;
     defining_name   : Program_Unit_Name;
     renamed_package : Node_ID;
     span            : Adac.Source.Span;
     maximum_nodes   : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current generic package-instantiation node.
  --! contract
  --!   `defining_name` must be nonempty. `generic_name` and every named actual
  --!   must identify earlier current-name nodes in source order inside `span`.
  function append_package_instantiation
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     generic_name  : Node_ID;
     actuals       : Generic_Actual_Association_List;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current package-declaration node.
  --! contract
  --!   Visible/private declarations must identify earlier current declaration
  --!   nodes in source order. A nonempty private list requires a valid explicit
  --!   `private_part_span`. Every child and explicit boundary must be contained
  --!   by `span` and precede the closing name.
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

  --! summary: Append a package declaration with an implicit empty private part.
  function append_package_declaration
    (self                 : in out Store;
     defining_name        : Program_Unit_Name;
     visible_declarations : Node_List;
     end_name             : Program_Unit_Name;
     span                 : Adac.Source.Span;
     maximum_nodes        : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one selected package-body stub node.
  --! contract
  --!   `symbol` and `defining_span` identify the defining identifier and `span`
  --!   covers the complete `package body ... is separate;` source form.
  function append_package_body_stub
    (self          : in out Store;
     symbol        : Adac.Symbols.Symbol_ID;
     defining_span : Adac.Source.Span;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current package-body node.
  --! contract
  --!   `declarations` must contain only earlier represented package-body
  --!   declarative items in source order. `end_name` may be empty when the
  --!   optional closing
  --!   designator is absent. Every child span must be contained by `span`.
  function append_package_body
    (self          : in out Store;
     defining_name : Program_Unit_Name;
     declarations  : Node_List;
     end_name      : Program_Unit_Name;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one current procedure-body node.
  --! contract
  --!   Parameters and declarations must identify earlier current child nodes in
  --!   source order. `handled_sequence` must identify an earlier handled
  --!   sequence. `end_symbol` may be `INVALID_SYMBOL_ID` when the optional
  --!   closing designator is absent. Every child span must be contained by
  --!   `span`.
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

  --! summary: Append one current function-body node.
  --! contract
  --!   Parameters, result subtype, declarations, and handled sequence
  --!   must identify earlier current children in source order. `end_symbol` may
  --!   be invalid when the optional closing designator is absent.
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

  --! summary: Append one Ada subunit around an earlier proper body.
  --! contract
  --!   `parent_unit_name` must be nonempty and source ordered before the
  --!   earlier `proper_body`; the complete `span` begins at `separate` and ends
  --!   with the proper body.
  function append_subunit
    (self             : in out Store;
     parent_unit_name : Program_Unit_Name;
     proper_body      : Node_ID;
     span             : Adac.Source.Span;
     maximum_nodes    : Natural := Natural'Last)
  return Node_ID;

  --! summary: Append one structurally valid compilation-unit root.
  --! contract
  --!   Every context item must identify an earlier with clause and
  --!   `unit_item` must identify an earlier current library item or subunit in
  --!   `self`.
  function append_compilation_unit
    (self          : in out Store;
     context_items : Node_List;
     unit_item     : Node_ID;
     span          : Adac.Source.Span;
     maximum_nodes : Natural := Natural'Last)
  return Node_ID;

end Adac.AST.Construction;
