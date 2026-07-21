-- ============================================================================
-- adac-ast.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Containers.Vectors;

with Adac.Source;
with Adac.Symbols;

package Adac.AST is

  type Statement_Kind is
    (Null_Statement,
     Return_Statement);

  type Statement is record
    kind : Statement_Kind;
    span : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  end record;

  package Statement_Vectors is new Ada.Containers.Vectors
    (Index_Type   => Positive,
     Element_Type => Statement);

  subtype Statement_List is Statement_Vectors.Vector;

  type Compilation_Unit is record
    procedure_symbol : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    statements       : Statement_List;
    end_symbol       : Adac.Symbols.Symbol_ID := Adac.Symbols.INVALID_SYMBOL_ID;
    span             : Adac.Source.Span := Adac.Source.INVALID_SPAN;
  end record;

  --! summary
  --!   Validates one abstract syntax tree compilation unit.
  --! contract
  --!   Raises `Program_Error` when an internal AST invariant is violated.
  --!   Validation reports no source diagnostic and does not modify `value`.
  procedure validate (value : Compilation_Unit);

end Adac.AST;
