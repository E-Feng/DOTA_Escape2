"use strict";

function _ScoreboardUpdater_SetTextSafe( panel, childName, textValue )
{
	if ( panel === null )
		return;
	var childPanel = panel.FindChildInLayoutFile( childName )
	if ( childPanel === null )
		return;
	
	childPanel.text = textValue;
}

// Function to run upon being called
(function()
{
	$.Msg("leaderboard_header.js function running");
	//$.Msg($.GetContextPanel().layoutfile);

	const monthNames = ["January", "February", "March", "April", "May", "June",
  	"July", "August", "September", "October", "November", "December"];

	const date = new Date();
	const month = monthNames[date.getMonth()];
	const year = date.getFullYear();

	const text = "Season - " + month + " " + year;

	var seasonContainer = $("#SeasonContainer");

	_ScoreboardUpdater_SetTextSafe(seasonContainer, "SeasonDate", text)
})();
