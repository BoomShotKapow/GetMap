#include <sourcemod>
#include <convar_class>
#include <ripext>
#include <bzip2>

#pragma semicolon 1
#pragma newdecls required

Convar gCV_PublicURL = null;
Convar gCV_FastDLPath = null;
Convar gCV_ReplaceMap = null;

char gS_PublicURL[PLATFORM_MAX_PATH];
char gS_MapPath[PLATFORM_MAX_PATH];
char gS_FastDLPath[PLATFORM_MAX_PATH];

HTTPClient gHC_HttpClient = null;

public Plugin myinfo =
{
	name = "GetMap",
	author = "BoomShot",
	description = "Allows a user with !map privileges to download a map while in-game.",
	version = "1.0.0",
	url = "https://github.com/BoomShotKapow/GetMap"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_getmap", Command_GetMap, ADMFLAG_CHANGEMAP, "Download a bz2 compressed map file to use in the server");
	RegAdminCmd("sm_downloadmap", Command_GetMap, ADMFLAG_CHANGEMAP, "Download a bz2 compressed map file to use in the server");

	gCV_PublicURL = new Convar("gm_public_url", "http://sojourner.me/fastdl/maps/", "Replace with a public FastDL URL containing maps for your respective game, the default one is for CS:S.");
	gCV_FastDLPath = new Convar("gm_fastdl_path", "../../public_html/fastdl/maps", "Path to your FastDL's map directory, relative to the game's folder (cstrike/csgo/etc).");
	gCV_ReplaceMap = new Convar("gm_replace_map", "0", "Specifies whether or not to replace the map if it already exists.", _, true, 0.0, true, 1.0);

	Convar.AutoExecConfig();
}

public Action Command_GetMap(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "Usage: sm_getmap <mapname>");

		return Plugin_Handled;
	}

	char mapName[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapName, sizeof(mapName));

	if(mapName[0] == '\0')
	{
		ReplyToCommand(client, "Usage: sm_getmap <mapname>");

		return Plugin_Handled;
	}

	gCV_PublicURL.GetString(gS_PublicURL, sizeof(gS_PublicURL));
	gCV_FastDLPath.GetString(gS_FastDLPath, sizeof(gS_FastDLPath));
	gS_MapPath = "maps";

	if(gS_PublicURL[0] == '\0')
	{
		ReplyToCommand(client, "Invalid public URL path, please update cvar: gm_public_url");

		return Plugin_Handled;
	}
	else if(!FormatDirectoryPath(gS_FastDLPath, sizeof(gS_FastDLPath), mapName, ".bsp.bz2"))
	{
		ReplyToCommand(client, "Invalid fastdl path, please update cvar: gm_fastdl_path");

		return Plugin_Handled;
	}
	else if(!FormatDirectoryPath(gS_MapPath, sizeof(gS_MapPath), mapName, ".bsp"))
	{
		char gameFolder[PLATFORM_MAX_PATH];
		GetGameFolderName(gameFolder, sizeof(gameFolder));

		ReplyToCommand(client, "Cannot find %s/maps folder!", gameFolder);

		return Plugin_Handled;
	}
	else if((FileExists(gS_MapPath) || FileExists(gS_FastDLPath)) && !gCV_ReplaceMap.BoolValue)
	{
		ReplyToCommand(client, "Map already exists in maps or fastdl folder! To allow replacing, use the cvar: gm_replace_map or edit the plugin's cfg file.");

		return Plugin_Handled;
	}

	char endPoint[PLATFORM_MAX_PATH];
	Format(endPoint, sizeof(endPoint), "%s.bsp.bz2", mapName);

	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteString(mapName);

	gHC_HttpClient = new HTTPClient(gS_PublicURL);
	gHC_HttpClient.DownloadFile(endPoint, gS_FastDLPath, OnMapFileDownloaded, data);

	return Plugin_Handled;
}

bool FormatDirectoryPath(char[] path, int maxlen, const char[] mapName, const char[] extension)
{
	if(path[0] == '\0')
	{
		return false;
	}

	char temp[PLATFORM_MAX_PATH];
	strcopy(temp, sizeof(temp), path);

	if(path[strlen(path) - 1] == '/')
	{
		Format(path, maxlen, "%s%s%s", path, mapName, extension);
	}
	else
	{
		Format(path, maxlen, "%s/%s%s", path, mapName, extension);
	}

	return DirExists(temp);
}

void OnMapFileDownloaded(HTTPStatus status, DataPack data)
{
	delete gHC_HttpClient;

	data.Reset();

	int client = data.ReadCell();

	char mapName[PLATFORM_MAX_PATH];
	data.ReadString(mapName, sizeof(mapName));

	if(status != HTTPStatus_OK)
	{
		LogError("GetMap: Failed to download %s: HTTPStatus (%d)", mapName, status);
		ReplyToCommand(client, "Failed to download %s: HTTPStatus (%d)", mapName, status);

		if(FileExists(gS_FastDLPath))
		{
			DeleteFile(gS_FastDLPath);
		}

		delete data;

		return;
	}

	ReplyToCommand(client, "Decompressing the map file, please wait...");
	
	BZ2_DecompressFile(gS_FastDLPath, gS_MapPath, OnDecompressFile, data);
}

void OnDecompressFile(BZ_Error iError, char[] inFile, char[] outFile, DataPack data)
{
	data.Reset();

	int client = data.ReadCell();

	char mapName[PLATFORM_MAX_PATH];
	data.ReadString(mapName, sizeof(mapName));

	delete data;

	if(iError != BZ_OK)
	{
		LogError("GetMap: Failed to decompress %s: BZ_Error (%d)", inFile, iError);
		ReplyToCommand(client, "Failed to decompress %s: BZ_Error (%d)", inFile, iError);
		
		return;
	}

	ReplyToCommand(client, "Map successfully added to the server! Use !map %s to change to it.", mapName);
}