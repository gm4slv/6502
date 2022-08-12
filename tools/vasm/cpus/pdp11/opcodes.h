  /* double operand */
  "mov",  {ANY,ANY}, {0010000,DO,STD},
  "cmp",  {ANY,ANY}, {0020000,DO,STD},
  "bit",  {ANY,ANY}, {0030000,DO,STD},
  "bic",  {ANY,ANY}, {0040000,DO,STD},
  "bis",  {ANY,ANY}, {0050000,DO,STD},
  "add",  {ANY,ANY}, {0060000,DO,STD},
  "movb", {ANY,ANY}, {0110000,DO,STD},
  "cmpb", {ANY,ANY}, {0120000,DO,STD},
  "bitb", {ANY,ANY}, {0130000,DO,STD},
  "bicb", {ANY,ANY}, {0140000,DO,STD},
  "bisb", {ANY,ANY}, {0150000,DO,STD},
  "sub",  {ANY,ANY}, {0160000,DO,STD},

  /* register source or destination */
  "jsr",  {REG,ANY}, {0004000,RO,STD},
  "mul",  {ANY,REG}, {0070000,RO,EIS},
  "div",  {ANY,REG}, {0071000,RO,EIS},
  "ash",  {ANY,REG}, {0072000,RO,EIS},
  "ashc", {ANY,REG}, {0073000,RO,EIS},
  "xor",  {REG,ANY}, {0074000,RO,STD},

  /* single oprand */
  "jmp",  {ANY,0},   {0000100,SO,STD},
  "swab", {ANY,0},   {0000300,SO,STD},
  "clr",  {ANY,0},   {0005000,SO,STD},
  "com",  {ANY,0},   {0005100,SO,STD},
  "inc",  {ANY,0},   {0005200,SO,STD},
  "dec",  {ANY,0},   {0005300,SO,STD},
  "neg",  {ANY,0},   {0005400,SO,STD},
  "adc",  {ANY,0},   {0005500,SO,STD},
  "sbc",  {ANY,0},   {0005600,SO,STD},
  "tst",  {ANY,0},   {0005700,SO,STD},
  "ror",  {ANY,0},   {0006000,SO,STD},
  "rol",  {ANY,0},   {0006100,SO,STD},
  "asr",  {ANY,0},   {0006200,SO,STD},
  "asl",  {ANY,0},   {0006300,SO,STD},
  "mfpi", {ANY,0},   {0006500,SO,MSP},
  "mtpi", {ANY,0},   {0006600,SO,MSP},
  "sxt",  {ANY,0},   {0006700,SO,STD},
  "clrb", {ANY,0},   {0105000,SO,STD},
  "comb", {ANY,0},   {0105100,SO,STD},
  "incb", {ANY,0},   {0105200,SO,STD},
  "decb", {ANY,0},   {0105300,SO,STD},
  "negb", {ANY,0},   {0105400,SO,STD},
  "adcb", {ANY,0},   {0105500,SO,STD},
  "sbcb", {ANY,0},   {0105600,SO,STD},
  "tstb", {ANY,0},   {0105700,SO,STD},
  "rorb", {ANY,0},   {0106000,SO,STD},
  "rolb", {ANY,0},   {0106100,SO,STD},
  "asrb", {ANY,0},   {0106200,SO,STD},
  "aslb", {ANY,0},   {0106300,SO,STD},
  "mtps", {ANY,0},   {0106400,SO,PSW},
  "mfpd", {ANY,0},   {0106500,SO,MSP},
  "mtpd", {ANY,0},   {0106600,SO,MSP},
  "mfps", {ANY,0},   {0106700,SO,PSW},

  /* branches */
  "br",   {EXP,0},   {0000400,BR,STD},
  "bne",  {EXP,0},   {0001000,BR,STD},
  "beq",  {EXP,0},   {0001400,BR,STD},
  "bge",  {EXP,0},   {0002000,BR,STD},
  "blt",  {EXP,0},   {0002400,BR,STD},
  "bgt",  {EXP,0},   {0003000,BR,STD},
  "ble",  {EXP,0},   {0003400,BR,STD},
  "bpl",  {EXP,0},   {0100000,BR,STD},
  "bmi",  {EXP,0},   {0100400,BR,STD},
  "bhi",  {EXP,0},   {0101000,BR,STD},
  "blos", {EXP,0},   {0101400,BR,STD},
  "bvc",  {EXP,0},   {0102000,BR,STD},
  "bvs",  {EXP,0},   {0102400,BR,STD},
  "bcc",  {EXP,0},   {0103000,BR,STD},
  "bcs",  {EXP,0},   {0103400,BR,STD},
  "bhis", {EXP,0},   {0103000,BR,STD},
  "blo",  {EXP,0},   {0103400,BR,STD},

  /* register and branch */
  "sob",  {REG,EXP}, {0077000,RB,STD},

  /* single register */
  "rts",  {REG,0},   {0000200,RG,STD},
  "fadd", {REG,0},   {0075000,RG,FIS},
  "fsub", {REG,0},   {0075010,RG,FIS},
  "fmul", {REG,0},   {0075020,RG,FIS},
  "fdiv", {REG,0},   {0075030,RG,FIS},

  /* traps */
  "emt",  {EXP,0},   {0104000,TP,STD},
  "trap", {EXP,0},   {0104400,TP,STD},

  /* no operand */
  "halt", {0},       {0000000,NO,STD},
  "wait", {0},       {0000001,NO,STD},
  "rti",  {0},       {0000002,NO,STD},
  "bpt",  {0},       {0000003,NO,STD},
  "iot",  {0},       {0000004,NO,STD},
  "reset",{0},       {0000005,NO,STD},
  "rtt",  {0},       {0000006,NO,STD},
  "nop",  {0},       {0000240,NO,STD},
  "clc",  {0},       {0000241,NO,STD},
  "clv",  {0},       {0000242,NO,STD},
  "clz",  {0},       {0000244,NO,STD},
  "cln",  {0},       {0000250,NO,STD},
  "ccc",  {0},       {0000257,NO,STD},
  "sec",  {0},       {0000261,NO,STD},
  "sev",  {0},       {0000262,NO,STD},
  "sez",  {0},       {0000264,NO,STD},
  "sen",  {0},       {0000270,NO,STD},
  "scc",  {0},       {0000277,NO,STD},
