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
RESOLUTION_MAX = 7 # largest angle steps to take when moving

ANGLE_MIN = 0
ANGLE_MAX = 180

HOME_LOW = 44.5
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


def rotate_to_angle(current_angle, dest_angle, attack, speed=0.08, pause=0):
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

    # set the direction multiplier
    direction = 1 if current_angle < dest_angle else -1

    break_out = False

    breakout_msg = None

    step_size = map_range((0, 1), (RESOLUTION_MIN, RESOLUTION_MAX), speed)
    steps = int(abs((current_angle-dest_angle)/step_size))

    print(f'ROTATE to {dest_angle}; speed: {speed}')

    for i in range(0, steps+1):
        limit_switch.update()
        direction_switch.update()
        # print(f'direction: {direction}\nattack: {attack}\ndirection_switch: {direction_switch.value}\n')

        if direction == 1 and attack == True and direction_switch.value == True:
            break_out = True
            breakout_msg = 'direction switch changed to "true" '

        if direction == -1 and attack == False and direction_switch.value == False:
            break_out = True
            breakout_msg = 'direction switch changed to "False"'

        if direction == -1 and limit_switch.value == True:
            break_out = True
            breakout_msg = 'bottom limit siwtch hit'


        if break_out:
            print(f'{breakout_msg}')
            break

        else:
            current_angle = current_angle + (step_size * direction)

            # if over-run in positive or negative, set to max or min as appropriate
            current_angle = check_angle(current_angle)
            servo.duty_cycle = angle_to_duty(current_angle)

    current_angle = check_angle(current_angle)
    print('')
    return current_angle, break_out

def pause(s):
    t = time.monotonic()
    limit_switch.update()
    direction_switch.update()

    direction_switch_current = direction_switch.value
    break_out = False
    breakout_msg = None

    print(f'pausing for {s} seconds')
    while time.monotonic() - t < s:
        limit_switch.update()
        direction_switch.update()

        if direction_switch.value != direction_switch_current:
            breakout_msg = 'user changed switch, pause canceled'
            break_out = True

        if break_out:
            print(breakout_msg)
            break

    return break_out

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
# servo.duty_cycle = angle_to_duty(HOME_LOW+10)
go_to_angle(HOME_LOW-.5)
# servo.duty_cycle = angle_to_duty(HOME_LOW-.5)

# l = [50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 65, 70, 75, 80, 90, 100]
#
# for i in l:
#     print(f'angle: {i}')
#     go_to_angle(i)
#     time.sleep(1.5)

current_angle = HOME_LOW

peek_a_boo = [(62, .3, None), (None, None, 1.5),
              (HOME_LOW, .05, None), (None, None, 1.5),
              (62, .3, None), (None, None, 1.5),
              (HOME_LOW, .05, None), (None, None, 1.5),
              (HOME_HIGH, .8, None)]

# attack_program = [(100, 0.55, None), (125, 0.1, None), (150, 0.59, None), (HOME_HIGH, 0.1, None)]
attack_program = peek_a_boo
# attack_program = [(90, 0.99, None), (145, 0.1, None), (90, 0.3, None), (HOME_HIGH, 0.1, None)]
retreat_program = [(150, .1, None), (50, 0.1, None), (HOME_LOW, 0.01, None)]


while True:
    limit_switch.update()
    direction_switch.update()

    if not direction_switch.value:
        # reset current angle to max/min
        if current_angle >= HOME_HIGH:
            current_angle = HOME_HIGH
        else:
            print('**********attack!**********')
            # current_angle = rotate_to_angle(current_angle, HOME_HIGH)
            for i in attack_program:
                if i[2]:
                    break_out = pause(i[2])
                    if break_out:
                        break
                else:
                    current_angle, break_out = rotate_to_angle(current_angle=current_angle,
                                                               dest_angle=i[0],
                                                               attack=True,
                                                               speed=i[1])
                    if break_out:
                        break

    if not limit_switch.value and direction_switch.value:
        if current_angle <= HOME_LOW:
            current_angle = HOME_LOW
        else:
            print('**********retreat!**********')
            # current_angle = rotate_to_angle(current_angle, HOME_LOW)
            for i in retreat_program:
                if i[2]:
                    break_out = pause(i[2])
                    if break_out:
                        break
                else:
                    current_angle, break_out = rotate_to_angle(current_angle, i[0], False, i[1])
                    if break_out:
                        break

    if  limit_switch.value != limit_last:
        limit_last = limit_switch.value
        print(f'limit: {limit_switch.value}')

    if direction_switch.value != direction_last:
        direction_last = direction_switch.value
        print(f'direction: {direction_switch.value}')
