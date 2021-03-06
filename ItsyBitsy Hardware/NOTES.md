# UM Development Notes

## Benchmarks
* 21.02.07 Tie colors to steps
* 21.02.07 Add colors
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
- [x] write variety of attack/retreat routines
- [x] arm can pause during program
- [x] arm runs appropriate part of attack/retreat program when state changes
- [x] randomly select attack/retreat routine
- [x] random seed based on os.urandom()
- [x] machine switches off after set interval in HOME_LOW
- [x] mood lighting
- [ ] more subtle mood lighting
- [ ] set timeout for program to complete -- if arm is stranded, try to park
