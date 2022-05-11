--[[
	Copyright (c) 2012 Carreras Nicolas
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]
--- Lua INI Parser.
-- It has never been that simple to use INI files with Lua.
--@author Dynodzzo

local tinsert = table.insert

local LIP = {};

--- Returns a table containing all the data from the INI file.
--@param fileName The name of the INI file to parse. [string]
--@return The table containing all data from the INI file. [table]
function LIP.load(fileName, defaultsection)
	assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.')
	local file = assert(io.open(fileName, 'r'), 'Error loading file : ' .. fileName)
	local data = {};
	local section = defaultsection or "default";
	data[section] = {}
	data.lookup = {}

	local paramcomments = {}
	for line in file:lines() do
		-- Empty lines and comments are attaches to the following param.
		local comment = line:sub(1, 1)
		if(comment == '#') then tinsert( paramcomments, line ) end

		local param, value = line:match('^([%w|_]+)%s+=%s+(.+)$')
		if(param and value ~= nil)then
			if(tonumber(value))then
				value = tonumber(value);
			elseif(value == 'true')then
				value = true;
			elseif(value == 'false')then
				value = false;
			end
			if(tonumber(param))then
				param = tonumber(param)
			end

			local datapoint = { key = param, value = value, comments = paramcomments }
			tinsert(data[section], datapoint)
			data.lookup[param] = datapoint

			paramcomments = {}
		end
	end
	file:close()
	return data
end

--- Saves all the data from a table to an INI file.
--@param fileName The name of the INI file to fill. [string]
--@param data The table containing all the data to store. [table]
function LIP.save(fileName, data, section)
	assert(type(fileName) == 'string', 'Parameter "fileName" must be a string.');
	assert(type(data) == 'table', 'Parameter "data" must be a table.');
	local file = assert(io.open(fileName, 'w+b'), 'Error loading file :' .. fileName);
	local contents = '';
	section = section or "default"
	for s, param in pairs(data) do
		if(s == section) then 
			-- contents = contents .. ('[%s]\n'):format(section);
			for key, value in pairs(param) do
				contents = contents .. '\n'
				for i, comment in ipairs(value.comments) do 
					contents = contents .. ('%s\n'):format(tostring(comment));	
				end
				contents = contents .. ('%s = %s\n'):format(value.key, tostring(value.value));
			end
			contents = contents .. '\n';
		end
	end
	file:write(contents);
	file:close();
end

return LIP;