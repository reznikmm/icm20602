--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package offers a straightforward method for setting up the ICM20602
--  when connected via I2C, especially useful when the use of only one sensor
--  is required. If you need multiple sensors, it is preferable to use the
--  ICM20602.I2C_Sensors package, which provides the appropriate tagged type.

with HAL.I2C;

with ICM20602.Generic_Sensor;

generic
   I2C_Port    : not null HAL.I2C.Any_I2C_Port;
   I2C_Address : HAL.UInt7 := 16#68#;  --  The ICM20602 7-bit I2C address
package ICM20602.I2C is

   procedure Read
     (Data    : out HAL.UInt8_Array;
      Success : out Boolean);
   --  Read registers starting from Data'First

   procedure Write
     (Data    : HAL.UInt8_Array;
      Success : out Boolean);
   --  Write the value to the ICM20602 chip register with given Address.

   package Sensor is new Generic_Sensor (Read, Write);

end ICM20602.I2C;
