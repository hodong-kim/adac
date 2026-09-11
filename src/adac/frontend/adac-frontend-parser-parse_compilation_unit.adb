-- ============================================================================
-- adac-frontend-parser-parse_compilation_unit.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.Frontend.Parser)
procedure parse_compilation_unit
  (self    : in out Parser;
   context : in out Adac.Compilation.Context)
is
  unit_first : constant Adac.Source.Position := self.current.position;
  body_first : Adac.Source.Position := self.current.position;
  last       : Adac.Source.Position;
  had_recovered_statement_error : Boolean := False;

  procedure parse_package_body_stub_after_package
    (first : Adac.Source.Position;
     stub  : out Adac.AST.Node_ID)
  is
    symbol        : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    defining_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    last          : Adac.Source.Position := first;
  begin
    stub := Adac.AST.INVALID_NODE_ID;
    expect (self, context, Tok_Body);
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

    defining_span :=
      make_token_span (self.current.position, current_text (self));
    symbol := parse_identifier_symbol (self, context);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Dot then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested package bodies are not supported");
      return;
    end if;

    expect (self, context, Tok_Is);
    if self.failed then
      return;
    end if;

    if self.current.kind /= Tok_Separate then
      self.failed := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "nested package bodies are not supported");
      return;
    end if;
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
      stub := Adac.Compilation.Syntax.create_package_body_stub
        (context,
         symbol,
         defining_span,
         Adac.Source.make_span (first, last));
      Adac.Compilation.Syntax.validate_package_body_stub (context, stub);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        stub := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_package_body_stub_after_package;

  procedure parse_package_body_after_package
    (first       : Adac.Source.Position;
     require_eof : Boolean;
     package_node : out Adac.AST.Node_ID;
     package_span : out Adac.Source.Span)
  is
    parsed_defining_name : Parsed_Program_Unit_Name;
    parsed_end_name      : Parsed_Program_Unit_Name;
    defining_name        : Adac.AST.Program_Unit_Name;
    end_name             : Adac.AST.Program_Unit_Name;
    body_declarations    : Adac.AST.Node_List;
    body_last            : Adac.Source.Position := first;
    had_recovered_declarative_error : Boolean := False;

    procedure recover_misplaced_simple_statement is
    begin
      had_recovered_declarative_error := True;
      Adac.Compilation.Diagnostics.error
        (context,
         self.current.position,
         "statement is not allowed in package body declarative part");

      while not self.failed and then
        self.current.kind /= Tok_Semicolon and then
        self.current.kind /= Tok_End and then
        self.current.kind /= Tok_EOF
      loop
        advance (self, context);
      end loop;

      if not self.failed and then self.current.kind = Tok_Semicolon then
        advance (self, context);
      elsif not self.failed and then self.current.kind = Tok_EOF then
        self.failed := True;
      end if;
    end recover_misplaced_simple_statement;
  begin
    package_node := Adac.AST.INVALID_NODE_ID;
    package_span := Adac.Source.INVALID_SPAN;

    if self.current.kind /= Tok_Body then
      raise Program_Error with
        "package-body staging requires a body token";
    end if;
    expect (self, context, Tok_Body);
    parse_program_unit_name_staging (self, context, parsed_defining_name);
    expect (self, context, Tok_Is);
    if self.failed then
      return;
    end if;

    while not self.failed and then self.current.kind /= Tok_End loop
      declare
        item           : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
        item_span      : Adac.Source.Span := Adac.Source.INVALID_SPAN;
        recovered_item : Boolean := False;
      begin
        case self.current.kind is
          when Tok_Procedure =>
            parse_nested_procedure_body_staging
              (self,
               context,
               item,
               allow_declaration => True,
               allow_body_stub   => True);

          when Tok_Package =>
            declare
              item_first : constant Adac.Source.Position :=
                self.current.position;
            begin
              expect (self, context, Tok_Package);
              if not self.failed then
                if self.current.kind = Tok_Body then
                  parse_package_body_stub_after_package (item_first, item);
                else
                  parse_package_declaration_staging
                    (self,
                     context,
                     item_first,
                     require_eof => False,
                     declaration => item,
                     span        => item_span);
                end if;
              end if;
            end;

          when Tok_Type =>
            parse_type_declaration_staging (self, context, item);

          when Tok_Subtype =>
            parse_subtype_declaration_staging (self, context, item);

          when Tok_Identifier | Tok_Invalid_Identifier =>
            parse_current_declaration_staging
              (self,
               context,
               declaration             => item,
               represent_object        => True,
               represent_number        => True,
               allow_deferred_constant => True);

          when Tok_Function =>
            parse_function_body_staging (self, context, item);

          when Tok_Use =>
            parse_use_clause_staging (self, context, item);

          when Tok_Null | Tok_Return =>
            recovered_item := True;
            recover_misplaced_simple_statement;

          when others =>
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               self.current.position,
               "package body declarative item is not supported");
        end case;

        if not self.failed and then not recovered_item then
          if item = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "package body declarative item lost represented syntax";
          end if;
          Adac.AST.append (body_declarations, item);
        end if;
      end;
    end loop;

    if self.failed then
      return;
    end if;

    parse_package_closing_staging
      (self,
       context,
       parsed_end_name,
       body_last,
       require_eof => require_eof);
    if self.failed then
      return;
    end if;

    if had_recovered_declarative_error then
      self.failed := True;
      return;
    end if;

    publish_program_unit_name
      (self, context, parsed_defining_name, defining_name);
    if self.failed then
      return;
    end if;
    publish_program_unit_name (self, context, parsed_end_name, end_name);
    if self.failed then
      return;
    end if;

    package_span := Adac.Source.make_span (first, body_last);
    begin
      package_node :=
        Adac.Compilation.Syntax.create_package_body
          (context,
           defining_name,
           body_declarations,
           end_name,
           package_span);
      Adac.Compilation.Syntax.validate_package_body (context, package_node);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        package_node := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, first, "AST node limit exceeded");
    end;
  end parse_package_body_after_package;

