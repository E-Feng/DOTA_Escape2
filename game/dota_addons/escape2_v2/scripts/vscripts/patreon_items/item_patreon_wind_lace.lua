item_patreon_wind_lace = item_patreon_wind_lace or class({})
LinkLuaModifier("modifier_patreon_wind_lace", "patreon_items/item_patreon_wind_lace", LUA_MODIFIER_MOTION_NONE)


function item_patreon_wind_lace:GetIntrinsicModifierName()
	return "modifier_patreon_wind_lace"
end


-- Modifier for wind lace ms and turn rate
modifier_patreon_wind_lace = modifier_patreon_wind_lace or class({})

function modifier_patreon_wind_lace:IsHidden()		  return false end
function modifier_patreon_wind_lace:IsPurgable()		return false end
function modifier_patreon_wind_lace:RemoveOnDeath()	return false end
function modifier_patreon_wind_lace:GetAttributes()	return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_patreon_wind_lace:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()

  if IsServer() then
    if not self:GetAbility() then self:Destroy() end
  end

  self.ms_bonus = self.ability:GetSpecialValueFor("ms_bonus")
  self.turn_rate_bonus = self.ability:GetSpecialValueFor("turn_rate_bonus")
end

function modifier_patreon_wind_lace:DeclareFunctions()
	return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE
	}
end

function modifier_patreon_wind_lace:GetModifierMoveSpeedBonus_Constant()
	return self.ms_bonus
end

function modifier_patreon_wind_lace:GetModifierTurnRate_Percentage()
	return self.turn_rate_bonus
end