-- LuaJIT process to extract run data from iMAR-type mapping files (iMAR, Memsense)
-- adds multiple run handling
-- refactored as a loadable Lua function

function tcodemem(fn, ...)

	local function to2comp24bit(val)
	-- Returns the two's complement of the 24bit value. val is the array with the 24bit data
		if val <= 8388608 then return val end
		return -(16777216 - val)
	end
		
	local function processParameters(param, ...)
		for i,v in ipairs{...} do
			if v == '-flip' then param.flipendian=true end
		end
		return param
	end

-- define the C structures for the analysis
	local structdefs = require("struct_mem")
	local summary_msg = ffi.new("C_mapping_summary_msg_t")	-- file structure information
	local imu_second = ffi.new("C_mapping_raw_data_t")			-- this is one second of mapping data

	local parameters = processParameters({flipendian=false}, ...)
	pp(parameters)

	local infile = assert(io.open(fn..'.dat', "rb"))
	infile:seek('set', ffi.sizeof("C_mapping_header_t"))	
	-- read in the summary headers
	local summaryList = {}
	local	summaryEntry = {}
	for i=1,4096 do 
		local summaryAddr = hex(infile:seek(), 4)
		local e = infile:read(ffi.sizeof("C_mapping_summary_msg_t"))
		ffi.copy(summary_msg, e, #e)
		if summary_msg.summary_header == 0xAC then
			if summary_msg.status_type == 0x04 then
				summaryEntry = {start={}, finish={}}
				summaryEntry.runStart_addr = summaryAddr
				summaryEntry.data_start_addr = hex(summary_msg.next_empty_sector * 512 + 0x200, 4) -- The 512 bytes per sector is an assumption, could be larger for modern SD/CF cards
				summaryEntry.odo_a = nil
				summaryEntry.odo_b = nil
			end
			if summary_msg.status_type == 0x0D then
				summaryEntry.start.latitude = summary_msg.gps_time.latitude
				summaryEntry.start.longitude = summary_msg.gps_time.longitude
				summaryEntry.start.altitude = summary_msg.gps_time.altitude
				summaryEntry.start.year = summary_msg.gps_time.year
				summaryEntry.start.month = summary_msg.gps_time.month
				summaryEntry.start.day = summary_msg.gps_time.day
				summaryEntry.start.hour = summary_msg.gps_time.hour
				summaryEntry.start.minute = summary_msg.gps_time.minute
				summaryEntry.start.second = summary_msg.gps_time.second
				summaryEntry.start.hrdate = string.format([[%02d:%02d:%02d %02d/%02d/%4d]], summaryEntry.start.hour, 
																		summaryEntry.start.minute, summaryEntry.start.second, 
																		summaryEntry.start.month, summaryEntry.start.day, 
																		summaryEntry.start.year)
			end
			if summary_msg.status_type == 0x0E then 
				summaryEntry.finish.latitude = summary_msg.gps_time.latitude
				summaryEntry.finish.longitude = summary_msg.gps_time.longitude
				summaryEntry.finish.altitude = summary_msg.gps_time.altitude
				summaryEntry.finish.year = summary_msg.gps_time.year
				summaryEntry.finish.month = summary_msg.gps_time.month
				summaryEntry.finish.day = summary_msg.gps_time.day
				summaryEntry.finish.hour = summary_msg.gps_time.hour
				summaryEntry.finish.minute = summary_msg.gps_time.minute
				summaryEntry.finish.second = summary_msg.gps_time.second
				summaryEntry.finish.hrdate = string.format([[%02d:%02d:%02d %02d/%02d/%4d]], summaryEntry.finish.hour, 
																		summaryEntry.finish.minute, summaryEntry.finish.second, 
																		summaryEntry.finish.month, summaryEntry.finish.day, 
																		summaryEntry.finish.year)
			end
			if summary_msg.status_type == 0x05 then
				summaryEntry.runEnd_addr = summaryAddr
				summaryEntry.data_end_addr = hex(summary_msg.next_empty_sector * 512 + 0x200, 4) -- The 512 bytes per sector is an assumption, could be larger for modern SD/CF cards
				table.insert(summaryList, summaryEntry);
			end
		end
	end
-- Catch strange files that do not have good summary information
	if #summaryList == 0 then
		summaryEntry.data_start_addr = 0x00200200
		summaryEntry.data_end_addr = 0xFFFFFFFF
		table.insert(summaryList, summaryEntry);
	end
-- 	print(infile:seek())
	print('There are ' .. #summaryList .. ' runs in this file.')
	
	for runNumber,runData in ipairs(summaryList) do
-- Skip to the start of the data
		print("Start run #" .. runNumber)
		infile:seek("set", tonumber(runData.data_start_addr))
		local hour = 0
		local t = nil
		local f=""
		local cp = 0
		local done = false
		local memloc = 0
		local temp = 0
	
		while done == false do
			hour = hour + 1
-- Open a new output file for the run
			local outfile = assert(io.open(fn.."_"..runNumber.."_"..hour..".txt", "w"))
			outfile:write('stop,mem,counter,time,phiX,phiY,phiZ,vX,vY,vZ\n')
			
-- Output the run data until end of run reached
			for i=1,3600 do
-- read in 1 second IMU data block and output
				local offset = infile:seek()
				f = infile:read(ffi.sizeof(imu_second))
				cp = infile:seek()
-- EOF check
				done = done or (not f)
-- Check to see if overran the next run data
				done = done or (cp > tonumber(runData.data_end_addr))
				if done == true then break end
-- Process the data into the output format
				ffi.copy(imu_second, f, #f)
				for i=0,399 do
-- Clear out the old packet data
					t = {}
-- Parse the data into Lua table for use
					memloc = ffi.offsetof(imu_second, 'imu_line') + (i * ffi.sizeof('C_imu_line_t')) + offset
					if parameters.flipendian then
						temp = imu_second.imu_line[i].packetHeader
						temp = bit.rshift(bit.bswap(temp),16)
						t.packetHeader = temp
					else
						t.packetHeader = imu_second.imu_line[i].packetHeader
					end
					t.Address = imu_second.imu_line[i].Address
					t.Control = imu_second.imu_line[i].Control
					t.aX = imu_second.imu_line[i].accel_z_increment.data
					t.aY = imu_second.imu_line[i].accel_y_increment.data
					t.aZ = imu_second.imu_line[i].accel_x_increment.data
					t.pX = imu_second.imu_line[i].gyro_z_increment.data
					t.pY = imu_second.imu_line[i].gyro_y_increment.data
					t.pZ = imu_second.imu_line[i].gyro_x_increment.data
					t.imu_status = bit.tohex(imu_second.imu_line[i].imu_status,4)
					t.crc = bit.tohex(imu_second.imu_line[i].crc,4)
					t.stop = bit.tohex(imu_second.imu_line[i].stop,4)
					t.packetFooter = bit.tohex(imu_second.imu_line[i].packetFooter,4)
					t.odo0 = imu_second.imu_line[i].odo0
					t.timestamp = imu_second.imu_line[i].timestamp -- looks like ticks of a 65536 clock
					t.odo1 = imu_second.imu_line[i].odo1					
-- Scale the kinematic data. Need to rotate the data into the Memsense reference frame - z->x, y->y, -x->z
					t.dVx = to2comp24bit(imu_second.imu_line[i].accel_x_increment.data) * 1.5258789e-6 -- 0.05 / 2^15
					t.dVy = to2comp24bit(imu_second.imu_line[i].accel_y_increment.data) * 1.5258789e-6 -- 0.05 / 2^15
					t.dVz = to2comp24bit(imu_second.imu_line[i].accel_z_increment.data) * 1.5258789e-6 -- 0.05 / 2^15 - there is no sign change to keep directions consistent
					t.dTHx = to2comp24bit(imu_second.imu_line[i].gyro_x_increment.data) * 4.84813271605e-7 -- 0.1 arcseconds to radians
					t.dTHy = to2comp24bit(imu_second.imu_line[i].gyro_y_increment.data) * 4.84813271605e-7 -- 0.1 arcseconds to radians
					t.dTHz = to2comp24bit(imu_second.imu_line[i].gyro_z_increment.data) * 4.84813271605e-7 -- 0.1 arcseconds to radians				
	-- Check packet footer (misalignment in the data)
					done = done or (t.packetFooter ~= 'a521')
					if done == true then break end
	-- output the formatted data
-- 					outstring = string.format('%s,%d,%d,%d,%e,%e,%e,%e,%e,%e\n',t.stop,memloc,t.packetHeader,t.timestamp,t.dTHx,t.dTHy,t.dTHz,t.dVx,t.dVy,t.dVz)		
					outstring = string.format('%s,%d,%s,%s,%e,%e,%e,%e,%e,%e\n',t.stop,memloc,t.packetHeader,t.timestamp,t.dTHx,t.dTHy,t.dTHz,t.dVx,t.dVy,t.dVz)		
					outfile:write(outstring)
					t = nil
				end -- sample
				if done == true then break end
			end -- second
	-- Close the output
			outfile:close()
			print("  Hour " .. hour .. " processed.")
		end -- hour
	end -- runs
	
	infile:close()
end