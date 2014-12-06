-- This is a module to deal with all tings related to the Memsense IMU project

function imuhelp()
	print("function info(data)")
	print("function import(fn,parameters) -- reads a CSV file containing the IMU data")
end

function imuinfo(data, name)
	local m
	name = (name or "var")
	print("-><" .. name ..">")
	print("  |- header: " .. data.header)
	print("  |- matrix: [" .. #data.matrix .. " x " .. #data.matrix[1] .. "]")
end

function imuimport(fn)
-- assumes that the data starts at the 7th entry and is gx, gy, gz, ax, ay, az
-- data must be in the format S,#,#,#,#,#,#,#,#,#
-- "stop" marker, offset, rotation, 65536Hz timer counts, radians x, radians y, radians z, m/s x, m/s y, m/s z
-- accepts parameters to control whether scaling of the data is performed or not
	local data = {header='rotation, timer, gyro_x, gyro_y, gyro_z, accel_x, accel_y, accel_z', matrix={}} -- builds the data structure
	local f = {}
	local file = ''
	local newlines = {}
	local start = 0
	local i = 0
	
	f = assert(io.open(fn, 'r'))
	print('File "'..fn..'" opened.')
	file = f:read("*a") -- read the entire file in
	print('File "'..fn..'" loaded.')
	f:close()
-- Find all the newlines to pre-allocate memory
	i = 1
	while true do
		start,_ = string.find(file, "\n", start+1)
		if start == nil then break end
		if start >= #file then break end
		newlines[i] = start
		i=i+1
	end
	print(#newlines .. ' entries found in text') -- the header row (first row) is skipped
-- preallocate the memory for the data
	data.matrix[#newlines] = {0,0,0,0,0,0,0,0}
-- Process each of the lines and extract the desired data
	local q = {}
	local values = {}
	local fcn=string.find
	for j = 1,#newlines do
		data.matrix[j] = {0,0,0,0,0,0,0,0}
 		_,_,q[1],q[2],q[3],q[4],q[5],q[6],q[7],q[8] = fcn(file, '%w+,%d+,(%d+),(%d+),(%-*%d.%d+[eE][+-]%d+),(%-*%d.%d+[eE][+-]%d+),(%-*%d.%d+[eE][+-]%d+),(%-*%d.%d+[eE][+-]%d+),(%-*%d.%d+[eE][+-]%d+),(%-*%d.%d+[eE][+-]%d+)', newlines[j]+1)
 		for k,v in ipairs(q) do data.matrix[j][k] = tonumber(v) end
	end
	return(data)
end