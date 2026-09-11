-- ============================================================================
-- adac-frontend-parser-parse_package_declaration_staging.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac.Frontend.Parser)
procedure parse_package_declaration_staging
  (self        : in out Parser;
   context     : in out Adac.Compilation.Context;
   first       : Adac.Source.Position;
   require_eof : Boolean;
   declaration : out Adac.AST.Node_ID;
   span        : out Adac.Source.Span)
is
  use type Adac.Source.Position;

  type Package_Frame is record
    first                : Adac.Source.Position;
    parsed_defining_name : Parsed_Program_Unit_Name;
    parsed_end_name      : Parsed_Program_Unit_Name;
    defining_name        : Adac.AST.Program_Unit_Name;
    end_name             : Adac.AST.Program_Unit_Name;
    visible_declarations : Adac.AST.Node_List;
    private_part_span    : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    private_declarations : Adac.AST.Node_List;
    in_private_part      : Boolean := False;
  end record;

  function same_frame (left, right : Package_Frame) return Boolean is
    (left.first = right.first);

  package Package_Frame_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Package_Frame,
     "="          => same_frame);

  frames : Package_Frame_Vectors.Vector;

  procedure reject_package (message : String) is
  begin
    self.failed := True;
    Adac.Compilation.Diagnostics.error
      (context, self.current.position, message);
  end reject_package;

  procedure append_to_current_part (item : Adac.AST.Node_ID) is
    current : constant Package_Frame_Vectors.Reference_Type :=
      frames.reference (frames.last_index);
  begin
    if item = Adac.AST.INVALID_NODE_ID then
      raise Program_Error with "package declaration lost represented syntax";
    end if;

    if current.in_private_part then
      Adac.AST.append (current.private_declarations, item);
    else
      Adac.AST.append (current.visible_declarations, item);
    end if;
  end append_to_current_part;

  procedure parse_package_renaming_tail
    (package_first        : Adac.Source.Position;
     parsed_defining_name : Parsed_Program_Unit_Name;
     require_item_eof     : Boolean;
     item                 : out Adac.AST.Node_ID;
     item_span            : out Adac.Source.Span)
  is
    defining_name   : Adac.AST.Program_Unit_Name;
    renamed_package : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    last            : Adac.Source.Position := self.current.position;
  begin
    item := Adac.AST.INVALID_NODE_ID;
    item_span := Adac.Source.INVALID_SPAN;

    publish_program_unit_name
      (self, context, parsed_defining_name, defining_name);
    if self.failed then
      return;
    end if;

    expect (self, context, Tok_Renames);
    if self.failed then
      return;
    end if;

    if self.current.kind /= Tok_Identifier and then
       self.current.kind /= Tok_Invalid_Identifier
    then
      reject_package
        ("renamed package names outside current name subset are not supported");
      return;
    end if;

    parse_selected_identifier_name_staging
      (self,
       context,
       publish_syntax => True,
       syntax_node    => renamed_package);
    if self.failed then
      return;
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
      item :=
        Adac.Compilation.Syntax.create_package_renaming_declaration
          (context, defining_name, renamed_package, item_span);
      Adac.Compilation.Syntax.validate_package_renaming_declaration
        (context, item);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        item := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, package_first, "AST node limit exceeded");
    end;
  end parse_package_renaming_tail;

  procedure parse_package_instantiation_tail
    (package_first        : Adac.Source.Position;
     parsed_defining_name : Parsed_Program_Unit_Name;
     require_item_eof     : Boolean;
     item                 : out Adac.AST.Node_ID;
     item_span            : out Adac.Source.Span)
  is
  begin
    parse_package_instantiation_tail_common
      (self,
       context,
       package_first,
       parsed_defining_name,
       require_item_eof,
       item,
       item_span);
  end parse_package_instantiation_tail;

  procedure start_item
    (package_first    : Adac.Source.Position;
     require_item_eof : Boolean;
     item             : out Adac.AST.Node_ID;
     item_span        : out Adac.Source.Span;
     started_frame    : out Boolean)
  is
    frame : Package_Frame;
  begin
    item := Adac.AST.INVALID_NODE_ID;
    item_span := Adac.Source.INVALID_SPAN;
    started_frame := False;
    frame.first := package_first;

    if self.current.kind = Tok_Body then
      reject_package
        ("package bodies are not supported in package specifications");
      return;
    end if;

    parse_program_unit_name_staging
      (self, context, frame.parsed_defining_name);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_Renames then
      parse_package_renaming_tail
        (package_first,
         frame.parsed_defining_name,
         require_item_eof,
         item,
         item_span);
      return;
    end if;

    expect (self, context, Tok_Is);
    if self.failed then
      return;
    end if;

    if self.current.kind = Tok_New then
      parse_package_instantiation_tail
        (package_first,
         frame.parsed_defining_name,
         require_item_eof,
         item,
         item_span);
      return;
    end if;

    publish_program_unit_name
      (self, context, frame.parsed_defining_name, frame.defining_name);
    if not self.failed then
      frames.append (frame);
      started_frame := True;
    end if;
  end start_item;

  procedure parse_leaf_declaration is
    item : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
  begin
    case self.current.kind is
      when Tok_Procedure =>
        parse_package_procedure_declaration_staging (self, context, item);

      when Tok_Function =>
        parse_package_function_declaration_staging (self, context, item);

      when Tok_Type =>
        parse_type_declaration_staging (self, context, item);

      when Tok_Subtype =>
        parse_subtype_declaration_staging (self, context, item);

      when Tok_Identifier | Tok_Invalid_Identifier =>
        parse_current_declaration_staging
          (self,
           context,
           declaration                 => item,
           represent_object            => True,
           represent_number            => True,
           allow_deferred_constant     => True);

      when others =>
        raise Program_Error with
          "package leaf declaration dispatch received an invalid token";
    end case;

    if not self.failed then
      append_to_current_part (item);
    end if;
  end parse_leaf_declaration;

  procedure close_current_frame is
    completed : Package_Frame := frames.last_element;
    last      : Adac.Source.Position;
    item      : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    item_span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    closing_outermost : constant Boolean :=
      frames.first_index = frames.last_index;
  begin
    parse_package_closing_staging
      (self,
       context,
       completed.parsed_end_name,
       last,
       require_eof => closing_outermost and require_eof);

    if self.failed then
      return;
    end if;

    publish_program_unit_name
      (self, context, completed.parsed_end_name, completed.end_name);

    if self.failed then
      return;
    end if;

    item_span := Adac.Source.make_span (completed.first, last);
    begin
      item :=
        Adac.Compilation.Syntax.create_package_declaration
          (context,
           completed.defining_name,
           completed.visible_declarations,
           completed.private_part_span,
           completed.private_declarations,
           completed.end_name,
           item_span);
    exception
      when Adac.Resources.Limit_Exceeded =>
        self.failed := True;
        item := Adac.AST.INVALID_NODE_ID;
        Adac.Compilation.Diagnostics.error
          (context, completed.first, "AST node limit exceeded");
    end;

    if self.failed then
      return;
    end if;

    frames.delete_last;
    if frames.is_empty then
      declaration := item;
      span := item_span;
    else
      append_to_current_part (item);
    end if;
  end close_current_frame;

