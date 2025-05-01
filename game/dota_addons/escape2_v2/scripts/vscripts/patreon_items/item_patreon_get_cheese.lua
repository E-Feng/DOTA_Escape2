item_patreon_get_cheese1 = item_patreon_get_cheese1 or class({})
--item_patreon_get_cheese2 = item_patreon_get_cheese2 or class({})

function item_patreon_get_cheese1:OnSpellStart()
  local caster = self:GetCaster()
  local ability = self

  local playerID = caster:GetPlayerID()
  local name = PlayerResource:GetPlayerName(playerID)

  local sound_cast_win = "Hero_OgreMagi.Fireblast.x3"
  local sound_cast_fail = "Hero_OgreMagi.Fireblast.x1"

  local particle_cast = "particles/addons_gameplay/pit_lava_sparks.vpcf"

  -- Rolling chance
  local type = string.sub(ability:GetName(), -1)

  -- Chance, 0 for 100%, 100 for impossible
  local chance = 100 - ability:GetSpecialValueFor("chance" .. type)
  if type == "2" then
    local level = caster.patreonLevel
    if level >= 6 then
      chance = 0
    else
      chance = chance - math.max(0, level - 1) * 5
    end
  end
  local roll = RandomInt(1, 100)

  -- Quickly setting variables, casts and text
  local sound_cast = (roll > chance) and sound_cast_win or sound_cast_fail
  local roll_color = (roll > chance) and "green" or "red"
  local msg = (roll > chance) and "Jackpot!" or "Try again next game!"
  local msg_color = (roll > chance) and "green" or "white"

  -- Extraordinary ties
  if roll == chance then
    msg = "So close! Better luck next time!"
    msg_color = "yellow"
  end

  local roll_str = '<font color="' .. roll_color .. '">' .. roll .. '</font>'
  local chance_str = '<font color="yellow">' .. chance .. '</font>'
  local msg_str = '<font color="' .. msg_color .. '">' .. msg .. '</font>'

  local str = "Roll: " .. roll_str .. "  Goal: " .. chance_str .. "  by " .. name .. " - " .. msg_str

  GameRules:SendCustomMessage(str, 0, 1)
  if roll > chance then
    -- Particles
    local part = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(part, 0, caster:GetAbsOrigin() + Vector(0, 0, 100))

    -- Spawning courier to fetch cheese
    local player = caster:GetPlayerOwner()
    local courier = player:SpawnCourierAtPosition(caster:GetAbsOrigin())

    -- Removing controls from courier
    courier:SetControllableByPlayer(-1, false)
    for i = 0,16 do
			local abil = courier:GetAbilityByIndex(i)
			if abil then
				courier:RemoveAbility(abil:GetAbilityName())
			end
    end
    courier:SetControllableByPlayer(-1, false)
    courier:AddAbility("patrol_unit_passive"):SetLevel(1)

    DeepPrintTable(_G.Cheeses)
    -- Courier AI fetching and loitering
    Timers:CreateTimer(2, function()
      if IsValidEntity(courier) then
        local itemInSlot = courier:GetItemInSlot(0)

        local type = "dropped"
        local isFetching = not (itemInSlot == nil)
        for k,v in pairs(_G.Cheeses) do
          local temp = EntIndexToHScript(k)
          if temp ~= nil then
            if temp:GetItemSlot() < 0 then
              isFetching = true
            end
          end
          if v == "spawned" then
            type = "spawned"
          end
        end

        if TableLength(_G.Cheeses) > 0 and isFetching then
          if itemInSlot == nil then
            -- Go collect a cheese
            local randKey = GetRandomTableKey(_G.Cheeses)
            local randCheese = EntIndexToHScript(randKey)

            if _G.Cheeses[randKey] == type then
              print("Retreiving cheese with id", randKey)
              if randCheese ~= nil then
                courier:PickupDroppedItem(randCheese:GetContainer())
              end

              itemInSlot = courier:GetItemInSlot(0)
              if not (itemInSlot == nil) then   -- Cheese in inventory
                print(itemInSlot:GetEntityIndex(), randKey)
                courier.key = itemInSlot:GetEntityIndex()

                _G.Cheeses[randKey] = "inventory"
              else
                courier.returning = false
              end
            end
            return 2
          else
            print("Dropping item off to owner", itemInSlot:GetEntityIndex())
            _G.Cheeses[itemInSlot:GetEntityIndex()] = "dropped"
            courier:DropItemAtPosition(caster:GetAbsOrigin(), itemInSlot)

            return 1
          end
        else
          print("No more cheeses, moving around hero now")
          local r = 500
          local posOwner = caster:GetAbsOrigin()

          local randRad = RandomFloat(50, r)
          local randTheta = math.rad(RandomFloat(0, 360))

          local x = posOwner.x + randRad * math.cos(randTheta)
          local y = posOwner.y + randRad * math.sin(randTheta)

          courier:MoveToPosition(Vector(x, y, 128))
          return 15
        end
      else
        return
      end
    end)
  end

  --print("Emitting sound")
  EmitSoundOn(sound_cast, caster)

  ability:SpendCharge(0.01)
end

item_patreon_get_cheese2 = item_patreon_get_cheese1 or class({})