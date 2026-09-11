-- ============================================================================
-- adac-frontend-parser-parse_expression_staging.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.Frontend.Parser)
procedure parse_expression_staging
  (self                : in out Parser;
   context             : in out Adac.Compilation.Context;
   terminator          : Token_Kind;
   terminator_mode     : Expression_Terminator_Mode;
   completion_mode     : Expression_Completion_Mode;
   publish_expression_syntax : Boolean;
   syntax_node         : out Adac.AST.Node_ID;
   grammar_level       : Expression_Grammar_Level := Full_Expression_Level;
   accept_relation_expression : Boolean := False;
   accept_unary_expression : Boolean := False)
is
  type Primary_Form is
    (No_Primary,
     Numeric_Primary,
     Character_Primary,
     String_Primary,
     Null_Primary,
     Allocator_Primary,
     Parenthesized_Primary,
     Bracket_Primary,
     Name_Primary);

  type Delimiter_Form is
    (Parenthesized_Delimiter,
     Bracket_Delimiter);

  type Logical_Form is
    (No_Logical_Form,
     And_Logical_Form,
     And_Then_Logical_Form,
     Or_Logical_Form,
     Or_Else_Logical_Form,
     Xor_Logical_Form);

  position                 : constant Adac.Source.Position
                           := self.current.position;
  limits                   : constant Adac.Resources.Limits :=
    Adac.Compilation.resource_limits (context);
  text                     : Ada.Strings.Unbounded.Unbounded_String;
  first_form               : Primary_Form := No_Primary;
  staged_name_node         : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  latest_primary_node      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  latest_factor_node       : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  latest_term_node         : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  latest_simple_expression_node : Adac.AST.Node_ID :=
    Adac.AST.INVALID_NODE_ID;
  relation_left_operand    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  relation_right_operand   : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  relation_operator_text   : Ada.Strings.Unbounded.Unbounded_String;
  relation_operator_span   : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  membership_choices       : Adac.AST.Node_List;
  membership_operator_kind : Adac.AST.Membership_Operator_Kind :=
    Adac.AST.In_Membership_Operator;
  membership_not_span      : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  membership_in_span       : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  logical_expression_node  : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  has_relation_candidate   : Boolean := False;
  has_membership_candidate : Boolean := False;
  has_unrepresented_top_level : Boolean := False;
  expression_nesting       : Natural := 0;
  expression_call_depth    : Natural := 0;
  profile_nesting          : Natural := 0;
  has_operator             : Boolean := False;
  has_attribute            : Boolean := False;
  has_explicit_dereference : Boolean := False;
  has_parenthesized_suffix : Boolean := False;
  has_conditional_expression     : Boolean := False;
  has_qualified_expression       : Boolean := False;
  has_aggregate_expression       : Boolean := False;
  has_qualified_aggregate        : Boolean := False;
  has_delta_aggregate            : Boolean := False;
  has_qualified_delta            : Boolean := False;
  has_bracket_aggregate          : Boolean := False;
  has_qualified_bracket          : Boolean := False;
  has_bracket_delta              : Boolean := False;
  has_qualified_bracket_delta    : Boolean := False;
  primary_count                  : Natural := 0;
  name_primary_count       : Natural := 0;
  direct_name_count        : Natural := 0;
  selector_primary_count   : Natural := 0;
  range_attribute_count    : Natural := 0;
  operator_count           : Natural := 0;
  non_simple_operator_count : Natural := 0;
  represented_record_aggregate_count : Natural := 0;
  represented_array_aggregate_count  : Natural := 0;

  procedure append_current is
  begin
    Ada.Strings.Unbounded.append (text, current_text (self));
    advance (self, context);
  end append_current;

  procedure report_ast_node_limit (position : Adac.Source.Position) is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context, position, "AST node limit exceeded");
  end report_ast_node_limit;

  procedure append_spaced_token is
  begin
    if Ada.Strings.Unbounded.length (text) > 0 and then
       Ada.Strings.Unbounded.element
         (text, Ada.Strings.Unbounded.length (text)) /= ' ' and then
       Ada.Strings.Unbounded.element
         (text, Ada.Strings.Unbounded.length (text)) /= '(' and then
       Ada.Strings.Unbounded.element
         (text, Ada.Strings.Unbounded.length (text)) /= '['
    then
      Ada.Strings.Unbounded.append (text, " ");
    end if;

    Ada.Strings.Unbounded.append (text, current_text (self));
    Ada.Strings.Unbounded.append (text, " ");
    has_operator   := True;
    operator_count := operator_count + 1;
    advance (self, context);
  end append_spaced_token;

  procedure append_structural_token is
  begin
    if Ada.Strings.Unbounded.length (text) > 0 and then
       Ada.Strings.Unbounded.element
         (text, Ada.Strings.Unbounded.length (text)) /= ' ' and then
       Ada.Strings.Unbounded.element
         (text, Ada.Strings.Unbounded.length (text)) /= '(' and then
       Ada.Strings.Unbounded.element
         (text, Ada.Strings.Unbounded.length (text)) /= '['
    then
      Ada.Strings.Unbounded.append (text, " ");
    end if;

    Ada.Strings.Unbounded.append (text, current_text (self));
    Ada.Strings.Unbounded.append (text, " ");
    advance (self, context);
  end append_structural_token;

  procedure append_comma is
  begin
    Ada.Strings.Unbounded.append (text, current_text (self));
    Ada.Strings.Unbounded.append (text, " ");
    advance (self, context);
  end append_comma;

  procedure report_expression_expected (expected : String) is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "expected " &
       expected &
       ", got " &
       Token_Kind'image (self.current.kind) &
       " " &
       current_text (self));
  end report_expression_expected;

  procedure set_first_form (form : Primary_Form) is
  begin
    if first_form = No_Primary then
      first_form := form;
    end if;
  end set_first_form;

  procedure note_primary (is_name : Boolean := False) is
  begin
    primary_count := primary_count + 1;

    if is_name then
      name_primary_count := name_primary_count + 1;
    end if;
  end note_primary;

  function is_bare_subtype_mark
    (primary_before         : Natural;
     name_before            : Natural;
     range_attribute_before : Natural;
     operator_before        : Natural)
  return Boolean is
  begin
    return primary_count = primary_before + 1 and then
      name_primary_count = name_before + 1 and then
      range_attribute_count = range_attribute_before and then
      operator_count = operator_before;
  end is_bare_subtype_mark;

  function is_bare_selector_name
    (primary_before  : Natural;
     selector_before : Natural;
     operator_before : Natural)
  return Boolean is
  begin
    return primary_count = primary_before + 1 and then
      selector_primary_count = selector_before + 1 and then
      operator_count = operator_before;
  end is_bare_selector_name;

  function is_bare_range_attribute
    (primary_before         : Natural;
     name_before            : Natural;
     range_attribute_before : Natural;
     operator_before        : Natural)
  return Boolean is
  begin
    return primary_count = primary_before + 1 and then
      name_primary_count = name_before + 1 and then
      range_attribute_count = range_attribute_before + 1 and then
      operator_count = operator_before;
  end is_bare_range_attribute;

  procedure report_expression_nesting_limit is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "expression nesting limit exceeded");
  end report_expression_nesting_limit;

  procedure report_profile_nesting_limit is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "profile nesting limit exceeded");
  end report_profile_nesting_limit;

  procedure parse_expression;
  procedure parse_term;
  procedure parse_represented_term (node : out Adac.AST.Node_ID);
  procedure parse_simple_expression;
  procedure parse_represented_simple_expression
    (node : out Adac.AST.Node_ID);
  procedure parse_relation (allow_membership : Boolean);
  procedure parse_top_level_relation;
  procedure capture_top_level_relation_node
    (node : out Adac.AST.Node_ID);
  procedure parse_represented_current_expression
    (node : out Adac.AST.Node_ID);
  procedure parse_relation_tail (allow_membership : Boolean);
  procedure parse_logical_tail
    (allow_membership      : Boolean;
     publish_logical_syntax : Boolean := False);

  procedure parse_delimited_primary
    (form             : Primary_Form;
     is_qualified     : Boolean;
     delimiter        : Delimiter_Form;
     qualified_prefix : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID)
  is
    record_associations : Adac.AST.Record_Component_Association_List;
    array_associations  : Adac.AST.Array_Component_Association_List;
    bracket_expressions : Adac.AST.Node_List;
    qualified_child : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    can_publish_bracket_aggregate : Boolean :=
      publish_expression_syntax and then
      delimiter = Bracket_Delimiter and then
      not is_qualified;
    can_publish_record_aggregate : Boolean :=
      publish_expression_syntax and then
      delimiter = Parenthesized_Delimiter and then
      (not is_qualified or else
       qualified_prefix /= Adac.AST.INVALID_NODE_ID);
    can_publish_array_aggregate : Boolean :=
      publish_expression_syntax and then
      delimiter = Parenthesized_Delimiter and then
      is_qualified and then
      qualified_prefix /= Adac.AST.INVALID_NODE_ID;
    outer_primary_count  : constant Natural := primary_count;
    outer_name_count     : constant Natural := name_primary_count;
    outer_direct_count   : constant Natural := direct_name_count;
    outer_selector_count : constant Natural := selector_primary_count;
    outer_range_count    : constant Natural := range_attribute_count;
    outer_operator_count : constant Natural := operator_count;
    outer_non_simple_count : constant Natural := non_simple_operator_count;
    outer_has_operator   : constant Boolean := has_operator;

    function opening_kind return Token_Kind is
    begin
      if delimiter = Parenthesized_Delimiter then
        return Tok_Left_Parenthesis;
      end if;

      return Tok_Left_Bracket;
    end opening_kind;

    function closing_kind return Token_Kind is
    begin
      if delimiter = Parenthesized_Delimiter then
        return Tok_Right_Parenthesis;
      end if;

      return Tok_Right_Bracket;
    end closing_kind;

    procedure mark_aggregate is
    begin
      if delimiter = Bracket_Delimiter then
        has_bracket_aggregate := True;

        if is_qualified then
          has_qualified_bracket := True;
        end if;
      else
        has_aggregate_expression := True;

        if is_qualified then
          has_qualified_aggregate := True;
        end if;
      end if;
    end mark_aggregate;

    procedure mark_delta_aggregate is
    begin
      if delimiter = Bracket_Delimiter then
        has_bracket_delta := True;

        if is_qualified then
          has_qualified_bracket_delta := True;
        end if;
      else
        has_delta_aggregate := True;

        if is_qualified then
          has_qualified_delta := True;
        end if;
      end if;
    end mark_delta_aggregate;

    procedure report_aggregate_error
      (position : Adac.Source.Position;
       message  : String)
    is
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error (context, position, message);
    end report_aggregate_error;

    function is_qualified_direct_operand
      (node : Adac.AST.Node_ID)
    return Boolean is
      kind : Adac.AST.Node_Kind;
    begin
      if node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      kind := Adac.Compilation.Syntax.kind_of (context, node);
      return kind = Adac.AST.Numeric_Literal_Node or else
        kind = Adac.AST.Character_Literal_Node or else
        kind = Adac.AST.String_Literal_Node or else
        kind = Adac.AST.Null_Literal_Node or else
        kind = Adac.AST.Identifier_Name_Node or else
        kind = Adac.AST.Selected_Name_Node or else
        kind = Adac.AST.Selected_Component_Node or else
        kind = Adac.AST.Parenthesized_Name_Node or else
        kind = Adac.AST.Attribute_Name_Node or else
        kind = Adac.AST.Parenthesized_Expression_Node;
    end is_qualified_direct_operand;

    function is_nonaggregate_simple_expression
      (node : Adac.AST.Node_ID)
    return Boolean is
      kind : Adac.AST.Node_Kind;
    begin
      if node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      kind := Adac.Compilation.Syntax.kind_of (context, node);
      return kind = Adac.AST.Numeric_Literal_Node or else
        kind = Adac.AST.Character_Literal_Node or else
        kind = Adac.AST.String_Literal_Node or else
        kind = Adac.AST.Null_Literal_Node or else
        kind = Adac.AST.Parenthesized_Expression_Node or else
        kind = Adac.AST.Unary_Operator_Node or else
        kind = Adac.AST.Binary_Exponentiating_Node or else
        kind = Adac.AST.Binary_Multiplying_Node or else
        kind = Adac.AST.Binary_Adding_Node or else
        kind = Adac.AST.Identifier_Name_Node or else
        kind = Adac.AST.Selected_Name_Node or else
        kind = Adac.AST.Selected_Component_Node or else
        kind = Adac.AST.Parenthesized_Name_Node or else
        kind = Adac.AST.Attribute_Name_Node;
    end is_nonaggregate_simple_expression;

    function is_record_aggregate_value
      (node : Adac.AST.Node_ID)
    return Boolean is
    begin
      if node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      return Adac.Compilation.Syntax.kind_of (context, node) =
          Adac.AST.Record_Aggregate_Node or else
        is_nonaggregate_simple_expression (node);
    end is_record_aggregate_value;

    function simple_identifier_candidate
      (primary_before  : Natural;
       name_before     : Natural;
       operator_before : Natural)
    return Adac.AST.Node_ID is
    begin
      if primary_count = primary_before + 1 and then
         name_primary_count = name_before + 1 and then
         operator_count = operator_before and then
         latest_simple_expression_node /= Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.kind_of
           (context, latest_simple_expression_node) =
             Adac.AST.Identifier_Name_Node
      then
        return latest_simple_expression_node;
      end if;

      return Adac.AST.INVALID_NODE_ID;
    end simple_identifier_candidate;

    procedure append_bracket_expression (node : Adac.AST.Node_ID) is
    begin
      if not can_publish_bracket_aggregate then
        return;
      end if;

      if node = Adac.AST.INVALID_NODE_ID or else
         Adac.Compilation.Syntax.kind_of (context, node) /=
           Adac.AST.Allocator_Node
      then
        can_publish_bracket_aggregate := False;
        return;
      end if;

      Adac.AST.append (bracket_expressions, node);
    end append_bracket_expression;

    procedure publish_bracket_aggregate
      (opening_position : Adac.Source.Position;
       closing_position : Adac.Source.Position)
    is
    begin
      if not can_publish_bracket_aggregate or else
         Adac.AST.list_count (bracket_expressions) = 0
      then
        return;
      end if;

      latest_primary_node :=
        Adac.Compilation.Syntax.create_bracket_aggregate
          (context,
           bracket_expressions,
           Adac.Source.make_span (opening_position, closing_position));
      Adac.Compilation.Syntax.validate_bracket_aggregate
        (context, latest_primary_node);
    end publish_bracket_aggregate;

    procedure append_record_association
      (selector : Adac.AST.Node_ID;
       value    : Adac.AST.Node_ID)
    is
    begin
      if not can_publish_record_aggregate then
        return;
      end if;

      if selector = Adac.AST.INVALID_NODE_ID or else
         not is_record_aggregate_value (value)
      then
        can_publish_record_aggregate := False;
        return;
      end if;

      Adac.AST.append
        (record_associations,
         Adac.Compilation.Syntax.identifier_symbol (context, selector),
         Adac.Compilation.Syntax.node_span (context, selector),
         value);
    end append_record_association;

    procedure append_array_association
      (choice : Adac.AST.Node_ID;
       value  : Adac.AST.Node_ID)
    is
      choices : Adac.AST.Node_List;
    begin
      if not can_publish_array_aggregate then
        return;
      end if;

      if choice = Adac.AST.INVALID_NODE_ID or else
         Adac.Compilation.Syntax.kind_of (context, choice) /=
           Adac.AST.Numeric_Literal_Node or else
         not is_nonaggregate_simple_expression (value)
      then
        can_publish_array_aggregate := False;
        return;
      end if;

      Adac.AST.append (choices, choice);
      Adac.AST.append (array_associations, choices, value);
    end append_array_association;

    procedure parse_aggregate_value
      (allow_box : Boolean;
       value_node : out Adac.AST.Node_ID)
    is
      non_simple_before : constant Natural := non_simple_operator_count;
      record_aggregate_before : constant Natural :=
        represented_record_aggregate_count;
      array_aggregate_before  : constant Natural :=
        represented_array_aggregate_count;
    begin
      value_node := Adac.AST.INVALID_NODE_ID;

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Box then
        if not allow_box then
          report_aggregate_error
            (self.current.position,
             "box is not permitted in delta aggregate");
          return;
        end if;

        append_current;
        return;
      end if;

      parse_expression;

      if not self.failed and then
         non_simple_operator_count = non_simple_before and then
         represented_array_aggregate_count = array_aggregate_before
      then
        if represented_record_aggregate_count =
             record_aggregate_before and then
           is_nonaggregate_simple_expression (latest_simple_expression_node)
        then
          value_node := latest_simple_expression_node;
        elsif represented_record_aggregate_count >
                record_aggregate_before and then
              latest_simple_expression_node /=
                Adac.AST.INVALID_NODE_ID and then
              Adac.Compilation.Syntax.kind_of
                (context, latest_simple_expression_node) =
                  Adac.AST.Record_Aggregate_Node
        then
          value_node := latest_simple_expression_node;
        end if;
      end if;
    end parse_aggregate_value;

    procedure parse_aggregate_value (allow_box : Boolean) is
      ignored : Adac.AST.Node_ID;
    begin
      parse_aggregate_value (allow_box, ignored);
    end parse_aggregate_value;

    procedure parse_staged_range is
      primary_before         : constant Natural := primary_count;
      name_before            : constant Natural := name_primary_count;
      range_attribute_before : constant Natural := range_attribute_count;
      operator_before        : constant Natural := operator_count;
    begin
      parse_simple_expression;

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Double_Dot then
        append_structural_token;

        if self.failed then
          return;
        end if;

        parse_simple_expression;
        return;
      end if;

      if not is_bare_range_attribute
        (primary_before,
         name_before,
         range_attribute_before,
         operator_before)
      then
        report_expression_expected ("TOK_DOUBLE_DOT");
      end if;
    end parse_staged_range;

    procedure parse_choice_suffix (is_subtype_mark : Boolean) is
    begin
      if self.current.kind = Tok_Range then
        if not is_subtype_mark then
          report_aggregate_error
            (self.current.position,
             "range constraint requires a subtype mark");
          return;
        end if;

        append_structural_token;

        if not self.failed then
          parse_staged_range;
        end if;
      elsif self.current.kind = Tok_Double_Dot then
        append_structural_token;

        if self.failed then
          return;
        end if;

        parse_simple_expression;
      end if;
    end parse_choice_suffix;

    procedure parse_additional_choices is
    begin
      while not self.failed and then
            self.current.kind = Tok_Vertical_Bar
      loop
        append_structural_token;

        if self.failed then
          return;
        end if;

        declare
          primary_before  : constant Natural := primary_count;
          name_before     : constant Natural := name_primary_count;
          range_before    : constant Natural := range_attribute_count;
          operator_before : constant Natural := operator_count;
        begin
          parse_expression;

          if self.failed then
            return;
          end if;

          parse_choice_suffix
            (is_bare_subtype_mark
               (primary_before,
                name_before,
                range_before,
                operator_before));
        end;
      end loop;
    end parse_additional_choices;

    procedure parse_choice_list (first_is_subtype_mark : Boolean) is
    begin
      parse_choice_suffix (first_is_subtype_mark);

      if self.failed then
        return;
      end if;

      parse_additional_choices;
    end parse_choice_list;

    procedure parse_choice_tail
      (first_is_subtype_mark : Boolean;
       allow_box             : Boolean;
       value_node            : out Adac.AST.Node_ID)
    is
    begin
      value_node := Adac.AST.INVALID_NODE_ID;
      parse_choice_list (first_is_subtype_mark);

      if self.failed then
        return;
      end if;

      if self.current.kind /= Tok_Arrow then
        report_expression_expected ("TOK_ARROW");
        return;
      end if;

      append_structural_token;

      if self.failed then
        return;
      end if;

      parse_aggregate_value (allow_box, value_node);
    end parse_choice_tail;

    procedure parse_choice_tail
      (first_is_subtype_mark : Boolean;
       allow_box             : Boolean)
    is
      ignored : Adac.AST.Node_ID;
    begin
      parse_choice_tail (first_is_subtype_mark, allow_box, ignored);
    end parse_choice_tail;

    procedure parse_required_name
      (expected_name               : String;
       expected_after              : String;
       allow_parenthesized_suffix : Boolean)
    is
      has_qualified_apostrophe : Boolean := False;
      ignored_qualified_prefix : Adac.AST.Node_ID;
      has_range_attribute      : Boolean := False;
    begin
      if self.current.kind /= Tok_Identifier and then
         self.current.kind /= Tok_Invalid_Identifier
      then
        report_expression_expected (expected_name);
        return;
      end if;

      note_primary (is_name => True);
      parse_name_operand
        (self,
         context,
         text,
         has_attribute,
         has_explicit_dereference,
         has_parenthesized_suffix,
         has_qualified_apostrophe,
         ignored_qualified_prefix,
         has_range_attribute,
         direct_name_count,
         allow_parenthesized_suffix,
         publish_syntax => False,
         syntax_node    => staged_name_node);

      if self.failed then
        return;
      end if;

      if has_range_attribute then
        range_attribute_count := range_attribute_count + 1;
      end if;

      if has_qualified_apostrophe then
        report_expression_expected (expected_after);
      end if;
    end parse_required_name;

    procedure parse_loop_parameter_subtype_indication is
      type Composite_Item_Form is
        (Ambiguous_Composite_Item,
         Index_Composite_Item,
         Discriminant_Composite_Item);

      type Composite_Constraint_Form is
        (Unclassified_Composite,
         Index_Composite,
         Discriminant_Composite);

      procedure parse_optional_null_exclusion is
      begin
        if self.current.kind /= Tok_Not then
          return;
        end if;

        append_structural_token;

        if self.current.kind /= Tok_Null then
          report_expression_expected ("TOK_NULL");
          return;
        end if;

        append_structural_token;
      end parse_optional_null_exclusion;

      procedure parse_digits_expression is
      begin
        parse_relation (False);

        if not self.failed then
          parse_logical_tail (False);
        end if;
      end parse_digits_expression;

      procedure parse_discriminant_selector_name is
        spelling : constant String := current_text (self);
      begin
        case self.current.kind is
          when Tok_Identifier | Tok_Invalid_Identifier =>
            Ada.Strings.Unbounded.append (text, spelling);

            if parse_identifier_symbol (self, context) =
               Adac.Symbols.INVALID_SYMBOL_ID
            then
              return;
            end if;

          when Tok_Character_Literal =>
            append_current;

          when Tok_String_Literal =>
            if not is_operator_symbol (spelling) then
              report_invalid_operator_symbol (self, context);
              return;
            end if;

            append_current;

          when Tok_Invalid_String_Literal =>
            report_invalid_operator_symbol (self, context);

          when others =>
            report_expected_selector_name (self, context);
        end case;
      end parse_discriminant_selector_name;

      procedure parse_composite_constraint_association
        (item_form : out Composite_Item_Form;
         is_named  : out Boolean)
      is
        item_position   : constant Adac.Source.Position :=
          self.current.position;
        primary_before  : constant Natural := primary_count;
        name_before     : constant Natural := name_primary_count;
        selector_before : constant Natural := selector_primary_count;
        range_before    : constant Natural := range_attribute_count;
        operator_before : constant Natural := operator_count;
      begin
        item_form := Ambiguous_Composite_Item;
        is_named  := False;
        parse_simple_expression;

        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Double_Dot then
          item_form := Index_Composite_Item;
          append_structural_token;

          if self.failed then
            return;
          end if;

          parse_simple_expression;
          return;
        end if;

        parse_relation_tail (True);

        if not self.failed then
          parse_logical_tail (True);
        end if;

        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Range then
          if not is_bare_subtype_mark
            (primary_before,
             name_before,
             range_before,
             operator_before)
          then
            report_aggregate_error
              (self.current.position,
               "range constraint requires a subtype mark");
            return;
          end if;

          item_form := Index_Composite_Item;
          append_structural_token;

          if not self.failed then
            parse_staged_range;
          end if;

          return;
        end if;

        if self.current.kind /= Tok_Arrow and then
           self.current.kind /= Tok_Vertical_Bar
        then
          if not is_bare_subtype_mark
            (primary_before,
             name_before,
             range_before,
             operator_before) and then
             not is_bare_range_attribute
               (primary_before,
                name_before,
                range_before,
                operator_before)
          then
            item_form := Discriminant_Composite_Item;
          end if;

          return;
        end if;

        if not is_bare_selector_name
          (primary_before, selector_before, operator_before)
        then
          report_aggregate_error
            (item_position,
             "named discriminant association requires a selector name");
          return;
        end if;

        while self.current.kind = Tok_Vertical_Bar loop
          append_structural_token;

          if self.failed then
            return;
          end if;

          parse_discriminant_selector_name;

          if self.failed then
            return;
          end if;
        end loop;

        if self.current.kind /= Tok_Arrow then
          report_expression_expected ("TOK_ARROW");
          return;
        end if;

        append_structural_token;
        item_form := Discriminant_Composite_Item;
        is_named  := True;
        parse_expression;
      end parse_composite_constraint_association;

      procedure parse_access_object_tail
        (expected_name  : String;
         expected_after : String)
      is
      begin
        if self.current.kind = Tok_Constant then
          append_structural_token;

          if self.failed then
            return;
          end if;
        end if;

        parse_required_name
          (expected_name              => expected_name,
           expected_after             => expected_after,
           allow_parenthesized_suffix => True);
      end parse_access_object_tail;

      procedure parse_basic_formal_part;
      procedure parse_function_result (expected_after : String);

      procedure parse_access_subprogram_profile
        (expected_after : String)
      is
        procedure parse_profile_contents is
        begin
          if self.current.kind = Tok_Procedure then
            append_structural_token;

            if self.failed then
              return;
            end if;

            parse_basic_formal_part;
            return;
          end if;

          if self.current.kind /= Tok_Function then
            raise Program_Error with
              "access-subprogram parser received non-subprogram token";
          end if;

          append_structural_token;

          if self.failed then
            return;
          end if;

          parse_basic_formal_part;

          if self.failed then
            return;
          end if;

          if self.current.kind /= Tok_Return then
            report_expression_expected ("TOK_RETURN");
            return;
          end if;

          append_structural_token;

          if self.failed then
            return;
          end if;

          parse_function_result (expected_after);
        end parse_profile_contents;
      begin
        if self.current.kind /= Tok_Procedure and then
           self.current.kind /= Tok_Function
        then
          raise Program_Error with
            "access-subprogram parser received non-subprogram token";
        end if;

        if profile_nesting >= limits.maximum_profile_nesting then
          report_profile_nesting_limit;
          return;
        end if;

        profile_nesting := profile_nesting + 1;
        parse_profile_contents;
        profile_nesting := profile_nesting - 1;
      end parse_access_subprogram_profile;

      procedure parse_access_definition
        (expected_name  : String;
         expected_after : String)
      is
        has_protected : Boolean := False;
      begin
        if self.current.kind /= Tok_Access then
          raise Program_Error with
            "access-definition parser received non-access token";
        end if;

        append_structural_token;

        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Protected then
          has_protected := True;
          append_structural_token;

          if self.failed then
            return;
          end if;
        end if;

        if self.current.kind = Tok_Procedure or else
           self.current.kind = Tok_Function
        then
          parse_access_subprogram_profile (expected_after);
          return;
        end if;

        if has_protected then
          report_expression_expected ("TOK_PROCEDURE or TOK_FUNCTION");
          return;
        end if;

        parse_access_object_tail
          (expected_name  => expected_name,
           expected_after => expected_after);
      end parse_access_definition;

      procedure parse_basic_formal_part is
        procedure parse_formal_defining_identifier is
        begin
          if self.current.kind = Tok_Invalid_Identifier then
            report_invalid_identifier (self, context);
            return;
          elsif self.current.kind /= Tok_Identifier then
            report_expression_expected ("formal parameter identifier");
            return;
          end if;

          -- Formal defining identifiers have no binding entity in staging.
          append_current;
        end parse_formal_defining_identifier;

        procedure parse_parameter_mode is
        begin
          if self.current.kind = Tok_In then
            append_structural_token;

            if self.failed then
              return;
            end if;

            if self.current.kind = Tok_Out then
              append_structural_token;
            end if;
          elsif self.current.kind = Tok_Out then
            append_structural_token;
          end if;
        end parse_parameter_mode;

        procedure parse_parameter_subtype_mark
          (expected_name : String)
        is
        begin
          parse_required_name
            (expected_name              => expected_name,
             expected_after             =>
               "TOK_ASSIGN, TOK_WITH, TOK_SEMICOLON, or " &
               "TOK_RIGHT_PARENTHESIS",
             allow_parenthesized_suffix => True);
        end parse_parameter_subtype_mark;

        procedure parse_access_parameter_definition is
        begin
          parse_access_definition
            (expected_name  => "formal access parameter subtype mark",
             expected_after =>
               "TOK_ASSIGN, TOK_WITH, TOK_SEMICOLON, or " &
               "TOK_RIGHT_PARENTHESIS");
        end parse_access_parameter_definition;

        procedure parse_subtype_mark_parameter_definition is
        begin
          if self.current.kind = Tok_Aliased then
            append_structural_token;
          end if;

          parse_parameter_mode;

          if self.failed then
            return;
          end if;

          parse_optional_null_exclusion;

          if self.failed then
            return;
          end if;

          parse_parameter_subtype_mark ("formal parameter subtype mark");
        end parse_subtype_mark_parameter_definition;

        procedure parse_optional_parameter_default is
        begin
          if self.current.kind /= Tok_Assign then
            return;
          end if;

          append_structural_token;

          if self.failed then
            return;
          end if;

          parse_expression;
        end parse_optional_parameter_default;

        function is_class_designator return Boolean is
          spelling : constant String := current_text (self);
          expected : constant String := "class";
        begin
          if spelling'Length /= expected'Length then
            return False;
          end if;

          for index in spelling'Range loop
            if Ada.Characters.Handling.to_lower (spelling(index)) /=
               expected(expected'First + index - spelling'First)
            then
              return False;
            end if;
          end loop;

          return True;
        end is_class_designator;

        procedure parse_parameter_aspect_mark is
        begin
          if self.current.kind = Tok_Invalid_Identifier then
            report_invalid_identifier (self, context);
            return;
          elsif self.current.kind /= Tok_Identifier then
            report_expression_expected ("aspect identifier");
            return;
          end if;

          -- Aspect marks are structural and have no binding in staging.
          append_current;

          if self.current.kind /= Tok_Apostrophe then
            return;
          end if;

          append_current;

          if self.current.kind = Tok_Invalid_Identifier then
            report_invalid_identifier (self, context);
            return;
          end if;

          if self.current.kind /= Tok_Identifier or else
             not is_class_designator
          then
            report_expression_expected ("Class");
            return;
          end if;

          append_current;
        end parse_parameter_aspect_mark;

        procedure parse_optional_parameter_aspect_specification is
        begin
          if self.current.kind /= Tok_With then
            return;
          end if;

          append_structural_token;

          loop
            parse_parameter_aspect_mark;

            if self.failed then
              return;
            end if;

            if self.current.kind = Tok_Arrow then
              append_structural_token;

              if self.failed then
                return;
              end if;

              parse_expression;

              if self.failed then
                return;
              end if;
            end if;

            exit when self.current.kind /= Tok_Comma;
            append_comma;

            if self.failed then
              return;
            end if;
          end loop;
        end parse_optional_parameter_aspect_specification;

        procedure parse_basic_parameter_specification is
        begin
          loop
            parse_formal_defining_identifier;

            if self.failed then
              return;
            end if;

            exit when self.current.kind /= Tok_Comma;
            append_comma;

            if self.failed then
              return;
            end if;
          end loop;

          if self.current.kind /= Tok_Colon then
            report_expression_expected ("TOK_COLON");
            return;
          end if;

          append_structural_token;

          if self.current.kind = Tok_Not then
            parse_optional_null_exclusion;

            if self.failed then
              return;
            end if;

            if self.current.kind = Tok_Access then
              parse_access_parameter_definition;
            else
              parse_parameter_subtype_mark
                ("formal parameter subtype mark");
            end if;
          elsif self.current.kind = Tok_Access then
            parse_access_parameter_definition;
          else
            parse_subtype_mark_parameter_definition;
          end if;

          if self.failed then
            return;
          end if;

          parse_optional_parameter_default;

          if self.failed then
            return;
          end if;

          parse_optional_parameter_aspect_specification;
        end parse_basic_parameter_specification;

        procedure append_parameter_separator is
        begin
          Ada.Strings.Unbounded.append (text, current_text (self));
          Ada.Strings.Unbounded.append (text, " ");
          advance (self, context);
        end append_parameter_separator;
      begin
        if self.current.kind /= Tok_Left_Parenthesis then
          return;
        end if;

        append_current;

        loop
          parse_basic_parameter_specification;

          if self.failed then
            return;
          end if;

          exit when self.current.kind /= Tok_Semicolon;
          append_parameter_separator;

          if self.failed then
            return;
          end if;
        end loop;

        if self.current.kind /= Tok_Right_Parenthesis then
          report_expression_expected ("TOK_RIGHT_PARENTHESIS");
          return;
        end if;

        append_current;
      end parse_basic_formal_part;

      procedure parse_function_result (expected_after : String) is
      begin
        parse_optional_null_exclusion;

        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Access then
          parse_access_definition
            (expected_name  => "function result access subtype mark",
             expected_after => expected_after);
          return;
        end if;

        parse_required_name
          (expected_name              => "function result subtype mark",
           expected_after             => expected_after,
           allow_parenthesized_suffix => True);
      end parse_function_result;
    begin
      parse_optional_null_exclusion;

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Access then
        parse_access_definition
          (expected_name  => "access subtype mark",
           expected_after => "TOK_IN or TOK_OF");
        return;
      end if;

      parse_required_name
        (expected_name              => "loop parameter subtype mark",
         expected_after             => "TOK_IN or TOK_OF",
         allow_parenthesized_suffix => False);

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Range then
        append_structural_token;
        parse_staged_range;
      elsif self.current.kind = Tok_Digits then
        append_structural_token;
        parse_digits_expression;

        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Range then
          append_structural_token;
          parse_staged_range;
        end if;
      elsif self.current.kind = Tok_Left_Parenthesis then
        append_current;

        declare
          constraint_form : Composite_Constraint_Form :=
            Unclassified_Composite;
          named_started : Boolean := False;
        begin
          loop
            declare
              item_position : constant Adac.Source.Position :=
                self.current.position;
              item_form : Composite_Item_Form;
              is_named  : Boolean;
            begin
              parse_composite_constraint_association
                (item_form, is_named);

              if self.failed then
                return;
              end if;

              case item_form is
                when Ambiguous_Composite_Item =>
                  null;

                when Index_Composite_Item =>
                  if constraint_form = Discriminant_Composite then
                    report_aggregate_error
                      (item_position,
                       "index constraint item follows " &
                       "discriminant association");
                    return;
                  end if;

                  constraint_form := Index_Composite;

                when Discriminant_Composite_Item =>
                  if constraint_form = Index_Composite then
                    report_aggregate_error
                      (item_position,
                       "discriminant association follows " &
                       "index constraint item");
                    return;
                  end if;

                  constraint_form := Discriminant_Composite;
              end case;

              if named_started and then not is_named then
                report_aggregate_error
                  (item_position,
                   "positional discriminant association follows " &
                   "named association");
                return;
              end if;

              named_started := named_started or else is_named;
            end;

            exit when self.current.kind /= Tok_Comma;
            append_comma;

            if self.failed then
              return;
            end if;
          end loop;
        end;

        if self.current.kind /= Tok_Right_Parenthesis then
          report_expression_expected ("TOK_RIGHT_PARENTHESIS");
          return;
        end if;

        append_current;
      end if;
    end parse_loop_parameter_subtype_indication;

    procedure parse_iterator_name is
    begin
      parse_required_name
        (expected_name              => "iterator name",
         expected_after             => "TOK_ARROW",
         allow_parenthesized_suffix => True);
    end parse_iterator_name;

    procedure parse_iterator_filter is
    begin
      if self.current.kind /= Tok_When then
        raise Program_Error with
          "iterator filter parser requires TOK_WHEN";
      end if;

      append_structural_token;
      parse_expression;
    end parse_iterator_filter;

    procedure parse_reverse_in_domain is
      primary_before         : constant Natural := primary_count;
      name_before            : constant Natural := name_primary_count;
      range_attribute_before : constant Natural := range_attribute_count;
      operator_before        : constant Natural := operator_count;
      is_subtype_mark        : Boolean;
      is_range_attribute     : Boolean;
    begin
      if delimiter = Parenthesized_Delimiter then
        parse_iterator_name;
        return;
      end if;

      parse_simple_expression;

      if self.failed then
        return;
      end if;

      is_subtype_mark :=
        is_bare_subtype_mark
          (primary_before,
           name_before,
           range_attribute_before,
           operator_before);
      is_range_attribute :=
        is_bare_range_attribute
          (primary_before,
           name_before,
           range_attribute_before,
           operator_before);

      if self.current.kind = Tok_Range or else
         self.current.kind = Tok_Double_Dot
      then
        parse_choice_suffix (is_subtype_mark);
      elsif not is_subtype_mark and then
            not is_range_attribute
      then
        report_expression_expected ("TOK_DOUBLE_DOT");
      end if;
    end parse_reverse_in_domain;

    procedure parse_iterated_association is
      primary_before       : Natural;
      name_before          : Natural;
      range_before         : Natural;
      operator_before      : Natural;
      is_subtype_mark      : Boolean;
      is_range_attribute   : Boolean;
      has_discrete_suffix   : Boolean;
      has_multiple_choices  : Boolean;
      allow_in_filter       : Boolean := False;
      allow_key_expression  : Boolean := False;
      has_explicit_subtype  : Boolean := False;
    begin
      if self.current.kind /= Tok_For then
        raise Program_Error with
          "iterated association parser requires TOK_FOR";
      end if;

      append_structural_token;

      if self.current.kind = Tok_Invalid_Identifier then
        report_invalid_identifier (self, context);
        return;
      elsif self.current.kind /= Tok_Identifier then
        report_expression_expected ("TOK_IDENTIFIER");
        return;
      end if;

      -- The defining identifier has no binding entity in staging.
      append_structural_token;

      if self.current.kind = Tok_Colon then
        append_structural_token;
        parse_loop_parameter_subtype_indication;

        if self.failed then
          return;
        end if;

        has_explicit_subtype := True;
      end if;

      if self.current.kind = Tok_In then
        append_structural_token;

        if has_explicit_subtype then
          if self.current.kind = Tok_Reverse then
            append_structural_token;
          end if;

          parse_iterator_name;
          allow_in_filter := not self.failed;
          allow_key_expression :=
            delimiter = Bracket_Delimiter and then not self.failed;
        elsif self.current.kind = Tok_Reverse then
          append_structural_token;
          parse_reverse_in_domain;
          allow_in_filter := not self.failed;
          allow_key_expression :=
            delimiter = Bracket_Delimiter and then not self.failed;
        else
          primary_before  := primary_count;
          name_before     := name_primary_count;
          range_before    := range_attribute_count;
          operator_before := operator_count;
          parse_expression;

          if self.failed then
            return;
          end if;

          is_subtype_mark :=
            is_bare_subtype_mark
              (primary_before,
               name_before,
               range_before,
               operator_before);
          is_range_attribute :=
            is_bare_range_attribute
              (primary_before,
               name_before,
               range_before,
               operator_before);
          has_discrete_suffix :=
            self.current.kind = Tok_Range or else
            self.current.kind = Tok_Double_Dot;

          parse_choice_suffix (is_subtype_mark);

          if self.failed then
            return;
          end if;

          has_multiple_choices :=
            self.current.kind = Tok_Vertical_Bar;
          parse_additional_choices;

          if delimiter = Parenthesized_Delimiter then
            allow_in_filter :=
              not has_multiple_choices and then
              not has_discrete_suffix and then
              (is_subtype_mark or else is_range_attribute);
          else
            allow_in_filter :=
              not has_multiple_choices and then
              (has_discrete_suffix or else
               is_subtype_mark or else
               is_range_attribute);
            allow_key_expression := allow_in_filter;
          end if;
        end if;

        if not self.failed and then
           self.current.kind = Tok_When and then
           allow_in_filter
        then
          parse_iterator_filter;
        end if;
      elsif self.current.kind = Tok_Of then
        append_structural_token;

        if self.current.kind = Tok_Reverse then
          append_structural_token;
        end if;

        parse_iterator_name;
        allow_key_expression :=
          delimiter = Bracket_Delimiter and then not self.failed;

        if not self.failed and then self.current.kind = Tok_When then
          parse_iterator_filter;
        end if;
      else
        report_expression_expected ("TOK_IN or TOK_OF");
        return;
      end if;

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Use and then allow_key_expression then
        append_structural_token;
        parse_expression;

        if self.failed then
          return;
        end if;
      end if;

      if self.current.kind /= Tok_Arrow then
        report_expression_expected ("TOK_ARROW");
        return;
      end if;

      append_structural_token;

      if self.current.kind = Tok_Box then
        report_aggregate_error
          (self.current.position,
           "box is not permitted in iterated aggregate association");
        return;
      end if;

      parse_expression;
    end parse_iterated_association;

    procedure parse_aggregate_tail
      (named_started                : in out Boolean;
       allow_null_record            : Boolean;
       allow_named_after_positional : Boolean;
       allow_iterated               : Boolean;
       has_prior_positional         : Boolean)
    is
      first_item     : Boolean := True;
      saw_others     : Boolean := False;
      has_positional : Boolean := has_prior_positional;
    begin
      if has_prior_positional then
        can_publish_record_aggregate := False;
      end if;

      loop
        declare
          item_position    : constant Adac.Source.Position :=
            self.current.position;
          starts_with_null : constant Boolean :=
            self.current.kind = Tok_Null;
          primary_before   : constant Natural := primary_count;
          name_before      : constant Natural := name_primary_count;
          range_before     : constant Natural := range_attribute_count;
          operators_before : constant Natural := operator_count;
          is_named         : Boolean := False;
          is_null_record   : Boolean := False;
          is_subtype_mark  : Boolean := False;
          selector_node    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        begin
          if self.current.kind = Tok_For then
            if not allow_iterated then
              report_aggregate_error
                (self.current.position,
                 "iterated aggregate association is not permitted here");
              return;
            end if;

            if has_positional then
              report_aggregate_error
                (self.current.position,
                 "iterated aggregate association follows " &
                 "positional association");
              return;
            end if;

            named_started := True;
            is_named      := True;
            can_publish_record_aggregate := False;
            can_publish_bracket_aggregate := False;
            parse_iterated_association;
          elsif self.current.kind = Tok_Others then
            named_started := True;
            is_named      := True;
            saw_others    := True;
            can_publish_record_aggregate := False;
            can_publish_bracket_aggregate := False;
            append_current;

            if self.failed then
              return;
            end if;

            if self.current.kind /= Tok_Arrow then
              report_expression_expected ("TOK_ARROW");
              return;
            end if;

            append_structural_token;

            if self.failed then
              return;
            end if;

            parse_aggregate_value (True);
          else
            parse_expression;

            if self.failed then
              return;
            end if;

            is_subtype_mark :=
              is_bare_subtype_mark
                (primary_before,
                 name_before,
                 range_before,
                 operators_before);
            selector_node :=
              simple_identifier_candidate
                (primary_before, name_before, operators_before);

            if allow_null_record and then first_item and then
               starts_with_null and then
               operator_count = operators_before and then
               self.current.kind = Tok_Record
            then
              Ada.Strings.Unbounded.append (text, " ");
              append_current;
              is_null_record := True;
              can_publish_record_aggregate := False;
              can_publish_bracket_aggregate := False;
            elsif self.current.kind = Tok_Range or else
                  self.current.kind = Tok_Double_Dot or else
                  self.current.kind = Tok_Vertical_Bar or else
                  self.current.kind = Tok_Arrow
            then
              if not allow_named_after_positional and then
                 not named_started
              then
                report_aggregate_error
                  (item_position,
                   "named bracket aggregate association follows " &
                   "positional association");
                return;
              end if;

              named_started := True;
              is_named      := True;
              can_publish_bracket_aggregate := False;

              if self.current.kind = Tok_Arrow and then
                 ((can_publish_record_aggregate and then
                   selector_node /= Adac.AST.INVALID_NODE_ID) or else
                  can_publish_array_aggregate)
              then
                declare
                  choice_node : constant Adac.AST.Node_ID :=
                    latest_simple_expression_node;
                  value_node : Adac.AST.Node_ID;
                begin
                  parse_choice_tail
                    (is_subtype_mark,
                     allow_box  => True,
                     value_node => value_node);
                  if not self.failed then
                    if selector_node /= Adac.AST.INVALID_NODE_ID then
                      append_record_association (selector_node, value_node);
                    else
                      can_publish_record_aggregate := False;
                    end if;
                    append_array_association (choice_node, value_node);
                  end if;
                end;
              else
                can_publish_record_aggregate := False;
                can_publish_array_aggregate := False;
                parse_choice_tail
                  (is_subtype_mark,
                   allow_box => True);
              end if;
            elsif named_started then
              report_aggregate_error
                (item_position,
                 "positional aggregate association follows " &
                 "named association");
              return;
            else
              has_positional := True;
              can_publish_record_aggregate := False;
              append_bracket_expression (latest_simple_expression_node);
            end if;
          end if;

          if self.failed then
            return;
          end if;

          if is_null_record then
            if self.current.kind /= Tok_Right_Parenthesis then
              report_expected (self, context, Tok_Right_Parenthesis);
            end if;
            return;
          end if;

          if saw_others and then self.current.kind = Tok_Comma then
            report_aggregate_error
              (self.current.position,
               "others aggregate association must be last");
            return;
          end if;

          exit when self.current.kind /= Tok_Comma;

          if Adac.AST.array_component_association_list_count
            (array_associations) > 0
          then
            can_publish_array_aggregate := False;
          end if;
          append_comma;

          if self.failed then
            return;
          end if;

          first_item := False;

          if is_named then
            named_started := True;
          end if;
        end;
      end loop;
    end parse_aggregate_tail;

    procedure parse_delta_aggregate_tail is
    begin
      loop
        if self.current.kind = Tok_Others then
          report_aggregate_error
            (self.current.position,
             "others is not permitted in delta aggregate");
          return;
        end if;

        declare
          primary_before  : constant Natural := primary_count;
          name_before     : constant Natural := name_primary_count;
          range_before    : constant Natural := range_attribute_count;
          operator_before : constant Natural := operator_count;
          is_subtype_mark : Boolean;
        begin
          parse_expression;

          if self.failed then
            return;
          end if;

          is_subtype_mark :=
            is_bare_subtype_mark
              (primary_before,
               name_before,
               range_before,
               operator_before);

          parse_choice_tail
            (is_subtype_mark,
             allow_box => False);

          if self.failed then
            return;
          end if;
        end;

        exit when self.current.kind /= Tok_Comma;

        append_comma;

        if self.failed then
          return;
        end if;
      end loop;
    end parse_delta_aggregate_tail;

    procedure parse_current_if_expression
      (opening_position : Adac.Source.Position)
    is
      if_position : constant Adac.Source.Position := self.current.position;
      condition_first : Adac.Source.Position := self.current.position;
      then_first : Adac.Source.Position := self.current.position;
      else_first : Adac.Source.Position := self.current.position;
      condition_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      then_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      else_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      conditional_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      outer_primary_count : constant Natural := primary_count;
      outer_name_count : constant Natural := name_primary_count;
      outer_direct_count : constant Natural := direct_name_count;
      outer_selector_count : constant Natural := selector_primary_count;
      outer_range_count : constant Natural := range_attribute_count;
      outer_operator_count : constant Natural := operator_count;
      outer_has_operator : constant Boolean := has_operator;

      procedure report_unrepresented
        (position : Adac.Source.Position;
         part     : String)
      is
      begin
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           position,
           "conditional expression " & part & " is not supported");
      end report_unrepresented;

      procedure parse_current_condition
        (first : Adac.Source.Position;
         node  : out Adac.AST.Node_ID)
      is
      begin
        node := Adac.AST.INVALID_NODE_ID;
        if publish_expression_syntax then
          parse_represented_current_expression (node);
          if not self.failed and then node /= Adac.AST.INVALID_NODE_ID then
            declare
              kind : constant Adac.AST.Node_Kind :=
                Adac.Compilation.Syntax.kind_of (context, node);
            begin
              if kind /= Adac.AST.Relation_Node and then
                 kind /= Adac.AST.Short_Circuit_Expression_Node and then
                 kind /= Adac.AST.Numeric_Literal_Node and then
                 kind /= Adac.AST.Character_Literal_Node and then
                 kind /= Adac.AST.String_Literal_Node and then
                 kind /= Adac.AST.Null_Literal_Node and then
                 kind /= Adac.AST.Identifier_Name_Node and then
                 kind /= Adac.AST.Selected_Name_Node and then
                 kind /= Adac.AST.Selected_Component_Node and then
                 kind /= Adac.AST.Parenthesized_Name_Node and then
                 kind /= Adac.AST.Slice_Name_Node and then
                 kind /= Adac.AST.Attribute_Name_Node and then
                 kind /= Adac.AST.Unary_Operator_Node and then
                 kind /= Adac.AST.Binary_Exponentiating_Node and then
                 kind /= Adac.AST.Binary_Multiplying_Node and then
                 kind /= Adac.AST.Binary_Adding_Node
              then
                report_unrepresented (first, "condition");
              end if;
            end;
          elsif not self.failed then
            report_unrepresented (first, "condition");
          end if;
        else
          parse_relation (False);
        end if;
      end parse_current_condition;

      procedure parse_current_child
        (first : Adac.Source.Position;
         part  : String;
         node  : out Adac.AST.Node_ID)
      is
      begin
        node := Adac.AST.INVALID_NODE_ID;
        if publish_expression_syntax then
          parse_represented_simple_expression (node);
          if not self.failed and then node = Adac.AST.INVALID_NODE_ID then
            report_unrepresented (first, part);
          end if;
        else
          parse_simple_expression;
        end if;
      end parse_current_child;
    begin
      has_conditional_expression := True;
      append_structural_token;
      if self.failed then
        return;
      end if;

      condition_first := self.current.position;
      parse_current_condition (condition_first, condition_node);
      if self.failed then
        return;
      end if;

      if self.current.kind /= Tok_Then then
        report_expression_expected ("TOK_THEN");
        return;
      end if;
      append_structural_token;
      if self.failed then
        return;
      end if;

      then_first := self.current.position;
      parse_current_child (then_first, "then expression", then_node);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Right_Parenthesis then
        report_unrepresented (if_position, "without else");
        return;
      elsif self.current.kind = Tok_Elsif then
        report_unrepresented (self.current.position, "with elsif");
        return;
      elsif self.current.kind /= Tok_Else then
        report_expression_expected ("TOK_ELSE");
        return;
      end if;
      append_structural_token;
      if self.failed then
        return;
      end if;

      else_first := self.current.position;
      parse_current_child (else_first, "else expression", else_node);
      if self.failed then
        return;
      end if;
      if self.current.kind /= Tok_Right_Parenthesis then
        report_expected (self, context, Tok_Right_Parenthesis);
        return;
      end if;

      if publish_expression_syntax then
        begin
          declare
            else_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, else_node);
          begin
            conditional_node := Adac.Compilation.Syntax.create_if_expression
              (context,
               condition_node,
               then_node,
               else_node,
               Adac.Source.make_span
                 (if_position, Adac.Source.last_position (else_span)));
            Adac.Compilation.Syntax.validate_expression
              (context, conditional_node);
          end;
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit (if_position);
            return;
        end;
      end if;

      declare
        closing_position : constant Adac.Source.Position :=
          self.current.position;
      begin
        append_current;
        if self.failed then
          return;
        end if;

        if publish_expression_syntax then
          begin
            latest_primary_node :=
              Adac.Compilation.Syntax.create_parenthesized_expression
                (context,
                 conditional_node,
                 Adac.Source.make_span
                   (opening_position, closing_position));
            Adac.Compilation.Syntax.validate_expression
              (context, latest_primary_node);
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (opening_position);
              return;
          end;
        end if;
      end;

      primary_count := outer_primary_count;
      name_primary_count := outer_name_count;
      direct_name_count := outer_direct_count;
      selector_primary_count := outer_selector_count;
      range_attribute_count := outer_range_count;
      operator_count := outer_operator_count;
      has_operator := outer_has_operator;
    end parse_current_if_expression;

    procedure parse_current_case_expression
      (opening_position : Adac.Source.Position)
    is
      case_position : constant Adac.Source.Position := self.current.position;
      selecting_first : Adac.Source.Position := self.current.position;
      selecting_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      alternatives : Adac.AST.Node_List;
      conditional_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      outer_primary_count : constant Natural := primary_count;
      outer_name_count : constant Natural := name_primary_count;
      outer_direct_count : constant Natural := direct_name_count;
      outer_selector_count : constant Natural := selector_primary_count;
      outer_range_count : constant Natural := range_attribute_count;
      outer_operator_count : constant Natural := operator_count;
      outer_has_operator : constant Boolean := has_operator;

      procedure report_unrepresented
        (position : Adac.Source.Position;
         part     : String)
      is
      begin
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           position,
           "conditional expression " & part & " is not supported");
      end report_unrepresented;

      procedure parse_current_child
        (first : Adac.Source.Position;
         part  : String;
         node  : out Adac.AST.Node_ID)
      is
      begin
        node := Adac.AST.INVALID_NODE_ID;
        if publish_expression_syntax then
          parse_represented_simple_expression (node);
          if not self.failed and then node = Adac.AST.INVALID_NODE_ID then
            report_unrepresented (first, part);
          end if;
        else
          parse_simple_expression;
        end if;
      end parse_current_child;

      procedure parse_current_raise_expression
        (node : out Adac.AST.Node_ID)
      is
        raise_position : constant Adac.Source.Position := self.current.position;
        exception_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        message_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;

        procedure parse_exception_name is
        begin
          loop
            if self.current.kind /= Tok_Identifier and then
               self.current.kind /= Tok_Invalid_Identifier
            then
              report_expression_expected ("TOK_IDENTIFIER");
              return;
            end if;

            declare
              component_position : constant Adac.Source.Position :=
                self.current.position;
              component_spelling : constant String := current_text (self);
              component_span : constant Adac.Source.Span :=
                make_token_span (component_position, component_spelling);
            begin
              if publish_expression_syntax then
                declare
                  component_symbol : constant Adac.Symbols.Symbol_ID :=
                    parse_identifier_symbol (self, context);
                begin
                  if self.failed then
                    return;
                  end if;
                  Ada.Strings.Unbounded.append (text, component_spelling);
                  begin
                    if exception_node = Adac.AST.INVALID_NODE_ID then
                      exception_node :=
                        Adac.Compilation.Syntax.create_identifier_name
                          (context, component_symbol, component_span);
                    else
                      declare
                        prefix_span : constant Adac.Source.Span :=
                          Adac.Compilation.Syntax.node_span
                            (context, exception_node);
                      begin
                        exception_node :=
                          Adac.Compilation.Syntax.create_selected_name
                            (context,
                             exception_node,
                             component_symbol,
                             component_span,
                             Adac.Source.make_span
                               (Adac.Source.first_position (prefix_span),
                                Adac.Source.last_position (component_span)));
                      end;
                    end if;
                  exception
                    when Adac.Resources.Limit_Exceeded =>
                      report_ast_node_limit (component_position);
                      return;
                  end;
                end;
              else
                parse_unpublished_identifier (self, context);
                if self.failed then
                  return;
                end if;
                Ada.Strings.Unbounded.append (text, component_spelling);
              end if;
            end;

            exit when self.current.kind /= Tok_Dot;
            append_current;
            if self.failed then
              return;
            end if;
          end loop;
        end parse_exception_name;
      begin
        node := Adac.AST.INVALID_NODE_ID;
        if self.current.kind /= Tok_Raise then
          raise Program_Error with
            "raise-expression parser received a non-raise token";
        end if;

        append_structural_token;
        if self.failed then
          return;
        end if;
        parse_exception_name;
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_With then
          append_structural_token;
          if self.failed then
            return;
          end if;
          declare
            message_first : constant Adac.Source.Position :=
              self.current.position;
          begin
            parse_current_child
              (message_first, "raise message expression", message_node);
          end;
          if self.failed then
            return;
          end if;
        end if;

        if publish_expression_syntax then
          begin
            declare
              final_child : constant Adac.AST.Node_ID :=
                (if message_node = Adac.AST.INVALID_NODE_ID
                 then exception_node
                 else message_node);
              final_span : constant Adac.Source.Span :=
                Adac.Compilation.Syntax.node_span (context, final_child);
            begin
              node := Adac.Compilation.Syntax.create_raise_expression
                (context,
                 exception_node,
                 message_node,
                 Adac.Source.make_span
                   (raise_position, Adac.Source.last_position (final_span)));
              Adac.Compilation.Syntax.validate_expression (context, node);
            end;
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (raise_position);
          end;
        end if;
      end parse_current_raise_expression;

      procedure parse_simple_name_choice
        (choices : in out Adac.AST.Node_List)
      is
        choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        loop
          if self.current.kind /= Tok_Identifier and then
             self.current.kind /= Tok_Invalid_Identifier
          then
            report_unrepresented (self.current.position, "case choice");
            return;
          end if;

          declare
            component_position : constant Adac.Source.Position :=
              self.current.position;
            component_spelling : constant String := current_text (self);
            component_span : constant Adac.Source.Span :=
              make_token_span (component_position, component_spelling);
          begin
            if publish_expression_syntax then
              declare
                component_symbol : constant Adac.Symbols.Symbol_ID :=
                  parse_identifier_symbol (self, context);
              begin
                if self.failed then
                  return;
                end if;
                Ada.Strings.Unbounded.append (text, component_spelling);
                begin
                  if choice = Adac.AST.INVALID_NODE_ID then
                    choice := Adac.Compilation.Syntax.create_identifier_name
                      (context, component_symbol, component_span);
                  else
                    declare
                      prefix_span : constant Adac.Source.Span :=
                        Adac.Compilation.Syntax.node_span (context, choice);
                    begin
                      choice := Adac.Compilation.Syntax.create_selected_name
                        (context,
                         choice,
                         component_symbol,
                         component_span,
                         Adac.Source.make_span
                           (Adac.Source.first_position (prefix_span),
                            Adac.Source.last_position (component_span)));
                    end;
                  end if;
                exception
                  when Adac.Resources.Limit_Exceeded =>
                    report_ast_node_limit (component_position);
                    return;
                end;
              end;
            else
              parse_unpublished_identifier (self, context);
              if self.failed then
                return;
              end if;
              Ada.Strings.Unbounded.append (text, component_spelling);
            end if;
          end;

          exit when self.current.kind /= Tok_Dot;
          append_current;
          if self.failed then
            return;
          end if;
        end loop;

        if publish_expression_syntax then
          Adac.AST.append (choices, choice);
        end if;
      end parse_simple_name_choice;

      procedure parse_choice_list
        (choices : in out Adac.AST.Node_List)
      is
      begin
        if self.current.kind = Tok_Others then
          declare
            choice_position : constant Adac.Source.Position :=
              self.current.position;
            choice_span : constant Adac.Source.Span :=
              make_token_span (choice_position, current_text (self));
            choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          begin
            append_structural_token;
            if self.failed then
              return;
            end if;
            if publish_expression_syntax then
              begin
                choice := Adac.Compilation.Syntax.create_others_case_choice
                  (context, choice_span);
              exception
                when Adac.Resources.Limit_Exceeded =>
                  report_ast_node_limit (choice_position);
                  return;
              end;
              Adac.AST.append (choices, choice);
            end if;
          end;
          if self.current.kind = Tok_Vertical_Bar then
            report_unrepresented (self.current.position, "case choice");
          end if;
          return;
        end if;

        parse_simple_name_choice (choices);
        if self.failed then
          return;
        end if;

        while self.current.kind = Tok_Vertical_Bar loop
          append_structural_token;
          if self.failed then
            return;
          end if;
          if self.current.kind = Tok_Others then
            report_unrepresented (self.current.position, "case choice");
            return;
          end if;
          parse_simple_name_choice (choices);
          if self.failed then
            return;
          end if;
        end loop;
      end parse_choice_list;
    begin
      has_conditional_expression := True;
      append_structural_token;
      if self.failed then
        return;
      end if;

      selecting_first := self.current.position;
      parse_current_child
        (selecting_first, "case selecting expression", selecting_node);
      if self.failed then
        return;
      end if;

      if self.current.kind /= Tok_Is then
        report_expression_expected ("TOK_IS");
        return;
      end if;
      append_structural_token;
      if self.failed then
        return;
      end if;

      if self.current.kind /= Tok_When then
        report_expression_expected ("TOK_WHEN");
        return;
      end if;

      loop
        declare
          alternative_position : constant Adac.Source.Position :=
            self.current.position;
          choices : Adac.AST.Node_List;
          dependent_first : Adac.Source.Position := self.current.position;
          dependent_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          alternative_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        begin
          append_structural_token;
          if self.failed then
            return;
          end if;

          parse_choice_list (choices);
          if self.failed then
            return;
          end if;

          if self.current.kind /= Tok_Arrow then
            report_expression_expected ("TOK_ARROW");
            return;
          end if;
          append_structural_token;
          if self.failed then
            return;
          end if;

          dependent_first := self.current.position;
          if self.current.kind = Tok_Raise then
            parse_current_raise_expression (dependent_node);
          else
            parse_current_child
              (dependent_first, "case dependent expression", dependent_node);
          end if;
          if self.failed then
            return;
          end if;

          if publish_expression_syntax then
            begin
              declare
                dependent_span : constant Adac.Source.Span :=
                  Adac.Compilation.Syntax.node_span (context, dependent_node);
              begin
                alternative_node :=
                  Adac.Compilation.Syntax.create_case_expression_alternative
                    (context,
                     choices,
                     dependent_node,
                     Adac.Source.make_span
                       (alternative_position,
                        Adac.Source.last_position (dependent_span)));
              end;
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (alternative_position);
                return;
            end;
            Adac.AST.append (alternatives, alternative_node);
          end if;
        end;

        exit when self.current.kind /= Tok_Comma;
        append_comma;
        if self.failed then
          return;
        end if;
        if self.current.kind /= Tok_When then
          report_expression_expected ("TOK_WHEN");
          return;
        end if;
      end loop;

      if self.current.kind /= Tok_Right_Parenthesis then
        report_expected (self, context, Tok_Right_Parenthesis);
        return;
      end if;

      if publish_expression_syntax then
        begin
          declare
            final_alternative : constant Adac.AST.Node_ID :=
              Adac.AST.list_element
                (alternatives, Adac.AST.list_count (alternatives));
            final_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span
                (context, final_alternative);
          begin
            conditional_node := Adac.Compilation.Syntax.create_case_expression
              (context,
               selecting_node,
               alternatives,
               Adac.Source.make_span
                 (case_position, Adac.Source.last_position (final_span)));
            Adac.Compilation.Syntax.validate_expression
              (context, conditional_node);
          end;
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit (case_position);
            return;
        end;
      end if;

      declare
        closing_position : constant Adac.Source.Position :=
          self.current.position;
      begin
        append_current;
        if self.failed then
          return;
        end if;

        if publish_expression_syntax then
          begin
            latest_primary_node :=
              Adac.Compilation.Syntax.create_parenthesized_expression
                (context,
                 conditional_node,
                 Adac.Source.make_span
                   (opening_position, closing_position));
            Adac.Compilation.Syntax.validate_expression
              (context, latest_primary_node);
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (opening_position);
              return;
          end;
        end if;
      end;

      primary_count := outer_primary_count;
      name_primary_count := outer_name_count;
      direct_name_count := outer_direct_count;
      selector_primary_count := outer_selector_count;
      range_attribute_count := outer_range_count;
      operator_count := outer_operator_count;
      has_operator := outer_has_operator;
    end parse_current_case_expression;

    opening_position : constant Adac.Source.Position := self.current.position;
    starts_with_null : Boolean;
    primary_before   : Natural;
    name_before      : Natural;
    range_before     : Natural;
    operators_before : Natural;
    named_started    : Boolean := False;
    is_subtype_mark  : Boolean := False;
    selector_node    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    parenthesized_child : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    if self.current.kind /= opening_kind then
      raise Program_Error with
        "delimited primary parser received the wrong opening token";
    end if;

    if expression_nesting >= limits.maximum_expression_nesting then
      report_expression_nesting_limit;
      return;
    end if;

    set_first_form (form);
    expression_nesting := expression_nesting + 1;
    append_current;

    if self.failed then
      expression_nesting := expression_nesting - 1;
      return;
    end if;

    if delimiter = Bracket_Delimiter and then
       self.current.kind = Tok_Right_Bracket
    then
      mark_aggregate;
      append_current;
      expression_nesting := expression_nesting - 1;
      return;
    end if;

    if delimiter = Parenthesized_Delimiter and then
       not is_qualified and then
       self.current.kind = Tok_If
    then
      parse_current_if_expression (opening_position);
      expression_nesting := expression_nesting - 1;
      return;
    elsif delimiter = Parenthesized_Delimiter and then
          not is_qualified and then
          self.current.kind = Tok_Case
    then
      parse_current_case_expression (opening_position);
      expression_nesting := expression_nesting - 1;
      return;
    elsif self.current.kind = Tok_For then
      mark_aggregate;
      parse_aggregate_tail
        (named_started,
         allow_null_record            => False,
         allow_named_after_positional =>
           delimiter = Parenthesized_Delimiter,
         allow_iterated               => True,
         has_prior_positional         => False);
    elsif self.current.kind = Tok_Others then
      mark_aggregate;
      named_started := True;
      parse_aggregate_tail
        (named_started,
         allow_null_record            => False,
         allow_named_after_positional =>
           delimiter = Parenthesized_Delimiter,
         allow_iterated               => True,
         has_prior_positional         => False);
    else
      starts_with_null := self.current.kind = Tok_Null;
      primary_before   := primary_count;
      name_before      := name_primary_count;
      range_before     := range_attribute_count;
      operators_before := operator_count;
      if delimiter = Parenthesized_Delimiter and then
         not is_qualified and then
         publish_expression_syntax
      then
        parse_represented_current_expression (parenthesized_child);
      else
        parse_expression;
      end if;

      if self.failed then
        expression_nesting := expression_nesting - 1;
        return;
      end if;

      is_subtype_mark :=
        is_bare_subtype_mark
          (primary_before,
           name_before,
           range_before,
           operators_before);
      selector_node :=
        simple_identifier_candidate
          (primary_before, name_before, operators_before);

      if self.current.kind = closing_kind then
        if delimiter = Bracket_Delimiter then
          append_bracket_expression (latest_simple_expression_node);
          mark_aggregate;
        elsif not is_qualified and then
              publish_expression_syntax and then
              parenthesized_child = Adac.AST.INVALID_NODE_ID and then
              non_simple_operator_count = outer_non_simple_count and then
              latest_simple_expression_node /= Adac.AST.INVALID_NODE_ID
        then
          parenthesized_child := latest_simple_expression_node;
        elsif is_qualified and then
              publish_expression_syntax and then
              qualified_prefix /= Adac.AST.INVALID_NODE_ID and then
              non_simple_operator_count = outer_non_simple_count and then
              is_qualified_direct_operand (latest_simple_expression_node)
        then
          qualified_child := latest_simple_expression_node;
        end if;

        declare
          closing_position : constant Adac.Source.Position :=
            self.current.position;
        begin
          append_current;
          if self.failed then
            expression_nesting := expression_nesting - 1;
            return;
          end if;

          if delimiter = Bracket_Delimiter then
            begin
              publish_bracket_aggregate (opening_position, closing_position);
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (opening_position);
                expression_nesting := expression_nesting - 1;
                return;
            end;
          elsif parenthesized_child /= Adac.AST.INVALID_NODE_ID then
            begin
              latest_primary_node :=
                Adac.Compilation.Syntax.create_parenthesized_expression
                  (context,
                   parenthesized_child,
                   Adac.Source.make_span
                     (opening_position, closing_position));
              Adac.Compilation.Syntax.validate_expression
                (context, latest_primary_node);
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (opening_position);
                expression_nesting := expression_nesting - 1;
                return;
            end;
          elsif qualified_child /= Adac.AST.INVALID_NODE_ID then
            begin
              declare
                qualifier_span : constant Adac.Source.Span :=
                  Adac.Compilation.Syntax.node_span
                    (context, qualified_prefix);
              begin
                latest_primary_node :=
                  Adac.Compilation.Syntax.create_qualified_expression
                    (context,
                     qualified_prefix,
                     qualified_child,
                     Adac.Source.make_span
                       (Adac.Source.first_position (qualifier_span),
                        closing_position));
                Adac.Compilation.Syntax.validate_qualified_expression
                  (context, latest_primary_node);
              end;
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (opening_position);
                expression_nesting := expression_nesting - 1;
                return;
            end;
          end if;

          if parenthesized_child /= Adac.AST.INVALID_NODE_ID or else
             qualified_child /= Adac.AST.INVALID_NODE_ID or else
             (delimiter = Bracket_Delimiter and then
              latest_primary_node /= Adac.AST.INVALID_NODE_ID and then
              Adac.Compilation.Syntax.kind_of
                (context, latest_primary_node) =
                  Adac.AST.Bracket_Aggregate_Node)
          then
            primary_count := outer_primary_count;
            name_primary_count := outer_name_count;
            direct_name_count := outer_direct_count;
            selector_primary_count := outer_selector_count;
            range_attribute_count := outer_range_count;
            operator_count := outer_operator_count;
            non_simple_operator_count := outer_non_simple_count;
            has_operator := outer_has_operator;
          end if;
        end;
        expression_nesting := expression_nesting - 1;
        return;
      elsif delimiter = Parenthesized_Delimiter and then
            starts_with_null and then
            operator_count = operators_before and then
            self.current.kind = Tok_Record
      then
        mark_aggregate;
        can_publish_record_aggregate := False;
        Ada.Strings.Unbounded.append (text, " ");
        append_current;
      elsif self.current.kind = Tok_With then
        can_publish_record_aggregate := False;
        can_publish_bracket_aggregate := False;
        append_structural_token;

        if not self.failed and then self.current.kind = Tok_Delta then
          mark_delta_aggregate;
          append_structural_token;

          if not self.failed then
            parse_delta_aggregate_tail;
          end if;
        elsif not self.failed and then
              delimiter = Bracket_Delimiter
        then
          report_expression_expected ("TOK_DELTA");
        elsif not self.failed then
          mark_aggregate;
          parse_aggregate_tail
            (named_started,
             allow_null_record            => True,
             allow_named_after_positional => True,
             allow_iterated               => False,
             has_prior_positional         => False);
        end if;
      elsif self.current.kind = Tok_Comma then
        mark_aggregate;
        append_bracket_expression (latest_simple_expression_node);
        append_comma;

        if not self.failed then
          parse_aggregate_tail
            (named_started,
             allow_null_record            => False,
             allow_named_after_positional =>
               delimiter = Parenthesized_Delimiter,
             allow_iterated               => True,
             has_prior_positional         => True);
        end if;
      elsif self.current.kind = Tok_Range or else
            self.current.kind = Tok_Double_Dot or else
            self.current.kind = Tok_Vertical_Bar or else
            self.current.kind = Tok_Arrow
      then
        mark_aggregate;
        named_started := True;
        can_publish_bracket_aggregate := False;

        if self.current.kind = Tok_Arrow and then
           ((can_publish_record_aggregate and then
             selector_node /= Adac.AST.INVALID_NODE_ID) or else
            can_publish_array_aggregate)
        then
          declare
            choice_node : constant Adac.AST.Node_ID :=
              latest_simple_expression_node;
            value_node : Adac.AST.Node_ID;
          begin
            parse_choice_tail
              (is_subtype_mark,
               allow_box  => True,
               value_node => value_node);
            if not self.failed then
              if selector_node /= Adac.AST.INVALID_NODE_ID then
                append_record_association (selector_node, value_node);
              else
                can_publish_record_aggregate := False;
              end if;
              append_array_association (choice_node, value_node);
            end if;
          end;
        else
          can_publish_record_aggregate := False;
          can_publish_array_aggregate := False;
          parse_choice_tail
            (is_subtype_mark,
             allow_box => True);
        end if;

        if not self.failed and then self.current.kind = Tok_Comma then
          if Adac.AST.array_component_association_list_count
            (array_associations) > 0
          then
            can_publish_array_aggregate := False;
          end if;
          append_comma;

          if not self.failed then
            parse_aggregate_tail
              (named_started,
               allow_null_record            => False,
               allow_named_after_positional => True,
               allow_iterated               => True,
               has_prior_positional         => False);
          end if;
        end if;
      else
        report_expected (self, context, closing_kind);
      end if;
    end if;

    if self.failed then
      expression_nesting := expression_nesting - 1;
      return;
    end if;

    if self.current.kind /= closing_kind then
      report_expected (self, context, closing_kind);
      expression_nesting := expression_nesting - 1;
      return;
    end if;

    declare
      closing_position : constant Adac.Source.Position := self.current.position;
    begin
      append_current;

      if not self.failed and then
         can_publish_bracket_aggregate and then
         Adac.AST.list_count (bracket_expressions) > 0
      then
        begin
          publish_bracket_aggregate (opening_position, closing_position);
          primary_count := outer_primary_count;
          name_primary_count := outer_name_count;
          direct_name_count := outer_direct_count;
          selector_primary_count := outer_selector_count;
          range_attribute_count := outer_range_count;
          operator_count := outer_operator_count;
          non_simple_operator_count := outer_non_simple_count;
          has_operator := outer_has_operator;
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit (opening_position);
        end;
      elsif not self.failed and then
         can_publish_array_aggregate and then
         Adac.AST.array_component_association_list_count
           (array_associations) = 1
      then
        begin
          declare
            aggregate : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.create_array_aggregate
                (context,
                 array_associations,
                 Adac.Source.make_span (opening_position, closing_position));
            qualifier_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, qualified_prefix);
          begin
            represented_array_aggregate_count :=
              represented_array_aggregate_count + 1;
            Adac.Compilation.Syntax.validate_array_aggregate
              (context, aggregate);
            latest_primary_node :=
              Adac.Compilation.Syntax.create_qualified_expression
                (context,
                 qualified_prefix,
                 aggregate,
                 Adac.Source.make_span
                   (Adac.Source.first_position (qualifier_span),
                    closing_position));
            Adac.Compilation.Syntax.validate_qualified_expression
              (context, latest_primary_node);
          end;
          primary_count := outer_primary_count;
          name_primary_count := outer_name_count;
          direct_name_count := outer_direct_count;
          selector_primary_count := outer_selector_count;
          range_attribute_count := outer_range_count;
          operator_count := outer_operator_count;
          has_operator := outer_has_operator;
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit (opening_position);
        end;
      elsif not self.failed and then
         can_publish_record_aggregate and then
         Adac.AST.record_component_association_list_count
           (record_associations) > 0
      then
        begin
          declare
            aggregate : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.create_record_aggregate
                (context,
                 record_associations,
                 Adac.Source.make_span (opening_position, closing_position));
          begin
            represented_record_aggregate_count :=
              represented_record_aggregate_count + 1;
            Adac.Compilation.Syntax.validate_record_aggregate
              (context, aggregate);
            if is_qualified then
              declare
                qualifier_span : constant Adac.Source.Span :=
                  Adac.Compilation.Syntax.node_span
                    (context, qualified_prefix);
              begin
                latest_primary_node :=
                  Adac.Compilation.Syntax.create_qualified_expression
                    (context,
                     qualified_prefix,
                     aggregate,
                     Adac.Source.make_span
                       (Adac.Source.first_position (qualifier_span),
                        closing_position));
                Adac.Compilation.Syntax.validate_qualified_expression
                  (context, latest_primary_node);
              end;
            else
              latest_primary_node := aggregate;
            end if;
          end;
          primary_count := outer_primary_count;
          name_primary_count := outer_name_count;
          direct_name_count := outer_direct_count;
          selector_primary_count := outer_selector_count;
          range_attribute_count := outer_range_count;
          operator_count := outer_operator_count;
          has_operator := outer_has_operator;
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit (opening_position);
        end;
      end if;
    end;
    expression_nesting := expression_nesting - 1;
  end parse_delimited_primary;

  procedure parse_primary is
  begin
    latest_primary_node := Adac.AST.INVALID_NODE_ID;

    case self.current.kind is
      when Tok_Decimal_Integer_Literal |
           Tok_Decimal_Real_Literal |
           Tok_Based_Integer_Literal |
           Tok_Based_Real_Literal =>
        declare
          position : constant Adac.Source.Position := self.current.position;
          spelling : constant String := current_text (self);
          form     : constant Adac.AST.Numeric_Literal_Kind :=
            (case self.current.kind is
               when Tok_Decimal_Integer_Literal =>
                 Adac.AST.Decimal_Integer_Form,
               when Tok_Decimal_Real_Literal =>
                 Adac.AST.Decimal_Real_Form,
               when Tok_Based_Integer_Literal =>
                 Adac.AST.Based_Integer_Form,
               when Tok_Based_Real_Literal =>
                 Adac.AST.Based_Real_Form,
               when others =>
                 raise Program_Error with
                   "numeric primary has a nonnumeric token");
        begin
          note_primary;
          set_first_form (Numeric_Primary);

          if publish_expression_syntax then
            begin
              declare
                literal : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.create_numeric_literal
                    (context,
                     form,
                     spelling,
                     make_token_span (position, spelling));
              begin
                Adac.Compilation.Syntax.validate_numeric_literal
                  (context, literal);
                latest_primary_node := literal;
              end;
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (position);
            end;
          end if;

          if not self.failed then
            append_current;
          end if;
        end;

      when Tok_Invalid_Numeric_Literal =>
        report_numeric_literal (self, context);

      when Tok_Character_Literal =>
        declare
          position : constant Adac.Source.Position := self.current.position;
          spelling : constant String := current_text (self);
        begin
          note_primary;
          selector_primary_count := selector_primary_count + 1;
          set_first_form (Character_Primary);

          if publish_expression_syntax then
            begin
              declare
                literal : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.create_character_literal
                    (context,
                     spelling,
                     make_token_span (position, spelling));
              begin
                Adac.Compilation.Syntax.validate_character_literal
                  (context, literal);
                latest_primary_node := literal;
              end;
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (position);
            end;
          end if;

          if not self.failed then
            append_current;
          end if;
        end;

      when Tok_Apostrophe =>
        report_character_literal (self, context);

      when Tok_String_Literal =>
        declare
          position : constant Adac.Source.Position := self.current.position;
          spelling : constant String := current_text (self);
        begin
          note_primary;

          if is_operator_symbol (spelling) then
            selector_primary_count := selector_primary_count + 1;
          end if;

          set_first_form (String_Primary);

          if publish_expression_syntax then
            begin
              declare
                literal : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.create_string_literal
                    (context,
                     spelling,
                     make_token_span (position, spelling));
              begin
                Adac.Compilation.Syntax.validate_string_literal
                  (context, literal);
                latest_primary_node := literal;
              end;
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (position);
            end;
          end if;

          if not self.failed then
            append_current;
          end if;
        end;

      when Tok_Invalid_String_Literal =>
        report_string_literal (self, context);

      when Tok_Null =>
        declare
          position : constant Adac.Source.Position := self.current.position;
          spelling : constant String := current_text (self);
        begin
          note_primary;
          set_first_form (Null_Primary);

          if publish_expression_syntax then
            begin
              declare
                literal : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.create_null_literal
                    (context, make_token_span (position, spelling));
              begin
                Adac.Compilation.Syntax.validate_null_literal
                  (context, literal);
                latest_primary_node := literal;
              end;
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (position);
            end;
          end if;

          if not self.failed then
            append_current;
          end if;
        end;

      when Tok_New =>
        declare
          new_first : constant Adac.Source.Position := self.current.position;
          new_span  : constant Adac.Source.Span :=
            make_token_span (new_first, current_text (self));
          qualified : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          qualifier : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          staged_child_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          child_has_attribute : Boolean := False;
          child_has_explicit_dereference : Boolean := False;
          child_has_parenthesized_suffix : Boolean := False;
          child_has_qualified_apostrophe : Boolean := False;
          child_has_range_attribute : Boolean := False;
          child_direct_name_count : Natural := 0;
          saved_first_form : constant Primary_Form := first_form;
          saved_primary_count : constant Natural := primary_count;
          saved_name_count : constant Natural := name_primary_count;
          saved_direct_count : constant Natural := direct_name_count;
          saved_selector_count : constant Natural := selector_primary_count;
          saved_range_count : constant Natural := range_attribute_count;
          saved_operator_count : constant Natural := operator_count;
          saved_non_simple_count : constant Natural :=
            non_simple_operator_count;
          saved_has_operator : constant Boolean := has_operator;
        begin
          append_structural_token;
          if self.failed then
            return;
          end if;

          if self.current.kind /= Tok_Identifier and then
             self.current.kind /= Tok_Invalid_Identifier
          then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "allocator subtype indications are not supported");
            return;
          end if;

          parse_name_operand
            (self,
             context,
             text,
             child_has_attribute,
             child_has_explicit_dereference,
             child_has_parenthesized_suffix,
             child_has_qualified_apostrophe,
             qualifier,
             child_has_range_attribute,
             child_direct_name_count,
             allow_parenthesized_suffix => True,
             publish_syntax             => publish_expression_syntax,
             syntax_node                => staged_child_name);
          if self.failed then
            return;
          end if;

          if not child_has_qualified_apostrophe or else
             self.current.kind /= Tok_Left_Parenthesis
          then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "allocator subtype indications are not supported");
            return;
          end if;

          parse_delimited_primary
            (Name_Primary,
             is_qualified     => True,
             delimiter        => Parenthesized_Delimiter,
             qualified_prefix => qualifier);
          if self.failed then
            return;
          end if;

          qualified := latest_primary_node;
          if not publish_expression_syntax or else
             qualified = Adac.AST.INVALID_NODE_ID or else
             Adac.Compilation.Syntax.kind_of (context, qualified) /=
               Adac.AST.Qualified_Expression_Node
          then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               new_first,
               "allocator qualified expressions are not represented");
            return;
          end if;

          declare
            child_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, qualified);
          begin
            latest_primary_node := Adac.Compilation.Syntax.create_allocator
              (context,
               new_span,
               qualified,
               Adac.Source.make_span
                 (new_first, Adac.Source.last_position (child_span)));
            Adac.Compilation.Syntax.validate_allocator
              (context, latest_primary_node);
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (new_first);
              return;
          end;

          first_form := saved_first_form;
          primary_count := saved_primary_count;
          name_primary_count := saved_name_count;
          direct_name_count := saved_direct_count;
          selector_primary_count := saved_selector_count;
          range_attribute_count := saved_range_count;
          operator_count := saved_operator_count;
          non_simple_operator_count := saved_non_simple_count;
          has_operator := saved_has_operator;
          note_primary;
          set_first_form (Allocator_Primary);
        end;

      when Tok_Left_Parenthesis =>
        note_primary;
        parse_delimited_primary
          (Parenthesized_Primary,
           is_qualified => False,
           delimiter    => Parenthesized_Delimiter);

      when Tok_Left_Bracket =>
        note_primary;
        parse_delimited_primary
          (Bracket_Primary,
           is_qualified => False,
           delimiter    => Bracket_Delimiter);

      when Tok_Identifier | Tok_Invalid_Identifier =>
        declare
          has_qualified_apostrophe : Boolean := False;
          qualified_prefix_node    : Adac.AST.Node_ID :=
            Adac.AST.INVALID_NODE_ID;
          has_range_attribute      : Boolean := False;
          direct_before            : constant Natural := direct_name_count;
        begin
          note_primary (is_name => True);
          staged_name_node := Adac.AST.INVALID_NODE_ID;
          parse_name_operand
            (self,
             context,
             text,
             has_attribute,
             has_explicit_dereference,
             has_parenthesized_suffix,
             has_qualified_apostrophe,
             qualified_prefix_node,
             has_range_attribute,
             direct_name_count,
             allow_parenthesized_suffix => True,
             publish_syntax             => publish_expression_syntax,
             syntax_node                => staged_name_node);

          if self.failed then
            return;
          end if;

          if direct_name_count = direct_before + 1 then
            selector_primary_count := selector_primary_count + 1;
          end if;

          if has_range_attribute then
            range_attribute_count := range_attribute_count + 1;
          end if;

          if has_qualified_apostrophe then
            has_qualified_expression := True;

            if qualified_prefix_node /= Adac.AST.INVALID_NODE_ID then
              case Adac.Compilation.Syntax.kind_of
                (context, qualified_prefix_node)
              is
                when Adac.AST.Identifier_Name_Node |
                     Adac.AST.Selected_Name_Node =>
                  null;
                when others =>
                  qualified_prefix_node := Adac.AST.INVALID_NODE_ID;
              end case;
            end if;

            if self.current.kind = Tok_Left_Parenthesis then
              parse_delimited_primary
                (Name_Primary,
                 is_qualified     => True,
                 delimiter        => Parenthesized_Delimiter,
                 qualified_prefix => qualified_prefix_node);
            elsif self.current.kind = Tok_Left_Bracket then
              parse_delimited_primary
                (Name_Primary,
                 is_qualified     => True,
                 delimiter        => Bracket_Delimiter,
                 qualified_prefix => qualified_prefix_node);
            else
              raise Program_Error with
                "qualified boundary has no supported delimiter";
            end if;
          else
            set_first_form (Name_Primary);
            latest_primary_node := staged_name_node;
          end if;
        end;

      when others =>
        report_expression_expected ("expression primary");
    end case;
  end parse_primary;

  procedure parse_factor is
  begin
    latest_factor_node := Adac.AST.INVALID_NODE_ID;

    if self.current.kind = Tok_Not or else self.current.kind = Tok_Abs then
      declare
        operator_position : constant Adac.Source.Position :=
          self.current.position;
        operator_spelling : constant String := current_text (self);
      begin
        append_spaced_token;
        parse_primary;

        if not self.failed and then
           publish_expression_syntax and then
           latest_primary_node /= Adac.AST.INVALID_NODE_ID
        then
          declare
            operand_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span
                (context, latest_primary_node);
            expression_span : constant Adac.Source.Span :=
              Adac.Source.make_span
                (operator_position,
                 Adac.Source.last_position (operand_span));
          begin
            latest_factor_node :=
              Adac.Compilation.Syntax.create_unary_operator
                (context,
                 operator_spelling,
                 make_token_span (operator_position, operator_spelling),
                 latest_primary_node,
                 expression_span);
            Adac.Compilation.Syntax.validate_expression
              (context, latest_factor_node);
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (operator_position);
          end;
        end if;
      end;
      return;
    end if;

    parse_primary;

    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Double_Star then
      declare
        left_operand : constant Adac.AST.Node_ID := latest_primary_node;
        operator_position : constant Adac.Source.Position :=
          self.current.position;
        operator_spelling : constant String := current_text (self);
      begin
        append_spaced_token;
        parse_primary;

        if not self.failed and then
           publish_expression_syntax and then
           left_operand /= Adac.AST.INVALID_NODE_ID and then
           latest_primary_node /= Adac.AST.INVALID_NODE_ID
        then
          declare
            left_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, left_operand);
            right_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, latest_primary_node);
          begin
            latest_factor_node :=
              Adac.Compilation.Syntax.create_binary_exponentiating
                (context,
                 left_operand,
                 operator_spelling,
                 make_token_span (operator_position, operator_spelling),
                 latest_primary_node,
                 Adac.Source.make_span
                   (Adac.Source.first_position (left_span),
                    Adac.Source.last_position (right_span)));
            Adac.Compilation.Syntax.validate_expression
              (context, latest_factor_node);
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (operator_position);
          end;
        end if;
      end;
    else
      latest_factor_node := latest_primary_node;
    end if;
  end parse_factor;

  procedure parse_represented_factor (node : out Adac.AST.Node_ID) is
  begin
    node := Adac.AST.INVALID_NODE_ID;
    parse_factor;
    if not self.failed and then
       latest_factor_node /= Adac.AST.INVALID_NODE_ID
    then
      node := latest_factor_node;
    end if;
  end parse_represented_factor;

  procedure parse_term is
    left_operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    latest_term_node := Adac.AST.INVALID_NODE_ID;
    parse_represented_factor (left_operand);

    while not self.failed and then
          is_multiplying_operator (self.current.kind)
    loop
      declare
        operator_position : constant Adac.Source.Position :=
          self.current.position;
        operator_spelling : constant String := current_text (self);
        right_operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        append_spaced_token;
        parse_represented_factor (right_operand);

        if not self.failed and then
           left_operand /= Adac.AST.INVALID_NODE_ID and then
           right_operand /= Adac.AST.INVALID_NODE_ID
        then
          declare
            left_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, left_operand);
            right_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, right_operand);
          begin
            left_operand :=
              Adac.Compilation.Syntax.create_binary_multiplying
                (context,
                 left_operand,
                 operator_spelling,
                 make_token_span (operator_position, operator_spelling),
                 right_operand,
                 Adac.Source.make_span
                   (Adac.Source.first_position (left_span),
                    Adac.Source.last_position (right_span)));
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (operator_position);
          end;
        else
          left_operand := Adac.AST.INVALID_NODE_ID;
        end if;
      end;
    end loop;

    if not self.failed then
      latest_term_node := left_operand;
    end if;
  end parse_term;

  procedure parse_represented_term (node : out Adac.AST.Node_ID) is
  begin
    parse_term;
    if self.failed then
      node := Adac.AST.INVALID_NODE_ID;
    else
      node := latest_term_node;
    end if;
  end parse_represented_term;

  procedure parse_simple_expression is
    left_operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    latest_simple_expression_node := Adac.AST.INVALID_NODE_ID;

    if is_unary_adding_operator (self.current.kind) then
      declare
        operator_position : constant Adac.Source.Position :=
          self.current.position;
        operator_spelling : constant String := current_text (self);
        operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        append_spaced_token;
        parse_represented_term (operand);

        if not self.failed and then
           publish_expression_syntax and then
           operand /= Adac.AST.INVALID_NODE_ID
        then
          declare
            operand_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, operand);
            expression_span : constant Adac.Source.Span :=
              Adac.Source.make_span
                (operator_position,
                 Adac.Source.last_position (operand_span));
          begin
            left_operand := Adac.Compilation.Syntax.create_unary_operator
              (context,
               operator_spelling,
               make_token_span (operator_position, operator_spelling),
               operand,
               expression_span);
            Adac.Compilation.Syntax.validate_expression
              (context, left_operand);
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (operator_position);
          end;
        end if;
      end;
    else
      parse_represented_term (left_operand);
    end if;

    while not self.failed and then
          is_binary_adding_operator (self.current.kind)
    loop
      declare
        operator_kind     : constant Token_Kind := self.current.kind;
        operator_position : constant Adac.Source.Position :=
          self.current.position;
        operator_spelling : constant String := current_text (self);
        right_operand     : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        append_spaced_token;
        parse_represented_term (right_operand);

        if not self.failed and then
           is_binary_adding_operator (operator_kind) and then
           left_operand /= Adac.AST.INVALID_NODE_ID and then
           right_operand /= Adac.AST.INVALID_NODE_ID
        then
          declare
            left_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, left_operand);
            right_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, right_operand);
            expression_span : constant Adac.Source.Span :=
              Adac.Source.make_span
                (Adac.Source.first_position (left_span),
                 Adac.Source.last_position (right_span));
          begin
            left_operand := Adac.Compilation.Syntax.create_binary_adding
              (context,
               left_operand,
               operator_spelling,
               make_token_span (operator_position, operator_spelling),
               right_operand,
               expression_span);
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (position);
          end;
        else
          left_operand := Adac.AST.INVALID_NODE_ID;
        end if;
      end;
    end loop;

    if not self.failed then
      latest_simple_expression_node := left_operand;
    end if;
  end parse_simple_expression;

  procedure parse_represented_simple_expression
    (node : out Adac.AST.Node_ID)
  is
  begin
    parse_simple_expression;

    if self.failed then
      node := Adac.AST.INVALID_NODE_ID;
    else
      node := latest_simple_expression_node;
    end if;
  end parse_represented_simple_expression;

  procedure parse_membership_choice
    (node : out Adac.AST.Node_ID);
  procedure parse_membership_choice_list
    (choices         : out Adac.AST.Node_List;
     all_represented : out Boolean);
  procedure parse_membership_choice_list;

  procedure parse_membership_choice
    (node : out Adac.AST.Node_ID)
  is
  begin
    parse_represented_simple_expression (node);

    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Double_Dot then
      declare
        lower_bound : constant Adac.AST.Node_ID := node;
        upper_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        range_position : constant Adac.Source.Position := self.current.position;
        range_spelling : constant String := current_text (self);
        range_span : constant Adac.Source.Span :=
          make_token_span (range_position, range_spelling);
      begin
        node := Adac.AST.INVALID_NODE_ID;
        append_spaced_token;
        parse_represented_simple_expression (upper_bound);
        if self.failed then
          return;
        end if;

        if lower_bound /= Adac.AST.INVALID_NODE_ID and then
           upper_bound /= Adac.AST.INVALID_NODE_ID
        then
          declare
            lower_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, lower_bound);
            upper_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, upper_bound);
          begin
            node := Adac.Compilation.Syntax.create_membership_range_choice
              (context,
               lower_bound,
               range_span,
               upper_bound,
               Adac.Source.make_span
                 (Adac.Source.first_position (lower_span),
                  Adac.Source.last_position (upper_span)));
          exception
            when Adac.Resources.Limit_Exceeded =>
              report_ast_node_limit (range_position);
          end;
        end if;
        return;
      end;
    end if;

    if is_relational_operator (self.current.kind) then
      node := Adac.AST.INVALID_NODE_ID;
      append_spaced_token;
      parse_simple_expression;
    end if;

    if not self.failed and then is_logical_operator (self.current.kind) then
      node := Adac.AST.INVALID_NODE_ID;
      parse_logical_tail (False);
    end if;
  end parse_membership_choice;

  procedure parse_membership_choice_list
    (choices         : out Adac.AST.Node_List;
     all_represented : out Boolean)
  is
    empty  : Adac.AST.Node_List;
    choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    choices := empty;
    all_represented := True;
    parse_membership_choice (choice);
    if not self.failed then
      if choice = Adac.AST.INVALID_NODE_ID then
        all_represented := False;
      else
        Adac.AST.append (choices, choice);
      end if;
    end if;

    while not self.failed and then
          self.current.kind = Tok_Vertical_Bar
    loop
      append_spaced_token;
      parse_membership_choice (choice);
      if not self.failed then
        if choice = Adac.AST.INVALID_NODE_ID then
          all_represented := False;
        elsif all_represented then
          Adac.AST.append (choices, choice);
        end if;
      end if;
    end loop;
  end parse_membership_choice_list;

  procedure parse_membership_choice_list is
    ignored_choices : Adac.AST.Node_List;
    ignored_all     : Boolean;
  begin
    parse_membership_choice_list (ignored_choices, ignored_all);
  end parse_membership_choice_list;

  procedure parse_relation_tail (allow_membership : Boolean) is
  begin
    if is_relational_operator (self.current.kind) then
      non_simple_operator_count := non_simple_operator_count + 1;
      append_spaced_token;
      parse_simple_expression;
      return;
    end if;

    if not allow_membership then
      return;
    end if;

    if self.current.kind = Tok_In then
      non_simple_operator_count := non_simple_operator_count + 1;
      append_spaced_token;
      parse_membership_choice_list;
    elsif self.current.kind = Tok_Not then
      non_simple_operator_count := non_simple_operator_count + 1;
      append_spaced_token;

      if self.current.kind /= Tok_In then
        report_expression_expected ("TOK_IN");
        return;
      end if;

      append_spaced_token;
      parse_membership_choice_list;
    end if;
  end parse_relation_tail;

  procedure parse_relation (allow_membership : Boolean) is
  begin
    parse_simple_expression;

    if self.failed then
      return;
    end if;

    parse_relation_tail (allow_membership);
  end parse_relation;

  procedure parse_top_level_relation is
    operator_position : Adac.Source.Position;
    operator_spelling : Ada.Strings.Unbounded.Unbounded_String;
  begin
    has_relation_candidate := False;
    has_membership_candidate := False;
    has_unrepresented_top_level := False;
    relation_left_operand := Adac.AST.INVALID_NODE_ID;
    relation_right_operand := Adac.AST.INVALID_NODE_ID;
    relation_operator_span := Adac.Source.INVALID_SPAN;
    relation_operator_text := Ada.Strings.Unbounded.Null_Unbounded_String;
    declare
      empty_choices : Adac.AST.Node_List;
    begin
      membership_choices := empty_choices;
    end;
    membership_operator_kind := Adac.AST.In_Membership_Operator;
    membership_not_span := Adac.Source.INVALID_SPAN;
    membership_in_span := Adac.Source.INVALID_SPAN;

    parse_represented_simple_expression (relation_left_operand);

    if self.failed then
      return;
    end if;

    if is_relational_operator (self.current.kind) then
      non_simple_operator_count := non_simple_operator_count + 1;
      operator_position := self.current.position;
      operator_spelling := Ada.Strings.Unbounded.to_unbounded_string
        (current_text (self));
      append_spaced_token;
      parse_represented_simple_expression (relation_right_operand);

      if not self.failed and then
         relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
         relation_right_operand /= Adac.AST.INVALID_NODE_ID
      then
        relation_operator_text := operator_spelling;
        relation_operator_span := make_token_span
          (operator_position, Ada.Strings.Unbounded.to_string
             (operator_spelling));
        has_relation_candidate := True;
      else
        has_unrepresented_top_level := True;
      end if;
      return;
    end if;

    if self.current.kind = Tok_In then
      declare
        all_represented : Boolean;
        token_position : constant Adac.Source.Position :=
          self.current.position;
        token_spelling  : constant String := current_text (self);
      begin
        non_simple_operator_count := non_simple_operator_count + 1;
        membership_operator_kind := Adac.AST.In_Membership_Operator;
        membership_in_span := make_token_span (token_position, token_spelling);
        append_spaced_token;
        parse_membership_choice_list
          (membership_choices, all_represented);
        if not self.failed and then
           relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
           all_represented
        then
          has_membership_candidate := True;
        else
          has_unrepresented_top_level := True;
        end if;
      end;
    elsif self.current.kind = Tok_Not then
      declare
        all_represented : Boolean;
        not_position : constant Adac.Source.Position :=
          self.current.position;
        not_spelling    : constant String := current_text (self);
      begin
        non_simple_operator_count := non_simple_operator_count + 1;
        membership_operator_kind := Adac.AST.Not_In_Membership_Operator;
        membership_not_span := make_token_span (not_position, not_spelling);
        append_spaced_token;

        if self.current.kind /= Tok_In then
          report_expression_expected ("TOK_IN");
          return;
        end if;

        declare
          in_position : constant Adac.Source.Position := self.current.position;
          in_spelling : constant String := current_text (self);
        begin
          membership_in_span := make_token_span (in_position, in_spelling);
        end;
        append_spaced_token;
        parse_membership_choice_list
          (membership_choices, all_represented);
        if not self.failed and then
           relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
           all_represented
        then
          has_membership_candidate := True;
        else
          has_unrepresented_top_level := True;
        end if;
      end;
    end if;
  end parse_top_level_relation;

  procedure capture_top_level_relation_node
    (node : out Adac.AST.Node_ID)
  is
  begin
    node := Adac.AST.INVALID_NODE_ID;
    if not publish_expression_syntax or else has_unrepresented_top_level then
      return;
    end if;

    if has_relation_candidate then
      declare
        left_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, relation_left_operand);
        right_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, relation_right_operand);
        relation_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.first_position (left_span),
             Adac.Source.last_position (right_span));
      begin
        node := Adac.Compilation.Syntax.create_relation
          (context,
           relation_left_operand,
           Ada.Strings.Unbounded.to_string (relation_operator_text),
           relation_operator_span,
           relation_right_operand,
           relation_span);
      exception
        when Adac.Resources.Limit_Exceeded =>
          report_ast_node_limit (position);
      end;
    elsif has_membership_candidate then
      declare
        last_choice : constant Adac.AST.Node_ID :=
          Adac.AST.list_element
            (membership_choices, Adac.AST.list_count (membership_choices));
        tested_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, relation_left_operand);
        choice_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, last_choice);
        membership_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.first_position (tested_span),
             Adac.Source.last_position (choice_span));
      begin
        node := Adac.Compilation.Syntax.create_membership_expression
          (context,
           relation_left_operand,
           membership_operator_kind,
           membership_not_span,
           membership_in_span,
           membership_choices,
           membership_span);
      exception
        when Adac.Resources.Limit_Exceeded =>
          report_ast_node_limit (position);
      end;
    elsif relation_left_operand /= Adac.AST.INVALID_NODE_ID then
      node := relation_left_operand;
    end if;
  end capture_top_level_relation_node;

  procedure parse_logical_tail
    (allow_membership      : Boolean;
     publish_logical_syntax : Boolean := False)
  is
    form  : Logical_Form := No_Logical_Form;
    chain : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    operator_first_span  : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    operator_second_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;

    procedure capture_operator_token (span : out Adac.Source.Span) is
      token_position : constant Adac.Source.Position := self.current.position;
      token_spelling : constant String := current_text (self);
    begin
      span := make_token_span (token_position, token_spelling);
      append_spaced_token;
    end capture_operator_token;

    procedure parse_operand (node : out Adac.AST.Node_ID) is
    begin
      node := Adac.AST.INVALID_NODE_ID;
      if publish_logical_syntax then
        parse_top_level_relation;
        if not self.failed then
          capture_top_level_relation_node (node);
        end if;
      else
        parse_relation (allow_membership);
      end if;
    end parse_operand;

    procedure publish_logical_step
      (right_operand : Adac.AST.Node_ID)
    is
      operator_kind : Adac.AST.Short_Circuit_Operator_Kind;
    begin
      if not publish_logical_syntax or else
         chain = Adac.AST.INVALID_NODE_ID or else
         right_operand = Adac.AST.INVALID_NODE_ID or else
         form = No_Logical_Form
      then
        chain := Adac.AST.INVALID_NODE_ID;
        return;
      end if;

      if form = And_Logical_Form or else
         form = Or_Logical_Form or else
         form = Xor_Logical_Form
      then
        declare
          operator_kind : constant Adac.AST.Logical_Operator_Kind :=
            (case form is
               when And_Logical_Form => Adac.AST.And_Logical_Operator,
               when Or_Logical_Form  => Adac.AST.Or_Logical_Operator,
               when Xor_Logical_Form => Adac.AST.Xor_Logical_Operator,
               when others => raise Program_Error);
          left_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, chain);
          right_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, right_operand);
        begin
          chain := Adac.Compilation.Syntax.create_logical_expression
            (context,
             chain,
             operator_kind,
             operator_first_span,
             right_operand,
             Adac.Source.make_span
               (Adac.Source.first_position (left_span),
                Adac.Source.last_position (right_span)));
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit (position);
        end;
        return;
      end if;

      operator_kind :=
        (if form = And_Then_Logical_Form
         then Adac.AST.And_Then_Short_Circuit_Operator
         else Adac.AST.Or_Else_Short_Circuit_Operator);

      declare
        left_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, chain);
        right_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, right_operand);
        expression_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.first_position (left_span),
             Adac.Source.last_position (right_span));
      begin
        chain := Adac.Compilation.Syntax.create_short_circuit_expression
          (context,
           chain,
           operator_kind,
           operator_first_span,
           operator_second_span,
           right_operand,
           expression_span);
      exception
        when Adac.Resources.Limit_Exceeded =>
          report_ast_node_limit (position);
      end;
    end publish_logical_step;

    procedure parse_next_operand is
      right_operand : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      non_simple_operator_count := non_simple_operator_count + 1;
      parse_operand (right_operand);
      if not self.failed then
        publish_logical_step (right_operand);
      end if;
    end parse_next_operand;

  begin
    if self.failed or else not is_logical_operator (self.current.kind) then
      return;
    end if;

    case self.current.kind is
      when Tok_And =>
        capture_operator_token (operator_first_span);
        if self.current.kind = Tok_Then then
          capture_operator_token (operator_second_span);
          form := And_Then_Logical_Form;
        else
          form := And_Logical_Form;
        end if;

      when Tok_Or =>
        capture_operator_token (operator_first_span);
        if self.current.kind = Tok_Else then
          capture_operator_token (operator_second_span);
          form := Or_Else_Logical_Form;
        else
          form := Or_Logical_Form;
        end if;

      when Tok_Xor =>
        capture_operator_token (operator_first_span);
        form := Xor_Logical_Form;

      when others =>
        raise Program_Error with
          "logical staging received a nonlogical token";
    end case;

    if publish_logical_syntax then
      capture_top_level_relation_node (chain);
    end if;

    parse_next_operand;

    while not self.failed loop
      operator_first_span := Adac.Source.INVALID_SPAN;
      operator_second_span := Adac.Source.INVALID_SPAN;

      case form is
        when And_Logical_Form =>
          exit when self.current.kind /= Tok_And;
          capture_operator_token (operator_first_span);
          if self.current.kind = Tok_Then then
            report_expression_expected ("expression relation");
            return;
          end if;

        when And_Then_Logical_Form =>
          exit when self.current.kind /= Tok_And;
          capture_operator_token (operator_first_span);
          if self.current.kind /= Tok_Then then
            report_expression_expected ("TOK_THEN");
            return;
          end if;
          capture_operator_token (operator_second_span);

        when Or_Logical_Form =>
          exit when self.current.kind /= Tok_Or;
          capture_operator_token (operator_first_span);
          if self.current.kind = Tok_Else then
            report_expression_expected ("expression relation");
            return;
          end if;

        when Or_Else_Logical_Form =>
          exit when self.current.kind /= Tok_Or;
          capture_operator_token (operator_first_span);
          if self.current.kind /= Tok_Else then
            report_expression_expected ("TOK_ELSE");
            return;
          end if;
          capture_operator_token (operator_second_span);

        when Xor_Logical_Form =>
          exit when self.current.kind /= Tok_Xor;
          capture_operator_token (operator_first_span);

        when No_Logical_Form =>
          raise Program_Error with
            "logical staging did not select a logical form";
      end case;

      parse_next_operand;
    end loop;

    if publish_logical_syntax then
      if chain /= Adac.AST.INVALID_NODE_ID then
        logical_expression_node := chain;
      end if;
      has_relation_candidate := False;
      has_membership_candidate := False;
      has_unrepresented_top_level := chain = Adac.AST.INVALID_NODE_ID;
    end if;
  end parse_logical_tail;

  procedure parse_represented_current_expression
    (node : out Adac.AST.Node_ID)
  is
    saved_relation_left_operand : constant Adac.AST.Node_ID :=
      relation_left_operand;
    saved_relation_right_operand : constant Adac.AST.Node_ID :=
      relation_right_operand;
    saved_relation_operator_text : constant
      Ada.Strings.Unbounded.Unbounded_String := relation_operator_text;
    saved_relation_operator_span : constant Adac.Source.Span :=
      relation_operator_span;
    saved_membership_choices : constant Adac.AST.Node_List :=
      membership_choices;
    saved_membership_operator_kind : constant
      Adac.AST.Membership_Operator_Kind := membership_operator_kind;
    saved_membership_not_span : constant Adac.Source.Span :=
      membership_not_span;
    saved_membership_in_span : constant Adac.Source.Span :=
      membership_in_span;
    saved_logical_expression_node : constant Adac.AST.Node_ID :=
      logical_expression_node;
    saved_has_relation_candidate : constant Boolean :=
      has_relation_candidate;
    saved_has_membership_candidate : constant Boolean :=
      has_membership_candidate;
    saved_has_unrepresented_top_level : constant Boolean :=
      has_unrepresented_top_level;

    procedure restore_capture_state is
    begin
      relation_left_operand := saved_relation_left_operand;
      relation_right_operand := saved_relation_right_operand;
      relation_operator_text := saved_relation_operator_text;
      relation_operator_span := saved_relation_operator_span;
      membership_choices := saved_membership_choices;
      membership_operator_kind := saved_membership_operator_kind;
      membership_not_span := saved_membership_not_span;
      membership_in_span := saved_membership_in_span;
      logical_expression_node := saved_logical_expression_node;
      has_relation_candidate := saved_has_relation_candidate;
      has_membership_candidate := saved_has_membership_candidate;
      has_unrepresented_top_level := saved_has_unrepresented_top_level;
    end restore_capture_state;
  begin
    node := Adac.AST.INVALID_NODE_ID;
    logical_expression_node := Adac.AST.INVALID_NODE_ID;

    parse_top_level_relation;
    if not self.failed then
      parse_logical_tail
        (True, publish_logical_syntax => publish_expression_syntax);
    end if;

    if not self.failed then
      if logical_expression_node /= Adac.AST.INVALID_NODE_ID then
        node := logical_expression_node;
      else
        capture_top_level_relation_node (node);
      end if;
    end if;

    restore_capture_state;
  end parse_represented_current_expression;

  procedure parse_expression is
    capture_relation : constant Boolean := expression_call_depth = 0;
  begin
    expression_call_depth := expression_call_depth + 1;

    if capture_relation then
      parse_top_level_relation;
    else
      parse_relation (True);
    end if;

    if not self.failed then
      parse_logical_tail
        (True,
         publish_logical_syntax =>
           capture_relation and then publish_expression_syntax);
    end if;

    expression_call_depth := expression_call_depth - 1;
  end parse_expression;

  procedure report_unsupported is
    spelling : constant String :=
      Ada.Strings.Unbounded.to_string (text);
  begin
    self.failed := True;

    if has_conditional_expression then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "conditional expressions are not supported: " & spelling);
    elsif has_operator then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "operator expressions are not supported: " & spelling);
    elsif has_qualified_bracket_delta then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "qualified bracket delta aggregate expressions are not supported: " &
         spelling);
    elsif has_bracket_delta then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "bracket delta aggregate expressions are not supported: " &
         spelling);
    elsif has_qualified_delta then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "qualified delta aggregate expressions are not supported: " &
         spelling);
    elsif has_delta_aggregate then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "delta aggregate expressions are not supported: " & spelling);
    elsif has_qualified_bracket then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "qualified bracket aggregate expressions are not supported: " &
         spelling);
    elsif has_bracket_aggregate then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "bracket aggregate expressions are not supported: " & spelling);
    elsif has_qualified_aggregate then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "qualified aggregate expressions are not supported: " & spelling);
    elsif has_aggregate_expression then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "aggregate expressions are not supported: " & spelling);
    elsif has_qualified_expression then
      Adac.Compilation.Diagnostics.error
        (context,
         position,
         "qualified expressions are not supported: " & spelling);
    else
      case first_form is
        when Numeric_Primary =>
          Adac.Compilation.Diagnostics.error
            (context,
             position,
             "numeric literal expressions are not supported: " & spelling);

        when Character_Primary =>
          Adac.Compilation.Diagnostics.error
            (context,
             position,
             "character literal expressions are not supported: " &
             spelling);

        when String_Primary =>
          Adac.Compilation.Diagnostics.error
            (context,
             position,
             "string literal expressions are not supported: " & spelling);

        when Null_Primary =>
          Adac.Compilation.Diagnostics.error
            (context,
             position,
             "null literal expressions are not supported: " & spelling);

        when Allocator_Primary =>
          Adac.Compilation.Diagnostics.error
            (context,
             position,
             "allocator expressions are not supported: " & spelling);

        when Parenthesized_Primary =>
          Adac.Compilation.Diagnostics.error
            (context,
             position,
             "parenthesized expressions are not supported: " & spelling);

        when Bracket_Primary =>
          raise Program_Error with
            "bracket primary completed without aggregate classification";

        when Name_Primary =>
          if has_parenthesized_suffix then
            Adac.Compilation.Diagnostics.error
              (context,
               position,
               "parenthesized name forms are not supported: " & spelling);
          elsif has_explicit_dereference then
            Adac.Compilation.Diagnostics.error
              (context,
               position,
               "explicit dereferences are not supported: " & spelling);
          elsif has_attribute then
            Adac.Compilation.Diagnostics.error
              (context,
               position,
               "attribute references are not supported: " & spelling);
          else
            Adac.Compilation.Diagnostics.error
              (context,
               position,
               "name expressions are not supported: " & spelling);
          end if;

        when No_Primary =>
          raise Program_Error with
            "expression staging completed without a primary";
      end case;
    end if;
  end report_unsupported;