begin
  declaration := Adac.AST.INVALID_NODE_ID;
  span := Adac.Source.INVALID_SPAN;
  declare
    item          : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
    item_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
    started_frame : Boolean := False;
  begin
    start_item
      (first,
       require_eof,
       item,
       item_span,
       started_frame);
    if not self.failed and then not started_frame then
      declaration := item;
      span := item_span;
    end if;
  end;

  while not self.failed and then not frames.is_empty loop
    case self.current.kind is
      when Tok_Procedure |
           Tok_Function |
           Tok_Type |
           Tok_Subtype |
           Tok_Identifier |
           Tok_Invalid_Identifier =>
        parse_leaf_declaration;

      when Tok_Package =>
        declare
          nested_first  : constant Adac.Source.Position :=
            self.current.position;
          item          : Adac.AST.Node_ID := Adac.AST.INVALID_NODE_ID;
          item_span     : Adac.Source.Span := Adac.Source.INVALID_SPAN;
          started_frame : Boolean := False;
        begin
          expect (self, context, Tok_Package);
          if not self.failed then
            start_item
              (nested_first,
               require_item_eof => False,
               item             => item,
               item_span        => item_span,
               started_frame    => started_frame);
          end if;
          if not self.failed and then not started_frame then
            append_to_current_part (item);
          end if;
        end;

      when Tok_Private =>
        declare
          current : constant Package_Frame_Vectors.Reference_Type :=
            frames.reference (frames.last_index);
        begin
          if current.in_private_part then
            reject_package ("duplicate package private part is not supported");
          else
            current.private_part_span :=
              make_token_span (self.current.position, current_text (self));
            current.in_private_part := True;
          end if;
        end;
        if not self.failed then
          expect (self, context, Tok_Private);
        end if;

      when Tok_End =>
        close_current_frame;

      when others =>
        declare
          current : constant Package_Frame_Vectors.Reference_Type :=
            frames.reference (frames.last_index);
        begin
          if current.in_private_part then
            reject_package ("package private declaration is not supported");
          else
            reject_package ("package visible declaration is not supported");
          end if;
        end;
    end case;
  end loop;
end parse_package_declaration_staging;
