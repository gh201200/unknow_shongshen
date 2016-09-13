#!ousr/bin/env lua
---Sample application to read a XML file and print it on the terminal.
--@author Manoel Campos da Silva Filho - http://manoelcampos.com
dofile("../3rd/LuaXMLlib/xml.lua")
dofile("../3rd/LuaXMLlib/handler.lua")
local filename = "./lualib/gamedata/SpawnMonster.xml"
local xmltext = ""
local f, e = io.open(filename, "r")
if f then
  xmltext = f:read("*a")
else
  error(e)
end
local xmlhandler = simpleTreeHandler()
local xmlparser = xmlParser(xmlhandler)
xmlparser:parse(xmltext)

local modolsTable = {}
for k, p in pairs(xmlhandler.root.info.item) do
	local tmpTb = {}
	for _i,_v in pairs(p)do
		if _i == "_attr" then
			tmpTb.id = tonumber(_v.id)
		else
			if string.match(_i,"n32%a+") then
				tmpTb[_i] = tonumber(_v)
			elseif string.match(_i,"b%a+") then
				if tonumber(_v) == 0 then
					tmpTb[_i] = false
				else
					tmpTb[_i] = true
				end
			else
				if _i == "szMonsterIds" then
					tmpTb[_i] = {}
					for w in string.gmatch(_v, "%d+") do
						table.insert(tmpTb[_i], tonumber(w))		
					end	
				elseif _i == "szPosition" then
					tmpTb[_i] = {}
					for _x, _z in string.gmatch(_v, "(%d+),(%d+)") do
						table.insert(tmpTb[_i], {x=_x,z=_z})
					end
				else
					tmpTb[_i] = _v
				end
			end 
		end
	end
	assert(#tmpTb.szMonsterIds==#tmpTb.szPosition, 'wrong spawn monster data: '..tmpTb.id)
	modolsTable[tmpTb.id] = tmpTb
end
--[[
for _k,_v in pairs(modolsTable) do
	print(_k,_v.id,_v)
end
]]
return modolsTable
