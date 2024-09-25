--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Unchecked_Conversion;

package body ICM20602.Raw is

   ---------------------
   -- Get_Measurement --
   ---------------------

   procedure Get_Measurement
     (Raw   : Byte_Array;
      GFSR  : Gyroscope_Full_Scale_Range;
      AFSR  : Accelerometer_Full_Scale_Range;
      Gyro  : out Angular_Speed_Vector;
      Accel : out Acceleration_Vector)
   is
      subtype Int is Integer range -2**15 .. 2**15 - 1;

      Raw_G : Raw_Vector;
      Raw_A : Raw_Vector;
   begin
      Get_Raw_Measurement (Raw, Raw_G, Raw_A);

      case GFSR is
         when 250 =>
            Gyro :=
              (X => Int (Raw_G.X) * Scaled_Angular_Speed'Small,
               Y => Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
               Z => Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
         when 500  =>
            Gyro :=
              (X => 2 * Int (Raw_G.X) * Scaled_Angular_Speed'Small,
               Y => 2 * Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
               Z => 2 * Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
         when 1000  =>
            Gyro :=
              (X => 4 * Int (Raw_G.X) * Scaled_Angular_Speed'Small,
               Y => 4 * Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
               Z => 4 * Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
         when 2000 =>
            Gyro :=
              (X => 8 * Int (Raw_G.X) * Scaled_Angular_Speed'Small,
               Y => 8 * Int (Raw_G.Y) * Scaled_Angular_Speed'Small,
               Z => 8 * Int (Raw_G.Z) * Scaled_Angular_Speed'Small);
      end case;

      case AFSR is
         when 2 =>
            Accel :=
              (X => Int (Raw_A.X) * Acceleration'Small,
               Y => Int (Raw_A.Y) * Acceleration'Small,
               Z => Int (Raw_A.Z) * Acceleration'Small);
         when 4  =>
            Accel :=
              (X => 2 * Int (Raw_A.X) * Acceleration'Small,
               Y => 2 * Int (Raw_A.Y) * Acceleration'Small,
               Z => 2 * Int (Raw_A.Z) * Acceleration'Small);
         when 8  =>
            Accel :=
              (X => 4 * Int (Raw_A.X) * Acceleration'Small,
               Y => 4 * Int (Raw_A.Y) * Acceleration'Small,
               Z => 4 * Int (Raw_A.Z) * Acceleration'Small);
         when 16 =>
            Accel :=
              (X => 8 * Int (Raw_A.X) * Acceleration'Small,
               Y => 8 * Int (Raw_A.Y) * Acceleration'Small,
               Z => 8 * Int (Raw_A.Z) * Acceleration'Small);
      end case;
   end Get_Measurement;

   -------------------------
   -- Get_Raw_Measurement --
   -------------------------

   procedure Get_Raw_Measurement
     (Raw   : Byte_Array;
      Gyro  : out Raw_Vector;
      Accel : out Raw_Vector)
   is
      use Interfaces;

      function Cast is new Ada.Unchecked_Conversion
        (Unsigned_16, Integer_16);

      function Decode (Data : Byte_Array) return Integer_16 is
         (Cast (Shift_Left (Unsigned_16 (Data (Data'First)), 8)
            + Unsigned_16 (Data (Data'Last))));

   begin
      Accel.X := Decode (Raw (16#3B# .. 16#3C#));
      Accel.Y := Decode (Raw (16#3D# .. 16#3E#));
      Accel.Z := Decode (Raw (16#3F# .. 16#40#));
      Gyro.X := Decode (Raw (16#43# .. 16#44#));
      Gyro.Y := Decode (Raw (16#45# .. 16#46#));
      Gyro.Z := Decode (Raw (16#47# .. 16#48#));
   end Get_Raw_Measurement;

   -----------------------
   -- Set_Configuration --
   -----------------------

   function Set_Configuration
     (Value : Sensor_Configuration) return Configuration_Data
   is
      FCHOICE_B : constant Byte :=
        (if Value.Gyroscope.Power = Low_Noise then
           (case Value.Gyroscope.Filter.Rate is
               when Rate_1kHz | Rate_8kHz => 0,
               when Rate_32kHz =>
                 (case Value.Gyroscope.Filter.Bandwidth_32kHz is
                     when 8173 => 1,
                     when 3281 => 2,
                     when others => 0))
         else 0);

      FS_SEL : constant Byte :=
        (if Value.Gyroscope.Power in Off | Standby then 0
         else
           (case Value.Gyroscope.FSR is
               when 250  => 0,
               when 500  => 1,
               when 1000 => 2,
               when 2000 => 3));

      DLPF_CFG : constant Byte :=
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
         else 1);

      ACCEL_FS_SEL : constant Byte :=
        (if Value.Accelerometer.Power = Off then 0
         else
           (case Value.Accelerometer.FSR is
               when 2  => 0,
               when 4  => 1,
               when 8  => 2,
               when 16 => 3));

      DEC2_CFG : constant Byte :=
        (if Value.Accelerometer.Power = Low_Power then
           (case Value.Accelerometer.Average is
              when 4 => 0,
              when 8 => 1,
              when 16 => 2,
              when 32 => 3)
         else 0);

      ACCEL_FCHOICE_B : constant Byte :=
        (if Value.Accelerometer.Power = Low_Noise then
           (case Value.Accelerometer.Filter.Rate is
               when Rate_4kHz => 1,
               when Rate_1kHz => 0)
         else 0);

      A_DLPF_CFG : constant Byte :=
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

      GYRO_CYCLE : constant Byte :=
        (if Value.Gyroscope.Power = Low_Power then 1 else 0);

      G_AVGCFG : constant Byte :=
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

      Data_1 : constant Byte_Array (16#19# .. 16#1E#) :=
        (16#19# => Byte (Value.Rate_Divider - 1),  --  SMPLRT_DIV
         16#1A# => DLPF_CFG,                --  CONFIG
         16#1B# => FS_SEL * 8 + FCHOICE_B,  --  GYRO_CONFIG
         16#1C# => ACCEL_FS_SEL * 8,        --  ACCEL_CONFIG
         16#1D# =>                          --  ACCEL_CONFIG2
           DEC2_CFG * 16 + ACCEL_FCHOICE_B * 8 + A_DLPF_CFG,
         16#1E# => GYRO_CYCLE * 128 + G_AVGCFG * 16);  --  LP_MODE_CFG

      CYCLE : constant Byte :=
        (if Value.Accelerometer.Power = Low_Power then 1 else 0);
      GYRO_STANDBY : constant Byte :=
        (if Value.Gyroscope.Power = Standby then 1 else 0);
      TEMP_DIS : constant Byte :=
        (if Value.Gyroscope.Power = Off
         and Value.Accelerometer.Power = Off then 1 else 0);
      STBY_A : constant Byte :=
        (if Value.Accelerometer.Power = Off then 7 else 0);
      STBY_G : constant Byte :=
        (if Value.Gyroscope.Power in Off | Standby then 7 else 0);

      Data_2 : constant Byte_Array (16#6B# .. 16#6C#) :=
         (16#6B# => CYCLE * 32 + GYRO_STANDBY * 16 + TEMP_DIS * 8 + 1,
          16#6C# => STBY_A * 8 + STBY_G);
   begin
      return (Data_1, Data_2);
   end Set_Configuration;

   --------------------
   -- Set_Interrupts --
   --------------------

   function Set_Interrupts
     (Active_Is_Low      : Boolean := False;
      Is_Open_Drain      : Boolean := False;
      Is_Latched         : Boolean := False;
      Clear_On_Read      : Boolean := False;
      FSync_Enabled      : Boolean := False;
      Wake_On_X_Enabled  : Boolean := False;
      Wake_On_Y_Enabled  : Boolean := False;
      Wake_On_Z_Enabled  : Boolean := False;
      Gyro_Ready_Enabled : Boolean := False;
      Data_Ready_Enabled : Boolean := False) return Configure_Interrupts_Data
   is

      INT_PIN_CFG : constant Byte :=
        (if Active_Is_Low then 2**7 else 0) +
        (if Is_Open_Drain then 2**6 else 0) +
        (if Is_Latched then 2**5 else 0) +
        (if Clear_On_Read then 2**4 else 0) +
        (if FSync_Enabled then 2**2 else 0);

      INT_ENABLE : constant Byte :=
        (if Wake_On_X_Enabled then 2**7 else 0) +
        (if Wake_On_Y_Enabled then 2**6 else 0) +
        (if Wake_On_Z_Enabled then 2**5 else 0) +
        (if Gyro_Ready_Enabled then 2**2 else 0) +
        (if Data_Ready_Enabled then 2**0 else 0);
   begin
      return (16#37# => INT_PIN_CFG, 16#38# => INT_ENABLE);
   end Set_Interrupts;

end ICM20602.Raw;
