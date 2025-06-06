--  SPDX-FileCopyrightText: 2024-2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

--  This package provides a low-level interface for interacting with the
--  sensor. Communication with the sensor is done by reading/writing one
--  or more bytes to predefined registers. The interface allows the user to
--  implement the read/write operations in the way they prefer but handles
--  encoding/decoding register values into user-friendly formats.
--
--  For each request to the sensor, the interface defines a subtype-array
--  where the index of the array element represents the register number to
--  read/write, and the value of the element represents the corresponding
--  register value.
--
--  Functions starting with `Set_` prepare values to be written to the
--  registers. Conversely, functions starting with `Get_` decode register
--  values. Functions starting with `Is_` are a special case for boolean
--  values.
--
--  The user is responsible for reading and writing register values!

package ICM20602.Raw is

   use type Interfaces.Integer_16;
   use type Interfaces.Unsigned_8;

   subtype Chip_Id_Data is Byte_Array (16#75# .. 16#75#);
   --  WHO AM I register

   function Get_Chip_Id (Raw : Byte_Array) return Byte is
     (Raw (Chip_Id_Data'First));
   --  Read the chip ID. Raw data should contain Chip_Id_Data'First item.

   subtype Gyroscope_Offset_Data is Byte_Array (16#13# .. 16#18#);
   --  REGISTER 19..24 GYRO OFFSET ADJUSTMENT REGISTER. Scale???

   function Set_Raw_Gyroscope_Offset
     (Value : Raw_Vector) return Gyroscope_Offset_Data is
      (Byte (Value.X / 256),
       Byte (Value.X mod 256),
       Byte (Value.Y / 256),
       Byte (Value.Y mod 256),
       Byte (Value.Z / 256),
       Byte (Value.Z mod 256));
   --  Encode gyroscope offsets

   function Set_Gyroscope_Offset
     (Value : Angular_Speed_Vector) return Gyroscope_Offset_Data;
   --  Encode gyroscope offsets

   function Get_Raw_Gyroscope_Offset (Value : Byte_Array) return Raw_Vector
     with Pre =>
       Gyroscope_Offset_Data'First in Value'Range
         and then Gyroscope_Offset_Data'Last in Value'Range;
   --  Decode gyroscope offsets

   function Get_Gyroscope_Offset
     (Value : Byte_Array) return Angular_Speed_Vector
     with Pre =>
       Gyroscope_Offset_Data'First in Value'Range
         and then Gyroscope_Offset_Data'Last in Value'Range;
   --  Decode gyroscope offsets

   subtype Accelerometer_Offset_Data is Byte_Array (16#77# .. 16#7E#);
   --  Set REGISTER 119..126 ACCELEROMETER OFFSET ADJUSTMENT REGISTER
   --  ±16g scale, 15 bits. It's set at the factory. It will be added to value

   function Set_Raw_Accelerometer_Offset
     (Value : Raw_Vector) return Accelerometer_Offset_Data;
   --  Encode accelerometer offsets

   function Set_Accelerometer_Offset
     (Value : Accelerometer_Offset_Vector) return Accelerometer_Offset_Data;
   --  Encode accelerometer offsets

   function Get_Raw_Accelerometer_Offset (Value : Byte_Array) return Raw_Vector
     with Pre =>
       Accelerometer_Offset_Data'First in Value'Range
         and then Accelerometer_Offset_Data'Last in Value'Range;
   --  Decode accelerometer offsets

   function Get_Accelerometer_Offset
     (Value : Byte_Array) return Accelerometer_Offset_Vector
     with Pre =>
       Accelerometer_Offset_Data'First in Value'Range
         and then Accelerometer_Offset_Data'Last in Value'Range;
   --  Decode accelerometer offsets

   subtype Sample_Rate_Data is Byte_Array (16#19# .. 16#19#);
   --  Set REGISTER 25 SAMPLE RATE DIVIDER

   function Set_Sample_Rate
     (Value : Sample_Rate_Divider) return Sample_Rate_Data is
       (Sample_Rate_Data'First => Byte (Value - 1));
   --  Encode sample rate

   type Configuration_Data is record
      Data_1 : Byte_Array (16#19# .. 16#1E#);
      Data_2 : Byte_Array (16#6B# .. 16#6C#);
   end record;

   function Set_Configuration
     (Value : Sensor_Configuration) return Configuration_Data;
   --  Encode sensor configuration (including sample rate)

   Set_I2C_Disabled : constant Byte_Array (16#70# .. 16#70#) :=
     (16#70# => 64);
   --  REGISTER 112 – I2C INTERFACE.
   --
   --  To prevent switching into I2C mode when using SPI, the I2C interface
   --  should be disabled by writting this register. It should be done after
   --  2ms since power up.

   subtype Measurement_Data is Byte_Array (16#3B# .. 16#48#);
   --  * REGISTERS 59 TO 64 – ACCELEROMETER MEASUREMENTS.
   --  * REGISTERS 65 TO 66 – TEMPERATURE MEASUREMENT
   --  * REGISTERS 67 TO 72 – GYROSCOPE MEASUREMENT

   procedure Get_Raw_Measurement
     (Raw   : Byte_Array;
      Gyro  : out Raw_Vector;
      Accel : out Raw_Vector)
     with Pre =>
       Measurement_Data'First in Raw'Range
         and then Measurement_Data'Last in Raw'Range;
   --
   --  Decode raw measurement. Raw data should contain Measurement_Data'Range
   --  items.

   procedure Get_Measurement
     (Raw   : Byte_Array;
      GFSR  : Gyroscope_Full_Scale_Range;
      AFSR  : Accelerometer_Full_Scale_Range;
      Gyro  : out Angular_Speed_Vector;
      Accel : out Acceleration_Vector)
     with Pre =>
       Measurement_Data'First in Raw'Range
         and then Measurement_Data'Last in Raw'Range;
   --
   --  Decode measurement according to scale factors. Raw data should contain
   --  Measurement_Data'Range items.

   subtype Reset_Data is Byte_Array (16#6B# .. 16#6B#);
   --  REGISTER 107 – POWER MANAGEMENT 1

   Set_Reset : constant Reset_Data := (16#6B# => 16#80#);
   --  Reset the internal registers and restores the default settings.

   function Is_Reseting (Raw : Byte_Array) return Boolean is
     ((Raw (Reset_Data'First) and 16#80#) /= 0);

   subtype Configure_Interrupts_Data is Byte_Array (16#37# .. 16#38#);
   --  * REGISTER 55 – INT/DRDY PIN / BYPASS ENABLE CONFIGURATION
   --  * REGISTER 56 – INTERRUPT ENABLE

   function Set_Interrupts
     (Active_Is_Low      : Boolean := False;
      Is_Open_Drain      : Boolean := False;
      Is_Latched         : Boolean := False;
      Clear_On_Read      : Boolean := False;
      FSync_Enabled      : Boolean := False;
      Wake_On_X_Enabled  : Boolean := False;
      Wake_On_Y_Enabled  : Boolean := False;
      Wake_On_Z_Enabled  : Boolean := False;
      Gyro_Ready_Enabled : Boolean := False;
      Data_Ready_Enabled : Boolean := False) return Configure_Interrupts_Data;
   --  Encode interrupts settings

   subtype Interrupt_Status_Data is Byte_Array (16#3A# .. 16#3A#);
   --  REGISTER 58 – INTERRUPT STATUS

   function Is_Data_Ready (Raw : Byte_Array) return Boolean is
     ((Raw (Interrupt_Status_Data'First) and 1) /= 0);

   function Is_Gyro_Ready (Raw : Byte_Array) return Boolean is
     ((Raw (Interrupt_Status_Data'First) and 4) /= 0);

   function Is_Wake_On_Motion (Raw : Byte_Array) return Boolean is
     ((Raw (Interrupt_Status_Data'First) and 224) /= 0);

   ----------------------------------
   -- SPI/I2C Write/Read functions --
   ----------------------------------

   function SPI_Write (X : Register_Address) return Byte is
     (Byte (X) and 16#7F#);
   --  For read operation on the SPI bus the register address is passed with
   --  the highest bit off (0).

   function SPI_Read (X : Register_Address) return Byte is
     (Byte (X) or 16#80#);
   --  For write operation on the SPI bus the register address is passed with
   --  the highest bit on (1).

   function SPI_Write (X : Byte_Array) return Byte_Array is
     ((X'First - 1 => SPI_Write (X'First)) & X);
   --  Prefix the byte array with the register address for the SPI write
   --  operation

   function SPI_Read (X : Byte_Array) return Byte_Array is
     ((X'First - 1 => SPI_Read (X'First)) & X);
   --  Prefix the byte array with the register address for the SPI read
   --  operation

   function I2C_Write (X : Byte_Array) return Byte_Array is
     ((X'First - 1 => Byte (X'First)) & X);
   --  Prefix the byte array with the register address for the I2C write
   --  operation

   function I2C_Read (X : Byte_Array) return Byte_Array renames I2C_Write;
   --  Prefix the byte array with the register address for the I2C read
   --  operation

end ICM20602.Raw;
