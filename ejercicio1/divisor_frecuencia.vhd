-- Archivo: divisor_frecuencia.vhd
-- Descripcion: Divisor de frecuencia de 50 MHz a 1 Hz.
--              La placa DE0 tiene un reloj de 50 MHz.
--              El timer necesita un pulso de 1 Hz (1 por segundo).
--              Este modulo genera ese pulso contando 50,000,000
--              ciclos del reloj de 50 MHz.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY divisor_frecuencia IS
    PORT (
        clk_50  : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        clk_1hz : OUT STD_LOGIC
    );
END divisor_frecuencia;

ARCHITECTURE arch1 OF divisor_frecuencia IS
    -- 25,000,000 ciclos en alto + 25,000,000 en bajo = 1 segundo
    -- Necesita 26 bits (2^26 = 67,108,864 > 24,999,999)
    SIGNAL cnt     : UNSIGNED(25 DOWNTO 0);
    SIGNAL clk_reg : STD_LOGIC;
BEGIN

    pDiv : PROCESS (clk_50, reset)
    BEGIN
        -- Reset asincrono activo en alto
        IF (reset = '1') THEN
            cnt     <= (OTHERS => '0');
            clk_reg <= '0';
        ELSIF (clk_50'EVENT AND clk_50 = '1') THEN
            IF (cnt = 24999999) THEN
                cnt     <= (OTHERS => '0');
                clk_reg <= NOT clk_reg;
            ELSE
                cnt <= cnt + 1;
            END IF;
        END IF;
    END PROCESS;

    clk_1hz <= clk_reg;

END arch1;
