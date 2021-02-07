import board
import digitalio
import time
import pulseio
import neopixel



from adafruit_debouncer import Debouncer


##### CONSTANTS  #####
# shutoff timeout (seconds)
SHUTDOWN_TIMEOUT = 10

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

# NeoPixel driver PIN
PIXEL_PWM_PHY = board.A1
NUM_PIX = 7
PIX_BRIGHT_MAX = 1
PIX_BRIGHT_MIN = 0.01
RED = (255, 0, 0)
YELLOW = (255, 150, 0)
GREEN = (0, 255, 0)
CYAN = (0, 255, 255)
BLUE = (0, 0, 255)
PURPLE = (180, 0, 255)
ORANGE = (255, 128, 0)
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

# Attack routines
## TODO:  move to external file
att_peek_a_boo = [(62, .3, None), (None, None, 1),
              (HOME_LOW+2, .7, None), (None, None, .5),
              (62, .3, None), (None, None, 1),
              (HOME_LOW+2, .7, None), (None, None, .5),
              (HOME_HIGH-10, .6, None),
              (HOME_HIGH, .1, None)]

att_standard = [(90, .8, None),
                   (110, .7, None),
                   (HOME_HIGH - 15, .7, None),
                   (HOME_HIGH, .1, None)]
att_array = [att_peek_a_boo, att_standard]

att_color = [(90, .8, None, ORANGE),
                   (110, .7, None, ORANGE),
                   (HOME_HIGH - 15, .7, None, RED),
                   (HOME_HIGH, .1, None, RED)]

ret_standard = [(150, .6, None),
                (70, .6, None),
                (60, .4, None),
                (50, .2, None),
                (HOME_LOW, .05, None),
                (None, None, 0.25)]

ret_aggressive = [(150, .9, None),
               (70, .9, None),
               (50, .6, None),
               (HOME_LOW, 0.5, None),
               (None, None, 0.25)] # all retreat programs need this at the end to ensure it stops



attack_program = att_standard
retreat_program = ret_aggressive
attack = None

current_angle = HOME_LOW + 1

color = BLACK
##### /GLOBALS #####

# make sure the arm is parked to start
go_to_angle(current_angle)
time.sleep(.1)

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
        # reset the shutdown timer
        shutdown_timer = time.monotonic()
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
        msg = '**********ATTACK!**********'
        attack = True
    elif direction_switch.value == True and limit_switch.value == False:
        msg = '**********RETREAT!**********'
        attack = False
    else:
        msg = 'none'
        attack = None

    if attack is not None:
        if heart_beat(1):
            print(msg)

    # if direction_switch.value == False:
    #     print('**********ATTACK!**********')
    #     attack = True
    #     program = attack_program
    # elif direction_switch.value == True and limit_switch.value == False:
    #     print('**********RETREAT!**********')
    #     # OOPS! This should likely be attack =- TRUE for find index
    #     # attack_index = find_index(current_angle=current_angle,
    #     #                           program=attack_program, attack=True)
    #     attack = False
    #     program = retreat_program
    # else:
    #     attack = None
    #
    # if attack is not None:
    #     program_index = find_index(current_angle=current_angle,
    #                                program=program, attack=True)
    #     program_slice = retreat_program[program_index:]
    #
    #
    #     for i in program_slice:
    #         if i[2]:
    #             break_out = pause(i[2])
    #         else:
    #             current_angle, break_out = rotate_to_angle(current_angle=current_angle,
    #                                                        dest_angle=i[0],
    #                                                        attack=False,
    #                                                        speed=i[1])
    #         if break_out:
    #             print('breaking out of program "for" loop')
    #             break


    if limit_switch.value != limit_switch_last:
        print(f'limit switch state: {limit_switch.value}')
        limit_switch_last = limit_switch.value
    if direction_switch.value != direction_switch_last:
        print(f'direction switch state: {direction_switch.value}')
        direction_switch_last = direction_switch.value
