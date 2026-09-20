-- =============================================================
-- Archivo     : cont_seg.vhd
-- Descripcion : Contador de segundos de 0 a 59 (modulo 60).
--               Las salidas se entregan separadas en decenas
--               y unidades para facilitar la decodificacion
--               en los displays de 7 segmentos.
--
--
-- Entradas    : clk_1hz -> Reloj de 1 Hz (1 ciclo = 1 segundo)
--               reset   -> Reset asincrono activo alto
--               enable  -> '1' = contar, '0' = pausado
-- Salidas     : seg_u   -> Unidades de segundos (0-9) en 4 bits
--               seg_d   -> Decenas de segundos  (0-5) en 4 bits
--               carry   -> Pulso registrado al completar 59 seg.
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY cont_seg IS
    PORT (
        clk_1hz : IN  std_logic;
        reset   : IN  std_logic;
        enable  : IN  std_logic;
        seg_u   : OUT std_logic_vector(3 DOWNTO 0);
        seg_d   : OUT std_logic_vector(3 DOWNTO 0);
        carry   : OUT std_logic
    );
END cont_seg;

ARCHITECTURE arch1 OF cont_seg IS

    SIGNAL cnt_u     : UNSIGNED(3 DOWNTO 0) := (others => '0');
    SIGNAL cnt_d     : UNSIGNED(3 DOWNTO 0) := (others => '0');

BEGIN

    pSeg : PROCESS (clk_1hz, reset) IS
    BEGIN
        IF reset = '1' THEN
            cnt_u     <= (others => '0');
            cnt_d     <= (others => '0');
            

        ELSIF clk_1hz'event AND clk_1hz = '1' THEN

           

            IF enable = '1' THEN


                -- CASO 1: llegamos a 59 -> resetear 
                IF cnt_d = 5 AND cnt_u = 9 THEN
                    cnt_u     <= (others => '0');
                    cnt_d     <= (others => '0');
                    

                -- CASO 2: unidades llegaron a 9 -> subir decenas
                ELSIF cnt_u = 9 THEN
                    cnt_u <= (others => '0');
                    cnt_d <= cnt_d + 1;

                -- CASO 3: incremento normal
                ELSE
                    cnt_u <= cnt_u + 1;

                END IF;

            END IF;

        END IF;
    END PROCESS;

    seg_u <= std_logic_vector(cnt_u);
    seg_d <= std_logic_vector(cnt_d);
	 carry <= '1' WHEN (enable = '1' AND cnt_d = 5 AND cnt_u = 9) ELSE '0';
   

END arch1;