# ItsyBitsy Useless Machine

This useless machine runs off of an AdaFruit 5V ItsyBitsy running CircuitPython. It's got sassy, random responses, neo-pixle bling and it's just as useless and **AWESOME** as all the rest.

To get the 

This design runs off of 4xAA batteries and uses a latching relay and some clever double pull double throw magic to completely disconnect the battery when it's not in use so it won't chooch through your AAs like crazy.

If you want to have your own PCB milled, you can also find the Eagle design files. I have a few extra PCBs sitting around for anyone that's interested. I'll ship them to the first lucky people that ask.

![Useless Machine!](../useless_machine_in-action.jpg)

## Code

Find the code and necessary libraries in the [CircuitPython](./CircuitPython/) directory

### Pinouts

```python
# bottom limit switch (micros switch)
LIMIT_SWITCH_PHY = board.D9
# top direction switch (dpdt)
DIRECTION_SWITCH_PHY = board.D7
# servo PWM
SERVO_PWM_PHY = board.D10
# send +3v pulse to switch off relay
RELAY_OFF_PHY = board.D13
# NeoPixel driver PIN
PIXEL_PWM_PHY = board.A1
```
## Bill of Materials

[Eagle CSV version](./circuit/UM%20V2%20ItsyBitsy.csv)

|Part |Value|Device |Package |Description|ALLIED_NUMBER|DESCRIPTION |HEIGHT|MANUFACTURER_NAME|MANUFACTURER_PART_NUMBER|
|-|-|-|-|-|-|-|-|-|-|
|LED1 |LTST-C930KRKT|LTST-C930KRKT|LTSTC930KRKT|LED, Red LTST-C930KRKT, Lite-On 631 nm 3125 (1210) SMD package | |LED, Red LTST-C930KRKT, Lite-On 631 nm 3125 (1210) SMD package|2.5mm |Lite-On|LTST-C930KRKT |
|K1 |DS2E-SL2-DC5V|DS2E-SL2-DC5V|DS2ESL2DC5V |Low Signal Relays - PCB 2A 5VDC DPDT LATCHING PCB|70158678 |Low Signal Relays - PCB 2A 5VDC DPDT LATCHING PCB |10.2mm|Panasonic|DS2E-SL2-DC5V |
|C1 |470|CPOL-USE2,5-6E |E2,5-6E |POLARIZED CAPACITOR, American symbol | ||| ||
|D1 |1N4004 |1N4004 |DO41-10 |DIODE| ||| ||
|DIRECTIONSW|Direction Sw |CONN_04POLAR |MOLEX-1X4 |Multi connection point. Often used as Generic Header-pin footprint for 0.1 inch spaced/style header connections| ||| ||
|EXTPOWER |Limit Sw |CONN_02POLAR |MOLEX-1X2 |Multi connection point. Often used as Generic Header-pin footprint for 0.1 inch spaced/style header connections| ||| ||
|LIMITSW|Limit Sw |CONN_02POLAR |MOLEX-1X2 |Multi connection point. Often used as Generic Header-pin footprint for 0.1 inch spaced/style header connections| ||| ||
|NEOPIXEL |7x |CONN_03POLAR |MOLEX-1X3 |Multi connection point. Often used as Generic Header-pin footprint for 0.1 inch spaced/style header connections| ||| ||
|Q1 |2N3904 |MPS2222A-NPN-TO92-CBE|TO92-CBE|NPN Transistror| ||| ||
|R1 |100|R-US_M1206 |M1206 |RESISTOR, American symbol| ||| ||
|R2 |220|R-US_M1206 |M1206 |RESISTOR, American symbol| ||| ||
|SERVO|1051 M |CONN_03POLAR |MOLEX-1X3 |Multi connection point. Often used as Generic Header-pin footprint for 0.1 inch spaced/style header connections| ||| ||
|U$1|ITSYBITSY3V|ITSYBITSY3V|ITSYBITSY3V |AdaFruit ItsyBitsy M4 3V | ||| ||

## Eagle Files

Find the eagle files in the [circuit](./circuit/) folder.

I've had lots of success working with [OSH Park](https://oshpark.com/). Their instructions are incredibly clear and the service is great.
