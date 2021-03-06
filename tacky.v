// basic sizes of things
`define Word	[15:0]
`define HalfWord[7:0]
`define Opcode  [4:0]
`define Opcode1	[15:11]
`define Opcode2 [7:3]
`define Reg     [2:0]
`define Reg1    [10:8]
`define Reg2    [2:0]
`define Imm8    [7:0]
`define State	[4:0]
`define RegSize [16:0]
`define RegType [16]
`define RegValue[15:0]
`define MemSize [65535:0]

// opcode values, also state numbers
`define OPnot	5'b00000
`define OPand	5'b00001
`define OPor	5'b00010
`define OPxor	5'b00011
`define OPadd	5'b00100
`define OPsub	5'b00101
`define OPmul	5'b00110
`define OPdiv	5'b00111
`define OPsh	5'b01000
`define OPslt	5'b01001
`define OPjr	5'b01010
`define OPlf	5'b01011
`define OPli	5'b01100
`define OPr2a	5'b01101
`define OPa2r	5'b01110
`define OPst	5'b01111
`define OPcvt   5'b10000
`define OPjnz8  5'b11001
`define OPjz8   5'b11010
`define OPjp8   5'b11011
`define OPcf8   5'b11100
`define OPci8   5'b11101
`define OPpre   5'b11110
`define OPsys   5'b11111

//Bit value for float vs int registers
`define Float   1'b1
`define Int     1'b0

//Control signal channels
`define Signal      [3:0]
`define J_8_Compare [1:0]
`define Reg_Value   [2]
`define Jr_Load     [3]

/*
module tacky_control(control, instruction, clk);
output reg `Signal control;
input `Word instruction; input clk

reg `Word pc;
wire `Word result;

counter(result, instruction `Imm8)

always @(posedge clk) begin
end

always @(posedge clk) begin
end

endmodule

//Incrementer for pc
module incrementer(newpc, pc);
    output `Word newpc; input `Word pc; 
    assign newpc = pc + 1;
endmodule
*/

//Compare to see if a register value is or is not 0, as well as directly set the result if needed. 
//Used for jnz8, jp8, and jz8 (2b'00 is for non of them).
module compare_to_0(result, value, condition);
output reg result; input `Word value; input [1:0] condition;
always @(*)
    case(condition)
        2'b00: result = 0;
        2'b01: result = value == 0;
        2'b10: result = value != 0;
        2'b11: result = 1;
    endcase
endmodule

//circuit which decides next value of pc
//Signal bits:
//[1:0]: decide whether to use load incremeted pc or {pre, immediate}
//[2]: decide which register to use for jr 
//[3]: decide between previous pc decision result and register value for pc (if[1:0] non-zero, should always be 0)
module counter(new_pc, immediate, reg1, reg2, control_logic, pc);
output `Word new_pc;
input `Signal control_logic; input `Word reg1, reg2, immediate, pc;
wire `Word pc_inc, pc_inc_vs_immediate, pc_result, reg1_vs_reg2;  
wire compare_result;

incrementer inc(pc_inc, pc);
compare_to_0 compare(compare_result, reg1, control_logic `J_8_Compare);
assign pc_inc_vs_immediate = (compare_result) ? immediate : pc_inc;
assign reg1_vs_reg2 = (control_logic `Reg_Value) ? reg2 : reg1;
assign pc_result = (control_logic `Jr_Load) ?  reg1_vs_reg2 : pc_inc_vs_immediate;
assign new_pc = pc_result;

endmodule

