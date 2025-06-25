library ieee, work;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use work.flashstates.all;
use work.compiled.all;

entity toplevel is
    port(clk, miso, reset : in std_logic;
         btns : in std_logic_vector (0 to 4);
         cs, mosi, fclk, tx : out std_logic;
         leds : out std_logic_vector (0 to 5)
        );
end entity;

architecture behavior of toplevel is
signal raw : std_logic_vector(2047 downto 0) := (others => '0');
signal cmd : std_logic_vector(31 downto 0) := (others => '0');
signal arg : std_logic_vector(23 downto 0) := (others => '0');

signal assembled : std_logic := '0';
signal machine : binary := (others => (others => '0'));

type mem is (idle, rsten, rst, rstclk, wren, pp, ppclk, fr, run, done);
signal currentmem : mem := idle;

signal currentstate : state := init;

signal btn0reg, btn1reg, btn2reg, btn3reg, btn4reg : std_logic := '1';

signal tx_valid, tx_ready : std_logic;
signal tx_data : std_logic_vector (7 downto 0);

signal dataready, enableflash : std_logic;
signal byteread : std_logic_vector (15 downto 0);
signal readaddr : std_logic_vector (10 downto 0);

signal writeuart : std_logic;
signal cpucharindex : std_logic_vector (5 downto 0);
signal cpuchar : std_logic_vector (7 downto 0);
signal command : std_logic_vector (7 downto 0) := (others => '0');
signal flashaddr : std_logic_vector (23 downto 0) := (others => '0');
signal charin : std_logic_vector (2047 downto 0) := (others =>'0');
signal bytenum : integer range 0 to 256;
signal charout : std_logic_vector (2047 downto 0);

signal binready : std_logic;

signal code : std_logic_vector (0 to 823);

signal counter : integer range 0 to 324000000 := 0;
signal flashready : std_logic := '0';

component parser is
    port(clk : in std_logic;
         raw : in std_logic_vector (2047 downto 0);
         cmd : out std_logic_vector (31 downto 0);
         arg : out std_logic_vector (23 downto 0)
        );
end component;

component assembler is
    port(clk : in std_logic;
         instruction : in std_logic_vector (31 downto 0) := (others => '0');
         input : in std_logic_vector (23 downto 0) := (others => '0');
         assembled : out std_logic := '0';
         machine : out binary := (others => (others => '0'))
        );
end component;

component uarttx is
    port (clk : in  std_logic;
          reset : in  std_logic;
          tx_valid : in std_logic;
          tx_data : in  std_logic_vector (7 downto 0);
          tx_ready : out std_logic;
          tx_out : out std_logic);
end component;

component flash is
    generic (startup : std_logic_vector (31 downto 0) := to_stdlogicvector(10000000, 32));
    port(clk, miso : in std_logic;
         cmd : in std_logic_vector (7 downto 0);
         flashaddr : in std_logic_vector (23 downto 0) := (others => '0');
         charin : in std_logic_vector (2047 downto 0) := (others => '0');
         currentstate : in state;
         flashclk, mosi, flashready : out std_logic := '0';
         cs : out std_logic := '1';
         charout : out std_logic_vector (2047 downto 0) := (others => '0')
        );
end component;

component cpu is
    port(clk, reset, dataready : in std_logic;
         btns : in std_logic_vector (0 to 2);
         byteread : in std_logic_vector (15 downto 0);
         enableflash, writeuart : out std_logic := '0';
         charindex : out std_logic_vector (5 downto 0) := (others => '0');
         leds : out std_logic_vector (0 to 5) := (others => '1');
         char : out std_logic_vector (7 downto 0) := (others => '0');
         readaddr : out std_logic_vector (10 downto 0) := (others => '0')
        );
