# UM Development Notes

## Benchmarks
* 21.01.31 shutdown if arm is parked
* 21.01.30 Arm runs appropriate part of program on attack
* 21.01.30 Arm can pause
* 21.01.30 Arm can run forwards, backwards in same program
* 21.01.29 Arm can run variable speed programs
* 21.01.25 Arm runs backwards and forwards in response to switch
* 21.01.25 limit switches respected 

## To Do
- [ ] if switch is toggled too quickly, arm can get stuck agains the switch and never retreats - build in some sort of failsafe for this

## Goals
- [ ] write calibration routine for getting HOME_LOW and HOME_HIGH
- [ ] write variety of attack/retreat routines
- [x] arm can pause during program
- [x] arm runs appropriate part of attack/retreat program when state changes
- [ ] randomly select attack/retreat routine
- [ ] random seed based on internal processor temp
- [x] machine switches off after set interval in HOME_LOW
- [ ] mood lighting
