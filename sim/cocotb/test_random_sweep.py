import random
import cocotb
from cocotb.clock import Clock
from cordic_tb_utils import reset_dut, run_cordic_transaction, TOLERANCE

@cocotb.test()
async def test_1000_random_angles(dut):
    """Test 3: 1,000 Iteration Randomized Input Angle Sweep"""
    cocotb.start_soon(Clock(dut.i_clk, 100, unit="ns").start())
    await reset_dut(dut)

    max_err_c = 0.0
    max_err_s = 0.0

    for i in range(1000):
        rand_ang = random.randint(-32768, 32767) & 0xFFFF
        deg, act_c, exp_c, err_c, act_s, exp_s, err_s = await run_cordic_transaction(dut, rand_ang)
        
        max_err_c = max(max_err_c, err_c)
        max_err_s = max(max_err_s, err_s)
        
        assert err_c <= TOLERANCE and err_s <= TOLERANCE, f"Iteration {i} failed at angle {deg}°"

    dut._log.info(f"SWEEP COMPLETED | Max COS Error = {max_err_c:.6f} | Max SIN Error = {max_err_s:.6f}")
