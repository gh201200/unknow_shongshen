--local transfrom = require "entity.transfrom"
local vector3 = require "vector3"
local transfrom = require "entity.transfrom"
local IflyObj = class("IflyObj" , transfrom)
local Map = require "map.Map"
require "globalDefine"

function IflyObj.create(...)
	return  IflyObj.new(...)
end

function IflyObj:ctor(src,tgt,skilldata,extra1,extra2)
	self.source = src
	self.target = tgt
	self.pos = vector3.new(0,0,0)
	self.pos:set(src.pos.x,0,src.pos.z)
	self.skilldata = skilldata	
	self.effectdata = g_shareData.effectRepository[skilldata.n32BulletId]
	self.dir = vector3.new(0,0,0)
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
        self.dir:sub(self.pos)
        self.dir:normalize()
	self.moveSpeed = self.effectdata.n32speed
	self.targets = {}
	self.lifeTime = self.effectdata.n32time / 1000.0
	self.entityType = EntityType.flyObj 
	self.radius = self.effectdata.n32Redius
	self.isDead = false
	self.flyDistance = 0    --飞行距离
	--链式弹道
	if self.skilldata.n32BulletType == 2 then
		self.lifeTime = 1 --链式弹道检测一次
		if extra1 == nil and extra2 == nil then
			self.linkIndex = 1
			self.caster = src
			self.parent = nil
		else
			self.caster = extra1 --施法者
			self.parent = extra2 --父弹道
			self.linkIndex = self.parent.linkIndex + 1
			print("linkIndex==",self.linkIndex)
		end
	end
	local r = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletId,effectTime = 0,flag = 0}
	r.posX = tostring(self.pos.x)
	r.posZ = tostring(self.pos.z)
	r.dirX = tostring(self.dir.x)
	r.dirZ = tostring(self.dir.z)
	if self.target:getType() ~= "transform" then
		r.acceperId = self.target.serverId
	end
--	print("r====",self.caster.serverId,self.source.serverId,self.target.serverId)
	g_entityManager:sendToAllPlayers("pushEffect",r)

end
local dst = vector3.new(0,0,0)	

function IflyObj:getTarget()
	return self.target
end

function IflyObj:setTarget(t)
	self.target = t
end
function IflyObj:update(dt)
	--普通弹道
	if self.skilldata.n32BulletType == 1 then
		self:updateTarget(dt)
	--链式弹道
	elseif self.skilldata.n32BulletType == 2 then
		self:updateLink(dt)	
	--碰撞体弹道
	elseif self.skilldata.n32BulletType == 4 then
		self:updateCollider(dt)
	else
		self:updateNoTarget(dt)
	end
end

local function isInParentLinkTarget(_link,tgt)
	if _link.target == tgt then return true end
	if _link.parent and isInParentLinkTarget(_link.parent,tgt) == true then return true end
	return false
end
local function deadParentLink(_link)
	if _link ~= nil then
		_link.isDead =  true
		deadParentLink(_link.parent)
	end
end
--链式弹道
function IflyObj:updateLink(dt)
	--推送给客户端特效
	if self.lifeTime <= 0 then return end
	self.lifeTime = self.lifeTime - dt
	local targets = {self.target}
	self.caster.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)
	--print("updateLink",self.skilldata.szAffectRange)
	local tgt = nil
	if self.linkIndex < self.skilldata.szAffectRange[3] then
	   for i=#g_entityManager.entityList, 1, -1 do
		local v = g_entityManager.entityList[i]
		if v:getType() ~= "transform" and self.caster:isKind(v) == false then
			local dis = self.source:getDistance(v)
			if isInParentLinkTarget(self,v) == false and self.skilldata.szAffectRange[2] >= dis then
				tgt = v
				break
			end
		end
	    end	
	end
	if tgt ~= nil then
		print("创建新的弹道")
		g_entityManager:createFlyObj(self.target,tgt,self.skilldata,self.caster,self)
	else
		--清除所有的父节点
		deadParentLink(self)	
	end
end
--碰撞弹道
function IflyObj:updateCollider(dt)
	dt = dt / 1000.0
	self.flyDistance  = self.flyDistance + self.moveSpeed * dt
	dst:set(self.dir.x, self.dir.y, self.dir.z)
	dst:mul_num(self.moveSpeed * dt)
	dst:add(self.pos)
	self.pos:set(dst.x,0,dst.z)
	local _kind = true
	local _bomb = false
	if self.skilldata.n32BulleTarget == 0 then _kind = false end --敌方
	
	if self.flyDistance >= self.skilldata.n32BulletRange then
		print("outof distance===")
		_bomb = true	
	end
	if _bomb == false then
		for i=#g_entityManager.entityList, 1, -1 do
			local v = g_entityManager.entityList[i]
			if v:getType() ~= "transform" then
				if self.source:isKind(v) == _kind then
					local dis  = self:getDistance(v)
					if dis <= self.radius then
						_bomb = true
						print("collider bomm",v.serverId)
						break
					end
				end
			end
		end
	end
	if _bomb == true then
		--推送爆炸特效	
		local d = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletId,effectTime = 0,flag = 1}
		g_entityManager:sendToAllPlayers("pushEffect",d)

		local r = {acceperId = 0,producerId = self.source.serverId,effectId = self.skilldata.n32BulletBombId,effectTime = 0,flag = 0}
		r.posX = tostring(self.pos.x)
		r.posZ = tostring(self.pos.z)
		r.dirX = tostring(self.dir.x)
		r.dirZ = tostring(self.dir.z)
		g_entityManager:sendToAllPlayers("pushEffect",r)
				
		local selects = { self }
		local targets = g_entityManager:getSkillAffectEntitys(self.source,selects,self.skilldata,self.dir)
		print("target===",#targets)
		self.source.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)
		self.isDead = true
	end
	
end

function IflyObj:updateNoTarget(dt)
	self.lifeTime = self.lifeTime - dt
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
        dst:add(self.pos)
	self.pos:set(dst.x, 0, dst.z)
	for i=#g_entityManager.entityList, 1, -1 do
                local v = g_entityManager.entityList[i]
		if v:getType() ~= "transform" then
			if self.targets[v.serverId] == nil and v.serverId ~= self.source.serverId and v.camp ~= self.source.camp then
				local dis = self:getDistance(v)
				if dis <= self.radius  then	
					--添加buff
					self.targets[v.serverId] = 1
					v.affectTable:buildAffects(self.source,self.skilldata.szTargetAffect)	
				end
			end				
		end
	end
	--print("--------------------------end-------------------------------------------------")
end

function IflyObj:updateTarget(dt)
	dt = dt / 1000.0
	if self.target == nil  then 
		self.isDead = true
		return 
	end
	self.dir:set(self.target.pos.x, 0, self.target.pos.z)
	self.dir:sub(self.pos)
        self.dir:normalize()
	dst:set(self.dir.x, self.dir.y, self.dir.z)
        dst:mul_num(self.moveSpeed * dt)
	dst:add(self.pos)
	self.pos:set(dst.x,0,dst.z)
	local dis = self:getDistance(self.target)
	if dis <= 0.1 then
		--触发效果
		local selects = {self.target}
		local targets = g_entityManager:getSkillAffectEntitys(self.source,selects,self.skilldata)
		self.source.spell:trgggerAffect(self.skilldata.szAffectTargetAffect,targets,self.skilldata)
		self.isDead = true
	end
end
return IflyObj
