-- ============================================================================
-- adac_internal_tests.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

with Adac.AST;
with Adac.Compilation;
with Adac.Compilation.Diagnostics;
with Adac.Compilation.Semantics;
with Adac.Compilation.Semantics.Testing;
with Adac.Compilation.Sources;
with Adac.Compilation.Symbols;
with Adac.Compilation.Syntax;
with Adac.Compilation.Syntax.Testing;
with Adac.Frontend;
with Adac.IR;
with Adac.IR.Builder;
with Adac.Language;
with Adac.Resources;
with Adac.Sema;
with Adac.Semantics;
with Adac.Source;
with Adac.Symbols;

procedure adac_internal_tests is

  use type Adac.Source.Source_File_ID;
  use type Adac.Source.Position;
  use type Adac.Source.Span;
  use type Adac.Symbols.Symbol_ID;
  use type Adac.AST.Node_ID;
  use type Adac.AST.Node_Kind;
  use type Adac.Frontend.Parse_Status;
  use type Adac.Sema.Analysis_Status;
  use type Adac.Semantics.Entity_Kind;

  function new_context
    (case_sensitive_identifiers : Boolean := False;
     resource_limits : Adac.Resources.Limits :=
       Adac.Resources.DEFAULT_LIMITS)
  return Adac.Compilation.Context
  is
    options : constant Adac.Language.Options :=
      (case_sensitive_identifiers => case_sensitive_identifiers);
  begin
    return Adac.Compilation.create (options, resource_limits);
  end new_context;

  procedure require
    (condition : Boolean;
     message   : String)
  is
  begin
    if not condition then
      raise Program_Error with message;
    end if;
  end require;

  function create_minimal_unit
    (context        : in out Adac.Compilation.Context;
     procedure_name : String;
     end_name       : String;
     unit_span      : Adac.Source.Span;
     statement_span : Adac.Source.Span)
  return Adac.AST.Node_ID is
    statements : Adac.AST.Node_List;
  begin
    Adac.AST.append
      (statements,
       Adac.Compilation.Syntax.create_statement
         (context, Adac.AST.Null_Statement_Node, statement_span));

    return Adac.Compilation.Syntax.create_compilation_unit
      (context,
       Adac.Compilation.Symbols.intern (context, procedure_name),
       statements,
       Adac.Compilation.Symbols.intern (context, end_name),
       unit_span);
  end create_minimal_unit;

  function create_unchecked_unit
    (context          : in out Adac.Compilation.Context;
     procedure_symbol : Adac.Symbols.Symbol_ID;
     end_symbol       : Adac.Symbols.Symbol_ID;
     unit_span        : Adac.Source.Span;
     statement_span   : Adac.Source.Span;
     has_statement    : Boolean := True)
  return Adac.AST.Node_ID is
    statements : Adac.AST.Node_List;
  begin
    if has_statement then
      Adac.AST.append
        (statements,
         Adac.Compilation.Syntax.Testing.create_statement_unchecked
           (context, Adac.AST.Null_Statement_Node, statement_span));
    end if;

    return Adac.Compilation.Syntax.Testing.create_compilation_unit_unchecked
      (context,
       procedure_symbol,
       statements,
       end_symbol,
       unit_span);
  end create_unchecked_unit;

  function accepts_language_options
    (context : Adac.Compilation.Context) return Boolean
  is
  begin
    declare
      options : constant Adac.Language.Options :=
        Adac.Compilation.language_options (context);
      pragma unreferenced (options);
    begin
      null;
    end;

    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_language_options;

  function accepts_diagnostic_write
    (context : in out Adac.Compilation.Context) return Boolean
  is
  begin
    Adac.Compilation.Diagnostics.error (context, "uninitialized context");
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_diagnostic_write;

  function accepts_source_registration
    (context : in out Adac.Compilation.Context) return Boolean
  is
    file_id : Adac.Source.Source_File_ID;
  begin
    file_id := Adac.Compilation.Sources.register_file
      (context, "uninitialized.adb");
    return file_id /= Adac.Source.INVALID_SOURCE_FILE_ID;
  exception
    when Program_Error =>
      return False;
  end accepts_source_registration;

  function accepts_symbol_interning
    (context  : in out Adac.Compilation.Context;
     spelling : String)
  return Boolean is
    symbol : Adac.Symbols.Symbol_ID;
  begin
    symbol := Adac.Compilation.Symbols.intern (context, spelling);
    return symbol /= Adac.Symbols.INVALID_SYMBOL_ID;
  exception
    when Program_Error =>
      return False;
  end accepts_symbol_interning;

  function rejects_new_symbol_at_limit
    (context  : in out Adac.Compilation.Context;
     spelling : String)
  return Boolean
  is
  begin
    declare
      symbol : constant Adac.Symbols.Symbol_ID :=
        Adac.Compilation.Symbols.intern (context, spelling);
      pragma unreferenced (symbol);
    begin
      null;
    end;

    return False;
  exception
    when Adac.Resources.Limit_Exceeded =>
      return True;
  end rejects_new_symbol_at_limit;

  function accepts_ast_query
    (context : Adac.Compilation.Context) return Boolean
  is
    count : Natural;
    pragma unreferenced (count);
  begin
    count := Adac.Compilation.Syntax.node_count (context);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_ast_query;

  function accepts_semantic_query
    (context : Adac.Compilation.Context) return Boolean
  is
    count : Natural;
    pragma unreferenced (count);
  begin
    count := Adac.Compilation.Semantics.entity_count (context);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_semantic_query;

  function rejects_invalid_statement_before_limit
    (context : in out Adac.Compilation.Context;
     span    : Adac.Source.Span)
  return Boolean
  is
    node : Adac.AST.Node_ID;
    pragma unreferenced (node);
  begin
    node := Adac.Compilation.Syntax.create_statement
      (context, Adac.AST.Compilation_Unit_Node, span);
    return False;
  exception
    when Program_Error =>
      return True;

    when Adac.Resources.Limit_Exceeded =>
      return False;
  end rejects_invalid_statement_before_limit;

  function rejects_empty_unit_before_limit
    (context : in out Adac.Compilation.Context;
     symbol  : Adac.Symbols.Symbol_ID;
     span    : Adac.Source.Span)
  return Boolean
  is
    statements : Adac.AST.Node_List;
    node       : Adac.AST.Node_ID;
    pragma unreferenced (node);
  begin
    node := Adac.Compilation.Syntax.create_compilation_unit
      (context, symbol, statements, symbol, span);
    return False;
  exception
    when Program_Error =>
      return True;

    when Adac.Resources.Limit_Exceeded =>
      return False;
  end rejects_empty_unit_before_limit;

  function accepts_symbol
    (context : Adac.Compilation.Context;
     symbol  : Adac.Symbols.Symbol_ID)
  return Boolean is
  begin
    Adac.Compilation.Symbols.validate_symbol (context, symbol);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_symbol;

  function accepts_file_id
    (context : Adac.Compilation.Context;
     file_id : Adac.Source.Source_File_ID)
  return Boolean is
  begin
    declare
      path : constant String
           := Adac.Compilation.Sources.file_path (context, file_id);
      pragma unreferenced (path);
    begin
      return True;
    end;
  exception
    when Program_Error =>
      return False;
  end accepts_file_id;

  function accepts_span
    (first : Adac.Source.Position;
     last  : Adac.Source.Position)
  return Boolean is
  begin
    declare
      span : constant Adac.Source.Span :=
        Adac.Source.make_span (first, last);
      pragma unreferenced (span);
    begin
      null;
    end;

    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_span;

  function accepts_span
    (context : Adac.Compilation.Context;
     value   : Adac.Source.Span)
  return Boolean is
  begin
    Adac.Compilation.Sources.validate_span (context, value);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_span;

  function accepts_unit
    (context : Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Boolean
  is
  begin
    Adac.Compilation.Syntax.validate (context, root);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_unit;

  function accepts_analysis
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Boolean is
    result : Adac.Sema.Analysis_Result;
    pragma unreferenced (result);
  begin
    result := Adac.Sema.analyze (context, root);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_analysis;

  function analyze_entity
    (context : in out Adac.Compilation.Context;
     root    : Adac.AST.Node_ID)
  return Adac.Semantics.Entity_ID
  is
    result : constant Adac.Sema.Analysis_Result :=
      Adac.Sema.analyze (context, root);
  begin
    case result.status is
      when Adac.Sema.Analysis_Rejected =>
        raise Program_Error with
          "adac_internal_tests: expected semantic success";

      when Adac.Sema.Analysis_Succeeded =>
        return result.entity;
    end case;
  end analyze_entity;

  function accepts_lowering
    (context : Adac.Compilation.Context;
     entity  : Adac.Semantics.Entity_ID)
  return Boolean
  is
    module : Adac.IR.Module;
    pragma unreferenced (module);
  begin
    module := Adac.IR.Builder.build (context, entity);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_lowering;

  function accepts_module (module : Adac.IR.Module) return Boolean is
  begin
    Adac.IR.validate (module);
    return True;
  exception
    when Program_Error =>
      return False;
  end accepts_module;

  context_a : Adac.Compilation.Context := new_context;
  context_b : Adac.Compilation.Context := new_context;

begin
  declare
    uninitialized : Adac.Compilation.Context;
  begin
    require
      (not accepts_language_options (uninitialized),
       "default-initialized context exposed language options");
    require
      (not accepts_diagnostic_write (uninitialized),
       "default-initialized context accepted a diagnostic");
    require
      (not accepts_source_registration (uninitialized),
       "default-initialized context accepted a source path");
    require
      (not accepts_symbol_interning (uninitialized, "main"),
       "default-initialized context accepted a symbol");
    require
      (not accepts_ast_query (uninitialized),
       "default-initialized context exposed AST storage");
    require
      (not accepts_semantic_query (uninitialized),
       "default-initialized context exposed semantic storage");
  end;

  require
    (Adac.Compilation.Diagnostics.error_count (context_a) = 0,
     "context A did not start with zero diagnostics");
  require
    (Adac.Compilation.Diagnostics.error_count (context_b) = 0,
     "context B did not start with zero diagnostics");
  require
    (Adac.Compilation.resource_limits
       (context_a).maximum_source_characters_per_file =
     Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
     "context A did not receive the default source character limit");
  require
    (Adac.Compilation.resource_limits (context_a).maximum_symbols =
     Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
     "context A did not receive the default symbol limit");
  require
    (Adac.Compilation.resource_limits (context_a).maximum_ast_nodes =
     Adac.Resources.DEFAULT_MAXIMUM_AST_NODES,
     "context A did not receive the default AST node limit");

  Adac.Compilation.Diagnostics.error (context_a, "context A first error");

  require
    (Adac.Compilation.Diagnostics.error_count (context_a) = 1,
     "context A did not record its first diagnostic");
  require
    (Adac.Compilation.Diagnostics.error_count (context_b) = 0,
     "context A diagnostic leaked into context B");

  Adac.Compilation.Diagnostics.error (context_a, "context A second error");
  Adac.Compilation.Diagnostics.error (context_b, "context B error");

  require
    (Adac.Compilation.Diagnostics.error_count (context_a) = 2,
     "context A diagnostic count is incorrect");
  require
    (Adac.Compilation.Diagnostics.error_count (context_b) = 1,
     "context B diagnostic count is incorrect");
  require
    (Adac.Compilation.Diagnostics.has_error (context_a),
     "context A did not report an error state");
  require
    (Adac.Compilation.Diagnostics.has_error (context_b),
     "context B did not report an error state");

  require
    (Adac.Compilation.Sources.file_count (context_a) = 0,
     "context A did not start with an empty source registry");
  require
    (Adac.Compilation.Sources.file_count (context_b) = 0,
     "context B did not start with an empty source registry");

  declare
    source_a : constant Adac.Source.Source_File_ID
             := Adac.Compilation.Sources.register_file
                  (context_a, "alpha.adb");
    source_a_again : constant Adac.Source.Source_File_ID
                   := Adac.Compilation.Sources.register_file
                        (context_a, "alpha.adb");
    source_a_second : constant Adac.Source.Source_File_ID
                    := Adac.Compilation.Sources.register_file
                         (context_a, "second.adb");
    source_b : constant Adac.Source.Source_File_ID
             := Adac.Compilation.Sources.register_file
                  (context_b, "alpha.adb");
    position : constant Adac.Source.Position
             := Adac.Source.make_position (source_a, 7, 9);
    last_position : constant Adac.Source.Position
                  := Adac.Source.make_position (source_a, 8, 2);
    foreign_position : constant Adac.Source.Position
                     := Adac.Source.make_position (source_b, 8, 2);
    span : constant Adac.Source.Span :=
      Adac.Source.make_span (position, last_position);
  begin
    require
      (source_a = source_a_again,
       "duplicate source path received a different identifier");
    require
      (source_a /= source_a_second,
       "different source paths received the same identifier");
    require
      (Adac.Compilation.Sources.file_count (context_a) = 2,
       "context A source file count is incorrect");
    require
      (Adac.Compilation.Sources.file_count (context_b) = 1,
       "context B source file count is incorrect");
    require
      (source_a /= source_b,
       "different contexts received the same source identifier");
    require
      (Adac.Compilation.Sources.file_path (context_a, source_a) =
       "alpha.adb",
       "context A source path lookup failed");
    require
      (Adac.Compilation.Sources.file_path (context_b, source_b) =
       "alpha.adb",
       "context B source path lookup failed");
    require
      (Adac.Compilation.Sources.position_image (context_a, position) =
       "alpha.adb:7:9",
       "source position image is incorrect");
    require
      (not accepts_file_id (context_b, source_a),
       "context B accepted a source identifier owned by context A");
    require
      (not accepts_file_id
         (context_a, Adac.Source.INVALID_SOURCE_FILE_ID),
       "context A accepted the invalid source identifier");
    require
      (Adac.Source.first_position (span) = position and then
       Adac.Source.last_position (span) = last_position,
       "source span endpoints changed during construction");
    require
      (accepts_span (context_a, span),
       "source registry rejected its own span");
    require
      (not accepts_span (context_b, span),
       "source registry accepted a foreign span");
    require
      (not accepts_span (last_position, position),
       "source span accepted reversed endpoints");
    require
      (not accepts_span (position, foreign_position),
       "source span accepted endpoints from different files");
  end;

  declare
    symbol_a : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context_a, "Main");
    symbol_a_again : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context_a, "main");
    symbol_b : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context_b, "main");
  begin
    require
      (symbol_a = symbol_a_again,
       "case-insensitive context assigned different symbol IDs");
    require
      (symbol_a /= symbol_b,
       "different contexts assigned the same owned symbol ID");
    require
      (Adac.Compilation.Symbols.spelling (context_a, symbol_a) = "Main",
       "symbol store did not preserve the first spelling");
    require
      (Adac.Compilation.Symbols.symbol_count (context_a) = 1,
       "case-insensitive symbol store retained a duplicate");
    require
      (not accepts_symbol (context_b, symbol_a),
       "symbol store accepted a foreign symbol identifier");
    require
      (not accepts_symbol_interning (context_a, ""),
       "symbol store accepted an empty spelling");
  end;

  declare
    context : Adac.Compilation.Context := new_context (True);
    upper   : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Main");
    lower   : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "main");
  begin
    require
      (upper /= lower,
       "case-sensitive context merged distinct symbol spellings");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 2,
       "case-sensitive symbol count is incorrect");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_symbols   => 1,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    first     : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Main");
    duplicate : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "main");
  begin
    require
      (first = duplicate,
       "full symbol budget rejected an existing canonical spelling");
    require
      (rejects_new_symbol_at_limit (context, "other"),
       "full symbol budget accepted a distinct spelling");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "rejected symbol insertion changed the symbol store");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_symbols   => 0,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "zero symbol limit did not reject the first identifier");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "zero symbol limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 0,
       "zero symbol limit published a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "zero symbol limit published an AST node");
  end;

  declare
    context_c : constant Adac.Compilation.Context := new_context;
  begin
    require
      (Adac.Compilation.Diagnostics.error_count (context_c) = 0,
       "new context inherited diagnostics from an earlier context");
    require
      (not Adac.Compilation.Diagnostics.has_error (context_c),
       "new context started in an error state");
    require
      (Adac.Compilation.Sources.file_count (context_c) = 0,
       "new context inherited source files from an earlier context");
    require
      (Adac.Compilation.Semantics.entity_count (context_c) = 0,
       "new context inherited semantic entities from an earlier context");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file => 0,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "zero source character limit did not reject a nonempty file");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "zero source character limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 0,
       "zero source character limit published a symbol");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "zero source character limit published an AST node");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file => 20,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/line-comments/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "small source character limit did not reject a long line");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "small source character limit did not record one diagnostic");
    require
      (Adac.Compilation.Symbols.symbol_count (context) = 1,
       "small source character limit published unexpected symbols");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "small source character limit published an AST node");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file => 41,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "exact source character limit rejected the minimal file");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "exact source character limit recorded a diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 2,
       "exact source character limit changed AST publication");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 0));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "zero AST node limit did not reject parsing");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "zero AST node limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "zero AST node limit published a statement node");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 0));
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (context, "limit-contract.adb");
    span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 1, 1));
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "main");
  begin
    require
      (rejects_invalid_statement_before_limit (context, span),
       "AST limit hid an invalid statement kind");
    require
      (rejects_empty_unit_before_limit (context, symbol, span),
       "AST limit hid an empty compilation unit");
    require
      (Adac.Compilation.Syntax.node_count (context) = 0,
       "contract rejection published a node at zero AST limit");
  end;

  declare
    context : Adac.Compilation.Context :=
      new_context
        (resource_limits =>
           (maximum_source_characters_per_file =>
              Adac.Resources.DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
            maximum_symbols   => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => 1));
    result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Rejected,
       "one-node AST limit did not reject the unit root");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "one-node AST limit did not record one diagnostic");
    require
      (Adac.Compilation.Syntax.node_count (context) = 1,
       "one-node AST limit changed the store after root rejection");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "matching.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    root : constant Adac.AST.Node_ID :=
      create_minimal_unit
        (context, "Main", "main", unit_span, statement_span);
    analysis : constant Adac.Sema.Analysis_Result :=
      Adac.Sema.analyze (context, root);
  begin
    require
      (analysis.status = Adac.Sema.Analysis_Succeeded,
       "semantic analysis rejected matching Ada identifiers");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 0,
       "successful semantic analysis recorded a diagnostic");

    case analysis.status is
      when Adac.Sema.Analysis_Rejected =>
        null;

      when Adac.Sema.Analysis_Succeeded =>
        require
          (Adac.Compilation.Semantics.entity_count (context) = 1,
           "successful semantic analysis did not publish one entity");
        require
          (Adac.Compilation.Semantics.kind_of
             (context, analysis.entity) =
           Adac.Semantics.Procedure_Body_Entity,
           "semantic analysis published the wrong entity kind");
        require
          (Adac.Compilation.Semantics.declaration
             (context, analysis.entity) = root,
           "semantic entity refers to the wrong AST declaration");
        require
          (Adac.Compilation.Semantics.symbol (context, analysis.entity) =
           Adac.Compilation.Syntax.procedure_symbol (context, root),
           "semantic entity stores the wrong symbol");
        require
          (Adac.Compilation.Semantics.entity_span
             (context, analysis.entity) = unit_span,
           "semantic entity stores the wrong source span");
        require
          (accepts_lowering (context, analysis.entity),
           "IR builder rejected a valid semantic entity");
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context (True);
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "case-sensitive.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    root : constant Adac.AST.Node_ID :=
      create_minimal_unit
        (context, "Main", "main", unit_span, statement_span);
    analysis : constant Adac.Sema.Analysis_Result :=
      Adac.Sema.analyze (context, root);
  begin
    require
      (analysis.status = Adac.Sema.Analysis_Rejected,
       "semantic analysis accepted mismatched case-sensitive identifiers");
    require
      (Adac.Compilation.Diagnostics.error_count (context) = 1,
       "rejected semantic analysis did not record one diagnostic");
    require
      (Adac.Compilation.Semantics.entity_count (context) = 0,
       "rejected semantic analysis published an entity");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file (context, "ast-validation.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    outside_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 5, 1),
       Adac.Source.make_position (file_id, 5, 5));
    symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "main");
    valid_root : constant Adac.AST.Node_ID :=
      create_minimal_unit
        (context, "main", "main", unit_span, statement_span);
    invalid_procedure : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (context,
         Adac.Symbols.INVALID_SYMBOL_ID,
         symbol,
         unit_span,
         statement_span);
    invalid_end : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (context,
         symbol,
         Adac.Symbols.INVALID_SYMBOL_ID,
         unit_span,
         statement_span);
    empty_body : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (context,
         symbol,
         symbol,
         unit_span,
         statement_span,
         has_statement => False);
    invalid_span : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (context,
         symbol,
         symbol,
         Adac.Source.INVALID_SPAN,
         statement_span);
    outside_child : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (context, symbol, symbol, unit_span, outside_span);
  begin
    declare
      statements   : Adac.AST.Node_List;
      before_count : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
    begin
      begin
        declare
          root : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_compilation_unit
              (context, symbol, statements, symbol, unit_span);
          pragma unreferenced (root);
        begin
          null;
        end;
      exception
        when Program_Error =>
          rejected := True;
      end;

      require
        (rejected,
         "AST constructor accepted an empty statement list");
      require
        (Adac.Compilation.Syntax.node_count (context) = before_count,
         "rejected AST construction published a partial node");
    end;

    require
      (accepts_unit (context, valid_root),
       "AST validator rejected a valid minimal compilation unit");
    require
      (not accepts_unit (context, invalid_procedure),
       "AST validator accepted an invalid procedure symbol");
    require
      (not accepts_unit (context, invalid_end),
       "AST validator accepted an invalid end symbol");
    require
      (not accepts_unit (context, empty_body),
       "AST validator accepted an empty statement list");
    require
      (not accepts_unit (context, invalid_span),
       "AST validator accepted an invalid unit span");
    require
      (not accepts_unit (context, outside_child),
       "AST validator accepted a statement outside its unit span");
    require
      (not accepts_unit (context, Adac.AST.INVALID_NODE_ID),
       "AST validator accepted the invalid node identifier");
  end;

  declare
    owner_context   : Adac.Compilation.Context := new_context;
    foreign_context : Adac.Compilation.Context := new_context;
    file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (owner_context, "foreign-span.adb");
    unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 1, 1),
       Adac.Source.make_position (file_id, 4, 9));
    statement_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (file_id, 3, 3),
       Adac.Source.make_position (file_id, 3, 7));
    foreign_file_id : constant Adac.Source.Source_File_ID :=
      Adac.Compilation.Sources.register_file
        (foreign_context, "foreign-context.adb");
    foreign_unit_span : constant Adac.Source.Span := Adac.Source.make_span
      (Adac.Source.make_position (foreign_file_id, 1, 1),
       Adac.Source.make_position (foreign_file_id, 4, 9));
    foreign_statement_span : constant Adac.Source.Span :=
      Adac.Source.make_span
        (Adac.Source.make_position (foreign_file_id, 3, 3),
         Adac.Source.make_position (foreign_file_id, 3, 7));
    owner_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (owner_context, "main");
    foreign_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (foreign_context, "main");
    owner_root : constant Adac.AST.Node_ID :=
      create_minimal_unit
        (owner_context, "main", "main", unit_span, statement_span);
    foreign_root : constant Adac.AST.Node_ID :=
      create_minimal_unit
        (foreign_context,
         "main",
         "main",
         foreign_unit_span,
         foreign_statement_span);
    foreign_symbol_root : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (foreign_context,
         owner_symbol,
         owner_symbol,
         foreign_unit_span,
         foreign_statement_span);
    foreign_span_root : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (foreign_context,
         foreign_symbol,
         foreign_symbol,
         unit_span,
         statement_span);
    owner_entity : constant Adac.Semantics.Entity_ID :=
      analyze_entity (owner_context, owner_root);
    foreign_declaration_entity : constant Adac.Semantics.Entity_ID :=
      Adac.Compilation.Semantics.Testing.create_procedure_unchecked
        (foreign_context,
         owner_root,
         foreign_symbol,
         foreign_unit_span);
    foreign_symbol_entity : constant Adac.Semantics.Entity_ID :=
      Adac.Compilation.Semantics.Testing.create_procedure_unchecked
        (foreign_context,
         foreign_root,
         owner_symbol,
         foreign_unit_span);
    foreign_span_entity : constant Adac.Semantics.Entity_ID :=
      Adac.Compilation.Semantics.Testing.create_procedure_unchecked
        (foreign_context,
         foreign_root,
         foreign_symbol,
         unit_span);
    other_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (foreign_context, "other");
    mismatched_symbol_entity : constant Adac.Semantics.Entity_ID :=
      Adac.Compilation.Semantics.Testing.create_procedure_unchecked
        (foreign_context,
         foreign_root,
         other_symbol,
         foreign_unit_span);
    mismatched_span_entity : constant Adac.Semantics.Entity_ID :=
      Adac.Compilation.Semantics.Testing.create_procedure_unchecked
        (foreign_context,
         foreign_root,
         foreign_symbol,
         foreign_statement_span);
    invalid_ast_entity : constant Adac.Semantics.Entity_ID :=
      Adac.Compilation.Semantics.Testing.create_procedure_unchecked
        (foreign_context,
         foreign_span_root,
         foreign_symbol,
         foreign_unit_span);
  begin
    require
      (owner_root /= foreign_symbol_root,
       "different AST stores produced the same node identity");
    require
      (not accepts_analysis (foreign_context, owner_root),
       "semantic analysis accepted a foreign node identifier");
    require
      (not accepts_analysis (foreign_context, foreign_symbol_root),
       "semantic analysis accepted a foreign symbol");
    require
      (not accepts_analysis (foreign_context, foreign_span_root),
       "semantic analysis accepted a foreign source span");
    require
      (not accepts_lowering (foreign_context, owner_entity),
       "IR builder accepted a foreign entity identifier");
    require
      (not accepts_lowering
         (foreign_context, foreign_declaration_entity),
       "IR builder accepted a foreign entity declaration");
    require
      (not accepts_lowering (foreign_context, foreign_symbol_entity),
       "IR builder accepted a foreign entity symbol");
    require
      (not accepts_lowering (foreign_context, foreign_span_entity),
       "IR builder accepted a foreign entity span");
    require
      (not accepts_lowering
         (foreign_context, mismatched_symbol_entity),
       "IR builder accepted a mismatched entity symbol");
    require
      (not accepts_lowering (foreign_context, mismatched_span_entity),
       "IR builder accepted a mismatched entity span");
    require
      (not accepts_lowering (foreign_context, invalid_ast_entity),
       "IR builder accepted an entity with an invalid AST");
    require
      (not accepts_lowering
         (foreign_context, Adac.Semantics.INVALID_ENTITY_ID),
       "IR builder accepted the invalid entity identifier");
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/minimal/input.adb");
  begin
    require
      (result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected the valid minimal compilation unit");

    case result.status is
      when Adac.Frontend.Parse_Rejected =>
        raise Program_Error with "successful parse has no AST payload";

      when Adac.Frontend.Parse_Succeeded =>
        require
          (Adac.Compilation.Symbols.spelling
             (context,
              Adac.Compilation.Syntax.procedure_symbol
                (context, result.root)) =
           "main",
           "successful parse returned the wrong AST payload");
        require
          (Adac.Compilation.Syntax.node_count (context) = 2,
           "minimal parse did not create exactly two AST nodes");
        require
          (Adac.Compilation.Syntax.kind_of (context, result.root) =
           Adac.AST.Compilation_Unit_Node,
           "successful parse returned a non-unit root node");
        require
          (Adac.Compilation.Syntax.statement_count
             (context, result.root) = 1,
           "minimal parse returned the wrong statement count");

        declare
          unit_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, result.root);
          statement : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.statement_at
              (context, result.root, 1);
          statement_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, statement);
          unit_first : constant Adac.Source.Position :=
            Adac.Source.first_position (unit_span);
          unit_last : constant Adac.Source.Position :=
            Adac.Source.last_position (unit_span);
          statement_first : constant Adac.Source.Position :=
            Adac.Source.first_position (statement_span);
          statement_last : constant Adac.Source.Position :=
            Adac.Source.last_position (statement_span);
        begin
          require
            (Adac.Compilation.Syntax.kind_of (context, statement) =
             Adac.AST.Null_Statement_Node,
             "minimal parse returned the wrong statement kind");
          require
            (unit_first.line = 1 and then unit_first.column = 1 and then
             unit_last.line = 4 and then unit_last.column = 9,
             "parser returned the wrong compilation-unit span");
          require
            (statement_first.line = 3 and then
             statement_first.column = 3 and then
             statement_last.line = 3 and then
             statement_last.column = 7,
             "parser returned the wrong statement span");
        end;
    end case;
  end;

  declare
    valid_module : Adac.IR.Module;
    empty_name   : Adac.IR.Module;
    empty_code   : Adac.IR.Module;
  begin
    valid_module.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");
    valid_module.instructions.append
      (Adac.IR.Instruction'(kind => Adac.IR.Null_Instruction));

    empty_name.instructions.append
      (Adac.IR.Instruction'(kind => Adac.IR.Null_Instruction));

    empty_code.entry_name :=
      Ada.Strings.Unbounded.to_unbounded_string ("main");

    require
      (accepts_module (valid_module),
       "IR validator rejected a valid minimal module");
    require
      (not accepts_module (empty_name),
       "IR validator accepted an empty entry name");
    require
      (not accepts_module (empty_code),
       "IR validator accepted an empty instruction list");
  end;

end adac_internal_tests;
