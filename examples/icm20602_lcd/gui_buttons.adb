--  SPDX-FileCopyrightText: 2023 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Bitmapped_Drawing;
with BMP_Fonts;

package body GUI_Buttons is

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Buttons : Button_Info_Array;
      State   : Boolean_Array) is
   begin
      Draw (Buffer, Buttons, State, not State);
   end Draw;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Buffer     : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Buttons    : Button_Info_Array;
      State      : Boolean_Array;
      Prev_State : Boolean_Array) is
   begin
      for J in Buttons'Range loop
         if State (J) /= Prev_State (J) then
            declare
               use type HAL.Bitmap.Point;

               Button : Button_Info renames Buttons (J);

               Area   : constant HAL.Bitmap.Rect :=
                 (Button.Center - (10, 6),
                  Width => 20, Height => 13);

               Foreground : constant HAL.Bitmap.Bitmap_Color :=
                 (if State (J) then HAL.Bitmap.Black else Button.Color);

               Background : constant HAL.Bitmap.Bitmap_Color :=
                 (if State (J) then Button.Color else HAL.Bitmap.Black);
            begin
               Buffer.Set_Source (Background);
               Buffer.Fill_Rounded_Rect (Area, 3);

               Bitmapped_Drawing.Draw_String
                 (Buffer,
                  Start      => Area.Position + (1, 2),
                  Msg        => Button.Label,
                  Font       => BMP_Fonts.Font8x8,
                  Foreground => Foreground,
                  Background => Background);

               if not State (J) then
                  Buffer.Set_Source (Foreground);
                  Buffer.Draw_Rounded_Rect (Area, 3);
               end if;
            end;
         end if;
      end loop;
   end Draw;

end GUI_Buttons;
