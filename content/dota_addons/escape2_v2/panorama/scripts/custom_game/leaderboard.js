"use strict";

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_SetTextSafe( panel, childName, textValue )
{
	if ( panel === null )
		return;
	var childPanel = panel.FindChildInLayoutFile( childName )
	if ( childPanel === null )
		return;
	
	childPanel.text = textValue;
}

//=============================================================================
//=============================================================================
function _ScoreboardUpdater_SetStyleSafe( panel, childName, styleName, styleValue )
{
	if ( panel === null )
		return;
	var childPanel = panel.FindChildInLayoutFile( childName )
	if ( childPanel === null )
		return;
	
	childPanel.style[styleName] = styleValue;
}

function updateLeaderboard(container, arr, place) {
	//$.Msg("Updating leaderboard of: ", container.id);
	var rank = 1;
	if (arr.length == 1) {
		rank = "";
	}
	if (place == -2) {
		rank = "alltime";
	}

	for (var entry of arr) {
		$.Msg(entry);
		var entryPanel = $.CreatePanel("Panel", container, rank.toString());
		entryPanel.BLoadLayoutSnippet("LeaderboardRow");

		var players = Object.values(entry.players);
		var split = entry.timesplits;

		var total = 0
		players.forEach(player => (total = total + player.length))

		var playerString = '';
		for (var player of players) {
			var str = player
			if (total > 100) {
				str = str.substring(0, 20);
			}
			playerString = playerString + str + ', ';
		}
		playerString = playerString.substring(0, playerString.length - 2);
		//$.Msg("Total ", playerString.length);

		// Updating all time line
		if (place == -2) {
			rank = "ALL\nTIME";
			_ScoreboardUpdater_SetStyleSafe( entryPanel, "Rank", "fontSize", "16px"); 
			_ScoreboardUpdater_SetStyleSafe( entryPanel, "Rank", "textAlign", "center");
			_ScoreboardUpdater_SetStyleSafe( entryPanel, "Rank", "textOverflow", "shrink");
			entryPanel.style["borderBottom"] = "4px solid #cccccc";
			entryPanel.style["marginBottom"] = "4px"; 
		}

		_ScoreboardUpdater_SetTextSafe( entryPanel, "Rank", rank); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Time", convertSecondsToNiceString(entry.totaltime));
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Players", players.length); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "DeathCount", entry.deaths); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Lives", entry.lives); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Level1", convertSecondsToNiceString(split["1"])); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Level2", convertSecondsToNiceString(split["2"])); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Level3", convertSecondsToNiceString(split["3"])); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Level4", convertSecondsToNiceString(split["4"])); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Level5", convertSecondsToNiceString(split["5"])); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Level6", convertSecondsToNiceString(split["6"])); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "PlayerNames", playerString); 

		if (playerString.length > 150 ) {
			_ScoreboardUpdater_SetStyleSafe( entryPanel, "PlayerNames", "fontSize", "12px"); 
		}
		else if (playerString.length > 120) {
			_ScoreboardUpdater_SetStyleSafe( entryPanel, "PlayerNames", "fontSize", "14px"); 
		}

		if (place == rank) {
			entryPanel.style["boxShadow"] = "inset #00ff0040 0px 0px 20px 20px";
		}

		rank = rank + 1;
	}
}

function showConnectError(container) {
	$.Msg("Showing error container")
	var errorPanel = $.CreatePanel("Label", container, "error");
	errorPanel.text = $.Localize("#database_connection_error");
	errorPanel.style.color = "#FF0000;";
	errorPanel.style.fontSize = "48px;";
}

function convertSecondsToNiceString(total) {
	var min = Math.floor(total/60);
	var sec = total % 60;

	sec = sec.toString().padStart(2, "0");

	return min.toString() + ":" + sec;
}

function sortAndTrimArray(arr, len) {
	arr.sort((a, b) => (a.totaltime > b.totaltime) ? 1 : (a.totaltime == b.totaltime) ? ((a.deaths > b.deaths) ? 1 : -1) : -1);
	var newArr = arr.slice(0, len);
	return newArr;
}

