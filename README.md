# ARC4 Hardware Decryption & Key Cracking

SystemVerilog implementation of the ARC4 stream cipher with a complete decryption pipeline, a brute-force key search engine, and a two-core parallel cracker. The design uses on-chip memories for the ARC4 state, ciphertext, and plaintext, and coordinates modules with a ready/enable handshake.

---

## Table of Contents
- [Overview](#overview)
- [State Initialization](#state-initialization)
- [Key Scheduling Algorithm (KSA)](#key-scheduling-algorithm-ksa)
- [PRGA and Decryption](#prga-and-decryption)
- [Encryption and Decryption Orchestration](#encryption-and-decryption-orchestration)
- [Key Cracking](#key-cracking)
- [Parallel Cracking](#parallel-cracking)
- [Verification and Validation](#verification-and-validation)
- [Results](#results)
- [Future Work](#future-work)

---

## Overview

ARC4 is a symmetric stream cipher that produces a keystream from a secret key and XORs it with data. 

This project implements ARC4 end to end in hardware:

- **State Initialization:** load S[i] = i for all 256 entries  
- **Key Scheduling (KSA):** permute S using a 24-bit key  
- **PRGA:** generate keystream bytes and XOR with ciphertext to produce plaintext  
- **Key Cracking:** brute-force the 24-bit keyspace and stop at the first valid plaintext  
- **Parallel Cracking:** run two crackers in parallel (even and odd keys)

Implemented on the DE1-SoC FPGA with embedded memories and a ready/enable microprotocol, allowing clean module handshakes and efficient resource use.

---

## State Initialization

**Purpose:** Create a known-good initial state S where each entry equals its index.

**Algorithm:**

    for i = 0 to 255:
        S[i] = i

**Implementation:**  
Used a simple address counter and write enable to populate S sequentially.  
The module asserts **rdy** when idle and accepts a single enable pulse to run.

**Result:**  
Ensures a reproducible starting point before key scheduling begins.  
Verified by inspecting memory contents in simulation and on hardware.

---

## Key Scheduling Algorithm (KSA)

**Purpose:** Permute S using the 24-bit key so the subsequent keystream depends on the key.

**Algorithm:**

    j = 0
    for i = 0 to 255:
        j = (j + S[i] + key[i mod keylen]) mod 256
        swap S[i] and S[j]

**Implementation:**  
- Developed a state machine to perform `READ_i → READ_j → WRITE_i → WRITE_j` in sequence  
- Indexed key bytes using `i % 3` to support 24-bit big-endian input  
- Wrote swapped values back to memory using a single-port RAM interface  
- rdy deasserts during processing and reasserts only when the full 256-step permutation is complete  

**Result:**  
Final S array matches a Python ARC4 reference for more than 30 provided keys, confirming correctness before moving to PRGA.

---

## PRGA and Decryption

**Purpose:** Generate keystream bytes and XOR with ciphertext to recover plaintext.

**Algorithm:**

    i = 0, j = 0
    message_length = CT[0]
    for k = 1 to message_length:
        i = (i + 1) mod 256
        j = (j + S[i]) mod 256
        swap S[i] and S[j]
        pad = S[(S[i] + S[j]) mod 256]
        PT[k] = CT[k] xor pad
    PT[0] = message_length

**Implementation:**  
- Reads message length from `CT[0]` and stores it in `PT[0]`  
- Maintains counters `i` and `j`, swapping S[i] and S[j] each iteration  
- Reads S[(S[i] + S[j]) % 256] to compute the pad byte  
- XORs ciphertext with the pad and writes the result into PT memory  

**Result:**  
Plaintext produced in hardware matched the output of a software reference model across all test ciphertexts, proving the PRGA and decryption logic were correct.

---

## Encryption and Decryption Orchestration

**Purpose:** Coordinate Init, KSA, and PRGA while sharing the single-port S memory.

**Implementation:**  
- Controller state machine cycles: `INITALIZE → INIT → KSA → PRGA`  
- One-shot enables (`en_init`, `en_ksa`, `en_prga`) generated when modules report ready  
- S memory address, data, and wren multiplexed between modules  
- Returns to idle state with **rdy** asserted once decryption is complete  

**Result:**  
Allows a single enable pulse to perform a full decryption cycle.  
Same flow works for encryption since ARC4 is symmetric.

---

## Key Cracking

**Purpose:** Recover an unknown 24-bit key by brute force.

**Implementation:**  
- Incremented a 24-bit key counter, decrypting with each candidate  
- Monitored plaintext writes; if any byte was outside printable ASCII range, skipped remaining decryption for that key  
- If all bytes passed, asserted **key_valid** and kept plaintext in PT memory  

**Result:**  
Recovered correct keys on hardware and in simulation without prior knowledge of the key, validating the design’s end-to-end correctness.

---

## Parallel Cracking

**Purpose:** Speed up brute-force search by running two cracking cores simultaneously.

**Implementation:**  
- Core 1 searched even keys, core 2 searched odd keys  
- Both fed from the same ciphertext memory  
- Captured plaintext from whichever core reported success first  

**Result:**  
Reduced key search time by nearly 50% compared to single-core cracking, demonstrating the benefit of parallelism in hardware.

---

## Verification and Validation

Verification combined simulation and hardware-level testing:

- **Simulation:**  
  Ran RTL and post-synthesis simulations in ModelSim, viewing waveforms to confirm state sequencing and handshake behavior.  
  Compared S after KSA and PT after PRGA against a C reference model.  

- **Coverage:**  
  Achieved 100% branch and statement coverage through directed testbenches and corner-case scenarios.  

- **Hardware Bring-Up:**  
  Programmed the DE1-SoC FPGA and used Quartus In-System Memory Content Editor to view S, CT, and PT contents live, confirming correct decryption and key recovery.  

---

## Results

- Correct decryption for all provided ciphertext/key pairs  
- Successfully brute-forced unknown keys and validated plaintext  
- Parallel cracking halved decryption time versus single-core search  
- Memory behavior and timing confirmed in simulation and on FPGA  
- Full testbench coverage achieved, increasing design confidence  

