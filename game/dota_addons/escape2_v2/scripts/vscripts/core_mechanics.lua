-- This function is to run a thinker to revive heroes upon "contact"
function barebones:ReviveThinker()
  --print("Number of dead heroes is ", barebones:TableLength(DeadHeroPos))
  for _, alivehero in pairs(Players) do
    if alivehero:IsAlive() then
      --surr = Entities:FindAllInSphere(hero:GetAbsOrigin(), hero:GetModelRadius())
      --for i,ent in pairs(surr) do
      --  print(i, ent, ent:GetClassname(), ent:GetName())
      --end
      for _, deadhero in pairs(Players) do
        if deadhero.deadHeroPos then
          local reviveRadius = alivehero.reviveRadius

          -- Patreon larger x
          if deadhero.largerXMod then
            reviveRadius = math.min(reviveRadius * 1.5, REVIVE_RAD_MAX)
          end

          if CalcDist2D(alivehero:GetAbsOrigin(), deadhero.deadHeroPos) < reviveRadius then
            --print("Radius ", alivehero:GetName(), reviveRadius)
            barebones:HeroRevived(deadhero, alivehero)

            -- Patreon phase boots
            Timers:CreateTimer(0, function()
              if alivehero.phaseMod then
                alivehero:AddNewModifier(alivehero, nil, "modifier_phased", {duration = 2})
              end
              if deadhero.phaseMod then
                deadhero:AddNewModifier(deadhero, nil, "modifier_phased", {duration = 2})
              end
            end)
          end
        end
      end
    end
  end
end

-- This function runs to save the location and particle spawn upon hero killed
function barebones:HeroKilled(hero, attacker, ability)
  -- Saves position of killed hero into table
  local playerIdx = hero:GetEntityIndex()
  -- If hero steps onto grass/lava origin is moved closer to path
  hero:SetBaseMagicalResistanceValue(25)
  hero.deadHeroPos = hero:GetAbsOrigin()
  if ability then
    if ability:GetAbilityName() == "self_immolation" then
      --print("Moving back location of hero and particle")
      local shift = -30
      local forVector = hero:GetForwardVector():Normalized()
      local newDeadPos = hero:GetAbsOrigin() + forVector*shift
      hero.deadHeroPos = newDeadPos
      --print("Normalized forward vector: ", forVector)
      --print("Altered position: ", newDeadPos)
    end
  end
  --print(hero:GetAbsOrigin())

  --print("Hero", playerIdx, " position saved as ", DeadHeroPos[playerIdx])
  --print("Hero killed by", attacker, attacker:GetName())
  --print("Hero killed by ability", ability, ability:GetAbilityName())

  -- Creates a particle at position and saves particleIdx into tables
  local part = BeaconPart[hero.id]
  local dummy = CreateUnitByName("npc_dummy_unit", hero.deadHeroPos, true, nil, nil, DOTA_TEAM_GOODGUYS)
  dummy:FindAbilityByName("dummy_unit"):SetLevel(1)
  dummy:AddNewModifier(dummy, nil, "modifier_phased", {})
  dummy:AddNewModifier(dummy, nil, "modifier_spectre_spectral_dagger_path_phased", {})
  
  local beacon = ParticleManager:CreateParticle(part, PATTACH_ABSORIGIN, dummy)
  ParticleManager:SetParticleControl(beacon, 0, hero.deadHeroPos)
  ParticleManager:SetParticleControl(beacon, 1, Vector(hero.beaconSize, 0, 0))

  hero.particleNumber = beacon
  hero.dummyPartEntIndex = dummy:GetEntityIndex()
  --print("Particle Created: ", beacon, "under player ", playerIdx, "dummy index: ", PartDummy[playerIdx])

  -- Removes the "killed by" ui when dead
  local player = PlayerResource:GetPlayer(hero:GetPlayerID())
  if player then
    Timers:CreateTimer(0.03, function()
        player:SetKillCamUnit(nil)
    end)
  end
end

