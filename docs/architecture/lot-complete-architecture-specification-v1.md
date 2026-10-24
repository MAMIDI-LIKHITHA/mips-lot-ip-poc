# LOT Complete Architecture Specification v1.0

**Status:** Proposal for approval; preliminary documentation-level design  
**For:** Mihai Buta and Swapnil (MobilFlex)  
**Author:** Likhitha Mamidi  
**Source document:** `LOT-Complete-Architecture-Specification-v1.pdf`, dated 23 October 2026  
**Validation boundary:** Nothing in this specification has been tested on hardware. This Markdown transcription is a working repository reference; use the supplied PDF as the source of record if wording differs.

> **Evidence labels:** **Confirmed** = stated in a source read by the author; **Inference** = engineering reasoning; **Proposal** = design choice awaiting approval; **Check** = still to verify. These labels do not mean independent vendor approval or hardware validation.

## 1. Architecture in one page

The proposal is an FPGA-based MIPS host connected to a Silicon Labs SiWx917 radio board in NCP mode over SPI. The FPGA-side peripherals are intended to be reused or generated where possible. The principal proposed custom hardware block is `lot_rlink`, with a corresponding host-driver/HAL port and tests.

### Eight design decisions proposed for approval

1. **APB4 peripheral contract:** SPI, GPIO, UART and timer peripherals attach to APB4. A small host-bus adapter changes with the MIPS core so the peripherals, driver and tests can be reused. **[Proposal]**
2. **Reuse before build:** Evaluate PULP modules for an AXI path, APB bridge and error responder; reuse the Silicon Labs WiSeConnect SDK radio stack. New work is proposed as `lot_rlink`, HAL port and tests. **[Proposal]**
3. **Radio interface:** SiWx917 NCP over SPI mode 0, with interrupt and reset signals. Keep the NCP protocol in software and the hardware generic. **[Proposal; interface details marked Confirmed in source PDF]**
4. **Host core remains undecided:** options are MIPSfpga microAptiv UP (AHB-Lite; academic/non-commercial FPGA license), an Atlas MCU core if MIPS can provide an FPGA form, or a stand-in core for software bring-up only. **[Check]**
5. **No crossbar for one initiator:** add a crossbar only if a second initiator, such as DMA, is added. **[Inference]**
6. **Four verification levels:** unit, subsystem, firmware-in-the-loop, and board tests; reuse a radio model at each applicable level. **[Proposal]**
7. **Measure CPU cost per frame:** compare with Swapnil's x86 baseline. **[Proposal]**
8. **Optional offload:** consider DMA plus interrupt coalescing only after measuring a software-only baseline; its benefit is a hypothesis, not a promise. **[Inference]**

## 2. Scope, assumptions and requirements

**In scope:** FPGA board; MIPS host; SiWx917 NCP over SPI; Wi-Fi connection and throughput measurement; design provisions for Thread and Ethernet later.

**Out of scope unless approved:** Matter commissioning/certification, ASIC implementation, Arm CSS and Corstone.

**Known assumptions:** FPGA target is intended; board vendor, exact MIPS core and deadline are not yet known.

| ID | Requirement | Priority |
|---|---|---|
| R1 | MIPS host on FPGA runs software that reads/writes peripheral registers | Must |
| R2 | SPI master, mode 0, chip select per transfer; initialize at 25 MHz or less; optional higher speed afterwards | Must |
| R3 | GPIO for radio reset (open-drain), interrupt input connected to core interrupt, optional error-interrupt input, wake request output and sleep indication input | Must |
| R4 | Unmapped address returns an error and does not hang | Must |
| R5 | Port 12 WiSeConnect host functions and a CMSIS-RTOS2 layer | Must |
| R6 | Radio bring-up reaches BOARD READY and CARD READY, then joins Wi-Fi network | Must |
| R7 | Measure throughput and CPU cost per frame | Must |
| R8 | Simulation with radio model before board testing | Must |
| R9 | Licenses permit the POC | Must |
| R10 | Add Thread over UART or SPI and Ethernet without changing peripheral contract | Should |
| R11 | Offload engine to reduce CPU cost per frame | Could |
| R12 | Matter commissioning over BLE | Could; decision required |

