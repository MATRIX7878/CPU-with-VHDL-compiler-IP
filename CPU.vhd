library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity cpu is
    port(clk, reset, dataready : in std_logic;
         btns : in std_logic_vector (0 to 2);
         byteread : in std_logic_vector (15 downto 0);
         enableflash, writeuart : out std_logic := '0';
         charindex : out std_logic_vector (5 downto 0) := (others => '0');
         leds : out std_logic_vector (0 to 5) := (others => '1');
         char : out std_logic_vector (7 downto 0) := (others => '0');
         readaddr : out std_logic_vector (10 downto 0) := (others => '0')
        );
end entity;

architecture behavior of cpu is
type cmd is (clr, add, sta, inv, prt, jmz, pse, hlt);
signal arg : cmd := clr;

type state is (fetch, fetchstart, fetchdone, decode, retrieve, retrievestart, retrievedone, execute, halt, stay, print);
signal currentstate : state := fetch;

signal carry, sum : std_logic;
signal a, b, c, ac, param, command : std_logic_vector (7 downto 0) := (others => '0');
signal pc : std_logic_vector (10 downto 0) := (others => '0');
signal counter : std_logic_vector (15 downto 0) := (others => '0');

impure function addition (d : std_logic_vector; e : std_logic_vector; cin : std_logic) return std_logic_vector is
variable total : std_logic_vector (7 downto 0);
variable cout : std_logic_vector (8 downto 0);
begin
    cout(0) := cin;
    for i in 0 to 7 loop
        total(i) := d(i) xor e(i) xor cout(i);
        cout(i + 1) := (d(i) and e(i)) or (d(i) and cout(i)) or (e(i) and cout(i));
    end loop;
	return total;
end function;

impure function negate (f : std_logic_vector) return std_logic_vector is
variable other : std_logic_vector (7 downto 0);
begin
    for i in 7 downto 0 loop
        if f(i) = '1' then
            other(i) := '0';
        else
            other(i) := '1';
        end if;
    end loop;
    return other;
end function;

begin
    process(all)
    begin
        if rising_edge(clk) then
            if reset then
                pc <= (others => '0');
                a <= (others => '0');
                b <= (others => '0');
                c <= (others => '0');
                ac <= (others => '0');
                command <= (others => '0');
                param <= (others => '0');
                currentstate <= fetch;
                enableflash <= '0';
                leds <= (others => '1');
            else
                case currentstate is
                when fetch => if not enableflash then
                    readaddr <= pc;
                    enableflash <= '1';
                    currentstate <= fetchstart;
                end if;
                when fetchstart => if not dataready then
                    currentstate <= fetchdone;
                end if;
                when fetchdone => if dataready then
                    command <= byteread(15 downto 8);
                    enableflash <= '0';
                    currentstate <= decode;
                end if;
                when decode => pc <= pc + '1';
                    if command(7) then
                        currentstate <= retrieve;
                    else
                        param <= a when command(3) else b when command(2) else c when command(1) else ac;
                        currentstate <= execute;
                    end if;
                when retrieve => if not enableflash then
                    readaddr <= pc;
                    enableflash <= '1';
                    currentstate <= retrievestart;
                end if;
                when retrievestart => if not dataready then
                    currentstate <= retrievedone;
                end if;
                when retrievedone => if dataready then
                    param <= byteread(7 downto 0);
                    enableflash <= '0';
                    if command(7 downto 4) = 0 then
                        arg <= clr;
                    elsif command(6 downto 4) = 1 then
                        arg <= add;
                    elsif command(6 downto 4) = 2 then
                        arg <= sta;
                    elsif command(6 downto 4) = 3 then
                        arg <= inv;
                    elsif command(6 downto 4) = 4 then
                        arg <= prt;
                    elsif command(6 downto 4) = 5 then
                        arg <= jmz;
                    elsif command(6 downto 4) = 6 then
                        arg <= pse;
                    elsif command(6 downto 4) = 7 then
                        arg <= hlt;
                    end if; 
                    currentstate <= execute;
                    pc <= pc + '1';
                end if;
                when execute => currentstate <= fetch;
                    case arg is
                    when clr => if command(0) then
                        ac <= (others => '0');
                    elsif command(1) then
                        ac <= (others => '0') when btns(0) else x"01" when ac /= x"00" else (others => '0');
                    elsif command(2) then
                        b <= (others => '0');
                    elsif command(3) then
                        a <= (others => '0');
                    end if;
                    when add => ac <= addition(ac, param, '0');
                    when sta => if command(0) then
                        leds <= not ac(5 downto 0);
                    elsif command(1) then
                        c <= ac;
                    elsif command(2) then
                        b <= ac;
                    elsif command(3) then
                        a <= ac;
                    end if;
                    when inv => if command(0) then
                        ac <= negate(ac);
                    elsif command(1) then
                        c <= negate(c);
                    elsif command(2) then
                        b <= negate(b);
                    elsif command(3) then
                        a <= negate(a);
                    end if;
                    when prt => charindex <= ac(5 downto 0);
                        char <= param;
                        writeuart <= '1';
                        currentstate <= print;
                    when jmz => pc <= "000" & param when ac = 0 else pc;
                    when pse => counter <= (others => '0');
                        currentstate <= stay;
                    when hlt => currentstate <= halt;
                    end case;
                when halt => null;
                when stay => if counter = 27000 then
                    param <= param - 1;
                    counter <= (others => '0');
                    if param = 0 then
                        currentstate <= fetch;
                    end if;
                else
                    counter <= counter + '1';
                end if;
                when print => writeuart <= '0';
                    currentstate <= fetch;
                end case;
            end if;
        end if;
    end process;
end architecture;