module test_jp;
reg `Word pc, reg1, reg2, immediate;
reg `Signal signal;
reg clk = 0;
wire `Word result;

counter count(result, immediate, reg1, reg2, signal, pc);



always @(posedge clk) begin
    pc <= result;
end

initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, pc);
    pc = 0;
    reg1 = 16'h00ff;
    reg2 = 16'h0ff0;
    immediate = 16'h1234;
    signal = 4'h0;
    while(pc < 16'hffff) begin
    #1 clk = 1;
    #1 clk = 0;
    end
    $finish;
end

initial begin
    #50 signal = 4'h2;
    #10 signal = 4'h0;
    
    #10 reg1 = 0;
    #10 signal = 4'h1;
    #10 signal = 4'h0;
    #10 reg1 = 16'h00ff;
    
    #1 signal = 4'h3;
    #10 signal = 4'h0;
    
    #10 signal = 4'h8;

    #10 signal = 4'hc;
    
    #10 signal = 4'h0;

end

endmodule








// Floating point Verilog modules for CPE480
// Created February 19, 2019 by Henry Dietz, http://aggregate.org/hankd
// Distributed under CC BY 4.0, https://creativecommons.org/licenses/by/4.0/

// Field definitions
`define	WORD	[15:0]	// generic machine word size
`define	INT	signed [15:0]	// integer size
`define FLOAT	[15:0]	// half-precision float size
`define FSIGN	[15]	// sign bit
`define FEXP	[14:7]	// exponent
`define FFRAC	[6:0]	// fractional part (leading 1 implied)

// Constants
`define	FZERO	16'b0	  // float 0
`define F32767  16'h46ff  // closest approx to 32767, actually 32640
`define F32768  16'hc700  // -32768

// Count leading zeros, 16-bit (5-bit result) d=lead0s(s)
module lead0s(d, s);
output wire [4:0] d;
input wire `WORD s;
wire [4:0] t;
wire [7:0] s8;
wire [3:0] s4;
wire [1:0] s2;
assign t[4] = 0;
assign {t[3],s8} = ((|s[15:8]) ? {1'b0,s[15:8]} : {1'b1,s[7:0]});
assign {t[2],s4} = ((|s8[7:4]) ? {1'b0,s8[7:4]} : {1'b1,s8[3:0]});
assign {t[1],s2} = ((|s4[3:2]) ? {1'b0,s4[3:2]} : {1'b1,s4[1:0]});
assign t[0] = !s2[1];
assign d = (s ? t : 16);
endmodule

// Float set-less-than, 16-bit (1-bit result) torf=a<b
module fslt(torf, a, b);
output wire torf;
input wire `FLOAT a, b;
assign torf = (a `FSIGN && !(b `FSIGN)) ||
	      (a `FSIGN && b `FSIGN && (a[14:0] > b[14:0])) ||
	      (!(a `FSIGN) && !(b `FSIGN) && (a[14:0] < b[14:0]));
endmodule

