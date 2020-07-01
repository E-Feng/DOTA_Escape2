item_patreon_phoenix_ash = item_patreon_phoenix_ash or class({})

function item_patreon_phoenix_ash:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self  

  local sound_cast = "DOTA_Item.PhoenixAsh.Cast"
  local particle_cast = "particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf"

  if not caster:IsAlive() then
    -- Setting params and cleaning up particles and dummies
    local respawnLoc = GameRules.Checkpoint
    caster:SetRespawnPosition(respawnLoc)
    caster:SetBaseMagicalResistanceValue(25)

    if caster.particleNumber then
      ParticleManager:DestroyParticle(caster.particleNumber, true)
    end

    local dummy = EntIndexToHScript(caster.dummyPartEntIndex)
    if dummy and dummy:IsAlive() then
      dummy:RemoveSelf()
    end

    caster.deadHeroPos = nil
    caster.particleNumber = nil
    caster.dummyPartEntIndex = nil

    -- Respawning hero and particles/sound
    caster:RespawnHero(false, false)

    EmitSoundOn(sound_cast, caster)

    ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)
  else
    ability:EndCooldown()
  end
end