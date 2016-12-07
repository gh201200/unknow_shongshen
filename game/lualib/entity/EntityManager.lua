local skynet = require "skynet"
require "globalDefine"
local vector3 = require "vector3"
local IflyObj = require "entity.IflyObj"
local EntityManager = class("EntityManager")
local IPet = require "entity.Ipet"
function EntityManager:sendToAllPlayers(msg, val, except)
	if not except then except = "" end
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and  string.find(except, v.serverId)==nil and v.agent ~= nil  then
			skynet.call(v.agent, "lua", "sendRequest", msg, val)
		end
	end
end

function EntityManager:sendPlayer(player, msg, val)
	if player.agent then
		skynet.call(player.agent, "lua", "sendRequest", msg, val)
	end
end

function EntityManager:callAllAgents(msg, ...)
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and v.agent then
			skynet.call(v.agent, "lua", msg, ...)
		end
	end
end


function EntityManager:disconnectAgent(agent)
	for k, v in pairs(self.entityList) do
		if v.agent == agent then
			v.agent = nil
		end
	end
end

function EntityManager:sendToAllPlayersByCamp(msg, val, entity, except)
	if not except then except = "" end
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.player and  string.find(except, v.serverId)==nil  then
			if v:isKind( entity ) then
				skynet.call(v.agent, "lua", "sendRequest", msg, val)
			end
		end
	end

end

function EntityManager:ctor(p)
	--if you want to remove a entity, please set the entity's hp to 0
	--do not use table.remove or set nil
	self.entityList = {}
	g_entityManager = self
end

function EntityManager:dump()
	for i=#self.entityList, 1, -1 do
		local v = self.entityList[i]
		print('server id = '.. v.serverId)
		print('entity type = '.. v.entityType)
	end
end

function EntityManager:update(dt)
	for i=#self.entityList, 1, -1 do
		local v = self.entityList[i]
		if v.update then
			v:update(dt)		
			if v.entityType == EntityType.monster or v.entityType == EntityType.pet  then
				if v:getHp() <= 0 then		--dead, remove it
					table.remove(self.entityList, i)
				end
			elseif v.entityType == EntityType.flyObj then
				if v.isDead == true then
					table.remove(self.entityList, i)
				end	
			end
		end	
	end
end

function EntityManager:addEntity(entity)
	table.insert(self.entityList, entity)
end

function EntityManager:getEntity(serverId)
	for k, v in pairs(self.entityList) do 
		if v.serverId == serverId then
			return v		
		end
	end
	return nil
end

function EntityManager:getPlayerByPlayerId(account_id)
	for k, v in pairs(self.entityList) do 
		if v.entityType == EntityType.player and v.account_id == account_id then
			return v		
		end
	end
	return nil
end

function EntityManager:getMonsterCountByBatch(batch)
	local cnt = 0
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.monster and v.batch == batch then
			cnt = cnt + 1	
		end
	end
	return cnt
end

function EntityManager:getMonsterById(_id)
	local lt = {}
	for k, v in pairs(self.entityList) do
		if v.entityType == EntityType.monster and v.attDat.id == _id then
			table.insert(lt, v)
		end
	end
	return lt
end

function EntityManager:getCloseEntityByType(source, _type)
	local et = nil
	local minLen = 0xffffffff
	for k, v in pairs(self.entityList) do
		if v.entityType == _type and v ~= source then
			local ln = vector3.len(source.pos, v.pos)
			if minLen > ln then
				minLen = ln
				et = v
			end
		end
	end
	return et, minLen
end

function EntityManager:createFlyObj(srcObj,target,skilldata,extra1,extra2)
	local obj = IflyObj.create(srcObj,target,skilldata,extra1,extra2)	
	self:addEntity(obj)
end

function EntityManager:createPet(id,master,pos,isbody)
	isbody = isbody or 0
	local dir = vector3.create(0,0,0)
	local pet = IPet.new(pos,dir)
	pet.isbody = isbody
	g_entityManager:addEntity(pet)
	local pt = g_shareData.petRepository[id]
	pet.serverId = assin_server_id()	
	pet:init(pt,master)
	local _pet = {petId = id,serverId = pet.serverId,posx = 0,posz = 0,isbody = isbody,camp = master.camp,masterId = master.serverId}
	_pet.posx = math.ceil(pos.x * GAMEPLAY_PERCENT)
	_pet.posz = math.ceil(pos.z * GAMEPLAY_PERCENT)
	g_entityManager:sendToAllPlayers("summonPet",{pet = _pet } )
end
local function getEntityListByType(list,_type)

