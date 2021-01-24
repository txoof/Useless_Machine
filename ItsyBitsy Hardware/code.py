import board
import digitalio
import pulseio

from adafruit_debouncer import Debouncer

# physical switches
LIMIT_SWITCH_PHY = board.D9
DIRECTION_SWITCH_PHY = board.D7

SERVO_PWM_PHY = board.D10

DUTY_MIN = 0.5 # 0 degrees
DUTY_MAX = 2.5 # 180 degrees

RESOLUTION_MIN = 0.002 # smallest steps to take when moving
RESOLUTION_MAX = 0.04 # largest steps to take when moving

SERVO_MIN = 0
SERVO_MAX = 180
