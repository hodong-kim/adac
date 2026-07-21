-- ============================================================================
-- adac-ast.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers;

package body Adac.AST is

  use type Ada.Containers.Count_Type;

  procedure validate_store (self : Store) is
  begin
    if not self.initialized then
      raise Program_Error with "Adac.AST: store is not initialized";
    end if;
  end validate_store;

  procedure validate_node_id
    (self : Store;
     node : Node_ID)
  is
  begin
    validate_store (self);
    validate (node);

    if node.owner /= self.marker'Unchecked_Access then
      raise Program_Error with "Adac.AST: node belongs to another store";
    end if;

    if node.index > Natural(self.nodes.length) then
      raise Program_Error with "Adac.AST: node identifier is out of range";
    end if;
  end validate_node_id;

  function next_node_id (self : Store) return Node_ID is
  begin
    if self.nodes.length >= Ada.Containers.Count_Type(Positive'Last) then
      raise Storage_Error with "Adac.AST: node capacity exhausted";
    end if;

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.nodes.length) + 1);
  end next_node_id;

  procedure require_compilation_unit
    (self : Store;
     unit : Node_ID)
  is
  begin
    validate_node_id (self, unit);

    if self.nodes(Positive(unit.index)).kind /= Compilation_Unit_Node then
      raise Program_Error with "Adac.AST: node is not a compilation unit";
    end if;
  end require_compilation_unit;

  function create return Store is
  begin
    return result : Store do
      result.initialized := True;
    end return;
  end create;

  procedure append
    (self : in out Node_List;
     node : Node_ID)
  is
  begin
    validate (node);
    self.nodes.append (node);
  end append;

  function list_count (self : Node_List) return Natural is
  begin
    return Natural(self.nodes.length);
  end list_count;

  function list_element
    (self  : Node_List;
     index : Positive)
  return Node_ID is
  begin
    if index > Natural(self.nodes.length) then
      raise Program_Error with "Adac.AST: node list index is out of range";
    end if;

    return self.nodes(index);
  end list_element;

  function append_statement
    (self : in out Store;
     kind : Node_Kind;
     span : Adac.Source.Span)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);

    Adac.Source.validate (span);
    result := next_node_id (self);

    case kind is
      when Null_Statement_Node =>
        self.nodes.append
          (Node'(kind => Null_Statement_Node, span => span));

      when Return_Statement_Node =>
        self.nodes.append
          (Node'(kind => Return_Statement_Node, span => span));

      when Compilation_Unit_Node =>
        raise Program_Error with "Adac.AST: invalid statement node kind";
    end case;

    return result;
  end append_statement;

  function append_compilation_unit
    (self             : in out Store;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     statements       : Node_List;
     end_symbol       : Adac.Symbols.Symbol_ID;
     span             : Adac.Source.Span)
  return Node_ID is
    result : Node_ID;
  begin
    validate_store (self);
    Adac.Symbols.validate (procedure_symbol);
    Adac.Symbols.validate (end_symbol);
    Adac.Source.validate (span);

    if statements.nodes.is_empty then
      raise Program_Error with "Adac.AST: statement list is empty";
    end if;

    for statement of statements.nodes loop
      validate_node_id (self, statement);

      if self.nodes(Positive(statement.index)).kind = Compilation_Unit_Node then
        raise Program_Error with
          "Adac.AST: compilation unit used as a statement";
      end if;

      if not Adac.Source.contains
        (span, self.nodes(Positive(statement.index)).span)
      then
        raise Program_Error with
          "Adac.AST: statement span is outside compilation unit";
      end if;
    end loop;

    result := next_node_id (self);
    self.nodes.append
      (Node'(kind             => Compilation_Unit_Node,
             span             => span,
             procedure_symbol => procedure_symbol,
             statements       => statements.nodes,
             end_symbol       => end_symbol));
    return result;
  end append_compilation_unit;

  function node_count (self : Store) return Natural is
  begin
    validate_store (self);
    return Natural(self.nodes.length);
  end node_count;

  function kind_of
    (self : Store;
     node : Node_ID)
  return Node_Kind is
  begin
    validate_node_id (self, node);
    return self.nodes(Positive(node.index)).kind;
  end kind_of;

  function node_span
    (self : Store;
     node : Node_ID)
  return Adac.Source.Span is
  begin
    validate_node_id (self, node);
    return self.nodes(Positive(node.index)).span;
  end node_span;

  function procedure_symbol
    (self : Store;
     unit : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_compilation_unit (self, unit);
    return self.nodes(Positive(unit.index)).procedure_symbol;
  end procedure_symbol;

  function end_symbol
    (self : Store;
     unit : Node_ID)
  return Adac.Symbols.Symbol_ID is
  begin
    require_compilation_unit (self, unit);
    return self.nodes(Positive(unit.index)).end_symbol;
  end end_symbol;

  function statement_count
    (self : Store;
     unit : Node_ID)
  return Natural is
  begin
    require_compilation_unit (self, unit);
    return Natural(self.nodes(Positive(unit.index)).statements.length);
  end statement_count;

  function statement_at
    (self  : Store;
     unit  : Node_ID;
     index : Positive)
  return Node_ID is
  begin
    require_compilation_unit (self, unit);

    if index > Natural(self.nodes(Positive(unit.index)).statements.length) then
      raise Program_Error with "Adac.AST: statement index is out of range";
    end if;

    return self.nodes(Positive(unit.index)).statements(index);
  end statement_at;

  procedure validate (node : Node_ID) is
  begin
    if node.owner = null or else node.index = 0 then
      raise Program_Error with "Adac.AST: invalid node identifier";
    end if;
  end validate;

  procedure validate
    (self : Store;
     root : Node_ID)
  is
  begin
    require_compilation_unit (self, root);

    declare
      unit : Node renames self.nodes(Positive(root.index));
    begin
      Adac.Symbols.validate (unit.procedure_symbol);
      Adac.Symbols.validate (unit.end_symbol);
      Adac.Source.validate (unit.span);

      if unit.statements.is_empty then
        raise Program_Error with "Adac.AST: statement list is empty";
      end if;

      for statement of unit.statements loop
        validate_node_id (self, statement);

        if self.nodes(Positive(statement.index)).kind =
           Compilation_Unit_Node
        then
          raise Program_Error with
            "Adac.AST: compilation unit used as a statement";
        end if;

        Adac.Source.validate (self.nodes(Positive(statement.index)).span);

        if not Adac.Source.contains
          (unit.span, self.nodes(Positive(statement.index)).span)
        then
          raise Program_Error with
            "Adac.AST: statement span is outside compilation unit";
        end if;
      end loop;
    end;
  end validate;

end Adac.AST;
