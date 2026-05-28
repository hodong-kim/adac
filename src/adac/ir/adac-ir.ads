-- ============================================================================
-- adac-ir.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;

package Adac.IR is

  type Module is record
    entry_name : Ada.Strings.Unbounded.Unbounded_String;
  end record;

end Adac.IR;
