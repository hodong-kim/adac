procedure main is
  subtype Small is Integer range +1 .. 20 / 5 * 2 rem 7 mod 3 + 9;
  subtype Tiny is Small range +((2 + 3)) * 2 / 5 .. 12 / (2 + 1) + 1;
  subtype Also_Tiny is Tiny;
  subtype Negative is Integer range -Integer'Last - 1 .. -(1 + 1);
  subtype Natural_Copy is Natural;
  subtype Positive_Copy is Positive range Integer'First mod 3 .. Positive'Last;
  subtype Full_Integer is Integer range Integer'First / 1 .. Integer'Last / 1;
  subtype Almost_Positive is
    Positive range Standard.Positive'First .. Standard.Positive'Last - 1;
  subtype Tiny_Attributes is Tiny range Tiny'First .. Tiny'Last;
  subtype Absolute is Integer range abs (-3) .. abs (2 + 3);
  subtype Powered is Integer range 2 ** 3 .. 3 ** 2;
  subtype Power_Zero is Integer range 2 ** 0 .. 2 ** 3;
  subtype Power_Grouped is Integer range 2 ** (1 + 1) .. 2 ** (2 + 1);
  subtype Power_Attributes is Integer range 2 ** Natural'First .. 2 ** Tiny'First;
  Step : constant Integer := 1 + 1;
  Offset : constant Tiny := Step + 1;
  Max : constant := 500;
  Max_Line_Size : constant := Max / 6;
  Power_16 : constant := 2 ** 16;
  Two : constant := Max / 250;
  Wide : constant := 2 ** 100;
  Wide_Reduced : constant := Wide / (2 ** 100);
  subtype Number_Bounded is Integer range 1 .. Max_Line_Size;
  subtype Constant_Bounded is Integer range Step .. Offset + 2;
  source : Constant_Bounded := Offset + 1;
  target : Also_Tiny := Max_Line_Size - 81;
  Decimal_Real : constant := 12.50E-1;
  Based_Real : constant := 16#F.FF#E+2;
  Real_Copy : constant := Decimal_Real;
  Real_Sum : constant := (Real_Copy + 0.75);
  Real_Difference : constant := Real_Sum - 0.5;
  Real_Negative : constant := -Real_Sum;
  Real_Absolute : constant := abs Real_Negative;
  Real_Product : constant := Real_Absolute * 1.5;
  Real_Quotient : constant := Real_Product / 2.0;
  Real_Positive : constant := +Real_Quotient;
  Real_Times_Integer_Literal : constant := Decimal_Real * 2;
  Integer_Number_Times_Real : constant := Two * Decimal_Real;
  Real_Div_Integer_Number : constant := Real_Product / Two;
  Real_Power_Positive : constant := Decimal_Real ** 2;
  Real_Power_Negative : constant := 2.0 ** (-3);
  Real_Power_Zero : constant := Real_Product ** 0;
  Real_Power_Exact_Exponent : constant :=
    2.0 ** ((2 ** 100) - (2 ** 100) - 2);
  Ready : constant Boolean := True;
  Stopped : constant Standard.Boolean := False;
  Ready_Copy : constant Boolean := READY;
  Stopped_Copy : constant Standard.Boolean := stopped;
  Not_Ready : constant Boolean := not Ready;
  Grouped_Not_Stopped : constant Boolean := (not (Stopped_Copy));
  Both : constant Boolean := Ready and Stopped;
  Either : constant Boolean := Ready or Stopped;
  Different : constant Boolean := Ready xor Stopped;
  Mixed_Logic : constant Boolean := (not Both) and (Either xor Different);
  Short_And_Skip : constant Boolean := Stopped and then Ready;
  Short_And_Read : constant Boolean := Ready and then Different;
  Short_Or_Skip : constant Boolean := Ready or else Stopped;
  Short_Or_Read : constant Boolean := Stopped or else Different;
  Equal : constant Boolean := Ready = Ready_Copy;
  Not_Equal : constant Boolean := Ready /= Stopped;
  Equality_Logic : constant Boolean := (Ready = True) and (Stopped /= True);
  Equality_Short_Skip : constant Boolean :=
    Stopped and then (Ready /= Stopped);
  Equality_Short_Read : constant Boolean :=
    Ready and then (Stopped /= Ready);
  Less : constant Boolean := Stopped < Ready;
  Less_Equal : constant Boolean := Stopped <= Stopped;
  Greater : constant Boolean := Ready > Stopped;
  Greater_Equal : constant Boolean := Ready >= Ready;
  Ordering_Logic : constant Boolean :=
    (Stopped < Ready) and (Ready >= Stopped);
  Ordering_Short_Skip : constant Boolean :=
    Stopped and then (Ready > Stopped);
  Ordering_Short_Read : constant Boolean :=
    Ready and then (Ready > Stopped);
begin
  target := Wide_Reduced + 1;
  target := Two;
  target := Max / 100;
  target := source;
end main;
