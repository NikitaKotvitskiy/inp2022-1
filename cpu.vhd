 --cpu.vhdl
 --Author: Nikita Kotvitskiy (xkotvi01)
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

----------------------------------
entity cpu is
port (
  CLK:        in  std_logic;
  RESET:      in  std_logic;
  
  DATA_ADDR:  out std_logic_vector  (12 downto 0);
  DATA_RDATA: out std_logic_vector  (7 downto 0);
  DATA_WDATA: in  std_logic_vector  (7 downto 0);
  DATA_EN:    out std_logic;
  DATA_RDWR:  out std_logic;
  
  IN_REQ:     out std_logic;
  IN_VLD:     in  std_logic;
  IN_DATA:    in  std_logic_vector  (7 downto 0);
  
  OUT_BUSY:   in  std_logic;
  OUT_DATA:   out std_logic_vector  (7 downto 0);
  OUT_WE:     out std_logic:
);
end cpu;
----------------------------------
architecture behavioral of cpu is
  signal PC_pc: std_logic_vector (12 downto 0);
  signal PC_inc: std_logic;
  signal PC_dec: std_logic;
  signal PC_res: std_logic;
  
  signal PTR_ptr: std_logic_vector (12 downto 0);
  signal PTR_inc: std_logic;
  signal PTR_dec: std_logic;
  signal PTR_res: std_logic;
  
  signal CNT_cnt: std_logic_vector (7 downto 0);
  signal CNT_inc: std_logic;
  signal CNT_dec: std_logic;
  signal CNT_res: std_logic;
  
  signal ALU_in: std_logic_vector (7 downto 0);
  signal ALU_inc: std_logic_vector (7 downto 0);
  signal ALU_dec: std_logic_vector (7 downto 0);

  signal MX1: std_logic_vector (2 downto 0);
  signal MX2: std_logic;
  
  type STATE_T is ( START_S,
                    GET_COM_S_1,
                    GET_COM_S_2,
                    SWITCH_S,
                    PTR_INC_S,
                    PTR_DEC_S,
                    DATA_INC_S_1,
                    DATA_INC_S_2,
                    DATA_DEC_S_1,
                    DATA_DEC_S_2,
                    WHILE_START_S_1,
                    WHILE_START_S_2,
                    WHILE_END_SEARCH_S_1,
                    WHILE_END_SEARCH_S_2,
                    WHILE_END_SEARCH_S_3,
                    WHILE_END_S,
                    WHILE_START_SEARCH_S_1,
                    WHILE_START_SEARCH_S_2,
                    WHILE_START_SEARCH_S_3,
                    DO_WHILE_START_S,
                    DO_WHILE_END_S_1,
                    DO_WHILE_END_S_2,
                    DO_WHILE_START_SEARCH_S_1,
                    DO_WHILE_START_SEARCH_S_2,
                    DO_WHILE_START_SEARCH_S_3,
                    PRINT_S,
                    WAIT_FOR_OUT_S,
                    READ_S,
                    WAIT_FOR_IN_S,
                    END_S
                  )
  signal state: STATE_T: START_S; 

