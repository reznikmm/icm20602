--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Interfaces;

package ICM20602 is
   pragma Preelaborate;
   pragma Discard_Names;

   type Power_Mode is
     (Standby,
      Off,
      Low_Power,
      Low_Noise);

   subtype Accelerometer_Power_Mode is Power_Mode range Off .. Low_Noise;

   subtype Gyroscope_Full_Scale_Range is Positive range 250 .. 2000
     with Static_Predicate =>
       Gyroscope_Full_Scale_Range in 250 | 500 | 1000 | 2000;

   subtype Accelerometer_Full_Scale_Range is Positive range 2 .. 16
     with Static_Predicate =>
       Accelerometer_Full_Scale_Range in 2 | 4 | 8 | 16;
   --  Full scale range for accelerometer: ±2g, ±4g, ±8g, ±16g

   subtype Average_Count is Positive range 1 .. 128
     with Static_Predicate =>
       Average_Count in 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128;

   subtype Accelerometer_Average_Count is Positive range 1 .. 32
     with Static_Predicate =>
       Accelerometer_Average_Count in 1 | 4 | 8 | 16 | 32;

   type Sensor_Rate is (Rate_4kHz, Rate_1kHz, Rate_8kHz, Rate_32kHz);
   pragma Ordered (Sensor_Rate);

   subtype Gyroscope_Sensor_Rate is Sensor_Rate range Rate_1kHz .. Rate_32kHz;
   --  What is ODR for Rate_32kHz_x?

   subtype Accelerometer_Sensor_Rate is
     Sensor_Rate range Rate_4kHz .. Rate_1kHz;

   subtype Low_Pass_Filter_Bandwidth is Positive range 5 .. 8173
     with Static_Predicate => Low_Pass_Filter_Bandwidth in
       250 | 176 | 92 | 41 | 20 | 10 | 5 | 3281 | 8173;
   --
   --  Sensor Low Pass Filter Bandwidth in Hz.

   type Gyroscope_Low_Pass_Filter_Configuration
     (Rate : Gyroscope_Sensor_Rate := Rate_1kHz) is
   record
      case Rate is
         when Rate_1kHz =>
            Bandwidth_1kHz : Low_Pass_Filter_Bandwidth range 5 .. 176;
         when Rate_8kHz =>
            Bandwidth_8kHz : Low_Pass_Filter_Bandwidth range 250 .. 3281;
         when Rate_32kHz =>
            Bandwidth_32kHz : Low_Pass_Filter_Bandwidth range 3281 .. 8173;
      end case;
   end record;

   type Gyroscope_Configuration (Power : Power_Mode := Low_Noise) is record
      case Power is
         when Off | Standby =>
            null;

         when Low_Power | Low_Noise =>
            FSR : Gyroscope_Full_Scale_Range;

            case Power is
               when Low_Noise =>
                  Filter : Gyroscope_Low_Pass_Filter_Configuration;
               when Low_Power =>
                  Average : Average_Count;
               when others =>
                  null;
            end case;
      end case;
   end record;

   subtype Accelerometer_Low_Pass_Filter_Bandwidth is Positive range 5 .. 1046
     with Static_Predicate =>
       Accelerometer_Low_Pass_Filter_Bandwidth in
         218 | 99 | 45 | 21 | 10 | 5 | 420 | 1046;

   type Accelerometer_Low_Pass_Filter_Configuration
     (Rate : Accelerometer_Sensor_Rate := Rate_1kHz) is
   record
      case Rate is
         when Rate_1kHz =>
            Bandwidth_1kHz : Accelerometer_Low_Pass_Filter_Bandwidth
              range 5 .. 420;
         when Rate_4kHz =>
            Bandwidth_4kHz : Accelerometer_Low_Pass_Filter_Bandwidth
              range 1046 .. 1046;
      end case;
   end record;

   type Accelerometer_Configuration
     (Power : Accelerometer_Power_Mode := Low_Noise) is
   record
      case Power is
         when Off =>
            null;

         when Low_Power | Low_Noise =>
            FSR : Accelerometer_Full_Scale_Range;

            case Power is
               when Low_Noise =>
                  Filter : Accelerometer_Low_Pass_Filter_Configuration;
               when Low_Power =>
                  Average : Accelerometer_Average_Count;
               when Off =>
                  null;
            end case;
      end case;
   end record;

   subtype Sample_Rate_Divider is Positive range 1 .. 256;
   --  Output data rate (ODR) is 1kHz / Sample_Rate_Divider.
   --
   --  For Gyroscope Low_Noise mode, it only effective when Gyroscope
   --  Low_Pass_Filter_Bandwidth < 250.
   --  For Gyroscope Low_Power mode it should be >= 3 (max ODR = 333Hz).
   --  For Accelerometer Low_Power mode it should be >= 2 (max ODR = 500Hz).
   --  Has no effect if Accelerometer.Filter = Rate_4kHz.

   type Sensor_Configuration is record
      Gyroscope     : Gyroscope_Configuration;
      Accelerometer : Accelerometer_Configuration;
      Rate_Divider  : Sample_Rate_Divider := 1;
   end record;

   type Raw_Vector is record
      X, Y, Z : Interfaces.Integer_16;
   end record;
   --  A value read from the sensor in raw format

   type Scaled_Angular_Speed is delta 1.0 / 2.0**17
     range -1.0 .. 1.0 - 1.0 / 2.0**17;
   --  The angular speed value is scaled such that 1.0 corresponds to 2000
   --  degrees per second.

   type Angular_Speed_Vector is record
      X, Y, Z : Scaled_Angular_Speed;
   end record;
   --  Angular velocity values for each axis. X, Y and Z also known as
   --  Roll, Peach and Yaw angles.

   type Acceleration is delta 1.0 / 2.0**14
     range -16.0 .. 16.0 - 1.0 / 2.0**14;
   --  The linear acceleration value is scaled such that 1.0 corresponds to
   --  1 G (9.8 m/s2).

   type Acceleration_Vector is record
      X, Y, Z : Acceleration;
   end record;
   --  Linear acceleration values for each axis

   type Accelerometer_Offset is delta 1.0 / 2.0**10
     range -16.0 .. 16.0 - 1.0 / 2.0**10;
   --  The accelerometer bias has 15 bits and ±16g range

   type Accelerometer_Offset_Vector is record
      X, Y, Z : Accelerometer_Offset;
   end record;
   --  Accelerometer bias for each axis

   Chip_Id : constant := 16#12#;
   --  Expected value for WHO_AM_I register

   subtype Register_Address is Natural range 16#00# .. 16#FF#;
   --  Sensor's register address

   subtype Byte is Interfaces.Unsigned_8;  --  Register value

   type Byte_Array is array (Register_Address range <>) of Byte;
   --  Bytes to be exchanged with registers. Index is a register address, while
   --  elements are corresponding register values.

end ICM20602;
