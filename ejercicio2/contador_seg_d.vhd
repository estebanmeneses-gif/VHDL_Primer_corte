-- =============================================================
-- Archivo    : contador_seg_d.vhd
-- Descripcion: Contador de decenas de segundo (0 a 5).
--              Cuenta de 0 a 5 y genera carry_out cuando llega
--              a 5, para indicar al contador de minutos que
--              ha pasado un minuto completo.
-- Entradas   : clk, reset, enable (viene del carry de seg_u)
-- Salidas    : count (3 bits BCD), carry_out
-- Estilo     : Contador con UNSIGNED segun diapositivas del curso.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_seg_d IS
    PORT (
        clk       : IN  std_logic;                       -- Reloj del sistema (1 Hz)
        reset     : IN  std_logic;                       -- Reset asincrono
        enable    : IN  std_logic;                       -- Viene del carry de unidades
        count     : OUT std_logic_vector(2 DOWNTO 0);   -- Valor actual (0-5)
        carry_out : OUT std_logic                        -- Pulso cuando llega a 5
    );
END contador_seg_d;

ARCHITECTURE arch1 OF contador_seg_d IS

    -- Senal interna de conteo
    -- Rango 0-5 cabe en 3 bits
    SIGNAL cnt : UNSIGNED(2 DOWNTO 0);

BEGIN

    -- Proceso secuencial con reset asincrono y enable
    -- Mismo estilo que las diapositivas del contador (Slide 21)
    pSeq : PROCESS (clk, reset) IS
    BEGIN

        -- Reset asincrono: contador a cero
        IF reset = '0' THEN
            cnt <= (others => '0');

        -- Flanco ascendente del reloj
        ELSIF clk'event AND clk = '1' THEN

            -- Solo contar si el enable es activo
            -- (enable viene del carry_out de unidades de segundo)
            IF enable = '1' THEN

                -- Cuando llega a 5, volver a 0 (modulo-6)
                IF cnt = 5 THEN
                    cnt <= (others => '0');

                -- De lo contrario, incrementar
                ELSE
                    cnt <= cnt + 1;
                END IF;

            END IF;

        END IF;

    END PROCESS;

    -- Salida del valor del contador
    count <= std_logic_vector(cnt);

    -- carry_out es '1' cuando esta en 5 y habilitado
    -- Esto indica que ha completado un minuto
    carry_out <= '1' WHEN (cnt = 5 AND enable = '1') ELSE '0';

END arch1;