begin
  
  --PC
  process (PC_inc, PC_dec, PC_res, CLK)
  begin
    if rising_edge(CLK) then
      if PC_inc = 1 and PC_dec = 0 and PC_res = 0 then
        PC_pc <= PC_pc + 1;
      elsif PC_in = 0 and PC_dec = 1 and PC_res = 0 then
        PC_pc <= PC_pc - 1;
      elsif PC_in = 0 and PC_dec = 0 and PC_res = 1 then
        PC_pc <= 0;
      end if;
    end if;
  end process;
  
  --CNT
  process (CNT_inc, CNT_dec, CNT_res, CLK)
  begin
    if rising_edge(CLK) then
      if CNT_inc = 1 and CNT_dec = 0 and CNT_res = 0 then
        CNT_cnt <= CNT_cnt + 1;
      elsif CNT_in = 0 and CNT_dec = 1 and CNT_res = 0 then
        CNT_cnt <= CNT_cnt - 1;
      elsif CNT_in = 0 and CNT_dec = 0 and CNT_res = 1 then
        CNT_cnt <= 0;
      end if;
    end if;
  end process;
  
  --PTR
  process (PTR_inc, PTR_dec, PTR_res, CLK)
  begin
    if rising_edge(CLK) then
      if PTR_inc = 1 and PTR_dec = 0 and PTR_res = 0 then
        if PTR_ptr = 8191 then
          PTR_ptr <= 4096;
        else 
          PTR_ptr <= PTR_ptr + 1;
        end if;
      elsif PTR_in = 0 and PTR_dec = 1 and PTR_res = 0 then
        if  PTR_ptr = 4096 then
          PTR_ptr <= 8191;
        else
          PTR_ptr <= PTR_ptr - 1;
        end if;
      elsif PTR_in = 0 and PTR_dec = 0 and PTR_res = 1 then
        PTR_ptr <= 4096;
      end if;
    end if;
  end process;
  
  --ALU
  process (DATA_RDATA)
  begin
    ALU_inc <= DATA_RDATA + 1;
    ALU_dec <= DATA_RDATA - 1;
  end process;
  
  --MX-1
  process (MX1)
  begin
    if MX1 = 0 then
      DATA_WDATA <= IN_DATA;
    elsif MX1 = 1 then
      DATA_WDATA <= ALU_inc;
    elsif MX1 = 2 then
      DATA_WDATA <= ALU_dec;
    end if;
  end process;

  --MX-2
  process (MX2)
  begin
    if MX2 = 0 then
      DATA_ADDR <= PTR_ptr;
    else
      DATA_ADDR <= PC_pc;
  end process;

  --   ______    _______    ___________
  --  |  ____|  |  _____|  |  __   __  |
  --  | |__     | |_____   | |  | |  | |
  --  |  __|    |_____  |  | |  | |  | | 
  --  | |        _____| |  | |  | |  | |   
  --  |_|       |_______|  |_|  |_|  |_|  

  process(CLK, RESET)
  begin
    if RESET = 1 then
      state := START;
    elsif rising_edge(CLK) then

      --START 
      if state = START_S then
        PC_inc <= 0;
        PC_dec <= 0;
        PC_res <= 1;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 1;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 1;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 0;
        state := GET_COM_S_1;
      
      --GET_COM
      elsif state = GET_COM_S_1 then
        PC_inc <= 0;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 1;
        DATA_RDWR <= 0;
        MX2 <= 1;
        state := GET_COM_S_2;
      elsif state = GET_COM_S_2 then
        PC_inc <= 1;
        DATA_EN <= 0;
        state := SWITCH_S;
      
      --SWITCH
      elsif state = SWITCH_S then
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 0;
        if DATA_RDATA = '>' then
          state := PTR_INC_S;
        elsif DATA_RDATA = '<' then
          state := PTR_DEC_S;
        elsif DATA_RDATA = '+' then
          state := DATA_INC_S_1;
        elsif DATA_RDATA = '-' then
          state := DATA_DEC_S_1;
        elsif DATA_RDATA = '[' then
          state := WHILE_START_S_1;
        elsif DATA_RDATA = ']' then
          state := WHILE_END_S;
        elsif DATA_RDATA = '(' then
          state := DO_WHILE_START_S;
        elsif DATA_RDATA = ')' then
          state := DO_WHILE_END_S_1;
        elsif DATA_RDATA = '.' then
          state := PRINT_S;
        elsif DATA_RDATA = ',' then
          state := READ_S;
        elsif DATA_RDATA = 0 then
          state := END_S;
        else
          PC_inc <= 1;
          state := GET_COM_S_1;
        end if;
      
      --PTR_INC
      elsif state = PTR_INC_S then
        PC_inc <= 1;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 1;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 0;
        state := GET_COM_S_1;

      --PTR_DEC
      elsif state = PTR_DEC_S then
        PC_inc <= 1;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 1;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 0;
        state := GET_COM_S_1;

      --DATA_INC
      elsif state = DATA_INC_S_1 then
        PC_inc <= 1;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 1;
        DATA_RDWR <= 0; 
        MX2 <= 0;
        state := DATA_INC_S_2;
      elsif state <= DATA_INC_S_2 then
        PC_inc <= 0;
        DATA_RDWR <= 1;
        MX1 <= 1;
        state := GET_COM_S_1;

      --DATA_DEC
      elsif state = DATA_INC_S_1 then
        PC_inc <= 1;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 1;
        DATA_RDWR <= 0; 
        MX2 <= 0;
        state := DATA_INC_S_2;
      elsif state <= DATA_INC_S_2 then
        PC_inc <= 0;
        DATA_RDWR <= 1;
        MX1 <= 2;
        state := GET_COM_S_1;

      --WHILE_START
      elsif state = WHILE_START_S_1 then
        PC_inc <= 1;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 1;
        DATA_RDWR <= 0; 
        MX2 <= 0;
        state := WHILE_START_S_2;
      elsif state = WHILE_START_S_2 then
        PC_inc <= 0;
        DATA_EN <= 0;
        if DATA_RDATA != 0 then
          CNT_inc <= 0;
          state := GET_COM_S_1;
        else
          CNT_inc <= 1;
          state := WHILE_END_SEARCH_S_1;
        end if;
      elsif state = WHILE_END_SEARCH_S_1 then
        PC_inc <= 0;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 1;
        DATA_RDWR <= 0; 
        MX2 <= 1;
        state := WHILE_END_SEARCH_S_2;
      elsif state = WHILE_END_SEARCH_S_2 then
        DATA_EN <= 0;
        if DATA_RDATA = '[' then
          CNT_inc <= 1;
          CNT_dec <= 0;
        elsif DATA_RDATA = ']' then
          CNT_inc <= 0;
          CNT_dec <= 1;
        state := WHILE_END_SEARCH_S_3;
      elsif state = WHILE_END_SEARCH_S_3 then
        PC_inc <= 1;
        CNT_inc <= 0;
        CNT_dec <= 0;
        if CNT_cnt = 0 then
          state := GET_COM_S_1;
        else
          state := WHILE_END_SEARCH_S_1;
        end if;
      
      --WHILE_END:
      elsif state = WHILE_END_S then
        PC_inc <= 0;
        PC_dec <= 1;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 1;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 0;
        state := WHILE_START_SEARCH_S_1;
      elsif state = WHILE_START_SEARCH_S_1 then
        PC_inc <= 0;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 1;
        DATA_RDWR <= 0;
        MX2 <= 1;
        state := WHILE_START_SEARCH_S_2;
      elsif state = WHILE_START_SEARCH_S_2 then
        DATA_EN <= 0;
        if DATA_RDATA = ']' then
          CNT_inc <= 1; 
        elsif DATA_RDATA = '[' then
          CNT_dec <= 1;
        end if;
        state := WHILE_START_SEARCH_S_3;
      elsif state = WHILE_START_SEARCH_S_3 then
        CNT_inc <= 0;
        CNT_dec <= 0;
        if CNT_cnt = 0 then
          state := WHILE_START;
        else
          PC_dec <= 1;
          state := WHILE_START_SEARCH_S_1;
        end if;
      
      --DO_WHILE_START
      elsif state = DO_WHILE_START_S then
        PC_inc <= 1;
        PC_dec <= 0;
        PC_res <= 0;
        PTR_inc <= 0;
        PTR_dec <= 0;
        PTR_res <= 0;
        CNT_inc <= 0;
        CNT_dec <= 0;
        CNT_res <= 0;
        OUT_WE <= 0;
        IN_REQ <= 0;
        DATA_EN <= 0;
        state := GET_COM_S_1;
      
      --DO_WHILE_END
    elsif state = DO_WHILE_END_S_1 then
      PC_inc <= 0;
      PC_dec <= 0;
      PC_res <= 0;
      PTR_inc <= 0;
      PTR_dec <= 0;
      PTR_res <= 0;
      CNT_inc <= 0;
      CNT_dec <= 0;
      CNT_res <= 0;
      OUT_WE <= 0;
      IN_REQ <= 0;
      DATA_EN <= 1;
      DATA_RDWR <= 0;
      MX2 <= 0;
      state := DO_WHILE_START_SEARCH_S_2;
    elsif state = DO_WHILE_START_SEARCH_S_2 then
      DATA_EN <= 0;
      if DATA_RDATA = 0 then
        PC_inc <= 1;
        state := GET_COM_S_1;
      else
        PC_dec <= 1;
        CNT_inc <= 1;
        state := DO_WHILE_START_SEARCH_S_1;
      end if;
    elsif state = DO_WHILE_START_SEARCH_S_1 then
      PC_inc <= 0;
      PC_dec <= 0;
      PC_res <= 0;
      PTR_inc <= 0;
      PTR_dec <= 0;
      PTR_res <= 0;
      CNT_inc <= 0;
      CNT_dec <= 0;
      CNT_res <= 0;
      OUT_WE <= 0;
      IN_REQ <= 0;
      DATA_EN <= 1;
      DATA_RDWR <= 0;
      MX2 <= 1;
      state := DO_WHILE_START_SEARCH_S_2
    elsif state = DO_WHILE_START_SEARCH_S_2 then
      DATA_EN <= 0;
      if DATA_RDATA = ')' then
        CNT_inc <= 1;
      elsif DATA_RDATA = '(' then
        CNT_dec <= 1;
      end if;
      state := DO_WHILE_START_SEARCH_S_3;
    elsif state = DO_WHILE_START_SEARCH_S_3 then
      CNT_inc <= 0;
      CNT_dec <= 0;
      if CNT_cnt = 0 then
        PC_inc <= 1;
        state := GET_COM_S_1;
      else
        PC_dec <= 1;
        state := DO_WHILE_START_SEARCH_S_1;
      end if;

    --PRINT
    elsif state = PRINT_S then
      PC_inc <= 1;
      PC_dec <= 0;
      PC_res <= 0;
      PTR_inc <= 0;
      PTR_dec <= 0;
      PTR_res <= 0;
      CNT_inc <= 0;
      CNT_dec <= 0;
      CNT_res <= 0;
      OUT_WE <= 0;
      IN_REQ <= 0;
      DATA_EN <= 1;
      DATA_RDWR <= 0;
      MX2 <= 0;
      state := WAIT_FOR_OUT_S;
    elsif state = WAIT_FOR_OUT_S then
      PC_inc <= 0;
      DATA_EN <= 0;
      if OUT_BUSY = 1 then
        OUT_WE <= 0
        state := WAIT_FOR_OUT_S;
      else
        OUT_WE <= 1;
        OUT_DATA <= DATA_RDATA;
        state := GET_COM_S_1;
      end if;

    --READ
    elsif state = READ_S then
      PC_inc <= 1;
      PC_dec <= 0;
      PC_res <= 0;
      PTR_inc <= 0;
      PTR_dec <= 0;
      PTR_res <= 0;
      CNT_inc <= 0;
      CNT_dec <= 0;
      CNT_res <= 0;
      OUT_WE <= 0;
      IN_REQ <= 1;
      DATA_EN <= 0;
      state := WAIT_FOR_IN_S;
    elsif state = WAIT_FOR_IN_S then
      PC_inc <= 0;
      if IN_VLD = 1 then
        IN_REQ <= 0;
        DATA_EN <= 1;
        DATA_RDWR <= 1;
        MX1 <= 0
        state := GET_COM_S_1;
      else
        state := WAIT_FOR_IN_S;
      end if;

    --END
    elsif state = END_S then
      PC_inc <= 0;
      PC_dec <= 0;
      PC_res <= 0;
      PTR_inc <= 0;
      PTR_dec <= 0;
      PTR_res <= 0;
      CNT_inc <= 0;
      CNT_dec <= 0;
      CNT_res <= 0;
      OUT_WE <= 0;
      IN_REQ <= 0;
      DATA_EN <= 0;
      state := END_S;

    end if;
  end process;

end behavioral;
