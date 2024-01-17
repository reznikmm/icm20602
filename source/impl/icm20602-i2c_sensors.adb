--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with ICM20602.Internal;

package body ICM20602.I2C_Sensors is

   procedure Read
     (Self    : ICM20602_I2C_Sensor'Class;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean);
   --  Read registers starting from Data'First

   procedure Write
     (Self    : ICM20602_I2C_Sensor'Class;
      Data    : HAL.UInt8_Array;
      Success : out Boolean);
   --  Write registers starting from Data'First

   package Sensor is new Internal (ICM20602_I2C_Sensor'Class, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   overriding function Check_Chip_Id
     (Self   : ICM20602_I2C_Sensor;
      Expect : HAL.UInt8 := 16#12#) return Boolean is
        (Sensor.Check_Chip_Id (Self, Expect));

   ---------------
   -- Configure --
   ---------------

   overriding procedure Configure
     (Self    : in out ICM20602_I2C_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Sensor.Configure (Self, Value, Success);
   end Configure;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize
     (Self  : ICM20602_I2C_Sensor;
      Timer : not null HAL.Time.Any_Delays) is
   begin
      Sensor.Initialize (Self, Timer, Use_SPI => False);
   end Initialize;

   ---------------
   -- Measuring --
   ---------------

   overriding function Measuring (Self : ICM20602_I2C_Sensor) return Boolean is
     (Sensor.Measuring (Self));

   ----------
   -- Read --
   ----------

   procedure Read
     (Self    : ICM20602_I2C_Sensor'Class;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      Self.I2C_Port.Mem_Read
        (Addr          => 2 * HAL.UInt10 (Self.I2C_Address),
         Mem_Addr      => HAL.UInt16 (Data'First),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => Data,
         Status        => Status);

      Success := Status = HAL.I2C.Ok;
   end Read;

   ----------------------
   -- Read_Measurement --
   ----------------------

   overriding procedure Read_Measurement
     (Self    : ICM20602_I2C_Sensor;
      Gyro    : out Angular_Speed_Vector;
      Accel   : out Acceleration_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Measurement
        (Self,
         GFSR    => Self.GFSR,
         AFSR    => Self.AFSR,
         Gyro    => Gyro,
         Accel   => Accel,
         Success => Success);
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   overriding procedure Read_Raw_Measurement
     (Self    : ICM20602_I2C_Sensor;
      Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean) is
   begin
      Sensor.Read_Raw_Measurement (Self, Gyro, Accel, Success);
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   overriding procedure Reset
     (Self    : ICM20602_I2C_Sensor;
      Timer   : not null HAL.Time.Any_Delays;
      Success : out Boolean) is
   begin
      Sensor.Reset (Self, Timer, Success);
   end Reset;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self    : ICM20602_I2C_Sensor'Class;
      Data    : HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      if Data'Length = 0 then
         Self.I2C_Port.Master_Transmit
           (Addr          => 2 * HAL.UInt10 (Self.I2C_Address),
            Data          => [HAL.UInt8 (Data'First)],
            Status        => Status);
      else
         Self.I2C_Port.Mem_Write
           (Addr          => 2 * HAL.UInt10 (Self.I2C_Address),
            Mem_Addr      => HAL.UInt16 (Data'First),
            Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
            Data          => Data,
            Status        => Status);
      end if;

      Success := Status = HAL.I2C.Ok;
   end Write;

end ICM20602.I2C_Sensors;
