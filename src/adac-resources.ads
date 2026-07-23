-- ============================================================================
-- adac-resources.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package Adac.Resources is

  subtype Source_Character_Limit is Natural range 0 .. Positive'Last - 1;

  DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE :
    constant Source_Character_Limit := 16_777_216;
  DEFAULT_MAXIMUM_SYMBOLS : constant Positive := 1_000_000;
  DEFAULT_MAXIMUM_AST_NODES : constant Positive := 1_000_000;

  type Limits is record
    maximum_source_characters_per_file : Source_Character_Limit :=
      DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE;
    maximum_symbols   : Natural := DEFAULT_MAXIMUM_SYMBOLS;
    maximum_ast_nodes : Natural := DEFAULT_MAXIMUM_AST_NODES;
  end record;

  DEFAULT_LIMITS : constant Limits :=
    (maximum_source_characters_per_file =>
       DEFAULT_MAXIMUM_SOURCE_CHARACTERS_PER_FILE,
     maximum_symbols   => DEFAULT_MAXIMUM_SYMBOLS,
     maximum_ast_nodes => DEFAULT_MAXIMUM_AST_NODES);

  Limit_Exceeded : exception;

end Adac.Resources;
