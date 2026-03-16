# =================================================================================================
# UVM-Based Verification of a Parameterized FIFO
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# OVERVIEW
# -------------------------------------------------------------------------------------------------
## This project demonstrates the design and verification of a parameterized synchronous FIFO using SystemVerilog and the Universal Verification Methodology (UVM).

## The goal of this project is to implement a FIFO RTL design and verify its functionality using a structured UVM testbench capable of generating multiple traffic patterns and validating DUT behavior using a reference model based scoreboard.

## The verification environment follows an industry-style UVM architecture with agents,drivers, monitors, sequencers, virtual sequencer, and a scoreboard.

# -------------------------------------------------------------------------------------------------
# FIFO DESIGN
# -------------------------------------------------------------------------------------------------
# The FIFO is a synchronous parameterized design supporting configurable data width and depth.

# Key Features
 - Parameterized DATA WIDTH
 - Parameterized FIFO POINTERS
 - Parameterized FIFO DEPTH
 - Read pointer and write pointer architecture
 - Counter-based tracking of FIFO occupancy
 - Full flag generation
 - Empty flag generation

# Protection against invalid operations:
 - Write operation blocked when FIFO is FULL
 - Read operation blocked when FIFO is EMPTY

# -------------------------------------------------------------------------------------------------
# VERIFICATION METHODOLOGY
# -------------------------------------------------------------------------------------------------
### The verification environment is implemented using SystemVerilog UVM and follows a modular architecture separating stimulus generation, driving, monitoring and checking.

## UVM Components Implemented
 - Transaction (Sequence Item)
 - Sequences
 - Sequencers
 - Drivers
 - Monitors
 - Read Agent
 - Write Agent
 - Virtual Sequencer
 - Virtual Sequence
 - Scoreboard
 - Environment
 - Test
 - Interface

# Separate READ and WRITE agents allow independent stimulus and monitoring for both interfaces of the FIFO.

# Virtual sequencer and virtual sequence coordinate activity between both agents.

# -------------------------------------------------------------------------------------------------
# VERIFICATION ARCHITECTURE
# -------------------------------------------------------------------------------------------------
```bash
 Test
   |
   +-- Environment
        |
        +-- Write Agent
        |     +-- Driver
        |     +-- Sequencer
        |     +-- Monitor
        |
        +-- Read Agent
        |     +-- Driver
        |     +-- Sequencer
        |     +-- Monitor
        |
        +-- Virtual Sequencer
        |
        +-- Scoreboard
```

# -------------------------------------------------------------------------------------------------
# TEST SCENARIOS IMPLEMENTED
# -------------------------------------------------------------------------------------------------

# 1. Burst Write
- Multiple consecutive write operations used to fill the FIFO.

# 2. Burst Read
- Multiple consecutive read operations used to drain the FIFO.

# 3. Simultaneous Read and Write
- Read and write operations occur in the same clock cycle.

# 4. Constrained Random Traffic
- Randomized stimulus generation using SystemVerilog constraints to explore different FIFO operating states.

# -------------------------------------------------------------------------------------------------
# SCOREBOARD
# -------------------------------------------------------------------------------------------------
# A queue-based reference model is implemented in the scoreboard.

# Write operation:
 - push_back() data into reference queue

# Read operation:
 - pop_front() expected data from reference queue

## The DUT output is compared with the expected reference output.

## Any mismatch between expected and actual output is reported as an error.

# -------------------------------------------------------------------------------------------------
# TOOLS USED
# -------------------------------------------------------------------------------------------------
 - SystemVerilog
 - UVM (Universal Verification Methodology)
 - QuestaSim 

# -------------------------------------------------------------------------------------------------
# FUTURE IMPROVEMENTS
# -------------------------------------------------------------------------------------------------
 - Add SystemVerilog Assertions (SVA) for protocol checking
 - Implement Functional Coverage to measure verification completeness
 - Increase random stress testing scenarios
 - Separate UVM components into structured files and packages
 - Improve repository structure for scalability

# -------------------------------------------------------------------------------------------------
# LEARNING OBJECTIVES
# -------------------------------------------------------------------------------------------------
 - SystemVerilog RTL design
 - UVM testbench architecture
 - Virtual sequencer based multi-agent coordination
 - Constrained random verification
 - Scoreboard based functional checking
# =================================================================================================