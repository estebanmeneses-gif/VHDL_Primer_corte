-- =============================================================
-- Archivo  : contador_ext.vhd
-- Entidad  : contador_ext
-- Desc     : Contador de tiempo extra de 00 a 99 segundos.
--            Se activa cuando enable = ocupado AND done_35.
--            alarma = enable (encendida mientras hay tiempo extra).
--            Se congela exactamente en 99 con NULL.
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY contador_ext IS
    PORT (
        clk_1hz : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        uni     : OUT INTEGER RANGE 0 TO 9;
        dec     : OUT INTEGER RANGE 0 TO 9;
        alarma  : OUT STD_LOGIC
    );
END contador_ext;

ARCHITECTURE behavior OF contador_ext IS
    SIGNAL cnt_u     : INTEGER RANGE 0 TO 9;
    SIGNAL cnt_d     : INTEGER RANGE 0 TO 9;
BEGIN

    pExt : PROCESS (clk_1hz, reset)
    BEGIN
        IF (reset = '1') THEN
            cnt_u     <= 0;
            cnt_d     <= 0;

        ELSIF (clk_1hz'EVENT AND clk_1hz = '1') THEN

            IF (enable = '1') THEN

                -- CASO 1: tope en 99, congelar
                IF (cnt_d = 9 AND cnt_u = 9) THEN
                    NULL;

                -- CASO 2: unidades llegan a 9 -> subir decenas
                ELSIF (cnt_u = 9) THEN
                    cnt_u     <= 0;
                    cnt_d     <= cnt_d + 1;

                -- CASO 3: incremento normal
                ELSE
                    cnt_u <= cnt_u + 1;
                END IF;

            END IF;
        END IF;
    END PROCESS;

    uni <= cnt_u;
    dec <= cnt_d;

    -- alarma: activa mientras hay tiempo extra corriendo
    alarma <= enable;

END behavior;