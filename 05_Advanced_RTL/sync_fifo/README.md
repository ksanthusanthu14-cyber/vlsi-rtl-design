Synchronous FIFO

Overview

This project implements a parameterized synchronous FIFO (First-In First-Out) buffer using Verilog RTL.

The FIFO uses a single clock domain for both read and write operations. It uses FIFO memory, read/write pointers, and an occupancy counter to manage stored data. full and empty flags indicate whether the FIFO can accept a write or perform a read.

Architecture

                 +----------------------+
                 |    Synchronous FIFO  |
                 |                      |
din -----------> |   FIFO Memory        |
                 |       |              |
wr_en ---------->|       v              |
                 |   Write Pointer      |
                 |                      |
rd_en ---------->|   Read Pointer       |
                 |       |              |
                 |       v              |
                 |      dout            |
                 |                      |
                 |  Occupancy Counter   |
                 |       |              |
                 |   +---+---+          |
                 |   |       |          |
                 |  FULL   EMPTY        |
                 +----------------------+

RTL Features

Parameterized data width

Parameterized FIFO depth

Single synchronous clock

Synchronous active-high reset

Independent read and write enables

FIFO memory array

Read and write pointers

Occupancy counter

full status flag

empty status flag

Protection against writes when FIFO is full

Protection against reads when FIFO is empty

Parameters

Parameter

Default

Description

DATA_WIDTH

8

Width of each FIFO data word

DEPTH

16

Number of entries in the FIFO

Interface

Signal

Direction

Description

clk

Input

FIFO clock

rst

Input

Synchronous active-high reset

wr_en

Input

Write enable

rd_en

Input

Read enable

din

Input

Input data

dout

Output

Output data

full

Output

Indicates FIFO is full

empty

Output

Indicates FIFO is empty

Operation

Write Operation

A write is performed on the rising edge of clk when:

wr_en = 1
full  = 0

The input data is stored at the current write-pointer location and the write pointer advances.

Read Operation

A read is performed on the rising edge of clk when:

rd_en = 1
empty = 0

The data at the current read-pointer location is transferred to dout and the read pointer advances.

Occupancy Tracking

The internal count register tracks the number of elements currently stored in the FIFO.

count = 0       -> EMPTY
count = DEPTH   -> FULL

A valid write without a valid read increments the count.

A valid read without a valid write decrements the count.

When a valid read and write occur during the same clock cycle, the count remains unchanged.

Verification

The testbench demonstrates:

Reset behavior

Writing multiple data values

Reading stored data

Writing additional data after reads

Reading the additional data

Monitoring full and empty status

Generating a VCD waveform for inspection

Test Data

The testbench writes and reads the following sequences:

First sequence:
A1 -> B2 -> C3

Second sequence:
11 -> 22 -> 33

Simulation

Compile with Icarus Verilog:

iverilog -o sim sync_fifo.v sync_fifo_tb.v

Run the simulation:

vvp sim

Generate/view the waveform with GTKWave:

gtkwave sync_fifo.vcd

Expected Behavior

Immediately after reset:

EMPTY = 1
FULL  = 0

After writing data:

EMPTY = 0
FULL  = 0

After all stored data is read:

EMPTY = 1
FULL  = 0

The FIFO can then be reused for subsequent write and read operations.

Skills Demonstrated

Verilog RTL Design

Sequential Logic Design

FIFO Architecture

Memory Modeling

Read/Write Pointer Design

Occupancy Counter Design

Status Flag Generation

Parameterized RTL

RTL Simulation

Icarus Verilog

GTKWave

Git/GitHub

Files

sync_fifo/
├── README.md
├── sync_fifo.v
└── sync_fifo_tb.v

Generated simulation files such as .vcd waveforms and compiled simulation executables are intentionally excluded from the source repository.

Learning Outcome

This project demonstrates the implementation of a synchronous FIFO at RTL level and provides practical experience with memory addressing, read/write pointer management, occupancy tracking, control logic, and FIFO status generation.

The FIFO can serve as a reusable RTL building block for larger systems such as processors, communication interfaces, DMA engines, and SoC subsystems.