-- ============================================================================
-- adac-frontend-parser-parse_nested_procedure_body_staging.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.Frontend.Parser)
procedure parse_nested_procedure_body_staging
  (self                     : in out Parser;
   context                  : in out Adac.Compilation.Context;
   syntax_node              : out Adac.AST.Node_ID;
   allow_declaration        : Boolean := False;
   allow_nested_subprograms : Boolean := True;
   allow_body_stub          : Boolean := False)
is
  first : constant Adac.Source.Position := self.current.position;

  defining_position  : Adac.Source.Position := self.current.position;
  defining_span      : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  procedure_symbol   : Adac.Symbols.Symbol_ID :=
    Adac.Symbols.INVALID_SYMBOL_ID;
  end_symbol         : Adac.Symbols.Symbol_ID :=
    Adac.Symbols.INVALID_SYMBOL_ID;
  parameters         : Adac.AST.Node_List;
  declarations       : Adac.AST.Node_List;
  handled_statements : Adac.AST.Node_List;
  handlers           : Adac.AST.Node_List;
  handled_sequence   : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  last               : Adac.Source.Position := first;

  procedure parse_current_package_instantiation
    (declaration : out Adac.AST.Node_ID)
  is
    package_first : constant Adac.Source.Position := self.current.position;
    defining_name : Parsed_Program_Unit_Name;
    item_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  begin
    declaration := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Package);
    if self.failed then
      return;
    end if;

    parse_program_unit_name_staging (self, context, defining_name);
    if self.failed then
      return;
    end if;

    expect (self, context, Tok_Is);
    if self.failed then
      return;
    end if;
    if self.current.kind /= Tok_New then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested procedure package declarations outside current " &
         "instantiation subset are not supported");
      return;
    end if;

    parse_package_instantiation_tail_common
      (self,
       context,
       package_first,
       defining_name,
       False,
       declaration,
       item_span);
  end parse_current_package_instantiation;

  procedure parse_current_block_prefix_staging
    (block_declarations : in out Adac.AST.Node_List)
  is
  begin
    if self.current.kind /= Tok_Declare and then
       self.current.kind /= Tok_Begin
    then
      raise Program_Error with
        "block prefix staging requires a declare or begin token";
    end if;

    if self.current.kind = Tok_Declare then
      expect (self, context, Tok_Declare);
      if self.failed then
        return;
      end if;

      while not self.failed and then
            (self.current.kind = Tok_Identifier or else
             self.current.kind = Tok_Invalid_Identifier)
      loop
        declare
          declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        begin
          parse_current_declaration_staging
            (self, context, declaration);
          if not self.failed and then
             declaration = Adac.AST.INVALID_NODE_ID
          then
            raise Program_Error with
              "block declarative part lost a declaration node";
          end if;
          if not self.failed then
            Adac.AST.append (block_declarations, declaration);
          end if;
        end;
      end loop;

      if self.failed then
        return;
      end if;
      if self.current.kind /= Tok_Begin then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "block statement declarative parts are not supported");
        return;
      end if;
    end if;

    expect (self, context, Tok_Begin);
  end parse_current_block_prefix_staging;

  procedure parse_current_case_header_staging
    (case_first           : out Adac.Source.Position;
     selecting_expression : out Adac.AST.Node_ID)
  is
  begin
    parse_current_case_header_common
      (self, context, case_first, selecting_expression);
  end parse_current_case_header_staging;

  procedure parse_current_case_and_block_closing
    (case_semicolon  : out Adac.Source.Position;
     block_semicolon : out Adac.Source.Position)
  is
    case_semicolon_value  : Adac.Source.Position := self.current.position;
    block_semicolon_value : Adac.Source.Position := self.current.position;
  begin
    parse_current_case_closing_common
      (self, context, case_semicolon_value);
    if self.failed then
      return;
    end if;
    expect (self, context, Tok_End);
    if self.failed then
      return;
    end if;
    block_semicolon_value := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;
    case_semicolon := case_semicolon_value;
    block_semicolon := block_semicolon_value;
  end parse_current_case_and_block_closing;

  procedure parse_current_case_alternative_header_staging
    (choice : out Adac.AST.Node_ID)
  is
    choices : Adac.AST.Node_List;
  begin
    choice := Adac.AST.INVALID_NODE_ID;
    parse_current_case_alternative_header_common
      (self,
       context,
       allow_multiple_choices => False,
       allow_others_choice    => False,
       choices                => choices);
    if self.failed then
      return;
    end if;
    if Adac.AST.list_count (choices) /= 1 then
      raise Program_Error with
        "narrow case alternative lost its single choice";
    end if;
    choice := Adac.AST.list_element (choices, 1);
  end parse_current_case_alternative_header_staging;

  procedure parse_current_case_call_or_simple_sequence
    (terminator : Token_Kind;
     statements : in out Adac.AST.Node_List)
  is
  begin
    parse_current_case_statement_sequence_common
      (self,
       context,
       exact_terminator           => terminator,
       stop_at_alternative_or_end => False,
       current_statement_subset   => False,
       statements                 => statements);
  end parse_current_case_call_or_simple_sequence;

  procedure publish_current_case_alternative
    (first       : Adac.Source.Position;
     choices     : Adac.AST.Node_List;
     statements  : Adac.AST.Node_List;
     alternative : out Adac.AST.Node_ID)
  is
  begin
    publish_current_case_alternative_common
      (self,
       context,
       first,
       choices,
       statements,
       alternative);
  end publish_current_case_alternative;

  procedure publish_current_case_statement
    (first                : Adac.Source.Position;
     selecting_expression : Adac.AST.Node_ID;
     alternatives         : Adac.AST.Node_List;
     semicolon            : Adac.Source.Position;
     statement            : out Adac.AST.Node_ID)
  is
  begin
    publish_current_case_statement_common
      (self,
       context,
       first,
       selecting_expression,
       alternatives,
       semicolon,
       statement);
  end publish_current_case_statement;

  procedure publish_current_block
    (block_first        : Adac.Source.Position;
     block_declarations : Adac.AST.Node_List;
     block_statements   : Adac.AST.Node_List;
     block_handlers     : Adac.AST.Node_List;
     sequence_span      : Adac.Source.Span;
     block_semicolon    : Adac.Source.Position;
     block_statement    : out Adac.AST.Node_ID)
  is
  begin
    publish_current_block_staging
      (self,
       context,
       block_first,
       block_declarations,
       block_statements,
       block_handlers,
       sequence_span,
       block_semicolon,
       block_statement);
  end publish_current_block;

  procedure publish_current_case_block
    (block_first        : Adac.Source.Position;
     block_declarations : Adac.AST.Node_List;
     case_statement     : Adac.AST.Node_ID;
     block_semicolon    : Adac.Source.Position;
     block_statement    : out Adac.AST.Node_ID)
  is
    block_statements : Adac.AST.Node_List;
    block_handlers   : Adac.AST.Node_List;
    case_span        : constant Adac.Source.Span :=
      Adac.Compilation.Syntax.node_span (context, case_statement);
  begin
    Adac.AST.append (block_statements, case_statement);
    publish_current_block
      (block_first,
       block_declarations,
       block_statements,
       block_handlers,
       case_span,
       block_semicolon,
       block_statement);
  end publish_current_case_block;

  procedure parse_current_block_staging
    (syntax_node : out Adac.AST.Node_ID)
  is
    block_first : constant Adac.Source.Position := self.current.position;
    block_declarations : Adac.AST.Node_List;
    selecting_expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    alternative_choice : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    first_alternative_choices : Adac.AST.Node_List;
    first_alternative_statements : Adac.AST.Node_List;
    second_alternative_choices : Adac.AST.Node_List;
    second_alternative_statements : Adac.AST.Node_List;
    case_alternatives : Adac.AST.Node_List;
    first_alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    second_alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    case_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    case_first : Adac.Source.Position := self.current.position;
    first_alternative_first : Adac.Source.Position := self.current.position;
    second_alternative_first : Adac.Source.Position := self.current.position;
    case_semicolon : Adac.Source.Position := self.current.position;
    block_semicolon : Adac.Source.Position := self.current.position;

  begin
    syntax_node := Adac.AST.INVALID_NODE_ID;
    parse_current_block_prefix_staging (block_declarations);
    if self.failed then
      return;
    end if;

    if self.current.kind /= Tok_Case then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "block statement bodies are not supported");
      return;
    end if;
    parse_current_case_header_staging
      (case_first, selecting_expression);
    if self.failed then
      return;
    end if;

    first_alternative_first := self.current.position;
    parse_current_case_alternative_header_staging (alternative_choice);
    if self.failed then
      return;
    end if;
    Adac.AST.append (first_alternative_choices, alternative_choice);

    parse_current_case_call_or_simple_sequence
      (Tok_When, first_alternative_statements);
    if self.failed then
      return;
    end if;

    second_alternative_first := self.current.position;
    parse_current_case_alternative_header_staging (alternative_choice);
    if self.failed then
      return;
    end if;
    Adac.AST.append (second_alternative_choices, alternative_choice);

    declare
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if self.current.kind /= Tok_Identifier and then
         self.current.kind /= Tok_Invalid_Identifier
      then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "case alternative statement sequences are not supported");
        return;
      end if;
      parse_current_procedure_call_statement_staging
        (self,
         context,
         publish_call_syntax => True,
         syntax_node         => statement);
      if self.failed then
        return;
      end if;
      if statement = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "second case alternative lost its procedure call syntax";
      end if;
      Adac.AST.append (second_alternative_statements, statement);
    end;

    declare
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if self.current.kind /= Tok_Identifier and then
         self.current.kind /= Tok_Invalid_Identifier
      then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "case alternative statement sequences are not supported");
        return;
      end if;
      parse_current_assignment_statement_staging
        (self, context, statement);
      if self.failed then
        return;
      end if;
      if statement = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "second case alternative lost its assignment syntax";
      end if;
      Adac.AST.append (second_alternative_statements, statement);
    end;

    parse_current_case_and_block_closing
      (case_semicolon, block_semicolon);
    if self.failed then
      return;
    end if;

    publish_current_case_alternative
      (first_alternative_first,
       first_alternative_choices,
       first_alternative_statements,
       first_alternative);
    if self.failed then
      return;
    end if;
    Adac.AST.append (case_alternatives, first_alternative);

    publish_current_case_alternative
      (second_alternative_first,
       second_alternative_choices,
       second_alternative_statements,
       second_alternative);
    if self.failed then
      return;
    end if;
    Adac.AST.append (case_alternatives, second_alternative);

    publish_current_case_statement
      (case_first,
       selecting_expression,
       case_alternatives,
       case_semicolon,
       case_statement);
    if self.failed then
      return;
    end if;

    publish_current_case_block
      (block_first,
       block_declarations,
       case_statement,
       block_semicolon,
       syntax_node);
  end parse_current_block_staging;

  procedure publish_current_procedure_body is
  begin
    if Adac.AST.list_count (handled_statements) = 0 then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested procedure statements are not supported");
      return;
    end if;
    if self.current.kind /= Tok_End then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested procedure body continuation is not supported");
      return;
    end if;

    begin
      declare
        first_statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (handled_statements, 1);
        last_statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element
            (handled_statements, Adac.AST.list_count (handled_statements));
        final_child : constant Adac.AST.Node_ID :=
          (if Adac.AST.list_count (handlers) = 0 then
             last_statement
           else
             Adac.AST.list_element
               (handlers, Adac.AST.list_count (handlers)));
        first_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, first_statement);
        final_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, final_child);
      begin
        handled_sequence :=
          Adac.Compilation.Syntax.create_handled_sequence
            (context,
             handled_statements,
             handlers,
             Adac.Source.make_span
               (Adac.Source.first_position (first_span),
                Adac.Source.last_position (final_span)));
        Adac.Compilation.Syntax.validate_handled_sequence
          (context, handled_sequence);
      end;
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
    if self.failed then
      return;
    end if;

    expect (self, context, Tok_End);
    if not self.failed and then
       (self.current.kind = Tok_Identifier or else
        self.current.kind = Tok_Invalid_Identifier)
    then
      end_symbol := parse_identifier_symbol (self, context);
    end if;
    if self.failed then
      return;
    end if;

    last := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;

    begin
      syntax_node := Adac.Compilation.Syntax.create_procedure_body
        (context,
         procedure_symbol,
         parameters,
         declarations,
         handled_sequence,
         end_symbol,
         Adac.Source.make_span (first, last));
      Adac.Compilation.Syntax.validate_procedure_body
        (context, syntax_node);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        syntax_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end publish_current_procedure_body;

  procedure complete_current_procedure_body is
  begin
    if Adac.AST.list_count (handled_statements) = 0 then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested procedure statements are not supported");
      return;
    end if;

    if self.current.kind = Tok_Exception then
      if Adac.AST.list_count (handlers) /= 0 then
        raise Program_Error with
          "nested procedure retained handlers before exception part";
      end if;
      parse_exception_handlers_staging
        (self,
         context,
         terminator             => Tok_End,
         completion_mode        => Return_After_Handler_Staging,
         publish_handler_syntax => True,
         handlers               => handlers);
      if self.failed then
        return;
      end if;
      if Adac.AST.list_count (handlers) = 0 then
        raise Program_Error with
          "nested procedure handler list lost represented syntax";
      end if;
    elsif self.current.kind /= Tok_End then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested procedure body continuation is not supported");
      return;
    end if;

    publish_current_procedure_body;
  end complete_current_procedure_body;

  procedure parse_current_block_body is
    block_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    parse_current_block_staging (block_statement);
    if self.failed then
      return;
    end if;
    if block_statement = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with "current block lost its statement syntax";
    end if;
    Adac.AST.append (handled_statements, block_statement);

    if self.current.kind = Tok_Identifier or else
       self.current.kind = Tok_Invalid_Identifier
    then
      declare
        statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        parse_current_procedure_call_statement_staging
          (self,
           context,
           publish_call_syntax => True,
           syntax_node         => statement);
        if not self.failed and then statement = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "post-block procedure call lost its statement syntax";
        end if;
        if not self.failed then
          Adac.AST.append (handled_statements, statement);
        end if;
      end;
    end if;

    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Declare then
      declare
        second_block_first : constant Adac.Source.Position :=
          self.current.position;
        second_block_declarations : Adac.AST.Node_List;
        second_case_first : Adac.Source.Position := self.current.position;
        second_selecting_expression : Adac.AST.Node_ID :=
          Adac.AST.INVALID_NODE_ID;
        first_alternative_first : Adac.Source.Position :=
          self.current.position;
        first_alternative_choice : Adac.AST.Node_ID :=
          Adac.AST.INVALID_NODE_ID;
        first_alternative_choices : Adac.AST.Node_List;
        first_alternative_statements : Adac.AST.Node_List;
        first_alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        second_alternative_first : Adac.Source.Position :=
          self.current.position;
        second_alternative_choice : Adac.AST.Node_ID :=
          Adac.AST.INVALID_NODE_ID;
        second_alternative_choices : Adac.AST.Node_List;
        second_alternative_statements : Adac.AST.Node_List;
        second_alternative : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        case_alternatives : Adac.AST.Node_List;
        second_case : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        second_block : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        case_semicolon : Adac.Source.Position := self.current.position;
        block_semicolon : Adac.Source.Position := self.current.position;
      begin
        parse_current_block_prefix_staging (second_block_declarations);
        if self.failed then
          return;
        end if;

        if self.current.kind /= Tok_Case then
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "block statement bodies are not supported");
          return;
        end if;

        parse_current_case_header_staging
          (second_case_first, second_selecting_expression);
        if self.failed then
          return;
        end if;
        if second_selecting_expression = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "second block case lost its selecting expression";
        end if;

        first_alternative_first := self.current.position;
        parse_current_case_alternative_header_staging
          (first_alternative_choice);
        if self.failed then
          return;
        end if;
        Adac.AST.append
          (first_alternative_choices, first_alternative_choice);

        parse_current_case_call_or_simple_sequence
          (Tok_When, first_alternative_statements);
        if self.failed then
          return;
        end if;

        publish_current_case_alternative
          (first_alternative_first,
           first_alternative_choices,
           first_alternative_statements,
           first_alternative);
        if self.failed then
          return;
        end if;
        if first_alternative = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "second block case lost its first alternative";
        end if;
        Adac.AST.append (case_alternatives, first_alternative);

        second_alternative_first := self.current.position;
        parse_current_case_alternative_header_staging
          (second_alternative_choice);
        if self.failed then
          return;
        end if;
        Adac.AST.append
          (second_alternative_choices, second_alternative_choice);

        parse_current_case_call_or_simple_sequence
          (Tok_End, second_alternative_statements);
        if self.failed then
          return;
        end if;

        parse_current_case_and_block_closing
          (case_semicolon, block_semicolon);
        if self.failed then
          return;
        end if;

        publish_current_case_alternative
          (second_alternative_first,
           second_alternative_choices,
           second_alternative_statements,
           second_alternative);
        if self.failed then
          return;
        end if;
        Adac.AST.append (case_alternatives, second_alternative);

        publish_current_case_statement
          (second_case_first,
           second_selecting_expression,
           case_alternatives,
           case_semicolon,
           second_case);
        if self.failed then
          return;
        end if;

        publish_current_case_block
          (second_block_first,
           second_block_declarations,
           second_case,
           block_semicolon,
           second_block);
        if self.failed then
          return;
        end if;
        if second_block = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "second block lost its statement syntax";
        end if;
        Adac.AST.append (handled_statements, second_block);

        while not self.failed and then
              (self.current.kind = Tok_Identifier or else
               self.current.kind = Tok_Invalid_Identifier)
        loop
          declare
            statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          begin
            parse_current_procedure_call_statement_staging
              (self,
               context,
               publish_call_syntax => True,
               syntax_node         => statement);
            if not self.failed and then
               statement = Adac.AST.INVALID_NODE_ID
            then
              raise Program_Error with
                "post-second-block call lost its statement syntax";
            end if;
            if not self.failed then
              Adac.AST.append (handled_statements, statement);
            end if;
          end;
        end loop;

        if self.failed then
          return;
        end if;

        if self.current.kind = Tok_End then
          complete_current_procedure_body;
          return;
        end if;
      end;
    end if;

    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context,
       self.current.position,
       "nested procedure body continuation is not supported");
  end parse_current_block_body;

  procedure parse_current_handler_free_statements is
    statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    while not self.failed and then
      (self.current.kind = Tok_Identifier or else
       self.current.kind = Tok_Invalid_Identifier or else
       self.current.kind = Tok_Case or else
       self.current.kind = Tok_If or else
       self.current.kind = Tok_Declare or else
       self.current.kind = Tok_Begin or else
       self.current.kind = Tok_For or else
       self.current.kind = Tok_While or else
       self.current.kind = Tok_Loop or else
       self.current.kind = Tok_Raise)
    loop
      statement := Adac.AST.INVALID_NODE_ID;
      case self.current.kind is
        when Tok_Identifier | Tok_Invalid_Identifier =>
          parse_current_identifier_statement_staging
            (self, context, statement);

        when Tok_Case =>
          parse_current_case_statement_staging
            (self, context, statement);

        when Tok_If =>
          parse_if_statement_staging
            (self, context, Return_After_If_Staging, statement);

        when Tok_Declare | Tok_Begin =>
          parse_current_block_statement_staging
            (self, context, statement);

        when Tok_For =>
          parse_current_for_loop_staging (self, context, statement);

        when Tok_While =>
          parse_current_while_loop_staging (self, context, statement);

        when Tok_Loop =>
          parse_current_simple_loop_staging (self, context, statement);

        when Tok_Raise =>
          parse_current_raise_statement_staging
            (self, context, statement, True);

        when others =>
          raise Program_Error with
            "handler-free statement dispatcher selected an invalid token";
      end case;

      if not self.failed then
        if statement = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "handler-free procedure statement lost represented syntax";
        end if;
        Adac.AST.append (handled_statements, statement);
      end if;
    end loop;
  end parse_current_handler_free_statements;

  procedure parse_handler_free_call_body is
  begin
    parse_current_handler_free_statements;
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Begin then
      declare
        outer_block_first : constant Adac.Source.Position :=
          self.current.position;
        block_declarations : Adac.AST.Node_List;
      begin
        parse_current_block_prefix_staging (block_declarations);
        if self.failed then
          return;
        end if;
        if Adac.AST.list_count (block_declarations) /= 0 then
          raise Program_Error with
            "bare block header published explicit declarations";
        end if;

        if self.current.kind = Tok_Declare then
          declare
            inner_block_first : constant Adac.Source.Position :=
              self.current.position;
            inner_block_declarations : Adac.AST.Node_List;
          begin
            parse_current_block_prefix_staging (inner_block_declarations);
            if self.failed then
              return;
            end if;
            if Adac.AST.list_count (inner_block_declarations) = 0 then
              raise Program_Error with
                "inner explicit block lost its declaration syntax";
            end if;

            if self.current.kind = Tok_Case then
              declare
                case_first : Adac.Source.Position := self.current.position;
                selecting_expression : Adac.AST.Node_ID :=
                  Adac.AST.INVALID_NODE_ID;
                first_alternative_first : Adac.Source.Position :=
                  self.current.position;
                first_alternative_choice : Adac.AST.Node_ID :=
                  Adac.AST.INVALID_NODE_ID;
                first_alternative_choices : Adac.AST.Node_List;
                first_alternative_statements : Adac.AST.Node_List;
                first_alternative : Adac.AST.Node_ID :=
                  Adac.AST.INVALID_NODE_ID;
                second_alternative_first : Adac.Source.Position :=
                  self.current.position;
                second_alternative_choice : Adac.AST.Node_ID :=
                  Adac.AST.INVALID_NODE_ID;
                second_alternative_choices : Adac.AST.Node_List;
                second_alternative_statements : Adac.AST.Node_List;
                second_alternative : Adac.AST.Node_ID :=
                  Adac.AST.INVALID_NODE_ID;
                case_alternatives : Adac.AST.Node_List;
                case_statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
                inner_block : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
                case_semicolon : Adac.Source.Position :=
                  self.current.position;
                block_semicolon : Adac.Source.Position :=
                  self.current.position;
              begin
                parse_current_case_header_staging
                  (case_first, selecting_expression);
                if self.failed then
                  return;
                end if;
                if selecting_expression = Adac.AST.INVALID_NODE_ID then
                  raise Program_Error with
                    "compile_file case lost its selecting expression";
                end if;

                first_alternative_first := self.current.position;
                parse_current_case_alternative_header_staging
                  (first_alternative_choice);
                if self.failed then
                  return;
                end if;
                Adac.AST.append
                  (first_alternative_choices, first_alternative_choice);

                parse_current_case_call_or_simple_sequence
                  (Tok_When, first_alternative_statements);
                if self.failed then
                  return;
                end if;

                publish_current_case_alternative
                  (first_alternative_first,
                   first_alternative_choices,
                   first_alternative_statements,
                   first_alternative);
                if self.failed then
                  return;
                end if;
                if first_alternative = Adac.AST.INVALID_NODE_ID then
                  raise Program_Error with
                    "compile_file case lost its first alternative";
                end if;
                Adac.AST.append (case_alternatives, first_alternative);

                second_alternative_first := self.current.position;
                parse_current_case_alternative_header_staging
                  (second_alternative_choice);
                if self.failed then
                  return;
                end if;
                Adac.AST.append
                  (second_alternative_choices, second_alternative_choice);

                parse_current_case_call_or_simple_sequence
                  (Tok_End, second_alternative_statements);
                if self.failed then
                  return;
                end if;

                parse_current_case_and_block_closing
                  (case_semicolon, block_semicolon);
                if self.failed then
                  return;
                end if;

                publish_current_case_alternative
                  (second_alternative_first,
                   second_alternative_choices,
                   second_alternative_statements,
                   second_alternative);
                if self.failed then
                  return;
                end if;
                Adac.AST.append (case_alternatives, second_alternative);

                publish_current_case_statement
                  (case_first,
                   selecting_expression,
                   case_alternatives,
                   case_semicolon,
                   case_statement);
                if self.failed then
                  return;
                end if;

                publish_current_case_block
                  (inner_block_first,
                   inner_block_declarations,
                   case_statement,
                   block_semicolon,
                   inner_block);
                if self.failed then
                  return;
                end if;
                if inner_block = Adac.AST.INVALID_NODE_ID then
                  raise Program_Error with
                    "compile_file inner block lost its statement syntax";
                end if;

                if self.current.kind = Tok_Exception then
                  declare
                    outer_statements : Adac.AST.Node_List;
                    outer_handlers   : Adac.AST.Node_List;
                    outer_block      : Adac.AST.Node_ID :=
                      Adac.AST.INVALID_NODE_ID;
                    outer_block_semicolon : Adac.Source.Position :=
                      self.current.position;
                  begin
                    parse_exception_handlers_staging
                      (self,
                       context,
                       terminator             => Tok_End,
                       completion_mode        => Return_After_Handler_Staging,
                       publish_handler_syntax => True,
                       handlers               => outer_handlers);
                    if self.failed then
                      return;
                    end if;
                    if Adac.AST.list_count (outer_handlers) = 0 then
                      raise Program_Error with
                        "compile_file block lost its exception handler";
                    end if;

                    expect (self, context, Tok_End);
                    if self.failed then
                      return;
                    end if;
                    outer_block_semicolon := self.current.position;
                    expect (self, context, Tok_Semicolon);
                    if self.failed then
                      return;
                    end if;

                    Adac.AST.append (outer_statements, inner_block);
                    declare
                      inner_span : constant Adac.Source.Span :=
                        Adac.Compilation.Syntax.node_span
                          (context, inner_block);
                      last_handler : constant Adac.AST.Node_ID :=
                        Adac.AST.list_element
                          (outer_handlers,
                           Adac.AST.list_count (outer_handlers));
                      handler_span : constant Adac.Source.Span :=
                        Adac.Compilation.Syntax.node_span
                          (context, last_handler);
                      sequence_span : constant Adac.Source.Span :=
                        Adac.Source.make_span
                          (Adac.Source.first_position (inner_span),
                           Adac.Source.last_position (handler_span));
                    begin
                      publish_current_block
                        (outer_block_first,
                         block_declarations,
                         outer_statements,
                         outer_handlers,
                         sequence_span,
                         outer_block_semicolon,
                         outer_block);
                    end;
                    if self.failed then
                      return;
                    end if;
                    if outer_block = Adac.AST.INVALID_NODE_ID then
                      raise Program_Error with
                        "compile_file outer block lost its statement syntax";
                    end if;
                    Adac.AST.append (handled_statements, outer_block);
                    complete_current_procedure_body;
                    return;
                  end;
                end if;
              end;
            end if;
          end;
        end if;

        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "block statement bodies are not supported");
        return;
      end;
    end if;

    complete_current_procedure_body;
  end parse_handler_free_call_body;

  procedure parse_declarative_nested_procedure_body
    (body_node : out Adac.AST.Node_ID)
  is
    type Procedure_Frame_State is
      (Parsing_Declarative_Part, Parsing_Statement_Part);

    type Procedure_Frame is record
      first            : Adac.Source.Position;
      procedure_symbol : Adac.Symbols.Symbol_ID :=
        Adac.Symbols.INVALID_SYMBOL_ID;
      parameters       : Adac.AST.Node_List;
      declarations     : Adac.AST.Node_List;
      statements       : Adac.AST.Node_List;
      handlers         : Adac.AST.Node_List;
      state            : Procedure_Frame_State := Parsing_Declarative_Part;
    end record;

    package Procedure_Frame_Vectors is new Ada.Containers.Vectors
      (Index_Type   => Positive,
       Element_Type => Procedure_Frame);

    frames : Procedure_Frame_Vectors.Vector;

    procedure replace_last_frame (frame : Procedure_Frame) is
    begin
      frames.replace_element (frames.last_index, frame);
    end replace_last_frame;

    procedure append_declaration (declaration : Adac.AST.Node_ID) is
      frame : Procedure_Frame := frames.last_element;
    begin
      if frame.state /= Parsing_Declarative_Part then
        raise Program_Error with
          "nested procedure declaration appended after begin";
      end if;
      if declaration = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "nested procedure lost a declarative child";
      end if;
      Adac.AST.append (frame.declarations, declaration);
      replace_last_frame (frame);
    end append_declaration;

    procedure append_statement (statement : Adac.AST.Node_ID) is
      frame : Procedure_Frame := frames.last_element;
    begin
      if frame.state /= Parsing_Statement_Part then
        raise Program_Error with
          "nested procedure statement appended before begin";
      end if;
      if statement = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "nested procedure lost a statement child";
      end if;
      Adac.AST.append (frame.statements, statement);
      replace_last_frame (frame);
    end append_statement;

    procedure push_frame is
      frame             : Procedure_Frame;
      defining_position : Adac.Source.Position := self.current.position;
      defining_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    begin
      if self.current.kind /= Tok_Procedure then
        raise Program_Error with
          "nested procedure frame requires a procedure token";
      end if;

      frame.first := self.current.position;
      expect (self, context, Tok_Procedure);
      if self.failed then
        return;
      end if;

      defining_position := self.current.position;
      if self.current.kind = Tok_Identifier then
        defining_span := make_token_span
          (defining_position, current_text (self));
      end if;
      frame.procedure_symbol := parse_identifier_symbol (self, context);
      if self.failed then
        return;
      end if;
      parse_current_formal_part_staging
        (self,
         context,
         frame.parameters,
         allow_default_expressions => True);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Semicolon then
        declare
          declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          semicolon   : constant Adac.Source.Position := self.current.position;
        begin
          expect (self, context, Tok_Semicolon);
          if self.failed then
            return;
          end if;

          begin
            declaration :=
              Adac.Compilation.Syntax.create_procedure_declaration
                (context,
                 frame.procedure_symbol,
                 defining_span,
                 frame.parameters,
                 Adac.Source.make_span (frame.first, semicolon));
            Adac.Compilation.Syntax.validate_declaration
              (context, declaration);
          exception
            when Adac.Resources.Limit_Exceeded =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context, frame.first, "AST node limit exceeded");
              return;
          end;

          if frames.is_empty then
            body_node := declaration;
          else
            append_declaration (declaration);
          end if;
        end;
        return;
      end if;

      expect (self, context, Tok_Is);
      if not self.failed then
        frames.append (frame);
      end if;
    end push_frame;

    procedure close_frame is
      frame : constant Procedure_Frame := frames.last_element;
      handled_sequence : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      end_symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
      last : Adac.Source.Position := self.current.position;
      completed : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if frame.state /= Parsing_Statement_Part then
        raise Program_Error with
          "nested procedure closed before begin";
      end if;
      if Adac.AST.list_count (frame.statements) = 0 then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "nested procedure statements are not supported");
        return;
      end if;

      declare
        first_statement : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (frame.statements, 1);
        first_span : constant Adac.Source.Span :=
          Adac.Compilation.Syntax.node_span (context, first_statement);
        sequence_last : Adac.Source.Position;
      begin
        if Adac.AST.list_count (frame.handlers) = 0 then
          declare
            last_statement : constant Adac.AST.Node_ID :=
              Adac.AST.list_element
                (frame.statements, Adac.AST.list_count (frame.statements));
          begin
            sequence_last := Adac.Source.last_position
              (Adac.Compilation.Syntax.node_span (context, last_statement));
          end;
        else
          declare
            last_handler : constant Adac.AST.Node_ID :=
              Adac.AST.list_element
                (frame.handlers, Adac.AST.list_count (frame.handlers));
          begin
            sequence_last := Adac.Source.last_position
              (Adac.Compilation.Syntax.node_span (context, last_handler));
          end;
        end if;

        begin
          handled_sequence :=
            Adac.Compilation.Syntax.create_handled_sequence
              (context,
               frame.statements,
               frame.handlers,
               Adac.Source.make_span
                 (Adac.Source.first_position (first_span), sequence_last));
          Adac.Compilation.Syntax.validate_handled_sequence
            (context, handled_sequence);
        exception
          when Adac.Resources.Limit_Exceeded =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context, frame.first, "AST node limit exceeded");
        end;
      end;
      if self.failed then
        return;
      end if;

      expect (self, context, Tok_End);
      if self.failed then
        return;
      end if;
      if self.current.kind = Tok_Identifier or else
         self.current.kind = Tok_Invalid_Identifier
      then
        end_symbol := parse_identifier_symbol (self, context);
      end if;
      if self.failed then
        return;
      end if;
      last := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed then
        return;
      end if;

      begin
        completed := Adac.Compilation.Syntax.create_procedure_body
          (context,
           frame.procedure_symbol,
           frame.parameters,
           frame.declarations,
           handled_sequence,
           end_symbol,
           Adac.Source.make_span (frame.first, last));
        Adac.Compilation.Syntax.validate_procedure_body (context, completed);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, frame.first, "AST node limit exceeded");
          return;
      end;

      frames.delete_last;
      if frames.is_empty then
        body_node := completed;
      else
        append_declaration (completed);
      end if;
    end close_frame;

  begin
    body_node := Adac.AST.INVALID_NODE_ID;
    push_frame;

    while not self.failed and then not frames.is_empty loop
      declare
        frame : Procedure_Frame := frames.last_element;
        child : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        case frame.state is
          when Parsing_Declarative_Part =>
            case self.current.kind is
              when Tok_Identifier | Tok_Invalid_Identifier =>
                parse_current_declaration_staging (self, context, child);
                if not self.failed then
                  append_declaration (child);
                end if;

              when Tok_Procedure =>
                push_frame;

              when Tok_Function =>
                parse_procedure_nested_function_body_staging
                  (self, context, child);
                if not self.failed then
                  append_declaration (child);
                end if;

              when Tok_Type =>
                parse_nested_procedure_type_declaration_staging
                  (self, context, child);
                if not self.failed then
                  append_declaration (child);
                end if;

              when Tok_Use =>
                parse_use_clause_staging (self, context, child);
                if not self.failed then
                  append_declaration (child);
                end if;

              when Tok_Package =>
                parse_current_package_instantiation (child);
                if not self.failed then
                  append_declaration (child);
                end if;

              when Tok_Begin =>
                expect (self, context, Tok_Begin);
                if not self.failed then
                  frame.state := Parsing_Statement_Part;
                  replace_last_frame (frame);
                end if;

              when others =>
                self.failed := True;
                Adac.Compilation.Diagnostics.error
                  (context,
                   self.current.position,
                   "nested procedure declarative parts are not supported");
            end case;

          when Parsing_Statement_Part =>
            case self.current.kind is
              when Tok_Identifier | Tok_Invalid_Identifier =>
                parse_current_identifier_statement_staging
                  (self, context, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_If =>
                parse_if_statement_staging
                  (self, context, Return_After_If_Staging, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_Declare | Tok_Begin =>
                parse_current_block_statement_staging (self, context, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_For =>
                parse_current_for_loop_staging (self, context, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_While =>
                parse_current_while_loop_staging (self, context, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_Loop =>
                parse_current_simple_loop_staging (self, context, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_Case =>
                parse_current_case_statement_staging (self, context, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_Null | Tok_Return =>
                parse_statement
                  (self, context, Return_Statement_Syntax, child);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_Raise =>
                parse_current_raise_statement_staging
                  (self, context, child, True);
                if not self.failed then
                  append_statement (child);
                end if;

              when Tok_Exception =>
                parse_exception_handlers_staging
                  (self,
                   context,
                   terminator             => Tok_End,
                   completion_mode        => Return_After_Handler_Staging,
                   publish_handler_syntax => True,
                   handlers               => frame.handlers);
                if not self.failed then
                  if Adac.AST.list_count (frame.handlers) = 0 then
                    raise Program_Error with
                      "nested procedure handler list lost represented syntax";
                  end if;
                  replace_last_frame (frame);
                  close_frame;
                end if;

              when Tok_End =>
                close_frame;

              when others =>
                self.failed := True;
                Adac.Compilation.Diagnostics.error
                  (context,
                   self.current.position,
                   "nested procedure body continuation is not supported");
            end case;
        end case;
      end;
    end loop;
  end parse_declarative_nested_procedure_body;

begin
  syntax_node := Adac.AST.INVALID_NODE_ID;
  if self.current.kind /= Tok_Procedure then
    raise Program_Error with
      "nested procedure staging requires a procedure token";
  end if;

  expect (self, context, Tok_Procedure);

  if self.failed then
    return;
  end if;

  defining_position := self.current.position;
  if self.current.kind = Tok_Identifier then
    defining_span := make_token_span
      (defining_position, current_text (self));
  end if;
  procedure_symbol := parse_identifier_symbol (self, context);

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

  if allow_declaration and then self.current.kind = Tok_Semicolon then
    last := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;

    begin
      syntax_node := Adac.Compilation.Syntax.create_procedure_declaration
        (context,
         procedure_symbol,
         defining_span,
         parameters,
         Adac.Source.make_span (first, last));
      Adac.Compilation.Syntax.validate_declaration (context, syntax_node);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        syntax_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
    return;
  end if;

  expect (self, context, Tok_Is);

  if self.failed then
    return;
  end if;

  if allow_body_stub and then self.current.kind = Tok_Separate then
    expect (self, context, Tok_Separate);
    if self.failed then
      return;
    end if;
    last := self.current.position;
    expect (self, context, Tok_Semicolon);
    if self.failed then
      return;
    end if;
    begin
      syntax_node := Adac.Compilation.Syntax.create_procedure_body_stub
        (context,
         procedure_symbol,
         defining_span,
         parameters,
         Adac.Source.make_span (first, last));
      Adac.Compilation.Syntax.validate_declaration (context, syntax_node);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        syntax_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
    return;
  end if;

  if self.current.kind = Tok_Begin then
    expect (self, context, Tok_Begin);

    if self.failed then
      return;
    end if;

    parse_handler_free_call_body;
    return;
  end if;

  if self.current.kind = Tok_Identifier or else
     self.current.kind = Tok_Invalid_Identifier or else
     self.current.kind = Tok_Type or else
     self.current.kind = Tok_Use or else
     self.current.kind = Tok_Package or else
     (allow_nested_subprograms and then
      (self.current.kind = Tok_Procedure or else
       self.current.kind = Tok_Function))
  then
    while not self.failed and then
          (self.current.kind = Tok_Identifier or else
           self.current.kind = Tok_Invalid_Identifier or else
           self.current.kind = Tok_Type or else
           self.current.kind = Tok_Use or else
           self.current.kind = Tok_Package or else
           (allow_nested_subprograms and then
            (self.current.kind = Tok_Procedure or else
             self.current.kind = Tok_Function)))
    loop
      declare
        declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      begin
        if self.current.kind = Tok_Procedure then
          parse_declarative_nested_procedure_body (declaration);
        elsif self.current.kind = Tok_Function then
          parse_procedure_nested_function_body_staging
            (self, context, declaration);
        elsif self.current.kind = Tok_Type then
          parse_nested_procedure_type_declaration_staging
            (self, context, declaration);
        elsif self.current.kind = Tok_Use then
          parse_use_clause_staging (self, context, declaration);
        elsif self.current.kind = Tok_Package then
          parse_current_package_instantiation (declaration);
        else
          parse_current_declaration_staging
            (self, context, declaration);
        end if;

        if not self.failed and then
           declaration = Adac.AST.INVALID_NODE_ID
        then
          raise Program_Error with
            "nested declarative part lost a declaration node";
        end if;
        if not self.failed then
          Adac.AST.append (declarations, declaration);
        end if;
      end;
    end loop;

    if self.failed then
      return;
    end if;

    if self.current.kind /= Tok_Begin then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         (if not allow_nested_subprograms and then
              (self.current.kind = Tok_Procedure or else
               self.current.kind = Tok_Function)
          then "nested procedure declarative subprograms are not supported"
          else "nested procedure declarative parts are not supported"));
      return;
    end if;

    expect (self, context, Tok_Begin);

    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_If then
      parse_current_handler_free_statements;
      if not self.failed then
        complete_current_procedure_body;
      end if;
    elsif self.current.kind = Tok_Identifier or else
          self.current.kind = Tok_Invalid_Identifier or else
          self.current.kind = Tok_Case or else
          self.current.kind = Tok_For or else
          self.current.kind = Tok_While or else
          self.current.kind = Tok_Loop or else
          self.current.kind = Tok_Raise
    then
      parse_current_handler_free_statements;

      if not self.failed then
        complete_current_procedure_body;
      end if;
    elsif self.current.kind = Tok_Declare or else
          self.current.kind = Tok_Begin
    then
      parse_current_block_body;
    else
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested procedure statements are not supported");
    end if;
    return;
  end if;

  self.failed := True;
  Adac.Compilation.Diagnostics.error
    (context, first, "nested procedure bodies are not supported");
end parse_nested_procedure_body_staging;
