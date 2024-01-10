--  SPDX-FileCopyrightText: 2024 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

pragma Ada_2022;

package body ICM20602.I2C is

   ----------
   -- Read --
   ----------

   procedure Read
     (Data    : out HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      I2C_Port.Mem_Read
        (Addr          => 2 * HAL.UInt10 (I2C_Address),
         Mem_Addr      => HAL.UInt16 (Data'First),
         Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
         Data          => Data,
         Status        => Status);

      Success := Status = HAL.I2C.Ok;
   end Read;

   -----------
   -- Write --
   -----------

   procedure Write
     (Data    : HAL.UInt8_Array;
      Success : out Boolean)
   is
      use type HAL.I2C.I2C_Status;
      use type HAL.UInt10;

      Status : HAL.I2C.I2C_Status;
   begin
      if Data'Length = 0 then
         I2C_Port.Master_Transmit
           (Addr          => 2 * HAL.UInt10 (I2C_Address),
            Data          => [HAL.UInt8 (Data'First)],
            Status        => Status);
      else
         I2C_Port.Mem_Write
           (Addr          => 2 * HAL.UInt10 (I2C_Address),
            Mem_Addr      => HAL.UInt16 (Data'First),
            Mem_Addr_Size => HAL.I2C.Memory_Size_8b,
            Data          => Data,
            Status        => Status);
      end if;

      Success := Status = HAL.I2C.Ok;
   end Write;

end ICM20602.I2C;
