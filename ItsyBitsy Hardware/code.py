import board
import digitalio
import pulseio
import time

from adafruit_debouncer import Debouncer

class ArmRoutine():
    def __init__(self, name):
        pass

# physical switches
LIMIT_SWITCH_PHY = board.D9
DIRECTION_SWITCH_PHY = board.D7

SERVO_PWM_PHY = board.D10

DUTY_MIN = 0.5 # 0 degrees
DUTY_MAX = 2.5 # 180 degrees

RESOLUTION_MIN = 0.04 # smallest angle steps to take when moving
RESOLUTION_MAX = 10 # largest angle steps to take when moving

ANGLE_MIN = 0
ANGLE_MAX = 180

HOME_LOW = 45
HOME_HIGH = 168


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
    print(f'moving to: {dest_angle}')
    servo.duty_cycle = angle_to_duty(dest_angle)


def rotate_to_angle(current_angle, dest_angle, speed=0.08):
    '''rotate from current_angle to dest_angle at speed
    Args:
        current_angle (real): angle between SERVO_MIN and SERVO_MAX
        dest_angle (real): angle between SERVO_MIN and SERVO_MAX
        speed (real): between 0 and 1
    '''
    def check_angle(angle):
        if angle > HOME_HIGH:
            angle = HOME_HIGH
        if angle < HOME_LOW:
            angle = HOME_LOW
        return angle

    direction = 1 if current_angle < dest_angle else -1

    break_out = False

    endstop_hit = None

    step_size = map_range((0, 1), (RESOLUTION_MIN, RESOLUTION_MAX), speed)
    steps = int(abs((current_angle-dest_angle)/step_size))

    print(f'ROTATE to {dest_angle}; dir: {direction} step_size: {step_size} steps: {steps}')

    for i in range(0, steps+1):
        limit_switch.update()
        direction_switch.update()

        # check for limit switch collisions
        if direction == -1 and limit_switch.value:
            break_out = True
            endstop_hit = 'limit_switch'

        if direction == 1 and direction_switch.value:
            break_out = True
            endstop_hit = 'direction_switch'

        if direction == -1 and not direction_switch.value:
            break_out = True
            endstop_hit = 'direction_switch changed while returning'

        if break_out:
            print(f'hit endstop: {endstop_hit}')
            break
        else:
            current_angle = current_angle + (step_size * direction)

            # if over-run in positive or negative, set to max or min as appropriate
            current_angle = check_angle(current_angle)


            servo.duty_cycle = angle_to_duty(current_angle)

    current_angle = check_angle(current_angle)
    return current_angle

# pin objects
limit_switch_pin = digitalio.DigitalInOut(LIMIT_SWITCH_PHY)
limit_switch_pin.direction = digitalio.Direction.INPUT
limit_switch_pin.pull = digitalio.Pull.DOWN
limit_switch = Debouncer(limit_switch_pin)

direction_switch_pin = digitalio.DigitalInOut(DIRECTION_SWITCH_PHY)
direction_switch_pin.direction = digitalio.Direction.INPUT
direction_switch_pin.pull = digitalio.Pull.DOWN
direction_switch = Debouncer(direction_switch_pin)

servo = pulseio.PWMOut(SERVO_PWM_PHY, duty_cycle=2**15, frequency=50)
limit_last = limit_switch.update()
direction_last = direction_switch.update()


# Startup
current_angle = HOME_LOW
# go_to_angle(HOME_LOW)
rotate_to_angle(HOME_LOW - 5, HOME_LOW, .9)




while True:
    limit_switch.update()
    direction_switch.update()

    if not direction_switch.value:
        if current_angle >= HOME_HIGH:
            pass
        else:
            print('run forwards')
            current_angle = rotate_to_angle(current_angle, HOME_HIGH)

    if not limit_switch.value and direction_switch.value:
        if current_angle <= HOME_LOW:
            pass
        else:
            print('run backwards')
            current_angle = rotate_to_angle(current_angle, HOME_LOW)


    if  limit_switch.value != limit_last:
        limit_last = limit_switch.value
        print(f'limit: {limit_switch.value}')

    if direction_switch.value != direction_last:
        direction_last = direction_switch.value
        print(f'direction: {direction_switch.value}')
