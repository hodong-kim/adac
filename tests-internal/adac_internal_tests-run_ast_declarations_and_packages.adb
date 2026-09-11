-- ============================================================================
-- adac_internal_tests-run_ast_declarations_and_packages.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_AST_Declarations_And_Packages is
begin
  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "parameter-specification-tree.adb");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "prefix");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "String");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 15));
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 15));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    parameter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parameter_specification
        (context,
         defining_symbol,
         defining_span,
         Adac.AST.Default_In_Parameter_Mode,
         subtype_mark,
         parameter_span);
  begin
    Adac.Compilation.Syntax.validate_parameter (context, parameter);
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "parameter construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, parameter) =
       Adac.AST.Parameter_Specification_Node,
       "parameter specification has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.parameter_symbol (context, parameter) =
       defining_symbol,
       "parameter specification lost its defining symbol");
    require
      (Adac.Compilation.Syntax.parameter_defining_span (context, parameter) =
       defining_span,
       "parameter specification lost its defining span");
    require
      (Adac.Compilation.Syntax.parameter_mode (context, parameter) =
       Adac.AST.Default_In_Parameter_Mode,
       "parameter specification lost its default mode form");
    require
      (Adac.Compilation.Syntax.parameter_subtype_mark (context, parameter) =
       subtype_mark,
       "parameter specification lost its subtype mark");
    require
      (Adac.Compilation.Syntax.parameter_default_expression
         (context, parameter) = Adac.AST.INVALID_NODE_ID,
       "parameter specification gained an absent default expression");
    require
      (Adac.Compilation.Syntax.node_span (context, parameter) = parameter_span,
       "parameter specification lost its complete span");
    require
      (not accepts_parameter (context_b, parameter),
       "parameter validator accepted a node from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "parameter-default-tree.adb");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "maximum_nodes");
    natural_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Natural");
    last_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Last");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 13));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 23));
    default_prefix_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 28),
         Adac.Source.make_position (file_id, 1, 34));
    last_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 36),
         Adac.Source.make_position (file_id, 1, 39));
    default_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 28),
         Adac.Source.make_position (file_id, 1, 39));
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 39));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, natural_symbol, subtype_span);
    default_prefix : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, natural_symbol, default_prefix_span);
    default_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_attribute_name
        (context,
         default_prefix,
         last_symbol,
         last_span,
         default_span);
    parameter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parameter_specification
        (context,
         parameter_symbol,
         defining_span,
         Adac.AST.Default_In_Parameter_Mode,
         subtype_mark,
         default_expression,
         parameter_span);
  begin
    Adac.Compilation.Syntax.validate_parameter (context, parameter);
    require
      (Adac.Compilation.Syntax.parameter_default_expression
         (context, parameter) = default_expression,
       "parameter specification lost its default expression");
    require
      (Adac.Compilation.Syntax.kind_of (context, default_expression) =
       Adac.AST.Attribute_Name_Node,
       "parameter default expression lost its attribute-name syntax");
    require
      (Adac.Compilation.Syntax.node_span (context, parameter) = parameter_span,
       "parameter default expression did not extend the parameter span");
    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "parameter default construction published the wrong node count");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-parameter-default-kind.adb");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "limit");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Natural");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 15));
    bad_default_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 20),
         Adac.Source.make_position (file_id, 1, 23));
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 23));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    bad_default : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_statement_unchecked
        (context, Adac.AST.Null_Statement_Node, bad_default_span);
    parameter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_parameter_specification_unchecked
        (context,
         parameter_symbol,
         defining_span,
         Adac.AST.Default_In_Parameter_Mode,
         subtype_mark,
         parameter_span,
         bad_default);
  begin
    require
      (not accepts_parameter (context, parameter),
       "parameter validator accepted a non-expression default child");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-parameter-default-order.adb");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "limit");
    natural_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Natural");
    default_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Default_Value");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 15));
    default_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 20),
         Adac.Source.make_position (file_id, 1, 32));
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 32));
    default_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, default_symbol, default_span);
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, natural_symbol, subtype_span);
    parameter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_parameter_specification_unchecked
        (context,
         parameter_symbol,
         defining_span,
         Adac.AST.Default_In_Parameter_Mode,
         subtype_mark,
         parameter_span,
         default_expression);
  begin
    require
      (not accepts_parameter (context, parameter),
       "parameter validator accepted a default published before its subtype");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "parameter-mode-tree.adb");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value_Type");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 4));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 15),
         Adac.Source.make_position (file_id, 1, 24));
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 24));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    parameter : Adac.AST.Node_ID;
  begin
    for mode in Adac.AST.Parameter_Mode_Kind loop
      parameter := Adac.Compilation.Syntax.create_parameter_specification
        (context,
         defining_symbol,
         defining_span,
         mode,
         subtype_mark,
         parameter_span);
      Adac.Compilation.Syntax.validate_parameter (context, parameter);
      require
        (Adac.Compilation.Syntax.parameter_mode (context, parameter) = mode,
         "parameter mode form did not round-trip through syntax storage");
    end loop;

    require
      (Adac.Compilation.Syntax.node_count (context) = 5,
       "parameter mode construction published the wrong node count");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "object-declaration-tree.adb");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "name");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "String");
    initializer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 4));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 22));
    initializer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 31));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 32));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    initializer : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, initializer_symbol, initializer_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_object_declaration
        (context,
         Adac.AST.Constant_Object_Form,
         defining_symbol,
         defining_span,
         subtype_mark,
         initializer,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);

    require
      (Adac.Compilation.Syntax.node_count (context) = 3,
       "object declaration construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
       Adac.AST.Object_Declaration_Node,
       "object declaration has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.object_form (context, declaration) =
       Adac.AST.Constant_Object_Form,
       "object declaration lost its constant source form");
    require
      (Adac.Compilation.Syntax.object_has_initializer (context, declaration),
       "object declaration lost initializer presence");
    require
      (Adac.Compilation.Syntax.object_symbol (context, declaration) =
       defining_symbol,
       "object declaration lost its defining symbol");
    require
      (Adac.Compilation.Syntax.object_defining_span (context, declaration) =
       defining_span,
       "object declaration lost its defining span");
    require
      (Adac.Compilation.Syntax.object_subtype_mark (context, declaration) =
       subtype_mark,
       "object declaration lost its subtype mark");
    require
      (Adac.Compilation.Syntax.object_initializer (context, declaration) =
       initializer,
       "object declaration lost its initializer");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "object declaration lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "declaration validator accepted a node from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "constrained-object-tree.adb");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "items");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Index_Array");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 19));
    lower_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 22));
    range_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 24),
         Adac.Source.make_position (file_id, 1, 25));
    upper_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 27));
    constraint_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 28));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 29));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    lower_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "1", lower_span);
    upper_bound : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "3", upper_span);
    constraint : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_index_constraint
        (context,
         lower_bound,
         range_span,
         upper_bound,
         constraint_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_constrained_object_declaration
        (context,
         Adac.AST.Variable_Object_Form,
         defining_symbol,
         defining_span,
         subtype_mark,
         constraint,
         Adac.AST.INVALID_NODE_ID,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.kind_of (context, constraint) =
         Adac.AST.Index_Constraint_Node and then
       Adac.Compilation.Syntax.index_constraint_lower_bound
         (context, constraint) = lower_bound and then
       Adac.Compilation.Syntax.index_constraint_range_span
         (context, constraint) = range_span and then
       Adac.Compilation.Syntax.index_constraint_upper_bound
         (context, constraint) = upper_bound and then
       Adac.Compilation.Syntax.object_has_index_constraint
         (context, declaration) and then
       Adac.Compilation.Syntax.object_index_constraint
         (context, declaration) = constraint and then
       not Adac.Compilation.Syntax.object_has_initializer
         (context, declaration),
       "constrained object lost its index-constraint ownership");
    require
      (not accepts_declaration (context_b, declaration),
       "constrained object validator accepted another context's node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "object-renaming-tree.adb");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "alias");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Node");
    renamed_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "value");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 12));
    renamed_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 26));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 27));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    renamed_name : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, renamed_symbol, renamed_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_object_renaming_declaration
        (context,
         defining_symbol,
         defining_span,
         subtype_mark,
         renamed_name,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
         Adac.AST.Object_Renaming_Declaration_Node and then
       Adac.Compilation.Syntax.object_renaming_symbol
         (context, declaration) = defining_symbol and then
       Adac.Compilation.Syntax.object_renaming_defining_span
         (context, declaration) = defining_span and then
       Adac.Compilation.Syntax.object_renaming_subtype_mark
         (context, declaration) = subtype_mark and then
       Adac.Compilation.Syntax.object_renaming_name
         (context, declaration) = renamed_name and then
       Adac.Compilation.Syntax.node_span (context, declaration) =
         declaration_span,
       "object renaming lost its syntax ownership");
    require
      (not accepts_declaration (context_b, declaration),
       "object-renaming validator accepted another context's node");

    declare
      rejected : Boolean := False;
    begin
      begin
        declare
          invalid : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_object_renaming_declaration
              (context,
               defining_symbol,
               defining_span,
               renamed_name,
               subtype_mark,
               declaration_span);
        begin
          if invalid = Adac.AST.INVALID_NODE_ID then
            raise Program_Error with
              "object-renaming negative construction lost a node";
          end if;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected,
         "object renaming accepted reversed subtype/renamed child order");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "deferred-constant-tree.ads");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Null_Value");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item_Type");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 10));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 23),
         Adac.Source.make_position (file_id, 1, 31));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 32));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_object_declaration
        (context,
         Adac.AST.Constant_Object_Form,
         defining_symbol,
         defining_span,
         subtype_mark,
         Adac.AST.INVALID_NODE_ID,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "deferred constant construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.object_form (context, declaration) =
       Adac.AST.Constant_Object_Form,
       "deferred constant lost its explicit constant form");
    require
      (not Adac.Compilation.Syntax.object_has_initializer
         (context, declaration),
       "deferred constant unexpectedly retained an initializer");
    require
      (Adac.Compilation.Syntax.object_initializer (context, declaration) =
       Adac.AST.INVALID_NODE_ID,
       "deferred constant invented an initializer node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "number-declaration-tree.adb");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Count");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    initializer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 21));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 22));
    initializer : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context,
         Adac.AST.Decimal_Integer_Form,
         "1",
         initializer_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_number_declaration
        (context,
         defining_symbol,
         defining_span,
         initializer,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);

    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "number declaration construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
       Adac.AST.Number_Declaration_Node,
       "number declaration has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.number_symbol (context, declaration) =
       defining_symbol,
       "number declaration lost its defining symbol");
    require
      (Adac.Compilation.Syntax.number_defining_span (context, declaration) =
       defining_span,
       "number declaration lost its defining span");
    require
      (Adac.Compilation.Syntax.number_initializer (context, declaration) =
       initializer,
       "number declaration lost its initializer");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "number declaration lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "number declaration validator accepted a node from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "procedure-declaration-tree.ads");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 11),
         Adac.Source.make_position (file_id, 1, 13));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 14));
    parameters : Adac.AST.Node_List;
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_declaration
        (context, defining_symbol, defining_span, parameters, declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);

    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "procedure declaration construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
       Adac.AST.Procedure_Declaration_Node,
       "procedure declaration has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.procedure_declaration_symbol
         (context, declaration) = defining_symbol,
       "procedure declaration lost its defining symbol");
    require
      (Adac.Compilation.Syntax.procedure_declaration_defining_span
         (context, declaration) = defining_span,
       "procedure declaration lost its defining span");
    require
      (Adac.Compilation.Syntax.procedure_declaration_parameter_count
         (context, declaration) = 0,
       "parameterless procedure declaration gained parameters");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "procedure declaration lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "procedure declaration validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "procedure-profile-declaration-tree.ads");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Update");
    self_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "self");
    value_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "value");
    item_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 11),
         Adac.Source.make_position (file_id, 1, 16));
    self_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 19),
         Adac.Source.make_position (file_id, 1, 22));
    first_subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 33),
         Adac.Source.make_position (file_id, 1, 36));
    first_parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 19),
         Adac.Source.make_position (file_id, 1, 36));
    value_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 39),
         Adac.Source.make_position (file_id, 1, 43));
    second_subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 47),
         Adac.Source.make_position (file_id, 1, 50));
    second_parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 39),
         Adac.Source.make_position (file_id, 1, 50));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 52));
    first_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, item_symbol, first_subtype_span);
    first_parameter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parameter_specification
        (context,
         self_symbol,
         self_span,
         Adac.AST.In_Out_Parameter_Mode,
         first_subtype,
         first_parameter_span);
    second_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, item_symbol, second_subtype_span);
    second_parameter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parameter_specification
        (context,
         value_symbol,
         value_span,
         Adac.AST.Default_In_Parameter_Mode,
         second_subtype,
         second_parameter_span);
    parameters : Adac.AST.Node_List;
    declaration : Adac.AST.Node_ID;
  begin
    Adac.AST.append (parameters, first_parameter);
    Adac.AST.append (parameters, second_parameter);
    declaration :=
      Adac.Compilation.Syntax.create_procedure_declaration
        (context,
         defining_symbol,
         defining_span,
         parameters,
         declaration_span);
    Adac.Compilation.Syntax.validate_declaration (context, declaration);

    require
      (Adac.Compilation.Syntax.node_count (context) = 5,
       "profiled procedure declaration published the wrong node count");
    require
      (Adac.Compilation.Syntax.procedure_declaration_parameter_count
         (context, declaration) = 2,
       "profiled procedure declaration lost its parameter count");
    require
      (Adac.Compilation.Syntax.procedure_declaration_parameter_at
         (context, declaration, 1) = first_parameter and then
       Adac.Compilation.Syntax.procedure_declaration_parameter_at
         (context, declaration, 2) = second_parameter,
       "profiled procedure declaration lost parameter source order");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "profiled procedure declaration lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "profiled procedure declaration validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "function-declaration-tree.ads");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Count");
    parameter_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "item");
    item_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item");
    natural_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Natural");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 14));
    parameter_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 20));
    parameter_subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 24),
         Adac.Source.make_position (file_id, 1, 27));
    parameter_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 27));
    result_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 37),
         Adac.Source.make_position (file_id, 1, 43));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 44));
    parameter_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, item_symbol, parameter_subtype_span);
    parameter : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_parameter_specification
        (context,
         parameter_symbol,
         parameter_defining_span,
         Adac.AST.Default_In_Parameter_Mode,
         parameter_subtype,
         parameter_span);
    result_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, natural_symbol, result_span);
    parameters : Adac.AST.Node_List;
    declaration : Adac.AST.Node_ID;
  begin
    Adac.AST.append (parameters, parameter);
    declaration :=
      Adac.Compilation.Syntax.create_function_declaration
        (context,
         defining_symbol,
         defining_span,
         parameters,
         result_subtype,
         Adac.AST.INVALID_NODE_ID,
         declaration_span);
    Adac.Compilation.Syntax.validate_declaration (context, declaration);

    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "function declaration construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
       Adac.AST.Function_Declaration_Node,
       "function declaration has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.function_declaration_symbol
         (context, declaration) = defining_symbol and then
       Adac.Compilation.Syntax.function_declaration_defining_span
         (context, declaration) = defining_span,
       "function declaration lost its defining name");
    require
      (Adac.Compilation.Syntax.function_declaration_parameter_count
         (context, declaration) = 1 and then
       Adac.Compilation.Syntax.function_declaration_parameter_at
         (context, declaration, 1) = parameter,
       "function declaration lost its parameter");
    require
      (Adac.Compilation.Syntax.function_declaration_result_subtype
         (context, declaration) = result_subtype,
       "function declaration lost its result subtype");
    require
      (not Adac.Compilation.Syntax.function_declaration_has_aspect
         (context, declaration),
       "plain function declaration gained an aspect");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "function declaration lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "function declaration validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "function-aspect-tree.ads");
    function_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "F");
    result_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "R");
    pre_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Pre");
    left_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "A");
    right_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "B");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 10));
    result_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 19),
         Adac.Source.make_position (file_id, 1, 19));
    aspect_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 37));
    mark_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 26),
         Adac.Source.make_position (file_id, 1, 28));
    left_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 33),
         Adac.Source.make_position (file_id, 1, 33));
    operator_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 35),
         Adac.Source.make_position (file_id, 1, 35));
    right_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 37),
         Adac.Source.make_position (file_id, 1, 37));
    relation_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.first_position (left_span),
         Adac.Source.last_position (right_span));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 38));
    result_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, result_symbol, result_span);
    left_operand : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, left_symbol, left_span);
    right_operand : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, right_symbol, right_span);
    relation : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_relation
        (context,
         left_operand,
         "=",
         operator_span,
         right_operand,
         relation_span);
    aspect : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_aspect_specification
        (context, pre_symbol, mark_span, relation, aspect_span);
    parameters : Adac.AST.Node_List;
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_function_declaration
        (context,
         function_symbol,
         defining_span,
         parameters,
         result_subtype,
         aspect,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_aspect_specification (context, aspect);
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.node_count (context) = 6,
       "function aspect construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, aspect) =
         Adac.AST.Aspect_Specification_Node and then
       Adac.Compilation.Syntax.aspect_mark_symbol (context, aspect) =
         pre_symbol and then
       Adac.Compilation.Syntax.aspect_mark_span (context, aspect) = mark_span,
       "function aspect lost its mark source ownership");
    require
      (Adac.Compilation.Syntax.aspect_definition (context, aspect) = relation,
       "function aspect lost its definition expression");
    require
      (Adac.Compilation.Syntax.function_declaration_has_aspect
         (context, declaration) and then
       Adac.Compilation.Syntax.function_declaration_aspect
         (context, declaration) = aspect,
       "function declaration lost its aspect ownership");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "private-type-declaration-tree.ads");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Item");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 9));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 21));
    discriminants : Adac.AST.Node_List;
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_private_type_declaration
        (context,
         defining_symbol,
         defining_span,
         discriminants,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "private type construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
       Adac.AST.Private_Type_Declaration_Node,
       "private type has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.private_type_symbol (context, declaration) =
       defining_symbol,
       "private type lost its defining symbol");
    require
      (Adac.Compilation.Syntax.private_type_defining_span
         (context, declaration) = defining_span,
       "private type lost its defining span");
    require
      (not Adac.Compilation.Syntax.private_type_is_limited
         (context, declaration),
       "nonlimited private type gained limited source form");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "private type lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "private type validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "limited-private-type-declaration-tree.ads");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Store");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 10));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 30));
    discriminants : Adac.AST.Node_List;
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_private_type_declaration
        (context,
         defining_symbol,
         defining_span,
         discriminants,
         declaration_span,
         limited_form => True);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
       Adac.AST.Private_Type_Declaration_Node,
       "limited private type has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.private_type_is_limited
         (context, declaration),
       "limited private type lost its source form");
    require
      (Adac.Compilation.Syntax.private_type_symbol (context, declaration) =
       defining_symbol and then
       Adac.Compilation.Syntax.private_type_defining_span
         (context, declaration) = defining_span and then
       Adac.Compilation.Syntax.node_span (context, declaration) =
         declaration_span,
       "limited private type lost its source ownership");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "discriminated-private-type-tree.ads");
    type_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Result");
    discriminant_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "status");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Status");
    default_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Failure");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 11));
    discriminant_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 14),
         Adac.Source.make_position (file_id, 1, 19));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 23),
         Adac.Source.make_position (file_id, 1, 28));
    default_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 33),
         Adac.Source.make_position (file_id, 1, 39));
    discriminant_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.first_position (discriminant_defining_span),
         Adac.Source.last_position (default_span));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 52));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    default_expression : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, default_symbol, default_span);
    discriminant : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_discriminant_specification
        (context,
         discriminant_symbol,
         discriminant_defining_span,
         subtype_mark,
         default_expression,
         discriminant_span);
    discriminants : Adac.AST.Node_List;
    declaration : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    Adac.AST.append (discriminants, discriminant);
    declaration :=
      Adac.Compilation.Syntax.create_private_type_declaration
        (context,
         type_symbol,
         defining_span,
         discriminants,
         declaration_span);

    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.private_type_discriminant_count
         (context, declaration) = 1 and then
       Adac.Compilation.Syntax.private_type_discriminant_at
         (context, declaration, 1) = discriminant,
       "private type lost discriminant ownership");
    require
      (Adac.Compilation.Syntax.discriminant_has_default_expression
         (context, discriminant) and then
       Adac.Compilation.Syntax.discriminant_default_expression
         (context, discriminant) = default_expression,
       "private type discriminant lost its default expression");
    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "discriminated private type published the wrong node count");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "enumeration-type-declaration-tree.ads");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Choice");
    one_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "One");
    two_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Two");
    three_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Three");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 6),
         Adac.Source.make_position (file_id, 1, 11));
    one_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 19));
    two_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 24));
    three_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 31));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 33));
    literals : Adac.AST.Enumeration_Literal_List;
    declaration : Adac.AST.Node_ID;
  begin
    Adac.AST.append (literals, one_symbol, one_span);
    Adac.AST.append (literals, two_symbol, two_span);
    Adac.AST.append (literals, three_symbol, three_span);
    declaration :=
      Adac.Compilation.Syntax.create_enumeration_type_declaration
        (context,
         defining_symbol,
         defining_span,
         literals,
         declaration_span);
    Adac.Compilation.Syntax.validate_declaration (context, declaration);

    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "enumeration type construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, declaration) =
       Adac.AST.Enumeration_Type_Declaration_Node,
       "enumeration type has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.enumeration_type_symbol
         (context, declaration) = defining_symbol and then
       Adac.Compilation.Syntax.enumeration_type_defining_span
         (context, declaration) = defining_span,
       "enumeration type lost its defining name");
    require
      (Adac.Compilation.Syntax.enumeration_literal_count
         (context, declaration) = 3,
       "enumeration type lost its literal count");
    require
      (Adac.Compilation.Syntax.enumeration_literal_symbol_at
         (context, declaration, 1) = one_symbol and then
       Adac.Compilation.Syntax.enumeration_literal_symbol_at
         (context, declaration, 2) = two_symbol and then
       Adac.Compilation.Syntax.enumeration_literal_symbol_at
         (context, declaration, 3) = three_symbol,
       "enumeration type lost literal source order");
    require
      (Adac.Compilation.Syntax.enumeration_literal_span_at
         (context, declaration, 1) = one_span and then
       Adac.Compilation.Syntax.enumeration_literal_span_at
         (context, declaration, 3) = three_span,
       "enumeration type lost literal spans");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "enumeration type lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "enumeration type validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "package-enumeration-child.ads");
    package_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Sample");
    type_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Choice");
    one_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "One");
    two_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Two");
    package_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 14));
    type_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 8),
         Adac.Source.make_position (file_id, 2, 13));
    one_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 19),
         Adac.Source.make_position (file_id, 2, 21));
    two_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 24),
         Adac.Source.make_position (file_id, 2, 26));
    type_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 28));
    package_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 4));
    literals : Adac.AST.Enumeration_Literal_List;
    defining_name : Adac.AST.Program_Unit_Name;
    end_name : Adac.AST.Program_Unit_Name;
    declarations : Adac.AST.Node_List;
    enumeration_declaration : Adac.AST.Node_ID;
    package_declaration : Adac.AST.Node_ID;
  begin
    Adac.AST.append (literals, one_symbol, one_span);
    Adac.AST.append (literals, two_symbol, two_span);
    enumeration_declaration :=
      Adac.Compilation.Syntax.create_enumeration_type_declaration
        (context,
         type_symbol,
         type_defining_span,
         literals,
         type_span);
    Adac.AST.append
      (defining_name, package_symbol, package_defining_span);
    Adac.AST.append (declarations, enumeration_declaration);
    package_declaration :=
      Adac.Compilation.Syntax.create_package_declaration
        (context, defining_name, declarations, end_name, package_span);
    Adac.Compilation.Syntax.validate_package_declaration
      (context, package_declaration);
    require
      (Adac.Compilation.Syntax.package_visible_declaration_count
         (context, package_declaration) = 1 and then
       Adac.Compilation.Syntax.package_visible_declaration_at
         (context, package_declaration, 1) = enumeration_declaration,
       "package declaration rejected an enumeration visible child");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "package-declaration-tree.ads");
    package_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Sample");
    end_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Other");
    number_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Count");
    package_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 14));
    package_end_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 5),
         Adac.Source.make_position (file_id, 3, 9));
    number_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 7));
    initializer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 23),
         Adac.Source.make_position (file_id, 2, 23));
    number_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 24));
    package_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 10));
    initializer : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context,
         Adac.AST.Decimal_Integer_Form,
         "1",
         initializer_span);
    number_declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_number_declaration
        (context,
         number_symbol,
         number_defining_span,
         initializer,
         number_span);
    defining_name : Adac.AST.Program_Unit_Name;
    end_name      : Adac.AST.Program_Unit_Name;
    declarations  : Adac.AST.Node_List;
    package_declaration : Adac.AST.Node_ID;
  begin
    Adac.AST.append
      (defining_name, package_symbol, package_defining_span);
    Adac.AST.append (end_name, end_symbol, package_end_span);
    Adac.AST.append (declarations, number_declaration);
    package_declaration :=
      Adac.Compilation.Syntax.create_package_declaration
        (context, defining_name, declarations, end_name, package_span);
    Adac.Compilation.Syntax.validate_package_declaration
      (context, package_declaration);

    require
      (Adac.Compilation.Syntax.node_count (context) = 3,
       "package declaration construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, package_declaration) =
       Adac.AST.Package_Declaration_Node,
       "package declaration has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.package_defining_name_count
         (context, package_declaration) = 1 and then
       Adac.Compilation.Syntax.package_defining_name_symbol_at
         (context, package_declaration, 1) = package_symbol and then
       Adac.Compilation.Syntax.package_defining_name_span_at
         (context, package_declaration, 1) = package_defining_span,
       "package declaration lost its defining name");
    require
      (Adac.Compilation.Syntax.package_visible_declaration_count
         (context, package_declaration) = 1 and then
       Adac.Compilation.Syntax.package_visible_declaration_at
         (context, package_declaration, 1) = number_declaration,
       "package declaration lost its visible declaration");
    require
      (not Adac.Compilation.Syntax.package_has_explicit_private_part
         (context, package_declaration) and then
       Adac.Compilation.Syntax.package_private_declaration_count
         (context, package_declaration) = 0,
       "package declaration invented an explicit private part");
    require
      (Adac.Compilation.Syntax.package_has_end_designator
         (context, package_declaration) and then
       Adac.Compilation.Syntax.package_end_name_count
         (context, package_declaration) = 1 and then
       Adac.Compilation.Syntax.package_end_name_symbol_at
         (context, package_declaration, 1) = end_symbol and then
       Adac.Compilation.Syntax.package_end_name_span_at
         (context, package_declaration, 1) = package_end_span,
       "package declaration lost its closing designator");
    require
      (Adac.Compilation.Syntax.node_span (context, package_declaration) =
       package_span,
       "package declaration lost its complete span");
    require
      (not accepts_package_declaration (context_b, package_declaration),
       "package validator accepted a node from another context");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "package-explicit-empty-private.ads");
    package_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Sample");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 14));
    private_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 2, 7));
    package_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 4));
    defining_name        : Adac.AST.Program_Unit_Name;
    visible_declarations : Adac.AST.Node_List;
    private_declarations : Adac.AST.Node_List;
    end_name             : Adac.AST.Program_Unit_Name;
    package_declaration  : Adac.AST.Node_ID;
  begin
    Adac.AST.append (defining_name, package_symbol, defining_span);
    package_declaration :=
      Adac.Compilation.Syntax.create_package_declaration
        (context,
         defining_name,
         visible_declarations,
         private_span,
         private_declarations,
         end_name,
         package_span);
    Adac.Compilation.Syntax.validate_package_declaration
      (context, package_declaration);

    require
      (Adac.Compilation.Syntax.package_visible_declaration_count
         (context, package_declaration) = 0 and then
       Adac.Compilation.Syntax.package_has_explicit_private_part
         (context, package_declaration) and then
       Adac.Compilation.Syntax.package_private_part_span
         (context, package_declaration) = private_span and then
       Adac.Compilation.Syntax.package_private_declaration_count
         (context, package_declaration) = 0,
       "package declaration lost its explicit empty private part");
  end;

  declare
    context   : Adac.Compilation.Context := new_context;
    context_b : constant Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "package-body-tree.adb");
    parent_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Parent");
    child_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Child");
    run_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    other_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Other");
    name_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Name");
    parent_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 14),
         Adac.Source.make_position (file_id, 1, 19));
    child_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 25));
    null_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 5),
         Adac.Source.make_position (file_id, 4, 9));
    procedure_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 5, 10));
    other_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 5),
         Adac.Source.make_position (file_id, 6, 9));
    name_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 11),
         Adac.Source.make_position (file_id, 6, 14));
    package_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 6, 15));
    null_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, null_span);
    statements   : Adac.AST.Node_List;
    handlers     : Adac.AST.Node_List;
    parameters   : Adac.AST.Node_List;
    declarations : Adac.AST.Node_List;
    package_declarations : Adac.AST.Node_List;
    invalid_declarations : Adac.AST.Node_List;
    context_items : Adac.AST.Node_List;
    handled_sequence : Adac.AST.Node_ID;
    procedure_body  : Adac.AST.Node_ID;
    defining_name   : Adac.AST.Program_Unit_Name;
    end_name        : Adac.AST.Program_Unit_Name;
    package_body    : Adac.AST.Node_ID;
    root            : Adac.AST.Node_ID;
  begin
    Adac.AST.append (statements, null_statement);
    handled_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, statements, handlers, null_span);
    procedure_body := Adac.Compilation.Syntax.create_procedure_body
      (context,
       run_symbol,
       parameters,
       declarations,
       handled_sequence,
       run_symbol,
       procedure_span);
    Adac.AST.append (defining_name, parent_symbol, parent_span);
    Adac.AST.append (defining_name, child_symbol, child_span);
    Adac.AST.append (end_name, other_symbol, other_span);
    Adac.AST.append (end_name, name_symbol, name_span);
    Adac.AST.append (package_declarations, procedure_body);
    package_body := Adac.Compilation.Syntax.create_package_body
      (context,
       defining_name,
       package_declarations,
       end_name,
       package_span);
    Adac.Compilation.Syntax.validate_package_body (context, package_body);

    require
      (Adac.Compilation.Syntax.node_count (context) = 4,
       "package-body construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.kind_of (context, package_body) =
       Adac.AST.Package_Body_Node,
       "package body has the wrong AST kind");
    require
      (Adac.Compilation.Syntax.package_body_defining_name_count
         (context, package_body) = 2 and then
       Adac.Compilation.Syntax.package_body_defining_name_symbol_at
         (context, package_body, 1) = parent_symbol and then
       Adac.Compilation.Syntax.package_body_defining_name_symbol_at
         (context, package_body, 2) = child_symbol and then
       Adac.Compilation.Syntax.package_body_defining_name_span_at
         (context, package_body, 2) = child_span,
       "package body lost its defining name");
    require
      (Adac.Compilation.Syntax.package_body_declaration_count
         (context, package_body) = 1 and then
       Adac.Compilation.Syntax.package_body_declaration_at
         (context, package_body, 1) = procedure_body,
       "package body lost its procedure declaration child");
    require
      (Adac.Compilation.Syntax.package_body_has_end_designator
         (context, package_body) and then
       Adac.Compilation.Syntax.package_body_end_name_count
         (context, package_body) = 2 and then
       Adac.Compilation.Syntax.package_body_end_name_symbol_at
         (context, package_body, 1) = other_symbol and then
       Adac.Compilation.Syntax.package_body_end_name_span_at
         (context, package_body, 2) = name_span,
       "package body lost its closing name");
    require
      (Adac.Compilation.Syntax.node_span (context, package_body) = package_span,
       "package body lost its complete span");
    require
      (not accepts_package_body (context_b, package_body),
       "package-body validator accepted a foreign node");
    Adac.AST.append (invalid_declarations, null_statement);
    require
      (rejects_package_body_construction
         (context,
          defining_name,
          invalid_declarations,
          end_name,
          package_span),
       "package body accepted a non-procedure declarative item");

    root := Adac.Compilation.Syntax.create_compilation_unit
      (context, context_items, package_body, package_span);
    Adac.Compilation.Syntax.validate (context, root);
    require
      (Adac.Compilation.Syntax.library_item (context, root) = package_body,
       "compilation unit lost its package-body library item");
    require
      (Adac.Sema.analyze (context, root).status = Adac.Sema.Analysis_Rejected,
       "package body unexpectedly passed semantic analysis");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package-body semantic rejection published an entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "package-body-stub.adb");
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Helper");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 14),
         Adac.Source.make_position (file_id, 1, 19));
    stub_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 32));
    stub : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_package_body_stub
        (context, symbol, defining_span, stub_span);
  begin
    Adac.Compilation.Syntax.validate_package_body_stub (context, stub);
    require
      (Adac.Compilation.Syntax.kind_of (context, stub) =
         Adac.AST.Package_Body_Stub_Node and then
       Adac.Compilation.Syntax.package_body_stub_symbol (context, stub) =
         symbol and then
       Adac.Compilation.Syntax.package_body_stub_defining_span
         (context, stub) = defining_span and then
       Adac.Compilation.Syntax.node_span (context, stub) = stub_span,
       "package-body stub lost defining syntax ownership");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-package-declaration.ads");
    package_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Sample");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 9),
         Adac.Source.make_position (file_id, 1, 14));
    bad_child_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 7));
    package_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 3, 4));
    bad_child : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_statement_unchecked
        (context, Adac.AST.Null_Statement_Node, bad_child_span);
    defining_name : Adac.AST.Program_Unit_Name;
    end_name      : Adac.AST.Program_Unit_Name;
    declarations  : Adac.AST.Node_List;
    package_declaration : Adac.AST.Node_ID;
  begin
    Adac.AST.append (defining_name, package_symbol, defining_span);
    Adac.AST.append (declarations, bad_child);
    package_declaration :=
      Adac.Compilation.Syntax.Testing.create_package_declaration_unchecked
        (context, defining_name, declarations, end_name, package_span);
    require
      (not accepts_package_declaration (context, package_declaration),
       "package validator accepted a non-current visible declaration");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "variable-object-declaration-tree.adb");
    defining_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "module");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Module_Type");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 6));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 10),
         Adac.Source.make_position (file_id, 1, 20));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 21));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_object_declaration
        (context,
         Adac.AST.Variable_Object_Form,
         defining_symbol,
         defining_span,
         subtype_mark,
         Adac.AST.INVALID_NODE_ID,
         declaration_span);
  begin
    Adac.Compilation.Syntax.validate_declaration (context, declaration);
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "variable object construction published the wrong node count");
    require
      (Adac.Compilation.Syntax.object_form (context, declaration) =
       Adac.AST.Variable_Object_Form,
       "variable object declaration lost its source form");
    require
      (not Adac.Compilation.Syntax.object_has_initializer
         (context, declaration),
       "variable object declaration gained an initializer");
    require
      (Adac.Compilation.Syntax.object_initializer (context, declaration) =
       Adac.AST.INVALID_NODE_ID,
       "variable object declaration has a noninvalid initializer");
    require
      (Adac.Compilation.Syntax.object_subtype_mark (context, declaration) =
       subtype_mark,
       "variable object declaration lost its subtype mark");
    require
      (Adac.Compilation.Syntax.node_span (context, declaration) =
       declaration_span,
       "variable object declaration lost its complete span");
    require
      (not accepts_declaration (context_b, declaration),
       "variable declaration validator accepted a foreign node");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "procedure-body-tree.adb");
    procedure_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "report");
    nested_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "forward");
    object_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "item");
    subtype_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "String");
    initializer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value");
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 17),
         Adac.Source.make_position (file_id, 2, 22));
    initializer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 27),
         Adac.Source.make_position (file_id, 2, 31));
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 6));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 2, 32));
    nested_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 13),
         Adac.Source.make_position (file_id, 3, 19));
    nested_declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 3),
         Adac.Source.make_position (file_id, 3, 20));
    statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 3),
         Adac.Source.make_position (file_id, 4, 7));
    body_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 5, 11));
    subtype_mark : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, subtype_symbol, subtype_span);
    initializer : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, initializer_symbol, initializer_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_object_declaration
        (context,
         Adac.AST.Constant_Object_Form,
         object_symbol,
         defining_span,
         subtype_mark,
         initializer,
         declaration_span);
    nested_parameters : Adac.AST.Node_List;
    nested_declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_declaration
        (context, nested_symbol, nested_defining_span, nested_parameters,
         nested_declaration_span);
    statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, statement_span);
    parameters, declarations, statements, handlers : Adac.AST.Node_List;
    sequence, procedure_node : Adac.AST.Node_ID;
  begin
    Adac.AST.append (declarations, declaration);
    Adac.AST.append (declarations, nested_declaration);
    Adac.AST.append (statements, statement);
    sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, statements, handlers, statement_span);
    procedure_node := Adac.Compilation.Syntax.create_procedure_body
      (context, procedure_symbol, parameters, declarations, sequence,
       procedure_symbol, body_span);
    Adac.Compilation.Syntax.validate_procedure_body (context, procedure_node);
    require
      (Adac.Compilation.Syntax.declaration_count
         (context, procedure_node) = 2 and then
       Adac.Compilation.Syntax.declaration_at
         (context, procedure_node, 1) = declaration and then
       Adac.Compilation.Syntax.declaration_at
         (context, procedure_node, 2) = nested_declaration and then
       Adac.Compilation.Syntax.kind_of (context, nested_declaration) =
         Adac.AST.Procedure_Declaration_Node,
       "procedure body lost its ordered declarative part");
    require
      (Adac.Compilation.Syntax.procedure_handled_sequence
         (context, procedure_node) = sequence and then
       Adac.Compilation.Syntax.statement_count
         (context, procedure_node) = 1 and then
       Adac.Compilation.Syntax.statement_at
         (context, procedure_node, 1) = statement,
       "procedure body lost its handled sequence");
    require
      (Adac.Compilation.Syntax.has_end_designator (context, procedure_node),
       "procedure body lost its closing designator");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    depth : constant Positive := 64;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "function-nested-procedure-tree.adb");
    function_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "wrap");
    procedure_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "validate");
    result_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Integer");
    result_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 28));
    result_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, result_symbol, result_span);
    function_parameters : Adac.AST.Node_List;
    function_declarations : Adac.AST.Node_List;
    function_statements : Adac.AST.Node_List;
    function_handlers : Adac.AST.Node_List;
    nested_procedure : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    function_sequence : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    function_body : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    for level in reverse 1 .. depth loop
      declare
        statement_line : constant Positive := 3 * depth - 2 * level + 2;
        statement_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, statement_line, 5),
             Adac.Source.make_position (file_id, statement_line, 9));
        body_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, level + 1, 3),
             Adac.Source.make_position (file_id, statement_line + 1, 12));
        statement : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_statement
            (context, Adac.AST.Null_Statement_Node, statement_span);
        parameters : Adac.AST.Node_List;
        declarations : Adac.AST.Node_List;
        statements : Adac.AST.Node_List;
        handlers : Adac.AST.Node_List;
        sequence : Adac.AST.Node_ID;
      begin
        if nested_procedure /= Adac.AST.INVALID_NODE_ID then
          Adac.AST.append (declarations, nested_procedure);
        end if;
        Adac.AST.append (statements, statement);
        sequence := Adac.Compilation.Syntax.create_handled_sequence
          (context, statements, handlers, statement_span);
        nested_procedure := Adac.Compilation.Syntax.create_procedure_body
          (context,
           procedure_symbol,
           parameters,
           declarations,
           sequence,
           procedure_symbol,
           body_span);
      end;
    end loop;

    Adac.AST.append (function_declarations, nested_procedure);
    declare
      statement_line : constant Positive := 3 * depth + 2;
      statement_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, statement_line, 3),
           Adac.Source.make_position (file_id, statement_line, 7));
      body_span : constant Adac.Source.Span :=
        Adac.Source.make_span
          (Adac.Source.make_position (file_id, 1, 1),
           Adac.Source.make_position (file_id, statement_line + 1, 10));
      statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.create_statement
          (context, Adac.AST.Null_Statement_Node, statement_span);
    begin
      Adac.AST.append (function_statements, statement);
      function_sequence := Adac.Compilation.Syntax.create_handled_sequence
        (context, function_statements, function_handlers, statement_span);
      function_body := Adac.Compilation.Syntax.create_function_body
        (context,
         function_symbol,
         function_parameters,
         result_subtype,
         function_declarations,
         function_sequence,
         function_symbol,
         body_span);
    end;

    Adac.Compilation.Syntax.validate_function_body (context, function_body);
    require
      (Adac.Compilation.Syntax.function_body_declaration_count
         (context, function_body) = 1 and then
       Adac.Compilation.Syntax.kind_of
         (context,
          Adac.Compilation.Syntax.function_body_declaration_at
            (context, function_body, 1)) = Adac.AST.Procedure_Body_Node,
       "function body lost its nested procedure declarative child");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    depth : constant Positive := 64;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "function-nested-function-tree.adb");
    function_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "nested");
    result_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Integer");
    nested_function : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    for level in reverse 1 .. depth loop
      declare
        statement_line : constant Positive := 3 * depth - 2 * level + 2;
        result_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, level, 20),
             Adac.Source.make_position (file_id, level, 26));
        statement_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, statement_line, 3),
             Adac.Source.make_position (file_id, statement_line, 7));
        body_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, level, 1),
             Adac.Source.make_position (file_id, statement_line + 1, 10));
        result_subtype : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_identifier_name
            (context, result_symbol, result_span);
        statement : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_statement
            (context, Adac.AST.Null_Statement_Node, statement_span);
        parameters : Adac.AST.Node_List;
        declarations : Adac.AST.Node_List;
        statements : Adac.AST.Node_List;
        handlers : Adac.AST.Node_List;
        sequence : Adac.AST.Node_ID;
      begin
        if nested_function /= Adac.AST.INVALID_NODE_ID then
          Adac.AST.append (declarations, nested_function);
        end if;
        Adac.AST.append (statements, statement);
        sequence := Adac.Compilation.Syntax.create_handled_sequence
          (context, statements, handlers, statement_span);
        nested_function := Adac.Compilation.Syntax.create_function_body
          (context,
           function_symbol,
           parameters,
           result_subtype,
           declarations,
           sequence,
           function_symbol,
           body_span);
      end;
    end loop;

    Adac.Compilation.Syntax.validate_function_body
      (context, nested_function);
    require
      (Adac.Compilation.Syntax.function_body_declaration_count
         (context, nested_function) = 1 and then
       Adac.Compilation.Syntax.kind_of
         (context,
          Adac.Compilation.Syntax.function_body_declaration_at
            (context, nested_function, 1)) = Adac.AST.Function_Body_Node,
       "function body lost its nested function declarative child");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "procedure-function-declaration-rejected.adb");
    procedure_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    function_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Local");
    nested_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Nested");
    result_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Integer");
    result_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 25),
         Adac.Source.make_position (file_id, 2, 31));
    nested_defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 15),
         Adac.Source.make_position (file_id, 3, 20));
    nested_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 5),
         Adac.Source.make_position (file_id, 3, 21));
    function_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 5, 5),
         Adac.Source.make_position (file_id, 5, 9));
    function_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 6, 12));
    procedure_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 8, 3),
         Adac.Source.make_position (file_id, 8, 7));
    procedure_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 9, 10));
    result_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, result_symbol, result_span);
    nested_parameters : Adac.AST.Node_List;
    nested_declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_procedure_declaration
        (context,
         nested_symbol,
         nested_defining_span,
         nested_parameters,
         nested_span);
    function_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, function_statement_span);
    procedure_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, procedure_statement_span);
    function_parameters : Adac.AST.Node_List;
    function_declarations : Adac.AST.Node_List;
    function_statements : Adac.AST.Node_List;
    function_handlers : Adac.AST.Node_List;
    procedure_parameters : Adac.AST.Node_List;
    procedure_declarations : Adac.AST.Node_List;
    procedure_statements : Adac.AST.Node_List;
    procedure_handlers : Adac.AST.Node_List;
    function_sequence : Adac.AST.Node_ID;
    procedure_sequence : Adac.AST.Node_ID;
    local_function : Adac.AST.Node_ID;
    rejected : Boolean := False;
  begin
    Adac.AST.append (function_declarations, nested_declaration);
    Adac.AST.append (function_statements, function_statement);
    function_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context,
       function_statements,
       function_handlers,
       function_statement_span);
    local_function := Adac.Compilation.Syntax.create_function_body
      (context,
       function_symbol,
       function_parameters,
       result_subtype,
       function_declarations,
       function_sequence,
       function_symbol,
       function_span);
    Adac.AST.append (procedure_declarations, local_function);
    Adac.AST.append (procedure_statements, procedure_statement);
    procedure_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context,
       procedure_statements,
       procedure_handlers,
       procedure_statement_span);

    begin
      declare
        ignored : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_procedure_body
            (context,
             procedure_symbol,
             procedure_parameters,
             procedure_declarations,
             procedure_sequence,
             procedure_symbol,
             procedure_span);
      begin
        if ignored = Adac.AST.INVALID_NODE_ID then
          null;
        end if;
      end;
    exception
      when Program_Error =>
        rejected := True;
    end;
    require
      (rejected,
       "procedure body accepted a function with declarative children");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "procedure-function-procedure-depth-rejected.adb");
    outer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    function_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Local");
    leaf_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Leaf");
    deep_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Too_Deep");
    result_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Integer");
    result_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 25),
         Adac.Source.make_position (file_id, 2, 31));
    deep_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 6, 7),
         Adac.Source.make_position (file_id, 6, 11));
    deep_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 5),
         Adac.Source.make_position (file_id, 7, 18));
    leaf_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 9, 5),
         Adac.Source.make_position (file_id, 9, 9));
    leaf_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 3),
         Adac.Source.make_position (file_id, 10, 12));
    function_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 12, 3),
         Adac.Source.make_position (file_id, 12, 7));
    function_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 1),
         Adac.Source.make_position (file_id, 13, 10));
    outer_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 15, 3),
         Adac.Source.make_position (file_id, 15, 7));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 16, 10));
    result_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, result_symbol, result_span);
    parameters : Adac.AST.Node_List;
    deep_declarations : Adac.AST.Node_List;
    deep_statements : Adac.AST.Node_List;
    deep_handlers : Adac.AST.Node_List;
    leaf_declarations : Adac.AST.Node_List;
    leaf_statements : Adac.AST.Node_List;
    leaf_handlers : Adac.AST.Node_List;
    function_declarations : Adac.AST.Node_List;
    function_statements : Adac.AST.Node_List;
    function_handlers : Adac.AST.Node_List;
    outer_declarations : Adac.AST.Node_List;
    outer_statements : Adac.AST.Node_List;
    outer_handlers : Adac.AST.Node_List;
    deep_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, deep_statement_span);
    leaf_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, leaf_statement_span);
    function_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, function_statement_span);
    outer_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, outer_statement_span);
    deep_sequence : Adac.AST.Node_ID;
    deep_procedure : Adac.AST.Node_ID;
    leaf_sequence : Adac.AST.Node_ID;
    leaf_procedure : Adac.AST.Node_ID;
    function_sequence : Adac.AST.Node_ID;
    local_function : Adac.AST.Node_ID;
    outer_sequence : Adac.AST.Node_ID;
    unchecked_outer : Adac.AST.Node_ID;
    construction_rejected : Boolean := False;
    validation_rejected : Boolean := False;
  begin
    Adac.AST.append (deep_statements, deep_statement);
    deep_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, deep_statements, deep_handlers, deep_statement_span);
    deep_procedure := Adac.Compilation.Syntax.create_procedure_body
      (context,
       deep_symbol,
       parameters,
       deep_declarations,
       deep_sequence,
       deep_symbol,
       deep_span);

    Adac.AST.append (leaf_declarations, deep_procedure);
    Adac.AST.append (leaf_statements, leaf_statement);
    leaf_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, leaf_statements, leaf_handlers, leaf_statement_span);
    leaf_procedure := Adac.Compilation.Syntax.create_procedure_body
      (context,
       leaf_symbol,
       parameters,
       leaf_declarations,
       leaf_sequence,
       leaf_symbol,
       leaf_span);

    Adac.AST.append (function_declarations, leaf_procedure);
    Adac.AST.append (function_statements, function_statement);
    function_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context,
       function_statements,
       function_handlers,
       function_statement_span);
    local_function := Adac.Compilation.Syntax.create_function_body
      (context,
       function_symbol,
       parameters,
       result_subtype,
       function_declarations,
       function_sequence,
       function_symbol,
       function_span);

    Adac.AST.append (outer_declarations, local_function);
    Adac.AST.append (outer_statements, outer_statement);
    outer_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, outer_statements, outer_handlers, outer_statement_span);

    begin
      declare
        ignored : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.create_procedure_body
            (context,
             outer_symbol,
             parameters,
             outer_declarations,
             outer_sequence,
             outer_symbol,
             outer_span);
        pragma Unreferenced (ignored);
      begin
        null;
      end;
    exception
      when Program_Error =>
        construction_rejected := True;
    end;
    require
      (construction_rejected,
       "procedure construction accepted alternating subprogram body depth");

    unchecked_outer :=
      Adac.Compilation.Syntax.Testing.create_procedure_body_unchecked
        (context,
         outer_symbol,
         parameters,
         outer_declarations,
         outer_sequence,
         outer_symbol,
         outer_span);
    begin
      Adac.Compilation.Syntax.validate_procedure_body
        (context, unchecked_outer);
    exception
      when Program_Error =>
        validation_rejected := True;
    end;
    require
      (validation_rejected,
       "procedure validation accepted alternating subprogram body depth");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-function-nested-procedure.adb");
    function_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "wrap");
    procedure_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "validate");
    result_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Integer");
    result_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 22),
         Adac.Source.make_position (file_id, 1, 28));
    bad_declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 3, 5),
         Adac.Source.make_position (file_id, 3, 9));
    nested_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 4, 5),
         Adac.Source.make_position (file_id, 4, 9));
    nested_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 2, 3),
         Adac.Source.make_position (file_id, 5, 12));
    function_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 7, 3),
         Adac.Source.make_position (file_id, 7, 7));
    function_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 8, 10));
    result_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, result_symbol, result_span);
    bad_declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_statement_unchecked
        (context, Adac.AST.Null_Statement_Node, bad_declaration_span);
    nested_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, nested_statement_span);
    function_statement : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_statement
        (context, Adac.AST.Null_Statement_Node, function_statement_span);
    parameters : Adac.AST.Node_List;
    bad_declarations : Adac.AST.Node_List;
    nested_statements : Adac.AST.Node_List;
    nested_handlers : Adac.AST.Node_List;
    function_declarations : Adac.AST.Node_List;
    function_statements : Adac.AST.Node_List;
    function_handlers : Adac.AST.Node_List;
    nested_sequence : Adac.AST.Node_ID;
    bad_procedure : Adac.AST.Node_ID;
    function_sequence : Adac.AST.Node_ID;
    function_body : Adac.AST.Node_ID;
    rejected : Boolean := False;
  begin
    Adac.AST.append (bad_declarations, bad_declaration);
    Adac.AST.append (nested_statements, nested_statement);
    nested_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context, nested_statements, nested_handlers, nested_statement_span);
    bad_procedure :=
      Adac.Compilation.Syntax.Testing.create_procedure_body_unchecked
        (context,
         procedure_symbol,
         parameters,
         bad_declarations,
         nested_sequence,
         procedure_symbol,
         nested_span);
    Adac.AST.append (function_declarations, bad_procedure);
    Adac.AST.append (function_statements, function_statement);
    function_sequence := Adac.Compilation.Syntax.create_handled_sequence
      (context,
       function_statements,
       function_handlers,
       function_statement_span);
    function_body := Adac.Compilation.Syntax.create_function_body
      (context,
       function_symbol,
       parameters,
       result_subtype,
       function_declarations,
       function_sequence,
       function_symbol,
       function_span);

    begin
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
    exception
      when Program_Error =>
        rejected := True;
    end;
    require
      (rejected,
       "function validator accepted a malformed nested procedure subtree");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-object-declaration.adb");
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "name");
    initializer_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 4));
    subtype_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 17),
         Adac.Source.make_position (file_id, 1, 22));
    initializer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 27),
         Adac.Source.make_position (file_id, 1, 31));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 32));
    bad_subtype : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_statement_unchecked
        (context, Adac.AST.Null_Statement_Node, subtype_span);
    initializer : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_identifier_name
        (context, initializer_symbol, initializer_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_object_declaration_unchecked
        (context,
         Adac.AST.Constant_Object_Form,
         symbol,
         defining_span,
         bad_subtype,
         initializer,
         declaration_span);
  begin
    require
      (not accepts_declaration (context, declaration),
       "declaration validator accepted a statement subtype mark");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-procedure-declaration.ads");
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Run");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 3));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 4));
    parameters : Adac.AST.Node_List;
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_procedure_declaration_unchecked
        (context, symbol, defining_span, parameters, declaration_span);
  begin
    require
      (not accepts_declaration (context, declaration),
       "procedure declaration validator accepted a missing keyword interval");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "malformed-number-declaration.adb");
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Count");
    defining_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 5));
    initializer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 21));
    declaration_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 22));
    bad_initializer : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_statement_unchecked
        (context, Adac.AST.Null_Statement_Node, initializer_span);
    declaration : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.Testing.create_number_declaration_unchecked
        (context,
         symbol,
         defining_span,
         bad_initializer,
         declaration_span);
  begin
    require
      (not accepts_declaration (context, declaration),
       "number declaration validator accepted a statement initializer");
  end;
end Run_AST_Declarations_And_Packages;
