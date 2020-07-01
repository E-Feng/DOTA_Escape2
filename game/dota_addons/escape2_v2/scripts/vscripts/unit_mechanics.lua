-- This function calls the CreepPatrol thinker for the creeps
function barebones:MoveCreeps(level)
  print("----------Creep moving starting----------")
  for i,entvals in pairs(EntList[level]) do
    if entvals[ENT_TYPEN] == ENT_PATRL or entvals[ENT_TYPEN] == ENT_BIGPT or entvals[ENT_TYPEN] == ENT_PATTR then
      local entid = entvals[ENT_INDEX]
      local vecnum = entvals[PAT_VECNM]
      local delay = entvals[PAT_DELAY]
      local ms = entvals[PAT_MVSPD]
      local turnDelay = entvals[PAT_TURND] or 0.5
      --print("Turn Delay, ", turnDelay)
      local unit = EntIndexToHScript(entid)
      if entvals[ENT_TYPEN] == ENT_BIGPT then
        table.insert(Linked, unit)
        Timers:CreateTimer(delay, function()
          barebones:CreepPatrolLinked(unit, vecnum, turnDelay)
        end)  
      else
        Timers:CreateTimer(delay, function()
          barebones:CreepPatrol(unit, vecnum, turnDelay)
        end)
      end
      print(unit:GetUnitName(), "(", entid, ") start patrol after delay of", delay)    
    end
  end
  print("----------Creep moving done----------")
end

-- This function does patrols for multiple waypoints
function barebones:CreepPatrol(unit, idx, turnDelay)
  local waypoints = MultVector[idx]
  local newpos = CopyTable(waypoints)
  local first = table.remove(newpos, 1)
  table.insert(newpos, first)
  Timers:CreateTimer(function()
    if IsValidEntity(unit) then
      for i,waypoint in pairs(waypoints) do
        local posU = unit:GetAbsOrigin()
        if CalcDist(posU, waypoint) < 5 then
          unit:MoveToPosition(newpos[i])
          unit.goal = newpos[i]
        end
      end
      unit:MoveToPosition(unit.goal)
      return turnDelay
    else
      return
    end
  end)
end

-- This function does patrols for multiple waypoints
function barebones:CreepPatrolLinked(unit, idx, turnDelay)
  local waypoints = MultVector[idx]
  local newpos = CopyTable(waypoints)
  local first = table.remove(newpos, 1)
  table.insert(newpos, first)
  local last = TableLength(newpos)
  unit.done = false
  unit.go = true
  unit.goal = newpos[1]
  unit.pos = 1
  Timers:CreateTimer(function()
    if IsValidEntity(unit) then
      for i,waypoint in pairs(waypoints) do
        local posU = unit:GetAbsOrigin()
        if CalcDist2D(posU, waypoint) < 25 then
          unit.goal = newpos[i]
          unit.pos = i
          if i == last then
            unit.done = true
            unit.go = false
          else
            unit:MoveToPosition(unit.goal)
          end
        else
          if unit.pos ~= last then
            unit:MoveToPosition(unit.goal)
          elseif unit.go then
            unit:MoveToPosition(unit.goal)
          end
        end
      end
      return turnDelay
    else
      return
    end
  end)
end

