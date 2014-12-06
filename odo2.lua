local socket = require("socket")
local json = require ("dkjson")
local gpio = require("GPIO")
local wpi = require("wpi")

local fn = 'gps_odo.txt'
local outfile = io.open(fn, 'w')
outfile:write('GPS log data: time, lat, lon, m/s, mode\n')

-- Connect to the GPS
local tcp = socket.connect('127.0.0.1', 2947)
tcp:send('?WATCH={"enable":true,"json":true}\r\n')
tcp:settimeout(0, 't')

gpio.setmode(gpio.BCM)
gpio.setup(18, gpio.OUT, gpio.LOW)

-- Set up the PWM output

local period = 1e6 -- 10msec
local d = 0
local period_start = 0

while true do

	local buf, status, partial = tcp:receive('*l')   -- this is blocking, there are two reads per second

	d = wpi.micros()
	if (d-period_start) > period then
		period_start = d
		gpio.output(18, gpio.HIGH)
		wpi.delay(1)
		gpio.output(18, gpio.LOW)
	end
	
	if status ~= 'timeout' then
		local obj, pos, err = json.decode (buf, 1, nil)
		if obj.class == "TPV" then -- this updates the frequency of the PWM
	
			outfile:write(obj.time..',', string.format("%.5f,%.5f,%.3fm/s", obj.lat, obj.lon, obj.speed), ','..obj.mode..'\n')
			outfile:flush()
			
			period = (1 / obj.speed) * 1e6 -- this gives microseconds/meter
			if period > 2e6 then period = 2e6 end
		end
	end

	d = wpi.micros()
	if (d-period_start) > period then
		period_start = d
		gpio.output(18, gpio.HIGH)
		wpi.delay(1)
		gpio.output(18, gpio.LOW)
	end

end

gpio.cleanup()
outfile:close()
tcp:send('?WATCH={"enable":false}\r\n')
tcp:close()



