GPS
===

GPS odometer for Raspberry Pi

Two sets of ua code here:
1) odo2.lua works on a Raspberry Pi and uses JSON messages from a Garmin GPS to determine the pulse rate of a signal on a DIO port. Tried to make PWM work but just not fine enough timing.

2) imu*.lua & *mem.lua - these files process data from inertial motion units. tcode uses the FFI interface to C to processess binary files efficiently.
