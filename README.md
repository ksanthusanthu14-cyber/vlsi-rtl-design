# VLSI RTL Design & Verification Portfolio

A structured **115-project RTL design, SystemVerilog, verification,
timing, and processor architecture portfolio** developed from digital
design fundamentals through advanced RTL and verification concepts.

The repository demonstrates progressive hands-on work in:

-   Digital Logic Design
-   Verilog RTL Design
-   SystemVerilog
-   RTL Verification
-   Assertions
-   Functional Coverage
-   Randomized Verification
-   UVM-style Verification
-   AMBA/APB
-   UART / SPI / I2C
-   Clock Domain Crossing
-   DFT / BIST
-   Static Timing Analysis concepts
-   CPU Architecture
-   RISC Processors
-   Pipelined Processor Design

------------------------------------------------------------------------

## 🎯 Portfolio Objective

The objective of this repository is to build practical RTL design and
verification skills through progressively complex hardware projects.

The projects move from:

**Digital Logic → RTL → Sequential Design → FSMs → Advanced RTL →
Interfaces → CDC → CPU Architecture → SystemVerilog → Verification →
Coverage → Timing → SoC → RISC Processors**

Each project is developed with a focus on:

-   Synthesizable RTL
-   Modular hardware architecture
-   Self-checking testbenches
-   Simulation-based verification
-   Corner-case testing
-   Timing analysis concepts
-   Hardware design methodology

------------------------------------------------------------------------

# 📚 Project Roadmap

## 01--32 --- Digital Design & RTL Fundamentals

### Digital Basics

-   Logic gates
-   Boolean logic
-   Basic combinational circuits
-   Digital building blocks

### Combinational RTL

-   Multiplexers
-   Demultiplexers
-   Encoders
-   Decoders
-   Comparators
-   Adders
-   Subtractors
-   ALU

### Sequential RTL

-   D Flip-Flop
-   JK Flip-Flop
-   T Flip-Flop
-   SR Flip-Flop
-   Registers
-   Shift Registers
-   Counters

### FSM Design

-   Moore FSM
-   Mealy FSM
-   Traffic Light Controller
-   Vending Machine
-   Elevator Controller

------------------------------------------------------------------------

# ⚙️ 33--81 --- Advanced RTL Design

Advanced RTL projects cover reusable hardware blocks, memories,
communication interfaces, CDC, DFT and processor architecture.

### Parameterized & Sequential Hardware

-   Parameterized Counter
-   Parameterized Register
-   Universal Shift Register
-   Ring Counter
-   Johnson Counter
-   Frequency Divider
-   Pulse Generator

### Memory & FIFO Design

-   Single-Port RAM
-   Dual-Port RAM
-   ROM
-   Synchronous FIFO
-   Asynchronous FIFO

### Communication Interfaces

-   UART Transmitter
-   UART Receiver
-   Complete UART
-   SPI Master
-   SPI Slave
-   I2C Master
-   I2C Master/Slave
-   APB Master/Slave
-   APB Register Bank
-   APB Peripheral
-   APB UART Peripheral

### Peripheral RTL

-   PWM Generator
-   Watchdog Timer
-   Timer Peripheral
-   Debounce Circuit
-   Edge Detector

### Clock Domain Crossing

-   CDC Synchronizer
-   Pulse Synchronizer
-   Asynchronous Handshake CDC
-   Glitch-Free Clock Multiplexer

### Control Systems

-   Digital Clock
-   Stopwatch
-   Digital Timer
-   Advanced Traffic Controller
-   Advanced Elevator Controller
-   Advanced Vending Machine

### CPU & Processor Architecture

-   8-bit CPU
-   8-bit Single-Cycle CPU
-   Simple RISC CPU
-   5-Stage Pipelined RISC CPU

### DFT / BIST

-   Scan Flip-Flop
-   Scan Chain
-   LFSR
-   PRBS Generator
-   MISR
-   BIST

------------------------------------------------------------------------

# 🧪 82--105 --- SystemVerilog & Verification

The verification phase progresses from basic SystemVerilog RTL through
self-checking, randomized and UVM-style environments.

## SystemVerilog RTL

-   SystemVerilog ALU
-   SystemVerilog FIFO
-   SystemVerilog UART
-   Parameterized SystemVerilog FIFO

## Self-Checking Verification

-   Self-checking ALU Testbench
-   Randomized ALU Verification
-   FIFO Verification Environment
-   UART Verification Environment
-   SPI Verification Environment

## Assertions

-   FIFO Assertion Verification
-   UART Assertion Verification
-   Protocol Assertion Verification

> The assertion projects use clocked assertion-monitor techniques
> compatible with the simulator environment used for this portfolio.

## Functional Coverage

-   ALU Functional Coverage
-   FIFO Functional Coverage
-   UART Functional Coverage
-   APB Functional Coverage

> Functional coverage is implemented using simulator-compatible coverage
> models rather than relying on unsupported native SystemVerilog
> covergroup features.

## Randomized Verification

-   Randomized FIFO Verification
-   Randomized UART Verification
-   Randomized APB Verification

