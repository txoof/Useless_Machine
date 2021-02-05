import board
import digitalio
import time
import pulseio


from adafruit_debouncer import Debouncer


##### CONSTANTS  #####
# shutoff timeout (seconds)
SHUTDOWN_TIMEOUT = 4

# endstop positions for arm
HOME_LOW = 43
HOME_HIGH = 168.5

# bottom limit switch
LIMIT_SWITCH_PHY = board.D9
# top direction switch
DIRECTION_SWITCH_PHY = board.D7

# servo PWM
SERVO_PWM_PHY = board.D10

# send +3v pulse to switch off relay
RELAY_OFF_PHY = board.D12

# min and max duty cycle for PWM servo 0.5==0 degrees; 2.5==180 degrees
DUTY_MIN = 0.5 # 0 degrees
DUTY_MAX = 2.5 # 180 degrees

# max, min angle
ANGLE_MIN = 0
ANGLE_MAX = 180

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

# relay power-off pin
relay_pin = digitalio.DigitalInOut(RELAY_OFF_PHY)
relay_pin.direction = digitalio.Direction.OUTPUT

# servo pwm OUTPUT
servo = pulseio.PWMOut(SERVO_PWM_PHY, duty_cycle=2**15, frequency=50)
##### /PIN OBJECTS #####

def map_range(a, b, s):
    '''Map range (min a, max a) to range (min b, max b) for value s
    '''
    (a1, a2), (b1, b2) = a, b
    return b1 + ((s - a1) * (b2 - b1) / (a2 - a1))

def angle_to_duty(angle, frequency=50):
    '''convert angle between ANGLE_MIN-ANGLE_MAX to a position between DUTY_MIN-DUTY_MAX'''
    pulse_ms = map_range((ANGLE_MIN, ANGLE_MAX), (DUTY_MIN, DUTY_MAX), angle)

    period_ms = 1.0 / frequency * 1000.0
    return int(pulse_ms / (period_ms / 65535.0))

def go_to_angle(dest_angle):
    '''move servo directly to angle'''
    print(f'moving to: {dest_angle}')
    servo.duty_cycle = angle_to_duty(dest_angle)


##### GLOBALS  #####
# last state of limit switch
limit_switch_last = None
# last state of direction switch
direction_switch_last = None

# global timer
timer = time.monotonic()

# shutdown timer
shutdown_timer = time.monotonic()
# shutdown state
is_shutdown = False
# arm is parked, switches shutoff
is_parked = True
# timeout time expired
is_timedout = False
##### /GLOBALS #####

go_to_angle(45)


while True:
    if heart_beat(2.5):
        if not is_shutdown:
            print(f'time to shutdown: {time.monotonic() - shutdown_timer - SHUTDOWN_TIMEOUT}')
        pass
    limit_switch.update()
    direction_switch.update()

    is_parked = True if limit_switch.value and direction_switch.value else False
    is_timedout = True if time.monotonic() - shutdown_timer >= SHUTDOWN_TIMEOUT else False

    if is_parked == False:
        shutdown_timer = time.monotonic()
        is_timedout = False
        is_shutdown = False

    if is_parked and is_timedout and not is_shutdown:
        print('sending shutdown pulse')
        relay_pin.value = True
        time.sleep(1)
        relay_pin.value = False
        is_shutdown = True


    if limit_switch.value != limit_switch_last:
        print(f'limit switch state: {limit_switch.value}')
        limit_switch_last = limit_switch.value
    if direction_switch.value != direction_switch_last:
        print(f'direction switch state: {direction_switch.value}')
        direction_switch_last = direction_switch.value
