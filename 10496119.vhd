----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.04.2018 18:25:36
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
--librerie necessarie per rappresentare i numeri interi sottoforma di stringhe di bit
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--libreria necessaria per fare operazioni aritmetiche con stringhe di bit
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project_reti_logiche is
port (
i_clk : in std_logic;
i_start : in std_logic;
i_rst : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type STATUS is (rst, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9 ,S10 , S11);
    signal stato: STATUS := rst;
    signal n_righe: std_logic_vector(7 downto 0);
    signal n_colonne: std_logic_vector(7 downto 0);
    signal soglia: std_logic_vector(7 downto 0);
    signal cont_righe: std_logic_vector(7 downto 0) := "00000001";
    signal cont_colonne: std_logic_vector(7 downto 0) := "00000001";
    signal curr_address: std_logic_vector(15 downto 0);
    signal lato1: std_logic_vector(7 downto 0) := "00000000";
    signal lato2: std_logic_vector(7 downto 0) := "00000000";
    signal lato3: std_logic_vector(7 downto 0) := "00000000";
    signal lato4: std_logic_vector(7 downto 0) := "00000000";
    signal base: std_logic_vector(7 downto 0);
    signal altezza: std_logic_vector(7 downto 0);
    signal area: std_logic_vector(15 downto 0);
    
begin        
    --processo logica sequenziale
    process1: process(i_clk)
    begin
        if(rising_edge(i_clk)) then 
            --ogni volta che siamo sul fronte di salita del clock
            --se viene asserito i_rst lo stato diventa lo sato iniziale S0
            if(i_rst = '1' or stato = rst) then
                stato <= S0;
                o_en <= '1';
                curr_address <="0000000000000000";
                o_address <= "0000000000000000";
            end if;
        
            --se viene asserito i_start viene cambiato stato solo se la rete è nello stato iniziale S0
            if(i_start = '1' and stato = S0) then
                stato <= S1;
                curr_address<= "0000000000000011";
                o_address <= "0000000000000010";
                --resetto tutti i contatori
                cont_righe <= "00000001";
                cont_colonne <= "00000000";
                n_righe <= "00000000";
                n_colonne <= "00000000";
                soglia <= "00000000";
                base <= "00000000";
                altezza <= "00000000";
                area <= "0000000000000000";
                o_done <= '0';
                o_we <= '0';
                o_data <= "00000000";
            end if;
            
            if(stato = S1) then
                stato <= S2;
                curr_address <= curr_address + "0000000000000001";
                o_address <=curr_address; 
            end if;
            
            --leggo n_colonne
            if(stato = S2) then
                stato <= S3;
                n_colonne <= i_data;
                curr_address <= curr_address + "0000000000000001";
                o_address <= curr_address; 
            end if;
            
            --leggo n_righe
            if(stato = S3) then
                stato <= S4;
                n_righe <= i_data;
                curr_address <= curr_address + "0000000000000001";
                o_address <= curr_address; 
            end if;
            
            --leggo la soglia
            if(stato = S4) then
                lato1 <= n_righe;
                lato4 <= "00000000";
                lato2 <= n_colonne;
                lato3 <= "00000000";
                cont_colonne <= cont_colonne + "00000001";
                stato <= S5;
                soglia <= i_data;
                curr_address <= curr_address + "0000000000000001";
                o_address <= curr_address;
            end if;
            
            --leggo l'immagine rimanendo nello stato S5
            if(stato = S5) then
                if(i_data >= soglia) then
                    if(n_righe /= 0 and n_colonne /= 0) then
                        --aggiorno i lati
                        if(cont_righe < lato1) then
                            lato1 <= cont_righe;
                        end if;
                        if(cont_righe > lato4) then
                            lato4 <= cont_righe;
                        end if;
                        if(cont_colonne < lato2) then
                            lato2 <= cont_colonne;
                        end if;
                        if(cont_colonne > lato3) then
                            lato3 <= cont_colonne;
                        end if;
                    end if;
                end if;
                cont_colonne <= cont_colonne + "00000001";
                if (cont_colonne = n_colonne) then
                    cont_colonne <= "00000001";
                    cont_righe <= cont_righe + "00000001";
                end if;
                curr_address <= curr_address + "0000000000000001";
                o_address <= curr_address;
                --se ho letto tutta l'immagine vado nello stato S6 e o_address lo imposto a zero
                if(((cont_colonne = n_colonne) and (cont_righe= n_righe)) or n_colonne = "00000000" or n_righe = "00000000") then
                    stato <= S6;
                    curr_address <= "0000000000000001";
                    o_address <= "0000000000000000";
                end if;
            end if;
            
            --ho letto l'intera immagine e calcolo base e altezza e asserisco il segnale o_we
            if(stato = S6) then
                stato <= S7;
                o_we <= '1';
                if(lato4>=lato1) then
                    if(lato3>=lato2) then
                        base <= ((lato4-lato1)+1);
                        altezza <= ((lato3-lato2)+1);             
                    end if;
                end if;
            end if;
            
            --calcolo l'area in S7
            if(stato = S7) then
                stato <= S8;
                area <= base*altezza;
            end if;
            
            --scrivo il primo byte in memoria
            if(stato = S8) then
                stato <= S9;
                o_data <= area(7 downto 0);
            end if;
            
            --scrivo il secondo byte in memoria
            if(stato = S9) then
                stato <= S10;
                o_data <= area(15 downto 8);
                o_done <= '1';
                o_address <= curr_address;
            end if;
            
            --stato finale
            if(stato = S10) then
                stato <= S11;
                curr_address <= "0000000000000010";
            end if;
            
            --torno nello stato di reset
            if(stato = S11) then
                o_done <= '0';
                o_we <= '0';
                stato <= rst;
            end if;
                       
        end if;
    end process;
end Behavioral;
