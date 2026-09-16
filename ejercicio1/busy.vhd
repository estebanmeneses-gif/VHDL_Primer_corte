-- =============================================================
-- Archivo  : busy.vhd
-- Entidad  : busy
-- Descripcion: Detector de ocupacion del espacio.
--
-- Entradas:
--   clk       : Reloj 50 MHz
--   reset     : Reset asincrono activo en alto
--   entrada   : '1' cuando la persona ingresa
--   salida    : '1' cuando la persona sale
--   tiempo_ok : '1' cuando el contador de 35s ha terminado
-- Salidas:
--   ocupado      : '1' mientras hay persona en el espacio
--   felicitacion : '1' durante 3 segundos al salir a tiempo
--   rst_cont     : pulso de un ciclo para reiniciar contadores
-- =============================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY busy IS
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
END busy;

ARCHITECTURE synth OF busy IS

    SIGNAL est_ocupado      : STD_LOGIC := '0';
    SIGNAL est_felicitacion : STD_LOGIC := '0';

    -- Sincronizadores de 2 flip-flops para los botones
    -- (los botones son asincronos respecto a CLOCK_50)
    SIGNAL entrada_s1, entrada_s2 : STD_LOGIC := '0';
    SIGNAL salida_s1,  salida_s2  : STD_LOGIC := '0';

    -- Deteccion de flanco de subida de los botones
    SIGNAL entrada_prev : STD_LOGIC := '0';
    SIGNAL salida_prev  : STD_LOGIC := '0';

    -- Contador de 3 segundos para apagar felicitacion
    SIGNAL cnt_felic : UNSIGNED(27 DOWNTO 0) := (others => '0');

    -- Indica si el contador de felicitacion esta corriendo
    SIGNAL contando_felic : STD_LOGIC := '0';

    -- Constante: 3 segundos en ciclos de 50 MHz
    CONSTANT TRES_SEG : UNSIGNED(27 DOWNTO 0) := to_unsigned(150000000, 28);

BEGIN

    pSeq : PROCESS (clk, reset)
    BEGIN
        IF (reset = '1') THEN
            est_ocupado      <= '0';
            est_felicitacion <= '0';
            entrada_s1       <= '0';
            entrada_s2       <= '0';
            salida_s1        <= '0';
            salida_s2        <= '0';
            entrada_prev     <= '0';
            salida_prev      <= '0';
            rst_cont         <= '0';
            cnt_felic        <= (others => '0');
            contando_felic   <= '0';

        ELSIF (clk'EVENT AND clk = '1') THEN

            -- Sincronizacion de botones
            entrada_s1 <= entrada;
            entrada_s2 <= entrada_s1;
            salida_s1  <= salida;
            salida_s2  <= salida_s1;

            -- Por defecto el pulso de reset dura solo un ciclo
            rst_cont <= '0';

            -- -----------------------------------------------
            -- CONTADOR DE 3 SEGUNDOS PARA FELICITACION
            -- Corre mientras contando_felic='1'.
            -- Al llegar a TRES_SEG apaga el LED.
            -- -----------------------------------------------
            IF (contando_felic = '1') THEN
                IF (cnt_felic >= TRES_SEG) THEN
                    est_felicitacion <= '0';
                    contando_felic   <= '0';
                    cnt_felic        <= (others => '0');
                ELSE
                    cnt_felic <= cnt_felic + 1;
                END IF;
            END IF;

            -- -----------------------------------------------
            -- SUBIDA DE ENTRADA
            -- -----------------------------------------------
            IF (entrada_s2 = '1' AND entrada_prev = '0') THEN
                est_ocupado      <= '1';
                -- Si aun estaba el LED de felicitacion, apagarlo
                est_felicitacion <= '0';
                contando_felic   <= '0';
                cnt_felic        <= (others => '0');
            END IF;

            -- -----------------------------------------------
            -- SUBIDA DE SALIDA
            -- -----------------------------------------------
            IF (salida_s2 = '1' AND salida_prev = '0' AND est_ocupado = '1') THEN
                est_ocupado <= '0';
                rst_cont    <= '1';   -- reiniciar contadores display

                IF (tiempo_ok = '0') THEN
                    -- Salio antes de 35s: encender felicitacion
                    -- y arrancar contador de 3 segundos
                    est_felicitacion <= '1';
                    contando_felic   <= '1';
                    cnt_felic        <= (others => '0');
                ELSE
                    est_felicitacion <= '0';
                END IF;
            END IF;

            -- Guardar estado anterior de botones
            entrada_prev <= entrada_s2;
            salida_prev  <= salida_s2;

        END IF;
    END PROCESS;

    ocupado      <= est_ocupado;
    felicitacion <= est_felicitacion;

END synth;