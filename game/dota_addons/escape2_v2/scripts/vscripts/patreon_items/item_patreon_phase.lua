item_patreon_phase = item_patreon_phase or class({})
LinkLuaModifier("modifier_patreon_phase", "patreon_items/item_patreon_phase", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_patreon_phase_ms", "patreon_items/item_patreon_phase", LUA_MODIFIER_MOTION_NONE)

function item_patreon_phase:GetIntrinsicModifierName()
	return "modifier_patreon_phase"
end

function item_patreon_phase:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self
  local sound_cast = "DOTA_Item.PhaseBoots.Activate"
  local particle_cast = "particles/items2_fx/phase_boots.vpcf"

  local phase_duration = ability:GetSpecialValueFor("phase_duration")
  local phase_modifier = "modifier_phased"
  local ms_bonus_modifier = "modifier_patreon_phase_ms"

  EmitSoundOn(sound_cast, caster)

  ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)

  caster:AddNewModifier(caster, ability, phase_modifier, {duration = phase_duration})
  caster:AddNewModifier(caster, ability, ms_bonus_modifier, {duration = phase_duration})
end


-- Modifier for phase boots
modifier_patreon_phase = modifier_patreon_phase or class({})

function modifier_patreon_phase:IsHidden()		  return false end
function modifier_patreon_phase:IsPurgable()		return false end
function modifier_patreon_phase:RemoveOnDeath()	return false end

function modifier_patreon_phase:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()

  if IsServer() then
    if not self:GetAbility() then self:Destroy() end

    self.caster.phaseMod = true
    --print("Patreon phase on ", self.caster:GetName(), self.caster.phaseMod)
  end

  self.base_ms = self.ability:GetSpecialValueFor("base_ms")
end

function modifier_patreon_phase:OnDestroy()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()

  if IsServer() then
    if not self:GetAbility() then self:Destroy() end

    self.caster.phaseMod = false
    --print("Patreon phase on ", self.caster:GetName(), self.caster.phaseMod)
  end
end

function modifier_patreon_phase:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE  
	}
end

function modifier_patreon_phase:GetModifierMoveSpeedBonus_Special_Boots()
	return self.base_ms
end


-- Modifier for phase boots ms
modifier_patreon_phase_ms = modifier_patreon_phase_ms or class({})

function modifier_patreon_phase_ms:IsHidden()		  return true end
function modifier_patreon_phase_ms:IsPurgable()		return false end
function modifier_patreon_phase_ms:RemoveOnDeath()	return false end

function modifier_patreon_phase_ms:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()

  if IsServer() then
    if not self:GetAbility() then self:Destroy() end
  end

  self.ms_bonus = self.ability:GetSpecialValueFor("ms_bonus")
end

function modifier_patreon_phase_ms:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
	}
end

function modifier_patreon_phase_ms:GetModifierMoveSpeedBonus_Constant()
	return self.ms_bonus
end