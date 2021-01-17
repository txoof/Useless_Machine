import time
import board
import pulseio
from adafruit_motor import servo

# create a PWMOut object on Pin D5.
pwm = pulseio.PWMOut(board.D10, duty_cycle=2 ** 15,  frequency=50)

# Create a servo object.
servo = servo.Servo(pwm)

while True:
    for angle in range(0, 180, 1):  # 0 - 180 degrees, 5 degrees at a time.
        servo.angle = angle
        time.sleep(0.05)
    for angle in range(180, 0, -1): # 180 - 0 degrees, 5 degrees at a time.
        servo.angle = angle
        time.sleep(0.04)
