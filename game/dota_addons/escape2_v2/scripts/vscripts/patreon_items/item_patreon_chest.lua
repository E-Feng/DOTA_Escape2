item_patreon_chest = item_patreon_chest or class({})

function item_patreon_chest:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local sound_cast = "ui.treasure_01"
  local particle_cast = ""

  -- Checking for patreon status
  local playerID = caster:GetPlayerID()
  local steamID = tostring(PlayerResource:GetSteamID(playerID))
  --DeepPrintTable(WebApi.patreons)
  --print("Steam ID: ", steamID)

  local patreonLevel = 0

  if WebApi.patreonsLoaded then
    if WebApi.patreons[steamID] then
      patreonLevel = WebApi.patreons[steamID]
      caster.patreonLevel = patreonLevel

      -- Adjusting for non level 6 item
      patreonLevel = math.min(patreonLevel, 5)

      if patreonLevel > 0 then
      -- Chest used, leaderboard DQ
      _G.patreonUsed = true
      end
    end

    local itemList = {}
    itemList[0] = "item_patreon_get_cheese1"
    itemList[1] = "item_patreon_get_cheese2"
    itemList[2] = "item_patreon_larger_x"
    itemList[3] = "item_patreon_wind_lace"
    itemList[4] = "item_patreon_phoenix_ash"
    itemList[5] = "item_patreon_phase"

    -- Remove charge and give items
    ability:SpendCharge()
    while patreonLevel >= 0 do
      print("Giving item ", itemList[patreonLevel])
      caster:AddItemByName(itemList[patreonLevel])
      patreonLevel = patreonLevel - 1
    end

    EmitSoundOn(sound_cast, caster)
    --ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)
  else
    print("Patreon list has failed to load")
    ability:SpendCharge()

    local str = '<font color="red">Failed to connect to Patreon database, please try again next game.</font>'
    GameRules:SendCustomMessage(str, 0, 1)
  end
end