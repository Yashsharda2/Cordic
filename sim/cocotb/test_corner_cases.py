import cocotb
from cocotb.clock import Clock
from cordic_tb_utils import reset_dut, run_cordic_transaction, TOLERANCE

@cocotb.test()
async def test_cardinal_and_boundary_angles(dut):
    """Test 1: Cardinal Angles and Precision Limits"""
    cocotb.start_soon(Clock(dut.i_clk, 100, unit="ns").start())
    await reset_dut(dut)

    # 0°, 90°, -90°, ~180°, -180°, +1 LSB angle, -1 LSB angle
    test_angles = [0, 16384, -16384, 32767, -32768, 1, -1]

    for raw_ang in test_angles:
        deg, act_c, exp_c, err_c, act_s, exp_s, err_s = await run_cordic_transaction(dut, raw_ang & 0xFFFF)
        dut._log.info(f"ANG {deg:7.2f}° | COS act={act_c:8.5f} exp={exp_c:8.5f} | SIN act={act_s:8.5f} exp={exp_s:8.5f}")
        assert err_c <= TOLERANCE, f"COS error ({err_c:.5f}) out of spec at {deg}°"
        assert err_s <= TOLERANCE, f"SIN error ({err_s:.5f}) out of spec at {deg}°"
