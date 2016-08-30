local demageAffect = require "skill.Affects.demageAffect"
local recoverAffect = require "skill.Affects.recoverAffect"
local dizzyAffect = require "skill.Affects.dizzyAffect"
local blinkAffect = require "skill.Affects.blinkAffect"
local invincibleAffect = require "skill.Affects.invincibleAffect"

local AffectTable = class("AffectTable")

function AffectTable:ctor(entity)
	self.owner = entity
	print("ttttttttttttttttttt",self.owner:getType())
	self.affects = {}
	self.affectStates = 0
end

function AffectTable:update(dt)
	self.affectStates = 0
	for i=#self.affects,1,-1 do
		if self.affects[i].status == "exec" then
			self.affects[i]:onExec(dt)
			self.affectStates = bit_or(self.affectStates,self.affects[i].affectState)
		elseif self.affects[i].status == "enter" then
			--self.affects[i].status = "exec"
			self.affects[i]:onEnter()			
		elseif self.affects[i].status == "exit" then
			print("Affect remove affect", i)
			table.remove(self.affects,i)
		end
	end
end
--能否控制
function AffectTable:canControl()
	if bit_and(self.affectStates,AffectState.dizzy) ~= 0 then return false end
	if bit_and(self.affectStates,AffectState.repel) ~= 0 then return false end
	if bit_and(self.affectStates,AffectState.jump) ~= 0 then return false end
	if bit_and(self.affectStates,AffectState.charge) ~= 0 then return false end
	return true
end

function AffectTable:addAffect(source,data)
	--print("addAffect",data)
	local aff = nil
	if data[1] == "ap" or data[1] == "str" or data[1] == "dex" or data[1] == "inte" then
		print("mmmmmmmmmmim111" ,self.owner:getType())
		aff = demageAffect.new(self.owner,source,data)
		print("mmmmmmmmmmm" ,self.owner:getType())
	elseif data[1] == "curehp" or data[1] == "curemp" then
		aff = recoverAffect.new(self.owner,source,data)
	elseif data[1] == "dizzy" then
		aff = dizzyAffect.new(self.owner,source,data)
	elseif data[1] == "blink" then
		aff = blinkAffect.new(self.owner,source,data)
	elseif data[1] == "invincible" then
		aff = invincibleAffect.new(self.owner,source,data)
	end
	if aff ~= nil then 
		if data[1] == "dizzy" or data[1] == "invincible" or data[1] == "repel" then
			--特殊效果 覆盖
			for i=#self.affects,1,-1 do
				if self.affects[i].data[1] == data[1] then
					self.affects[i]:onExit()
					table.remove(self.affects,i)
				end
			end
		end
		table.insert(self.affects,aff)
	 end
end

function AffectTable:buildAffects(source,dataStr)
	local tb = {}
	--print(dataStr)
	print("AffectTable:buildAffects",self.owner:getType())
	for v in string.gmatch(dataStr,"%[(.-)%]") do
		local data = {}
		for tp,vals in string.gmatch(v,"(%a+)%:(.+)") do
			vals = vals .. "," 
			table.insert(data,tp)
			for val in string.gmatch(vals,"(%d+)%,") do
				table.insert(data,tonumber(val))
			end 
		end
		self:addAffect(source,data) 
	end
	self.owner:advanceEventStamp(EventStampType.Affect)		
end


return AffectTable

