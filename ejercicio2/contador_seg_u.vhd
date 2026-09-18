-- =============================================================
-- Archivo    : contador_seg_u.vhd
-- Descripcion: Contador de unidades de segundo (0 a 9).
--              Cuenta de 0 a 9 y genera un pulso de acarreo
--              (carry_out='1') cuando llega a 9, para indicar
--              al siguiente digito que debe incrementarse.
-- Entradas   : clk, reset, enable
-- Salidas    : count (4 bits BCD), carry_out
-- Estilo     : Contador con UNSIGNED segun diapositivas del curso.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY contador_seg_u IS
    PORT (
        clk       : IN  std_logic;                       -- Reloj del sistema (1 Hz)
        reset     : IN  std_logic;                       -- Reset asincrono
        enable    : IN  std_logic;                       -- Habilitacion del contador
        count     : OUT std_logic_vector(3 DOWNTO 0);   -- Valor actual (0-9)
        carry_out : OUT std_logic                        -- Pulso cuando llega a 9
    );
END contador_seg_u;

ARCHITECTURE arch1 OF contador_seg_u IS

    -- Senal interna de conteo (tipo UNSIGNED para aritmetica)
    -- segun el estilo mostrado en las diapositivas del contador
    SIGNAL cnt : UNSIGNED(3 DOWNTO 0);

BEGIN

    -- Proceso secuencial con reset asincrono y enable
    -- Estilo directo de las diapositivas del curso (Slide 21)
    pSeq : PROCESS (clk, reset) IS
    BEGIN

        -- Reset asincrono: contador a cero
        IF reset = '0' THEN
            cnt <= (others => '0');

        -- Flanco ascendente del reloj
        ELSIF clk'event AND clk = '1' THEN

            -- Solo contar si el timer esta habilitado (enable='1')
            IF enable = '1' THEN

                -- Cuando llega a 9, volver a 0 (modulo-10)
                IF cnt = 9 THEN
                    cnt <= (others => '0');

                -- De lo contrario, incrementar
                ELSE
                    cnt <= cnt + 1;
                END IF;

            END IF;

        END IF;

    END PROCESS;

    -- Salida del valor del contador en std_logic_vector
    -- Conversion de UNSIGNED a std_logic_vector segun las diapositivas
    count <= std_logic_vector(cnt);

    -- carry_out es '1' solo cuando el contador esta en 9 y habilitado
    -- Esto indica al siguiente digito que debe incrementar
    carry_out <= '1' WHEN (cnt = 9 AND enable = '1') ELSE '0';

END arch1;
