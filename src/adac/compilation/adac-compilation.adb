-- ============================================================================
-- adac-compilation.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
package body Adac.Compilation is

  function create
    (language_options : Adac.Language.Options;
     resource_limits  : Adac.Resources.Limits :=
       Adac.Resources.DEFAULT_LIMITS)
  return Context is
  begin
    return (initialized      => True,
            ast_store        => Adac.AST.create,
            options          => language_options,
            limits           => resource_limits,
            diagnostic_state => Adac.Diagnostics.create,
            source_registry  => Adac.Source.create,
            semantic_store   => Adac.Semantics.create,
            symbol_store     => Adac.Symbols.create
              (language_options.case_sensitive_identifiers),
            type_store       => Adac.Types.create);
  end create;

  function language_options
    (self : Context)
  return Adac.Language.Options is
  begin
    validate (self);
    return self.options;
  end language_options;

  function resource_limits
    (self : Context)
  return Adac.Resources.Limits is
  begin
    validate (self);
    return self.limits;
  end resource_limits;

  procedure validate (self : Context) is
  begin
    if not self.initialized then
      raise Program_Error with "Adac.Compilation: context is not initialized";
    end if;
  end validate;

end Adac.Compilation;
