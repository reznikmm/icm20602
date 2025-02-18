--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

generic
   type Device_Context (<>) is limited private;

   with procedure Read
     (Device  : Device_Context;
      Data    : out Byte_Array;
      Success : out Boolean);
   --  Read the values from the ICM-20602 chip registers into Data.
   --  Each element in the Data corresponds to a specific register address
   --  in the chip, so Data'Range determines the range of registers to read.
   --  The value read from register X will be stored in Data(X), so
   --  Data'Range should be of the Register_Address subtype.

   with procedure Write
     (Device  : Device_Context;
      Data    : Byte_Array;
      Success : out Boolean);
   --  Write the Data values to the ICM-20602 chip registers.
   --  Each element in the Data corresponds to a specific register address
   --  in the chip, so Data'Range determines the range of registers to write.
   --  The value read from Data(X) will be stored in register X, so
   --  Data'Range should be of the Register_Address subtype.

package ICM20602.Internal is

   procedure Initialize
     (Device  : Device_Context;
      Use_SPI : Boolean);
   --  Should be called before any other subrpogram call in this package

   function Check_Chip_Id
     (Device : Device_Context;
      Expect : Byte) return Boolean;
   --  Read the chip ID and check that it matches

   procedure Set_Gyroscope_Offset
     (Device  : Device_Context;
      Value   : Raw_Vector;
      Success : out Boolean);
   --  Set REGISTER 19..24 GYRO OFFSET ADJUSTMENT REGISTER
   --  Current scale???

   procedure Set_Accelerometer_Offset
     (Device  : Device_Context;
      Value   : Raw_Vector;
      Success : out Boolean);
   --  Set REGISTER 119..126 ACCELEROMETER OFFSET ADJUSTMENT REGISTER
   --  In +/- 16g scale. 15 bits!!!

   procedure Set_Sample_Rate
     (Device  : Device_Context;
      Value   : Sample_Rate_Divider;
      Success : out Boolean);
   --  Set REGISTER 25 SAMPLE RATE DIVIDER

   procedure Configure
     (Device  : Device_Context;
      Value   : Sensor_Configuration;
      Success : out Boolean);

   procedure Reset
     (Device  : Device_Context;
      Success : out Boolean);
   --  Issue a soft reset without a wait until the chip is ready.

   function Is_Reseting (Device  : Device_Context)  return Boolean;
   --  Check if the reset is in progress.

   function Measuring (Device  : Device_Context) return Boolean;
   --  Check if a measurement is in progress

   procedure Read_Measurement
     (Device  : Device_Context;
      GFSR    : Gyroscope_Full_Scale_Range;
      AFSR    : Accelerometer_Full_Scale_Range;
      Gyro    : out Angular_Speed_Vector;
      Accel   : out Acceleration_Vector;
      Success : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Device  : Device_Context;
      Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean);
   --  Read the raw measurement values from the sensor

end ICM20602.Internal;