## UVM-Style Verification

-   UVM-style ALU Verification
-   UVM-style FIFO Verification
-   UVM-style UART Verification
-   UVM-style APB Verification
-   UVM-style SPI Verification

> These projects implement UVM-style verification architecture and
> methodology using the available open-source simulation environment.
> They are not presented as native IEEE UVM implementations.

------------------------------------------------------------------------

# ⏱️ 106--110 --- Timing & STA Concepts

Timing-focused projects explore the fundamentals of synchronous timing
analysis and timing closure.

### 106 --- Setup-Time Analysis

-   Setup slack calculation
-   Path-delay sweeps
-   Frequency analysis
-   Fmax estimation

### 107 --- Hold-Time Analysis

-   Hold slack calculation
-   Minimum-delay analysis
-   Hold-margin sweeps

### 108 --- Critical Path Analysis

-   Critical-path identification
-   Slack calculation
-   Fmax estimation
-   Timing-boundary analysis

### 109 --- SDC Timing Constraints

-   Clock constraints
-   Clock uncertainty
-   Input delay
-   Output delay
-   Input transition
-   Output load
-   Timing-window analysis

### 110 --- Timing Closure

-   Timing violation analysis
-   Path optimization
-   Slack improvement
-   Frequency improvement
-   Final timing closure verification

> These projects model timing concepts mathematically and through
> simulation. Icarus Verilog is not a commercial STA engine.

------------------------------------------------------------------------

# 🚀 111--115 --- Hardware Architecture & Processor Capstones

## 111 --- UART SoC Peripheral

A small APB-style UART peripheral subsystem integrating:

-   APB-style register interface
-   UART TX
-   UART RX
-   Status registers
-   Control/data registers
-   Self-checking verification

------------------------------------------------------------------------

## 112 --- APB Peripheral Subsystem

A shared APB-style peripheral subsystem containing:

-   UART
-   Timer
-   GPIO
-   Address decoding
-   Peripheral isolation
-   Invalid-address handling
-   APB response multiplexing

Address map:

``` text
0x000–0x0FF   UART
0x100–0x1FF   TIMER
0x200–0x2FF   GPIO
0x300+        Invalid / Unmapped
```

------------------------------------------------------------------------

## 113 --- FIFO-Based Data Acquisition

A hardware data-acquisition pipeline:

``` text
DATA SOURCE
     │
     ▼
   FIFO
     │
     ▼
DATA CONSUMER
```

Verification includes:

-   FIFO ordering
-   Burst transfers
-   Full condition
-   Overflow
-   Underflow
-   Producer/consumer rate differences
-   Simultaneous read/write

------------------------------------------------------------------------

## 114 --- Mini RISC Processor

A simple 8-bit RISC processor with:

-   16-bit instruction width
-   8 general-purpose registers
-   Instruction memory
-   Data memory
-   ALU
-   Control unit
-   Branch instructions
-   Jump instructions
-   Load/store instructions
-   HALT instruction

The project demonstrates the transition from RTL blocks to
processor-level architecture.

------------------------------------------------------------------------

# 🏆 115 --- 5-Stage Pipelined RISC Processor

The final project implements a 5-stage pipelined RISC processor:

``` text
IF
 ↓
ID
 ↓
EX
 ↓
MEM
 ↓
WB
```

### Pipeline Features

-   Instruction Fetch
-   Instruction Decode
-   Execute
-   Memory Access
-   Write Back
-   Register file
-   ALU
-   Control unit
-   Data memory
-   Pipeline registers
-   Data forwarding
-   Load-use hazard detection
-   Pipeline stall
-   Branch flushing
-   Jump flushing
-   Register-zero protection
-   HALT handling

### Verification

The processor testbench contains eight major verification scenarios:

1.  Basic pipelined ALU
2.  Data forwarding
3.  Pipelined store/load
4.  Load-use hazard and stall
5.  Register-zero protection
6.  Branch flushing
7.  Jump flushing
8.  Pipeline HALT

Final verification result:

``` text
TOTAL CHECKS  = 24
PASSED CHECKS = 24
FAILED CHECKS = 0
OVERALL RESULT = PASS
```

------------------------------------------------------------------------

# 🔬 Verification Approach

The repository progressively develops verification capability through:

``` text
Directed Testing
      ↓
Self-Checking Testbenches
      ↓
Randomized Testing
      ↓
Assertions
      ↓
Functional Coverage
      ↓
Randomized Verification
      ↓
UVM-Style Verification
      ↓
System-Level Verification
```

Verification techniques used include:

-   Directed stimulus
-   Randomized stimulus
-   Self-checking testbenches
-   Scoreboard-style checking
-   Protocol checking
-   Status checking
-   Corner-case testing
-   Assertion-monitor techniques
-   Functional coverage models
-   Hazard testing
-   Pipeline verification
-   Timing sweeps

------------------------------------------------------------------------

# 🛠️ Tools & Technologies

## HDL

-   Verilog
-   SystemVerilog

## Simulation

-   Icarus Verilog
-   VVP
-   GTKWave

## Development

