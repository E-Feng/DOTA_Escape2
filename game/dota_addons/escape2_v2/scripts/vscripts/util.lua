function DebugPrint(...)
	if USE_DEBUG then
		print(...)
	end
end

function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

-- Requires an element and a table, returns true if element is in the table.
function TableContains(t, element)
    if t == nil then return false end
    for k,v in pairs(t) do
        if v == element then
            return true
        end
    end
    return false
end

-- Return length of the table even if the table is nil or empty
function TableLength(t)
    if t == nil or t == {} then
        return 0
    end
    local length = 0
    for k,v in pairs(t) do
        length = length + 1
    end
    return length
end

-- Return key of table from given value in subkey
function GetTableKeyFromValue(tbl, subkey, val)
  for k, v in pairs(tbl) do
      if v[subkey] == val then return k end
  end
  return nil
end

function GetRandomTableElement(t)
    -- iterate over whole table to get all keys
    local keyset = {}
    for k in pairs(t) do
        table.insert(keyset, k)
    end
    -- now you can reliably return a random key
    return t[keyset[RandomInt(1, #keyset)]]
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

function DebugAllCalls()
    if not GameRules.DebugCalls then
        print("Starting DebugCalls")
        GameRules.DebugCalls = true

        debug.sethook(function(...)
            local info = debug.getinfo(2)
            local src = tostring(info.short_src)
            local name = tostring(info.name)
            if name ~= "__index" then
                print("Call: ".. src .. " -- " .. name .. " -- " .. info.currentline)
            end
        end, "c")
    else
        print("Stopped DebugCalls")
        GameRules.DebugCalls = false
        debug.sethook(nil, "c")
    end
end

-- Author: Noya
-- This function hides all dota item cosmetics (hats/wearables) from the hero/unit and store them into a handle variable
function HideWearables(unit)
	unit.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
    local model = unit:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW) -- Set model hidden
            table.insert(unit.hiddenWearables, model)
        end
        model = model:NextMovePeer()
    end
end

-- Author: Noya
-- This function un-hides (shows) wearables that were hidden with HideWearables() function.
function ShowWearables(unit)
	for i,v in pairs(unit.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end

-- Author: Noya
-- This function changes (swaps) dota item cosmetic models (hats/wearables)
function SwapWearable(unit, target_model, new_model)
    local wearable = unit:FirstMoveChild()
    while wearable ~= nil do
        if wearable:GetClassname() == "dota_item_wearable" then
            if wearable:GetModelName() == target_model then
                wearable:SetModel(new_model)
                return
            end
        end
        wearable = wearable:NextMovePeer()
    end
end

-- This function checks if a given unit is Roshan, returns boolean value;
function CDOTA_BaseNPC:IsRoshan()
	if self:IsAncient() and self:GetUnitName() == "npc_dota_roshan" then
		return true
	end
	
	return false
end

-- This function checks if this entity is a fountain or not; returns boolean value;
function CBaseEntity:IsFountain()
	if self:GetName() == "ent_dota_fountain_bad" or self:GetName() == "ent_dota_fountain_good" then
		return true
	end
	
	return false
end

-- Author: Noya
-- This function is showing custom Error Messages using notifications library
function SendErrorMessage(pID, string)
  if Notifications then
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
  end
  EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

function CalcDist(pos1, pos2)
  dist = math.sqrt(math.pow(pos1.x - pos2.x,2) + math.pow(pos1.y - pos2.y,2) + math.pow(pos1.z - pos2.z,2))
  --print("Calcuate distance is ", dist)
  return dist
end

function CalcDist2D(pos1, pos2)
  dist = math.sqrt(math.pow(pos1.x - pos2.x,2) + math.pow(pos1.y - pos2.y,2))
  --print("Calcuate distance is ", dist)
  return dist
end

function AveragePos(pos1, pos2)
  dist = Vector((pos1.x + pos2.x)/2, (pos1.y + pos2.y)/2, (pos1.z + pos2.z)/2)
  return dist
end

function CopyTable(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function DotProduct(v1, v2)
  return Vector(v1.x*v2.x, v1.y*v2.y, v1.z*v2.z)
end

function ReverseTable(t)
  for i=1, math.floor(#t / 2) do
    t[i], t[#t - i + 1] = t[#t - i + 1], t[i]
  end
end

function VectorToFlatAngle(vec)
  local x = vec.x
  local y = vec.y
  return math.deg(math.atan2(y,x))
end

function RotateVector2D(v,theta)
  local theta = math.rad(theta)
  local xp = v.x*math.cos(theta)-v.y*math.sin(theta)
  local yp = v.x*math.sin(theta)+v.y*math.cos(theta)
  return Vector(xp,yp,v.z):Normalized()
end

function OutsideRectangle(unit, tl, br)
  local pos = unit:GetAbsOrigin()
  local xmax = br.x
  local xmin = tl.x
  local ymax = tl.y
  local ymin = br.y
  return pos.x > xmax or pos.x < xmin or pos.y > ymax or pos.y < ymin
end

function AdditionTables(t1, t2)
  local t3 = {}
  for i,val in pairs(t2) do
    t3[i] = t1[i] or val
  end
  return t3
end

function PrintLogicalTable(t1)
  local str = ""
  for i,v in pairs(t1) do
    if v then
      str = str .. "X"
    else
      str = str .. "-"
    end
  end
  return str
end

function GetNumberInsideRectangle(tl, br, alive)
  local count = 0
  for _,hero in pairs(Players) do
    if not OutsideRectangle(hero, tl, br) and hero:IsAlive() == alive then
      count = count + 1
    end
  end
  return count
end