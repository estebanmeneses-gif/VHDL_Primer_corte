-- =============================================================
-- Archivo    : contador_min.vhd
-- Descripcion: Contador de minutos (0 a 9).
--              Cuenta de 0 a 9. Se detiene en 9 y no vuelve a 0.
--              La condicion de maximo (9:59) la gestiona el
--              modulo principal usando la senal max_reached.
-- Entradas   : clk, reset, enable (viene del carry de seg_d)
-- Salidas    : count (4 bits BCD)
-- Estilo     : Contador con UNSIGNED segun diapositivas del curso.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_min IS
    PORT (
        clk    : IN  std_logic;                       -- Reloj del sistema (1 Hz)
        reset  : IN  std_logic;                       -- Reset asincrono
        enable : IN  std_logic;                       -- Viene del carry de decenas
        count  : OUT std_logic_vector(3 DOWNTO 0)    -- Valor actual (0-9)
    );
END contador_min;

ARCHITECTURE arch1 OF contador_min IS

    -- Senal interna de conteo (4 bits para 0-9)
    SIGNAL cnt : UNSIGNED(3 DOWNTO 0);

BEGIN

    -- Proceso secuencial con reset asincrono y enable
    -- Mismo estilo que las diapositivas del contador (Slide 21)
    pSeq : PROCESS (clk, reset) IS
    BEGIN

        -- Reset asincrono: contador de minutos a cero
        IF reset = '0' THEN
            cnt <= (others => '0');

        -- Flanco ascendente del reloj
        ELSIF clk'event AND clk = '1' THEN

            -- Solo contar si enable es activo
            -- (enable viene del carry_out de decenas de segundo)
            IF enable = '1' THEN

                -- Limite en 9: no incrementar mas alla de 9
                -- La condicion 9:59 detiene el timer antes de
                -- que los minutos intenten pasar de 9
                IF cnt < 9 THEN
                    cnt <= cnt + 1;
                END IF;

            END IF;

        END IF;

    END PROCESS;

    -- Salida del valor del contador
    count <= std_logic_vector(cnt);

END arch1;
