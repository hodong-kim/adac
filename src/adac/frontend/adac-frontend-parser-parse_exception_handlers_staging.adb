-- ============================================================================
-- adac-frontend-parser-parse_exception_handlers_staging.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.Frontend.Parser)
procedure parse_exception_handlers_staging
  (self                   : in out Parser;
   context                : in out Adac.Compilation.Context;
   terminator             : Token_Kind;
   completion_mode        : Exception_Handler_Staging_Completion_Mode;
   publish_handler_syntax : Boolean;
   handlers               : in out Adac.AST.Node_List)
is
  first : constant Adac.Source.Position := self.current.position;

  procedure report_choice_expected is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "expected exception choice, got " &
       Token_Kind'image (self.current.kind) &
       " " & current_text (self));
  end report_choice_expected;

  function intern_preconsumed_identifier
    (position : Adac.Source.Position;
     spelling : String)
  return Adac.Symbols.Symbol_ID
  is
  begin
    return Adac.Compilation.Symbols.intern (context, spelling);
  exception
    when Adac.Resources.Limit_Exceeded =>
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context, position, "symbol limit exceeded");
      return Adac.Symbols.INVALID_SYMBOL_ID;
  end intern_preconsumed_identifier;

  procedure parse_preconsumed_selected_exception_name
    (first_position : Adac.Source.Position;
     first_spelling : String;
     publish_syntax : Boolean;
     syntax_node    : out Adac.AST.Node_ID)
  is
    first_symbol : constant Adac.Symbols.Symbol_ID :=
      intern_preconsumed_identifier (first_position, first_spelling);
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
  end parse_preconsumed_selected_exception_name;

  procedure parse_selected_exception_name
    (publish_syntax : Boolean;
     syntax_node    : out Adac.AST.Node_ID)
  is
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.failed then
      return;
    end if;
    if self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier
    then
      report_choice_expected;
      return;
    end if;
    parse_selected_identifier_name_staging
      (self, context, publish_syntax, syntax_node);
  end parse_selected_exception_name;

  procedure parse_current_exception_choice
    (publish_syntax : Boolean;
     syntax_node    : out Adac.AST.Node_ID)
  is
    choice_first : constant Adac.Source.Position := self.current.position;
  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    if self.current.kind = Tok_Others then
      declare
        choice_span : constant Adac.Source.Span :=
          make_token_span (choice_first, current_text (self));
      begin
        expect (self, context, Tok_Others);
        if not self.failed and then publish_syntax then
          begin
            syntax_node :=
              Adac.Compilation.Syntax.create_others_exception_choice
                (context, choice_span);
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, choice_first, "AST node limit exceeded");
          end;
        end if;
      end;
    else
      parse_selected_exception_name (publish_syntax, syntax_node);
    end if;
  end parse_current_exception_choice;

  procedure report_statement_sequence_unsupported is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "exception handler statement sequences are not supported");
  end report_statement_sequence_unsupported;

  procedure parse_current_exception_handler is
    handler_first          : constant Adac.Source.Position :=
      self.current.position;
    has_choice_parameter   : Boolean := False;
    has_named_choices      : Boolean := False;
    has_others_choice      : Boolean := False;
    choice_parameter_symbol : Adac.Symbols.Symbol_ID :=
      Adac.Symbols.INVALID_SYMBOL_ID;
    choice_parameter_span  : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    choices                : Adac.AST.Node_List;
    statements             : Adac.AST.Node_List;
    syntax_node            : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;

    procedure parse_parameterless_named_choice_body is
      saw_statement : Boolean := False;
    begin
      while not self.failed and then
            self.current.kind /= Tok_When and then
            self.current.kind /= terminator
      loop
        case self.current.kind is
          when Tok_Identifier =>
            parse_current_identifier_statement_staging
              (self,
               context,
               syntax_node,
               publish_syntax => publish_handler_syntax);

            if publish_handler_syntax and then not self.failed then
              if syntax_node = Adac.AST.INVALID_NODE_ID then
                raise Program_Error with
                  "exception handler identifier statement lost its node";
              end if;
              Adac.AST.append (statements, syntax_node);
            end if;

          when Tok_Invalid_Identifier =>
            report_invalid_identifier (self, context);

          when Tok_Raise =>
            if publish_handler_syntax then
              parse_current_raise_statement_staging
                (self, context, syntax_node, True, bare_only => True);
              if not self.failed then
                if syntax_node = Adac.AST.INVALID_NODE_ID then
                  raise Program_Error with
                    "exception handler bare raise lost its statement node";
                end if;
                Adac.AST.append (statements, syntax_node);
              end if;
            else
              parse_current_raise_statement_staging
                (self, context, syntax_node, False, bare_only => True);
            end if;

          when Tok_Null | Tok_Return =>
            if publish_handler_syntax then
              parse_statement
                (self,
                 context,
                 Return_Statement_Syntax,
                 syntax_node,
                 allow_return_expression_syntax =>
                   self.current.kind = Tok_Return);
              if not self.failed then
                if syntax_node = Adac.AST.INVALID_NODE_ID then
                  raise Program_Error with
                    "exception handler lost its body statement";
                end if;
                Adac.AST.append (statements, syntax_node);
              end if;
            else
              parse_statement (self, context, Skip_Statement_Publication);
            end if;

          when others =>
            report_statement_sequence_unsupported;
        end case;

        if self.failed then
          return;
        end if;
        saw_statement := True;
      end loop;

      if not saw_statement then
        report_expected (self, context, Tok_Null);
      end if;
    end parse_parameterless_named_choice_body;

    procedure parse_parameterless_others_body is
      saw_call : Boolean := False;
    begin
      if self.current.kind = Tok_Begin then
        if not publish_handler_syntax then
          report_statement_sequence_unsupported;
          return;
        end if;
        parse_compound_statement_staging
          (self,
           context,
           root_token      => Tok_Begin,
           completion_mode => Return_After_If_Staging,
           syntax_node     => syntax_node);
        if self.failed then
          return;
        end if;
        if syntax_node = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "exception handler block lost its statement node";
        end if;
        Adac.AST.append (statements, syntax_node);

        if self.current.kind /= Tok_Raise then
          report_statement_sequence_unsupported;
          return;
        end if;
        parse_current_raise_statement_staging
          (self,
           context,
           syntax_node,
           publish_handler_syntax,
           bare_only => True);
        if not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "exception handler bare raise lost its statement node";
          end if;
          Adac.AST.append (statements, syntax_node);
        end if;
        return;
      end if;

      while not self.failed and then
            (self.current.kind = Tok_Identifier or else
             self.current.kind = Tok_Invalid_Identifier)
      loop
        if self.current.kind = Tok_Invalid_Identifier then
          report_invalid_identifier (self, context);
          return;
        end if;

        parse_current_procedure_call_statement_staging
          (self,
           context,
           publish_call_syntax => publish_handler_syntax,
           syntax_node         => syntax_node);
        if publish_handler_syntax and then not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "exception handler call lost its statement node";
          end if;
          Adac.AST.append (statements, syntax_node);
        end if;
        saw_call := True;
      end loop;

      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Raise then
        parse_current_raise_statement_staging
          (self,
           context,
           syntax_node,
           publish_handler_syntax,
           bare_only => True);
        if publish_handler_syntax and then not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "exception handler bare raise lost its statement node";
          end if;
          Adac.AST.append (statements, syntax_node);
        end if;
        return;
      end if;

      if saw_call then
        report_statement_sequence_unsupported;
        return;
      end if;

      if self.current.kind /= Tok_Null then
        if starts_statement (self.current.kind) then
          report_statement_sequence_unsupported;
        else
          report_expected (self, context, Tok_Null);
        end if;
        return;
      end if;

      if publish_handler_syntax then
        parse_statement
          (self, context, Return_Statement_Syntax, syntax_node);
        if not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "exception handler lost its body statement";
          end if;
          Adac.AST.append (statements, syntax_node);
        end if;
      else
        parse_statement (self, context, Skip_Statement_Publication);
      end if;
    end parse_parameterless_others_body;
  begin
    if self.current.kind /= Tok_When then
      raise Program_Error with
        "exception handler staging requires a when token";
    end if;

    expect (self, context, Tok_When);
    if self.failed then
      return;
    end if;

    case self.current.kind is
      when Tok_Others =>
        has_others_choice := True;
        parse_current_exception_choice
          (publish_handler_syntax, syntax_node);
        if publish_handler_syntax and then not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with "exception choice lost its syntax";
          end if;
          Adac.AST.append (choices, syntax_node);
        end if;

      when Tok_Invalid_Identifier =>
        report_invalid_identifier (self, context);
        return;

      when Tok_Identifier =>
        declare
          first_position : constant Adac.Source.Position :=
            self.current.position;
          first_spelling : constant String := current_text (self);
          defining_span : constant Adac.Source.Span :=
            make_token_span (first_position, first_spelling);
        begin
          parse_unpublished_identifier (self, context);
          if self.failed then
            return;
          end if;

          if self.current.kind = Tok_Colon then
            if publish_handler_syntax then
              choice_parameter_symbol :=
                intern_preconsumed_identifier
                  (first_position, first_spelling);
              if self.failed then
                return;
              end if;
              choice_parameter_span := defining_span;
            end if;

            expect (self, context, Tok_Colon);
            if self.failed then
              return;
            end if;

            has_choice_parameter := True;
            loop
              parse_current_exception_choice
                (publish_handler_syntax, syntax_node);
              if self.failed then
                return;
              end if;
              if publish_handler_syntax then
                if syntax_node = Adac.AST.INVALID_NODE_ID then
                  raise Program_Error with
                    "exception choice lost its syntax";
                end if;
                Adac.AST.append (choices, syntax_node);
              end if;
              exit when self.current.kind /= Tok_Vertical_Bar;
              expect (self, context, Tok_Vertical_Bar);
              if self.failed then
                return;
              end if;
            end loop;
          else
            has_named_choices := True;
            parse_preconsumed_selected_exception_name
              (first_position,
               first_spelling,
               publish_handler_syntax,
               syntax_node);
            if self.failed then
              return;
            end if;
            if publish_handler_syntax then
              if syntax_node = Adac.AST.INVALID_NODE_ID then
                raise Program_Error with
                  "exception choice lost its syntax";
              end if;
              Adac.AST.append (choices, syntax_node);
            end if;

            while self.current.kind = Tok_Vertical_Bar loop
              expect (self, context, Tok_Vertical_Bar);
              if self.failed then
                return;
              end if;
              parse_current_exception_choice
                (publish_handler_syntax, syntax_node);
              if self.failed then
                return;
              end if;
              if publish_handler_syntax then
                if syntax_node = Adac.AST.INVALID_NODE_ID then
                  raise Program_Error with
                    "exception choice lost its syntax";
                end if;
                Adac.AST.append (choices, syntax_node);
              end if;
            end loop;
          end if;
        end;

      when others =>
        report_choice_expected;
        return;
    end case;

    expect (self, context, Tok_Arrow);
    if self.failed then
      return;
    end if;

    if has_named_choices then
      parse_parameterless_named_choice_body;
      if self.failed then
        return;
      end if;
    elsif has_others_choice then
      parse_parameterless_others_body;
      if self.failed then
        return;
      end if;
    elsif has_choice_parameter and then self.current.kind = Tok_Return then
      if publish_handler_syntax then
        parse_statement
          (self,
           context,
           Return_Statement_Syntax,
           syntax_node,
           allow_return_expression_syntax => True);
        if not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "exception handler return lost its statement node";
          end if;
          Adac.AST.append (statements, syntax_node);
        end if;
      else
        parse_statement (self, context, Skip_Statement_Publication);
      end if;
      if self.failed then
        return;
      end if;
    elsif has_choice_parameter and then
       (self.current.kind = Tok_Identifier or else
        self.current.kind = Tok_Invalid_Identifier)
    then
      while not self.failed and then
            (self.current.kind = Tok_Identifier or else
             self.current.kind = Tok_Invalid_Identifier)
      loop
        parse_current_procedure_call_statement_staging
          (self,
           context,
           publish_call_syntax => publish_handler_syntax,
           syntax_node         => syntax_node);
        if publish_handler_syntax and then not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "exception handler call lost its statement node";
          end if;
          Adac.AST.append (statements, syntax_node);
        end if;
      end loop;
      if self.failed then
        return;
      end if;
    else
      if self.current.kind = Tok_Invalid_Identifier then
        report_invalid_identifier (self, context);
        return;
      end if;
      if self.current.kind /= Tok_Null then
        if self.current.kind = Tok_Identifier or else
           starts_statement (self.current.kind)
        then
          report_statement_sequence_unsupported;
        else
          report_expected (self, context, Tok_Null);
        end if;
        return;
      end if;

      if publish_handler_syntax then
        parse_statement
          (self, context, Return_Statement_Syntax, syntax_node);
        if not self.failed then
          if syntax_node = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "exception handler lost its body statement";
          end if;
          Adac.AST.append (statements, syntax_node);
        end if;
      else
        parse_statement (self, context, Skip_Statement_Publication);
      end if;
      if self.failed then
        return;
      end if;
    end if;

    if self.current.kind = Tok_Invalid_Identifier then
      report_invalid_identifier (self, context);
      return;
    end if;
    if self.current.kind = Tok_Identifier or else
       starts_statement (self.current.kind)
    then
      report_statement_sequence_unsupported;
    end if;
    if self.failed or else not publish_handler_syntax then
      return;
    end if;

    if Adac.AST.list_count (choices) = 0 or else
       Adac.AST.list_count (statements) = 0
    then
      raise Program_Error with "exception handler lost represented children";
    end if;

    begin
      declare
        last_statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element
            (statements, Adac.AST.list_count (statements));
        body_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, last_statement);
        handler : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_exception_handler
            (context,
             choice_parameter_symbol,
             choice_parameter_span,
             choices,
             statements,
             Adac.Source.make_span
               (handler_first, Adac.Source.last_position (body_span)));
      begin
        Adac.Compilation.Syntax.validate_exception_handler
          (context, handler);
        Adac.AST.append (handlers, handler);
      end;
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context, handler_first, "AST node limit exceeded");
    end;
  end parse_current_exception_handler;

begin
  if self.current.kind /= Tok_Exception then
    raise Program_Error with
      "exception handler staging requires an exception token";
  end if;

  expect (self, context, Tok_Exception);

  if self.failed then
    return;
  end if;

  if self.current.kind /= Tok_When then
    report_expected (self, context, Tok_When);
    return;
  end if;

  while not self.failed and then self.current.kind = Tok_When loop
    parse_current_exception_handler;
  end loop;

  if self.failed then
    return;
  end if;

  if self.current.kind /= terminator then
    report_expected (self, context, terminator);
    return;
  end if;

  if completion_mode = Reject_Unsupported_Handlers then
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context, first, "exception handlers are not supported");
  end if;
end parse_exception_handlers_staging;
