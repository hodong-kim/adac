-- ============================================================================
-- adac_internal_tests-run_bootstrap_package_ownership.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_Bootstrap_Package_Ownership is
  use type Adac.AST.General_Access_Modifier_Kind;
  use type Adac.AST.Generic_Actual_Association_Form;
  use type Adac.AST.Loop_Statement_Form;
  use type Adac.AST.Logical_Operator_Kind;
  use type Adac.AST.Membership_Operator_Kind;
  use type Adac.AST.Short_Circuit_Operator_Kind;
begin
  declare
    path : constant String :=
      "tests/context/context-with-clauses-semantic-unsupported/input.adb";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "represented with clauses did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "represented with clauses recorded a parse diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 7,
       "represented with clauses changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 15,
       "represented with clauses changed AST publication");
    require
      (Adac.Compilation.Syntax.context_item_count (context, result.root) = 3,
       "compilation unit did not retain three with clauses");
    require
      (Adac.Compilation.Syntax.with_clause_name_count
         (context,
          Adac.Compilation.Syntax.context_item_at
            (context, result.root, 2)) = 2,
       "comma-separated with clause did not retain both names");

    declare
      second_clause : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.context_item_at (context, result.root, 2);
      first_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.with_clause_name_at
          (context, second_clause, 1);
      prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, first_name);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, second_clause) =
           Adac.AST.With_Clause_Node,
         "context item did not retain its with-clause kind");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol (context, prefix)) =
           "Ada",
         "with-clause prefix symbol changed");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol (context, first_name)) =
           "Exceptions",
         "with-clause selector symbol changed");
    end;

    declare
      procedure_node : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      root_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, result.root);
      procedure_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, procedure_node);
      analysis : constant Adac.Sema.Analysis_Result :=
        Adac.Sema.analyze (context, result.root);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, procedure_node) =
           Adac.AST.Procedure_Body_Node,
         "compilation unit did not retain a procedure-body library item");
      require
        (Adac.Compilation.Syntax.statement_count
           (context, procedure_node) = 1,
         "procedure-body statement list changed");
      require
        (Adac.Source.first_position (root_span).line = 1 and then
         Adac.Source.first_position (root_span).column = 1 and then
         Adac.Source.first_position (procedure_span).line = 5 and then
         Adac.Source.first_position (procedure_span).column = 1 and then
         Adac.Source.last_position (root_span) =
           Adac.Source.last_position (procedure_span),
         "context root and procedure-body spans changed");
      require
        (analysis.status = Adac.Sema.Analysis_Rejected,
         "context clauses reached semantic procedure publication");
      require
        (Adac.Compilation.Diagnostics.error_count (context) = 1,
         "context-clause semantic rejection did not record one diagnostic");
      require
        (Adac.Compilation.Semantics.entity_count (context) = 0,
         "context-clause semantic rejection published an entity");
    end;
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 2));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/context/" &
                  "context-with-clauses-semantic-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "with-clause AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "with-clause AST limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "with-clause AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "with-clause AST limit published a partial clause node");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => 1,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/context/" &
                  "context-with-clauses-semantic-unsupported/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "with-clause symbol limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "with-clause symbol limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "with-clause symbol limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "with-clause symbol limit changed prior name publication");
  end;

  declare
    path : constant String :=
      "tests/declarations/types/record-type-default-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "record type fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "record type fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      record_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      component : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_at
          (context, record_type, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_subtype_mark
          (context, component);
      default_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_default_expression
          (context, component);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, record_type) =
           Adac.AST.Record_Type_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_type_symbol
              (context, record_type)) = "Marker" and then
         Adac.Compilation.Syntax.record_component_count
           (context, record_type) = 1 and then
         not Adac.Compilation.Syntax.record_type_is_limited
           (context, record_type),
         "record type lost its defining name, form, or component list");
      require
        (Adac.Compilation.Syntax.kind_of (context, component) =
           Adac.AST.Record_Component_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_component_symbol
              (context, component)) = "identity" and then
         Adac.Compilation.Syntax.record_component_has_default_expression
           (context, component) and then
         not Adac.Compilation.Syntax.record_component_is_aliased
           (context, component),
         "record component lost its defining name, form, or default");
      require
        (Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Boolean" and then
         Adac.Compilation.Syntax.kind_of (context, default_expression) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, default_expression)) = "False",
         "record component lost its subtype mark or default expression");
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/record-type-limited-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "limited record fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "limited record fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      record_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, record_type) =
           Adac.AST.Record_Type_Declaration_Node and then
         Adac.Compilation.Syntax.record_type_is_limited
           (context, record_type) and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_type_symbol
              (context, record_type)) = "Holder",
         "limited record lost its source form or defining symbol");
      Adac.Compilation.Syntax.validate_record_type_declaration
        (context, record_type);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/" &
      "record-type-aliased-component-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "aliased record-component fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "aliased record-component fixture parsing recorded " &
       "a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      record_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      component : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_at
          (context, record_type, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, component) =
           Adac.AST.Record_Component_Declaration_Node and then
         Adac.Compilation.Syntax.record_component_is_aliased
           (context, component) and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_component_symbol
              (context, component)) = "value",
         "aliased record component lost its source form or defining symbol");
      Adac.Compilation.Syntax.validate_record_type_declaration
        (context, record_type);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/record-type-null-default-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "record null-default fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "record null-default fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      record_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      null_component : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_at
          (context, record_type, 1);
      numeric_component : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_at
          (context, record_type, 2);
      null_default : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_default_expression
          (context, null_component);
      numeric_default : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_default_expression
          (context, numeric_component);
    begin
      require
        (Adac.Compilation.Syntax.record_component_count
           (context, record_type) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, null_default) =
           Adac.AST.Null_Literal_Node,
         "record component null default lost null-literal syntax ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, numeric_default) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, numeric_default) = "0",
         "record component numeric default lost numeric-literal syntax");
      Adac.Compilation.Syntax.validate_expression (context, null_default);
      Adac.Compilation.Syntax.validate_expression (context, numeric_default);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/" &
      "package-private-type-discriminant-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "private-type discriminant fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "private-type discriminant fixture recorded a parse diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      private_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, package_declaration, 1);
      discriminant : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.private_type_discriminant_at
          (context, private_type, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.discriminant_subtype_mark
          (context, discriminant);
      default_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.discriminant_default_expression
          (context, discriminant);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, private_type) =
           Adac.AST.Private_Type_Declaration_Node and then
         Adac.Compilation.Syntax.private_type_discriminant_count
           (context, private_type) = 1,
         "private type lost its discriminant ownership");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.discriminant_symbol
              (context, discriminant)) = "status" and then
         Adac.Compilation.Syntax.discriminant_has_default_expression
           (context, discriminant),
         "private type discriminant lost its symbol or default");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Result_Status" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, default_expression)) = "Failure",
         "private type discriminant changed subtype/default ownership");
      Adac.Compilation.Syntax.validate_declaration (context, private_type);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/" &
      "package-function-pre-aspect-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "function Pre aspect fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function Pre aspect fixture recorded a parse diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, package_declaration, 2);
      aspect : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_declaration_aspect
          (context, function_declaration);
      definition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.aspect_definition (context, aspect);
      left_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_left_operand
          (context, definition);
      right_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand
          (context, definition);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, function_declaration) =
           Adac.AST.Function_Declaration_Node and then
         Adac.Compilation.Syntax.function_declaration_has_aspect
           (context, function_declaration),
         "function declaration lost its aspect syntax");
      require
        (Adac.Compilation.Syntax.kind_of (context, aspect) =
           Adac.AST.Aspect_Specification_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.aspect_mark_symbol
              (context, aspect)) = "Pre",
         "function aspect lost its mark ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, definition) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, definition) = "=" and then
         Adac.Compilation.Syntax.kind_of (context, left_operand) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, right_operand) =
           Adac.AST.Identifier_Name_Node,
         "function Pre aspect lost its relation operands");
      Adac.Compilation.Syntax.validate_aspect_specification (context, aspect);
      Adac.Compilation.Syntax.validate_declaration
        (context, function_declaration);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/record-type-discriminant-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "record discriminant fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "record discriminant fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      record_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      discriminant : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_discriminant_at
          (context, record_type, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.discriminant_subtype_mark
          (context, discriminant);
      default_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.discriminant_default_expression
          (context, discriminant);
    begin
      require
        (Adac.Compilation.Syntax.record_discriminant_count
           (context, record_type) = 1 and then
         Adac.Compilation.Syntax.record_component_count
           (context, record_type) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, discriminant) =
           Adac.AST.Discriminant_Specification_Node,
         "record type changed discriminant or component ownership");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.discriminant_symbol
              (context, discriminant)) = "kind" and then
         Adac.Compilation.Syntax.discriminant_has_default_expression
           (context, discriminant),
         "record discriminant lost its defining symbol or default");
      require
        (Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Choice" and then
         Adac.Compilation.Syntax.kind_of (context, default_expression) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, default_expression)) = "Default_Kind",
         "record discriminant changed subtype or default ownership");
      Adac.Compilation.Syntax.validate_discriminant_specification
        (context, discriminant);
      Adac.Compilation.Syntax.validate_record_type_declaration
        (context, record_type);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/record-type-variant-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "record variant fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "record variant fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      record_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 2);
      variant_part : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_variant_part (context, record_type);
      discriminant_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_variant_part_discriminant_name
          (context, variant_part);
      first_variant : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_variant_part_variant_at
          (context, variant_part, 1);
      second_variant : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_variant_part_variant_at
          (context, variant_part, 2);
      first_choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_variant_choice_at
          (context, first_variant, 1);
      second_choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_variant_choice_at
          (context, first_variant, 2);
      first_component : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_variant_component_at
          (context, first_variant, 1);
    begin
      require
        (Adac.Compilation.Syntax.record_has_variant_part
           (context, record_type) and then
         Adac.Compilation.Syntax.record_discriminant_count
           (context, record_type) = 1 and then
         Adac.Compilation.Syntax.record_component_count
           (context, record_type) = 1 and then
         Adac.Compilation.Syntax.record_variant_part_variant_count
           (context, variant_part) = 2,
         "record type changed discriminant/component/variant ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, discriminant_name) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, discriminant_name)) = "kind",
         "record variant part lost its discriminant direct name");
      require
        (Adac.Compilation.Syntax.record_variant_choice_count
           (context, first_variant) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, first_choice)) = "A" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, second_choice)) = "B",
         "record variant changed ordered discrete choices");
      require
        (not Adac.Compilation.Syntax.record_variant_has_null_component_list
           (context, first_variant) and then
         Adac.Compilation.Syntax.record_variant_component_count
           (context, first_variant) = 1 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_component_symbol
              (context, first_component)) = "value",
         "record variant changed ordinary component ownership");
      require
        (Adac.Compilation.Syntax.record_variant_choice_count
           (context, second_variant) = 1 and then
         Adac.Compilation.Syntax.record_variant_has_null_component_list
           (context, second_variant) and then
         Adac.Compilation.Syntax.record_variant_component_count
           (context, second_variant) = 0,
         "record variant changed null component-list ownership");
      Adac.Compilation.Syntax.validate_record_variant
        (context, first_variant);
      Adac.Compilation.Syntax.validate_record_variant
        (context, second_variant);
      Adac.Compilation.Syntax.validate_record_variant_part
        (context, variant_part);
      Adac.Compilation.Syntax.validate_record_type_declaration
        (context, record_type);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-record-aggregate-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "package record-aggregate fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package record-aggregate fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      full_constant : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_initializer (context, full_constant);
      left_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, aggregate, 1);
      right_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, aggregate, 2);
    begin
      require
        (Adac.Compilation.Syntax.object_form (context, full_constant) =
           Adac.AST.Constant_Object_Form and then
         Adac.Compilation.Syntax.kind_of (context, aggregate) =
           Adac.AST.Record_Aggregate_Node and then
         Adac.Compilation.Syntax.record_aggregate_association_count
           (context, aggregate) = 2,
         "package record aggregate changed object or association ownership");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_aggregate_selector_symbol_at
              (context, aggregate, 1)) = "Left" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_aggregate_selector_symbol_at
              (context, aggregate, 2)) = "Right",
         "record aggregate changed selector ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, left_value) =
           Adac.AST.Null_Literal_Node and then
         Adac.Compilation.Syntax.kind_of (context, right_value) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, right_value) = "0",
         "record aggregate changed association value ownership");
      Adac.Compilation.Syntax.validate_record_aggregate (context, aggregate);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/derived-type-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "derived type fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "derived type fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      derived_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      parent_subtype : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.derived_type_parent_subtype_mark
          (context, derived_type);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, derived_type) =
           Adac.AST.Derived_Type_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.derived_type_symbol
              (context, derived_type)) = "Alias",
         "derived type lost its defining symbol");
      require
        (Adac.Compilation.Syntax.kind_of (context, parent_subtype) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, parent_subtype)) = "Type_Name",
         "derived type lost its parent subtype mark");
      Adac.Compilation.Syntax.validate_derived_type_declaration
        (context, derived_type);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/exceptions/exception-declaration-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "exception declaration fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "exception declaration fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      exception_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, package_declaration, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, exception_declaration) =
           Adac.AST.Exception_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.exception_declaration_symbol
              (context, exception_declaration)) = "Problem",
         "exception declaration lost its defining symbol");
      Adac.Compilation.Syntax.validate_exception_declaration
        (context, exception_declaration);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/subtype-range-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "subtype range fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "subtype range fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      subtype_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, package_declaration, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.subtype_declaration_subtype_mark
          (context, subtype_declaration);
      constraint : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.subtype_declaration_constraint
          (context, subtype_declaration);
      lower_bound : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.range_constraint_lower_bound
          (context, constraint);
      upper_bound : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.range_constraint_upper_bound
          (context, constraint);
      upper_left : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.binary_adding_left_operand
          (context, upper_bound);
      upper_right : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.binary_adding_right_operand
          (context, upper_bound);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, subtype_declaration) =
           Adac.AST.Subtype_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.subtype_declaration_symbol
              (context, subtype_declaration)) = "Small" and then
         Adac.Compilation.Syntax.subtype_declaration_has_constraint
           (context, subtype_declaration),
         "subtype declaration lost its defining symbol or constraint");
      require
        (Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Natural" and then
         Adac.Compilation.Syntax.kind_of (context, constraint) =
           Adac.AST.Range_Constraint_Node,
         "subtype declaration lost its subtype mark or range constraint");
      require
        (Adac.Compilation.Syntax.kind_of (context, lower_bound) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, lower_bound) = "0" and then
         Adac.Compilation.Syntax.kind_of (context, upper_bound) =
           Adac.AST.Binary_Adding_Node and then
         Adac.Compilation.Syntax.binary_adding_operator_spelling
           (context, upper_bound) = "-",
         "subtype range lost its represented bounds");
      require
        (Adac.Compilation.Syntax.kind_of (context, upper_left) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context, Adac.Compilation.Syntax.attribute_symbol
             (context, upper_left)) = "Last" and then
         Adac.Compilation.Syntax.kind_of (context, upper_right) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, upper_right) = "1",
         "subtype upper bound lost attribute or numeric operand ownership");
      Adac.Compilation.Syntax.validate_range_constraint (context, constraint);
      Adac.Compilation.Syntax.validate_subtype_declaration
        (context, subtype_declaration);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/" &
      "package-generic-instantiation-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "generic package instantiation fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "generic package instantiation fixture recorded a parse diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      instantiation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      generic_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_instantiation_generic_name
          (context, instantiation);
      first_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_instantiation_actual_at
          (context, instantiation, 1);
      second_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_instantiation_actual_at
          (context, instantiation, 2);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, instantiation) =
           Adac.AST.Package_Instantiation_Node and then
         Adac.Compilation.Syntax.package_instantiation_defining_name_count
           (context, instantiation) = 1 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax
              .package_instantiation_defining_name_symbol_at
                (context, instantiation, 1)) = "Items",
         "generic package instantiation lost its defining name");
      require
        (Adac.Compilation.Syntax.kind_of (context, generic_name) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, generic_name)) = "Vectors",
         "generic package instantiation lost its generic package name");
      require
        (Adac.Compilation.Syntax.package_instantiation_actual_count
           (context, instantiation) = 2 and then
         Adac.Compilation.Syntax.package_instantiation_actual_form_at
           (context, instantiation, 1) =
             Adac.AST.Named_Generic_Actual_Form and then
         Adac.Compilation.Syntax.package_instantiation_actual_form_at
           (context, instantiation, 2) =
             Adac.AST.Named_Generic_Actual_Form and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax
              .package_instantiation_actual_selector_symbol_at
                (context, instantiation, 1)) = "Index_Type" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax
              .package_instantiation_actual_selector_symbol_at
                (context, instantiation, 2)) = "Element_Type",
         "generic package instantiation changed named actual selectors");
      require
        (Adac.Compilation.Syntax.kind_of (context, first_actual) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, first_actual)) = "Positive" and then
         Adac.Compilation.Syntax.kind_of (context, second_actual) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, second_actual)) = "Item",
         "generic package instantiation changed named actual ownership");
      Adac.Compilation.Syntax.validate_package_instantiation
        (context, instantiation);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/" &
      "package-generic-instantiation-operator-selector-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "operator-selector generic instantiation did not parse cleanly");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      instantiation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_instantiation_actual_at
          (context, instantiation, 3);
      actual_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, actual);
    begin
      require
        (Adac.Compilation.Syntax.package_instantiation_actual_count
           (context, instantiation) = 3 and then
         Adac.Compilation.Syntax.package_instantiation_actual_form_at
           (context, instantiation, 3) =
             Adac.AST.Named_Generic_Actual_Form and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax
              .package_instantiation_actual_selector_symbol_at
                (context, instantiation, 3)) = """=""" and then
         Adac.Compilation.Syntax.kind_of (context, actual) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol (context, actual)) =
              """=""" and then
         Adac.Compilation.Syntax.kind_of (context, actual_prefix) =
           Adac.AST.Selected_Name_Node,
         "generic operator selector lost selected actual ownership");
      Adac.Compilation.Syntax.validate_package_instantiation
        (context, instantiation);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/" &
      "package-generic-instantiation-positional-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "positional generic package instantiation fixture did not parse " &
       "cleanly");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      instantiation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      first_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_instantiation_actual_at
          (context, instantiation, 1);
      second_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_instantiation_actual_at
          (context, instantiation, 2);
      selector_rejected : Boolean := False;
    begin
      require
        (Adac.Compilation.Syntax.package_instantiation_actual_count
           (context, instantiation) = 2 and then
         Adac.Compilation.Syntax.package_instantiation_actual_form_at
           (context, instantiation, 1) =
             Adac.AST.Positional_Generic_Actual_Form and then
         Adac.Compilation.Syntax.package_instantiation_actual_form_at
           (context, instantiation, 2) =
             Adac.AST.Positional_Generic_Actual_Form and then
         Adac.Compilation.Syntax.kind_of (context, first_actual) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, first_actual)) = "Item" and then
         Adac.Compilation.Syntax.kind_of (context, second_actual) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling
           (context, second_actual) = """=""",
         "positional generic actual lost source form or actual ownership");

      begin
        declare
          ignored : constant Adac.Symbols.Symbol_ID :=
            Adac.Compilation.Syntax
              .package_instantiation_actual_selector_symbol_at
                (context, instantiation, 1);
        begin
          pragma Unreferenced (ignored);
          null;
        end;
      exception
        when Program_Error =>
          selector_rejected := True;
      end;
      require
        (selector_rejected,
         "positional generic actual exposed a named selector");
      Adac.Compilation.Syntax.validate_package_instantiation
        (context, instantiation);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-object-forms-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "package object-form fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package object-form fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      visible_variable : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, package_declaration, 1);
      deferred_constant : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, package_declaration, 2);
      private_variable : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      full_constant : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 2);
    begin
      require
        (Adac.Compilation.Syntax.package_visible_declaration_count
           (context, package_declaration) = 2 and then
         Adac.Compilation.Syntax.package_private_declaration_count
           (context, package_declaration) = 2,
         "package object forms changed visible/private ownership");
      require
        (Adac.Compilation.Syntax.object_form (context, visible_variable) =
           Adac.AST.Variable_Object_Form and then
         not Adac.Compilation.Syntax.object_has_initializer
           (context, visible_variable),
         "package variable object changed its source form");
      require
        (Adac.Compilation.Syntax.object_form (context, deferred_constant) =
           Adac.AST.Constant_Object_Form and then
         not Adac.Compilation.Syntax.object_has_initializer
           (context, deferred_constant),
         "package deferred constant changed its source form");
      require
        (Adac.Compilation.Syntax.object_form (context, private_variable) =
           Adac.AST.Variable_Object_Form and then
         Adac.Compilation.Syntax.object_has_initializer
           (context, private_variable) and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, Adac.Compilation.Syntax.object_initializer
              (context, private_variable)) = "0",
         "package initialized variable changed its source form");
      require
        (Adac.Compilation.Syntax.object_form (context, full_constant) =
           Adac.AST.Constant_Object_Form and then
         Adac.Compilation.Syntax.object_has_initializer
           (context, full_constant) and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, Adac.Compilation.Syntax.object_initializer
              (context, full_constant)) = "0",
         "package full constant changed its source form");
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/types/access-object-type-modifiers-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "access-to-object type fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "access-to-object type fixture parsing recorded a diagnostic");

    declare
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      plain_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 1);
      all_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 2);
      constant_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, package_declaration, 3);
    begin
      require
        (Adac.Compilation.Syntax.package_private_declaration_count
           (context, package_declaration) = 3,
         "access-to-object fixture changed private declaration ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, plain_type) =
           Adac.AST.Access_Object_Type_Declaration_Node and then
         Adac.Compilation.Syntax.access_object_type_modifier
           (context, plain_type) = Adac.AST.No_General_Access_Modifier and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.access_object_type_designated_subtype
              (context, plain_type)) = Adac.AST.Identifier_Name_Node,
         "plain access-to-object type lost its form or designated subtype");
      require
        (Adac.Compilation.Syntax.kind_of (context, all_type) =
           Adac.AST.Access_Object_Type_Declaration_Node and then
         Adac.Compilation.Syntax.access_object_type_modifier
           (context, all_type) = Adac.AST.All_General_Access_Modifier,
         "all access-to-object type lost its general access modifier");
      require
        (Adac.Compilation.Syntax.kind_of (context, constant_type) =
           Adac.AST.Access_Object_Type_Declaration_Node and then
         Adac.Compilation.Syntax.access_object_type_modifier
           (context, constant_type) = Adac.AST.Constant_General_Access_Modifier,
         "constant access-to-object type lost its general access modifier");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.access_object_type_symbol
              (context, plain_type)) = "Plain_Ref" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.access_object_type_symbol
              (context, all_type)) = "All_Ref" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.access_object_type_symbol
              (context, constant_type)) = "Constant_Ref",
         "access-to-object types changed defining-name ownership");

      declare
        plain_designated : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.access_object_type_designated_subtype
            (context, plain_type);
        all_designated : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.access_object_type_designated_subtype
            (context, all_type);
        constant_designated : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.access_object_type_designated_subtype
            (context, constant_type);
      begin
        require
          (Adac.Compilation.Symbols.spelling
             (context,
              Adac.Compilation.Syntax.identifier_symbol
                (context, plain_designated)) = "Target" and then
           Adac.Compilation.Symbols.spelling
             (context,
              Adac.Compilation.Syntax.identifier_symbol
                (context, all_designated)) = "Target" and then
           Adac.Compilation.Symbols.spelling
             (context,
              Adac.Compilation.Syntax.identifier_symbol
                (context, constant_designated)) = "Target",
           "access-to-object types changed designated subtype spelling");
      end;
    end;
  end;

  declare
    path : constant String := "src/adac.ads";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "package compilation unit did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package parsing recorded a diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 4,
       "package syntax changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 8,
       "package syntax changed AST publication");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package syntax published a semantic entity");

    declare
      root : constant Adac.AST.Node_ID := result.root;
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, root);
      package_symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Syntax.package_defining_name_symbol_at
          (context, package_declaration, 1);
      package_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, package_declaration);
      defining_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.package_defining_name_span_at
          (context, package_declaration, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, root) =
         Adac.AST.Compilation_Unit_Node,
         "package parse returned the wrong root kind");
      require
        (Adac.Compilation.Syntax.context_item_count (context, root) = 0,
         "context-free package unit gained context items");
      require
        (Adac.Compilation.Syntax.kind_of
           (context, package_declaration) = Adac.AST.Package_Declaration_Node,
         "package unit lost its package library item");
      require
        (Adac.Compilation.Syntax.package_defining_name_count
           (context, package_declaration) = 1 and then
         Adac.Compilation.Symbols.spelling (context, package_symbol) = "Adac",
         "package declaration lost its defining spelling");
      require
        (Adac.Compilation.Syntax.package_has_end_designator
           (context, package_declaration) and then
         Adac.Compilation.Syntax.package_end_name_count
           (context, package_declaration) = 1 and then
         Adac.Compilation.Syntax.package_end_name_symbol_at
           (context, package_declaration, 1) = package_symbol,
         "package declaration lost its closing designator");
      require
        (Adac.Source.first_position (defining_span).line = 7 and then
         Adac.Source.first_position (defining_span).column = 9 and then
         Adac.Source.last_position (defining_span).line = 7 and then
         Adac.Source.last_position (defining_span).column = 12,
         "package declaration has the wrong defining span");
      require
        (Adac.Source.first_position (package_span).line = 7 and then
         Adac.Source.first_position (package_span).column = 1 and then
         Adac.Source.last_position (package_span).line = 13 and then
         Adac.Source.last_position (package_span).column = 9 and then
         Adac.Compilation.Syntax.node_span (context, root) = package_span,
         "package declaration or root has the wrong complete span");
      require
        (Adac.Compilation.Syntax.package_visible_declaration_count
           (context, package_declaration) = 3,
         "package declaration lost a version declaration");

      for index in 1 .. 3 loop
        declare
          declaration : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.package_visible_declaration_at
              (context, package_declaration, index);
        begin
          require
            (Adac.Compilation.Syntax.kind_of (context, declaration) =
             Adac.AST.Number_Declaration_Node,
             "package visible item has the wrong declaration kind");
        end;
      end loop;

      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.number_symbol
              (context,
               Adac.Compilation.Syntax.package_visible_declaration_at
                 (context, package_declaration, 1))) = "VERSION_MAJOR" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.number_symbol
              (context,
               Adac.Compilation.Syntax.package_visible_declaration_at
                 (context, package_declaration, 2))) = "VERSION_MINOR" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.number_symbol
              (context,
               Adac.Compilation.Syntax.package_visible_declaration_at
                 (context, package_declaration, 3))) = "VERSION_PATCH",
         "package declaration changed visible declaration order");

      declare
        analysis : constant Adac.Sema.Analysis_Result :=
          Adac.Sema.analyze (context, root);
      begin
        require
          (analysis.status = Adac.Sema.Analysis_Rejected,
           "package semantic boundary did not reject analysis");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "package semantic boundary did not record one diagnostic");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "package semantic rejection published an entity");
      end;
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-nested-private-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "private nested package did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "private nested package parsing recorded a diagnostic");

    declare
      outer_package : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      inner_package : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_private_declaration_at
          (context, outer_package, 1);
      inner_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, inner_package, 1);
    begin
      require
        (Adac.Compilation.Syntax.package_visible_declaration_count
           (context, outer_package) = 0 and then
         Adac.Compilation.Syntax.package_has_explicit_private_part
           (context, outer_package) and then
         Adac.Compilation.Syntax.package_private_declaration_count
           (context, outer_package) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, inner_package) =
           Adac.AST.Package_Declaration_Node,
         "private nested package was not owned by the " &
         "private declaration list");
      require
        (Adac.Compilation.Syntax.package_defining_name_count
           (context, inner_package) = 1 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.package_defining_name_symbol_at
              (context, inner_package, 1)) = "Inner" and then
         Adac.Compilation.Syntax.package_visible_declaration_count
           (context, inner_package) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, inner_function) =
           Adac.AST.Function_Declaration_Node,
         "private nested package lost its independent declaration ownership");
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-nested-visible-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "visible nested package did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "visible nested package parsing recorded a diagnostic");

    declare
      outer_package : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      inner_package : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, outer_package, 1);
    begin
      require
        (Adac.Compilation.Syntax.package_visible_declaration_count
           (context, outer_package) = 1 and then
         not Adac.Compilation.Syntax.package_has_explicit_private_part
           (context, outer_package) and then
         Adac.Compilation.Syntax.package_private_declaration_count
           (context, outer_package) = 0 and then
         Adac.Compilation.Syntax.kind_of (context, inner_package) =
           Adac.AST.Package_Declaration_Node,
         "visible nested package was not owned by the " &
         "visible declaration list");
    end;
  end;

  declare
    path : constant String := "src/adac.ads";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 1));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "package number declaration AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "package number declaration AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "package number declaration AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "package number declaration AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package number declaration AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.ads";
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "selected package did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "selected package parsing recorded a diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "selected package changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 3,
       "selected package changed AST publication");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "selected package parsing published a semantic entity");

    declare
      root : constant Adac.AST.Node_ID := result.root;
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, root);
      procedure_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_visible_declaration_at
          (context, package_declaration, 1);
      package_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.node_span (context, package_declaration);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, root) =
         Adac.AST.Compilation_Unit_Node and then
         Adac.Compilation.Syntax.kind_of (context, package_declaration) =
           Adac.AST.Package_Declaration_Node,
         "selected package lost its compilation ownership");
      require
        (Adac.Compilation.Syntax.package_defining_name_count
           (context, package_declaration) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.package_defining_name_symbol_at
              (context, package_declaration, 1)) = "Adac" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.package_defining_name_symbol_at
              (context, package_declaration, 2)) = "Driver",
         "selected package lost its defining components");
      require
        (Adac.Source.first_position
           (Adac.Compilation.Syntax.package_defining_name_span_at
              (context, package_declaration, 1)).line = 6 and then
         Adac.Source.first_position
           (Adac.Compilation.Syntax.package_defining_name_span_at
              (context, package_declaration, 1)).column = 9 and then
         Adac.Source.last_position
           (Adac.Compilation.Syntax.package_defining_name_span_at
              (context, package_declaration, 1)).column = 12 and then
         Adac.Source.first_position
           (Adac.Compilation.Syntax.package_defining_name_span_at
              (context, package_declaration, 2)).column = 14 and then
         Adac.Source.last_position
           (Adac.Compilation.Syntax.package_defining_name_span_at
              (context, package_declaration, 2)).column = 19,
         "selected package has the wrong defining component spans");
      require
        (Adac.Compilation.Syntax.package_visible_declaration_count
           (context, package_declaration) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, procedure_declaration) =
           Adac.AST.Procedure_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.procedure_declaration_symbol
              (context, procedure_declaration)) = "run",
         "selected package lost its procedure declaration");
      require
        (Adac.Source.first_position
           (Adac.Compilation.Syntax.procedure_declaration_defining_span
              (context, procedure_declaration)).line = 7 and then
         Adac.Source.first_position
           (Adac.Compilation.Syntax.procedure_declaration_defining_span
              (context, procedure_declaration)).column = 13 and then
         Adac.Source.last_position
           (Adac.Compilation.Syntax.procedure_declaration_defining_span
              (context, procedure_declaration)).column = 15 and then
         Adac.Source.first_position
           (Adac.Compilation.Syntax.node_span
              (context, procedure_declaration)).column = 3 and then
         Adac.Source.last_position
           (Adac.Compilation.Syntax.node_span
              (context, procedure_declaration)).column = 16,
         "selected package procedure has the wrong source spans");
      require
        (Adac.Compilation.Syntax.package_end_name_count
           (context, package_declaration) = 2 and then
         Adac.Compilation.Syntax.package_end_name_symbol_at
           (context, package_declaration, 1) =
           Adac.Compilation.Syntax.package_defining_name_symbol_at
             (context, package_declaration, 1) and then
         Adac.Compilation.Syntax.package_end_name_symbol_at
           (context, package_declaration, 2) =
           Adac.Compilation.Syntax.package_defining_name_symbol_at
             (context, package_declaration, 2),
         "selected package lost its closing components");
      require
        (Adac.Source.first_position
           (Adac.Compilation.Syntax.package_end_name_span_at
              (context, package_declaration, 1)).line = 8 and then
         Adac.Source.first_position
           (Adac.Compilation.Syntax.package_end_name_span_at
              (context, package_declaration, 1)).column = 5 and then
         Adac.Source.last_position
           (Adac.Compilation.Syntax.package_end_name_span_at
              (context, package_declaration, 1)).column = 8 and then
         Adac.Source.first_position
           (Adac.Compilation.Syntax.package_end_name_span_at
              (context, package_declaration, 2)).column = 10 and then
         Adac.Source.last_position
           (Adac.Compilation.Syntax.package_end_name_span_at
              (context, package_declaration, 2)).column = 15,
         "selected package has the wrong closing component spans");
      require
        (Adac.Source.first_position (package_span).line = 6 and then
         Adac.Source.first_position (package_span).column = 1 and then
         Adac.Source.last_position (package_span).line = 8 and then
         Adac.Source.last_position (package_span).column = 16 and then
         Adac.Compilation.Syntax.node_span (context, root) = package_span,
         "selected package or root has the wrong complete span");

      declare
        analysis : constant Adac.Sema.Analysis_Result :=
          Adac.Sema.analyze (context, root);
      begin
        require
          (analysis.status = Adac.Sema.Analysis_Rejected,
           "selected package semantic boundary did not reject analysis");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "selected package semantic boundary changed diagnostics");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "selected package semantic rejection published an entity");
      end;
    end;
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.ads";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 0));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "procedure declaration AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "procedure declaration AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "procedure declaration AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "procedure declaration AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "procedure declaration AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.ads";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 1));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "selected package parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "selected package parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "selected package parent AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "selected package parent AST limit published a partial package");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.ads";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 2));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "selected package root AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "selected package root AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 3,
       "selected package root AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "selected package root AST limit published a partial root");
  end;

  declare
    path : constant String :=
      "tests/declarations/subunits/package-body-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "subunit package-body fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "subunit package-body fixture recorded a parse diagnostic");

    declare
      subunit_node : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.unit_item (context, result.root);
      proper_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.subunit_proper_body (context, subunit_node);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, subunit_node) =
           Adac.AST.Subunit_Node and then
         Adac.Compilation.Syntax.subunit_parent_name_count
           (context, subunit_node) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.subunit_parent_name_symbol_at
              (context, subunit_node, 1)) = "Parent" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.subunit_parent_name_symbol_at
              (context, subunit_node, 2)) = "Unit",
         "subunit lost its ordered parent unit name");
      require
        (Adac.Compilation.Syntax.kind_of (context, proper_body) =
           Adac.AST.Package_Body_Node and then
         Adac.Compilation.Syntax.package_body_defining_name_count
           (context, proper_body) = 1 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.package_body_defining_name_symbol_at
              (context, proper_body, 1)) = "Child",
         "subunit lost its proper package body");

      declare
        rejected : Boolean := False;
      begin
        begin
          declare
            ignored : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.library_item (context, result.root);
            pragma Unreferenced (ignored);
          begin
            null;
          end;
        exception
          when Program_Error =>
            rejected := True;
        end;
        require
          (rejected,
           "subunit compilation unit was exposed as an ordinary library item");
      end;

      Adac.Compilation.Syntax.validate_package_body (context, proper_body);
      Adac.Compilation.Syntax.validate_subunit (context, subunit_node);
      Adac.Compilation.Syntax.validate (context, result.root);
      require
        (Adac.Compilation.Semantics.entity_count (context) = 0,
         "subunit syntax fixture published semantics");
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subunits/procedure-body-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "subunit procedure-body fixture did not parse cleanly");

    declare
      subunit_node : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.unit_item (context, result.root);
      proper_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.subunit_proper_body (context, subunit_node);
      statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.statement_at (context, proper_body, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, subunit_node) =
           Adac.AST.Subunit_Node and then
         Adac.Compilation.Syntax.subunit_parent_name_count
           (context, subunit_node) = 1 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.subunit_parent_name_symbol_at
              (context, subunit_node, 1)) = "Parent",
         "procedure subunit lost its parent-unit name");
      require
        (Adac.Compilation.Syntax.kind_of (context, proper_body) =
           Adac.AST.Procedure_Body_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.procedure_symbol
              (context, proper_body)) = "Child" and then
         Adac.Compilation.Syntax.statement_count
           (context, proper_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, statement) =
           Adac.AST.Procedure_Call_Statement_Node,
         "procedure subunit lost its represented proper body");
      Adac.Compilation.Syntax.validate_procedure_body (context, proper_body);
      Adac.Compilation.Syntax.validate_subunit (context, subunit_node);
      Adac.Compilation.Syntax.validate (context, result.root);
      require
        (Adac.Compilation.Semantics.entity_count (context) = 0,
         "procedure subunit syntax fixture published semantics");
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-return-expression-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "function-body return fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function-body return fixture recorded a parse diagnostic");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      second_parameter : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_parameter_at
          (context, function_body, 2);
      result_subtype : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_result_subtype
          (context, function_body);
      handled_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, handled_sequence, 1);
      return_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      callable : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, return_expression);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, package_body) =
           Adac.AST.Package_Body_Node and then
         Adac.Compilation.Syntax.package_body_declaration_count
           (context, package_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, function_body) =
           Adac.AST.Function_Body_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.function_body_symbol
              (context, function_body)) = "Wrap",
         "package body lost its function-body identity");
      require
        (Adac.Compilation.Syntax.function_body_parameter_count
           (context, function_body) = 2 and then
         Adac.Compilation.Syntax.parameter_default_expression
           (context, second_parameter) /= Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context,
               Adac.Compilation.Syntax.parameter_default_expression
                 (context, second_parameter))) = "Default_Value",
         "function body lost its parameters or default expression");
      require
        (Adac.Compilation.Syntax.kind_of (context, result_subtype) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, result_subtype)) = "Integer",
         "function body lost its result subtype");
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, handled_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, return_statement) and then
         Adac.Compilation.Syntax.kind_of (context, return_expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, return_expression) = 2,
         "function body lost its represented return expression");
      require
        (Adac.Compilation.Syntax.kind_of (context, callable) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, callable)) = "Call" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context,
               Adac.Compilation.Syntax.parenthesized_item_at
                 (context, return_expression, 1))) = "value" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context,
               Adac.Compilation.Syntax.parenthesized_item_at
                 (context, return_expression, 2))) = "fallback",
         "function return call lost its callable or ordered actuals");
      require
        (Adac.Compilation.Syntax.function_body_has_end_designator
           (context, function_body) and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.function_body_end_symbol
              (context, function_body)) = "Wrap",
         "function body lost its closing designator");
      Adac.Compilation.Syntax.validate_return_statement
        (context, return_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-unary-minus-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "unary-minus function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.unary_operand (context, expression);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Unary_Operator_Node and then
         Adac.Compilation.Syntax.unary_operator_spelling
           (context, expression) = "-" and then
         Adac.Compilation.Syntax.kind_of (context, operand) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, operand) = "2_147_483_648",
         "unary-minus expression lost operator/operand ownership");
      Adac.Compilation.Syntax.validate_expression (context, expression);
      Adac.Compilation.Syntax.validate_return_statement
        (context, return_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-short-circuit-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "short-circuit function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      outer_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      inner_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_left_operand
          (context, outer_condition);
      outer_right : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, outer_condition);
      inner_left : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_left_operand
          (context, inner_condition);
      inner_right : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, inner_condition);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, outer_condition) =
             Adac.AST.Or_Else_Short_Circuit_Operator and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, inner_condition) =
             Adac.AST.Or_Else_Short_Circuit_Operator,
         "short-circuit parser did not preserve left-associated chain syntax");
      require
        (Adac.Compilation.Syntax.kind_of (context, inner_left) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_right) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.kind_of (context, outer_right) =
           Adac.AST.Unary_Operator_Node,
         "short-circuit parser lost represented relation/unary operands");
      declare
        first_left : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.relation_left_operand
            (context, inner_left);
        second_left : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.relation_left_operand
            (context, inner_right);
        unary_operand : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.unary_operand (context, outer_right);
        nested_item : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.parenthesized_item_at
            (context, unary_operand, 1);
      begin
        require
          (Adac.Compilation.Syntax.kind_of (context, first_left) =
             Adac.AST.Selected_Component_Node and then
           Adac.Compilation.Syntax.kind_of (context, second_left) =
             Adac.AST.Selected_Component_Node and then
           first_left /= second_left,
           "repeated parenthesized names leaked publication state");
        require
          (Adac.Compilation.Syntax.kind_of (context, unary_operand) =
             Adac.AST.Parenthesized_Name_Node and then
           Adac.Compilation.Syntax.parenthesized_item_count
             (context, unary_operand) = 1 and then
           Adac.Compilation.Syntax.kind_of (context, nested_item) =
             Adac.AST.Selected_Component_Node,
           "parenthesized name lost selected-component item syntax");
      end;
      Adac.Compilation.Syntax.validate_short_circuit_expression
        (context, outer_condition);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-parenthesized-short-circuit-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "parenthesized short-circuit fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      outer_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      parenthesized_right : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, outer_condition);
      inner_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, parenthesized_right);
      inner_left : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_left_operand
          (context, inner_condition);
      inner_right : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, inner_condition);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, outer_condition) =
             Adac.AST.Or_Else_Short_Circuit_Operator and then
         Adac.Compilation.Syntax.kind_of (context, parenthesized_right) =
           Adac.AST.Parenthesized_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, inner_condition) =
             Adac.AST.And_Then_Short_Circuit_Operator and then
         Adac.Compilation.Syntax.kind_of (context, inner_left) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_right) =
           Adac.AST.Unary_Operator_Node,
         "parenthesized short-circuit parser lost nested ownership");
      Adac.Compilation.Syntax.validate_expression (context, outer_condition);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-parenthesized-unary-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "parenthesized-unary function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      relation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      parenthesized : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand (context, relation);
      unary : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, parenthesized);
      operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.unary_operand (context, unary);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, relation) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.kind_of (context, parenthesized) =
           Adac.AST.Parenthesized_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, unary) =
           Adac.AST.Unary_Operator_Node and then
         Adac.Compilation.Syntax.kind_of (context, operand) =
           Adac.AST.Selected_Name_Node,
         "parenthesized unary parser lost relation/primary ownership");
      Adac.Compilation.Syntax.validate_expression (context, relation);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-relation-parenthesized-attribute-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "parenthesized-attribute relation fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      relation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      right_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand
          (context, relation);
      attribute_item : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, right_operand, 1);
      attribute_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, attribute_item);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, relation) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, relation) = ">=" and then
         Adac.Compilation.Syntax.kind_of (context, right_operand) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, right_operand) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, attribute_item) =
           Adac.AST.Attribute_Name_Node,
         "relation lost parenthesized attribute-item ownership");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, attribute_prefix)) = "Positive" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.attribute_symbol
              (context, attribute_item)) = "Last",
         "parenthesized attribute item lost prefix/designator symbols");
      Adac.Compilation.Syntax.validate_expression (context, relation);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-parenthesized-name-actuals-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "parenthesized-name actual fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      first_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 1);
      second_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 2);
      second_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, second_actual);
      nested_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, second_prefix, 1);
      third_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 3);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, expression) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, first_actual) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_actual) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_prefix) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, nested_actual) =
           Adac.AST.Binary_Adding_Node and then
         Adac.Compilation.Syntax.kind_of (context, third_actual) =
           Adac.AST.Binary_Adding_Node,
         "parenthesized-name actuals lost nested/binary ownership");
      require
        (Adac.Compilation.Syntax.binary_adding_operator_spelling
           (context, nested_actual) = "+" and then
         Adac.Compilation.Syntax.binary_adding_operator_spelling
           (context, third_actual) = "-",
         "parenthesized-name actuals lost adding operator spelling");
      Adac.Compilation.Syntax.validate_name (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-repeated-parenthesized-name-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "repeated-parenthesized return fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      outer_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, expression);
      inner_parenthesized : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, outer_prefix);
      outer_item : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, outer_prefix) =
           Adac.AST.Selected_Component_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_parenthesized) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, expression) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, outer_item) =
           Adac.AST.Identifier_Name_Node,
         "repeated parenthesized return lost suffix ownership");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, outer_prefix)) =
           "exception_handler_choices_value" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, outer_item)) = "index",
         "repeated parenthesized return lost selector/item symbols");
      Adac.Compilation.Syntax.validate_name (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-multiplying-relation-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "multiplying relation fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      relation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      right_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand (context, relation);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, relation) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, relation) = ">" and then
         Adac.Compilation.Syntax.kind_of (context, right_operand) =
           Adac.AST.Binary_Multiplying_Node and then
         Adac.Compilation.Syntax.binary_multiplying_operator_spelling
           (context, right_operand) = "/",
         "multiplying relation lost relation/term ownership");
      Adac.Compilation.Syntax.validate_expression (context, relation);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-range-membership-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "range membership fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      left_membership : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_left_operand
          (context, expression);
      right_membership : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, expression);
      left_range : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_choice_at
          (context, left_membership, 1);
      right_range : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_choice_at
          (context, right_membership, 1);
      left_lower : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_range_choice_lower_bound
          (context, left_range);
      left_upper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_range_choice_upper_bound
          (context, left_range);
      right_lower : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_range_choice_lower_bound
          (context, right_range);
      right_upper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_range_choice_upper_bound
          (context, right_range);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, expression) =
           Adac.AST.Or_Else_Short_Circuit_Operator and then
         Adac.Compilation.Syntax.kind_of (context, left_membership) =
           Adac.AST.Membership_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, right_membership) =
           Adac.AST.Membership_Expression_Node and then
         Adac.Compilation.Syntax.membership_choice_count
           (context, left_membership) = 1 and then
         Adac.Compilation.Syntax.membership_choice_count
           (context, right_membership) = 1,
         "range membership lost short-circuit/membership ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, left_range) =
           Adac.AST.Membership_Range_Choice_Node and then
         Adac.Compilation.Syntax.kind_of (context, right_range) =
           Adac.AST.Membership_Range_Choice_Node and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, left_lower) = "'A'" and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, left_upper) = "'Z'" and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, right_lower) = "'a'" and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, right_upper) = "'z'",
         "range membership lost explicit range bounds");
      Adac.Compilation.Syntax.validate_expression (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-membership-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "membership function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      membership : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      tested : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_tested_expression
          (context, membership);
      first_choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_choice_at
          (context, membership, 1);
      second_choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.membership_choice_at
          (context, membership, 2);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, membership) =
           Adac.AST.Membership_Expression_Node and then
         Adac.Compilation.Syntax.membership_operator (context, membership) =
           Adac.AST.Not_In_Membership_Operator and then
         Adac.Compilation.Syntax.membership_choice_count
           (context, membership) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, tested)) = "form" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, first_choice)) = "Discrete_Range_Loop_Form" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, second_choice)) = "Generalized_Iterator_Loop_Form",
         "membership fixture lost tested/operator/choice ownership");
      Adac.Compilation.Syntax.validate_expression (context, membership);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-attribute-parenthesized-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "attribute-parenthesized function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      attribute_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, expression);
      value_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, attribute_name) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.attribute_symbol
              (context, attribute_name)) = "image" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, value_name)) = "value",
         "attribute-parenthesized return lost attribute/item ownership");
      Adac.Compilation.Syntax.validate_name (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/function-body-slice-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "slice function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      slice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      lower : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.slice_lower_bound (context, slice);
      upper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.slice_upper_bound (context, slice);
      lower_left : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.binary_adding_left_operand (context, lower);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, slice) =
           Adac.AST.Slice_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, lower) =
           Adac.AST.Binary_Adding_Node and then
         Adac.Compilation.Syntax.kind_of (context, lower_left) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, upper) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.attribute_symbol
              (context, lower_left)) = "first" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.attribute_symbol (context, upper)) =
           "last",
         "slice return lost range-bound ownership");
      Adac.Compilation.Syntax.validate_name (context, slice);
      Adac.Compilation.Syntax.validate_expression (context, slice);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-extended-return-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "extended-return function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      function_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      extended_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, function_sequence, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.extended_return_subtype_mark
          (context, extended_return);
      return_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.extended_return_handled_sequence
          (context, extended_return);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, return_sequence, 1);
      call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, return_sequence, 2);
      null_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, return_sequence, 3);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, extended_return) =
           Adac.AST.Extended_Return_Statement_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.extended_return_symbol
              (context, extended_return)) = "result" and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, return_sequence) = 3 and then
         Adac.Compilation.Syntax.handled_sequence_handler_count
           (context, return_sequence) = 0 and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, call) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, null_statement) =
           Adac.AST.Null_Statement_Node,
         "extended return lost defining/subtype/body ownership");
      Adac.Compilation.Syntax.validate_extended_return_statement
        (context, extended_return);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-character-literal-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "character-literal function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      outer_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      inner_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_left_operand
          (context, outer_condition);
      second_relation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, inner_condition);
      third_relation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, outer_condition);
      second_literal : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand
          (context, second_relation);
      third_literal : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand
          (context, third_relation);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, outer_condition) =
             Adac.AST.Or_Else_Short_Circuit_Operator and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, inner_condition) =
             Adac.AST.Or_Else_Short_Circuit_Operator,
         "character-literal condition lost its or-else chain");
      require
        (Adac.Compilation.Syntax.kind_of (context, second_literal) =
           Adac.AST.Character_Literal_Node and then
         Adac.Compilation.Syntax.kind_of (context, third_literal) =
           Adac.AST.Character_Literal_Node and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, second_literal) = "'""'" and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, third_literal) = "'""'",
         "character-literal relation operands lost exact syntax");
      Adac.Compilation.Syntax.validate_expression (context, outer_condition);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-relational-operators-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);

    function expected_operator (index : Positive) return String is
    begin
      case index is
        when 1 =>
          return "=";
        when 2 =>
          return "/=";
        when 3 =>
          return "<";
        when 4 =>
          return "<=";
        when 5 =>
          return ">";
        when 6 =>
          return ">=";
        when others =>
          raise Program_Error with "unexpected relational operator index";
      end case;
    end expected_operator;
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "relational-operator function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 7,
         "relational-operator function lost its statement sequence");

      for index in 1 .. 6 loop
        declare
          statement : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, sequence, index);
          condition : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.if_condition (context, statement);
        begin
          require
            (Adac.Compilation.Syntax.kind_of (context, statement) =
               Adac.AST.If_Statement_Node and then
             Adac.Compilation.Syntax.kind_of (context, condition) =
               Adac.AST.Relation_Node and then
             Adac.Compilation.Syntax.relation_operator_spelling
               (context, condition) = expected_operator (index),
             "relational operator parser lost relation spelling");
          Adac.Compilation.Syntax.validate_expression (context, condition);
          Adac.Compilation.Syntax.validate_if_statement (context, statement);
        end;
      end loop;

      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-nested-if-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested-if function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      middle_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, outer_if, 1);
      inner_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, middle_if, 1);
      inner_else : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_else_statement_at
          (context, inner_if, 1);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, outer_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, middle_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_else) =
           Adac.AST.Procedure_Call_Statement_Node,
         "nested-if parser lost bottom-up statement ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, outer_if);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-elsif-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "elsif function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      first_part : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_elsif_part_at (context, statement, 1);
      second_part : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_elsif_part_at (context, statement, 2);
      first_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.elsif_condition (context, first_part);
      second_condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.elsif_condition (context, second_part);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, statement) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.if_elsif_part_count
           (context, statement) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, first_part) =
           Adac.AST.Elsif_Part_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_part) =
           Adac.AST.Elsif_Part_Node and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, first_condition) = "/=" and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, second_condition) = "<" and then
         Adac.Compilation.Syntax.elsif_statement_count
           (context, first_part) = 1 and then
         Adac.Compilation.Syntax.elsif_statement_count
           (context, second_part) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.elsif_statement_at
              (context, first_part, 1)) = Adac.AST.Raise_Statement_Node and then
         Adac.Compilation.Syntax.if_else_statement_count
           (context, statement) = 1,
         "elsif parser lost ordered alternative ownership");
      Adac.Compilation.Syntax.validate_elsif_part (context, first_part);
      Adac.Compilation.Syntax.validate_elsif_part (context, second_part);
      Adac.Compilation.Syntax.validate_if_statement (context, statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-assignment-not-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "unary-not assignment fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.assignment_expression
          (context, assignment);
      operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.unary_operand (context, expression);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Unary_Operator_Node and then
         Adac.Compilation.Syntax.unary_operator_spelling
           (context, expression) = "not" and then
         Adac.Compilation.Syntax.kind_of (context, operand) =
           Adac.AST.Selected_Name_Node,
         "assignment lost exact unary-not expression ownership");
      Adac.Compilation.Syntax.validate_assignment_statement
        (context, assignment);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-assignment-relation-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "relation assignment fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      relation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.assignment_expression
          (context, assignment);
      left_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_left_operand (context, relation);
      right_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand (context, relation);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, relation) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, relation) = "=" and then
         Adac.Compilation.Syntax.kind_of (context, left_operand) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, right_operand) =
           Adac.AST.Identifier_Name_Node,
         "assignment lost exact relation expression ownership");
      Adac.Compilation.Syntax.validate_assignment_statement
        (context, assignment);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-if-assignment-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "if-assignment function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      part : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_elsif_part_at (context, statement, 1);
      then_assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at (context, statement, 1);
      elsif_assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.elsif_statement_at (context, part, 1);
      else_assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_else_statement_at (context, statement, 1);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, then_assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, elsif_assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, else_assignment) =
           Adac.AST.Assignment_Statement_Node,
         "if assignment dispatcher lost branch ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-block-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function block fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, block_statement) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, block_sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, block_sequence, 1)) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, block_sequence, 2)) =
           Adac.AST.Assignment_Statement_Node,
         "function body lost standalone block ownership");
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-if-block-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "if/block function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_else_statement_at
          (context, outer_if, 1);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
      block_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, block_sequence, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, block_statement) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_handler_count
           (context, block_sequence) = 0 and then
         Adac.Compilation.Syntax.kind_of (context, block_if) =
           Adac.AST.If_Statement_Node,
         "if/block parser lost mixed compound ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, outer_if);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-if-bare-handler-block-current/" &
      "input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "if/bare handled-block fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      bare_block : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, outer_if, 1);
      bare_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, bare_block);
      inner_block : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, bare_sequence, 1);
      inner_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, inner_block);
      handler : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_handler_at
          (context, bare_sequence, 1);
      handler_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.if_then_statement_count
           (context, outer_if) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, bare_block) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, bare_block) = 0 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, bare_sequence) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_handler_count
           (context, bare_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, inner_block) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, inner_block) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, inner_sequence, 1)) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, handler_statement) =
           Adac.AST.Procedure_Call_Statement_Node,
         "if arm lost bare handled-block ownership");
      Adac.Compilation.Syntax.validate_exception_handler (context, handler);
      Adac.Compilation.Syntax.validate_block_statement (context, inner_block);
      Adac.Compilation.Syntax.validate_block_statement (context, bare_block);
      Adac.Compilation.Syntax.validate_if_statement (context, outer_if);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-compound-case-return-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "compound case return fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      outer_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, outer_if, 1);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, outer_loop, 1);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      second_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 2);
      first_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 1);
      second_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, second_alternative, 1);
      first_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression (context, first_return);
      second_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression (context, second_return);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, first_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, first_return) and then
         Adac.Compilation.Syntax.kind_of (context, first_expression) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context, Adac.Compilation.Syntax.identifier_symbol
             (context, first_expression)) = "True" and then
         Adac.Compilation.Syntax.kind_of (context, second_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, second_return) and then
         Adac.Compilation.Syntax.kind_of (context, second_expression) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context, Adac.Compilation.Syntax.identifier_symbol
             (context, second_expression)) = "False",
         "compound case alternatives lost return-expression ownership");
      Adac.Compilation.Syntax.validate_case_statement
        (context, case_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-if-loop-case-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "if/loop/case function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      outer_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, outer_if, 1);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, outer_loop, 1);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      nested_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 1);
      alternative_block : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 2);
      nested_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, nested_if, 1);
      else_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_else_statement_at
          (context, outer_if, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, outer_loop) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, case_statement) =
           Adac.AST.Case_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, nested_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.case_alternative_statement_count
           (context, first_alternative) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, alternative_block) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, alternative_block) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, nested_loop) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, else_loop) =
           Adac.AST.Loop_Statement_Node,
         "if/loop/case parser lost alternating compound ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, outer_if);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-if-case-sequence-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "if/case sequence function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      nested_if : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_else_statement_at
          (context, outer_if, 1);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_else_statement_at
          (context, outer_if, 2);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      first_call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 1);
    begin
      require
        (Adac.Compilation.Syntax.if_else_statement_count
           (context, outer_if) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, nested_if) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, case_statement) =
           Adac.AST.Case_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, first_call) =
           Adac.AST.Procedure_Call_Statement_Node,
         "if else arm lost ordered if/case ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, outer_if);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/" &
      "function-body-iterator-loop-assignment-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "iterator assignment function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, loop_statement) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 4 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.loop_statement_at
              (context, loop_statement, 1)) =
              Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.loop_statement_at
              (context, loop_statement, 2)) =
              Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.loop_statement_at
              (context, loop_statement, 3)) =
              Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.loop_statement_at
              (context, loop_statement, 4)) =
              Adac.AST.Procedure_Call_Statement_Node,
         "iterator parser lost source-ordered assignment/call ownership");
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-loop-block-exit-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "loop block exit fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      function_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, function_sequence, 1);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 1);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
      exit_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, block_sequence, 1);
      condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exit_condition (context, exit_statement);
    begin
      require
        (Adac.Compilation.Syntax.loop_form (context, loop_statement) =
           Adac.AST.Simple_Loop_Form and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, block_statement) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, block_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, exit_statement) =
           Adac.AST.Exit_Statement_Node and then
         Adac.Compilation.Syntax.exit_has_condition
           (context, exit_statement) and then
         Adac.Compilation.Syntax.kind_of (context, condition) =
           Adac.AST.Identifier_Name_Node,
         "loop block lost represented conditional exit ownership");
      Adac.Compilation.Syntax.validate_exit_statement
        (context, exit_statement);
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/" &
      "function-body-iterator-loop-case-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "iterator case function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 1);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      second_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 2);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, loop_statement) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, case_statement) =
           Adac.AST.Case_Statement_Node and then
         Adac.Compilation.Syntax.case_alternative_count
           (context, case_statement) = 2,
         "iterator parser lost its case-statement child");
      require
        (Adac.Compilation.Syntax.case_alternative_choice_count
           (context, first_alternative) = 2 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.case_alternative_choice_at
              (context, first_alternative, 1)) =
              Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.case_alternative_choice_at
              (context, first_alternative, 2)) =
              Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Syntax.case_alternative_statement_count
           (context, first_alternative) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.case_alternative_statement_at
              (context, first_alternative, 1)) =
              Adac.AST.Procedure_Call_Statement_Node,
         "iterator case lost ordered multiple choices or call body");
      require
        (Adac.Compilation.Syntax.case_alternative_choice_count
           (context, second_alternative) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.case_alternative_choice_at
              (context, second_alternative, 1)) =
              Adac.AST.Others_Case_Choice_Node and then
         Adac.Compilation.Syntax.case_alternative_statement_count
           (context, second_alternative) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.case_alternative_statement_at
              (context, second_alternative, 1)) =
              Adac.AST.Raise_Statement_Node,
         "iterator case lost sole others choice or raise body");
      Adac.Compilation.Syntax.validate_case_statement
        (context, case_statement);
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-case-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function-body case fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      second_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 2);
      first_block : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 2);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, case_statement) =
           Adac.AST.Case_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.case_alternative_choice_count
           (context, first_alternative) = 2 and then
         Adac.Compilation.Syntax.case_alternative_statement_count
           (context, first_alternative) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, first_block) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, first_block) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.case_alternative_choice_at
              (context, second_alternative, 1)) =
              Adac.AST.Others_Case_Choice_Node,
         "function body lost direct case/return ownership");
      Adac.Compilation.Syntax.validate_case_statement
        (context, case_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-case-loop-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "case-loop function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 2);
      loop_call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 1);
      trailing_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 3);
    begin
      require
        (Adac.Compilation.Syntax.case_alternative_statement_count
           (context, first_alternative) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, loop_statement) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_form (context, loop_statement) =
           Adac.AST.Discrete_Range_Loop_Form and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, loop_call) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, trailing_return) =
           Adac.AST.Return_Statement_Node,
         "case alternative lost ordered loop/return ownership");
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_case_statement
        (context, case_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-if-return-expression-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "if-return-expression function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      branch_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, if_statement, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, branch_return);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, branch_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, branch_return) and then
         Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, expression)) = "value",
         "if arm lost represented return-expression ownership");
      Adac.Compilation.Syntax.validate_return_statement
        (context, branch_return);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-nested-case-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested-case function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_case : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      outer_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, outer_case, 1);
      inner_case : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, outer_alternative, 1);
      inner_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, inner_case, 1);
      inner_call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, inner_alternative, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_case) =
           Adac.AST.Case_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_case) =
           Adac.AST.Case_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner_call) =
           Adac.AST.Procedure_Call_Statement_Node,
         "nested case lost case/call ownership");
      Adac.Compilation.Syntax.validate_case_statement (context, outer_case);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-case-return-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "case-return function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_statement_at
          (context, first_alternative, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, return_statement) and then
         Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Selected_Component_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, expression)) = "selected_prefix",
         "case alternative lost represented return-expression ownership");
      Adac.Compilation.Syntax.validate_return_statement
        (context, return_statement);
      Adac.Compilation.Syntax.validate_case_statement
        (context, case_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-case-integer-choice-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "integer case-choice fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_choice_at
          (context, first_alternative, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, choice) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_form (context, choice) =
           Adac.AST.Decimal_Integer_Form and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, choice) = "1",
         "case statement lost integer choice ownership");
      Adac.Compilation.Syntax.validate_case_statement
        (context, case_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-case-character-choice-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "character case-choice fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      case_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_at
          (context, case_statement, 1);
      choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_alternative_choice_at
          (context, first_alternative, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, choice) =
           Adac.AST.Character_Literal_Node and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, choice) = "'='",
         "case statement lost character choice ownership");
      Adac.Compilation.Syntax.validate_case_statement
        (context, case_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/operators/" &
      "function-body-and-then-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "and-then function fixture did not parse cleanly");
    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, condition) =
             Adac.AST.And_Then_Short_Circuit_Operator,
         "and-then parser lost short-circuit operator ownership");
      Adac.Compilation.Syntax.validate_short_circuit_expression
        (context, condition);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-if-raise-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function-body if/raise fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      raise_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, if_statement, 1);
      exception_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.raise_exception_name
          (context, raise_statement);
      message : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.raise_message_expression
          (context, raise_statement);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, if_statement) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.if_then_statement_count
           (context, if_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, raise_statement) =
           Adac.AST.Raise_Statement_Node,
         "function body lost represented if/raise ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, exception_name) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, exception_name)) = "Program_Error" and then
         Adac.Compilation.Syntax.kind_of (context, message) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling
           (context, message) = """empty""",
         "raise statement lost exception name or message");
      Adac.Compilation.Syntax.validate_raise_statement
        (context, raise_statement);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-if-raise-expression-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function-body raise-expression fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      raise_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, if_statement, 1);
      message : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.raise_message_expression
          (context, raise_statement);
      left_message : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.binary_adding_left_operand
          (context, message);
      right_message : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.binary_adding_right_operand
          (context, message);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, raise_statement) =
           Adac.AST.Raise_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, message) =
           Adac.AST.Binary_Adding_Node and then
         Adac.Compilation.Syntax.kind_of (context, left_message) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.kind_of (context, right_message) =
           Adac.AST.String_Literal_Node,
         "raise statement lost represented concatenation message");
      Adac.Compilation.Syntax.validate_raise_statement
        (context, raise_statement);
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/aggregates/" &
      "function-body-record-aggregate-adding-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "record aggregate adding fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      owner_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, aggregate, 1);
      index_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, aggregate, 2);
      index_left : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.binary_adding_left_operand
          (context, index_value);
      index_right : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.binary_adding_right_operand
          (context, index_value);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, aggregate) =
           Adac.AST.Record_Aggregate_Node and then
         Adac.Compilation.Syntax.record_aggregate_association_count
           (context, aggregate) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, owner_value) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, index_value) =
           Adac.AST.Binary_Adding_Node,
         "record aggregate lost attribute/binary association values");
      require
        (Adac.Compilation.Syntax.kind_of (context, index_left) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, index_right) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, index_right) = "1",
         "record aggregate lost binary-adding operand ownership");
      Adac.Compilation.Syntax.validate_record_aggregate (context, aggregate);
      Adac.Compilation.Syntax.validate_return_statement
        (context, return_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/aggregates/" &
      "function-body-record-aggregate-nested-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested record aggregate fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      first_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, aggregate, 1);
      last_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, aggregate, 2);
      first_line : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, first_value, 2);
      last_column : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, last_value, 3);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, aggregate) =
           Adac.AST.Record_Aggregate_Node and then
         Adac.Compilation.Syntax.record_aggregate_association_count
           (context, aggregate) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_aggregate_selector_symbol_at
              (context, aggregate, 1)) = "first" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_aggregate_selector_symbol_at
              (context, aggregate, 2)) = "last" and then
         Adac.Compilation.Syntax.kind_of (context, first_value) =
           Adac.AST.Record_Aggregate_Node and then
         Adac.Compilation.Syntax.kind_of (context, last_value) =
           Adac.AST.Record_Aggregate_Node,
         "record aggregate lost direct nested aggregate ownership");
      require
        (Adac.Compilation.Syntax.record_aggregate_association_count
           (context, first_value) = 3 and then
         Adac.Compilation.Syntax.record_aggregate_association_count
           (context, last_value) = 3 and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, first_line) = "1" and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, last_column) = "3",
         "nested record aggregate lost ordered component values");
      Adac.Compilation.Syntax.validate_record_aggregate (context, aggregate);
      Adac.Compilation.Syntax.validate_return_statement
        (context, return_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    DEPTH : constant Positive := 4_096;
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "record-aggregate-deep-nested-value.adb");
    selector : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "A");
    current : Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context,
         Adac.AST.Decimal_Integer_Form,
         "1",
         Adac.Source.make_span
           (Adac.Source.make_position (file_id, DEPTH + 1, 10),
            Adac.Source.make_position (file_id, DEPTH + 1, 10)));
  begin
    for level in reverse 1 .. DEPTH loop
      declare
        associations : Adac.AST.Record_Component_Association_List;
        selector_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, level, 2),
             Adac.Source.make_position (file_id, level, 2));
        aggregate_span : constant Adac.Source.Span :=
          Adac.Source.make_span
            (Adac.Source.make_position (file_id, level, 1),
             Adac.Source.make_position
               (file_id, 2 * DEPTH - level + 2, 1));
      begin
        Adac.AST.append
          (associations, selector, selector_span, current);
        current := Adac.Compilation.Syntax.create_record_aggregate
          (context, associations, aggregate_span);
      end;
    end loop;

    Adac.Compilation.Syntax.validate_record_aggregate (context, current);
    require
      (Adac.Compilation.Syntax.kind_of (context, current) =
         Adac.AST.Record_Aggregate_Node and then
       Adac.Compilation.Syntax.node_count (context) = DEPTH + 1,
       "deep nested record aggregate lost bounded iterative validation");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "record-aggregate-nested-value.adb");
    inner_selector : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Inner");
    outer_selector : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Outer");
    inner_selector_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 12),
         Adac.Source.make_position (file_id, 1, 16));
    inner_literal_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 21),
         Adac.Source.make_position (file_id, 1, 21));
    inner_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 11),
         Adac.Source.make_position (file_id, 1, 22));
    plus_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 24),
         Adac.Source.make_position (file_id, 1, 24));
    right_literal_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 26),
         Adac.Source.make_position (file_id, 1, 26));
    binary_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 11),
         Adac.Source.make_position (file_id, 1, 26));
    outer_selector_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 6));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 27));
    inner_literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "1", inner_literal_span);
    inner_associations : Adac.AST.Record_Component_Association_List;
    inner_aggregate : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    right_literal : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    binary_value : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    outer_associations : Adac.AST.Record_Component_Association_List;
  begin
    Adac.AST.append
      (inner_associations,
       inner_selector,
       inner_selector_span,
       inner_literal);
    inner_aggregate := Adac.Compilation.Syntax.create_record_aggregate
      (context, inner_associations, inner_span);
    right_literal := Adac.Compilation.Syntax.create_numeric_literal
      (context, Adac.AST.Decimal_Integer_Form, "2", right_literal_span);
    binary_value := Adac.Compilation.Syntax.create_binary_adding
      (context, inner_aggregate, "+", plus_span, right_literal, binary_span);
    Adac.AST.append
      (outer_associations,
       outer_selector,
       outer_selector_span,
       binary_value);

    declare
      nodes_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.create_record_aggregate
          (context, outer_associations, outer_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then ignored = Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.node_count (context) = nodes_before,
         "record aggregate accepted nested aggregate through binary value");
    end;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "array-aggregate-nested-value.adb");
    selector : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "A");
    choice_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 2),
         Adac.Source.make_position (file_id, 1, 2));
    inner_selector_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 8),
         Adac.Source.make_position (file_id, 1, 8));
    inner_literal_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 13),
         Adac.Source.make_position (file_id, 1, 13));
    inner_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 7),
         Adac.Source.make_position (file_id, 1, 14));
    outer_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (file_id, 1, 1),
         Adac.Source.make_position (file_id, 1, 15));
    choice : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "1", choice_span);
    inner_literal : constant Adac.AST.Node_ID :=
      Adac.Compilation.Syntax.create_numeric_literal
        (context, Adac.AST.Decimal_Integer_Form, "2", inner_literal_span);
    inner_associations : Adac.AST.Record_Component_Association_List;
    inner_aggregate : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    choices : Adac.AST.Node_List;
    array_associations : Adac.AST.Array_Component_Association_List;
  begin
    Adac.AST.append
      (inner_associations, selector, inner_selector_span, inner_literal);
    inner_aggregate := Adac.Compilation.Syntax.create_record_aggregate
      (context, inner_associations, inner_span);
    Adac.AST.append (choices, choice);
    Adac.AST.append (array_associations, choices, inner_aggregate);

    declare
      nodes_before : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
      ignored : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    begin
      begin
        ignored := Adac.Compilation.Syntax.create_array_aggregate
          (context, array_associations, outer_span);
      exception
        when Program_Error =>
          rejected := True;
      end;
      require
        (rejected and then ignored = Adac.AST.INVALID_NODE_ID and then
         Adac.Compilation.Syntax.node_count (context) = nodes_before,
         "array aggregate accepted nested aggregate value");
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/aggregates/" &
      "qualified-record-aggregate-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "qualified record aggregate fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      call_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      qualified : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_call_actual_at
          (context, call_statement, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.qualified_expression_subtype_mark
          (context, qualified);
      aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.qualified_expression_operand
          (context, qualified);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, qualified) =
           Adac.AST.Qualified_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Pair" and then
         Adac.Compilation.Syntax.kind_of (context, aggregate) =
           Adac.AST.Record_Aggregate_Node,
         "qualified aggregate lost qualifier or aggregate ownership");
      require
        (Adac.Compilation.Syntax.record_aggregate_association_count
           (context, aggregate) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_aggregate_selector_symbol_at
              (context, aggregate, 1)) = "Left" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_aggregate_selector_symbol_at
              (context, aggregate, 2)) = "Right",
         "qualified aggregate lost ordered associations");
      Adac.Compilation.Syntax.validate_qualified_expression
        (context, qualified);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/aggregates/" &
      "qualified-array-aggregate-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "qualified array aggregate fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      qualified : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_initializer (context, declaration);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.qualified_expression_subtype_mark
          (context, qualified);
      aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.qualified_expression_operand
          (context, qualified);
      choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.array_aggregate_choice_at
          (context, aggregate, 1, 1);
      value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.array_aggregate_expression_at
          (context, aggregate, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, declaration) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Syntax.kind_of (context, qualified) =
           Adac.AST.Qualified_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "String" and then
         Adac.Compilation.Syntax.kind_of (context, aggregate) =
           Adac.AST.Array_Aggregate_Node,
         "qualified array aggregate lost qualifier/aggregate ownership");
      require
        (Adac.Compilation.Syntax.array_aggregate_association_count
           (context, aggregate) = 1 and then
         Adac.Compilation.Syntax.array_aggregate_choice_count
           (context, aggregate, 1) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, choice) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, choice) = "1" and then
         Adac.Compilation.Syntax.kind_of (context, value) =
           Adac.AST.Selected_Name_Node,
         "qualified array aggregate lost choice/value ownership");
      Adac.Compilation.Syntax.validate_array_aggregate (context, aggregate);
      Adac.Compilation.Syntax.validate_qualified_expression
        (context, qualified);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/qualified-direct-expression-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "qualified direct expression fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      qualified : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.qualified_expression_subtype_mark
          (context, qualified);
      operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.qualified_expression_operand
          (context, qualified);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, qualified) =
           Adac.AST.Qualified_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "String" and then
         Adac.Compilation.Syntax.kind_of (context, operand) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling
           (context, operand) = """-o""",
         "qualified direct expression lost qualifier or string operand");
      Adac.Compilation.Syntax.validate_qualified_expression
        (context, qualified);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/allocator-qualified-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "qualified allocator fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      allocator : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      qualified : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.allocator_expression (context, allocator);
      operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.qualified_expression_operand
          (context, qualified);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, allocator) =
           Adac.AST.Allocator_Node and then
         Adac.Source.first_position
           (Adac.Compilation.Syntax.allocator_new_span
              (context, allocator)).column = 12 and then
         Adac.Compilation.Syntax.kind_of (context, qualified) =
           Adac.AST.Qualified_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, operand) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling
           (context, operand) = """-o""",
         "qualified allocator lost new/qualified/string ownership");
      Adac.Compilation.Syntax.validate_allocator (context, allocator);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/objects/" &
      "function-body-constant-string-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "constant string fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      initializer : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_initializer (context, declaration);
    begin
      require
        (Adac.Compilation.Syntax.object_form (context, declaration) =
           Adac.AST.Constant_Object_Form and then
         Adac.Compilation.Syntax.kind_of (context, initializer) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling
           (context, initializer) = """class""",
         "constant initializer lost represented string ownership");
      Adac.Compilation.Syntax.validate_expression (context, initializer);
      Adac.Compilation.Syntax.validate_declaration (context, declaration);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/objects/" &
      "function-body-constant-relation-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "constant relation fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      initializer : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_initializer (context, declaration);
      left_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_left_operand
          (context, initializer);
      right_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_right_operand
          (context, initializer);
    begin
      require
        (Adac.Compilation.Syntax.object_form (context, declaration) =
           Adac.AST.Constant_Object_Form and then
         Adac.Compilation.Syntax.kind_of (context, initializer) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, initializer) = "/=" and then
         Adac.Compilation.Syntax.kind_of (context, left_operand) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, right_operand) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, right_operand) = "0",
         "constant initializer lost represented relation ownership");
      Adac.Compilation.Syntax.validate_expression (context, initializer);
      Adac.Compilation.Syntax.validate_declaration (context, declaration);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-named-actual-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "named actual fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      first_selector : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_selector
          (context, expression, 6);
      second_selector : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_selector
          (context, expression, 7);
      last_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 7);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, expression) = 7,
         "named actual call lost parenthesized item ownership");
      for index in 1 .. 5 loop
        require
          (Adac.Compilation.Syntax.parenthesized_item_form
             (context, expression, index) =
               Adac.AST.Positional_Parenthesized_Name_Item_Form,
           "named actual call changed a positional actual form");
      end loop;
      require
        (Adac.Compilation.Syntax.parenthesized_item_form
           (context, expression, 6) =
             Adac.AST.Named_Parenthesized_Name_Item_Form and then
         Adac.Compilation.Syntax.parenthesized_item_form
           (context, expression, 7) =
             Adac.AST.Named_Parenthesized_Name_Item_Form,
         "named actual call lost named association forms");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, first_selector)) = "limited_form" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, second_selector)) = "maximum_nodes",
         "named actual call lost selector ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, last_actual) =
           Adac.AST.Selected_Name_Node,
         "named actual call lost selected-name actual ownership");
      Adac.Compilation.Syntax.validate_name (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-logical-call-actual-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "logical call-actual fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      first_call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      second_call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      third_call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 3);
      first_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_call_actual_at
          (context, first_call, 1);
      second_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_call_actual_at
          (context, second_call, 1);
      third_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_call_actual_at
          (context, third_call, 1);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 4 and then
         Adac.Compilation.Syntax.kind_of (context, first_actual) =
           Adac.AST.Logical_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_actual) =
           Adac.AST.Logical_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, third_actual) =
           Adac.AST.Logical_Expression_Node,
         "logical call actuals lost represented expression ownership");
      require
        (Adac.Compilation.Syntax.logical_operator
           (context, first_actual) = Adac.AST.And_Logical_Operator and then
         Adac.Compilation.Syntax.logical_operator
           (context, second_actual) = Adac.AST.Or_Logical_Operator and then
         Adac.Compilation.Syntax.logical_operator
           (context, third_actual) = Adac.AST.Xor_Logical_Operator,
         "logical call actuals lost operator forms");
      require
        (Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context,
               Adac.Compilation.Syntax.logical_left_operand
                 (context, first_actual))) = "left" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context,
               Adac.Compilation.Syntax.logical_right_operand
                 (context, first_actual))) = "right",
         "logical call actual lost operand ownership");
      Adac.Compilation.Syntax.validate_expression (context, first_actual);
      Adac.Compilation.Syntax.validate_expression (context, second_actual);
      Adac.Compilation.Syntax.validate_expression (context, third_actual);
      Adac.Compilation.Syntax.validate_procedure_call (context, first_call);
      Adac.Compilation.Syntax.validate_procedure_call (context, second_call);
      Adac.Compilation.Syntax.validate_procedure_call (context, third_call);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-slice-relation-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested slice relation fixture did not parse cleanly");
    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      relation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression (context, statement);
      call_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.relation_left_operand (context, relation);
      slice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, call_name, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, relation) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.kind_of (context, call_name) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, slice) =
           Adac.AST.Slice_Name_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, Adac.Compilation.Syntax.slice_lower_bound
              (context, slice)) = Adac.AST.Binary_Adding_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, Adac.Compilation.Syntax.slice_upper_bound
              (context, slice)) = Adac.AST.Binary_Adding_Node,
         "nested slice relation lost call/slice/bound ownership");
      Adac.Compilation.Syntax.validate_expression (context, relation);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/aggregates/bracket-allocator-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "bracket allocator fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_initializer (context, declaration);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, declaration) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Syntax.object_has_index_constraint
           (context, declaration) and then
         Adac.Compilation.Syntax.kind_of (context, aggregate) =
           Adac.AST.Bracket_Aggregate_Node and then
         Adac.Compilation.Syntax.bracket_aggregate_expression_count
           (context, aggregate) = 3,
         "bracket allocator fixture lost object/aggregate ownership");

      for index in 1 .. 3 loop
        declare
          allocator : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.bracket_aggregate_expression_at
              (context, aggregate, index);
        begin
          require
            (Adac.Compilation.Syntax.kind_of (context, allocator) =
               Adac.AST.Allocator_Node,
             "bracket aggregate lost an allocator element");
          Adac.Compilation.Syntax.validate_allocator (context, allocator);
        end;
      end loop;

      declare
        first_allocator : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.bracket_aggregate_expression_at
            (context, aggregate, 1);
        qualified : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.allocator_expression
            (context, first_allocator);
        operand : constant Adac.AST.Node_ID :=
          Adac.Compilation.Syntax.qualified_expression_operand
            (context, qualified);
      begin
        require
          (Adac.Compilation.Syntax.string_literal_spelling
             (context, operand) = """-o""",
           "bracket aggregate first allocator lost its string operand");
      end;

      Adac.Compilation.Syntax.validate_bracket_aggregate (context, aggregate);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/names/parenthesized-explicit-dereference-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "explicit-dereference actual fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.assignment_expression
          (context, assignment);
      first_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 1);
      second_actual : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 2);
      all_span : constant Adac.Source.Span :=
        Adac.Compilation.Syntax.explicit_dereference_all_span
          (context, first_actual);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, expression) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, first_actual) =
           Adac.AST.Explicit_Dereference_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_actual) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Source.first_position (all_span).column = 44 and then
         Adac.Source.last_position (all_span).column = 46,
         "parenthesized name lost explicit-dereference actual ownership");
      require
        (Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.name_prefix
              (context, first_actual)) = Adac.AST.Identifier_Name_Node,
         "explicit dereference lost compiler_path prefix");
      Adac.Compilation.Syntax.validate_name (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-statement-sequence-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function-body statement sequence did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      call_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      null_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 3);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 4);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 4 and then
         Adac.Compilation.Syntax.kind_of (context, call_statement) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, null_statement) =
           Adac.AST.Null_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node,
         "function body lost its ordered statement kinds");
      require
        (Adac.Compilation.Syntax.procedure_call_actual_count
           (context, call_statement) = 1 and then
         Adac.Compilation.Syntax.return_has_expression
           (context, return_statement),
         "function body lost call actual or expression return ownership");
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-bare-block-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "bare block fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
      call_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, block_sequence, 1);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, block_statement) = 0 and then
         Adac.Compilation.Syntax.kind_of (context, call_statement) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node,
         "bare block fixture lost block/function statement ownership");
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-object-declaration-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "function-body declaration fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function-body declaration fixture recorded a parse diagnostic");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_subtype_mark
          (context, declaration);
    begin
      require
        (Adac.Compilation.Syntax.function_body_declaration_count
           (context, function_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, declaration) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.object_symbol
              (context, declaration)) = "local" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Integer",
         "function body lost its ordered local object declaration");
      Adac.Compilation.Syntax.validate_declaration (context, declaration);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/objects/" &
      "function-body-index-constrained-object-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "index-constrained object fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_subtype_mark
          (context, declaration);
      constraint : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_index_constraint
          (context, declaration);
      lower_bound : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.index_constraint_lower_bound
          (context, constraint);
      upper_bound : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.index_constraint_upper_bound
          (context, constraint);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, declaration) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Syntax.object_has_index_constraint
           (context, declaration) and then
         Adac.Compilation.Syntax.kind_of (context, constraint) =
           Adac.AST.Index_Constraint_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, subtype_mark)) = "Argument_List" and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, lower_bound) = "1" and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, upper_bound) = "3" and then
         not Adac.Compilation.Syntax.object_has_initializer
           (context, declaration),
         "index-constrained object lost subtype/range ownership");
      Adac.Compilation.Syntax.validate_index_constraint
        (context, constraint);
      Adac.Compilation.Syntax.validate_declaration (context, declaration);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-handlers-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function handler fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      first_handler : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_handler_at
          (context, sequence, 1);
      second_handler : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_handler_at
          (context, sequence, 2);
      first_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, first_handler, 1);
      second_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, second_handler, 1);
      first_aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression (context, first_return);
      second_aggregate : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression (context, second_return);
      diagnostic_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_aggregate_expression_at
          (context, second_aggregate, 2);
      concatenation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, diagnostic_value, 1);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.handled_sequence_handler_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.exception_handler_has_choice_parameter
           (context, first_handler) and then
         Adac.Compilation.Syntax.exception_handler_choice_count
           (context, first_handler) = 1 and then
         not Adac.Compilation.Syntax.exception_handler_has_choice_parameter
           (context, second_handler) and then
         Adac.Compilation.Syntax.exception_handler_choice_count
           (context, second_handler) = 3,
         "function body lost ordered handler ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, first_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, first_return) and then
         Adac.Compilation.Syntax.kind_of (context, first_aggregate) =
           Adac.AST.Record_Aggregate_Node and then
         Adac.Compilation.Syntax.record_aggregate_association_count
           (context, first_aggregate) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, second_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_aggregate) =
           Adac.AST.Record_Aggregate_Node and then
         Adac.Compilation.Syntax.record_aggregate_association_count
           (context, second_aggregate) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, diagnostic_value) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, diagnostic_value) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, concatenation) =
           Adac.AST.Binary_Adding_Node,
         "function handlers lost aggregate/string-concatenation returns");
      Adac.Compilation.Syntax.validate_exception_handler
        (context, first_handler);
      Adac.Compilation.Syntax.validate_exception_handler
        (context, second_handler);
      Adac.Compilation.Syntax.validate_handled_sequence (context, sequence);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-loop-nested-return-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "loop nested-return fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 1);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, if_statement, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, loop_statement) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, if_statement) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.if_then_statement_count
           (context, if_statement) = 1,
         "loop nested-return fixture lost compound statement ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, return_statement) and then
         Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, expression) = "1",
         "loop nested-return fixture lost expression return ownership");
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-block-return-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "block return fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_declaration_at
          (context, block_statement, 1);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, block_sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, block_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, declaration) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, block_sequence) = 1,
         "block return fixture lost explicit block ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, return_statement) and then
         Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Identifier_Name_Node,
         "block return fixture lost expression return ownership");
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_handled_sequence
        (context, block_sequence);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-function-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      outer_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      inner_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, outer_body, 1);
      inner_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, inner_body);
      inner_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, inner_sequence, 1);
      inner_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, inner_return);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_body) =
           Adac.AST.Function_Body_Node and then
         Adac.Compilation.Syntax.function_body_declaration_count
           (context, outer_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, inner_body) =
           Adac.AST.Function_Body_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.function_body_symbol
              (context, inner_body)) = "Inner",
         "nested function fixture lost function-body ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, inner_expression) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, inner_expression) = "1",
         "nested function fixture lost its return expression");
      Adac.Compilation.Syntax.validate_function_body (context, outer_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "function nested-procedure fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "function nested-procedure fixture recorded a parse diagnostic");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      forward_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at
          (context, nested_procedure, 1);
      forward_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at
          (context, nested_procedure, 2);
      local_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at
          (context, nested_procedure, 3);
      nested_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      first_nested_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 1);
      second_nested_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 2);
      third_nested_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 3);
      fourth_nested_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 4);
      fifth_nested_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 5);
    begin
      require
        (Adac.Compilation.Syntax.function_body_declaration_count
           (context, function_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, nested_procedure) =
           Adac.AST.Procedure_Body_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.procedure_symbol
              (context, nested_procedure)) = "Touch",
         "function body lost its nested procedure declarative child");
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, forward_declaration) =
           Adac.AST.Procedure_Declaration_Node and then
         Adac.Compilation.Syntax.kind_of (context, forward_body) =
           Adac.AST.Procedure_Body_Node and then
         Adac.Compilation.Syntax.kind_of (context, local_declaration) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, nested_sequence) = 5 and then
         Adac.Compilation.Syntax.kind_of
           (context, first_nested_statement) =
             Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, second_nested_statement) =
             Adac.AST.Case_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, third_nested_statement) =
             Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, fourth_nested_statement) =
             Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, fifth_nested_statement) =
             Adac.AST.Assignment_Statement_Node,
         "function nested procedure lost ordered declaration/statements");
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-function-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "procedure-local function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      outer_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, outer_function, 1);
      failed_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      local_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 2);
      local_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, local_function);
      local_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, local_sequence, 1);
      handler : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_handler_at
          (context, local_sequence, 1);
      first_handler_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 1);
      second_handler_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 2);
      third_handler_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 3);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, helper) =
           Adac.AST.Procedure_Body_Node and then
         Adac.Compilation.Syntax.declaration_count
           (context, helper) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, failed_declaration) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Syntax.kind_of (context, local_function) =
           Adac.AST.Function_Body_Node and then
         Adac.Compilation.Syntax.function_body_parameter_count
           (context, local_function) = 2 and then
         Adac.Compilation.Syntax.function_body_declaration_count
           (context, local_function) = 0,
         "nested procedure lost its bounded local function declaration");
      require
        (Adac.Compilation.Syntax.kind_of (context, local_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.handled_sequence_handler_count
           (context, local_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context, first_handler_statement) =
             Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, second_handler_statement) =
             Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, third_handler_statement) =
             Adac.AST.Return_Statement_Node,
         "procedure-local function lost return/handler ownership");
      Adac.Compilation.Syntax.validate_exception_handler (context, handler);
      Adac.Compilation.Syntax.validate_function_body
        (context, local_function);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body
        (context, outer_function);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-function-procedure-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "procedure-local function procedure fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      outer_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, outer_function, 1);
      local_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, local_function, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, local_function) =
           Adac.AST.Function_Body_Node and then
         Adac.Compilation.Syntax.function_body_declaration_count
           (context, local_function) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, nested_procedure) =
           Adac.AST.Procedure_Body_Node and then
         Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 0,
         "procedure-local function lost bounded procedure ownership");
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body
        (context, local_function);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body
        (context, outer_function);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-function-if-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "procedure-local function if fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      outer_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, outer_function, 1);
      local_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, local_function);
      conditional : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      final_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      nested_return : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, conditional, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, local_function) =
           Adac.AST.Function_Body_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, conditional) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.if_then_statement_count
           (context, conditional) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, nested_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, nested_return) and then
         Adac.Compilation.Syntax.kind_of (context, final_return) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, final_return),
         "procedure-local function lost compound return ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, conditional);
      Adac.Compilation.Syntax.validate_function_body
        (context, local_function);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body
        (context, outer_function);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-function-object-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "procedure-local function object fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      outer_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, outer_function, 1);
      local_function : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      local_object : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, local_function, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, local_function);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, local_function) =
           Adac.AST.Function_Body_Node and then
         Adac.Compilation.Syntax.function_body_declaration_count
           (context, local_function) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, local_object) =
           Adac.AST.Object_Declaration_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, return_statement) =
           Adac.AST.Return_Statement_Node and then
         Adac.Compilation.Syntax.return_has_expression
           (context, return_statement),
         "procedure-local function lost object/statement ownership");
      Adac.Compilation.Syntax.validate_declaration (context, local_object);
      Adac.Compilation.Syntax.validate_function_body
        (context, local_function);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body
        (context, outer_function);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-default-parameter-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested procedure default-parameter fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      first_parameter : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_at (context, helper, 1);
      second_parameter : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_at (context, helper, 2);
      third_parameter : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_at (context, helper, 3);
      first_default : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_default_expression
          (context, first_parameter);
      second_default : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_default_expression
          (context, second_parameter);
      third_default : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_default_expression
          (context, third_parameter);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, helper) =
           Adac.AST.Procedure_Body_Node and then
         Adac.Compilation.Syntax.parameter_count (context, helper) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, first_default) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, first_default)) = "Default_Mode" and then
         Adac.Compilation.Syntax.kind_of (context, second_default) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, second_default)) = "False" and then
         Adac.Compilation.Syntax.kind_of (context, third_default) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling
           (context, third_default) = """""",
         "nested procedure lost represented parameter defaults");
      Adac.Compilation.Syntax.validate_parameter (context, first_parameter);
      Adac.Compilation.Syntax.validate_parameter (context, second_parameter);
      Adac.Compilation.Syntax.validate_parameter (context, third_parameter);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-enumeration-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested procedure enumeration fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      enumeration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, enumeration) =
           Adac.AST.Enumeration_Type_Declaration_Node and then
         Adac.Compilation.Syntax.enumeration_literal_count
           (context, enumeration) = 3 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.enumeration_literal_symbol_at
              (context, enumeration, 1)) = "Idle" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.enumeration_literal_symbol_at
              (context, enumeration, 2)) = "Busy" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.enumeration_literal_symbol_at
              (context, enumeration, 3)) = "Done",
         "nested procedure lost its enumeration declarative child");
      Adac.Compilation.Syntax.validate_declaration (context, enumeration);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-package-instantiation-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested procedure package instantiation did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      instantiation : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      generic_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_instantiation_generic_name
          (context, instantiation);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, instantiation) =
           Adac.AST.Package_Instantiation_Node and then
         Adac.Compilation.Syntax.kind_of (context, generic_name) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, generic_name)) = "Vectors" and then
         Adac.Compilation.Syntax.package_instantiation_actual_count
           (context, instantiation) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax
              .package_instantiation_actual_selector_symbol_at
                (context, instantiation, 1)) = "Index_Type" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax
              .package_instantiation_actual_selector_symbol_at
                (context, instantiation, 2)) = "Element_Type",
         "nested procedure lost package-instantiation ownership");
      Adac.Compilation.Syntax.validate_package_instantiation
        (context, instantiation);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-multiple-defining-parameters-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "multiple-defining parameter fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      parameter : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_parameter_at
          (context, function_body, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_subtype_mark (context, parameter);
    begin
      require
        (Adac.Compilation.Syntax.function_body_parameter_count
           (context, function_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, parameter) =
           Adac.AST.Parameter_Specification_Node and then
         Adac.Compilation.Syntax.parameter_defining_identifier_count
           (context, parameter) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.parameter_defining_symbol_at
              (context, parameter, 1)) = "Left" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.parameter_defining_symbol_at
              (context, parameter, 2)) = "Right" and then
         Adac.Compilation.Syntax.parameter_symbol (context, parameter) =
           Adac.Compilation.Syntax.parameter_defining_symbol_at
             (context, parameter, 1) and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context, Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Package_Frame",
         "parameter defining-identifier list lost source ownership");
      Adac.Compilation.Syntax.validate_parameter (context, parameter);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-expression-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "expression-function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_declaration_expression
          (context, declaration);
      child : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, expression);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, declaration) =
           Adac.AST.Function_Declaration_Node and then
         Adac.Compilation.Syntax.function_declaration_has_expression
           (context, declaration) and then
         Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, child) =
           Adac.AST.Relation_Node,
         "expression function lost its represented return expression");
      Adac.Compilation.Syntax.validate_declaration (context, declaration);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-use-type-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested procedure use-type fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      clause : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.use_type_subtype_mark_at
          (context, clause, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, clause) =
           Adac.AST.Use_Type_Clause_Node and then
         Adac.Compilation.Syntax.use_type_subtype_mark_count
           (context, clause) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, subtype_mark)) = "Position",
         "nested procedure lost its use-type declarative child");
      Adac.Compilation.Syntax.validate_use_type_clause (context, clause);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-grouped-formal-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "grouped formal fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      parameter : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_parameter_at
          (context, function_body, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parameter_subtype_mark
          (context, parameter);
    begin
      require
        (Adac.Compilation.Syntax.function_body_parameter_count
           (context, function_body) = 1 and then
         Adac.Compilation.Syntax.parameter_defining_identifier_count
           (context, parameter) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.parameter_defining_symbol_at
              (context, parameter, 1)) = "left" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.parameter_defining_symbol_at
              (context, parameter, 2)) = "right" and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, subtype_mark)) = "Boolean",
         "grouped formal lost ordered defining identifiers or subtype");
      Adac.Compilation.Syntax.validate_parameter (context, parameter);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-use-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested procedure use-clause fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      use_type_clause : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      use_package_clause : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 2);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, use_type_clause) =
           Adac.AST.Use_Type_Clause_Node and then
         Adac.Compilation.Syntax.use_type_subtype_mark_count
           (context, use_type_clause) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, use_package_clause) =
           Adac.AST.Use_Package_Clause_Node and then
         Adac.Compilation.Syntax.use_package_name_count
           (context, use_package_clause) = 1,
         "nested procedure lost ordered use-clause ownership");
      Adac.Compilation.Syntax.validate_use_type_clause
        (context, use_type_clause);
      Adac.Compilation.Syntax.validate_use_package_clause
        (context, use_package_clause);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-record-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested procedure record fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      helper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      record_type : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at (context, helper, 1);
      first_component : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_at
          (context, record_type, 1);
      second_component : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.record_component_at
          (context, record_type, 2);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, record_type) =
           Adac.AST.Record_Type_Declaration_Node and then
         Adac.Compilation.Syntax.record_component_count
           (context, record_type) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_component_symbol
              (context, first_component)) = "Prefix" and then
         Adac.Compilation.Syntax.record_component_has_default_expression
           (context, first_component) and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.record_component_symbol
              (context, second_component)) = "Ready" and then
         Adac.Compilation.Syntax.record_component_has_default_expression
           (context, second_component),
         "nested procedure lost its record declarative child");
      Adac.Compilation.Syntax.validate_declaration (context, record_type);
      Adac.Compilation.Syntax.validate_procedure_body (context, helper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-handler-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested procedure handler fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      handler : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_handler_at
          (context, sequence, 1);
      choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_choice_at
          (context, handler, 1);
      handler_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 1);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.handled_sequence_handler_count
           (context, sequence) = 1 and then
         Adac.Compilation.Syntax.exception_handler_choice_count
           (context, handler) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, choice) =
           Adac.AST.Others_Exception_Choice_Node and then
         Adac.Compilation.Syntax.exception_handler_statement_count
           (context, handler) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, handler_statement) =
           Adac.AST.Null_Statement_Node,
         "nested procedure lost declarative/body/handler ownership");
      Adac.Compilation.Syntax.validate_exception_handler (context, handler);
      Adac.Compilation.Syntax.validate_handled_sequence (context, sequence);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-named-handler-assignment-current/" &
      "input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "named handler assignment fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      handler : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_handler_at
          (context, sequence, 1);
      choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_choice_at
          (context, handler, 1);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 1);
      call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 2);
    begin
      require
        (Adac.Compilation.Syntax.exception_handler_choice_count
           (context, handler) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, choice) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Syntax.exception_handler_statement_count
           (context, handler) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, call) =
           Adac.AST.Procedure_Call_Statement_Node,
         "named handler lost assignment/call statement ownership");
      Adac.Compilation.Syntax.validate_exception_handler (context, handler);
      Adac.Compilation.Syntax.validate_handled_sequence (context, sequence);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-block-nested-bare-handler-current/" &
      "input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested bare handler block fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      function_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      outer_block : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, function_sequence, 1);
      outer_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, outer_block);
      inner_block : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, outer_sequence, 2);
      inner_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, inner_block);
      handler : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_handler_at
          (context, inner_sequence, 1);
      first_handler_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 1);
      second_handler_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exception_handler_statement_at
          (context, handler, 2);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, outer_block) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, outer_sequence) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, inner_block) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.handled_sequence_handler_count
           (context, inner_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context, first_handler_statement) =
             Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context, second_handler_statement) =
             Adac.AST.Procedure_Call_Statement_Node,
         "block frame lost nested bare handled-block ownership");
      Adac.Compilation.Syntax.validate_exception_handler (context, handler);
      Adac.Compilation.Syntax.validate_block_statement (context, inner_block);
      Adac.Compilation.Syntax.validate_block_statement (context, outer_block);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-nested-call-block-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested call/block fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      nested_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      first_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 1);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 2);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
    begin
      require
        (Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, nested_sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, first_statement) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, block_statement) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, block_sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, block_sequence, 1)) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, block_sequence, 2)) =
           Adac.AST.If_Statement_Node,
         "handler-free procedure lost call/block statement ownership");
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/" &
      "function-body-nested-declaration-call-block-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested declaration/call/block fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      nested_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      first_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 1);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 2);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, nested_sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, first_statement) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.block_declaration_count
           (context, block_statement) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, block_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, block_sequence, 1)) =
           Adac.AST.Assignment_Statement_Node,
         "nested procedure lost declaration/call/block ownership");
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/" &
      "function-body-nested-declaration-block-loop-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "nested block/loop fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      nested_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 2);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, block_sequence, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, block_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, loop_statement) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.loop_statement_at
              (context, loop_statement, 1)) =
           Adac.AST.Assignment_Statement_Node,
         "caller-neutral block lost iterator-loop ownership");
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-nested-deep-block-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "deep nested-block fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      nested_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      root_block : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, nested_sequence, 2);
      current_block : Adac.AST.Node_ID := root_block;
      valid_chain   : Boolean := True;
    begin
      Adac.Compilation.Syntax.validate_block_statement (context, root_block);
      for level in 1 .. 64 loop
        if Adac.Compilation.Syntax.kind_of (context, current_block) /=
           Adac.AST.Block_Statement_Node
        then
          valid_chain := False;
          exit;
        end if;

        declare
          sequence : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.block_handled_sequence
              (context, current_block);
        begin
          if Adac.Compilation.Syntax.handled_sequence_statement_count
            (context, sequence) /= 1
          then
            valid_chain := False;
            exit;
          end if;

          declare
            child : constant Adac.AST.Node_ID :=
              Adac.Compilation.Syntax.handled_sequence_statement_at
                (context, sequence, 1);
          begin
            if level < 64 then
              current_block := child;
            elsif Adac.Compilation.Syntax.kind_of (context, child) /=
                  Adac.AST.Assignment_Statement_Node
            then
              valid_chain := False;
            end if;
          end;
        end;
      end loop;

      require
        (valid_chain,
         "deep nested-block ownership lost its 64-level block chain");
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/procedure/" &
      "function-body-deep-nested-procedure-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "deep nested-procedure fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      root_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      root_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, root_procedure);
      current_procedure : Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at
          (context, root_procedure, 2);
      valid_chain : Boolean :=
        Adac.Compilation.Syntax.declaration_count
          (context, root_procedure) = 2 and then
        Adac.Compilation.Syntax.kind_of
          (context,
           Adac.Compilation.Syntax.declaration_at
             (context, root_procedure, 1)) =
          Adac.AST.Object_Renaming_Declaration_Node and then
        Adac.Compilation.Syntax.kind_of (context, current_procedure) =
          Adac.AST.Procedure_Body_Node and then
        Adac.Compilation.Syntax.kind_of
          (context,
           Adac.Compilation.Syntax.handled_sequence_statement_at
             (context, root_sequence, 1)) =
          Adac.AST.Procedure_Call_Statement_Node;
    begin
      Adac.Compilation.Syntax.validate_procedure_body
        (context, root_procedure);
      for level in 1 .. 32 loop
        if not valid_chain or else
           Adac.Compilation.Syntax.kind_of (context, current_procedure) /=
             Adac.AST.Procedure_Body_Node
        then
          valid_chain := False;
          exit;
        end if;

        declare
          declaration_count : constant Natural :=
            Adac.Compilation.Syntax.declaration_count
              (context, current_procedure);
          first_declaration : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.declaration_at
              (context, current_procedure, 1);
          sequence : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.procedure_handled_sequence
              (context, current_procedure);
        begin
          if Adac.Compilation.Syntax.kind_of (context, first_declaration) /=
               Adac.AST.Object_Renaming_Declaration_Node or else
             declaration_count /= (if level < 32 then 2 else 1) or else
             Adac.Compilation.Syntax.handled_sequence_statement_count
               (context, sequence) /= 1 or else
             Adac.Compilation.Syntax.kind_of
               (context,
                Adac.Compilation.Syntax.handled_sequence_statement_at
                  (context, sequence, 1)) /= Adac.AST.Null_Statement_Node
          then
            valid_chain := False;
            exit;
          end if;

          if level < 32 then
            current_procedure :=
              Adac.Compilation.Syntax.declaration_at
                (context, current_procedure, 2);
          end if;
        end;
      end loop;

      require
        (valid_chain,
         "deep nested-procedure ownership lost its 32-level child chain");
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-first-if-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "first-if nested procedure fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      raise_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_then_statement_at
          (context, if_statement, 1);
      trailing_raise : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      trailing_message : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.raise_message_expression
          (context, trailing_raise);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 0 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, if_statement) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, raise_statement) =
           Adac.AST.Raise_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, trailing_raise) =
           Adac.AST.Raise_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, trailing_message) =
           Adac.AST.Binary_Adding_Node,
         "direct nested procedure lost if/raise continuation ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-call-case-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "call-first nested case fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      first_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      second_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 0 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, first_statement) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_statement) =
           Adac.AST.Case_Statement_Node,
         "call-first nested procedure lost following case ownership");
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-direct-assignment-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "direct-assignment nested procedure fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      first_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      second_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      third_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 3);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 0 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, first_statement) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_statement) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, third_statement) =
           Adac.AST.Procedure_Call_Statement_Node,
         "direct nested procedure lost assignment/call source order");
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-direct-loops-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "direct-loop nested procedure fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      range_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      while_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      simple_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 3);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 0 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, range_loop) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_form (context, range_loop) =
           Adac.AST.Discrete_Range_Loop_Form and then
         Adac.Compilation.Syntax.kind_of (context, while_loop) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_form (context, while_loop) =
           Adac.AST.While_Loop_Form and then
         Adac.Compilation.Syntax.kind_of (context, simple_loop) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_form (context, simple_loop) =
           Adac.AST.Simple_Loop_Form,
         "direct nested procedure lost loop source forms/order");
      Adac.Compilation.Syntax.validate_loop_statement (context, range_loop);
      Adac.Compilation.Syntax.validate_loop_statement (context, while_loop);
      Adac.Compilation.Syntax.validate_loop_statement (context, simple_loop);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-declarative-while-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "declarative-while nested procedure fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      while_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      trailing_call : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, while_loop) =
           Adac.AST.Loop_Statement_Node and then
         Adac.Compilation.Syntax.loop_form (context, while_loop) =
           Adac.AST.While_Loop_Form and then
         Adac.Compilation.Syntax.kind_of (context, trailing_call) =
           Adac.AST.Procedure_Call_Statement_Node,
         "declarative nested procedure lost while/call source order");
      Adac.Compilation.Syntax.validate_loop_statement (context, while_loop);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-nested-procedure-declarative-if-continuation-current/" &
      "input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "declarative-if continuation fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      nested_procedure : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_handled_sequence
          (context, nested_procedure);
      first_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      second_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      third_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 3);
    begin
      require
        (Adac.Compilation.Syntax.declaration_count
           (context, nested_procedure) = 1 and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, sequence) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, first_statement) =
           Adac.AST.If_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_statement) =
           Adac.AST.Procedure_Call_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, third_statement) =
           Adac.AST.Assignment_Statement_Node,
         "declarative first-if continuation lost statement source order");
      Adac.Compilation.Syntax.validate_if_statement
        (context, first_statement);
      Adac.Compilation.Syntax.validate_procedure_body
        (context, nested_procedure);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "function-body-procedure-declarations-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "procedure-declaration fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      forward_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 1);
      outer_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_declaration_at
          (context, function_body, 2);
      inner_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.declaration_at
          (context, outer_body, 1);
    begin
      require
        (Adac.Compilation.Syntax.function_body_declaration_count
           (context, function_body) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, forward_declaration) =
           Adac.AST.Procedure_Declaration_Node and then
         Adac.Compilation.Syntax.procedure_declaration_parameter_count
           (context, forward_declaration) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, outer_body) =
           Adac.AST.Procedure_Body_Node and then
         Adac.Compilation.Syntax.declaration_count
           (context, outer_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, inner_declaration) =
           Adac.AST.Procedure_Declaration_Node and then
         Adac.Compilation.Syntax.procedure_declaration_parameter_count
           (context, inner_declaration) = 1,
         "procedure declarations lost function/procedure ownership");
      Adac.Compilation.Syntax.validate_declaration
        (context, forward_declaration);
      Adac.Compilation.Syntax.validate_declaration
        (context, inner_declaration);
      Adac.Compilation.Syntax.validate_procedure_body (context, outer_body);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-discrete-range-loop-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "discrete-range loop fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      first_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      second_loop : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 2);
      first_lower : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_range_lower_bound
          (context, first_loop);
      first_upper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_range_upper_bound
          (context, first_loop);
      second_upper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_range_upper_bound
          (context, second_loop);
    begin
      require
        (Adac.Compilation.Syntax.loop_form (context, first_loop) =
           Adac.AST.Discrete_Range_Loop_Form and then
         not Adac.Compilation.Syntax.loop_is_reverse
           (context, first_loop) and then
         Adac.Compilation.Syntax.kind_of (context, first_lower) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, first_lower) = "1" and then
         Adac.Compilation.Syntax.kind_of (context, first_upper) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, first_loop) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.loop_statement_at
              (context, first_loop, 1)) =
           Adac.AST.Procedure_Call_Statement_Node,
         "discrete-range loop lost lower/upper/body ownership");
      require
        (Adac.Compilation.Syntax.loop_form (context, second_loop) =
           Adac.AST.Discrete_Range_Loop_Form and then
         Adac.Compilation.Syntax.loop_is_reverse
           (context, second_loop) and then
         Adac.Compilation.Syntax.kind_of (context, second_upper) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, second_upper) = "3",
         "reverse discrete-range loop lost its source form");
      Adac.Compilation.Syntax.validate_loop_statement (context, first_loop);
      Adac.Compilation.Syntax.validate_loop_statement (context, second_loop);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-range-attribute-loop-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "range-attribute loop fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      range_attribute : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_range_attribute
          (context, loop_statement);
      prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, range_attribute);
    begin
      require
        (Adac.Compilation.Syntax.loop_form (context, loop_statement) =
           Adac.AST.Range_Attribute_Loop_Form and then
         not Adac.Compilation.Syntax.loop_is_reverse
           (context, loop_statement) and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.loop_parameter_symbol
              (context, loop_statement)) = "Index" and then
         Adac.Compilation.Syntax.kind_of (context, range_attribute) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.attribute_symbol
              (context, range_attribute)) = "Range" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol (context, prefix)) =
           "Arguments" and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.loop_statement_at
              (context, loop_statement, 1)) =
           Adac.AST.Procedure_Call_Statement_Node,
         "range-attribute loop lost parameter/attribute/body ownership");
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-simple-loop-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "simple-loop function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 1);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 2);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
    begin
      require
        (Adac.Compilation.Syntax.loop_form (context, loop_statement) =
           Adac.AST.Simple_Loop_Form and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.handled_sequence_statement_count
           (context, block_sequence) = 1 and then
         Adac.Compilation.Syntax.kind_of
           (context,
            Adac.Compilation.Syntax.handled_sequence_statement_at
              (context, block_sequence, 1)) =
           Adac.AST.Assignment_Statement_Node,
         "simple-loop parser lost assignment/block ownership");
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-parenthesized-numeric-actual-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "parenthesized-numeric function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      attribute : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, expression);
      attribute_prefix : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.name_prefix (context, attribute);
      literal : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, expression) = 1 and then
         Adac.Compilation.Syntax.parenthesized_item_form
           (context, expression, 1) =
           Adac.AST.Positional_Parenthesized_Name_Item_Form,
         "parenthesized numeric actual lost item ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, attribute) =
           Adac.AST.Attribute_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.attribute_symbol
              (context, attribute)) = "Val" and then
         Adac.Compilation.Syntax.kind_of (context, attribute_prefix) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, attribute_prefix)) = "Character",
         "parenthesized numeric actual lost attribute-prefix ownership");
      require
        (Adac.Compilation.Syntax.kind_of (context, literal) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_form (context, literal) =
           Adac.AST.Based_Integer_Form and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, literal) = "16#27#",
         "parenthesized numeric actual lost based-literal ownership");
      Adac.Compilation.Syntax.validate_name (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-parenthesized-character-actual-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "parenthesized-character function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      literal : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, expression, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, expression) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, expression) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, literal) =
           Adac.AST.Character_Literal_Node and then
         Adac.Compilation.Syntax.character_literal_spelling
           (context, literal) = "'0'",
         "parenthesized character actual lost parser ownership");
      Adac.Compilation.Syntax.validate_name (context, expression);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-parenthesized-string-actual-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "parenthesized-string function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      if_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_condition (context, if_statement);
      literal : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_item_at
          (context, condition, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, condition) =
           Adac.AST.Parenthesized_Name_Node and then
         Adac.Compilation.Syntax.parenthesized_item_count
           (context, condition) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, literal) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling (context, literal) =
           """ADAC_CC""",
         "parenthesized string actual lost parser ownership");
      Adac.Compilation.Syntax.validate_if_statement (context, if_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-case-expression-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "case-expression function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      wrapper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      conditional : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, wrapper);
      selecting : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_selecting_expression
          (context, conditional);
      first_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_at
          (context, conditional, 1);
      second_alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_at
          (context, conditional, 2);
      first_choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_choice_at
          (context, first_alternative, 1);
      second_choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_choice_at
          (context, first_alternative, 2);
      others_choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_choice_at
          (context, second_alternative, 1);
      first_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_expression
          (context, first_alternative);
      second_value : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_expression
          (context, second_alternative);
      raise_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.raise_expression_exception_name
          (context, second_value);
      raise_message : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.raise_expression_message
          (context, second_value);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, wrapper) =
           Adac.AST.Parenthesized_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, conditional) =
           Adac.AST.Case_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, selecting) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, selecting)) = "kind" and then
         Adac.Compilation.Syntax.case_expression_alternative_count
           (context, conditional) = 2 and then
         Adac.Compilation.Syntax.case_expression_alternative_choice_count
           (context, first_alternative) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, first_choice) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, first_choice)) = "Alpha" and then
         Adac.Compilation.Syntax.kind_of (context, second_choice) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, second_choice)) = "Beta" and then
         Adac.Compilation.Syntax.case_expression_alternative_choice_count
           (context, second_alternative) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, others_choice) =
           Adac.AST.Others_Case_Choice_Node and then
         Adac.Compilation.Syntax.kind_of (context, first_value) =
           Adac.AST.Numeric_Literal_Node and then
         Adac.Compilation.Syntax.numeric_literal_spelling
           (context, first_value) = "1" and then
         Adac.Compilation.Syntax.kind_of (context, second_value) =
           Adac.AST.Raise_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, raise_name) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol
              (context, raise_name)) = "Parse_Error" and then
         Adac.Compilation.Syntax.raise_expression_has_message
           (context, second_value) and then
         Adac.Compilation.Syntax.kind_of (context, raise_message) =
           Adac.AST.String_Literal_Node and then
         Adac.Compilation.Syntax.string_literal_spelling
           (context, raise_message) = """bad kind""",
         "case expression lost ordered selector/choice/value ownership");
      Adac.Compilation.Syntax.validate_expression (context, wrapper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-case-expression-selected-choice-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "selected case-expression choice fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      wrapper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      conditional : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, wrapper);
      alternative : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_at
          (context, conditional, 1);
      choice : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.case_expression_alternative_choice_at
          (context, alternative, 1);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, choice) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol (context, choice)) =
           "Discrete_Range_Loop_Form",
         "case expression lost selected-name choice ownership");
      Adac.Compilation.Syntax.validate_expression (context, wrapper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-conditional-relation-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "conditional-relation function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      wrapper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      conditional : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, wrapper);
      condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_expression_condition
          (context, conditional);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, wrapper) =
           Adac.AST.Parenthesized_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, conditional) =
           Adac.AST.If_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, condition) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.relation_operator_spelling
           (context, condition) = "=",
         "conditional relation condition lost AST ownership");
      Adac.Compilation.Syntax.validate_expression (context, wrapper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/expressions/general/" &
      "function-body-conditional-short-circuit-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "conditional short-circuit fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      return_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      wrapper : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.return_expression
          (context, return_statement);
      conditional : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, wrapper);
      condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.if_expression_condition
          (context, conditional);
      right_operand : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.short_circuit_right_operand
          (context, condition);
      inner : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.parenthesized_expression_child
          (context, right_operand);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, condition) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, condition) =
             Adac.AST.And_Then_Short_Circuit_Operator and then
         Adac.Compilation.Syntax.kind_of (context, right_operand) =
           Adac.AST.Parenthesized_Expression_Node and then
         Adac.Compilation.Syntax.kind_of (context, inner) =
           Adac.AST.Short_Circuit_Expression_Node and then
         Adac.Compilation.Syntax.short_circuit_operator
           (context, inner) = Adac.AST.Or_Else_Short_Circuit_Operator,
         "conditional short-circuit condition lost AST ownership");
      Adac.Compilation.Syntax.validate_expression (context, wrapper);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-exit-when-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "exit-when function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      exit_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 1);
      condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.exit_condition (context, exit_statement);
      call_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 2);
    begin
      require
        (Adac.Compilation.Syntax.loop_form (context, loop_statement) =
           Adac.AST.Simple_Loop_Form and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, exit_statement) =
           Adac.AST.Exit_Statement_Node and then
         not Adac.Compilation.Syntax.exit_has_loop_name
           (context, exit_statement) and then
         Adac.Compilation.Syntax.exit_has_condition
           (context, exit_statement) and then
         Adac.Compilation.Syntax.kind_of (context, condition) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.identifier_symbol (context, condition)) =
           "terminated" and then
         Adac.Compilation.Syntax.kind_of (context, call_statement) =
           Adac.AST.Procedure_Call_Statement_Node,
         "exit-when parser lost loop-body order or condition ownership");
      Adac.Compilation.Syntax.validate_exit_statement (context, exit_statement);
      Adac.Compilation.Syntax.validate_loop_statement (context, loop_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/statements/function-body-while-loop-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "while-loop function fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      loop_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      condition : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_condition (context, loop_statement);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 1);
      block_sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_handled_sequence
          (context, block_statement);
      assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, block_sequence, 1);
      increment_assignment : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.loop_statement_at
          (context, loop_statement, 2);
      increment_expression : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.assignment_expression
          (context, increment_assignment);
    begin
      require
        (Adac.Compilation.Syntax.loop_form (context, loop_statement) =
           Adac.AST.While_Loop_Form and then
         Adac.Compilation.Syntax.kind_of (context, condition) =
           Adac.AST.Relation_Node and then
         Adac.Compilation.Syntax.loop_statement_count
           (context, loop_statement) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, block_statement) =
           Adac.AST.Block_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, increment_assignment) =
           Adac.AST.Assignment_Statement_Node and then
         Adac.Compilation.Syntax.kind_of (context, increment_expression) =
           Adac.AST.Binary_Adding_Node and then
         Adac.Compilation.Syntax.binary_adding_operator_spelling
           (context, increment_expression) = "+",
         "while-loop parser lost block/binary-adding assignment ownership");
      Adac.Compilation.Syntax.validate_loop_statement
        (context, loop_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/object/object-renaming-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "object-renaming fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      function_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      sequence : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.function_body_handled_sequence
          (context, function_body);
      block_statement : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.handled_sequence_statement_at
          (context, sequence, 1);
      renaming : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.block_declaration_at
          (context, block_statement, 1);
      subtype_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_renaming_subtype_mark
          (context, renaming);
      renamed_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.object_renaming_name (context, renaming);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, renaming) =
           Adac.AST.Object_Renaming_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.object_renaming_symbol
              (context, renaming)) = "alias" and then
         Adac.Compilation.Syntax.kind_of (context, subtype_mark) =
           Adac.AST.Identifier_Name_Node and then
         Adac.Compilation.Syntax.kind_of (context, renamed_name) =
           Adac.AST.Parenthesized_Name_Node,
         "object renaming lost defining/subtype/renamed-name syntax");
      Adac.Compilation.Syntax.validate_declaration (context, renaming);
      Adac.Compilation.Syntax.validate_block_statement
        (context, block_statement);
      Adac.Compilation.Syntax.validate_function_body (context, function_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-body-use-type-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package-body use-type fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      first_clause : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      second_clause : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 2);
      object_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 3);
      first_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.use_type_subtype_mark_at
          (context, first_clause, 1);
      second_first_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.use_type_subtype_mark_at
          (context, second_clause, 1);
      second_last_mark : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.use_type_subtype_mark_at
          (context, second_clause, 2);
    begin
      require
        (Adac.Compilation.Syntax.package_body_declaration_count
           (context, package_body) = 3 and then
         Adac.Compilation.Syntax.kind_of (context, first_clause) =
           Adac.AST.Use_Type_Clause_Node and then
         Adac.Compilation.Syntax.kind_of (context, second_clause) =
           Adac.AST.Use_Type_Clause_Node and then
         Adac.Compilation.Syntax.kind_of (context, object_declaration) =
           Adac.AST.Object_Declaration_Node,
         "package body lost ordered use-type declarative items");
      require
        (Adac.Compilation.Syntax.use_type_subtype_mark_count
           (context, first_clause) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, first_mark) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol (context, first_mark)) =
           "Count_Type",
         "single use-type clause lost its subtype mark");
      require
        (Adac.Compilation.Syntax.use_type_subtype_mark_count
           (context, second_clause) = 2 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, second_first_mark)) = "Position" and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, second_last_mark)) = "Span",
         "multi-mark use-type clause lost source order");
      Adac.Compilation.Syntax.validate_use_type_clause
        (context, first_clause);
      Adac.Compilation.Syntax.validate_use_type_clause
        (context, second_clause);
      Adac.Compilation.Syntax.validate_declaration
        (context, object_declaration);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-body-use-package-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package-body package-use fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      clause : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      package_name : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.use_package_name_at
          (context, clause, 1);
    begin
      require
        (Adac.Compilation.Syntax.package_body_declaration_count
           (context, package_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, clause) =
           Adac.AST.Use_Package_Clause_Node and then
         Adac.Compilation.Syntax.use_package_name_count
           (context, clause) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, package_name) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, package_name)) = "Tokens",
         "package-use clause lost selected package-name ownership");
      Adac.Compilation.Syntax.validate_use_package_clause (context, clause);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-body-stub-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package-body stub fixture did not parse cleanly");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      package_declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      stub : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 2);
    begin
      require
        (Adac.Compilation.Syntax.package_body_declaration_count
           (context, package_body) = 2 and then
         Adac.Compilation.Syntax.kind_of (context, package_declaration) =
           Adac.AST.Package_Declaration_Node and then
         Adac.Compilation.Syntax.kind_of (context, stub) =
           Adac.AST.Package_Body_Stub_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.package_body_stub_symbol
              (context, stub)) = "Helper",
         "package body lost package-body stub ownership");
      Adac.Compilation.Syntax.validate_package_body_stub (context, stub);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/procedure-body-stub-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "procedure-body stub fixture did not parse cleanly");
    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      stub : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      parameter : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.procedure_body_stub_parameter_at
          (context, stub, 1);
    begin
      require
        (Adac.Compilation.Syntax.package_body_declaration_count
           (context, package_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, stub) =
           Adac.AST.Procedure_Body_Stub_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.procedure_body_stub_symbol
              (context, stub)) = "Helper" and then
         Adac.Compilation.Syntax.procedure_body_stub_parameter_count
           (context, stub) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, parameter) =
           Adac.AST.Parameter_Specification_Node,
         "procedure body stub lost profile ownership");
      Adac.Compilation.Syntax.validate_declaration (context, stub);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/subprograms/" &
      "package-body-procedure-declaration-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded and then
       Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package-body procedure declaration fixture did not parse cleanly");
    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      declaration : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
    begin
      require
        (Adac.Compilation.Syntax.package_body_declaration_count
           (context, package_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, declaration) =
           Adac.AST.Procedure_Declaration_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.procedure_declaration_symbol
              (context, declaration)) = "Helper" and then
         Adac.Compilation.Syntax.procedure_declaration_parameter_count
           (context, declaration) = 1,
         "package body lost procedure declaration ownership");
      Adac.Compilation.Syntax.validate_declaration (context, declaration);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String :=
      "tests/declarations/package/package-body-renaming-current/input.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "package-body renaming fixture did not parse successfully");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package-body renaming fixture recorded a parse diagnostic");

    declare
      package_body : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.library_item (context, result.root);
      renaming : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_body_declaration_at
          (context, package_body, 1);
      renamed_package : constant Adac.AST.Node_ID :=
        Adac.Compilation.Syntax.package_renaming_renamed_package
          (context, renaming);
    begin
      require
        (Adac.Compilation.Syntax.kind_of (context, package_body) =
           Adac.AST.Package_Body_Node and then
         Adac.Compilation.Syntax.package_body_declaration_count
           (context, package_body) = 1 and then
         Adac.Compilation.Syntax.kind_of (context, renaming) =
           Adac.AST.Package_Renaming_Declaration_Node,
         "package body lost its package-renaming declarative child");
      require
        (Adac.Compilation.Syntax.package_renaming_defining_name_count
           (context, renaming) = 1 and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.package_renaming_defining_name_symbol_at
              (context, renaming, 1)) = "Implementation",
         "package renaming lost its defining name");
      require
        (Adac.Compilation.Syntax.kind_of (context, renamed_package) =
           Adac.AST.Selected_Name_Node and then
         Adac.Compilation.Symbols.spelling
           (context,
            Adac.Compilation.Syntax.selector_symbol
              (context, renamed_package)) = "Helper",
         "package renaming lost its renamed selected name");
      Adac.Compilation.Syntax.validate_package_renaming_declaration
        (context, renaming);
      Adac.Compilation.Syntax.validate_package_body (context, package_body);
      Adac.Compilation.Syntax.validate (context, result.root);
    end;
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context := new_context;
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "package body did not publish a compilation-unit root");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "package body frontend success recorded a diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 69,
       "package body root changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 393,
       "package body root changed AST publication");
    require
      (Adac.Compilation.Syntax.kind_of
         (context,
          Adac.Compilation.Syntax.library_item (context, result.root)) =
       Adac.AST.Package_Body_Node,
       "package body root has the wrong library-item kind");
    require
      (Adac.Compilation.Syntax.package_body_declaration_count
         (context,
          Adac.Compilation.Syntax.library_item (context, result.root)) = 5,
       "package body root lost current procedure bodies");
    require
      (Adac.Compilation.Syntax.package_body_defining_name_count
         (context,
          Adac.Compilation.Syntax.library_item (context, result.root)) = 2 and
       then Adac.Compilation.Syntax.package_body_end_name_count
         (context,
          Adac.Compilation.Syntax.library_item (context, result.root)) = 2,
       "package body root lost defining or closing name components");
    require
      (Adac.Sema.analyze (context, result.root).status =
       Adac.Sema.Analysis_Rejected,
       "production package body unexpectedly passed semantic analysis");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "production package body semantic rejection changed diagnostics");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package body semantic rejection published an entity");
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [391, 392];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "package-body/root AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "package-body/root AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 69,
           "package-body/root limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "package-body/root limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "package-body/root limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [386, 387, 388];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "run block ownership AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "run block ownership AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 68,
           "run block ownership limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "run block ownership limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "run block ownership limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [389, 390];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "run procedure ownership AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "run procedure ownership AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 68,
           "run procedure ownership limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "run procedure ownership limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "run procedure ownership limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 334));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "run if parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "run if parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 64,
       "run if parent limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 334,
       "run if parent limit published a partial if parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "run if parent limit published a semantic entity");
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [369, 370];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "run conditional AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "run conditional AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 66,
           "run conditional AST limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "run conditional AST limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "run conditional AST limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 381));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "run context object AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "run context object AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 68,
       "run context object limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 381,
       "run context object limit published a partial object parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "run context object limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 357));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "run block declaration AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "run block declaration AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 65,
       "run block declaration limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 357,
       "run block declaration limit published a partial object parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "run block declaration limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 348));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "run second if parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "run second if parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 65,
       "run second if parent limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 348,
       "run second if parent limit published a partial if parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "run second if parent limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 310));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "run unary AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "run unary AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 62,
       "run unary AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 310,
       "run unary AST limit published a partial unary parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "run unary AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 240));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "compile_file result AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "compile_file result AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 50,
       "compile_file result limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 240,
       "compile_file result limit published a partial object parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "compile_file result limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 242));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "compile_file case-header AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "compile_file case-header AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 50,
       "compile_file case-header limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 242,
       "compile_file case-header limit published a partial selected name");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "compile_file case-header limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 249));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "compile_file first-alternative AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "compile_file first-alternative AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 51,
       "compile_file first-alternative limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 249,
       "compile_file first-alternative limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "compile_file first-alternative limit published a semantic entity");
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [259, 260, 261, 262];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "compile_file inner-block AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "compile_file inner-block AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 52,
           "compile_file inner-block limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "compile_file inner-block limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "compile_file inner-block limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 280));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "compile_file exception-header AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "compile_file exception-header AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 58,
       "compile_file exception-header limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 280,
       "compile_file exception-header limit published a partial selected name");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "compile_file exception-header limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 294));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "compile_file exception-handler AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "compile_file exception-handler AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 58,
       "compile_file exception-handler limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 294,
       "compile_file exception-handler limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "compile_file exception-handler limit published a semantic entity");
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [295, 296];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "compile_file outer-block AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "compile_file outer-block AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 58,
           "compile_file outer-block limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "compile_file outer-block limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "compile_file outer-block limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [297, 298];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "compile_file body AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "compile_file body AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 58,
           "compile_file body limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "compile_file body limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "compile_file body limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [214, 215];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "compile_parsed_unit parent AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "compile_parsed_unit parent AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 46,
           "compile_parsed_unit parent limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "compile_parsed_unit parent limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "compile_parsed_unit parent limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [195, 213];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "post-second-block call AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "post-second-block call AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 46,
           "post-second-block call limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "post-second-block call limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "post-second-block call limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [187, 188, 189, 190];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "second case/block parent AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "second case/block parent AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 46,
           "second case/block parent limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "second case/block parent limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "second case/block parent limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 182));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "second case first alternative AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "second case first alternative AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 45,
       "second case first alternative limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 182,
       "second case first alternative limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "second case first alternative limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 163));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "second case selector AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "second case selector AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 42,
       "second case selector limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 163,
       "second case selector limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "second case selector limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 161));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "second block declaration AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "second block declaration AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 42,
       "second block declaration limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 161,
       "second block declaration limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "second block declaration limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 151));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "post-block call parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "post-block call parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 39,
       "post-block call AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 151,
       "post-block call AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "post-block call AST limit published a semantic entity");
  end;

  declare
    type AST_Budget_Array is array (Positive range <>) of Natural;
    budgets : constant AST_Budget_Array := [142, 143, 144, 145, 146];
  begin
    for maximum_ast_nodes of budgets loop
      declare
        path : constant String := "src/adac/driver/adac-driver.adb";
        context : Adac.Compilation.Context :=
          new_context
            (resource_limits =>
               (maximum_source_characters_per_file =>
                  Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
                maximum_expression_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
                maximum_profile_nesting =>
                  Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
                maximum_universal_integer_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
                maximum_universal_real_component_decimal_digits =>
                  Adac.Resources
                    .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
                maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
                maximum_ast_nodes => maximum_ast_nodes));
        result : constant Adac.Frontend.Parse_Result :=
          Adac.Frontend.parse_file (context, path);
      begin
        require
          (result.status = Adac.Frontend.Parse_Rejected,
           "case/block parent AST limit did not reject parsing");
        require
          (Adac.Compilation.Diagnostics.error_count (context) = 1,
           "case/block parent AST limit changed diagnostics");
        require
          (Adac.Compilation.Symbols.symbol_count (context) = 39,
           "case/block parent AST limit changed symbol publication");
        require
          (Adac.Compilation.Syntax.node_count (context) = maximum_ast_nodes,
           "case/block parent AST limit published a partial parent");
        require
          (Adac.Compilation.Semantics.entity_count (context) = 0,
           "case/block parent AST limit published a semantic entity");
      end;
    end loop;
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 141));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "assignment parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "assignment parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 39,
       "assignment AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 141,
       "assignment AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "assignment AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 131));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "second case alternative call AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "second case alternative call AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 37,
       "second case alternative call limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 131,
       "second case alternative call limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "second case alternative call limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 123));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "first case alternative return AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "first case alternative return AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 36,
       "first case alternative AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 123,
       "first case alternative AST limit published a partial return");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "first case alternative AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 116));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "case selecting-name parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "case selecting-name parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 35,
       "case selecting-name AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 116,
       "case selecting-name AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "case selecting-name AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 114));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "block declaration parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "block declaration parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 34,
       "block declaration AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 114,
       "block declaration AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "block declaration AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 104));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "first body call parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "first body call parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 31,
       "first body call AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 104,
       "first body call AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "first body call AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 99));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "variable object parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "variable object parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 31,
       "variable object AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 99,
       "variable object AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "variable object AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 54));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "package-body procedure parent AST limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "package-body procedure parent AST limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 19,
       "package-body procedure AST limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 54,
       "package-body procedure AST limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "package-body procedure AST limit published a semantic entity");
  end;

  declare
    path : constant String := "src/adac/driver/adac-driver.adb";
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_expression_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_EXPRESSION_NESTING,
            maximum_profile_nesting =>
              Adac.Resources.DEFAULT_MAXIMUM_PROFILE_NESTING,
            maximum_universal_integer_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_INTEGER_DECIMAL_DIGITS,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 85));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "second package-body procedure parent limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "second package-body procedure limit changed diagnostics");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 25,
       "second package-body procedure limit changed symbol publication");
    require
      (Adac.Compilation.Syntax.node_count (context) = 85,
       "second package-body procedure limit published a partial parent");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "second package-body procedure limit published a semantic entity");
  end;
end Run_Bootstrap_Package_Ownership;
