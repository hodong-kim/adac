-- ============================================================================
-- adac-frontend-parser-parse_function_body_staging.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.Frontend.Parser)
procedure parse_function_body_staging
  (self        : in out Parser;
   context     : in out Adac.Compilation.Context;
   syntax_node : out Adac.AST.Node_ID;
   mode        : Function_Body_Staging_Mode := Ordinary_Function_Body)
is
  first            : constant Adac.Source.Position := self.current.position;
  function_symbol  : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
  function_defining_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  parameters       : Adac.AST.Node_List;
  result_subtype   : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  declarations     : Adac.AST.Node_List;
  statements       : Adac.AST.Node_List;
  handlers         : Adac.AST.Node_List;
  handled_sequence : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  saw_return       : Boolean := False;
  saw_nested_return : Boolean := False;
  end_symbol       : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
  last             : Adac.Source.Position := self.current.position;

  procedure reject_current (message : String) is
  begin
    self.failed := True;
    syntax_node := Adac.AST.INVALID_NODE_ID;
    Adac.Compilation.Diagnostics.error
      (context, self.current.position, message);
  end reject_current;

  function statement_tree_has_expression_return
    (statement : Adac.AST.Node_ID)
  return Boolean is
    pending : Adac.AST.Node_List;
    next    : Natural := 1;

    procedure append_handled_sequence (sequence : Adac.AST.Node_ID) is
    begin
      for index in 1 ..
        Adac.Compilation.Syntax.handled_sequence_statement_count
          (context, sequence)
      loop
        Adac.AST.append
          (pending,
           Adac.Compilation.Syntax.handled_sequence_statement_at
             (context, sequence, index));
      end loop;

      for handler_index in 1 ..
        Adac.Compilation.Syntax.handled_sequence_handler_count
          (context, sequence)
      loop
        declare
          handler : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.handled_sequence_handler_at
              (context, sequence, handler_index);
        begin
          for statement_index in 1 ..
            Adac.Compilation.Syntax.exception_handler_statement_count
              (context, handler)
          loop
            Adac.AST.append
              (pending,
               Adac.Compilation.Syntax.exception_handler_statement_at
                 (context, handler, statement_index));
          end loop;
        end;
      end loop;
    end append_handled_sequence;
  begin
    Adac.AST.append (pending, statement);
    while next <= Adac.AST.list_count (pending) loop
      declare
        current : constant Adac.AST.Node_ID :=
          Adac.AST.list_element (pending, next);
      begin
        case Adac.Compilation.Syntax.kind_of (context, current) is
          when Adac.AST.Return_Statement_Node =>
            if Adac.Compilation.Syntax.return_has_expression
              (context, current)
            then
              return True;
            end if;

          when Adac.AST.Extended_Return_Statement_Node =>
            return True;

          when Adac.AST.If_Statement_Node =>
            for index in 1 ..
              Adac.Compilation.Syntax.if_then_statement_count
                (context, current)
            loop
              Adac.AST.append
                (pending,
                 Adac.Compilation.Syntax.if_then_statement_at
                   (context, current, index));
            end loop;

            for part_index in 1 ..
              Adac.Compilation.Syntax.if_elsif_part_count (context, current)
            loop
              declare
                part : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.if_elsif_part_at
                    (context, current, part_index);
              begin
                for statement_index in 1 ..
                  Adac.Compilation.Syntax.elsif_statement_count
                    (context, part)
                loop
                  Adac.AST.append
                    (pending,
                     Adac.Compilation.Syntax.elsif_statement_at
                       (context, part, statement_index));
                end loop;
              end;
            end loop;

            for index in 1 ..
              Adac.Compilation.Syntax.if_else_statement_count
                (context, current)
            loop
              Adac.AST.append
                (pending,
                 Adac.Compilation.Syntax.if_else_statement_at
                   (context, current, index));
            end loop;

          when Adac.AST.Case_Statement_Node =>
            for alternative_index in 1 ..
              Adac.Compilation.Syntax.case_alternative_count (context, current)
            loop
              declare
                alternative : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.case_alternative_at
                    (context, current, alternative_index);
              begin
                for statement_index in 1 ..
                  Adac.Compilation.Syntax.case_alternative_statement_count
                    (context, alternative)
                loop
                  Adac.AST.append
                    (pending,
                     Adac.Compilation.Syntax.case_alternative_statement_at
                       (context, alternative, statement_index));
                end loop;
              end;
            end loop;

          when Adac.AST.Block_Statement_Node =>
            append_handled_sequence
              (Adac.Compilation.Syntax.block_handled_sequence
                 (context, current));

          when Adac.AST.Loop_Statement_Node =>
            for index in 1 ..
              Adac.Compilation.Syntax.loop_statement_count (context, current)
            loop
              Adac.AST.append
                (pending,
                 Adac.Compilation.Syntax.loop_statement_at
                   (context, current, index));
            end loop;

          when others =>
            null;
        end case;
      end;
      next := next + 1;
    end loop;

    return False;
  end statement_tree_has_expression_return;