## 3. System architecture

### 3.1 Host core options

| Option | Bus / knowns | Fit and caveats | Status in source specification |
|---|---|---|---|
| MIPSfpga microAptiv UP | AHB-Lite; bridge to AXI optional | FPGA-oriented MIPS core; license described as academic/non-commercial and FPGA-only. Written MIPS permission is required before MobilFlex company-POC use. | Core availability described as Confirmed in cited material; permission is Check |
| MIPS Atlas M8500 or RMX-100 MCU class | FPGA interface not published in the report | Potential connectivity-host fit only if MIPS supplies an FPGA form. | Lineup Confirmed; FPGA form Check |
| MIPS Atlas I8500 / P8700 | AXI4 or ACE noted for P8700 | Report considers these likely too large for the development FPGA; this is an inference. | Bus Confirmed in cited material; size Inference |
| MIPS developer platforms (Actus-1 / Aegis-1) | Board-level platforms | SPI pin exposure and price are unknown. | Names Confirmed; details Check |
| OpenMIPS | Wishbone; LGPL-3.0; README reportedly requires Xilinx ISE 14.7 | Stand-in for software bring-up only, not a current MIPS commercial product. | Repository Confirmed |

**Proposal:** ask MIPS whether an Atlas MCU core is available for FPGA use. Until clarified, use MIPSfpga microAptiv UP for software work only if MIPS gives written permission; any stand-in core is for bring-up, not proof that the final target is supported.

**Repository alignment note:** the repo contains OpenMIPS native-cache/bridge simulation work. That work is engineering evidence for a candidate bring-up path, not project-owner approval of the production host core. Keep the actual target and license gate open.

### 3.2 Host-bus adapters

- **Variant A:** AHB-Lite decoder plus AHB-to-APB bridge; the source report says MIPSfpga+ shows an AHB-Lite memory/peripheral system. The report did not find an AHB-to-APB bridge in the PULP set, so this bridge needs a vendor or small custom implementation. **[Check]**
- **Variant B:** AXI4 path using PULP `axi_xbar`, `axi_to_axi_lite`, `axi_lite_to_apb` and `axi_err_slv`; the report records these modules in the PULP AXI repository under Solderpad Hardware License 0.51. **[Confirmed per source report; re-check exact revision and license before use]**

A crossbar is unnecessary for one initiator unless the actual topology adds another initiator (for example, DMA). Do not implement Variant A or B as the final adapter until the target bus is confirmed.

## 4. Hardware architecture

### 4.1 Proposed `lot_rlink`

`lot_rlink` is proposed as a thin APB4 wrapper around an SPI master and radio-related GPIO. SPI implementation candidates are PULP `apb_spi_master` or FPGA-vendor SPI IP. The source PDF explicitly says mode-0 support with software-controlled chip select was **not confirmed** for PULP's core and must be checked against AN1432 before adoption.

| Offset | Register | Access | Proposed purpose |
|---|---|---|---|
| 0x00 | ID | RO | Block ID and version |
| 0x04 | CTRL | RW | Enable, soft reset, manual chip select, high-speed select, interrupt polarity; mode fixed to 0 |
| 0x08 | STATUS | RO | Busy, FIFO flags, raw SPI_INTR/SPI_ERR_INTR, sleep indication, reset asserted |
| 0x0C | CLKDIV | RW | SPI divider for initialization at 25 MHz or less |
| 0x10 | CLKDIV_HS | RW | Optional higher-speed divider after initialization |
| 0x14 | TXDATA | WO | Byte/word to shift out (FIFO) |
| 0x18 | RXDATA | RO | Received byte/word (FIFO) |
| 0x1C | XFER_LEN | RW | Transfer length in bytes; writing while chip select is asserted starts transfer |
| 0x20 | GPIO_OUT | RW | Bit 0 RESET_N (0 drives low, 1 releases open-drain pin); bit 1 wake request |
| 0x24 | IRQ_EN | RW | Interrupt enable bits |
| 0x28 | IRQ_STATUS | W1C | Frame pending, error interrupt, transfer done, receive overrun, timeout |
| 0x2C | TIMEOUT | RW | Bus timeout in clock cycles |

These offsets and semantics are proposals, not a frozen software/hardware contract.

