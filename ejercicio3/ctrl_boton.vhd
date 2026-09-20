-- =============================================================
-- Archivo     : ctrl_boton.vhd
-- Descripcion : Controlador del unico boton del temporizador.
--               Corre con clk_50 (50 MHz) para detectar la
--               pulsacion de forma INMEDIATA, sin esperar el
--               flanco de 1 Hz.
--
-- Correcciones aplicadas:
--   1. Senales internas inicializadas para evitar estado
--      indefinido al arrancar en simulacion o hardware.
--   2. Debounce de 20 ms agregado antes de evaluar el boton.
--      20 ms x 50,000,000 Hz = 1,000,000 ciclos (20 bits).
--
-- Logica de deteccion (sobre btn_stable, no btn directo):
--   - Pulsacion corta : al soltar, dur_cnt < 100,000,000
--                       -> toggle de running (start/stop)
--   - Pulsacion larga : dur_cnt >= 100,000,000 (2 segundos)
--                       -> rst_tmr = '1' (reset del timer)
--
-- Entradas    : clk_50  -> Reloj de 50 MHz de la FPGA
--               btn     -> Boton unico (activo bajo en DE0)
-- Salidas     : running -> '1' = temporizador en marcha
--               rst_tmr -> '1' = reset del temporizador
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.NUMERIC_STD.all;

ENTITY ctrl_boton IS
    PORT (
        clk_50  : IN  std_logic;   -- Reloj de 50 MHz
        btn     : IN  std_logic;   -- Boton unico (activo alto)
        running : OUT std_logic;   -- 1 = temporizador corriendo
        rst_tmr : OUT std_logic    -- Pulso de reset al temporizador
    );
END ctrl_boton;

ARCHITECTURE arch1 OF ctrl_boton IS

    -- ----------------------------------------------------------
    -- DEBOUNCE
    -- Filtro de 20 ms para eliminar rebotes del pulsador fisico.
    -- 20 ms a 50 MHz = 1,000,000 ciclos -> 20 bits (2^20 = 1,048,576)
    -- ----------------------------------------------------------
    SIGNAL deb_cnt    : UNSIGNED(19 DOWNTO 0) := (others => '0');
    SIGNAL btn_stable : std_logic := '0';   -- Boton filtrado (sin rebotes)

    -- ----------------------------------------------------------
    -- CONTROL DE PULSACION
    -- ----------------------------------------------------------
    -- Estado anterior del boton filtrado: detecta flanco de bajada
    SIGNAL btn_prev  : std_logic := '0';

    -- Contador de duracion de pulsacion en ciclos de 50 MHz
    -- 27 bits: maxima cuenta 134,217,728 > 100,000,000 (2s)
    SIGNAL dur_cnt   : UNSIGNED(26 DOWNTO 0) := (others => '0');

    -- Estado de marcha del temporizador
    SIGNAL run_reg   : std_logic := '0';

    -- Marca si la pulsacion ya fue clasificada como larga
    SIGNAL fue_larga : std_logic := '0';

    -- Constante: 2 segundos en ciclos de 50 MHz
    -- 2 x 50,000,000 = 100,000,000
    CONSTANT DOS_SEG : UNSIGNED(26 DOWNTO 0) := to_unsigned(100000000, 27);

    -- Constante: 20 ms en ciclos de 50 MHz (umbral de debounce)
    CONSTANT DEB_MAX : UNSIGNED(19 DOWNTO 0) := to_unsigned(1000000, 20);

BEGIN

    -- ==========================================================
    -- PROCESO DE DEBOUNCE
    -- Cada vez que btn cambia, se reinicia el contador.
    -- Solo cuando el boton se mantiene estable DEB_MAX ciclos
    -- se actualiza btn_stable. Asi se eliminan los rebotes.
    -- ==========================================================
    pDebounce : PROCESS (clk_50) IS
    BEGIN
        IF clk_50'event AND clk_50 = '1' THEN

            IF btn /= btn_stable THEN
                -- El boton cambio respecto al valor estable:
                -- reiniciar contador y esperar estabilidad
                IF deb_cnt < DEB_MAX THEN
                    deb_cnt <= deb_cnt + 1;
                ELSE
                    -- Se mantuvo el tiempo suficiente -> aceptar
                    btn_stable <= btn;
                    deb_cnt    <= (others => '0');
                END IF;
            ELSE
                -- El boton no cambio: reiniciar contador
                deb_cnt <= (others => '0');
            END IF;

        END IF;
    END PROCESS;

    -- ==========================================================
    -- PROCESO DE CONTROL DEL BOTON
    -- Trabaja sobre btn_stable (ya sin rebotes).
    -- ==========================================================
    pBoton : PROCESS (clk_50) IS
    BEGIN
        IF clk_50'event AND clk_50 = '1' THEN

            -- Por defecto el reset dura solo un ciclo
            rst_tmr <= '0';

            -- -----------------------------------------------
            -- BOTON PRESIONADO (nivel alto estable)
            -- -----------------------------------------------
            IF btn_stable = '1' THEN

                -- Incrementar contador de duracion
                -- Solo si no alcanzo el maximo (evita overflow)
                IF dur_cnt < DOS_SEG THEN
                    dur_cnt <= dur_cnt + 1;
                END IF;

                -- Si ya lleva 2 segundos presionado
                -- y no habia sido marcado aun como largo:
                IF dur_cnt >= DOS_SEG AND fue_larga = '0' THEN
                    rst_tmr   <= '1';    -- Pulso de reset
                    fue_larga <= '1';    -- Marcar como larga
                    run_reg   <= '0';    -- Detener temporizador
                END IF;

            -- -----------------------------------------------
            -- FLANCO DE BAJADA: boton recien soltado
            -- btn_stable='0' y btn_prev='1'
            -- -----------------------------------------------
            ELSIF btn_stable = '0' AND btn_prev = '1' THEN

                -- Si NO fue pulsacion larga -> toggle start/stop
                IF fue_larga = '0' THEN
                    run_reg <= NOT run_reg;
                END IF;

                -- Reiniciar para la proxima pulsacion
                dur_cnt   <= (others => '0');
                fue_larga <= '0';

            END IF;

            -- Guardar estado del boton filtrado para proximo ciclo
            btn_prev <= btn_stable;

        END IF;
    END PROCESS;

    running <= run_reg;

END arch1;