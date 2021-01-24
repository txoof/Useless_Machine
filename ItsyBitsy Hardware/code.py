# """CircuitPython Essentials Storage logging example"""
# import time
# import board
# import digitalio
# import microcontroller
# # For most CircuitPython boards:
# led = digitalio.DigitalInOut(board.D13)
# # For QT Py M0:
# # led = digitalio.DigitalInOut(board.SCK)
# led.switch_to_output()
# try:
#     with open("/temperature.txt", "a") as fp:
#         while True:
#             temp = microcontroller.cpu.temperature
#             # do the C-to-F conversion here if you would like
#             print(temp)
#             fp.write('{0:f}\n'.format(temp))
#             fp.flush()
#             led.value = not led.value
#             time.sleep(1)
# except OSError as e:
#     delay = 0.5
#     if e.args[0] == 28:
#         delay = 0.25
#     while True:
#         led.value = not led.value
#         time.sleep(delay)
#         print('cannot write to storage')


import board
import digitalio
import time
import pulseio
from math import ceil
# import random

from adafruit_debouncer import Debouncer
# from adafruit_motor import servo

##### CONSTANTS #####
# physical pins
# limit switch physical pin
LIMIT_SW_PHY = board.D9
SERVO_OUT_PHY = board.D10

DUTY_MIN = 0.5
DUTY_MAX = 2.5

RESOLUTION_MAX = 0.04
RESOLUTION_MIN = 0.002

SERVO_MIN = 0
SERVO_MAX = 180

# pin objects
limitsw_pin = digitalio.DigitalInOut(LIMIT_SW_PHY)
servo = pulseio.PWMOut(SERVO_OUT_PHY, duty_cycle=2 **15, frequency=50)



# setup objects
limitsw_pin.direction = digitalio.Direction.INPUT
limitsw_pin.pull = digitalio.Pull.DOWN

# servo object
# servo = servo.Servo(servo_pwm_pin, min_pulse=500, max_pulse=2100)

# debounce object
limitsw = Debouncer(limitsw_pin)

def map_range(a, b, s):
    '''Map range (min a, max a) to range (min b, max b) for value s
    '''
    (a1, a2), (b1, b2) = a, b
    return b1 + ((s - a1) * (b2 - b1) / (a2 - a1))

def angle_to_duty(angle):
    pulse_ms = map_range((ANGLE_MIN, ANGLE_MAX), (DUTY_MIN, DUTY_MAX), angle)
    return servo_duty_cycle(pulse_ms)


def servo_duty_cycle(pulse_ms, frequency=50):
    period_ms = 1.0 / frequency * 1000.0
    duty_cycle = int(pulse_ms / (period_ms / 65535.0))
    return duty_cycle

def angle_to_duty(angle):
    pulse_ms = map_range((ANGLE_MIN, ANGLE_MAX), (DUTY_MIN, DUTY_MAX), angle)
    return servo_duty_cycle(pulse_ms)

def rotate_to_position(current_angle, dest_angle, speed):
    print(f'rotating from {current_angle} to {dest_angle}')
    if current_angle > dest_angle:
        direction = -1
    else:
        direction = 0

    step_size = map_range((0, 1), (RESOLUTION_MIN, RESOLUTION_MAX), speed)
    steps = ceil(abs(current_angle - dest_angle)/step_size)
    for i in range (0, steps):
        current_angle = current_angle + step_size * direction
        print(current_angle)



limitsw.update()
limitsw_last = limitsw.value

home_angle = 0

current_angle = home_angle
direction = 1

resolution = 0.002

# servo.duty_cycle = servo_duty_cycle(start)
while True:
    limitsw.update()

    # move to
    servo.duty_cycle = servo_duty_cycle(1.5)

    # if limitsw.value:
    #     current = current + resolution * direction
    #     # print(f'direction: {direction}; current: {current}')
    #     servo.duty_cycle = servo_duty_cycle(current)
    #
    # if current >= end or current <=start:
    #     direction = direction * -1

    if  limitsw.value != limitsw_last:
        print(f'limitsw statechange: {not  limitsw.value}')
        limitsw_last = limitsw.value
    # servo.duty_cycle = servo_duty_cycle(.4)
    # time.sleep(1.5)
    # servo.duty_cycle = servo_duty_cycle(2.5)
    # time.sleep(1.5)
