`timescale 1ns / 1ps


// PPG cell — 4-bit × 4-bit  (used by N=8 and N=16)
module ppg4 (
    input  [3:0] a_slice,
    input  [3:0] b_slice,
    input        en,
    output [7:0] product
);
    assign product = en ? (a_slice * b_slice) : 8'b0;
endmodule

// PPG cell — 8-bit × 8-bit  (used by N=32)
module ppg8 (
    input  [7:0]  a_slice,
    input  [7:0]  b_slice,
    input         en,
    output [15:0] product
);
    assign product = en ? (a_slice * b_slice) : 16'b0;
endmodule

// mantissa_mult_2r — 2-region × 2-region, 4-bit cells  (N=8)
module mantissa_mult_2r #(
    parameter MANT_W = 8
)(
    input  [MANT_W-1:0]   A,
    input  [MANT_W-1:0]   B,
    input                 ctl_A,   // 1-bit
    input                 ctl_B,
    output [2*MANT_W-1:0] product
);
    localparam OFF2 = 4;    // MSB 4-bit slice: LSB sits at bit 4
    localparam OFF1 = 0;    // LSB 4-bit slice: LSB sits at bit 0
    localparam P    = 2 * MANT_W;   // 16

    wire [3:0] A2 = A[7:4];
    wire [3:0] A1 = A[3:0];
    wire [3:0] B2 = B[7:4];
    wire [3:0] B1 = B[3:0];

    // ctl=0 → both active; ctl=1 → MSB only
    wire RV2_en = 1'b1;
    wire RV1_en = ~ctl_A;
    wire RH2_en = 1'b1;
    wire RH1_en = ~ctl_B;

    wire [7:0] p22, p12, p21, p11;
    ppg4 pg22(.a_slice(A2),.b_slice(B2),.en(RV2_en & RH2_en),.product(p22));
    ppg4 pg12(.a_slice(A1),.b_slice(B2),.en(RV1_en & RH2_en),.product(p12));
    ppg4 pg21(.a_slice(A2),.b_slice(B1),.en(RV2_en & RH1_en),.product(p21));
    ppg4 pg11(.a_slice(A1),.b_slice(B1),.en(RV1_en & RH1_en),.product(p11));

    wire [P-1:0] s22 = {{P-8{1'b0}}, p22} << (OFF2+OFF2);  // <<8
    wire [P-1:0] s12 = {{P-8{1'b0}}, p12} << (OFF1+OFF2);  // <<4
    wire [P-1:0] s21 = {{P-8{1'b0}}, p21} << (OFF2+OFF1);  // <<4
    wire [P-1:0] s11 = {{P-8{1'b0}}, p11} << (OFF1+OFF1);  // <<0

    assign product = s22 + s12 + s21 + s11;
endmodule


// mantissa_mult_4r4 — 4-region × 4-region, 4-bit cells  (N=16)
module mantissa_mult_4r4 #(
    parameter MANT_W = 16
)(
    input  [MANT_W-1:0]   A,
    input  [MANT_W-1:0]   B,
    input  [1:0]          ctl_A,
    input  [1:0]          ctl_B,
    output [2*MANT_W-1:0] product
);
    localparam OFF4 = MANT_W - 4;
    localparam OFF3 = MANT_W - 8;
    localparam OFF2 = MANT_W - 12;
    localparam OFF1 = 0;
    localparam P    = 2 * MANT_W;

    // Pad A and B to 16 bits (MSB-aligned, zero-fill LSBs) so all 4-bit
    // slice indices [15:12],[11:8],[7:4],[3:0] are always in-range,
    // regardless of MANT_W (handles es=5 where MANT_W=12, etc.)
    wire [15:0] Ap = {{A, {(16-MANT_W){1'b0}}}};
    wire [15:0] Bp = {{B, {(16-MANT_W){1'b0}}}};

    wire [3:0] A4 = Ap[15:12];
    wire [3:0] A3 = Ap[11: 8];
    wire [3:0] A2 = Ap[ 7: 4];
    wire [3:0] A1 = Ap[ 3: 0];

    wire [3:0] B4 = Bp[15:12];
    wire [3:0] B3 = Bp[11: 8];
    wire [3:0] B2 = Bp[ 7: 4];
    wire [3:0] B1 = Bp[ 3: 0];

    wire RV4_en = 1'b1;
    wire RV3_en = ctl_A[1] | ctl_A[0];
    wire RV2_en = ctl_A[1];
    wire RV1_en = ctl_A[1] & ctl_A[0];

    wire RH4_en = 1'b1;
    wire RH3_en = ctl_B[1] | ctl_B[0];
    wire RH2_en = ctl_B[1];
    wire RH1_en = ctl_B[1] & ctl_B[0];

    wire [7:0] p44,p34,p24,p14, p43,p33,p23,p13, p42,p32,p22,p12, p41,p31,p21,p11;

    ppg4 pg44(.a_slice(A4),.b_slice(B4),.en(RV4_en&RH4_en),.product(p44));
    ppg4 pg34(.a_slice(A3),.b_slice(B4),.en(RV3_en&RH4_en),.product(p34));
    ppg4 pg24(.a_slice(A2),.b_slice(B4),.en(RV2_en&RH4_en),.product(p24));
    ppg4 pg14(.a_slice(A1),.b_slice(B4),.en(RV1_en&RH4_en),.product(p14));

    ppg4 pg43(.a_slice(A4),.b_slice(B3),.en(RV4_en&RH3_en),.product(p43));
    ppg4 pg33(.a_slice(A3),.b_slice(B3),.en(RV3_en&RH3_en),.product(p33));
    ppg4 pg23(.a_slice(A2),.b_slice(B3),.en(RV2_en&RH3_en),.product(p23));
    ppg4 pg13(.a_slice(A1),.b_slice(B3),.en(RV1_en&RH3_en),.product(p13));

    ppg4 pg42(.a_slice(A4),.b_slice(B2),.en(RV4_en&RH2_en),.product(p42));
    ppg4 pg32(.a_slice(A3),.b_slice(B2),.en(RV3_en&RH2_en),.product(p32));
    ppg4 pg22(.a_slice(A2),.b_slice(B2),.en(RV2_en&RH2_en),.product(p22));
    ppg4 pg12(.a_slice(A1),.b_slice(B2),.en(RV1_en&RH2_en),.product(p12));

    ppg4 pg41(.a_slice(A4),.b_slice(B1),.en(RV4_en&RH1_en),.product(p41));
    ppg4 pg31(.a_slice(A3),.b_slice(B1),.en(RV3_en&RH1_en),.product(p31));
    ppg4 pg21(.a_slice(A2),.b_slice(B1),.en(RV2_en&RH1_en),.product(p21));
    ppg4 pg11(.a_slice(A1),.b_slice(B1),.en(RV1_en&RH1_en),.product(p11));

    wire [P-1:0] s44={{P-8{1'b0}},p44}<<(OFF4+OFF4); wire [P-1:0] s34={{P-8{1'b0}},p34}<<(OFF3+OFF4);
    wire [P-1:0] s24={{P-8{1'b0}},p24}<<(OFF2+OFF4); wire [P-1:0] s14={{P-8{1'b0}},p14}<<(OFF1+OFF4);
    wire [P-1:0] s43={{P-8{1'b0}},p43}<<(OFF4+OFF3); wire [P-1:0] s33={{P-8{1'b0}},p33}<<(OFF3+OFF3);
    wire [P-1:0] s23={{P-8{1'b0}},p23}<<(OFF2+OFF3); wire [P-1:0] s13={{P-8{1'b0}},p13}<<(OFF1+OFF3);
    wire [P-1:0] s42={{P-8{1'b0}},p42}<<(OFF4+OFF2); wire [P-1:0] s32={{P-8{1'b0}},p32}<<(OFF3+OFF2);
    wire [P-1:0] s22={{P-8{1'b0}},p22}<<(OFF2+OFF2); wire [P-1:0] s12={{P-8{1'b0}},p12}<<(OFF1+OFF2);
    wire [P-1:0] s41={{P-8{1'b0}},p41}<<(OFF4+OFF1); wire [P-1:0] s31={{P-8{1'b0}},p31}<<(OFF3+OFF1);
    wire [P-1:0] s21={{P-8{1'b0}},p21}<<(OFF2+OFF1); wire [P-1:0] s11={{P-8{1'b0}},p11}<<(OFF1+OFF1);

    assign product = s44+s34+s24+s14 + s43+s33+s23+s13 + s42+s32+s22+s12 + s41+s31+s21+s11;
endmodule


// mantissa_mult_4r8 — 4-region × 4-region, 8-bit cells  (N=32)

module mantissa_mult_4r8 #(
    parameter MANT_W = 32
)(
    input  [MANT_W-1:0]   A,
    input  [MANT_W-1:0]   B,
    input  [1:0]          ctl_A,
    input  [1:0]          ctl_B,
    output [2*MANT_W-1:0] product
);
    localparam OFF4 = MANT_W - 8;
    localparam OFF3 = MANT_W - 16;
    localparam OFF2 = MANT_W - 24;
    localparam OFF1 = 0;
    localparam P    = 2 * MANT_W;

    wire [7:0] A4 = A[MANT_W-1   : MANT_W-8];
    wire [7:0] A3 = A[MANT_W-9   : MANT_W-16];
    wire [7:0] A2 = A[MANT_W-17  : MANT_W-24];
    wire [7:0] A1 = {{(8-(MANT_W-24)){1'b0}}, A[MANT_W-25:0]};

    wire [7:0] B4 = B[MANT_W-1   : MANT_W-8];
    wire [7:0] B3 = B[MANT_W-9   : MANT_W-16];
    wire [7:0] B2 = B[MANT_W-17  : MANT_W-24];
    wire [7:0] B1 = {{(8-(MANT_W-24)){1'b0}}, B[MANT_W-25:0]};

    wire RV4_en = 1'b1;
    wire RV3_en = ctl_A[1] | ctl_A[0];
    wire RV2_en = ctl_A[1];
    wire RV1_en = ctl_A[1] & ctl_A[0];

    wire RH4_en = 1'b1;
    wire RH3_en = ctl_B[1] | ctl_B[0];
    wire RH2_en = ctl_B[1];
    wire RH1_en = ctl_B[1] & ctl_B[0];

    wire [15:0] p44,p34,p24,p14, p43,p33,p23,p13, p42,p32,p22,p12, p41,p31,p21,p11;

    ppg8 pg44(.a_slice(A4),.b_slice(B4),.en(RV4_en&RH4_en),.product(p44));
    ppg8 pg34(.a_slice(A3),.b_slice(B4),.en(RV3_en&RH4_en),.product(p34));
    ppg8 pg24(.a_slice(A2),.b_slice(B4),.en(RV2_en&RH4_en),.product(p24));
    ppg8 pg14(.a_slice(A1),.b_slice(B4),.en(RV1_en&RH4_en),.product(p14));

    ppg8 pg43(.a_slice(A4),.b_slice(B3),.en(RV4_en&RH3_en),.product(p43));
    ppg8 pg33(.a_slice(A3),.b_slice(B3),.en(RV3_en&RH3_en),.product(p33));
    ppg8 pg23(.a_slice(A2),.b_slice(B3),.en(RV2_en&RH3_en),.product(p23));
    ppg8 pg13(.a_slice(A1),.b_slice(B3),.en(RV1_en&RH3_en),.product(p13));

    ppg8 pg42(.a_slice(A4),.b_slice(B2),.en(RV4_en&RH2_en),.product(p42));
    ppg8 pg32(.a_slice(A3),.b_slice(B2),.en(RV3_en&RH2_en),.product(p32));
    ppg8 pg22(.a_slice(A2),.b_slice(B2),.en(RV2_en&RH2_en),.product(p22));
    ppg8 pg12(.a_slice(A1),.b_slice(B2),.en(RV1_en&RH2_en),.product(p12));

    ppg8 pg41(.a_slice(A4),.b_slice(B1),.en(RV4_en&RH1_en),.product(p41));
    ppg8 pg31(.a_slice(A3),.b_slice(B1),.en(RV3_en&RH1_en),.product(p31));
    ppg8 pg21(.a_slice(A2),.b_slice(B1),.en(RV2_en&RH1_en),.product(p21));
    ppg8 pg11(.a_slice(A1),.b_slice(B1),.en(RV1_en&RH1_en),.product(p11));

    wire [P-1:0] s44={{P-16{1'b0}},p44}<<(OFF4+OFF4); wire [P-1:0] s34={{P-16{1'b0}},p34}<<(OFF3+OFF4);
    wire [P-1:0] s24={{P-16{1'b0}},p24}<<(OFF2+OFF4); wire [P-1:0] s14={{P-16{1'b0}},p14}<<(OFF1+OFF4);
    wire [P-1:0] s43={{P-16{1'b0}},p43}<<(OFF4+OFF3); wire [P-1:0] s33={{P-16{1'b0}},p33}<<(OFF3+OFF3);
    wire [P-1:0] s23={{P-16{1'b0}},p23}<<(OFF2+OFF3); wire [P-1:0] s13={{P-16{1'b0}},p13}<<(OFF1+OFF3);
    wire [P-1:0] s42={{P-16{1'b0}},p42}<<(OFF4+OFF2); wire [P-1:0] s32={{P-16{1'b0}},p32}<<(OFF3+OFF2);
    wire [P-1:0] s22={{P-16{1'b0}},p22}<<(OFF2+OFF2); wire [P-1:0] s12={{P-16{1'b0}},p12}<<(OFF1+OFF2);
    wire [P-1:0] s41={{P-16{1'b0}},p41}<<(OFF4+OFF1); wire [P-1:0] s31={{P-16{1'b0}},p31}<<(OFF3+OFF1);
    wire [P-1:0] s21={{P-16{1'b0}},p21}<<(OFF2+OFF1); wire [P-1:0] s11={{P-16{1'b0}},p11}<<(OFF1+OFF1);

    assign product = s44+s34+s24+s14 + s43+s33+s23+s13 + s42+s32+s22+s12 + s41+s31+s21+s11;
endmodule


// LOD — Leading-One Detector.  Counts position of first '1' from MSB.


// 8-bit input → 3-bit output  (used by N=8, and inside the 16/32-bit LODs)
module lod8 (input [7:0] in, output [2:0] out, output vld);
    assign vld = |in;
    assign out = in[7] ? 3'd0 : in[6] ? 3'd1 : in[5] ? 3'd2 : in[4] ? 3'd3 :
                 in[3] ? 3'd4 : in[2] ? 3'd5 : in[1] ? 3'd6 : in[0] ? 3'd7 : 3'd0;
endmodule

// 16-bit input → 4-bit output  (used by N=16)
module lod16 (input [15:0] in, output [3:0] out, output vld);
    wire [2:0] outh, outl; wire vldh, vldl;
    lod8 h (.in(in[15:8]), .out(outh), .vld(vldh));
    lod8 l (.in(in[7:0]),  .out(outl), .vld(vldl));
    assign vld = vldh | vldl;
    // Upper half is more significant: if it has a '1', its position wins
    assign out = vldh ? {1'b0, outh} : {vldl, outl};
endmodule

// 32-bit input → 5-bit output  (used by N=32)
module lod32 (input [31:0] in, output [4:0] out, output vld);
    wire [3:0] outh, outl; wire vldh, vldl;
    lod16 h (.in(in[31:16]), .out(outh), .vld(vldh));
    lod16 l (.in(in[15:0]),  .out(outl), .vld(vldl));
    assign vld = vldh | vldl;
    assign out = vldh ? {1'b0, outh} : {vldl, outl};
endmodule


// data_extract_v2_param — posit component extraction + shift_rg

module data_extract_v2_param #(
    parameter N  = 16,
    parameter Bs = 4,    // must equal $clog2(N); pass explicitly for V2001
    parameter es = 1
)(
    input  [N-1:0]    in,
    output            rc,
    output [Bs-1:0]   regime,
    output [es-1:0]   exp,
    output [N-es-1:0] mant,
    output [Bs:0]     shift_rg  // one extra bit prevents k+1 overflow
);
    wire [N-1:0] xin   = in;
    assign rc = xin[N-2];

    wire [N-1:0] xin_r = rc ? ~xin : xin;

    // LOD: find position of first '1' in {xin_r[N-2:0], 1'b0}
    wire [N-1:0] lod_in = {xin_r[N-2:0], rc}; // PaCoGen uses rc not 1'b0
    wire [Bs-1:0] k;
    wire lod_vld;

    generate
        if (N == 8) begin : g_lod8
            lod8  lodX (.in(lod_in[7:0]),  .out(k), .vld(lod_vld));
        end else if (N == 16) begin : g_lod16
            lod16 lodX (.in(lod_in[15:0]), .out(k), .vld(lod_vld));
        end else begin : g_lod32
            lod32 lodX (.in(lod_in[31:0]), .out(k), .vld(lod_vld));
        end
    endgenerate

    assign regime   = rc ? (k - 1'b1) : k;
    assign shift_rg = k + 1'b1;

    wire [N-1:0] shifted;
    generate
        integer ii;
        assign shifted = ({xin[N-3:0], 2'b0}) << k;
    endgenerate

    assign exp  = shifted[N-1 : N-es];
    assign mant = shifted[N-es-1 : 0];
endmodule


// posit_mult_paper_param — TOP-LEVEL
module posit_mult_paper_param #(
    parameter N  = 16,
    parameter es = 1
)(
    input  [N-1:0] in1, in2,
    input          start,
    output [N-1:0] out,
    output         inf, zero,
    output         done
);


// Bs = log2(N): 8→3, 16→4, 32→5
localparam Bs     = (N==8)  ? 3 :
                    (N==16) ? 4 : 5;

// MANT_W = N - es + 1  (mantissa including implicit bit)
localparam MANT_W = N - es + 1;

// Granularity (bits per PPG slice): 4 for N=8,16;  8 for N=32
localparam GRAN   = (N == 32) ? 8 : 4;

wire start0 = start;

// Sign and special-value detection  (unchanged from PaCoGen)
wire s1 = in1[N-1];
wire s2 = in2[N-1];
wire zero_tmp1 = |in1[N-2:0];
wire zero_tmp2 = |in2[N-2:0];
wire inf1  = in1[N-1] & (~zero_tmp1);
wire inf2  = in2[N-1] & (~zero_tmp2);
wire zero1 = ~(in1[N-1] | zero_tmp1);
wire zero2 = ~(in2[N-1] | zero_tmp2);
assign inf  = inf1 | inf2;
assign zero = zero1 & zero2;

// Data extraction (two-complement if negative)
wire [N-1:0] xin1 = s1 ? -in1 : in1;
wire [N-1:0] xin2 = s2 ? -in2 : in2;

wire            rc1,   rc2;
wire [Bs-1:0]   regime1, regime2;
wire [es-1:0]   e1,    e2;
wire [N-es-1:0] mant1, mant2;
wire [Bs:0]     shift_rg1, shift_rg2; // Bs+1 bits: k+1 never overflows

data_extract_v2_param #(.N(N),.Bs(Bs),.es(es)) uut_de1 (
    .in(xin1), .rc(rc1), .regime(regime1),
    .exp(e1), .mant(mant1), .shift_rg(shift_rg1)
);
data_extract_v2_param #(.N(N),.Bs(Bs),.es(es)) uut_de2 (
    .in(xin2), .rc(rc2), .regime(regime2),
    .exp(e2), .mant(mant2), .shift_rg(shift_rg2)
);

// Prepend implicit bit → m1/m2 are MANT_W = N-es+1 bits = [N-es:0]
wire [N-es:0] m1 = {zero_tmp1, mant1};
wire [N-es:0] m2 = {zero_tmp2, mant2};

// CTL generation (paper Section III-B,C — adapted per N)

wire [1:0] ctl_A_2b, ctl_B_2b;   // 2-bit ctl for N=16,32
wire       ctl_A_1b, ctl_B_1b;   // 1-bit ctl for N=8

generate
    if (N == 8) begin : g_ctl8
        // 1-bit: ~shift_rg[2]  (Bs=3, index 2 < 3 ✓)
        assign ctl_A_1b = shift_rg1[2];
        assign ctl_B_1b = shift_rg2[2];
        assign ctl_A_2b = 2'b00;   // unused
        assign ctl_B_2b = 2'b00;
    end else if (N == 16) begin : g_ctl16
        // 2-bit: {~shift_rg[3], ~shift_rg[2]}  (Bs=4, indices 3,2 < 4 ✓)
        assign ctl_A_2b = {~shift_rg1[3], ~shift_rg1[2]};
        assign ctl_B_2b = {~shift_rg2[3], ~shift_rg2[2]};
        assign ctl_A_1b = 1'b0;    // unused
        assign ctl_B_1b = 1'b0;
    end else begin : g_ctl32
        // 2-bit: {~shift_rg[4], ~shift_rg[3]}  (Bs=5, indices 4,3 < 5 ✓)
        assign ctl_A_2b = {~shift_rg1[4], ~shift_rg1[3]};
        assign ctl_B_2b = {~shift_rg2[4], ~shift_rg2[3]};
        assign ctl_A_1b = 1'b0;    // unused
        assign ctl_B_1b = 1'b0;
    end
endgenerate

// Sign
wire mult_s = s1 ^ s2;

// Mantissa multiplication — generate-selected mantissa multiplier
// product is [2*(N-es)+1:0]  (same declaration as PaCoGen m1*m2)

wire [2*(N-es)+1:0] mult_m;

generate
    if (N == 8) begin : g_mant8
        // 2-region, 4-bit cells
        mantissa_mult_2r #(.MANT_W(MANT_W)) u_mm (
            .A(m1), .B(m2),
            .ctl_A(ctl_A_1b), .ctl_B(ctl_B_1b),
            .product(mult_m)
        );
    end else if (N == 16) begin : g_mant16
        // 4-region, 4-bit cells
        mantissa_mult_4r4 #(.MANT_W(MANT_W)) u_mm (
            .A(m1), .B(m2),
            .ctl_A(ctl_A_2b), .ctl_B(ctl_B_2b),
            .product(mult_m)
        );
    end else begin : g_mant32
        // 4-region, 8-bit cells
        mantissa_mult_4r8 #(.MANT_W(MANT_W)) u_mm (
            .A(m1), .B(m2),
            .ctl_A(ctl_A_2b), .ctl_B(ctl_B_2b),
            .product(mult_m)
        );
    end
endgenerate

// Unchanged PaCoGen datapath: regime/exponent addition, normalization,packing, and rounding

wire mult_m_ovf = mult_m[2*(N-es)+1];
wire [2*(N-es)+1:0] mult_mN = ~mult_m_ovf ? mult_m << 1'b1 : mult_m;

wire [Bs+1:0] r1 = rc1 ? {2'b0, regime1} : -{{2'b0}, regime1};
wire [Bs+1:0] r2 = rc2 ? {2'b0, regime2} : -{{2'b0}, regime2};
wire [Bs+es+1:0] mult_e;
add_N_Cin_pp #(.N(Bs+es+1)) uut_add_exp ({r1,e1}, {r2,e2}, mult_m_ovf, mult_e);

wire [es-1:0] e_o;
wire [Bs:0]   r_o;
reg_exp_op_pp #(.es(es),.Bs(Bs)) uut_reg_ro (mult_e[es+Bs+1:0], e_o, r_o);

wire [2*N-1+3:0] tmp_o = {
    {N{~mult_e[es+Bs+1]}},
    mult_e[es+Bs+1],
    e_o,
    mult_mN[2*(N-es) : 2*(N-es)-(N-es-1)+1],
    mult_mN[2*(N-es)-(N-es-1) : 2*(N-es)-(N-es-1)-1],
    |mult_mN[2*(N-es)-(N-es-1)-2 : 0]
};

wire [3*N-1+3:0] tmp1_o;
DSR_right_pp #(.N(3*N+3),.S(Bs+1)) dsr2 (
    .a({tmp_o,{N{1'b0}}}),
    .b(r_o[Bs] ? {Bs{1'b1}} : r_o),
    .c(tmp1_o)
);

wire L   = tmp1_o[N+4];
wire G   = tmp1_o[N+3];
wire R   = tmp1_o[N+2];
wire St  = |tmp1_o[N+1:0];
wire ulp = ((G & (R | St)) | (L & G & ~(R | St)));
wire [N-1:0] rnd_ulp = {{N-1{1'b0}}, ulp};

wire [N:0] tmp1_o_rnd_ulp;
add_N_pp #(.N(N)) uut_add_ulp (tmp1_o[2*N-1+3:N+3], rnd_ulp, tmp1_o_rnd_ulp);

wire [N-1:0] tmp1_o_rnd = (r_o < N-es-2)
    ? tmp1_o_rnd_ulp[N-1:0]
    : tmp1_o[2*N-1+3:N+3];

wire [N-1:0] tmp1_oN = mult_s ? -tmp1_o_rnd : tmp1_o_rnd;

assign out  = inf | zero | (~mult_mN[2*(N-es)+1])
              ? {inf, {N-1{1'b0}}}
              : {mult_s, tmp1_oN[N-1:1]};
assign done = start0;

endmodule
// 

module add_N_pp(a, b, c);
    parameter N = 10;
    input  [N-1:0] a, b;
    output [N:0]   c;
    assign c = {1'b0,a} + {1'b0,b};
endmodule
//
module add_N_Cin_pp(a, b, cin, c);
    parameter N = 10;
    input  [N:0]  a, b;
    input         cin;
    output [N:0]  c;
    assign c = a + b + cin;
endmodule
//
module conv_2c_pp(a, c);
    parameter N = 10;
    input  [N:0] a;
    output [N:0] c;
    assign c = a + 1'b1;
endmodule

module reg_exp_op_pp(exp_o, e_o, r_o);
    parameter es = 3;
    parameter Bs = 5;
    input  [es+Bs+1:0] exp_o;
    output [es-1:0]    e_o;
    output [Bs:0]      r_o;
    assign e_o = exp_o[es-1:0];
    wire [es+Bs:0] exp_oN_tmp;
    conv_2c_pp #(.N(es+Bs)) u1 (~exp_o[es+Bs:0], exp_oN_tmp);
    wire [es+Bs:0] exp_oN = exp_o[es+Bs+1] ? exp_oN_tmp[es+Bs:0] : exp_o[es+Bs:0];
    assign r_o = (~exp_o[es+Bs+1] || |(exp_oN[es-1:0]))
                 ? exp_oN[es+Bs:es] + 1
                 : exp_oN[es+Bs:es];
endmodule

module DSR_right_pp(a, b, c);
    parameter N = 16;
    parameter S = 4;
    input  [N-1:0] a;
    input  [S-1:0] b;
    output [N-1:0] c;
    wire [N-1:0] tmp[S-1:0];
    assign tmp[0] = b[0] ? a >> 7'd1 : a;
    genvar i;
    generate for (i=1; i<S; i=i+1) begin : rsh
        assign tmp[i] = b[i] ? tmp[i-1] >> (1<<i) : tmp[i-1];
    end endgenerate
    assign c = tmp[S-1];
endmodule
