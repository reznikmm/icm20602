# ICM-20602

[![Build status](https://github.com/reznikmm/icm20602/actions/workflows/alire.yml/badge.svg)](https://github.com/reznikmm/icm20602/actions/workflows/alire.yml)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/icm20602.json)](https://alire.ada.dev/crates/icm20602.html)
[![REUSE status](https://api.reuse.software/badge/github.com/reznikmm/icm20602)](https://api.reuse.software/info/github.com/reznikmm/icm20602)

> An Ada driver for 3-axis gyroscope, 3-axis accelerometer

- [Datasheet](https://invensense.tdk.com/download-pdf/icm-20602-datasheet/)

The sensor is available as a module for DIY projects from various
manufacturers, such as
[6DOF IMU 4 Click](https://www.mikroe.com/6dof-imu-4-click)
or (like mine) [unbranded](https://aliexpress.com/item/1005003998548428.html).
It boasts high precision, low power consumption, a compact size, and the
flexibility to connect via both I2C and SPI interfaces.

The ICM-20602 driver enables the following functionalities:

- Detect the presence of the sensor.
- Perform a reset operation.
- Configure the range, the parameters of the digital filter and sampling rate
  for each channel.
- Adjust offsets for gyroscope and accelerometer.
- Conduct measurements as raw 16-bit values and scaled values.
- Configure interrupts ~~and Wake-on-motion (TBD)~~

## Install

Add `icm20602` as a dependency to your crate with Alire:

    alr with icm20602

## Usage

The sensor supports SPI (mode 0 or 3) with a frequency of up to 10 MHz
and I2C at frequencies up to 400 kHz.

> ### Note
>
> In my configuration of icm-20602 with ADL stm32f407, I cannot get
> `HAL.I2C.Read_Mem` to work correctly until I make an artificial call to
> `HAL.I2C.Master_Transmit`. I have not yet figured out why this is happening.
> I guess there is an issue in I2C in Ada Driver Library.
> I need to investigate. I have left this call before calling the `Initialize`
> procedure for now, it should not interfere.

The driver implements two usage models: the generic package, which is more
convenient when dealing with a single sensor, and the tagged type, which
allows easy creation of objects for any number of sensors and uniform handling.

Generic instantiation looks like this:

```ada
declare
   package ICM20602_I2C is new ICM20602.I2C
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#69#);

begin
   ICM20602_I2C.Initialize (Ravenscar_Time.Delays);

   if ICM20602_I2C.Check_Chip_Id then
      ICM20602_I2C.Reset (Ravenscar_Time.Delays, Ok);
      ...
```

While declaring object of the tagged type looks like this:

```ada
declare
   Sensor : ICM20602.I2C_Sensors.ICM20602_I2C_Sensor :=
     (I2C_Port    => STM32.Device.I2C_1'Access,
      I2C_Address => 16#69#);
begin
   Sensor.Initialize (Ravenscar_Time.Delays);

   if Sensor.Check_Chip_Id then
      Sensor.Reset (Ravenscar_Time.Delays, Ok);
      ...
```
### Configuring the Sensor

The sensor is configured by passing a single configuration record of type
`Sensor_Configuration` to the Configure procedure. This record contains all
the settings for the gyroscope, accelerometer, and the final output data rate.

The main configuration record is defined as follows:

```ada
type Sensor_Configuration is record
   Gyroscope     : Gyroscope_Configuration;
   Accelerometer : Accelerometer_Configuration;
   Rate_Divider  : Sample_Rate_Divider := 1;
end record;
```

It has three key fields:

- `Gyroscope`: Holds all settings specific to the gyroscope.
- `Accelerometer`: Holds all settings specific to the accelerometer.
- `Rate_Divider`: An integer used to set the final Output Data Rate (ODR).
  See the section on ODR below for details.

**Important Constraint**: The sensor hardware does not support running both
the gyroscope and the accelerometer in `Low_Power` mode simultaneously.
The driver enforces this with a dynamic predicate on the
`Sensor_Configuration` type. If you need to save power, it is recommended
to use `Low_Power` for the gyroscope and `Low_Noise` for the accelerometer.

#### Power Modes

Both the gyroscope and accelerometer are configured primarily by selecting
a Power mode. This choice determines which other configuration options are
available.

- `Off`: The sensor is turned off and consumes no power. No measurements
  are taken.
- `Low_Noise`: This is the high-performance mode. It offers the most
  configuration options, including access to higher internal sampling
  rates and advanced filtering.
- `Low_Power`: A power-saving mode with a more limited set of options.
  The internal sample rate is fixed at 1kHz.
- `Standby` (Gyroscope Only): A low-power mode where the gyroscope
  is ready to start up quickly but is not taking measurements.

#### Gyroscope Configuration

Configuration is based on the selected Power mode.

In `Low_Noise` Mode:

This mode provides maximum flexibility.

- `FSR`: Set the Full-Scale Range (e.g., ±250, ±500, ±1000, or ±2000 dps).
- `Filter`: Configure the digital low-pass filter (DLPF).
  - `Rate`: Sets the internal sensor sample rate. Can be `Rate_1kHz`,
    `Rate_8kHz`, or `Rate_32kHz`.
  - `Bandwidth`: Sets the filter's cutoff frequency, which depends
    on the selected Rate.

In `Low_Power` Mode:

This mode is optimized for low energy consumption.

- The internal sample rate is fixed at 1kHz.
- `FSR`: Set the Full-Scale Range.
- `Average`: Set the number of samples to be averaged by the hardware
   to reduce noise.
- `Bandwidth_1kHz`: Configure the low-pass filter bandwidth for the 1kHz rate.

#### Accelerometer Configuration

Similar to the gyroscope, configuration depends on the Power mode.

In `Low_Noise` Mode:

- `FSR`: Set the Full-Scale Range (e.g., ±2, ±4, ±8, or ±16 **g**).
- `Filter`: Configure the digital low-pass filter.
  - `Rate`: Sets the internal sensor sample rate. Can be `Rate_1kHz`
    or `Rate_4kHz`.
  - `Bandwidth`: Sets the filter's cutoff frequency.

In `Low_Power` Mode:

- The internal sample rate is fixed at 1kHz.
- `FSR`: Set the Full-Scale Range.
- `Average`: Set the number of hardware samples to average (1, 2, 4, 8, 16
  or 32).

#### Output Data Rate (ODR) and Rate_Divider

The final rate at which data is made available (ODR) is determined by the
internal sample rate and the Rate_Divider.

**Formula**: `ODR` = Internal Sample Rate / `Rate_Divider`

**Crucial Rule**: The `Rate_Divider` is only effective when the internal sample
rate is 1kHz. This occurs in the following scenarios:

- When a sensor is in `Low_Power` mode.
- When a sensor is in `Low_Noise` mode and its `Filter.Rate` is explicitly
  set to Rate_1kHz.

If a higher internal rate (e.g., 4kHz, 8kHz, or 32kHz) is selected,
the `Rate_Divider` is ignored, and the ODR will be equal to that internal rate.

#### Configuration Example

Here is an example of how to configure both sensors to run in `Low_Noise`
mode with a final Output Data Rate of 500Hz.

```ada
ICM20602_I2C.Configure
  (Config =>
    (Gyroscope     =>
       (Power  => ICM20602.Low_Noise,
        FSR    => 250,  -- Full scale range => -250 .. +250 dps
        Filter =>      -- Low-pass filter 176Hz on 1kHz rate
          (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
     Accelerometer =>
       (Power  => ICM20602.Low_Noise,
        FSR    => 2,    -- Full scale range => -2g .. +2g
        Filter =>      -- Low-pass filter 176Hz on 1kHz rate
          (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
     Rate_Divider  => 2),  -- Divide 1kHz rate by 2, so ODR = 500Hz
   Ok     => Ok_Flag);
```

In this example, both sensors are set to an internal sample rate of 1kHz.
The `Rate_Divider` of 2 is then applied to this base rate, resulting
in a final ODR of `1000Hz / 2 = 500Hz`.

### Accelerometer Offset Adjustment

The sensor includes 15-bit hardware registers to correct the accelerometer's
zero-g offset. The corrective effect on the final, scaled measurements is
consistent across all Full-Scale Range (FSR) settings.

**How It Works**:
A change in the offset register corresponds to a fixed physical acceleration
value. Each increment (1 LSB) of the offset register adjusts the final scaled
output by approximately 0.977 mg (or more precisely, 1g/1024). This allows you
to apply a desired correction in **g** without needing to account for
the current FSR.

On the other side, this means that while the effect on the final scaled output
is constant, the effect on the raw sensor data varies with the FSR setting,
as shown below:

|FSR    | Raw value change per 1 offset |
|-------|---------|
| ±2g   | 16 LSBs |
| ±4g   | 8 LSBs  |
| ±8g   | 4 LSBs  |
| ±16g  | 2 LSBs  |

This driver provides two methods for writing offset values:

* Using Physical Units (Recommended): You can use functions that accept
  a fixed-point value representing the desired offset in **g**.
  This is the easiest and safest method.
* Using Raw Values: For advanced use cases, the driver also allows you
  to directly read and write the raw integer values of the offset
  registers.

**Note:** The offset registers are **not affected** by a software reset.

### Gyroscope Offset Adjustment

The sensor includes 16-bit hardware registers to correct the gyroscope's
zero offset. The corrective effect on the final, scaled measurements is
consistent across all Full-Scale Range (FSR) settings.

**How It Works**:
A change in the offset register corresponds to a fixed physical acceleration
value. Each increment (1 LSB) of the offset register adjusts the final scaled
output by approximately 0.061 degree/s (or more precisely, 2000/32768). This
allows you to apply a desired correction in degree/s without needing to account
for the current FSR.

On the other side, this means that while the effect on the final scaled output
is constant, the effect on the raw sensor data varies with the FSR setting,
as shown below:

|FSR    | Raw value change per 1 offset |
|-------|----------|
| 250   | 4 LSBs   |
| 500   | 2 LSBs   |
| 1000  | 1 LSBs   |
| 2000  | 0.5 LSBs |

This driver provides two methods for writing offset values:

* Using Physical Units (Recommended): You can use functions that accept
  a fixed-point value representing the desired offset in **degree/s**.
  This is the easiest and safest method.
* Using Raw Values: For advanced use cases, the driver also allows you
  to directly read and write the raw integer values of the offset
  registers.

**Note:** The offset registers are **not affected** by a software reset.

### Low-Level Interface: `ICM20602.Raw`

The `ICM20602.Raw` package provides a low-level interface for interacting with
the ICM-20602 sensor. This package is designed to handle encoding and decoding
of sensor register values, while allowing users to implement the actual
read/write operations in a way that suits their hardware setup. The
communication with the sensor is done by reading or writing one or more bytes
to predefined registers. This package does not depend on HAL and can be used
with DMA or any other method of interacting with the sensor.

#### Purpose of ICM20602.Raw

The package defines array subtypes where the index represents the register
number, and the value corresponds to the register's data. Functions in this
package help prepare and interpret the register values. For example, functions
prefixed with `Set_` create the values for writing to registers, while those
prefixed with `Get_` decode the values read from registers. Additionally,
functions starting with `Is_` handle boolean logic values, such as checking
if the sensor is measuring or updating.

Users are responsible for implementing the reading and writing of these
register values to the sensor.

#### SPI and I2C Functions

The package also provides helper functions for handling SPI and I2C
communication with the sensor. For write operations, the register
address is sent first, followed by one or more data bytes, as the
sensor allows multi-byte writes. For read operations, the register
address is sent first, and then consecutive data can be read without
needing to specify the address for each subsequent byte.

- Two functions convert register address to byte:

  ```ada
  function SPI_Write (X : Register_Address) return Byte;
  function SPI_Read (X : Register_Address) return Byte;
  ```

- Other functions prefix a byte array with the register address:

  ```ada
    function SPI_Write (X : Byte_Array) return Byte_Array;
    function SPI_Read (X : Byte_Array) return Byte_Array
    function I2C_Write (X : Byte_Array) return Byte_Array;
    function I2C_Read (X : Byte_Array) return Byte_Array;
  ```

These functions help abstract the specifics of SPI and I2C communication,
making it easier to focus on the sensor’s register interactions without
worrying about protocol details. For example, you configure the sensor
by specifying the Inactivity duration and the IRR filter:

```ada
declare
   Data : Byte_Array := ICM20602.Raw.SPI_Write
    (ICM20602.Raw.Set_Configuration
      ((Gyroscope     =>
        (Power  => ICM20602.Low_Noise,
         FSR    => 250,  --  full scale range => -250 .. +250 dps
         Filter =>  --  Low-pass filter 176Hz on 1kHz rate
           (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
        Accelerometer =>
         (Power  => ICM20602.Low_Noise,
          FSR    => 2,  --  full scale range => -2g .. +2g
          Filter =>  --  Low-pass filter 176Hz on 1kHz rate
            (Rate => ICM20602.Rate_1kHz, Bandwidth_1kHz => 176)),
        Rate_Divider  => 2));  --  Divide 1kHz rate by 2, so ODR = 500Hz
begin
   --  Now write Data to the sensor by SPI
```

The reading looks like this:

```ada
declare
   Data : Byte_Array := ICM20602.Raw.SPI_Read
    ((ICM20602.Raw.Measurement_Data => 0));
   Gyro  : ICM20602.Angular_Speed_Vector;
   Accel : ICM20602.Acceleration_Vector;
begin
   --  Start SPI exchange (read/write) then decode Data:
   ICM20602.Raw.Get_Measurement
     (Data,
      GFSR  => 250,  --  Gyroscope full scale range
      AFSR  => 2,    --  Accelerometer full scale range
      Gyro  => Gyro,
      Accel => Accel);
```

## Examples

Examples use `Ada_Drivers_Library`. It's installed by Alire (alr >= 2.1.0 required).
Run Alire to build:

    alr -C examples build

### GNAT Studio

Launch GNAT Studio with Alire:

    alr -C examples exec gnatstudio -- -P icm20602_put/icm20602_put.gpr

### VS Code

Make sure `alr` in the `PATH`.
Open the `examples` folder in VS Code. Use pre-configured tasks to build
projects and flash (openocd or st-util). Install Cortex Debug extension
to launch pre-configured debugger targets.

- [Simple example for STM32 F4VE board](examples/icm20602_put) - complete
  example for the generic instantiation.
- [Advanced example for STM32 F4VE board and LCD & touch panel](examples/icm20602_lcd) -
  complete example of the tagged type usage.