### 4.2 Illustrative peripheral map

| Region | Start | Size | Target / note |
|---|---:|---:|---|
| Program/data memory | Core-defined | About 1.5 MB and 256 kB planning estimate | AHB or AXI4 memory; report notes driver-only build may need much less |
| `lot_rlink` | 0x4000_0000 | 4 kB | APB: SPI and GPIO |
| UART | 0x4000_1000 | 4 kB | APB console and optional Thread radio |
| Timer and interrupt | 0x4000_2000 | 4 kB | APB timeouts and interrupt masking |
| Optional offload engine | 0x4000_3000 | 4 kB | APB control plus bus initiator for DMA queue |
| Everything else | — | — | Error responder returns an error |

Interrupt mapping is proposed: IRQ0 for `lot_rlink`; IRQ1 for UART; core timer for scheduling. Actual interrupt controller and map depend on selected core.

### 4.3 Clocks and reset

- Proposed one bus clock for host/fabric/peripherals; generate SPI clock using a divided enable inside `lot_rlink`.
- Synchronize asynchronous SPI_INTR, SPI_ERR_INTR and sleep indication using two flip-flops, subject to CDC review.
- Drive SPI_CSN and SPI_CLK before releasing RESET_N.
- RESET_N is open-drain: drive low, release high.
- Initialize SPI at 25 MHz or less; optionally switch faster after initialization if supported.
- The source PDF proposes starting at 12.5 MHz because the cited reference EFR32 host runs at that speed; confirm against the selected board/SDK.

### 4.4 Board integration checks

The source PDF lists adapter-board signal positions for BRD8045C and BRD8045A EXP:

| Signal | Direction from FPGA | BRD8045C | BRD8045A EXP |
|---|---|---|---|
| SPI_CLK | Output | P101.6 | J100.8 |
| SPI_MOSI | Output | P101.4 | J100.4 |
| SPI_MISO | Input | P101.5 | J100.6 |
| SPI_CSN | Output | P101.3 | J100.10 |
| SPI_INTR | Input | P101.1 | J100.13 |
| RESET_N | Output, open-drain | P101.2 | J100.11 |
| Sleep indication | Input | P103.5 | J100.7 |
| Wake request | Output | P103.3 | J100.9 |

These are adapter-board positions from the source report, not FPGA pin assignments. FPGA pins depend on the actual FPGA board. Before wiring, confirm voltage compatibility/level shifting, board manuals, loader/JTAG or serial path, short SPI wiring (report says under 2 inches for prototyping), SPI output-delay constraints and analyzer access.

## 5. Software architecture

### 5.1 Host functions

The source report cites the WiSeConnect 4.1.2 porting guide and lists these functions to implement in the HAL, plus a CMSIS-RTOS2 layer. Exact signatures and SDK release must be checked against the selected SDK.

| Function(s) | Proposed responsibility |
|---|---|
| `sl_si91x_host_init`, `host_deinit` | Initialize `lot_rlink`, GPIO and interrupt; deinit may be empty if valid for selected SDK |
| `sl_si91x_host_spi_transfer(tx, rx, length)` | Assert CS, move bytes through FIFO or DMA, wait for completion, release CS; handle NULL tx/rx where SDK permits |
| `sl_si91x_host_enable_high_speed_bus` | Switch to CLKDIV_HS; may remain empty if higher speed is not used |
| `sl_si91x_host_uart_transfer` | Only if UART host interface is selected; source report notes cited STM32 example marks it unimplemented |
| `sl_si91x_host_hold_in_reset`, `release_from_reset` | Drive/release open-drain RESET_N |
| `sl_si91x_host_set_sleep_indicator`, `clear_sleep_indicator` | Control wake-request GPIO |
| `sl_si91x_host_get_wake_indicator` | Read sleep indication status |
| `sl_si91x_host_enable_bus_interrupt`, `disable_bus_interrupt` | Mask/unmask SPI_INTR; verify apparent disable-call issue noted in the cited example |
| Interrupt handler | Set SDK receive event `NCP_HOST_BUS_RX_EVENT` or call `sl_si91x_bus_rx_irq_handler()` |

