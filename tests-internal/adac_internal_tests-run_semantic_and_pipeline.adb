-- ============================================================================
-- adac_internal_tests-run_semantic_and_pipeline.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

separate (Adac_Internal_Tests)
procedure Run_Semantic_And_Pipeline is
  use type Adac.IR.Boolean_Binary_Operator_Kind;
  use type Adac.Semantics.Boolean_Binary_Operator_Kind;
  use type Adac.Semantics.Boolean_Expression_Value_Kind;
  use type Adac.Semantics.Subtype_Constraint_Kind;
  use type Adac.Types.Boolean_Value;
  use type Adac.Types.Universal_Real_Value;
begin
  declare
    context : Adac.Compilation.Context := new_context;
    foreign_context : Adac.Compilation.Context := new_context;
    scope : Adac.Semantics.Lexical_Scope;
    first_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Value");
    equivalent_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "VALUE");
    absent_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (context, "Other");
    foreign_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (foreign_context, "Value");
    inserted : Boolean;
    rejected_foreign : Boolean := False;
  begin
    Adac.Compilation.Semantics.try_bind_local_object
      (context, scope, first_symbol, 1, inserted);
    require (inserted, "lexical scope rejected its first local binding");
    require
      (Adac.Semantics.scope_binding_count (scope) = 1 and then
       Adac.Semantics.scope_binding_symbol_at (scope, 1) = first_symbol and then
       Adac.Semantics.scope_binding_local_at (scope, 1) = 1,
       "lexical scope lost source-order binding metadata");
    require
      (Adac.Compilation.Semantics.resolve_local_object
         (context, scope, equivalent_symbol) = 1,
       "lexical scope lost case-insensitive symbol lookup");

    Adac.Compilation.Semantics.try_bind_local_object
      (context, scope, equivalent_symbol, 2, inserted);
    require
      (not inserted and then Adac.Semantics.scope_binding_count (scope) = 1,
       "duplicate lexical binding mutated the scope");
    require
      (Adac.Compilation.Semantics.resolve_local_object
         (context, scope, absent_symbol) = 0,
       "lexical scope resolved an absent symbol");

    begin
      declare
        local : constant Natural :=
          Adac.Compilation.Semantics.resolve_local_object
            (context, scope, foreign_symbol);
        pragma unreferenced (local);
      begin
        null;
      end;
    exception
      when Program_Error =>
        rejected_foreign := True;
    end;
    require
      (rejected_foreign,
       "lexical scope accepted a symbol from another compilation context");
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
             (context, analysis.entity) =
           Adac.Compilation.Syntax.library_item (context, root),
           "semantic entity refers to the wrong procedure-body declaration");
        require
          (Adac.Compilation.Semantics.symbol (context, analysis.entity) =
           Adac.Compilation.Syntax.procedure_symbol
             (context, Adac.Compilation.Syntax.library_item (context, root)),
           "semantic entity stores the wrong symbol");
        require
          (Adac.Compilation.Semantics.entity_span
             (context, analysis.entity) = unit_span,
           "semantic entity stores the wrong source span");
        require
          (Adac.Compilation.Semantics.procedure_scope_binding_count
             (context, analysis.entity) = 0,
           "empty procedure published lexical bindings");
        require
          (accepts_lowering (context, analysis.entity),
           "IR builder rejected a valid semantic entity");
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/pipeline/local-integer-variable/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected the local Integer integration fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected a local Integer variable");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                local : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 1);
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.entity_count (context) = 2,
                   "local Integer analysis published the wrong entity count");
                require
                  (Adac.Compilation.Semantics.procedure_local_count
                     (context, analysis.entity) = 1,
                   "procedure did not own exactly one local object");
                require
                  (Adac.Compilation.Semantics.kind_of (context, local) =
                   Adac.Semantics.Object_Entity,
                   "procedure local has the wrong entity kind");
                require
                  (Adac.Compilation.Semantics.object_type (context, local) =
                   Adac.Compilation.Types.standard_integer (context),
                   "local object has the wrong semantic type");
                require
                  (not Adac.Compilation.Semantics.object_has_integer_initializer
                     (context, local),
                   "uninitialized local object gained an initializer");
                require
                  (Natural (module.locals.length) = 1,
                   "IR builder did not preserve the local object");
                require
                  (Ada.Strings.Unbounded.to_string (module.locals (1).name) =
                   "value",
                   "IR builder changed the local object name");
                require
                  (module.locals (1).value_type =
                   Adac.IR.Signed_Integer_32_Type,
                   "IR builder lowered local Integer to the wrong type");
              end;
          end case;
        end;
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/pipeline/local-integer-initializer/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected the local Integer initializer fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected a local Integer initializer");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                local : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 1);
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.object_has_integer_initializer
                     (context, local),
                   "initialized local object lost its initializer");
                require
                  (Adac.Compilation.Semantics.object_integer_initializer
                     (context, local) = 1,
                   "initialized local object stored the wrong value");
                require
                  (Adac.Compilation.Semantics.object_type (context, local) =
                   Adac.Compilation.Types.standard_integer (context),
                   "initialized local object stored the wrong type");
                require
                  (Natural (module.values.length) = 1,
                   "initializer lowering published the wrong value count");
                require
                  (Natural (module.instructions.length) = 2,
                   "initializer lowering has the wrong instruction count");
                require
                  (module.instructions (1).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (1).target_local = 1 and then
                   module.instructions (1).value = Adac.IR.Value_ID (1),
                   "initializer store was not first in procedure IR");
                require
                  (module.instructions (2).kind = Adac.IR.Null_Instruction,
                   "initializer store did not precede the procedure body");
              end;
          end case;
        end;
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/pipeline/" &
                  "local-integer-initialization-order/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected ordered local Integer initializers");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected ordered local initializers");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                first_local : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 1);
                second_local : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 2);
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.object_integer_initializer
                     (context, first_local) = 1 and then
                   Adac.Compilation.Semantics.object_integer_initializer
                     (context, second_local) = 2,
                   "initializer values lost declaration order");
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 1,
                   "initializers became procedure body statements");
                require
                  (Natural (module.values.length) = 3 and then
                   Natural (module.instructions.length) = 3,
                   "ordered initializer lowering has the wrong IR size");
                require
                  (module.instructions (1).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (1).target_local = 1 and then
                   module.instructions (1).value = Adac.IR.Value_ID (1) and then
                   module.instructions (2).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (2).target_local = 2 and then
                   module.instructions (2).value = Adac.IR.Value_ID (2) and then
                   module.instructions (3).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (3).target_local = 1 and then
                   module.instructions (3).value = Adac.IR.Value_ID (3),
                   "initializer/body stores are not in elaboration order");
              end;
          end case;
        end;
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/pipeline/local-integer-assignment/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected the local Integer assignment fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected a local Integer assignment");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                procedure_node : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.library_item
                    (context, parse_result.root);
                statement : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Syntax.statement_at
                    (context, procedure_node, 1);
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 1,
                   "assignment procedure has the wrong statement count");
                require
                  (Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                   Adac.Semantics.Local_Integer_Static_Assignment_Statement,
                   "assignment procedure stored the wrong statement kind");
                require
                  (Adac.Compilation.Semantics.procedure_statement_syntax
                     (context, analysis.entity, 1) = statement,
                   "assignment semantic statement lost canonical syntax");
                require
                  (Adac.Compilation.Semantics.assignment_target_local
                     (context, analysis.entity, 1) = 1,
                   "assignment bound the wrong local object");
                require
                  (Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 1) =
                   Adac.Compilation.Types.standard_integer (context),
                   "assignment stored the wrong expected type");
                require
                  (Adac.Compilation.Semantics.assignment_integer_value
                     (context, analysis.entity, 1) = 1,
                   "assignment stored the wrong integer value");
                require
                  (Natural (module.values.length) = 1,
                   "IR builder did not publish one assignment value");
                require
                  (module.values (1).kind =
                     Adac.IR.Integer_Constant_Value and then
                   module.values (1).value_type =
                     Adac.IR.Signed_Integer_32_Type and then
                   module.values (1).integer_value = 1,
                   "IR builder lowered the wrong integer constant");
                require
                  (Natural (module.instructions.length) = 1,
                   "IR builder emitted the wrong assignment instruction count");
                require
                  (module.instructions (1).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (1).target_local = 1 and then
                   module.instructions (1).value = Adac.IR.Value_ID (1),
                   "IR builder lowered the wrong local store");
              end;
          end case;
        end;
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/pipeline/local-integer-copy-initialized/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected an initialized local Integer copy");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected an initialized local copy");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                   Adac.Semantics.Local_Integer_Copy_Assignment_Statement,
                   "initialized copy stored the wrong statement kind");
                require
                  (Adac.Compilation.Semantics.assignment_target_local
                     (context, analysis.entity, 1) = 2 and then
                   Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 1) = 1,
                   "initialized copy bound the wrong local objects");
                require
                  (Adac.Compilation.Semantics.
                     assignment_source_definition_statement
                       (context, analysis.entity, 1) = 0,
                   "initialized copy lost initializer provenance");
                require
                  (Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 1) =
                   Adac.Compilation.Types.standard_integer (context),
                   "initialized copy stored the wrong expected type");
                require
                  (Natural (module.values.length) = 2 and then
                   module.values (2).kind = Adac.IR.Local_Load_Value and then
                   module.values (2).value_type =
                     Adac.IR.Signed_Integer_32_Type and then
                   module.values (2).source_local = 1,
                   "initialized copy lowered the wrong local-load value");
                require
                  (Natural (module.instructions.length) = 2 and then
                   module.instructions (2).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (2).target_local = 2 and then
                   module.instructions (2).value = Adac.IR.Value_ID (2),
                   "initialized copy lowered the wrong local store");
              end;
          end case;
        end;
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/pipeline/" &
                  "local-integer-copy-after-assignment/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected a local copy after assignment");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected a copy after assignment");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              require
                (Adac.Compilation.Semantics.procedure_statement_count
                   (context, analysis.entity) = 2,
                 "copy-after-assignment stored the wrong statement count");
              require
                (Adac.Compilation.Semantics.procedure_statement_kind_at
                   (context, analysis.entity, 1) =
                 Adac.Semantics.
                   Local_Integer_Static_Assignment_Statement and then
                 Adac.Compilation.Semantics.procedure_statement_kind_at
                   (context, analysis.entity, 2) =
                 Adac.Semantics.Local_Integer_Copy_Assignment_Statement,
                 "copy-after-assignment stored the wrong statement kinds");
              require
                (Adac.Compilation.Semantics.assignment_source_local
                   (context, analysis.entity, 2) = 1 and then
                 Adac.Compilation.Semantics.
                   assignment_source_definition_statement
                     (context, analysis.entity, 2) = 1,
                 "copy-after-assignment lost source provenance");
          end case;
        end;
    end case;
  end;

  require_semantic_rejection_without_entities
    ("tests/semantics/sema-assignment-undeclared/input.adb",
     "undeclared assignment target");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-assignment-unsupported-target/input.adb",
     "unsupported assignment target");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-assignment-type-mismatch/input.adb",
     "assignment type mismatch");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-assignment-out-of-range/input.adb",
     "out-of-range assignment literal");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-static-assignment-zero-divisor/input.adb",
     "static assignment zero divisor");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-assignment-undeclared-source/input.adb",
     "undeclared assignment source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-assignment-unsupported-source/input.adb",
     "unsupported assignment source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-assignment-uninitialized-source/input.adb",
     "uninitialized assignment source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-copy-uninitialized/input.adb",
     "uninitialized mutable Boolean local copy");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-copy-type-mismatch/input.adb",
     "mismatched mutable Boolean local copy");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-not-uninitialized/input.adb",
     "uninitialized mutable Boolean runtime not");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-not-type-mismatch/input.adb",
     "mismatched mutable Boolean runtime not");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-binary-uninitialized/input.adb",
     "uninitialized mutable Boolean binary logical source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-binary-type-mismatch/input.adb",
     "mismatched mutable Boolean binary logical source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-equality-uninitialized/input.adb",
     "uninitialized mutable Boolean equality source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-equality-type-mismatch/input.adb",
     "mismatched mutable Boolean equality source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-ordering-uninitialized/input.adb",
     "uninitialized mutable Boolean ordering source");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-boolean-ordering-type-mismatch/input.adb",
     "mismatched mutable Boolean ordering source");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-boolean-expression-uninitialized/input.adb",
     "uninitialized nested Boolean expression source");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-boolean-expression-type-mismatch/input.adb",
     "mismatched nested Boolean expression source");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-boolean-runtime-short-circuit/input.adb",
     "mixed runtime/static Boolean short-circuit expression");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-boolean-short-circuit-uninitialized/input.adb",
     "uninitialized direct Boolean short-circuit source");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-boolean-short-circuit-type-mismatch/input.adb",
     "mismatched direct Boolean short-circuit source");

  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-duplicate/input.adb",
     "duplicate local declaration");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-static-constant-assignment-target/input.adb",
     "static constant assignment target");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-constant-use-before-declaration/input.adb",
     "static constant use before declaration");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-constant-shadows-predefined-subtype/input.adb",
     "static constant shadows predefined subtype");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-static-constant-shadows-standard/input.adb",
     "static constant shadows Standard");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-assignment-target/input.adb",
     "static Boolean constant assignment target");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-use-before-declaration/input.adb",
     "static Boolean constant use before declaration");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-shadows-literal/input.adb",
     "static Boolean constant shadows predefined literal");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-shadows-subtype/input.adb",
     "static Boolean constant shadows predefined subtype");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-shadows-standard/input.adb",
     "static Boolean constant shadows Standard");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-duplicate/input.adb",
     "duplicate static Boolean constant");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-unsupported-initializer/input.adb",
     "static Boolean constant unsupported initializer");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-not-nonboolean/input.adb",
     "static Boolean not non-Boolean operand");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-logical-nonboolean/input.adb",
     "static Boolean logical non-Boolean operand");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-short-circuit/input.adb",
     "static Boolean skipped and-then RHS must be static");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-short-circuit-or/input.adb",
     "static Boolean skipped or-else RHS must be static");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-equality-nonboolean/input.adb",
     "static Boolean equality non-Boolean operand");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-static-boolean-constant-ordering-nonboolean/input.adb",
     "static Boolean ordering non-Boolean operand");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-real-number-compound-unsupported/input.adb",
     "compound real named number outside direct-literal subset");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-real-number-resource-limit/input.adb",
     "real named number resource limit");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-real-number-zero-divisor/input.adb",
     "real named number zero divisor");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-real-number-arithmetic-resource-limit/input.adb",
     "real named number arithmetic resource limit");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-real-number-assignment-target/input.adb",
     "real named number assignment target");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-real-number-assignment-source-mismatch/input.adb",
     "real named number assignment source type mismatch");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-real-number-shadows-predefined-subtype/input.adb",
     "real named number shadows predefined subtype");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-real-number-shadows-standard/input.adb",
     "real named number shadows Standard");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-real-number-duplicate/input.adb",
     "duplicate real named number");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-integer-number-use-before-declaration/input.adb",
     "integer named number use before declaration");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-integer-number-out-of-envelope/input.adb",
     "integer named number outside host envelope");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-integer-number-assignment-target/input.adb",
     "integer named number assignment target");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-integer-number-shadows-predefined-subtype/input.adb",
     "integer named number shadows predefined subtype");

  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-unsupported-selected-subtype/input.adb",
     "unsupported selected local subtype");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-standard-shadowed-subtype/input.adb",
     "shadowed Standard selected subtype");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-use-before-declaration/input.adb",
     "local subtype use before declaration");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-initializer-out-of-range/input.adb",
     "constrained subtype initializer out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-positive-out-of-range/input.adb",
     "predefined Positive initializer out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-assignment-out-of-range/input.adb",
     "constrained subtype assignment out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-copy-out-of-range/input.adb",
     "constrained subtype copy out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-child-outside-parent/input.adb",
     "child subtype outside parent range");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-nonliteral-bound/input.adb",
     "nonliteral constrained subtype bound");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-unsupported-attribute/input.adb",
     "unsupported constrained subtype attribute");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-subtype-unsupported-expanded-attribute/input.adb",
     "unsupported expanded constrained subtype attribute");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-subtype-static-expression-out-of-range/input.adb",
     "static constrained subtype expression out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-subtype-multiplication-out-of-range/input.adb",
     "static constrained subtype multiplication out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-parenthesized-overflow/input.adb",
     "parenthesized static constrained subtype overflow");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-unary-out-of-range/input.adb",
     "unary static constrained subtype overflow");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-abs-out-of-range/input.adb",
     "absolute static constrained subtype overflow");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-exponentiation-out-of-range/input.adb",
     "static constrained subtype exponentiation out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-subtype-exponentiation-unsupported-exponent/input.adb",
     "unsupported static constrained subtype exponent expression");
  require_semantic_rejection_without_entities
    ("tests/semantics/" &
       "sema-local-subtype-exponentiation-negative-exponent/input.adb",
     "negative static constrained subtype exponent expression");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-division-by-zero/input.adb",
     "static constrained subtype division by zero");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-rem-by-zero/input.adb",
     "static constrained subtype remainder by zero");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-mod-by-zero/input.adb",
     "static constrained subtype modulus by zero");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-subtype-duplicate-object/input.adb",
     "duplicate subtype/object declaration");

  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-initializer-type-mismatch/input.adb",
     "local initializer type mismatch");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-initializer-out-of-range/input.adb",
     "out-of-range local initializer");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-static-initializer-out-of-range/input.adb",
     "static local initializer out of range");
  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-unsupported-initializer/input.adb",
     "unsupported local initializer");

  require_semantic_rejection_without_entities
    ("tests/semantics/sema-local-initializer-invalid-based/input.adb",
     "invalid based local initializer");

  declare
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context, "tests/pipeline/local-integer-variables/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected consecutive local Integer variables");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected consecutive Integer variables");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              require
                (Adac.Compilation.Semantics.entity_count (context) = 3,
                 "two local Integers published the wrong entity count");
              require
                (Adac.Compilation.Semantics.procedure_local_count
                   (context, analysis.entity) = 2,
                 "procedure did not own both local objects");
              declare
                first_local : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 1);
                second_local : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 2);
                first_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Semantics.symbol (context, first_local);
                second_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Semantics.symbol (context, second_local);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_count
                     (context, analysis.entity) = 2,
                   "procedure lexical scope lost local binding count");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_symbol_at
                     (context, analysis.entity, 1) = first_symbol and then
                   Adac.Compilation.Semantics.procedure_scope_binding_local_at
                     (context, analysis.entity, 1) = 1 and then
                   Adac.Compilation.Semantics.procedure_scope_binding_symbol_at
                     (context, analysis.entity, 2) = second_symbol and then
                   Adac.Compilation.Semantics.procedure_scope_binding_local_at
                     (context, analysis.entity, 2) = 2,
                   "procedure lexical scope lost source-order bindings");
                require
                  (Adac.Compilation.Semantics.procedure_local_for_symbol
                     (context, analysis.entity, first_symbol) = 1 and then
                   Adac.Compilation.Semantics.procedure_local_for_symbol
                     (context, analysis.entity, second_symbol) = 2,
                   "procedure lexical scope lookup disagrees with local order");
                require
                  (Adac.Compilation.Semantics.procedure_local_for_symbol
                     (context,
                      analysis.entity,
                      Adac.Compilation.Symbols.intern (context, "FIRST")) = 1,
                   "stored lexical scope lost case-insensitive lookup");
                require
                  (Adac.Compilation.Semantics.procedure_local_for_symbol
                     (context,
                      analysis.entity,
                      Adac.Compilation.Semantics.symbol
                        (context, analysis.entity)) = 0,
                   "procedure symbol became a local lexical binding");
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-subtype-variable/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected local subtype declaration");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected local subtype declaration");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                procedure_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics.declaration
                    (context, analysis.entity);
                count_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_subtype_declaration_at
                      (context, analysis.entity, 1);
                more_count_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_subtype_declaration_at
                      (context, analysis.entity, 2);
                count_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Syntax.subtype_declaration_symbol
                    (context, count_declaration);
                more_count_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Syntax.subtype_declaration_symbol
                    (context, more_count_declaration);
                count_type : constant Adac.Types.Type_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_subtype_type_at
                      (context, analysis.entity, 1);
                more_count_type : constant Adac.Types.Type_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_subtype_type_at
                      (context, analysis.entity, 2);
                local : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 1);
                local_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Semantics.symbol (context, local);
              begin
                require
                  (Adac.Compilation.Semantics.entity_count (context) = 2
                   and then Adac.Compilation.Types.type_count (context) = 6,
                   "local subtype created extra semantic identity");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_count
                     (context, analysis.entity) = 3 and then
                   Adac.Compilation.Semantics.procedure_local_count
                     (context, analysis.entity) = 1,
                   "local subtype changed object ownership counts");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Local_Subtype_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Subtype_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Local_Object_Binding,
                   "lexical scope lost subtype/object source order");
                require
                  (count_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context, procedure_declaration, 1) and then
                   more_count_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context, procedure_declaration, 2) and then
                   count_type =
                     Adac.Compilation.Types.standard_integer (context) and then
                   more_count_type = count_type,
                   "local subtype chain lost declaration or type");
                require
                  (Adac.Compilation.Semantics.procedure_subtype_for_symbol
                     (context, analysis.entity, count_symbol) = count_type
                   and then
                   Adac.Compilation.Semantics.procedure_subtype_for_symbol
                     (context, analysis.entity, more_count_symbol) =
                     count_type and then
                   Adac.Compilation.Semantics.procedure_subtype_for_symbol
                     (context,
                      analysis.entity,
                      Adac.Compilation.Symbols.intern (context, "MORE_COUNT")) =
                     count_type,
                   "stored subtype lookup lost chained or folded name");
                require
                  (Adac.Compilation.Semantics.procedure_local_for_symbol
                     (context, analysis.entity, count_symbol) = 0 and then
                   Adac.Compilation.Semantics.procedure_local_for_symbol
                     (context, analysis.entity, more_count_symbol) = 0,
                   "subtype symbol became an object binding");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_local_at
                     (context, analysis.entity, 3) = 1 and then
                   Adac.Compilation.Semantics.procedure_scope_binding_symbol_at
                     (context, analysis.entity, 3) = local_symbol and then
                   Adac.Compilation.Semantics.object_type (context, local) =
                     count_type,
                   "object binding lost local subtype resolution");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
                require
                  (accepts_lowering (context, analysis.entity),
                   "IR builder rejected object using local subtype");
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-constrained-subtype-variable/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected constrained local subtype pipeline fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected constrained local subtype");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                small_constraint : constant Adac.Semantics.Subtype_Constraint :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_subtype_constraint_at
                      (context, analysis.entity, 1);
                tiny_constraint : constant Adac.Semantics.Subtype_Constraint :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_subtype_constraint_at
                      (context, analysis.entity, 2);
                inherited_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 3);
                negative_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 4);
                natural_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 5);
                positive_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 6);
                full_integer_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 7);
                almost_positive_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 8);
                tiny_attribute_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 9);
                absolute_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 10);
                powered_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 11);
                power_zero_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 12);
                power_grouped_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 13);
                power_attribute_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 14);
                step_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 15);
                offset_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 16);
                step_constraint : constant Adac.Semantics.Subtype_Constraint :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_constraint_at
                      (context, analysis.entity, 15);
                offset_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_constraint_at
                      (context, analysis.entity, 16);
                max_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_integer_number_declaration_at
                      (context, analysis.entity, 17);
                max_line_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_integer_number_declaration_at
                      (context, analysis.entity, 18);
                power_16_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_integer_number_declaration_at
                      (context, analysis.entity, 19);
                wide_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_integer_number_declaration_at
                      (context, analysis.entity, 21);
                wide_reduced_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_integer_number_declaration_at
                      (context, analysis.entity, 22);
                number_bounded_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                    Adac.Compilation.Semantics
                      .procedure_scope_binding_subtype_constraint_at
                        (context, analysis.entity, 23);
                small_symbol : constant Adac.Symbols.Symbol_ID :=
                  Adac.Compilation.Semantics.procedure_scope_binding_symbol_at
                    (context, analysis.entity, 1);
                source : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 1);
                target : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 2);
                source_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                  Adac.Compilation.Semantics.object_subtype_constraint
                    (context, source);
                target_constraint : constant
                  Adac.Semantics.Subtype_Constraint :=
                  Adac.Compilation.Semantics.object_subtype_constraint
                    (context, target);
                decimal_real_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_real_number_declaration_at
                      (context, analysis.entity, 27);
                based_real_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_real_number_declaration_at
                      (context, analysis.entity, 28);
                real_positive_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_real_number_declaration_at
                      (context, analysis.entity, 36);
                real_div_integer_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_real_number_declaration_at
                      (context, analysis.entity, 39);
                ready_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 44);
                stopped_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 45);
                ready_copy_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 46);
                stopped_copy_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 47);
                not_ready_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 48);
                grouped_not_stopped_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 49);
                both_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 50);
                either_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 51);
                different_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 52);
                mixed_logic_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 53);
                short_and_skip_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 54);
                short_and_read_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 55);
                short_or_skip_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 56);
                short_or_read_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 57);
                equal_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 58);
                not_equal_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 59);
                equality_logic_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 60);
                equality_short_skip_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 61);
                equality_short_read_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 62);
                less_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 63);
                less_equal_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 64);
                greater_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 65);
                greater_equal_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 66);
                ordering_logic_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 67);
                ordering_short_skip_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 68);
                ordering_short_read_declaration : constant Adac.AST.Node_ID :=
                  Adac.Compilation.Semantics
                    .procedure_scope_binding_static_constant_declaration_at
                      (context, analysis.entity, 69);
                expected_decimal_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("5", "4", 1_024);
                expected_based_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("4095", "1", 1_024);
                expected_two_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("2", "1", 1_024);
                expected_three_halves_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("3", "2", 1_024);
                expected_negative_two_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("-2", "1", 1_024);
                expected_three_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("3", "1", 1_024);
                expected_five_halves_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("5", "2", 1_024);
                expected_twenty_five_sixteenths_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("25", "16", 1_024);
                expected_one_eighth_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("1", "8", 1_024);
                expected_one_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("1", "1", 1_024);
                expected_one_fourth_real : constant
                  Adac.Types.Universal_Real_Value :=
                    Adac.Types.make_universal_real_value_from_quotient
                      ("1", "4", 1_024);
              begin
                require
                  (Adac.Compilation.Semantics.entity_count (context) = 3
                   and then Adac.Compilation.Types.type_count (context) = 6,
                   "constrained subtype created runtime or type identity");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_count
                     (context, analysis.entity) = 69 and then
                   Adac.Compilation.Semantics.procedure_local_count
                     (context, analysis.entity) = 2,
                   "constrained subtype changed binding/local ownership");
                for binding_index in 27 .. 43 loop
                  require
                    (Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                       (context, analysis.entity, binding_index) =
                         Adac.Semantics.Local_Real_Number_Binding,
                     "real named number lost its lexical binding kind");
                  require
                    (Adac.Compilation.Semantics
                       .procedure_scope_binding_real_number_type_at
                         (context, analysis.entity, binding_index) =
                           Adac.Compilation.Types.universal_real (context),
                     "real named number lost universal_real identity");
                end loop;
                require
                  (decimal_real_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        27) and then
                   based_real_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        28) and then
                   real_positive_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        36) and then
                   real_div_integer_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        39),
                   "real named numbers lost source-order declarations");
                for binding_index in 44 .. 69 loop
                  require
                    (Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                       (context, analysis.entity, binding_index) =
                         Adac.Semantics.Local_Static_Boolean_Constant_Binding,
                     "Boolean constants lost their lexical binding kind");
                end loop;
                require
                  (ready_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        44) and then
                   stopped_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        45) and then
                   ready_copy_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        46) and then
                   stopped_copy_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        47) and then
                   not_ready_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        48) and then
                   grouped_not_stopped_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        49) and then
                   both_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        50) and then
                   either_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        51) and then
                   different_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        52) and then
                   mixed_logic_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        53) and then
                   short_and_skip_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        54) and then
                   short_and_read_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        55) and then
                   short_or_skip_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        56) and then
                   short_or_read_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        57) and then
                   equal_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        58) and then
                   not_equal_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        59) and then
                   equality_logic_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        60) and then
                   equality_short_skip_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        61) and then
                   equality_short_read_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        62) and then
                   less_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        63) and then
                   less_equal_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        64) and then
                   greater_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        65) and then
                   greater_equal_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        66) and then
                   ordering_logic_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        67) and then
                   ordering_short_skip_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        68) and then
                   ordering_short_read_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        69),
                   "Boolean constants lost source-order declarations");
                for binding_index in 44 .. 69 loop
                  require
                    (Adac.Compilation.Semantics
                       .procedure_scope_binding_static_constant_type_at
                         (context, analysis.entity, binding_index) =
                           Adac.Compilation.Types.standard_boolean (context),
                     "Boolean constant lost Standard.Boolean type identity");
                end loop;
                require
                  (Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 44) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 45) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 46) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 47) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 48) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 49) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 50) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 51) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 52) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 53) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 54) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 55) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 56) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 57) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 58) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 59) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 60) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 61) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 62) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 63) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 64) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 65) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 66) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 67) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 68) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_boolean_constant_value_at
                       (context, analysis.entity, 69) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean constants lost ordering relation values");
                require
                  (Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 27) =
                       expected_decimal_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 28) =
                         expected_based_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 29) =
                         expected_decimal_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 30) =
                         expected_two_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 31) =
                         expected_three_halves_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 32) =
                         expected_negative_two_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 33) =
                         expected_two_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 34) =
                         expected_three_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 35) =
                         expected_three_halves_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 36) =
                         expected_three_halves_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 37) =
                         expected_five_halves_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 38) =
                         expected_five_halves_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 39) =
                         expected_three_halves_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 40) =
                         expected_twenty_five_sixteenths_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 41) =
                         expected_one_eighth_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 42) =
                         expected_one_real and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_real_number_value_at
                       (context, analysis.entity, 43) =
                         expected_one_fourth_real,
                   "real named numbers lost exact compound values");
                require
                  (Adac.Semantics.subtype_constraint_category
                     (small_constraint) =
                       Adac.Semantics.Signed_Integer_Range_Constraint and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (small_constraint) = 1 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (small_constraint) = 10 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (tiny_constraint) = 2 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (tiny_constraint) = 5 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (inherited_constraint) = 2 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (inherited_constraint) = 5 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (negative_constraint) = -2147483648 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (negative_constraint) = -2 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (natural_constraint) = 0 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (natural_constraint) = 2147483647 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (positive_constraint) = 1 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (positive_constraint) = 2147483647 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (full_integer_constraint) = -2147483648 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (full_integer_constraint) = 2147483647 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (almost_positive_constraint) = 1 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (almost_positive_constraint) = 2147483646 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (tiny_attribute_constraint) = 2 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (tiny_attribute_constraint) = 5 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (absolute_constraint) = 3 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (absolute_constraint) = 5 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (powered_constraint) = 8 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (powered_constraint) = 9 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (power_zero_constraint) = 1 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (power_zero_constraint) = 8 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (power_grouped_constraint) = 4 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (power_grouped_constraint) = 8 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (power_attribute_constraint) = 1 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (power_attribute_constraint) = 4,
                   "constrained subtype lost evaluated, inherited, " &
                   "predefined, attribute, absolute-value, or power metadata");
                require
                  (Adac.Semantics.subtype_constraint_lower_bound
                     (Adac.Compilation.Semantics
                        .procedure_subtype_constraint_for_symbol
                          (context, analysis.entity, small_symbol)) = 1,
                   "stored subtype lookup lost range constraint");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 15) =
                       Adac.Semantics
                         .Local_Static_Integer_Constant_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 16) =
                       Adac.Semantics.Local_Static_Integer_Constant_Binding,
                   "static constants lost their lexical binding kind");
                require
                  (step_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        15) and then
                   offset_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        16),
                   "static constants lost source-order declarations");
                require
                  (Adac.Compilation.Semantics
                     .procedure_scope_binding_static_constant_type_at
                       (context, analysis.entity, 15) =
                       Adac.Compilation.Types.standard_integer
                         (context) and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_constant_type_at
                       (context, analysis.entity, 16) =
                       Adac.Compilation.Types.standard_integer (context),
                   "static constants changed their shared Integer type " &
                   "identity");
                require
                  (Adac.Semantics.subtype_constraint_category
                     (step_constraint) =
                     Adac.Semantics.No_Constraint and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (offset_constraint) = 2 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (offset_constraint) = 5 and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_constant_value_at
                       (context, analysis.entity, 15) = 2 and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_static_constant_value_at
                       (context, analysis.entity, 16) = 3,
                   "static constant bindings lost constraint or checked value");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 17) =
                       Adac.Semantics.Local_Integer_Number_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 18) =
                       Adac.Semantics.Local_Integer_Number_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 19) =
                       Adac.Semantics.Local_Integer_Number_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 20) =
                       Adac.Semantics.Local_Integer_Number_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 21) =
                       Adac.Semantics.Local_Integer_Number_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 22) =
                       Adac.Semantics.Local_Integer_Number_Binding,
                   "named numbers lost their lexical binding kind");
                require
                  (max_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        17) and then
                   max_line_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        18) and then
                   power_16_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        19) and then
                   wide_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        21) and then
                   wide_reduced_declaration =
                     Adac.Compilation.Syntax.declaration_at
                       (context,
                        Adac.Compilation.Syntax.library_item
                          (context, parse_result.root),
                        22),
                   "named numbers lost source-order declarations");
                require
                  (Adac.Compilation.Semantics
                     .procedure_scope_binding_integer_number_type_at
                       (context, analysis.entity, 17) =
                       Adac.Compilation.Types.universal_integer
                         (context) and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_integer_number_type_at
                       (context, analysis.entity, 18) =
                       Adac.Compilation.Types.universal_integer
                         (context) and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_integer_number_type_at
                       (context, analysis.entity, 19) =
                       Adac.Compilation.Types.universal_integer
                         (context) and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_integer_number_type_at
                       (context, analysis.entity, 20) =
                       Adac.Compilation.Types.universal_integer
                         (context) and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_integer_number_type_at
                       (context, analysis.entity, 21) =
                       Adac.Compilation.Types.universal_integer
                         (context) and then
                   Adac.Compilation.Semantics
                     .procedure_scope_binding_integer_number_type_at
                       (context, analysis.entity, 22) =
                       Adac.Compilation.Types.universal_integer (context),
                   "named numbers lost universal_integer identity");
                require
                  (Adac.Types.universal_integer_to_long_long
                     (Adac.Compilation.Semantics
                        .procedure_scope_binding_integer_number_value_at
                          (context, analysis.entity, 17)) = 500 and then
                   Adac.Types.universal_integer_to_long_long
                     (Adac.Compilation.Semantics
                        .procedure_scope_binding_integer_number_value_at
                          (context, analysis.entity, 18)) = 83 and then
                   Adac.Types.universal_integer_to_long_long
                     (Adac.Compilation.Semantics
                        .procedure_scope_binding_integer_number_value_at
                          (context, analysis.entity, 19)) = 65_536 and then
                   Adac.Types.universal_integer_to_long_long
                     (Adac.Compilation.Semantics
                        .procedure_scope_binding_integer_number_value_at
                          (context, analysis.entity, 20)) = 2 and then
                   not Adac.Types.universal_integer_fits_long_long
                     (Adac.Compilation.Semantics
                        .procedure_scope_binding_integer_number_value_at
                          (context, analysis.entity, 21)) and then
                   Adac.Types.universal_integer_decimal_digits
                     (Adac.Compilation.Semantics
                        .procedure_scope_binding_integer_number_value_at
                          (context, analysis.entity, 21)) = 31 and then
                   Adac.Types.universal_integer_to_long_long
                     (Adac.Compilation.Semantics
                        .procedure_scope_binding_integer_number_value_at
                          (context, analysis.entity, 22)) = 1,
                   "named numbers lost checked universal values");
                require
                  (Adac.Semantics.subtype_constraint_lower_bound
                     (number_bounded_constraint) = 1 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (number_bounded_constraint) = 83,
                   "named number did not feed a later subtype bound");
                require
                  (Adac.Compilation.Semantics.object_integer_initializer
                     (context, source) = 4 and then
                   Adac.Compilation.Semantics.object_integer_initializer
                     (context, target) = 2,
                   "static initializers lost their evaluated integer values");
                require
                  (Adac.Semantics.subtype_constraint_lower_bound
                     (source_constraint) = 2 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (source_constraint) = 5 and then
                   Adac.Semantics.subtype_constraint_lower_bound
                     (target_constraint) = 2 and then
                   Adac.Semantics.subtype_constraint_upper_bound
                     (target_constraint) = 5,
                   "object entities lost nominal subtype constraints");
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 4 and then
                   Adac.Compilation.Semantics.assignment_integer_value
                     (context, analysis.entity, 1) = 2 and then
                   Adac.Compilation.Semantics.assignment_integer_value
                     (context, analysis.entity, 2) = 2 and then
                   Adac.Compilation.Semantics.assignment_integer_value
                     (context, analysis.entity, 3) = 5 and then
                   Adac.Compilation.Semantics.assignment_integer_value
                     (context, analysis.entity, 4) = 4 and then
                   Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 4) = 1,
                   "constrained assignment lost checked static values");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
                require
                  (accepts_lowering (context, analysis.entity),
                   "IR builder rejected constrained subtype scalar program");
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-variable/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected mutable Boolean local fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected mutable Boolean locals");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                ready : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 1);
                stopped : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 2);
                flag : constant Adac.Semantics.Entity_ID :=
                  Adac.Compilation.Semantics.procedure_local_at
                    (context, analysis.entity, 3);
                boolean_type : constant Adac.Types.Type_ID :=
                  Adac.Compilation.Types.standard_boolean (context);
              begin
                require
                  (Adac.Compilation.Semantics.entity_count (context) = 4
                   and then
                   Adac.Compilation.Semantics.procedure_local_count
                     (context, analysis.entity) = 3 and then
                   Adac.Compilation.Semantics.procedure_scope_binding_count
                     (context, analysis.entity) = 3,
                   "mutable Boolean locals changed semantic ownership counts");
                require
                  (Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Local_Object_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Object_Binding and then
                   Adac.Compilation.Semantics.procedure_scope_binding_kind_at
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Local_Object_Binding,
                   "mutable Boolean locals lost lexical object bindings");
                require
                  (Adac.Compilation.Semantics.object_type (context, ready) =
                     boolean_type and then
                   Adac.Compilation.Semantics.object_type (context, stopped) =
                     boolean_type and then
                   Adac.Compilation.Semantics.object_type (context, flag) =
                     boolean_type,
                   "mutable Boolean locals lost Standard.Boolean type " &
                   "identity");
                require
                  (Adac.Compilation.Semantics.object_has_boolean_initializer
                     (context, ready) and then
                   Adac.Compilation.Semantics.object_has_boolean_initializer
                     (context, stopped) and then
                   not Adac.Compilation.Semantics.object_has_boolean_initializer
                     (context, flag) and then
                   not Adac.Compilation.Semantics.object_has_integer_initializer
                     (context, ready) and then
                   not Adac.Compilation.Semantics.object_has_integer_initializer
                     (context, stopped) and then
                   not Adac.Compilation.Semantics.object_has_integer_initializer
                     (context, flag),
                   "mutable Boolean initializer kind was not retained exactly");
                require
                  (Adac.Compilation.Semantics.object_boolean_initializer
                     (context, ready) = Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics.object_boolean_initializer
                     (context, stopped) = Adac.Types.False_Boolean_Value,
                   "mutable Boolean initializer value was not retained");
                require
                  (Adac.Semantics.subtype_constraint_category
                     (Adac.Compilation.Semantics.object_subtype_constraint
                        (context, ready)) = Adac.Semantics.No_Constraint
                   and then
                   Adac.Semantics.subtype_constraint_category
                     (Adac.Compilation.Semantics.object_subtype_constraint
                        (context, stopped)) = Adac.Semantics.No_Constraint
                   and then
                   Adac.Semantics.subtype_constraint_category
                     (Adac.Compilation.Semantics.object_subtype_constraint
                        (context, flag)) = Adac.Semantics.No_Constraint,
                   "mutable Boolean object acquired numeric subtype " &
                   "constraint");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
                require
                  (accepts_lowering (context, analysis.entity),
                   "IR builder rejected mutable Boolean local fixture");
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-static-assignment/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected static Boolean assignment fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected static Boolean assignment");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                boolean_type : constant Adac.Types.Type_ID :=
                  Adac.Compilation.Types.standard_boolean (context);
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 2,
                   "static Boolean assignments changed statement count");
                require
                  (Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement,
                   "static Boolean assignment lost statement kind");
                require
                  (Adac.Compilation.Semantics.assignment_target_local
                     (context, analysis.entity, 1) = 1 and then
                   Adac.Compilation.Semantics.assignment_target_local
                     (context, analysis.entity, 2) = 1 and then
                   Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 1) = boolean_type and then
                   Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 2) = boolean_type,
                   "static Boolean assignment lost target or expected type");
                require
                  (Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 1) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 2) =
                       Adac.Types.False_Boolean_Value,
                   "static Boolean assignment lost folded value");
                require
                  (Natural (module.locals.length) = 1 and then
                   Natural (module.values.length) = 2 and then
                   Natural (module.instructions.length) = 2,
                   "static Boolean assignment lowered the wrong IR size");
                require
                  (module.values (1).kind =
                     Adac.IR.Boolean_Constant_Value and then
                   module.values (1).value_type = Adac.IR.Boolean_Type and then
                   module.values (1).boolean_value and then
                   module.values (2).kind =
                     Adac.IR.Boolean_Constant_Value and then
                   module.values (2).value_type = Adac.IR.Boolean_Type and then
                   not module.values (2).boolean_value,
                   "static Boolean assignment lowered the wrong constants");
                require
                  (module.instructions (1).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (1).target_local = 1 and then
                   module.instructions (1).value = Adac.IR.Value_ID (1) and then
                   module.instructions (2).kind =
                     Adac.IR.Store_Local_Instruction and then
                   module.instructions (2).target_local = 1 and then
                   module.instructions (2).value = Adac.IR.Value_ID (2),
                   "static Boolean assignment lowered the wrong stores");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-copy/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected Boolean local-copy fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected Boolean local copies");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                boolean_type : constant Adac.Types.Type_ID :=
                  Adac.Compilation.Types.standard_boolean (context);
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 4,
                   "Boolean local-copy fixture changed statement count");
                require
                  (Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Local_Boolean_Copy_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Local_Boolean_Copy_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 4) =
                       Adac.Semantics.Local_Boolean_Copy_Assignment_Statement,
                   "Boolean local copies lost statement kinds");
                require
                  (Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 1) = boolean_type and then
                   Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 2) = boolean_type and then
                   Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 3) = boolean_type and then
                   Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 4) = boolean_type,
                   "Boolean local copies lost expected type");
                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 1) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 1) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean copy lost initializer provenance");
                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 3) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 3) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 3) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 4) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 4) = 1 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 4) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean copy lost earlier-statement provenance");
                require
                  (Natural (module.locals.length) = 3 and then
                   Natural (module.values.length) = 5 and then
                   Natural (module.instructions.length) = 5,
                   "Boolean local copies lowered the wrong IR size");
                require
                  (module.values (2).kind = Adac.IR.Local_Load_Value and then
                   module.values (2).value_type = Adac.IR.Boolean_Type and then
                   module.values (2).source_local = 1 and then
                   module.values (4).kind = Adac.IR.Local_Load_Value and then
                   module.values (4).value_type = Adac.IR.Boolean_Type and then
                   module.values (4).source_local = 1 and then
                   module.values (5).kind = Adac.IR.Local_Load_Value and then
                   module.values (5).value_type = Adac.IR.Boolean_Type and then
                   module.values (5).source_local = 2,
                   "Boolean local copies lowered the wrong source loads");
                require
                  (module.instructions (2).target_local = 2 and then
                   module.instructions (4).target_local = 3 and then
                   module.instructions (5).target_local = 3,
                   "Boolean local copies lowered the wrong target stores");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-runtime-not/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected Boolean runtime-not fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected Boolean runtime not");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                boolean_type : constant Adac.Types.Type_ID :=
                  Adac.Compilation.Types.standard_boolean (context);
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 4,
                   "Boolean runtime-not fixture changed statement count");
                require
                  (Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Local_Boolean_Not_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Local_Boolean_Not_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 4) =
                       Adac.Semantics.Local_Boolean_Not_Assignment_Statement,
                   "Boolean runtime not lost statement kinds");
                require
                  (Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 1) = boolean_type and then
                   Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 3) = boolean_type and then
                   Adac.Compilation.Semantics.assignment_expected_type
                     (context, analysis.entity, 4) = boolean_type,
                   "Boolean runtime not lost expected type");
                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 1) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 1) =
                       Adac.Types.False_Boolean_Value,
                   "Boolean runtime not lost initializer provenance");
                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 3) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 3) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 3) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 4) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 4) = 3 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 4) =
                       Adac.Types.False_Boolean_Value,
                   "Boolean runtime not lost statement provenance");
                require
                  (Natural (module.locals.length) = 2 and then
                   Natural (module.values.length) = 8 and then
                   Natural (module.instructions.length) = 5,
                   "Boolean runtime not lowered the wrong IR size");
                require
                  (module.values (2).kind = Adac.IR.Local_Load_Value and then
                   module.values (2).source_local = 1 and then
                   module.values (3).kind = Adac.IR.Boolean_Not_Value and then
                   module.values (3).value_type = Adac.IR.Boolean_Type and then
                   module.values (3).operand_value =
                     Adac.IR.Value_ID (2) and then
                   module.values (5).kind = Adac.IR.Local_Load_Value and then
                   module.values (5).source_local = 1 and then
                   module.values (6).kind = Adac.IR.Boolean_Not_Value and then
                   module.values (6).operand_value =
                     Adac.IR.Value_ID (5) and then
                   module.values (7).kind = Adac.IR.Local_Load_Value and then
                   module.values (7).source_local = 2 and then
                   module.values (8).kind = Adac.IR.Boolean_Not_Value and then
                   module.values (8).operand_value = Adac.IR.Value_ID (7),
                   "Boolean runtime not lost load/operator value graph");
                require
                  (module.instructions (2).target_local = 2 and then
                   module.instructions (2).value = Adac.IR.Value_ID (3) and then
                   module.instructions (4).target_local = 2 and then
                   module.instructions (4).value = Adac.IR.Value_ID (6) and then
                   module.instructions (5).target_local = 2 and then
                   module.instructions (5).value = Adac.IR.Value_ID (8),
                   "Boolean runtime not lowered the wrong stores");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
                Adac.IR.validate (module);
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-runtime-logical/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected Boolean runtime logical fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected Boolean runtime logical operators");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 5,
                   "Boolean runtime logical fixture changed statement count");
                require
                  (Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Local_Boolean_Binary_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Local_Boolean_Binary_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 4) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 5) =
                       Adac.Semantics.Local_Boolean_Binary_Assignment_Statement,
                   "Boolean runtime logical operators lost statement kinds");
                require
                  (Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 1) =
                       Adac.Semantics.And_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Or_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 5) =
                       Adac.Semantics.Xor_Boolean_Binary_Operator,
                   "Boolean runtime logical operators lost operator kind");
                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 1) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics.assignment_right_source_local
                     (context, analysis.entity, 1) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 1) =
                       Adac.Types.False_Boolean_Value,
                   "Boolean and lost initializer provenance or result");
                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 3) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 3) = 0 and then
                   Adac.Compilation.Semantics.assignment_right_source_local
                     (context, analysis.entity, 3) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 3) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 3) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean or lost independent provenance or result");
                require
                  (Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 5) = 4 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 5) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 5) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean xor lost earlier definitions or result");
                require
                  (Natural (module.locals.length) = 3 and then
                   Natural (module.values.length) = 13 and then
                   Natural (module.instructions.length) = 7,
                   "Boolean runtime logical operators lowered wrong IR size");
                require
                  (module.values (3).kind = Adac.IR.Local_Load_Value and then
                   module.values (3).source_local = 1 and then
                   module.values (4).kind = Adac.IR.Local_Load_Value and then
                   module.values (4).source_local = 2 and then
                   module.values (5).kind =
                     Adac.IR.Boolean_Binary_Value and then
                   module.values (5).boolean_operator =
                     Adac.IR.And_Boolean_Binary_Operator and then
                   module.values (5).operand_value =
                     Adac.IR.Value_ID (3) and then
                   module.values (5).right_operand_value =
                     Adac.IR.Value_ID (4) and then
                   module.values (9).boolean_operator =
                     Adac.IR.Or_Boolean_Binary_Operator and then
                   module.values (13).boolean_operator =
                     Adac.IR.Xor_Boolean_Binary_Operator,
                   "Boolean runtime logical operators lost IR value graph");
                require
                  (module.instructions (3).value = Adac.IR.Value_ID (5) and then
                   module.instructions (5).value = Adac.IR.Value_ID (9) and then
                   module.instructions (7).value = Adac.IR.Value_ID (13),
                   "Boolean runtime logical stores lost operator results");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
                Adac.IR.validate (module);
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-runtime-equality/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected Boolean runtime equality fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected Boolean runtime equality");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 6,
                   "Boolean runtime equality fixture changed statement count");
                require
                  (Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Equal_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Equal_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 4) =
                       Adac.Semantics.Not_Equal_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 6) =
                       Adac.Semantics.Not_Equal_Boolean_Binary_Operator,
                   "Boolean runtime equality lost operator selection");
                require
                  (Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 1) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 3) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 3) =
                       Adac.Types.False_Boolean_Value,
                   "Boolean equality lost source provenance or result");
                require
                  (Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 4) = 0 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 4) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 4) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 6) = 5 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 6) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 6) =
                       Adac.Types.False_Boolean_Value,
                   "Boolean inequality lost source provenance or result");
                require
                  (Natural (module.locals.length) = 3 and then
                   Natural (module.values.length) = 16 and then
                   Natural (module.instructions.length) = 8,
                   "Boolean runtime equality lowered wrong IR size");
                require
                  (module.values (5).kind =
                     Adac.IR.Boolean_Binary_Value and then
                   module.values (5).boolean_operator =
                     Adac.IR.Equal_Boolean_Binary_Operator and then
                   module.values (9).boolean_operator =
                     Adac.IR.Equal_Boolean_Binary_Operator and then
                   module.values (12).boolean_operator =
                     Adac.IR.Not_Equal_Boolean_Binary_Operator and then
                   module.values (16).boolean_operator =
                     Adac.IR.Not_Equal_Boolean_Binary_Operator,
                   "Boolean runtime equality lost IR operators");
                require
                  (module.values (5).operand_value = Adac.IR.Value_ID (3) and
                   then module.values (5).right_operand_value =
                     Adac.IR.Value_ID (4) and then
                   module.values (16).operand_value =
                     Adac.IR.Value_ID (14) and then
                   module.values (16).right_operand_value =
                     Adac.IR.Value_ID (15),
                   "Boolean runtime equality lost IR source graph");
                require
                  (module.instructions (3).value = Adac.IR.Value_ID (5) and
                   then module.instructions (5).value =
                     Adac.IR.Value_ID (9) and then
                   module.instructions (6).value =
                     Adac.IR.Value_ID (12) and then
                   module.instructions (8).value =
                     Adac.IR.Value_ID (16),
                   "Boolean runtime equality stores lost comparison results");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
                Adac.IR.validate (module);
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-runtime-ordering/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected Boolean runtime ordering fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected Boolean runtime ordering");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 9,
                   "Boolean runtime ordering fixture changed statement count");
                require
                  (Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 1) =
                       Adac.Semantics.Less_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 2) =
                       Adac.Semantics.
                         Less_Equal_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 3) =
                       Adac.Semantics.Greater_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 4) =
                       Adac.Semantics.Greater_Equal_Boolean_Binary_Operator and
                   then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 6) =
                       Adac.Semantics.Less_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 7) =
                       Adac.Semantics.
                         Less_Equal_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 8) =
                       Adac.Semantics.Greater_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics.assignment_boolean_operator
                     (context, analysis.entity, 9) =
                       Adac.Semantics.Greater_Equal_Boolean_Binary_Operator,
                   "Boolean runtime ordering lost operator selection");
                require
                  (Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 1) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 2) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 3) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 4) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 6) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 7) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 8) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 9) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean runtime ordering lost position-order results");
                require
                  (Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 6) = 5 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 6) = 0,
                   "Boolean runtime ordering lost definition provenance");
                require
                  (Natural (module.locals.length) = 3 and then
                   Natural (module.values.length) = 27 and then
                   Natural (module.instructions.length) = 11,
                   "Boolean runtime ordering lowered wrong IR size");
                require
                  (module.values (5).boolean_operator =
                     Adac.IR.Less_Boolean_Binary_Operator and then
                   module.values (8).boolean_operator =
                     Adac.IR.Less_Equal_Boolean_Binary_Operator and then
                   module.values (11).boolean_operator =
                     Adac.IR.Greater_Boolean_Binary_Operator and then
                   module.values (14).boolean_operator =
                     Adac.IR.Greater_Equal_Boolean_Binary_Operator and then
                   module.values (18).boolean_operator =
                     Adac.IR.Less_Boolean_Binary_Operator and then
                   module.values (21).boolean_operator =
                     Adac.IR.Less_Equal_Boolean_Binary_Operator and then
                   module.values (24).boolean_operator =
                     Adac.IR.Greater_Boolean_Binary_Operator and then
                   module.values (27).boolean_operator =
                     Adac.IR.Greater_Equal_Boolean_Binary_Operator,
                   "Boolean runtime ordering lost IR operator graph");
                require
                  (module.values (5).operand_value = Adac.IR.Value_ID (3) and
                   then module.values (5).right_operand_value =
                     Adac.IR.Value_ID (4) and then
                   module.values (27).operand_value =
                     Adac.IR.Value_ID (25) and then
                   module.values (27).right_operand_value =
                     Adac.IR.Value_ID (26),
                   "Boolean runtime ordering lost IR source graph");
                Adac.Compilation.Semantics.validate (context, analysis.entity);
                Adac.IR.validate (module);
              end;
          end case;
        end;
    end case;
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
            maximum_universal_integer_decimal_digits => 30,
            maximum_universal_real_component_decimal_digits =>
              Adac.Resources
                .DEFAULT_MAXIMUM_UNIVERSAL_REAL_COMPONENT_DECIMAL_DIGITS,
            maximum_symbols => Adac.Resources.DEFAULT_MAXIMUM_SYMBOLS,
            maximum_ast_nodes => Adac.Resources.DEFAULT_MAXIMUM_AST_NODES));
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file
        (context,
         "tests/pipeline/local-constrained-subtype-variable/input.adb");
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "small universal integer limit changed frontend parsing");
    declare
      analysis : constant Adac.Sema.Analysis_Result :=
        Adac.Sema.analyze (context, parse_result.root);
    begin
      require
        (analysis.status = Adac.Sema.Analysis_Rejected,
         "small universal integer limit did not reject wide named number");
      require
        (Adac.Compilation.Diagnostics.error_count (context) = 1,
         "small universal integer limit changed diagnostic count");
      require
        (Adac.Compilation.Semantics.entity_count (context) = 0,
         "small universal integer limit published semantic state");
    end;
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
    foreign_context : Adac.Compilation.Context := new_context;
    foreign_symbol : constant Adac.Symbols.Symbol_ID :=
      Adac.Compilation.Symbols.intern (foreign_context, "main");
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
    absent_end : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (context,
         symbol,
         Adac.Symbols.INVALID_SYMBOL_ID,
         unit_span,
         statement_span);
    invalid_end : constant Adac.AST.Node_ID :=
      create_unchecked_unit
        (context, symbol, foreign_symbol, unit_span, statement_span);
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
      parameters   : Adac.AST.Node_List;
      declarations : Adac.AST.Node_List;
      before_count : constant Natural :=
        Adac.Compilation.Syntax.node_count (context);
      rejected : Boolean := False;
    begin
      begin
        declare
          root : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.create_procedure_body
              (context,
               symbol,
               parameters,
               declarations,
               Adac.AST.INVALID_NODE_ID,
               symbol,
               unit_span);
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
         "AST constructor accepted a missing handled sequence");
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
      (accepts_unit (context, absent_end),
       "AST validator rejected an absent closing designator");
    require
      (not Adac.Compilation.Syntax.has_end_designator
         (context, Adac.Compilation.Syntax.library_item (context, absent_end)),
       "absent closing designator was not preserved");
    require
      (not accepts_unit (context, invalid_end),
       "AST validator accepted a foreign end symbol");
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
    path : constant String :=
      "tests/pipeline/local-boolean-runtime-short-circuit/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected Boolean runtime short-circuit fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected Boolean runtime short circuits");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 6 and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.
                         Local_Boolean_And_Then_Assignment_Statement and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 3) =
                       Adac.Semantics.
                         Local_Boolean_And_Then_Assignment_Statement and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 4) =
                       Adac.Semantics.
                         Local_Boolean_Or_Else_Assignment_Statement and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 5) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 6) =
                       Adac.Semantics.
                         Local_Boolean_Or_Else_Assignment_Statement,
                   "Boolean short circuits lost semantic statement kinds");

                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 1) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics.assignment_right_source_local
                     (context, analysis.entity, 1) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 1) = 0 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 1) =
                       Adac.Types.False_Boolean_Value,
                   "first Boolean and-then lost initializer provenance");

                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 3) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 3) = 2 and then
                   Adac.Compilation.Semantics.assignment_right_source_local
                     (context, analysis.entity, 3) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 3) = 0 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 3) =
                       Adac.Types.True_Boolean_Value,
                   "second Boolean and-then lost redefinition provenance");

                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 4) = 3 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 4) = 3 and then
                   Adac.Compilation.Semantics.assignment_right_source_local
                     (context, analysis.entity, 4) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 4) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 4) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean or-else lost prior short-circuit provenance");

                require
                  (Adac.Compilation.Semantics.assignment_source_local
                     (context, analysis.entity, 6) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_source_definition_statement
                       (context, analysis.entity, 6) = 5 and then
                   Adac.Compilation.Semantics.assignment_right_source_local
                     (context, analysis.entity, 6) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_right_source_definition_statement
                       (context, analysis.entity, 6) = 2 and then
                   Adac.Compilation.Semantics.assignment_boolean_value
                     (context, analysis.entity, 6) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean or-else lost fall-through source provenance");

                require
                  (Natural (module.locals.length) = 3 and then
                   Natural (module.values.length) = 16 and then
                   Natural (module.instructions.length) = 8,
                   "Boolean short circuits lowered the wrong IR size");
                require
                  (module.values (5).kind = Adac.IR.Boolean_And_Then_Value and
                   then module.values (5).operand_value = Adac.IR.Value_ID (3)
                   and then module.values (5).right_operand_value =
                     Adac.IR.Value_ID (4) and then
                   module.values (9).kind = Adac.IR.Boolean_And_Then_Value and
                   then module.values (9).operand_value = Adac.IR.Value_ID (7)
                   and then module.values (9).right_operand_value =
                     Adac.IR.Value_ID (8) and then
                   module.values (12).kind = Adac.IR.Boolean_Or_Else_Value and
                   then module.values (12).operand_value =
                     Adac.IR.Value_ID (10) and then
                   module.values (12).right_operand_value =
                     Adac.IR.Value_ID (11) and then
                   module.values (16).kind = Adac.IR.Boolean_Or_Else_Value and
                   then module.values (16).operand_value =
                     Adac.IR.Value_ID (14) and then
                   module.values (16).right_operand_value =
                     Adac.IR.Value_ID (15),
                   "Boolean short circuits lost lazy IR operands");
                require
                  (module.instructions (3).target_local = 3 and then
                   module.instructions (3).value = Adac.IR.Value_ID (5) and
                   then module.instructions (5).value = Adac.IR.Value_ID (9)
                   and then module.instructions (6).value = Adac.IR.Value_ID (12)
                   and then module.instructions (8).value = Adac.IR.Value_ID (16),
                   "Boolean short circuits lost store roots");

                Adac.Compilation.Semantics.validate (context, analysis.entity);
                Adac.IR.validate (module);
              end;
          end case;
        end;
    end case;
  end;

  declare
    path : constant String :=
      "tests/pipeline/local-boolean-runtime-expression-tree/input.adb";
    context : Adac.Compilation.Context := new_context;
    parse_result : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, path);
  begin
    require
      (parse_result.status = Adac.Frontend.Parse_Succeeded,
       "frontend rejected Boolean runtime expression-tree fixture");

    case parse_result.status is
      when Adac.Frontend.Parse_Rejected =>
        null;

      when Adac.Frontend.Parse_Succeeded =>
        declare
          analysis : constant Adac.Sema.Analysis_Result :=
            Adac.Sema.analyze (context, parse_result.root);
        begin
          require
            (analysis.status = Adac.Sema.Analysis_Succeeded,
             "semantic analysis rejected Boolean runtime expression tree");

          case analysis.status is
            when Adac.Sema.Analysis_Rejected =>
              null;

            when Adac.Sema.Analysis_Succeeded =>
              declare
                module : constant Adac.IR.Module :=
                  Adac.IR.Builder.build (context, analysis.entity);
              begin
                require
                  (Adac.Compilation.Semantics.procedure_statement_count
                     (context, analysis.entity) = 5 and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 1) =
                       Adac.Semantics.
                         Local_Boolean_Expression_Assignment_Statement and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 2) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 3) =
                       Adac.Semantics.
                         Local_Boolean_Expression_Assignment_Statement and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 4) =
                       Adac.Semantics.Local_Boolean_Static_Assignment_Statement
                   and then
                   Adac.Compilation.Semantics.procedure_statement_kind_at
                     (context, analysis.entity, 5) =
                       Adac.Semantics.
                         Local_Boolean_Expression_Assignment_Statement,
                   "Boolean expression tree lost statement kinds");

                require
                  (Adac.Compilation.Semantics
                     .assignment_boolean_expression_value_count
                       (context, analysis.entity, 1) = 6 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_value_count
                       (context, analysis.entity, 3) = 6 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_value_count
                       (context, analysis.entity, 5) = 8,
                   "Boolean expression tree retained the wrong value counts");

                require
                  (Adac.Compilation.Semantics
                     .assignment_boolean_expression_value_kind
                       (context, analysis.entity, 1, 1) =
                       Adac.Semantics.Boolean_Expression_Local_Value and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_source_local
                       (context, analysis.entity, 1, 1) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_source_definition
                       (context, analysis.entity, 1, 1) = 0 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_known_value
                       (context, analysis.entity, 1, 1) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_value_kind
                       (context, analysis.entity, 1, 2) =
                       Adac.Semantics.Boolean_Expression_Not_Value and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_operand
                       (context, analysis.entity, 1, 2) = 1,
                   "Boolean expression tree lost unary local provenance");

                require
                  (Adac.Compilation.Semantics
                     .assignment_boolean_expression_operator
                       (context, analysis.entity, 1, 5) =
                       Adac.Semantics.Xor_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_operand
                       (context, analysis.entity, 1, 5) = 3 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_right_operand
                       (context, analysis.entity, 1, 5) = 4 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_operator
                       (context, analysis.entity, 1, 6) =
                       Adac.Semantics.Or_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_known_value
                       (context, analysis.entity, 1, 6) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean expression tree lost nested logical structure");

                require
                  (Adac.Compilation.Semantics
                     .assignment_boolean_expression_source_local
                       (context, analysis.entity, 3, 1) = 4 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_source_definition
                       (context, analysis.entity, 3, 1) = 1 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_value_kind
                       (context, analysis.entity, 3, 2) =
                       Adac.Semantics.Boolean_Expression_Constant_Value and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_known_value
                       (context, analysis.entity, 3, 2) =
                       Adac.Types.True_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_operator
                       (context, analysis.entity, 3, 6) =
                       Adac.Semantics.Equal_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_known_value
                       (context, analysis.entity, 3, 6) =
                       Adac.Types.True_Boolean_Value,
                   "Boolean expression tree lost folded static subtree or " &
                   "prior expression-definition provenance");

                require
                  (Adac.Compilation.Semantics
                     .assignment_boolean_expression_source_definition
                       (context, analysis.entity, 5, 1) = 2 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_source_definition
                       (context, analysis.entity, 5, 2) = 4 and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_operator
                       (context, analysis.entity, 5, 3) =
                       Adac.Semantics.Less_Boolean_Binary_Operator and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_value_kind
                       (context, analysis.entity, 5, 7) =
                       Adac.Semantics.Boolean_Expression_Constant_Value and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_known_value
                       (context, analysis.entity, 5, 7) =
                       Adac.Types.False_Boolean_Value and then
                   Adac.Compilation.Semantics
                     .assignment_boolean_expression_operator
                       (context, analysis.entity, 5, 8) =
                       Adac.Semantics.Or_Boolean_Binary_Operator,
                   "Boolean expression tree lost ordering or static " &
                   "short-circuit folding");

                require
                  (Natural (module.locals.length) = 4 and then
                   Natural (module.values.length) = 25 and then
                   Natural (module.instructions.length) = 8,
                   "Boolean expression tree lowered the wrong IR size");
                require
                  (module.values (4).kind = Adac.IR.Local_Load_Value and then
                   module.values (4).source_local = 1 and then
                   module.values (5).kind = Adac.IR.Boolean_Not_Value and then
                   module.values (5).operand_value = Adac.IR.Value_ID (4) and
                   then module.values (8).kind =
                     Adac.IR.Boolean_Binary_Value and then
                   module.values (8).boolean_operator =
                     Adac.IR.Xor_Boolean_Binary_Operator and then
                   module.values (9).boolean_operator =
                     Adac.IR.Or_Boolean_Binary_Operator and then
                   module.values (11).kind = Adac.IR.Local_Load_Value and then
                   module.values (11).source_local = 4 and then
                   module.values (16).boolean_operator =
                     Adac.IR.Equal_Boolean_Binary_Operator and then
                   module.values (20).boolean_operator =
                     Adac.IR.Less_Boolean_Binary_Operator and then
                   module.values (25).boolean_operator =
                     Adac.IR.Or_Boolean_Binary_Operator,
                   "Boolean expression tree lost generalized IR structure");
                require
                  (module.instructions (4).target_local = 4 and then
                   module.instructions (4).value = Adac.IR.Value_ID (9) and then
                   module.instructions (6).value = Adac.IR.Value_ID (16) and
                   then module.instructions (8).value = Adac.IR.Value_ID (25),
                   "Boolean expression tree stores lost root values");

                Adac.Compilation.Semantics.validate (context, analysis.entity);
                Adac.IR.validate (module);
              end;
          end case;
        end;
    end case;
  end;

  declare
    context : Adac.Compilation.Context := new_context;
    result  : constant Adac.Frontend.Parse_Result :=
      Adac.Frontend.parse_file (context, "tests/pipeline/minimal/input.adb");
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
                (context,
                 Adac.Compilation.Syntax.library_item
                   (context, result.root))) =
           "main",
           "successful parse returned the wrong AST payload");
        require
          (Adac.Compilation.Syntax.node_count (context) = 4,
           "minimal parse did not create exactly four AST nodes");
        require
          (Adac.Compilation.Syntax.kind_of (context, result.root) =
           Adac.AST.Compilation_Unit_Node,
           "successful parse returned a non-unit root node");
        require
          (Adac.Compilation.Syntax.statement_count
             (context,
              Adac.Compilation.Syntax.library_item (context, result.root)) = 1,
           "minimal parse returned the wrong statement count");

        declare
          unit_span : constant Adac.Source.Span :=
            Adac.Compilation.Syntax.node_span (context, result.root);
          statement : constant Adac.AST.Node_ID :=
            Adac.Compilation.Syntax.statement_at
              (context,
               Adac.Compilation.Syntax.library_item (context, result.root),
               1);
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
end Run_Semantic_And_Pipeline;