-   Visual Studio Code
-   PowerShell
-   Git
-   GitHub

## Hardware Design Concepts

-   RTL Design
-   FSM Design
-   FIFO Architecture
-   Memory Design
-   UART
-   SPI
-   I2C
-   AMBA/APB
-   CDC
-   DFT
-   BIST
-   CPU Architecture
-   Pipeline Architecture
-   Timing Analysis
-   Timing Closure

------------------------------------------------------------------------

# 📁 Repository Structure

``` text
vlsi-rtl-design/
│
├── 01_Digital_Basics/
│
├── 02_Combinational_RTL/
│
├── 03_Sequential_RTL/
│
├── 04_FSM_Design/
│
├── 05_Advanced_RTL/
│   │
│   ├── Advanced RTL Projects
│   ├── SystemVerilog Projects
│   ├── Verification Projects
│   ├── Assertion Projects
│   ├── Functional Coverage Projects
│   ├── Randomized Verification Projects
│   ├── UVM-style Verification Projects
│   ├── Timing Analysis Projects
│   ├── 111_UART_SoC_Peripheral/
│   ├── 112_APB_Peripheral_Subsystem/
│   ├── 113_FIFO_Data_Acquisition/
│   ├── 114_Mini_RISC_Processor/
│   └── 115_5_Stage_Pipelined_RISC_Processor/
│
├── .gitignore
│
└── README.md
```

------------------------------------------------------------------------

# ▶️ Running a Project

Enter the required project directory.

Example:

``` powershell
cd D:\vlsi\05_Advanced_RTL\115_5_Stage_Pipelined_RISC_Processor
```

Compile the RTL and testbench:

``` powershell
iverilog -g2012 -o pipelined_risc_cpu_test register_file.sv alu.sv control_unit.sv pipelined_risc_cpu.sv pipelined_risc_cpu_tb.sv
```

Run the simulation:

``` powershell
vvp pipelined_risc_cpu_test
```

For waveform-based projects, VCD files can be opened using:

``` powershell
gtkwave waveform.vcd
```

Generated simulation executables and temporary files are excluded
through `.gitignore`.

------------------------------------------------------------------------

# 📊 Portfolio Progression

``` text
Digital Logic
     ↓
Combinational RTL
     ↓
Sequential RTL
     ↓
FSM Design
     ↓
Advanced RTL
     ↓
Memory & FIFO
     ↓
UART / SPI / I2C / APB
     ↓
CDC
     ↓
DFT / BIST
     ↓
CPU Architecture
     ↓
SystemVerilog
     ↓
Verification
     ↓
Assertions
     ↓
Functional Coverage
     ↓
Randomized Verification
     ↓
UVM-Style Verification
     ↓
Timing / STA Concepts
     ↓
SoC Peripherals
     ↓
Mini RISC Processor
     ↓
5-Stage Pipelined RISC Processor
```

------------------------------------------------------------------------

# 🎓 Skills Demonstrated

### RTL Design

-   Synthesizable Verilog/SystemVerilog
-   Modular RTL architecture
-   Parameterized designs
-   Sequential and combinational logic
-   FSMs
-   Memory interfaces
-   FIFOs
-   Peripheral interfaces

### Verification

-   Testbench development
-   Self-checking verification
-   Randomized verification
-   Assertions
-   Functional coverage
-   Protocol verification
-   Corner-case testing
-   UVM-style architecture

### Computer Architecture

-   Register files
-   ALUs
-   Instruction memory
-   Data memory
-   RISC ISA concepts
-   Pipeline stages
-   Data forwarding
-   Hazard detection
-   Stalling
-   Branch/jump flushing

### Timing

-   Setup analysis
-   Hold analysis
-   Critical-path analysis
-   Slack
-   Fmax
-   SDC concepts
-   Timing closure

------------------------------------------------------------------------

# 📌 Verification Philosophy

Each project is treated as a small hardware engineering exercise:

``` text
Specification
     ↓
RTL Architecture
     ↓
RTL Implementation
     ↓
Testbench
     ↓
Simulation
     ↓
Debugging
     ↓
Corner Cases
     ↓
Self-Checking Verification
     ↓
PASS
```

The emphasis is on understanding **why the hardware works**, not only
producing simulation output.

------------------------------------------------------------------------

# 📈 Final Portfolio Scope

This repository contains a progression of **115 structured hardware
design and verification projects**, covering:

-   Digital logic
-   RTL design
-   SystemVerilog
-   Communication protocols
-   AMBA/APB
-   CDC
-   DFT/BIST
-   Verification
-   Assertions
-   Functional coverage
-   Randomized testing
-   UVM-style environments
-   Timing analysis
-   Timing closure
-   SoC peripherals
-   RISC architecture
-   Pipelined processor design

------------------------------------------------------------------------

## Author

**VLSI RTL Design & Verification Portfolio**

Built as a hands-on engineering progression from digital design
fundamentals to processor-level RTL and verification.

------------------------------------------------------------------------

## Repository

GitHub:

https://github.com/ksanthusanthu14-cyber/vlsi-rtl-design