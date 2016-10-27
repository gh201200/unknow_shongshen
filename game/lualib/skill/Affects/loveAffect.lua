local Affect = require "skill.Affects.Affect"
local loveAffect = class("loveAffect",Affect)

function loveAffect:ctor(owner,source,data)
	self.super.ctor(self,owner,source,data)
	self.effectId = data[3] or 0
	self.effectTime = data[2] or 0
	--self.control = bit_or(AffectState.NoAttack,AffectState.NoSpell) 
	self.speed = 1 
end

function loveAffect:onEnter()
	self.super.onEnter(self)
	--self.owner.affectState = bit_or(self.owner.affectState,self.control)
	self.owner:setTargetVar(self.source)
	self.owner.targetPos = self.source
	if self.owner:getType() == "IMapPlayer"  then
		self.owner.triggerCast = true
		self.owner.ReadySkillId = self.owner:getCommonSkillId()
	end
	self.owner:setActionState(self.speed, ActionState.loved)
end

function loveAffect:onExec(dt)
	self.effectTime = self.effectTime - dt
	if self.effectTime < 0 then
		self:onExit()
	end
end

function loveAffect:onExit()
	--self.owner.affectState = bit_and(self.owner.affectState,bit_not(self.control))
	self.owner:stand()	
	self.super.onExit(self)
end

return loveAffect