-- This function runs a thinker linking the patrol of units
function barebones:LinkedThinker()
  Timers:CreateTimer(2, function()
    local ready = true
    if GameRules.CLevel == 5 then
      --local unit1 = Linked[1]
      --local unit2 = Linked[2]
      --print(CalcDist2D(unit1:GetAbsOrigin(), unit2:GetAbsOrigin()))
      for i,unit in pairs(Linked) do
        --print(unit.done)
        if unit.done == false then
          ready = false
        end
      end
      if ready then
        for i,unit in pairs(Linked) do
          print("Restarting linked movement")
          unit:MoveToPosition(unit.goal)
          unit.go = true
          unit.done = false
          Timers:CreateTimer(1.5, function()
            if not unit:IsMoving() then
              unit:MoveToPosition(unit.goal)
            end
          end)
          Timers:CreateTimer(2.0, function()
            if not unit:IsMoving() then
              unit:MoveToPosition(unit.goal)
            end
          end)
          Timers:CreateTimer(2.5, function()
            unit.go = true
            unit.done = false
            if not unit:IsMoving() then
              unit:MoveToPosition(unit.goal)
            end
          end)
        end
      end
      return 0.25
    else
      return
    end
  end)

  local part = 0
  Timers:CreateTimer(1, function()
    if GameRules.CLevel == 5 then
      local unit1 = Linked[1]
      local unit2 = Linked[2]
      local pos1 = unit1:GetAbsOrigin()
      local pos2 = unit2:GetAbsOrigin()
      -- Killing units in area
      local table = FindUnitsInLine(DOTA_TEAM_GOODGUYS, 
                                    pos1, 
                                    pos2, 
                                    nil, 
                                    125, 
                                    DOTA_UNIT_TARGET_TEAM_BOTH, 
                                    DOTA_UNIT_TARGET_HERO, 
                                    FIND_ANY_ORDER)
      --PrintTable(table)
      for i,unit in pairs(table) do
        local damageTable = {victim = unit,
                             attacker = unit1,
                             damage = 1,
                             damage_type = DAMAGE_TYPE_PURE
                            }
        ApplyDamage(damageTable)
      end
      -- Arc lightning particle effect
      if part > 0 then
        ParticleManager:DestroyParticle(part, false)
      end
      part = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_ABSORIGIN, unit1)
      pos1.z = 192
      pos2.z = 192
      ParticleManager:SetParticleControl(part, 0, pos1)
      ParticleManager:SetParticleControl(part, 1, pos2)
      return 0.2
    else
      return
    end
  end)
end

-- This function initializes values for the patrol creeps
function barebones:PatrolInitial(unit, entvals)
  --print("Values initialized for ", unit:GetUnitName(), "(", unit:GetEntityIndex(), ")")
  unit:SetBaseMoveSpeed(entvals[PAT_MVSPD])
  if entvals[PAT_MVSPD] > 550 then
    unit:AddNewModifier(unit, nil, "modifier_dark_seer_surge", {})
  end
end

-- This function initializes values for the big patrol creeps
function barebones:PatrolInitialBig(unit, entvals)
  --print("Values initialized for ", unit:GetUnitName(), "(", unit:GetEntityIndex(), ")")
  unit:SetBaseMoveSpeed(entvals[PAT_MVSPD])
  unit:AddNewModifier(unit, nil, "modifier_spectre_spectral_dagger_path_phased", {})
  unit:AddAbility("kill_radius"):SetLevel(2)
end

-- This function initializes values for the patrol creeps
function barebones:PatrolInitialInvis(unit, entvals)
  --print("Values initialized for ", unit:GetUnitName(), "(", unit:GetEntityIndex(), ")")
  unit:SetBaseMoveSpeed(entvals[PAT_MVSPD])
  unit:AddAbility("riki_permanent_invisibility"):SetLevel(2)
end

-- This function is a thinker for a gate to move upon full mana
function barebones:GateThinker(unit, entvals)
  print("Thinker has started on unit", unit:GetUnitName(), "(", unit:GetEntityIndex(), ")")
  local pos = Entities:FindByName(nil, entvals[ENT_SPAWN]):GetAbsOrigin()
  local hullRadius = 80

  unit.moved = false
  unit:SetMana(15-entvals[GAT_NUMBR])
  unit:SetHullRadius(hullRadius)
  unit:SetForwardVector(entvals[GAT_ORIEN])
  local abil = unit:FindAbilityByName("gate_unit_passive")
  Timers:CreateTimer(function()
    if IsValidEntity(unit) then
      -- print("Has mana?", abil:IsOwnersManaEnough(), unit:GetUnitName(), "(", unit:GetEntityIndex(), ")")
      if abil:IsOwnersManaEnough() then
        unit:SetBaseMoveSpeed(100)
        unit:CastAbilityImmediately(abil, -1)
        unit:SetHullRadius(25)
        unit.moved = true
      end
      if not unit.moved then
        if CalcDist2D(unit:GetAbsOrigin(), pos) > 100 and RandomFloat(0, 1) > 0.75 then
          unit:MoveToPosition(pos)
        end

        -- Check for phase boots through
        local foundUnits = FindUnitsInRadius(DOTA_TEAM_GOODGUYS,
                                             unit:GetAbsOrigin(),
                                             nil,
                                             hullRadius,
                                             DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                             DOTA_UNIT_TARGET_HERO,
                                             DOTA_UNIT_TARGET_FLAG_NONE,
                                             FIND_ANY_ORDER,
                                             false)
        for _,foundUnit in pairs(foundUnits) do
          --print("Found", foundUnit:GetName())
          local posU = unit:GetAbsOrigin()
          local posF = foundUnit:GetAbsOrigin()

          local shift = -(hullRadius - CalcDist2D(posU, posF) + 25)
          local forwardVec = foundUnit:GetForwardVector():Normalized()
          local newOrigin = posF + forwardVec*shift
          foundUnit:SetAbsOrigin(newOrigin)
        end        
      end
      return 0.03
    else
      return
    end
  end)