// Floating-point addition, 16-bit r=a+b
module fadd(r, a, b);
output wire `FLOAT r;
input wire `FLOAT a, b;
wire `FLOAT s;
wire [8:0] sexp, sman, sfrac;
wire [7:0] texp, taman, tbman;
wire [4:0] slead;
wire ssign, aegt, amgt, eqsgn;
assign r = ((a == 0) ? b : ((b == 0) ? a : s));
assign aegt = (a `FEXP > b `FEXP);
assign texp = (aegt ? (a `FEXP) : (b `FEXP));
assign taman = (aegt ? {1'b1, (a `FFRAC)} : ({1'b1, (a `FFRAC)} >> (texp - a `FEXP)));
assign tbman = (aegt ? ({1'b1, (b `FFRAC)} >> (texp - b `FEXP)) : {1'b1, (b `FFRAC)});
assign eqsgn = (a `FSIGN == b `FSIGN);
assign amgt = (taman > tbman);
assign sman = (eqsgn ? (taman + tbman) : (amgt ? (taman - tbman) : (tbman - taman)));
lead0s m0(slead, {sman, 7'b0});
assign ssign = (amgt ? (a `FSIGN) : (b `FSIGN));
assign sfrac = sman << slead;
assign sexp = (texp + 1) - slead;
assign s = (sman ? (sexp ? {ssign, sexp[7:0], sfrac[7:1]} : 0) : 0);
endmodule

// Floating-point multiply, 16-bit r=a*b
module fmul(r, a, b);
output wire `FLOAT r;
input wire `FLOAT a, b;
wire [15:0] m; // double the bits in a fraction, we need high bits
wire [7:0] e;
wire s;
assign s = (a `FSIGN ^ b `FSIGN);
assign m = ({1'b1, (a `FFRAC)} * {1'b1, (b `FFRAC)});
assign e = (((a `FEXP) + (b `FEXP)) -127 + m[15]);
assign r = (((a == 0) || (b == 0)) ? 0 : (m[15] ? {s, e, m[14:8]} : {s, e, m[13:7]}));
endmodule

// Floating-point reciprocal, 16-bit r=1.0/a
// Note: requires initialized inverse fraction lookup table
module frecip(r, a);
output wire `FLOAT r;
input wire `FLOAT a;
reg [6:0] look[127:0];
initial $readmemh0(look);
assign r `FSIGN = a `FSIGN;
assign r `FEXP = 253 + (!(a `FFRAC)) - a `FEXP;
assign r `FFRAC = look[a `FFRAC];
endmodule

// Floating-point shift, 16 bit
// Shift +left,-right by integer
module fshift(r, f, i);
output wire `FLOAT r;
input wire `FLOAT f;
input wire `INT i;
assign r `FFRAC = f `FFRAC;
assign r `FSIGN = f `FSIGN;
assign r `FEXP = (f ? (f `FEXP + i) : 0);
endmodule

// Integer to float conversion, 16 bit
module i2f(f, i);
output wire `FLOAT f;
input wire `INT i;
wire [4:0] lead;
wire `WORD pos;
assign pos = (i[15] ? (-i) : i);
lead0s m0(lead, pos);
assign f `FFRAC = (i ? ({pos, 8'b0} >> (16 - lead)) : 0);
assign f `FSIGN = i[15];
assign f `FEXP = (i ? (128 + (14 - lead)) : 0);
endmodule

// Float to integer conversion, 16 bit
// Note: out-of-range values go to -32768 or 32767
module f2i(i, f);
output wire `INT i;
input wire `FLOAT f;
wire `FLOAT ui;
wire tiny, big;
fslt m0(tiny, f, `F32768);
fslt m1(big, `F32767, f);
assign ui = {1'b1, f `FFRAC, 16'b0} >> ((128+22) - f `FEXP);
assign i = (tiny ? 0 : (big ? 32767 : (f `FSIGN ? (-ui) : ui)));
endmodule

// Testing
module testbench;
reg `FLOAT a, b;
reg `WORD r;
wire `FLOAT addr,mulr, recr, shir, i2fr;
wire `INT f2ir, i, j, ia, ib, addri;
reg `WORD ref[1024:0];
f2i myfa(ia, a);
f2i myfb(ib, b);
fadd myadd(addr, a, b);
f2i myaddf(addri, addr);
fmul mymul(mulr, a, b);
frecip myrecip(recr, a);
fshift myshift(shir, a, f2ir);
f2i myf2i(f2ir, a);
f2i myib(i, b);
f2i myiadd(j, addr);
i2f myi2f(i2fr, f2ir);
initial begin
  $readmemh1(ref);
  r = 0;

  while (ref[r] != 0) begin
    a = ref[r]; b = ref[r+1];
    #1 $display("Testing (int)%x = %d, (int)%x = %d", a, ia, b, ib);
    if (addr != ref[r+2]) $display("%x + %x = %x # %x", a, b, addr, ref[r+2]);
    if (mulr != ref[r+3]) $display("%x * %x = %x # %x", a, b, mulr, ref[r+3]);
    if (recr != ref[r+4]) $display("1 / %x = %x # %x", a, recr, ref[r+4]);
    r = r + 5;
  end
end
endmodule

