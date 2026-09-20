-- =============================================================
-- Archivo     : cont_min.vhd
-- Descripcion : Contador de minutos de 0 a 9 (modulo 10).
--               Incrementa cuando recibe el pulso carry
--               proveniente del contador de segundos.
--
-- Entradas    : clk_1hz -> Reloj de 1 Hz
--               reset   -> Reset asincrono activo alto
--               enable  -> '1' = sistema en marcha
--               carry   -> Pulso de cont_seg
-- Salidas     : min_u   -> Valor de minutos (0-9) en 4 bits
--               fin     -> '1' cuando cnt_min = 9
--                          (no usar para detener el sistema,
--                           usar fin_real del top-level)
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY cont_min IS
    PORT (
        clk_1hz : IN  std_logic;                     -- Reloj 1 Hz
        reset   : IN  std_logic;                     -- Reset activo alto
        enable  : IN  std_logic;                     -- Habilitacion
        carry   : IN  std_logic;                     -- Pulso de cont_seg
        min_u   : OUT std_logic_vector(3 DOWNTO 0);  -- Valor de minutos
        fin     : OUT std_logic                      -- Indicador (ver nota)
    );
END cont_min;

ARCHITECTURE arch1 OF cont_min IS
    SIGNAL cnt_min : UNSIGNED(3 DOWNTO 0) := (others => '0');
BEGIN

    pMin : PROCESS (clk_1hz, reset) IS
    BEGIN
        IF reset = '1' THEN
            cnt_min <= (others => '0');

        ELSIF clk_1hz'event AND clk_1hz = '1' THEN
            -- Incrementar minuto cuando hay carry Y el sistema corre
            -- Y aun no se llego al maximo de 9 minutos
            IF enable = '1' AND carry = '1' AND cnt_min < 9 THEN
                cnt_min <= cnt_min + 1;
            END IF;
        END IF;
    END PROCESS;

    -- Salidas combinacionales
    min_u <= std_logic_vector(cnt_min);

    -- NOTA: esta senal queda disponible en el puerto pero
    -- NO debe conectarse al enable_t del top-level.
    -- El fin real (9:59) se determina en temporizador.vhd
    -- con fin_real usando bcd_mu, bcd_sd y bcd_su.
    fin <= '1' WHEN cnt_min = 9 ELSE '0';

END arch1;