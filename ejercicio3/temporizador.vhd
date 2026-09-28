-- =============================================================
-- Archivo     : temporizador.vhd
-- Descripcion : Archivo principal ESTRUCTURAL del temporizador.
--               Declara todos los componentes y los conecta
--               mediante PORT MAP, siguiendo el estilo del curso.
--
-- Componentes instanciados:
--   U_DIV     -> div_frec   : Divisor 50 MHz -> 1 Hz
--   U_BTN     -> ctrl_boton : Control del boton unico (corre a 50 MHz)
--   U_SEG     -> cont_seg   : Contador de segundos (0-59)
--   U_MIN     -> cont_min   : Contador de minutos  (0-9)
--   U_7S_SU   -> dec_7seg   : Display segundos unidades (HEX0)
--   U_7S_SD   -> dec_7seg   : Display segundos decenas  (HEX1)
--   U_7S_MU   -> dec_7seg   : Display minutos           (HEX2)
--   U_7S_C0   -> dec_7seg   : Display constante "0"     (HEX3)
--
-- Entradas    : clk_50 -> Reloj fisico de la FPGA (50 MHz)
--               btn    -> Boton unico (activo bajo en placa DE0)
-- Salidas     : HEX0   -> Display segundos unidades
--               HEX1   -> Display segundos decenas
--               HEX2   -> Display minutos unidades
--               HEX3   -> Display constante (siempre 0)
-- Comentarios dados por Gemini Pro 3.1
-- =============================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;

ENTITY temporizador IS
    PORT (
        clk_50 : IN  std_logic;                     -- Reloj fisico 50 MHz
        btn    : IN  std_logic;                     -- Boton fisico (activo bajo en DE0)
        HEX0   : OUT std_logic_vector(6 DOWNTO 0);  -- Seg. unidades seg.
        HEX1   : OUT std_logic_vector(6 DOWNTO 0);  -- Seg. decenas  seg.
        HEX2   : OUT std_logic_vector(6 DOWNTO 0);  -- Minutos
        HEX2_dp : OUT std_logic;
        HEX3   : OUT std_logic_vector(6 DOWNTO 0)   -- Constante 0
    );
END temporizador;

