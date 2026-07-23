# Goal
The goal of this script is to simplify KSP management especially if you have multiple game instances and numerous saves. But regular gamers may also find it useful.

# History
I've played KSP for many years (started somewhen in ~2012). Besides just enjoying vanilla game I always liked to install and test numerous mods. There are a huge number of them... Some are abandoned over time, new ones appear, some have duplicated functionality in whole or in part, some are broken or unfinished... As a result, I often need to do many experiments before letting a new mod into my game pack. When I learned about CKAN I was happy — it greatly simplifies mod installation and dependency tracking processes.

I follow these principles for KSP:
- keep game spirit and balance;
- avoid too much automation, do most of the work manually;
- improve performance;
- improve usability;
- focus on visual quality;
- retain portability of saves.

That's why I always spend a lot of time trying to keep the minimum number of installed mods, removing duplicates, diving deep into their configuration, writing patches. Sometimes I try to make my modest contribution to development.

Over time, I developed the practice of having several game instances installed: the main one (just to enjoy gameplay), same setup for polishing mod combination, more or less clean version for deep isolated experiments with new mods or resolving specific issues, different localizations and so on. Of course, sometimes I need to delete some instances or populate new ones.
In this situation, I came up with the idea of ​​a shared (or portable) profile. Its purposes are:
- easily share some information (saves, crafts and their thumbs, etc.) between game instances;
- preserve all valuable information (saves and crafts again, screenshots) in case I want to delete a particular game instance;
- store a reference copy of game and mod settings (those that I think fit best) easily and apply them if the mods were re-installed (or altered in-game but I don't like the result and want to revert);
- backup simplicity — no need to make backups of numerous different files and directories nested in the game's one, just copy whole profile.
The structure of this profile that I use:
```
.
├── _info
├── CKAN
├── crafts
├── saves
├── Screenshots
├── templates
├── thumbs
├── utilities
├── AIO.ini
├── AIO.ps1
└── KSP_file_list.txt
```
Where:
"_info" — Just a collection of useful information regarding KSP (notes, maps, etc.). "crafts" — Here I place downloaded crafts. "utilities" — A place for some small programs like KML. All this has nothing to do with the script, it is mentioned simply for completeness of information.
"CKAN" — The main CKAN profile. This directory isn't used in the current script, but I manually link it into %LOCALAPPDATA%. This way, I always have a backup copy of my CKAN settings that can be easily transferred to another system if needed. However, the "Downloads" subfolder, where the cache is stored, is linked from a different location to prevent the backup from becoming bloated.
"saves", "Screenshots", "thumbs" — These are being linked into game root directory by described script.
"templates" — Storage for files that can be copied over by the script to the game (settings, my patches, small fixes, etc.)
"KSP_file_list.txt" — The list of KSP vanilla files purging the game if needed (by the script).
"AIO.ini", "AIO.ps1" — The script I am writing about.

Now a little about the "templates" directory. Here is its tree view.
```
.
├── GameData
├── Saves
├── GameData.json
├── Saves.json
├── settings_en.cfg
└── settings_ru.cfg
```
Where:
"GameData" — directory where stored mods' files (to be copied by the script)
"GameData.json" — settings file for certain mods.
"Saves" — directory where stored .sfs templates (to be imported into the savefile by the script using KML utility)
"Saves.json" — settings file for the use of KML.
"settings_*.cfg" — reference game settings files.

Sharing is done via NTFS links, so the in-game changes appear at the same time in the profile. Actually I also link game's settings.cfg, since I finished experimenting with it years ago. Mod settings, however, may still require review after updates, that's why I store them separately and just copy over to game directory. If I manage to configure the mod better than before, then I copy the new settings into the templates manually.

As a result, a set of typical tasks arises:
- (re-/un-)install full mod pack (all mods I consider good to have to enjoy the game);
- (re-/un-)install some other mod sets (e.g. debug mods, like exception reporter, FPS monitor or part extended information — I don't need them usually but in some cases they are extremely helpful);
- copy reference mods settings to configure a new instance or reset a modified one;
- create NTFS links to files or folders;
- manage CKAN cache;
- purge mod files left after mods uninstallation.

The first two are perfectly solved by CKAN. For the rest I've written numerous cmd and powershell scripts over the past years. Recently I decided to create a single script combining all needed functions. Here it is. Intended to be launched by CKAN as a custom command line. Here is an excerpt from the CKAN config:
```
  "CommandLines": [
    "KSP_x64.exe -single-instance",
    "powershell -noprofile -nolog -noexit -file \"G:\\Saves\\KSP\\AIO.ps1\""
  ],
```

## NTFS links
NTFS (I use Windows mostly) allows you to create so-called links — you can point to a single file (or directory) from several locations, so this file (or directory) will be a member of several directories at the same time. This is very convenient if you want to have exactly the same game settings in two game instances, or be able to save your game progress in one game instance and then open in another one without copying any files, or if you'd like to save screenshots from all games in one place. Or simply for backup purposes, once I lost all my KSP progress due to HDD malfunction.

My script makes (option #1) links to:
1. Every directory nested in Saves (not a Saves itself) excluding "scenarios" and "training" (original will be kept), so it takes only savegames made by users.
2. "Thumbs" directory that stores craft thumbnail images.
3. "Screenshots" directory, obvious.
4. "UserLoadingScreens" directory linked to "Screenshots".
5. "Settings.cfg" file, source file must be inside directory with config templates, its name must be "settings_%locale%.cfg", where %locale% is the first two letters of game language, e.g. "en". (This makes it possible to have a separate file for each language; I am not sure it is really required though... There is a language setting line in the file, but the incorrect value doesn't seem to affect anything.)

If the directory to be linked is not empty, it gets a ".bak" extension. And a small remark about UserLoadingScreens. This is a built-in function, pictures placed in this directory will be added (though there are some format and size limitations) to the slideshow while game is loading, among default images. I link this directory to the Screenshots one.

## Mods settings.
This is a complex topic, and there will be a lot of text... There are many great mods but some of them need adjustments. At least I am not satisfied with the default settings. It is not a big issue if you install such a mod once a year. But when you reinstall it over and over again, spending an extra minute on settings starts to get frustrating. Then you start thinking about replicating your settings. Even if you have only one game instance, it can also be useful to back up your settings in case of a system reinstall or a disk failure. If you spent a day finding the perfect combination of anti-aliasing settings for each game scene, it makes sense to save them for future reference, so you don't have to redo the process in a year or two.

In writing this document, I assume that the reader is familiar with the general directory structure of the game, as well as how mods are installed and work, and where their files are stored. Therefore, I will describe only the sometimes hidden or non-obvious nuances concerning the settings only. I don't claim to have exhaustive knowledge, but here's what I've learned from my many years of practice and numerous experiments.

I know three methods by which mods store their settings.
1. Files in the mod directory. Can also be divided into:
   1. .cfg or .txt or other file formats (I've seen .xml), which are just read by the mod library.
   2. .cfg or .txt files, which are read by Module Manager, settings from those files are being added to the game db and the mod reads parameters from there.
2. Files in the subdirectory (I've seen named "AddOns") inside the Saves one. In the mod directory usually there is its copy or file with default settings.
3. Directly in the save file (.sfs). The mod directory may caontain a file with default settings.

So, the person who wants to automate mods settings management should also use different methods (exact number depends on the mod list). Unfortunately, there are no bulk methods, in any case every mod must be examined separately. The only easy case — if you are completely satisfied with the settings out-of-the-box. Then you just don't need to move anything. But problems can happen in case you played with settings, made things worse and want to reset to defaults — then follow the guide.

First, one should identify where the particular mod stores its settings. Common variants are described above (I may not be aware of some other if I never used some specific mods). Read mod description and help on the forum or another site where it is distributed. In rare cases authors describe this moment. Also, there are some mods that don't have any GUI, settings can be done only by altering its files — this is usually noted. If not... There's a trick to narrowing down options: in the game change mod settings; save if requires; quit the game; run it again; create new game; open mod settings; what do you see? If you see altered settings, then most probably you have variant #1. If default ones — 2 or 3. That's the difference — #2 and #3 have different settings per save, #1 is equal for all saves.

Then, if you suspect variant #1, look at the mod directory inside GameData, are there any text files (like .cfg, .txt, .xml) often with word "settings" in the name? In this file you should see some lines that more or less resemble the items visible in the mod in-game interface. Do their values correspond with those you set before? You may try to change something and check if it changes also in-game. Or change in-game and re-open the file — do you see changes? (Keep in mind that some mods save parameters only on scene change.) If all this is true, congratulations — this is a type one mod. Keep a copy somewhere of the settings file with desired configuration, overwrite one in the mod directory with it to bring your desired settings. If you need to reset to default, just reinstall the mod, this will restore the original files.

> By the way, automated copying files from backup to the game directory helps in some other cases. For example:
> - adding some extra files to the mods or even base game (flags, patches, localizations, etc.);
> - overwriting existing non-settings files (fix mistype in existing localization or provide own texture);
> - installing mods that aren't in CKAN...
> 
> On the other hand, when you start manipulating mod's files you can also delete something, reasons:
> - parts, flags and other stuff you will never use;
> - faulty modules...

Difference between 1.1. and 1.2. As far as I know, Module Manager reads all .cfg and .txt files inside GameData directory (except PluginData nested dirs), tries to interpret data from them as game objects and write those to the game db. Some mod authors seem unaware of this or don't care. They store mod settings in .cfg files but read them directly. Even if they are added to the game db by Module Manager, looks like mod ignores this. But some authors use this feature, they form mod settings like a game object and read it then from db. Altering db with Module Manager patches changes mod's settings overriding those specified in the file. If you prefer to keep file copy and overwrite then it doesn't matter, will work for both. But 1.2. type can be useful if you like patching MM. It may be easier to maintain because Module Manager has convenient features for patch management (like ordering and requirements), it is possible to apply the desired one from several competing configurations automatically (e.g. based on mod list) without file jugglery. Also try Patch Manager mod — it's not a required mod, but it adds some flexibility to the Module Manager.

Variant #2. I've seen only two or three mods using this approach, but it might be subjective. In general, the solution in this case is the same, but there are some peculiarities. You can keep a copy of the settings file with reference configuration and put it in the save directory of your choice or delete it there if reset is needed. But there may be another way. Such mods need to keep default configuration somewhere which will be used for new games. In the worst case it can be hardcoded. But the only mod that uses such approach (I don't remember others to check) stores default settings file in its own directory. So, I overwrite it with my favourite config and just delete file in the Saves\AddOns directory. In this case my configuration becomes "default" for any new (or cleaned) games. To reset the mod to factory defaults you can reinstall it.

And last but not least, #3. Game saves your progress in .sfs files. It is a text file, it can be edited in any text editor. But there is a special program for that, named Kerbal Markup Lister (KML). It can work in GUI mode as well as command-line mode. The .sfs file has a tree structure and has "PARAMETERS" hive that is used, surprisingly, to store parameters. KML command-line mode supports export, import and deletion of data sections. So, when mod configuration is finished, you can identify section name where particular mod stores its settings and export this section to a file. After that you can delete existing section and/or import the proper one back anytime. Unfortunately, some mods write their parameters in other .sfs file sections (e.g. SCENARIO), each such case must be handled individually.

So what does my script do in the end? There are three available actions (#2, #3, #4):
- One copies files (not only settings, but any files also actually) from templates to the GameData if same mod directories exist. Also it deletes any files specified in the settings (may be used to remove mod files you don't need).
- Another one copies directories marked as "extra" in the settings. It doesn't check whether the same directory exists in the GameData. Useful for "manual" installation of mods. In the settings any extra directory may have "depends_on" parameter — will be copied if a directory with specified name exists in GameData (for dependency tracking).
- And the third one deletes "AddOns" directory inside chosen save folder and purges anything non-default in PARAMETERS section of this save; then it collects names of all directories inside game's GameData and if there are matching names in the template Saves directory, imports those templates to the chosen save.
Remark about 1.1. and 1.2. types of mods. I keep settings as files only for those using 1.1. approach. For 1.2. I prefer to write patches, all of them sit in the Patch Manager collection which is installed as one of "extra" directories. Patch Manager is not mandatory but useful — it provides in-game interface to see active patches (no need to browse MM logs).

What are templates?
- GameData template is a directory with the same directory structure inside like GameData of the KSP but it stores only changed files (those game or mods files that I had changed and want to keep and share between instances). Earlier I was just copying this to the game overwriting everything. But there was a problem: I collected many files for different mods but not every mod may be present in the current game instance. So, the script checks and copies only those that do exist in the current game.
- Saves template is a directory with collection of .sfs templates (reference settings that I made for certain mods and exported with KML from save files). Each template is named after the corresponding mod's directory. Again, the script checks and imports to the chosen save only those files which mods do exist in the current game.

## CKAN cache
I prefer to keep CKAN cache without limits. But sometimes I forget to purge particular mod from cache before update (or don't want to do it in case update may break something). Then eventually I find that there are several versions of the same mod in the cache. Of course, I can purge it by CKAN completely and then re-download the latest. But it is more convenient to delete only outdated versions.

My script's option #5 tries to parse all filenames in the cache and find names of the mods, groups equal ones and, after confirmation, deletes every group excluding the most recent file.

## File purge
Some mods create new files when the game is launched: settings, cache, logs, etc. If these are located within the mod's directory, CKAN usually prompts you to delete them as well when you uninstall the mod. However, some files are placed in other locations. Then, if you uninstall mods, these files just waste space. In rare cases, these files can cause problems.

The script has two options (#6 and #7) for this.
First must be run preferably before game ever has been started or modified (fully vanilla). However, you can remove some files you are sure you don't need (e.g. readme.txt) or add something you want to keep forever. The script will create a list of files that are part of vanilla game and place it in the savepath (same as for links).
Then anytime you can run the second one, it will analyse existing files and remove all that are not on the list. There are exceptions configured: any CKAN-related files (CKAN stores some settings and history in the game directory, also in some scenarios it is intended to place CKAN executable there). Links created by the very first script step will be deleted as well. But any vanilla files that were overwritten cannot be restored.