The source report cites a 1,600-byte SPI buffer and optional DMA in the STM32 example. CMSIS-RTOS2 implementation depends on the RTOS selected for the MIPS core and remains open.

### 5.2 Radio bring-up and errors

| Condition | Proposed handling |
|---|---|
| Unmapped address | Error responder returns decode error; must not hang |
| Radio does not answer | Wait until TIMEOUT, then report SPI busy error (0x0054 per source report) |
| SPI_ERR_INTR asserts | Reinitialize SPI using the documented initialization sequence and restart transactions |
| Radio sleeps | Disable radio interrupt before sleep; re-enable after SPI is reinitialized |
| Wrong interrupt polarity | Configure CTRL polarity to match selected mode |

The radio model should mirror the documented initialization tokens and handshake sequence. Confirm token/order values against the exact AN1432 release before treating the model as protocol conformance evidence.

### 5.3 Thread / Ethernet later

- Thread radio: OpenThread co-processor design with Spinel over UART or SPI; this is a different driver using the same class of peripheral.
- Thread border router additionally needs an IP stack on the host; the proposed initial POC does not require border routing unless scope changes.
- Ethernet needs a MAC and board PHY. If the MAC uses AXI-Stream, a DMA or bridge may be required. This is an inference to validate against the selected MAC.
- The proposed APB4 peripheral contract should remain unchanged as new peripheral blocks are added.

## 6. Optional offload

The proposed offload is **not part of the initial baseline**. First implement a software-only driver and measure CPU cycles/interrupts per frame. Add offload only if the measured baseline shows meaningful interrupt/copy cost.

| Element | Proposal | Open question |
|---|---|---|
| Descriptor ring | Buffer descriptors in memory for received SPI data | Frame sizes and alignment; source example uses up to 1,600-byte buffer |
| DMA | Second bus initiator moves bytes between `lot_rlink` and memory | This adds an initiator and may make a crossbar useful |
| Interrupt coalescing | One interrupt after N frames or timer expiry | Added low-load latency; N must be configurable |
| Control | Optional registers at 0x4000_3000 for enable, ring base/size, N/timer, status | Define after baseline |

### Measurement plan

- Throughput in Mbit/s between host and PC through access point; compare with vendor reference figures only after checking exact AN1434 data.
- CPU cycles per frame and per Mbit using core cycle counter.
- Interrupts per second from ISR counter and optional logic-analyzer GPIO toggle.
- Per-frame latency using GPIO toggles at interrupt entry/exit.
- Compare with Swapnil's x86 baseline using agreed equivalent metrics.
- Disable serial logging during measurement runs to reduce measurement distortion.

A vector-I/O paper in the source report motivates batching as a hypothesis; its reported storage results do not establish that an SPI radio will improve. Report measured gain or no gain honestly.

## 7. Verification architecture and tests

| Level | Scope | Environment | Exit criterion |
|---|---|---|---|
| L1 Unit | `lot_rlink` registers, SPI shifter, CS timing, interrupts, clock divider | HDL simulator with assertions | Register/timing tests pass; coverage of every register bit |
| L2 Subsystem | Host model, adapter, fabric and `lot_rlink` against radio model; unmapped address; reset pending; error injection | Simulator (ModelSim already used in repo) | V1–V5 pass |
| L3 Firmware-in-loop | HAL port on core model or real core RTL against radio model; reach CARD READY | Simulation/core model or instruction-set simulator (availability Check) | V8 passes in simulation |
| L4 Board | Real core and radio; SPI waveforms, bring-up, Wi-Fi join, throughput | FPGA board, analyzer, access point | V7–V9 pass |

### Radio model proposal

SystemVerilog SPI-slave model should answer initialization bytes `0x12 0x4A 0x5C 0x00` with `0x58`, return BOARD READY, accept LOADFIRMWARE and reply `0xAA`, raise SPI_INTR/SPI_ERR_INTR on command, and support no-response fault injection. The PDF labels the protocol as sourced and the model itself as proposed. Validate token values/order against the exact AN1432 version.

### Test IDs

