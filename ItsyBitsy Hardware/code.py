import board
import digitalio
import pulseio

from hello import *

from adafruit_debouncer import Debouncer

# physical switches
LIMIT_SWITCH_PHY = board.D9
DIRECTION_SWITCH_PHY = board

print_hello()
