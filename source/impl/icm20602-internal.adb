--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

with Ada.Unchecked_Conversion;

package body ICM20602.Internal is

   -------------------
   -- Check_Chip_Id --
   -------------------

   function Check_Chip_Id
     (Device : Device_Context;
      Expect : HAL.UInt8) return Boolean
   is
      use type HAL.UInt8_Array;

      Ok   : Boolean;
      Data : HAL.UInt8_Array (16#75# .. 16#75#);
   begin
      Read (Device, Data, Ok);

      return Ok and Data = [Expect];
   end Check_Chip_Id;

   --------------------------
   -- Set_Gyroscope_Offset --
   --------------------------

   procedure Set_Gyroscope_Offset
     (Device  : Device_Context;
      Value   : Raw_Vector;
      Success : out Boolean)
   is
      use type Interfaces.Integer_16;

      Data : constant HAL.UInt8_Array (16#13# .. 16#18#) :=
        [HAL.UInt8 (Value.X / 256),
         HAL.UInt8 (Value.X mod 256),
         HAL.UInt8 (Value.Y / 256),
         HAL.UInt8 (Value.Y mod 256),
         HAL.UInt8 (Value.Z / 256),
         HAL.UInt8 (Value.Z mod 256)];
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
      use type Interfaces.Integer_16;

      Data_X : constant HAL.UInt8_Array (16#77# .. 16#78#) :=
        [HAL.UInt8 (Value.X / 256),
         HAL.UInt8 (Value.X mod 256)];
      Data_Y : constant HAL.UInt8_Array (16#7A# .. 16#7B#) :=
        [HAL.UInt8 (Value.Y / 256),
         HAL.UInt8 (Value.Y mod 256)];
      Data_Z : constant HAL.UInt8_Array (16#7D# .. 16#7E#) :=
        [HAL.UInt8 (Value.Z / 256),
         HAL.UInt8 (Value.Z mod 256)];
   begin
      Write (Device, Data_X, Success);

      if Success then
         Write (Device, Data_Y, Success);
      end if;

      if Success then
         Write (Device, Data_Z, Success);
      end if;
   end Set_Accelerometer_Offset;

   ---------------------
   -- Set_Sample_Rate --
   ---------------------

   procedure Set_Sample_Rate
     (Device  : Device_Context;
      Value   : Sample_Rate_Divider;
      Success : out Boolean)
   is
      Data : constant HAL.UInt8_Array (16#19# .. 16#19#) :=
        [HAL.UInt8 (Value - 1)];
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
      use type HAL.UInt8;

      FCHOICE_B : constant HAL.UInt8 :=
        (if Value.Gyroscope.Power = Low_Noise then
           (case Value.Gyroscope.Filter.Rate is
               when Rate_1kHz | Rate_8kHz => 0,
               when Rate_32kHz =>
                 (case Value.Gyroscope.Filter.Bandwidth_32kHz is
                     when 8173 => 1,
                     when 3281 => 2,
                     when others => 0))
         else 0);

      FS_SEL : constant HAL.UInt8 :=
        (if Value.Gyroscope.Power in Off | Standby then 0
         else
           (case Value.Gyroscope.FSR is
               when 250  => 0,
               when 500  => 1,
               when 1000 => 2,
               when 2000 => 3));

      DLPF_CFG : constant HAL.UInt8 :=
        (if Value.Gyroscope.Power = Low_Noise then
           (case Value.Gyroscope.Filter.Rate is
               when Rate_1kHz =>
                 (case Value.Gyroscope.Filter.Bandwidth_1kHz is
                     when 176 => 1,
                     when 92  => 2,
                     when 41  => 3,
                     when 20  => 4,
                     when 10  => 5,
                     when 5   => 6,
                     when others => 0),
               when Rate_8kHz =>
                 (case Value.Gyroscope.Filter.Bandwidth_8kHz is
                     when 250  => 0,
                     when 3281 => 7,
                     when others => 0),
               when Rate_32kHz => 0)
         else 0);

      ACCEL_FS_SEL : constant HAL.UInt8 :=
        (if Value.Accelerometer.Power = Off then 0
         else
           (case Value.Accelerometer.FSR is
               when 2  => 0,
               when 4  => 1,
               when 8  => 2,
               when 16 => 3));

      DEC2_CFG : constant HAL.UInt8 :=
        (if Value.Accelerometer.Power = Low_Power then
           (case Value.Accelerometer.Average is
              when 4 => 0,
              when 8 => 1,
              when 16 => 2,
              when 32 => 3)
         else 0);

      ACCEL_FCHOICE_B : constant HAL.UInt8 :=
        (if Value.Accelerometer.Power = Low_Noise then
           (case Value.Accelerometer.Filter.Rate is
               when Rate_4kHz => 1,
               when Rate_1kHz => 0)
         else 0);

      A_DLPF_CFG : constant HAL.UInt8 :=
        (if Value.Accelerometer.Power = Low_Noise
          and then Value.Accelerometer.Filter.Rate = Rate_1kHz then
           (case Value.Accelerometer.Filter.Bandwidth_1kHz is
               when 218 => 1,  --  0?
               when 99  => 2,
               when 45  => 3,
               when 21  => 4,
               when 10  => 5,
               when 5   => 6,
               when 420 => 7,
               when others => 0)
         else 0);

      GYRO_CYCLE : constant HAL.UInt8 :=
        (if Value.Gyroscope.Power = Low_Power then 1 else 0);

      G_AVGCFG : constant HAL.UInt8 :=
        (if Value.Gyroscope.Power = Low_Power then
           (case Value.Gyroscope.Average is
              when 1   => 0,
              when 2   => 1,
              when 4   => 2,
              when 8   => 3,
              when 16  => 4,
              when 32  => 5,
              when 64  => 6,
              when 128 => 7)
         else 0);

      Data : constant HAL.UInt8_Array (16#19# .. 16#1E#) :=
        [16#19# => HAL.UInt8 (Value.Rate_Divider - 1),  --  SMPLRT_DIV
         16#1A# => DLPF_CFG,                --  CONFIG
         16#1B# => FS_SEL * 8 + FCHOICE_B,  --  GYRO_CONFIG
         16#1C# => ACCEL_FS_SEL * 8,        --  ACCEL_CONFIG
         16#1D# =>                          --  ACCEL_CONFIG2
           DEC2_CFG * 16 + ACCEL_FCHOICE_B * 8 + A_DLPF_CFG,
         16#1E# => GYRO_CYCLE * 128 + G_AVGCFG * 16];  --  LP_MODE_CFG
   begin
      Write (Device, Data, Success);

      if Success then
         declare
            CYCLE : constant HAL.UInt8 :=
              (if Value.Accelerometer.Power = Low_Power then 1 else 0);
            GYRO_STANDBY : constant HAL.UInt8 :=
              (if Value.Gyroscope.Power = Standby then 1 else 0);
            TEMP_DIS : constant HAL.UInt8 :=
              (if Value.Gyroscope.Power = Off
               and Value.Accelerometer.Power = Off then 1 else 0);
            STBY_A : constant HAL.UInt8 :=
              (if Value.Accelerometer.Power = Off then 7 else 0);
            STBY_G : constant HAL.UInt8 :=
              (if Value.Gyroscope.Power in Off | Standby then 7 else 0);
         begin
            Write
              (Device,
               [16#6B# => CYCLE * 32 + GYRO_STANDBY * 16 + TEMP_DIS * 8 + 1,
                16#6C# => STBY_A * 8 + STBY_G],
               Success);
         end;
      end if;
   end Configure;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Device : Device_Context) is
      Aux : constant HAL.UInt8_Array (16#75# .. 16#74#) := [];
      Ignore : Boolean;
   begin
      Write (Device, Aux, Ignore);
   end Initialize;

   ---------------
   -- Measuring --
   ---------------

   function Measuring (Device : Device_Context) return Boolean is
      use type HAL.UInt8;

      Ok   : Boolean;
      Data : HAL.UInt8_Array (16#3A# .. 16#3A#);
   begin
      Read (Device, Data, Ok);

      return not (Ok and (Data (Data'First) and 1) /= 0);
   end Measuring;

   ----------------------
   -- Read_Measurement --
   ----------------------

   procedure Read_Measurement
     (Device  : Device_Context;
      Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean)
   is
      use Interfaces;

      function Cast is new Ada.Unchecked_Conversion
        (Unsigned_16, Integer_16);

      function Decode (Data : HAL.UInt8_Array) return Integer_16 is
         (Cast (Shift_Left (Unsigned_16 (Data (Data'First)), 8)
            + Unsigned_16 (Data (Data'Last))));

      Data : HAL.UInt8_Array (16#3B# .. 16#48#);
   begin
      Read (Device, Data, Success);

      if Success then
         Accel.X := Decode (Data (16#3B# .. 16#3C#));
         Accel.Y := Decode (Data (16#3D# .. 16#3E#));
         Accel.Z := Decode (Data (16#3F# .. 16#40#));
         Gyro.X := Decode (Data (16#43# .. 16#44#));
         Gyro.Y := Decode (Data (16#45# .. 16#46#));
         Gyro.Z := Decode (Data (16#47# .. 16#48#));
      end if;
   end Read_Measurement;

   -----------
   -- Reset --
   -----------

   procedure Reset
     (Device  : Device_Context;
      Timer   : not null HAL.Time.Any_Delays;
      Success : out Boolean)
   is
   begin
      Write (Device, [16#6B# => 16#80#], Success);
      --  PWR_MGMT_1: DEVICE_RESET

      while Success loop
         declare
            use type HAL.UInt8;
            PWR_MGMT_1 : HAL.UInt8_Array (16#6B# .. 16#6B#);
         begin
            Timer.Delay_Milliseconds (1);
            Read (Device, PWR_MGMT_1, Success);

            exit when (PWR_MGMT_1 (PWR_MGMT_1'First) and 16#80#) = 0;
         end;
      end loop;

      if Success then
         Write
           (Device,
            [16#69# => 16#02#, 16#6A# => 5, 16#6B# => 1, 16#6C# => 0],
            Success);
         --  ACCEL_INTEL_CTRL/OUTPUT_LIMIT
         --  To avoid limiting sensor output to less than 0x7FFF, set this bit
         --  to 1. This should be done every time the ICM-20602 is powered up.
         --
         --  USER_CTRL: FIFO_RST, SIG_COND_RST
         --  PWR_MGMT_1: CLKSEL=1
         --  PWR_MGMT_2: enable all axis
      end if;

      if Success then
         Write (Device, [16#37# => 16#10#, 16#38# => 1], Success);
         --  INT_PIN_CFG: INT_RD_CLEAR
         --  INT_ENABLE: DATA_RDY_INT_EN
      end if;
   end Reset;

end ICM20602.Internal;
