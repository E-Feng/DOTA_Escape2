WebApi = WebApi or {}

local isTesting = IsInToolsMode() -- and false
local key = ""
local dedicatedServerKey = IsDedicatedServer() and GetDedicatedServerKeyV2("1.0") or key
local url = "https://dota-escape2.firebaseio.com/" .. dedicatedServerKey .. "/"

--CustomNetTables:SetTableValue("serverKey", "serverKey", key)

local leaderboard = {}
local gamescore
local numEntries = 0
local maxEntries = 20
local fastestTime = 1e9
local slowestTime = 0
local slowestId

function WebApi:GetLeaderboard()
  local request = CreateHTTPRequestScriptVM("GET", url .. ".json")
  request:Send(function(response)
    if response.StatusCode == 200 then
      print("GET request successful")
      local data = json.decode(response.Body)
      
      for _,v in pairs(data) do table.insert(leaderboard, v) end
      table.sort(leaderboard, function(a,b) return a.totaltime < b.totaltime end)

      numEntries = TableLength(leaderboard)
      fastestTime = leaderboard[1].totaltime
      slowestTime = leaderboard[numEntries].totaltime
      slowestId = GetTableKeyFromValue(data, "totaltime", slowestTime)

      slowestTime = math.min(slowestTime, 1440)

      local cropped = {unpack(leaderboard, 1, maxEntries)}
      CustomNetTables:SetTableValue("leaderboard", "leaderboard", cropped)
      
      if isTesting then
        --DeepPrintTable(leaderboard)
        --DeepPrintTable(cropped)
        print(TableLength(leaderboard), TableLength(cropped))
        print("Vals: ", numEntries, fastestTime, slowestTime, slowestId)
      end
      print("Get request finished")
    else
      print("GET request failed")
      CustomNetTables:SetTableValue("leaderboard", "leaderboard", {})
    end
  end)
end

function WebApi:InitGameScore()
  print("Initializing gamescore table")
  gamescore = {
		matchId = isTesting and RandomInt(1, 10000000) or tonumber(tostring(GameRules:GetMatchID())),
    date = GetSystemDate(),
    players = {},
    timesplits = {0, 0, 0, 0, 0, 0},
    deaths = 0,
    totaltime = 0,
    lives = 0
  }

  for playerId = 0, 9 do
		if PlayerResource:IsValidPlayer(playerId) and not PlayerResource:IsFakeClient(playerId) then
      local steamId = tostring(PlayerResource:GetSteamID(playerId))
      local name = PlayerResource:GetPlayerName(playerId)
      gamescore.players[steamId] = name
    elseif PlayerResource:IsFakeClient(playerId) then
      -- Testing with bots
      local steamId = tostring(RandomInt(1, 1000000))
      local name = PlayerResource:GetPlayerName(playerId)
      gamescore.players[steamId] = name
    end
  end
  DeepPrintTable(gamescore)

  -- Reading dedicated key purposes
  local cond1 = TableLength(gamescore.players) == 1 and TableLength(Players) == 1
  local cond2 = tostring(PlayerResource:GetSteamID(0)) == "76561197965802278" -- Thats me!
  local cond3 = PlayerResource:GetPlayerName(0) == "CakeCake" -- Thats me!
  local cond4 = GameRules:IsCheatMode()
  print(cond1, cond2, cond3, cond4)
  if cond1 and cond2 and cond3 and cond4 then
    print("Showing dedicated server key")
    local msg = {
      text = dedicatedServerKey,
      duration = 60,
      style = {color="red", ["font-size"]="48px"}
    }
    Notifications:BottomToAll(msg)
  end
end

function WebApi:UpdateTimeSplit(level)
  local index = level - 1
  if gamescore.timesplits[index] == 0 then
    print("Updating timesplit for previous level")
    local dotaTime = math.floor(GameRules:GetDOTATime(false, false))
    local total = 0
    for i = 1, index do
      total = total + gamescore.timesplits[i]
    end
    local time = dotaTime - total
    gamescore.timesplits[index] = time
  end
  DeepPrintTable(gamescore)
end

function WebApi:SendDeleteRequest()
  local deleteData = numEntries > maxEntries
  --local deleteData = true

  for _,entry in pairs(leaderboard) do
    --DeepPrintTable(entry)
    for _,time in pairs(entry.timesplits) do
      --print(time)
      if time == 0 then
        deleteData = false
      end
    end
  end

  print("To delete data: ", deleteData)

  if (deleteData and slowestId) then
    print("Sending delete request")
    local request = CreateHTTPRequestScriptVM("DELETE", url .. slowestId .. ".json")

    request:Send(function(response)
      if response.StatusCode == 200 then
        print("DELETE request successfully sent")
      else
        print("DELETE request failed to send")
      end
    end)
  end
end

function WebApi:FinalizeGameScoreAndSend()
  print("Finalizing gamescore table")
  local time = math.floor(GameRules:GetDOTATime(false, false))
  local deaths = 0
  for i,hero in pairs(Players) do
    deaths = deaths + hero:GetDeaths()
  end

  gamescore.deaths = deaths
  gamescore.totaltime = time
  gamescore.lives = GameRules.Lives
  --DeepPrintTable(gamescore)

  local sendData = false
  local cheats = Convars:GetBool("sv_cheats") or GameRules:IsCheatMode() or TableLength(gamescore.players) <= 1
  local isLegitGame = isTesting and true or not cheats

  if numEntries < maxEntries then
    sendData = true
  else
    if time < slowestTime then
      sendData = true
    end
  end

  print("Cheats: ", cheats)
  print("To send data: ", sendData)
  print("Legit game: ", isLegitGame)

  if isLegitGame then
    CustomNetTables:SetTableValue("gamescore", "gamescore", gamescore)
    if sendData then
      print("Sending PUT request to db")
      if isTesting then
        DeepPrintTable(gamescore)
      end

      local name = string.format("%05d", gamescore.totaltime) .. "_" .. tostring(gamescore.matchId)
      local request = CreateHTTPRequestScriptVM("PUT", url .. name .. ".json")
      request:SetHTTPRequestRawPostBody("application/json", json.encode(gamescore))

      request:Send(function(response) 
        if response.StatusCode == 200 then
          print("PUT request successfully sent")
          --DeepPrintTable(response)
        else
          print("PUT request failed to send")
        end
      end)
    end
  end
end