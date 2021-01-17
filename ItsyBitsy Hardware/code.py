import time
import board
import pulseio
from adafruit_motor import servo

# create a PWMOut object on Pin D5.
pwm = pulseio.PWMOut(board.D10, duty_cycle=2 ** 15,  frequency=50)

# Create a servo object.
servo = servo.Servo(pwm)

# endstops for servo
servo_home = 0
servo_max = 180

servo_max_rate = 90
mervo_min_rate = 1

servo_position = servo_home
servo.angle = servo_home

def map_range(a, b, s):
    (a1, a2), (b1, b2) = a, b
    return b1 + ((s - a1) * (b2 - b1) / (a2 - a1))

def move_servo(rate=50, direction=1, angle=None):
    '''
    move servo forward or backwards in steps proportional to the rate

    Args:
        rate(int): 1-100 - higher rates move in larger steps
        direction(0, 1): 0 anti clockwise, 1 clockwise
        angle(int): move to given angle
    '''
    if angle:
        servo_position = add_angle
    else
        add_angle = map_range((0, 100), (servo_min_rate, servo_max_rate), rate)
        servo_position = servo_position + add_angle

    servo.angle = servo_position



while True:
    for angle in range(0, 180, 1):  # 0 - 180 degrees, 5 degrees at a time.
        servo.angle = angle
        time.sleep(0.05)
    for angle in range(180, 0, -1): # 180 - 0 degrees, 5 degrees at a time.
        servo.angle = angle
        time.sleep(0.05)
