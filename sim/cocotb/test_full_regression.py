import cocotb
from cocotb.clock import Clock
from cordic_tb_utils import reset_dut, run_cordic_transaction, TOLERANCE

@cocotb.test()
async def test_continuous_streaming_regression(dut):
    """Test 5: Continuous Multi-Frame Streaming Protocol Execution"""
    cocotb.start_soon(Clock(dut.i_clk, 100, unit="ns").start())
    await reset_dut(dut)

    stream_angles = [0, 8192, 16384, 24576, 32767, -8192, -16384, -24576]
    
    for ang in stream_angles:
        deg, act_c, exp_c, err_c, act_s, exp_s, err_s = await run_cordic_transaction(dut, ang & 0xFFFF, cs_delay_ns=50)
        assert err_c <= TOLERANCE and err_s <= TOLERANCE, f"Streaming failure at angle {deg}°"
