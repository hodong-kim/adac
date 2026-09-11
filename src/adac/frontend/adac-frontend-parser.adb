-- ============================================================================
-- adac-frontend-parser.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Characters.Handling;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Compilation.Diagnostics;
with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;
with Adac.Frontend.Lexer;
with Adac.Frontend.Tokens;
with Adac.Resources;
with Adac.Source;
with Adac.Symbols;

package body Adac.Frontend.Parser is

  use Adac.Frontend.Tokens;
  use type Adac.AST.Node_ID;
  use type Adac.AST.Node_Kind;
  use type Adac.AST.Object_Declaration_Form;
  use type Adac.Symbols.Symbol_ID;

  QUOTATION_MARK : constant Character := Character'Val (16#22#);

  type Parsed_Program_Unit_Name_Component is record
    spelling : Ada.Strings.Unbounded.Unbounded_String;
    span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  end record;

  package Parsed_Program_Unit_Name_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Parsed_Program_Unit_Name_Component);

  subtype Parsed_Program_Unit_Name is Parsed_Program_Unit_Name_Vectors.Vector;

  type Parser is limited record
    scanner : Adac.Frontend.Lexer.Scanner;
    current : Token;
    buffered_token : Token;
    has_buffered_token : Boolean := False;
    context_items : Adac.AST.Node_List;
    procedure_symbol : Adac.Symbols.Symbol_ID :=
      Adac.Symbols.INVALID_SYMBOL_ID;
    parameters   : Adac.AST.Node_List;
    declarations : Adac.AST.Node_List;
    statements   : Adac.AST.Node_List;
    unit_item    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    end_symbol   : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    body_span  : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    unit_span  : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    had_recovered_context_error : Boolean := False;
    failed  : Boolean := False;
  end record;

  procedure advance
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    if self.has_buffered_token then
      self.current := self.buffered_token;
      self.has_buffered_token := False;
    else
      self.current := Adac.Frontend.Lexer.next_token (self.scanner);
    end if;
  exception
    when Adac.Resources.Limit_Exceeded =>
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, "source character limit exceeded");
  end advance;

  function peek_token_kind
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  return Token_Kind is
  begin
    if not self.has_buffered_token then
      self.buffered_token := Adac.Frontend.Lexer.next_token (self.scanner);
      self.has_buffered_token := True;
    end if;
    return self.buffered_token.kind;
  exception
    when Adac.Resources.Limit_Exceeded =>
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, "source character limit exceeded");
      return Tok_EOF;
  end peek_token_kind;

  procedure report_expected
    (self     : in out Parser;
     context  : in out Adac.Compilation.Context;
     expected : Token_Kind)
  is
    text : constant String :=
      Ada.Strings.Unbounded.to_string (self.current.text);
  begin
    self.failed := True;

    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "expected " &
       Token_Kind'image (expected) &
       ", got " &
       Token_Kind'image (self.current.kind) &
       " " &
       text);
  end report_expected;

  procedure expect
    (self    : in out Parser;
     context : in out Adac.Compilation.Context;
     kind    : Token_Kind)
  is
  begin
    if self.failed then
      return;
    end if;

    if self.current.kind /= kind then
      report_expected (self, context, kind);
      return;
    end if;

    advance (self, context);
  end expect;

  function current_text (self : Parser) return String is
  begin
    return Ada.Strings.Unbounded.to_string (self.current.text);
  end current_text;

  function is_operator_symbol (text : String) return Boolean is
  begin
    if text'Length < 3 or else
       text(text'First) /= QUOTATION_MARK or else
       text(text'Last) /= QUOTATION_MARK
    then
      return False;
    end if;

    return operator_kind (text(text'First + 1 .. text'Last - 1)) /=
      Tok_Unknown;
  end is_operator_symbol;

  procedure report_expected_selector_name
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
    text : constant String := current_text (self);
  begin
    self.failed := True;

    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "expected selector name, got " &
       Token_Kind'image (self.current.kind) &
       " " &
       text);
  end report_expected_selector_name;

  procedure report_invalid_operator_symbol
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "invalid operator symbol " & current_text (self));
  end report_invalid_operator_symbol;

  function is_numeric_literal (kind : Token_Kind) return Boolean is
  begin
    case kind is
      when Tok_Decimal_Integer_Literal |
           Tok_Decimal_Real_Literal |
           Tok_Based_Integer_Literal |
           Tok_Based_Real_Literal |
           Tok_Invalid_Numeric_Literal =>
        return True;

      when others =>
        return False;
    end case;
  end is_numeric_literal;

  procedure report_numeric_literal
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
    text : constant String := current_text (self);
  begin
    self.failed := True;

    case self.current.kind is
      when Tok_Decimal_Integer_Literal |
           Tok_Decimal_Real_Literal |
           Tok_Based_Integer_Literal |
           Tok_Based_Real_Literal =>
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "numeric literal expressions are not supported: " & text);

      when Tok_Invalid_Numeric_Literal =>
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "invalid numeric literal " & text);

      when others =>
        raise Program_Error with
          "numeric literal reporter received a nonnumeric token";
    end case;
  end report_numeric_literal;

  procedure report_character_literal
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    self.failed := True;

    case self.current.kind is
      when Tok_Character_Literal =>
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "character literal expressions are not supported: " &
           current_text (self));

      when Tok_Apostrophe =>
        Adac.Compilation.Diagnostics.error
          (context, self.current.position, "invalid character literal");

      when others =>
        raise Program_Error with
          "character literal reporter received an unrelated token";
    end case;
  end report_character_literal;

  procedure report_string_literal
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    self.failed := True;

    case self.current.kind is
      when Tok_String_Literal =>
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "string literal expressions are not supported: " &
           current_text (self));

      when Tok_Invalid_String_Literal =>
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "invalid string literal " & current_text (self));

      when others =>
        raise Program_Error with
          "string literal reporter received an unrelated token";
    end case;
  end report_string_literal;

  procedure report_invalid_identifier
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    if self.current.kind /= Tok_Invalid_Identifier then
      raise Program_Error with
        "invalid identifier reporter received another token";
    end if;

    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "invalid identifier " & current_text (self));
  end report_invalid_identifier;

  function parse_identifier_symbol
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  return Adac.Symbols.Symbol_ID
  is
  begin
    if self.failed then
      return Adac.Symbols.INVALID_SYMBOL_ID;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return Adac.Symbols.INVALID_SYMBOL_ID;
    end if;

    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return Adac.Symbols.INVALID_SYMBOL_ID;
    end if;

    declare
      position : constant Adac.Source.Position := self.current.position;
      spelling : constant String := current_text (self);
      symbol   : Adac.Symbols.Symbol_ID;
    begin
      begin
        symbol := Adac.Compilation.Symbols.intern (context, spelling);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, position, "symbol limit exceeded");
          return Adac.Symbols.INVALID_SYMBOL_ID;
      end;

      advance (self, context);
      return symbol;
    end;
  end parse_identifier_symbol;

  procedure parse_unpublished_identifier
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
  begin
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;

    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    advance (self, context);
  end parse_unpublished_identifier;

  function make_token_span
    (position : Adac.Source.Position;
     spelling : String)
  return Adac.Source.Span is
    last : Adac.Source.Position := position;
  begin
    if spelling'length = 0 then
      raise Program_Error with "token span requires nonempty spelling";
    end if;

    if spelling'length - 1 > Positive'Last - position.column then
      raise Program_Error with "token span column overflow";
    end if;

    last.column := position.column + spelling'length - 1;
    return Adac.Source.make_span (position, last);
  end make_token_span;

  procedure continue_selected_identifier_name_staging
    (self                           : in out Parser;
     context                        : in out Adac.Compilation.Context;
     first_position                 : Adac.Source.Position;
     first_spelling                 : String;
     first_symbol                   : Adac.Symbols.Symbol_ID;
     publish_syntax                 : Boolean;
     allow_terminal_operator_symbol : Boolean;
     syntax_node                    : out Adac.AST.Node_ID)
  is
    procedure report_ast_node_limit (position : Adac.Source.Position) is
    begin
      self.failed := True;
      syntax_node := Adac.AST.INVALID_NODE_ID;
      Adac.Compilation.Diagnostics.error
        (context, position, "AST node limit exceeded");
    end report_ast_node_limit;

    procedure publish_component
      (position : Adac.Source.Position;
       spelling : String;
       symbol   : Adac.Symbols.Symbol_ID)
    is
      component_span : constant Adac.Source.Span :=
        make_token_span (position, spelling);
    begin
      if not publish_syntax then
        return;
      end if;

      if syntax_node = Adac.AST.INVALID_NODE_ID then
        syntax_node := Adac.Compilation.Syntax.create_identifier_name
          (context, symbol, component_span);
      else
        declare
          prefix_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, syntax_node);
        begin
          syntax_node := Adac.Compilation.Syntax.create_selected_name
            (context,
             syntax_node,
             symbol,
             component_span,
             Adac.Source.make_span
               (Adac.Source.first_position (prefix_span),
                Adac.Source.last_position (component_span)));
        end;
      end if;
    exception
      when Adac.Resources.Limit_Exceeded =>
        report_ast_node_limit (position);
    end publish_component;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    publish_component (first_position, first_spelling, first_symbol);
    if self.failed then
      return;
    end if;

    while self.current.kind = Tok_Dot loop
      expect (self, context, Tok_Dot);
      if self.failed then
        return;
      end if;

      if allow_terminal_operator_symbol and then
         self.current.kind in Tok_String_Literal | Tok_Invalid_String_Literal
      then
        declare
          position : constant Adac.Source.Position := self.current.position;
          spelling : constant String := current_text (self);
          symbol   : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
        begin
          if self.current.kind = Tok_Invalid_String_Literal or else
             not is_operator_symbol (spelling)
          then
            report_invalid_operator_symbol (self, context);
            return;
          end if;

          if publish_syntax then
            begin
              symbol := Adac.Compilation.Symbols.intern (context, spelling);
            exception
              when Adac.Resources.Limit_Exceeded =>
                self.failed := True;
                Adac.Compilation.Diagnostics.error
                  (context, position, "symbol limit exceeded");
                return;
            end;
          end if;

          advance (self, context);
          if self.failed then
            return;
          end if;
          publish_component (position, spelling, symbol);
          return;
        end;
      end if;

      declare
        position : constant Adac.Source.Position := self.current.position;
        spelling : constant String := current_text (self);
        symbol   : constant Adac.Symbols.Symbol_ID :=
          parse_identifier_symbol (self, context);
      begin
        if self.failed then
          return;
        end if;
        publish_component (position, spelling, symbol);
        if self.failed then
          return;
        end if;
      end;
    end loop;
  end continue_selected_identifier_name_staging;

  procedure parse_selected_identifier_name_staging
    (self           : in out Parser;
     context        : in out Adac.Compilation.Context;
     publish_syntax : Boolean;
     syntax_node    : out Adac.AST.Node_ID)
  is
    first_position : constant Adac.Source.Position := self.current.position;
    first_spelling : constant String := current_text (self);
    first_symbol   : constant Adac.Symbols.Symbol_ID :=
      parse_identifier_symbol (self, context);
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.failed then
      return;
    end if;

    continue_selected_identifier_name_staging
      (self,
       context,
       first_position,
       first_spelling,
       first_symbol,
       publish_syntax,
       allow_terminal_operator_symbol => False,
       syntax_node                    => syntax_node);
  end parse_selected_identifier_name_staging;

  procedure parse_selected_generic_actual_name_staging
    (self           : in out Parser;
     context        : in out Adac.Compilation.Context;
     publish_syntax : Boolean;
     syntax_node    : out Adac.AST.Node_ID)
  is
    first_position : constant Adac.Source.Position := self.current.position;
    first_spelling : constant String := current_text (self);
    first_symbol   : constant Adac.Symbols.Symbol_ID :=
      parse_identifier_symbol (self, context);
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.failed then
      return;
    end if;

    continue_selected_identifier_name_staging
      (self,
       context,
       first_position,
       first_spelling,
       first_symbol,
       publish_syntax,
       allow_terminal_operator_symbol => True,
       syntax_node                    => syntax_node);
  end parse_selected_generic_actual_name_staging;

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
  is separate;

  type Expression_Completion_Mode is
    (Reject_Unsupported_Expression,
     Return_After_Staging);

  type Expression_Terminator_Mode is
    (Require_Exact_Terminator,
     Allow_Comma_Before_Terminator,
     Allow_Semicolon_Before_Terminator,
     Allow_Loop_Before_Terminator);

  type Expression_Grammar_Level is
    (Full_Expression_Level,
     Simple_Expression_Level);

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
  is separate;

  function starts_expression_staging (kind : Token_Kind) return Boolean is
  begin
    if is_numeric_literal (kind) or else is_operator (kind) then
      return True;
    end if;

    case kind is
      when Tok_Character_Literal |
           Tok_Apostrophe |
           Tok_String_Literal |
           Tok_Invalid_String_Literal |
           Tok_Null |
           Tok_New |
           Tok_Left_Parenthesis |
           Tok_Left_Bracket |
           Tok_Identifier |
           Tok_Invalid_Identifier =>
        return True;

      when others =>
        return False;
    end case;
  end starts_expression_staging;

  procedure parse_assignment_statement_tail_staging
    (self           : in out Parser;
     context        : in out Adac.Compilation.Context;
     first          : Adac.Source.Position;
     target         : Adac.AST.Node_ID;
     syntax_node    : out Adac.AST.Node_ID;
     publish_syntax : Boolean := True)
  is
    expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    semicolon  : Adac.Source.Position := self.current.position;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if publish_syntax and then target = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with "assignment tail requires represented target";
    end if;
    if self.current.kind /= Tok_Assign then
      raise Program_Error with "assignment tail requires assignment token";
    end if;

    expect (self, context, Tok_Assign);
    if self.failed then
      return;
    end if;

    declare
      literal_rhs : constant Boolean := is_numeric_literal (self.current.kind);
    begin
      parse_expression_staging
        (self,
         context,
         terminator          => Tok_Semicolon,
         terminator_mode     => Require_Exact_Terminator,
         completion_mode     =>
           (if not publish_syntax or else literal_rhs
            then Return_After_Staging
            else Reject_Unsupported_Expression),
         publish_expression_syntax => publish_syntax,
         syntax_node         => expression,
         accept_relation_expression => True,
         accept_unary_expression    => True);
    end;

    if self.failed then
      return;
    end if;
    if publish_syntax and then expression = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with "assignment lost its RHS expression syntax";
    end if;

    semicolon := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed or else not publish_syntax then
      return;
    end if;

    begin
      syntax_node := Adac.Compilation.Syntax.create_assignment_statement
        (context,
         target,
         expression,
         Adac.Source.make_span (first, semicolon));
      Adac.Compilation.Syntax.validate_assignment_statement
        (context, syntax_node);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        syntax_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_assignment_statement_tail_staging;

  procedure parse_current_assignment_statement_staging
    (self           : in out Parser;
     context        : in out Adac.Compilation.Context;
     syntax_node    : out Adac.AST.Node_ID;
     publish_syntax : Boolean := True)
  is
    first  : constant Adac.Source.Position := self.current.position;
    target : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier
    then
      raise Program_Error with
        "assignment staging requires an identifier token";
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => publish_syntax,
       syntax_node    => target);
    if self.failed then
      return;
    end if;
    if publish_syntax and then target = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with "assignment lost its target syntax";
    end if;

    parse_assignment_statement_tail_staging
      (self,
       context,
       first,
       target,
       syntax_node,
       publish_syntax);
  end parse_current_assignment_statement_staging;

  procedure parse_procedure_call_statement_tail_staging
    (self                : in out Parser;
     context             : in out Adac.Compilation.Context;
     first               : Adac.Source.Position;
     callable_name       : Adac.AST.Node_ID;
     publish_call_syntax : Boolean;
     syntax_node         : out Adac.AST.Node_ID)
  is
    actual_node      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    actuals          : Adac.AST.Procedure_Call_Actual_Association_List;
    semicolon        : Adac.Source.Position := self.current.position;
    saw_named_actual : Boolean := False;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if publish_call_syntax and then
       callable_name = Adac.AST.INVALID_NODE_ID
    then
      raise Program_Error with "procedure call tail requires represented name";
    end if;
    if self.current.kind = Tok_Left_Parenthesis then
      expect (self, context, Tok_Left_Parenthesis);
      if self.failed then
        return;
      end if;

      loop
        declare
          actual_first : Adac.Source.Position := self.current.position;
          selector     : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          named_actual : Boolean := False;
        begin
          if self.current.kind = Tok_Identifier or else
             self.current.kind = Tok_Invalid_Identifier
          then
            named_actual := peek_token_kind (self, context) = Tok_Arrow;
            if self.failed then
              return;
            end if;
          end if;

          if named_actual then
            saw_named_actual := True;
            parse_selected_identifier_name_staging
              (self,
               context,
               publish_syntax => publish_call_syntax,
               syntax_node    => selector);
            if self.failed then
              return;
            end if;
            if publish_call_syntax and then
               selector = Adac.AST.INVALID_NODE_ID
            then
              raise Program_Error with
                "named procedure call actual lost its selector syntax";
            end if;

            expect (self, context, Tok_Arrow);
            if self.failed then
              return;
            end if;
            actual_first := self.current.position;
          elsif saw_named_actual then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "positional procedure call actual follows named association");
            return;
          end if;

          actual_node := Adac.AST.INVALID_NODE_ID;
          parse_expression_staging
            (self,
             context,
             terminator          => Tok_Right_Parenthesis,
             terminator_mode     => Allow_Comma_Before_Terminator,
             completion_mode     => Return_After_Staging,
             publish_expression_syntax => publish_call_syntax,
             syntax_node         => actual_node);
          if self.failed then
            return;
          end if;

          if publish_call_syntax then
            if actual_node = Adac.AST.INVALID_NODE_ID then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 actual_first,
                 "procedure call actual expression is not supported");
              return;
            end if;
            if named_actual then
              Adac.AST.append (actuals, selector, actual_node);
            else
              Adac.AST.append (actuals, actual_node);
            end if;
          end if;
        end;

        exit when self.current.kind = Tok_Right_Parenthesis;
        expect (self, context, Tok_Comma);
        if self.failed then
          return;
        end if;
      end loop;

      expect (self, context, Tok_Right_Parenthesis);
      if self.failed then
        return;
      end if;
    end if;

    semicolon := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed or else not publish_call_syntax then
      return;
    end if;

    begin
      declare
        callable_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, callable_name);
        call_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.first_position (callable_span), semicolon);
      begin
        syntax_node := Adac.Compilation.Syntax.create_procedure_call_statement
          (context, callable_name, actuals, call_span);
        Adac.Compilation.Syntax.validate_procedure_call (context, syntax_node);
      end;
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        syntax_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_procedure_call_statement_tail_staging;

  procedure parse_current_procedure_call_statement_staging
    (self                : in out Parser;
     context             : in out Adac.Compilation.Context;
     publish_call_syntax : Boolean;
     syntax_node         : out Adac.AST.Node_ID)
  is
    first         : constant Adac.Source.Position := self.current.position;
    callable_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier
    then
      raise Program_Error with
        "procedure call staging requires an identifier token";
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => publish_call_syntax,
       syntax_node    => callable_name);
    if self.failed then
      return;
    end if;
    if publish_call_syntax and then
       callable_name = Adac.AST.INVALID_NODE_ID
    then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, first, "procedure call callable name is not supported");
      return;
    end if;

    parse_procedure_call_statement_tail_staging
      (self,
       context,
       first,
       callable_name,
       publish_call_syntax,
       syntax_node);
  end parse_current_procedure_call_statement_staging;

  procedure parse_current_identifier_statement_staging
    (self           : in out Parser;
     context        : in out Adac.Compilation.Context;
     syntax_node    : out Adac.AST.Node_ID;
     publish_syntax : Boolean := True)
  is
    first : constant Adac.Source.Position := self.current.position;
    name  : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier
    then
      raise Program_Error with
        "identifier statement staging requires an identifier token";
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => publish_syntax,
       syntax_node    => name);
    if self.failed then
      return;
    end if;
    if publish_syntax and then name = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with
        "identifier statement lost its leading name syntax";
    end if;

    if self.current.kind = Tok_Assign then
      parse_assignment_statement_tail_staging
        (self,
         context,
         first,
         name,
         syntax_node,
         publish_syntax);
    else
      parse_procedure_call_statement_tail_staging
        (self,
         context,
         first,
         name,
         publish_call_syntax => publish_syntax,
         syntax_node         => syntax_node);
    end if;
  end parse_current_identifier_statement_staging;

  procedure parse_current_loop_closing_staging
    (self      : in out Parser;
     context   : in out Adac.Compilation.Context;
     semicolon : out Adac.Source.Position)
  is
  begin
    semicolon := self.current.position;
    if self.current.kind /= Tok_End then
      raise Program_Error with
        "loop closing staging requires an end token";
    end if;

    expect (self, context, Tok_End);
    if self.failed then
      return;
    end if;
    expect (self, context, Tok_Loop);
    if self.failed then
      return;
    end if;
    semicolon := self.current.position;
    expect (self, context, Tok_Semicolon);
  end parse_current_loop_closing_staging;

  procedure parse_current_for_loop_header_staging
    (self             : in out Parser;
     context          : in out Adac.Compilation.Context;
     form             : out Adac.AST.Loop_Statement_Form;
     parameter_symbol : out Adac.Symbols.Symbol_ID;
     parameter_span   : out Adac.Source.Span;
     reverse_present  : out Boolean;
     iterable_name     : out Adac.AST.Node_ID;
     range_attribute   : out Adac.AST.Node_ID;
     range_lower_bound : out Adac.AST.Node_ID;
     range_upper_bound : out Adac.AST.Node_ID)
  is
    bound_first : Adac.Source.Position := self.current.position;
  begin
    form             := Adac.AST.Generalized_Iterator_Loop_Form;
    parameter_symbol := Adac.Symbols.INVALID_SYMBOL_ID;
    parameter_span   := Adac.Source.INVALID_SPAN;
    reverse_present  := False;
    iterable_name     := Adac.AST.INVALID_NODE_ID;
    range_attribute   := Adac.AST.INVALID_NODE_ID;
    range_lower_bound := Adac.AST.INVALID_NODE_ID;
    range_upper_bound := Adac.AST.INVALID_NODE_ID;

    if self.current.kind /= Tok_For then
      raise Program_Error with
        "for-loop header staging requires a for token";
    end if;

    expect (self, context, Tok_For);
    if self.failed then
      return;
    end if;

    parameter_span :=
      make_token_span (self.current.position, current_text (self));
    parameter_symbol := parse_identifier_symbol (self, context);
    if self.failed then
      return;
    end if;

    case self.current.kind is
      when Tok_In =>
        form := Adac.AST.Discrete_Range_Loop_Form;
        expect (self, context, Tok_In);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Reverse then
          reverse_present := True;
          expect (self, context, Tok_Reverse);
          if self.failed then
            return;
          end if;
        end if;

        bound_first := self.current.position;
        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Double_Dot,
           terminator_mode     => Allow_Loop_Before_Terminator,
           completion_mode     => Return_After_Staging,
           publish_expression_syntax => True,
           syntax_node         => range_lower_bound,
           grammar_level       => Simple_Expression_Level);
        if self.failed then
          return;
        end if;
        if range_lower_bound = Adac.AST.INVALID_NODE_ID then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             bound_first,
             "discrete-range loop lower bounds are not supported");
          return;
        end if;

        if self.current.kind = Tok_Loop then
          if Adac.Compilation.Syntax.kind_of (context, range_lower_bound) /=
               Adac.AST.Attribute_Name_Node or else
             Ada.Characters.Handling.To_Lower
               (Adac.Compilation.Symbols.spelling
                  (context,
                   Adac.Compilation.Syntax.attribute_symbol
                     (context, range_lower_bound))) /= "range"
          then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               bound_first,
               "for-loop range attributes outside current name subset " &
               "are not supported");
            return;
          end if;

          form := Adac.AST.Range_Attribute_Loop_Form;
          range_attribute := range_lower_bound;
          range_lower_bound := Adac.AST.INVALID_NODE_ID;
          expect (self, context, Tok_Loop);
          return;
        end if;

        expect (self, context, Tok_Double_Dot);
        if self.failed then
          return;
        end if;

        bound_first := self.current.position;
        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Loop,
           terminator_mode     => Require_Exact_Terminator,
           completion_mode     => Return_After_Staging,
           publish_expression_syntax => True,
           syntax_node         => range_upper_bound,
           grammar_level       => Simple_Expression_Level);
        if self.failed then
          return;
        end if;
        if range_upper_bound = Adac.AST.INVALID_NODE_ID then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             bound_first,
             "discrete-range loop upper bounds are not supported");
          return;
        end if;

        expect (self, context, Tok_Loop);

      when Tok_Of =>
        form := Adac.AST.Generalized_Iterator_Loop_Form;
        expect (self, context, Tok_Of);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Reverse then
          reverse_present := True;
          expect (self, context, Tok_Reverse);
          if self.failed then
            return;
          end if;
        end if;

        if self.current.kind /= Tok_Identifier and then
           self.current.kind /= Tok_Invalid_Identifier
        then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "iterator loop containers outside current name subset are not " &
             "supported");
          return;
        end if;
        parse_selected_identifier_name_staging
          (self,
           context,
           publish_syntax => True,
           syntax_node    => iterable_name);
        if self.failed then
          return;
        end if;
        if iterable_name = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "iterator loop lost its represented iterable name";
        end if;

        expect (self, context, Tok_Loop);

      when others =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "for loops outside current in-range/of-name subsets are not " &
           "supported");
    end case;
  end parse_current_for_loop_header_staging;

  procedure parse_current_raise_statement_staging
    (self           : in out Parser;
     context        : in out Adac.Compilation.Context;
     syntax_node    : out Adac.AST.Node_ID;
     publish_syntax : Boolean := True;
     bare_only      : Boolean := False)
  is
    first          : constant Adac.Source.Position := self.current.position;
    exception_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    message        : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    message_first  : Adac.Source.Position := first;
    semicolon      : Adac.Source.Position := first;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.current.kind /= Tok_Raise then
      raise Program_Error with "raise staging requires a raise token";
    end if;

    expect (self, context, Tok_Raise);
    if self.failed then
      return;
    end if;
    if bare_only and then self.current.kind /= Tok_Semicolon then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "exception handler named raise statements are not supported");
      return;
    end if;

    if self.current.kind = Tok_Semicolon then
      semicolon := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed or else not publish_syntax then
        return;
      end if;

      begin
        syntax_node :=
          Adac.Compilation.Syntax.create_bare_raise_statement
            (context, Adac.Source.make_span (first, semicolon));
        Adac.Compilation.Syntax.validate_raise_statement
          (context, syntax_node);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          syntax_node := Adac.AST.INVALID_NODE_ID;
          Adac.Compilation.Diagnostics.error
            (context, first, "AST node limit exceeded");
      end;
      return;
    end if;

    if self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier
    then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "raise exception names outside current name subset are not supported");
      return;
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => publish_syntax,
       syntax_node    => exception_name);
    if self.failed then
      return;
    end if;
    if publish_syntax and then
       exception_name = Adac.AST.INVALID_NODE_ID
    then
      raise Program_Error with "raise statement lost its exception name";
    end if;

    if self.current.kind /= Tok_With then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "raise statements outside current with-message form are not " &
         "supported");
      return;
    end if;
    expect (self, context, Tok_With);
    if self.failed then
      return;
    end if;
    message_first := self.current.position;

    parse_expression_staging
      (self,
       context,
       terminator          => Tok_Semicolon,
       terminator_mode     => Require_Exact_Terminator,
       completion_mode     => Return_After_Staging,
       publish_expression_syntax => publish_syntax,
       syntax_node         => message);
    if self.failed then
      return;
    end if;
    if publish_syntax and then message = Adac.AST.INVALID_NODE_ID then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         message_first,
         "raise message expressions are not supported");
      return;
    end if;

    semicolon := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed or else not publish_syntax then
      return;
    end if;

    begin
      syntax_node :=
        Adac.Compilation.Syntax.create_raise_statement
          (context,
           exception_name,
           message,
           Adac.Source.make_span (first, semicolon));
      Adac.Compilation.Syntax.validate_raise_statement (context, syntax_node);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        syntax_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_current_raise_statement_staging;

  procedure parse_current_declaration_staging
    (self                       : in out Parser;
     context                    : in out Adac.Compilation.Context;
     declaration                : out Adac.AST.Node_ID;
     represent_object           : Boolean := True;
     represent_number           : Boolean := False;
     allow_deferred_constant    : Boolean := False;
     publish_syntax             : Boolean := True);

  procedure publish_current_block_staging
    (self               : in out Parser;
     context            : in out Adac.Compilation.Context;
     block_first        : Adac.Source.Position;
     block_declarations : Adac.AST.Node_List;
     block_statements   : Adac.AST.Node_List;
     block_handlers     : Adac.AST.Node_List;
     sequence_span      : Adac.Source.Span;
     block_semicolon    : Adac.Source.Position;
     block_statement    : out Adac.AST.Node_ID);

  type Statement_Publication_Mode is
    (Publish_Statement_Syntax,
     Return_Statement_Syntax,
     Skip_Statement_Publication);

  procedure parse_statement
    (self                           : in out Parser;
     context                        : in out Adac.Compilation.Context;
     publication_mode               : Statement_Publication_Mode;
     syntax_node                    : out Adac.AST.Node_ID;
     allow_return_expression_syntax : Boolean := False);

  type If_Staging_Completion_Mode is
    (Reject_Unsupported_If,
     Return_After_If_Staging);

  type Exception_Handler_Staging_Completion_Mode is
    (Reject_Unsupported_Handlers,
     Return_After_Handler_Staging);

  procedure parse_exception_handlers_staging
    (self                   : in out Parser;
     context                : in out Adac.Compilation.Context;
     terminator             : Token_Kind;
     completion_mode        : Exception_Handler_Staging_Completion_Mode;
     publish_handler_syntax : Boolean;
     handlers               : in out Adac.AST.Node_List);

  procedure parse_current_case_header_common
    (self                 : in out Parser;
     context              : in out Adac.Compilation.Context;
     case_first           : out Adac.Source.Position;
     selecting_expression : out Adac.AST.Node_ID);

  procedure parse_current_case_alternative_header_common
    (self                   : in out Parser;
     context                : in out Adac.Compilation.Context;
     allow_multiple_choices : Boolean;
     allow_others_choice    : Boolean;
     choices                : in out Adac.AST.Node_List);

  procedure parse_current_case_closing_common
    (self      : in out Parser;
     context   : in out Adac.Compilation.Context;
     semicolon : out Adac.Source.Position);

  procedure publish_current_case_alternative_common
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     first       : Adac.Source.Position;
     choices     : Adac.AST.Node_List;
     statements  : Adac.AST.Node_List;
     alternative : out Adac.AST.Node_ID);

  procedure publish_current_case_statement_common
    (self                 : in out Parser;
     context              : in out Adac.Compilation.Context;
     first                : Adac.Source.Position;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     semicolon            : Adac.Source.Position;
     statement            : out Adac.AST.Node_ID);

  procedure parse_compound_statement_staging
    (self            : in out Parser;
     context         : in out Adac.Compilation.Context;
     root_token      : Token_Kind;
     completion_mode : If_Staging_Completion_Mode;
     syntax_node     : out Adac.AST.Node_ID)
  is
    type If_Arm_Kind is (Then_Arm, Elsif_Arm, Else_Arm);
    type Compound_Frame_Kind is
      (If_Frame_Kind, Block_Frame_Kind, Loop_Frame_Kind, Case_Frame_Kind);

    type Compound_Frame is record
      kind               : Compound_Frame_Kind := If_Frame_Kind;
      first              : Adac.Source.Position;
      condition_node      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      then_statements     : Adac.AST.Node_List;
      elsif_parts         : Adac.AST.Node_List;
      elsif_first         : Adac.Source.Position;
      elsif_condition     : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      elsif_statements    : Adac.AST.Node_List;
      else_statements     : Adac.AST.Node_List;
      active_arm          : If_Arm_Kind := Then_Arm;
      then_has_statement  : Boolean := False;
      elsif_has_statement : Boolean := False;
      else_has_statement  : Boolean := False;
      block_declarations : Adac.AST.Node_List;
      block_statements   : Adac.AST.Node_List;
      block_handlers     : Adac.AST.Node_List;
      loop_form             : Adac.AST.Loop_Statement_Form :=
        Adac.AST.Generalized_Iterator_Loop_Form;
      loop_condition        : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      loop_parameter_symbol : Adac.Symbols.Symbol_ID :=
        Adac.Symbols.INVALID_SYMBOL_ID;
      loop_parameter_span   : Adac.Source.Span := Adac.Source.INVALID_SPAN;
      loop_reverse_present  : Boolean := False;
      loop_iterable_name     : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      loop_range_attribute   : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      loop_range_lower_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      loop_range_upper_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      loop_statements       : Adac.AST.Node_List;
      case_selecting_expression : Adac.AST.Node_ID :=
        Adac.AST.INVALID_NODE_ID;
      case_alternatives         : Adac.AST.Node_List;
      case_alternative_first    : Adac.Source.Position;
      case_choices              : Adac.AST.Node_List;
      case_statements           : Adac.AST.Node_List;
    end record;

    package Compound_Frame_Vectors is new Ada.Containers.Vectors
      (Index_Type   => Positive,
       Element_Type => Compound_Frame);

    frames : Compound_Frame_Vectors.Vector;
    publish_syntax : constant Boolean :=
      completion_mode = Return_After_If_Staging;

    procedure report_sequence_unsupported is
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "if statement sequences are not supported");
    end report_sequence_unsupported;

    procedure report_block_body_unsupported is
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "block statement bodies are not supported");
    end report_block_body_unsupported;

    function active_if_arm_has_statement
      (frame : Compound_Frame)
    return Boolean is
    begin
      if frame.kind /= If_Frame_Kind then
        raise Program_Error with "active if arm queried for a block frame";
      end if;
      case frame.active_arm is
        when Then_Arm =>
          return frame.then_has_statement;
        when Elsif_Arm =>
          return frame.elsif_has_statement;
        when Else_Arm =>
          return frame.else_has_statement;
      end case;
    end active_if_arm_has_statement;

    procedure replace_last_frame (frame : Compound_Frame) is
    begin
      frames.replace_element (frames.last_index, frame);
    end replace_last_frame;

    procedure note_statement (statement : Adac.AST.Node_ID) is
      frame : Compound_Frame := frames.last_element;
    begin
      if publish_syntax and then statement = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "represented compound sequence lost a required statement";
      end if;

      case frame.kind is
        when If_Frame_Kind =>
          case frame.active_arm is
            when Then_Arm =>
              frame.then_has_statement := True;
              if publish_syntax then
                Adac.AST.append (frame.then_statements, statement);
              end if;
            when Elsif_Arm =>
              frame.elsif_has_statement := True;
              if publish_syntax then
                Adac.AST.append (frame.elsif_statements, statement);
              end if;
            when Else_Arm =>
              frame.else_has_statement := True;
              if publish_syntax then
                Adac.AST.append (frame.else_statements, statement);
              end if;
          end case;

        when Block_Frame_Kind =>
          if not publish_syntax then
            raise Program_Error with
              "block frame entered without represented syntax";
          end if;
          Adac.AST.append (frame.block_statements, statement);

        when Loop_Frame_Kind =>
          if not publish_syntax then
            raise Program_Error with
              "loop frame entered without represented syntax";
          end if;
          Adac.AST.append (frame.loop_statements, statement);

        when Case_Frame_Kind =>
          if not publish_syntax then
            raise Program_Error with
              "case frame entered without represented syntax";
          end if;
          Adac.AST.append (frame.case_statements, statement);
      end case;
      replace_last_frame (frame);
    end note_statement;

    procedure parse_current_bare_return
      (statement : out Adac.AST.Node_ID)
    is
      first     : constant Adac.Source.Position := self.current.position;
      semicolon : Adac.Source.Position := first;
    begin
      statement := Adac.AST.INVALID_NODE_ID;
      expect (self, context, Tok_Return);
      if self.failed then
        return;
      end if;

      if self.current.kind /= Tok_Semicolon then
        report_sequence_unsupported;
        return;
      end if;

      semicolon := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed or else not publish_syntax then
        return;
      end if;

      begin
        statement := Adac.Compilation.Syntax.create_statement
          (context,
           Adac.AST.Return_Statement_Node,
           Adac.Source.make_span (first, semicolon));
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, first, "AST node limit exceeded");
      end;
    end parse_current_bare_return;

    procedure push_if_frame is
      frame : Compound_Frame;
      condition_first : Adac.Source.Position := self.current.position;
    begin
      if self.current.kind /= Tok_If then
        raise Program_Error with
          "if frame staging requires an if token";
      end if;

      frame.kind := If_Frame_Kind;
      frame.first := self.current.position;
      expect (self, context, Tok_If);
      if self.failed then
        return;
      end if;

      condition_first := self.current.position;
      parse_expression_staging
        (self,
         context,
         terminator          => Tok_Then,
         terminator_mode     => Require_Exact_Terminator,
         completion_mode     => Return_After_Staging,
         publish_expression_syntax => publish_syntax,
         syntax_node         => frame.condition_node);
      if self.failed then
        return;
      end if;

      if publish_syntax and then
         frame.condition_node = Adac.AST.INVALID_NODE_ID
      then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           condition_first,
           "if condition expressions are not supported");
        return;
      end if;

      expect (self, context, Tok_Then);
      if not self.failed then
        frames.append (frame);
      end if;
    end push_if_frame;

    procedure push_block_frame is
      frame : Compound_Frame;
      declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if not publish_syntax or else
         (self.current.kind /= Tok_Declare and then
          self.current.kind /= Tok_Begin)
      then
        raise Program_Error with
          "represented block frame requires a declare or begin token";
      end if;

      frame.kind := Block_Frame_Kind;
      frame.first := self.current.position;
      if self.current.kind = Tok_Declare then
        expect (self, context, Tok_Declare);
        if self.failed then
          return;
        end if;

        while not self.failed and then
              (self.current.kind = Tok_Identifier or else
               self.current.kind = Tok_Invalid_Identifier)
        loop
          declaration := Adac.AST.INVALID_NODE_ID;
          parse_current_declaration_staging
            (self, context, declaration => declaration);
          if self.failed then
            return;
          end if;
          if declaration = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "compound block declaration lost represented syntax";
          end if;
          Adac.AST.append (frame.block_declarations, declaration);
        end loop;
      end if;

      expect (self, context, Tok_Begin);
      if not self.failed then
        frames.append (frame);
      end if;
    end push_block_frame;

    procedure report_loop_body_unsupported
      (form : Adac.AST.Loop_Statement_Form)
    is
      message : constant String :=
        (case form is
           when Adac.AST.Discrete_Range_Loop_Form =>
             "discrete-range loop bodies are not supported",
           when Adac.AST.Range_Attribute_Loop_Form =>
             "range-attribute loop bodies are not supported",
           when Adac.AST.Generalized_Iterator_Loop_Form =>
             "iterator loop bodies are not supported",
           when Adac.AST.While_Loop_Form =>
             "while loop bodies are not supported",
           when Adac.AST.Simple_Loop_Form =>
             "loop bodies are not supported");
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, self.current.position, message);
    end report_loop_body_unsupported;

    procedure report_case_sequence_unsupported is
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "case alternative statement sequences are not supported");
    end report_case_sequence_unsupported;

    procedure push_loop_frame is
      frame : Compound_Frame;
      condition_first : Adac.Source.Position := self.current.position;
    begin
      if not publish_syntax or else
         (self.current.kind /= Tok_For and then
          self.current.kind /= Tok_While and then
          self.current.kind /= Tok_Loop)
      then
        raise Program_Error with
          "represented loop frame requires a loop-start token";
      end if;

      frame.kind := Loop_Frame_Kind;
      frame.first := self.current.position;
      case self.current.kind is
        when Tok_For =>
          parse_current_for_loop_header_staging
            (self,
             context,
             frame.loop_form,
             frame.loop_parameter_symbol,
             frame.loop_parameter_span,
             frame.loop_reverse_present,
             frame.loop_iterable_name,
             frame.loop_range_attribute,
             frame.loop_range_lower_bound,
             frame.loop_range_upper_bound);

        when Tok_While =>
          frame.loop_form := Adac.AST.While_Loop_Form;
          expect (self, context, Tok_While);
          if self.failed then
            return;
          end if;
          condition_first := self.current.position;
          parse_expression_staging
            (self,
             context,
             terminator          => Tok_Loop,
             terminator_mode     => Require_Exact_Terminator,
             completion_mode     => Return_After_Staging,
             publish_expression_syntax => True,
             syntax_node         => frame.loop_condition);
          if self.failed then
            return;
          end if;
          if frame.loop_condition = Adac.AST.INVALID_NODE_ID then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               condition_first,
               "while loop condition expressions are not supported");
            return;
          end if;
          expect (self, context, Tok_Loop);

        when Tok_Loop =>
          frame.loop_form := Adac.AST.Simple_Loop_Form;
          expect (self, context, Tok_Loop);

        when others =>
          raise Program_Error with
            "loop frame selected an invalid loop-start token";
      end case;
      if not self.failed then
        frames.append (frame);
      end if;
    end push_loop_frame;

    procedure push_case_frame is
      frame : Compound_Frame;
    begin
      if not publish_syntax or else self.current.kind /= Tok_Case then
        raise Program_Error with
          "represented case frame requires a case token";
      end if;

      frame.kind := Case_Frame_Kind;
      parse_current_case_header_common
        (self,
         context,
         frame.first,
         frame.case_selecting_expression);
      if self.failed then
        return;
      end if;
      if self.current.kind /= Tok_When then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "case statement alternatives are not supported");
        return;
      end if;

      frame.case_alternative_first := self.current.position;
      parse_current_case_alternative_header_common
        (self,
         context,
         allow_multiple_choices => True,
         allow_others_choice    => True,
         choices                => frame.case_choices);
      if not self.failed then
        frames.append (frame);
      end if;
    end push_case_frame;

    procedure parse_loop_simple_statement is
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      parse_current_identifier_statement_staging
        (self, context, statement);
      if not self.failed then
        note_statement (statement);
      end if;
    end parse_loop_simple_statement;

    procedure parse_current_exit_statement is
      first : constant Adac.Source.Position := self.current.position;
      when_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
      condition : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      semicolon : Adac.Source.Position := first;
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      expect (self, context, Tok_Exit);
      if self.failed then
        return;
      end if;

      if self.current.kind in Tok_Identifier | Tok_Invalid_Identifier then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "named exit statements are not supported");
        return;
      end if;

      if self.current.kind = Tok_When then
        declare
          position : constant Adac.Source.Position := self.current.position;
          spelling : constant String := current_text (self);
        begin
          when_span := make_token_span (position, spelling);
        end;
        expect (self, context, Tok_When);
        if self.failed then
          return;
        end if;

        parse_expression_staging
          (self,
           context,
           terminator                => Tok_Semicolon,
           terminator_mode           => Require_Exact_Terminator,
           completion_mode           => Return_After_Staging,
           publish_expression_syntax => True,
           syntax_node               => condition);
        if self.failed then
          return;
        end if;
        if condition = Adac.AST.INVALID_NODE_ID then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "exit condition is not represented");
          return;
        end if;
      end if;

      semicolon := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed then
        return;
      end if;

      begin
        statement := Adac.Compilation.Syntax.create_exit_statement
          (context,
           Adac.Symbols.INVALID_SYMBOL_ID,
           Adac.Source.INVALID_SPAN,
           when_span,
           condition,
           Adac.Source.make_span (first, semicolon));
        Adac.Compilation.Syntax.validate_exit_statement (context, statement);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, first, "AST node limit exceeded");
          return;
      end;

      note_statement (statement);
    end parse_current_exit_statement;

    procedure parse_case_simple_statement is
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      case self.current.kind is
        when Tok_Identifier | Tok_Invalid_Identifier =>
          parse_current_identifier_statement_staging
            (self, context, statement);

        when Tok_Raise =>
          parse_current_raise_statement_staging
            (self, context, statement, True);

        when Tok_Null =>
          parse_statement
            (self, context, Return_Statement_Syntax, statement);

        when Tok_Return =>
          if publish_syntax then
            parse_statement
              (self,
               context,
               Return_Statement_Syntax,
               statement,
               allow_return_expression_syntax => True);
            if not self.failed and then
               Adac.Compilation.Syntax.kind_of (context, statement) =
                 Adac.AST.Extended_Return_Statement_Node
            then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 Adac.Source.first_position
                   (Adac.Compilation.Syntax.node_span (context, statement)),
                 "case alternative statement sequences are not supported");
              return;
            end if;
          else
            parse_statement
              (self, context, Return_Statement_Syntax, statement);
          end if;

        when others =>
          raise Program_Error with
            "case simple-statement staging received an invalid token";
      end case;

      if not self.failed then
        note_statement (statement);
      end if;
    end parse_case_simple_statement;

    procedure finalize_case_alternative (frame : in out Compound_Frame) is
      alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if Adac.AST.list_count (frame.case_choices) = 0 or else
         Adac.AST.list_count (frame.case_statements) = 0
      then
        report_case_sequence_unsupported;
        return;
      end if;

      publish_current_case_alternative_common
        (self,
         context,
         frame.case_alternative_first,
         frame.case_choices,
         frame.case_statements,
         alternative);
      if self.failed then
        return;
      end if;
      if alternative = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "compound case frame lost its alternative syntax";
      end if;
      Adac.AST.append (frame.case_alternatives, alternative);
    end finalize_case_alternative;

    procedure start_case_alternative (frame : in out Compound_Frame) is
      empty_choices    : Adac.AST.Node_List;
      empty_statements : Adac.AST.Node_List;
    begin
      finalize_case_alternative (frame);
      if self.failed then
        return;
      end if;

      frame.case_choices := empty_choices;
      frame.case_statements := empty_statements;
      frame.case_alternative_first := self.current.position;
      parse_current_case_alternative_header_common
        (self,
         context,
         allow_multiple_choices => True,
         allow_others_choice    => True,
         choices                => frame.case_choices);
      if not self.failed then
        replace_last_frame (frame);
      end if;
    end start_case_alternative;

    procedure parse_if_simple_statement is
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      case self.current.kind is
        when Tok_Identifier | Tok_Invalid_Identifier =>
          if publish_syntax then
            parse_current_identifier_statement_staging
              (self, context, statement);
          else
            parse_current_procedure_call_statement_staging
              (self,
               context,
               publish_call_syntax => False,
               syntax_node         => statement);
          end if;
        when Tok_Return =>
          if publish_syntax then
            parse_statement
              (self,
               context,
               Return_Statement_Syntax,
               statement,
               allow_return_expression_syntax => True);
            if not self.failed and then
               Adac.Compilation.Syntax.kind_of (context, statement) =
                 Adac.AST.Extended_Return_Statement_Node
            then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 Adac.Source.first_position
                   (Adac.Compilation.Syntax.node_span (context, statement)),
                 "if statement sequences are not supported");
              return;
            end if;
          else
            parse_current_bare_return (statement);
          end if;
        when Tok_Raise =>
          parse_current_raise_statement_staging
            (self, context, statement, publish_syntax);
        when others =>
          raise Program_Error with
            "if simple-statement staging received an invalid token";
      end case;

      if not self.failed then
        note_statement (statement);
      end if;
    end parse_if_simple_statement;

    procedure parse_block_simple_statement is
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      parse_current_identifier_statement_staging
        (self, context, statement);
      if not self.failed then
        note_statement (statement);
      end if;
    end parse_block_simple_statement;

    procedure parse_block_return_statement is
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if publish_syntax then
        parse_statement
          (self,
           context,
           Return_Statement_Syntax,
           statement,
           allow_return_expression_syntax => True);
        if self.failed then
          return;
        end if;

        if Adac.Compilation.Syntax.kind_of (context, statement) =
           Adac.AST.Extended_Return_Statement_Node
        then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             Adac.Source.first_position
               (Adac.Compilation.Syntax.node_span (context, statement)),
             "block statement bodies are not supported");
          return;
        end if;
      else
        parse_current_bare_return (statement);
        if self.failed then
          return;
        end if;
      end if;

      note_statement (statement);
    end parse_block_return_statement;

    procedure finalize_elsif_part (frame : in out Compound_Frame) is
      part : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if frame.active_arm /= Elsif_Arm or else
         not frame.elsif_has_statement
      then
        raise Program_Error with
          "elsif finalization requires a nonempty active elsif arm";
      end if;

      if publish_syntax then
        declare
          last_statement : constant Adac.AST.Node_ID :=
            Adac.AST.list_element
              (frame.elsif_statements,
               Adac.AST.list_count (frame.elsif_statements));
          last_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, last_statement);
        begin
          part := Adac.Compilation.Syntax.create_elsif_part
            (context,
             frame.elsif_condition,
             frame.elsif_statements,
             Adac.Source.make_span
               (frame.elsif_first, Adac.Source.last_position (last_span)));
          Adac.Compilation.Syntax.validate_elsif_part (context, part);
          Adac.AST.append (frame.elsif_parts, part);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, frame.elsif_first, "AST node limit exceeded");
        end;
      end if;
    end finalize_elsif_part;

    procedure start_elsif_arm (frame : in out Compound_Frame) is
      condition_first : Adac.Source.Position := self.current.position;
      empty_statements : Adac.AST.Node_List;
    begin
      if frame.kind /= If_Frame_Kind or else self.current.kind /= Tok_Elsif then
        raise Program_Error with "elsif staging requires an if frame";
      end if;
      if frame.active_arm = Else_Arm or else
         not active_if_arm_has_statement (frame)
      then
        report_sequence_unsupported;
        return;
      end if;
      if completion_mode = Reject_Unsupported_If then
        report_sequence_unsupported;
        return;
      end if;

      if frame.active_arm = Elsif_Arm then
        finalize_elsif_part (frame);
        if self.failed then
          return;
        end if;
      end if;

      frame.elsif_first := self.current.position;
      frame.elsif_condition := Adac.AST.INVALID_NODE_ID;
      frame.elsif_statements := empty_statements;
      frame.elsif_has_statement := False;
      expect (self, context, Tok_Elsif);
      if self.failed then
        return;
      end if;

      condition_first := self.current.position;
      parse_expression_staging
        (self,
         context,
         terminator          => Tok_Then,
         terminator_mode     => Require_Exact_Terminator,
         completion_mode     => Return_After_Staging,
         publish_expression_syntax => publish_syntax,
         syntax_node         => frame.elsif_condition);
      if self.failed then
        return;
      end if;
      if publish_syntax and then
         frame.elsif_condition = Adac.AST.INVALID_NODE_ID
      then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           condition_first,
           "elsif condition expressions are not supported");
        return;
      end if;

      expect (self, context, Tok_Then);
      if not self.failed then
        frame.active_arm := Elsif_Arm;
        replace_last_frame (frame);
      end if;
    end start_elsif_arm;

    procedure close_if_frame (frame : in out Compound_Frame) is
      semicolon : Adac.Source.Position;
      completed : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if not active_if_arm_has_statement (frame) then
        report_sequence_unsupported;
        return;
      end if;
      if frame.active_arm = Elsif_Arm then
        finalize_elsif_part (frame);
        if self.failed then
          return;
        end if;
      end if;

      expect (self, context, Tok_End);
      if self.failed then
        return;
      end if;
      expect (self, context, Tok_If);
      if self.failed then
        return;
      end if;
      semicolon := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed then
        return;
      end if;

      if publish_syntax then
        begin
          completed := Adac.Compilation.Syntax.create_if_statement
            (context,
             frame.condition_node,
             frame.then_statements,
             frame.elsif_parts,
             frame.else_statements,
             Adac.Source.make_span (frame.first, semicolon));
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, frame.first, "AST node limit exceeded");
            return;
        end;
      end if;

      frames.delete_last;
      if frames.is_empty then
        if completion_mode = Reject_Unsupported_If then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, frame.first, "if statements are not supported");
        elsif publish_syntax then
          syntax_node := completed;
          Adac.Compilation.Syntax.validate_if_statement (context, syntax_node);
        end if;
        return;
      end if;

      note_statement (completed);
    end close_if_frame;

    procedure close_block_frame (frame : Compound_Frame) is
      semicolon : Adac.Source.Position;
      completed : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if Adac.AST.list_count (frame.block_statements) = 0 then
        report_block_body_unsupported;
        return;
      end if;

      expect (self, context, Tok_End);
      if self.failed then
        return;
      end if;
      semicolon := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed then
        return;
      end if;

      declare
        first_statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (frame.block_statements, 1);
        last_statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element
            (frame.block_statements,
             Adac.AST.list_count (frame.block_statements));
        first_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, first_statement);
        last_statement_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, last_statement);
        final_span : constant Adac.Source.Span :=
          (if Adac.AST.list_count (frame.block_handlers) = 0 then
             last_statement_span
           else
             Adac.Compilation.Syntax.node_span
               (context,
                Adac.AST.list_element
                  (frame.block_handlers,
                   Adac.AST.list_count (frame.block_handlers))));
        sequence_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.first_position (first_span),
             Adac.Source.last_position (final_span));
      begin
        publish_current_block_staging
          (self,
           context,
           frame.first,
           frame.block_declarations,
           frame.block_statements,
           frame.block_handlers,
           sequence_span,
           semicolon,
           completed);
      end;
      if self.failed then
        return;
      end if;

      frames.delete_last;
      if frames.is_empty then
        syntax_node := completed;
        Adac.Compilation.Syntax.validate_block_statement (context, syntax_node);
        return;
      end if;
      note_statement (completed);
    end close_block_frame;

    procedure close_loop_frame (frame : Compound_Frame) is
      semicolon : Adac.Source.Position := self.current.position;
      completed : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if Adac.AST.list_count (frame.loop_statements) = 0 then
        report_loop_body_unsupported (frame.loop_form);
        return;
      end if;

      parse_current_loop_closing_staging
        (self, context, semicolon);
      if self.failed then
        return;
      end if;

      begin
        case frame.loop_form is
          when Adac.AST.Discrete_Range_Loop_Form =>
            completed :=
              Adac.Compilation.Syntax.create_discrete_range_loop_statement
                (context,
                 frame.loop_parameter_symbol,
                 frame.loop_parameter_span,
                 frame.loop_reverse_present,
                 frame.loop_range_lower_bound,
                 frame.loop_range_upper_bound,
                 frame.loop_statements,
                 Adac.Source.make_span (frame.first, semicolon));
          when Adac.AST.Range_Attribute_Loop_Form =>
            completed :=
              Adac.Compilation.Syntax.create_range_attribute_loop_statement
                (context,
                 frame.loop_parameter_symbol,
                 frame.loop_parameter_span,
                 frame.loop_reverse_present,
                 frame.loop_range_attribute,
                 frame.loop_statements,
                 Adac.Source.make_span (frame.first, semicolon));
          when Adac.AST.Generalized_Iterator_Loop_Form =>
            completed := Adac.Compilation.Syntax.create_loop_statement
              (context,
               frame.loop_parameter_symbol,
               frame.loop_parameter_span,
               frame.loop_reverse_present,
               frame.loop_iterable_name,
               frame.loop_statements,
               Adac.Source.make_span (frame.first, semicolon));
          when Adac.AST.While_Loop_Form =>
            completed := Adac.Compilation.Syntax.create_while_loop_statement
              (context,
               frame.loop_condition,
               frame.loop_statements,
               Adac.Source.make_span (frame.first, semicolon));
          when Adac.AST.Simple_Loop_Form =>
            completed := Adac.Compilation.Syntax.create_simple_loop_statement
              (context,
               frame.loop_statements,
               Adac.Source.make_span (frame.first, semicolon));
        end case;
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, frame.first, "AST node limit exceeded");
          return;
      end;

      frames.delete_last;
      if frames.is_empty then
        syntax_node := completed;
        Adac.Compilation.Syntax.validate_loop_statement (context, syntax_node);
        return;
      end if;
      note_statement (completed);
    end close_loop_frame;

    procedure close_case_frame (frame : in out Compound_Frame) is
      semicolon : Adac.Source.Position := self.current.position;
      completed : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      finalize_case_alternative (frame);
      if self.failed then
        return;
      end if;

      parse_current_case_closing_common
        (self, context, semicolon);
      if self.failed then
        return;
      end if;
      publish_current_case_statement_common
        (self,
         context,
         frame.first,
         frame.case_selecting_expression,
         frame.case_alternatives,
         semicolon,
         completed);
      if self.failed then
        return;
      end if;
      if completed = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "compound case frame lost its statement syntax";
      end if;

      frames.delete_last;
      if frames.is_empty then
        syntax_node := completed;
        Adac.Compilation.Syntax.validate_case_statement (context, syntax_node);
        return;
      end if;
      note_statement (completed);
    end close_case_frame;

  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.current.kind /= root_token then
      raise Program_Error with
        "compound statement staging root token does not match input";
    end if;

    case root_token is
      when Tok_If =>
        push_if_frame;
      when Tok_Declare | Tok_Begin =>
        push_block_frame;
      when Tok_For | Tok_While | Tok_Loop =>
        push_loop_frame;
      when Tok_Case =>
        push_case_frame;
      when others =>
        raise Program_Error with
          "invalid compound statement staging root token";
    end case;
    while not self.failed and then not frames.is_empty loop
      declare
        frame : Compound_Frame := frames.last_element;
      begin
        case frame.kind is
          when If_Frame_Kind =>
            case self.current.kind is
              when Tok_Identifier | Tok_Invalid_Identifier =>
                if completion_mode = Reject_Unsupported_If and then
                   active_if_arm_has_statement (frame)
                then
                  report_sequence_unsupported;
                  return;
                end if;
                parse_if_simple_statement;

              when Tok_Exit =>
                if completion_mode = Reject_Unsupported_If then
                  report_sequence_unsupported;
                  return;
                end if;
                parse_current_exit_statement;

              when Tok_Return | Tok_Raise =>
                if completion_mode = Reject_Unsupported_If then
                  report_sequence_unsupported;
                  return;
                end if;
                parse_if_simple_statement;

              when Tok_If =>
                if completion_mode = Reject_Unsupported_If then
                  report_sequence_unsupported;
                  return;
                end if;
                push_if_frame;

              when Tok_Declare | Tok_Begin =>
                if completion_mode = Reject_Unsupported_If then
                  report_sequence_unsupported;
                  return;
                end if;
                push_block_frame;

              when Tok_For | Tok_While | Tok_Loop =>
                if completion_mode = Reject_Unsupported_If then
                  report_sequence_unsupported;
                  return;
                end if;
                push_loop_frame;

              when Tok_Case =>
                if completion_mode = Reject_Unsupported_If then
                  report_sequence_unsupported;
                  return;
                end if;
                push_case_frame;

              when Tok_Elsif =>
                start_elsif_arm (frame);

              when Tok_Else =>
                if frame.active_arm = Else_Arm or else
                   not active_if_arm_has_statement (frame)
                then
                  report_sequence_unsupported;
                  return;
                end if;
                if frame.active_arm = Elsif_Arm then
                  finalize_elsif_part (frame);
                  if self.failed then
                    return;
                  end if;
                end if;
                expect (self, context, Tok_Else);
                if self.failed then
                  return;
                end if;
                frame.active_arm := Else_Arm;
                replace_last_frame (frame);

              when Tok_End =>
                close_if_frame (frame);

              when others =>
                report_sequence_unsupported;
                return;
            end case;

          when Block_Frame_Kind =>
            case self.current.kind is
              when Tok_Identifier | Tok_Invalid_Identifier =>
                parse_block_simple_statement;
              when Tok_Return =>
                parse_block_return_statement;
              when Tok_Exit =>
                parse_current_exit_statement;
              when Tok_If =>
                push_if_frame;
              when Tok_Declare | Tok_Begin =>
                push_block_frame;
              when Tok_For | Tok_While | Tok_Loop =>
                push_loop_frame;
              when Tok_Case =>
                push_case_frame;
              when Tok_Exception =>
                if Adac.AST.list_count (frame.block_statements) = 0 then
                  report_block_body_unsupported;
                  return;
                end if;
                if Adac.AST.list_count (frame.block_handlers) /= 0 then
                  report_sequence_unsupported;
                  return;
                end if;
                parse_exception_handlers_staging
                  (self,
                   context,
                   terminator             => Tok_End,
                   completion_mode        => Return_After_Handler_Staging,
                   publish_handler_syntax => publish_syntax,
                   handlers               => frame.block_handlers);
                if self.failed then
                  return;
                end if;
                replace_last_frame (frame);
              when Tok_End =>
                close_block_frame (frame);
              when others =>
                if Adac.AST.list_count (frame.block_statements) = 0 then
                  report_block_body_unsupported;
                else
                  expect (self, context, Tok_End);
                end if;
                return;
            end case;

          when Loop_Frame_Kind =>
            case self.current.kind is
              when Tok_Identifier | Tok_Invalid_Identifier =>
                parse_loop_simple_statement;
              when Tok_Exit =>
                parse_current_exit_statement;
              when Tok_If =>
                push_if_frame;
              when Tok_Case =>
                push_case_frame;
              when Tok_Declare =>
                push_block_frame;
              when Tok_End =>
                close_loop_frame (frame);
              when others =>
                report_loop_body_unsupported (frame.loop_form);
                return;
            end case;

          when Case_Frame_Kind =>
            case self.current.kind is
              when Tok_Identifier | Tok_Invalid_Identifier |
                   Tok_Raise | Tok_Null | Tok_Return =>
                parse_case_simple_statement;
              when Tok_Exit =>
                parse_current_exit_statement;
              when Tok_If =>
                push_if_frame;
              when Tok_Case =>
                push_case_frame;
              when Tok_Declare =>
                push_block_frame;
              when Tok_For | Tok_While | Tok_Loop =>
                push_loop_frame;
              when Tok_When =>
                start_case_alternative (frame);
              when Tok_End =>
                close_case_frame (frame);
              when others =>
                report_case_sequence_unsupported;
                return;
            end case;
        end case;
      end;
    end loop;
  end parse_compound_statement_staging;

  procedure parse_if_statement_staging
    (self            : in out Parser;
     context         : in out Adac.Compilation.Context;
     completion_mode : If_Staging_Completion_Mode;
     syntax_node     : out Adac.AST.Node_ID)
  is
  begin
    parse_compound_statement_staging
      (self, context, Tok_If, completion_mode, syntax_node);
  end parse_if_statement_staging;

  procedure parse_if_statement_staging
    (self            : in out Parser;
     context         : in out Adac.Compilation.Context;
     completion_mode : If_Staging_Completion_Mode)
  is
    ignored_statement : Adac.AST.Node_ID;
  begin
    parse_if_statement_staging
      (self, context, completion_mode, ignored_statement);
  end parse_if_statement_staging;

  function starts_statement (kind : Token_Kind) return Boolean is
  begin
    case kind is
      when Tok_Null | Tok_Return | Tok_If =>
        return True;

      when others =>
        return False;
    end case;
  end starts_statement;

  procedure parse_statement
    (self                           : in out Parser;
     context                        : in out Adac.Compilation.Context;
     publication_mode               : Statement_Publication_Mode;
     syntax_node                    : out Adac.AST.Node_ID;
     allow_return_expression_syntax : Boolean := False)
  is
    first          : constant Adac.Source.Position := self.current.position;
    last           : Adac.Source.Position;
    statement_kind : Adac.AST.Node_Kind := Adac.AST.Null_Statement_Node;
    ignored_name   : Adac.AST.Node_ID;
    return_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;

    procedure parse_extended_return_statement is
      defining_position : constant Adac.Source.Position :=
        self.current.position;
      defining_spelling : constant String := current_text (self);
      defining_symbol   : Adac.Symbols.Symbol_ID :=
        Adac.Symbols.INVALID_SYMBOL_ID;
      subtype_mark : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      first_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      last_statement  : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      statements   : Adac.AST.Node_List;
      handlers     : Adac.AST.Node_List;
      sequence     : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      closing      : Adac.Source.Position := defining_position;
    begin
      defining_symbol := parse_identifier_symbol (self, context);
      if self.failed then
        return;
      end if;

      expect (self, context, Tok_Colon);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Aliased then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "aliased extended returns are not supported");
        return;
      end if;

      if self.current.kind = Tok_Constant then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "constant extended returns are not supported");
        return;
      end if;

      parse_selected_identifier_name_staging
        (self,
         context,
         publish_syntax => True,
         syntax_node    => subtype_mark);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Assign then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "extended return initializers are not supported");
        return;
      end if;

      expect (self, context, Tok_Do);
      if self.failed then
        return;
      end if;

      while not self.failed and then self.current.kind /= Tok_End loop
        declare
          statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        begin
          case self.current.kind is
            when Tok_Identifier | Tok_Invalid_Identifier =>
              parse_current_identifier_statement_staging
                (self, context, statement);

            when Tok_Null =>
              declare
                null_first : constant Adac.Source.Position :=
                  self.current.position;
                null_last : Adac.Source.Position := null_first;
              begin
                expect (self, context, Tok_Null);
                if self.failed then
                  return;
                end if;
                null_last := self.current.position;
                expect (self, context, Tok_Semicolon);
                if self.failed then
                  return;
                end if;
                begin
                  statement := Adac.Compilation.Syntax.create_statement
                    (context,
                     Adac.AST.Null_Statement_Node,
                     Adac.Source.make_span (null_first, null_last));
                exception
                  when Adac.Resources.Limit_Exceeded =>
                    self.failed := True;
                    Adac.Compilation.Diagnostics.error
                      (context, null_first, "AST node limit exceeded");
                    return;
                end;
              end;

            when others =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "extended return statements are not supported");
              return;
          end case;

          if self.failed then
            return;
          end if;
          if statement = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "extended return lost represented statement syntax";
          end if;

          if first_statement = Adac.AST.INVALID_NODE_ID then
            first_statement := statement;
          end if;
          last_statement := statement;
          Adac.AST.append (statements, statement);
        end;
      end loop;

      if first_statement = Adac.AST.INVALID_NODE_ID then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context, self.current.position, "extended return body is empty");
        return;
      end if;

      begin
        declare
          first_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, first_statement);
          last_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, last_statement);
        begin
          sequence := Adac.Compilation.Syntax.create_handled_sequence
            (context,
             statements,
             handlers,
             Adac.Source.make_span
               (Adac.Source.first_position (first_span),
                Adac.Source.last_position (last_span)));
        end;
        Adac.Compilation.Syntax.validate_handled_sequence (context, sequence);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, defining_position, "AST node limit exceeded");
          return;
      end;

      expect (self, context, Tok_End);
      if self.failed then
        return;
      end if;
      expect (self, context, Tok_Return);
      if self.failed then
        return;
      end if;
      closing := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed then
        return;
      end if;

      begin
        syntax_node := Adac.Compilation.Syntax.create_extended_return_statement
          (context,
           defining_symbol,
           make_token_span (defining_position, defining_spelling),
           subtype_mark,
           sequence,
           Adac.Source.make_span (first, closing));
        Adac.Compilation.Syntax.validate_extended_return_statement
          (context, syntax_node);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          syntax_node := Adac.AST.INVALID_NODE_ID;
          Adac.Compilation.Diagnostics.error
            (context, first, "AST node limit exceeded");
      end;
    end parse_extended_return_statement;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    case self.current.kind is
      when Tok_Null =>
        statement_kind := Adac.AST.Null_Statement_Node;
        expect (self, context, Tok_Null);

      when Tok_If =>
        parse_if_statement_staging
          (self, context, Reject_Unsupported_If);
        return;

      when Tok_Return =>
        statement_kind := Adac.AST.Return_Statement_Node;
        expect (self, context, Tok_Return);
        if not self.failed and then
           self.current.kind = Tok_Identifier and then
           peek_token_kind (self, context) = Tok_Colon
        then
          parse_extended_return_statement;
          if not self.failed and then
             publication_mode = Publish_Statement_Syntax
          then
            Adac.AST.append (self.statements, syntax_node);
          end if;
          return;
        end if;

        if not self.failed and then
           starts_expression_staging (self.current.kind)
        then
          if publication_mode = Skip_Statement_Publication or else
             not allow_return_expression_syntax
          then
            parse_expression_staging
              (self, context, terminator => Tok_Semicolon,
               terminator_mode => Require_Exact_Terminator,
               completion_mode => Reject_Unsupported_Expression,
               publish_expression_syntax => False,
               syntax_node => ignored_name);
            return;
          end if;

          parse_expression_staging
            (self, context, terminator => Tok_Semicolon,
             terminator_mode => Require_Exact_Terminator,
             completion_mode => Return_After_Staging,
             publish_expression_syntax => True,
             syntax_node => return_expression);
          if self.failed then
            return;
          end if;
          if return_expression = Adac.AST.INVALID_NODE_ID then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, self.current.position,
               "return expression is not represented");
            return;
          end if;
        end if;

      when Tok_Identifier | Tok_Invalid_Identifier =>
        parse_current_assignment_statement_staging
          (self, context, syntax_node);
        if not self.failed and then
           publication_mode = Publish_Statement_Syntax
        then
          Adac.AST.append (self.statements, syntax_node);
        end if;
        return;

      when others =>
        report_expected (self, context, Tok_Null);
        return;
    end case;

    if self.failed then
      return;
    end if;
    last := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed or else publication_mode = Skip_Statement_Publication then
      return;
    end if;

    begin
      if statement_kind = Adac.AST.Return_Statement_Node and then
         return_expression /= Adac.AST.INVALID_NODE_ID
      then
        syntax_node := Adac.Compilation.Syntax.create_return_statement
          (context,
           return_expression,
           Adac.Source.make_span (first, last));
        Adac.Compilation.Syntax.validate_return_statement
          (context, syntax_node);
      else
        syntax_node := Adac.Compilation.Syntax.create_statement
          (context, statement_kind, Adac.Source.make_span (first, last));
      end if;
      if publication_mode = Publish_Statement_Syntax then
        Adac.AST.append (self.statements, syntax_node);
      end if;
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        syntax_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_statement;

  procedure parse_statement
    (self             : in out Parser;
     context          : in out Adac.Compilation.Context;
     publication_mode : Statement_Publication_Mode)
  is
    ignored_statement : Adac.AST.Node_ID;
  begin
    parse_statement
      (self, context, publication_mode, ignored_statement);
  end parse_statement;

  procedure parse_current_case_header_common
    (self                 : in out Parser;
     context              : in out Adac.Compilation.Context;
     case_first           : out Adac.Source.Position;
     selecting_expression : out Adac.AST.Node_ID)
  is
  begin
    case_first := self.current.position;
    selecting_expression := Adac.AST.INVALID_NODE_ID;
    if self.current.kind /= Tok_Case then
      raise Program_Error with
        "case header staging requires a case token";
    end if;

    expect (self, context, Tok_Case);
    if self.failed then
      return;
    end if;

    declare
      selecting_first : constant Adac.Source.Position := self.current.position;
    begin
      parse_expression_staging
        (self,
         context,
         terminator          => Tok_Is,
         terminator_mode     => Require_Exact_Terminator,
         completion_mode     => Return_After_Staging,
         publish_expression_syntax => True,
         syntax_node         => selecting_expression);
      if self.failed then
        return;
      end if;
      if selecting_expression = Adac.AST.INVALID_NODE_ID then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           selecting_first,
           "case selecting expressions are not supported");
        return;
      end if;
    end;

    expect (self, context, Tok_Is);
  end parse_current_case_header_common;

  procedure parse_current_case_alternative_header_common
    (self                   : in out Parser;
     context                : in out Adac.Compilation.Context;
     allow_multiple_choices : Boolean;
     allow_others_choice    : Boolean;
     choices                : in out Adac.AST.Node_List)
  is
    procedure report_choice_unsupported is
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "case alternative choices are not supported");
    end report_choice_unsupported;

    procedure parse_name_choice is
      choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if self.current.kind /= Tok_Identifier and then
         self.current.kind /= Tok_Invalid_Identifier
      then
        report_choice_unsupported;
        return;
      end if;

      parse_selected_identifier_name_staging
        (self,
         context,
         publish_syntax => True,
         syntax_node    => choice);
      if self.failed then
        return;
      end if;
      if choice = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with "case alternative lost its choice syntax";
      end if;
      if Adac.Compilation.Syntax.kind_of (context, choice) /=
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, choice) /=
           Adac.AST.Selected_Name_Node
      then
        report_choice_unsupported;
        return;
      end if;
      Adac.AST.append (choices, choice);
    end parse_name_choice;

    procedure parse_integer_choice is
      position : constant Adac.Source.Position := self.current.position;
      spelling : constant String := current_text (self);
      form : Adac.AST.Numeric_Literal_Kind;
      choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      case self.current.kind is
        when Tok_Decimal_Integer_Literal =>
          form := Adac.AST.Decimal_Integer_Form;
        when Tok_Based_Integer_Literal =>
          form := Adac.AST.Based_Integer_Form;
        when others =>
          report_choice_unsupported;
          return;
      end case;

      begin
        choice := Adac.Compilation.Syntax.create_numeric_literal
          (context,
           form,
           spelling,
           make_token_span (position, spelling));
        Adac.Compilation.Syntax.validate_numeric_literal (context, choice);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, position, "AST node limit exceeded");
          return;
      end;
      advance (self, context);
      if not self.failed then
        Adac.AST.append (choices, choice);
      end if;
    end parse_integer_choice;

    procedure parse_character_choice is
      lower_position : constant Adac.Source.Position := self.current.position;
      lower_spelling : constant String := current_text (self);
      lower : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if self.current.kind /= Tok_Character_Literal then
        report_choice_unsupported;
        return;
      end if;

      begin
        lower := Adac.Compilation.Syntax.create_character_literal
          (context,
           lower_spelling,
           make_token_span (lower_position, lower_spelling));
        Adac.Compilation.Syntax.validate_character_literal (context, lower);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, lower_position, "AST node limit exceeded");
          return;
      end;
      advance (self, context);
      if self.failed then
        return;
      end if;

      if self.current.kind /= Tok_Double_Dot then
        Adac.AST.append (choices, lower);
        return;
      end if;

      declare
        range_position : constant Adac.Source.Position := self.current.position;
        range_spelling : constant String := current_text (self);
        range_span : constant Adac.Source.Span :=
          make_token_span (range_position, range_spelling);
      begin
        expect (self, context, Tok_Double_Dot);
        if self.failed then
          return;
        end if;
        if self.current.kind /= Tok_Character_Literal then
          report_choice_unsupported;
          return;
        end if;

        declare
          upper_position : constant Adac.Source.Position :=
            self.current.position;
          upper_spelling : constant String := current_text (self);
          upper_span : constant Adac.Source.Span :=
            make_token_span (upper_position, upper_spelling);
          upper : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        begin
          begin
            upper := Adac.Compilation.Syntax.create_character_literal
              (context, upper_spelling, upper_span);
            Adac.Compilation.Syntax.validate_character_literal (context, upper);
            choice := Adac.Compilation.Syntax.create_case_range_choice
              (context,
               lower,
               range_span,
               upper,
               Adac.Source.make_span
                 (lower_position, Adac.Source.last_position (upper_span)));
            Adac.Compilation.Syntax.validate_case_range_choice
              (context, choice);
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, upper_position, "AST node limit exceeded");
              return;
          end;

          advance (self, context);
          if not self.failed then
            Adac.AST.append (choices, choice);
          end if;
        end;
      end;
    end parse_character_choice;

    procedure parse_current_choice is
    begin
      case self.current.kind is
        when Tok_Identifier | Tok_Invalid_Identifier =>
          parse_name_choice;
        when Tok_Decimal_Integer_Literal | Tok_Based_Integer_Literal =>
          parse_integer_choice;
        when Tok_Character_Literal =>
          parse_character_choice;
        when others =>
          report_choice_unsupported;
      end case;
    end parse_current_choice;
  begin
    if self.current.kind /= Tok_When then
      report_expected (self, context, Tok_When);
      return;
    end if;
    expect (self, context, Tok_When);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Others then
      declare
        others_position : constant Adac.Source.Position :=
          self.current.position;
        others_span : constant Adac.Source.Span :=
          make_token_span (self.current.position, current_text (self));
        choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        if not allow_others_choice then
          report_choice_unsupported;
          return;
        end if;
        expect (self, context, Tok_Others);
        if self.failed then
          return;
        end if;
        begin
          choice := Adac.Compilation.Syntax.create_others_case_choice
            (context, others_span);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, others_position, "AST node limit exceeded");
            return;
        end;
        Adac.AST.append (choices, choice);
        if self.current.kind = Tok_Vertical_Bar then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "case alternative others choice must be sole");
          return;
        end if;
      end;
    else
      parse_current_choice;
      if self.failed then
        return;
      end if;

      while self.current.kind = Tok_Vertical_Bar loop
        if not allow_multiple_choices then
          report_choice_unsupported;
          return;
        end if;
        expect (self, context, Tok_Vertical_Bar);
        if self.failed then
          return;
        end if;
        if self.current.kind = Tok_Others then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "case alternative others choice must be sole");
          return;
        end if;
        parse_current_choice;
        if self.failed then
          return;
        end if;
      end loop;
    end if;

    expect (self, context, Tok_Arrow);
  end parse_current_case_alternative_header_common;

  procedure parse_current_block_statement_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID);

  procedure parse_current_explicit_block_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID);

  procedure parse_current_case_statement_sequence_common
    (self                       : in out Parser;
     context                    : in out Adac.Compilation.Context;
     exact_terminator           : Token_Kind;
     stop_at_alternative_or_end : Boolean;
     current_statement_subset   : Boolean;
     statements                 : in out Adac.AST.Node_List)
  is
    function at_end return Boolean is
    begin
      if stop_at_alternative_or_end then
        return self.current.kind = Tok_When or else
          self.current.kind = Tok_End;
      end if;
      return self.current.kind = exact_terminator;
    end at_end;
  begin
    while not self.failed and then not at_end loop
      declare
        statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        case self.current.kind is
          when Tok_Identifier | Tok_Invalid_Identifier =>
            if current_statement_subset then
              parse_current_identifier_statement_staging
                (self, context, statement);
            else
              parse_current_procedure_call_statement_staging
                (self,
                 context,
                 publish_call_syntax => True,
                 syntax_node         => statement);
            end if;

          when Tok_Raise =>
            if not current_statement_subset then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "case alternative statement sequences are not supported");
            else
              parse_current_raise_statement_staging
                (self, context, statement, True);
            end if;

          when Tok_If =>
            if current_statement_subset then
              parse_if_statement_staging
                (self, context, Return_After_If_Staging, statement);
            else
              parse_statement
                (self, context, Return_Statement_Syntax, statement);
            end if;

          when Tok_Declare =>
            if current_statement_subset then
              parse_current_explicit_block_staging
                (self, context, statement);
            else
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "case alternative statement sequences are not supported");
            end if;

          when Tok_Case =>
            if current_statement_subset then
              parse_compound_statement_staging
                (self,
                 context,
                 root_token      => Tok_Case,
                 completion_mode => Return_After_If_Staging,
                 syntax_node     => statement);
            else
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "case alternative statement sequences are not supported");
            end if;

          when Tok_For | Tok_While | Tok_Loop =>
            if current_statement_subset then
              parse_compound_statement_staging
                (self,
                 context,
                 root_token      => self.current.kind,
                 completion_mode => Return_After_If_Staging,
                 syntax_node     => statement);
            else
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "case alternative statement sequences are not supported");
            end if;

          when Tok_Null =>
            parse_statement
              (self, context, Return_Statement_Syntax, statement);

          when Tok_Return =>
            parse_statement
              (self,
               context,
               Return_Statement_Syntax,
               statement,
               allow_return_expression_syntax => current_statement_subset);

          when others =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "case alternative statement sequences are not supported");
        end case;

        if not self.failed then
          if statement = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "case alternative lost its statement syntax";
          end if;
          Adac.AST.append (statements, statement);
        end if;
      end;
    end loop;

    if self.failed then
      return;
    end if;
    if Adac.AST.list_count (statements) = 0 then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "case alternative statement sequences are not supported");
    end if;
  end parse_current_case_statement_sequence_common;

  procedure parse_current_case_closing_common
    (self      : in out Parser;
     context   : in out Adac.Compilation.Context;
     semicolon : out Adac.Source.Position)
  is
  begin
    semicolon := self.current.position;
    expect (self, context, Tok_End);
    if self.failed then
      return;
    end if;
    expect (self, context, Tok_Case);
    if self.failed then
      return;
    end if;
    semicolon := self.current.position;
    expect (self, context, Tok_Semicolon);
  end parse_current_case_closing_common;

  procedure publish_current_case_alternative_common
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     first       : Adac.Source.Position;
     choices     : Adac.AST.Node_List;
     statements  : Adac.AST.Node_List;
     alternative : out Adac.AST.Node_ID)
  is
  begin
    alternative := Adac.AST.INVALID_NODE_ID;
    if Adac.AST.list_count (statements) = 0 then
      raise Program_Error with "case alternative lost its statements";
    end if;
    declare
      last_statement : constant Adac.AST.Node_ID :=
        Adac.AST.list_element
          (statements, Adac.AST.list_count (statements));
      last_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, last_statement);
    begin
      alternative := Adac.Compilation.Syntax.create_case_alternative
        (context,
         choices,
         statements,
         Adac.Source.make_span
           (first, Adac.Source.last_position (last_span)));
      Adac.Compilation.Syntax.validate_case_alternative
        (context, alternative);
    end;
  exception
    when Adac.Resources.Limit_Exceeded =>
      self.failed := True;
      alternative := Adac.AST.INVALID_NODE_ID;
      Adac.Compilation.Diagnostics.error
        (context, first, "AST node limit exceeded");
  end publish_current_case_alternative_common;

  procedure publish_current_case_statement_common
    (self                 : in out Parser;
     context              : in out Adac.Compilation.Context;
     first                : Adac.Source.Position;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     semicolon            : Adac.Source.Position;
     statement            : out Adac.AST.Node_ID)
  is
  begin
    begin
      statement := Adac.Compilation.Syntax.create_case_statement
        (context,
         selecting_expression,
         alternatives,
         Adac.Source.make_span (first, semicolon));
      Adac.Compilation.Syntax.validate_case_statement
        (context, statement);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        statement := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end publish_current_case_statement_common;

  procedure parse_current_case_statement_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID)
  is
    case_first : Adac.Source.Position := self.current.position;
    selecting_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    alternatives : Adac.AST.Node_List;
    case_semicolon : Adac.Source.Position := self.current.position;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    parse_current_case_header_common
      (self, context, case_first, selecting_expression);
    if self.failed then
      return;
    end if;

    if self.current.kind /= Tok_When then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "case statement alternatives are not supported");
      return;
    end if;

    while not self.failed and then self.current.kind = Tok_When loop
      declare
        alternative_first : constant Adac.Source.Position :=
          self.current.position;
        choices : Adac.AST.Node_List;
        statements : Adac.AST.Node_List;
        alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        parse_current_case_alternative_header_common
          (self,
           context,
           allow_multiple_choices => True,
           allow_others_choice    => True,
           choices                => choices);
        if self.failed then
          return;
        end if;

        parse_current_case_statement_sequence_common
          (self,
           context,
           exact_terminator           => Tok_End,
           stop_at_alternative_or_end => True,
           current_statement_subset   => True,
           statements                 => statements);
        if self.failed then
          return;
        end if;

        publish_current_case_alternative_common
          (self,
           context,
           alternative_first,
           choices,
           statements,
           alternative);
        if self.failed then
          return;
        end if;
        if alternative = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "case statement lost its alternative syntax";
        end if;
        Adac.AST.append (alternatives, alternative);
      end;
    end loop;

    parse_current_case_closing_common
      (self, context, case_semicolon);
    if self.failed then
      return;
    end if;
    publish_current_case_statement_common
      (self,
       context,
       case_first,
       selecting_expression,
       alternatives,
       case_semicolon,
       syntax_node);
  end parse_current_case_statement_staging;

  procedure parse_statement_sequence
    (self                : in out Parser;
     context             : in out Adac.Compilation.Context;
     had_recovered_error : out Boolean)
  is
    procedure recover_misplaced_use_clause is
    begin
      had_recovered_error := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "declarative item is not allowed in statement sequence");

      while not self.failed and then
        self.current.kind /= Tok_Semicolon and then
        self.current.kind /= Tok_End and then
        self.current.kind /= Tok_Exception and then
        self.current.kind /= Tok_EOF
      loop
        advance (self, context);
      end loop;

      if not self.failed and then self.current.kind = Tok_Semicolon then
        advance (self, context);
      elsif not self.failed and then self.current.kind = Tok_EOF then
        self.failed := True;
      end if;
    end recover_misplaced_use_clause;
  begin
    had_recovered_error := False;
    if self.failed then
      return;
    end if;

    if not starts_statement (self.current.kind) and then
       self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier and then
       self.current.kind /= Tok_Use
    then
      report_expected (self, context, Tok_Null);
      return;
    end if;

    while not self.failed and then
      (starts_statement (self.current.kind) or else
       self.current.kind = Tok_Identifier or else
       self.current.kind = Tok_Invalid_Identifier or else
       self.current.kind = Tok_Use)
    loop
      if self.current.kind = Tok_Use then
        recover_misplaced_use_clause;
      else
        parse_statement (self, context, Publish_Statement_Syntax);
      end if;
    end loop;
  end parse_statement_sequence;

  procedure parse_exception_handlers_staging
    (self                   : in out Parser;
     context                : in out Adac.Compilation.Context;
     terminator             : Token_Kind;
     completion_mode        : Exception_Handler_Staging_Completion_Mode;
     publish_handler_syntax : Boolean;
     handlers               : in out Adac.AST.Node_List)
  is separate;

  procedure parse_exception_handlers_staging
    (self            : in out Parser;
     context         : in out Adac.Compilation.Context;
     terminator      : Token_Kind;
     completion_mode : Exception_Handler_Staging_Completion_Mode)
  is
    ignored_handlers : Adac.AST.Node_List;
  begin
    parse_exception_handlers_staging
      (self,
       context,
       terminator,
       completion_mode,
       publish_handler_syntax => False,
       handlers               => ignored_handlers);
  end parse_exception_handlers_staging;

  procedure parse_context_clause
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is
    procedure report_ast_node_limit (position : Adac.Source.Position) is
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, position, "AST node limit exceeded");
    end report_ast_node_limit;

    procedure parse_library_unit_name (names : in out Adac.AST.Node_List) is
      name : Adac.AST.Node_ID;
    begin
      parse_selected_identifier_name_staging
        (self, context, publish_syntax => True, syntax_node => name);

      if not self.failed then
        Adac.AST.append (names, name);
      end if;
    end parse_library_unit_name;

    procedure parse_with_clause is
      first : constant Adac.Source.Position := self.current.position;
      last  : Adac.Source.Position;
      names : Adac.AST.Node_List;
    begin
      expect (self, context, Tok_With);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Semicolon then
        self.had_recovered_context_error := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "with clause requires a library unit name");
        advance (self, context);
        return;
      end if;

      parse_library_unit_name (names);

      while not self.failed and then self.current.kind = Tok_Comma loop
        expect (self, context, Tok_Comma);
        parse_library_unit_name (names);
      end loop;

      if self.failed then
        return;
      end if;

      last := self.current.position;
      expect (self, context, Tok_Semicolon);

      if self.failed then
        return;
      end if;

      begin
        Adac.AST.append
          (self.context_items,
           Adac.Compilation.Syntax.create_with_clause
             (context, names, Adac.Source.make_span (first, last)));
      exception
        when Adac.Resources.Limit_Exceeded =>
          report_ast_node_limit (first);
      end;
    end parse_with_clause;

  begin
    if self.current.kind /= Tok_With then
      raise Program_Error with
        "context-clause parsing requires a with token";
    end if;

    while not self.failed and then self.current.kind = Tok_With loop
      parse_with_clause;
    end loop;
  end parse_context_clause;

  procedure parse_current_declaration_staging
    (self                       : in out Parser;
     context                    : in out Adac.Compilation.Context;
     declaration                : out Adac.AST.Node_ID;
     represent_object           : Boolean := True;
     represent_number           : Boolean := False;
     allow_deferred_constant    : Boolean := False;
     publish_syntax             : Boolean := True)
  is
    first : constant Adac.Source.Position := self.current.position;

    procedure report_unsupported (message : String) is
    begin
      self.failed := True;
      declaration := Adac.AST.INVALID_NODE_ID;
      Adac.Compilation.Diagnostics.error (context, first, message);
    end report_unsupported;

    procedure report_ast_node_limit is
    begin
      self.failed := True;
      declaration := Adac.AST.INVALID_NODE_ID;
      Adac.Compilation.Diagnostics.error
        (context, first, "AST node limit exceeded");
    end report_ast_node_limit;

  begin
    declaration := Adac.AST.INVALID_NODE_ID;

    if self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier
    then
      raise Program_Error with
        "object declaration staging requires an identifier token";
    end if;

    declare
      defining_spelling : constant String := current_text (self);
      defining_span : constant Adac.Source.Span :=
        make_token_span (first, defining_spelling);
      defining_symbol : Adac.Symbols.Symbol_ID :=
        Adac.Symbols.INVALID_SYMBOL_ID;
      object_form : Adac.AST.Object_Declaration_Form :=
        Adac.AST.Variable_Object_Form;
      subtype_mark : Adac.AST.Node_ID;
      index_constraint : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      renamed_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      initializer  : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      last         : Adac.Source.Position;
    begin
      parse_unpublished_identifier (self, context);

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Comma then
        report_unsupported
          ("declarations with multiple defining identifiers are not supported");
        return;
      end if;

      expect (self, context, Tok_Colon);

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Exception then
        if publish_syntax then
          begin
            defining_symbol :=
              Adac.Compilation.Symbols.intern (context, defining_spelling);
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, first, "symbol limit exceeded");
              return;
          end;
        end if;

        expect (self, context, Tok_Exception);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Semicolon then
          last := self.current.position;
        end if;
        expect (self, context, Tok_Semicolon);
        if self.failed or else not publish_syntax then
          return;
        end if;

        begin
          declaration :=
            Adac.Compilation.Syntax.create_exception_declaration
              (context,
               defining_symbol,
               defining_span,
               Adac.Source.make_span (first, last));
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit;
            return;
        end;

        Adac.Compilation.Syntax.validate_exception_declaration
          (context, declaration);
        return;
      end if;

      if self.current.kind = Tok_Constant then
        object_form := Adac.AST.Constant_Object_Form;
        expect (self, context, Tok_Constant);

        if self.failed then
          return;
        end if;
      end if;

      if object_form = Adac.AST.Constant_Object_Form and then
         self.current.kind = Tok_Assign
      then
        if not represent_number then
          report_unsupported ("number declarations are not supported");
          return;
        end if;

        if publish_syntax then
          begin
            defining_symbol :=
              Adac.Compilation.Symbols.intern (context, defining_spelling);
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, first, "symbol limit exceeded");
              return;
          end;
        end if;

        expect (self, context, Tok_Assign);

        if self.failed then
          return;
        end if;

        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Semicolon,
           terminator_mode     => Require_Exact_Terminator,
           completion_mode     => Return_After_Staging,
           publish_expression_syntax => publish_syntax,
           syntax_node         => initializer);

        if self.failed then
          return;
        end if;

        if publish_syntax and then initializer = Adac.AST.INVALID_NODE_ID then
          report_unsupported
            ("number declaration expressions are not supported");
          return;
        end if;

        last := self.current.position;
        expect (self, context, Tok_Semicolon);

        if self.failed or else not publish_syntax then
          return;
        end if;

        begin
          declaration := Adac.Compilation.Syntax.create_number_declaration
            (context,
             defining_symbol,
             defining_span,
             initializer,
             Adac.Source.make_span (first, last));
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit;
            return;
        end;

        Adac.Compilation.Syntax.validate_declaration (context, declaration);
        return;
      end if;

      if self.current.kind /= Tok_Identifier and then
         self.current.kind /= Tok_Invalid_Identifier
      then
        report_unsupported ("object declarations are not supported");
        return;
      end if;

      if not represent_object then
        report_unsupported ("package visible declarations are not supported");
        return;
      end if;

      if publish_syntax then
        begin
          defining_symbol :=
            Adac.Compilation.Symbols.intern (context, defining_spelling);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, first, "symbol limit exceeded");
            return;
        end;
      end if;

      parse_selected_identifier_name_staging
        (self,
         context,
         publish_syntax => publish_syntax,
         syntax_node    => subtype_mark);

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Left_Parenthesis then
        declare
          constraint_first : constant Adac.Source.Position :=
            self.current.position;
          lower_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          upper_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          range_span  : Adac.Source.Span := Adac.Source.INVALID_SPAN;
          constraint_last : Adac.Source.Position := self.current.position;
        begin
          expect (self, context, Tok_Left_Parenthesis);
          if self.failed then
            return;
          end if;

          parse_expression_staging
            (self,
             context,
             terminator          => Tok_Double_Dot,
             terminator_mode     => Require_Exact_Terminator,
             completion_mode     => Return_After_Staging,
             publish_expression_syntax => publish_syntax,
             syntax_node         => lower_bound,
             grammar_level       => Simple_Expression_Level);
          if self.failed then
            return;
          end if;
          if publish_syntax and then lower_bound = Adac.AST.INVALID_NODE_ID then
            report_unsupported
              ("object index-constraint lower bounds are not supported");
            return;
          end if;

          range_span :=
            make_token_span (self.current.position, current_text (self));
          expect (self, context, Tok_Double_Dot);
          if self.failed then
            return;
          end if;

          parse_expression_staging
            (self,
             context,
             terminator          => Tok_Right_Parenthesis,
             terminator_mode     => Require_Exact_Terminator,
             completion_mode     => Return_After_Staging,
             publish_expression_syntax => publish_syntax,
             syntax_node         => upper_bound,
             grammar_level       => Simple_Expression_Level);
          if self.failed then
            return;
          end if;
          if publish_syntax and then upper_bound = Adac.AST.INVALID_NODE_ID then
            report_unsupported
              ("object index-constraint upper bounds are not supported");
            return;
          end if;

          constraint_last := self.current.position;
          expect (self, context, Tok_Right_Parenthesis);
          if self.failed then
            return;
          end if;

          if publish_syntax then
            begin
              index_constraint :=
                Adac.Compilation.Syntax.create_index_constraint
                  (context,
                   lower_bound,
                   range_span,
                   upper_bound,
                   Adac.Source.make_span
                     (constraint_first, constraint_last));
              Adac.Compilation.Syntax.validate_index_constraint
                (context, index_constraint);
            exception
              when Adac.Resources.Limit_Exceeded =>
                report_ast_node_limit;
                return;
            end;
          end if;
        end;
      end if;

      if object_form = Adac.AST.Variable_Object_Form and then
         self.current.kind = Tok_Renames
      then
        if index_constraint /= Adac.AST.INVALID_NODE_ID then
          report_unsupported
            ("constrained object renamings are not supported");
          return;
        end if;
        expect (self, context, Tok_Renames);
        if self.failed then
          return;
        end if;

        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Semicolon,
           terminator_mode     => Require_Exact_Terminator,
           completion_mode     => Return_After_Staging,
           publish_expression_syntax => publish_syntax,
           syntax_node         => renamed_name);
        if self.failed then
          return;
        end if;

        if publish_syntax then
          if renamed_name = Adac.AST.INVALID_NODE_ID then
            report_unsupported
              ("object renaming names are not supported");
            return;
          end if;
          case Adac.Compilation.Syntax.kind_of (context, renamed_name) is
            when Adac.AST.Identifier_Name_Node |
                 Adac.AST.Selected_Name_Node |
                 Adac.AST.Selected_Component_Node |
                 Adac.AST.Parenthesized_Name_Node |
                 Adac.AST.Attribute_Name_Node =>
              null;
            when others =>
              report_unsupported
                ("object renaming names are not supported");
              return;
          end case;
        end if;

        last := self.current.position;
        expect (self, context, Tok_Semicolon);
        if self.failed or else not publish_syntax then
          return;
        end if;

        begin
          declaration :=
            Adac.Compilation.Syntax.create_object_renaming_declaration
              (context,
               defining_symbol,
               defining_span,
               subtype_mark,
               renamed_name,
               Adac.Source.make_span (first, last));
        exception
          when Adac.Resources.Limit_Exceeded =>
            report_ast_node_limit;
            return;
        end;
        Adac.Compilation.Syntax.validate_declaration (context, declaration);
        return;
      end if;

      if object_form = Adac.AST.Variable_Object_Form then
        if self.current.kind = Tok_Assign then
          expect (self, context, Tok_Assign);

          if self.failed then
            return;
          end if;

          declare
            literal_initializer : constant Boolean :=
              is_numeric_literal (self.current.kind);
          begin
            parse_expression_staging
              (self,
               context,
               terminator          => Tok_Semicolon,
               terminator_mode     => Require_Exact_Terminator,
               completion_mode     =>
                 (if not publish_syntax or else literal_initializer
                  then Return_After_Staging
                  else Reject_Unsupported_Expression),
               publish_expression_syntax => publish_syntax,
               syntax_node         => initializer,
               accept_relation_expression => True);
          end;

          if self.failed then
            return;
          end if;

          if publish_syntax and then initializer = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "variable declaration lost a staged initializer";
          end if;
        end if;

        last := self.current.position;
        expect (self, context, Tok_Semicolon);

        if self.failed then
          return;
        end if;
      else
        if self.current.kind = Tok_Semicolon then
          if not allow_deferred_constant then
            report_unsupported
              ("deferred constant declarations are not supported");
            return;
          end if;

          last := self.current.position;
          expect (self, context, Tok_Semicolon);

          if self.failed then
            return;
          end if;
        else
          if self.current.kind /= Tok_Assign then
            report_unsupported ("object declarations are not supported");
            return;
          end if;

          expect (self, context, Tok_Assign);

          if self.failed then
            return;
          end if;

          parse_expression_staging
            (self,
             context,
             terminator          => Tok_Semicolon,
             terminator_mode     => Require_Exact_Terminator,
             completion_mode     =>
               (if publish_syntax
                then Reject_Unsupported_Expression
                else Return_After_Staging),
             publish_expression_syntax => publish_syntax,
             syntax_node         => initializer,
             accept_relation_expression => True,
             accept_unary_expression    => True);

          if self.failed then
            return;
          end if;

          if publish_syntax and then initializer = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "constant declaration lost a staged initializer";
          end if;

          last := self.current.position;
          expect (self, context, Tok_Semicolon);

          if self.failed then
            return;
          end if;
        end if;
      end if;

      if not publish_syntax then
        return;
      end if;

      begin
        if index_constraint = Adac.AST.INVALID_NODE_ID then
          declaration := Adac.Compilation.Syntax.create_object_declaration
            (context,
             object_form,
             defining_symbol,
             defining_span,
             subtype_mark,
             initializer,
             Adac.Source.make_span (first, last));
        else
          declaration :=
            Adac.Compilation.Syntax.create_constrained_object_declaration
              (context,
               object_form,
               defining_symbol,
               defining_span,
               subtype_mark,
               index_constraint,
               initializer,
               Adac.Source.make_span (first, last));
        end if;
      exception
        when Adac.Resources.Limit_Exceeded =>
          report_ast_node_limit;
          return;
      end;

      Adac.Compilation.Syntax.validate_declaration (context, declaration);
    end;
  end parse_current_declaration_staging;

  procedure publish_current_block_staging
    (self               : in out Parser;
     context            : in out Adac.Compilation.Context;
     block_first        : Adac.Source.Position;
     block_declarations : Adac.AST.Node_List;
     block_statements   : Adac.AST.Node_List;
     block_handlers     : Adac.AST.Node_List;
     sequence_span      : Adac.Source.Span;
     block_semicolon    : Adac.Source.Position;
     block_statement    : out Adac.AST.Node_ID)
  is
    block_sequence : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    sequence_first : constant Adac.Source.Position :=
      Adac.Source.first_position (sequence_span);
  begin
    block_statement := Adac.AST.INVALID_NODE_ID;

    begin
      block_sequence := Adac.Compilation.Syntax.create_handled_sequence
        (context,
         block_statements,
         block_handlers,
         sequence_span);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context, sequence_first, "AST node limit exceeded");
    end;
    if self.failed then
      return;
    end if;

    begin
      block_statement := Adac.Compilation.Syntax.create_block_statement
        (context,
         block_declarations,
         block_sequence,
         Adac.Source.make_span (block_first, block_semicolon));
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        block_statement := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, block_first, "AST node limit exceeded");
    end;
  end publish_current_block_staging;

  procedure parse_current_block_statement_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID)
  is
    root_token : constant Token_Kind := self.current.kind;
  begin
    if root_token /= Tok_Declare and then root_token /= Tok_Begin then
      raise Program_Error with
        "current block staging requires declare or begin";
    end if;

    parse_compound_statement_staging
      (self,
       context,
       root_token,
       Return_After_If_Staging,
       syntax_node);
  end parse_current_block_statement_staging;

  procedure parse_current_explicit_block_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID)
  is
  begin
    if self.current.kind /= Tok_Declare then
      raise Program_Error with
        "explicit block staging requires declare";
    end if;
    parse_current_block_statement_staging (self, context, syntax_node);
  end parse_current_explicit_block_staging;

  procedure parse_current_for_loop_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID)
  is
  begin
    parse_compound_statement_staging
      (self, context, Tok_For, Return_After_If_Staging, syntax_node);
  end parse_current_for_loop_staging;

  procedure parse_current_while_loop_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID)
  is
  begin
    parse_compound_statement_staging
      (self, context, Tok_While, Return_After_If_Staging, syntax_node);
  end parse_current_while_loop_staging;

  procedure parse_current_simple_loop_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID)
  is
  begin
    parse_compound_statement_staging
      (self, context, Tok_Loop, Return_After_If_Staging, syntax_node);
  end parse_current_simple_loop_staging;

  procedure parse_current_formal_part_staging
    (self                      : in out Parser;
     context                   : in out Adac.Compilation.Context;
     parameters                : in out Adac.AST.Node_List;
     allow_default_expressions : Boolean := False)
  is
    procedure parse_parameter_specification is
      first : constant Adac.Source.Position := self.current.position;
      defining_identifiers : Adac.AST.Defining_Identifier_List;
      mode               : Adac.AST.Parameter_Mode_Kind :=
        Adac.AST.Default_In_Parameter_Mode;
      subtype_mark       : Adac.AST.Node_ID;
      default_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      loop
        declare
          defining_first : constant Adac.Source.Position :=
            self.current.position;
          defining_text  : constant String := current_text (self);
          defining_symbol : Adac.Symbols.Symbol_ID;
        begin
          defining_symbol := parse_identifier_symbol (self, context);
          if self.failed then
            return;
          end if;
          Adac.AST.append
            (defining_identifiers,
             defining_symbol,
             make_token_span (defining_first, defining_text));
        end;

        exit when self.current.kind /= Tok_Comma;
        expect (self, context, Tok_Comma);
        if self.failed then
          return;
        end if;
      end loop;

      expect (self, context, Tok_Colon);
      if self.failed then
        return;
      end if;

      case self.current.kind is
        when Tok_In =>
          mode := Adac.AST.Explicit_In_Parameter_Mode;
          expect (self, context, Tok_In);

          if not self.failed and then self.current.kind = Tok_Out then
            mode := Adac.AST.In_Out_Parameter_Mode;
            expect (self, context, Tok_Out);
          end if;

        when Tok_Out =>
          mode := Adac.AST.Out_Parameter_Mode;
          expect (self, context, Tok_Out);

        when others =>
          null;
      end case;

      if self.failed then
        return;
      end if;

      parse_selected_identifier_name_staging
        (self,
         context,
         publish_syntax => True,
         syntax_node    => subtype_mark);

      if self.failed then
        return;
      end if;

      if subtype_mark = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "formal parameter lost its subtype-mark syntax";
      end if;

      if allow_default_expressions and then self.current.kind = Tok_Assign then
        expect (self, context, Tok_Assign);

        if self.failed then
          return;
        end if;

        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Right_Parenthesis,
           terminator_mode     => Allow_Semicolon_Before_Terminator,
           completion_mode     => Reject_Unsupported_Expression,
           publish_expression_syntax => True,
           syntax_node         => default_expression);

        if self.failed then
          return;
        end if;

        if default_expression = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "formal parameter lost its represented default expression";
        end if;

        case Adac.Compilation.Syntax.kind_of (context, default_expression) is
          when Adac.AST.Identifier_Name_Node |
               Adac.AST.Selected_Name_Node |
               Adac.AST.Selected_Component_Node |
               Adac.AST.Parenthesized_Name_Node |
               Adac.AST.Attribute_Name_Node |
               Adac.AST.String_Literal_Node =>
            null;

          when others =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               Adac.Source.first_position
                 (Adac.Compilation.Syntax.node_span
                    (context, default_expression)),
               "formal parameter default expressions outside current " &
               "name subset are not supported");
            return;
        end case;
      end if;

      declare
        subtype_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, subtype_mark);
        last : constant Adac.Source.Position :=
          (if default_expression = Adac.AST.INVALID_NODE_ID
           then Adac.Source.last_position (subtype_span)
           else Adac.Source.last_position
             (Adac.Compilation.Syntax.node_span
                (context, default_expression)));
        parameter : Adac.AST.Node_ID;
        parameter_span : constant Adac.Source.Span :=
          Adac.Source.make_span (first, last);
      begin
        if default_expression = Adac.AST.INVALID_NODE_ID then
          parameter :=
            Adac.Compilation.Syntax.create_parameter_specification
              (context,
               defining_identifiers,
               mode,
               subtype_mark,
               parameter_span);
        else
          parameter :=
            Adac.Compilation.Syntax.create_parameter_specification
              (context,
               defining_identifiers,
               mode,
               subtype_mark,
               default_expression,
               parameter_span);
        end if;

        Adac.Compilation.Syntax.validate_parameter (context, parameter);
        Adac.AST.append (parameters, parameter);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, first, "AST node limit exceeded");
      end;
    end parse_parameter_specification;
  begin
    if self.current.kind /= Tok_Left_Parenthesis then
      return;
    end if;

    expect (self, context, Tok_Left_Parenthesis);

    if self.failed then
      return;
    end if;

    parse_parameter_specification;

    while not self.failed and then self.current.kind = Tok_Semicolon loop
      expect (self, context, Tok_Semicolon);

      if self.failed then
        return;
      end if;

      parse_parameter_specification;
    end loop;

    if self.failed then
      return;
    end if;

    expect (self, context, Tok_Right_Parenthesis);
  end parse_current_formal_part_staging;

  type Function_Body_Staging_Mode is
    (Ordinary_Function_Body,
     Function_Nested_Function_Body,
     Procedure_Nested_Function_Body);

  procedure parse_procedure_nested_function_body_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID);

  procedure parse_nested_procedure_type_declaration_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     declaration : out Adac.AST.Node_ID);

  procedure parse_program_unit_name_staging
    (self       : in out Parser;
     context    : in out Adac.Compilation.Context;
     components : in out Parsed_Program_Unit_Name);

  procedure parse_use_clause_staging
    (self    : in out Parser;
     context : in out Adac.Compilation.Context;
     clause  : out Adac.AST.Node_ID);

  procedure parse_package_instantiation_tail_common
    (self                 : in out Parser;
     context              : in out Adac.Compilation.Context;
     package_first        : Adac.Source.Position;
     parsed_defining_name : Parsed_Program_Unit_Name;
     require_item_eof     : Boolean;
     item                 : out Adac.AST.Node_ID;
     item_span            : out Adac.Source.Span);

  procedure parse_nested_procedure_body_staging
    (self                     : in out Parser;
     context                  : in out Adac.Compilation.Context;
     syntax_node              : out Adac.AST.Node_ID;
     allow_declaration        : Boolean := False;
     allow_nested_subprograms : Boolean := True;
     allow_body_stub          : Boolean := False)
  is separate;

  procedure parse_function_body_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID;
     mode        : Function_Body_Staging_Mode := Ordinary_Function_Body)
  is separate;

  procedure parse_procedure_nested_function_body_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     syntax_node : out Adac.AST.Node_ID)
  is
  begin
    parse_function_body_staging
      (self,
       context,
       syntax_node,
       mode => Procedure_Nested_Function_Body);
  end parse_procedure_nested_function_body_staging;

  procedure parse_program_unit_name_staging
    (self       : in out Parser;
     context    : in out Adac.Compilation.Context;
     components : in out Parsed_Program_Unit_Name)
  is
    procedure parse_component is
    begin
      if self.current.kind = Tok_Invalid_Identifier then
        report_invalid_identifier (self, context);
        return;
      end if;

      if self.current.kind /= Tok_Identifier then
        report_expected (self, context, Tok_Identifier);
        return;
      end if;

      components.append
        (Parsed_Program_Unit_Name_Component'
          (spelling => Ada.Strings.Unbounded.to_unbounded_string
             (current_text (self)),
           span => make_token_span
             (self.current.position, current_text (self))));
      advance (self, context);
    end parse_component;
  begin
    parse_component;
    while not self.failed and then self.current.kind = Tok_Dot loop
      expect (self, context, Tok_Dot);
      parse_component;
    end loop;
  end parse_program_unit_name_staging;

  procedure publish_program_unit_name
    (self       : in out Parser;
     context    : in out Adac.Compilation.Context;
     components : Parsed_Program_Unit_Name;
     name       : in out Adac.AST.Program_Unit_Name)
  is
  begin
    for component of components loop
      declare
        symbol : Adac.Symbols.Symbol_ID;
      begin
        begin
          symbol := Adac.Compilation.Symbols.intern
            (context, Ada.Strings.Unbounded.to_string (component.spelling));
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               Adac.Source.first_position (component.span),
               "symbol limit exceeded");
            return;
        end;
        Adac.AST.append (name, symbol, component.span);
      end;
    end loop;
  end publish_program_unit_name;

  procedure parse_use_clause_staging
    (self    : in out Parser;
     context : in out Adac.Compilation.Context;
     clause  : out Adac.AST.Node_ID)
  is
    first         : constant Adac.Source.Position := self.current.position;
    names         : Adac.AST.Node_List;
    use_type_form : Boolean := False;
    last          : Adac.Source.Position := first;
  begin
    clause := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Use);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_All then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "use all type clauses are not supported");
      return;
    end if;

    if self.current.kind = Tok_Type then
      use_type_form := True;
      expect (self, context, Tok_Type);
      if self.failed then
        return;
      end if;
    end if;

    loop
      if self.current.kind /= Tok_Identifier and then
         self.current.kind /= Tok_Invalid_Identifier
      then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           (if use_type_form
            then "use type subtype marks are not supported"
            else "package use names are not supported"));
        return;
      end if;

      declare
        name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        parse_selected_identifier_name_staging
          (self,
           context,
           publish_syntax => True,
           syntax_node    => name);
        if self.failed then
          return;
        end if;
        if name = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with "use clause lost represented name syntax";
        end if;
        Adac.AST.append (names, name);
      end;

      exit when self.current.kind /= Tok_Comma;
      expect (self, context, Tok_Comma);
      if self.failed then
        return;
      end if;
    end loop;

    last := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;

    begin
      if use_type_form then
        clause := Adac.Compilation.Syntax.create_use_type_clause
          (context, names, Adac.Source.make_span (first, last));
        Adac.Compilation.Syntax.validate_use_type_clause (context, clause);
      else
        clause := Adac.Compilation.Syntax.create_use_package_clause
          (context, names, Adac.Source.make_span (first, last));
        Adac.Compilation.Syntax.validate_use_package_clause (context, clause);
      end if;
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        clause := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_use_clause_staging;

  procedure parse_package_instantiation_tail_common
    (self                 : in out Parser;
     context              : in out Adac.Compilation.Context;
     package_first        : Adac.Source.Position;
     parsed_defining_name : Parsed_Program_Unit_Name;
     require_item_eof     : Boolean;
     item                 : out Adac.AST.Node_ID;
     item_span            : out Adac.Source.Span)
  is
    defining_name : Adac.AST.Program_Unit_Name;
    generic_name  : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    actuals       : Adac.AST.Generic_Actual_Association_List;
    last          : Adac.Source.Position := self.current.position;

    procedure reject_instantiation (message : String) is
    begin
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, self.current.position, message);
    end reject_instantiation;

    procedure parse_actual (actual : out Adac.AST.Node_ID) is
    begin
      actual := Adac.AST.INVALID_NODE_ID;

      case self.current.kind is
        when Tok_Identifier | Tok_Invalid_Identifier =>
          parse_selected_generic_actual_name_staging
            (self, context, publish_syntax => True, syntax_node => actual);

        when Tok_String_Literal =>
          declare
            position : constant Adac.Source.Position := self.current.position;
            spelling : constant String := current_text (self);
          begin
            begin
              actual := Adac.Compilation.Syntax.create_string_literal
                (context, spelling, make_token_span (position, spelling));
              Adac.Compilation.Syntax.validate_string_literal (context, actual);
            exception
              when Adac.Resources.Limit_Exceeded =>
                self.failed := True;
                Adac.Compilation.Diagnostics.error
                  (context, position, "AST node limit exceeded");
                return;
            end;

            advance (self, context);
          end;

        when Tok_Invalid_String_Literal =>
          report_string_literal (self, context);

        when others =>
          reject_instantiation
            ("generic actual expressions outside current name/string literal " &
             "subset are not supported");
      end case;
    end parse_actual;
  begin
    item := Adac.AST.INVALID_NODE_ID;
    item_span := Adac.Source.INVALID_SPAN;

    publish_program_unit_name
      (self, context, parsed_defining_name, defining_name);
    if self.failed then
      return;
    end if;

    expect (self, context, Tok_New);
    if self.failed then
      return;
    end if;

    parse_selected_identifier_name_staging
      (self, context, publish_syntax => True, syntax_node => generic_name);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Left_Parenthesis then
      expect (self, context, Tok_Left_Parenthesis);
      if self.failed then
        return;
      end if;

      loop
        if self.current.kind = Tok_Invalid_Identifier then
          report_invalid_identifier (self, context);
          return;
        end if;
        if self.current.kind = Tok_Invalid_String_Literal then
          report_string_literal (self, context);
          return;
        end if;
        if self.current.kind = Tok_String_Literal and then
           peek_token_kind (self, context) = Tok_Arrow and then
           not is_operator_symbol (current_text (self))
        then
          report_invalid_operator_symbol (self, context);
          return;
        end if;
        if self.current.kind /= Tok_Identifier and then
           self.current.kind /= Tok_String_Literal
        then
          reject_instantiation
            ("generic actual expressions outside current name/string literal " &
             "subset are not supported");
          return;
        end if;

        if peek_token_kind (self, context) = Tok_Arrow then
          declare
            selector_position : constant Adac.Source.Position :=
              self.current.position;
            selector_spelling : constant String := current_text (self);
            selector_span : constant Adac.Source.Span :=
              make_token_span (selector_position, selector_spelling);
            selector_symbol : Adac.Symbols.Symbol_ID :=
              Adac.Symbols.INVALID_SYMBOL_ID;
            actual : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          begin
            if self.current.kind = Tok_Identifier then
              parse_unpublished_identifier (self, context);
            else
              advance (self, context);
            end if;
            if self.failed then
              return;
            end if;

            begin
              selector_symbol :=
                Adac.Compilation.Symbols.intern (context, selector_spelling);
            exception
              when Adac.Resources.Limit_Exceeded =>
                self.failed := True;
                Adac.Compilation.Diagnostics.error
                  (context, selector_position, "symbol limit exceeded");
                return;
            end;

            expect (self, context, Tok_Arrow);
            if self.failed then
              return;
            end if;

            parse_actual (actual);
            if self.failed then
              return;
            end if;
            Adac.AST.append
              (actuals, selector_symbol, selector_span, actual);
          end;
        else
          declare
            actual : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          begin
            parse_actual (actual);
            if self.failed then
              return;
            end if;
            Adac.AST.append (actuals, actual);
          end;
        end if;

        exit when self.current.kind = Tok_Right_Parenthesis;
        expect (self, context, Tok_Comma);
        if self.failed then
          return;
        end if;
      end loop;

      expect (self, context, Tok_Right_Parenthesis);
      if self.failed then
        return;
      end if;
    end if;

    last := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;
    if require_item_eof then
      expect (self, context, Tok_EOF);
      if self.failed then
        return;
      end if;
    end if;

    item_span := Adac.Source.make_span (package_first, last);
    begin
      item := Adac.Compilation.Syntax.create_package_instantiation
        (context, defining_name, generic_name, actuals, item_span);
      Adac.Compilation.Syntax.validate_package_instantiation (context, item);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        item := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, package_first, "AST node limit exceeded");
    end;
  end parse_package_instantiation_tail_common;

  procedure parse_package_procedure_declaration_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     declaration : out Adac.AST.Node_ID)
  is
    first             : constant Adac.Source.Position := self.current.position;
    defining_position : Adac.Source.Position := self.current.position;
    defining_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    parameters        : Adac.AST.Node_List;
    last              : Adac.Source.Position := self.current.position;
  begin
    declaration := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Procedure);

    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;

    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    defining_position := self.current.position;
    declare
      spelling : constant String := current_text (self);
    begin
      defining_span := make_token_span (defining_position, spelling);
      parse_unpublished_identifier (self, context);

      if self.failed then
        return;
      end if;

      parse_current_formal_part_staging (self, context, parameters);

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_With then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "package procedure aspects are not supported");
        return;
      end if;

      if self.current.kind = Tok_Semicolon then
        last := self.current.position;
      end if;
      expect (self, context, Tok_Semicolon);

      if self.failed then
        return;
      end if;

      declare
        symbol : Adac.Symbols.Symbol_ID;
      begin
        begin
          symbol := Adac.Compilation.Symbols.intern (context, spelling);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, defining_position, "symbol limit exceeded");
            return;
        end;

        begin
          declaration :=
            Adac.Compilation.Syntax.create_procedure_declaration
              (context,
               symbol,
               defining_span,
               parameters,
               Adac.Source.make_span (first, last));
          Adac.Compilation.Syntax.validate_declaration
            (context, declaration);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            declaration := Adac.AST.INVALID_NODE_ID;
            Adac.Compilation.Diagnostics.error
              (context, first, "AST node limit exceeded");
        end;
      end;
    end;
  end parse_package_procedure_declaration_staging;

  procedure parse_package_function_declaration_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     declaration : out Adac.AST.Node_ID)
  is
    first             : constant Adac.Source.Position := self.current.position;
    defining_position : Adac.Source.Position := self.current.position;
    defining_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    defining_spelling : Ada.Strings.Unbounded.Unbounded_String;
    parameters        : Adac.AST.Node_List;
    result_subtype    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    aspect            : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    last              : Adac.Source.Position := self.current.position;
  begin
    declaration := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Function);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind /= Tok_Identifier then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "function defining designators outside identifiers are not supported");
      return;
    end if;

    defining_position := self.current.position;
    defining_spelling :=
      Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    defining_span :=
      make_token_span (defining_position, current_text (self));
    parse_unpublished_identifier (self, context);
    if self.failed then
      return;
    end if;

    parse_current_formal_part_staging
      (self,
       context,
       parameters,
       allow_default_expressions => True);
    if self.failed then
      return;
    end if;

    expect (self, context, Tok_Return);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Not or else self.current.kind = Tok_Access then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "function null exclusions or access results are not supported");
      return;
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => True,
       syntax_node    => result_subtype);
    if self.failed then
      return;
    end if;
    if result_subtype = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with "function result lost represented syntax";
    end if;

    if self.current.kind = Tok_With then
      declare
        aspect_first : constant Adac.Source.Position := self.current.position;
        mark_position : Adac.Source.Position := self.current.position;
        mark_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
        mark_spelling : Ada.Strings.Unbounded.Unbounded_String;
        mark_symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
        definition : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        expect (self, context, Tok_With);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Invalid_Identifier then
          report_invalid_identifier (self, context);
          return;
        end if;
        if self.current.kind /= Tok_Identifier then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "function aspect marks outside identifiers are not supported");
          return;
        end if;

        mark_position := self.current.position;
        mark_spelling :=
          Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
        mark_span := make_token_span (mark_position, current_text (self));
        parse_unpublished_identifier (self, context);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Apostrophe then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "function aspect Class forms are not supported");
          return;
        end if;

        expect (self, context, Tok_Arrow);
        if self.failed then
          return;
        end if;

        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Semicolon,
           terminator_mode     => Require_Exact_Terminator,
           completion_mode     => Return_After_Staging,
           publish_expression_syntax => True,
           syntax_node         => definition);
        if self.failed then
          return;
        end if;
        if definition = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with "function aspect lost its definition";
        end if;

        begin
          mark_symbol := Adac.Compilation.Symbols.intern
            (context, Ada.Strings.Unbounded.to_string (mark_spelling));
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, mark_position, "symbol limit exceeded");
            return;
        end;

        begin
          aspect :=
            Adac.Compilation.Syntax.create_aspect_specification
              (context,
               mark_symbol,
               mark_span,
               definition,
               Adac.Source.make_span
                 (aspect_first,
                  Adac.Source.last_position
                    (Adac.Compilation.Syntax.node_span
                       (context, definition))));
          Adac.Compilation.Syntax.validate_aspect_specification
            (context, aspect);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            aspect := Adac.AST.INVALID_NODE_ID;
            Adac.Compilation.Diagnostics.error
              (context, aspect_first, "AST node limit exceeded");
            return;
        end;
      end;
    end if;

    if self.current.kind = Tok_Semicolon then
      last := self.current.position;
    end if;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;

    declare
      symbol : Adac.Symbols.Symbol_ID;
    begin
      begin
        symbol :=
          Adac.Compilation.Symbols.intern
            (context,
             Ada.Strings.Unbounded.to_string (defining_spelling));
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, defining_position, "symbol limit exceeded");
          return;
      end;

      begin
        declaration :=
          Adac.Compilation.Syntax.create_function_declaration
            (context,
             symbol,
             defining_span,
             parameters,
             result_subtype,
             aspect,
             Adac.Source.make_span (first, last));
        Adac.Compilation.Syntax.validate_declaration (context, declaration);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          declaration := Adac.AST.INVALID_NODE_ID;
          Adac.Compilation.Diagnostics.error
            (context, first, "AST node limit exceeded");
      end;
    end;
  end parse_package_function_declaration_staging;

  procedure parse_record_component_staging
    (self      : in out Parser;
     context   : in out Adac.Compilation.Context;
     component : out Adac.AST.Node_ID)
  is
  begin
    component := Adac.AST.INVALID_NODE_ID;
  declare
    component_first    : constant Adac.Source.Position :=
      self.current.position;
    component_position : Adac.Source.Position := self.current.position;
    component_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    component_spelling : Ada.Strings.Unbounded.Unbounded_String;
    component_symbol   : Adac.Symbols.Symbol_ID :=
      Adac.Symbols.INVALID_SYMBOL_ID;
    aliased_form       : Boolean := False;
    subtype_mark       : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    default_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    component_last     : Adac.Source.Position := self.current.position;
    component_node     : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    component_position := self.current.position;
    component_spelling :=
      Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    component_span :=
      make_token_span (component_position, current_text (self));
    parse_unpublished_identifier (self, context);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Comma then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "record components with multiple defining " &
        "identifiers " &
         "are not supported");
      return;
    end if;

    begin
      component_symbol :=
        Adac.Compilation.Symbols.intern
          (context,
           Ada.Strings.Unbounded.to_string (component_spelling));
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context, component_position, "symbol limit exceeded");
        return;
    end;

    expect (self, context, Tok_Colon);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Aliased then
      aliased_form := True;
      expect (self, context, Tok_Aliased);
      if self.failed then
        return;
      end if;
    end if;

    if self.current.kind = Tok_Access then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "access record components are not supported");
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => True,
       syntax_node    => subtype_mark);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Assign then
      expect (self, context, Tok_Assign);
      if self.failed then
        return;
      end if;

      parse_expression_staging
        (self,
         context,
         terminator          => Tok_Semicolon,
         terminator_mode     => Require_Exact_Terminator,
         completion_mode     => Reject_Unsupported_Expression,
         publish_expression_syntax => True,
         syntax_node         => default_expression);
      if self.failed then
        return;
      end if;
    end if;

    if self.current.kind = Tok_With then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "record component aspects are not supported");
      return;
    end if;

    if self.current.kind = Tok_Semicolon then
      component_last := self.current.position;
    end if;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;

    begin
      component_node :=
        Adac.Compilation.Syntax.create_record_component_declaration
          (context,
           component_symbol,
           component_span,
           aliased_form,
           subtype_mark,
           default_expression,
           Adac.Source.make_span
             (component_first, component_last));
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context, component_first, "AST node limit exceeded");
        return;
    end;

    component := component_node;
  end;
  end parse_record_component_staging;

  procedure parse_record_variant_part_staging
    (self         : in out Parser;
     context      : in out Adac.Compilation.Context;
     variant_part : out Adac.AST.Node_ID)
  is
    first             : constant Adac.Source.Position := self.current.position;
    discriminant_name : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    variants          : Adac.AST.Node_List;
    last              : Adac.Source.Position := first;
  begin
    variant_part := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Case);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => True,
       syntax_node    => discriminant_name);
    if self.failed then
      return;
    end if;
    if Adac.Compilation.Syntax.kind_of (context, discriminant_name) /=
       Adac.AST.Identifier_Name_Node
    then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         first,
         "record variant discriminant names outside identifier subset are " &
         "not supported");
      return;
    end if;

    expect (self, context, Tok_Is);
    if self.failed then
      return;
    end if;

    if self.current.kind /= Tok_When then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, self.current.position, "record variant part has no variants");
      return;
    end if;

    while not self.failed and then self.current.kind = Tok_When loop
      declare
        variant_first       : constant Adac.Source.Position :=
          self.current.position;
        choices             : Adac.AST.Node_List;
        components          : Adac.AST.Node_List;
        null_component_list : Boolean := False;
        variant_last        : Adac.Source.Position := variant_first;
        variant_node        : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        expect (self, context, Tok_When);
        if self.failed then
          return;
        end if;

        loop
          if self.current.kind = Tok_Others then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "record variant others choices are not supported");
            return;
          end if;
          if self.current.kind = Tok_Invalid_Identifier then
            report_invalid_identifier (self, context);
            return;
          end if;
          if self.current.kind /= Tok_Identifier then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "record variant choices outside identifier subset are not " &
               "supported");
            return;
          end if;

          declare
            choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
            choice_position : constant Adac.Source.Position :=
              self.current.position;
          begin
            parse_selected_identifier_name_staging
              (self,
               context,
               publish_syntax => True,
               syntax_node    => choice);
            if self.failed then
              return;
            end if;
            if Adac.Compilation.Syntax.kind_of (context, choice) /=
               Adac.AST.Identifier_Name_Node
            then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 choice_position,
                 "record variant choices outside identifier subset are not " &
                 "supported");
              return;
            end if;
            Adac.AST.append (choices, choice);
          end;

          exit when self.current.kind /= Tok_Vertical_Bar;
          expect (self, context, Tok_Vertical_Bar);
          if self.failed then
            return;
          end if;
        end loop;

        expect (self, context, Tok_Arrow);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Null then
          null_component_list := True;
          expect (self, context, Tok_Null);
          if self.failed then
            return;
          end if;
          if self.current.kind = Tok_Semicolon then
            variant_last := self.current.position;
          end if;
          expect (self, context, Tok_Semicolon);
          if self.failed then
            return;
          end if;
        else
          if self.current.kind = Tok_When or else
             self.current.kind = Tok_End
          then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "record variant component list is empty");
            return;
          end if;

          while not self.failed and then
                self.current.kind /= Tok_When and then
                self.current.kind /= Tok_End
          loop
            if self.current.kind = Tok_Case then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "nested record variant parts are not supported");
              return;
            end if;

            declare
              component : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
            begin
              parse_record_component_staging (self, context, component);
              if self.failed then
                return;
              end if;
              Adac.AST.append (components, component);
              variant_last := Adac.Source.last_position
                (Adac.Compilation.Syntax.node_span (context, component));
            end;
          end loop;
        end if;

        begin
          variant_node :=
            Adac.Compilation.Syntax.create_record_variant
              (context,
               choices,
               components,
               null_component_list,
               Adac.Source.make_span (variant_first, variant_last));
          Adac.Compilation.Syntax.validate_record_variant
            (context, variant_node);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, variant_first, "AST node limit exceeded");
            return;
        end;
        Adac.AST.append (variants, variant_node);
      end;
    end loop;

    expect (self, context, Tok_End);
    if self.failed then
      return;
    end if;
    expect (self, context, Tok_Case);
    if self.failed then
      return;
    end if;
    if self.current.kind = Tok_Semicolon then
      last := self.current.position;
    end if;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;

    begin
      variant_part :=
        Adac.Compilation.Syntax.create_record_variant_part
          (context,
           discriminant_name,
           variants,
           Adac.Source.make_span (first, last));
      Adac.Compilation.Syntax.validate_record_variant_part
        (context, variant_part);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        variant_part := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_record_variant_part_staging;

  procedure parse_subtype_declaration_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     declaration : out Adac.AST.Node_ID)
  is
    first             : constant Adac.Source.Position := self.current.position;
    defining_position : Adac.Source.Position := self.current.position;
    defining_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    defining_spelling : Ada.Strings.Unbounded.Unbounded_String;
    defining_symbol   : Adac.Symbols.Symbol_ID :=
      Adac.Symbols.INVALID_SYMBOL_ID;
    subtype_mark      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    constraint        : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    last              : Adac.Source.Position := self.current.position;
  begin
    declaration := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Subtype);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    defining_position := self.current.position;
    defining_spelling :=
      Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    defining_span := make_token_span (defining_position, current_text (self));
    parse_unpublished_identifier (self, context);
    if self.failed then
      return;
    end if;

    begin
      defining_symbol :=
        Adac.Compilation.Symbols.intern
          (context, Ada.Strings.Unbounded.to_string (defining_spelling));
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context, defining_position, "symbol limit exceeded");
        return;
    end;

    expect (self, context, Tok_Is);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => True,
       syntax_node    => subtype_mark);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Range then
      declare
        range_first : constant Adac.Source.Position := self.current.position;
        lower_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        upper_bound : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        range_last  : Adac.Source.Position := self.current.position;
      begin
        expect (self, context, Tok_Range);
        if self.failed then
          return;
        end if;

        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Double_Dot,
           terminator_mode     => Require_Exact_Terminator,
           completion_mode     => Return_After_Staging,
           publish_expression_syntax => True,
           syntax_node         => lower_bound);
        if self.failed then
          return;
        end if;
        if lower_bound = Adac.AST.INVALID_NODE_ID then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "subtype range lower bound is not represented");
          return;
        end if;

        expect (self, context, Tok_Double_Dot);
        if self.failed then
          return;
        end if;

        parse_expression_staging
          (self,
           context,
           terminator          => Tok_Semicolon,
           terminator_mode     => Require_Exact_Terminator,
           completion_mode     => Return_After_Staging,
           publish_expression_syntax => True,
           syntax_node         => upper_bound);
        if self.failed then
          return;
        end if;
        if upper_bound = Adac.AST.INVALID_NODE_ID then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "subtype range upper bound is not represented");
          return;
        end if;

        range_last := Adac.Source.last_position
          (Adac.Compilation.Syntax.node_span (context, upper_bound));
        begin
          constraint :=
            Adac.Compilation.Syntax.create_range_constraint
              (context,
               lower_bound,
               upper_bound,
               Adac.Source.make_span (range_first, range_last));
          Adac.Compilation.Syntax.validate_range_constraint
            (context, constraint);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, range_first, "AST node limit exceeded");
            return;
        end;
      end;
    elsif self.current.kind /= Tok_Semicolon then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "subtype constraints outside current range subset are not supported");
      return;
    end if;

    if self.current.kind = Tok_Semicolon then
      last := self.current.position;
    end if;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;

    begin
      declaration :=
        Adac.Compilation.Syntax.create_subtype_declaration
          (context,
           defining_symbol,
           defining_span,
           subtype_mark,
           constraint,
           Adac.Source.make_span (first, last));
      Adac.Compilation.Syntax.validate_declaration (context, declaration);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        declaration := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_subtype_declaration_staging;

  procedure parse_type_declaration_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     declaration : out Adac.AST.Node_ID)
  is
    first             : constant Adac.Source.Position := self.current.position;
    defining_position : Adac.Source.Position := self.current.position;
    defining_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    defining_spelling : Ada.Strings.Unbounded.Unbounded_String;
    discriminants     : Adac.AST.Node_List;
    discriminated_symbol : Adac.Symbols.Symbol_ID :=
      Adac.Symbols.INVALID_SYMBOL_ID;
    has_discriminants : Boolean := False;
    limited_form      : Boolean := False;
    last              : Adac.Source.Position := self.current.position;
  begin
    declaration := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Type);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind /= Tok_Identifier then
      report_expected (self, context, Tok_Identifier);
      return;
    end if;

    defining_position := self.current.position;
    defining_spelling :=
      Ada.Strings.Unbounded.to_unbounded_string (current_text (self));
    defining_span :=
      make_token_span (defining_position, current_text (self));
    parse_unpublished_identifier (self, context);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Left_Parenthesis then
      has_discriminants := True;
      begin
        discriminated_symbol :=
          Adac.Compilation.Symbols.intern
            (context,
             Ada.Strings.Unbounded.to_string (defining_spelling));
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, defining_position, "symbol limit exceeded");
          return;
      end;

      expect (self, context, Tok_Left_Parenthesis);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Invalid_Identifier then
        report_invalid_identifier (self, context);
        return;
      end if;
      if self.current.kind /= Tok_Identifier then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "discriminant forms outside current represented subset are not " &
           "supported");
        return;
      end if;

      declare
        discriminant_first : constant Adac.Source.Position :=
          self.current.position;
        discriminant_spelling : constant String := current_text (self);
        discriminant_span : constant Adac.Source.Span :=
          make_token_span (discriminant_first, discriminant_spelling);
        discriminant_symbol : Adac.Symbols.Symbol_ID :=
          Adac.Symbols.INVALID_SYMBOL_ID;
        subtype_mark : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        default_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        discriminant_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        discriminant_last : Adac.Source.Position := discriminant_first;
      begin
        parse_unpublished_identifier (self, context);
        if self.failed then
          return;
        end if;
        if self.current.kind = Tok_Comma then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "discriminants with multiple defining identifiers are not " &
             "supported");
          return;
        end if;

        begin
          discriminant_symbol :=
            Adac.Compilation.Symbols.intern (context, discriminant_spelling);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, discriminant_first, "symbol limit exceeded");
            return;
        end;

        expect (self, context, Tok_Colon);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Not then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "discriminant null exclusions are not supported");
          return;
        end if;
        if self.current.kind = Tok_Access then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "access discriminants are not supported");
          return;
        end if;
        if self.current.kind = Tok_Invalid_Identifier then
          report_invalid_identifier (self, context);
          return;
        end if;
        if self.current.kind /= Tok_Identifier then
          report_expected (self, context, Tok_Identifier);
          return;
        end if;

        parse_selected_identifier_name_staging
          (self,
           context,
           publish_syntax => True,
           syntax_node    => subtype_mark);
        if self.failed then
          return;
        end if;
        discriminant_last := Adac.Source.last_position
          (Adac.Compilation.Syntax.node_span (context, subtype_mark));

        if self.current.kind = Tok_Assign then
          expect (self, context, Tok_Assign);
          if self.failed then
            return;
          end if;
          parse_expression_staging
            (self,
             context,
             terminator          => Tok_Right_Parenthesis,
             terminator_mode     => Allow_Semicolon_Before_Terminator,
             completion_mode     => Reject_Unsupported_Expression,
             publish_expression_syntax => True,
             syntax_node         => default_expression);
          if self.failed then
            return;
          end if;
          if default_expression = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "discriminant default lost represented expression syntax";
          end if;
          discriminant_last := Adac.Source.last_position
            (Adac.Compilation.Syntax.node_span (context, default_expression));
        end if;

        if self.current.kind = Tok_With then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "discriminant aspects are not supported");
          return;
        end if;
        if self.current.kind = Tok_Semicolon then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "multiple discriminant specifications are not supported");
          return;
        end if;

        begin
          discriminant_node :=
            Adac.Compilation.Syntax.create_discriminant_specification
              (context,
               discriminant_symbol,
               discriminant_span,
               subtype_mark,
               default_expression,
               Adac.Source.make_span
                 (discriminant_first, discriminant_last));
          Adac.Compilation.Syntax.validate_discriminant_specification
            (context, discriminant_node);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, discriminant_first, "AST node limit exceeded");
            return;
        end;
        Adac.AST.append (discriminants, discriminant_node);
      end;

      expect (self, context, Tok_Right_Parenthesis);
      if self.failed then
        return;
      end if;
    end if;

    expect (self, context, Tok_Is);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Limited then
      limited_form := True;
      expect (self, context, Tok_Limited);
      if self.failed then
        return;
      end if;
    end if;

    if limited_form and then self.current.kind = Tok_Semicolon and then
       not has_discriminants
    then
      report_expected (self, context, Tok_Private);
      return;
    end if;

    if has_discriminants and then
       self.current.kind /= Tok_Record and then
       self.current.kind /= Tok_Private
    then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "discriminant parts outside current record/private type subset are " &
         "not supported");
      return;
    end if;

    if limited_form and then self.current.kind /= Tok_Record and then
       self.current.kind /= Tok_Private
    then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "type declarations outside current represented subset " &
         "are not supported");
      return;
    end if;

    if self.current.kind = Tok_New then
      declare
        defining_symbol     : Adac.Symbols.Symbol_ID;
        parent_subtype_mark : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        begin
          defining_symbol :=
            Adac.Compilation.Symbols.intern
              (context,
               Ada.Strings.Unbounded.to_string (defining_spelling));
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, defining_position, "symbol limit exceeded");
            return;
        end;

        expect (self, context, Tok_New);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Invalid_Identifier then
          report_invalid_identifier (self, context);
          return;
        end if;
        if self.current.kind /= Tok_Identifier then
          report_expected (self, context, Tok_Identifier);
          return;
        end if;

        parse_selected_identifier_name_staging
          (self,
           context,
           publish_syntax => True,
           syntax_node    => parent_subtype_mark);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Left_Parenthesis or else
           self.current.kind = Tok_Range
        then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "derived type constraints are not supported");
          return;
        end if;

        if self.current.kind = Tok_And then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "derived type interface lists are not supported");
          return;
        end if;

        if self.current.kind = Tok_With then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "derived type extensions or aspects are not supported");
          return;
        end if;

        if self.current.kind = Tok_Semicolon then
          last := self.current.position;
        end if;
        expect (self, context, Tok_Semicolon);
        if self.failed then
          return;
        end if;

        begin
          declaration :=
            Adac.Compilation.Syntax.create_derived_type_declaration
              (context,
               defining_symbol,
               defining_span,
               parent_subtype_mark,
               Adac.Source.make_span (first, last));
          Adac.Compilation.Syntax.validate_declaration (context, declaration);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            declaration := Adac.AST.INVALID_NODE_ID;
            Adac.Compilation.Diagnostics.error
              (context, first, "AST node limit exceeded");
        end;
      end;
      return;
    end if;

    if self.current.kind = Tok_Left_Parenthesis then
      declare
        parsed_literals : Parsed_Program_Unit_Name;
      begin
        expect (self, context, Tok_Left_Parenthesis);
        if self.failed then
          return;
        end if;

        loop
          if self.current.kind = Tok_Character_Literal then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "enumeration character literals are not supported");
            return;
          end if;
          if self.current.kind = Tok_Invalid_Identifier then
            report_invalid_identifier (self, context);
            return;
          end if;
          if self.current.kind /= Tok_Identifier then
            report_expected (self, context, Tok_Identifier);
            return;
          end if;

          parsed_literals.append
            (Parsed_Program_Unit_Name_Component'
              (spelling => Ada.Strings.Unbounded.to_unbounded_string
                 (current_text (self)),
               span => make_token_span
                 (self.current.position, current_text (self))));
          parse_unpublished_identifier (self, context);
          if self.failed then
            return;
          end if;

          exit when self.current.kind /= Tok_Comma;
          expect (self, context, Tok_Comma);
          if self.failed then
            return;
          end if;
        end loop;

        expect (self, context, Tok_Right_Parenthesis);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_With then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "enumeration type aspects are not supported");
          return;
        end if;

        if self.current.kind = Tok_Semicolon then
          last := self.current.position;
        end if;
        expect (self, context, Tok_Semicolon);
        if self.failed then
          return;
        end if;

        declare
          defining_symbol : Adac.Symbols.Symbol_ID;
          literals        : Adac.AST.Enumeration_Literal_List;
        begin
          begin
            defining_symbol :=
              Adac.Compilation.Symbols.intern
                (context,
                 Ada.Strings.Unbounded.to_string (defining_spelling));
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, defining_position, "symbol limit exceeded");
              return;
          end;

          for literal of parsed_literals loop
            declare
              symbol : Adac.Symbols.Symbol_ID;
            begin
              begin
                symbol := Adac.Compilation.Symbols.intern
                  (context, Ada.Strings.Unbounded.to_string (literal.spelling));
              exception
                when Adac.Resources.Limit_Exceeded =>
                  self.failed := True;
                  Adac.Compilation.Diagnostics.error
                    (context,
                     Adac.Source.first_position (literal.span),
                     "symbol limit exceeded");
                  return;
              end;
              Adac.AST.append (literals, symbol, literal.span);
            end;
          end loop;

          begin
            declaration :=
              Adac.Compilation.Syntax.create_enumeration_type_declaration
                (context,
                 defining_symbol,
                 defining_span,
                 literals,
                 Adac.Source.make_span (first, last));
            Adac.Compilation.Syntax.validate_declaration (context, declaration);
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              declaration := Adac.AST.INVALID_NODE_ID;
              Adac.Compilation.Diagnostics.error
                (context, first, "AST node limit exceeded");
          end;
        end;
      end;
      return;
    end if;

    if self.current.kind = Tok_Access then
      declare
        defining_symbol   : Adac.Symbols.Symbol_ID;
        modifier          : Adac.AST.General_Access_Modifier_Kind :=
          Adac.AST.No_General_Access_Modifier;
        designated_subtype : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        begin
          defining_symbol :=
            Adac.Compilation.Symbols.intern
              (context,
               Ada.Strings.Unbounded.to_string (defining_spelling));
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, defining_position, "symbol limit exceeded");
            return;
        end;

        expect (self, context, Tok_Access);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_All then
          modifier := Adac.AST.All_General_Access_Modifier;
          expect (self, context, Tok_All);
        elsif self.current.kind = Tok_Constant then
          modifier := Adac.AST.Constant_General_Access_Modifier;
          expect (self, context, Tok_Constant);
        end if;
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Procedure or else
           self.current.kind = Tok_Function
        then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "access-to-subprogram types are not supported");
          return;
        end if;

        if self.current.kind = Tok_Invalid_Identifier then
          report_invalid_identifier (self, context);
          return;
        end if;
        if self.current.kind /= Tok_Identifier then
          report_expected (self, context, Tok_Identifier);
          return;
        end if;

        parse_selected_identifier_name_staging
          (self,
           context,
           publish_syntax => True,
           syntax_node    => designated_subtype);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_Left_Parenthesis or else
           self.current.kind = Tok_Range
        then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "access subtype constraints are not supported");
          return;
        end if;

        if self.current.kind = Tok_With then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "access type aspects are not supported");
          return;
        end if;

        if self.current.kind = Tok_Semicolon then
          last := self.current.position;
        end if;
        expect (self, context, Tok_Semicolon);
        if self.failed then
          return;
        end if;

        begin
          declaration :=
            Adac.Compilation.Syntax.create_access_object_type_declaration
              (context,
               defining_symbol,
               defining_span,
               modifier,
               designated_subtype,
               Adac.Source.make_span (first, last));
          Adac.Compilation.Syntax.validate_declaration (context, declaration);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            declaration := Adac.AST.INVALID_NODE_ID;
            Adac.Compilation.Diagnostics.error
              (context, first, "AST node limit exceeded");
        end;
      end;
      return;
    end if;

    if self.current.kind = Tok_Record then
      declare
        defining_symbol : Adac.Symbols.Symbol_ID := discriminated_symbol;
        components      : Adac.AST.Node_List;
        variant_part    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        if not has_discriminants then
          begin
            defining_symbol :=
              Adac.Compilation.Symbols.intern
                (context,
                 Ada.Strings.Unbounded.to_string (defining_spelling));
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, defining_position, "symbol limit exceeded");
              return;
          end;
        end if;

        expect (self, context, Tok_Record);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_End then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "record type has no represented components");
          return;
        end if;

        if self.current.kind = Tok_Null then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, self.current.position, "null records are not supported");
          return;
        end if;

        while not self.failed and then self.current.kind /= Tok_End loop
          if self.current.kind = Tok_Case then
            parse_record_variant_part_staging
              (self, context, variant_part);
            if self.failed then
              return;
            end if;
            exit;
          end if;

          declare
            component : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          begin
            parse_record_component_staging (self, context, component);
            if self.failed then
              return;
            end if;
            Adac.AST.append (components, component);
          end;
        end loop;

        expect (self, context, Tok_End);
        if self.failed then
          return;
        end if;
        expect (self, context, Tok_Record);
        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_With then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "record type aspects are not supported");
          return;
        end if;

        if self.current.kind = Tok_Semicolon then
          last := self.current.position;
        end if;
        expect (self, context, Tok_Semicolon);
        if self.failed then
          return;
        end if;

        begin
          declaration :=
            Adac.Compilation.Syntax.create_record_type_declaration
              (context,
               defining_symbol,
               defining_span,
               limited_form,
               discriminants,
               components,
               variant_part,
               Adac.Source.make_span (first, last));
          Adac.Compilation.Syntax.validate_declaration (context, declaration);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            declaration := Adac.AST.INVALID_NODE_ID;
            Adac.Compilation.Diagnostics.error
              (context, first, "AST node limit exceeded");
        end;
      end;
      return;
    end if;

    declare
    begin
      if self.current.kind /= Tok_Private then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "type declarations outside current represented subset " &
           "are not supported");
        return;
      end if;

      expect (self, context, Tok_Private);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_With then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "private type aspects are not supported");
        return;
      end if;

      if self.current.kind = Tok_Semicolon then
        last := self.current.position;
      end if;
      expect (self, context, Tok_Semicolon);
      if self.failed then
        return;
      end if;

      declare
        symbol : Adac.Symbols.Symbol_ID := discriminated_symbol;
      begin
        if not has_discriminants then
          begin
            symbol := Adac.Compilation.Symbols.intern
              (context, Ada.Strings.Unbounded.to_string (defining_spelling));
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, defining_position, "symbol limit exceeded");
              return;
          end;
        end if;

        begin
          declaration :=
            Adac.Compilation.Syntax.create_private_type_declaration
              (context,
               symbol,
               defining_span,
               discriminants,
               Adac.Source.make_span (first, last),
               limited_form);
          Adac.Compilation.Syntax.validate_declaration (context, declaration);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            declaration := Adac.AST.INVALID_NODE_ID;
            Adac.Compilation.Diagnostics.error
              (context, first, "AST node limit exceeded");
        end;
      end;
    end;
  end parse_type_declaration_staging;

  procedure parse_nested_procedure_type_declaration_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     declaration : out Adac.AST.Node_ID)
  is
  begin
    parse_type_declaration_staging (self, context, declaration);
    if self.failed then
      return;
    end if;

    case Adac.Compilation.Syntax.kind_of (context, declaration) is
      when Adac.AST.Enumeration_Type_Declaration_Node |
           Adac.AST.Record_Type_Declaration_Node =>
        null;

      when others =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position
             (Adac.Compilation.Syntax.node_span (context, declaration)),
           "nested procedure type declarations outside current " &
           "enumeration/record subset are not supported");
    end case;
  end parse_nested_procedure_type_declaration_staging;

  procedure parse_package_closing_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     components  : in out Parsed_Program_Unit_Name;
     last        : out Adac.Source.Position;
     require_eof : Boolean)
  is
  begin
    last := self.current.position;
    expect (self, context, Tok_End);

    if not self.failed and then
      (self.current.kind = Tok_Identifier or else
       self.current.kind = Tok_Invalid_Identifier)
    then
      parse_program_unit_name_staging (self, context, components);
    end if;

    if not self.failed and then self.current.kind = Tok_Semicolon then
      last := self.current.position;
    end if;
    expect (self, context, Tok_Semicolon);
    if require_eof then
      expect (self, context, Tok_EOF);
    end if;
  end parse_package_closing_staging;

  procedure parse_package_declaration_staging
    (self        : in out Parser;
     context     : in out Adac.Compilation.Context;
     first       : Adac.Source.Position;
     require_eof : Boolean;
     declaration : out Adac.AST.Node_ID;
     span        : out Adac.Source.Span)
  is separate;

  procedure parse_compilation_unit
    (self    : in out Parser;
     context : in out Adac.Compilation.Context)
  is separate;

  function parse_file
    (context : in out Adac.Compilation.Context;
     path    : String)
  return Adac.Frontend.Parse_Result is
    self    : Parser;
    file_id : constant Adac.Source.Source_File_ID
            := Adac.Compilation.Sources.register_file (context, path);
  begin
    Adac.Frontend.Lexer.open
      (self.scanner,
       path,
       file_id,
       Adac.Compilation.resource_limits
         (context).maximum_source_characters_per_file);
    advance (self, context);

    parse_compilation_unit (self, context);

    Adac.Frontend.Lexer.close (self.scanner);

    if self.failed or else self.had_recovered_context_error then
      return (status => Adac.Frontend.Parse_Rejected);
    end if;

    begin
      declare
        unit_item : Adac.AST.Node_ID := self.unit_item;
        root      : Adac.AST.Node_ID;
      begin
        if unit_item = Adac.AST.INVALID_NODE_ID then
          declare
            handlers     : Adac.AST.Node_List;
            first_statement : constant Adac.AST.Node_ID :=
              Adac.AST.list_element (self.statements, 1);
            last_statement : constant Adac.AST.Node_ID :=
              Adac.AST.list_element
                (self.statements, Adac.AST.list_count (self.statements));
            first_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, first_statement);
            last_span : constant Adac.Source.Span :=
              Adac.Compilation.Syntax.node_span (context, last_statement);
            handled_sequence : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.create_handled_sequence
                (context,
                 self.statements,
                 handlers,
                 Adac.Source.make_span
                   (Adac.Source.first_position (first_span),
                    Adac.Source.last_position (last_span)));
          begin
            unit_item :=
              Adac.Compilation.Syntax.create_procedure_body
                (context,
                 self.procedure_symbol,
                 self.parameters,
                 self.declarations,
                 handled_sequence,
                 self.end_symbol,
                 self.body_span);
          end;
        end if;

        root := Adac.Compilation.Syntax.create_compilation_unit
          (context, self.context_items, unit_item, self.unit_span);
        Adac.Compilation.Syntax.validate (context, root);
        return (status => Adac.Frontend.Parse_Succeeded,
                root   => root);
      end;
    exception
      when Adac.Resources.Limit_Exceeded =>
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position (self.unit_span),
           "AST node limit exceeded");
        return (status => Adac.Frontend.Parse_Rejected);
    end;
  exception
    when others =>
      begin
        Adac.Frontend.Lexer.close (self.scanner);
      exception
        when others =>
          null;
      end;

      raise;
  end parse_file;

end Adac.Frontend.Parser;
