# Two Player Race

VHDL reaction game for the Basys 3 FPGA board using Xilinx Vivado.

The game lights random LEDs for each player. Players use the board switches to clear their side's lit LEDs and score points. Scores and victory patterns are shown on the four-digit seven-segment display.

## Controls

| Control | Purpose |
| --- | --- |
| `btnC` | Start game |
| `btnD` | Reset game |
| `sw[6:0]` | Player 1 switches |
| `sw[15:9]` | Player 2 switches |
| `led[6:0]` | Player 1 lit targets |
| `led[15:9]` | Player 2 lit targets |
| `seg`, `an` | Score and victory display |

## Files

- `src/Two_Player_Race.vhd` - top-level game logic
- `src/SevenSegmentDriver.vhd` - multiplexed four-digit seven-segment display driver
- `constraints/basys3-master.xdc` - Basys 3 pin constraints used by this design

## Notes

The original repository name referenced VGA, but the current design does not expose VGA ports. The active hardware interface is switches, buttons, LEDs, and the seven-segment display.
