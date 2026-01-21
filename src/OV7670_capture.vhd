library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OV7670_capture is
    port ( 
        pclk  : in   std_logic;
        vsync : in   std_logic;
        href  : in   std_logic;
        dport : in   std_logic_vector(7 downto 0);
        addr  : out  std_logic_vector(16 downto 0);
        dout  : out  std_logic_vector(15 downto 0);
        we    : out  std_logic
    );
end OV7670_capture;

architecture Behavioral of OV7670_capture is
    signal latched_dport : std_logic_vector(7 downto 0) := (others => '0');
    signal latched_href  : std_logic := '0';
    signal pixel_half    : std_logic := '0';
    signal address       : unsigned(16 downto 0) := (others => '0');
begin

    addr <= std_logic_vector(address);
    
    process(pclk)
    begin
        if rising_edge(pclk) then
            -- Latch input data
            latched_dport <= dport;
            latched_href  <= href;

            -- Reset address on new frame (VSYNC)
            if vsync = '1' then
                address <= (others => '0');
                pixel_half <= '0';
                we <= '0';
            else
                -- Capture active pixels
                if latched_href = '1' then
                    pixel_half <= not pixel_half;
                    
                    if pixel_half = '0' then
                        -- First byte of pixel (xxxxRRRR)
                        dout(15 downto 8) <= latched_dport;
                        we <= '0';
                    else
                        -- Second byte of pixel (GGGGBBBB)
                        dout(7 downto 0) <= latched_dport;
                        we <= '1'; -- Write completed pixel
                        address <= address + 1;
                    end if;
                else
                    we <= '0';
                end if;
            end if;
        end if;
    end process;
end Behavioral;