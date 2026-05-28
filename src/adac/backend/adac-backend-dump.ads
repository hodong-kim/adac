-- ============================================================================
-- adac-backend-dump.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Adac.IR;

package Adac.Backend.Dump is

  function emit (module : Adac.IR.Module) return Boolean;

end Adac.Backend.Dump;
