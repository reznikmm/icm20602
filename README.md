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
  for each channel. **It looks like low-power mode isn't working for now :-/.**
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
> In my configuration of icm-20602 with stm32f407, I cannot get
> `HAL.I2C.Read_Mem` to work correctly until I make an artificial call to
> `HAL.I2C.Master_Transmit`. I have not yet figured out why this is happening.
> It is possible that additional resistors are needed on the I2C bus.
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
*  Using Raw Values: For advanced use cases, the driver also allows you
   to directly read and write the raw integer values of the offset
   registers.

**Note:** The offset registers are not affected by a software reset.

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
