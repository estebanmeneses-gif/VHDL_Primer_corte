-- ============================================================
-- Archivo     : dec_7seg.vhd
-- Descripción : Decodificador BCD a 7 segmentos.
--               Recibe un dígito INTEGER (0 a 9) y entrega
--               el patrón para display activo en bajo (DE0).
--               Segmentos: "gfedcba" (bit 6 = g, bit 0 = a)
--               Usa CASE dentro de PROCESS, igual que los
--               ejemplos 6.7 y el ejemplo de Rapid Prototyping.
-- Entradas:
--   bcd : dígito decimal (0 a 9)
-- Salidas:
--   seg : patrón 7 segmentos activo en bajo
-- ============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY dec_7seg IS
    PORT (
        bcd : IN  INTEGER RANGE 0 TO 9;
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END dec_7seg;

ARCHITECTURE behavior OF dec_7seg IS
BEGIN

    PROCESS (bcd)
    BEGIN
        -- CASE sobre INTEGER, patrón exacto del ejemplo 6.7
        -- Patrones activo en bajo para displays DE0
        -- Orden de bits: seg = "gfedcba"
        CASE bcd IS
            WHEN 0 => seg <= "1000000"; -- 0
            WHEN 1 => seg <= "1111001"; -- 1
            WHEN 2 => seg <= "0100100"; -- 2
            WHEN 3 => seg <= "0110000"; -- 3
            WHEN 4 => seg <= "0011001"; -- 4
            WHEN 5 => seg <= "0010010"; -- 5
            WHEN 6 => seg <= "0000010"; -- 6
            WHEN 7 => seg <= "1111000"; -- 7
            WHEN 8 => seg <= "0000000"; -- 8
            WHEN 9 => seg <= "0010000"; -- 9
            WHEN OTHERS => seg <= "1111111"; -- apagado
        END CASE;
    END PROCESS;

END behavior;