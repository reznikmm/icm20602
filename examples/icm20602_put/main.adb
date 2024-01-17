--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Ada.Real_Time;
with Ada.Text_IO;

with Ravenscar_Time;

with STM32.Board;
with STM32.Device;
with STM32.Setup;

with ICM20602.I2C;

procedure Main is
   use type Ada.Real_Time.Time;

   package ICM20602_I2C is new ICM20602.I2C
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#69#);  --  ICM-20602 alternative address

   Ok    : Boolean := False;
   Gyro  : array (1 .. 16) of ICM20602.Angular_Speed_Vector;
   Accel : array (1 .. 16) of ICM20602.Acceleration_Vector;
   Prev  : Ada.Real_Time.Time;

   Spinned : Natural;
begin
   STM32.Board.Initialize_LEDs;
   STM32.Setup.Setup_I2C_Master
     (Port        => STM32.Device.I2C_1,
      SDA         => STM32.Device.PB9,
      SCL         => STM32.Device.PB8,
      SDA_AF      => STM32.Device.GPIO_AF_I2C1_4,
      SCL_AF      => STM32.Device.GPIO_AF_I2C1_4,
      Clock_Speed => 400_000);

   ICM20602_I2C.Initialize (Ravenscar_Time.Delays);

   --  Look for ICM-20602 chip
   if not ICM20602_I2C.Check_Chip_Id (16#12#) then
      Ada.Text_IO.Put_Line ("ICM20602 not found.");
      raise Program_Error;
   end if;

   --  Reset ICM-20602
   ICM20602_I2C.Reset (Ravenscar_Time.Delays, Ok);
   pragma Assert (Ok);

   --  Set ICM-20602 up
   ICM20602_I2C.Configure
     ((Gyroscope     =>
        (Power  => ICM20602.Low_Noise,
         FSR    => 250,  --  full scale range => -250 .. +250 dps
         Filter =>  --  Low-pass filter 176Hz on 1kHz rate
           (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
       Accelerometer =>
         (Power  => ICM20602.Low_Noise,
          FSR    => 2,  --  full scale range => -2g .. +2g
          Filter =>  --  Low-pass filter 176Hz on 1kHz rate
            (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
       Rate_Divider  => 2),  --  Divide 1kHz rate by 2, so ODR = 500Hz
      Ok);

   Ravenscar_Time.Delays.Delay_Milliseconds (100);  --  Gyro start-up time

   loop
      Spinned := 0;
      Prev := Ada.Real_Time.Clock;
      STM32.Board.Toggle (STM32.Board.D1_LED);

      for J in Gyro'Range loop

         while ICM20602_I2C.Measuring loop
            Spinned := Spinned + 1;
         end loop;

         --  Read scaled values from the sensor
         ICM20602_I2C.Read_Measurement (Gyro (J), Accel (J), Ok);
         pragma Assert (Ok);
      end loop;

      --  Printing...
      declare
         Now : constant Ada.Real_Time.Time := Ada.Real_Time.Clock;
         Diff : constant Duration := Ada.Real_Time.To_Duration (Now - Prev);
      begin
         Ada.Text_IO.New_Line;
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line
           ("Time=" & Diff'Image & "/16 Spinned=" & Spinned'Image);

         Ada.Text_IO.Put_Line ("Accelerometer:");

         for Value of Accel loop
            Ada.Text_IO.Put_Line
              ("X=" & Value.X'Image &
               " Y=" & Value.Y'Image &
               " Z=" & Value.Z'Image);
         end loop;

         Ada.Text_IO.Put_Line ("Gyroscope:");

         for Value of Gyro loop
            Ada.Text_IO.Put_Line
              ("X=" & Value.X'Image &
               " Y=" & Value.Y'Image &
               " Z=" & Value.Z'Image);
         end loop;

         Ada.Text_IO.Put_Line ("Sleeping 2s...");
         Ravenscar_Time.Delays.Delay_Seconds (2);
      end;
   end loop;
end Main;
