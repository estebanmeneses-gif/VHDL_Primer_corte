-- =============================================================
-- Archivo     : div_frec.vhd
-- Descripcion : Divisor de frecuencia de 50 MHz a 1 Hz
--               Utilizado para generar el reloj de 1 segundo
--               a partir del reloj de la FPGA DE0 (50 MHz).
--
-- Logica      : Contador que cuenta hasta 25,000,000 y luego
--               invierte la salida. Esto genera un periodo de
--               50,000,000 ciclos = 1 segundo (1 Hz).
--               Solo cuenta mientras enable='1' (running='1'),
--               asi el primer segundo despues de arrancar dura
--               1 s completo y no un tiempo al azar.
--
-- Entradas    : clk_50   -> Reloj de 50 MHz de la FPGA
--               reset    -> Reset asincrono activo alto (rst_tmr)
--               enable   -> '1' mientras el temporizador corre
-- Salidas     : clk_1hz  -> Reloj de 1 Hz generado
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY div_frec IS
    PORT (
        clk_50  : IN  std_logic;   -- Reloj de entrada 50 MHz
        reset   : IN  std_logic;   -- Reset asincrono activo alto
        enable  : IN  std_logic;   -- '1' = temporizador corriendo
        clk_1hz : OUT std_logic    -- Reloj de salida 1 Hz
    );
END div_frec;

ARCHITECTURE arch1 OF div_frec IS

    -- Constante: numero de ciclos para medio periodo a 50 MHz
    -- 50,000,000 / 2 = 25,000,000 ciclos por semiciclo
    SIGNAL cnt     : UNSIGNED(25 DOWNTO 0) := (others => '0');
    SIGNAL clk_reg : std_logic := '1';

BEGIN

    -- Proceso secuencial: contador y generacion de clk_1hz
    pDiv : PROCESS (clk_50, reset) IS
    BEGIN
        IF reset = '1' THEN
            -- Reset asincrono: limpiar contador y salida
            cnt     <= (others => '0');
            clk_reg <= '1';   -- 1 -> 0 a los 0.5 s, 0 -> 1 al 1 s
        ELSIF clk_50'event AND clk_50 = '1' THEN
            IF enable = '1' THEN
                -- En cada flanco de subida del reloj de 50 MHz
                IF cnt = 24999999 THEN
                    -- Al llegar a 25,000,000 ciclos: invertir salida
                    -- y reiniciar contador
                    clk_reg <= NOT clk_reg;
                    cnt     <= (others => '0');
                ELSE
                    -- Incrementar contador
                    cnt <= cnt + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Asignacion de la salida
    clk_1hz <= clk_reg;

END arch1;
