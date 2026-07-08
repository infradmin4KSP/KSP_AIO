# To make the script easily portable between systems, local paths configuration is done via separate .ini file.
# Intended to be run by CKAN as a command line, so assumed the present working directory is always the current game instance root directory.

cls
$IniPath="$(if ($PSScriptRoot) {"$PSScriptRoot"} else {"."})\AIO.ini"
$ini = gc $IniPath | ?{$_ -notmatch '^[\[;]' } | %{$_.trim() -replace '"' -replace "\\$" -replace "\s*=\s*","=" -replace "\\","\\" -replace '%(\w+)%(.*)','$($env:$1)$2'} | Out-String | ConvertFrom-StringData
$($ini.Keys) | %{$ini[$_] = $ExecutionContext.InvokeCommand.ExpandString($ini[$_])}
if ($ini.kmlpath -notmatch "\.exe$") {$ini.kmlpath = $ini.kmlpath + "\KML.exe"}

$pathhash=[ordered]@{}
"savepath","tmplpath","kmlpath","cachepath" | %{
$pathhash.$_ = @{
exists = ($ini[$_] -and (test-path $ini[$_] -EA 0))
path = $ini[$_]
}
}
$pathhash.Keys | %{write-host -fore $(if ($pathhash.$_.exists) {'green'} else {'red'}) "Path '$_' is '$($pathhash.$_.path)', is$(if ($pathhash.$_.exists) {''} else {' not'}) found."}
write-host -fore green "Working directory is '$($pwd.path)'.`n"

$optionhash=[ordered]@{
1 = @{
title = "Create/make links to centrally stored directories and files."
depends_on = "savepath,tmplpath"
}
2 = @{
title = "Populate mod settings into the GameData directory."
depends_on = "tmplpath"
}
3 = @{
title = "Populate mod settings into the certain savefile."
depends_on = "tmplpath,kmlpath"
}
4 = @{
title = "Purge duplicates from CKAN cache."
depends_on = "cachepath"
}
}

$optionhash.keys | %{$optionhash.$_.enabled = ($optionhash.$_.depends_on -split "," | %{$pathhash.$_.exists}) -notcontains $false}
$msg=""
$optionhash.keys | %{if ($optionhash.$_.enabled) {$msg+="`n $($_). $($optionhash.$_.title)"}}
if ($msg) {write-host -fore yellow "What would you like to do?$msg"} else {write-host -fore red "Nothing can be done. Please check paramaters.";break}
$choice = read-host -prompt "Enter you choice (may be several)"

1..4 | %{$optionhash.$_.chosen = $choice -match $_}

if ((1..2 | %{$optionhash.$_.enabled -and $optionhash.$_.chosen}) -contains $true) {
$locale = $(gc "buildID64.txt" | ?{$_ -match "language"}).replace("language = ","").trim()
echo "`nLocale is '$locale'."
}

if ($optionhash.([int]1).chosen -and $optionhash.([int]1).enabled) {
echo "`n####################################################################################################"
echo "# Making links to stored data directories"

$links  = gci "$($pathhash.savepath.path)\saves" -dir | select @{name="path";expression={"$($pwd.path)\Saves\$($_.name)"}},@{name="value";expression={$_.fullname}},@{name="type";expression={"Junction"}}
$links += "thumbs","Screenshots" | select @{name="path";expression={"$($pwd.path)\$_"}},@{name="value";expression={"$($pathhash.savepath.path)\$_"}},@{name="type";expression={"Junction"}}
$links += [pscustomobject]@{"path"="$($pwd.path)\UserLoadingScreens";"value"="$($pathhash.savepath.path)\Screenshots";"type"="Junction"}
$links += [pscustomobject]@{"path"="$($pwd.path)\settings.cfg";"value"="$($pathhash.tmplpath.path)\settings_$($locale -replace "-\w*$").cfg";"type"="HardLink"}
$links | select -exp path | ?{test-path $_} | %{gi $_ | %{if (!($_.LinkType) -and (gci $_).count) {ren -path "$($_.fullname)" -new "$($_.fullname).bak" -force} else {del $_ -rec -force}}}
$links | %{ni -path "$($_.path)" -value "$($_.value)" -itemtype $_.type} | select FullName
}

