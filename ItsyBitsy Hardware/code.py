import board
import digitalio
import time


from adafruit_debouncer import Debouncer


##### CONSTANTS  #####
# shutoff timeout (seconds)
SHUTDOWN_TIMEOUT = 4

# bottom limit switch
LIMIT_SWITCH_PHY = board.D9
# top direction switch
DIRECTION_SWITCH_PHY = board.D7

# servo PWM
SERVO_PWM_PHY = board.D10

# send +3v pulse to switch off relay
RELAY_OFF_PHY = board.D12
##### /CONSTANTS #####

def heart_beat(t=10):
    global timer

    if time.monotonic() - timer >= t:
        timer = time.monotonic()
        print(f'tick: {timer}')
        return True
    else:
        return False



##### PIN OBJECTS  #####
limit_switch_pin = digitalio.DigitalInOut(LIMIT_SWITCH_PHY)
limit_switch_pin.direction = digitalio.Direction.INPUT
limit_switch_pin.pull = digitalio.Pull.DOWN
limit_switch = Debouncer(limit_switch_pin)

direction_switch_pin = digitalio.DigitalInOut(DIRECTION_SWITCH_PHY)
direction_switch_pin.direction = digitalio.Direction.INPUT
direction_switch_pin.pull = digitalio.Pull.DOWN
direction_switch = Debouncer(direction_switch_pin)
##### /PIN OBJECTS #####

##### GLOBALS  #####
# last state of limit switch
limit_switch_last = None
# last state of direction switch
direction_switch_last = None

# global timer
timer = time.monotonic()

# shutdown timer
shutdown_timer = time.monotonic()
is_shutdown = False
##### /GLOBALS #####

def shutdown_check(limit_switch, direction_switch):
    global timer
    shutdown_now = False
    if time.monotonic() - timer >= SHUTDOWN_TIMEOUT:
        # check if limit and direction switch are both in the home (true) position
        if limit_switch.value and direction_switch.value:
            shutdown_now = True
        else:
            shutdown_now = False
    else:
        shutdown_now = False

    return shtudown_now

while True:
    if heart_beat(3):
        print(f'time to shutdown: {time.monotonic() - shutdown_timer - SHUTDOWN_TIMEOUT}')
        pass
    limit_switch.update()
    direction_switch.update()

    if direction_switch.value == True:
        is_shutdown = False
        timer = time.monotonic()


    if is_shutdown:
        pass
    else:
        if shutdown_now(limit_switch, direction_switch):
            print(f'sending shutdown pulse on pin {RELAY_OFF_PHY}')
            is_shutdown = True



    if limit_switch.value != limit_switch_last:
        print(f'limit switch state: {limit_switch.value}')
        limit_switch_last = limit_switch.value
    if direction_switch.value != direction_switch_last:
        print(f'direction switch state: {direction_switch.value}')
        direction_switch_last = direction_switch.value
