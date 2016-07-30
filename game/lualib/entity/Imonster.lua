local Ientity = require "entity.Ientity"
local vector3 =require "vector3"
local HateList = require "ai.HateList" 
local NpcAI = require "ai.NpcAI"


local IMonster = class("IMonster", Ientity)


function IMonster:ctor()
	print("IMonster:ctor")
	IMonster.super.ctor(self,nil,nil)
	self.entityType = EntityType.monster	
	self.hateList = HateList.new()
	self.ai = NpcAI.new(self)
	register_class_var(self, "PreSkillData", nil)
	self.bornPos =  vector3.create()
end

function IMonster:init(mt)
	self.attDat = g_shareData.monsterRepository[mt.id]
	self.pos:set(mt.px, 0, mt.pz)
	self.bornPos:set(mt.px, 0, mt.pz)
	self:calcStats()
	self:setHp(self:getHpMax())
	self:setMp(self:getMpMax())
	self.HpMpChange = true
	self.StatsChange = true
end


function IMonster:update(dt)
	IMonster.super.update(self, dt)
	self.ai:update(dt)
end

function IMonster:calcStats()
	self:calcHpMax()
	self:calcMpMax()
	self:calcAttack()
	self:calcDefence()
	self:calcASpeed()
	self:calcMSpeed()
	self:calcAttackRange()
	self:calcRecvHp()
	self:calcRecvMp()
end

function IMonster:onDead()
	IMonster.super.onDead(self)	
end

function IMonster:preCastSkill()
	self:setPreSkilldata(self.attDat.n32Skill)
end

function IMonster:clearPreCastSkill()
	self:setPreSkillData(nil)
end



return IMonster
