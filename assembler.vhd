library ieee, work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.compiled.all;
use work.translator.all;

entity assembler is
    port(clk : in std_logic;
         instruction : in std_logic_vector (31 downto 0) := (others => '0');
         input : in std_logic_vector (23 downto 0) := (others => '0');
         assembled : out std_logic := '0';
         machine : out binary := (others => (others => '0'))
        );
end entity;

architecture behavior of assembler is
type command is (preproc, clr, add, sta, inv, prnt, jmpz, pse, hlt);
signal cmd, newcmd : command := preproc;

type argument is (a, b, c, ac, btn, led, other);
signal arg, newarg : argument := other;

signal newassembled, ready : std_logic := '0';
signal newmachine, bin : binary := (others => (others => '0'));

signal code, newcode : std_logic_vector (15 downto 0) := (others => '0');

signal memaddr, newmemaddr : integer range 0 to 2048 := 0;
signal number, newnumber : integer range 0 to 255 := 0;
signal numbers : long;

begin
    assembled <= ready;
    machine <= bin;

    numbers <= converter;

    process(all)
    begin
        newassembled <= ready;
        newmachine <= bin;
        newcmd <= cmd;
        newarg <= arg;
        newcode <= code;
        newmemaddr <= memaddr;
        newnumber <= number;

        case instruction is
        when x"41444400" => newcmd <= add;
        when x"434c5200" => newcmd <= clr;
        when x"50534500" => newcmd <= pse;
        when x"53544100" => newcmd <= sta;
        when x"4a4d505a" => newcmd <= jmpz;
        when x"2e6f7267" => newcmd <= preproc;
        when others => null;
        end case;

        case input is
        when x"410000" => newarg <= a;
        when x"420000" => newarg <= b;
        when x"430000" => newarg <= c;
        when x"414300" => newarg <= ac;
        when x"42544e" => newarg <= btn;
        when x"4c4544" => newarg <= led;
        when others => newarg <= other;
        end case;

        case cmd is
        when preproc => newcode(15 downto 8) <= x"ff";
            for i in 0 to 255 loop
                if numbers(i) = input then
                    newcode(7 downto 0) <= to_stdlogicvector(i, 8);
                    newnumber <= i;
                end if;
            end loop;
        when clr => newcode(15 downto 12) <= (others => '0');
            case arg is
            when a => newcode(11 downto 8) <= "1000";
            when b => newcode(11 downto 8) <= "0100";
            when btn => newcode(11 downto 8) <= "0010";
            when ac => newcode(11 downto 8) <= "0001";
            when others => null;
            end case;
            newcode(7 downto 0) <= (others => '1');
        when add => newcode(15 downto 12) <= "0001";
            case arg is
            when a => newcode(11 downto 8) <= "1000";
                newcode(7 downto 0) <= x"10";
            when b => newcode(11 downto 8) <= "0100";
                newcode(7 downto 0) <= x"11";
            when c => newcode(11 downto 8) <= "0010";
                newcode(7 downto 0) <= x"12";
            when other => newcode(15 downto 8) <= x"91";
                for i in 0 to 255 loop
                    if numbers(i) = input then
                        newcode(7 downto 0) <= to_stdlogicvector(i, 8);
                        newnumber <= i;
                    end if;
                end loop;
            when others => null;
            end case;
        when sta => newcode(15 downto 12) <= "0010";
            case arg is
            when a => newcode(11 downto 8) <= "1000";
            when b => newcode(11 downto 8) <= "0100";
            when c => newcode(11 downto 8) <= "0010";
            when led => newcode(11 downto 8) <= "0001";
            when others => null;
            end case;
            newcode(7 downto 0) <= x"dd";
        when inv => newcode(15 downto 12) <= "0011";
            case arg is
            when a => newcode(11 downto 8) <= "1000";
            when b => newcode(11 downto 8) <= "0100";
            when c => newcode(11 downto 8) <= "0010";
            when ac => newcode(11 downto 8) <= "0001";
            when others => null;
            end case;
            newcode(7 downto 0) <= x"bb";
        when prnt => newcode(15 downto 12) <= "0100";
            case arg is
            when a => newcode(11 downto 8) <= "1000";
                newcode(7 downto 0) <= x"10";
            when b => newcode(11 downto 8) <= "0100";
                newcode(7 downto 0) <= x"11";
            when c => newcode(11 downto 8) <= "0010";
                newcode(7 downto 0) <= x"12";
            when other => newcode(15 downto 8) <= x"c1";
                for i in 0 to 255 loop
                    if numbers(i) = input then
                        newcode(7 downto 0) <= to_stdlogicvector(i, 8);
                        newnumber <= i;
                    end if;
                end loop;
            when others => null;
            end case;
        when jmpz => newcode(15 downto 12) <= "0101";
            case arg is
            when a => newcode(11 downto 8) <= "1000";
                newcode(7 downto 0) <= x"10";
            when b => newcode(11 downto 8) <= "0100";
                newcode(7 downto 0) <= x"11";
            when c => newcode(11 downto 8) <= "0010";
                newcode(7 downto 0) <= x"12";
            when other => newcode(15 downto 8) <= x"d1";
                for i in 0 to 255 loop
                    if numbers(i) = input then
                        newcode(7 downto 0) <= to_stdlogicvector(i, 8);
                        newnumber <= i;
                    end if;
                end loop;
            when others => null;
            end case;
        when pse => newcode(15 downto 12) <= "0110";
            case arg is
            when a => newcode(11 downto 8) <= "1000";
                newcode(7 downto 0) <= x"10";
            when b => newcode(11 downto 8) <= "0100";
                newcode(7 downto 0) <= x"11";
            when c => newcode(11 downto 8) <= "0010";
                newcode(7 downto 0) <= x"12";
            when other => newcode(15 downto 8) <= x"e1";
                for i in 0 to 255 loop
                    if numbers(i) = input then
                        newcode(7 downto 0) <= to_stdlogicvector(i, 8);
                        newnumber <= i;
                    end if;
                end loop;
            when others => null;
            end case;
        when hlt => newcode(15 downto 0) <= x"7000";
        end case;

        newmachine(memaddr) <= code;
        if code(15 downto 8) = x"ff" then
            newmemaddr <= memaddr + (number - memaddr);
        else
            newmemaddr <= memaddr + 1;
        end if;
    end process;

    process(all)
    begin
        if rising_edge(clk) then
            ready <= newassembled;
            bin <= newmachine;
            code <= newcode;
            number <= newnumber;
            memaddr <= newmemaddr;
        end if;

        if falling_edge(clk) then
            cmd <= newcmd;
            arg <= newarg;
        end if;
    end process;
end architecture;
