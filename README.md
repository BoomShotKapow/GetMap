# GetMap
SourceMod plugin that allows users to download a map while in-game and it will automatically setup the FastDL.

## ConVars

  - gm_public_url (Default = http://sojourner.me/fastdl/maps/) - This is the URL that will be used to download the bz2 compressed map file.
  - gm_fastdl_path (Default = ../../public_html/fastdl/maps) - The fastdl path relative to the game's folder (cstrike/csgo/etc).
  - gm_replace_map (Default = 0, Min = 0, Max = 1) - Whether or not to replace the map if it exists already in either the fastdl or maps folder.

## Admin Command

  - sm_getmap (ADMFLAG_CHANGEMAP) - Admin command that will download a bz2 compressed map file from the gm_public_url ConVar and it will be saved in the directory that's specified in the gm_fastdl_path. Afterwards, it'll be decompressed to the game's respective maps folder. The downloaded compressed file will remain in the fastdl after extraction.

## Directory Structure

  The directory structure is important in order to get the downloaded file and the decompressed file in the desired locations. The path (at the moment) is dependent on the dedicated server's game folder that has the SourceMod installation. This game folder is called cstrike for Counter-Strike: Source and csgo for Counter-Strike: Global Offensive. If the directory structure is setup with LinuxGSM, it'll look similar to this for cstrike: ~/serverfiles/cstrike/ and the fastdl: ~/public_html/fastdl/maps
  
  So, in order to set the gm_fast_dl_path, since it's starting in your game's respective folder (cstrike/csgo): ../ to move up a directory into serverfiles, ../ to move up a directory into the user's home directory. Then into public_html/fastdl/maps. Obviously configure this to your game server's directory structure, it may not be configured the same way as the default values.
