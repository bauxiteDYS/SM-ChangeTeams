#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>



#define TEAM_NONE 0
#define TEAM_SPECTATOR 1
#define TEAM_PUNK 2
#define TEAM_CORPS 3

public Plugin myinfo = {
	name = "Dys Team join chat commands, and admin force",
	description = "Use !s, !p, !c, to join Spec, Punks and Corps teams respectively, add f to force",
	author = "bauxite, rain",
	version = "0.1.1",
	url = "",
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_p", Cmd_Switch, "Change to Punks team");
	RegConsoleCmd("sm_c", Cmd_Switch, "Change to Corps team");
	RegConsoleCmd("sm_s", Cmd_Switch, "Change to Spectator team");
	
	RegAdminCmd("sm_pf", Cmd_SwitchForce, ADMFLAG_GENERIC);
	RegAdminCmd("sm_cf", Cmd_SwitchForce, ADMFLAG_GENERIC);
	RegAdminCmd("sm_sf", Cmd_SwitchForce, ADMFLAG_GENERIC);
	RegAdminCmd("sm_spec", Cmd_SwitchForce, ADMFLAG_GENERIC);
	
	RegAdminCmd("sm_forcespec", Cmd_ForceSpec, ADMFLAG_GENERIC);
}

void KillWithoutXpLoss(int client)
{
	FakeClientCommand(client, "kill");
}

public Action Cmd_ForceSpec(int client, int args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i))
		{
			if (IsPlayerAlive(i))
			{
				KillWithoutXpLoss(i);
			}
			
			FakeClientCommand(i, "jointeam 1");
		}
	}
	
	return Plugin_Handled;
}
// For a case-insensitive input character c, return the matching
// client index such that:
// 'j' == TEAM_JINRAI, 'n' == TEAM_NSF, 's' == TEAM_SPECTATOR.
// Anything else will return TEAM_NONE.

int GetTeamOfChar(char c)
{
	switch (CharToLower(c))
	{
		case 'p': return TEAM_PUNK;
		case 'c': return TEAM_CORPS;
		case 's': return TEAM_SPECTATOR;
	}
	return TEAM_NONE;
}

public Action Cmd_Switch(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command cannot be used by the server.");
		return Plugin_Handled;
	}

	char cmd_name[4 + 1];
	GetCmdArg(0, cmd_name, sizeof(cmd_name));

	char team_char = cmd_name[3];
	int requested_team = GetTeamOfChar(team_char);
	if (requested_team == TEAM_NONE)
	{
		ThrowError("Unknown team for cmd: \"%s\"", cmd_name);
	}

	int current_team = GetClientTeam(client);

	if (current_team == requested_team)
	{
		return Plugin_Handled;
	}

	if (IsPlayerAlive(client))
	{
		KillWithoutXpLoss(client);
	}

	FakeClientCommand(client, "jointeam %d", requested_team);

	return Plugin_Handled;
}

public Action Cmd_SwitchForce(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_(s/p/c)f TARGET");
		return Plugin_Handled;
	}
	
	char cmd_name[4 + 1];
	GetCmdArg(0, cmd_name, sizeof(cmd_name));
	
	char team_char = cmd_name[3];
	int requested_team = GetTeamOfChar(team_char);
	if (requested_team == TEAM_NONE)
	{
		ThrowError("Unknown team for cmd: \"%s\"", cmd_name);
	}
	
	char pattern[65];
	GetCmdArg(1, pattern, sizeof(pattern));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if((target_count = 
		ProcessTargetString(
		pattern,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_NO_IMMUNITY,
		target_name,
		sizeof(target_name),
		tn_is_ml)) 
		<= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	int current_team;
	int player;
	
	for (int i = 0; i < target_count; i++)
	{
		player = target_list[i];
		current_team = GetClientTeam(player);
		
		if(!IsClientInGame(player) || IsClientSourceTV(player))
		{
			continue;
		}
		
		if (current_team == requested_team)
		{
			continue;
		}
		
		if (IsPlayerAlive(player))
		{
			KillWithoutXpLoss(player);
		}

		FakeClientCommand(player, "jointeam %d", requested_team);
	}

	return Plugin_Handled;
}
