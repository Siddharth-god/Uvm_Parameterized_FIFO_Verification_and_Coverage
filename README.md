# UVM-Based Verification of a Parameterized FIFO

---

## OVERVIEW
This project implements and verifies a **parameterized synchronous FIFO** using **SystemVerilog RTL** and **UVM**.

The goal of this project is to:
- Design a configurable FIFO
- Build a structured UVM testbench
- Validate functionality under multiple traffic scenarios
- Implement a timing-aware scoreboard for accurate verification

The verification environment follows an **industry-style UVM architecture** with clear separation of stimulus generation, driving, monitoring, and checking.

---

## FIFO DESIGN

The FIFO is a **synchronous, parameterized design** supporting configurable data width and depth.

### Key Features
- Parameterized DATA WIDTH
- Parameterized ADDR (pointer size)
- Configurable FIFO DEPTH
- Separate read pointer and write pointer
- Counter-based tracking of FIFO occupancy
- Full flag generation
- Empty flag generation

### Protection against invalid operations
- Write operation is blocked when FIFO is **FULL**
- Read operation is blocked when FIFO is **EMPTY**

---

## VERIFICATION METHODOLOGY

The verification environment is implemented using **SystemVerilog UVM** with a modular and scalable architecture.

### UVM Components Implemented
- Transaction (Sequence Item)
- Sequences
- Sequencers
- Drivers
- Monitors
- Write Agent
- Read Agent
- Virtual Sequencer
- Virtual Sequence
- Scoreboard
- Environment
- Test
- Interface

### Architecture Highlights
- Separate **READ and WRITE agents** for independent stimulus and monitoring
- Virtual sequencer coordinates activity between both agents
- Constrained-random stimulus generation for better coverage
- Passive monitors capture DUT behavior
- Scoreboard validates functional correctness

---

## VERIFICATION ARCHITECTURE

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

---

## TEST SCENARIOS IMPLEMENTED

### 1. Burst Write
- Multiple consecutive write operations used to fill the FIFO

### 2. Burst Read
- Multiple consecutive read operations used to drain the FIFO

### 3. Simultaneous Read and Write
- Read and write operations occur in the same clock cycle

### 4. Constrained Random Traffic
- Randomized stimulus using SystemVerilog constraints to explore different FIFO states

---

## SCOREBOARD

A **queue-based reference model** is implemented in the scoreboard.

### Functional Model
- Write operation → push_back() into reference queue
- Read operation → pop_front() from reference queue
- DUT output is compared with expected reference output

### Comparison
- Match → Info message
- Mismatch → Error reported

---

## TIMING ALIGNMENT (IMPORTANT LEARNING)

A key issue observed during verification was **data misalignment due to clocking block sampling skew**.

### Root Cause
- Default sampling uses input #1step
- This introduces a delta-cycle delay
- Scoreboard assumed zero-cycle latency
- Result → mismatch between expected and actual data

---

### Method 1 (Recommended - Timing-Aware Scoreboard)
- Keep input #1step
- Delay comparison by 1 clock cycle

READ (cycle N) → DATA_OUT compared at (cycle N+1)

Reason:
- Matches real hardware behavior
- Works for pipelined and complex designs
- Scalable and robust

---

### Method 2 (Workable - Compare-Then-Update Alignment)

- Perform comparison first
- Then update the expected reference (pop from queue)

#### Idea
Instead of updating expected data immediately on read,  
we compare using the **previous expected value**, then update it.

This naturally aligns with the fact that **data_out corresponds to a previous read**.

#### Behavior
READ (cycle N) → DATA_OUT corresponds to previous expected value  
After comparison → update expected for next cycle

#### Why it works
- Avoids delta-cycle misalignment
- Keeps scoreboard simple
- No need to modify clocking block skew
- Matches observed DUT behavior without extra delay handling

#### Example

```bash
# exp_data holds previous expected value (initialized to 0)

# Key Observation:
DUT output is effectively 1 cycle behind inputs

#Timeline:
    @100 → Inputs applied
         Output corresponds to @90 inputs

    @110 → Inputs applied
         Output corresponds to @100 inputs

# So:
    Current output = result of previous cycle input
    Therefore:
    Compare with previous expected, then update expected

# First comparison:
    exp_data = 0 (default)
    DUT also outputs 0 initially
    → Match

# Compare first
    if(exp_data != rd_xtn.data_out)
        `uvm_error("SB", $sformatf("EXP=%0d ACT=%0d", exp_data, rd_xtn.data_out));

# Then update expected for next cycle
    if(ref_q.size() > 0)
        exp_data = ref_q.pop_front();
```

---

### Method 3 (Workable - Sampling Alignment)
- Use input #0 in clocking block
- Compare immediately after popping data out from the queue

READ (cycle N) → DATA_OUT compared at (cycle N)

Reason:
- Aligns sampling with scoreboard assumption
- Works well for simple synchronous designs

---

### Key Insight
A scoreboard is not just logic — it is a timing model of the DUT

---

## CLOCKING BLOCK UNDERSTANDING

### Default Behavior
- input skew = #1step
- output skew = #0

### Important Clarification Learned
Sampling always happens after posedge, not before (Theoritical and Practical Differences).

- input #0 → sample immediately after clock edge
- input #1step → sample slightly after clock edge (delta delay)
- input #1 → sample later (time unit delay)

### Key Learning
Even a small delta delay can cause misalignment if scoreboard assumes zero latency.

---

## TOOLS AND LANGUAGES USED
- SystemVerilog
- UVM (Universal Verification Methodology)
- QuestaSim

---

## ADDED ASSERTIONS USING _BIND_ METHOD 

### Assertions checked are : 
- RESET
- FIFO_FULL
- FIFO_EMPTY
- READ_CHECK
- WRITE_CHECK
- NO_FULL_EMPTY
- FULL_DEASSERT
- SIMULTANEOUS READ & WRITE
- IF_READ_COUNT_MINUS 
- IF_WRITE_COUNT_PLUS

## IMPLEMENTED FUNCTIONAL COVERAGE
- Added _Write_ and _Read_ Side Coverage covering all INPUTS and OUTPUTS
- Coverage is written inside the _Score Board_

---

## DEBUGGING THE SCOREBOARD LOGIC – UPDATED CODE
- Fixed multiple issues in the scoreboard logic that were affecting correctness
- Improved queue handling by adding missing boundary conditions (full/empty awareness)
- Updated write monitor sampling to include full and empty signals, ensuring accurate expected data generation
- Added _copy()_ method for transaction handling (currently unused, may be removed later if not required)
- Enhanced coverage model to better reflect functional behavior and corner cases


## FUTURE IMPROVEMENTS
- Improve random stress scenarios
- Modularize UVM components into packages/files
- Enhance repository structure

---

## LEARNING OBJECTIVES
- SystemVerilog RTL design
- UVM testbench architecture
- Virtual sequencer coordination
- Constrained random verification
- Scoreboard-based checking and synchronization
- Debugging timing mismatches
- Understanding clocking block skew
- Understanding Binding Method for Assertions 
- How to achieve above 95% Coverage 
---

## FINAL NOTE

Correct verification depends not only on logic,  
but also on accurate timing alignment between DUT and testbench.