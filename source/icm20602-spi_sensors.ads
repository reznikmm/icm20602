--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package offers a straightforward method for setting up the ICM-20602
--  when connected via SPI, especially useful when you need multiple sensors
--  of this kind. If you use only one sensor, it could be preferable to use the
--  ICM20602.SPI generic package.

with HAL.GPIO;
with HAL.SPI;
with HAL.Time;

with ICM20602.Sensors;

package ICM20602.SPI_Sensors is

   type ICM20602_SPI_Sensor
     (SPI_Port : not null HAL.SPI.Any_SPI_Port;
      SPI_CS   : not null HAL.GPIO.Any_GPIO_Point) is
        limited new ICM20602.Sensors.Sensor with private;

   overriding procedure Initialize
     (Self  : ICM20602_SPI_Sensor;
      Timer : not null HAL.Time.Any_Delays);
   --  Should be called before any other subrpogram call in this package

   overriding function Check_Chip_Id
     (Self   : ICM20602_SPI_Sensor;
      Expect : Byte := Chip_Id) return Boolean;
   --  Read the chip ID and check that it matches

   overriding procedure Reset
     (Self    : ICM20602_SPI_Sensor;
      Success : out Boolean);
   --  Issue a soft reset and wait until the chip is ready.

   overriding function Is_Reseting (Self : ICM20602_SPI_Sensor) return Boolean;
   --  Check if the reset is in progress.

   overriding procedure Configure
     (Self    : in out ICM20602_SPI_Sensor;
      Value   : Sensor_Configuration;
      Success : out Boolean);
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

   overriding function Measuring (Self : ICM20602_SPI_Sensor) return Boolean;
   --  Check if a measurement is in progress

   overriding procedure Read_Measurement
     (Self    : ICM20602_SPI_Sensor;
      Gyro    : out Angular_Speed_Vector;
      Accel   : out Acceleration_Vector;
      Success : out Boolean);
   --  Read scaled measurement values from the sensor

   overriding procedure Read_Raw_Measurement
     (Self    : ICM20602_SPI_Sensor;
      Gyro    : out Raw_Vector;
      Accel   : out Raw_Vector;
      Success : out Boolean);
   --  Read raw measurement values from the sensor

private

   type ICM20602_SPI_Sensor
     (SPI_Port : not null HAL.SPI.Any_SPI_Port;
      SPI_CS   : not null HAL.GPIO.Any_GPIO_Point) is
        limited new ICM20602.Sensors.Sensor with
   record
      GFSR : Gyroscope_Full_Scale_Range := 250;
      AFSR : Accelerometer_Full_Scale_Range := 2;
   end record;

end ICM20602.SPI_Sensors;