| Test | Check | Level | Requirement |
|---|---|---|---|
| V1 | Core model reads/writes `lot_rlink` through fabric | L2 | R1 |
| V2 | Radio model answers init bytes with 0x58 | L2 | R2, R6 |
| V3 | Unmapped address returns error | L2 | R4 |
| V4 | SPI_ERR_INTR triggers reinitialization | L2 | R3, R6 |
| V5 | Reset with transfer pending recovers | L2 | R2, R3 |
| V6 | Synthesis meets timing; resources recorded | Board tools | R1, R9 |
| V7 | Init sequence visible on SPI lines | L4 | R2 |
| V8 | BOARD READY then CARD READY observed | L3, L4 | R5, R6 |
| V9 | Wi-Fi join; throughput measured | L4 | R6, R7 |
| V10 | BLE commissioning completes if Matter is in scope | L4 | R12 |
| V11 | Offload run shows fewer cycles or interrupts per frame | L4 | R7, R11 |
| V12 | Thread radio brings up over UART or SPI if in scope | L4 | R10 |

The source PDF reports the repository has crossbar tests, SVA/coverage, and a 12-test local regression, but says the regression was not rerun while authoring that document. Re-run the current repo test suites and update results with actual CI/run evidence before using this statement as current verification status.

## 8. Delivery phases and ownership

| Phase | Deliverables | Exit criterion | Proposed owner |
|---|---|---|---|
| 0. Decide | Answer section 9 decision questions | All answered or explicitly left open by owner | Mihai, Swapnil |
| 1. Simulate | `lot_rlink`, adapter, radio model, V1–V5, HAL skeleton | V1–V5 pass | Likhitha |
| 2. Build | Core, fabric, peripherals on board; synthesis/timing; boot/console | V6 passes; software reads register on board | Likhitha with MIPS/board vendor |
| 3. Radio | Wired board; six bring-up steps on real radio | V7 and V8 pass | Likhitha |
| 4. Connect | Wi-Fi join, throughput/CPU measurements, baseline report | V9 passes; results recorded | Likhitha; Swapnil comparison |
| 5. Offload | Only if baseline justifies it; remeasure | Measured gain or documented no gain | Open |
| 6. Extend | Thread, Ethernet, BLE/Matter, key storage | Scope defined and accepted | Open |

No dates or effort estimates are specified because the board, core and deadline are unresolved. Critical path: FPGA-available core → board build → real radio. Phase 1 simulation work can begin before board procurement.

## 9. Decisions and open items

| # | Question | Proposed answer / required input |
|---|---|---|
| 1 | LOT product role | Device-side connectivity only for POC; no Thread border router proposed |
| 2 | MIPS core and bus | Resolve through decision 7; plan for adapters only as needed |
| 3 | Silicon Labs board/mode | SiWx917 NCP over SPI proposed; exact board and SDK version to confirm |
| 4 | Arm access | Confirm Flexible Access tier; NIC-400 optional for FPGA and preferred for silicon in source proposal, subject to fit/access |
| 5 | FPGA board | Name vendor, part and free header pins |
| 6 | Radios in scope | Wi-Fi first; Thread/Ethernet later; BLE required if Matter is in scope |
| 7 | MIPS core in FPGA form and license | Ask MIPS which core/form is available and obtain written POC permission |
| 8 | Definition of done and deadline | Proposed: Wi-Fi join and throughput measured on board; deadline needed |
| 9 | Performance targets | Throughput, latency and CPU targets not set; owner input needed |
| 10 | Arm CSS, Corstone, dashboard | Do not pursue CSS; Corstone only with Arm host; dashboard optional |
| 11 | Offload engine | Build software baseline first; decide after measuring |
| 12 | Vendor contacts | Name one MobilFlex owner for MIPS and one for Silicon Labs |

## 10. Risks

| Risk | Impact | Mitigation / next action |
|---|---|---|
| No FPGA-ready MIPS core in time | Blocks phase 2 | Resolve core availability first; stand-in is software bring-up only |
| MIPSfpga license is academic only | Company POC may be outside terms | Get written MIPS permission or select another properly licensed core |
| Matter does not fit host | Matter scope unreachable | Keep Matter out of scope until approved; estimate build footprint first |
| SPI IP lacks mode 0/software CS | Rework `lot_rlink` | Check core early; implement a small shifter only if needed |
| Voltage/pin mismatch | Radio does not respond or damage risk | Read board guides and confirm I/O levels before wiring |
| Driver port takes longer | Delays radio phase | Start from Silicon Labs host example and adapt to selected RTOS |
| Offload gain is small | Weak performance demonstration | Measure baseline first |
| Scope/deadline unclear | Rework | Close decisions 6 and 8 |

