--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with ICM20602.Internal;

package body ICM20602.Generic_Sensor is

   type Null_Record is null record;

   Chip : constant Null_Record := (null record);

   procedure Read_Sensor
     (Ignore  : Null_Record;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean);

   procedure Write_Sensor
     (Ignore  : Null_Record;
      Data    : HAL.UInt8_Array;
      Success : out Boolean);

   ------------
   -- Sensor --
   ------------

   package Sensor is new ICM20602.Internal
     (Null_Record, Read_Sensor, Write_Sensor);

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id (Expect : HAL.UInt8 := 16#12#) return Boolean
     is (Sensor.Check_Chip_Id (Chip, Expect));

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Sensor.Configure (Chip, Value, Success);
   end Configure;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Sensor.Initialize (Chip);
   end Initialize;

   ---------------
   -- Measuring --
   ---------------

   function Measuring return Boolean is (Sensor.Measuring (Chip));

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement (Chip, Gyro, Accel, Success);
   end Read_Measurement;

   -----------------
   -- Read_Sensor --
   -----------------

   procedure Read_Sensor
     (Ignore  : Null_Record;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean) is
   begin
      Read (Data, Success);
   end Read_Sensor;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Timer   : not null HAL.Time.Any_Delays;
      Success : out Boolean) is
   begin
      Sensor.Reset (Chip, Timer, Success);
   end Reset;

   ------------------
   -- Write_Sensor --
   ------------------

   procedure Write_Sensor
     (Ignore  : Null_Record;
      Data    : HAL.UInt8_Array;
      Success : out Boolean) is
   begin
      Write (Data, Success);
   end Write_Sensor;

end ICM20602.Generic_Sensor;
