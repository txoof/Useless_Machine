import time
import board
import pulseio
import random
from adafruit_motor import servo
# handle switch reading
import digitalio
from adafruit_debouncer import Debouncer

 # import DigitalInOut, Direction, Pull

# pin definitions
servo_pin = board.D10
endstop_pin = board.D9

# input/output
endstop = digitalio.DigitalInOut(endstop_pin)
endstop.direction = digitalio.Direction.INPUT
endstop.pull = digitalio.Pull.DOWN
endstop_switch = Debouncer(endstop)

# create a PWMOut object on Pin D5.
pwm = pulseio.PWMOut(servo_pin, duty_cycle=2 ** 15,  frequency=50)



# Create a servo object.
servo = servo.Servo(pwm, min_pulse=500, max_pulse=2100)


# endstops for servo
servo_home = 0
servo_max = 179
direction = 1

servo_max_rate = 50
servo_min_rate = 0.05



def home_arm(angle, endstop_switch, servo):
    endstop_switch.update()
    while not endstop_switch.value():
        print('endstop open')
        endstop_switch.update()
        servo.angle = angle
    print('endstop closed')


def map_range(a, b, s):
    (a1, a2), (b1, b2) = a, b
    return b1 + ((s - a1) * (b2 - b1) / (a2 - a1))

def set_servo(servo_position, rate, direction, endstop_switch):
    '''
    move servo forward or backwards in steps proportional to the rate

    Args:
        rate(int): 1-100 - higher rates move in larger steps
        direction(0, 1): 0 anti clockwise, 1 clockwise
    '''
    endstop_switch.update()
    if endstop_switch.value:
        print('enstop closed - refusing to move')
        return servo_position
    add_angle = map_range((0, 100), (servo_min_rate, servo_max_rate), rate)
    sleep_value = add_angle * 0.01
    servo_position = (servo_position + (add_angle * direction))
    if servo_position > servo_max:
        print(f'position greater than 180 {servo_position}')
        servo_position = servo_max
    if servo_position < servo_home:
        print(f'position lessthan than 0 {servo_position}')
        servo_position = servo_home

    servo.angle = servo_position
    time.sleep(sleep_value)
    print(f'deg: {add_angle}; current pos: {servo_position}; direction: {direction}')
    return servo_position


# servo_position = servo_home
# servo.angle = servo_position

home_arm(servo_home, endstop_switch, servo=servo)


while True:
    if servo_position <= servo_home:
        direction = 1
        time.sleep(3)
        print('hit endstop')
        print('*'*10)
    if servo_position >= servo_max:
        direction = -1
        print('hit endstop')
        print('*'*10)
        time.sleep(3)

    my_rate = random.randint(1, 100)
    print(f'servo rate: {my_rate}')

    servo_position = set_servo(servo_position=servo_position,
                                rate=my_rate, direction=direction,
                                endstop_switch=endstop_switch)
