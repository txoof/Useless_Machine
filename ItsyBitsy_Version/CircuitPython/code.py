import board
import digitalio
import time
# import pulseio
import pwmio
import neopixel
from os import urandom
import random




from adafruit_debouncer import Debouncer


##### CONSTANTS  #####
# shutoff timeout (seconds)
SHUTDOWN_TIMEOUT = 10

# endstop positions for arm - determine these through trial and error
HOME_LOW = 43
HOME_HIGH = 168.5

# bottom limit switch for detecting when the arm is "home"
LIMIT_SWITCH_PHY = board.D9

# top direction switch DPDT switch
DIRECTION_SWITCH_PHY = board.D7

# servo PWM
SERVO_PWM_PHY = board.D10

# The latching relay is latched on by the DPDT switch
# After the program has sat idle, send +3v pulse to switch off relay and disconnect battery
RELAY_OFF_PHY = board.D13

# NeoPixel driver PIN
PIXEL_PWM_PHY = board.A1
NUM_PIX = 7
PIX_BRIGHT_MAX = 1
PIX_BRIGHT_MIN = 0.01
RED = (255, 0, 0)
RED_LT = (240,128,128)
ORANGE = (255, 128, 0)
ORANGE_LT = (255,69,0)
PINK = (255, 20, 147)
YELLOW = (255, 150, 0)
GREEN = (0, 255, 0)
GREEN_DK = (85,107,47)
CYAN = (0, 255, 255)
BLUE = (0, 0, 255)
NAVY = (0, 0, 128)
PURPLE = (180, 0, 255)
BLACK = (0, 0, 0)


# min and max duty cycle for PWM servo 0.5==0 degrees; 2.5==180 degrees
DUTY_MIN = 0.5 # 0 degrees
DUTY_MAX = 2.5 # 180 degrees

# min and max step size for rotating servo (degrees)
RESOLUTION_MIN = 0.04 # smallest angle steps to take when moving
RESOLUTION_MAX = 6 # largest angle steps to take when moving

# max, min angle
ANGLE_MIN = 0
ANGLE_MAX = 180

# soft landing program step for parking arm - this should always be the last
# step for a retreat program
SOFT_LANDING = (None, None, 0.25)

##### /CONSTANTS #####

def heart_beat(t=10):
    # simply outputs a tick to the console; helpful in debugging
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
# Debounce the lmit switch - this is critical
limit_switch = Debouncer(limit_switch_pin)

direction_switch_pin = digitalio.DigitalInOut(DIRECTION_SWITCH_PHY)
direction_switch_pin.direction = digitalio.Direction.INPUT
direction_switch_pin.pull = digitalio.Pull.DOWN
# debounce the DPDT direction switch on the outside of the box
direction_switch = Debouncer(direction_switch_pin)

# relay power-off pin 
relay_pin = digitalio.DigitalInOut(RELAY_OFF_PHY)
relay_pin.direction = digitalio.Direction.OUTPUT

# servo pwm OUTPUT
servo = pwmio.PWMOut(SERVO_PWM_PHY, duty_cycle=2**15, frequency=50)


# NeoPixel pwm OUTPUT
pixels = neopixel.NeoPixel(PIXEL_PWM_PHY, NUM_PIX, brightness=PIX_BRIGHT_MAX,
                           auto_write=False)
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

def rotate_to_angle(current_angle, dest_angle, attack, speed=0.08):
    '''rotate from current_angle to dest_angle at speed
    Args:
        current_angle (real): angle between SERVO_MIN and SERVO_MAX
        dest_angle (real): angle between SERVO_MIN and SERVO_MAX
        attack (bool): True - arm moves out (ccw), False - arm moves in (cw)
        speed (real): between 0 and 1
    '''
    def check_angle(angle):
        '''check if angle is out of range'''
        if angle > HOME_HIGH:
            angle = HOME_HIGH
        if angle < HOME_LOW:
            angle = HOME_LOW
        return angle

    # set the direction multiplier (positive is attack, negative retreat)
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
            breakout_msg = 'direction switch changed to "True" '

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
    '''pause for s seconds using monotonic timer (non blocking)
    change in direction_switch will break out of pause

    Args:
        s(real): seconds to pause

    Returns:
        bool: true if pause was interrupted by a switch state change
    '''
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

