# 5-Stage Pipelined RISC Processor

## Overview

A SystemVerilog implementation of a 5-stage pipelined RISC processor designed to demonstrate practical CPU microarchitecture, pipeline control and hazard handling.

## Pipeline

```text
IF → ID → EX → MEM → WB
```

## Major Components

* Register file
* ALU
* Control unit
* Pipeline registers
* Forwarding logic
* Load-use hazard detection
* Pipeline stall logic
* Branch flushing
* Jump flushing
* HALT handling

## Verification

The processor was verified using a self-checking SystemVerilog testbench.

### Final Results

| Test                 | Result |
| -------------------- | -----: |
| Basic pipelined ALU  |   PASS |
| Data forwarding      |   PASS |
| Pipelined store/load |   PASS |
| Load-use hazard      |   PASS |
| Register zero        |   PASS |
| Branch flush         |   PASS |
| Jump flush           |   PASS |
| Pipeline HALT        |   PASS |

**Total checks: 24**
**Passed: 24**
**Failed: 0**

## Architecture

```text
             ┌─────────────┐
             │     IF      │
             └──────┬──────┘
                    ↓
             ┌─────────────┐
             │     ID      │
             └──────┬──────┘
                    ↓
             ┌─────────────┐
             │     EX      │
             └──────┬──────┘
                    ↓
             ┌─────────────┐
             │     MEM     │
             └──────┬──────┘
                    ↓
             ┌─────────────┐
             │     WB      │
             └─────────────┘
```

## Tools

* SystemVerilog
* Icarus Verilog
* GTKWave
* VS Code
* PowerShell

## Key Learning Areas

* Pipeline architecture
* Data hazards
* Forwarding
* Load-use stalls
* Control hazards
* Branch/jump flushing
* RTL debugging
* Self-checking verification
