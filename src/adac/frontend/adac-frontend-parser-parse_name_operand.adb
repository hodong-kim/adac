-- ============================================================================
-- adac-frontend-parser-parse_name_operand.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.Frontend.Parser)
procedure parse_name_operand
  (self                       : in out Parser;
   context                    : in out Adac.Compilation.Context;
   text                       : in out Ada.Strings.Unbounded.Unbounded_String;
   has_attribute              : in out Boolean;
   has_explicit_dereference   : in out Boolean;
   has_parenthesized_suffix   : in out Boolean;
   has_qualified_apostrophe   : in out Boolean;
   qualified_prefix_node      : out Adac.AST.Node_ID;
   has_range_attribute        : in out Boolean;
   direct_name_count          : in out Natural;
   allow_parenthesized_suffix : Boolean;
   publish_syntax             : Boolean;
   syntax_node                : in out Adac.AST.Node_ID)
is
  type Parenthesized_State is
    (Expect_Item,
     After_Item,
     After_Dot,
     After_Apostrophe);
  limits : constant Adac.Resources.Limits :=
    Adac.Compilation.resource_limits (context);
  is_direct_name : Boolean := True;
  can_publish    : Boolean := publish_syntax;
  current_has_attribute : Boolean := False;
  current_has_parenthesized_suffix : Boolean := False;

  procedure disable_publication is
  begin
    can_publish := False;
    syntax_node := Adac.AST.INVALID_NODE_ID;
  end disable_publication;

  function current_accepts_parenthesized_suffix return Boolean is
  begin
    if syntax_node = Adac.AST.INVALID_NODE_ID then
      return False;
    end if;

    declare
      kind : constant Adac.AST.Node_Kind :=
        Adac.Compilation.Syntax.kind_of (context, syntax_node);
    begin
      return kind = Adac.AST.Identifier_Name_Node or else
        kind = Adac.AST.Selected_Name_Node or else
        kind = Adac.AST.Parenthesized_Name_Node or else
        kind = Adac.AST.Selected_Component_Node or else
        kind = Adac.AST.Attribute_Name_Node;
    end;
  end current_accepts_parenthesized_suffix;

  procedure report_ast_node_limit (position : Adac.Source.Position) is
  begin
    self.failed := True;
    syntax_node := Adac.AST.INVALID_NODE_ID;
    Adac.Compilation.Diagnostics.error
      (context, position, "AST node limit exceeded");
  end report_ast_node_limit;

  procedure parse_identifier_component
    (target      : in out Adac.AST.Node_ID;
     is_selector : Boolean;
     publish     : Boolean)
  is
    position : constant Adac.Source.Position := self.current.position;
    spelling : constant String := current_text (self);
    symbol   : Adac.Symbols.Symbol_ID;
  begin
    Ada.Strings.Unbounded.append (text, spelling);
    symbol := parse_identifier_symbol (self, context);

    if self.failed or else not publish then
      return;
    end if;

    declare
      component_span : constant Adac.Source.Span :=
        make_token_span (position, spelling);
    begin
      if is_selector then
        if target = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "selected-name publication requires a prefix";
        end if;

        declare
          prefix_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, target);
          prefix_kind : constant Adac.AST.Node_Kind :=
            Adac.Compilation.Syntax.kind_of (context, target);
          whole_span : constant Adac.Source.Span :=
            Adac.Source.make_span
              (Adac.Source.first_position (prefix_span),
               Adac.Source.last_position (component_span));
        begin
          case prefix_kind is
            when Adac.AST.Identifier_Name_Node |
                 Adac.AST.Selected_Name_Node =>
              target := Adac.Compilation.Syntax.create_selected_name
                (context, target, symbol, component_span, whole_span);

            when Adac.AST.Parenthesized_Name_Node |
                 Adac.AST.Explicit_Dereference_Name_Node |
                 Adac.AST.Selected_Component_Node =>
              target := Adac.Compilation.Syntax.create_selected_component
                (context, target, symbol, component_span, whole_span);

            when others =>
              raise Program_Error with
                "selected-component publication received an unsupported prefix";
          end case;
        end;
      else
        target := Adac.Compilation.Syntax.create_identifier_name
          (context, symbol, component_span);
      end if;
    exception
      when Adac.Resources.Limit_Exceeded =>
        report_ast_node_limit (position);
    end;
  end parse_identifier_component;

  function is_identifier_component return Boolean is
  begin
    return self.current.kind = Tok_Identifier or else
      self.current.kind = Tok_Invalid_Identifier;
  end is_identifier_component;

  procedure parse_selector is
    spelling : constant String := current_text (self);
  begin
    case self.current.kind is
      when Tok_Identifier | Tok_Invalid_Identifier =>
        parse_identifier_component
          (syntax_node,
           is_selector => True,
           publish     => can_publish);

      when Tok_Character_Literal =>
        disable_publication;
        Ada.Strings.Unbounded.append (text, spelling);
        advance (self, context);

      when Tok_String_Literal =>
        disable_publication;

        if not is_operator_symbol (spelling) then
          report_invalid_operator_symbol (self, context);
          return;
        end if;

        Ada.Strings.Unbounded.append (text, spelling);
        advance (self, context);

      when Tok_Invalid_String_Literal =>
        disable_publication;
        report_invalid_operator_symbol (self, context);

      when others =>
        disable_publication;
        report_expected_selector_name (self, context);
    end case;
  end parse_selector;

  procedure report_parenthesized_expected (expected : String)
  is
    spelling : constant String := current_text (self);
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
       spelling);
  end report_parenthesized_expected;

  procedure report_invalid_parenthesized_token is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "invalid token in parenthesized name suffix " &
       current_text (self));
  end report_invalid_parenthesized_token;

  procedure parse_parenthesized_suffix
  is
    type Parenthesized_Frame is record
      prefix_node          : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      items                : Adac.AST.Parenthesized_Name_Item_List;
      pending_selector     : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      saw_named_item       : Boolean := False;
      binary_left          : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      binary_operator_text : Ada.Strings.Unbounded.Unbounded_String;
      binary_operator_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
      slice_lower_bound    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      slice_range_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
      slice_active         : Boolean := False;
    end record;

    package Parenthesized_Frame_Vectors is new Ada.Containers.Vectors
      (Index_Type   => Positive,
       Element_Type => Parenthesized_Frame);

    prefix_node : Adac.AST.Node_ID := syntax_node;
    depth       : Natural := 1;
    state       : Parenthesized_State := Expect_Item;
    items       : Adac.AST.Parenthesized_Name_Item_List;
    item_node   : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    pending_selector : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    saw_named_item   : Boolean := False;
    frames      : Parenthesized_Frame_Vectors.Vector;
    binary_left : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    binary_operator_text : Ada.Strings.Unbounded.Unbounded_String;
    binary_operator_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    slice_lower_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    slice_range_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    slice_active : Boolean := False;

    procedure append_current is
    begin
      Ada.Strings.Unbounded.append (text, current_text (self));
      advance (self, context);
    end append_current;

    procedure reset_items is
      empty : Adac.AST.Parenthesized_Name_Item_List;
    begin
      items := empty;
    end reset_items;

    procedure reset_slice is
    begin
      slice_lower_bound := Adac.AST.INVALID_NODE_ID;
      slice_range_span := Adac.Source.INVALID_SPAN;
      slice_active := False;
    end reset_slice;

    procedure restore_parent_frame (completed : Adac.AST.Node_ID) is
      frame : constant Parenthesized_Frame := frames.last_element;
    begin
      frames.delete_last;
      prefix_node := frame.prefix_node;
      items := frame.items;
      pending_selector := frame.pending_selector;
      saw_named_item := frame.saw_named_item;
      binary_left := frame.binary_left;
      binary_operator_text := frame.binary_operator_text;
      binary_operator_span := frame.binary_operator_span;
      slice_lower_bound := frame.slice_lower_bound;
      slice_range_span := frame.slice_range_span;
      slice_active := frame.slice_active;
      item_node := completed;
      state := After_Item;
    end restore_parent_frame;

    procedure disable_parenthesized_publication is
    begin
      disable_publication;
      item_node := Adac.AST.INVALID_NODE_ID;
    end disable_parenthesized_publication;

    function item_is_simple_name return Boolean is
    begin
      if item_node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      declare
        kind : constant Adac.AST.Node_Kind :=
          Adac.Compilation.Syntax.kind_of (context, item_node);
      begin
        return kind = Adac.AST.Identifier_Name_Node or else
          kind = Adac.AST.Selected_Name_Node;
      end;
    end item_is_simple_name;

    function item_accepts_selector return Boolean is
    begin
      if item_node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      declare
        kind : constant Adac.AST.Node_Kind :=
          Adac.Compilation.Syntax.kind_of (context, item_node);
      begin
        return kind = Adac.AST.Identifier_Name_Node or else
          kind = Adac.AST.Selected_Name_Node or else
          kind = Adac.AST.Parenthesized_Name_Node or else
          kind = Adac.AST.Explicit_Dereference_Name_Node or else
          kind = Adac.AST.Selected_Component_Node;
      end;
    end item_accepts_selector;

    function item_accepts_attribute return Boolean is
    begin
      if item_node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      declare
        kind : constant Adac.AST.Node_Kind :=
          Adac.Compilation.Syntax.kind_of (context, item_node);
      begin
        return kind = Adac.AST.Identifier_Name_Node or else
          kind = Adac.AST.Selected_Name_Node or else
          kind = Adac.AST.Parenthesized_Name_Node or else
          kind = Adac.AST.Explicit_Dereference_Name_Node or else
          kind = Adac.AST.Selected_Component_Node or else
          kind = Adac.AST.Slice_Name_Node or else
          kind = Adac.AST.Attribute_Name_Node;
      end;
    end item_accepts_attribute;

    function parenthesized_name_is_bounded_binary_operand
      (candidate : Adac.AST.Node_ID)
    return Boolean is
      pending    : Adac.AST.Node_List;
      next_index : Natural := 1;
    begin
      Adac.AST.append (pending, candidate);

      while next_index <= Adac.AST.list_count (pending) loop
        declare
          current : constant Adac.AST.Node_ID :=
            Adac.AST.list_element (pending, Positive(next_index));
          kind : constant Adac.AST.Node_Kind :=
            Adac.Compilation.Syntax.kind_of (context, current);
        begin
          next_index := next_index + 1;
          case kind is
            when Adac.AST.Parenthesized_Name_Node =>
              declare
                prefix : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.name_prefix (context, current);
              begin
                Adac.AST.append (pending, prefix);
              end;
              for index in 1 ..
                Adac.Compilation.Syntax.parenthesized_item_count
                  (context, current)
              loop
                declare
                  actual : constant Adac.AST.Node_ID :=
                    Adac.Compilation.Syntax.parenthesized_item_at
                      (context, current, index);
                  actual_kind : constant Adac.AST.Node_Kind :=
                    Adac.Compilation.Syntax.kind_of (context, actual);
                begin
                  case actual_kind is
                    when Adac.AST.Identifier_Name_Node |
                         Adac.AST.Selected_Name_Node |
                         Adac.AST.Parenthesized_Name_Node |
                         Adac.AST.Attribute_Name_Node =>
                      Adac.AST.append (pending, actual);

                    when Adac.AST.Numeric_Literal_Node |
                         Adac.AST.Character_Literal_Node |
                         Adac.AST.String_Literal_Node =>
                      null;

                    when others =>
                      return False;
                  end case;
                end;
              end loop;

            when Adac.AST.Attribute_Name_Node =>
              declare
                prefix : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.name_prefix (context, current);
                prefix_kind : constant Adac.AST.Node_Kind :=
                  Adac.Compilation.Syntax.kind_of (context, prefix);
              begin
                if prefix_kind /= Adac.AST.Identifier_Name_Node and then
                   prefix_kind /= Adac.AST.Selected_Name_Node
                then
                  return False;
                end if;
              end;

            when Adac.AST.Identifier_Name_Node |
                 Adac.AST.Selected_Name_Node =>
              null;

            when others =>
              return False;
          end case;
        end;
      end loop;

      return True;
    end parenthesized_name_is_bounded_binary_operand;

    function item_is_parenthesized_binary_operand return Boolean is
    begin
      if item_node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      declare
        kind : constant Adac.AST.Node_Kind :=
          Adac.Compilation.Syntax.kind_of (context, item_node);
      begin
        if kind = Adac.AST.Attribute_Name_Node then
          declare
            prefix : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.name_prefix (context, item_node);
            prefix_kind : constant Adac.AST.Node_Kind :=
              Adac.Compilation.Syntax.kind_of (context, prefix);
          begin
            return prefix_kind = Adac.AST.Identifier_Name_Node or else
              prefix_kind = Adac.AST.Selected_Name_Node;
          end;
        end if;

        if kind = Adac.AST.Parenthesized_Name_Node then
          return parenthesized_name_is_bounded_binary_operand (item_node);
        end if;

        return kind = Adac.AST.Numeric_Literal_Node or else
          kind = Adac.AST.String_Literal_Node or else
          kind = Adac.AST.Identifier_Name_Node or else
          kind = Adac.AST.Selected_Name_Node or else
          kind = Adac.AST.Binary_Adding_Node;
      end;
    end item_is_parenthesized_binary_operand;

    function prefix_accepts_slice return Boolean is
    begin
      if prefix_node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      declare
        kind : constant Adac.AST.Node_Kind :=
          Adac.Compilation.Syntax.kind_of (context, prefix_node);
      begin
        return kind = Adac.AST.Identifier_Name_Node or else
          kind = Adac.AST.Selected_Name_Node or else
          kind = Adac.AST.Attribute_Name_Node;
      end;
    end prefix_accepts_slice;

    function item_is_current_simple_expression return Boolean is
    begin
      if item_node = Adac.AST.INVALID_NODE_ID then
        return False;
      end if;

      declare
        kind : constant Adac.AST.Node_Kind :=
          Adac.Compilation.Syntax.kind_of (context, item_node);
      begin
        return kind = Adac.AST.Numeric_Literal_Node or else
          kind = Adac.AST.Identifier_Name_Node or else
          kind = Adac.AST.Selected_Name_Node or else
          kind = Adac.AST.Selected_Component_Node or else
          kind = Adac.AST.Parenthesized_Name_Node or else
          kind = Adac.AST.Slice_Name_Node or else
          kind = Adac.AST.Attribute_Name_Node or else
          kind = Adac.AST.Binary_Exponentiating_Node or else
          kind = Adac.AST.Binary_Multiplying_Node or else
          kind = Adac.AST.Binary_Adding_Node;
      end;
    end item_is_current_simple_expression;

    procedure publish_numeric_item is
      literal_position : constant Adac.Source.Position := self.current.position;
      spelling : constant String := current_text (self);
      form : Adac.AST.Numeric_Literal_Kind;
    begin
      case self.current.kind is
        when Tok_Decimal_Integer_Literal =>
          form := Adac.AST.Decimal_Integer_Form;
        when Tok_Decimal_Real_Literal =>
          form := Adac.AST.Decimal_Real_Form;
        when Tok_Based_Integer_Literal =>
          form := Adac.AST.Based_Integer_Form;
        when Tok_Based_Real_Literal =>
          form := Adac.AST.Based_Real_Form;
        when others =>
          raise Program_Error with
            "slice numeric item received a nonnumeric token";
      end case;

      item_node := Adac.Compilation.Syntax.create_numeric_literal
        (context, form, spelling, make_token_span (literal_position, spelling));
      Adac.Compilation.Syntax.validate_numeric_literal (context, item_node);
    exception
      when Adac.Resources.Limit_Exceeded =>
        report_ast_node_limit (literal_position);
    end publish_numeric_item;

    procedure finish_pending_binary is
    begin
      if binary_left = Adac.AST.INVALID_NODE_ID then
        return;
      end if;
      if not can_publish or else not item_is_parenthesized_binary_operand then
        disable_parenthesized_publication;
        binary_left := Adac.AST.INVALID_NODE_ID;
        return;
      end if;

      declare
        left_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, binary_left);
        right_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, item_node);
      begin
        item_node := Adac.Compilation.Syntax.create_binary_adding
          (context,
           binary_left,
           Ada.Strings.Unbounded.to_string (binary_operator_text),
           binary_operator_span,
           item_node,
           Adac.Source.make_span
             (Adac.Source.first_position (left_span),
              Adac.Source.last_position (right_span)));
        Adac.Compilation.Syntax.validate_expression (context, item_node);
        binary_left := Adac.AST.INVALID_NODE_ID;
      exception
        when Adac.Resources.Limit_Exceeded =>
          report_ast_node_limit
            (Adac.Source.first_position (binary_operator_span));
      end;
    end finish_pending_binary;

    procedure append_published_item is
    begin
      if not can_publish then
        return;
      end if;
      if item_node = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "parenthesized-name publication lost an item";
      end if;

      if pending_selector /= Adac.AST.INVALID_NODE_ID then
        Adac.AST.append (items, pending_selector, item_node);
        pending_selector := Adac.AST.INVALID_NODE_ID;
        saw_named_item := True;
      elsif saw_named_item then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "positional actual follows named association");
        return;
      else
        Adac.AST.append (items, item_node);
      end if;
      item_node := Adac.AST.INVALID_NODE_ID;
    end append_published_item;

    procedure parse_item_attribute_designator is
      designator_first : constant Adac.Source.Position :=
        self.current.position;
      spelling : constant String := current_text (self);
      symbol   : Adac.Symbols.Symbol_ID;
    begin
      if not can_publish or else not item_accepts_attribute then
        raise Program_Error with
          "parenthesized attribute publication requires a current-name item";
      end if;

      Ada.Strings.Unbounded.append (text, spelling);
      symbol := parse_identifier_symbol (self, context);
      if self.failed then
        return;
      end if;

      declare
        designator_span : constant Adac.Source.Span :=
          make_token_span (designator_first, spelling);
        prefix_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, item_node);
      begin
        item_node := Adac.Compilation.Syntax.create_attribute_name
          (context,
           item_node,
           symbol,
           designator_span,
           Adac.Source.make_span
             (Adac.Source.first_position (prefix_span),
              Adac.Source.last_position (designator_span)));
      exception
        when Adac.Resources.Limit_Exceeded =>
          report_ast_node_limit (designator_first);
      end;
    end parse_item_attribute_designator;

    procedure report_state_error is
    begin
      if state = After_Item then
        report_parenthesized_expected
          ("parenthesized name delimiter");
      else
        report_parenthesized_expected
          ("parenthesized name item");
      end if;
    end report_state_error;

    procedure report_nested_frame_limit is
    begin
      self.failed := True;
      syntax_node := Adac.AST.INVALID_NODE_ID;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "expression nesting limit exceeded");
    end report_nested_frame_limit;

    function create_parenthesized_node
      (closing : Adac.Source.Position)
    return Adac.AST.Node_ID
    is
    begin
      if prefix_node = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "parenthesized-name publication requires a prefix";
      end if;

      return Adac.Compilation.Syntax.create_parenthesized_name
        (context,
         prefix_node,
         items,
         Adac.Source.make_span
           (Adac.Source.first_position
              (Adac.Compilation.Syntax.node_span (context, prefix_node)),
            closing));
    exception
      when Adac.Resources.Limit_Exceeded =>
        report_ast_node_limit
          (Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, prefix_node)));
        return Adac.AST.INVALID_NODE_ID;
    end create_parenthesized_node;

  begin
    if self.current.kind /= Tok_Left_Parenthesis then
      raise Program_Error with
        "parenthesized suffix parser requires a left parenthesis";
    end if;

    if can_publish and then prefix_node = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with
        "parenthesized-name publication requires a prefix";
    end if;

    has_parenthesized_suffix := True;
    append_current;

    while not self.failed loop
      case self.current.kind is
        when Tok_Identifier =>
          if state = After_Item then
            report_state_error;
            return;
          end if;

          if can_publish and then state = Expect_Item then
            parse_identifier_component
              (item_node,
               is_selector => False,
               publish     => True);
          elsif can_publish and then state = After_Dot then
            parse_identifier_component
              (item_node,
               is_selector => True,
               publish     => True);
          elsif can_publish and then state = After_Apostrophe then
            parse_item_attribute_designator;
          else
            append_current;
          end if;

          state := After_Item;

        when Tok_Invalid_Identifier =>
          disable_parenthesized_publication;
          report_invalid_identifier (self, context);
          return;

        when Tok_Decimal_Integer_Literal |
             Tok_Decimal_Real_Literal |
             Tok_Based_Integer_Literal |
             Tok_Based_Real_Literal |
             Tok_Null =>
          if state /= Expect_Item then
            report_state_error;
            return;
          end if;

          if can_publish and then self.current.kind /= Tok_Null then
            publish_numeric_item;
          else
            disable_parenthesized_publication;
          end if;
          if not self.failed then
            append_current;
            state := After_Item;
          end if;

        when Tok_Invalid_Numeric_Literal =>
          disable_parenthesized_publication;
          report_numeric_literal (self, context);
          return;

        when Tok_Character_Literal =>
          if state /= Expect_Item and then state /= After_Dot then
            report_state_error;
            return;
          end if;

          if can_publish and then state = Expect_Item then
            declare
              literal_position : constant Adac.Source.Position :=
                self.current.position;
              spelling : constant String := current_text (self);
            begin
              item_node := Adac.Compilation.Syntax.create_character_literal
                (context,
                 spelling,
                 make_token_span (literal_position, spelling));
              Adac.Compilation.Syntax.validate_character_literal
                (context, item_node);
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (literal_position);
                return;
            end;
          else
            disable_parenthesized_publication;
          end if;

          append_current;
          state := After_Item;

        when Tok_String_Literal =>
          if state = After_Dot then
            if not is_operator_symbol (current_text (self)) then
              report_invalid_operator_symbol (self, context);
              return;
            end if;
            disable_parenthesized_publication;
          elsif state /= Expect_Item then
            report_state_error;
            return;
          elsif can_publish then
            declare
              literal_position : constant Adac.Source.Position :=
                self.current.position;
              spelling : constant String := current_text (self);
            begin
              item_node := Adac.Compilation.Syntax.create_string_literal
                (context,
                 spelling,
                 make_token_span (literal_position, spelling));
              Adac.Compilation.Syntax.validate_string_literal
                (context, item_node);
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (literal_position);
                return;
            end;
          end if;

          append_current;
          state := After_Item;

        when Tok_Invalid_String_Literal =>
          disable_parenthesized_publication;

          if state = After_Dot then
            report_invalid_operator_symbol (self, context);
          else
            report_string_literal (self, context);
          end if;
          return;

        when Tok_All =>
          if state /= After_Dot then
            report_state_error;
            return;
          end if;

          has_explicit_dereference := True;
          if can_publish then
            if item_node = Adac.AST.INVALID_NODE_ID then
              raise Program_Error with
                "explicit-dereference publication lost its prefix";
            end if;

            declare
              all_position : constant Adac.Source.Position :=
                self.current.position;
              spelling : constant String := current_text (self);
              all_span : constant Adac.Source.Span :=
                make_token_span (all_position, spelling);
              prefix_span : constant Adac.Source.Span :=
                Adac.Compilation.Syntax.node_span (context, item_node);
            begin
              item_node :=
                Adac.Compilation.Syntax.create_explicit_dereference_name
                  (context,
                   item_node,
                   all_span,
                   Adac.Source.make_span
                     (Adac.Source.first_position (prefix_span),
                      Adac.Source.last_position (all_span)));
              Adac.Compilation.Syntax.validate_name (context, item_node);
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (all_position);
                return;
            end;
          end if;

          append_current;
          state := After_Item;

        when Tok_Left_Parenthesis =>
          if state = After_Dot then
            report_state_error;
            return;
          end if;

          if can_publish and then
             state = After_Item and then
             item_is_simple_name
          then
            if Natural(frames.length) >=
               limits.maximum_expression_nesting
            then
              report_nested_frame_limit;
              return;
            end if;

            frames.append
              (Parenthesized_Frame'
                 (prefix_node          => prefix_node,
                  items                => items,
                  pending_selector     => pending_selector,
                  saw_named_item       => saw_named_item,
                  binary_left          => binary_left,
                  binary_operator_text => binary_operator_text,
                  binary_operator_span => binary_operator_span,
                  slice_lower_bound    => slice_lower_bound,
                  slice_range_span     => slice_range_span,
                  slice_active         => slice_active));
            prefix_node := item_node;
            item_node := Adac.AST.INVALID_NODE_ID;
            reset_items;
            pending_selector := Adac.AST.INVALID_NODE_ID;
            saw_named_item := False;
            binary_left := Adac.AST.INVALID_NODE_ID;
            binary_operator_text := Ada.Strings.Unbounded.Null_Unbounded_String;
            binary_operator_span := Adac.Source.INVALID_SPAN;
            reset_slice;
          else
            disable_parenthesized_publication;
          end if;

          depth := depth + 1;
          append_current;
          state := Expect_Item;

        when Tok_Right_Parenthesis =>
          if state /= After_Item then
            report_state_error;
            return;
          end if;

          finish_pending_binary;
          if self.failed then
            return;
          end if;

          if can_publish and then slice_active then
            if slice_lower_bound = Adac.AST.INVALID_NODE_ID or else
               not item_is_current_simple_expression
            then
              disable_parenthesized_publication;
            else
              declare
                closing : constant Adac.Source.Position :=
                  self.current.position;
                completed : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
              begin
                completed := Adac.Compilation.Syntax.create_slice_name
                  (context,
                   prefix_node,
                   slice_lower_bound,
                   slice_range_span,
                   item_node,
                   Adac.Source.make_span
                     (Adac.Source.first_position
                        (Adac.Compilation.Syntax.node_span
                           (context, prefix_node)),
                      closing));
                Adac.Compilation.Syntax.validate_name (context, completed);
                append_current;
                depth := depth - 1;
                reset_slice;
                if frames.is_empty then
                  if depth /= 0 then
                    raise Program_Error with
                      "slice-name frame depth is inconsistent";
                  end if;
                  syntax_node := completed;
                  return;
                end if;
                restore_parent_frame (completed);
              exception
                when Adac.Resources.Limit_Exceeded =>
                  report_ast_node_limit (closing);
                  return;
              end;
            end if;
          end if;

          if can_publish then
            append_published_item;

            declare
              closing : constant Adac.Source.Position :=
                self.current.position;
              completed : constant Adac.AST.Node_ID :=
                create_parenthesized_node (closing);
            begin
              if self.failed then
                return;
              end if;

              append_current;
              depth := depth - 1;

              if frames.is_empty then
                if depth /= 0 then
                  raise Program_Error with
                    "parenthesized-name frame depth is inconsistent";
                end if;
                syntax_node := completed;
                return;
              end if;

              restore_parent_frame (completed);
            end;
          elsif depth = 1 then
            append_current;
            depth := depth - 1;
            return;
          else
            append_current;
            depth := depth - 1;
            state := After_Item;
          end if;

        when Tok_Plus | Tok_Minus | Tok_Ampersand =>
          if state /= After_Item then
            report_state_error;
            return;
          end if;

          if binary_left /= Adac.AST.INVALID_NODE_ID then
            finish_pending_binary;
            if self.failed then
              return;
            end if;
          end if;

          if can_publish and then
             item_is_parenthesized_binary_operand
          then
            binary_left := item_node;
            item_node := Adac.AST.INVALID_NODE_ID;
            binary_operator_text :=
              Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
            binary_operator_span :=
              make_token_span (self.current.position, current_text (self));
          else
            disable_parenthesized_publication;
          end if;

          append_current;
          state := Expect_Item;

        when Tok_Comma =>
          if state /= After_Item then
            report_state_error;
            return;
          end if;

          finish_pending_binary;
          if self.failed then
            return;
          end if;
          if slice_active then
            disable_parenthesized_publication;
          end if;

          if can_publish then
            append_published_item;
          end if;

          append_current;
          state := Expect_Item;

        when Tok_Double_Dot =>
          if state /= After_Item then
            report_state_error;
            return;
          end if;

          finish_pending_binary;
          if self.failed then
            return;
          end if;

          if can_publish and then
             not slice_active and then
             prefix_accepts_slice and then
             Adac.AST.parenthesized_name_item_list_count (items) = 0 and then
             item_is_current_simple_expression
          then
            slice_lower_bound := item_node;
            item_node := Adac.AST.INVALID_NODE_ID;
            slice_range_span :=
              make_token_span (self.current.position, current_text (self));
            slice_active := True;
          else
            disable_parenthesized_publication;
          end if;

          append_current;
          state := Expect_Item;

        when Tok_Arrow =>
          if state /= After_Item then
            report_state_error;
            return;
          end if;

          if can_publish then
            finish_pending_binary;
            if self.failed then
              return;
            end if;
            if slice_active or else
               pending_selector /= Adac.AST.INVALID_NODE_ID or else
               item_node = Adac.AST.INVALID_NODE_ID or else
               Adac.Compilation.Syntax.kind_of (context, item_node) /=
                 Adac.AST.Identifier_Name_Node
            then
              disable_parenthesized_publication;
            else
              pending_selector := item_node;
              item_node := Adac.AST.INVALID_NODE_ID;
            end if;
          end if;

          append_current;
          state := Expect_Item;

        when Tok_Dot =>
          if state /= After_Item then
            report_state_error;
            return;
          end if;

          if can_publish and then not item_accepts_selector then
            disable_parenthesized_publication;
          end if;

          append_current;
          state := After_Dot;

        when Tok_Apostrophe =>
          if state /= After_Item then
            report_state_error;
            return;
          end if;

          has_attribute := True;
          if can_publish and then not item_accepts_attribute then
            disable_parenthesized_publication;
          end if;
          append_current;
          state := After_Apostrophe;

        when Tok_Range | Tok_Digits | Tok_Delta =>
          if state /= After_Apostrophe then
            report_state_error;
            return;
          end if;

          disable_parenthesized_publication;
          append_current;
          state := After_Item;

        when Tok_Semicolon | Tok_EOF =>
          disable_parenthesized_publication;
          report_expected (self, context, Tok_Right_Parenthesis);
          return;

        when others =>
          disable_parenthesized_publication;
          report_invalid_parenthesized_token;
          return;
      end case;
    end loop;
  end parse_parenthesized_suffix;

