--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with ICM20602.Internal;

package body ICM20602.SPI_Sensors is

   procedure Read
     (Self    : ICM20602_SPI_Sensor'Class;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean);
   --  Read registers starting from Data'First

   procedure Write
     (Self    : ICM20602_SPI_Sensor'Class;
      Data    : HAL.UInt8_Array;
      Success : out Boolean);
   --  Write registers starting from Data'First

   package Sensor is new Internal (ICM20602_SPI_Sensor'Class, Read, Write);

   -------------------
   -- Check_Chip_Id --
   -------------------

   overriding function Check_Chip_Id
     (Self   : ICM20602_SPI_Sensor;
      Expect : HAL.UInt8 := 16#12#) return Boolean is
        (Sensor.Check_Chip_Id (Self, Expect));

   ---------------
   -- Configure --
   ---------------

   overriding procedure Configure
     (Self    : in out ICM20602_SPI_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean) is
   begin
      Sensor.Configure (Self, Value, Success);
   end Configure;

   ----------------
   -- Initialize --
   ----------------

   overriding procedure Initialize
     (Self  : ICM20602_SPI_Sensor;
      Timer : not null HAL.Time.Any_Delays) is
   begin
      Sensor.Initialize (Self, Timer, Use_SPI => True);
   end Initialize;

   ---------------
   -- Measuring --
   ---------------

   overriding function Measuring (Self : ICM20602_SPI_Sensor) return Boolean is
     (Sensor.Measuring (Self));

   ----------
   -- Read --
   ----------

   procedure Read
     (Self    : ICM20602_SPI_Sensor'Class;
      Data    : out HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.UInt8;
      use all type HAL.SPI.SPI_Status;

      Addr : constant HAL.UInt8 := HAL.UInt8 (Data'First) or 16#80#;
      Status : HAL.SPI.SPI_Status;
   begin
      Self.SPI_CS.Clear;

      Self.SPI_Port.Transmit (HAL.SPI.SPI_Data_8b'(1 => Addr), Status);

      if Status = Ok then
         Self.SPI_Port.Receive (HAL.SPI.SPI_Data_8b (Data), Status);
      end if;

      Self.SPI_CS.Set;

      Success := Status = Ok;
   end Read;

   ----------------------
   -- Read_Measurement --
   ----------------------

   overriding procedure Read_Measurement
     (Self    : ICM20602_SPI_Sensor;
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
     (Self    : ICM20602_SPI_Sensor;
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
     (Self    : ICM20602_SPI_Sensor;
      Timer   : not null HAL.Time.Any_Delays;
      Success : out Boolean) is
   begin
      Sensor.Reset (Self, Timer, Success);
   end Reset;

   -----------
   -- Write --
   -----------

   procedure Write
     (Self    : ICM20602_SPI_Sensor'Class;
      Data    : HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.UInt8;
      use type HAL.UInt8_Array;
      use all type HAL.SPI.SPI_Status;

      Addr : constant HAL.UInt8 := HAL.UInt8 (Data'First) and 16#7F#;
      Status : HAL.SPI.SPI_Status;
   begin
      Self.SPI_CS.Clear;

      Self.SPI_Port.Transmit (HAL.SPI.SPI_Data_8b (Addr & Data), Status);

      Self.SPI_CS.Set;

      Success := Status = Ok;
   end Write;

end ICM20602.SPI_Sensors;
