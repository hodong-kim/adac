-- ============================================================================
-- adac-semantics-testing.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.Semantics.Testing is

  function append_procedure_unchecked
    (self        : in out Store;
     declaration : Adac.AST.Node_ID;
     symbol      : Adac.Symbols.Symbol_ID;
     span        : Adac.Source.Span)
  return Entity_ID is
  begin
    self.entities.append
      (Entity_Record'
         (kind                    => Procedure_Body_Entity,
          declaration             => declaration,
          symbol                  => symbol,
          span                    => span,
          semantic_type           => Adac.Types.INVALID_TYPE_ID,
          has_integer_initializer => False,
          integer_initializer     => 0,
          has_boolean_initializer => False,
          boolean_initializer     => Adac.Types.False_Boolean_Value,
          constraint_value        => NO_SUBTYPE_CONSTRAINT,
          first_scope_binding     => 0,
          scope_binding_count     => 0,
          first_local_relation    => 0,
          local_count             => 0,
          first_statement         => 0,
          statement_count         => 0,
          first_boolean_expression_value => 0,
          boolean_expression_value_count => 0));

    return (owner => self.marker'Unchecked_Access,
            index => Natural(self.entities.length));
  end append_procedure_unchecked;

end Adac.Semantics.Testing;
