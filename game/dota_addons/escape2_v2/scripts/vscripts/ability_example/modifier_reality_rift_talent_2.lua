if modifier_reality_rift_talent_2 == nil then
	modifier_reality_rift_talent_2 = class({})
end

function modifier_reality_rift_talent_2:IsHidden()
    return true
end

function modifier_reality_rift_talent_2:IsPurgable()
    return false
end

function modifier_reality_rift_talent_2:AllowIllusionDuplicate() 
	return false
end

function modifier_reality_rift_talent_2:RemoveOnDeath()
    return false
end

function modifier_reality_rift_talent_2:OnCreated()
	local parent = self:GetParent()
	local talent = self:GetAbility()
	local talent_value = talent:GetSpecialValueFor("value")
	parent.reality_rift_talent_2_value = talent_value
end
