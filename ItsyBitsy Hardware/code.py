import board
import digitalio
from adafruit_debouncer import Debouncer

# physical pins
# limit switch physical pin
limitsw_phy = board.D9

# pin objects
limitsw_pin = digitalio.DigitalInOut(limitsw_phy)


# setup objects
limitsw_pin.direction = digitalio.Direction.INPUT
limitsw_pin.pull = digitalio.Pull.DOWN

limitsw = Debouncer(limitsw_pin)

limitsw.update()
limitsw_last = limitsw.value
while True:
    limitsw.update()
    # print(limitsw.value)
    if  limitsw.value != limitsw_last:
        print(f'limitsw statechange: {not  limitsw.value}')
        limitsw_last = limitsw.value
