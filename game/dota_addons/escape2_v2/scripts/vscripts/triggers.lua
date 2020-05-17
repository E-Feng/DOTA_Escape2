function OnStartSafety(trigger)
	local ent = trigger.activator
	if not ent then return end
	--print(ent:GetName(), " has stepped on trigger")
	if ent:IsRealHero() and ent:IsAlive() then
		ent.isSafe = true
		ent:SetBaseMagicalResistanceValue(100)
		return
	end
end

function OnEndSafety(trigger)
	local ent = trigger.activator
	print(ent:GetName(), " has stepped off trigger")
	if not ent then return end
	if ent:IsRealHero() and ent:IsAlive() and ent:GetAbsOrigin().z < 135 then
		print(ent:GetName(), " will be killed")
		ent.isSafe = false
		ent:SetBaseMagicalResistanceValue(25)
		return
	end
end

function UpdateCheckpoint(trigger)
	print("---------UpdateCheckpoint trigger activated--------")
	local trigblock = trigger.caller
	local position = trigblock:GetAbsOrigin()
	--print("Checkpoint was:", GameRules.Checkpoint)
	GameRules.Checkpoint = position
	local name = trigblock:GetName()
	local level = tonumber(string.sub(name, -1))
	if GameRules.CLevel ~= level then
		GameRules.CLevel = level
		print("Checkpoint updated to:", position)
		print("Level updated to:", level)
		local msg = {
			text = "Level " .. tostring(level) .. "!",
			duration = 5.0,
			style={color="white", ["font-size"]="96px"}
		}       
		if level < 7 then
			Notifications:TopToAll(msg)
			GameRules:SendCustomMessage("Level " .. tostring(level) .. "!", 0, 1)
		end
		if level > 1 and level < 7 then
			barebones:ReviveAll()
			barebones:RemoveAllSkills()
			barebones:CleanLevel(level-1)
			barebones:SetUpLevel(level)
			barebones:MoveCreeps(level, {})
			WebApi:UpdateTimeSplit(level)
		elseif level == 7 then
			GameRules.Ongoing = false
			WebApi:UpdateTimeSplit(level)
			Timers:CreateTimer(0.1, function()
				WebApi:FinalizeGameScoreAndSend()
				WebApi:SendDeleteRequest()
				Timers:CreateTimer(2, function()
					GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
					GameRules:SetSafeToLeave(true)
				end)
			end)
		end
		print("---------UpdateCheckpoint trigger finished--------")
	end
end

function GiveSkill(trigger)
	print("Skill trigger triggered")
	local hero = trigger.activator
	local trig = trigger.caller
	local name = trig:GetName()
	local level = tonumber(string.sub(name, 1, 1))
	local abilName = string.sub(name, 2)
	if trig and level == GameRules.CLevel then
		-- Giving skills
		if not hero:FindAbilityByName(abilName) then
			print("Giving skill to player")
			local partname = "particles/generic_hero_status/hero_levelup.vpcf"
			local part = ParticleManager:CreateParticle(partname, PATTACH_ABSORIGIN_FOLLOW, hero)
			hero:AddAbility(abilName):SetLevel(1)
		else
			print("Setting skill to level 1")
			local abil = hero:FindAbilityByName(abilName)
			local level = abil:GetLevel()
			if level < 1 then
				abil:SetLevel(1)
				local partname = "particles/generic_hero_status/hero_levelup.vpcf"
				local part = ParticleManager:CreateParticle(partname, PATTACH_ABSORIGIN_FOLLOW, hero)
			end
		end
	end

	-- Hack code to ensure no stuck timberchains
	if GameRules.CLevel == 4 then
		for _,hero in pairs(Players) do
			-- Removing any modifiers
			print("Checking for modifiers - ", hero:GetName())
			if hero:HasModifier("modifier_shredder_timber_chain") then
				print("Removing timberchain")
				hero:RemoveModifierByName("modifier_shredder_timber_chain")
			end
		end
	end
end

function RemoveSkill(trigger)
	print("Remove skill trigger triggered")
	local hero = trigger.activator
	local trig = trigger.caller
	if trig then
		local abilName = trig:GetName()
		local abil = hero:FindAbilityByName(abilName)
		if abil then
			print("Removing ability")
			abil:StartCooldown(2)
			abil:SetLevel(0)
			--Timers:CreateTimer(1, function()
			--	hero:RemoveAbility(abilName)
			--end)
		end
	end
end