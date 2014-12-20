local socket = require("socket")
local json = require ("dkjson")
local gpio = require("GPIO") -- requires run with root privilege

local outfile = io.open('gps_odo.txt', 'w')
outfile:write('GPS log data: time, lat, lon, m/s, mode\n')

local pinstate = false

gpio.setmode(gpio.BCM)
gpio.setup(18, gpio.OUT, gpio.LOW)

-- Main loop processes the JSON GPS messages
local tcp = socket.connect('127.0.0.1', 2947)
tcp:send('?WATCH={"enable":true,"json":true}\r\n')
tcp:settimeout(0, 't')

local resolution = 1 -- set to number of meters at which to change odo state
local currentvelocity = 0
local accumdistance = 0
local i = 0
local t1, now = socket.gettime()
local start = socket.gettime()

while i < 20 do
-- compute the distance traveled since last loop at the current velocity
	now = socket.gettime()
	accumdistance = accumdistance + (now-t1) * currentvelocity
	t1=now
	
-- Signal passage of fixed distance
	if accumdistance >= resolution then
-- 		print(now-start, accumdistance)
		start = now
		
		if pinstate then gpio.output(18, gpio.HIGH) else gpio.output(18, gpio.LOW) end			
		pinstate = not pinstate	

		accumdistance = accumdistance - resolution
	end

-- look for the next speed update
	local buf, status, partial = tcp:receive('*l')   -- non-blocking, there are two reads per second
	if status ~= 'timeout' then
		local obj, pos, err = json.decode (buf, 1, nil)
		if obj.class == "TPV" then -- this updates the frequency of the PWM
			i = i + 1
			currentvelocity = obj.speed -- m/s
			currentvelocity = 29
 			outfile:write(string.format("%s,%.5f,%.5f,%.3f,m/s\n", obj.time, obj.lat, obj.lon, obj.speed))
--  			outfile:flush()			
		end
	end
end

tcp:send('?WATCH={"enable":false}\r\n')
tcp:close()
outfile:close()
gpio.output(18, gpio.LOW)
gpio.cleanup()
