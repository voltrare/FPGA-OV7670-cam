library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE1_SoC_Top is
    port (
        CLOCK_50 : in std_logic;

        -- DE1-SoC Keys and Switches
        KEY : in std_logic_vector(3 downto 0);
        SW  : in std_logic_vector(9 downto 0);

        -- VGA Output (8-bit DACs on DE1-SoC)
        VGA_R       : out std_logic_vector(7 downto 0);
        VGA_G       : out std_logic_vector(7 downto 0);
        VGA_B       : out std_logic_vector(7 downto 0);
        VGA_HS      : out std_logic;
        VGA_VS      : out std_logic;
        VGA_CLK     : out std_logic;
        VGA_BLANK_N : out std_logic;
        VGA_SYNC_N  : out std_logic;

        -- GPIO for OV7670 (Map these to your GPIO header pins)
        OV7670_SIOC  : out   std_logic;
        OV7670_SIOD  : inout std_logic;
        OV7670_VSYNC : in    std_logic;
        OV7670_HREF  : in    std_logic;
        OV7670_PCLK  : in    std_logic;
        OV7670_XCLK  : out   std_logic;
        OV7670_D     : in    std_logic_vector(7 downto 0);
        OV7670_RESET : out   std_logic;
        OV7670_PWDN  : out   std_logic;
        
        -- LED status
        LEDR : out std_logic_vector(9 downto 0)
    );
end DE1_SoC_Top;

architecture rtl of DE1_SoC_Top is

    -- Signal for the generated 25MHz clock
    signal clk25 : std_logic := '0';
    
    -- Internal signals
    signal config_finished : std_logic;
    signal capture_addr    : std_logic_vector(16 downto 0); -- Extended for 320x240 (76800 pixels)
    signal capture_data    : std_logic_vector(15 downto 0);
    signal capture_we      : std_logic;
    signal buffer_addr     : std_logic_vector(16 downto 0);
    signal buffer_data     : std_logic_vector(15 downto 0);
    
    -- Internal VGA 4-bit signals
    signal vga_red_4b   : std_logic_vector(3 downto 0);
    signal vga_green_4b : std_logic_vector(3 downto 0);
    signal vga_blue_4b  : std_logic_vector(3 downto 0);

begin

    ----------------------------------------------------------------
    -- Connectivity
    ----------------------------------------------------------------
    
    -- Camera hardware settings
    OV7670_RESET <= '1'; -- Active low reset, hold high
    OV7670_PWDN  <= '0'; -- Active high power down, hold low
    OV7670_XCLK  <= clk25; -- System clock to camera (25MHz)

    -- Status LEDs
    LEDR(9) <= config_finished; -- Lit when camera config is done
    LEDR(8 downto 0) <= SW(8 downto 0);

    -- VGA DAC Assignments for DE1-SoC
    -- Map 4-bit logic to 8-bit DACs (MSB padding)
    VGA_R <= vga_red_4b & "0000";
    VGA_G <= vga_green_4b & "0000";
    VGA_B <= vga_blue_4b & "0000";
    VGA_CLK <= clk25;       -- VGA pixel clock
    VGA_BLANK_N <= '1';     -- Keep high (active low blanking)
    VGA_SYNC_N  <= '0';     -- Keep low (not used often in modern VGA, sync on green off)

    ----------------------------------------------------------------
    -- Logic Generated Clock (50MHz -> 25MHz)
    ----------------------------------------------------------------
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            clk25 <= not clk25;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Component Instantiations
    ----------------------------------------------------------------

    -- 1. I2C Driver for Camera Config
    inst_ov7670_driver: entity work.ov7670_driver
    port map(
        iclk50          => clk25, -- Driving I2C at 25MHz is okay, internal dividers handle it
        config_finished => config_finished,
        sioc            => OV7670_SIOC,
        siod            => OV7670_SIOD,
        sw              => SW,
        key             => KEY -- Reset/Resend control
    );

    -- 2. Framebuffer (Dual Port RAM)
    inst_framebuffer: entity work.framebuffer
    port map(
        rdclock   => clk25,
        rdaddress => buffer_addr,
        q         => buffer_data,
        
        wrclock   => OV7670_PCLK,
        wraddress => capture_addr,
        data      => capture_data,
        wren      => capture_we
    );

    -- 3. Camera Capture
    inst_ov7670_capture: entity work.OV7670_capture
    port map(
        pclk  => OV7670_PCLK,
        vsync => OV7670_VSYNC,
        href  => OV7670_HREF,
        dport => OV7670_D,
        addr  => capture_addr,
        dout  => capture_data,
        we    => capture_we
    );

    -- 4. VGA Driver
    inst_vga_driver: entity work.vga_driver
    port map(
        iVGA_CLK    => clk25,
        r           => vga_red_4b,
        g           => vga_green_4b,
        b           => vga_blue_4b,
        hs          => VGA_HS,
        vs          => VGA_VS,
        buffer_addr => buffer_addr,
        buffer_data => buffer_data
    );

end rtl;