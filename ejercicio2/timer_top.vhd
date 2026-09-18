-- =============================================================
-- Archivo    : timer_top.vhd
-- Descripcion: Modulo principal TOP-LEVEL del timer 0:00 - 9:59
--
--   clk_50 -> divisor_frecuencia -> clk_1hz -> contadores
--   clk_50 -> timer_control (deteccion de botones a 50 MHz)
--
-- Entradas   : clk_50    - PIN_G21  Reloj 50 MHz DE0
--              reset     - PIN_H2   BUTTON[0] activo en bajo
--              start     - PIN_G3   BUTTON[1] activo en bajo
--              stop      - PIN_F1   BUTTON[2] activo en bajo
-- Salidas    : ssd_min   - HEX3     Display minutos
--              ssd_seg_d - HEX1     Display decenas segundo
--              ssd_seg_u - HEX0     Display unidades segundo
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

ENTITY timer_top IS
    PORT (
        clk_50    : IN  std_logic;
        reset     : IN  std_logic;
        start     : IN  std_logic;
        stop      : IN  std_logic;
        ssd_min   : OUT std_logic_vector(6 DOWNTO 0);
        ssd_seg_d : OUT std_logic_vector(6 DOWNTO 0);
        ssd_seg_u : OUT std_logic_vector(6 DOWNTO 0)
    );
END timer_top;

ARCHITECTURE structural OF timer_top IS

    -- ==========================================================
    -- DECLARACION DE COMPONENTES
    -- ==========================================================

    COMPONENT divisor_frecuencia IS
        PORT (
            clk_50  : IN  std_logic;
            reset   : IN  std_logic;
            enable  : IN  std_logic;
            clk_1hz : OUT std_logic
        );
    END COMPONENT;

    -- CAMBIO: timer_control ahora recibe clk_50
    COMPONENT timer_control IS
        PORT (
            clk_50      : IN  std_logic;
            reset       : IN  std_logic;
            start       : IN  std_logic;
            stop        : IN  std_logic;
            max_reached : IN  std_logic;
            running     : OUT std_logic
        );
    END COMPONENT;

    COMPONENT contador_seg_u IS
        PORT (
            clk       : IN  std_logic;
            reset     : IN  std_logic;
            enable    : IN  std_logic;
            count     : OUT std_logic_vector(3 DOWNTO 0);
            carry_out : OUT std_logic
        );
    END COMPONENT;

    COMPONENT contador_seg_d IS
        PORT (
            clk       : IN  std_logic;
            reset     : IN  std_logic;
            enable    : IN  std_logic;
            count     : OUT std_logic_vector(2 DOWNTO 0);
            carry_out : OUT std_logic
        );
    END COMPONENT;

    COMPONENT contador_min IS
        PORT (
            clk    : IN  std_logic;
            reset  : IN  std_logic;
            enable : IN  std_logic;
            count  : OUT std_logic_vector(3 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT decodificador_ssd IS
        PORT (
            bcd : IN  std_logic_vector(3 DOWNTO 0);
            seg : OUT std_logic_vector(6 DOWNTO 0)
        );
    END COMPONENT;

    -- ==========================================================
    -- SENALES INTERNAS
    -- ==========================================================

    SIGNAL clk_1hz      : std_logic;
    SIGNAL running      : std_logic;
    SIGNAL carry_seg_u  : std_logic;
    SIGNAL carry_seg_d  : std_logic;
    SIGNAL bcd_seg_u    : std_logic_vector(3 DOWNTO 0);
    SIGNAL bcd_seg_d_3b : std_logic_vector(2 DOWNTO 0);
    SIGNAL bcd_seg_d    : std_logic_vector(3 DOWNTO 0);
    SIGNAL bcd_min      : std_logic_vector(3 DOWNTO 0);
    SIGNAL max_reached  : std_logic;

BEGIN

    -- ==========================================================
    -- LOGICA COMBINACIONAL
    -- ==========================================================

    max_reached <= '1' WHEN (bcd_min = "1001" AND
                              bcd_seg_d_3b = "101" AND
                              bcd_seg_u = "1001")
                  ELSE '0';

    bcd_seg_d <= '0' & bcd_seg_d_3b;

    -- ==========================================================
    -- INSTANCIACION DE COMPONENTES
    -- ==========================================================

    -- Divisor: 50 MHz -> 1 Hz para los contadores
    -- Solo corre con running='1' para que el conteo arranque en 0:00
    -- y no se corte el segundo al hacer stop/start
    U_DIV : divisor_frecuencia
        PORT MAP (
            clk_50  => clk_50,
            reset   => reset,
            enable  => running,
            clk_1hz => clk_1hz
        );

    -- Control: usa clk_50 para detectar botones rapidamente
    U_CONTROL : timer_control
        PORT MAP (
            clk_50      => clk_50,
            reset       => reset,
            start       => start,
            stop        => stop,
            max_reached => max_reached,
            running     => running
        );

    -- Contadores: usan clk_1hz para contar segundos reales
    U_SEG_U : contador_seg_u
        PORT MAP (
            clk       => clk_1hz,
            reset     => reset,
            enable    => running,
            count     => bcd_seg_u,
            carry_out => carry_seg_u
        );

    U_SEG_D : contador_seg_d
        PORT MAP (
            clk       => clk_1hz,
            reset     => reset,
            enable    => carry_seg_u,
            count     => bcd_seg_d_3b,
            carry_out => carry_seg_d
        );

    U_MIN : contador_min
        PORT MAP (
            clk    => clk_1hz,
            reset  => reset,
            enable => carry_seg_d,
            count  => bcd_min
        );

    -- Decodificadores
    U_SSD_SEG_U : decodificador_ssd
        PORT MAP (
            bcd => bcd_seg_u,
            seg => ssd_seg_u
        );

    U_SSD_SEG_D : decodificador_ssd
        PORT MAP (
            bcd => bcd_seg_d,
            seg => ssd_seg_d
        );

    U_SSD_MIN : decodificador_ssd
        PORT MAP (
            bcd => bcd_min,
            seg => ssd_min
        );

END structural;