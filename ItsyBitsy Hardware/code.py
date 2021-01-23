import board
import digitalio
import time
import pulseio
# import random

from adafruit_debouncer import Debouncer
# from adafruit_motor import servo

##### CONSTANTS #####
# physical pins
# limit switch physical pin
LIMIT_SW_PHY = board.D9
SERVO_OUT_PHY = board.D10

MIN_DUTY = 0.5
MAX_DUTY = 2.5


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





def servo_duty_cycle(pulse_ms, frequency=50):
    period_ms = 1.0 / frequency * 1000.0
    duty_cycle = int(pulse_ms / (period_ms / 65535.0))
    return duty_cycle


def rotate(current, degrees, speed):
    limitsw.update()
    resolution = map_range((1,100), (0.005, .8), speed)


limitsw.update()
limitsw_last = limitsw.value

start = MIN_DUTY
end = MAX_DUTY
current = start
direction = 1

resolution = 0.005

servo.duty_cycle = servo_duty_cycle(start)
while True:
    limitsw.update()


    if limitsw.value:
        current = current + resolution * direction
        # print(f'direction: {direction}; current: {current}')
        servo.duty_cycle = servo_duty_cycle(current)

    if current >= end or current <=start:
        direction = direction * -1

    if  limitsw.value != limitsw_last:
        print(f'limitsw statechange: {not  limitsw.value}')
        limitsw_last = limitsw.value
    # servo.duty_cycle = servo_duty_cycle(.4)
    # time.sleep(1.5)
    # servo.duty_cycle = servo_duty_cycle(2.5)
    # time.sleep(1.5)
