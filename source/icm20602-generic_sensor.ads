--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This generic package contains shared code independent of the sensor
--  connection method. Following the Singleton pattern, it is convenient
--  when using only one sensor is required.

with HAL.Time;

generic
   with procedure Read
     (Data    : out HAL.UInt8_Array;
      Success : out Boolean);
   --  Read the values from the ICM20602 chip registers into Data.
   --  Each element in the Data corresponds to a specific register address
   --  in the chip, so Data'Range determines the range of registers to read.
   --  The value read from register X will be stored in Data(X), so
   --  Data'Range should be of the Register_Address subtype.

   with procedure Write
     (Data    : HAL.UInt8_Array;
      Success : out Boolean);
   --  Write Data values to the ICM20602 chip registers.

package ICM20602.Generic_Sensor is

   procedure Initialize;
   --  Should be called before any other subrpogram call in this package

   function Check_Chip_Id (Expect : HAL.UInt8 := 16#12#) return Boolean;
   --  Read the chip ID and check that it matches

   procedure Reset
     (Timer   : not null HAL.Time.Any_Delays;
      Success : out Boolean);
   --  Issue a soft reset and wait until the chip is ready.

   procedure Configure
     (Value   : Sensor_Configuration;
      Success : out Boolean);
   --  TBD

   function Measuring return Boolean;
   --  Check if a measurement is in progress

   procedure Read_Measurement
     (Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

end ICM20602.Generic_Sensor;