function DataLoaded(tableName, key, data) {
	$.Msg("Data loaded, updating leaderboard now for: ", key);
	//$.Msg(tableName, key, data);
	var data = CustomNetTables.GetTableValue("leaderboard", key);

	if (data === undefined) {
		$.Msg("No data loaded into net tables yet, returning")
		return
	}

	// Getting UI containers
	var leaderboardContainer = $("#LeaderboardContainer");
	leaderboardContainer.RemoveAndDeleteChildren();

	if (Object.keys(data).length === 0) {
		showConnectError(leaderboardContainer);
		return
	}

	// Processing data
	if (arr.length == 0) {
		for (var key in data) {
			var entry = data[key]
			arr.push(entry)
		}

		if (allTimes.length == 0) {
			allTimes.push(entry.totaltime);
		}
	}


	arr = sortAndTrimArray(arr, count);

	allTimes.sort((a,b) => (a > b) ? 1 : -1);
	allTimes = allTimes.slice(0, count);

	// Updating leaderboard
	updateLeaderboard(leaderboardContainer, [arr[0]], -2);
	updateLeaderboard(leaderboardContainer, arr.slice(1), -1)

	$.Msg("Finished loading leaderboard...")
}

function FinishedGame( table_name ) {
	$.Msg("Game has finished, updating gamescore now...")
	var leaderboardContainer = $("#LeaderboardContainer");
	var scoreContainer = $("#ScoreContainer");

	// Getting gamescore from table
	var rawData = CustomNetTables.GetAllTableValues("gamescore");
	var data = rawData["0"]["value"];

	//$.Msg(allTimes);
	//$.Msg("Time ", data.totaltime);

	var rank = 0;
	var c = 1;
	for (var time of allTimes) {
		//$.Msg("Time1 ", data.totaltime, " Time2 ", time);
		if (data.totaltime < time && rank == 0) {
			rank = c
		}
		c = c + 1;
	}
	//$.Msg("New rank ", rank);

	if (rank > 0) {
		arr.push(data);
		arr = sortAndTrimArray(arr, count);

		// Clear leaderboard and add in new record entry
		leaderboardContainer.RemoveAndDeleteChildren();
		updateLeaderboard(leaderboardContainer, arr, rank);
	}

	// Adding bottom scorecard
	//$.Msg(scoreContainer, leaderboardContainer);
	$.Msg('Printing score data');
	//$.Msg(data);
	updateLeaderboard(scoreContainer, [data], -1);
}

function UpdateWinners() {
	$.Msg("Updating winners table");
	var data = CustomNetTables.GetTableValue("winners", "winners");

	if (data === undefined) {
		$.Msg("No data loaded into net tables yet, returning")
		return
	}

	var container = $("#WinnersContainer");
	container.RemoveAndDeleteChildren();

	var winners = [];
	var len = 11;

	for (var key in data) {
		var entryData = data[key];
		winners.push(entryData);
	}

	winners.sort((a, b) => (parseInt(a.level) < parseInt(b.level)) ? 1 : -1);
	winners = winners.slice(0, len)
	$.Msg(winners);

	winners.forEach((winner, i) => {
		var entryPanel = $.CreatePanel("Panel", container, "winner" + i);
		entryPanel.BLoadLayoutSnippet("WinnerRow");

		_ScoreboardUpdater_SetTextSafe( entryPanel, "Name", winner.name); 
		_ScoreboardUpdater_SetTextSafe( entryPanel, "Level", winner.level); 
	})
}

$.Msg("Leaderboard.js function running");
//$.Msg($.GetContextPanel().layoutfile);
CustomNetTables.SubscribeNetTableListener( "leaderboard", DataLoaded );
CustomNetTables.SubscribeNetTableListener( "winners", UpdateWinners );

var layoutfile = $.GetContextPanel().layoutfile;
var arr = [];
var allTimes = [];
var count = 11;

/*
var leaderboardCleared = false

// Possible fix to leaderboard not rendering
var leaderboardInitialized = false
var winnersInitialized = false

if (!leaderboardInitialized) {
	$.Msg("Runninig initial leaderboard functions")
	DataLoaded(null, "alltime")
	DataLoaded(null, "leaderboard")
}
if (!winnersInitialized) {
	$.Msg("Runninig initial winners functions")
	UpdateWinners()
}
*/

//CustomNetTables.SubscribeNetTableListener( "gamescore", FinishedGame );

$.Msg(layoutfile);

if (layoutfile.indexOf("end_screen") > 0) {
	$.Msg("Loading endscreen leaderboard");
	var allTimeData = CustomNetTables.GetTableValue("leaderboard", "alltime");
	var leaderboardData = CustomNetTables.GetTableValue("leaderboard", "leaderboard");
	//$.Msg(allTimeData);
	//$.Msg(leaderboardData);
	DataLoaded("leaderboard", "alltime", allTimeData);
	DataLoaded("leaderboard", "leaderboard", leaderboardData);

	var rawData = CustomNetTables.GetAllTableValues("gamescore");
	if (rawData.hasOwnProperty("0")) {
		FinishedGame("gamescore");
	}
}