-- This function revives the hero once the thinker has found "contact"
function barebones:HeroRevived(deadhero, alivehero)
  -- Sets up location of hero and respawns there
  local xLocation = deadhero.deadHeroPos

  -- Takes the average of alivehero and x location to respawn closer to path
  local respawnLoc = AveragePos(alivehero:GetAbsOrigin(), xLocation)
  deadhero:SetRespawnPosition(respawnLoc)
  deadhero:RespawnHero(false, false)
  deadhero:SetBaseMoveSpeed(300)
  --print("Hero Idx(", playerIdx, ") respawned at ", respawnLoc)

  -- Finds the particle index and deletes it
  local partID = deadhero.particleNumber
  ParticleManager:DestroyParticle(partID, true)
  --print("Particle: ", partID, "destroyed after respawn")

  -- Resetting and updating
  deadhero.deadHeroPos = nil
  deadhero.particleNumber = nil

  local dummy = EntIndexToHScript(deadhero.dummyPartEntIndex)
  if dummy and dummy:IsAlive() then
    dummy:RemoveSelf()
  end
  deadhero.dummyPartEntIndex = nil
end

-- This function is a thinker to check if everyone is dead and revives them
function barebones:CheckpointThinker()
  local numPlayers = TableLength(Players)
  local deadHeroes = 0
  for _,hero in pairs(Players) do
    if not hero:IsAlive() then
      deadHeroes = deadHeroes + 1
    end
  end
  --print("Dead heroes:", deadHeroes, "Total:", numPlayers, "Lives:", GameRules.Lives)
  -- print("CheckpointThinker started, players:", numPlayers, "dead players:", numdead)
  if GameRules.Lives >= 0 and numPlayers == deadHeroes and numPlayers ~= 0 then
    deadHeroes = 0
    Timers:CreateTimer(0.5, function()
      barebones:ReviveAll()
      GameRules.Lives = GameRules.Lives - 1
      if GameRules.Lives >= 0 then
        local str = "You now have " .. tostring(GameRules.Lives) .. " lives remaining!"
        local msg = {
          text = str,
          duration = 5.0,
          style={color="red", ["font-size"]="80px"}
        }
        Notifications:TopToAll(msg)
        GameRules:SendCustomMessage(str, 0, 1)
      end
    end)
  elseif GameRules.Lives < 0 then
    WebApi:SendDeleteRequest()
    Timers:CreateTimer(1, function()
      GameRules.Ongoing = false
      GameRules:SetGameWinner(DOTA_TEAM_ZOMBIES)
      GameRules:SetSafeToLeave(true)
    end)
  end
end

-- This function revives everyone when they all die at last checkpoint
function barebones:ReviveAll()
  print("--------Everyone died, reviving all----------")
  local respawnLoc = GameRules.Checkpoint
  local caster
  for i,hero in pairs(Players) do
    if hero:IsAlive() then
      hero:SetBaseMagicalResistanceValue(25)
    end
    hero:SetRespawnPosition(respawnLoc)
    --print("Respawn location set to", respawnLoc)
    hero:RespawnHero(false, false)
    hero:SetBaseMoveSpeed(300)
    hero:Stop()
    hero.deadHeroPos = nil
    print("Hero Idx(", i, ") respawned at ", hero:GetAbsOrigin())
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
    if hero.particleNumber then
      ParticleManager:DestroyParticle(hero.particleNumber, true)
    end
    caster = hero
  end
  EmitSoundOnLocationForAllies(respawnLoc, "Hero_Omniknight.Purification", caster)
  print("-------All respawned, reset--------------")
end

-- This function is called to spawn the entities for the level
function barebones:SetUpLevel(level)
  print("------Spawning Entities (", level, ")-----")
  -- Running functions
  for _,funcName in pairs(FuncList[level]) do
    barebones[funcName]()
  end
  -- Spawning entities
  for i,entvals in pairs(EntList[level]) do
    local entnum = entvals[ENT_TYPEN]
    local entspawn = Entities:FindByName(nil, entvals[ENT_SPAWN])
    local entname = Ents[entnum]
    local pos = entspawn:GetAbsOrigin()
    if entvals[ENT_UNTIM] == 1 then  -- item
      local item = CreateItem(entname, nil, nil)
      CreateItemOnPositionSync(pos, item)
      print(item:GetName(), "(", item:GetEntityIndex(), ") has spawned at", pos)
      EntList[level][i][ENT_INDEX] = item:GetEntityIndex()
    elseif entvals[ENT_UNTIM] == 2 then -- unit
      local unit = CreateUnitByName(entname, pos, true, nil, nil, DOTA_TEAM_ZOMBIES)
      print(unit:GetUnitName(), "(", unit:GetEntityIndex(), ") has spawned at", pos)
      EntList[level][i][ENT_INDEX] = unit:GetEntityIndex()
      -- Running appriopriate function/thinker for entity
      if entvals[ENT_RFUNC] then
        barebones[entvals[ENT_RFUNC]](barebones, unit, entvals)
      end
    end
  end
  -- Spawning particles
  for _,partvals in pairs(PartList[level]) do
    if TableLength(partvals) > 0 then
      barebones:SpawnParticle(partvals)
    end
  end
  print("----------All Entities Spawned----------")
