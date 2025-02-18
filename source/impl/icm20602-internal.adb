--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with ICM20602.Raw;

package body ICM20602.Internal is

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id
     (Device : Device_Context;
      Expect : Byte) return Boolean
   is
      use type Byte;

      Ok   : Boolean;
      Data : Raw.Chip_Id_Data;
   begin
      Read (Device, Data, Ok);

      return Ok and Raw.Get_Chip_Id (Data) = Expect;
   end Check_Chip_Id;

   --------------------------
   -- Set_Gyroscope_Offset --
   --------------------------

   procedure Set_Gyroscope_Offset
     (Device  : Device_Context;
      Value   : Raw_Vector;
      Success : out Boolean)
   is
      Data : constant Raw.Gyroscope_Offset_Data :=
        Raw.Set_Gyroscope_Offset (Value);
   begin
      Write (Device, Data, Success);
   end Set_Gyroscope_Offset;

   ------------------------------
   -- Set_Accelerometer_Offset --
   ------------------------------

   procedure Set_Accelerometer_Offset
     (Device  : Device_Context;
      Value   : Raw_Vector;
      Success : out Boolean)
   is
      Data : constant Raw.Accelerometer_Offset_Data :=
        Raw.Set_Accelerometer_Offset (Value);
   begin
      Write (Device, Data, Success);
   end Set_Accelerometer_Offset;

   ---------------------
   -- Set_Sample_Rate --
   ---------------------

   procedure Set_Sample_Rate
     (Device  : Device_Context;
      Value   : Sample_Rate_Divider;
      Success : out Boolean)
   is
      Data : constant Raw.Sample_Rate_Data :=
        Raw.Set_Sample_Rate (Value);
   begin
      Write (Device, Data, Success);
   end Set_Sample_Rate;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (Device  : Device_Context;
      Value   : Sensor_Configuration;
      Success : out Boolean)
   is
      Data : constant Raw.Configuration_Data :=
        Raw.Set_Configuration (Value);
   begin
      Write (Device, Data.Data_1, Success);

      if Success then
         Write (Device, Data.Data_2, Success);
      end if;
   end Configure;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Device  : Device_Context;
      Use_SPI : Boolean)
   is
      Ignore : Boolean;
   begin
      if Use_SPI then
         Write (Device, Raw.Set_I2C_Disabled, Ignore);
      end if;
   end Initialize;

   -----------------
   -- Is_Reseting --
   -----------------

   function Is_Reseting (Device  : Device_Context)  return Boolean is
      Ok   : Boolean;
      Data : Raw.Reset_Data;
   begin
      Read (Device, Data, Ok);

      return Ok and then Raw.Is_Reseting (Data);
   end Is_Reseting;

   ---------------
   -- Measuring --
   ---------------

   function Measuring (Device : Device_Context) return Boolean is
      use type Byte;

      Ok   : Boolean;
      Data : Byte_Array (16#3A# .. 16#3A#);
   begin
      Read (Device, Data, Ok);

      return not (Ok and (Data (Data'First) and 1) /= 0);
   end Measuring;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Device  : Device_Context;
      GFSR    : Gyroscope_Full_Scale_Range;
      AFSR    : Accelerometer_Full_Scale_Range;
      Gyro    : out Angular_Speed_Vector;
      Accel   : out Acceleration_Vector;
      Success : out Boolean)
   is
      Data : Raw.Measurement_Data;
   begin
      Read (Device, Data, Success);

      if Success then
         Raw.Get_Measurement (Data, GFSR, AFSR, Gyro, Accel);
      else
         Gyro := (others => 0.0);
         Accel := (others => 0.0);
      end if;
   end Read_Measurement;

   --------------------------
   -- Read_Raw_Measurement --
   --------------------------

   procedure Read_Raw_Measurement
     (Device  : Device_Context;
      Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean)
   is
      Data : Raw.Measurement_Data;
   begin
      Read (Device, Data, Success);

      if Success then
         Raw.Get_Raw_Measurement (Data, Gyro, Accel);
      end if;
   end Read_Raw_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Device  : Device_Context;
      Success : out Boolean) is
   begin
      Write (Device, Raw.Set_Reset, Success);
      --  PWR_MGMT_1: DEVICE_RESET
   end Reset;

end ICM20602.Internal;