begin
  if self.current.kind = Tok_With then
    parse_context_clause (self, context);
    if self.failed then
      return;
    end if;
    if self.had_recovered_context_error and then
       self.current.kind = Tok_EOF
    then
      self.failed := True;
      return;
    end if;
  end if;

  body_first := self.current.position;

  if self.current.kind = Tok_Separate then
    declare
      subunit_first : constant Adac.Source.Position :=
        self.current.position;
      parsed_parent_name : Parsed_Program_Unit_Name;
      parent_name        : Adac.AST.Program_Unit_Name;
      proper_body        : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      proper_span        : Adac.Source.Span := Adac.Source.INVALID_SPAN;
      subunit_node       : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      subunit_span       : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    begin
      expect (self, context, Tok_Separate);
      expect (self, context, Tok_Left_Parenthesis);
      if not self.failed then
        parse_program_unit_name_staging (self, context, parsed_parent_name);
      end if;
      expect (self, context, Tok_Right_Parenthesis);
      if self.failed then
        return;
      end if;

      publish_program_unit_name
        (self, context, parsed_parent_name, parent_name);
      if self.failed then
        return;
      end if;

      case self.current.kind is
        when Tok_Package =>
          declare
            proper_first : constant Adac.Source.Position :=
              self.current.position;
          begin
            expect (self, context, Tok_Package);
            if self.failed then
              return;
            end if;
            if self.current.kind /= Tok_Body then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "subunit proper body must be a package body");
              return;
            end if;
            parse_package_body_after_package
              (proper_first, True, proper_body, proper_span);
          end;

        when Tok_Procedure =>
          parse_nested_procedure_body_staging
            (self, context, proper_body);
          if not self.failed and then
             proper_body = Adac.AST.INVALID_NODE_ID
          then
            raise Program_Error with
              "subunit procedure proper body lost represented syntax";
          end if;
          if not self.failed then
            proper_span :=
              Adac.Compilation.Syntax.node_span (context, proper_body);
            expect (self, context, Tok_EOF);
          end if;

        when others =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context,
             self.current.position,
             "subunit proper bodies outside current package/procedure " &
               "subset are not supported");
          return;
      end case;

      if self.failed then
        return;
      end if;

      subunit_span :=
        Adac.Source.make_span
          (subunit_first, Adac.Source.last_position (proper_span));
      begin
        subunit_node :=
          Adac.Compilation.Syntax.create_subunit
            (context, parent_name, proper_body, subunit_span);
        Adac.Compilation.Syntax.validate_subunit (context, subunit_node);
      exception
        when Adac.Resources.Limit_Exceeded =>
          self.failed := True;
          Adac.Compilation.Diagnostics.error
            (context, subunit_first, "AST node limit exceeded");
          return;
      end;

      self.unit_item := subunit_node;
      self.body_span := proper_span;
      self.unit_span :=
        Adac.Source.make_span
          (unit_first, Adac.Source.last_position (subunit_span));
    end;
    return;
  end if;

  if self.current.kind = Tok_Package then
    declare
      package_node : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      package_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    begin
      expect (self, context, Tok_Package);
      if self.failed then
        return;
      end if;

      if self.current.kind = Tok_Body then
        parse_package_body_after_package
          (body_first, True, package_node, package_span);
      else
        parse_package_declaration_staging
          (self,
           context,
           body_first,
           require_eof => True,
           declaration => package_node,
           span        => package_span);
      end if;

      if not self.failed then
        self.unit_item := package_node;
        self.body_span := package_span;
        self.unit_span :=
          Adac.Source.make_span
            (unit_first, Adac.Source.last_position (package_span));
      end if;
    end;
    return;
  end if;

  expect (self, context, Tok_Procedure);

  self.procedure_symbol := parse_identifier_symbol (self, context);
  expect (self, context, Tok_Is);

  if not self.failed and then self.current.kind = Tok_Procedure then
    declare
      nested_body        : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      outer_statement    : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      outer_handled      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      outer_body         : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
      outer_end_symbol   : Adac.Symbols.Symbol_ID :=
        Adac.Symbols.INVALID_SYMBOL_ID;
      outer_declarations : Adac.AST.Node_List;
      outer_statements   : Adac.AST.Node_List;
      outer_handlers     : Adac.AST.Node_List;
    begin
      parse_nested_procedure_body_staging (self, context, nested_body);
      if not self.failed and then nested_body = Adac.AST.INVALID_NODE_ID then
        raise Program_Error with "nested procedure lost its body node";
      end if;
      if not self.failed then
        Adac.AST.append (outer_declarations, nested_body);
      end if;

      if not self.failed and then self.current.kind = Tok_Begin then
        declare
          body_begin : constant Adac.Source.Position :=
            self.current.position;
        begin
          expect (self, context, Tok_Begin);

          if not self.failed and then
             (self.current.kind = Tok_Identifier or else
              self.current.kind = Tok_Invalid_Identifier)
          then
            parse_current_procedure_call_statement_staging
              (self,
               context,
               publish_call_syntax => True,
               syntax_node         => outer_statement);

            if not self.failed and then
               outer_statement = Adac.AST.INVALID_NODE_ID
            then
              raise Program_Error with
                "outer procedure call lost its statement node";
            end if;
            if not self.failed then
              Adac.AST.append (outer_statements, outer_statement);
            end if;

            if not self.failed and then self.current.kind = Tok_Exception then
              parse_exception_handlers_staging
                (self,
                 context,
                 terminator             => Tok_End,
                 completion_mode        => Return_After_Handler_Staging,
                 publish_handler_syntax => True,
                 handlers               => outer_handlers);

              if not self.failed and then
                 Adac.AST.list_count (outer_handlers) = 0
              then
                raise Program_Error with
                  "outer handler list lost its syntax";
              end if;

              if not self.failed then
                begin
                  declare
                    first_span : constant Adac.Source.Span :=
                      Adac.Compilation.Syntax.node_span
                        (context, outer_statement);
                    last_handler : constant Adac.AST.Node_ID :=
                      Adac.AST.list_element
                        (outer_handlers,
                         Adac.AST.list_count (outer_handlers));
                    last_span : constant Adac.Source.Span :=
                      Adac.Compilation.Syntax.node_span
                        (context, last_handler);
                  begin
                    outer_handled :=
                      Adac.Compilation.Syntax.create_handled_sequence
                        (context,
                         outer_statements,
                         outer_handlers,
                         Adac.Source.make_span
                           (Adac.Source.first_position (first_span),
                            Adac.Source.last_position (last_span)));
                    Adac.Compilation.Syntax.validate_handled_sequence
                      (context, outer_handled);
                  end;
                exception
                  when Adac.Resources.Limit_Exceeded =>
                    self.failed := True;
                    Adac.Compilation.Diagnostics.error
                      (context, body_begin, "AST node limit exceeded");
                end;
              end if;

              if not self.failed then
                expect (self, context, Tok_End);

                if not self.failed and then
                   (self.current.kind = Tok_Identifier or else
                    self.current.kind = Tok_Invalid_Identifier)
                then
                  outer_end_symbol := parse_identifier_symbol (self, context);
                end if;

                if not self.failed then
                  last := self.current.position;
                end if;
                expect (self, context, Tok_Semicolon);
                expect (self, context, Tok_EOF);

                if not self.failed then
                  begin
                    outer_body :=
                      Adac.Compilation.Syntax.create_procedure_body
                        (context,
                         self.procedure_symbol,
                         self.parameters,
                         outer_declarations,
                         outer_handled,
                         outer_end_symbol,
                         Adac.Source.make_span (body_first, last));
                    Adac.Compilation.Syntax.validate_procedure_body
                      (context, outer_body);
                  exception
                    when Adac.Resources.Limit_Exceeded =>
                      self.failed := True;
                      outer_body := Adac.AST.INVALID_NODE_ID;
                      Adac.Compilation.Diagnostics.error
                        (context, body_first, "AST node limit exceeded");
                  end;
                end if;

                if not self.failed then
                  self.unit_item := outer_body;
                  self.body_span := Adac.Source.make_span (body_first, last);
                  self.unit_span := Adac.Source.make_span (unit_first, last);
                end if;
              end if;
            elsif not self.failed then
              self.failed := True;
              Adac.Compilation.Diagnostics.error
                (context,
                 self.current.position,
                 "procedure body continuation after staged declarative " &
                 "part is not supported");
            end if;
          elsif not self.failed then
            self.failed := True;
            Adac.Compilation.Diagnostics.error
              (context,
               body_begin,
               "nested subprograms are not supported in procedure " &
               "declarative parts");
          end if;
        end;
      elsif not self.failed then
        self.failed := True;
        Adac.Compilation.Diagnostics.error
          (context,
           self.current.position,
           "nested subprograms are not supported in procedure " &
           "declarative parts");
      end if;
    end;
    return;
  end if;

  while not self.failed and then
    (self.current.kind = Tok_Identifier or else
     self.current.kind = Tok_Invalid_Identifier or else
     self.current.kind = Tok_Subtype)
  loop
    declare
      declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      if self.current.kind = Tok_Subtype then
        parse_subtype_declaration_staging (self, context, declaration);
      else
        parse_current_declaration_staging
          (self,
           context,
           declaration      => declaration,
           represent_object => True,
           represent_number => True);
      end if;

      if not self.failed then
        if declaration = Adac.AST.INVALID_NODE_ID then
          raise Program_Error with
            "procedure declarative part lost represented syntax";
        end if;
        Adac.AST.append (self.declarations, declaration);
      end if;
    end;
  end loop;

  expect (self, context, Tok_Begin);
  parse_statement_sequence
    (self, context, had_recovered_statement_error);

  if not self.failed and then self.current.kind = Tok_Exception then
    parse_exception_handlers_staging
      (self,
       context,
       terminator      => Tok_End,
       completion_mode => Reject_Unsupported_Handlers);
    return;
  end if;

  expect (self, context, Tok_End);

  self.end_symbol := parse_identifier_symbol (self, context);

  if not self.failed then
    last := self.current.position;
  end if;

  expect (self, context, Tok_Semicolon);

  if not self.failed then
    self.body_span := Adac.Source.make_span (body_first, last);
    self.unit_span := Adac.Source.make_span (unit_first, last);
  end if;

  expect (self, context, Tok_EOF);

  if not self.failed and then had_recovered_statement_error then
    self.failed := True;
  end if;
end parse_compilation_unit;