end

-- This function spawns particles
function barebones:SpawnParticle(partvals)
  print("-----------Particles spawning------------")
  local entspawn = Entities:FindByName(nil, partvals[PAR_SPAWN]):GetAbsOrigin()
  local dummy = CreateUnitByName("npc_dummy_unit", entspawn, true, nil, nil, DOTA_TEAM_GOODGUYS)
  dummy:FindAbilityByName("dummy_unit"):SetLevel(1)
  local part = ParticleManager:CreateParticle(partvals[PAR_FNAME], PATTACH_ABSORIGIN, dummy)
  ParticleManager:SetParticleControl(part, partvals[PAR_CTRLP], dummy:GetAbsOrigin())
  partvals[PAR_INDEX] = part
  table.insert(Extras, dummy:GetEntityIndex())
  print("Part", part, "spawned at", dummy:GetAbsOrigin())
end

-- This function spawns the cheeses for extra life in the beginning
function barebones:ExtraLifeSpawn()
  print("Spawning extra life cheeses")
  local pos = Entities:FindByName(nil, "cheese_spawn"):GetAbsOrigin()
  local cheeseNum = 6
  local r = 175
  for i = 1,cheeseNum do
    local item = CreateItem("item_cheese_custom", nil, nil)
    local angle = math.rad((i-1)*(360/cheeseNum))
    local spawnPos = Vector(pos.x + r*math.cos(angle), pos.y + r*math.sin(angle), pos.z)
    CreateItemOnPositionSync(spawnPos, item)

    -- For patreon courier
    _G.Cheeses[item:GetEntityIndex()] = "spawned"
  end
end

-- This function cleans up the previous level
function barebones:CleanLevel(level)
  print("-------------Cleaning level---------------")
  for _,entvals in pairs(EntList[level]) do
    if entvals[ENT_INDEX] ~= 0 then
      local ent = EntIndexToHScript(entvals[ENT_INDEX])
      if ent ~= nil then
        if entvals[ENT_UNTIM] == 2 and ent:IsAlive() then
          print("Ent", ent:GetUnitName(), "ID", entvals[ENT_INDEX], "removed")
          ent:RemoveSelf()
        elseif entvals[ENT_UNTIM] == 1 and ent:GetName() == "item_mango_custom" then
          --print(ent, ent:GetClassname(), ent:GetName())
          if ent:GetContainer() ~= nil then
            print("Ent container", ent:GetName(), "ID", entvals[ENT_INDEX], "removed")
            ent:GetContainer():RemoveSelf()
          end
          if ent ~= nil then
            print("Ent", ent:GetName(), "ID", entvals[ENT_INDEX], "removed")
            ent:RemoveSelf()
          end
        elseif entvals[ENT_UNTIM] == 1 and ent:GetName() == "item_cheese_custom" then
          --print(ent, ent:GetClassname(), ent:GetName())
          if ent:GetContainer() ~= nil then
            print("Ent container", ent:GetName(), "ID", entvals[ENT_INDEX], "removed")
            ent:GetContainer():RemoveSelf()
          end
          if ent ~= nil then
            print("Ent", ent:GetName(), "ID", entvals[ENT_INDEX], "removed")
            ent:RemoveSelf()
          end
        end
      end
    end
  end
  for _,extra in pairs(Extras) do
    local ent = EntIndexToHScript(extra)
    print("Ent ID", ent:GetUnitName(), extra, "removed")
    ent:RemoveSelf()
  end
  for _,partvals in pairs(PartList[level]) do
    if TableLength(partvals) > 0 and partvals[PAR_INDEX] ~= 0 then
      ParticleManager:DestroyParticle(partvals[PAR_INDEX], true)
      print("Particle", partvals[PAR_INDEX], "removed")
    end
  end
  Extras = {}
  print("----------Cleaning level done------------")
end

-- This function removes all skills from all players
function barebones:RemoveAllSkills()
  print("---------Removing All Skills------------")
  for _,hero in pairs(Players) do
    -- Removing abilities
    for i = 0,5 do
      local abil = hero:GetAbilityByIndex(i)
      if abil then
        Timers:CreateTimer(1, function()
          abil:SetLevel(0)
        end)
      end
    end
  end
end