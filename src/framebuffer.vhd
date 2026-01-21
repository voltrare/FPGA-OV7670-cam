library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity framebuffer is
    port (
        rdclock   : in  std_logic;
        rdaddress : in  std_logic_vector(16 downto 0);
        q         : out std_logic_vector(15 downto 0);
        
        wrclock   : in  std_logic;
        wraddress : in  std_logic_vector(16 downto 0);
        data      : in  std_logic_vector(15 downto 0);
        wren      : in  std_logic
    );
end framebuffer;

architecture Behavioral of framebuffer is
    -- 320 * 240 = 76,800 pixels.
    -- This fits in DE1-SoC M10K blocks (approx 4Mbit total available, we need ~1.2Mbit).
    type ram_type is array (0 to 76799) of std_logic_vector(15 downto 0);
    shared variable ram : ram_type; 
begin

    -- Port A: Write (Camera)
    process(wrclock)
    begin
        if rising_edge(wrclock) then
            if wren = '1' then
                ram(to_integer(unsigned(wraddress))) := data;
            end if;
        end if;
    end process;

    -- Port B: Read (VGA)
    process(rdclock)
    begin
        if rising_edge(rdclock) then
            q <= ram(to_integer(unsigned(rdaddress)));
        end if;
    end process;

end Behavioral;