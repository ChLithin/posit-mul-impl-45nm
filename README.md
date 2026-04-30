# posit-mul-impl-45nm

**Course Implementation — Power-Efficient Posit Multiplier**  
VLSI Architecture Course | Department of ECE | 2025–26

> Implementation of the power-efficient posit multiplier architecture proposed in **Zhang & Ko, IEEE TCAS-II 2020**, re-synthesized on **45nm GPDK** as part of our VLSI Architecture course project. No new architecture is proposed — this is a faithful RTL implementation of the paper's design.

---

## Paper Implemented

**H. Zhang and S.-B. Ko**, "Design of Power Efficient Posit Multiplier,"  
*IEEE Transactions on Circuits and Systems—II: Express Briefs*,  
vol. 67, no. 5, pp. 861–865, May 2020.  
DOI: [10.1109/TCSII.2020.2980531](https://doi.org/10.1109/TCSII.2020.2980531)

The original paper synthesized on **STM 90nm** using Synopsys Design Compiler + PrimeTime PX. We re-implemented and synthesized on **45nm GPDK** using Cadence Genus.

---

## What We Did

- Read and understood the posit number format and standard posit multiplier datapath
- Used **PACoGen** (Parameterized Posit Arithmetic Hardware Generator) as the baseline
- Replaced the monolithic mantissa multiply (`m1*m2`) with the paper's **region-gated mantissa multiplier**
- Implemented and verified the design for **Posit(8,1)**, **Posit(16,es)**, and **Posit(32,es)**
- Synthesized both baseline (PACoGen) and proposed designs using **Cadence Genus on 45nm GPDK**
- Compared power, area, and timing across all `(N, es)` configurations

The core RTL change:

```verilog
// PACoGen baseline — monolithic multiply
wire [2*(N-es)+1:0] mult_m = m1 * m2;

// Our implementation of the paper — region-gated multiplier
mantissa_mult_4r4 #(.MANT_W(MANT_W)) u_mm (
    .A(m1), .B(m2),
    .ctl_A(ctl_A_2b), .ctl_B(ctl_B_2b),
    .product(mult_m)
);
```

---

## Background: The Paper's Key Idea

In a posit number, the mantissa width is variable — it depends on how many bits the regime consumes. A standard posit multiplier sizes its mantissa multiplier for the worst-case `(nb − es)` bits. When the actual mantissa is small (large regime), the unused upper bits are zero but their partial products still toggle inside a Booth multiplier, wasting dynamic power.

The paper's fix: split the mantissa multiplier into **regions** and gate off the regions not needed for the current operand, controlled by `shift_rg` (the regime bit-width extracted during posit decoding):

```
mant_bit = nb − es − shift_rg
ctl[1] = ~shift_rg[3],  ctl[0] = ~shift_rg[2]
```

Only the active regions compute partial products — the rest are disabled, eliminating unnecessary switching activity.

---

## Repository Structure

```
posit-mul-impl-45nm/
│
├── rtl/
│   ├── pacogen.v               # Unmodified PACoGen posit multiplier
│   └── posit_mult_paper_param.v                
│
├── tb/                            # Testbench
│   └── tb_posit_mult_paper.v
│
├── synthesis_reports/                     # Cadence Genus reports — 45nm GPDK
│   ├── 8_1/
│   │   ├── Pacogen/
│   │   │   ├── syn_opt_area.txt
│   │   │   ├── syn_opt_power.txt
│   │   │   └── syn_opt_timing.txt
│   │   └── Proposed/
│   │       ├── syn_opt_area.txt
│   │       ├── syn_opt_power.txt
│   │       └── syn_opt_timing.txt
│   ├── 16_1/ ... 16_5/            # Same structure for each (N, es)
│   └── 32_1/ ... 32_8/
│
│── presentation.pdf
└── README.md
```

---

## Synthesis Results (45nm GPDK)

Synthesized using Cadence Genus. Power compared against PACoGen baseline at the same configuration.

| Configuration | Delay — Base (ns) | Delay — Prop (ns) | Area — Base (µm²) | Area — Prop (µm²) | Power — Base (mW) | Power — Prop (mW) | Reduction |
|---------------|-------------------|-------------------|-------------------|-------------------|-------------------|-------------------|-----------|
| Posit(8,1)    | 7.863             | 8.007             | 728.46            | 759.58            | 0.0635            | 0.0552            | **13%**   |
| Posit(16,1)   | 15.108            | 14.831            | 2236              | 2668              | 0.344             | 0.206             | **40%**   |
| Posit(16,2)   | 14.606            | 14.812            | 2084              | 2410              | 0.252             | 0.185             | **26.5%** |
| Posit(32,1)   | 25.978            | 25.573            | 6799              | 8957              | 1.33              | 0.703             | **47.1%** |
| Posit(32,2)   | 25.829            | 25.498            | 6592              | 8560              | 1.24              | 0.680             | **45.1%** |

Full reports (area, power, timing) for all `(N, es)` configurations are in `synthesis_reports/`.

> Note: The original paper (90nm, Synopsys DC) reports an average 16% power reduction. Our results on 45nm GPDK show higher reduction on larger formats — differences are expected due to the different PDK, tool, and synthesis flow.


## Reference

> H. Zhang and S.-B. Ko, "Design of Power Efficient Posit Multiplier,"
> *IEEE Transactions on Circuits and Systems—II: Express Briefs*,
> vol. 67, no. 5, pp. 861–865, May 2020.
> DOI: 10.1109/TCSII.2020.2980531

PACoGen baseline:
> R. Chaurasiya et al., "Parameterized Posit Arithmetic Hardware Generator,"
> *Proc. IEEE 36th Int. Conf. Comput. Design (ICCD)*, Oct. 2018, pp. 334–341.

---