ARCHITECTURE Structural OF temporizador IS

    -- =========================================================
    -- DECLARACION DE COMPONENTES
    -- =========================================================

    -- Componente: Divisor de frecuencia 50 MHz -> 1 Hz
    COMPONENT div_frec IS
        PORT (
            clk_50  : IN  std_logic;
            reset   : IN  std_logic;
            enable  : IN  std_logic;
            clk_1hz : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Controlador del boton unico
    -- Corre con clk_50 para respuesta inmediata al presionar
    COMPONENT ctrl_boton IS
        PORT (
            clk_50  : IN  std_logic;
            btn     : IN  std_logic;
            running : OUT std_logic;
            rst_tmr : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Contador de segundos 0-59
    COMPONENT cont_seg IS
        PORT (
            clk_1hz : IN  std_logic;
            reset   : IN  std_logic;
            enable  : IN  std_logic;
            seg_u   : OUT std_logic_vector(3 DOWNTO 0);
            seg_d   : OUT std_logic_vector(3 DOWNTO 0);
            carry   : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Contador de minutos 0-9
    COMPONENT cont_min IS
        PORT (
            clk_1hz : IN  std_logic;
            reset   : IN  std_logic;
            enable  : IN  std_logic;
            carry   : IN  std_logic;
            min_u   : OUT std_logic_vector(3 DOWNTO 0);
            fin     : OUT std_logic
        );
    END COMPONENT;

    -- Componente: Decodificador BCD -> 7 segmentos
    -- Se declara UNA SOLA VEZ y se instancia 4 veces
    COMPONENT dec_7seg IS
        PORT (
            bcd : IN  std_logic_vector(3 DOWNTO 0);
            seg : OUT std_logic_vector(6 DOWNTO 0)
        );
    END COMPONENT;

    -- =========================================================
    -- DECLARACION DE SENALES INTERNAS DE INTERCONEXION
    -- =========================================================

    -- Reloj de 1 Hz generado por el divisor de frecuencia
    SIGNAL clk_1hz  : std_logic;

    -- Boton interno: activo alto (invertido desde la placa)
    SIGNAL btn_i    : std_logic;

    -- Senal de habilitacion del temporizador
    SIGNAL running  : std_logic;

    -- Senal de reset especifico del temporizador (pulsacion larga)
    SIGNAL rst_tmr  : std_logic;

    -- Enable final: running AND NOT fin_real
    SIGNAL enable_t : std_logic;

    -- Carry entre contador de segundos y contador de minutos
    SIGNAL carry    : std_logic;

    -- Valores BCD de cada digito (4 bits cada uno)
    SIGNAL bcd_su   : std_logic_vector(3 DOWNTO 0);  -- Segundos unidades
    SIGNAL bcd_sd   : std_logic_vector(3 DOWNTO 0);  -- Segundos decenas
    SIGNAL bcd_mu   : std_logic_vector(3 DOWNTO 0);  -- Minutos unidades

    -- fin_min: salida de cont_min (minuto=9).
    -- Se recibe pero NO se usa para detener el sistema.
    -- El verdadero fin se calcula aqui con fin_real.
    SIGNAL fin_min  : std_logic;

    -- fin_real: verdadero indicador de fin de conteo.
    -- Se activa SOLO cuando minutos=9, decenas_seg=5 y unidades_seg=9
    -- Es decir, exactamente cuando el display muestra 9:59.
    SIGNAL fin_real : std_logic;

BEGIN

    -- =========================================================
    -- LOGICA COMBINACIONAL DE SENALES DE CONTROL
    -- =========================================================

    -- Invertir boton: en la DE0 el pulsador es activo en bajo
    -- presionado='0' -> btn_i='1' (activo alto para ctrl_boton)
    btn_i <= NOT btn;
    HEX2_dp <= '0' ;
    -- Calculo del verdadero fin de conteo: 9:59
    -- Las tres condiciones deben cumplirse simultaneamente:
    --   bcd_mu = "1001"  ->  minutos unidades = 9
    --   bcd_sd = "0101"  ->  segundos decenas = 5
    --   bcd_su = "1001"  ->  segundos unidades = 9
    fin_real <= '1' WHEN (bcd_mu = "1001" AND bcd_sd = "0101" AND bcd_su = "1001") ELSE '0';

    -- Enable: el contador solo avanza si running='1' y no llego a 9:59
    enable_t <= running AND (NOT fin_real);

    -- =========================================================
    -- INSTANCIACION DE COMPONENTES CON PORT MAP
    -- =========================================================

    -- Divisor de frecuencia: 50 MHz -> 1 Hz
    -- CORREGIDO: antes reset='0' fijo y sin enable, por lo que
    -- corria desde el encendido de la placa sin importar running.
    -- Ahora solo cuenta mientras running='1' (arranca en 00 con
    -- 1 s completo) y se reinicia con rst_tmr (pulsacion larga).
    U_DIV : div_frec
        PORT MAP (
            clk_50  => clk_50,
            reset   => rst_tmr,
            enable  => running,
            clk_1hz => clk_1hz
        );

    -- Controlador del boton: corre a 50 MHz para respuesta inmediata
    -- rst_tmr se pasa directamente a los contadores como reset
    U_BTN : ctrl_boton
        PORT MAP (
            clk_50  => clk_50,
            btn     => btn_i,
            running => running,
            rst_tmr => rst_tmr
        );

    -- Contador de segundos: corre a 1 Hz
    -- Se resetea con rst_tmr (pulsacion larga del boton)
    U_SEG : cont_seg
        PORT MAP (
            clk_1hz => clk_1hz,
            reset   => rst_tmr,
            enable  => enable_t,
            seg_u   => bcd_su,
            seg_d   => bcd_sd,
            carry   => carry
        );

    -- Contador de minutos: corre a 1 Hz
    -- Se resetea con rst_tmr (pulsacion larga del boton)
    -- fin se conecta a fin_min: solo indica que el minuto llego a 9,
    U_MIN : cont_min
        PORT MAP (
            clk_1hz => clk_1hz,
            reset   => rst_tmr,
            enable  => enable_t,
            carry   => carry,
            min_u   => bcd_mu,
            fin     => fin_min
        );

    -- Decodificador segundos unidades -> HEX0
    U_7S_SU : dec_7seg
        PORT MAP (
            bcd => bcd_su,
            seg => HEX0
        );

    -- Decodificador segundos decenas -> HEX1
    U_7S_SD : dec_7seg
        PORT MAP (
            bcd => bcd_sd,
            seg => HEX1
        );

    -- Decodificador minutos -> HEX2
    U_7S_MU : dec_7seg
        PORT MAP (
            bcd => bcd_mu,
            seg => HEX2
        );

    -- Decodificador HEX3: siempre muestra "0"
    U_7S_C0 : dec_7seg
        PORT MAP (
            bcd => "0000",
            seg => HEX3
        );

END Structural;