def find_index(current_angle, program, attack=True):
    '''find the first tuple who's 0th element is closest to current_angle

    Args:
        current_angle(real): angle of arm
        program(list of tuple): attack/retreat program
        attack(bool): true - search for first element that is >= current_angle
                      false - search for first element that is <= current_angle
    '''

    # for attack
    for i, val in enumerate(program):
        try:
            if attack:
                if val[0] >= current_angle:
                    break
            else:
                if val[0] <= current_angle:
                    break
        except TypeError:
            next

    return i



##### GLOBALS  #####
# Attack/Retreat routines
# Format: [(angle, speed, pause, color), ()]
# angle(real: 0-180),
# speed(real: 0.01-1),
# sec. pause(real)
# color(3-tuple of int)
## TODO:  move to external file


# coy
att_peek_a_boo = [(62, .3, None, PINK), (None, None, 1, PINK),
              (HOME_LOW+2, .7, None, CYAN), (None, None, .5, CYAN),
              (70, .3, None, PINK), (None, None, 1, PINK),
              (HOME_LOW+2, .7, None, CYAN), (None, None, .5, CYAN),
              (HOME_HIGH-10, .6, None, ORANGE),
              (HOME_HIGH, .1, None, ORANGE)]

# standard in and out
att_standard = [(90, .8, None, RED),
                   (110, .7, None, RED),
                   (HOME_HIGH - 15, .7, None, RED),
                   (HOME_HIGH, .1, None, RED)]

#hurry up and wait
att_hurry_wait = [(90, .9, None, GREEN),
                  (130, .9, None, GREEN),
                  (150, .9, None, GREEN),
                  (None, None, 4, GREEN_DK),
                  (HOME_HIGH, .1, None, GREEN)]


att_ever_slower = [(90, .3, None, RED),
                   (110, .2, None, RED_LT),
                   (130, .1, None, ORANGE_LT),
                   (145, .05, None, ORANGE),
                   (150, .02, None, PINK),
                   (HOME_HIGH, .01, None, PINK)]

att_array = [att_standard, att_peek_a_boo, att_hurry_wait, att_ever_slower]
att_dict = {'A.Standard': att_standard,
            'A.Peek A Boo': att_peek_a_boo,
            'A.Hurry Up and Wait': att_hurry_wait,
            'A.Ever Slower': att_ever_slower}


ret_standard = [(150, .6, None, BLUE),
                (70, .6, None, BLUE),
                (60, .4, None, BLUE),
                (50, .2, None, BLUE),
                (HOME_LOW, .05, None, BLUE),
                (None, None, .25)]

ret_ever_slower = [(150, .3, None, RED),
                   (145, .2, None, RED_LT),
                   (130, .1, None, ORANGE_LT),
                   (80, .05, None, ORANGE),
                   (50, .02, None, PINK),
                   # (HOME_LOW - 5, .01, None, PINK),
                   (HOME_LOW, .01, None, BLUE),
                   (None, None, .25)]

                   # (90, .3, None, RED),
                   # (110, .2, None, RED_LT),
                   # (130, .1, None, ORANGE_LT),
                   # (145, .05, None, ORANGE),
                   # (150, .02, None, PINK),
                   # (HOME_HIGH, .01, None, PINK)]

ret_just_checking = [(150, .5, None, BLUE),
                     (None, None, 1, NAVY),
                     (120, .5, None, BLUE),
                     (None, None, 1, NAVY),
                     (50, .8, None, BLUE),
                     (None, None, .5, NAVY),
                     (62, .3, None, RED),
                     (None, None, 1.25, NAVY),
                     (50, .1, None, BLUE),
                     (None, None, .5, NAVY),
                     (62, .3, None, RED),
                     (None, None, 1.25, NAVY),
                     (50, .1, None, BLUE),
                     (None, None, .5),
                     (100, .6, None, PINK),
                     (None, None, 1.25, NAVY),
                     (50, .4, None, BLUE),
                     (HOME_LOW, 0.05, None, BLUE)]

ret_aggressive = [(150, .9, None, NAVY),
               (70, .9, None, NAVY),
               (50, .6, None, NAVY),
               (HOME_LOW, 0.05, None, NAVY),
               (None, None, 0.25)] # all retreat programs need this at the end to ensure it stops