begin
  syntax_node := Adac.AST.INVALID_NODE_ID;

  case grammar_level is
    when Full_Expression_Level =>
      parse_expression;
    when Simple_Expression_Level =>
      parse_represented_simple_expression (syntax_node);
  end case;

  if self.failed then
    return;
  end if;

  if self.current.kind /= terminator and then
     (terminator_mode /= Allow_Comma_Before_Terminator or else
      self.current.kind /= Tok_Comma) and then
     (terminator_mode /= Allow_Semicolon_Before_Terminator or else
      self.current.kind /= Tok_Semicolon) and then
     (terminator_mode /= Allow_Loop_Before_Terminator or else
      self.current.kind /= Tok_Loop)
  then
    if terminator = Tok_Semicolon then
      report_expression_expected ("expression end");
    else
      report_expected (self, context, terminator);
    end if;
    return;
  end if;

  if grammar_level = Simple_Expression_Level then
    if publish_expression_syntax and then
       syntax_node /= Adac.AST.INVALID_NODE_ID
    then
      Adac.Compilation.Syntax.validate_expression (context, syntax_node);
      return;
    end if;

    if completion_mode = Return_After_Staging then
      return;
    end if;

    report_unsupported;
    return;
  end if;

  if logical_expression_node /= Adac.AST.INVALID_NODE_ID then
    syntax_node := logical_expression_node;
    Adac.Compilation.Syntax.validate_expression (context, syntax_node);
    return;
  end if;

  if has_relation_candidate then
    declare
      left_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, relation_left_operand);
      right_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, relation_right_operand);
      relation_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.first_position (left_span),
           Adac.Source.last_position (right_span));
    begin
      syntax_node := Adac.Compilation.Syntax.create_relation
        (context,
         relation_left_operand,
         Ada.Strings.Unbounded.to_string (relation_operator_text),
         relation_operator_span,
         relation_right_operand,
         relation_span);
      Adac.Compilation.Syntax.validate_expression (context, syntax_node);
      if accept_relation_expression then
        return;
      end if;
    exception
      when Adac.Resources.Limit_Exceeded =>
        report_ast_node_limit (position);
        return;
    end;
  elsif has_membership_candidate then
    capture_top_level_relation_node (syntax_node);
    if not self.failed and then syntax_node /= Adac.AST.INVALID_NODE_ID then
      Adac.Compilation.Syntax.validate_expression (context, syntax_node);
    end if;
  elsif completion_mode = Return_After_Staging and then
        publish_expression_syntax and then
        not has_unrepresented_top_level and then
        relation_left_operand /= Adac.AST.INVALID_NODE_ID
  then
    syntax_node := relation_left_operand;
    Adac.Compilation.Syntax.validate_expression (context, syntax_node);
  end if;

  if completion_mode = Return_After_Staging then
    return;
  end if;

  if accept_unary_expression and then
     publish_expression_syntax and then
     not has_unrepresented_top_level and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Unary_Operator_Node
  then
    syntax_node := relation_left_operand;
    Adac.Compilation.Syntax.validate_expression (context, syntax_node);
    return;
  end if;

  if publish_expression_syntax and then
     not has_unrepresented_top_level and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     (Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
        Adac.AST.Binary_Exponentiating_Node or else
      Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
        Adac.AST.Binary_Multiplying_Node or else
      Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
        Adac.AST.Binary_Adding_Node)
  then
    syntax_node := relation_left_operand;
    Adac.Compilation.Syntax.validate_expression (context, syntax_node);
    return;
  end if;

  if publish_expression_syntax and then
     has_qualified_expression and then
     not has_qualified_aggregate and then
     not has_delta_aggregate and then
     not has_qualified_delta and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Qualified_Expression_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     has_qualified_aggregate and then
     not has_delta_aggregate and then
     not has_qualified_delta and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Qualified_Expression_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     has_aggregate_expression and then
     not has_qualified_aggregate and then
     not has_delta_aggregate and then
     not has_qualified_delta and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Record_Aggregate_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     first_form = Numeric_Primary and then
     primary_count = 1 and then
     not has_operator and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Numeric_Literal_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     first_form = String_Primary and then
     primary_count = 1 and then
     not has_operator and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.String_Literal_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     first_form = Null_Primary and then
     primary_count = 1 and then
     not has_operator and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Null_Literal_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     first_form = Allocator_Primary and then
     primary_count = 1 and then
     not has_operator and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Allocator_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     first_form = Bracket_Primary and then
     has_bracket_aggregate and then
     not has_qualified_bracket and then
     not has_bracket_delta and then
     not has_qualified_bracket_delta and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Bracket_Aggregate_Node
  then
    syntax_node := relation_left_operand;
    Adac.Compilation.Syntax.validate_bracket_aggregate
      (context, syntax_node);
    return;
  end if;

  if publish_expression_syntax and then
     first_form = Parenthesized_Primary and then
     relation_left_operand /= Adac.AST.INVALID_NODE_ID and then
     Adac.Compilation.Syntax.kind_of (context, relation_left_operand) =
       Adac.AST.Parenthesized_Expression_Node
  then
    syntax_node := relation_left_operand;
    return;
  end if;

  if publish_expression_syntax and then
     first_form = Name_Primary and then
     primary_count = 1 and then
     not has_operator and then
     not has_qualified_expression and then
     not has_aggregate_expression and then
     not has_qualified_aggregate and then
     not has_delta_aggregate and then
     not has_qualified_delta and then
     not has_bracket_aggregate and then
     not has_qualified_bracket and then
     not has_bracket_delta and then
     not has_qualified_bracket_delta and then
     staged_name_node /= Adac.AST.INVALID_NODE_ID
  then
    syntax_node := staged_name_node;
    return;
  end if;

  syntax_node := Adac.AST.INVALID_NODE_ID;
  report_unsupported;
end parse_expression_staging;