end
--获取施法目标的范围的目标
function EntityManager:getSkillSelectsEntitys(source,target,skilldata)
	local tgt = target 
	if skilldata.n32SkillTargetType == 0 then
		tgt = source
	end
	local typeTargets = {}
	for _ek,_ev in pairs(self.entityList) do
		--友方（包含自己）
		if skilldata.n32SelectTargetType  == 1 and source:isKind(_ev) == true then
			table.insert(typeTargets,_ev)
		--友方（除掉自己）
		elseif skilldata.n32SelectTargetType  == 2 and source:isKind(_ev) == true and source ~= _ev then
			table.insert(typeTargets,_ev)
		--敌方
		elseif skilldata.n32SelectTargetType  == 3 and source:isKind(_ev) == false then	
			table.insert(typeTargets,_ev)
		--除自己所有人
		elseif skilldata.n32SelectTargetType  == 4 and source ~= _ev then
			table.insert(typeTargets,_ev)
		--所有人
		elseif skilldata.n32SelectTargetType  == 5 then
			table.insert(typeTargets,_ev)
		end
	end
	local selects = {}
	if skilldata.szSelectRange[1] == 'single' then
		table.insert(selects,tgt)
	elseif skilldata.szSelectRange[1] == 'circle' then
		local radius = 	skilldata.szSelectRange[2]
		local target_uplimit = skilldata.szSelectRange[3]
		local select_mod = skilldata.szSelectRange[4]
		local tSelects = {}
		local tNum = 0
		for _k,_v in pairs(typeTargets) do
			local disVec = tgt.pos:return_sub(_v.pos)
			local disLen = disVec:length()
			if disLen <= radius then
				tNum = tNum + 1
				--tSelects[int_disLen] = _v
				table.insert(tSelects,{key = disLen,value = _v})
			end
		end
		if select_mod == 0 then
			table.sort(tSelects,function(a,b) return a.key > b.key end)
		else
			table.sort(tSelects,function(a,b) return a.key > b.key end)
		end
		local num  = 1 
		for _k,_v in pairs(tSelects) do
			if num <= target_uplimit or target_uplimit == -1 then
				table.insert(selects,_v.value)
				num  =  num + 1
			end
		end		
	--	print("#slects===",#selects)	
	elseif skilldata.szSelectRange[1] == 'sector' then
		
	elseif skilldata.szSelectRange[1] == 'rectangle' then
		local w = skilldata.szSelectRange[3]
		local h = skilldata.szSelectRange[2]
		local ret = {}
		local dir1 = target.pos:return_sub(source.pos)
		dir1:normalize()
		local dir2 = vector3.create(dir1.z,0,-dir1.x)
		local dot = {}
		dot[0] = source.pos:return_add( dir2:return_mul_num(w) )
		dot[3] = source.pos:return_sub( dir2:return_mul_num(w))
		local pos2 = source.pos:return_add( dir1:return_mul_num(h))
		dot[1] = pos2:return_add( dir2:return_mul_num(w) )
		dot[2] = pos2:return_sub( dir2:return_mul_num(w))
		for _k,_v in pairs(self.typeTargets) do
			local isIn = ptInRect(_v.pos,dot) 
			if isIn == true then
				table.insert(selects,_v)		
			end	
		end
	end
	return selects
end

--获取效果范围的目标
function EntityManager:getSkillAffectEntitys(source,selects,skilldata,extra)
	local affects = {}
	if skilldata.n32AffectTargetType == 0 then
		table.insert(affects,source)
		return affects
	end
	local typeTargets = {}
	for _ek,_ev in pairs(self.entityList) do
		--友方（包含自己）
		if skilldata.n32AffectTargetType  == 1 and source:isKind(_ev) == true then
			table.insert(typeTargets,_ev)
		--友方（除掉自己）
		elseif skilldata.n32AffectTargetType  == 2 and source:isKind(_ev) == true and source ~= _ev then
			table.insert(typeTargets,_ev)
		--敌方
		elseif skilldata.n32AffectTargetType  == 3 and source:isKind(_ev) == false then	
			table.insert(typeTargets,_ev)
		--除自己所有人
		elseif skilldata.n32AffectTargetType  == 4 and source ~= _ev then
			table.insert(typeTargets,_ev)
		--所有人
		elseif skilldata.n32AffectTargetType  == 5 then
			table.insert(typeTargets,_ev)
		end
	end
	--print("#typeTargets",#typeTargets)
	for _tk,_tv in pairs(typeTargets) do
		for _sk,_sv in pairs(selects) do
			--print("sv:",_sv.serverId,"tv",_tv.serverId)
			if skilldata.szAffectRange[1] == "single" and _sv == _tv then
				--print("111111111")
				table.insert(affects,_tv)
			elseif skilldata.szAffectRange[1] == "circle" then
				local disVec = _tv.pos:return_sub(_sv.pos)
				if disVec <= skilldata.szAffectRange[2] then
					table.insert(affects,_tv)
				end
			elseif skilldata.szAffectRange[1] == "sector" then
			--	print("get secotr",_sv.pos.x,_sv.pos.z)
				local center = _sv.pos
				local uDir = extra --附加参数方向
				local r = skilldata.szAffectRange[2]
				local theta = skilldata.szAffectRange[3]
				if ptInSector(_tv.pos,_sv.pos,uDir,r,theta) then
					table.insert(affects,_tv)
				end	
			end
		end 
	end
	return affects
end
return EntityManager.new()