ret_array = [ret_standard, ret_aggressive, ret_just_checking, ret_ever_slower]
ret_dict = {'R.Standard': ret_standard,
            'R.Aggressive': ret_aggressive,
            'R.Just Checking, Don\'t Trust Ya': ret_just_checking,
            'R.Ever Slower': ret_ever_slower}

# Set default programs
att_default = 'A.Standard'
ret_default = 'R.Standard'

# set these equal to a particular program to override random choice
# set to `None` for random choice
att_test = None
ret_test = None

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
# arm is parked
is_parked = True
# timeout time expired
is_timedout = False

first_run = True

attack = None

# set initial angle
current_angle = HOME_LOW + 1

color = BLACK
seed = int.from_bytes(urandom(4), 'big')
##### /GLOBALS #####

# make sure the arm is parked to start
go_to_angle(current_angle)
time.sleep(.1)


while True:
    if heart_beat(1.5):
        if not is_shutdown:
            print(f'time to shutdown: {time.monotonic() - shutdown_timer - SHUTDOWN_TIMEOUT}')
        if is_shutdown:
            print('idle: relay off')
    limit_switch.update()
    direction_switch.update()

    is_parked = True if limit_switch.value and direction_switch.value else False
    is_timedout = True if time.monotonic() - shutdown_timer >= SHUTDOWN_TIMEOUT else False

    if is_parked == False:
        # reset the shutdown timer
        # shutdown_timer = time.monotonic()
        # reset the timout and shutdown bools
        is_timedout = False
        is_shutdown = False
    else:
        pixels.fill(BLACK)
        pixels.show()

    if is_parked and is_timedout and not is_shutdown:
        print('sending shutdown pulse')
        relay_pin.value = True
        time.sleep(1)
        relay_pin.value = False
        is_shutdown = True

    if direction_switch.value == False:
        seed = int.from_bytes(urandom(4), 'big')
        msg = '**********ATTACK!**********'
        attack = True

        # always run standard program on first run
        if first_run:
            print(f'first run after boot using default program: {att_default}')
            program = att_dict[att_default]
        else:
            # program = random.choice(att_array)
            program_name = random.choice(list(att_dict.keys()))
            print(f'PROGRAM: {program_name}')
            program = att_dict[program_name]


        # override with test attack
        if att_test:
            print('using test attack program')
            program = att_test
    elif direction_switch.value == True and limit_switch.value == False:
        seed = int.from_bytes(urandom(4), 'big')
        msg = '**********RETREAT!**********'
        attack = False

        if not program[-1] == SOFT_LANDING:
            program.append(SOFT_LANDING)
        # always run standard program on boot
        if first_run:
            print(f'first run after boot using default program: {ret_default}')
            program = ret_dict[ret_default]
            # set first_run to False
            first_run = False
        else:
            program_name = random.choice(list(ret_dict.keys()))
            print(f'PROGRAM: {program_name}')
            program = ret_dict[program_name]


        # override with test retreat
        if ret_test:
            print('using test attack program')
            program = ret_test
    else:
        msg = 'none'
        attack = None

    if attack is not None:
        print(msg)

        program_index = find_index(current_angle=current_angle,
                        program=program, attack=attack)
        program_slice = program[program_index:]

        for i in program_slice:
            # reset shutdown_timer while loop is running
            # shutdown_timer = time.monotonic()

            try:
                color = i[3]
            except IndexError:
                color = BLACK
            print(f'color: {color}')
            pixels.fill(color)
            pixels.write()
            # check if this program step is a pause step
            if i[2]:
                break_out = pause(i[2])
            else:
                current_angle, break_out = rotate_to_angle(current_angle=current_angle,
                                           dest_angle=i[0],
                                           attack=attack,
                                           speed=i[1])

            if break_out:
                print('breaking out of attack/retreat program')
                # reset the shutdown timer to start counting down after
                # program is executed
                shutdown_timer = time.monotonic()
                break

    if limit_switch.value != limit_switch_last:
        print(f'limit switch state: {limit_switch.value}')
        limit_switch_last = limit_switch.value
    if direction_switch.value != direction_switch_last:
        print(f'direction switch state: {direction_switch.value}')
        direction_switch_last = direction_switch.value
