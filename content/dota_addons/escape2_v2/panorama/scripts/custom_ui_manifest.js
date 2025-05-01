function HidePickScreen() {
  $.Msg("HidePickScreen function running");
  var dotaHud = $.GetContextPanel().GetParent().GetParent();
  if (Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    dotaHud.FindChild("PreGame").visible = false;
  }
  else if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_HERO_SELECTION)) {
    dotaHud.FindChild("PreGame").visible = true;
  }
  else if (Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_PRE_GAME)) {
    dotaHud.FindChild("PreGame").visible = false;
  }
}
(function()
{
  GameEvents.Subscribe( "game_rules_state_change", HidePickScreen );
})();

GameUI.CustomUIConfig().multiteam_top_scoreboard =
{
  reorder_team_scores: true,
  LeftInjectXMLFile: "file://{resources}/layout/custom_game/overthrow_scoreboard_left.xml",
  TeamOverlayXMLFile: "file://{resources}/layout/custom_game/overthrow_scoreboard_team_overlay.xml"
};

// Uncomment any of the following lines in order to disable that portion of the default UI

//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );      		//Time of day (clock).
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );     			//Heroes and team score at the top of the HUD.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );      	//Lefthand flyout scoreboard.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false );     		//Hero actions UI.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false );     		//Minimap.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false );      	//Entire Inventory UI
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );     		//Shop portion of the Inventory. 
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, false );      	//Player items.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );     	//Quickbuy.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );      	//Courier controls.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );      	//Glyph.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );     		//Gold display.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );      //Suggested items shop panel.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false );     //Hero selection Radiant and Dire player lists.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false ); //Hero selection game mode name display.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );     //Hero selection clock.
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false );     	//Top-left menu buttons in the HUD.
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );      			//Endgame scoreboard.    
//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false );     	//Top-left menu buttons in the HUD.

// These lines set up the panorama colors used by each team (for game select/setup, etc)
GameUI.CustomUIConfig().team_colors = {}
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#3dd296;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#F3C909;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = "#c54da8;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = "#FF6C00;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = "#3455FF;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = "#65d413;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = "#815336;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = "#1bc0d8;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = "#c7e40d;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = "#8c2af4;";

GameUI.CustomUIConfig().team_colors_copy = {}
GameUI.CustomUIConfig().team_colors_copy[0] = "#3dd296;";
GameUI.CustomUIConfig().team_colors_copy[1] = "#F3C909;";
GameUI.CustomUIConfig().team_colors_copy[2] = "#c54da8;";
GameUI.CustomUIConfig().team_colors_copy[3] = "#FF6C00;";
GameUI.CustomUIConfig().team_colors_copy[4] = "#3455FF;";
GameUI.CustomUIConfig().team_colors_copy[5] = "#65d413;";
GameUI.CustomUIConfig().team_colors_copy[6] = "#815336;";
GameUI.CustomUIConfig().team_colors_copy[7] = "#1bc0d8;";
GameUI.CustomUIConfig().team_colors_copy[8] = "#c7e40d;";
GameUI.CustomUIConfig().team_colors_copy[9] = "#8c2af4;";

$.Msg("Configuring default dota HUD");
var hud = $.GetContextPanel().GetParent();
for(var i = 0; i < 100; i++) {
    if(hud.id != "Hud") {
        hud = hud.GetParent();
    } else {
        break;
    }
}

// Moving the clock on the top HUD
var timeBlock = hud.FindChildTraverse("TimeOfDay");
timeBlock.style.horizontalAlign="left";

var timeBlockBG = hud.FindChildTraverse("TimeOfDayBG");
timeBlockBG.style.horizontalAlign="left";

var timeBlockUntil = hud.FindChildTraverse("TimeUntil");
timeBlockUntil.style.visibility="collapse";

// Hiding talent tree
var talentTree = hud.FindChildTraverse("StatBranch");
talentTree.style.visibility="collapse";		

// Adjusting minimap and hiding glyph
var glyph = hud.FindChildTraverse("GlyphScanContainer");
glyph.style.visibility="collapse";	

var minimap = hud.FindChildTraverse("minimap");
var minimapBlock = hud.FindChildTraverse("minimap_block");
minimap.style.width="260px";
minimap.style.height="260px";
minimapBlock.style.width="260px";
minimapBlock.style.height="260px";			

// Moving combat events up. combat_events or ToastLinesWrapper
var combatEvents = hud.FindChildTraverse("combat_events");
combatEvents.style.marginTop="260px";   // 395px default