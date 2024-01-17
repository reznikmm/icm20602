--  SPDX-FileCopyrightText: 2023 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Text_IO;

package body GUI is

   use type GUI_Buttons.Boolean_Array;

   Prev  : GUI_Buttons.Boolean_Array (Buttons'Range) := not State;

   procedure On_Click
     (Button : Button_Kind;
      Update : in out Boolean);

   -----------------
   -- Check_Touch --
   -----------------

   procedure Check_Touch
     (TP     : in out HAL.Touch_Panel.Touch_Panel_Device'Class;
      Update : out Boolean)
   is
      Touch  : constant HAL.Touch_Panel.TP_State := TP.Get_All_Touch_Points;
      Index  : Natural := Buttons'First;
      Min    : Natural := Natural'Last;
   begin
      Update := False;

      if Touch'Length = 0 then
         return;
      end if;

      for J in Buttons'Range loop
         declare
            Center : constant HAL.Bitmap.Point := Buttons (J).Center;
            Dist   : constant Natural :=
              (Center.X - Touch (Touch'First).X) ** 2
                + (Center.Y - Touch (Touch'First).Y)**2;
         begin
            if Min > Dist then
               Min := Dist;
               Index := J;
            end if;
         end;
      end loop;

      if Min < 600 then
         On_Click (Button_Kind'Val (Index), Update);
      end if;
   end Check_Touch;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (LCD   : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Clear : Boolean := False) is
   begin
      if Clear then
         LCD.Set_Source (HAL.Bitmap.Black);
         LCD.Fill;
         Prev := not State;
      end if;

      if State /= Prev then
         GUI_Buttons.Draw (LCD, Buttons, State, Prev);
         Prev := State;
      end if;
   end Draw;

   -----------------
   -- Dump_Screen --
   -----------------

   procedure Dump_Screen (LCD : in out HAL.Bitmap.Bitmap_Buffer'Class) is
      Color : HAL.UInt32;
   begin
      for Y in 0 .. LCD.Height - 1 loop
         for X in 0 .. LCD.Width - 1 loop
            Color := LCD.Pixel ((X, Y));
            Ada.Text_IO.Put_Line (Color'Image);
         end loop;
      end loop;
   end Dump_Screen;

   --------------
   -- On_Click --
   --------------

   procedure On_Click
     (Button : Button_Kind;
      Update : in out Boolean) is
   begin
      case Button is
         when G_41 .. G_5 =>
            State (+G_41 .. +G_5) := (others => False);
            State (+Button) := True;
            Update := True;
         when A_41 .. A_5 =>
            State (+A_41 .. +A_5) := (others => False);
            State (+Button) := True;
            Update := True;
         when R_10 .. R_80 =>
            State (+R_10 .. +R_80) := (others => False);
            State (+Button) := True;
            Update := True;
         when Gx .. Az =>
            State (+Button) := not State (+Button);
      end case;
   end On_Click;

end GUI;
