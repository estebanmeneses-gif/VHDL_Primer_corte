-- =============================================================
-- Archivo    : timer_control.vhd
-- Descripcion: Modulo de control del timer.
--              Usa clk_50 (50 MHz) para detectar pulsaciones
--              de botones con precision. El estado 'running'
--              controla si los contadores de 1Hz cuentan o no.
--
-- RAZON DEL CAMBIO:
--              Con clk_1hz (1 Hz) solo hay 1 muestreo por segundo.
--              Una pulsacion humana dura ~100-200ms y puede perderse
--              facilmente. Con clk_50 (50 MHz) hay 50 millones de
--              muestreos por segundo: ninguna pulsacion se pierde.
--
-- Entradas   : clk_50      - Reloj 50 MHz para detectar botones
--              reset       - BUTTON[0] activo en bajo
--              start       - BUTTON[1] activo en bajo
--              stop        - BUTTON[2] activo en bajo
--              max_reached - Timer llego a 9:59
-- Salidas    : running     - 1=corriendo, 0=detenido
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

ENTITY timer_control IS
    PORT (
        clk_50      : IN  std_logic;   -- Reloj 50 MHz para botones
        reset       : IN  std_logic;   -- BUTTON[0] activo en bajo
        start       : IN  std_logic;   -- BUTTON[1] activo en bajo
        stop        : IN  std_logic;   -- BUTTON[2] activo en bajo
        max_reached : IN  std_logic;   -- Timer llego a 9:59
        running     : OUT std_logic    -- 1=corriendo, 0=detenido
    );
END timer_control;

ARCHITECTURE arch1 OF timer_control IS

    SIGNAL state      : std_logic;
    SIGNAL start_prev : std_logic;
    SIGNAL stop_prev  : std_logic;

BEGIN

    pControl : PROCESS (clk_50, reset) IS
    BEGIN

        -- Reset asincrono activo en bajo
        IF reset = '0' THEN
            state      <= '0';
            start_prev <= '1';
            stop_prev  <= '1';

        -- Muestreo a 50 MHz: detecta flancos de botones
        ELSIF clk_50'event AND clk_50 = '1' THEN

            start_prev <= start;
            stop_prev  <= stop;

            -- Flanco descendente de start (1->0 = boton presionado)
            IF start = '0' AND start_prev = '1' AND max_reached = '0' THEN
                state <= '1';

            -- Flanco descendente de stop (1->0 = boton presionado)
            ELSIF stop = '0' AND stop_prev = '1' THEN
                state <= '0';

            -- Detenerse automaticamente al llegar a 9:59
            ELSIF max_reached = '1' THEN
                state <= '0';

            END IF;

        END IF;

    END PROCESS;

    running <= state;

END arch1;