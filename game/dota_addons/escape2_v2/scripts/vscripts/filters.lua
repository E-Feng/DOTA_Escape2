-- Order Filter; order can be casting an ability, moving, clicking to attack, using scan (radar), glyph etc.
function barebones:OrderFilter(filter_table)
	--PrintTable(filter_table)

	local order = filter_table.order_type
	local units = filter_table.units
	local playerID = filter_table.issuer_player_id_const

	-- Order enums:
	-- DOTA_UNIT_ORDER_NONE = 0
	-- DOTA_UNIT_ORDER_MOVE_TO_POSITION = 1
	-- DOTA_UNIT_ORDER_MOVE_TO_TARGET = 2
	-- DOTA_UNIT_ORDER_ATTACK_MOVE = 3
	-- DOTA_UNIT_ORDER_ATTACK_TARGET = 4
	-- DOTA_UNIT_ORDER_CAST_POSITION = 5
	-- DOTA_UNIT_ORDER_CAST_TARGET = 6
	-- DOTA_UNIT_ORDER_CAST_TARGET_TREE = 7
	-- DOTA_UNIT_ORDER_CAST_NO_TARGET = 8
	-- DOTA_UNIT_ORDER_CAST_TOGGLE = 9
	-- DOTA_UNIT_ORDER_HOLD_POSITION = 10
	-- DOTA_UNIT_ORDER_TRAIN_ABILITY = 11
	-- DOTA_UNIT_ORDER_DROP_ITEM = 12
	-- DOTA_UNIT_ORDER_GIVE_ITEM = 13
	-- DOTA_UNIT_ORDER_PICKUP_ITEM = 14
	-- DOTA_UNIT_ORDER_PICKUP_RUNE = 15
	-- DOTA_UNIT_ORDER_PURCHASE_ITEM = 16
	-- DOTA_UNIT_ORDER_SELL_ITEM = 17
	-- DOTA_UNIT_ORDER_DISASSEMBLE_ITEM = 18
	-- DOTA_UNIT_ORDER_MOVE_ITEM = 19
	-- DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO = 20
	-- DOTA_UNIT_ORDER_STOP = 21
	-- DOTA_UNIT_ORDER_TAUNT = 22
	-- DOTA_UNIT_ORDER_BUYBACK = 23
	-- DOTA_UNIT_ORDER_GLYPH = 24
	-- DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH = 25
	-- DOTA_UNIT_ORDER_CAST_RUNE = 26
	-- DOTA_UNIT_ORDER_PING_ABILITY = 27
	-- DOTA_UNIT_ORDER_MOVE_TO_DIRECTION = 28
	-- DOTA_UNIT_ORDER_PATROL = 29
	-- DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION = 30
	-- DOTA_UNIT_ORDER_RADAR = 31
	-- DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK = 32
	-- DOTA_UNIT_ORDER_CONTINUE = 33
	-- DOTA_UNIT_ORDER_VECTOR_TARGET_CANCELED = 34
	-- DOTA_UNIT_ORDER_CAST_RIVER_PAINT = 35
	-- DOTA_UNIT_ORDER_PREGAME_ADJUST_ITEM_ASSIGNMENT = 36

	-- Example 1: If the order is an ability
	if order == DOTA_UNIT_ORDER_CAST_POSITION or order == DOTA_UNIT_ORDER_CAST_TARGET or order == DOTA_UNIT_ORDER_CAST_NO_TARGET or order == DOTA_UNIT_ORDER_CAST_TOGGLE or order == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
		local ability_index = filter_table.entindex_ability
		local ability = EntIndexToHScript(ability_index)
		local caster = EntIndexToHScript(units["0"])
	end

	-- Example 2: If the order is a simple move command
	if order == DOTA_UNIT_ORDER_MOVE_TO_POSITION and units["0"] then
		local unit_with_order = EntIndexToHScript(units["0"])
		local destination_x = filter_table.position_x
		local destination_y = filter_table.position_y
    end
	
	if DISABLE_ITEM_STEALING_FROM_COURIER then
		if order == DOTA_UNIT_ORDER_DROP_ITEM or order == DOTA_UNIT_ORDER_GIVE_ITEM then
			local unit_with_order = EntIndexToHScript(units["0"])
			local ability_index = filter_table.entindex_ability
			local ability = EntIndexToHScript(ability_index)

			if unit_with_order:IsCourier() and ability and ability:IsItem() then
				local purchaser = ability:GetPurchaser()
				if purchaser and purchaser:GetPlayerID() ~= playerID then
					CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#hud_error_courier_cant_order_item" })
					return false
				end
			end
		end
	end

	return true
end

