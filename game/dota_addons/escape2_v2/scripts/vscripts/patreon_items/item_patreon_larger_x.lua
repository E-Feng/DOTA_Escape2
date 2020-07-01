item_patreon_larger_x = item_patreon_larger_x or class({})
LinkLuaModifier("modifier_patreon_larger_x", "patreon_items/item_patreon_larger_x", LUA_MODIFIER_MOTION_NONE)


function item_patreon_larger_x:GetIntrinsicModifierName()
	return "modifier_patreon_larger_x"
end

-- Modifier for larger x
modifier_patreon_larger_x = modifier_patreon_larger_x or class({})

function modifier_patreon_larger_x:IsHidden()		  return false end
function modifier_patreon_larger_x:IsPurgable()		return false end
function modifier_patreon_larger_x:RemoveOnDeath()	return false end

function modifier_patreon_larger_x:OnCreated()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()

  if IsServer() then
    if not self:GetAbility() then self:Destroy() end

    self.caster.beaconSize = BEACON_LARGE
    self.caster.largerXMod = true
    print("Beacon size on ", self.caster:GetName(), self.caster.beaconSize)
    print("Revive radius on ", self.caster:GetName(), self.caster.reviveRadius)
  end
end

function modifier_patreon_larger_x:OnDestroy()
  self.caster = self:GetCaster()
  self.ability = self:GetAbility()

  if IsServer() then
    if not self:GetAbility() then self:Destroy() end

    self.caster.beaconSize = BEACON_NORMAL
    self.caster.largerXMod = false    
    print("Beacon size on ", self.caster:GetName(), self.caster.beaconSize)
    print("Revive radius on ", self.caster:GetName(), self.caster.reviveRadius)
  end
end