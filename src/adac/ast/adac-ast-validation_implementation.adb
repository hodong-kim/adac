-- ============================================================================
-- adac-ast-validation_implementation.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.AST)
package body Validation_Implementation is

  procedure validate_numeric_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    require_numeric_literal (self, literal);
    validate_numeric_literal_shape
      (Ada.Strings.Unbounded.to_string
         (self.nodes(Positive(literal.index)).numeric_spelling),
       self.nodes(Positive(literal.index)).span);
  end validate_numeric_literal;

  procedure validate_derived_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    require_derived_type_declaration (self, declaration);
    declare
      value : Node renames self.nodes(Positive(declaration.index));
      defining_span : constant Adac.Source.Span :=
        value.derived_type_defining_span_value;
      parent_subtype_mark : constant Node_ID :=
        value.derived_type_parent_subtype_mark_value;
      parent_span : Adac.Source.Span;
    begin
      Adac.Symbols.validate (value.derived_type_symbol_value);
      Adac.Source.validate (defining_span);
      Adac.Source.validate (value.span);
      require_simple_name (self, parent_subtype_mark);
      if parent_subtype_mark.index >= declaration.index
      then
        raise Program_Error with
          "Adac.AST: derived-type parent subtype mark is not earlier";
      end if;
      validate_name (self, parent_subtype_mark);
      parent_span := node_span (self, parent_subtype_mark);
      if not Adac.Source.contains (value.span, defining_span) or else
         not Adac.Source.contains (value.span, parent_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (defining_span)) or else
         not precedes
           (Adac.Source.last_position (defining_span),
            Adac.Source.first_position (parent_span)) or else
         not precedes
           (Adac.Source.last_position (parent_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: derived-type declaration spans are out of source order";
      end if;
    end;
  end validate_derived_type_declaration;

  procedure validate_exception_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    require_exception_declaration (self, declaration);
    declare
      value : Node renames self.nodes(Positive(declaration.index));
    begin
      Adac.Symbols.validate (value.exception_declaration_symbol_value);
      Adac.Source.validate (value.exception_declaration_defining_span_value);
      Adac.Source.validate (value.span);

      if not Adac.Source.contains
        (value.span, value.exception_declaration_defining_span_value) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position
             (value.exception_declaration_defining_span_value) or else
         not precedes
           (Adac.Source.last_position
              (value.exception_declaration_defining_span_value),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: exception-declaration spans are out of source order";
      end if;
    end;
  end validate_exception_declaration;

  procedure validate_range_constraint
    (self       : Store;
     constraint : Node_ID)
  is
    lower_bound : Node_ID;
    upper_bound : Node_ID;
    lower_span  : Adac.Source.Span;
    upper_span  : Adac.Source.Span;
  begin
    require_range_constraint (self, constraint);
    declare
      value : Node renames self.nodes(Positive(constraint.index));
    begin
      Adac.Source.validate (value.span);
      lower_bound := value.range_constraint_lower_bound_value;
      upper_bound := value.range_constraint_upper_bound_value;
      require_current_expression (self, lower_bound);
      require_current_expression (self, upper_bound);
      if lower_bound.index >= upper_bound.index or else
         upper_bound.index >= constraint.index
      then
        raise Program_Error with
          "Adac.AST: range-constraint bounds are not earlier and ordered";
      end if;
      validate_expression (self, lower_bound);
      validate_expression (self, upper_bound);
      lower_span := node_span (self, lower_bound);
      upper_span := node_span (self, upper_bound);
      if not Adac.Source.contains (value.span, lower_span) or else
         not Adac.Source.contains (value.span, upper_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (lower_span)) or else
         not precedes
           (Adac.Source.last_position (lower_span),
            Adac.Source.first_position (upper_span)) or else
         Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (upper_span)
      then
        raise Program_Error with
          "Adac.AST: range-constraint bounds are out of source order";
      end if;
    end;
  end validate_range_constraint;

  procedure validate_index_constraint
    (self       : Store;
     constraint : Node_ID)
  is
    lower_bound : Node_ID;
    upper_bound : Node_ID;
    lower_span  : Adac.Source.Span;
    upper_span  : Adac.Source.Span;
  begin
    require_index_constraint (self, constraint);
    declare
      value : Node renames self.nodes(Positive(constraint.index));
    begin
      Adac.Source.validate (value.span);
      validate_double_dot_span (value.index_constraint_range_span_value);
      lower_bound := value.index_constraint_lower_bound_value;
      upper_bound := value.index_constraint_upper_bound_value;
      require_current_simple_expression (self, lower_bound);
      require_current_simple_expression (self, upper_bound);
      if lower_bound.index >= upper_bound.index or else
         upper_bound.index >= constraint.index
      then
        raise Program_Error with
          "Adac.AST: index-constraint bounds are not earlier and ordered";
      end if;
      validate_expression (self, lower_bound);
      validate_expression (self, upper_bound);
      lower_span := node_span (self, lower_bound);
      upper_span := node_span (self, upper_bound);
      if not Adac.Source.contains (value.span, lower_span) or else
         not Adac.Source.contains
           (value.span, value.index_constraint_range_span_value) or else
         not Adac.Source.contains (value.span, upper_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (lower_span)) or else
         not precedes
           (Adac.Source.last_position (lower_span),
            Adac.Source.first_position
              (value.index_constraint_range_span_value)) or else
         not precedes
           (Adac.Source.last_position
              (value.index_constraint_range_span_value),
            Adac.Source.first_position (upper_span)) or else
         not precedes
           (Adac.Source.last_position (upper_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: index-constraint bounds are out of source order";
      end if;
    end;
  end validate_index_constraint;

  procedure validate_subtype_declaration
    (self        : Store;
     declaration : Node_ID)
  is
    subtype_mark : Node_ID;
    subtype_span : Adac.Source.Span;
  begin
    require_subtype_declaration (self, declaration);
    declare
      value : Node renames self.nodes(Positive(declaration.index));
    begin
      Adac.Symbols.validate (value.subtype_declaration_symbol_value);
      Adac.Source.validate (value.subtype_declaration_defining_span_value);
      Adac.Source.validate (value.span);
      subtype_mark := value.subtype_declaration_subtype_mark_value;
      require_simple_name (self, subtype_mark);
      if subtype_mark.index >= declaration.index then
        raise Program_Error with
          "Adac.AST: subtype declaration subtype mark is not earlier";
      end if;
      validate_name (self, subtype_mark);
      subtype_span := node_span (self, subtype_mark);
      if not Adac.Source.contains
        (value.span, value.subtype_declaration_defining_span_value) or else
         not Adac.Source.contains (value.span, subtype_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position
              (value.subtype_declaration_defining_span_value)) or else
         not precedes
           (Adac.Source.last_position
              (value.subtype_declaration_defining_span_value),
            Adac.Source.first_position (subtype_span))
      then
        raise Program_Error with
          "Adac.AST: subtype declaration children are out of source order";
      end if;

      if value.subtype_declaration_constraint_value = INVALID_NODE_ID then
        if not precedes
          (Adac.Source.last_position (subtype_span),
           Adac.Source.last_position (value.span))
        then
          raise Program_Error with
            "Adac.AST: subtype declaration span omits its terminator";
        end if;
      else
        declare
          constraint : constant Node_ID :=
            value.subtype_declaration_constraint_value;
          constraint_span : Adac.Source.Span;
        begin
          require_range_constraint (self, constraint);
          if subtype_mark.index >= constraint.index or else
             constraint.index >= declaration.index
          then
            raise Program_Error with
              "Adac.AST: subtype constraint is not earlier and ordered";
          end if;
          validate_range_constraint (self, constraint);
          constraint_span := node_span (self, constraint);
          if not Adac.Source.contains (value.span, constraint_span) or else
             not precedes
               (Adac.Source.last_position (subtype_span),
                Adac.Source.first_position (constraint_span)) or else
             not precedes
               (Adac.Source.last_position (constraint_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: subtype constraint is out of source order";
          end if;
        end;
      end if;
    end;
  end validate_subtype_declaration;

  procedure validate_discriminant_specification
    (self         : Store;
     discriminant : Node_ID)
  is
  begin
    require_discriminant_specification (self, discriminant);
    declare
      value : Node renames self.nodes(Positive(discriminant.index));
      defining_span : constant Adac.Source.Span :=
        value.discriminant_defining_span_value;
      subtype_mark : constant Node_ID := value.discriminant_subtype_mark_value;
      subtype_span : Adac.Source.Span;
    begin
      Adac.Symbols.validate (value.discriminant_symbol_value);
      Adac.Source.validate (defining_span);
      Adac.Source.validate (value.span);
      require_simple_name (self, subtype_mark);
      if subtype_mark.index >= discriminant.index then
        raise Program_Error with
          "Adac.AST: discriminant subtype mark is not earlier";
      end if;
      validate_name (self, subtype_mark);
      subtype_span := node_span (self, subtype_mark);

      if not Adac.Source.contains (value.span, defining_span) or else
         not Adac.Source.contains (value.span, subtype_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (defining_span) or else
         not precedes
           (Adac.Source.last_position (defining_span),
            Adac.Source.first_position (subtype_span))
      then
        raise Program_Error with
          "Adac.AST: discriminant children are out of source order";
      end if;

      if value.discriminant_default_expression_value = INVALID_NODE_ID then
        if Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (subtype_span)
        then
          raise Program_Error with
            "Adac.AST: discriminant span does not end at its subtype mark";
        end if;
      else
        declare
          default_expression : constant Node_ID :=
            value.discriminant_default_expression_value;
          default_span : Adac.Source.Span;
        begin
          require_current_expression (self, default_expression);
          if default_expression.index >= discriminant.index or else
             subtype_mark.index >= default_expression.index
          then
            raise Program_Error with
              "Adac.AST: discriminant default is not earlier and ordered";
          end if;
          validate_expression (self, default_expression);
          default_span := node_span (self, default_expression);
          if not Adac.Source.contains (value.span, default_span) or else
             not precedes
               (Adac.Source.last_position (subtype_span),
                Adac.Source.first_position (default_span)) or else
             Adac.Source.last_position (value.span) /=
               Adac.Source.last_position (default_span)
          then
            raise Program_Error with
              "Adac.AST: discriminant default is out of source order";
          end if;
        end;
      end if;
    end;
  end validate_discriminant_specification;

  procedure validate_record_component_declaration
    (self      : Store;
     component : Node_ID)
  is
  begin
    require_record_component_declaration (self, component);
    declare
      value        : Node renames self.nodes(Positive(component.index));
      subtype_span : Adac.Source.Span;
    begin
      Adac.Symbols.validate (value.record_component_symbol_value);
      Adac.Source.validate (value.record_component_defining_span_value);
      Adac.Source.validate (value.span);
      require_simple_name (self, value.record_component_subtype_mark_value);

      if value.record_component_subtype_mark_value.index >= component.index then
        raise Program_Error with
          "Adac.AST: record component subtype mark is not earlier";
      end if;
      validate_simple_name (self, value.record_component_subtype_mark_value);
      subtype_span :=
        node_span (self, value.record_component_subtype_mark_value);

      if not Adac.Source.contains
        (value.span, value.record_component_defining_span_value) or else
         not Adac.Source.contains (value.span, subtype_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position
             (value.record_component_defining_span_value) or else
         not precedes
           (Adac.Source.last_position
              (value.record_component_defining_span_value),
            Adac.Source.first_position (subtype_span))
      then
        raise Program_Error with
          "Adac.AST: record component children are out of source order";
      end if;

      if value.record_component_default_expression_value = INVALID_NODE_ID then
        if not precedes
          (Adac.Source.last_position (subtype_span),
           Adac.Source.last_position (value.span))
        then
          raise Program_Error with
            "Adac.AST: record component span omits its terminator";
        end if;
      else
        declare
          default_expression : constant Node_ID :=
            value.record_component_default_expression_value;
          default_span : Adac.Source.Span;
        begin
          require_current_expression (self, default_expression);
          if default_expression.index >= component.index or else
             value.record_component_subtype_mark_value.index >=
               default_expression.index
          then
            raise Program_Error with
              "Adac.AST: record component default is not earlier and ordered";
          end if;
          validate_expression (self, default_expression);
          default_span := node_span (self, default_expression);
          if not Adac.Source.contains (value.span, default_span) or else
             not precedes
               (Adac.Source.last_position (subtype_span),
                Adac.Source.first_position (default_span)) or else
             not precedes
               (Adac.Source.last_position (default_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: record component default is out of source order";
          end if;
        end;
      end if;
    end;
  end validate_record_component_declaration;

  procedure validate_record_variant
    (self    : Store;
     variant : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_record_variant (self, variant);
    declare
      value : Node renames self.nodes(Positive(variant.index));
    begin
      Adac.Source.validate (value.span);
      if value.record_variant_choices_value.is_empty then
        raise Program_Error with "Adac.AST: record variant has no choices";
      end if;
      if value.record_variant_null_component_list_value =
         (not value.record_variant_components_value.is_empty)
      then
        raise Program_Error with
          "Adac.AST: record variant component-list form is inconsistent";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for choice of value.record_variant_choices_value loop
        validate_node_id (self, choice);
        if choice.index >= variant.index then
          raise Program_Error with
            "Adac.AST: record variant choice is not earlier";
        end if;
        if self.nodes(Positive(choice.index)).kind /= Identifier_Name_Node then
          raise Program_Error with
            "Adac.AST: record variant choice is not an identifier name";
        end if;
        validate_name (self, choice);
        declare
          choice_span : constant Adac.Source.Span := node_span (self, choice);
        begin
          if not Adac.Source.contains (value.span, choice_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (choice_span))
          then
            raise Program_Error with
              "Adac.AST: record variant choices are out of source order";
          end if;
          previous_last := Adac.Source.last_position (choice_span);
        end;
      end loop;

      for component of value.record_variant_components_value loop
        require_record_component_declaration (self, component);
        if component.index >= variant.index then
          raise Program_Error with
            "Adac.AST: record variant component is not earlier";
        end if;
        validate_record_component_declaration (self, component);
        declare
          component_span : constant Adac.Source.Span :=
            node_span (self, component);
        begin
          if not Adac.Source.contains (value.span, component_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (component_span))
          then
            raise Program_Error with
              "Adac.AST: record variant components are out of source order";
          end if;
          previous_last := Adac.Source.last_position (component_span);
        end;
      end loop;

      if value.record_variant_null_component_list_value then
        if not precedes
          (previous_last, Adac.Source.last_position (value.span))
        then
          raise Program_Error with
            "Adac.AST: null record variant span omits its terminator";
        end if;
      elsif previous_last /= Adac.Source.last_position (value.span) then
        raise Program_Error with
          "Adac.AST: record variant span does not end with its last component";
      end if;
    end;
  end validate_record_variant;

  procedure validate_record_variant_part
    (self         : Store;
     variant_part : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_record_variant_part (self, variant_part);
    declare
      value : Node renames self.nodes(Positive(variant_part.index));
      discriminant_name : constant Node_ID :=
        value.record_variant_part_discriminant_name_value;
    begin
      Adac.Source.validate (value.span);
      validate_node_id (self, discriminant_name);
      if discriminant_name.index >= variant_part.index then
        raise Program_Error with
          "Adac.AST: variant-part discriminant name is not earlier";
      end if;
      if self.nodes(Positive(discriminant_name.index)).kind /=
         Identifier_Name_Node
      then
        raise Program_Error with
          "Adac.AST: variant-part discriminant is not an identifier name";
      end if;
      validate_name (self, discriminant_name);
      if value.record_variant_part_variants_value.is_empty then
        raise Program_Error with
          "Adac.AST: record variant part has no variants";
      end if;

      declare
        name_span : constant Adac.Source.Span :=
          node_span (self, discriminant_name);
      begin
        if not Adac.Source.contains (value.span, name_span) or else
           not precedes
             (Adac.Source.first_position (value.span),
              Adac.Source.first_position (name_span))
        then
          raise Program_Error with
            "Adac.AST: variant-part discriminant is out of source order";
        end if;
        previous_last := Adac.Source.last_position (name_span);
      end;

      for variant of value.record_variant_part_variants_value loop
        require_record_variant (self, variant);
        if variant.index >= variant_part.index then
          raise Program_Error with "Adac.AST: record variant is not earlier";
        end if;
        validate_record_variant (self, variant);
        declare
          variant_span : constant Adac.Source.Span := node_span (self, variant);
        begin
          if not Adac.Source.contains (value.span, variant_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (variant_span))
          then
            raise Program_Error with
              "Adac.AST: record variants are out of source order";
          end if;
          previous_last := Adac.Source.last_position (variant_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: record variant-part span omits end case";
      end if;
    end;
  end validate_record_variant_part;

  procedure validate_record_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_record_type_declaration (self, declaration);
    declare
      value : Node renames self.nodes(Positive(declaration.index));
    begin
      Adac.Symbols.validate (value.record_type_symbol_value);
      Adac.Source.validate (value.record_type_defining_span_value);
      Adac.Source.validate (value.span);
      if value.record_components_value.is_empty and then
         value.record_variant_part_value = INVALID_NODE_ID
      then
        raise Program_Error with
          "Adac.AST: record type has no represented components";
      end if;
      if not Adac.Source.contains
        (value.span, value.record_type_defining_span_value) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (value.record_type_defining_span_value))
      then
        raise Program_Error with
          "Adac.AST: record type defining span is out of source order";
      end if;

      previous_last := Adac.Source.last_position
        (value.record_type_defining_span_value);
      for child of value.record_discriminants_value loop
        require_discriminant_specification (self, child);
        if child.index >= declaration.index then
          raise Program_Error with
            "Adac.AST: discriminant is not earlier than its record type";
        end if;
        validate_discriminant_specification (self, child);
        declare
          child_span : constant Adac.Source.Span := node_span (self, child);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: record discriminants are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      for child of value.record_components_value loop
        require_record_component_declaration (self, child);
        if child.index >= declaration.index then
          raise Program_Error with
            "Adac.AST: record component is not earlier than its record type";
        end if;
        validate_record_component_declaration (self, child);
        declare
          child_span : constant Adac.Source.Span := node_span (self, child);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: record components are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      if value.record_variant_part_value /= INVALID_NODE_ID then
        require_record_variant_part (self, value.record_variant_part_value);
        if value.record_variant_part_value.index >= declaration.index then
          raise Program_Error with
            "Adac.AST: record variant part is not earlier than its record type";
        end if;
        validate_record_variant_part (self, value.record_variant_part_value);
        declare
          variant_span : constant Adac.Source.Span :=
            node_span (self, value.record_variant_part_value);
        begin
          if not Adac.Source.contains (value.span, variant_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (variant_span))
          then
            raise Program_Error with
              "Adac.AST: record variant part is out of source order";
          end if;
          previous_last := Adac.Source.last_position (variant_span);
        end;
      end if;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: record type span omits end record";
      end if;
    end;
  end validate_record_type_declaration;

  procedure validate_access_object_type_declaration
    (self        : Store;
     declaration : Node_ID)
  is
    designated_subtype : Node_ID;
    designated_span    : Adac.Source.Span;
  begin
    require_access_object_type_declaration (self, declaration);
    declare
      value : Node renames self.nodes(Positive(declaration.index));
    begin
      Adac.Symbols.validate (value.access_object_type_symbol_value);
      Adac.Source.validate (value.access_object_type_defining_span_value);
      Adac.Source.validate (value.span);
      designated_subtype := value.access_object_type_designated_subtype_value;
      require_simple_name (self, designated_subtype);
      if designated_subtype.index >= declaration.index then
        raise Program_Error with
          "Adac.AST: access-to-object designated subtype is not earlier";
      end if;
      validate_simple_name (self, designated_subtype);
      designated_span := node_span (self, designated_subtype);

      if not Adac.Source.contains
        (value.span, value.access_object_type_defining_span_value) or else
         not Adac.Source.contains (value.span, designated_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position
              (value.access_object_type_defining_span_value)) or else
         not precedes
           (Adac.Source.last_position
              (value.access_object_type_defining_span_value),
            Adac.Source.first_position (designated_span)) or else
         not precedes
           (Adac.Source.last_position (designated_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: access-to-object type children are out of source order";
      end if;
    end;
  end validate_access_object_type_declaration;

  procedure validate_exception_handler
    (self    : Store;
     handler : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_exception_handler (self, handler);
    declare
      value : Node renames self.nodes(Positive(handler.index));
    begin
      Adac.Source.validate (value.span);

      if value.exception_handler_choice_parameter_symbol_value =
           Adac.Symbols.INVALID_SYMBOL_ID
      then
        if value.exception_handler_choice_parameter_span_value /=
           Adac.Source.INVALID_SPAN
        then
          raise Program_Error with
            "Adac.AST: absent choice parameter has a source span";
        end if;
        previous_last := Adac.Source.first_position (value.span);
      else
        Adac.Symbols.validate
          (value.exception_handler_choice_parameter_symbol_value);
        Adac.Source.validate
          (value.exception_handler_choice_parameter_span_value);
        if not Adac.Source.contains
          (value.span,
           value.exception_handler_choice_parameter_span_value) or else
           not precedes
             (Adac.Source.first_position (value.span),
              Adac.Source.first_position
                (value.exception_handler_choice_parameter_span_value))
        then
          raise Program_Error with
            "Adac.AST: choice parameter is outside handler span";
        end if;
        previous_last := Adac.Source.last_position
          (value.exception_handler_choice_parameter_span_value);
      end if;

      if value.exception_handler_choices_value.is_empty then
        raise Program_Error with "Adac.AST: exception handler has no choices";
      end if;
      if value.exception_handler_statements_value.is_empty then
        raise Program_Error with "Adac.AST: exception handler body is empty";
      end if;

      for choice of value.exception_handler_choices_value loop
        validate_current_exception_choice (self, choice);
        if choice.index >= handler.index then
          raise Program_Error with
            "Adac.AST: exception choice is not earlier";
        end if;
        declare
          choice_span : constant Adac.Source.Span := node_span (self, choice);
        begin
          if not Adac.Source.contains (value.span, choice_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (choice_span))
          then
            raise Program_Error with
              "Adac.AST: exception choices are out of source order";
          end if;
          previous_last := Adac.Source.last_position (choice_span);
        end;
      end loop;

      for statement of value.exception_handler_statements_value loop
        validate_current_exception_handler_statement (self, statement);
        if statement.index >= handler.index then
          raise Program_Error with
            "Adac.AST: exception-handler statement is not earlier";
        end if;
        declare
          child_span : constant Adac.Source.Span := node_span (self, statement);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: exception-handler body is out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      if previous_last /= Adac.Source.last_position (value.span) then
        raise Program_Error with
          "Adac.AST: exception-handler span does not end with its body";
      end if;
    end;
  end validate_exception_handler;

  procedure validate_handled_sequence
    (self     : Store;
     sequence : Node_ID)
  is
    previous_last : Adac.Source.Position;
    first_child   : Boolean := True;
  begin
    require_handled_sequence (self, sequence);
    declare
      value : Node renames self.nodes(Positive(sequence.index));
    begin
      Adac.Source.validate (value.span);
      if value.handled_sequence_statements_value.is_empty then
        raise Program_Error with "Adac.AST: handled sequence is empty";
      end if;
      for statement of value.handled_sequence_statements_value loop
        validate_current_handled_statement (self, statement);
        if statement.index >= sequence.index then
          raise Program_Error with
            "Adac.AST: handled statement is not earlier";
        end if;
        declare
          child_span : constant Adac.Source.Span := node_span (self, statement);
        begin
          if not Adac.Source.contains (value.span, child_span) then
            raise Program_Error with
              "Adac.AST: handled statement is outside sequence span";
          end if;
          if first_child then
            if Adac.Source.first_position (value.span) /=
               Adac.Source.first_position (child_span)
            then
              raise Program_Error with
                "Adac.AST: handled sequence does not start at first statement";
            end if;
            first_child := False;
          elsif not precedes
            (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: handled statements are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;
      for handler of value.handled_sequence_handlers_value loop
        validate_exception_handler (self, handler);
        if handler.index >= sequence.index then
          raise Program_Error with
            "Adac.AST: handled-sequence handler is not earlier";
        end if;
        declare
          child_span : constant Adac.Source.Span := node_span (self, handler);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: exception handlers are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;
      if previous_last /= Adac.Source.last_position (value.span) then
        raise Program_Error with
          "Adac.AST: handled-sequence span does not end at its final child";
      end if;
    end;
  end validate_handled_sequence;

  procedure validate_compound_statement_graph
    (self         : Store;
     root         : Node_ID;
     handler_root : Node_ID)
  is
    pending : Node_List;
    next    : Positive := 1;

    procedure validate_branch_child
      (owner         : Node_ID;
       owner_span    : Adac.Source.Span;
       child         : Node_ID;
       previous_last : in out Adac.Source.Position;
       branch_name   : String)
    is
      child_span : Adac.Source.Span;
      child_kind : Node_Kind;
    begin
      validate_current_if_child_statement (self, child);
      if child.index >= owner.index then
        raise Program_Error with
          "Adac.AST: " & branch_name & " child is not earlier";
      end if;

      child_kind := self.nodes(Positive(child.index)).kind;
      if child_kind = If_Statement_Node or else
         child_kind = Block_Statement_Node or else
         child_kind = Loop_Statement_Node or else
         child_kind = Case_Statement_Node
      then
        append (pending, child);
      end if;

      child_span := node_span (self, child);
      if not Adac.Source.contains (owner_span, child_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (child_span))
      then
        raise Program_Error with
          "Adac.AST: " & branch_name & " statements are out of source order";
      end if;
      previous_last := Adac.Source.last_position (child_span);
    end validate_branch_child;

    procedure validate_elsif_node (part : Node_ID) is
      value : Node renames self.nodes(Positive(part.index));
      condition_span : Adac.Source.Span;
      previous_last  : Adac.Source.Position;
    begin
      require_elsif_part (self, part);
      Adac.Source.validate (value.span);
      validate_expression (self, value.elsif_condition_value);
      if value.elsif_condition_value.index >= part.index then
        raise Program_Error with "Adac.AST: elsif condition is not earlier";
      end if;
      if value.elsif_statements_value.is_empty then
        raise Program_Error with "Adac.AST: elsif statement list is empty";
      end if;

      condition_span := node_span (self, value.elsif_condition_value);
      if not Adac.Source.contains (value.span, condition_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (condition_span))
      then
        raise Program_Error with
          "Adac.AST: elsif condition span is outside part";
      end if;

      previous_last := Adac.Source.last_position (condition_span);
      for child of value.elsif_statements_value loop
        validate_branch_child
          (part, value.span, child, previous_last, "elsif");
      end loop;
      if previous_last /= Adac.Source.last_position (value.span) then
        raise Program_Error with
          "Adac.AST: elsif span does not end at its final statement";
      end if;
    end validate_elsif_node;

    procedure validate_if_node (if_statement : Node_ID) is
      previous_last  : Adac.Source.Position;
      value : Node renames self.nodes(Positive(if_statement.index));
      condition_span : Adac.Source.Span;
    begin
      require_if_statement (self, if_statement);
      Adac.Source.validate (value.span);
      validate_expression (self, value.if_condition_value);

      if value.if_condition_value.index >= if_statement.index then
        raise Program_Error with "Adac.AST: if condition is not earlier";
      end if;
      if value.if_then_statements_value.is_empty then
        raise Program_Error with "Adac.AST: if then branch is empty";
      end if;

      condition_span := node_span (self, value.if_condition_value);
      if not Adac.Source.contains (value.span, condition_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (condition_span))
      then
        raise Program_Error with
          "Adac.AST: if condition span is outside statement";
      end if;

      previous_last := Adac.Source.last_position (condition_span);
      for child of value.if_then_statements_value loop
        validate_branch_child
          (if_statement, value.span, child, previous_last, "if then");
      end loop;

      for part of value.if_elsif_parts_value loop
        require_elsif_part (self, part);
        if part.index >= if_statement.index then
          raise Program_Error with "Adac.AST: elsif part is not earlier";
        end if;
        declare
          part_span : constant Adac.Source.Span := node_span (self, part);
        begin
          if not Adac.Source.contains (value.span, part_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (part_span))
          then
            raise Program_Error with
              "Adac.AST: elsif parts are out of source order";
          end if;
          previous_last := Adac.Source.last_position (part_span);
        end;
        append (pending, part);
      end loop;

      for child of value.if_else_statements_value loop
        validate_branch_child
          (if_statement, value.span, child, previous_last, "if else");
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: if span does not include its closing syntax";
      end if;
    end validate_if_node;

    procedure validate_block_node (block_statement : Node_ID) is
      previous_last : Adac.Source.Position;
      value : Node renames self.nodes(Positive(block_statement.index));
      sequence : Node_ID;
      sequence_span : Adac.Source.Span;
      first_statement : Boolean := True;
      sequence_last : Adac.Source.Position;
    begin
      require_block_statement (self, block_statement);
      Adac.Source.validate (value.span);
      previous_last := Adac.Source.first_position (value.span);

      for declaration of value.block_declarations_value loop
        validate_current_block_declaration (self, declaration);
        if declaration.index >= block_statement.index then
          raise Program_Error with "Adac.AST: block declaration is not earlier";
        end if;
        declare
          child_span : constant Adac.Source.Span :=
            node_span (self, declaration);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: block declarations are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      sequence := value.block_handled_sequence_value;
      require_handled_sequence (self, sequence);
      if sequence.index >= block_statement.index then
        raise Program_Error with
          "Adac.AST: block handled sequence is not earlier";
      end if;

      declare
        sequence_value : Node renames self.nodes(Positive(sequence.index));
      begin
        Adac.Source.validate (sequence_value.span);
        if sequence_value.handled_sequence_statements_value.is_empty then
          raise Program_Error with
            "Adac.AST: current block handled sequence is empty";
        end if;
        sequence_last := Adac.Source.first_position (sequence_value.span);
        for child of sequence_value.handled_sequence_statements_value loop
          validate_node_id (self, child);
          case self.nodes(Positive(child.index)).kind is
            when Assignment_Statement_Node =>
              Structural_Validation.validate_assignment_statement (self, child);
            when Exit_Statement_Node =>
              Structural_Validation.validate_exit_statement (self, child);
            when Block_Statement_Node =>
              if not sequence_value.handled_sequence_handlers_value
                .is_empty
              then
                declare
                  nested_sequence : constant Node_ID :=
                    self.nodes(Positive(child.index))
                      .block_handled_sequence_value;
                begin
                  require_handled_sequence (self, nested_sequence);
                  if not self.nodes
                    (Positive(nested_sequence.index))
                      .handled_sequence_handlers_value.is_empty
                  then
                    raise Program_Error with
                      "Adac.AST: handler-bearing block owns a handled " &
                      "block child";
                  end if;
                end;
              end if;
              append (pending, child);

            when Case_Statement_Node |
                 If_Statement_Node |
                 Loop_Statement_Node =>
              append (pending, child);
            when Procedure_Call_Statement_Node =>
              Structural_Validation.validate_procedure_call (self, child);
            when Return_Statement_Node =>
              Structural_Validation.validate_return_statement (self, child);
            when others =>
              raise Program_Error with
                "Adac.AST: current handler-free block body is not a " &
                "bounded block statement";
          end case;

          if child.index >= sequence.index then
            raise Program_Error with
              "Adac.AST: handled statement is not earlier";
          end if;
          declare
            child_span : constant Adac.Source.Span := node_span (self, child);
          begin
            if not Adac.Source.contains (sequence_value.span, child_span) then
              raise Program_Error with
                "Adac.AST: handled statement is outside sequence span";
            end if;
            if first_statement then
              if Adac.Source.first_position (sequence_value.span) /=
                 Adac.Source.first_position (child_span)
              then
                raise Program_Error with
                  "Adac.AST: handled sequence does not start at " &
                  "first statement";
              end if;
              first_statement := False;
            elsif not precedes
              (sequence_last, Adac.Source.first_position (child_span))
            then
              raise Program_Error with
                "Adac.AST: handled statements are out of source order";
            end if;
            sequence_last := Adac.Source.last_position (child_span);
          end;
        end loop;

        if handler_root /= INVALID_NODE_ID and then
           block_statement /= handler_root and then
           not sequence_value.handled_sequence_handlers_value.is_empty
        then
          raise Program_Error with
            "Adac.AST: handler-owned block contains a nested handled block";
        end if;

        for handler of sequence_value.handled_sequence_handlers_value loop
          validate_node_id (self, handler);
          if handler_root /= INVALID_NODE_ID and then
             block_statement = handler_root
          then
            require_exception_handler (self, handler);
            declare
              handler_value : Node renames self.nodes(Positive(handler.index));
            begin
              for nested_statement of
                handler_value.exception_handler_statements_value
              loop
                validate_node_id (self, nested_statement);
                case self.nodes(Positive(nested_statement.index)).kind is
                  when Null_Statement_Node |
                       Return_Statement_Node |
                       Assignment_Statement_Node |
                       Procedure_Call_Statement_Node |
                       Raise_Statement_Node =>
                    null;
                  when others =>
                    raise Program_Error with
                      "Adac.AST: handler-owned block has recursive handler " &
                      "syntax";
                end case;
              end loop;
            end;
          end if;
          if handler.index >= sequence.index then
            raise Program_Error with
              "Adac.AST: exception handler is not earlier than its sequence";
          end if;
          Structural_Validation.validate_exception_handler (self, handler);
          declare
            handler_span : constant Adac.Source.Span :=
              node_span (self, handler);
          begin
            if not Adac.Source.contains
              (sequence_value.span, handler_span) or else
               not precedes
                 (sequence_last, Adac.Source.first_position (handler_span))
            then
              raise Program_Error with
                "Adac.AST: block exception handlers are out of source order";
            end if;
            sequence_last := Adac.Source.last_position (handler_span);
          end;
        end loop;

        if sequence_last /= Adac.Source.last_position (sequence_value.span) then
          raise Program_Error with
            "Adac.AST: handled-sequence span does not end at its final child";
        end if;
      end;

      sequence_span := node_span (self, sequence);
      if not Adac.Source.contains (value.span, sequence_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (sequence_span)) or else
         not precedes
           (Adac.Source.last_position (sequence_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: block handled sequence is outside statement";
      end if;
    end validate_block_node;

    procedure validate_loop_node (loop_statement : Node_ID) is
      previous_last : Adac.Source.Position;
      value : Node renames self.nodes(Positive(loop_statement.index));
    begin
      require_loop_statement (self, loop_statement);
      Adac.Source.validate (value.span);
      if value.loop_statements_value.is_empty then
        raise Program_Error with "Adac.AST: loop body is empty";
      end if;

      if value.loop_form_value = Discrete_Range_Loop_Form then
        if value.loop_condition_value /= INVALID_NODE_ID or else
           value.loop_iterable_name_value /= INVALID_NODE_ID or else
           value.loop_range_attribute_value /= INVALID_NODE_ID
        then
          raise Program_Error with
            "Adac.AST: discrete-range loop retained another header form";
        end if;
        Adac.Symbols.validate (value.loop_parameter_symbol_value);
        Adac.Source.validate (value.loop_parameter_span_value);
        require_current_simple_expression
          (self, value.loop_range_lower_bound_value);
        require_current_simple_expression
          (self, value.loop_range_upper_bound_value);

        if value.loop_range_lower_bound_value.index >=
             value.loop_range_upper_bound_value.index or else
           value.loop_range_upper_bound_value.index >= loop_statement.index
        then
          raise Program_Error with
            "Adac.AST: discrete-range loop bounds are not earlier/in order";
        end if;

        validate_expression (self, value.loop_range_lower_bound_value);
        validate_expression (self, value.loop_range_upper_bound_value);
        declare
          lower_span : constant Adac.Source.Span :=
            node_span (self, value.loop_range_lower_bound_value);
          upper_span : constant Adac.Source.Span :=
            node_span (self, value.loop_range_upper_bound_value);
        begin
          if not Adac.Source.contains
               (value.span, value.loop_parameter_span_value) or else
             not Adac.Source.contains (value.span, lower_span) or else
             not Adac.Source.contains (value.span, upper_span) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.loop_parameter_span_value)) or else
             not precedes
               (Adac.Source.last_position
                  (value.loop_parameter_span_value),
                Adac.Source.first_position (lower_span)) or else
             not precedes
               (Adac.Source.last_position (lower_span),
                Adac.Source.first_position (upper_span))
          then
            raise Program_Error with
              "Adac.AST: discrete-range loop header is out of source order";
          end if;
          previous_last := Adac.Source.last_position (upper_span);
        end;
      elsif value.loop_form_value = Range_Attribute_Loop_Form then
        if value.loop_condition_value /= INVALID_NODE_ID or else
           value.loop_iterable_name_value /= INVALID_NODE_ID or else
           value.loop_range_lower_bound_value /= INVALID_NODE_ID or else
           value.loop_range_upper_bound_value /= INVALID_NODE_ID
        then
          raise Program_Error with
            "Adac.AST: range-attribute loop retained another header form";
        end if;
        Adac.Symbols.validate (value.loop_parameter_symbol_value);
        Adac.Source.validate (value.loop_parameter_span_value);
        require_attribute_name (self, value.loop_range_attribute_value);
        Structural_Validation.validate_name
          (self, value.loop_range_attribute_value);

        if value.loop_range_attribute_value.index >= loop_statement.index then
          raise Program_Error with
            "Adac.AST: range-attribute loop name is not earlier";
        end if;

        declare
          attribute_span : constant Adac.Source.Span :=
            node_span (self, value.loop_range_attribute_value);
        begin
          if not Adac.Source.contains
               (value.span, value.loop_parameter_span_value) or else
             not Adac.Source.contains (value.span, attribute_span) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.loop_parameter_span_value)) or else
             not precedes
               (Adac.Source.last_position
                  (value.loop_parameter_span_value),
                Adac.Source.first_position (attribute_span))
          then
            raise Program_Error with
              "Adac.AST: range-attribute loop header is out of source order";
          end if;
          previous_last := Adac.Source.last_position (attribute_span);
        end;

      elsif value.loop_form_value = Generalized_Iterator_Loop_Form then
        if value.loop_condition_value /= INVALID_NODE_ID or else
           value.loop_range_attribute_value /= INVALID_NODE_ID or else
           value.loop_range_lower_bound_value /= INVALID_NODE_ID or else
           value.loop_range_upper_bound_value /= INVALID_NODE_ID
        then
          raise Program_Error with
            "Adac.AST: iterator loop retained another header form";
        end if;
        Adac.Symbols.validate (value.loop_parameter_symbol_value);
        Adac.Source.validate (value.loop_parameter_span_value);
        Structural_Validation.validate_name
          (self, value.loop_iterable_name_value);

        if value.loop_iterable_name_value.index >= loop_statement.index then
          raise Program_Error with
            "Adac.AST: iterator-loop iterable name is not earlier";
        end if;

        declare
          iterable_span : constant Adac.Source.Span :=
            node_span (self, value.loop_iterable_name_value);
        begin
          if not Adac.Source.contains
            (value.span, value.loop_parameter_span_value) or else
             not Adac.Source.contains (value.span, iterable_span) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.loop_parameter_span_value)) or else
             not precedes
               (Adac.Source.last_position
                  (value.loop_parameter_span_value),
                Adac.Source.first_position (iterable_span))
          then
            raise Program_Error with
              "Adac.AST: iterator-loop header is out of source order";
          end if;
          previous_last := Adac.Source.last_position (iterable_span);
        end;
      elsif value.loop_form_value = While_Loop_Form then
        if value.loop_parameter_symbol_value /=
             Adac.Symbols.INVALID_SYMBOL_ID or else
           value.loop_parameter_span_value /= Adac.Source.INVALID_SPAN or else
           value.loop_reverse_value or else
           value.loop_iterable_name_value /= INVALID_NODE_ID or else
           value.loop_range_attribute_value /= INVALID_NODE_ID or else
           value.loop_range_lower_bound_value /= INVALID_NODE_ID or else
           value.loop_range_upper_bound_value /= INVALID_NODE_ID
        then
          raise Program_Error with
            "Adac.AST: while loop retained iterator header syntax";
        end if;
        require_current_expression (self, value.loop_condition_value);
        if value.loop_condition_value.index >= loop_statement.index then
          raise Program_Error with
            "Adac.AST: while-loop condition is not earlier";
        end if;
        validate_expression (self, value.loop_condition_value);
        declare
          condition_span : constant Adac.Source.Span :=
            node_span (self, value.loop_condition_value);
        begin
          if not Adac.Source.contains (value.span, condition_span) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position (condition_span))
          then
            raise Program_Error with
              "Adac.AST: while-loop condition is out of source order";
          end if;
          previous_last := Adac.Source.last_position (condition_span);
        end;
      else
        if value.loop_condition_value /= INVALID_NODE_ID or else
           value.loop_parameter_symbol_value /=
             Adac.Symbols.INVALID_SYMBOL_ID or else
           value.loop_parameter_span_value /= Adac.Source.INVALID_SPAN or else
           value.loop_reverse_value or else
           value.loop_iterable_name_value /= INVALID_NODE_ID or else
           value.loop_range_lower_bound_value /= INVALID_NODE_ID or else
           value.loop_range_upper_bound_value /= INVALID_NODE_ID
        then
          raise Program_Error with
            "Adac.AST: simple loop retained iteration-scheme syntax";
        end if;
        previous_last := Adac.Source.first_position (value.span);
      end if;

      for child of value.loop_statements_value loop
        validate_current_loop_statement (self, child);
        if child.index >= loop_statement.index then
          raise Program_Error with
            "Adac.AST: loop body statement is not earlier";
        end if;
        case self.nodes(Positive(child.index)).kind is
          when Case_Statement_Node | If_Statement_Node | Block_Statement_Node =>
            append (pending, child);
          when others =>
            null;
        end case;
        declare
          child_span : constant Adac.Source.Span := node_span (self, child);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: loop body is out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: loop span misses its closing syntax";
      end if;
    end validate_loop_node;

    procedure validate_case_alternative_node (alternative : Node_ID) is
      previous_last : Adac.Source.Position;
      value : Node renames self.nodes(Positive(alternative.index));
    begin
      require_case_alternative (self, alternative);
      Adac.Source.validate (value.span);
      if value.case_alternative_choices_value.is_empty then
        raise Program_Error with
          "Adac.AST: case alternative choice list is empty";
      end if;
      if value.case_alternative_statements_value.is_empty then
        raise Program_Error with
          "Adac.AST: case alternative statement list is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for choice of value.case_alternative_choices_value loop
        validate_node_id (self, choice);
        case self.nodes(Positive(choice.index)).kind is
          when Identifier_Name_Node | Selected_Name_Node =>
            Structural_Validation.validate_name (self, choice);
          when Numeric_Literal_Node =>
            Structural_Validation.validate_numeric_literal (self, choice);
          when Character_Literal_Node =>
            Structural_Validation.validate_character_literal (self, choice);
          when Case_Range_Choice_Node =>
            validate_case_range_choice (self, choice);
          when Others_Case_Choice_Node =>
            Adac.Source.validate (self.nodes(Positive(choice.index)).span);
            if Natural(value.case_alternative_choices_value.length) /= 1 then
              raise Program_Error with
                "Adac.AST: others case choice is not sole";
            end if;
          when others =>
            raise Program_Error with
              "Adac.AST: node is not a current case choice";
        end case;
        if choice.index >= alternative.index then
          raise Program_Error with "Adac.AST: case choice is not earlier";
        end if;
        declare
          child_span : constant Adac.Source.Span := node_span (self, choice);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: case choices are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      for child of value.case_alternative_statements_value loop
        validate_current_case_alternative_statement (self, child);
        if child.index >= alternative.index then
          raise Program_Error with
            "Adac.AST: case alternative statement is not earlier";
        end if;
        if self.nodes(Positive(child.index)).kind = If_Statement_Node or else
           self.nodes(Positive(child.index)).kind = Block_Statement_Node or else
           self.nodes(Positive(child.index)).kind = Loop_Statement_Node or else
           self.nodes(Positive(child.index)).kind = Case_Statement_Node
        then
          append (pending, child);
        end if;
        declare
          child_span : constant Adac.Source.Span := node_span (self, child);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: case alternative statements are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      if previous_last /= Adac.Source.last_position (value.span) then
        raise Program_Error with
          "Adac.AST: case alternative span does not end at its final statement";
      end if;
    end validate_case_alternative_node;

    procedure validate_case_node (case_statement : Node_ID) is
      previous_last : Adac.Source.Position;
      value : Node renames self.nodes(Positive(case_statement.index));
      selecting_span : Adac.Source.Span;
    begin
      require_case_statement (self, case_statement);
      Adac.Source.validate (value.span);
      Structural_Validation.validate_expression
        (self, value.case_selecting_expression_value);
      if value.case_selecting_expression_value.index >=
         case_statement.index
      then
        raise Program_Error with
          "Adac.AST: case selecting expression is not earlier";
      end if;
      if value.case_alternatives_value.is_empty then
        raise Program_Error with "Adac.AST: case alternative list is empty";
      end if;

      selecting_span := node_span (self, value.case_selecting_expression_value);
      if not Adac.Source.contains (value.span, selecting_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (selecting_span))
      then
        raise Program_Error with
          "Adac.AST: case selecting expression is outside statement";
      end if;
      previous_last := Adac.Source.last_position (selecting_span);

      for alternative of value.case_alternatives_value loop
        require_case_alternative (self, alternative);
        if alternative.index >= case_statement.index then
          raise Program_Error with "Adac.AST: case alternative is not earlier";
        end if;
        append (pending, alternative);
        declare
          child_span : constant Adac.Source.Span :=
            node_span (self, alternative);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: case alternatives are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: case span does not include its closing syntax";
      end if;
    end validate_case_node;

  begin
    validate_node_id (self, root);
    case self.nodes(Positive(root.index)).kind is
      when If_Statement_Node | Elsif_Part_Node | Block_Statement_Node |
           Loop_Statement_Node | Case_Statement_Node | Case_Alternative_Node =>
        append (pending, root);
      when others =>
        raise Program_Error with
          "Adac.AST: invalid root in compound validation graph";
    end case;

    while next <= list_count (pending) loop
      declare
        current : constant Node_ID := list_element (pending, next);
      begin
        case self.nodes(Positive(current.index)).kind is
          when If_Statement_Node =>
            validate_if_node (current);
          when Elsif_Part_Node =>
            validate_elsif_node (current);
          when Block_Statement_Node =>
            validate_block_node (current);
          when Loop_Statement_Node =>
            validate_loop_node (current);
          when Case_Statement_Node =>
            validate_case_node (current);
          when Case_Alternative_Node =>
            validate_case_alternative_node (current);
          when others =>
            raise Program_Error with
              "Adac.AST: invalid node in compound validation worklist";
        end case;
      end;
      next := next + 1;
    end loop;
  end validate_compound_statement_graph;

  procedure validate_exception_handler_block_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    require_block_statement (self, statement);
    validate_compound_statement_graph (self, statement, statement);
  end validate_exception_handler_block_statement;

  procedure validate_elsif_part
    (self : Store;
     part : Node_ID)
  is
  begin
    require_elsif_part (self, part);
    validate_compound_statement_graph (self, part, INVALID_NODE_ID);
  end validate_elsif_part;

  procedure validate_if_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    require_if_statement (self, statement);
    validate_compound_statement_graph (self, statement, INVALID_NODE_ID);
  end validate_if_statement;

  procedure validate_extended_return_statement
    (self      : Store;
     statement : Node_ID)
  is
    subtype_span  : Adac.Source.Span;
    sequence_span : Adac.Source.Span;
  begin
    require_extended_return_statement (self, statement);
    declare
      value : Node renames self.nodes(Positive(statement.index));
    begin
      Adac.Symbols.validate (value.extended_return_symbol_value);
      Adac.Source.validate (value.extended_return_defining_span_value);
      Adac.Source.validate (value.span);
      require_simple_name (self, value.extended_return_subtype_mark_value);
      require_handled_sequence
        (self, value.extended_return_handled_sequence_value);

      if value.extended_return_subtype_mark_value.index >=
           statement.index or else
         value.extended_return_handled_sequence_value.index >=
           statement.index or else
         value.extended_return_subtype_mark_value.index >=
           value.extended_return_handled_sequence_value.index
      then
        raise Program_Error with
          "Adac.AST: extended return children are not earlier and ordered";
      end if;

      validate_name (self, value.extended_return_subtype_mark_value);
      declare
        sequence_value : Node renames
          self.nodes
            (Positive(value.extended_return_handled_sequence_value.index));
      begin
        if sequence_value.handled_sequence_statements_value.is_empty or else
           not sequence_value.handled_sequence_handlers_value.is_empty
        then
          raise Program_Error with
            "Adac.AST: extended return requires a handler-free body";
        end if;
        for child of sequence_value.handled_sequence_statements_value loop
          validate_node_id (self, child);
          if self.nodes(Positive(child.index)).kind not in
            Null_Statement_Node |
            Assignment_Statement_Node | Procedure_Call_Statement_Node
          then
            raise Program_Error with
              "Adac.AST: extended return body statement is not supported";
          end if;
        end loop;
      end;
      validate_handled_sequence
        (self, value.extended_return_handled_sequence_value);

      subtype_span :=
        node_span (self, value.extended_return_subtype_mark_value);
      sequence_span :=
        node_span (self, value.extended_return_handled_sequence_value);
      if not Adac.Source.contains
        (value.span, value.extended_return_defining_span_value) or else
         not Adac.Source.contains (value.span, subtype_span) or else
         not Adac.Source.contains (value.span, sequence_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position
              (value.extended_return_defining_span_value)) or else
         not precedes
           (Adac.Source.last_position
              (value.extended_return_defining_span_value),
            Adac.Source.first_position (subtype_span)) or else
         not precedes
           (Adac.Source.last_position (subtype_span),
            Adac.Source.first_position (sequence_span)) or else
         not precedes
           (Adac.Source.last_position (sequence_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: extended return children are out of source order";
      end if;
    end;
  end validate_extended_return_statement;

  procedure validate_exit_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    require_exit_statement (self, statement);
    declare
      value : Node renames self.nodes(Positive(statement.index));
    begin
      Adac.Source.validate (value.span);
      if (value.exit_loop_name_symbol_value = Adac.Symbols.INVALID_SYMBOL_ID) /=
         (value.exit_loop_name_span_value = Adac.Source.INVALID_SPAN)
      then
        raise Program_Error with
          "Adac.AST: exit loop-name symbol/span presence disagrees";
      end if;

      if value.exit_loop_name_symbol_value /=
         Adac.Symbols.INVALID_SYMBOL_ID
      then
        Adac.Symbols.validate (value.exit_loop_name_symbol_value);
        Adac.Source.validate (value.exit_loop_name_span_value);
        if not Adac.Source.contains
          (value.span, value.exit_loop_name_span_value) or else
           not precedes
             (Adac.Source.first_position (value.span),
              Adac.Source.first_position (value.exit_loop_name_span_value))
        then
          raise Program_Error with
            "Adac.AST: exit loop name is out of source order";
        end if;
      end if;

      if (value.exit_condition_value = INVALID_NODE_ID) /=
         (value.exit_when_span_value = Adac.Source.INVALID_SPAN)
      then
        raise Program_Error with
          "Adac.AST: exit when/condition presence disagrees";
      end if;

      if value.exit_condition_value /= INVALID_NODE_ID then
        if value.exit_condition_value.index >= statement.index then
          raise Program_Error with "Adac.AST: exit condition is not earlier";
        end if;
        validate_when_span (value.exit_when_span_value);
        validate_expression (self, value.exit_condition_value);
        declare
          condition_span : constant Adac.Source.Span :=
            node_span (self, value.exit_condition_value);
          previous_last : Adac.Source.Position;
        begin
          if value.exit_loop_name_symbol_value =
             Adac.Symbols.INVALID_SYMBOL_ID
          then
            previous_last := Adac.Source.first_position (value.span);
          else
            previous_last :=
              Adac.Source.last_position (value.exit_loop_name_span_value);
          end if;
          if not Adac.Source.contains
            (value.span, value.exit_when_span_value) or else
             not Adac.Source.contains (value.span, condition_span) or else
             not precedes
               (previous_last,
                Adac.Source.first_position (value.exit_when_span_value)) or else
             not precedes
               (Adac.Source.last_position (value.exit_when_span_value),
                Adac.Source.first_position (condition_span)) or else
             not precedes
               (Adac.Source.last_position (condition_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: exit condition is out of source order";
          end if;
        end;
      elsif value.exit_loop_name_symbol_value /=
              Adac.Symbols.INVALID_SYMBOL_ID and then
            not precedes
              (Adac.Source.last_position (value.exit_loop_name_span_value),
               Adac.Source.last_position (value.span))
      then
        raise Program_Error with "Adac.AST: exit span omits its terminator";
      end if;
    end;
  end validate_exit_statement;

  procedure validate_return_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    require_return_statement (self, statement);
    declare
      value : Node renames self.nodes(Positive(statement.index));
    begin
      Adac.Source.validate (value.span);
      if value.return_expression_value /= INVALID_NODE_ID then
        if value.return_expression_value.index >= statement.index then
          raise Program_Error with "Adac.AST: return expression is not earlier";
        end if;
        validate_expression (self, value.return_expression_value);
        declare
          expression_span : constant Adac.Source.Span :=
            node_span (self, value.return_expression_value);
        begin
          if not Adac.Source.contains (value.span, expression_span) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position (expression_span)) or else
             not precedes
               (Adac.Source.last_position (expression_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: return expression is out of source order";
          end if;
        end;
      end if;
    end;
  end validate_return_statement;

  procedure validate_raise_statement
    (self      : Store;
     statement : Node_ID)
  is
    exception_span : Adac.Source.Span;
    message_span   : Adac.Source.Span;
  begin
    require_raise_statement (self, statement);
    declare
      value : Node renames self.nodes(Positive(statement.index));
    begin
      Adac.Source.validate (value.span);
      case value.raise_form_value is
        when Bare_Reraise_Form =>
          if value.raise_exception_name_value /= INVALID_NODE_ID or else
             value.raise_message_expression_value /= INVALID_NODE_ID
          then
            raise Program_Error with
              "Adac.AST: bare re-raise has unexpected children";
          end if;

        when Named_With_Message_Raise_Form =>
          require_simple_name (self, value.raise_exception_name_value);
          require_current_expression
            (self, value.raise_message_expression_value);
          if value.raise_exception_name_value.index >=
               value.raise_message_expression_value.index or else
             value.raise_message_expression_value.index >= statement.index
          then
            raise Program_Error with
              "Adac.AST: raise-statement children are not earlier and ordered";
          end if;
          validate_name (self, value.raise_exception_name_value);
          validate_expression (self, value.raise_message_expression_value);
          exception_span := node_span (self, value.raise_exception_name_value);
          message_span :=
            node_span (self, value.raise_message_expression_value);
          if not Adac.Source.contains (value.span, exception_span) or else
             not Adac.Source.contains (value.span, message_span) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position (exception_span)) or else
             not precedes
               (Adac.Source.last_position (exception_span),
                Adac.Source.first_position (message_span)) or else
             not precedes
               (Adac.Source.last_position (message_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: raise-statement children are out of source order";
          end if;
      end case;
    end;
  end validate_raise_statement;

  procedure validate_assignment_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    require_assignment_statement (self, statement);

    declare
      value : Node renames self.nodes(Positive(statement.index));
      target_span : Adac.Source.Span;
      expression_span : Adac.Source.Span;
    begin
      Adac.Source.validate (value.span);
      validate_name (self, value.assignment_target_value);
      validate_expression (self, value.assignment_expression_value);

      if value.assignment_target_value.index >= statement.index or else
         value.assignment_expression_value.index >= statement.index
      then
        raise Program_Error with "Adac.AST: assignment child is not earlier";
      end if;

      target_span := node_span (self, value.assignment_target_value);
      expression_span := node_span (self, value.assignment_expression_value);

      if not Adac.Source.contains (value.span, target_span) or else
         not Adac.Source.contains (value.span, expression_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (target_span)
      then
        raise Program_Error with
          "Adac.AST: assignment child span is outside statement";
      end if;

      if not precedes
        (Adac.Source.last_position (target_span),
         Adac.Source.first_position (expression_span)) or else
         not precedes
           (Adac.Source.last_position (expression_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: assignment children are out of source order";
      end if;
    end;
  end validate_assignment_statement;

  procedure validate_case_alternative
    (self        : Store;
     alternative : Node_ID)
  is
  begin
    require_case_alternative (self, alternative);
    validate_compound_statement_graph (self, alternative, INVALID_NODE_ID);
  end validate_case_alternative;

  procedure validate_case_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    require_case_statement (self, statement);
    validate_compound_statement_graph (self, statement, INVALID_NODE_ID);
  end validate_case_statement;

  procedure validate_block_statement
    (self      : Store;
     statement : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_block_statement (self, statement);
    declare
      sequence : constant Node_ID :=
        self.nodes(Positive(statement.index)).block_handled_sequence_value;
    begin
      require_handled_sequence (self, sequence);
      if self.nodes(Positive(sequence.index)).handled_sequence_handlers_value
        .is_empty
      then
        validate_compound_statement_graph (self, statement, INVALID_NODE_ID);
        return;
      end if;
    end;
    declare
      value : Node renames self.nodes(Positive(statement.index));
      sequence_span : Adac.Source.Span;
    begin
      Adac.Source.validate (value.span);
      previous_last := Adac.Source.first_position (value.span);

      for declaration of value.block_declarations_value loop
        validate_current_block_declaration (self, declaration);
        if declaration.index >= statement.index then
          raise Program_Error with "Adac.AST: block declaration is not earlier";
        end if;
        declare
          child_span : constant Adac.Source.Span :=
            node_span (self, declaration);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: block declarations are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      validate_current_block_handled_sequence
        (self, value.block_handled_sequence_value);
      Structural_Validation.validate_handled_sequence
        (self, value.block_handled_sequence_value);
      if value.block_handled_sequence_value.index >= statement.index then
        raise Program_Error with
          "Adac.AST: block handled sequence is not earlier";
      end if;
      sequence_span := node_span (self, value.block_handled_sequence_value);
      if not Adac.Source.contains (value.span, sequence_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (sequence_span)) or else
         not precedes
           (Adac.Source.last_position (sequence_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: block handled sequence is outside statement";
      end if;
    end;
  end validate_block_statement;

  procedure validate_loop_statement
    (self      : Store;
     statement : Node_ID)
  is
  begin
    require_loop_statement (self, statement);
    validate_compound_statement_graph (self, statement, INVALID_NODE_ID);
  end validate_loop_statement;

  procedure validate_procedure_call
    (self      : Store;
     statement : Node_ID)
  is
    previous_last    : Adac.Source.Position;
    saw_named_actual : Boolean := False;
  begin
    require_procedure_call (self, statement);

    declare
      value : Node renames self.nodes(Positive(statement.index));
      callable_span : Adac.Source.Span;
    begin
      Adac.Source.validate (value.span);
      validate_name (self, value.procedure_call_callable_name_value);

      if value.procedure_call_callable_name_value.index >= statement.index then
        raise Program_Error with
          "Adac.AST: procedure-call callable name is not earlier";
      end if;

      callable_span :=
        node_span (self, value.procedure_call_callable_name_value);

      if not Adac.Source.contains (value.span, callable_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (callable_span)
      then
        raise Program_Error with
          "Adac.AST: callable-name span is outside procedure call";
      end if;

      previous_last := Adac.Source.last_position (callable_span);

      for item of value.procedure_call_actuals_value loop
        if item.form = Named_Procedure_Call_Actual_Form then
          saw_named_actual := True;
          validate_node_id (self, item.selector);
          if self.nodes(Positive(item.selector.index)).kind /=
             Identifier_Name_Node
          then
            raise Program_Error with
              "Adac.AST: named procedure-call selector is not an identifier";
          end if;
          if item.selector.index >= statement.index then
            raise Program_Error with
              "Adac.AST: procedure-call selector is not earlier";
          end if;

          declare
            selector_span : constant Adac.Source.Span :=
              node_span (self, item.selector);
          begin
            if not Adac.Source.contains (value.span, selector_span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (selector_span))
            then
              raise Program_Error with
                "Adac.AST: procedure-call selector is out of source order";
            end if;
            previous_last := Adac.Source.last_position (selector_span);
          end;
        elsif saw_named_actual then
          raise Program_Error with
            "Adac.AST: positional procedure-call actual follows named actual";
        end if;

        validate_expression (self, item.actual);

        if item.actual.index >= statement.index then
          raise Program_Error with
            "Adac.AST: procedure-call actual is not earlier";
        end if;

        declare
          actual_span : constant Adac.Source.Span :=
            node_span (self, item.actual);
        begin
          if not Adac.Source.contains (value.span, actual_span) then
            raise Program_Error with
              "Adac.AST: actual span is outside procedure call";
          end if;

          if not precedes
            (previous_last, Adac.Source.first_position (actual_span))
          then
            raise Program_Error with
              "Adac.AST: procedure-call actuals are out of source order";
          end if;

          previous_last := Adac.Source.last_position (actual_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: procedure-call span does not include its terminator";
      end if;
    end;
  end validate_procedure_call;

  procedure validate_character_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    require_character_literal (self, literal);
    validate_character_literal_shape
      (Ada.Strings.Unbounded.to_string
         (self.nodes(Positive(literal.index)).character_spelling),
       self.nodes(Positive(literal.index)).span);
  end validate_character_literal;

  procedure validate_string_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    require_string_literal (self, literal);
    validate_string_literal_shape
      (Ada.Strings.Unbounded.to_string
         (self.nodes(Positive(literal.index)).string_spelling),
       self.nodes(Positive(literal.index)).span);
  end validate_string_literal;

  procedure validate_null_literal
    (self    : Store;
     literal : Node_ID)
  is
  begin
    require_null_literal (self, literal);
    Adac.Source.validate (self.nodes(Positive(literal.index)).span);
  end validate_null_literal;

  procedure validate_nonaggregate_simple_expression_shape
    (self       : Store;
     expression : Node_ID)
  is
  begin
    require_nonaggregate_simple_expression (self, expression);
  end validate_nonaggregate_simple_expression_shape;

  procedure validate_record_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
    pending    : Node_List;
    next_index : Natural := 1;

    procedure validate_one (current : Node_ID) is
      previous_last : Adac.Source.Position;
    begin
      require_record_aggregate (self, current);
      declare
        value : Node renames self.nodes(Positive(current.index));
      begin
        Adac.Source.validate (value.span);
        if value.record_aggregate_associations_value.is_empty then
          raise Program_Error with
            "Adac.AST: record aggregate association list is empty";
        end if;
        previous_last := Adac.Source.first_position (value.span);

        for association of value.record_aggregate_associations_value loop
          Adac.Symbols.validate (association.selector);
          Adac.Source.validate (association.selector_span);
          require_record_aggregate_value (self, association.expression);
          if association.expression.index >= current.index then
            raise Program_Error with
              "Adac.AST: record aggregate value is not earlier";
          end if;

          if self.nodes(Positive(association.expression.index)).kind =
             Record_Aggregate_Node
          then
            append (pending, association.expression);
          else
            validate_expression (self, association.expression);
          end if;

          declare
            expression_span : constant Adac.Source.Span :=
              self.nodes(Positive(association.expression.index)).span;
          begin
            if not Adac.Source.contains
              (value.span, association.selector_span) or else
               not Adac.Source.contains (value.span, expression_span) or else
               not precedes
                 (previous_last,
                  Adac.Source.first_position
                    (association.selector_span)) or else
               not precedes
                 (Adac.Source.last_position (association.selector_span),
                  Adac.Source.first_position (expression_span))
            then
              raise Program_Error with
                "Adac.AST: record aggregate association is out of source order";
            end if;
            previous_last := Adac.Source.last_position (expression_span);
          end;
        end loop;

        if not precedes
          (previous_last, Adac.Source.last_position (value.span))
        then
          raise Program_Error with
            "Adac.AST: record aggregate span misses its closing delimiter";
        end if;
      end;
    end validate_one;
  begin
    require_record_aggregate (self, aggregate);
    append (pending, aggregate);

    while next_index <= list_count (pending) loop
      validate_one (list_element (pending, Positive(next_index)));
      next_index := next_index + 1;
    end loop;
  end validate_record_aggregate;

  procedure validate_array_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
    previous_last : Adac.Source.Position;

    procedure validate_choices
      (value       : Node;
       association : Array_Component_Association)
    is
    begin
      if association.choices.is_empty then
        raise Program_Error with
          "Adac.AST: array aggregate choice list is empty";
      end if;

      for choice of association.choices loop
        validate_node_id (self, choice);
        if choice.index >= aggregate.index then
          raise Program_Error with
            "Adac.AST: array aggregate choice is not earlier";
        end if;
        validate_nonaggregate_simple_expression_shape (self, choice);
        validate_expression (self, choice);

        declare
          choice_span : constant Adac.Source.Span :=
            self.nodes(Positive(choice.index)).span;
        begin
          if not Adac.Source.contains (value.span, choice_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (choice_span))
          then
            raise Program_Error with
              "Adac.AST: array aggregate choice is out of source order";
          end if;
          previous_last := Adac.Source.last_position (choice_span);
        end;
      end loop;
    end validate_choices;
  begin
    require_array_aggregate (self, aggregate);
    declare
      value : Node renames self.nodes(Positive(aggregate.index));
    begin
      Adac.Source.validate (value.span);
      if value.array_aggregate_associations_value.is_empty then
        raise Program_Error with
          "Adac.AST: array aggregate association list is empty";
      end if;
      previous_last := Adac.Source.first_position (value.span);

      for association of value.array_aggregate_associations_value loop
        validate_choices (value, association);
        validate_node_id (self, association.expression);
        if association.expression.index >= aggregate.index then
          raise Program_Error with
            "Adac.AST: array aggregate value is not earlier";
        end if;
        validate_nonaggregate_simple_expression_shape
          (self, association.expression);
        validate_expression (self, association.expression);

        declare
          expression_span : constant Adac.Source.Span :=
            self.nodes(Positive(association.expression.index)).span;
        begin
          if not Adac.Source.contains (value.span, expression_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (expression_span))
          then
            raise Program_Error with
              "Adac.AST: array aggregate value is out of source order";
          end if;
          previous_last := Adac.Source.last_position (expression_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: array aggregate span misses its closing delimiter";
      end if;
    end;
  end validate_array_aggregate;

  procedure validate_bracket_aggregate
    (self      : Store;
     aggregate : Node_ID)
  is
    value : Node renames self.nodes(Positive(aggregate.index));
    previous_last : Adac.Source.Position;
    first_child   : Boolean := True;
  begin
    validate_store (self);
    require_bracket_aggregate (self, aggregate);
    Adac.Source.validate (value.span);
    if value.bracket_aggregate_expressions_value.is_empty then
      raise Program_Error with
        "Adac.AST: bracket aggregate expression list is empty";
    end if;
    previous_last := Adac.Source.first_position (value.span);

    for expression of value.bracket_aggregate_expressions_value loop
      require_allocator (self, expression);
      if expression.index >= aggregate.index then
        raise Program_Error with
          "Adac.AST: bracket aggregate expression is not earlier";
      end if;
      validate_allocator (self, expression);
      declare
        child_span : constant Adac.Source.Span := node_span (self, expression);
      begin
        if not Adac.Source.contains (value.span, child_span) or else
           (if first_child then
              not precedes
                (Adac.Source.first_position (value.span),
                 Adac.Source.first_position (child_span))
            else
              not precedes
                (previous_last, Adac.Source.first_position (child_span)))
        then
          raise Program_Error with
            "Adac.AST: bracket aggregate expressions are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
        first_child := False;
      end;
    end loop;

    if not precedes (previous_last, Adac.Source.last_position (value.span)) then
      raise Program_Error with
        "Adac.AST: bracket aggregate span misses its closing delimiter";
    end if;
  end validate_bracket_aggregate;

  procedure validate_qualified_expression
    (self       : Store;
     expression : Node_ID)
  is
    subtype_span : Adac.Source.Span;
    operand_span : Adac.Source.Span;
  begin
    require_qualified_expression (self, expression);
    declare
      value : Node renames self.nodes(Positive(expression.index));
    begin
      Adac.Source.validate (value.span);
      require_simple_name
        (self, value.qualified_expression_subtype_mark_value);
      validate_node_id (self, value.qualified_expression_operand_value);
      declare
        operand_kind : constant Node_Kind :=
          self.nodes
            (Positive(value.qualified_expression_operand_value.index)).kind;
      begin
        if operand_kind /= Record_Aggregate_Node and then
           operand_kind /= Array_Aggregate_Node and then
           (not is_current_qualified_operand_kind (operand_kind))
        then
          raise Program_Error with
            "Adac.AST: qualified-expression operand is outside current subset";
        end if;
      end;
      if value.qualified_expression_subtype_mark_value.index >=
           value.qualified_expression_operand_value.index or else
         value.qualified_expression_operand_value.index >= expression.index
      then
        raise Program_Error with
          "Adac.AST: qualified-expression children are not earlier and ordered";
      end if;

      validate_name (self, value.qualified_expression_subtype_mark_value);
      if self.nodes
        (Positive(value.qualified_expression_operand_value.index)).kind =
          Record_Aggregate_Node
      then
        validate_record_aggregate
          (self, value.qualified_expression_operand_value);
      elsif self.nodes
        (Positive(value.qualified_expression_operand_value.index)).kind =
          Array_Aggregate_Node
      then
        validate_array_aggregate
          (self, value.qualified_expression_operand_value);
      else
        require_nonaggregate_simple_expression
          (self, value.qualified_expression_operand_value);
        validate_expression (self, value.qualified_expression_operand_value);
      end if;
      subtype_span :=
        node_span (self, value.qualified_expression_subtype_mark_value);
      operand_span :=
        node_span (self, value.qualified_expression_operand_value);
      if not Adac.Source.contains (value.span, subtype_span) or else
         not Adac.Source.contains (value.span, operand_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (subtype_span) or else
         not precedes
           (Adac.Source.last_position (subtype_span),
            Adac.Source.first_position (operand_span))
      then
        raise Program_Error with
          "Adac.AST: qualified-expression children are out of source order";
      end if;

      if self.nodes
        (Positive(value.qualified_expression_operand_value.index)).kind =
          Record_Aggregate_Node or else
         self.nodes
           (Positive(value.qualified_expression_operand_value.index)).kind =
             Array_Aggregate_Node
      then
        if Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (operand_span)
        then
          raise Program_Error with
            "Adac.AST: qualified aggregate does not end at its operand";
        end if;
      elsif not precedes
        (Adac.Source.last_position (operand_span),
         Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: qualified direct operand does not precede " &
          "its closing syntax";
      end if;
    end;
  end validate_qualified_expression;

  procedure validate_allocator
    (self      : Store;
     allocator : Node_ID)
  is
    value      : Node;
    child_span : Adac.Source.Span;
  begin
    validate_store (self);
    require_allocator (self, allocator);
    value := self.nodes(Positive(allocator.index));
    Adac.Source.validate (value.span);
    validate_new_span (value.allocator_new_span_value);
    require_qualified_expression (self, value.allocator_expression_value);

    if value.allocator_expression_value.index >= allocator.index then
      raise Program_Error with
        "Adac.AST: allocator child is not earlier";
    end if;

    validate_qualified_expression (self, value.allocator_expression_value);
    child_span := node_span (self, value.allocator_expression_value);
    if not Adac.Source.contains
      (value.span, value.allocator_new_span_value) or else
       not Adac.Source.contains (value.span, child_span) or else
       Adac.Source.first_position (value.span) /=
         Adac.Source.first_position (value.allocator_new_span_value) or else
       not precedes
         (Adac.Source.last_position (value.allocator_new_span_value),
          Adac.Source.first_position (child_span)) or else
       Adac.Source.last_position (value.span) /=
         Adac.Source.last_position (child_span)
    then
      raise Program_Error with
        "Adac.AST: allocator child is out of source order";
    end if;
  end validate_allocator;

  procedure validate_case_range_choice
    (self   : Store;
     choice : Node_ID)
  is
    lower_bound : Node_ID;
    upper_bound : Node_ID;
    lower_span  : Adac.Source.Span;
    upper_span  : Adac.Source.Span;
  begin
    require_case_range_choice (self, choice);
    declare
      value : Node renames self.nodes(Positive(choice.index));
    begin
      Adac.Source.validate (value.span);
      Adac.Source.validate (value.case_range_choice_range_span_value);
      lower_bound := value.case_range_choice_lower_bound_value;
      upper_bound := value.case_range_choice_upper_bound_value;
      validate_character_literal (self, lower_bound);
      validate_character_literal (self, upper_bound);
      if lower_bound.index >= upper_bound.index or else
         upper_bound.index >= choice.index
      then
        raise Program_Error with
          "Adac.AST: case range bounds are not earlier and ordered";
      end if;
      lower_span := node_span (self, lower_bound);
      upper_span := node_span (self, upper_bound);
      if not Adac.Source.contains (value.span, lower_span) or else
         not Adac.Source.contains
           (value.span, value.case_range_choice_range_span_value) or else
         not Adac.Source.contains (value.span, upper_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (lower_span) or else
         not precedes
           (Adac.Source.last_position (lower_span),
            Adac.Source.first_position
              (value.case_range_choice_range_span_value)) or else
         not precedes
           (Adac.Source.last_position
              (value.case_range_choice_range_span_value),
            Adac.Source.first_position (upper_span)) or else
         Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (upper_span)
      then
        raise Program_Error with
          "Adac.AST: case range spans are out of source order";
      end if;
    end;
  end validate_case_range_choice;

  procedure validate_membership_range_choice
    (self   : Store;
     choice : Node_ID)
  is
    lower_bound : Node_ID;
    upper_bound : Node_ID;
    lower_span  : Adac.Source.Span;
    upper_span  : Adac.Source.Span;
  begin
    require_membership_range_choice (self, choice);
    declare
      value : Node renames self.nodes(Positive(choice.index));
    begin
      Adac.Source.validate (value.span);
      Adac.Source.validate (value.membership_range_choice_range_span_value);
      lower_bound := value.membership_range_choice_lower_bound_value;
      upper_bound := value.membership_range_choice_upper_bound_value;
      require_current_simple_expression (self, lower_bound);
      require_current_simple_expression (self, upper_bound);
      if lower_bound.index >= upper_bound.index or else
         upper_bound.index >= choice.index
      then
        raise Program_Error with
          "Adac.AST: membership range bounds are not earlier and ordered";
      end if;
      validate_expression (self, lower_bound);
      validate_expression (self, upper_bound);
      lower_span := node_span (self, lower_bound);
      upper_span := node_span (self, upper_bound);
      if not Adac.Source.contains (value.span, lower_span) or else
         not Adac.Source.contains
           (value.span, value.membership_range_choice_range_span_value) or else
         not Adac.Source.contains (value.span, upper_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (lower_span) or else
         not precedes
           (Adac.Source.last_position (lower_span),
            Adac.Source.first_position
              (value.membership_range_choice_range_span_value)) or else
         not precedes
           (Adac.Source.last_position
              (value.membership_range_choice_range_span_value),
            Adac.Source.first_position (upper_span)) or else
         Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (upper_span)
      then
        raise Program_Error with
          "Adac.AST: membership range spans are out of source order";
      end if;
    end;
  end validate_membership_range_choice;

  procedure validate_logical_expression
    (self       : Store;
     expression : Node_ID)
  is
    current : Node_ID := expression;
  begin
    loop
      require_logical_expression (self, current);
      declare
        value : Node renames self.nodes(Positive(current.index));
        left_operand : constant Node_ID := value.logical_left_operand_value;
        right_operand : constant Node_ID := value.logical_right_operand_value;
        left_span  : Adac.Source.Span;
        right_span : Adac.Source.Span;
      begin
        require_current_expression (self, left_operand);
        require_current_expression (self, right_operand);
        if left_operand.index >= current.index or else
           right_operand.index >= current.index
        then
          raise Program_Error with
            "Adac.AST: logical operand is not earlier";
        end if;
        if self.nodes(Positive(right_operand.index)).kind =
           Logical_Expression_Node
        then
          raise Program_Error with
            "Adac.AST: logical right operand must not be a chain";
        end if;
        validate_expression (self, right_operand);
        Adac.Source.validate (value.logical_operator_span_value);
        Adac.Source.validate (value.span);
        left_span := node_span (self, left_operand);
        right_span := node_span (self, right_operand);
        if not Adac.Source.contains (value.span, left_span) or else
           not Adac.Source.contains
             (value.span, value.logical_operator_span_value) or else
           not Adac.Source.contains (value.span, right_span) or else
           Adac.Source.first_position (value.span) /=
             Adac.Source.first_position (left_span) or else
           not precedes
             (Adac.Source.last_position (left_span),
              Adac.Source.first_position
                (value.logical_operator_span_value)) or else
           not precedes
             (Adac.Source.last_position
                (value.logical_operator_span_value),
              Adac.Source.first_position (right_span)) or else
           Adac.Source.last_position (value.span) /=
             Adac.Source.last_position (right_span)
        then
          raise Program_Error with
            "Adac.AST: logical expression is out of source order";
        end if;

        if self.nodes(Positive(left_operand.index)).kind =
           Logical_Expression_Node
        then
          current := left_operand;
        else
          validate_expression (self, left_operand);
          exit;
        end if;
      end;
    end loop;
  end validate_logical_expression;

  procedure validate_short_circuit_expression
    (self       : Store;
     expression : Node_ID)
  is
    current : Node_ID := expression;
  begin
    loop
      require_short_circuit_expression (self, current);

      declare
        value : Node renames self.nodes(Positive(current.index));
        left_operand : constant Node_ID :=
          value.short_circuit_left_operand_value;
        right_operand : constant Node_ID :=
          value.short_circuit_right_operand_value;
        left_span  : Adac.Source.Span;
        right_span : Adac.Source.Span;
      begin
        require_current_expression (self, left_operand);
        require_current_expression (self, right_operand);
        if self.nodes(Positive(right_operand.index)).kind =
           Short_Circuit_Expression_Node
        then
          raise Program_Error with
            "Adac.AST: short-circuit right operand must not be a chain";
        end if;
        if left_operand.index >= current.index or else
           right_operand.index >= current.index
        then
          raise Program_Error with
            "Adac.AST: short-circuit operand is not earlier";
        end if;

        Adac.Source.validate (value.span);
        Adac.Source.validate
          (value.short_circuit_operator_first_span_value);
        Adac.Source.validate
          (value.short_circuit_operator_second_span_value);
        validate_expression (self, right_operand);

        left_span := node_span (self, left_operand);
        right_span := node_span (self, right_operand);
        if not Adac.Source.contains (value.span, left_span) or else
           not Adac.Source.contains
             (value.span, value.short_circuit_operator_first_span_value) or else
           not Adac.Source.contains
             (value.span,
              value.short_circuit_operator_second_span_value) or else
           not Adac.Source.contains (value.span, right_span) or else
           Adac.Source.first_position (value.span) /=
             Adac.Source.first_position (left_span) or else
           not precedes
             (Adac.Source.last_position (left_span),
              Adac.Source.first_position
                (value.short_circuit_operator_first_span_value)) or else
           not precedes
             (Adac.Source.last_position
                (value.short_circuit_operator_first_span_value),
              Adac.Source.first_position
                (value.short_circuit_operator_second_span_value)) or else
           not precedes
             (Adac.Source.last_position
                (value.short_circuit_operator_second_span_value),
              Adac.Source.first_position (right_span)) or else
           Adac.Source.last_position (value.span) /=
             Adac.Source.last_position (right_span)
        then
          raise Program_Error with
            "Adac.AST: short-circuit expression is out of source order";
        end if;

        if self.nodes(Positive(left_operand.index)).kind =
           Short_Circuit_Expression_Node
        then
          current := left_operand;
        else
          validate_expression (self, left_operand);
          exit;
        end if;
      end;
    end loop;
  end validate_short_circuit_expression;

  procedure validate_expression
    (self       : Store;
     expression : Node_ID)
  is
    pending    : Node_List;
    next_index : Natural := 1;

    procedure validate_one_expression (current_expression : Node_ID);
    procedure validate_simple_expression (node : Node_ID);
    procedure validate_if_expression_node (expression_node : Node_ID);
    procedure validate_parenthesized_expression_node
      (expression_node : Node_ID);
    procedure validate_slice_expression_node (slice : Node_ID);

    procedure validate_slice_expression_node (slice : Node_ID) is
      value       : Node renames self.nodes(Positive(slice.index));
      prefix_span : Adac.Source.Span;
      lower_span  : Adac.Source.Span;
      upper_span  : Adac.Source.Span;
    begin
      require_slice_name (self, slice);
      Adac.Source.validate (value.span);
      validate_double_dot_span (value.slice_range_span_value);
      require_current_name (self, value.slice_prefix_value);
      if not is_current_slice_prefix_kind
        (self.nodes(Positive(value.slice_prefix_value.index)).kind)
      then
        raise Program_Error with
          "Adac.AST: slice prefix has the wrong kind";
      end if;
      require_current_simple_expression
        (self, value.slice_lower_bound_value);
      require_current_simple_expression
        (self, value.slice_upper_bound_value);

      if value.slice_prefix_value.index >=
           value.slice_lower_bound_value.index or else
         value.slice_lower_bound_value.index >=
           value.slice_upper_bound_value.index or else
         value.slice_upper_bound_value.index >= slice.index
      then
        raise Program_Error with "Adac.AST: slice children are not earlier";
      end if;

      validate_name (self, value.slice_prefix_value);
      prefix_span := node_span (self, value.slice_prefix_value);
      lower_span := node_span (self, value.slice_lower_bound_value);
      upper_span := node_span (self, value.slice_upper_bound_value);

      if not Adac.Source.contains (value.span, prefix_span) or else
         not Adac.Source.contains (value.span, lower_span) or else
         not Adac.Source.contains
           (value.span, value.slice_range_span_value) or else
         not Adac.Source.contains (value.span, upper_span) or else
         Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (prefix_span) or else
         not precedes
           (Adac.Source.last_position (prefix_span),
            Adac.Source.first_position (lower_span)) or else
         not precedes
           (Adac.Source.last_position (lower_span),
            Adac.Source.first_position (value.slice_range_span_value)) or else
         not precedes
           (Adac.Source.last_position (value.slice_range_span_value),
            Adac.Source.first_position (upper_span)) or else
         not precedes
           (Adac.Source.last_position (upper_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: slice spans are out of source order";
      end if;

      append (pending, value.slice_lower_bound_value);
      append (pending, value.slice_upper_bound_value);
    end validate_slice_expression_node;

    procedure validate_direct_expression (node : Node_ID) is
    begin
      validate_node_id (self, node);

      case self.nodes(Positive(node.index)).kind is
        when Numeric_Literal_Node =>
          validate_numeric_literal (self, node);

        when Character_Literal_Node =>
          validate_character_literal (self, node);

        when String_Literal_Node =>
          validate_string_literal (self, node);

        when Null_Literal_Node =>
          validate_null_literal (self, node);

        when Record_Aggregate_Node =>
          validate_record_aggregate (self, node);

        when Array_Aggregate_Node =>
          validate_array_aggregate (self, node);

        when Bracket_Aggregate_Node =>
          validate_bracket_aggregate (self, node);

        when Qualified_Expression_Node =>
          validate_qualified_expression (self, node);

        when Allocator_Node =>
          validate_allocator (self, node);

        when Identifier_Name_Node |
             Selected_Name_Node |
             Explicit_Dereference_Name_Node |
             Selected_Component_Node |
             Parenthesized_Name_Node |
             Attribute_Name_Node =>
          validate_name (self, node);

        when Slice_Name_Node =>
          validate_slice_expression_node (node);

        when Parenthesized_Expression_Node =>
          validate_parenthesized_expression_node (node);

        when others =>
          raise Program_Error with
            "Adac.AST: node is not a current direct expression";
      end case;
    end validate_direct_expression;

    procedure validate_factor_expression (node : Node_ID) is
    begin
      validate_node_id (self, node);
      if self.nodes(Positive(node.index)).kind = Unary_Operator_Node or else
         self.nodes(Positive(node.index)).kind = Binary_Exponentiating_Node
      then
        append (pending, node);
      else
        validate_direct_expression (node);
      end if;
    end validate_factor_expression;

    procedure validate_binary_multiplying_chain (root : Node_ID) is
      current : Node_ID := root;
    begin
      loop
        require_binary_multiplying (self, current);
        declare
          value : Node renames self.nodes(Positive(current.index));
          left_span  : Adac.Source.Span;
          right_span : Adac.Source.Span;
        begin
          Adac.Source.validate (value.span);
          validate_binary_multiplying_operator_shape
            (Ada.Strings.Unbounded.to_string
               (value.binary_multiplying_operator_spelling_value),
             value.binary_multiplying_operator_span_value);
          require_current_term_expression
            (self, value.binary_multiplying_left_operand_value);
          require_current_factor_expression
            (self, value.binary_multiplying_right_operand_value);

          if value.binary_multiplying_left_operand_value.index >=
               current.index or else
             value.binary_multiplying_right_operand_value.index >= current.index
          then
            raise Program_Error with
              "Adac.AST: binary-multiplying operand is not earlier";
          end if;

          validate_factor_expression
            (value.binary_multiplying_right_operand_value);
          left_span := node_span
            (self, value.binary_multiplying_left_operand_value);
          right_span := node_span
            (self, value.binary_multiplying_right_operand_value);

          if not Adac.Source.contains (value.span, left_span) or else
             not Adac.Source.contains
               (value.span,
                value.binary_multiplying_operator_span_value) or else
             not Adac.Source.contains (value.span, right_span)
          then
            raise Program_Error with
              "Adac.AST: binary-multiplying child span is outside expression";
          end if;

          if Adac.Source.first_position (value.span) /=
               Adac.Source.first_position (left_span) or else
             not precedes
               (Adac.Source.last_position (left_span),
                Adac.Source.first_position
                  (value.binary_multiplying_operator_span_value)) or else
             not precedes
               (Adac.Source.last_position
                  (value.binary_multiplying_operator_span_value),
                Adac.Source.first_position (right_span)) or else
             Adac.Source.last_position (value.span) /=
               Adac.Source.last_position (right_span)
          then
            raise Program_Error with
              "Adac.AST: binary-multiplying spans are out of source order";
          end if;

          if self.nodes
            (Positive(value.binary_multiplying_left_operand_value.index)).kind =
              Binary_Multiplying_Node
          then
            current := value.binary_multiplying_left_operand_value;
          else
            validate_factor_expression
              (value.binary_multiplying_left_operand_value);
            exit;
          end if;
        end;
      end loop;
    end validate_binary_multiplying_chain;

    procedure validate_term_expression (node : Node_ID) is
    begin
      validate_node_id (self, node);
      if self.nodes(Positive(node.index)).kind = Binary_Multiplying_Node then
        validate_binary_multiplying_chain (node);
      else
        validate_factor_expression (node);
      end if;
    end validate_term_expression;

    procedure validate_binary_adding_chain (root : Node_ID) is
      current : Node_ID := root;
    begin
      loop
        require_binary_adding (self, current);

        declare
          value : Node renames self.nodes(Positive(current.index));
          left_span : Adac.Source.Span;
          right_span : Adac.Source.Span;
        begin
          Adac.Source.validate (value.span);
          validate_binary_adding_operator_shape
            (Ada.Strings.Unbounded.to_string
               (value.binary_adding_operator_spelling_value),
             value.binary_adding_operator_span_value);
          require_current_simple_expression
            (self, value.binary_adding_left_operand_value);
          require_current_term_expression
            (self, value.binary_adding_right_operand_value);

          if value.binary_adding_left_operand_value.index >=
               current.index or else
             value.binary_adding_right_operand_value.index >= current.index
          then
            raise Program_Error with
              "Adac.AST: binary-adding operand is not earlier";
          end if;

          validate_term_expression (value.binary_adding_right_operand_value);
          left_span := node_span
            (self, value.binary_adding_left_operand_value);
          right_span := node_span
            (self, value.binary_adding_right_operand_value);

          if not Adac.Source.contains (value.span, left_span) or else
             not Adac.Source.contains
               (value.span, value.binary_adding_operator_span_value) or else
             not Adac.Source.contains (value.span, right_span)
          then
            raise Program_Error with
              "Adac.AST: binary-adding child span is outside expression";
          end if;

          if Adac.Source.first_position (value.span) /=
               Adac.Source.first_position (left_span) or else
             not precedes
               (Adac.Source.last_position (left_span),
                Adac.Source.first_position
                  (value.binary_adding_operator_span_value)) or else
             not precedes
               (Adac.Source.last_position
                  (value.binary_adding_operator_span_value),
                Adac.Source.first_position (right_span)) or else
             Adac.Source.last_position (value.span) /=
               Adac.Source.last_position (right_span)
          then
            raise Program_Error with
              "Adac.AST: binary-adding spans are out of source order";
          end if;

          if self.nodes
            (Positive(value.binary_adding_left_operand_value.index)).kind =
              Binary_Adding_Node
          then
            current := value.binary_adding_left_operand_value;
          else
            validate_term_expression (value.binary_adding_left_operand_value);
            exit;
          end if;
        end;
      end loop;
    end validate_binary_adding_chain;

    procedure validate_simple_expression (node : Node_ID) is
    begin
      validate_node_id (self, node);
      if self.nodes(Positive(node.index)).kind = Binary_Adding_Node then
        validate_binary_adding_chain (node);
      else
        validate_term_expression (node);
      end if;
    end validate_simple_expression;

    procedure validate_if_expression_node (expression_node : Node_ID) is
      value : Node renames self.nodes(Positive(expression_node.index));
      cond_span : Adac.Source.Span;
      then_span : Adac.Source.Span;
      else_span : Adac.Source.Span;
    begin
      require_if_expression (self, expression_node);
      Adac.Source.validate (value.span);
      require_current_if_expression_condition
        (self, value.if_expression_condition_value);
      require_current_conditional_expression_child
        (self, value.if_expression_then_value);
      require_current_conditional_expression_child
        (self, value.if_expression_else_value);

      if value.if_expression_condition_value.index >=
           expression_node.index or else
         value.if_expression_then_value.index >= expression_node.index or else
         value.if_expression_else_value.index >= expression_node.index
      then
        raise Program_Error with
          "Adac.AST: if-expression child is not earlier";
      end if;

      if self.nodes
           (Positive(value.if_expression_condition_value.index)).kind in
           Relation_Node |
           Logical_Expression_Node |
           Short_Circuit_Expression_Node
      then
        validate_one_expression (value.if_expression_condition_value);
      else
        validate_simple_expression (value.if_expression_condition_value);
      end if;
      validate_simple_expression (value.if_expression_then_value);
      validate_simple_expression (value.if_expression_else_value);
      cond_span := node_span (self, value.if_expression_condition_value);
      then_span := node_span (self, value.if_expression_then_value);
      else_span := node_span (self, value.if_expression_else_value);

      if not Adac.Source.contains (value.span, cond_span) or else
         not Adac.Source.contains (value.span, then_span) or else
         not Adac.Source.contains (value.span, else_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (cond_span)) or else
         not precedes
           (Adac.Source.last_position (cond_span),
            Adac.Source.first_position (then_span)) or else
         not precedes
           (Adac.Source.last_position (then_span),
            Adac.Source.first_position (else_span)) or else
         Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (else_span)
      then
        raise Program_Error with
          "Adac.AST: if-expression spans are out of source order";
      end if;
    end validate_if_expression_node;

    procedure validate_raise_expression_node
      (expression_node : Node_ID)
    is
      value : Node renames self.nodes(Positive(expression_node.index));
      exception_span : Adac.Source.Span;
    begin
      require_raise_expression (self, expression_node);
      Adac.Source.validate (value.span);
      require_simple_name (self, value.raise_expression_exception_name_value);
      if value.raise_expression_exception_name_value.index >=
           expression_node.index
      then
        raise Program_Error with
          "Adac.AST: raise-expression exception name is not earlier";
      end if;
      Structural_Validation.validate_name
        (self, value.raise_expression_exception_name_value);
      exception_span :=
        node_span (self, value.raise_expression_exception_name_value);
      if not Adac.Source.contains (value.span, exception_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (exception_span))
      then
        raise Program_Error with
          "Adac.AST: raise-expression exception name is out of source order";
      end if;

      if value.raise_expression_message_value = INVALID_NODE_ID then
        if Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (exception_span)
        then
          raise Program_Error with
            "Adac.AST: raise-expression span does not end at exception name";
        end if;
        return;
      end if;

      require_current_conditional_expression_child
        (self, value.raise_expression_message_value);
      if value.raise_expression_message_value.index >=
           expression_node.index or else
         value.raise_expression_exception_name_value.index >=
           value.raise_expression_message_value.index
      then
        raise Program_Error with
          "Adac.AST: raise-expression message is not an ordered earlier child";
      end if;
      validate_simple_expression (value.raise_expression_message_value);
      declare
        message_span : constant Adac.Source.Span :=
          node_span (self, value.raise_expression_message_value);
      begin
        if not Adac.Source.contains (value.span, message_span) or else
           not precedes
             (Adac.Source.last_position (exception_span),
              Adac.Source.first_position (message_span)) or else
           Adac.Source.last_position (value.span) /=
             Adac.Source.last_position (message_span)
        then
          raise Program_Error with
            "Adac.AST: raise-expression message is out of source order";
        end if;
      end;
    end validate_raise_expression_node;

    procedure validate_case_expression_alternative_node
      (alternative : Node_ID)
    is
      value : Node renames self.nodes(Positive(alternative.index));
      dependent : constant Node_ID :=
        value.case_expression_alternative_expression_value;
      previous_last : Adac.Source.Position;
      dependent_span : Adac.Source.Span;
    begin
      require_case_expression_alternative (self, alternative);
      Adac.Source.validate (value.span);
      if value.case_expression_alternative_choices_value.is_empty then
        raise Program_Error with
          "Adac.AST: case-expression alternative choice list is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for choice of value.case_expression_alternative_choices_value loop
        require_current_case_expression_choice (self, choice);
        if choice.index >= alternative.index then
          raise Program_Error with
            "Adac.AST: case-expression choice is not earlier";
        end if;
        case self.nodes(Positive(choice.index)).kind is
          when Identifier_Name_Node | Selected_Name_Node =>
            Structural_Validation.validate_name (self, choice);
          when Others_Case_Choice_Node =>
            Adac.Source.validate (self.nodes(Positive(choice.index)).span);
          when others =>
            raise Program_Error with
              "Adac.AST: invalid case-expression choice";
        end case;
        declare
          choice_span : constant Adac.Source.Span := node_span (self, choice);
        begin
          if not Adac.Source.contains (value.span, choice_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (choice_span))
          then
            raise Program_Error with
              "Adac.AST: case-expression choices are out of source order";
          end if;
          previous_last := Adac.Source.last_position (choice_span);
        end;
      end loop;

      validate_node_id
        (self, dependent);
      if self.nodes
        (Positive(dependent.index)).kind =
          Raise_Expression_Node
      then
        require_raise_expression
          (self, dependent);
      else
        require_current_conditional_expression_child
          (self, dependent);
      end if;
      if dependent.index >=
           alternative.index
      then
        raise Program_Error with
          "Adac.AST: case-expression dependent expression is not earlier";
      end if;
      if self.nodes
        (Positive(dependent.index)).kind =
          Raise_Expression_Node
      then
        validate_raise_expression_node
          (dependent);
      else
        validate_simple_expression
          (dependent);
      end if;
      dependent_span :=
        node_span (self, value.case_expression_alternative_expression_value);
      if not Adac.Source.contains (value.span, dependent_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (dependent_span)) or else
         Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (dependent_span)
      then
        raise Program_Error with
          "Adac.AST: case-expression dependent expression is out of " &
          "source order";
      end if;
    end validate_case_expression_alternative_node;

    procedure validate_case_expression_node (expression_node : Node_ID) is
      value : Node renames self.nodes(Positive(expression_node.index));
      selecting_span : Adac.Source.Span;
      previous_last : Adac.Source.Position;
    begin
      require_case_expression (self, expression_node);
      Adac.Source.validate (value.span);
      require_current_conditional_expression_child
        (self, value.case_expression_selecting_expression_value);
      if value.case_expression_selecting_expression_value.index >=
           expression_node.index
      then
        raise Program_Error with
          "Adac.AST: case-expression selector is not earlier";
      end if;
      validate_simple_expression
        (value.case_expression_selecting_expression_value);
      if value.case_expression_alternatives_value.is_empty then
        raise Program_Error with
          "Adac.AST: case-expression alternative list is empty";
      end if;

      selecting_span :=
        node_span (self, value.case_expression_selecting_expression_value);
      if not Adac.Source.contains (value.span, selecting_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (selecting_span))
      then
        raise Program_Error with
          "Adac.AST: case-expression selector is outside expression";
      end if;
      previous_last := Adac.Source.last_position (selecting_span);

      for alternative of value.case_expression_alternatives_value loop
        require_case_expression_alternative (self, alternative);
        if alternative.index >= expression_node.index then
          raise Program_Error with
            "Adac.AST: case-expression alternative is not earlier";
        end if;
        validate_case_expression_alternative_node (alternative);
        declare
          alternative_span : constant Adac.Source.Span :=
            node_span (self, alternative);
        begin
          if not Adac.Source.contains (value.span, alternative_span) or else
             not precedes
               (previous_last,
                Adac.Source.first_position (alternative_span))
          then
            raise Program_Error with
              "Adac.AST: case-expression alternatives are out of source order";
          end if;
          previous_last := Adac.Source.last_position (alternative_span);
        end;
      end loop;

      if previous_last /= Adac.Source.last_position (value.span) then
        raise Program_Error with
          "Adac.AST: case-expression span does not end at final alternative";
      end if;
    end validate_case_expression_node;

    procedure validate_parenthesized_expression_node
      (expression_node : Node_ID)
    is
      value : Node renames self.nodes(Positive(expression_node.index));
      child_span : Adac.Source.Span;
    begin
      require_parenthesized_expression (self, expression_node);
      Adac.Source.validate (value.span);
      validate_node_id (self, value.parenthesized_expression_child_value);
      if self.nodes
        (Positive(value.parenthesized_expression_child_value.index)).kind /=
          If_Expression_Node and then
         self.nodes
           (Positive(value.parenthesized_expression_child_value.index)).kind /=
             Case_Expression_Node
      then
        require_current_expression
          (self, value.parenthesized_expression_child_value);
      end if;

      if value.parenthesized_expression_child_value.index >=
           expression_node.index
      then
        raise Program_Error with
          "Adac.AST: parenthesized-expression child is not earlier";
      end if;

      append (pending, value.parenthesized_expression_child_value);
      child_span := node_span
        (self, value.parenthesized_expression_child_value);

      if not Adac.Source.contains (value.span, child_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (child_span)) or else
         not precedes
           (Adac.Source.last_position (child_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: parenthesized-expression span does not bracket its child";
      end if;
    end validate_parenthesized_expression_node;

    procedure validate_one_expression (current_expression : Node_ID) is
    begin
      validate_node_id (self, current_expression);
    case self.nodes(Positive(current_expression.index)).kind is
      when Numeric_Literal_Node |
           Character_Literal_Node |
           String_Literal_Node |
           Null_Literal_Node |
           Record_Aggregate_Node |
           Bracket_Aggregate_Node |
           Qualified_Expression_Node |
           Allocator_Node |
           Parenthesized_Expression_Node |
           Identifier_Name_Node |
           Selected_Name_Node |
           Explicit_Dereference_Name_Node |
           Selected_Component_Node |
           Parenthesized_Name_Node |
           Slice_Name_Node |
           Attribute_Name_Node =>
        validate_direct_expression (current_expression);

      when If_Expression_Node =>
        validate_if_expression_node (current_expression);

      when Raise_Expression_Node =>
        validate_raise_expression_node (current_expression);

      when Case_Expression_Node =>
        validate_case_expression_node (current_expression);

      when Unary_Operator_Node =>
        declare
          value : Node renames
            self.nodes(Positive(current_expression.index));
          operator_spelling : constant String :=
            Ada.Strings.Unbounded.to_string
              (value.unary_operator_spelling_value);
          operand_span : Adac.Source.Span;
        begin
          Adac.Source.validate (value.span);
          validate_unary_operator_shape
            (operator_spelling, value.unary_operator_span_value);
          if operator_spelling = "+" or else operator_spelling = "-" then
            require_current_term_expression (self, value.unary_operand_value);
          else
            require_current_direct_expression (self, value.unary_operand_value);
          end if;

          if value.unary_operand_value.index >= current_expression.index then
            raise Program_Error with
              "Adac.AST: unary operator operand is not earlier";
          end if;

          if operator_spelling = "+" or else operator_spelling = "-" then
            validate_term_expression (value.unary_operand_value);
          else
            validate_direct_expression (value.unary_operand_value);
          end if;
          operand_span := node_span (self, value.unary_operand_value);

          if not Adac.Source.contains
               (value.span, value.unary_operator_span_value) or else
             not Adac.Source.contains (value.span, operand_span) or else
             Adac.Source.first_position (value.span) /=
               Adac.Source.first_position
                 (value.unary_operator_span_value) or else
             not precedes
               (Adac.Source.last_position (value.unary_operator_span_value),
                Adac.Source.first_position (operand_span)) or else
             Adac.Source.last_position (value.span) /=
               Adac.Source.last_position (operand_span)
          then
            raise Program_Error with
              "Adac.AST: unary operator spans are out of source order";
          end if;
        end;

      when Binary_Exponentiating_Node =>
        declare
          value : Node renames
            self.nodes(Positive(current_expression.index));
          left_span  : Adac.Source.Span;
          right_span : Adac.Source.Span;
        begin
          Adac.Source.validate (value.span);
          validate_binary_exponentiating_operator_shape
            (Ada.Strings.Unbounded.to_string
               (value.binary_exponentiating_operator_spelling_value),
             value.binary_exponentiating_operator_span_value);
          require_current_direct_expression
            (self, value.binary_exponentiating_left_operand_value);
          require_current_direct_expression
            (self, value.binary_exponentiating_right_operand_value);

          if value.binary_exponentiating_left_operand_value.index >=
               current_expression.index or else
             value.binary_exponentiating_right_operand_value.index >=
               current_expression.index
          then
            raise Program_Error with
              "Adac.AST: binary-exponentiating operand is not earlier";
          end if;

          validate_direct_expression
            (value.binary_exponentiating_left_operand_value);
          validate_direct_expression
            (value.binary_exponentiating_right_operand_value);
          left_span := node_span
            (self, value.binary_exponentiating_left_operand_value);
          right_span := node_span
            (self, value.binary_exponentiating_right_operand_value);

          if not Adac.Source.contains (value.span, left_span) or else
             not Adac.Source.contains
               (value.span,
                value.binary_exponentiating_operator_span_value) or else
             not Adac.Source.contains (value.span, right_span) or else
             Adac.Source.first_position (value.span) /=
               Adac.Source.first_position (left_span) or else
             not precedes
               (Adac.Source.last_position (left_span),
                Adac.Source.first_position
                  (value.binary_exponentiating_operator_span_value)) or else
             not precedes
               (Adac.Source.last_position
                  (value.binary_exponentiating_operator_span_value),
                Adac.Source.first_position (right_span)) or else
             Adac.Source.last_position (value.span) /=
               Adac.Source.last_position (right_span)
          then
            raise Program_Error with
              "Adac.AST: binary-exponentiating spans are out of source order";
          end if;
        end;

      when Binary_Multiplying_Node =>
        validate_binary_multiplying_chain (current_expression);

      when Binary_Adding_Node =>
        validate_binary_adding_chain (current_expression);

      when Membership_Expression_Node =>
        declare
          value : Node renames
            self.nodes(Positive(current_expression.index));
          tested_span   : Adac.Source.Span;
          previous_span : Adac.Source.Span;
        begin
          Adac.Source.validate (value.span);
          require_current_simple_expression
            (self, value.membership_tested_expression_value);
          if value.membership_tested_expression_value.index >=
             current_expression.index
          then
            raise Program_Error with
              "Adac.AST: membership tested expression is not earlier";
          end if;
          if value.membership_choices_value.is_empty then
            raise Program_Error with
              "Adac.AST: membership choice list is empty";
          end if;

          tested_span :=
            node_span (self, value.membership_tested_expression_value);
          Adac.Source.validate (value.membership_in_span_value);
          case value.membership_operator_value is
            when In_Membership_Operator =>
              if value.membership_not_span_value /=
                 Adac.Source.INVALID_SPAN
              then
                raise Program_Error with
                  "Adac.AST: in membership has a not token span";
              end if;
              if not precedes
                (Adac.Source.last_position (tested_span),
                 Adac.Source.first_position (value.membership_in_span_value))
              then
                raise Program_Error with
                  "Adac.AST: membership operator is out of source order";
              end if;

            when Not_In_Membership_Operator =>
              Adac.Source.validate (value.membership_not_span_value);
              if not precedes
                (Adac.Source.last_position (tested_span),
                 Adac.Source.first_position
                   (value.membership_not_span_value)) or else
                 not precedes
                   (Adac.Source.last_position
                      (value.membership_not_span_value),
                    Adac.Source.first_position (value.membership_in_span_value))
              then
                raise Program_Error with
                  "Adac.AST: membership operator is out of source order";
              end if;
          end case;

          if not Adac.Source.contains (value.span, tested_span) or else
             not Adac.Source.contains
               (value.span, value.membership_in_span_value) or else
             (value.membership_operator_value =
                Not_In_Membership_Operator and then
              not Adac.Source.contains
                (value.span, value.membership_not_span_value)) or else
             Adac.Source.first_position (value.span) /=
               Adac.Source.first_position (tested_span)
          then
            raise Program_Error with
              "Adac.AST: membership source span is inconsistent";
          end if;

          validate_simple_expression
            (value.membership_tested_expression_value);
          previous_span := value.membership_in_span_value;
          for choice of value.membership_choices_value loop
            validate_node_id (self, choice);
            if choice.index >= current_expression.index then
              raise Program_Error with
                "Adac.AST: membership choice is not earlier";
            end if;
            if self.nodes(Positive(choice.index)).kind =
               Membership_Range_Choice_Node
            then
              validate_membership_range_choice (self, choice);
            else
              require_current_simple_expression (self, choice);
            end if;
            declare
              choice_span : constant Adac.Source.Span :=
                node_span (self, choice);
            begin
              if not Adac.Source.contains (value.span, choice_span) or else
                 not precedes
                   (Adac.Source.last_position (previous_span),
                    Adac.Source.first_position (choice_span))
              then
                raise Program_Error with
                  "Adac.AST: membership choices are out of source order";
              end if;
              previous_span := choice_span;
            end;
            if self.nodes(Positive(choice.index)).kind /=
               Membership_Range_Choice_Node
            then
              validate_simple_expression (choice);
            end if;
          end loop;

          if Adac.Source.last_position (value.span) /=
             Adac.Source.last_position (previous_span)
          then
            raise Program_Error with
              "Adac.AST: membership span does not end at its last choice";
          end if;
        end;

      when Logical_Expression_Node =>
        validate_logical_expression (self, current_expression);

      when Short_Circuit_Expression_Node =>
        validate_short_circuit_expression (self, current_expression);

      when Relation_Node =>
        declare
          value : Node renames
            self.nodes(Positive(current_expression.index));
          left_span  : Adac.Source.Span;
          right_span : Adac.Source.Span;
        begin
          Adac.Source.validate (value.span);
          validate_relation_operator_shape
            (Ada.Strings.Unbounded.to_string
               (value.relation_operator_spelling_value),
             value.relation_operator_span_value);
          require_current_simple_expression
            (self, value.relation_left_operand_value);
          require_current_simple_expression
            (self, value.relation_right_operand_value);

          if value.relation_left_operand_value.index >=
               current_expression.index or else
             value.relation_right_operand_value.index >=
               current_expression.index
          then
            raise Program_Error with
              "Adac.AST: relation operand is not earlier";
          end if;

          validate_simple_expression (value.relation_left_operand_value);
          validate_simple_expression (value.relation_right_operand_value);
          left_span := node_span (self, value.relation_left_operand_value);
          right_span := node_span (self, value.relation_right_operand_value);

          if not Adac.Source.contains (value.span, left_span) or else
             not Adac.Source.contains
               (value.span, value.relation_operator_span_value) or else
             not Adac.Source.contains (value.span, right_span)
          then
            raise Program_Error with
              "Adac.AST: relation child span is outside relation";
          end if;

          if Adac.Source.first_position (value.span) /=
               Adac.Source.first_position (left_span) or else
             not precedes
               (Adac.Source.last_position (left_span),
                Adac.Source.first_position
                  (value.relation_operator_span_value)) or else
             not precedes
               (Adac.Source.last_position
                  (value.relation_operator_span_value),
                Adac.Source.first_position (right_span)) or else
             Adac.Source.last_position (value.span) /=
               Adac.Source.last_position (right_span)
          then
            raise Program_Error with
              "Adac.AST: relation spans are out of source order";
          end if;
        end;

      when others =>
        raise Program_Error with
          "Adac.AST: node is not a current represented expression";
    end case;
    end validate_one_expression;

  begin
    validate_node_id (self, expression);
    append (pending, expression);

    while next_index <= list_count (pending) loop
      validate_one_expression
        (list_element (pending, Positive(next_index)));
      next_index := next_index + 1;
    end loop;
  end validate_expression;

  procedure validate_name
    (self : Store;
     name : Node_ID)
  is
    pending    : Node_List;
    next_index : Natural := 1;
  begin
    validate_node_id (self, name);
    append (pending, name);

    while next_index <= list_count (pending) loop
      declare
        current : constant Node_ID :=
          list_element (pending, Positive(next_index));
      begin
        next_index := next_index + 1;
        validate_node_id (self, current);

        case self.nodes(Positive(current.index)).kind is
          when Identifier_Name_Node | Selected_Name_Node =>
            validate_simple_name (self, current);

          when Explicit_Dereference_Name_Node =>
            declare
              value : Node renames self.nodes(Positive(current.index));
              prefix_span : Adac.Source.Span;
            begin
              Adac.Source.validate (value.span);
              validate_all_span (value.explicit_dereference_all_span_value);
              require_current_name
                (self, value.explicit_dereference_prefix_value);

              if value.explicit_dereference_prefix_value.index >= current.index
              then
                raise Program_Error with
                  "Adac.AST: explicit-dereference prefix is not earlier";
              end if;

              prefix_span :=
                node_span (self, value.explicit_dereference_prefix_value);
              if not Adac.Source.contains (value.span, prefix_span) or else
                 not Adac.Source.contains
                   (value.span,
                    value.explicit_dereference_all_span_value) or else
                 Adac.Source.first_position (value.span) /=
                   Adac.Source.first_position (prefix_span) or else
                 not precedes
                   (Adac.Source.last_position (prefix_span),
                    Adac.Source.first_position
                      (value.explicit_dereference_all_span_value)) or else
                 Adac.Source.last_position (value.span) /=
                   Adac.Source.last_position
                     (value.explicit_dereference_all_span_value)
              then
                raise Program_Error with
                  "Adac.AST: explicit-dereference spans are out of " &
                  "source order";
              end if;

              append (pending, value.explicit_dereference_prefix_value);
            end;

          when Selected_Component_Node =>
            declare
              value       : Node renames self.nodes(Positive(current.index));
              prefix_span : Adac.Source.Span;
            begin
              Adac.Source.validate (value.span);
              Adac.Symbols.validate (value.selected_symbol);
              Adac.Source.validate (value.selected_span);
              require_current_name (self, value.selected_prefix);

              if self.nodes(Positive(value.selected_prefix.index)).kind /=
                   Parenthesized_Name_Node and then
                 self.nodes(Positive(value.selected_prefix.index)).kind /=
                   Explicit_Dereference_Name_Node and then
                 self.nodes(Positive(value.selected_prefix.index)).kind /=
                   Selected_Component_Node
              then
                raise Program_Error with
                  "Adac.AST: selected-component prefix has the wrong kind";
              end if;
              if value.selected_prefix.index >= current.index then
                raise Program_Error with
                  "Adac.AST: selected-component prefix is not earlier";
              end if;

              prefix_span := node_span (self, value.selected_prefix);
              if not Adac.Source.contains (value.span, prefix_span) or else
                 not Adac.Source.contains
                   (value.span, value.selected_span) or else
                 Adac.Source.first_position (value.span) /=
                   Adac.Source.first_position (prefix_span) or else
                 not precedes
                   (Adac.Source.last_position (prefix_span),
                    Adac.Source.first_position (value.selected_span)) or else
                 Adac.Source.last_position (value.span) /=
                   Adac.Source.last_position (value.selected_span)
              then
                raise Program_Error with
                  "Adac.AST: selected-component span does not match components";
              end if;

              append (pending, value.selected_prefix);
            end;

          when Slice_Name_Node =>
            validate_expression (self, current);

          when Attribute_Name_Node =>
            declare
              value : Node renames self.nodes(Positive(current.index));
              prefix_span : Adac.Source.Span;
            begin
              Adac.Source.validate (value.span);
              Adac.Symbols.validate (value.attribute_symbol_value);
              Adac.Source.validate (value.attribute_span_value);
              require_current_name (self, value.attribute_prefix);

              if value.attribute_prefix.index >= current.index then
                raise Program_Error with
                  "Adac.AST: attribute-name prefix is not earlier";
              end if;

              prefix_span := node_span (self, value.attribute_prefix);

              if not Adac.Source.contains (value.span, prefix_span) or else
                 not Adac.Source.contains
                   (value.span, value.attribute_span_value)
              then
                raise Program_Error with
                  "Adac.AST: attribute-name child span is outside name";
              end if;

              if Adac.Source.first_position (value.span) /=
                   Adac.Source.first_position (prefix_span) or else
                 not precedes
                   (Adac.Source.last_position (prefix_span),
                    Adac.Source.first_position
                      (value.attribute_span_value)) or else
                 Adac.Source.last_position (value.span) /=
                   Adac.Source.last_position (value.attribute_span_value)
              then
                raise Program_Error with
                  "Adac.AST: attribute-name spans are out of source order";
              end if;

              append (pending, value.attribute_prefix);
            end;

          when Parenthesized_Name_Node =>
            declare
              value : Node renames self.nodes(Positive(current.index));
              previous_last  : Adac.Source.Position;
              saw_named_item : Boolean := False;
            begin
              Adac.Source.validate (value.span);
              require_current_name (self, value.parenthesized_prefix);
              if not is_current_parenthesized_prefix_kind
                (self.nodes(Positive(value.parenthesized_prefix.index)).kind)
              then
                raise Program_Error with
                  "Adac.AST: parenthesized-name prefix has the wrong kind";
              end if;

              if value.parenthesized_prefix.index >= current.index then
                raise Program_Error with
                  "Adac.AST: parenthesized-name prefix is not earlier";
              end if;

              if value.parenthesized_items.is_empty then
                raise Program_Error with
                  "Adac.AST: parenthesized-name item list is empty";
              end if;

              if not Adac.Source.contains
                (value.span,
                 self.nodes
                   (Positive(value.parenthesized_prefix.index)).span) or else
                 Adac.Source.first_position (value.span) /=
                   Adac.Source.first_position
                     (self.nodes
                        (Positive(value.parenthesized_prefix.index)).span)
              then
                raise Program_Error with
                  "Adac.AST: parenthesized-name prefix span is outside name";
              end if;

              append (pending, value.parenthesized_prefix);
              previous_last := Adac.Source.last_position
                (self.nodes(Positive(value.parenthesized_prefix.index)).span);

              for association of value.parenthesized_items loop
                if association.form = Named_Parenthesized_Name_Item_Form then
                  saw_named_item := True;
                  validate_node_id (self, association.selector);
                  if self.nodes(Positive(association.selector.index)).kind /=
                     Identifier_Name_Node
                  then
                    raise Program_Error with
                      "Adac.AST: named parenthesized selector is not an " &
                      "identifier";
                  end if;
                  if association.selector.index >= current.index then
                    raise Program_Error with
                      "Adac.AST: named parenthesized selector is not earlier";
                  end if;
                  if not Adac.Source.contains
                    (value.span,
                     self.nodes
                       (Positive(association.selector.index)).span) or else
                     not precedes
                       (previous_last,
                        Adac.Source.first_position
                          (self.nodes
                             (Positive(association.selector.index)).span))
                  then
                    raise Program_Error with
                      "Adac.AST: named parenthesized selector is out of " &
                      "source order";
                  end if;
                  append (pending, association.selector);
                  previous_last := Adac.Source.last_position
                    (self.nodes(Positive(association.selector.index)).span);
                elsif saw_named_item then
                  raise Program_Error with
                    "Adac.AST: positional parenthesized item follows named " &
                    "item";
                end if;

                require_current_parenthesized_item (self, association.actual);
                if association.actual.index >= current.index then
                  raise Program_Error with
                    "Adac.AST: parenthesized-name item is not earlier";
                end if;
                if not Adac.Source.contains
                  (value.span,
                   self.nodes(Positive(association.actual.index)).span) or else
                   not precedes
                     (previous_last,
                      Adac.Source.first_position
                        (self.nodes(Positive(association.actual.index)).span))
                then
                  raise Program_Error with
                    "Adac.AST: parenthesized-name item is out of source " &
                    "order";
                end if;
                previous_last := Adac.Source.last_position
                  (self.nodes(Positive(association.actual.index)).span);

                if is_current_name_kind
                  (self.nodes(Positive(association.actual.index)).kind)
                then
                  append (pending, association.actual);
                else
                  validate_expression (self, association.actual);
                end if;
              end loop;
            end;

          when others =>
            raise Program_Error with "Adac.AST: node is not a current name";
        end case;
      end;
    end loop;
  end validate_name;

  procedure validate_aspect_specification
    (self   : Store;
     aspect : Node_ID)
  is
    definition_span : Adac.Source.Span;
  begin
    require_aspect_specification (self, aspect);
    declare
      value : Node renames self.nodes(Positive(aspect.index));
    begin
      Adac.Symbols.validate (value.aspect_mark_symbol_value);
      Adac.Source.validate (value.aspect_mark_span_value);
      Adac.Source.validate (value.span);
      require_current_expression (self, value.aspect_definition_value);
      if value.aspect_definition_value.index >= aspect.index then
        raise Program_Error with
          "Adac.AST: aspect definition is not earlier";
      end if;
      validate_expression (self, value.aspect_definition_value);
      definition_span := node_span (self, value.aspect_definition_value);

      if not Adac.Source.contains
        (value.span, value.aspect_mark_span_value) or else
         not Adac.Source.contains (value.span, definition_span) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position (value.aspect_mark_span_value)) or else
         not precedes
           (Adac.Source.last_position (value.aspect_mark_span_value),
            Adac.Source.first_position (definition_span)) or else
         Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (definition_span)
      then
        raise Program_Error with
          "Adac.AST: aspect specification is out of source order";
      end if;
    end;
  end validate_aspect_specification;

  procedure validate_parameter
    (self      : Store;
     parameter : Node_ID)
  is
  begin
    require_parameter_specification (self, parameter);

    declare
      value        : Node renames self.nodes(Positive(parameter.index));
      subtype_span : Adac.Source.Span;
    begin
      Adac.Symbols.validate (value.parameter_symbol_value);
      Adac.Source.validate (value.parameter_defining_span_value);
      Adac.Source.validate (value.span);
      require_simple_name (self, value.parameter_subtype_mark_value);

      if value.parameter_subtype_mark_value.index >= parameter.index then
        raise Program_Error with
          "Adac.AST: parameter subtype mark is not earlier";
      end if;

      validate_simple_name (self, value.parameter_subtype_mark_value);
      subtype_span := node_span (self, value.parameter_subtype_mark_value);

      if not Adac.Source.contains
        (value.span, value.parameter_defining_span_value) or else
         not Adac.Source.contains (value.span, subtype_span)
      then
        raise Program_Error with
          "Adac.AST: parameter child span is outside specification";
      end if;

      declare
        previous_last : Adac.Source.Position :=
          Adac.Source.last_position (value.parameter_defining_span_value);
      begin
        if Adac.Source.first_position (value.span) /=
           Adac.Source.first_position (value.parameter_defining_span_value)
        then
          raise Program_Error with
            "Adac.AST: parameter spans are out of source order";
        end if;

        for index in 2 ..
          parameter_defining_identifier_count (self, parameter)
        loop
          declare
            symbol_value : constant Adac.Symbols.Symbol_ID :=
              parameter_defining_symbol_at (self, parameter, index);
            defining_span : constant Adac.Source.Span :=
              parameter_defining_span_at (self, parameter, index);
          begin
            Adac.Symbols.validate (symbol_value);
            Adac.Source.validate (defining_span);
            if not Adac.Source.contains (value.span, defining_span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (defining_span))
            then
              raise Program_Error with
                "Adac.AST: parameter defining identifiers are out of " &
                "source order";
            end if;
            previous_last := Adac.Source.last_position (defining_span);
          end;
        end loop;

        if not precedes
          (previous_last, Adac.Source.first_position (subtype_span))
        then
          raise Program_Error with
            "Adac.AST: parameter spans are out of source order";
        end if;
      end;

      if value.parameter_default_expression_value = INVALID_NODE_ID then
        if Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (subtype_span)
        then
          raise Program_Error with
            "Adac.AST: parameter spans are out of source order";
        end if;
      else
        declare
          default_expression : constant Node_ID :=
            value.parameter_default_expression_value;
          default_span : Adac.Source.Span;
        begin
          require_current_expression (self, default_expression);

          if default_expression.index >= parameter.index or else
             value.parameter_subtype_mark_value.index >=
               default_expression.index
          then
            raise Program_Error with
              "Adac.AST: parameter default is not earlier and ordered";
          end if;

          validate_expression (self, default_expression);
          default_span := node_span (self, default_expression);

          if not Adac.Source.contains (value.span, default_span) or else
             not precedes
               (Adac.Source.last_position (subtype_span),
                Adac.Source.first_position (default_span)) or else
             Adac.Source.last_position (value.span) /=
               Adac.Source.last_position (default_span)
          then
            raise Program_Error with
              "Adac.AST: parameter default is out of source order";
          end if;
        end;
      end if;
    end;
  end validate_parameter;

  procedure validate_declaration
    (self        : Store;
     declaration : Node_ID)
  is
  begin
    validate_node_id (self, declaration);

    case self.nodes(Positive(declaration.index)).kind is
      when Object_Declaration_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          subtype_span : Adac.Source.Span;
          subtype_last : Adac.Source.Position;
        begin
          Adac.Symbols.validate (value.object_symbol_value);
          Adac.Source.validate (value.object_defining_span_value);
          Adac.Source.validate (value.span);
          require_simple_name (self, value.object_subtype_mark_value);

          if value.object_subtype_mark_value.index >= declaration.index then
            raise Program_Error with
              "Adac.AST: object-declaration subtype mark is not earlier";
          end if;

          validate_simple_name (self, value.object_subtype_mark_value);
          subtype_span := node_span (self, value.object_subtype_mark_value);
          subtype_last := Adac.Source.last_position (subtype_span);

          if not Adac.Source.contains
            (value.span, value.object_defining_span_value) or else
             not Adac.Source.contains (value.span, subtype_span)
          then
            raise Program_Error with
              "Adac.AST: object-declaration child span is outside declaration";
          end if;

          if Adac.Source.first_position (value.span) /=
               Adac.Source.first_position
                 (value.object_defining_span_value) or else
             not precedes
               (Adac.Source.last_position (value.object_defining_span_value),
                Adac.Source.first_position (subtype_span))
          then
            raise Program_Error with
              "Adac.AST: object-declaration spans are out of source order";
          end if;

          if value.object_index_constraint_value /= INVALID_NODE_ID then
            require_index_constraint
              (self, value.object_index_constraint_value);
            if value.object_subtype_mark_value.index >=
                 value.object_index_constraint_value.index or else
               value.object_index_constraint_value.index >= declaration.index
            then
              raise Program_Error with
                "Adac.AST: object index constraint is not earlier and ordered";
            end if;
            validate_index_constraint
              (self, value.object_index_constraint_value);
            declare
              constraint_span : constant Adac.Source.Span :=
                node_span (self, value.object_index_constraint_value);
            begin
              if not Adac.Source.contains (value.span, constraint_span) or else
                 not precedes
                   (subtype_last,
                    Adac.Source.first_position (constraint_span))
              then
                raise Program_Error with
                  "Adac.AST: object index constraint is out of source order";
              end if;
              subtype_last := Adac.Source.last_position (constraint_span);
            end;
          end if;

          if value.object_initializer_value = INVALID_NODE_ID then
            if not precedes
              (subtype_last,
               Adac.Source.last_position (value.span))
            then
              raise Program_Error with
                "Adac.AST: object-declaration span omits its terminator";
            end if;
          else
            require_current_expression
              (self, value.object_initializer_value);

            if value.object_initializer_value.index >= declaration.index then
              raise Program_Error with
                "Adac.AST: object-declaration initializer is not earlier";
            end if;

            validate_expression (self, value.object_initializer_value);

            declare
              initializer_span : constant Adac.Source.Span :=
                node_span (self, value.object_initializer_value);
            begin
              if not Adac.Source.contains (value.span, initializer_span) or else
                 not precedes
                   (subtype_last,
                    Adac.Source.first_position (initializer_span)) or else
                 not precedes
                   (Adac.Source.last_position (initializer_span),
                    Adac.Source.last_position (value.span))
              then
                raise Program_Error with
                  "Adac.AST: object-declaration initializer is out of " &
                  "source order";
              end if;
            end;
          end if;
        end;

      when Object_Renaming_Declaration_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          subtype_span : Adac.Source.Span;
          renamed_span : Adac.Source.Span;
        begin
          Adac.Symbols.validate (value.object_renaming_symbol_value);
          Adac.Source.validate (value.object_renaming_defining_span_value);
          Adac.Source.validate (value.span);
          require_simple_name (self, value.object_renaming_subtype_mark_value);
          require_current_name (self, value.object_renaming_name_value);

          if value.object_renaming_subtype_mark_value.index >=
               value.object_renaming_name_value.index or else
             value.object_renaming_name_value.index >= declaration.index
          then
            raise Program_Error with
              "Adac.AST: object-renaming children are not earlier and ordered";
          end if;

          validate_simple_name (self, value.object_renaming_subtype_mark_value);
          validate_name (self, value.object_renaming_name_value);
          subtype_span :=
            node_span (self, value.object_renaming_subtype_mark_value);
          renamed_span := node_span (self, value.object_renaming_name_value);

          if not Adac.Source.contains
            (value.span, value.object_renaming_defining_span_value) or else
             not Adac.Source.contains (value.span, subtype_span) or else
             not Adac.Source.contains (value.span, renamed_span) or else
             Adac.Source.first_position (value.span) /=
               Adac.Source.first_position
                 (value.object_renaming_defining_span_value) or else
             not precedes
               (Adac.Source.last_position
                  (value.object_renaming_defining_span_value),
                Adac.Source.first_position (subtype_span)) or else
             not precedes
               (Adac.Source.last_position (subtype_span),
                Adac.Source.first_position (renamed_span)) or else
             not precedes
               (Adac.Source.last_position (renamed_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: object-renaming children are out of source order";
          end if;
        end;

      when Exception_Declaration_Node =>
        validate_exception_declaration (self, declaration);

      when Number_Declaration_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          initializer_span : Adac.Source.Span;
        begin
          Adac.Symbols.validate (value.number_symbol_value);
          Adac.Source.validate (value.number_defining_span_value);
          Adac.Source.validate (value.span);
          require_current_expression (self, value.number_initializer_value);

          if value.number_initializer_value.index >= declaration.index then
            raise Program_Error with
              "Adac.AST: number-declaration initializer is not earlier";
          end if;

          validate_expression (self, value.number_initializer_value);
          initializer_span := node_span (self, value.number_initializer_value);

          if not Adac.Source.contains
            (value.span, value.number_defining_span_value) or else
             not Adac.Source.contains (value.span, initializer_span)
          then
            raise Program_Error with
              "Adac.AST: number-declaration child span is outside declaration";
          end if;

          if Adac.Source.first_position (value.span) /=
               Adac.Source.first_position
                 (value.number_defining_span_value) or else
             not precedes
               (Adac.Source.last_position (value.number_defining_span_value),
                Adac.Source.first_position (initializer_span)) or else
             not precedes
               (Adac.Source.last_position (initializer_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: number-declaration spans are out of source order";
          end if;
        end;

      when Procedure_Declaration_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          previous_last : Adac.Source.Position;
        begin
          Adac.Symbols.validate (value.procedure_declaration_symbol_value);
          Adac.Source.validate
            (value.procedure_declaration_defining_span_value);
          Adac.Source.validate (value.span);

          if not Adac.Source.contains
            (value.span,
             value.procedure_declaration_defining_span_value) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.procedure_declaration_defining_span_value))
          then
            raise Program_Error with
              "Adac.AST: procedure-declaration spans are out of source order";
          end if;

          previous_last :=
            Adac.Source.last_position
              (value.procedure_declaration_defining_span_value);
          for parameter of value.procedure_declaration_parameters_value loop
            if parameter.index >= declaration.index then
              raise Program_Error with
                "Adac.AST: procedure parameter is not earlier";
            end if;
            validate_parameter (self, parameter);
            declare
              child_span : constant Adac.Source.Span :=
                node_span (self, parameter);
            begin
              if not Adac.Source.contains (value.span, child_span) or else
                 not precedes
                   (previous_last, Adac.Source.first_position (child_span))
              then
                raise Program_Error with
                  "Adac.AST: procedure parameters are out of source order";
              end if;
              previous_last := Adac.Source.last_position (child_span);
            end;
          end loop;

          if not precedes
            (previous_last, Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: procedure-declaration spans are out of source order";
          end if;
        end;

      when Procedure_Body_Stub_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          previous_last : Adac.Source.Position;
        begin
          Adac.Symbols.validate (value.procedure_body_stub_symbol_value);
          Adac.Source.validate (value.procedure_body_stub_defining_span_value);
          Adac.Source.validate (value.span);
          if not Adac.Source.contains
            (value.span, value.procedure_body_stub_defining_span_value) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.procedure_body_stub_defining_span_value))
          then
            raise Program_Error with
              "Adac.AST: procedure-body-stub spans are out of source order";
          end if;
          previous_last :=
            Adac.Source.last_position
              (value.procedure_body_stub_defining_span_value);
          for parameter of value.procedure_body_stub_parameters_value loop
            if parameter.index >= declaration.index then
              raise Program_Error with
                "Adac.AST: procedure-body-stub parameter is not earlier";
            end if;
            validate_parameter (self, parameter);
            declare
              child_span : constant Adac.Source.Span :=
                node_span (self, parameter);
            begin
              if not Adac.Source.contains (value.span, child_span) or else
                 not precedes
                   (previous_last, Adac.Source.first_position (child_span))
              then
                raise Program_Error with
                  "Adac.AST: procedure-body-stub parameters are out of " &
                    "source order";
              end if;
              previous_last := Adac.Source.last_position (child_span);
            end;
          end loop;
          if not precedes
            (previous_last, Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: procedure-body-stub span omits its completion";
          end if;
        end;

      when Function_Declaration_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          previous_last : Adac.Source.Position;
          result_span   : Adac.Source.Span;
        begin
          Adac.Symbols.validate (value.function_declaration_symbol_value);
          Adac.Source.validate
            (value.function_declaration_defining_span_value);
          Adac.Source.validate (value.span);

          if not Adac.Source.contains
            (value.span, value.function_declaration_defining_span_value) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.function_declaration_defining_span_value))
          then
            raise Program_Error with
              "Adac.AST: function-declaration spans are out of source order";
          end if;

          previous_last :=
            Adac.Source.last_position
              (value.function_declaration_defining_span_value);
          for parameter of value.function_declaration_parameters_value loop
            if parameter.index >= declaration.index then
              raise Program_Error with
                "Adac.AST: function parameter is not earlier";
            end if;
            validate_parameter (self, parameter);
            declare
              child_span : constant Adac.Source.Span :=
                node_span (self, parameter);
            begin
              if not Adac.Source.contains (value.span, child_span) or else
                 not precedes
                   (previous_last, Adac.Source.first_position (child_span))
              then
                raise Program_Error with
                  "Adac.AST: function parameters are out of source order";
              end if;
              previous_last := Adac.Source.last_position (child_span);
            end;
          end loop;

          if value.function_declaration_result_subtype_value.index >=
             declaration.index
          then
            raise Program_Error with
              "Adac.AST: function result subtype is not earlier";
          end if;
          require_simple_name
            (self, value.function_declaration_result_subtype_value);
          validate_simple_name
            (self, value.function_declaration_result_subtype_value);
          result_span :=
            node_span (self, value.function_declaration_result_subtype_value);

          if not Adac.Source.contains (value.span, result_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (result_span))
          then
            raise Program_Error with
              "Adac.AST: function result is out of source order";
          end if;
          previous_last := Adac.Source.last_position (result_span);

          if value.function_declaration_expression_value /= INVALID_NODE_ID then
            declare
              expression : constant Node_ID :=
                value.function_declaration_expression_value;
              expression_span : Adac.Source.Span;
            begin
              if expression.index >= declaration.index then
                raise Program_Error with
                  "Adac.AST: function expression is not earlier";
              end if;
              require_current_expression (self, expression);
              validate_expression (self, expression);
              expression_span := node_span (self, expression);
              if not Adac.Source.contains (value.span, expression_span) or else
                 not precedes
                   (previous_last, Adac.Source.first_position (expression_span))
              then
                raise Program_Error with
                  "Adac.AST: function expression is out of source order";
              end if;
              previous_last := Adac.Source.last_position (expression_span);
            end;
          end if;

          if value.function_declaration_aspect_value /= INVALID_NODE_ID then
            declare
              aspect : constant Node_ID :=
                value.function_declaration_aspect_value;
              aspect_span : Adac.Source.Span;
            begin
              require_aspect_specification (self, aspect);
              if aspect.index >= declaration.index then
                raise Program_Error with
                  "Adac.AST: function aspect is not earlier";
              end if;
              validate_aspect_specification (self, aspect);
              aspect_span := node_span (self, aspect);
              if not Adac.Source.contains (value.span, aspect_span) or else
                 not precedes
                   (previous_last, Adac.Source.first_position (aspect_span))
              then
                raise Program_Error with
                  "Adac.AST: function aspect is out of source order";
              end if;
              previous_last := Adac.Source.last_position (aspect_span);
            end;
          end if;

          if not precedes
            (previous_last, Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: function declaration span omits its terminator";
          end if;
        end;

      when Derived_Type_Declaration_Node =>
        validate_derived_type_declaration (self, declaration);

      when Subtype_Declaration_Node =>
        validate_subtype_declaration (self, declaration);

      when Private_Type_Declaration_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          previous_last : Adac.Source.Position;
        begin
          Adac.Symbols.validate (value.private_type_symbol_value);
          Adac.Source.validate (value.private_type_defining_span_value);
          Adac.Source.validate (value.span);

          if not Adac.Source.contains
            (value.span, value.private_type_defining_span_value) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.private_type_defining_span_value))
          then
            raise Program_Error with
              "Adac.AST: private-type defining span is out of source order";
          end if;

          previous_last :=
            Adac.Source.last_position (value.private_type_defining_span_value);
          for discriminant of value.private_type_discriminants_value loop
            require_discriminant_specification (self, discriminant);
            if discriminant.index >= declaration.index then
              raise Program_Error with
                "Adac.AST: private-type discriminant is not earlier";
            end if;
            validate_discriminant_specification (self, discriminant);
            declare
              child_span : constant Adac.Source.Span :=
                node_span (self, discriminant);
            begin
              if not Adac.Source.contains (value.span, child_span) or else
                 not precedes
                   (previous_last, Adac.Source.first_position (child_span))
              then
                raise Program_Error with
                  "Adac.AST: private-type discriminants are out of " &
                  "source order";
              end if;
              previous_last := Adac.Source.last_position (child_span);
            end;
          end loop;

          if not precedes
            (previous_last, Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: private-type declaration span omits its completion";
          end if;
        end;

      when Record_Type_Declaration_Node =>
        validate_record_type_declaration (self, declaration);

      when Access_Object_Type_Declaration_Node =>
        validate_access_object_type_declaration (self, declaration);

      when Package_Renaming_Declaration_Node =>
        validate_package_renaming_declaration (self, declaration);

      when Package_Instantiation_Node =>
        validate_package_instantiation (self, declaration);

      when Package_Declaration_Node =>
        validate_package_declaration (self, declaration);

      when Enumeration_Type_Declaration_Node =>
        declare
          value : Node renames self.nodes(Positive(declaration.index));
          previous_last : Adac.Source.Position;
        begin
          Adac.Symbols.validate (value.enumeration_type_symbol_value);
          Adac.Source.validate (value.enumeration_type_defining_span_value);
          Adac.Source.validate (value.span);
          if value.enumeration_literals_value.is_empty then
            raise Program_Error with
              "Adac.AST: enumeration type has no defining literals";
          end if;
          if not Adac.Source.contains
            (value.span, value.enumeration_type_defining_span_value) or else
             not precedes
               (Adac.Source.first_position (value.span),
                Adac.Source.first_position
                  (value.enumeration_type_defining_span_value))
          then
            raise Program_Error with
              "Adac.AST: enumeration type defining span is out of source order";
          end if;

          previous_last :=
            Adac.Source.last_position
              (value.enumeration_type_defining_span_value);
          for literal of value.enumeration_literals_value loop
            Adac.Symbols.validate (literal.symbol);
            Adac.Source.validate (literal.span);
            if not Adac.Source.contains (value.span, literal.span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (literal.span))
            then
              raise Program_Error with
                "Adac.AST: enumeration literals are out of source order";
            end if;
            previous_last := Adac.Source.last_position (literal.span);
          end loop;

          if not precedes
            (previous_last, Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: enumeration span does not include its terminator";
          end if;
        end;

      when others =>
        raise Program_Error with "Adac.AST: node is not a declaration";
    end case;
  end validate_declaration;

  procedure validate_use_type_clause
    (self   : Store;
     clause : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_use_type_clause (self, clause);
    declare
      value : Node renames self.nodes(Positive(clause.index));
    begin
      Adac.Source.validate (value.span);
      if value.use_type_subtype_marks_value.is_empty then
        raise Program_Error with
          "Adac.AST: use-type subtype-mark list is empty";
      end if;
      previous_last := Adac.Source.first_position (value.span);
      for subtype_mark of value.use_type_subtype_marks_value loop
        require_simple_name (self, subtype_mark);
        if subtype_mark.index >= clause.index then
          raise Program_Error with
            "Adac.AST: use-type subtype mark is not earlier";
        end if;
        validate_name (self, subtype_mark);
        declare
          mark_span : constant Adac.Source.Span :=
            node_span (self, subtype_mark);
        begin
          if not Adac.Source.contains (value.span, mark_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (mark_span))
          then
            raise Program_Error with
              "Adac.AST: use-type subtype marks are out of source order";
          end if;
          previous_last := Adac.Source.last_position (mark_span);
        end;
      end loop;
      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: use-type clause span omits its terminator";
      end if;
    end;
  end validate_use_type_clause;

  procedure validate_use_package_clause
    (self   : Store;
     clause : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_use_package_clause (self, clause);
    declare
      value : Node renames self.nodes(Positive(clause.index));
    begin
      Adac.Source.validate (value.span);
      if value.use_package_names_value.is_empty then
        raise Program_Error with
          "Adac.AST: package-use name list is empty";
      end if;
      previous_last := Adac.Source.first_position (value.span);
      for package_name of value.use_package_names_value loop
        require_simple_name (self, package_name);
        if package_name.index >= clause.index then
          raise Program_Error with
            "Adac.AST: package-use name is not earlier";
        end if;
        validate_name (self, package_name);
        declare
          name_span : constant Adac.Source.Span :=
            node_span (self, package_name);
        begin
          if not Adac.Source.contains (value.span, name_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (name_span))
          then
            raise Program_Error with
              "Adac.AST: package-use names are out of source order";
          end if;
          previous_last := Adac.Source.last_position (name_span);
        end;
      end loop;
      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: package-use clause span omits its terminator";
      end if;
    end;
  end validate_use_package_clause;

  procedure validate_package_renaming_declaration
    (self        : Store;
     declaration : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_package_renaming_declaration (self, declaration);
    declare
      value : Node renames self.nodes(Positive(declaration.index));
      renamed_span : Adac.Source.Span;
    begin
      Adac.Source.validate (value.span);
      if value.package_renaming_defining_name_value.is_empty then
        raise Program_Error with
          "Adac.AST: package renaming defining name is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for component of value.package_renaming_defining_name_value loop
        Adac.Symbols.validate (component.symbol);
        Adac.Source.validate (component.span);
        if not Adac.Source.contains (value.span, component.span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component.span))
        then
          raise Program_Error with
            "Adac.AST: package renaming defining name is out of source order";
        end if;
        previous_last := Adac.Source.last_position (component.span);
      end loop;

      require_simple_name (self, value.package_renaming_renamed_package_value);
      if value.package_renaming_renamed_package_value.index >= declaration.index
      then
        raise Program_Error with
          "Adac.AST: renamed package name is not earlier";
      end if;
      validate_name (self, value.package_renaming_renamed_package_value);
      renamed_span :=
        node_span (self, value.package_renaming_renamed_package_value);
      if not Adac.Source.contains (value.span, renamed_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (renamed_span)) or else
         not precedes
           (Adac.Source.last_position (renamed_span),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: renamed package name is out of source order";
      end if;
    end;
  end validate_package_renaming_declaration;

  procedure validate_package_instantiation
    (self          : Store;
     instantiation : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_package_instantiation (self, instantiation);
    declare
      value : Node renames self.nodes(Positive(instantiation.index));
      generic_span : Adac.Source.Span;
    begin
      Adac.Source.validate (value.span);
      if value.package_instantiation_defining_name_value.is_empty then
        raise Program_Error with
          "Adac.AST: package instantiation defining name is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for component of value.package_instantiation_defining_name_value loop
        Adac.Symbols.validate (component.symbol);
        Adac.Source.validate (component.span);
        if not Adac.Source.contains (value.span, component.span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component.span))
        then
          raise Program_Error with
            "Adac.AST: package instantiation defining name is out of " &
            "source order";
        end if;
        previous_last := Adac.Source.last_position (component.span);
      end loop;

      require_simple_name
        (self, value.package_instantiation_generic_name_value);
      if value.package_instantiation_generic_name_value.index >=
         instantiation.index
      then
        raise Program_Error with
          "Adac.AST: generic package name is not earlier";
      end if;
      validate_name (self, value.package_instantiation_generic_name_value);
      generic_span :=
        node_span (self, value.package_instantiation_generic_name_value);
      if not Adac.Source.contains (value.span, generic_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (generic_span))
      then
        raise Program_Error with
          "Adac.AST: generic package name is out of source order";
      end if;
      previous_last := Adac.Source.last_position (generic_span);

      for association of value.package_instantiation_actuals_value loop
        if association.actual.index >= instantiation.index then
          raise Program_Error with
            "Adac.AST: generic actual is not earlier";
        end if;
        case kind_of (self, association.actual) is
          when String_Literal_Node =>
            validate_string_literal (self, association.actual);
          when others =>
            require_current_name (self, association.actual);
            validate_name (self, association.actual);
        end case;
        declare
          actual_span : constant Adac.Source.Span :=
            node_span (self, association.actual);
        begin
          case association.form is
            when Positional_Generic_Actual_Form =>
              if association.selector /= Adac.Symbols.INVALID_SYMBOL_ID or else
                 association.selector_span /= Adac.Source.INVALID_SPAN or else
                 not Adac.Source.contains (value.span, actual_span) or else
                 not precedes
                   (previous_last, Adac.Source.first_position (actual_span))
              then
                raise Program_Error with
                  "Adac.AST: positional generic actual is out of source order";
              end if;

            when Named_Generic_Actual_Form =>
              Adac.Symbols.validate (association.selector);
              Adac.Source.validate (association.selector_span);
              if not Adac.Source.contains
                (value.span, association.selector_span) or else
                 not Adac.Source.contains (value.span, actual_span) or else
                 not precedes
                   (previous_last,
                    Adac.Source.first_position
                      (association.selector_span)) or else
                 not precedes
                   (Adac.Source.last_position (association.selector_span),
                    Adac.Source.first_position (actual_span))
              then
                raise Program_Error with
                  "Adac.AST: named generic actual is out of source order";
              end if;
          end case;
          previous_last := Adac.Source.last_position (actual_span);
        end;
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: package instantiation span omits its terminator";
      end if;
    end;
  end validate_package_instantiation;

  procedure validate_package_declaration
    (self        : Store;
     declaration : Node_ID)
  is
    pending : Node_List;
    next    : Positive := 1;

    procedure validate_one (package_node : Node_ID) is
      previous_last : Adac.Source.Position;
      value : Node renames self.nodes(Positive(package_node.index));

      procedure validate_child
        (child     : Node_ID;
         part_name : String)
      is
        child_span : Adac.Source.Span;
      begin
        validate_node_id (self, child);
        if child.index >= package_node.index then
          raise Program_Error with
            "Adac.AST: package declaration child is not earlier";
        end if;

        case self.nodes(Positive(child.index)).kind is
          when Object_Declaration_Node |
               Object_Renaming_Declaration_Node |
               Number_Declaration_Node |
               Exception_Declaration_Node |
               Procedure_Declaration_Node |
               Function_Declaration_Node |
               Private_Type_Declaration_Node |
               Derived_Type_Declaration_Node |
               Subtype_Declaration_Node |
               Enumeration_Type_Declaration_Node |
               Record_Type_Declaration_Node |
               Access_Object_Type_Declaration_Node |
               Package_Renaming_Declaration_Node |
               Package_Instantiation_Node =>
            validate_declaration (self, child);

          when Package_Declaration_Node =>
            append (pending, child);

          when others =>
            raise Program_Error with
              "Adac.AST: node is not a current package declaration";
        end case;

        child_span := node_span (self, child);
        if not Adac.Source.contains (value.span, child_span) or else
           not precedes
             (previous_last, Adac.Source.first_position (child_span))
        then
          raise Program_Error with
            "Adac.AST: package " & part_name &
            " declarations are out of source order";
        end if;
        previous_last := Adac.Source.last_position (child_span);
      end validate_child;

    begin
      require_package_declaration (self, package_node);
      Adac.Source.validate (value.span);
      if value.package_defining_name_value.is_empty then
        raise Program_Error with
          "Adac.AST: package defining program-unit name is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for component of value.package_defining_name_value loop
        Adac.Symbols.validate (component.symbol);
        Adac.Source.validate (component.span);
        if not Adac.Source.contains (value.span, component.span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component.span))
        then
          raise Program_Error with
            "Adac.AST: package defining name is out of source order";
        end if;
        previous_last := Adac.Source.last_position (component.span);
      end loop;

      for child of value.package_visible_declarations_value loop
        validate_child (child, "visible");
      end loop;

      if value.package_private_part_span_value = Adac.Source.INVALID_SPAN then
        if not value.package_private_declarations_value.is_empty then
          raise Program_Error with
            "Adac.AST: package private declarations lack a private boundary";
        end if;
      else
        Adac.Source.validate (value.package_private_part_span_value);
        if not Adac.Source.contains
          (value.span, value.package_private_part_span_value) or else
           not precedes
             (previous_last,
              Adac.Source.first_position
                (value.package_private_part_span_value))
        then
          raise Program_Error with
            "Adac.AST: package private boundary is out of source order";
        end if;
        previous_last :=
          Adac.Source.last_position (value.package_private_part_span_value);

        for child of value.package_private_declarations_value loop
          validate_child (child, "private");
        end loop;
      end if;

      for component of value.package_end_name_value loop
        Adac.Symbols.validate (component.symbol);
        Adac.Source.validate (component.span);
        if not Adac.Source.contains (value.span, component.span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component.span))
        then
          raise Program_Error with
            "Adac.AST: package closing name is out of source order";
        end if;
        previous_last := Adac.Source.last_position (component.span);
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: package span does not include its terminator";
      end if;
    end validate_one;

  begin
    require_package_declaration (self, declaration);
    append (pending, declaration);

    while next <= list_count (pending) loop
      validate_one (list_element (pending, next));
      next := next + 1;
    end loop;
  end validate_package_declaration;

  procedure validate_package_body_stub
    (self : Store;
     stub : Node_ID)
  is
  begin
    require_package_body_stub (self, stub);
    declare
      value : Node renames self.nodes(Positive(stub.index));
    begin
      Adac.Symbols.validate (value.package_body_stub_symbol_value);
      Adac.Source.validate (value.package_body_stub_defining_span_value);
      Adac.Source.validate (value.span);

      if not Adac.Source.contains
        (value.span, value.package_body_stub_defining_span_value) or else
         not precedes
           (Adac.Source.first_position (value.span),
            Adac.Source.first_position
              (value.package_body_stub_defining_span_value)) or else
         not precedes
           (Adac.Source.last_position
              (value.package_body_stub_defining_span_value),
            Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: package-body-stub spans are out of source order";
      end if;
    end;
  end validate_package_body_stub;

  procedure validate_package_body
    (self : Store;
     package_body : Node_ID)
  is
    previous_last : Adac.Source.Position;
  begin
    require_package_body (self, package_body);
    declare
      value : Node renames self.nodes(Positive(package_body.index));
    begin
      Adac.Source.validate (value.span);
      if value.body_defining_name_value.is_empty then
        raise Program_Error with
          "Adac.AST: package-body defining program-unit name is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for component of value.body_defining_name_value loop
        Adac.Symbols.validate (component.symbol);
        Adac.Source.validate (component.span);
        if not Adac.Source.contains (value.span, component.span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component.span))
        then
          raise Program_Error with
            "Adac.AST: package-body defining name is out of source order";
        end if;
        previous_last := Adac.Source.last_position (component.span);
      end loop;

      for child of value.body_declarations_value loop
        validate_node_id (self, child);
        if child.index >= package_body.index then
          raise Program_Error with
            "Adac.AST: package-body declaration is not earlier";
        end if;
        case self.nodes(Positive(child.index)).kind is
          when Procedure_Body_Node =>
            validate_procedure_body (self, child);

          when Function_Body_Node =>
            validate_function_body (self, child);

          when Use_Type_Clause_Node =>
            validate_use_type_clause (self, child);

          when Use_Package_Clause_Node =>
            validate_use_package_clause (self, child);

          when Package_Body_Stub_Node =>
            validate_package_body_stub (self, child);

          when Object_Declaration_Node |
               Object_Renaming_Declaration_Node |
               Number_Declaration_Node |
               Exception_Declaration_Node |
               Procedure_Declaration_Node |
               Procedure_Body_Stub_Node |
               Function_Declaration_Node |
               Private_Type_Declaration_Node |
               Derived_Type_Declaration_Node |
               Subtype_Declaration_Node |
               Enumeration_Type_Declaration_Node |
               Record_Type_Declaration_Node |
               Access_Object_Type_Declaration_Node |
               Package_Renaming_Declaration_Node |
               Package_Instantiation_Node |
               Package_Declaration_Node =>
            validate_declaration (self, child);

          when others =>
            raise Program_Error with
              "Adac.AST: node is not a package-body declarative item";
        end case;
        declare
          child_span : constant Adac.Source.Span := node_span (self, child);
        begin
          if not Adac.Source.contains (value.span, child_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (child_span))
          then
            raise Program_Error with
              "Adac.AST: package-body declarations are out of source order";
          end if;
          previous_last := Adac.Source.last_position (child_span);
        end;
      end loop;

      for component of value.body_end_name_value loop
        Adac.Symbols.validate (component.symbol);
        Adac.Source.validate (component.span);
        if not Adac.Source.contains (value.span, component.span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component.span))
        then
          raise Program_Error with
            "Adac.AST: package-body closing name is out of source order";
        end if;
        previous_last := Adac.Source.last_position (component.span);
      end loop;

      if not precedes
        (previous_last, Adac.Source.last_position (value.span))
      then
        raise Program_Error with
          "Adac.AST: package-body span does not include its terminator";
      end if;
    end;
  end validate_package_body;

  procedure validate_procedure_body
    (self           : Store;
     procedure_body : Node_ID)
  is
    pending : Node_List;
    next    : Positive := 1;

    procedure validate_one (item : Node_ID) is
      previous_last : Adac.Source.Position;
    begin
      require_procedure_body (self, item);
      declare
        value : Node renames self.nodes(Positive(item.index));
      begin
        Adac.Symbols.validate (value.procedure_symbol);
        if value.end_symbol /= Adac.Symbols.INVALID_SYMBOL_ID then
          Adac.Symbols.validate (value.end_symbol);
        end if;
        Adac.Source.validate (value.span);
        previous_last := Adac.Source.first_position (value.span);

        for parameter of value.parameters loop
          validate_parameter (self, parameter);
          if parameter.index >= item.index then
            raise Program_Error with
              "Adac.AST: procedure-body parameter is not earlier";
          end if;
          declare
            child_span : constant Adac.Source.Span :=
              node_span (self, parameter);
          begin
            if not Adac.Source.contains (value.span, child_span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (child_span))
            then
              raise Program_Error with
                "Adac.AST: procedure parameters are out of source order";
            end if;
            previous_last := Adac.Source.last_position (child_span);
          end;
        end loop;

        for declaration of value.declarations loop
          validate_node_id (self, declaration);
          case self.nodes(Positive(declaration.index)).kind is
            when Object_Declaration_Node |
                 Number_Declaration_Node |
                 Object_Renaming_Declaration_Node |
                 Procedure_Declaration_Node |
                 Function_Declaration_Node |
                 Enumeration_Type_Declaration_Node |
                 Record_Type_Declaration_Node |
                 Subtype_Declaration_Node |
                 Package_Instantiation_Node =>
              validate_declaration (self, declaration);
            when Use_Type_Clause_Node =>
              validate_use_type_clause (self, declaration);
            when Use_Package_Clause_Node =>
              validate_use_package_clause (self, declaration);
            when Procedure_Body_Node =>
              append (pending, declaration);
            when Function_Body_Node =>
              for function_index in 1 ..
                function_body_declaration_count (self, declaration)
              loop
                declare
                  function_declaration : constant Node_ID :=
                    function_body_declaration_at
                      (self, declaration, function_index);
                begin
                  validate_node_id (self, function_declaration);
                  case self.nodes
                    (Positive(function_declaration.index)).kind is
                    when Object_Declaration_Node =>
                      validate_declaration (self, function_declaration);

                    when Procedure_Body_Node =>
                      for nested_index in 1 ..
                        declaration_count (self, function_declaration)
                      loop
                        declare
                          nested : constant Node_ID := declaration_at
                            (self, function_declaration, nested_index);
                        begin
                          case self.nodes(Positive(nested.index)).kind is
                            when Procedure_Body_Node | Function_Body_Node =>
                              raise Program_Error with
                                "Adac.AST: bounded procedure-owned function " &
                                "procedure contains a subprogram body";
                            when others =>
                              null;
                          end case;
                        end;
                      end loop;
                      validate_procedure_body (self, function_declaration);

                    when others =>
                      raise Program_Error with
                        "Adac.AST: procedure-owned function has unsupported " &
                        "declarative item";
                  end case;
                end;
              end loop;
              validate_function_body (self, declaration);
            when others =>
              raise Program_Error with
                "Adac.AST: node is not a procedure declarative item";
          end case;

          if declaration.index >= item.index then
            raise Program_Error with
              "Adac.AST: procedure-body declaration is not earlier";
          end if;
          declare
            child_span : constant Adac.Source.Span :=
              node_span (self, declaration);
          begin
            if not Adac.Source.contains (value.span, child_span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (child_span))
            then
              raise Program_Error with
                "Adac.AST: procedure declarations are out of source order";
            end if;
            previous_last := Adac.Source.last_position (child_span);
          end;
        end loop;

        validate_handled_sequence
          (self, value.procedure_handled_sequence_value);
        if value.procedure_handled_sequence_value.index >= item.index then
          raise Program_Error with
            "Adac.AST: procedure handled sequence is not earlier";
        end if;
        declare
          handled_span : constant Adac.Source.Span :=
            node_span (self, value.procedure_handled_sequence_value);
        begin
          if not Adac.Source.contains (value.span, handled_span) or else
             not precedes
               (previous_last,
                Adac.Source.first_position (handled_span)) or else
             not precedes
               (Adac.Source.last_position (handled_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: handled sequence is out of procedure-body order";
          end if;
        end;
      end;
    end validate_one;
  begin
    append (pending, procedure_body);
    while next <= list_count (pending) loop
      validate_one (list_element (pending, next));
      next := next + 1;
    end loop;
  end validate_procedure_body;

  procedure validate_function_body
    (self          : Store;
     function_body : Node_ID)
  is
    pending_functions  : Node_List;
    pending_procedures : Node_List;
    next_function      : Natural := 1;

    procedure validate_one (item : Node_ID) is
      previous_last : Adac.Source.Position;
    begin
      require_function_body (self, item);
      declare
        value : Node renames self.nodes(Positive(item.index));
      begin
        Adac.Symbols.validate (value.function_body_symbol_value);
        if value.function_body_end_symbol_value /=
           Adac.Symbols.INVALID_SYMBOL_ID
        then
          Adac.Symbols.validate (value.function_body_end_symbol_value);
        end if;
        Adac.Source.validate (value.span);
        previous_last := Adac.Source.first_position (value.span);

        for parameter of value.function_body_parameters_value loop
          validate_parameter (self, parameter);
          if parameter.index >= item.index then
            raise Program_Error with
              "Adac.AST: function-body parameter is not earlier";
          end if;
          declare
            child_span : constant Adac.Source.Span :=
              node_span (self, parameter);
          begin
            if not Adac.Source.contains (value.span, child_span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (child_span))
            then
              raise Program_Error with
                "Adac.AST: function parameters are out of source order";
            end if;
            previous_last := Adac.Source.last_position (child_span);
          end;
        end loop;

        require_simple_name (self, value.function_body_result_subtype_value);
        if value.function_body_result_subtype_value.index >= item.index then
          raise Program_Error with
            "Adac.AST: function result subtype is not earlier";
        end if;
        validate_name (self, value.function_body_result_subtype_value);
        declare
          result_span : constant Adac.Source.Span :=
            node_span (self, value.function_body_result_subtype_value);
        begin
          if not Adac.Source.contains (value.span, result_span) or else
             not precedes
               (previous_last, Adac.Source.first_position (result_span))
          then
            raise Program_Error with
              "Adac.AST: function result subtype is out of source order";
          end if;
          previous_last := Adac.Source.last_position (result_span);
        end;

        for declaration of value.function_body_declarations_value loop
          validate_node_id (self, declaration);
          if declaration.index >= item.index then
            raise Program_Error with
              "Adac.AST: function-body declaration is not earlier";
          end if;
          case self.nodes(Positive(declaration.index)).kind is
            when Procedure_Body_Node =>
              append (pending_procedures, declaration);
            when Function_Body_Node =>
              append (pending_functions, declaration);
            when others =>
              validate_declaration (self, declaration);
          end case;
          declare
            child_span : constant Adac.Source.Span :=
              node_span (self, declaration);
          begin
            if not Adac.Source.contains (value.span, child_span) or else
               not precedes
                 (previous_last, Adac.Source.first_position (child_span))
            then
              raise Program_Error with
                "Adac.AST: function declarations are out of source order";
            end if;
            previous_last := Adac.Source.last_position (child_span);
          end;
        end loop;

        validate_handled_sequence
          (self, value.function_body_handled_sequence_value);
        if value.function_body_handled_sequence_value.index >= item.index then
          raise Program_Error with
            "Adac.AST: function handled sequence is not earlier";
        end if;
        declare
          handled_span : constant Adac.Source.Span :=
            node_span (self, value.function_body_handled_sequence_value);
        begin
          if not Adac.Source.contains (value.span, handled_span) or else
             not precedes
               (previous_last,
                Adac.Source.first_position (handled_span)) or else
             not precedes
               (Adac.Source.last_position (handled_span),
                Adac.Source.last_position (value.span))
          then
            raise Program_Error with
              "Adac.AST: handled sequence is out of function-body order";
          end if;
        end;
      end;
    end validate_one;
  begin
    append (pending_functions, function_body);
    while next_function <= list_count (pending_functions) loop
      validate_one (list_element (pending_functions, next_function));
      next_function := next_function + 1;
    end loop;

    for index in 1 .. list_count (pending_procedures) loop
      validate_procedure_body
        (self, list_element (pending_procedures, index));
    end loop;
  end validate_function_body;

  procedure validate_subunit
    (self    : Store;
     subunit : Node_ID)
  is
    previous_last : Adac.Source.Position;
    body_span     : Adac.Source.Span;
  begin
    require_subunit (self, subunit);
    declare
      value : Node renames self.nodes(Positive(subunit.index));
    begin
      Adac.Source.validate (value.span);
      if value.subunit_parent_name_value.is_empty then
        raise Program_Error with "Adac.AST: subunit parent unit name is empty";
      end if;

      previous_last := Adac.Source.first_position (value.span);
      for component of value.subunit_parent_name_value loop
        Adac.Symbols.validate (component.symbol);
        Adac.Source.validate (component.span);
        if not Adac.Source.contains (value.span, component.span) or else
           not precedes
             (previous_last, Adac.Source.first_position (component.span))
        then
          raise Program_Error with
            "Adac.AST: subunit parent unit name is out of source order";
        end if;
        previous_last := Adac.Source.last_position (component.span);
      end loop;

      validate_node_id (self, value.subunit_proper_body_value);
      if value.subunit_proper_body_value.index >= subunit.index then
        raise Program_Error with "Adac.AST: subunit proper body is not earlier";
      end if;
      case self.nodes(Positive(value.subunit_proper_body_value.index)).kind is
        when Procedure_Body_Node =>
          validate_procedure_body (self, value.subunit_proper_body_value);
        when Function_Body_Node =>
          validate_function_body (self, value.subunit_proper_body_value);
        when Package_Body_Node =>
          validate_package_body (self, value.subunit_proper_body_value);
        when others =>
          raise Program_Error with
            "Adac.AST: node is not a current proper body";
      end case;

      body_span := node_span (self, value.subunit_proper_body_value);
      if not Adac.Source.contains (value.span, body_span) or else
         not precedes
           (previous_last, Adac.Source.first_position (body_span)) or else
         Adac.Source.last_position (value.span) /=
           Adac.Source.last_position (body_span)
      then
        raise Program_Error with
          "Adac.AST: subunit proper body is out of source order";
      end if;
    end;
  end validate_subunit;

  procedure validate
    (self : Store;
     root : Node_ID)
  is
    previous_last : Adac.Source.Position;
    first_context : Boolean := True;
  begin
    require_compilation_unit (self, root);

    declare
      unit : Node renames self.nodes(Positive(root.index));
    begin
      Adac.Source.validate (unit.span);
      validate_node_id (self, unit.unit_item_value);

      if unit.unit_item_value.index >= root.index then
        raise Program_Error with
          "Adac.AST: compilation-unit item is not earlier";
      end if;

      case self.nodes(Positive(unit.unit_item_value.index)).kind is
        when Subunit_Node =>
          validate_subunit (self, unit.unit_item_value);
        when Procedure_Body_Node =>
          validate_procedure_body (self, unit.unit_item_value);
        when Package_Renaming_Declaration_Node =>
          validate_package_renaming_declaration (self, unit.unit_item_value);
        when Package_Instantiation_Node =>
          validate_package_instantiation (self, unit.unit_item_value);
        when Package_Declaration_Node =>
          validate_package_declaration (self, unit.unit_item_value);
        when Package_Body_Node =>
          validate_package_body (self, unit.unit_item_value);
        when others =>
          raise Program_Error with
            "Adac.AST: node is not a current unit item";
      end case;
      declare
        item_span : constant Adac.Source.Span :=
          self.nodes(Positive(unit.unit_item_value.index)).span;
      begin
        if not Adac.Source.contains (unit.span, item_span) or else
           Adac.Source.last_position (unit.span) /=
             Adac.Source.last_position (item_span)
        then
          raise Program_Error with
            "Adac.AST: unit-item span is outside compilation unit";
        end if;

        if unit.context_items.is_empty then
          if Adac.Source.first_position (unit.span) /=
             Adac.Source.first_position (item_span)
          then
            raise Program_Error with
              "Adac.AST: context-free unit span does not start at unit item";
          end if;
        else
          previous_last := Adac.Source.first_position (unit.span);
          for item of unit.context_items loop
            require_with_clause (self, item);

            if item.index >= unit.unit_item_value.index then
              raise Program_Error with
                "Adac.AST: context item does not precede unit item";
            end if;

            validate_with_clause (self, item);
            declare
              context_span : constant Adac.Source.Span :=
                self.nodes(Positive(item.index)).span;
            begin
              if not Adac.Source.contains (unit.span, context_span) then
                raise Program_Error with
                  "Adac.AST: context-item span is outside compilation unit";
              end if;

              if first_context then
                if Adac.Source.first_position (context_span) /=
                   Adac.Source.first_position (unit.span)
                then
                  raise Program_Error with
                    "Adac.AST: compilation-unit span misses first context item";
                end if;
                first_context := False;
              elsif not precedes
                (previous_last, Adac.Source.first_position (context_span))
              then
                raise Program_Error with
                  "Adac.AST: context items are out of source order";
              end if;

              previous_last := Adac.Source.last_position (context_span);
            end;
          end loop;

          if not precedes
            (previous_last, Adac.Source.first_position (item_span))
          then
            raise Program_Error with
              "Adac.AST: context clause does not precede unit item";
          end if;
        end if;
      end;
    end;
  end validate;

end Validation_Implementation;
