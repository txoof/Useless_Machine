import board
import digitalio
import pulseio
import time

from adafruit_debouncer import Debouncer

# physical switches
LIMIT_SWITCH_PHY = board.D9
DIRECTION_SWITCH_PHY = board.D7

SERVO_PWM_PHY = board.D10

DUTY_MIN = 0.5 # 0 degrees
DUTY_MAX = 2.5 # 180 degrees

RESOLUTION_MIN = 0.002 # smallest steps to take when moving
RESOLUTION_MAX = 0.04 # largest steps to take when moving

ANGLE_MIN = 0
ANGLE_MAX = 180

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


def rotate_to_angle(current_angle, dest_angle, speed):
    '''rotate from current_angle to dest_angle at speed
    Args:
        current_angle (real): angle between SERVO_MIN and SERVO_MAX
        dest_angle (real): angle between SERVO_MIN and SERVO_MAX
        speed (real): between 0 and 1
    '''

    direction = 1 if current_angle < dest_angle else -1
    endstop = limit_switch if direction == -1 else direction_switch

    endstop.update()

    step_size = map_range((0, 1), (RESOLUTION_MIN, RESOLUTION_MAX), speed)
    steps = int(abs(current_angle-dest_angle))

    print('ROTATING to {dest_angle} with step_size: {step_size}')
    for i in range(0, steps):
        print(f'{i} of {steps} cur_angle: {current_angel}')
        if endstop.value:
            break
        current_angel = current_angle + (step_size * direction)
        servo.duty_cycle = angle_to_duty(current_angle)

    return current_angle



l = [70, 80, 90, 100, 110, 90, 70, 60]
last = 65
for i in l:
    print(f'current: {last}, dest: {i}')
    rotate_to_angle(last, i, 1)
    time.sleep(.5)
    last = i