end

-- This function is for the "train" system
function barebones:TrainThinker()
  print("Train thinker has started")
  local entNames = {{"carty2_1a", "carty2_1b"}, {"carty2_2a", "carty2_2b"}, {"carty2_3a", "carty2_3b"}}
  local entLocs = {}
  local xOffset = 130
  local baseMoveSpeed = {250, 335, 145}
  local timeSpawn = {2, 1.5, 2.4}
  local carts = 3
  -- Converts the entity names into vector locations
  for i,list in pairs(entNames) do
    entLocs[i] = {}
    for j,entLoc in pairs(list) do
      local pos = Entities:FindByName(nil, entLoc):GetAbsOrigin()
      entLocs[i][j] = pos
    end
  end
  -- Starts the spawning and moving
  for i,loc in pairs(entLocs) do
    local posS = loc[1]
    local posE = loc[2]
    Timers:CreateTimer(function()
      if GameRules.CLevel == 2 then
        for j = 1,carts do
          local pos1 = Vector(posS.x + xOffset*(j-1), posS.y, posS.z)
          local pos2 = Vector(posE.x + xOffset*(j-1), posE.y, posE.z)
          local unit = CreateUnitByName("npc_dota_badguys_siege", pos1, true, nil, nil, DOTA_TEAM_ZOMBIES)
          unit.posE = pos2
          unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
          unit:AddAbility("patrol_unit_passive"):SetLevel(1)
          unit:AddAbility("kill_radius"):SetLevel(1)
          unit:SetBaseMoveSpeed(baseMoveSpeed[i])
          Timers:CreateTimer(0.2, function()
            unit:MoveToPosition(pos2)
          end)
          Timers:CreateTimer(function()
            if IsValidEntity(unit) then
              if CalcDist(unit:GetAbsOrigin(), pos2) < 10 then
                unit:RemoveSelf()
              end
              return 0.1
            else
              return
            end
          end)
        end
        return timeSpawn[i]
      else
        return
      end
    end)
  end
end

-- This function is for the static zombie thinker
function barebones:StaticThinker(unit, entvals)
  print("Thinker has started on static zombie (", unit:GetEntityIndex(), ")")
  local minwait = 5
  local maxwait = 10
  Timers:CreateTimer(1, function()
    if IsValidEntity(unit) then
      local pos = unit:GetAbsOrigin()
      local xrand = RandomFloat(-1, 1)
      local yrand = RandomFloat(-1, 1)
      unit:MoveToPosition(Vector(pos.x + xrand, pos.y + yrand, 0))
      return RandomFloat(minwait, maxwait)
    else
      return
    end
  end)
end

