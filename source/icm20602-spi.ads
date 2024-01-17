--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package offers a straightforward method for setting up the ICM-20602
--  when connected via SPI, especially useful when the use of only one sensor
--  is required. If you need multiple sensors, it is preferable to use the
--  ICM20602.SPI_Sensors package, which provides the appropriate tagged type.

with HAL.SPI;
with HAL.Time;
with HAL.GPIO;

generic
   SPI_Port : not null HAL.SPI.Any_SPI_Port;
   SPI_CS   : not null HAL.GPIO.Any_GPIO_Point;
package ICM20602.SPI is

   procedure Initialize (Timer : not null HAL.Time.Any_Delays);
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
   --  Setup sensor configuration, including
   --  * power mode
   --  * full scale rate
   --  * low-pass filter (or average counter for low power mode)
   --  * rate divider to set output data rate (ODR)
   --
   --  Configuration example:
   --
   --  Configure
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

   function Measuring return Boolean;
   --  Check if a measurement is in progress

   procedure Read_Measurement
     (Gyro    : out Angular_Speed_Vector;
      Accel   : out Acceleration_Vector;
      Success : out Boolean);
   --  Read scaled measurement values from the sensor

   procedure Read_Raw_Measurement
     (Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean);
   --  Read raw measurement values from the sensor

end ICM20602.SPI;