-- Damage filter function
function barebones:DamageFilter(keys)
	--PrintTable(keys)

	local attacker
	local victim
	if keys.entindex_attacker_const and keys.entindex_victim_const then
		attacker = EntIndexToHScript(keys.entindex_attacker_const)
		victim = EntIndexToHScript(keys.entindex_victim_const)
	else
		return false
	end

	local damage_type = keys.damagetype_const
	local inflictor = keys.entindex_inflictor_const	-- keys.entindex_inflictor_const is nil if damage is not caused by an ability
	local damage_after_reductions = keys.damage 	-- keys.damage is damage after reductions without spell amplifications

	-- Damage types:
	-- DAMAGE_TYPE_NONE = 0
	-- DAMAGE_TYPE_PHYSICAL = 1
	-- DAMAGE_TYPE_MAGICAL = 2
	-- DAMAGE_TYPE_PURE = 4
	-- DAMAGE_TYPE_ALL = 7
	-- DAMAGE_TYPE_HP_REMOVAL = 8

	-- Find the ability/item that dealt the dmg, if normal attack or no ability/item it will be nil
	local damaging_ability
	if inflictor then
		damaging_ability = EntIndexToHScript(inflictor)
	else
		damaging_ability = nil
	end

	-- Lack of entities handling (illusions error fix)
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Update the gold bounty of the hero before he dies
	if USE_CUSTOM_HERO_GOLD_BOUNTY then
		if attacker:IsControllableByAnyPlayer() and victim:IsRealHero() and damage_after_reductions >= victim:GetHealth() then
			-- Get his killing streak
			local hero_streak = victim:GetStreak()
			-- Get his level
			local hero_level = victim:GetLevel()
			-- Adjust Gold bounty
			local gold_bounty
			if hero_streak > 2 then
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*HERO_KILL_GOLD_PER_STREAK
			else
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
			end

			victim:SetMinimumGoldBounty(gold_bounty)
			victim:SetMaximumGoldBounty(gold_bounty)
		end
	end

	return true
end

-- Modifier (buffs, debuffs) filter function
function barebones:ModifierFilter(keys)
	--PrintTable(keys)

	local unit_with_modifier = EntIndexToHScript(keys.entindex_parent_const)
	local modifier_name = keys.name_const
	local modifier_duration = keys.duration
	local modifier_caster
	if keys.entindex_caster_const then
		modifier_caster = EntIndexToHScript(keys.entindex_caster_const)
	else
		modifier_caster = nil
	end

	return true
end

-- Experience filter function
function barebones:ExperienceFilter(keys)
	--PrintTable(keys)
	local experience = keys.experience
	local playerID = keys.player_id_const
	local reason = keys.reason_const

	-- Reasons:
	--DOTA_ModifyXP_Unspecified		0
	--DOTA_ModifyXP_HeroKill		1
	--DOTA_ModifyXP_CreepKill		2
	--DOTA_ModifyXP_RoshanKill		3

	return true
end

-- Tracking Projectile (attack and spell projectiles) filter function
function barebones:ProjectileFilter(keys)
	--PrintTable(keys)

	local can_be_dodged = keys.dodgeable				-- values: 1 for yes or 0 for no
	local ability_index = keys.entindex_ability_const	-- value if not ability: -1
	local source_index = keys.entindex_source_const
	local target_index = keys.entindex_target_const
	local expire_time = keys.expire_time
	local is_an_attack_projectile = keys.is_attack		-- values: 1 for yes or 0 for no
	local max_impact_time = keys.max_impact_time
	local projectile_speed = keys.move_speed

	return true
end

-- Bounty Rune Filter, can be used to modify Alchemist's Greevil Greed for example
function barebones:BountyRuneFilter(keys)
	--PrintTable(keys)

	local gold_bounty = keys.gold_bounty
	local playerID = keys.player_id_const
	local xp_bounty = keys.xp_bounty		-- value: 0

	return true
end

-- Rune filter, can be used to modify what runes spawn and don't spawn, can be used to replace runes
function barebones:RuneSpawnFilter(keys)
	--PrintTable(keys)

	local rune = keys.rune_type
	local spawner_index = keys.spawner_entindex_const

	-- Rune enums:
	-- DOTA_RUNE_INVALID		-1
	-- DOTA_RUNE_DOUBLEDAMAGE	0
	-- DOTA_RUNE_HASTE			1
	-- DOTA_RUNE_ILLUSION		2
	-- DOTA_RUNE_INVISIBILITY	3
	-- DOTA_RUNE_REGENERATION	4
	-- DOTA_RUNE_BOUNTY			5
	-- DOTA_RUNE_ARCANE			6

	-- local number_of_runes = 6
	-- keys.rune_type = RandomInt(0, number_of_runes)

	-- local random_number =  RandomFloat(0, 100)
	-- local chance_to_spawn = 100/number_of_runes
	-- if random_number <= chance_to_spawn then
		-- keys.rune_type = DOTA_RUNE_DOUBLEDAMAGE
	-- elseif random_number > chance_to_spawn and random_number <= 2*chance_to_spawn then
		-- keys.rune_type = DOTA_RUNE_HASTE
	-- elseif random_number > 2*chance_to_spawn and random_number <= 3*chance_to_spawn then
		-- keys.rune_type = DOTA_RUNE_ILLUSION
	-- elseif random_number > 3*chance_to_spawn and random_number <= 4*chance_to_spawn then
		-- keys.rune_type = DOTA_RUNE_INVISIBILITY
	-- elseif random_number > 4*chance_to_spawn and random_number <= 5*chance_to_spawn then
		-- keys.rune_type = DOTA_RUNE_REGENERATION
	-- else
		-- keys.rune_type = DOTA_RUNE_ARCANE
	-- end

	return true
