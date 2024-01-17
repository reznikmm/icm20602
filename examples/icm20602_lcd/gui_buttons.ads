--  SPDX-FileCopyrightText: 2023 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with HAL.Bitmap;

package GUI_Buttons is

   type Button_Info is record
      Label   : String (1 .. 2);
      Center  : HAL.Bitmap.Point;
      Color   : HAL.Bitmap.Bitmap_Color;
   end record;

   type Button_Info_Array is array (Natural range <>) of Button_Info;
   type Boolean_Array is array (Natural range <>) of Boolean with Pack;

   procedure Draw
     (Buffer  : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Buttons : Button_Info_Array;
      State   : Boolean_Array);

   procedure Draw
     (Buffer     : in out HAL.Bitmap.Bitmap_Buffer'Class;
      Buttons    : Button_Info_Array;
      State      : Boolean_Array;
      Prev_State : Boolean_Array);
   --  Optimized version of Draw, It works as Draw, but draws only buttons (J)
   --  if State (J) /= Prev_State (J)

end GUI_Buttons;
