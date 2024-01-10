--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Interfaces;

package ICM20602 is
   pragma Preelaborate;
   pragma Discard_Names;

   subtype Gyroscope_Range is Positive
     with Static_Predicate =>
       Gyroscope_Range in 250 | 500 | 1000 | 2000;

   subtype Gyroscope_Full_Scale_Range is Positive range 250 .. 2000
     with Static_Predicate =>
       Gyroscope_Full_Scale_Range in 250 | 500 | 1000 | 2000;

   --  Digitally-programmable low-pass filter??? 32kHz?

   subtype Accelerometer_Full_Scale_Range is Positive range 2 .. 16
     with Static_Predicate =>
       Accelerometer_Full_Scale_Range in 2 | 4 | 8 | 16;

   subtype Average_Count is Positive range 1 .. 128
     with Static_Predicate =>
       Average_Count in 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128;

   subtype Accelerometer_Average_Count is Average_Count range 4 .. 32;

   type Gyroscope_Low_Pass_Filter_Mode is
     (Rate_32kHz_Bandwidth_8173Hz,
      Rate_32kHz_Bandwidth_3281Hz,
      Other_Rate);
   --  Gyroscope Low Pass Filter configuration mode. Bandwidth is 3dB in Hz.
   --  What is ODR for Rate_32kHz_x?

   subtype Gyroscope_Low_Pass_Filter_Bandwidth is Positive range 5 .. 3281
     with Static_Predicate =>
       Gyroscope_Low_Pass_Filter_Bandwidth in
         250 | 176 | 92 | 41 | 20 | 10 | 5 | 3281;
   --  Gyroscope Low Pass Filter Bandwidth in Hz of rates less then 32kHz.
   --  Rate is 1kHz if bandwidth < 250 and 8kHz otherwise.

   type Gyroscope_Low_Pass_Filter_Configuration
     (Mode : Gyroscope_Low_Pass_Filter_Mode := Other_Rate) is
   record
      case Mode is
         when Other_Rate =>
            Bandwidth : Gyroscope_Low_Pass_Filter_Bandwidth;
         when others =>
            null;
      end case;
   end record;

   type Gyroscope_Configuration (Low_Power : Boolean := False) is record
      FSR : Gyroscope_Full_Scale_Range;

      case Low_Power is
         when False =>
            --  Low-Noise mode
            Filter : Gyroscope_Low_Pass_Filter_Configuration;
         when True =>
            --  Low-Power mode
            Average : Average_Count;
      end case;
   end record;

   type Accelerometer_Low_Pass_Filter_Mode is
     (Rate_4kHz_Bandwidth_1046Hz,
      Rate_1kHz);
   --  Accelerometer Low Pass Filter configuration mode
   --  What is ODR for Rate_4kHz_x? I guess 4kHz.
   --  What is ODR for Rate_4kHz_x in low-power mode?

   subtype Accelerometer_Low_Pass_Filter_Bandwidth is Positive range 5 .. 420
     with Static_Predicate =>
       Accelerometer_Low_Pass_Filter_Bandwidth in
         218 | 99 | 45 | 21 | 10 | 5 | 420;

   type Accelerometer_Low_Pass_Filter_Configuration
     (Mode : Accelerometer_Low_Pass_Filter_Mode := Rate_1kHz) is
   record
      case Mode is
         when Rate_1kHz =>
            Bandwidth : Accelerometer_Low_Pass_Filter_Bandwidth;
         when others =>
            null;
      end case;
   end record;

   type Accelerometer_Configuration (Low_Power : Boolean := False) is record
      FSR : Accelerometer_Full_Scale_Range;

      case Low_Power is
         when False =>
            --  Low-Noise mode
            Filter : Accelerometer_Low_Pass_Filter_Configuration;
            --  Average??? Does Average works in Low-Noise mode?
         when True =>
            --  Low-Power mode
            Average : Accelerometer_Average_Count;
            --  Does Average works in Low-Noise mode?
      end case;
   end record;

   subtype Sample_Rate_Divider is Positive range 1 .. 256;
   --  Output data rate (ODR) is 1kHz / Sample_Rate_Divider.
   --  only effective when Gyroscope_Low_Pass_Filter_Bandwidth < 250

   type Sensor_Configuration (Low_Power : Boolean := False) is record
      Gyroscope     : Gyroscope_Configuration (Low_Power);
      Accelerometer : Accelerometer_Configuration (Low_Power);
      Rate_Divider  : Sample_Rate_Divider := 1;
   end record;

   type Raw_Vector is record
      X, Y, Z : Interfaces.Integer_16;
   end record;

end ICM20602;