end

-- Healing Filter, can be used to modify how much hp regen and healing a unit is gaining
-- Triggers every time a unit gains health
function barebones:HealingFilter(keys)
	--PrintTable(keys)

	local healing_target_index = keys.entindex_target_const
	local heal_amount = keys.heal -- heal amount of the ability or health restored with hp regen during server tick

	local healer_index
	if keys.entindex_healer_const then
		healer_index = keys.entindex_healer_const
	end

	local healing_ability_index
	if keys.entindex_inflictor_const then
		healing_ability_index = keys.entindex_inflictor_const
	end

	local healing_target = EntIndexToHScript(healing_target_index)

	-- Find the source of the heal - the healer
	local healer
	if healer_index then
		healer = EntIndexToHScript(healer_index)
	else
		healer = healing_target -- hp regen
	end

	-- Find healing ability
	-- Abilities that give bonus hp regen don't count as healing abilities!!!
	local healing_ability
	if healing_ability_index then
		healing_ability = EntIndexToHScript(healing_ability_index)
	else
		healing_ability = nil -- hp regen
	end

	return true
end

-- Gold filter, can be used to modify how much gold player gains/loses
function barebones:GoldFilter(keys)
	--PrintTable(keys)

	local gold = keys.gold
	local playerID = keys.player_id_const
	local reason = keys.reason_const
	local reliable = keys.reliable

	-- Reasons:
	-- DOTA_ModifyGold_Unspecified = 0
	-- DOTA_ModifyGold_Death = 1
	-- DOTA_ModifyGold_Buyback = 2
	-- DOTA_ModifyGold_PurchaseConsumable = 3
	-- DOTA_ModifyGold_PurchaseItem = 4
	-- DOTA_ModifyGold_AbandonedRedistribute = 5
	-- DOTA_ModifyGold_SellItem = 6
	-- DOTA_ModifyGold_AbilityCost = 7
	-- DOTA_ModifyGold_CheatCommand = 8
	-- DOTA_ModifyGold_SelectionPenalty = 9
	-- DOTA_ModifyGold_GameTick = 10
	-- DOTA_ModifyGold_Building = 11
	-- DOTA_ModifyGold_HeroKill = 12
	-- DOTA_ModifyGold_CreepKill = 13
	-- DOTA_ModifyGold_RoshanKill = 14
	-- DOTA_ModifyGold_CourierKill = 15
	-- DOTA_ModifyGold_SharedGold = 16

	-- Disable all hero kill gold
	if DISABLE_ALL_GOLD_FROM_HERO_KILLS then
		if reason == DOTA_ModifyGold_HeroKill then
			return false
		end
	end

	return true
end

-- Inventory filter, triggers every time a unit picks up or buys an item, doesn't trigger when you change item's slot inside inventory
function barebones:InventoryFilter(keys)
	--PrintTable(keys)

	local unit_with_inventory_index = keys.inventory_parent_entindex_const -- -1 if not defined
	local item_index = keys.item_entindex_const
	local owner_index = keys.item_parent_entindex_const -- -1 if not defined
	local item_slot = keys.suggested_slot -- slot in which the item should be put, usually its -1 meaning put in the first free slot

	-- Item slots:
	-- Inventory slots: DOTA_ITEM_SLOT_1 - DOTA_ITEM_SLOT_9
	-- Backpack slots: DOTA_ITEM_SLOT_7 - DOTA_ITEM_SLOT_9
	-- Stash slots: DOTA_STASH_SLOT_1 - DOTA_STASH_SLOT_6
	-- Teleport scroll slot: 15? (no enum)
	-- Neutral item slot: 16? (no enum)

	local unit_with_inventory
	local unit_name
	if unit_with_inventory_index ~= -1 then
		unit_with_inventory = EntIndexToHScript(unit_with_inventory_index)
		unit_name = unit_with_inventory:GetUnitName()
	end

	local item = EntIndexToHScript(item_index)
	local item_name = item:GetName()

	local owner_of_this_item
	if owner_index ~= -1 then
		-- not reliable
		owner_of_this_item = EntIndexToHScript(owner_index)
	else
		owner_of_this_item = item:GetPurchaser()
	end

	local owner_name
	if owner_of_this_item then
		owner_name = owner_of_this_item:GetUnitName()
	end

	if not TELEPORT_SCROLL_ON_START then
		if item:GetAbilityName() == "item_tpscroll" and item:GetPurchaser() == nil then
			return false
		end
	end

	return true
end
