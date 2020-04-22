require('libraries/custom_illusions')

if detonator_conjure_image == nil then
	detonator_conjure_image = class({})
end

function detonator_conjure_image:IsStealable()
	return true
end

function detonator_conjure_image:IsHiddenWhenStolen()
	return false
end

function detonator_conjure_image:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	
	if target == nil then
		return nil
	end
	
	if IsServer() then
		local caster_team = caster:GetTeamNumber()
		-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
		if (not target:TriggerSpellAbsorb(self)) or (target:GetTeamNumber() == caster_team) then
			-- Target is a friend or an enemy that doesn't have Spell Block
			local duration = self:GetSpecialValueFor("duration")
			local damage_dealt = self:GetSpecialValueFor("illusion_damage_out")
			local damage_taken = self:GetSpecialValueFor("illusion_damage_in")
			-- Use function from custom_illusions.lua
			local custom_illusion = target:CreateIllusion(caster, self, duration, nil, damage_dealt, damage_taken, true, nil)
			-- Sound on the target
			target:EmitSound("Hero_Terrorblade.ConjureImage")
		end
	end
end

function detonator_conjure_image:ProcsMagicStick()
	return true
end
