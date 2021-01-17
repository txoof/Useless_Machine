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
direction = 1

servo_max_rate = 30
servo_min_rate = 1

servo_position = servo_home
servo.angle = servo_position
# for angle in range(0, 180, 1):  # 0 - 180 degrees, 5 degrees at a time.
#     servo.angle = angle
#     time.sleep(0.01)
# for angle in range(180, 0, -1): # 180 - 0 degrees, 5 degrees at a time.
#     servo.angle = angle
#     time.sleep(0.01)





def map_range(a, b, s):
    (a1, a2), (b1, b2) = a, b
    return b1 + ((s - a1) * (b2 - b1) / (a2 - a1))

def set_servo(servo_position, rate=50, direction=1):
    '''
    move servo forward or backwards in steps proportional to the rate

    Args:
        rate(int): 1-100 - higher rates move in larger steps
        direction(0, 1): 0 anti clockwise, 1 clockwise
    '''

    add_angle = map_range((0, 100), (servo_min_rate, servo_max_rate), rate)
    servo_position = int((servo_position + add_angle) * direction)
    if servo_position > 180:
        print(f'position greater than 180 {servo_position}')
        servo_position = 180
    if servo_position < 0:
        print(f'position lessthan than 0 {servo_position}')
        servo_position = 0

    servo.angle = servo_position
    time.sleep(0.01)

    return servo_position





while True:
    if servo_position <= servo_home:
        direction = 1
        time.sleep(3)
    if servo_position >= servo_max:
        direction = -1
        time.sleep(3)



    servo_position = set_servo(servo_position=servo_position,
                                rate=10, direction=direction)

    print(servo_position, direction)


    # for angle in range(0, 180, 1):  # 0 - 180 degrees, 5 degrees at a time.
    #     servo.angle = angle
    #     time.sleep(0.05)
    # for angle in range(180, 0, -1): # 180 - 0 degrees, 5 degrees at a time.
    #     servo.angle = angle
    #     time.sleep(0.05)
