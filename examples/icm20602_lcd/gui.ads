--  SPDX-FileCopyrightText: 2023 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with GUI_Buttons;
with HAL.Bitmap;
with HAL.Touch_Panel;

package GUI is

   type Button_Kind is
     (Gx, Gy, Gz,
      Ax, Ay, Az,
      G_41, G_20, G_10, G_5,
      A_41, A_20, A_10, A_5,
      R_10, R_20, R_30, R_40, R_50, R_60, R_70, R_80);

   function "+" (X : Button_Kind) return Natural is (Button_Kind'Pos (X))
     with Static;

   Buttons : constant GUI_Buttons.Button_Info_Array :=
     [(Label  => "Gx",
       Center => (23 * 1, 20),
       Color  => HAL.Bitmap.Red),
      (Label  => "Gy",
       Center => (23 * 2, 20),
       Color  => HAL.Bitmap.Green),
      (Label  => "Gz",
       Center => (23 * 3, 20),
       Color  => HAL.Bitmap.Blue),
      (Label  => "Ax",
       Center => (23 * 1 + 160, 20),
       Color  => HAL.Bitmap.Dark_Red),
      (Label  => "Ay",
       Center => (23 * 2 + 160, 20),
       Color  => HAL.Bitmap.Dark_Green),
      (Label  => "Az",
       Center => (23 * 3 + 160, 20),
       Color  => HAL.Bitmap.Dark_Blue),
      (Label  => "41",
       Center => (23 * 1 + 20, 220),
       Color  => HAL.Bitmap.Red),
      (Label  => "20",
       Center => (23 * 2 + 20, 220),
       Color  => HAL.Bitmap.Red),
      (Label  => "10",
       Center => (23 * 3 + 20, 220),
       Color  => HAL.Bitmap.Red),
      (Label  => "5 ",
       Center => (23 * 4 + 20, 220),
       Color  => HAL.Bitmap.Red),
      (Label  => "41",
       Center => (23 * 1 + 160, 220),
       Color  => HAL.Bitmap.Dark_Red),
      (Label  => "20",
       Center => (23 * 2 + 160, 220),
       Color  => HAL.Bitmap.Dark_Red),
      (Label  => "10",
       Center => (23 * 3 + 160, 220),
       Color  => HAL.Bitmap.Dark_Red),
      (Label  => "5 ",
       Center => (23 * 4 + 160, 220),
       Color  => HAL.Bitmap.Dark_Red),
      (Label  => "10",
       Center => (23, 60 + 1 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "20",
       Center => (23, 60 + 2 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "30",
       Center => (23, 60 + 3 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "40",
       Center => (23, 60 + 4 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "50",
       Center => (23, 60 + 5 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "60",
       Center => (23, 60 + 6 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "70",
       Center => (23, 60 + 7 * 15),
       Color  => HAL.Bitmap.Dark_Grey),
      (Label  => "80",
       Center => (23, 60 + 8 * 15),
       Color  => HAL.Bitmap.Dark_Grey)];

   State : GUI_Buttons.Boolean_Array (Buttons'Range) :=
     [+Gx | +Ax | +G_5 | +A_5 | +R_10 => True, others => False];

   procedure Check_Touch
     (TP     : in out HAL.Touch_Panel.Touch_Panel_Device'Class;
      Update : out Boolean);
   --  Check buttons touched, update State, set Update = True if State changed

   procedure Draw
     (LCD   : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Clear : Boolean := False);

   procedure Dump_Screen (LCD : in out HAL.Bitmap.Bitmap_Buffer'Class);

end GUI;
