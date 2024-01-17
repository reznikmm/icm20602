--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with HAL.Time;

package ICM20602.Sensors is

   type Sensor is limited interface;

   procedure Initialize
     (Self  : Sensor;
      Timer : not null HAL.Time.Any_Delays) is abstract;
   --  Should be called before any other subrpogram call in this package

   function Check_Chip_Id
     (Self   : Sensor;
      Expect : HAL.UInt8 := 16#12#) return Boolean is abstract;
   --  Read the chip ID and check that it matches

   procedure Reset
     (Self    : Sensor;
      Timer   : not null HAL.Time.Any_Delays;
      Success : out Boolean) is abstract;
   --  Issue a soft reset and wait until the chip is ready.

   procedure Configure
     (Self    : in out Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean) is abstract;
   --  Setup sensor configuration, including
   --  * power mode
   --  * full scale rate
   --  * low-pass filter (or average counter for low power mode)
   --  * rate divider to set output data rate (ODR)
   --
   --  Configuration example:
   --
   --  Sensor.Configure
   --    ((Gyroscope     =>
   --       (Power  => ICM20602.Low_Noise,
   --        FSR    => 250,  --  full scale range => -250 .. +250 dps
   --        Filter =>  --  Low-pass filter 176Hz on 1kHz rate
   --          (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
   --      Accelerometer =>
   --        (Power  => ICM20602.Low_Noise,
   --         FSR    => 2,  --  full scale range => -2g .. +2g
   --         Filter =>  --  Low-pass filter 176Hz on 1kHz rate
   --           (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
   --      Rate_Divider  => 2),  --  Divide 1kHz rate by 2, so ODR = 500Hz
   --     Ok);

   function Measuring (Self : Sensor) return Boolean is abstract;
   --  Check if a measurement is in progress

   procedure Read_Measurement
     (Self    : Sensor;
      Gyro    : out Angular_Speed_Vector;
      Accel   : out Acceleration_Vector;
      Success : out Boolean) is abstract;
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Self    : Sensor;
      Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean) is abstract;
   --  Read raw measurement values from the sensor

end ICM20602.Sensors;
