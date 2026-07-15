# Goal
The goal of this script is to simplify management mainly if you have multiple KSP game instances and numerous saves. But simple gamers may also find it useful.

# History
I play KSP for many years (started somewhen in ~2012). Beside just enjoying vanilla game I always liked to install and test numerous mods. There are a huge number of them... Some are abandoned over time, new ones appear, some have duplicated functionality in whole or in part, some are broken or unfinished... As a result, I often need to make many experiments before letting a new mod into my game pack. When I learned about CKAN I was happy — it greatly simplifies mod installation and dependency tracking processes.

I follow these principles for KSP:
- keep game spirit and balance;
- avoid too much automation, do most of the work manually;
- improve performance;
- improve usability;
- focus on visual quality;
- retain portability of saves.

That's why I always spend a lot of time trying to keep the minimum number of installed mods, removing duplicated, diving deep in their configuration, writing patches. Sometimes I try to make my modest contribution to development.

Over time, I developed a practice to have several game instances installed: the main one (just to enjoy gameplay), same setup for polishing mod combination, more or less clean version for deep isolated experiments with new mods or resolving specific issues, also different localizations and so on. Of course, sometimes I need to delete some instances or populate new ones. As a result, a set of typical tasks arises:
- (re-/un-)install full mod pack (all mods I consider good to have to enjoy the game);
- (re-/un-)install some other mod sets (e.g. debug mods, like exception reporter, FPS monitor or part extended information — I don't need them usually but in some cases they are extremely helpful);
- copy mods settings from main game to another instance;
- reset mods settings to default;
- create NTFS links to files or folders;
- manage CKAN cache.

The first two are perfectly solved by CKAN. For the rest I wrote numerous cmd and powershell scripts over the past years. Recently I decided to create a single script combining all needed functions. Here it is. Intended to be started by CKAN as a custom command line. Here is an abstract from CKAN config:
```
  "CommandLines": [
    "KSP_x64.exe -single-instance",
    "powershell -noprofile -nolog -noexit -file \"G:\\Saves\\KSP\\AIO.ps1\""
  ],
```

## NTFS links
NTFS (I use Windows mostly) allows to create so called links — you can point to a single file (or directory) from several locations, so this file (or directory) will be a member of several directories at the same time. This is very convenient if you want to have exactly the same game settings in two game instances, or be able to save you game progress in one game instance and then open in another one without copying any files, or if you'd like to save screenshots from all games in one place. Or simply for backup purposes, once I lost all my KSP progress due to HDD malfunction.

My script makes links to:
1. Every directory nested in Saves (not a Saves itself) excluding "scenarios" and "training" (original will be kept), so it takes only savegames made by users.
2. "Thumbs" directory that stores craft thumbnail images.
3. "Screenshots" directory, obvious.
4. "UserLoadingScreens" directory linked to "Screenshots".
5. "Settings.cfg" file, source file must be inside directory with config templates, its name must be "settings_%locale%.cfg", where %locale% is the first two letters of game language, e.g. "en". (This makes it possible to have a separate file for each language; I am not sure it is really required though... There is a language setting line in the file, but the incorrect value doesn't seem to affect anything.)

If directry to be linked is not empty, it gets ".bak" extension. And a small remark about UserLoadingScreens. This is built-in function, pictures placed in this directory will be added (though there are some format and size limitations) to the slide-show while game is loading, among default images. I link this directory to the Screenshots one.

## Mods settings.
This is a complex topic, and there will be a lot of text... The are many great mods but some of them need adjustments. At least I am not satisfied with the default settings. It is not a big issue if you install such a mod once a year. But when you reinstall it over and over again, spending an extra minute on settings starts to get frustrating. Then you start thinking about replicating your settings. Even if you have only one game instance, it can also be useful to back up your settings in case of a system reinstall or a disk failure. If you spent a day finding the perfect combination of anti-aliasing settings for each game scene, it makes sense to save them for future reference so you don't have to redo the process in a year or two.

In writing this document, I assume that the reader is familiar with the general directory structure of the game, as well as how mods are installed and work, and where their files are stored. Therefore, I will describe only the sometimes hidden or non-obvious nuances concerning the settings only. I don't claim to have exhaustive knowledge, but here's what I've learned from my many years of practice and numerous experiments.

I know three methods how mods store their settings.
1. Files in the mod directory. Can also be divided in:
   1. .cfg or .txt or other files formats (I've seen .xml), which are just read by the mod library.
   2. .cfg or .txt files, which are read by Module Manager, settings from those files are being added to the game db and the mod reads parameters from there.
2. Files in the subdirectory (I've seen named "AddOns") inside the Saves one. In the mod directory usually there is its copy or file with default settings.
3. Directly in the save file (.sfs). In the mod directory may be a file with default settings.

So, the person who wants to automate mods settings management should also use different methods (exact number depends on the mod list). Unfortunately, there is no bulk methods, in any case every mods examined separately. The only easy case — if you are completely satisfied with the settings out-of-the-box. Then you just don't need to move anything. But problem can happen in case you played with settings, made things worse and want to reset to defaults — then follow the guide.

First, one should identify where the particular mod stores its settings. Common variants are described above (I may not be aware of some other if I never used some specific mods). Read mod description and help on the forum or another site where it is distributed. In rare cases authors describe this moment. Also there are some mods that don't have any GUI, settings can be done only by altering its files — this is usually noted. If not... There's a trick to narrowing down options: in the game change mod settings; save if requires; quit the game; run it again; create new game; open mod settings; what do you see? If you see altered settings, then most probably you have variant #1. If default ones — 2 or 3. That's the difference — #2 and #3 have different settings per save, #1 is equal for all saves.

Then, if you suspect variant #1, look at the mod directory inside GameData, are there some text files (like .cfg, .txt, .xml) often with word "settings" in the name? In this file you should see some lines that more or less resemble the items visible in the mod in-game interface. Do their values correspond with those you set before? You may try to change something and check if it changes also in-game. Or change in-game and re-open the file — do you see changes? (Keep in mind that some mods save parameters only on scene change.) If this is all true, congratulations, this is mod of the first type. Keep somewhere a copy of the settings file with desired configuration, overwrite one in the mod directory with it to bring your desired settings. If you need to reset to default, just reinstall the mod, this will revert to original file.

> By the way, automated copying files from backup to the game directory helps in some other cases. For examples:
> - adding some extra files to the mods or even base game (flags, patches, localizations, etc.);
> - overwriting existing non-settings files (fix mistype in existing localization or provide own texture);
> - installation of the mods that are absent in CKAN...
> 
> On the other hand, when you start manipulating mod's files you can also delete something, reasons:
> - parts, flags and other stuff you will never use;
> - faulty modules...

Difference between 1.1. and 1.2. As I know Module Manager reads all .cfg and .txt files inside GameData directory (except PluginData nested dirs), tries to interpret data from them as game objects and write those to the game db. Some mod authors seem are not aware about that or don't care. They store mod settings in .cfg files but read them directly. If they even added to the game db by Module Manager, looks like mod ignores this. But some authors use this feature, they form mod settings like a game object and read it then from db. Altering db with Module Manager patches changes mod's settings overriding those specified in the file. If you prefer to keep file copy and overwrite then it doesn't matter, will work for both. But 1.2. type can be useful if you like patching MM. It may be easier to maintain because Module Manager has convenient features for patch management (like ordering and requirements), it is possible to apply the desired one from several competing configurations automatically (e.g. based on mod list) without file jugglery. Also try Patch Manager mod — it's not a required mod, but it adds some flexibility to the Module Manager.

Variant #2. I've seen only two or three mods using this approach, but it might be subjective. In general, the solution in this case is the same, but there are some peculiarities. You can keep a copy of the settings file with reference configuration and put it in the save directory of your choice or delete it there if reset is needed. But there may be another way. Such mods need to keep default configuration somewhere which will be used for new games. In the worst case it can be hardcoded. But the only mod that uses such approach (don't remember other to check) stores a copy of settings file in its own directory. So, I overwrite it with my favourite config and just delete file in the Saves\AddOns directory. In this case my configuration becomes "default" for any new (or cleaned) games. To reset the mod to factory defaults you can reinstall it.

And the last but not the least, #3. Game saves your progress in .sfs files. It is a text file, it can be edited in any text editor. But there is special program for that, named Kerbal Markup Lister (KML). It can work in GUI mode as well as command-line mode. File .sfs has tree structure and has "PARAMETERS" hive that is used, surprisingly, to store parameters. KML command-line mode supports export, import and deletion of data sections. So, when mod configuration is finished, you can identify section name where particular mod stores its settings and export this section to a file. After that you can delete existing section and/or import the proper one back anytime.

So what does my script do in the end? There are three available actions:
- One copies files (not only settings, any files actually) from templates to the GameData if same mod directories exist. Also it deletes any files specified in the settings (may be used to remove mod files you don't need).
- Another one copies those directories that marked as "extra" in the settings. It doesn't check existance of the same directory in the GameData. Useful for "manual" installation of mods. In the settings any extra directory may have "depends_on" parameter — will be copied if a directory with specified name exists in GameData (for dependency tracking).
- And the third one deletes "AddOns" directory inside chosen save folder and purges anything non-default in PARAMETERS section of this save; then it collects names of all directories inside game's GameData and if there are same names in the template Saves directory, imports those templates to the chosen save.
Remark about 1.1. and 1.2. types of mods. I keep settings as files only for those using 1.1. approach. For 1.2. I prefer to write patches, all of them sit in the Patch Manager collection which is installed as one of "extra" directories. Patch Manager is not mandatory but useful — it provides in-game interface to see active patches (no need to browse MM logs).

What are templates?
- GameData template is a directory with the same directory structure inside like GameData of the KSP but it stores only changed files (those game or mods files that I had changed and want to keep and share between instances). Earlier I was just copying this to the game overwriting everything. But there was a problem: I collected many files for many mods but at current game instance not every mod may be present. So, the script checks and copyies only those that do exist in the current game.
- Saves template is a directory with collection of .sfs templates (reference settings that I made for certain mods and exported with KML from save files). Each template name as directory of the corresponding mod. Again, the script checks and imports to the chosen save only those files which mods do exist in the current game.

## CKAN cache
I prefer to keep CKAN cache without limits. But sometimes I forget to purge particular mod from cache before update (or don't want to do it in case update may break something). Then eventually I find that there are several versions of the same mod in the cache. Of course, I can purge it by CKAN completely and then re-download the latest. But it is more convenient to delete only outdated versions.

My script tries to parse all filenames in the cache and find names of the mods, groups equal ones and, after confirmation, deletes every group excluding the most recent file.
