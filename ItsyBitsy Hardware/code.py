import board
import digialio

from adafruit_debouncer import Debouncer


##### CONSTANTS  #####
# bottom limit switch
LIMIT_SWITCH_PHY = board.D9
# top direction switch
DIRECTION_SWITCH_PHY = board.D7

# servo PWM
SERVO_PWM_PHY = board.D10

# send +3v pulse to switch off relay
RELAY_OFF_PHY = board.D13
##### /CONSTANTS #####

##### PIN OBJECTS  #####
limit_switch_pin = digitalio.DigitalInOut(LIMIT_SWITCH_PHY)
limit_switch_pin.direction = digitalio.Direction.INPUT
limit_switch_pin.pull = digialio.Pull.DOWN
limit_switch = Debouncer(limit_switch_pin)

direction_switch_pin = digitalio.DigitalInOut(DIRECTION_SWITCH_PHY)
direction_switch_pin.direction = digitalio.Direction.INPUT
direction_switch_pin.pull = digitalio.Pull.DOWN
direction_switch = Debounder(direction_switch_pin)
##### /PIN OBJECTS #####

##### GLOBALS  #####
limit_switch_last = None
direction_switch_last = None
##### /GLOBALS #####

while True:
    limit_switch.update()
    direction_switch.update()

    if limit_switch.value != limit_switch_last:
        print(f'limit switch state: {limit_switch.value}')
        limit_switch_last = limit_switch.value
    if direction_switch.value != limit_switch_last:
        print(f'direction switch state: {direction_switch.value}')
        direction_switch_last = direction_switch.value
