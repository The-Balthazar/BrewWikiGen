![BrewWikiGen logo](BrewWikiGen.png)

***BrewWikiGen***, by Sean 'Balthazar' Wheeldon; automatic Github markdown style
wiki page generation for *Supreme Commander: Forged Alliance* unit mods.

## Installation:
The script requires Lua 5.4 or greater to run. The uncompiled official download
for that is [available here](https://www.lua.org/download.html), however, I downloaded
pre-compiled binaries [from here](http://luabinaries.sourceforge.net/download.html).
`lua-5.4.2_Win64_bin.zip` to be specific.

For convenience, I execute from within [Atom](https://atom.io/) using the
[LuaRunner](https://github.com/shenfll/luarunner) plugin, downloadable from within
the Atom package manager. Ctrl-Shift-x opens the LuaRunner pane, point it at
lua54.exe, open and [appropriately edit `Run.lua`](#Configuring) for your personal
environment, and run. Alternatively running a `.bat` file containing:
```bat
"C:\Program Files (x86)\Lua\5.4.2\lua54.exe" C:\BrewWikiGen\Run.lua
pause
```
Edited as appropriate for your setup will also suffice for easy running. The `pause`
is optional, and is mostly so you can read the log output. You will still need to
edit `Run.lua`.

## Configuring:
The following are all the values read from `Run.lua`. Some will need updating for
your setup:

* `OutputDirectory` needs to point to a real directory. I'd go for wherever you
check out your mods wiki repository, but what you do with the output is up to you.

* `WikiGeneratorDirectory` should point to the folder `Main.lua` is located in.
Include a slash at the end.

* `EnvironmentData` contains the following environmental values:

  * `Blueprints`, a bool for if it should search subfolders of the `/Environment/`
    folder for blueprints or a shell links to blueprints. (Note: any link still
    needs to be in a subfolder). Don't ask why I implemented reading shell links
    for just this instead of just making the value a path. I genuinely don't know.

  * `GenerateWikiPages`, assuming `Blueprints` is true, this bool defines if it
    should generate pages for the environmental blueprints. If not they will only
    be used for built-by lists and upgrades to/from information, and won't include
    them in navigation/category pages or include them in engineering build lists.

  * `Factions`, optionally, is a an array of custom factions formatted as sub-arrays
    containing the faction category then the faction name. For example:
    ```lua
    Factions = {
        {'NOMADS', 'Nomads'},
        {'ARM', 'Arm'},
        {'CORE', 'Core'},
    },
    ```
    The order is used for navigation sections and doesn't need to match the faction
    index in game. They are appended to the vanilla factions followed by 'Other',
    which is used for anything else and anything with multiple faction categories.

  * `Lua`, optional, defines the location that *contains* the lua folder to try
    to load `lua/ui/help/unitdescription.lua` and `lua/ui/help/tooltips.lua` from.
    They are expected to be valid Lua, and are sandboxed with no access to functions.
    If undefined, the generator comes with a default set of order tooltips.

  * `LOC`, optional, defines the location that *contains* the loc folder to try
    to load `loc/`Language`/strings_db.lua` from. It is expected to be valid Lua
    and is sandboxed with no access to functions.

  * `name` is how it refers to the environment in navigation.

  * `author`, `version`, and `icon` are all used in the 'mod page' for generated
    for the environment if `GenerateWikiPages` is true.

  * `ExtraData` can point to an optional extra document of hand written content
    for specific sections of specific unit pages. It expects said document to be
    formatted as a `UnitData` table, keyed with unit IDs (upper case, or however
    the bp files are named if they are anything other than entirely lower case),
    with table values containing keys that match the syntax `[Section]Prefix` or
    `[Section]Suffix`, where `[Section]` matches the English names of sections,
    like `Weapons` or `Adjacency`, or `LeadSuffix`, with string values, or keyed
    with `Videos` with an array of tables that match the format
    `{YouTube = '[Video ID]', '[Display name]'}`, where `[Video ID]` is the 11-ish
    character YouTube video ID, and `[Display name]` is the link caption to display.
    Which is a very wordy way to say to look like this example:
    ```lua
    UnitData = {
        SSL0403 = {
            Videos = {
                {YouTube = 'IInITjdtaPM', 'Time-lapse'},
            },
            LeadSuffix = "Paragraph to appear after the generated lead paragraph.",
            AdjacencyPrefix = "Paragraph to appear before the Adjacency section."
        },
    }
    ```
    If you don't have such a document, you can remove the field or set it to `false`.

* `WikiOptions` contains the following bool-ish options:

  * `Language` should be the two letter language code for which LOC files should
    be loaded. They are not ISO_639-1. Non-`'US'` is only partially supported.

  * `GenerateHomePage`, `GenerateSidebar`, `GenerateModPages`, `GenerateUnitPages`,
    and `GenerateCategoryPages`; `true` or `false`: Generate those parts or not.

  * `AbilityDescriptions`; `true` or `false`: If `false` it lists the abilities of
    the units verbatim in the abilities section. If true it will try to map them
    to tooltips in the `abilityDesc` table in `/Environment/Game.lua`.

  * `BalanceNote` appears at the bottom of Balance sections if they exist. It can
    be set to false or removed. The section will only appear on pages for blueprints
    that have `bp.WikiBalance` be truthy. The auto generated content of balance
    requires `bp.WikiBalance.Affects`; expected to contain an array of blueprint
    sections affected by the script, and optionally `bp.WikiBalance.ReferenceIDs`;
    expected to be an array containing 1 or 2 unit ID's, with it assuming the result
    is an average if both are defined.

    The section would be devoid of generated content if `BalanceNote` evaluates
    false and `bp.WikiBalance` evaluates true, but has none of the expected content.
    This would allow you to fill it with your own content as detailed in `ExtraData`.

  * `ConstructionNote` appears at the top of Construction sections in unit pages.
    It can be set to false or removed.

  * `BuildListSaysModUnits` if true the build list refers to what can be built as
    "mod unit(s)" instead of "unit(s)".

* `CleanupOptions` contains the following bool options:

  * `CleanUnitBpFiles`; `true` or `false`: Enables or disables all `.bp` file
    modifying scripts. Note it only applies to loaded `.bp` files that would be
    given a wiki page.

  * `CleanUnitBpGeneral`, `CleanUnitBpDisplay`, `CleanUnitBpInterface`,
    and `CleanUnitBpUseOOBTestZoom`; `true` or `false`: Removes obsolete vales.
    Specifically:
    * From `General`: `Category`, `Classification`, `TechLevel`, and `UnitWeight`.
    * From `Display`: `PlaceholderMeshName`, and `SpawnRandomRotation`.
    * The whole of `Interface`.
    * The value `UseOOBTestZoom`.

  * `CleanUnitBpThreat`; `true` or `false`: Updates the threat values based on
    an extensive formula.

* `ModDirectories` should point to your local copies of the mod(s) you wish to
generate wiki pages for. It assumes, but doesn't require, multiple mods. It
expects a `mod_info.lua` file directly in each item on the list. The order listed
is used for navigation ordering on the sidebar and home page generations.

* `UnitBlueprintsFolder` is where within the mod folders it should start looking
for blueprints. Standard convention is `units`. This value can be removed, but
execution can take double the time to complete.

* `BlueprintFolderExclusions` and `BlueprintFileExclusions` are arrays of regex
matches for what to exclude from the blueprint search. The first is used against
anything without a `.` in it, assumed to be folders, the second is used against
anything that ends in `_unit.bp`. It won't look in any folder that matches, or
open any file that matches.

* `BlueprintIdExclusions` is an array of exact blueprint IDs to exclude. Case insensitive.

* `FooterCategories` is a list of unit categories that the generator should create
category pages for, and link to at the bottom of the relevant units. They appear
on unit pages in the order written, so I tried to order them in a natural language
order, or as close to as possible. If you have no units in a given category, no
page will be generated. Add or remove as seems appropriate for your mods needs.
Can be completely removed if you don't need categories.

* `Logging` contains several options for verbose logging of additional information
which can be interesting or helpful in the case of any issues.

* `Sanity` contains options for flagging anything in blueprints and their meshes
that I consider anomalous or unnecessary. Exercise discretion when taking its advice.

## Usage notes:
If you have pre-existing pages for `Home.md`, `_Sidebar.md` or mods in your wiki
you can specify where and if the generator outputs in those pages specifically.
This can be done through specific xml tags read by the generator.

Behaviours on these pages are; if matching opening and closing tags exist (`<tag>`
and `</tag>`) it will replace the contents with the new generation, if an empty
tag exists (`<tag />` with the space) it will specifically not write that section,
otherwise it appends the content to the end surrounded by matching opening and
closing tags.

If you want it to not output on an entire class of page, that can be done via the
relevant `WikiOptions` flags. Yes this makes `<brewwikihome />` and `<brewwikisidebar />`
redundant, but it's the same code for all of them, so it's free.

Tags are:
* `<brewwikihome>` for the mod navigation for `Home.md`.
* `<brewwikisidebar>` for the mod drop downs for `_Sidebar.md`.
* `<brewwikimodinfobox>` for the infobox on mod pages.
* `<brewwikileadtext>` for the lead text on mod pages.
* `<brewwikimodunits>` for the unit navigation images on mod pages.

### Blueprints.lua:
If you have content modified or generated in `Blueprints.lua` that would be
important to the wiki, you can have the generator run it by adding a `WikiBlueprints`
function to that file. That function is called in much the same way as
`ModBlueprints`, except by the generator instead of the game. Input argument is the
same, except only `.Unit` is populated currently. This is easier to achieve if
your `Blueprints.lua` is formatted such that your `ModBlueprints` hook is
populated with function calls rather than with code ran directly within that hook.
However, as outlined below, it needs to be valid Lua.

### Lua validation:
Since this generator runs mod files directly for data, any referenced `.lua` file
must be valid for Lua 5.4. This notably means **not** using `#` instead of `--`,
not using `!=` instead of `~=`, and probably several other things.

Code in required files that validates as Lua, but wouldn't run, ie: because it
runs a loop without defining an iterator like `pairs` or `ipairs`, or wouldn't
want to be ran for the wiki generation can be selectively ran by changing the
code to check `_VERSION == "Lua 5.0.1"` first so that it only runs in-game.

I don't anticipate this being a huge issue, since these are generally data files
and any code in them shouldn't need to be performed more than once.

Files this affects are as follows:

*    `/mod_info.lua`
*    `/hook/lua/ui/help/tooltips.lua`
*    `/hook/lua/ui/help/unitdescription.lua`
*    `/hook/lua/system/blueprints.lua`
*    `/hook/loc/US/strings_db.lua`

### Included files:
It will skip any mod that doesn't have a valid `mod_info.lua`, and, while blueprint
files are sanitised, it will halt if it reaches a `.bp` file that still doesn't
validate as Lua after sanitisation. For the other files it will continue with a
warning, but may have missing data on the pages.

Only blueprint files that end in `_unit.bp` will be included, and only non-Merge
blueprints in those that contain defined `Display`, `Categories`, `Defense`,
`Physics`, and `General` tables will be considered 'valid' and included.

### Images
The Github wiki image loading is case sensitive.

For mod icons if the mod in question has a `mod_info.lua` `icon` field it expects
a `icons/mods/[mod-name].png` file and a `images/mods/[mod-name].png` file, where
mod-name matches the mods written name in lowercase with spaces replaced with
hyphens and non-web-safe characters removed. It ignores the actual value of `icon`,
because `icon` has a high chance of pointing to something not-web-safe, and could
cause clashes. I recommend that the icon be 64x64px and the image be 512x512px.

It expects to find unit icons at `icons/units/[ID]_icon.png`, it expects ID to
match the case of the original `.bp` file, unless it's entirely lowercase, in
which case uppercase.

If you have files at `images/units/[ID].jpg` in the output directory it will insert
them in the matching unit infoboxes, and if you have files at `images/units/[ID]-n.jpg`
where `n` is a number from `1` onwards, it will create a gallery section for them
on said pages.

If you have mixed case unit icon files that don't match, this script can be used
to rename them to `[uppercase ID]_icon.png`:
```lua
local folderdir = string.match(debug.getinfo(1, 'S').short_src, '.*\\')
print(folderdir)

local folder = io.popen(string.format('dir "%s" /b', folderdir))

for name in folder:lines() do
  if string.lower(string.sub(name, -8)) == 'icon.png' then
      local newname = string.upper(string.match(name, '(.+)_[iI][cC][oO][nN]'))..'_icon.png'
      local file = io.open(folderdir..name, 'rb'):read('all')

      io.open(folderdir..'test\\'..newname, 'wb'):write(file):close()
      file:close()
  end
end

print("end")
```
To use it save it as `.lua` in the images folder and run it. Powershell or a batch
script would probably be more convenient, but I don't know those, and you need to
run Lua files for the generator anyway. It creates renamed copies in a `\test\`
sub folder. That folder may or may not need to exist before hand. I've not tested.

If your unit blueprints themselves are mixed case then god help you.
