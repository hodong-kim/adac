-- ============================================================================
-- adac-ir-builder.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

package body Adac.IR.Builder is

  function build (unit : Adac.AST.Compilation_Unit) return Adac.IR.Module is
  begin
    return
      (entry_name => unit.procedure_name);
  end build;

end Adac.IR.Builder;
