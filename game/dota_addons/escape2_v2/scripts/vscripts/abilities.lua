function GateMove(event)
    print("GateMove started, gate moving now")
    local gate_move = EntIndexToHScript(event.caster_entindex)
    local origin = gate_move:GetAbsOrigin()
    local level = GameRules.CLevel
    gate_move:SetMana(0)
    for i,entvals in pairs(EntList[level]) do
        if entvals[ENT_INDEX] == event.caster_entindex then
            local pos = Entities:FindByName(nil, entvals[GAT_MOVES]):GetAbsOrigin()
            gate_move:AddAbility("gate_unselectable"):SetLevel(1)
            gate_move:MoveToPosition(pos)
            if entvals[GAT_MVBCK] then
            	Timers:CreateTimer(4, function()
            		gate_move:RemoveAbility("gate_unselectable")
            		gate_move:RemoveModifierByName("patrol_unit_state")
                	gate_move:MoveToPosition(origin)
                	Timers:CreateTimer(6, function()
                    	gate_move:SetMana(5-entvals[GAT_NUMBR])
                	end)
            	end)
            end
        end
    end
end