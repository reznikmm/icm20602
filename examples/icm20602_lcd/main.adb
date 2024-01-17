--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Text_IO;

with Ravenscar_Time;

with STM32.Board;
with STM32.Device;
with STM32.GPIO;
with STM32.Setup;
with STM32.User_Button;

with HAL.Bitmap;
with HAL.Framebuffer;

with Display_ILI9341;
with Bitmapped_Drawing;
with BMP_Fonts;

with ICM20602.I2C_Sensors;

with GUI;
--  with GUI_Buttons;

procedure Main is
   use all type GUI.Button_Kind;

   Sensor : ICM20602.I2C_Sensors.ICM20602_I2C_Sensor
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#69#);

   procedure Configure_Sensor;
   --  Restart sensor with new settings according to GUI state

   type Sensor_Data is record
      Gyro  : ICM20602.Angular_Speed_Vector;
      Accel : ICM20602.Acceleration_Vector;
   end record;

   function Read_Sensor return Sensor_Data;

   function Min (Left, Right : ICM20602.Angular_Speed_Vector)
     return ICM20602.Angular_Speed_Vector is
       (X => ICM20602.Scaled_Angular_Speed'Min (Left.X, Right.X),
        Y => ICM20602.Scaled_Angular_Speed'Min (Left.Y, Right.Y),
        Z => ICM20602.Scaled_Angular_Speed'Min (Left.Z, Right.Z));

   function Min (Left, Right : ICM20602.Acceleration_Vector)
     return ICM20602.Acceleration_Vector is
       (X => ICM20602.Acceleration'Min (Left.X, Right.X),
        Y => ICM20602.Acceleration'Min (Left.Y, Right.Y),
        Z => ICM20602.Acceleration'Min (Left.Z, Right.Z));

   function Min (Left, Right : Sensor_Data) return Sensor_Data is
     (Gyro  => Min (Left.Gyro, Right.Gyro),
      Accel => Min (Left.Accel, Right.Accel));

   function Max (Left, Right : ICM20602.Angular_Speed_Vector)
     return ICM20602.Angular_Speed_Vector is
       (X => ICM20602.Scaled_Angular_Speed'Max (Left.X, Right.X),
        Y => ICM20602.Scaled_Angular_Speed'Max (Left.Y, Right.Y),
        Z => ICM20602.Scaled_Angular_Speed'Max (Left.Z, Right.Z));

   function Max (Left, Right : ICM20602.Acceleration_Vector)
     return ICM20602.Acceleration_Vector is
       (X => ICM20602.Acceleration'Max (Left.X, Right.X),
        Y => ICM20602.Acceleration'Max (Left.Y, Right.Y),
        Z => ICM20602.Acceleration'Max (Left.Z, Right.Z));

   function Max (Left, Right : Sensor_Data) return Sensor_Data is
     (Gyro  => Max (Left.Gyro, Right.Gyro),
      Accel => Max (Left.Accel, Right.Accel));

   use type ICM20602.Scaled_Angular_Speed;
   use type ICM20602.Acceleration;

   function "*" (Percent : Integer; Right : ICM20602.Angular_Speed_Vector)
     return ICM20602.Angular_Speed_Vector is
       (X => ICM20602.Scaled_Angular_Speed'Max
          (abs Right.X / 100, ICM20602.Scaled_Angular_Speed'Small) * Percent,
        Y => ICM20602.Scaled_Angular_Speed'Max
          (abs Right.Y / 100, ICM20602.Scaled_Angular_Speed'Small) * Percent,
        Z => ICM20602.Scaled_Angular_Speed'Max
          (abs Right.Z / 100, ICM20602.Scaled_Angular_Speed'Small) * Percent);

   function "+" (Left, Right : ICM20602.Angular_Speed_Vector)
     return ICM20602.Angular_Speed_Vector is
       (X => Left.X + Right.X,
        Y => Left.Y + Right.Y,
        Z => Left.Z + Right.Z);

   function "*" (Percent : Integer; Right : ICM20602.Acceleration_Vector)
     return ICM20602.Acceleration_Vector is
       (X => ICM20602.Acceleration'Max
           (abs Right.X / 100, ICM20602.Acceleration'Small) * Percent,
        Y => ICM20602.Acceleration'Max
           (abs Right.Y / 100, ICM20602.Acceleration'Small) * Percent,
        Z => ICM20602.Acceleration'Max
           (abs Right.Z / 100, ICM20602.Acceleration'Small) * Percent);

   function "+" (Left, Right : ICM20602.Acceleration_Vector)
     return ICM20602.Acceleration_Vector is
       (X => Left.X + Right.X,
        Y => Left.Y + Right.Y,
        Z => Left.Z + Right.Z);

   type Sensor_Limits is record
      Min : Sensor_Data;
      Max : Sensor_Data;
   end record;

   procedure Make_Wider (Limits : in out Sensor_Limits);
   --  Make limits a bit wider

   procedure Print
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      Data   : Sensor_Data);

   procedure Plot
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      X      : Natural;
      Data   : in out Sensor_Data;
      Limits : Sensor_Limits);

   ----------------------
   -- Configure_Sensor --
   ----------------------

   procedure Configure_Sensor is
      --  use all type GUI.Button_Kind;

      Map : constant array (R_10 .. R_80) of ICM20602.Sample_Rate_Divider :=
        (1000 / 10, 1000 / 20, 1000 / 30, 1000 / 40,
         1000 / 50, 1000 / 60, 1000 / 70, 1000 / 80);

      Div : ICM20602.Sample_Rate_Divider := 2;
      Ok : Boolean;
      GB : ICM20602.Low_Pass_Filter_Bandwidth := 41;
      AB : ICM20602.Low_Pass_Filter_Bandwidth := 41;
   begin
      for J in Map'Range loop
         if GUI.State (+J) then
            Div := Map (J);
            exit;
         end if;
      end loop;

      for V of GUI.State (+G_41 .. +G_5) loop
         exit when V;
         GB := GB / 2;
      end loop;

      for V of GUI.State (+A_41 .. +A_5) loop
         exit when V;
         AB := AB / 2;
      end loop;

      Sensor.Configure
        ((Gyroscope     =>
           (Power  => ICM20602.Low_Noise,
            FSR    => 250,  --  full scale range => -250 .. +250 dps
            Filter =>  --  Low-pass filter on 1kHz rate
              (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => GB)),
          Accelerometer =>
            (Power  => ICM20602.Low_Noise,
             FSR    => 2,  --  full scale range => -2g .. +2g
             Filter =>  --  Low-pass filter on 1kHz rate
               (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => AB)),
          Rate_Divider  => Div),  --  Divide 1kHz rate by Div
         Ok);
      pragma Assert (Ok);
   end Configure_Sensor;

   ----------------
   -- Make_Wider --
   ----------------

      procedure Make_Wider (Limits : in out Sensor_Limits) is
   begin
      Limits.Min :=
        (Gyro  => Limits.Min.Gyro + (-20) * Limits.Min.Gyro,
         Accel => Limits.Min.Accel + (-20) * Limits.Min.Accel);

      Limits.Max :=
        (Gyro  => Limits.Max.Gyro + 20 * Limits.Max.Gyro,
         Accel => Limits.Max.Accel + 20 * Limits.Max.Accel);
   end Make_Wider;

   -----------
   -- Print --
   -----------

   procedure Print
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      Data   : Sensor_Data)
   is
      TGX : constant String :=
        ICM20602.Scaled_Angular_Speed'Image (Data.Gyro.X);
      TGY : constant String :=
        ICM20602.Scaled_Angular_Speed'Image (Data.Gyro.Y);
      TGZ : constant String :=
        ICM20602.Scaled_Angular_Speed'Image (Data.Gyro.Z);

      TAX : constant String := ICM20602.Acceleration'Image (Data.Accel.X);
      TAY : constant String := ICM20602.Acceleration'Image (Data.Accel.Y);
      TAZ : constant String := ICM20602.Acceleration'Image (Data.Accel.Z);
   begin
      if GUI.State (+Gx) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 30),
            Msg        => TGX,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Gx).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Gy) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 40),
            Msg        => TGY,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Gy).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Gz) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (0, 50),
            Msg        => TGZ,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Gz).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Ax) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (160, 30),
            Msg        => TAX,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Ax).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Ay) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (160, 40),
            Msg        => TAY,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Ay).Color,
            Background => HAL.Bitmap.Black);
      end if;

      if GUI.State (+Az) then
         Bitmapped_Drawing.Draw_String
           (LCD.all,
            Start      => (160, 50),
            Msg        => TAZ,
            Font       => BMP_Fonts.Font8x8,
            Foreground => GUI.Buttons (+Az).Color,
            Background => HAL.Bitmap.Black);
      end if;
   end Print;

   ----------
   -- Plot --
   ----------

   procedure Plot
     (LCD    : not null HAL.Bitmap.Any_Bitmap_Buffer;
      X      : Natural;
      Data   : in out Sensor_Data;
      Limits : Sensor_Limits)
   is
      Y : Natural;
   begin
      Data := Min (Data, Limits.Max);
      Data := Max (Data, Limits.Min);

      if GUI.State (+Gx) then
         Y := Natural
           (ICM20602.Scaled_Angular_Speed'Base'
              (LCD.Height * (Data.Gyro.X - Limits.Min.Gyro.X))
            / ICM20602.Scaled_Angular_Speed'Base'
              (Limits.Max.Gyro.X - Limits.Min.Gyro.X));

         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Gx).Color);
      end if;

      if GUI.State (+Gy) then
         Y := Natural
           (ICM20602.Scaled_Angular_Speed'Base'
              (LCD.Height * (Data.Gyro.Y - Limits.Min.Gyro.Y))
            / ICM20602.Scaled_Angular_Speed'Base'
              (Limits.Max.Gyro.Y - Limits.Min.Gyro.Y));

         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Gy).Color);
      end if;

      if GUI.State (+Gz) then
         Y := Natural
           (ICM20602.Scaled_Angular_Speed'Base'
              (LCD.Height * (Data.Gyro.Z - Limits.Min.Gyro.Z))
            / ICM20602.Scaled_Angular_Speed'Base'
              (Limits.Max.Gyro.Z - Limits.Min.Gyro.Z));

         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Gz).Color);
      end if;

      if GUI.State (+Ax) then
         Y := Natural
           (ICM20602.Acceleration'Base'
              (LCD.Height * (Data.Accel.X - Limits.Min.Accel.X))
            / ICM20602.Acceleration'Base'
              (Limits.Max.Accel.X - Limits.Min.Accel.X));

         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Ax).Color);
      end if;

      if GUI.State (+Ay) then
         Y := Natural
           (ICM20602.Acceleration'Base'
              (LCD.Height * (Data.Accel.Y - Limits.Min.Accel.Y))
            / ICM20602.Acceleration'Base'
              (Limits.Max.Accel.Y - Limits.Min.Accel.Y));

         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Ay).Color);
      end if;

      if GUI.State (+Az) then
         Y := Natural
           (ICM20602.Acceleration'Base'
              (LCD.Height * (Data.Accel.Z - Limits.Min.Accel.Z))
            / ICM20602.Acceleration'Base'
              (Limits.Max.Accel.Z - Limits.Min.Accel.Z));

         Y := LCD.Height - Y;
         LCD.Set_Pixel ((X, Y), GUI.Buttons (+Az).Color);
      end if;
   end Plot;

   -----------------
   -- Read_Sensor --
   -----------------

   function Read_Sensor return Sensor_Data is
      Ok     : Boolean;
      Result : Sensor_Data;
   begin
      --  Wait for the first measurement
      while Sensor.Measuring loop
         null;
      end loop;

      Sensor.Read_Measurement (Result.Gyro, Result.Accel, Ok);
      pragma Assert (Ok);

      return Result;
   end Read_Sensor;

   Empty : constant Sensor_Limits :=
     (Min =>
        (Gyro  => (X | Y | Z => ICM20602.Scaled_Angular_Speed'Last),
         Accel => (X | Y | Z => ICM20602.Acceleration'Last)),
      Max =>
        (Gyro  => (X | Y | Z => ICM20602.Scaled_Angular_Speed'First),
         Accel => (X | Y | Z => ICM20602.Acceleration'First)));

   LCD : constant not null HAL.Bitmap.Any_Bitmap_Buffer :=
     STM32.Board.TFT_Bitmap'Access;

   Ok          : Boolean;
   Next_Limits : Sensor_Limits;
begin
   STM32.Board.Initialize_LEDs;
   STM32.User_Button.Initialize;
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Set_Orientation (HAL.Framebuffer.Landscape);
   STM32.Board.Touch_Panel.Initialize;
   STM32.Board.Touch_Panel.Set_Orientation (HAL.Framebuffer.Landscape);

   --  Initialize touch panel IRQ pin
   STM32.Board.TFT_RS.Configure_IO
     ((STM32.GPIO.Mode_In, Resistors => STM32.GPIO.Floating));

   STM32.Setup.Setup_I2C_Master
     (Port        => STM32.Device.I2C_1,
      SDA         => STM32.Device.PB9,
      SCL         => STM32.Device.PB8,
      SDA_AF      => STM32.Device.GPIO_AF_I2C1_4,
      SCL_AF      => STM32.Device.GPIO_AF_I2C1_4,
      Clock_Speed => 400_000);

   Sensor.Initialize (Ravenscar_Time.Delays);

   --  Look for ICM20602 chip
   if not Sensor.Check_Chip_Id then
      Ada.Text_IO.Put_Line ("ICM20602 not found.");
      raise Program_Error;
   end if;

   --  Reset ICM20602
   Sensor.Reset (Ravenscar_Time.Delays, Ok);
   pragma Assert (Ok);

   Configure_Sensor;
   Ravenscar_Time.Delays.Delay_Milliseconds (100);  --  Gyro start-up time
   Next_Limits.Min := Read_Sensor;

   --  Predict boundaries from the first sensor measurement
   Next_Limits.Min := Read_Sensor;
   Next_Limits.Max := Next_Limits.Min;
   Make_Wider (Next_Limits);

   loop
      declare
         Limits : constant Sensor_Limits := Next_Limits;
         Data   : Sensor_Data;
         Update : Boolean := False;  --  GUI state updated
      begin
         GUI.Draw (LCD.all, Clear => True);  --  draw all buttons
         Next_Limits := Empty;

         for X in 0 .. LCD.Width - 1 loop
            STM32.Board.Toggle (STM32.Board.D1_LED);

            Data := Read_Sensor;

            Next_Limits :=
              (Min => Min (Data, Next_Limits.Min),
               Max => Max (Data, Next_Limits.Max));

            if not STM32.Board.TFT_RS.Set then  --  Touch IRQ Pin is active
               GUI.Check_Touch (STM32.Board.Touch_Panel, Update);
            end if;

            GUI.Draw (LCD.all);
            Print (LCD, Data);
            Plot (LCD, X, Data, Limits);

            if Update then
               Configure_Sensor;
            elsif STM32.User_Button.Has_Been_Pressed then
               GUI.Dump_Screen (LCD.all);
            end if;
         end loop;

         Make_Wider (Next_Limits);
      end;
   end loop;
end Main;
