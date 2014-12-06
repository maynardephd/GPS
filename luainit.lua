_PROMPT="luajit->"

ser = require "ser"
serpent = require "serpent"
std = require "std"
pl = require "pl"
pretty = require "pl.pretty"

-- Get the base global variables so we can see what we added
basevars = {}
for k,v in pairs(_G) do
--   print("Global key", k, "value", v)
	basevars[k]=true
end

-- Everything after this will get listed as a non-base value

function whos()
	local varList = {}
	for k,v in pairs(_G) do
		if (basevars[k] == nil) then
			print('Global key: "'..k..'"->',v)
		end
	end
end

function fcns(param)
-- value of param:
--   table: use this list as the comparison list (find new functions)
--   number: suppress output
--   nil: use the initial list as the comparison list
	local compList = {}
	local showOutput = true
	local fcnList = {}
	
	if param then
		if type(param) == 'table' then compList = param end
		if type(param) == 'number' then showOutput = false end
	end
	for k,v in pairs(_G) do
		if (type(v)=='function') then
			if (basevars[k] == nil) and (compList[k] == nil) then fcnList[k] = true end
		end
	end
	if showOutput then
		local keys = {}
		print('**Function List:')
		for k,v in pairs(fcnList) do keys[#keys+1] = k end
		table.sort(keys)
		for k,v in ipairs(keys) do print('   ' .. v .. "()") end
	end
	return fcnList
end

function vars()
	local varList = {}
	print('**Variables List:')
	for k,v in pairs(_G) do
		if (type(v)~='function') and (basevars[k] == nil) then 
			table.insert(varList, k) 
		end
	end
	table.sort(varList)
	for _,v in ipairs(varList) do
		if type(_G[v]) == 'string' then print('  Variable: "' .. v .. '" is "' .. _G[v] .. '"')
			elseif type(_G[v]) == 'number' then print('  Variable: "' .. v .. '" = ' .. _G[v])
			elseif type(_G[v]) == 'table' then print('  Variable: "' .. v .. '" is a table')
			else print('  Variable: "' .. v .. '" = ' .. tostring(_G[v]))
		end
	end	
end

useser = function (a) print(ser(a)) end -- only for "nice" tables
serpf = function (a) print(serpent.dump(a)) end
serpl = function (a) print(serpent.line(a)) end
serpm = function (a) print(serpent.block(a)) end
pp = function (a) print(pretty.write(a)) end

cd = function (path) os.execute('cd '..path) end
pwd = function () os.execute('cd') end
ls = function () os.execute('dir') end

function freemem()
	print('Before free: ' .. collectgarbage("count") .. 'K used') 
	collectgarbage("collect")
	print('After free: ' .. collectgarbage("count") .. 'K used') 
end

function mem()
	print('Memory in use: ' .. math.floor(collectgarbage("count")) .. 'K') 
end

function hexstr(a, bytes) -- bits is nil return the shortest version
	return string.format('0x%s', bit.tohex(a, bytes))
end
hex = bit.tohex

function clearpkg(pkg)
	if type(pkg) == 'string' then
		pcall(loadstring('package.loaded.' .. pkg .. '=nil'))
	else
		print('**** FUNCTION USAGE: clearpkg(string)')
	end
end

function fcnload(name) -- stands for load function file
-- used to load function files either in local or SCRIPTS directory
	local fullName = name .. '.lua'
	local altName = LUA_SCRIPT_DIR .. '\\' .. name .. '.lua'
	local fn = ''
	local startList = fcns(0)

-- determine which file to use
	local f1 = io.open(fullName,"r")
	local f2 = io.open(altName,"r")
	if f1 then fn = fullName elseif f2 then fn = altName else fn = nil end
	if f1 then io.close(f1) end
	if f2 then io.close(f2) end

	if not fn then	
		print('No file "' .. name .. '" located locally of in scripts directory.')
	else
		print('Loading "' .. fn .. '"...')		
		local f,err = loadfile(fn)
		if f then
			f()
			fcns(startList)
			print("Functions loaded.")
		else 
			print("Compile error: " .. err)
		end
	end

end

function scandir(directory)
-- returns the files in the directory specified - wildcards are allowed
	directory = directory or '.'
  local i, t = 0, {}
  for filename in io.popen('dir "'..directory..'" /b'):lines() do
      i = i + 1
      t[i] = filename
  end
  return t
end