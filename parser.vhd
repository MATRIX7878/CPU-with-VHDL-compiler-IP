library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.bytes.all;

entity parser is
    port(clk : in std_logic;
         raw : in std_logic_vector (2047 downto 0);
         cmd : out std_logic_vector (31 downto 0);
         arg : out std_logic_vector (23 downto 0)
        );
end entity;

architecture behavior of parser is
type state is (count, divide, parse);
signal currentstate, newstate : state := count;

signal newcmd, command : std_logic_vector (31 downto 0) := (others => '0');

signal newarg, argument : std_logic_vector (23 downto 0) := (others => '0');

signal bytes, newbytes : integer range 0 to 256 := 0;

signal bytenum, newbytenum : integer range 0 to 256 := 0;

signal instruction, newinstruction : data;

begin
    cmd <= command;
    arg <= argument;

    process(all)
    begin
        newcmd <= command;
        newarg <= argument;
        newstate <= currentstate;
        newinstruction <= instruction;
        newbytenum <= bytenum;
        newbytes <= bytes;

        case currentstate is
        when count => for i in 0 to 255 loop
            newinstruction(i) <= raw(2047 - i * 8 downto 2040 - i * 8);
        end loop;
            newstate <= divide;
        when divide => if instruction(bytenum) /= x"00" then
            newbytes <= bytes + 1;
            newbytenum <= bytenum + 1;
        elsif instruction(bytenum) = x"00" then
            newstate <= parse;
            newbytenum <= 0;
        end if;
        when parse => if bytenum /= bytes then
            if instruction(bytenum + 3) = x"20" then
                newcmd <= instruction(bytenum) & instruction(bytenum + 1) & instruction(bytenum + 2) & x"00";
                if instruction(bytenum + 5) = x"0a" and instruction(bytenum + 6) /= x"0a" then
                    newarg <= instruction(bytenum + 4) & x"0000";
                    newbytenum <= bytenum + 6;
                elsif instruction(bytenum + 6) = x"0a" and instruction(bytenum + 7) /= x"0a" then
                    newarg <= instruction(bytenum + 4) & instruction(bytenum + 5) & x"00";
                    newbytenum <= bytenum + 7;
                elsif instruction(bytenum + 7) = x"0a" and instruction(bytenum + 8) /= x"0a" then
                    newarg <= instruction(bytenum + 4) & instruction(bytenum + 5) & instruction(bytenum + 6);
                    newbytenum <= bytenum + 8;
                end if;
                if instruction(bytenum + 5) = x"0a" and instruction(bytenum + 6) = x"0a" then
                    newarg <= instruction(bytenum + 4) & x"0000";
                    newbytenum <= bytenum + 7;
                elsif instruction(bytenum + 6) = x"0a" and instruction(bytenum + 7) = x"0a" then
                    newarg <= instruction(bytenum + 4) & instruction(bytenum + 5) & x"00";
                    newbytenum <= bytenum + 8;
                elsif instruction(bytenum + 7) = x"0a" and instruction(bytenum + 8) = x"0a" then
                    newarg <= instruction(bytenum + 4) & instruction(bytenum + 5) & instruction(bytenum + 6);
                    newbytenum <= bytenum + 9;
                end if;
                if instruction(bytenum + 5) = x"00" then
                    newarg <= instruction(bytenum + 4) & x"0000";
                    newbytenum <= bytenum + 5;
                elsif instruction(bytenum + 6) = x"00" then
                    newarg <= instruction(bytenum + 4) & instruction(bytenum + 5) & x"00";
                    newbytenum <= bytenum + 6;
                elsif instruction(bytenum + 7) = x"00" then
                    newarg <= instruction(bytenum + 4) & instruction(bytenum + 5) & instruction(bytenum + 6);
                    newbytenum <= bytenum + 7;
                end if;
            elsif instruction(bytenum + 4) = x"20" then
                newcmd <= instruction(bytenum) & instruction(bytenum + 1) & instruction(bytenum + 2) & instruction(bytenum + 3);
                if instruction(bytenum + 6) = x"0a" and instruction(bytenum + 7) /= x"0a" then
                    newarg <= instruction(bytenum + 5) & x"0000";
                    newbytenum <= bytenum + 7;
                elsif instruction(bytenum + 7) = x"0a" and instruction(bytenum + 8) /= x"0a" then
                    newarg <= instruction(bytenum + 5) & instruction(bytenum + 6) & x"00";
                    newbytenum <= bytenum + 8;
                elsif instruction(bytenum + 8) = x"0a" and instruction(bytenum + 9) /= x"0a" then
                    newarg <= instruction(bytenum + 5) & instruction(bytenum + 6) & instruction(bytenum + 7);
                    newbytenum <= bytenum + 9;
                end if;
                if instruction(bytenum + 6) = x"0a" and instruction(bytenum + 7) = x"0a" then
                    newarg <= instruction(bytenum + 5) & x"0000";
                    newbytenum <= bytenum + 8;
                elsif instruction(bytenum + 7) = x"0a" and instruction(bytenum + 8) = x"0a" then
                    newarg <= instruction(bytenum + 5) & instruction(bytenum + 6) & x"00";
                    newbytenum <= bytenum + 9;
                elsif instruction(bytenum + 8) = x"0a" and instruction(bytenum + 9) = x"0a" then
                    newarg <= instruction(bytenum + 5) & instruction(bytenum + 6) & instruction(bytenum + 7);
                    newbytenum <= bytenum + 10;
                end if;
                if instruction(bytenum + 6) = x"00" then
                    newarg <= instruction(bytenum + 5) & x"0000";
                    newbytenum <= bytenum + 6;
                elsif instruction(bytenum + 7) = x"00" then
                    newarg <= instruction(bytenum + 5) & instruction(bytenum + 6) & x"00";
                    newbytenum <= bytenum + 7;
                elsif instruction(bytenum + 8) = x"00" then
                    newarg <= instruction(bytenum + 5) & instruction(bytenum + 6) & instruction(bytenum + 7);
                    newbytenum <= bytenum + 8;
                end if;
            end if;
        end if;
        end case;
    end process;

    process(all)
    begin
        if rising_edge(clk) then
            command <= newcmd;
            argument <= newarg;
            currentstate <= newstate;
            bytes <= newbytes;
            instruction <= newinstruction;
            bytenum <= newbytenum;
        end if;
    end process;
end architecture;
