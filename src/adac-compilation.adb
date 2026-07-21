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
    return (options => language_options);
  end create;

  function language_options
    (self : Context)
  return Adac.Language.Options is
  begin
    return self.options;
  end language_options;

end Adac.Compilation;