-- This function is for the cross thinker
function barebones:CrossThinker()
  print("Cross thinker starter")
  -- 1 is up/down, 2 is left/right
  local entNames = {{"cross3_1a", "cross3_1b"}, {"cross3_2a", "cross3_2b"}}
  local entLocs = {}
  local gap = 512
  local rows = 4
  local ms = 475
  local units = 2
  local unitgap = 100
  -- Converts the entity names into vector locations
  for i,list in pairs(entNames) do
    entLocs[i] = {}
    for j,entLoc in pairs(list) do
      local pos = Entities:FindByName(nil, entLoc):GetAbsOrigin()
      entLocs[i][j] = pos
    end
  end
  -- Starting thinker
  for i,loc in pairs(entLocs) do
    local xx = 1
    local yy = 0
    if i == 2 then
      xx = 0
      yy = -1
    end
    local spawn = loc[1]
    local waypo = loc[2]
    for j = 1,rows do
      for k = 1,units do
        local pos1 = Vector(spawn.x + gap*xx*(j-1) + unitgap*xx*(k-1), spawn.y + gap*yy*(j-1) + unitgap*yy*(k-1), spawn.z)
        local pos2 = Vector(waypo.x + gap*xx*(j-1) + unitgap*xx*(k-1), waypo.y + gap*yy*(j-1) + unitgap*yy*(k-1), waypo.z)
        local unit = CreateUnitByName("npc_creep_patrol", pos1, true, nil, nil, DOTA_TEAM_ZOMBIES)
        unit:SetBaseMoveSpeed(ms)
        unit:MoveToPosition(pos2)
        Timers:CreateTimer(.03, function()
          if IsValidEntity(unit) and GameRules.CLevel == 3 then
            if CalcDist(unit:GetAbsOrigin(), pos2) < 5 then
              unit:MoveToPosition(pos1)
            elseif CalcDist(unit:GetAbsOrigin(), pos1) < 5 then
              unit:MoveToPosition(pos2)
            end
            return 0.25
          else
            unit:RemoveSelf()
            return
          end
        end)
      end
    end
  end
end

-- This function is for the timberchain level
function barebones:TimberChainThinker()
  print("Thinker for timberchain level started")
  local units = 20
  local ms = 400
  local boundsLoc = 1
  local boundsTL = BoundsVector[boundsLoc][1]
  local boundsBR = BoundsVector[boundsLoc][2]
  local spacing = (boundsBR.x-boundsTL.x)/(units-1)
  -- Spawning the wall of zombies
  Timers:CreateTimer(0.5, function()
    if GameRules.CLevel == 3 then
      for i = 1,units do
        local x = boundsTL.x + spacing*(i-1)
        local pos1 = Vector(x, boundsBR.y, 128)
        local unit = CreateUnitByName("npc_creep_patrol_torso", pos1, true, nil, nil, DOTA_TEAM_ZOMBIES)
        local pos2 = Vector(x, boundsTL.y, 128)
        unit:SetBaseMoveSpeed(ms)
        unit:AddNewModifier(unit, nil, "modifier_spectre_spectral_dagger_path_phased", {})
        Timers:CreateTimer(0.5, function()
          unit:MoveToPosition(pos2)
          if IsValidEntity(unit) then
            if CalcDist(unit:GetAbsOrigin(), pos2) < 5 then
              unit:ForceKill(true)
              return
            end
            return 0.1
          else
            unit:RemoveSelf()
            return
          end
        end)
      end
      return 8
    else
      return
    end
  end)
  -- Spawning the trees
  Timers:CreateTimer(0.5, function()
    if GameRules.CLevel == 3 then
      local numInside = GetNumberInsideRectangle(boundsTL, boundsBR, true)
      local numInsideDead = GetNumberInsideRectangle(boundsTL, boundsBR, false)
      local numTreeDead = math.floor(numInsideDead/3)
      local numTrees = math.max(math.ceil(numInside/2), 1) + numTreeDead + 1
      --print(numInside, numTrees)
      for i = 1,numTrees do
        local x = RandomFloat(boundsTL.x, boundsBR.x)
        local y = RandomFloat(boundsTL.y, boundsBR.y + 100)
        local pos = Vector(x, y, 128)
        local tree = CreateTempTree(pos, 14)
      end
      return 1
    else
      return
    end
  end)
end

-- This function is for the fissue level
function barebones:FissureThinker()
  print("Fissure level thinker started")
  local names = {"spawn5_1", "spawn5_2", "spawn5_3", "spawn5_4"}
  local direcs = {-1, -1, 1, 1}
  local lens = 275
  local dists = {1100, 1100, 1100, 600}
  local rates = {0.25, 0.25, 0.25, 0.25}
  for i,name in pairs(names) do
    local pos = Entities:FindByName(nil, name):GetAbsOrigin()
    barebones:SpawnRandomly(pos, direcs[i], lens, dists[i], rates[i])
  end
