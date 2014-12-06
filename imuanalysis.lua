-- Set of functions to analyze the imu data
function savemat(fn, mat)
	local f = io.open(fn,'w')
	for k,v in pairs(mat) do
		local str = k .. ',' .. table.concat(v,',') .. '\n'
		f:write(str)
	end
	io.close(f)
end

function matprn(data, start, stop)
-- takes a table which it assumes is an n by m matrix and prints it out as such
	start = (start or 1)
	stop = (stop or #data)
	for n = start,stop do
		print("[" .. n .. "]" , unpack(data[n]))
	end
end

function basicstats(data, col)
-- Computes mean and variance of the imudata kinametric data. Iterative methods are used to keep the 
-- errors from accumulating and to go fast
  local mean = 0
  local M2 = 0
  local variance = 0
  local max = -math.huge
  local min = math.huge

	assert(col <= #data.matrix[1], "imu column out of range")
	for n = 1,#data.matrix do
		local x = data.matrix[n][col]
		local delta = x - mean
		mean = mean + delta/n
    M2 = M2 + delta*(x - mean)
    if x < min then min = x end
    if x > max then max = x end
	end

	if #data.matrix > 2 then variance = M2/(#data.matrix - 1) end

	return mean, variance, max, min
end

function imuhisto(data, col, bincount)
-- returns the histogram of the data, suitable for plotting
-- compute the mean and the range and then divide into some number of bins
  local max = -math.huge
  local min = math.huge
  local counts = {}
  local histo = {}

  bincount = (bincount or 20)
	assert(col <= #data.matrix[1], "imu column out of range")
-- find the range of the data
	for n = 1,#data.matrix do
		local x = data.matrix[n][col]
    if x < min then min = x end
    if x > max then max = x end
	end
-- put data into the bins
	local step = (max - min) / bincount
	local floor = math.floor
	for n = 1,#data.matrix do
		local x = data.matrix[n][col]
		local b = floor((x - min) / step)
		local b = floor((floor(b*2)+1)/2)
		counts[b] = (counts[b] or 0) + 1
	end
-- assemble the return table
	for n = 0,bincount do histo[n] = {n , n * step + min, (counts[n] or 0)} end

	return histo
end

function summarizeDir(fn)
-- get all of the data files
	local fns = scandir(fn)
	local result = {}
-- import the imu file
	for k,v in pairs(fns) do
		local d = imuimport(v)
-- process the statistics for the columns
		for col=3,8 do
			print(#d.matrix[1], col)
			local mean, var, max, min = basicstats(d, col)
			print(mean,var,max,min)
			result[#result+1] = {v, col, mean, var, max, min}
		end
		d = nil
	end
	return result
end