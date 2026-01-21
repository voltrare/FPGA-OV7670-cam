library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_driver is
    port ( 
        iVGA_CLK    : in  std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0);
        hs          : out std_logic;
        vs          : out std_logic;
        buffer_addr : out std_logic_vector(16 downto 0);
        buffer_data : in  std_logic_vector(15 downto 0)
    );
end vga_driver;

architecture Behavioral of vga_driver is

    -- Standard VGA 640x480 @ 60Hz timing
    constant hRes       : natural := 640;
    constant hStartSync : natural := 656;
    constant hEndSync   : natural := 752;
    constant hMax       : natural := 800;
    
    constant vRes       : natural := 480;
    constant vStartSync : natural := 490;
    constant vEndSync   : natural := 492;
    constant vMax       : natural := 525;

    signal hCount : unsigned(9 downto 0) := (others => '0');
    signal vCount : unsigned(9 downto 0) := (others => '0');
    signal blank  : std_logic := '0';

begin

    process(iVGA_CLK)
        -- Variables for address calculation
        variable x_mem : unsigned(9 downto 0);
        variable y_mem : unsigned(9 downto 0);
        variable address_calc : unsigned(19 downto 0);
    begin
        if rising_edge(iVGA_CLK) then
            
            -- Horizontal Counter
            if hCount = hMax - 1 then
                hCount <= (others => '0');
                -- Vertical Counter
                if vCount = vMax - 1 then
                    vCount <= (others => '0');
                else
                    vCount <= vCount + 1;
                end if;
            else
                hCount <= hCount + 1;
            end if;

            -- Sync Signals
            if hCount >= hStartSync and hCount < hEndSync then
                hs <= '0'; -- VGA standard is usually negative sync
            else
                hs <= '1';
            end if;

            if vCount >= vStartSync and vCount < vEndSync then
                vs <= '0'; -- VGA standard is usually negative sync
            else
                vs <= '1';
            end if;

            -- Video Active Area
            if hCount < hRes and vCount < vRes then
                blank <= '0';
            else
                blank <= '1';
            end if;

            -- Address Calculation for 320x240 buffer displayed on 640x480
            -- We read the pixel at (hCount/2, vCount/2)
            -- Address = y*320 + x
            x_mem := hCount(9 downto 1); -- Divide by 2
            y_mem := vCount(9 downto 1); -- Divide by 2
            
            -- 320 = 256 + 64.  y*320 = (y<<8) + (y<<6)
            address_calc := ("00" & y_mem & "00000000") + ("0000" & y_mem & "000000");
            address_calc := address_calc + x_mem;
            
            buffer_addr <= std_logic_vector(address_calc(16 downto 0));

            -- Output Colors
            if blank = '0' then
                -- RGB444 Format in buffer: xxxx RRRR GGGG BBBB
                -- High byte: xxxxRRRR (Bits 11 to 8 of valid color) -> buffer(11 downto 8)
                -- Low byte:  GGGGBBBB (Bits 7 to 4 are G, 3 to 0 are B)
                
                -- Note: vga_driver in original code had mixed mapping. 
                -- Assuming XRGB logic:
                r <= buffer_data(11 downto 8);
                g <= buffer_data(7 downto 4);
                b <= buffer_data(3 downto 0);
            else
                r <= (others => '0');
                g <= (others => '0');
                b <= (others => '0');
            end if;
            
        end if;
    end process;
end Behavioral;