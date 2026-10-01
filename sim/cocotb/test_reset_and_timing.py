import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cordic_tb_utils import reset_dut, spi_xfer, run_cordic_transaction, TOLERANCE

@cocotb.test()
async def test_mid_calculation_reset(dut):
    """Test 4: Assert reset while CORDIC engine is running mid-calculation"""
    cocotb.start_soon(Clock(dut.i_clk, 100, unit="ns").start())
    await reset_dut(dut)

    # Start Word 0 to kick off CORDIC calculation
    dut.i_ss_n.value = 0
    _ = await spi_xfer(dut, 16384, sck_half_ns=1000)
    
    # Assert reset while CORDIC engine is actively computing
    await Timer(500, unit="ns")
    dut.i_rst_n.value = 0
    await Timer(300, unit="ns")
    dut.i_rst_n.value = 1
    dut.i_ss_n.value = 1
    await Timer(500, unit="ns")

    # Verify system operates cleanly after reset
    deg, act_c, exp_c, err_c, act_s, exp_s, err_s = await run_cordic_transaction(dut, 0)
    assert err_c <= TOLERANCE and err_s <= TOLERANCE, "System failed to recover after mid-calculation reset"