if ($optionhash.([int]2).chosen -and $optionhash.([int]2).enabled) {
echo "`n####################################################################################################"
echo "# Populate mod setting to directories`n"

$GameData = gc "$($pathhash.tmplpath.path)\GameData.json" | ConvertFrom-Json
if ($locale -eq "ru") {$exc=@()} else {$exc=@("dictionary.cfg")}

$fromdir = "$($pathhash.tmplpath.path)\GameData"
$todir   = "$($pwd.path)\GameData"

$dirs = gci $todir -dir | select name

$targets = $dirs | ?{$_.name -notin $($GameData.level2_dirs | select -exp name) -and $_.name -notin $($GameData.extra_dirs | select -exp name)} | select -exp name
# $targets += $dirs | ?{$_.name -in $($GameData.level2_dirs | select -exp name)} | %{$dd = $_.name; gci $(join-path $todir $_.name) -dir | select @{n="name";e={"$dd\$($_.name)"}}} | select -exp name
$targets += $dirs | ?{$_.name -in $($GameData.level2_dirs | select -exp name)} | %{gci $(join-path $todir $_.name) -dir} | select -exp fullname | %{$_.replace("$todir\","")}
$targets += $GameData.extra_dirs | ? {$_.depends_on -like "" -or $_.depends_on -in $($dirs | select -exp name)} | select -exp name
echo "$($targets.count) potencial target directories were found"
$todo = $targets | ?{test-path $(join-path $fromdir $_)}
echo "$($todo.count) applicable source directories were found"

echo "`nCopying files:"
$todo | % {copy -path "$(join-path $fromdir $_)" -dest "$((join-path $todir $_) -replace "\\\w*$")" -rec -force -exc $exc -pass | select fullname}

echo "`nDeleting unwanted files of directories:"
$GameData.unwanted | ?{$_.depends_on -notin $targets} | %{join-path $todir $_.name} | %{if (test-path "$_") {del "$_" -rec; echo $_}}
}

if ($optionhash.([int]3).chosen -and $optionhash.([int]3).enabled) {
echo "`n####################################################################################################"
echo "# Populate mod setting to savefiles"

$Saves = gc "$($pathhash.tmplpath.path)\Saves.json" | ConvertFrom-Json
$entrypattern = "\d/\d/\d*: "
$fromdir  = "$($pathhash.tmplpath.path)\Saves"
$todir    = "$($pwd.path)\GameData"
$save_filterout = @("training","scenarios","Backup")
$save_filterout = ($save_filterout | %{".*\\$_\\.*"}) -join "|"

$savefiles = gci "$($pwd.path)\Saves" -rec -file -inc "*.sfs" | ?{$_.fullname -notmatch $save_filterout} | select @{name="FileName";expression={$_.FullName}},@{name="Game";expression={$_.Directory.Name}},@{name="File";expression={$_.Name}} | ogv -Title "Select file to alter" –PassThru | select -exp FileName

if ($savefiles) {
$savefiles | %{split-path -path $_ -parent} | sort -un | %{"$_\AddOns"} | %{if (test-path $_) {del "$_" -rec; echo "Deleted $_."}}

$dirs = gci $todir -dir | select -exp name
$todo = gci $fromdir -file | sort -des name | ? {$_.basename -in $dirs} | select -exp fullname

foreach ($savefile in $savefiles) {
& "$($pathhash.kmlpath.path)" @("$savefile","--tree","--select=GAME/PARAMETERS")
& "$($pathhash.kmlpath.path)" @("$savefile","--tree","--select=GAME/PARAMETERS") | ?{$_ -match $entrypattern} | %{$_ -replace $entrypattern} | ?{$_ -notin $($Saves.good_parameters)} | %{& "$($pathhash.kmlpath.path)" @("$savefile","--tree","--select=GAME/PARAMETERS/$_","--delete"; sleep 1)}
sleep 3
$todo | %{& "$($pathhash.kmlpath.path)" @("$savefile","--tree","--select=GAME/PARAMETERS/$($($Saves.good_parameters)[-1])","--import-after=$_"); sleep 1}
& "$($pathhash.kmlpath.path)" @("$savefile","--tree","--select=GAME/PARAMETERS")
& "$($pathhash.kmlpath.path)" @("$savefile","--repair")
}
} else {echo "`nNo files were selected!"}
}

if ($optionhash.([int]4).chosen -and $optionhash.([int]4).enabled) {
echo "`n####################################################################################################"
echo "# Purge duplicates from CKAN cache"

$duplicates = gci $pathhash.cachepath.path -file | sort -des LastWriteTime | select *,@{name="mod";expression={$_.name -replace "^.*?-","" -replace "-KSP|-adoption","" -replace "[0-9v.-]*\.zip$"}} | group mod | sort count | ? {$_.count -gt 1}
if ($duplicates) {
$duplicates | select count,name | oh
if ($(Read-Host -Prompt "Whould you like to delete older versions (enter 'yes', any other input will be consifered as 'no')?") -eq "yes") {$duplicates | % {$_.group | select -exp fullname -skip 1} | %{del "$_"; echo $_}} else {echo "Canceled."}
} else {echo "`nNo duplicates found"}
}