## 11. Licensing summary

| Item | Reported terms/status | Required process |
|---|---|---|
| MIPSfpga microAptiv UP | Report says academic, non-commercial, FPGA-only click-through license | Written permission for company POC before use |
| PULP AXI, `apb_spi_master`, `register_interface` | Report records Solderpad Hardware License 0.51 | Pin exact revision; review included license and dependencies |
| OpenMIPS | LGPL-3.0 reported | Review exact repository license and obligations |
| WiSeConnect SDK | Silicon Labs license; non-Silicon-Labs-host terms not read in source report | Verify for selected host/SDK |
| Matter SDK, FPGA tools, MIPS Atlas cores, Arm IP | Not checked in source report | Review before adoption/distribution |

This table transcribes the supplied PDF's research status; it is not legal advice or a current independent license audit.

## 12. Source list and verification boundary

The source PDF lists:
- Silicon Labs, [Implement the Hardware Abstraction Layer (WiSeConnect 4.1.2)](https://docs.silabs.com/wiseconnect/latest/wiseconnect-developers-guide-migr-porting-steps/implement-hardware-abstraction)
- Silicon Labs, [Porting for an external host](https://docs.silabs.com/wiseconnect/latest/wiseconnect-developers-guide-migr-porting-approach)
- Silicon Labs, [AN1432 SPI features and configuration](https://docs.silabs.com/wifi-application-notes/1.0.4/wifi-siwx917-ncp-spi-protocol-application-note/spi-features-and-configuration)
- Silicon Labs, [Wi-Fi application note index](https://docs.silabs.com/wifi-application-notes/1.0.4/wifi-siwx917-ncp-spi-protocol-application-note/)
- Silicon Labs, [Matter hardware requirements](https://docs.silabs.com/matter/latest/matter-prerequisites/hardware-requirements)
- OpenThread, [co-processor designs](https://openthread.io/guides/ncp)
- MIPS by GF, [September 2026 overview PDF](https://mips.com/wp-content/uploads/2026/09/MIPS-Overview-Sept-2026.pdf)
- MIPS, [P8700 datasheet](https://mips.com/wp-content/uploads/2024/11/P8700_Data_Sheet.pdf)
- Harris et al., [MIPSfpga paper](https://pages.hmc.edu/harris/research/mipsfpga.pdf)
- [MIPSfpga-plus repository](https://github.com/MIPSfpga/mipsfpga-plus)
- Imagination, [MIPSfpga materials info sheet](https://www.silicon-russia.com/public_materials/2016_09_01_kazakhstan/day_4_microa/rchitecture/01_slides/06_Info-sheet-MIPSfpga-Materials-ver-6.5-November-2015.pdf)
- GlobalSpec, [MIPS architecture opened to universities](https://electronics360.globalspec.com/article/5270/mips-architecture-opened-to-universities)
- MIPS Open Developer Day, [DAC 2019 PDF](https://www.silicon-russia.com/wp-content/uploads/2019/06/mipsopen_developer_day_dac_2019_05_31.pdf)
- [PULP AXI repository](https://github.com/pulp-platform/axi)
- [PULP apb_spi_master repository](https://github.com/pulp-platform/apb_spi_master)
- [PULP register_interface repository](https://github.com/pulp-platform/register_interface)
- [OpenMIPS repository](https://github.com/grantae/OpenMIPS)
- Vasudevan, Kaminsky and Andersen, *Using vector interfaces to deliver millions of IOPS* (SoCC 2012), referenced in the supplied research pack.

The PDF says some sources were read as excerpts and should be reopened before external citation; it identifies AN1432 and the WiSeConnect HAL page as read in full. This repository copy preserves that caveat.

**Non-claims:** this is a preliminary engineering proposal, not vendor confirmation, legal opinion or hardware test report. Exact MIPS core/bus, FPGA board, SDK versions, target-specific licensing, timing/resources and hardware behavior remain unresolved.
