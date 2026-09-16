-- =============================================================
-- Archivo  : temporizador_espacio.vhd
-- Desc     : Top level. Cuenta 00-35 s mientras hay una persona
--            en el espacio (HEX1-HEX0); si se pasa de 35 s cuenta
--            el tiempo extra 00-99 (HEX3-HEX2) y enciende alarma.
--            Si sale antes de 35 s enciende felicitacion 3 s.
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY temporizador_espacio IS
    PORT (
        CLOCK_50     : IN  STD_LOGIC;
        BUTTON       : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        alarma       : OUT STD_LOGIC;
        felicitacion : OUT STD_LOGIC;
        HEX0_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3_D       : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END temporizador_espacio;

ARCHITECTURE structural OF temporizador_espacio IS

    -- ----------------------------------------------------------
    -- Declaracion de componentes
    -- ----------------------------------------------------------

    COMPONENT divisor_frecuencia IS
        PORT (
            clk_50  : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            clk_1hz : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT busy IS
        PORT (
            clk          : IN  STD_LOGIC;
            reset        : IN  STD_LOGIC;
            entrada      : IN  STD_LOGIC;
            salida       : IN  STD_LOGIC;
            tiempo_ok    : IN  STD_LOGIC;
            ocupado      : OUT STD_LOGIC;
            felicitacion : OUT STD_LOGIC;
            rst_cont     : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT contador_seg35 IS
        PORT (
            clk_1hz : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            uni     : OUT INTEGER RANGE 0 TO 9;
            dec     : OUT INTEGER RANGE 0 TO 3;
            done    : OUT STD_LOGIC;
            carry   : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT contador_ext IS
        PORT (
            clk_1hz : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            uni     : OUT INTEGER RANGE 0 TO 9;
            dec     : OUT INTEGER RANGE 0 TO 9;
            alarma  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT dec_7seg IS
        PORT (
            bcd : IN  INTEGER RANGE 0 TO 9;
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    -- ----------------------------------------------------------
    -- Senales internas
    -- ----------------------------------------------------------

    SIGNAL sig_reset   : STD_LOGIC;
    SIGNAL sig_entrada : STD_LOGIC;
    SIGNAL sig_salida  : STD_LOGIC;
    SIGNAL clk_1seg    : STD_LOGIC;

    SIGNAL sig_ocupado : STD_LOGIC;
    SIGNAL sig_done_35 : STD_LOGIC;

    -- Pulso de reset emitido por busy cuando la persona sale
    SIGNAL sig_rst_cont : STD_LOGIC;

    -- Reset combinado: boton reset OR persona que sale
    -- Reinicia los contadores en ambos casos
    SIGNAL reset_cont  : STD_LOGIC;

    -- Enable del contador de 35s
    SIGNAL sig_enable_35  : STD_LOGIC;

    -- Enable del tiempo extra
    SIGNAL sig_enable_ext : STD_LOGIC;

    -- Digitos para los displays
    SIGNAL sig_u35  : INTEGER RANGE 0 TO 9;
    SIGNAL sig_d35  : INTEGER RANGE 0 TO 3;
    SIGNAL sig_uext : INTEGER RANGE 0 TO 9;
    SIGNAL sig_dext : INTEGER RANGE 0 TO 9;

    -- Adaptacion de rango para dec_7seg (0-3 -> 0-9)
    SIGNAL sig_d35_ext : INTEGER RANGE 0 TO 9;


BEGIN

    -- Botones activos en bajo en DE0 -> invertir
    sig_reset   <= NOT BUTTON(0);
    sig_entrada <= NOT BUTTON(1);
    sig_salida  <= NOT BUTTON(2);

    -- Reset de contadores: boton reset manual O persona que sale
    reset_cont <= sig_reset OR sig_rst_cont;

    -- Enable del contador de 35s: corre si hay persona Y no termino
    sig_enable_35  <= sig_ocupado AND (NOT sig_done_35);

    -- Enable del tiempo extra: corre si hay persona Y ya paso 35s
    sig_enable_ext <= sig_ocupado AND sig_done_35;

    -- Adaptacion de rango
    sig_d35_ext <= sig_d35;

    -- ----------------------------------------------------------
    -- Instancia 1: Divisor de frecuencia 50 MHz -> 1 Hz
    -- ----------------------------------------------------------
    U_DIV : divisor_frecuencia
        PORT MAP (
            clk_50  => CLOCK_50,
            reset   => sig_reset,
            clk_1hz => clk_1seg
        );

    -- ----------------------------------------------------------
    -- Instancia 2: Detector de ocupacion
    -- Corre a 50 MHz para deteccion inmediata del boton
    -- ----------------------------------------------------------
    U_BUSY : busy
        PORT MAP (
            clk          => CLOCK_50,      -- 50 MHz, no 1 Hz
            reset        => sig_reset,
            entrada      => sig_entrada,
            salida       => sig_salida,
            tiempo_ok    => sig_done_35,
            ocupado      => sig_ocupado,
            felicitacion => felicitacion,
            rst_cont     => sig_rst_cont   -- pulso al salir
        );

    -- ----------------------------------------------------------
    -- Instancia 3: Contador de 00 a 35 segundos
    -- Se resetea con reset_cont (boton reset O persona que sale)
    -- ----------------------------------------------------------
    U_CONT35 : contador_seg35
        PORT MAP (
            clk_1hz => clk_1seg,
            reset   => reset_cont,         -- reset combinado
            enable  => sig_enable_35,
            uni     => sig_u35,
            dec     => sig_d35,
            done    => sig_done_35,
            carry   => OPEN
        );

    -- ----------------------------------------------------------
    -- Instancia 4: Contador de tiempo extra 00 a 99 segundos
    -- Se resetea con reset_cont (boton reset O persona que sale)
    -- ----------------------------------------------------------
    U_CONTEXT : contador_ext
        PORT MAP (
            clk_1hz => clk_1seg,
            reset   => reset_cont,         -- reset combinado
            enable  => sig_enable_ext,     -- CORREGIDO: antes sig_enable_35
            uni     => sig_uext,
            dec     => sig_dext,
            alarma  => alarma
        );

    -- ----------------------------------------------------------
    -- Instancias 5-8: Decodificadores 7 segmentos
    -- HEX0: unidades de 35s   HEX1: decenas de 35s
    -- HEX2: unidades extra    HEX3: decenas extra
    -- ----------------------------------------------------------
    U_SEG0 : dec_7seg PORT MAP (bcd => sig_u35,     seg => HEX0_D);
    U_SEG1 : dec_7seg PORT MAP (bcd => sig_d35_ext, seg => HEX1_D);
    U_SEG2 : dec_7seg PORT MAP (bcd => sig_uext,    seg => HEX2_D);
    U_SEG3 : dec_7seg PORT MAP (bcd => sig_dext,    seg => HEX3_D);

END structural;