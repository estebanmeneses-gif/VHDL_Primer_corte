-- =============================================================
-- Archivo  : contador_seg35.vhd
-- Entidad  : contador_seg35
-- Desc     : Contador unificado de 00 a 35 segundos.
--            Unidades y decenas en un solo proceso, igual que
--            cont_seg del proyecto anterior. Elimina todos los
--            problemas de sincronizacion de carry entre modulos.
--
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY contador_seg35 IS
    PORT (
        clk_1hz : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        uni     : OUT INTEGER RANGE 0 TO 9;
        dec     : OUT INTEGER RANGE 0 TO 3;
        done    : OUT STD_LOGIC;
        carry   : OUT STD_LOGIC
    );
END contador_seg35;

ARCHITECTURE behavior OF contador_seg35 IS
    SIGNAL cnt_u     : INTEGER RANGE 0 TO 9;
    SIGNAL cnt_d     : INTEGER RANGE 0 TO 3;
    SIGNAL carry_reg : STD_LOGIC;
    SIGNAL done_reg  : STD_LOGIC;
BEGIN

    pCont35 : PROCESS (clk_1hz, reset)
BEGIN
    IF (reset = '1') THEN
        cnt_u     <= 0;
        cnt_d     <= 0;
        carry_reg <= '0';
        done_reg  <= '0';

    ELSIF (clk_1hz'EVENT AND clk_1hz = '1') THEN
        carry_reg <= '0';

        IF (enable = '1') THEN

            -- ya estamos en 35: quedarse quieto
            IF (cnt_d = 3 AND cnt_u = 5) THEN
                NULL;

            -- unidades llegan a 9
            ELSIF (cnt_u = 9) THEN
                cnt_u     <= 0;
                cnt_d     <= cnt_d + 1;
                carry_reg <= '1';

            -- incremento normal
            ELSE
                cnt_u <= cnt_u + 1;
                -- CORREGIDO: done sube en el mismo flanco en que
                -- el display pasa de 34 a 35 (antes subia 1 s tarde)
                IF (cnt_d = 3 AND cnt_u = 4) THEN
                    done_reg <= '1';
                END IF;
            END IF;

        END IF;
    END IF;
END PROCESS;

    uni   <= cnt_u;
    dec   <= cnt_d;
    done  <= done_reg;
    carry <= carry_reg;

END behavior;
	