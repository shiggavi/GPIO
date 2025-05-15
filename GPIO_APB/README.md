GPIO APB Peripheral with 4-bit Filter Thresholds

This document provides a step-by-step guide to understanding, instantiating, and integrating the gpio_apb Verilog-2005 module into your design.

Overview:
    This overview focuses exclusively on the internal GPIO controller logic—how pins are sampled, filtered, driven, and how interrupts and strap sampling integrate—omitting bus and pad-wrapper details.
    APB3 compliant bus interface (PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR)
The Advanced Peripheral Bus (APB3) provides a simple, low-power interface for register-mapped peripherals:

    Signal Roles:

    PCLK, PRESETn: Clock and reset.

    PSEL: Selects the peripheral for a transaction.

    PENABLE: Differentiates setup and access phases.

    PWRITE: High for write, low for read operations.

    PADDR[5:0]: Address lines index into the register map.

    PWDATA[31:0]: Data bus for writes.

    PRDATA[31:0]: Data bus for reads.

    PREADY: Indicates the peripheral is ready to complete the transaction (can stretch cycles).

    PSLVERR: Signals an error response.

    Transaction Flow:

    Master drives PSEL=1, PADDR, PWRITE, and PWDATA for writes.

    In the following cycle, PENABLE is asserted.

    The peripheral responds with PREADY=1 when data is available (read) or write is accepted.

    During reads, PRDATA must be valid when PREADY is high.

    If an error occurs, PSLVERR is asserted alongside PREADY.

    Stall Support: The controller can stretch the access by holding PREADY low (via the stall input) for additional cycles if needed.

Bidirectional GPIO: 
    32 input pins, configurable direction, and output value

    Bidirectional GPIO Operation

    The controller uses separate direction (gpio_dir) and output (gpio_out) registers to achieve true bidirectional behavior.

    Drive mode: When gpio_dir[i] is 1, the pad is driven with the value gpio_out[i].

    Sense mode: When gpio_dir[i] is 0, the pad is tri-stated (high-Z) and the external signal is sampled into gpio_in[i], feeding the internal synchronizer and filter.

Configurable interrupts: 
    edge-sensitive, maskable, with status flags


    Edge Selection: Each pin’s edge sensitivity is set via the EDGE register bit: 1 for rising-edge, 0 for falling-edge.

    Event Detection: On every clock, filtered inputs (gpio_in_filtered) compare against the previous state (r_in_d):

    Rising: ~r_in_d & gpio_in_filtered when EDGE[i]=1

    Falling: r_in_d & ~gpio_in_filtered when EDGE[i]=0

    Masking & Flags: Detected edge events are AND’ed with the interrupt-enable mask (IE) to update the sticky interrupt-flag register (IFG).

    Clearing Flags: Write a 1 to specific bits in IFG via the IFG register address to clear those flags.

    IRQ Output: A global interrupt signal (irq) is asserted when any enabled flag is set: irq = |(r_ie & r_ifg).

    These steps ensure precise, per-pin interrupt generation with software-controlled masking and clearing.

Strap sampling: 
    one-shot sampling of input pins at reset or on demand

    One-Shot Capture: On assertion of strap_en (and if not already sampled), the raw gpio_in bus is latched into strap_sample_data and strap_sample_valid is asserted.

    Valid Flag: strap_sample_valid indicates new strap data availability until cleared; remains valid across resets until explicitly cleared.

    Re-Arm: Writing a 1 to the least significant bit of the STRAP_VALID register clears strap_sample_valid and resets the sampler (strap_done) for a new capture.

    Non-Interference: Sampling occurs asynchronously alongside normal GPIO operation—does not block or interfere with filter, interrupts, or APB transactions.

    Glitch Immunity: Because raw inputs are sampled directly, brief glitches on strap_en are harmless; the one-shot mechanism prevents repeated captures.

    Readback: Sampled data and validity can be read via STRAP_DATA and STRAP_VALID registers over APB for software configuration.

    Usage: Ideal for capturing static configuration pins (straps) at reset or on-demand to select boot modes, hardware options, or calibration settings.

Filter + synchronizer: 
    per-pin 4-bit counter-based filter thresholds with optional two-stage synchronizer

    Each GPIO input bit is processed in three configurable steps to guarantee signal integrity:

    Two-Stage Synchronization: Aligns asynchronous external signals to the internal clock domain using two flip-flops, eliminating metastability risks.

    Glitch Filtering: Applies a per-pin debounce mechanism. A level change only registers after the input remains stable for a programmable number of clock cycles, filtering out transient spikes.

    Threshold Configuration: Each pin has a 4-bit filter threshold (0–15 cycles) stored in the FILT_TH0–FILT_TH3 registers. A threshold of N requires the input to be stable for at least N cycles before updating, allowing fine-grained noise immunity tuning.

    Software Control:

    Global synchronization enable via the AsyncOn parameter.

    Per-pin filter enable via the FILT_EN register.

    Per-pin threshold values via the FILT_THx registers.

    Data Flow: Raw gpio_in → two-stage sync → stable sample → filter counter (threshold test) → filtered output gpio_in_filtered → captured in r_in_d for edge detection and internal logic.

