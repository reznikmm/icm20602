--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with ICM20602.Internal;

package body ICM20602.I2C is

   type Chip_Settings is record
      GFSR : Gyroscope_Full_Scale_Range := 250;
      AFSR : Accelerometer_Full_Scale_Range := 2;
   end record;

   Chip : Chip_Settings := (250, 2);

   procedure Read
     (Ignore  : Chip_Settings;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean);
   --  Read registers starting from Data'First

   procedure Write
     (Ignore  : Chip_Settings;
      Data    : HAL.UInt8_Array;
      Success : out Boolean);
   --  Write the value to the ICM20602 chip register with given Address.

   package Sensor is new Internal (Chip_Settings, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id (Expect : HAL.UInt8 := 16#12#) return Boolean is
     (Sensor.Check_Chip_Id (Chip, Expect));

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Chip :=
        (GFSR =>
           (if Value.Gyroscope.Power in Low_Noise | Low_Power
            then Value.Gyroscope.FSR else 250),
         AFSR =>
           (if Value.Accelerometer.Power in Low_Noise | Low_Power
            then Value.Accelerometer.FSR else 2));

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

   ----------
   -- Read --
   ----------

   procedure Read
     (Ignore  : Chip_Settings;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      I2C_Port.Mem_Read
        (Addr          => 2 * HAL.UInt10 (I2C_Address),
         Mem_Addr      => HAL.UInt16 (Data'First),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => Data,
         Status        => Status);

      Success := Status = HAL.I2C.Ok;
   end Read;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Gyro    : out Angular_Speed_Vector;
      Accel   : out Acceleration_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement
        (Chip, Chip.GFSR, Chip.AFSR, Gyro, Accel, Success);
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   procedure Read_Raw_Measurement
     (Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Raw_Measurement (Chip, Gyro, Accel, Success);
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Timer   : not null HAL.Time.Any_Delays;
      Success : out Boolean) is
   begin
      Sensor.Reset (Chip, Timer, Success);
   end Reset;

   -----------
   -- Write --
   -----------

   procedure Write
     (Ignore  : Chip_Settings;
      Data    : HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      if Data'Length = 0 then
         I2C_Port.Master_Transmit
           (Addr          => 2 * HAL.UInt10 (I2C_Address),
            Data          => [HAL.UInt8 (Data'First)],
            Status        => Status);
      else
         I2C_Port.Mem_Write
           (Addr          => 2 * HAL.UInt10 (I2C_Address),
            Mem_Addr      => HAL.UInt16 (Data'First),
            Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
            Data          => Data,
            Status        => Status);
      end if;

      Success := Status = HAL.I2C.Ok;
   end Write;

end ICM20602.I2C;