end

-- This subfunction spawns zombies randomly for fissure level
function barebones:SpawnRandomly(pos, direc, length, dist, rate)
  local x1 = pos.x - length
  local x2 = pos.x + length
  local y1 = pos.y
  local y2 = pos.y + direc*dist
  Timers:CreateTimer(function()
    if GameRules.CLevel == 5 then
      local xSpawn = RandomFloat(x1, x2)
      local xGoal = RandomFloat(x1, x2)
      local pos1 = Vector(xSpawn, y1, 128)
      local pos2 = Vector(xGoal, y2, 128)
      local unit = CreateUnitByName("npc_creep_patrol_torso", pos1, true, nil, nil, DOTA_TEAM_ZOMBIES)
      Timers:CreateTimer(0.5, function()
        unit:MoveToPosition(pos2)
        if IsValidEntity(unit) then
          if CalcDist(unit:GetAbsOrigin(), pos2) < 5 then
            unit:ForceKill(true)
            return
          end
          return 0.1
        else
          unit:RemoveSelf()
          return
        end          
      end)
      return rate
    else
      return
    end
  end)
end

-- This function is for the roundabout thinker
function barebones:RoundaboutThinker()
  print("Roundabout thinker started")
  local entname = "roundabout"
  local center = Entities:FindByName(nil, entname):GetAbsOrigin()
  local rings = 14
  local rSpacing = 150
  local rStart = 200
  local patrolSpace = 400
  local movespeed = 300
  local angleMove = math.rad(5)
  local skip = {6, 11}
  for i = 1,rings do
    if not TableContains(skip, i) then
      print("Creating ring ", i)
      local unitTable = {}
      local r = rStart + (i-1)*rSpacing
      local perimeter = 2*math.pi*r
      local units = math.ceil(perimeter/patrolSpace)
      local extra = math.ceil(i/2)
      for j = 1,(units + extra) do
        local angle = math.rad((360/(units + extra))*j)
        local pos = Vector(center.x + r*math.cos(angle), center.y + r*math.sin(angle), center.z)
        local unit = CreateUnitByName("npc_creep_patrol_no_turn", pos, true, nil, nil, DOTA_TEAM_ZOMBIES)
        unit:SetBaseMoveSpeed(movespeed)
        unit.angle = angle
        unit.pos = pos
        unit.move = angleMove
        if i % 2 == 0 then
          unit.move = -angleMove
        end
        unitTable[#unitTable+1] = unit
      end
      -- Running thinkers at once for zombies
      for i,unit in pairs(unitTable) do
        local pos = unit.pos
        local angle = unit.angle
        local move = unit.move
        Timers:CreateTimer(2, function()
          if IsValidEntity(unit) then
            if CalcDist(unit:GetAbsOrigin(), pos) < 5 then
              angle = angle + move
              pos = Vector(center.x + r*math.cos(angle), center.y + r*math.sin(angle), center.z)
              unit:MoveToPosition(pos)
            end
            return 0.10
          else
            return
          end
        end)
      end
    else
      patrolSpace = patrolSpace + 50
    end
  end
end

--[[ This function is for the clockwork thinker
function barebones:ClockThinker()
  local pos = Entities:FindByName(nil, "clock_loc"):GetAbsOrigin()
  local unit = CreateUnitByName("npc_clockwerk", pos, true, nil, nil, DOTA_TEAM_GOODGUYS)
  unit.castX = -4500
  unit.castY = -2000
  local abil1 = unit:FindAbilityByName("rattletrap_rocket_flare_custom")
  local abil2 = unit:FindAbilityByName("zuus_lightning_bolt_custom")
  Timers:CreateTimer(1, function()
    if IsValidEntity(unit) then
      local castPos = Vector(unit.castX, unit.castY, 128)
      unit:CastAbilityOnPosition(castPos, abil1, -1)
      unit:CastAbilityOnPosition(castPos, abil2, -1)
      return 5
    else
      return
    end
  end)
end
]]