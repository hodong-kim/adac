-- ============================================================================
-- adac-resources.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Resources is

  DEFAULT_MAXIMUM_AST_NODES : constant Positive := 1_000_000;

  type Limits is record
    maximum_ast_nodes : Natural := DEFAULT_MAXIMUM_AST_NODES;
  end record;

  DEFAULT_LIMITS : constant Limits :=
    (maximum_ast_nodes => DEFAULT_MAXIMUM_AST_NODES);

  Limit_Exceeded : exception;

end Adac.Resources;
