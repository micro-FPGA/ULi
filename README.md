# ULi (Universal Link)

**A single-wire bidirectional clock-synchronous communication protocol for FPGAs.**

ULi enables full-duplex data transfer between two FPGA endpoints over a single electrical wire, using a clock-synchronous frame structure that can be recovered with standard FPGA PLL hardware. The master transmits 2 bits per frame (1 control + 1 data), the slave transmits 1 data bit per frame. Raw data rates of 16 Mbit/s in each direction are achievable at typical FPGA clock speeds, with the rate scaling linearly with the underlying clock frequency.

This repository contains the protocol specification, VHDL reference implementation, testbenches, and supporting documentation.

## At a glance

| Property | Value |
|----------|-------|
| Wires | 1 (single-ended) |
| Direction | Full-duplex bidirectional |
| Frame size | 8 clock periods |
| Master payload per frame | 2 bits (1 control, 1 data) |
| Slave payload per frame | 1 bit (data) |
| Master raw rate | 2 × clock_frequency / 8 |
| Slave raw rate | clock_frequency / 8 |
| Reference rates at 128 MHz PLL | 32 Mbit/s master, 16 Mbit/s slave |
| Superframe size | 128 frames |
| Effective data rate after sync overhead | 127/128 of raw data rate |
| Clock recovery | Standard FPGA PLL with blanking mechanism |
| Auto-alignment | Tolerates slave-side delay up to 1/8 of a bit-frame |
| Cable length (reference) | ~1.5 m at 16 Mbit/s without calibration |
| License | MIT |

## Why ULi exists

Single-wire protocols already exist (1-Wire from Maxim is the most widely deployed), but they tend to be asymmetric master-slave designs with modest throughput and clock-recovery requirements that do not match standard FPGA hardware. Multi-wire protocols (I2C, SPI, RS-485, CAN) provide more capabilities but require additional physical conductors at the cost of PCB area, connector pins, and cable conductors.

ULi was designed to fill a specific gap: a protocol that combines all of the following properties:

- Single physical wire between two endpoints
- Full-duplex bidirectional operation
- Clock-synchronous frame structure with deterministic timing
- Compatibility with standard FPGA PLL hardware for clock recovery
- Throughput that scales with the underlying clock speed
- Implementable with modest FPGA resource consumption
- Explicit framing through a dedicated control bit, eliminating the need to embed sync into the data channel

The protocol was conceived in 2016. Initial hardware testing verified the link-layer concept. The implementation in this repository was developed in 2026 and demonstrates the link layer working bidirectionally in simulation.

## Protocol overview

### Frame structure

Data is transmitted in 8-clock-period frames divided into two halves:

| Clock period | Direction |
|--------------|-----------|
| 0 | Master transmit |
| 1 | Master transmit |
| 2 | Master transmit |
| 3 | Master transmit |
| 4 | Slave transmit |
| 5 | Slave transmit |
| 6 | Slave transmit |
| 7 | Slave transmit |

Master and slave never transmit simultaneously.

### Master encoding

The master transmits 2 bits per frame: a **control bit** and a **data bit**. The encoding is:

| Control | Data | Master pattern |
|---------|------|----------------|
| 1 | 0 | `1000` |
| 0 | 0 | `1100` |
| 0 | 1 | `1110` |

The combination `control=1, data=1` is **not permitted**. The corresponding pattern `1010` would have an extra rising edge inside the master's transmission window, which would interfere with the slave's PLL lock.

All valid master patterns begin with a rising edge at the start of clock period 0, providing the periodic timing reference for the slave's PLL.

### Slave encoding

The slave transmits 1 data bit per frame:

| Data | Slave pattern |
|------|---------------|
| 0 | `0000` |
| 1 | `0100` |

Both patterns begin with the line at 0 (continuing from the master's transmission) and end with the line at 0 (returning to idle before the next frame begins).

### Superframe and synchronisation

A **superframe** consists of 128 ULi frames. The control bit transmitted by the master indicates which frame within the superframe is the first frame:

- **First frame of superframe**: control=1, data=0 (master pattern `1000`)
- **Other 127 frames**: control=0, data is free (master pattern `1100` or `1110`)

This provides explicit superframe synchronisation without requiring sync patterns to be embedded into the data channel. The receiver detects the control bit on each frame and identifies the start of each superframe directly. Frame counting within the superframe runs from 0 to 127 with the wraparound at frame 0 (the sync frame).

The cost of this synchronisation is that data bit 1 cannot be sent on the sync frame. The effective data rate on the master's data channel is 127/128 of the raw rate, or approximately 15.875 Mbit/s at 128 MHz PLL. The slave's data rate is unaffected by superframe synchronisation, since the slave does not have a control bit; the slave's data rate is the full 16 Mbit/s.

Higher protocol layers can use the superframe boundary for purposes such as:

- Packet alignment in framed protocols
- Error detection sequences (CRC over each superframe)
- Multiplexing of independent logical channels
- Synchronised events between master and slave
- Time-division allocation of communication slots

### Clock recovery and blanking

The slave uses a standard FPGA PLL to lock onto the master's rising edge. To prevent the slave's own transmissions from disturbing the lock, the slave's receive logic blanks the slave's transmission half of each frame from the PLL input. The PLL sees only the master's transmissions, which present a clean periodic signal with the rising edge at a known position.

This blanking mechanism allows ULi to use standard FPGA PLL hardware without requiring custom clock-data-recovery logic.

### Auto-alignment

The master receives the slave's transmissions through a single D flip-flop in an unusual configuration:

- The D input is tied to logic 1.
- The clock input is the slave's data signal.
- The asynchronous reset is driven by the master's frame phase logic, deasserted at the start of the slave's transmission window and asserted again at the end.

When the slave transmits a `0100` pattern, the rising edge at the start of clock period 5 clocks the constant 1 into the flip-flop's Q output, where it persists until the next reset. When the slave transmits a `0000` pattern, no rising edge occurs and Q remains 0.

This mechanism captures the slave's edge regardless of small variations in arrival time, providing tolerance of up to approximately 1/8 of a bit-frame for the slave's signal delay. At 16 Mbit/s with a 128 MHz PLL, this corresponds to roughly 1.5 metres of cable propagation, allowing the protocol to operate over moderate cable lengths without explicit delay calibration.
