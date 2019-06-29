
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vm2413_interface is
port(
	p_reset : in std_logic;
	m_clock : in std_logic;
	run     : in std_logic;
	ready   : in std_logic;
	D       : in std_logic_vector(7 downto 0);
	A       : in std_logic;
	write   : in std_logic;
	sound   : out std_logic_vector(9 downto 0)
);
end;

architecture RTL of vm2413_interface is

component global
port(
	a_in  : in  std_logic;
	a_out : out std_logic
);
end component;

component opll is
  port(
    XIN  : in std_logic;
    XOUT : out std_logic;
    XENA : in std_logic;
    D    : in std_logic_vector(7 downto 0);
    A    : in std_logic;
    CS_n : in std_logic;
    WE_n : in std_logic;
    IC_n : in std_logic;
    MO   : out std_logic_vector(9 downto 0);
    RO   : out std_logic_vector(9 downto 0)
  );
end component;

signal rst_n, IC_n : std_logic;
signal A_buf : std_logic;
signal D_buf : std_logic_vector(7 downto 0);
signal WE_n : std_logic;
signal MO, RO : std_logic_vector(9 downto 0);

signal wav : std_logic_vector(9 downto 0);

begin

	rst_n <= not (ready or p_reset);
	IC_n <= rst_n;

--	RSTU : global port map(
--		a_in => rst_n, a_out => IC_n
--	);

	process(p_reset, m_clock) begin
		if(p_reset='1') then
			A_buf <= '0';
			D_buf <= X"00";
		elsif(m_clock'event and m_clock='1') then
			if(write='1') then
				A_buf <= A;
				D_buf <= D;
			end if;
		end if;
	end process;

	process(p_reset, m_clock) begin
		if(p_reset='1') then
			WE_n <= '1';
		elsif(m_clock'event and m_clock='1') then
			if(write='1') then
				WE_n <= '0';
			elsif(run='1') then
				WE_n <= '1';
			end if;
		end if;
	end process;

	OC : opll port map(
		XIN   => m_clock, --: in std_logic;
		XOUT  => open,    --: out std_logic;
		XENA  => run,     --: in std_logic;
		D     => D_buf,   --: in std_logic_vector(7 downto 0);
		A     => A_buf,   --: in std_logic;
		CS_n  => WE_n,    --: in std_logic;
		WE_n  => WE_n,    --: in std_logic;
		IC_n  => IC_n,    --: in std_logic;
		MO    => MO,      --: out std_logic_vector(9 downto 0);
		RO    => RO       --: out std_logic_vector(9 downto 0)
	);

-- MO メロティー出力
-- RO リズム出力

-- MOとROを加算する場合は範囲を0～1023に収めるために0x200を引く
--	process(m_clock)
--		variable mix : std_logic_vector(10 downto 0);
--	begin
--		if(m_clock'event and m_clock='1') then
--			if(run='1') then
--				mix := ('0'&MO) + ('0'&RO) - "01000000000";
--				wav <= mix(wav'range);
--			end if;
--		end if;
--	end process;

-- MOのみ使用の場合はそのまま出力
	sound <= MO;

end RTL;
