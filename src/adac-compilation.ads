-- ============================================================================
-- adac-compilation.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.Diagnostics;
with Adac.Language;

package Adac.Compilation is

  type Context is limited private;

  --! summary: Create a context for one compilation.
  --! ownership: The caller owns the returned context.
  function create
    (language_options : Adac.Language.Options)
  return Context;

  --! summary: Return the language options owned by the context.
  function language_options
    (self : Context)
  return Adac.Language.Options;

private

  type Context is limited record
    options          : Adac.Language.Options;
    diagnostic_state : Adac.Diagnostics.State;
  end record;

end Adac.Compilation;
