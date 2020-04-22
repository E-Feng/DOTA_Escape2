function MangoEaten( event )
    local mana = event.mana_amount
    local level = GameRules.CLevel
    local item = event.ability
    local itemid = item:GetEntityIndex()
    for i,entvals in pairs(EntList[level]) do
        if entvals[ENT_INDEX] == itemid then
            if entvals[MNG_RSPWN] then
                local newitem = CreateItem(Ents[ENT_MANGO], nil, nil)
                local pos = Entities:FindByName(nil, entvals[ENT_SPAWN]):GetAbsOrigin()
                CreateItemOnPositionSync(pos, newitem)
                EntList[level][i][ENT_INDEX] = newitem:GetEntityIndex()
            else
                EntList[level][i][ENT_INDEX] = 0
            end
            if not entvals[MNG_MREAL] then
                mana = 0
            end
        end
    end
    event.target:GiveMana(mana)
end

function CheeseEaten(event)
    local lifeGained = event.life_gained
    GameRules.Lives = GameRules.Lives + lifeGained
    local str = "Cheese eaten! " .. tostring(GameRules.Lives) .. " lives remaining!"
    local msg = {
                  text = str,
                  duration = 2.0,
                  style={color="red", ["font-size"]="80px"}
                }
    Notifications:TopToAll(msg)
    GameRules:SendCustomMessage(str, 0, 1)
end

function DropItemOnDeath(event) 
    local killedUnit = EntIndexToHScript( event.caster_entindex )
    local itemName = tostring(event.ability:GetAbilityName())
    local itemid = event.ability:GetEntityIndex()
    local level = GameRules.CLevel
    if killedUnit:IsHero() or killedUnit:HasInventory() then
        for itemSlot = 0, 5, 1 do 
            if killedUnit ~= nil then --checks to make sure the killed unit is not nonexistent.
                local item = killedUnit:GetItemInSlot( itemSlot ) -- uses a variable which gets the actual item in the slot specified starting at 0, 1st slot, and ending at 5,the 6th slot.
                if item ~= nil and item:GetName() == itemName then -- makes sure that the item exists and making sure it is the correct item
                    local newItem = CreateItem(itemName, nil, nil) -- creates a new variable which recreates the item we want to drop and then sets it to have no owner
                    CreateItemOnPositionSync(killedUnit:GetOrigin(), newItem) -- takes the newItem variable and creates the physical item at the killed unit's location
                    for i,entvals in pairs(EntList[level]) do
                        if entvals[ENT_INDEX] == itemid then
                            EntList[level][i][ENT_INDEX] = newItem:GetEntityIndex()
                        end
                    end
                    killedUnit:RemoveItem(item) -- finally, the item is removed from the original units inventory.
                end
            end
        end
    end
end