end component;

    begin
    
    process(clk)
    begin
        if falling_edge(clk) then
            btn0reg <= '0' when btns(0) else '1';
            btn1reg <= '0' when btns(1) else '1';
        end if;
    end process;
    

    process(all)
    begin
        if rising_edge(clk) then
            case currentmem is
            when idle => if flashready then
                currentmem <= rsten;
            else
                currentstate <= init;
            end if;
            when rsten => command <= x"66";
                if counter = 0 then
                    currentstate <= loadcmd;
                    counter <= counter + 1;
                elsif counter = 1 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 17 then
                    currentstate <= done;
                    currentmem <= rst;
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when rst => command <= x"99";
                if counter = 0 then
                    currentstate <= loadcmd;
                    counter <= counter + 1;
                elsif counter = 1 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 17 then
                    currentstate <= done;
                    currentmem <= rstclk;
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when rstclk => if counter = 810 then
                counter <= 0;
                currentmem <= wren;
            else
                counter <= counter + 1;
            end if;
            when wren => command <= x"06";
                if counter = 0 then
                    currentstate <= loadcmd;
                    counter <= counter + 1;
                elsif counter = 1 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 18 then
                    currentstate <= done;
                    currentmem <= pp;
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;
            when pp => command <= x"02";
                bytenum <= 6;
                charin(2047 downto 1232) <= x"434c522041430a53544120420a4a4d505a2031300a0a" & 
                        x"2e6f72672031300a41444420420a41444420310a53544120420a535441204c454" &
                        x"40a505345203235300a505345203235300a505345203235300a50534520323530" &
                        x"0a434c522041430a4a4d505a203130";
                flashaddr <= x"000000";
                if counter = 0 then
                    currentstate <= loadcmd;
                    counter <= counter + 1;
                elsif counter = 1 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 18 then
                    currentstate <= loadaddr;
                    counter <= counter + 1;
                elsif counter = 19 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 66 then
                    currentstate <= loaddata;
                    counter <= counter + 1;
                elsif counter = 67 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 67 + bytenum * 16 then
                    counter <= 0;
                    currentmem <= ppclk;
                    currentstate <= done;
                else
                    counter <= counter + 1;
                end if;
            when ppclk => if counter = 10809 then
                counter <= 0;
                currentmem <= fr;
            else
                counter <= counter + 1;
            end if;
            when fr => command <= x"0b";
                bytenum <= 102;
                flashaddr <= x"000000";
                charin(2047 downto 2040) <= x"ff";
                charin(2039 downto 0) <= (others => '0');
                if counter = 0 then
                    currentstate <= loadcmd;
                    counter <= counter + 1;
                elsif counter = 1 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 18 then
                    currentstate <= loadaddr;
                    counter <= counter + 1;
                elsif counter = 19 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 66 then
                    currentstate <= loaddata;
                    counter <= counter + 1;
                elsif counter = 67 then
                    currentstate <= send;
                    counter <= counter + 1;
                elsif counter = 84 then
                    currentstate <= read;
                    counter <= counter + 1;
                elsif counter = 84 + bytenum * 16 then
                    counter <= 0;
                    raw <= charout;
                    currentmem <= run;
                    currentstate <= done;
                else
                    counter <= counter + 1;
                end if;
            when run => if counter < bytenum then
                byteread <= machine(counter);
                counter <= counter + 1;
            else
                currentmem <= done;
                counter <= 0;
            end if;
            end case;
        end if;
    end process;

    parse : parser port map (clk => clk, raw => raw, cmd => cmd, arg => arg);
    assemble : assembler port map (clk => clk, instruction => cmd, input => arg, assembled => assembled, machine => machine);
    uart_tx : uarttx port map (clk => clk, reset => reset, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_out => tx);
    storage : flash generic map (startup => to_stdlogicvector(10000000, 32)) port map (clk => clk, miso => miso, cmd => command, flashaddr => flashaddr, charin => charin, currentstate => currentstate, flashclk => fclk, mosi => mosi, flashready => flashready, cs => cs, charout => charout);
    processor : cpu port map (clk => clk, reset => btn0reg, dataready => dataready, btns => btns(2 to 4), byteread => byteread, enableflash => enableflash, writeuart => writeuart, leds => leds, char => cpuchar, readaddr => readaddr);
end architecture;
