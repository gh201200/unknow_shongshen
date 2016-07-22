#!/usr/bin/env lua
---Sample application to read a XML file and print it on the terminal.
--@author Manoel Campos da Silva Filho - http://manoelcampos.com
dofile("../3rd/LuaXMLlib/xml.lua")
dofile("../3rd/LuaXMLlib/handler.lua")
local filename = "./lualib/gamedata/SkillDatas.xml"
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

local skillTable = {}
for k, p in pairs(xmlhandler.root.SkillDatas.info) do
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
				tmpTb[_i] = _v
			end 
		end
	end
	skillTable[tmpTb.id] = tmpTb
end


--skillEffect
filename = "./lualib/gamedata/SkillEffect.xml"
xmltext = ""
f, e = io.open(filename, "r")
if f then
  xmltext = f:read("*a")
else
  error(e)
end
xmlhandler = simpleTreeHandler()
xmlparser = xmlParser(xmlhandler)
xmlparser:parse(xmltext)
local skillEffectTable = {}
for k, p in pairs(xmlhandler.root.SkillEffect.info) do
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
				tmpTb[_i] = _v
			end 
		end
	end
	assert(skillTable[tmpTb.id])
	for _i,_v in pairs(tmpTb) do
		if _i ~= "id" then
			skillTable[tmpTb.id][_i] = _v
		end
	end
end
--[[
for _k,_v in pairs(skillTable) do
	print(_v)
end
]]
return skillTable