-- ============================================================================
-- adac-compilation.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.AST;
with Adac.Diagnostics;
with Adac.Language;
with Adac.Resources;
with Adac.Semantics;
with Adac.Source;
with Adac.Symbols;
with Adac.Types;

package Adac.Compilation is

  type Context is limited private;

  --! summary: Create a context for one compilation.
  --! ownership: The caller owns the returned context.
  function create
    (language_options : Adac.Language.Options;
     resource_limits  : Adac.Resources.Limits :=
       Adac.Resources.DEFAULT_LIMITS)
  return Context;

  --! summary: Return the language options owned by the context.
  function language_options
    (self : Context)
  return Adac.Language.Options;

  --! summary: Return the immutable limits owned by the context.
  function resource_limits
    (self : Context)
  return Adac.Resources.Limits;

private

  type Context is limited record
    initialized      : Boolean := False;
    ast_store        : Adac.AST.Store;
    options          : Adac.Language.Options;
    limits           : Adac.Resources.Limits;
    diagnostic_state : Adac.Diagnostics.State;
    source_registry  : Adac.Source.Registry;
    semantic_store   : Adac.Semantics.Store;
    symbol_store     : Adac.Symbols.Store;
    type_store       : Adac.Types.Store;
  end record;

  procedure validate (self : Context);

end Adac.Compilation;
