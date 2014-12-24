local lanes = require "lanes".configure()
local linda = lanes.linda()
local m = lanes.require "dkjson"

local json = require ("dkjson")
local socket = require("socket")
local gpio = require("GPIO") -- requires run with root privilege

local RESOLUTION = 1 -- set to number of meters at which to change odo state

-- This starts the required GPS services
os.execute("sudo gpsd /dev/ttyUSB0")

-- Append data to the output fie to avoid erasing data
local filename = '/home/pi/mylua/gps_odo.txt'
local outfile = io.open(filename, 'a+')
outfile:write('GPS log data: time, lat, lon, m/s, mode\n')

gpio.setmode(gpio.BCM)
gpio.setwarnings(false)
gpio.setup(18, gpio.OUT, gpio.LOW)
gpio.setup(23, gpio.OUT, gpio.LOW)
gpio.setup(25, gpio.IN)

local function updateVelocity()
	local f = assert(io.popen("gpspipe -w -l","r"))
	while true do
		local buf = f:read("*l")
 		local obj, pos, err = json.decode (buf, 1, nil)
 		if obj.class == "TPV" then -- this updates the frequency of the PWM
 			linda:set("time", obj.time)
 			linda:set("lat", obj.lat)
 			linda:set("lon", obj.lon)
 			linda:set("speed", obj.speed)
 			linda:set("new", true)
 		end
	end
end

local producer = lanes.gen("*", updateVelocity)()

local t1, t2
local elapsed = 0
local pinstate = false
local delta = 20

linda:set("new", false)
t1 = socket.gettime()
while true do
-- loop for the desired time or drop out after one second
	t2 = socket.gettime()
	elapsed = t2 - t1
	if elapsed >= delta then
		if pinstate then gpio.output(18, gpio.HIGH) else gpio.output(18, gpio.LOW) end			
		pinstate = not pinstate	
		t1=t2
	end

	local update = linda:get("new")
	if update then
		gpio.output(23, gpio.HIGH)
		local t, lat, lon, speed
		t = linda:get("time")
		lat = linda:get("lat")
		lon = linda:get("lon")
		speed = linda:get("speed")
		linda:set("new", false)			
		delta = RESOLUTION / speed -- this is the time to the next pulse
		outfile:write(string.format("%s,%.6f,%.6f,%.1f\n", t, lat, lon, speed)) -- velocity in m/s
		outfile:flush()
		print(t)
		gpio.output(23, gpio.LOW)
	end
	
	status = gpio.input(25)
	if status == false then break end
	
end

print('Closing down program')
outfile:close()
gpio.output(18, gpio.LOW)
gpio.output(23, gpio.LOW)
gpio.cleanup()
os.execute("sudo killall gpsd")
print('All done')
