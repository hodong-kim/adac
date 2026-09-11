-- ============================================================================
-- adac_assembly_patterns.adb
-- Copyright (c) 2026 Hodong Kim <hodong@nimfsoft.com>
-- SPDX-License-Identifier: 0BSD
-- ============================================================================
with Ada.Characters.Latin_1;
with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Fixed;

package body Adac_Assembly_Patterns is

  package Line_Vectors is new Ada.Containers.Indefinite_Vectors
    (Index_Type   => Positive,
     Element_Type => String);

  function split_lines (value : String) return Line_Vectors.Vector is
    result     : Line_Vectors.Vector;
    line_first : Integer := value'first;
  begin
    while line_first <= value'last loop
      declare
        line_after : Integer := line_first;
      begin
        while line_after <= value'last and then
              value(line_after) /= Ada.Characters.Latin_1.LF
        loop
          line_after := line_after + 1;
        end loop;

        if line_after = line_first then
          result.append ("");
        else
          result.append (value(line_first .. line_after - 1));
        end if;

        line_first := line_after + 1;
      end;
    end loop;

    return result;
  end split_lines;

  function contains_fragment
    (line     : String;
     fragment : String)
  return Boolean is
  begin
    return Ada.Strings.Fixed.index (line, fragment) /= 0;
  end contains_fragment;

  function matches
    (patterns : String;
     assembly : String)
  return Boolean
  is
    pattern_lines  : constant Line_Vectors.Vector := split_lines (patterns);
    assembly_lines : constant Line_Vectors.Vector := split_lines (assembly);
    next_line      : Natural := 1;
    has_directive  : Boolean := False;
  begin
    for pattern_line of pattern_lines loop
      if pattern_line'length = 0 or else
         pattern_line(pattern_line'first) = '#'
      then
        null;
      elsif pattern_line'length < 3 or else
            pattern_line(pattern_line'first + 1) /= ' ' or else
            (pattern_line(pattern_line'first) /= '+' and then
             pattern_line(pattern_line'first) /= '!')
      then
        raise Program_Error with "invalid assembly pattern directive";
      else
        declare
          fragment : constant String :=
            pattern_line(pattern_line'first + 2 .. pattern_line'last);
        begin
          has_directive := True;
          if fragment'length = 0 then
            raise Program_Error with "empty assembly pattern operand";
          end if;

          if pattern_line(pattern_line'first) = '!' then
            for line of assembly_lines loop
              if contains_fragment (line, fragment) then
                return False;
              end if;
            end loop;
          else
            declare
              found : Boolean := False;
              index : Natural := next_line;
            begin
              while index <= Natural(assembly_lines.length) loop
                if contains_fragment
                  (assembly_lines.element (Positive(index)), fragment)
                then
                  found     := True;
                  next_line := index + 1;
                  exit;
                end if;

                index := index + 1;
              end loop;

              if not found then
                return False;
              end if;
            end;
          end if;
        end;
      end if;
    end loop;

    if not has_directive then
      raise Program_Error with "assembly pattern file has no directives";
    end if;

    return True;
  end matches;

end Adac_Assembly_Patterns;
