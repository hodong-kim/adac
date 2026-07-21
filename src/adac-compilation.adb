-- ============================================================================
-- adac-compilation.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
package body Adac.Compilation is

  function create
    (language_options : Adac.Language.Options)
  return Context is
  begin
    return (initialized      => True,
            options          => language_options,
            diagnostic_state => Adac.Diagnostics.create,
            source_registry  => Adac.Source.create,
            symbol_store     => Adac.Symbols.create
              (language_options.case_sensitive_identifiers));
  end create;

  function language_options
    (self : Context)
  return Adac.Language.Options is
  begin
    validate (self);
    return self.options;
  end language_options;

  procedure validate (self : Context) is
  begin
    if not self.initialized then
      raise Program_Error with "Adac.Compilation: context is not initialized";
    end if;
  end validate;

end Adac.Compilation;