begin
  qualified_prefix_node := Adac.AST.INVALID_NODE_ID;
  if not is_identifier_component then
    raise Program_Error with
      "name parser received a token that cannot start a name";
  end if;

  if publish_syntax then
    syntax_node := Adac.AST.INVALID_NODE_ID;
  end if;

  parse_identifier_component
    (syntax_node,
     is_selector => False,
     publish     => can_publish);

  if self.failed then
    return;
  end if;

  loop
    if self.current.kind = Tok_Dot then
      is_direct_name := False;
      Ada.Strings.Unbounded.append (text, ".");
      expect (self, context, Tok_Dot);

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_All then
        disable_publication;
        has_explicit_dereference := True;
        Ada.Strings.Unbounded.append (text, current_text (self));
        advance (self, context);
      else
        parse_selector;
      end if;
    elsif self.current.kind = Tok_Apostrophe then
      if current_has_attribute or else current_has_parenthesized_suffix then
        disable_publication;
      end if;

      is_direct_name := False;
      Ada.Strings.Unbounded.append (text, "'");
      expect (self, context, Tok_Apostrophe);

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Left_Parenthesis or else
         self.current.kind = Tok_Left_Bracket
      then
        if can_publish then
          qualified_prefix_node := syntax_node;
        end if;
        disable_publication;
        has_qualified_apostrophe := True;
        return;
      end if;

      has_attribute := True;
      current_has_attribute := True;

      if self.current.kind = Tok_Range then
        has_range_attribute := True;
        declare
          designator_first : constant Adac.Source.Position :=
            self.current.position;
          spelling : constant String := current_text (self);
          symbol   : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
        begin
          Ada.Strings.Unbounded.append (text, spelling);
          if can_publish then
            begin
              symbol := Adac.Compilation.Symbols.intern (context, spelling);
            exception
              when Adac.Resources.Limit_Exceeded =>
                self.failed := True;
                Adac.Compilation.Diagnostics.error
                  (context, designator_first, "symbol limit exceeded");
                return;
            end;

            declare
              designator_span : constant Adac.Source.Span :=
                make_token_span (designator_first, spelling);
              prefix_span : constant Adac.Source.Span :=
                Adac.Compilation.Syntax.node_span (context, syntax_node);
            begin
              syntax_node := Adac.Compilation.Syntax.create_attribute_name
                (context,
                 syntax_node,
                 symbol,
                 designator_span,
                 Adac.Source.make_span
                   (Adac.Source.first_position (prefix_span),
                    Adac.Source.last_position (designator_span)));
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (designator_first);
                return;
            end;
          end if;
          advance (self, context);
        end;
      elsif self.current.kind = Tok_Digits or else
            self.current.kind = Tok_Delta
      then
        disable_publication;
        Ada.Strings.Unbounded.append (text, current_text (self));
        advance (self, context);
      elsif not is_identifier_component then
        disable_publication;
        report_expected (self, context, Tok_Identifier);
        return;
      else
        declare
          designator_first : constant Adac.Source.Position :=
            self.current.position;
          spelling : constant String := current_text (self);
          symbol   : Adac.Symbols.Symbol_ID;
        begin
          Ada.Strings.Unbounded.append (text, spelling);
          symbol := parse_identifier_symbol (self, context);

          if self.failed then
            return;
          end if;

          if can_publish then
            declare
              designator_span : constant Adac.Source.Span :=
                make_token_span (designator_first, spelling);
              prefix_span : constant Adac.Source.Span :=
                Adac.Compilation.Syntax.node_span (context, syntax_node);
            begin
              syntax_node := Adac.Compilation.Syntax.create_attribute_name
                (context,
                 syntax_node,
                 symbol,
                 designator_span,
                 Adac.Source.make_span
                   (Adac.Source.first_position (prefix_span),
                    Adac.Source.last_position (designator_span)));
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit (designator_first);
            end;
          end if;
        end;
      end if;
    elsif self.current.kind = Tok_Left_Parenthesis and then
          allow_parenthesized_suffix
    then
      if can_publish and then not current_accepts_parenthesized_suffix then
        disable_publication;
      end if;

      current_has_parenthesized_suffix := True;
      is_direct_name := False;
      parse_parenthesized_suffix;
    else
      exit;
    end if;

    if self.failed then
      return;
    end if;
  end loop;

  if is_direct_name then
    direct_name_count := direct_name_count + 1;
  end if;

  if not can_publish then
    syntax_node := Adac.AST.INVALID_NODE_ID;
  end if;
end parse_name_operand;
