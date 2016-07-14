local skynet = require "skynet"
local Ientity = require "entity.Ientity"
local vector3 = require "vector3"
local Buff = require "skill.Buff"


local IMapPlayer = class("IMapPlayer", Ientity)


function IMapPlayer:ctor()
	IMapPlayer.super.ctor(self)

	self.playerId = 0		--same with IAgentPlayer.playerId
	self.serverId = 0
	self.pos.x = 0
	self.pos.y = 0
	self.pos.z = 0
	self.dir:set(0, 0, 0)
	self.moveSpeed = 0
	self.entityType = EntityType.player
	self.agent = 0
	self.castSkillId = 0
	print("IMapPlayer:ctor()")
end

function IMapPlayer:update(dt)
	IMapPlayer.super.update(self,dt)
	self:move(dt)
end

function IMapPlayer:move(dt)
	dt = dt / 1000		--second
	if self.moveSpeed <= 0 then return end

	self.dir:set(self.targetPos.x, self.targetPos.y, self.targetPos.z)
	self.dir:sub(self.pos)
	self.dir:normalize(self.moveSpeed * dt)
	

	local dst = self.pos:return_add(self.dir)
	--check iegal
	
	--move
	self.pos:set(dst.x, dst.y, dst.z)
	if IS_SAME_GRID(self.targetPos,  dst) then
		self:stand()
	end

	--advance move event stamp
	self:advanceEventStamp(EventStampType.Move)
end

function IMapPlayer:init()
	local baseBuffId = 100000001
	local colorBuffId = 200000001

	self:addBuff(baseBuffId, 1, self, Buff.Origin.Equip) 
	self:addBuff(colorBuffId, 1, self, Buff.Origin.Equip)
	
	self.buffTable:calculateStats(true)
	
	self:addBuff(300000001, 1)
	self.Stats:dump()
	self.buffTable:dump()
end

return IMapPlayer

