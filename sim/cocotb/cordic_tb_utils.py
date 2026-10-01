import math
import cocotb
from cocotb.triggers import Timer

TOLERANCE = 0.002

def to_signed16(val: int) -> int:
    """Converts an unsigned 16-bit word to a signed 16-bit integer."""
    val = val & 0xFFFF
    return val - 65536 if val >= 32768 else val

async def reset_dut(dut):
    """Applies active-low reset pulse and initializes SPI bus signals."""
    dut.i_rst_n.value = 0
    dut.i_ss_n.value = 1
    dut.i_sck.value = 0
    dut.i_mosi.value = 0
    await Timer(200, unit="ns")
    dut.i_rst_n.value = 1
    await Timer(200, unit="ns")

async def spi_xfer(dut, tx_word: int, sck_half_ns: int = 2400) -> int:
    """
    Executes a 16-bit SPI Mode 0 transfer MSB-first.
    Master changes MOSI on falling edge, samples MISO on rising edge.
    """
    rx_word = 0
    for b in range(15, -1, -1):
        dut.i_mosi.value = (tx_word >> b) & 1
        await Timer(sck_half_ns, unit="ns")
        
        dut.i_sck.value = 1
        rx_word = (rx_word << 1) | int(dut.o_miso.value)
        await Timer(sck_half_ns, unit="ns")
        
        dut.i_sck.value = 0
        
    return rx_word

async def run_cordic_transaction(dut, angle_raw: int, sck_half_ns: int = 2400, cs_delay_ns: int = 100):
    """
    Executes a 2-word frame CORDIC SPI protocol transaction:
      Word 0 (MOSI): Angle input  | MISO: COS of PREVIOUS frame
      Word 1 (MOSI): Dummy 0x0000 | MISO: SIN of CURRENT frame
    """
    # Word 0 & Word 1 in Frame 0
    dut.i_ss_n.value = 0
    await Timer(cs_delay_ns, unit="ns")
    _ = await spi_xfer(dut, angle_raw, sck_half_ns)
    w1_rx = await spi_xfer(dut, 0x0000, sck_half_ns)
    await Timer(cs_delay_ns, unit="ns")
    dut.i_ss_n.value = 1

    await Timer(cs_delay_ns, unit="ns")

    # Frame 1: Retrieve Cosine
    dut.i_ss_n.value = 0
    await Timer(cs_delay_ns, unit="ns")
    dummy_rx = await spi_xfer(dut, 0x0000, sck_half_ns)
    await Timer(cs_delay_ns, unit="ns")
    dut.i_ss_n.value = 1
    await Timer(cs_delay_ns, unit="ns")

    # Conversion & Error Check
    act_sin = to_signed16(w1_rx) / 32768.0
    act_cos = to_signed16(dummy_rx) / 32768.0

    angle_signed = to_signed16(angle_raw)
    deg = (angle_signed / 32768.0) * 180.0
    rad = math.radians(deg)
    
    exp_cos = math.cos(rad)
    exp_sin = math.sin(rad)

    err_cos = abs(act_cos - exp_cos)
    err_sin = abs(act_sin - exp_sin)

    return deg, act_cos, exp_cos, err_cos, act_sin, exp_sin, err_sin