begin
  syntax_node := Adac.AST.INVALID_NODE_ID;
  expect (self, context, Tok_Function);
  if self.failed then
    return;
  end if;

  declare
    defining_first : constant Adac.Source.Position := self.current.position;
    defining_text  : constant String := current_text (self);
  begin
    function_symbol := parse_identifier_symbol (self, context);
    function_defining_span := make_token_span (defining_first, defining_text);
  end;
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
  if mode = Function_Nested_Function_Body and then
     Adac.AST.list_count (parameters) /= 0
  then
    reject_current ("nested function parameters are not supported");
    return;
  end if;

  expect (self, context, Tok_Return);
  if self.failed then
    return;
  end if;

  if self.current.kind = Tok_Not or else self.current.kind = Tok_Access then
    reject_current
      ("function body null exclusions or access results are not supported");
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
    raise Program_Error with "function body lost its result subtype syntax";
  end if;

  if self.current.kind = Tok_With then
    reject_current ("function body aspects are not supported");
    return;
  end if;

  expect (self, context, Tok_Is);
  if self.failed then
    return;
  end if;

  if mode /= Function_Nested_Function_Body and then
     self.current.kind = Tok_Left_Parenthesis
  then
    declare
      expression : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      semicolon  : Adac.Source.Position;
    begin
      parse_expression_staging
        (self,
         context,
         terminator               => Tok_Semicolon,
         terminator_mode          => Require_Exact_Terminator,
         completion_mode          => Return_After_Staging,
         publish_expression_syntax => True,
         syntax_node              => expression,
         accept_relation_expression => True,
         accept_unary_expression    => True);
      if self.failed then
        return;
      end if;
      if expression = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "expression function lost represented expression";
      end if;

      semicolon := self.current.position;
      expect (self, context, Tok_Semicolon);
      if self.failed then
        return;
      end if;

      begin
        syntax_node :=
          Adac.Compilation.Syntax.create_function_declaration
            (context,
             function_symbol,
             function_defining_span,
             parameters,
             result_subtype,
             expression,
             Adac.AST.INVALID_NODE_ID,
             Adac.Source.make_span (first, semicolon));
        Adac.Compilation.Syntax.validate_declaration
          (context, syntax_node);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
      end;
      return;
    end;
  end if;

  if mode = Function_Nested_Function_Body and then
     self.current.kind /= Tok_Begin
  then
    reject_current
      ("nested function declarative parts are not supported");
    return;
  end if;

  while not self.failed and then
    (self.current.kind = Tok_Identifier or else
     self.current.kind = Tok_Invalid_Identifier or else
     self.current.kind = Tok_Procedure or else
     self.current.kind = Tok_Function)
  loop
    declare
      declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      case self.current.kind is
        when Tok_Procedure =>
          if mode = Function_Nested_Function_Body then
            reject_current
              ("nested function declarative parts are not supported");
          else
            parse_nested_procedure_body_staging
              (self,
               context,
               declaration,
               allow_declaration        => True,
               allow_nested_subprograms =>
                 mode /= Procedure_Nested_Function_Body);
          end if;

        when Tok_Function =>
          if mode = Procedure_Nested_Function_Body then
            reject_current
              ("procedure-owned function declarative subprograms are not " &
               "supported");
          elsif mode = Function_Nested_Function_Body then
            reject_current
              ("nested function declarative parts are not supported");
          else
            parse_function_body_staging
              (self,
               context,
               declaration,
               mode => Function_Nested_Function_Body);
          end if;

        when Tok_Identifier | Tok_Invalid_Identifier =>
          parse_current_declaration_staging
            (self,
             context,
             declaration             => declaration,
             represent_object        => True,
             represent_number        => True,
             allow_deferred_constant => True);

        when others =>
          raise Program_Error with
            "function declarative dispatcher selected an invalid token";
      end case;

      if not self.failed then
        if declaration = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "function body declarative item lost represented syntax";
        end if;
        if mode = Procedure_Nested_Function_Body then
          case Adac.Compilation.Syntax.kind_of (context, declaration) is
            when Adac.AST.Object_Declaration_Node |
                 Adac.AST.Procedure_Body_Node =>
              null;

            when others =>
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 Adac.Source.first_position
                   (Adac.Compilation.Syntax.node_span (context, declaration)),
                 "procedure-owned function declarative items outside current " &
                 "object/procedure-body subset are not supported");
              return;
          end case;
        end if;
        Adac.AST.append (declarations, declaration);
      end if;
    end;
  end loop;
  if self.failed then
    return;
  end if;

  if self.current.kind /= Tok_Begin then
    reject_current ("function body declarative parts are not supported");
    return;
  end if;
  expect (self, context, Tok_Begin);
  if self.failed then
    return;
  end if;
  if mode = Function_Nested_Function_Body and then
     self.current.kind /= Tok_Return
  then
    reject_current ("nested function statements are not supported");
    return;
  end if;

  while not self.failed and then
        self.current.kind /= Tok_End and then
        self.current.kind /= Tok_Exception
  loop
    if saw_return then
      reject_current
        ("function body statements after return are not supported");
      return;
    end if;

    declare
      statement : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      case self.current.kind is
        when Tok_Identifier | Tok_Invalid_Identifier =>
          parse_current_identifier_statement_staging
            (self, context, statement);

        when Tok_Null =>
          parse_statement
            (self,
             context,
             Return_Statement_Syntax,
             statement);

        when Tok_If =>
          parse_if_statement_staging
            (self, context, Return_After_If_Staging, statement);

        when Tok_Case =>
          parse_current_case_statement_staging (self, context, statement);

        when Tok_Declare | Tok_Begin =>
          parse_current_block_statement_staging (self, context, statement);

        when Tok_For =>
          parse_current_for_loop_staging (self, context, statement);

        when Tok_While =>
          parse_current_while_loop_staging (self, context, statement);

        when Tok_Loop =>
          parse_current_simple_loop_staging (self, context, statement);

        when Tok_Return =>
          parse_statement
            (self,
             context,
             Return_Statement_Syntax,
             statement,
             allow_return_expression_syntax => True);
          if not self.failed then
            if statement = Adac.AST.INVALID_NODE_ID then
              raise Program_Error with
                "function body lost its return statement syntax";
            end if;
            case Adac.Compilation.Syntax.kind_of (context, statement) is
              when Adac.AST.Return_Statement_Node =>
                if not Adac.Compilation.Syntax.return_has_expression
                  (context, statement)
                then
                  reject_current
                    ("function return statements require an expression");
                  return;
                end if;

              when Adac.AST.Extended_Return_Statement_Node =>
                if mode /= Ordinary_Function_Body then
                  reject_current
                    ("nested function extended returns are not supported");
                  return;
                end if;

              when others =>
                raise Program_Error with
                  "function return parser published a non-return statement";
            end case;
            saw_return := True;
          end if;

        when others =>
          reject_current ("function body statement is not supported");
      end case;

      if self.failed then
        return;
      end if;
      if statement = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with
          "function body statement sequence lost represented syntax";
      end if;
      if not saw_nested_return and then
         statement_tree_has_expression_return (statement)
      then
        saw_nested_return := True;
      end if;
      Adac.AST.append (statements, statement);
    end;
  end loop;

  if self.failed then
    return;
  end if;
  if Adac.AST.list_count (statements) = 0 or else
     (not saw_return and then not saw_nested_return)
  then
    reject_current ("function body requires an expression return");
    return;
  end if;

  if mode = Function_Nested_Function_Body and then
     self.current.kind = Tok_Exception
  then
    reject_current ("nested function exception handlers are not supported");
    return;
  end if;

  if self.current.kind = Tok_Exception then
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
        "function body handler list lost represented syntax";
    end if;
  end if;

  declare
    first_statement : constant Adac.AST.Node_ID :=
      Adac.AST.list_element (statements, 1);
    last_statement : constant Adac.AST.Node_ID :=
      Adac.AST.list_element (statements, Adac.AST.list_count (statements));
    final_child : constant Adac.AST.Node_ID :=
      (if Adac.AST.list_count (handlers) = 0 then
         last_statement
       else
         Adac.AST.list_element (handlers, Adac.AST.list_count (handlers)));
    handled_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.first_position
           (Adac.Compilation.Syntax.node_span (context, first_statement)),
         Adac.Source.last_position
           (Adac.Compilation.Syntax.node_span (context, final_child)));
  begin
    begin
      handled_sequence :=
        Adac.Compilation.Syntax.create_handled_sequence
          (context, statements, handlers, handled_span);
      Adac.Compilation.Syntax.validate_handled_sequence
        (context, handled_sequence);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           Adac.Source.first_position (handled_span),
           "AST node limit exceeded");
        return;
    end;
  end;

  expect (self, context, Tok_End);
  if self.failed then
    return;
  end if;

  if self.current.kind = Tok_Invalid_Identifier then
    report_invalid_identifier (self, context);
    return;
  elsif self.current.kind = Tok_Identifier then
    end_symbol := parse_identifier_symbol (self, context);
    if self.failed then
      return;
    end if;
  end if;

  if self.current.kind = Tok_Semicolon then
    last := self.current.position;
  end if;
  expect (self, context, Tok_Semicolon);
  if self.failed then
    return;
  end if;

  begin
    syntax_node :=
      Adac.Compilation.Syntax.create_function_body
        (context,
         function_symbol,
         parameters,
         result_subtype,
         declarations,
         handled_sequence,
         end_symbol,
         Adac.Source.make_span (first, last));
    Adac.Compilation.Syntax.validate_function_body (context, syntax_node);
  exception
    when Adac.Resources.Limit_Exceeded =>
      self.failed := True;
      syntax_node := Adac.AST.INVALID_NODE_ID;
      Adac.Compilation.Diagnostics.error
        (context, first, "AST node limit exceeded");
  end;
end parse_function_body_staging;
