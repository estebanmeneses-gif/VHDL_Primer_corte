-- =============================================================
-- Archivo    : divisor_frecuencia.vhd
-- Descripcion: Divisor de frecuencia de 50 MHz a 1 Hz.
--              La placa DE0 tiene un reloj de 50 MHz.
--              El timer necesita un pulso de 1 Hz (1 por segundo).
--              Este modulo genera ese pulso contando 50,000,000
--              ciclos del reloj de 50 MHz.
--              Solo cuenta mientras enable = '1' (timer corriendo):
--              al hacer stop se congela y al hacer start sigue
--              desde donde iba, sin cortar el segundo. Despues del
--              reset la salida arranca en '1', asi el primer flanco
--              de subida llega 1 s despues del start (no a los 0.5 s).
--
-- Entradas   : clk_50  - Reloj de 50 MHz (CLOCK_50 de la DE0)
--              reset   - Reset asincrono (activo en bajo, DE0)
--              enable  - '1' mientras el timer esta corriendo
-- Salidas    : clk_1hz - Pulso de 1 Hz para el timer
--
-- Estilo     : Contador con PROCESS y clk'event
--              segun diapositivas del curso.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY divisor_frecuencia IS
    PORT (
        clk_50  : IN  std_logic;   -- Reloj 50 MHz de la DE0
        reset   : IN  std_logic;   -- Reset asincrono (activo en bajo)
        enable  : IN  std_logic;   -- '1' = timer corriendo
        clk_1hz : OUT std_logic    -- Pulso de 1 Hz para el timer
    );
END divisor_frecuencia;

ARCHITECTURE arch1 OF divisor_frecuencia IS

    -- Contador interno: necesita contar hasta 49,999,999
    -- 50,000,000 ciclos de 50MHz = 1 segundo
    -- Necesita 26 bits (2^26 = 67,108,864 > 49,999,999)
    SIGNAL cnt  : UNSIGNED(25 DOWNTO 0) := (others => '0');

    -- Senal interna de salida (para poder leerla y modificarla)
    SIGNAL clk_reg : std_logic := '1';

BEGIN

    -- Proceso de conteo: cuenta de 0 a 49,999,999
    -- Cuando llega al limite, invierte la senal de salida
    -- Reset asincrono activo en bajo (boton DE0)
    pDiv : PROCESS (clk_50, reset) IS
    BEGIN

        -- Reset asincrono activo en bajo
        IF reset = '0' THEN
            cnt     <= (others => '0');
            clk_reg <= '1';   -- 1 -> 0 a los 0.5 s, 0 -> 1 al 1 s

        -- Flanco ascendente del reloj de 50 MHz
        ELSIF clk_50'event AND clk_50 = '1' THEN

            -- Al llegar a 24,999,999 invierte la salida
            -- Esto genera una onda cuadrada de 1 Hz:
            -- 25,000,000 ciclos en alto + 25,000,000 en bajo = 1 segundo
            -- Solo cuenta mientras el timer esta corriendo
            IF enable = '1' THEN
                IF cnt = 24999999 THEN
                    cnt     <= (others => '0');
                    clk_reg <= NOT clk_reg;   -- Invertir senal
                ELSE
                    cnt <= cnt + 1;
                END IF;
            END IF;

        END IF;

    END PROCESS;

    -- Asignacion de salida
    clk_1hz <= clk_reg;

END arch1;