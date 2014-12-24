GPS
===

GPS odometer for Raspberry Pi

Two sets of Lua code here:
1) blinker2.lua works on a Raspberry Pi and uses JSON messages from a Garmin GPS to determine the pulse rate of a signal on a DIO port. Uses piped output from gpspipe to maintain stable messages from GPS driver. Sockets were not stable enough. Has an additional GPIO output to show that GPS is active and an input to terminate the program nicely.

