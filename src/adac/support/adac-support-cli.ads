-- ============================================================================
-- adac-support-cli.ads
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================

with Ada.Strings.Unbounded;
with Adac.Language;

package Adac.Support.CLI is

  type Options is record
    valid            : Boolean := True;
    error_message    : Ada.Strings.Unbounded.Unbounded_String;
    has_input        : Boolean := False;
    input_path       : Ada.Strings.Unbounded.Unbounded_String;
    has_output       : Boolean := False;
    output_path      : Ada.Strings.Unbounded.Unbounded_String;
    language_options : Adac.Language.Options;
  end record;

  function parse return Options;

end Adac.Support.CLI;
