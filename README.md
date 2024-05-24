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
- ~~Adjust offsets for gyroscope and accelerometer (TBD)~~.
- Conduct measurements as raw 16-bit values and scaled values.
- ~~Configure interrupts and Wake-on-motion (TBD)~~

## Install

Add `icm20602` as a dependency to your crate with Alire:

    alr with icm20602

## Usage

> ### Note
>
> In my configuration of icm-20602 with stm32f407, I cannot get
> `HAL.I2C.Read_Mem` to work correctly until I make an artificial call to
> `HAL.I2C.Master_Transmit`. I have not yet figured out why this is happening.
> It is possible that additional resistors are needed on the I2C bus.
> I need to investigate. I have left this call in the `Initialize` procedure
> for now, it should not interfere.

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

## Examples

You need `Ada_Drivers_Library` in `adl` directory. Clone it then run Alire
to build:

    git clone https://github.com/AdaCore/Ada_Drivers_Library.git adl
    cd examples
    alr build

### GNAT Studio

Launch GNAT Studio with Alire:

    cd examples; alr exec gnatstudio -- -P icm20602_put/icm20602_put.gpr

### VS Code

Make sure `alr` in the `PATH`.
Open the `examples` folder in VS Code. Use pre-configured tasks to build
projects and flash (openocd or st-util). Install Cortex Debug extension
to launch pre-configured debugger targets.

- [Simple example for STM32 F4VE board](examples/icm20602_put) - complete
  example for the generic instantiation.
- [Advanced example for STM32 F4VE board and LCD & touch panel](examples/icm20602_lcd) -
  complete example of the tagged type usage.
