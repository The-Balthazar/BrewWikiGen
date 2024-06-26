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

* `OutputDirectory` should point to a clone of your mods wiki repository. If you
don't have one, it at very least needs to be a valid folder. Use forward slashes
`/`, and include a trailing slash at the end.

* `WikiGeneratorDirectory` should point to the folder `Main.lua` is in, like: `"C:/BrewWikiGen/"`.

* `EnvironmentData` contains the following environmental values:

  * `location` optionally is a path for it to search for environmental blueprints.
    If it finds none it will use a shell link in there instead. Note this isn't recursive.

  * `GenerateWikiPages`, if `true`, has the generator treat the environment as 'mod 0'.
    Otherwise it will just be used for added context for mod pages.

  * `RebuildBlueprints`, if not `false`, and blueprint rebuild is enabled, it will
    rebuild environment blueprints.

  * `RunSanityChecks`, if `true`, and blueprint sanity checks are enabled, it will
    give logs about potential errors in environment blueprints.

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

  * `PreModBlueprints`, and `PostModBlueprints`, optional arrays of functions to
    have run from the environments' `lua/system/Blueprints.lua` file before and
    after mod hook `lua/system/Blueprints.lua` `WikiBlueprints` functions. If
    `PreModBlueprints` isn't populated it will try to run a `WikiBlueprints`
    function from that file at that time instead.

  * `LOC`, optional, defines the location that *contains* the loc folder to try
    to load `loc/`Language`/strings_db.lua` from. It is expected to be valid Lua
    and is sandboxed with no access to functions.

  * `name`, `author`, `version`, and `icon` are for environment pseudo mod info.

  * `ExtraData` can point to an optional extra document of hand written content
    for specific sections of specific unit pages. It expects said document to be
    formatted as a `UnitData` table, keyed with unit IDs (upper case, or however
    the bp files are named if they are anything other than entirely lower case),
    with table values containing keys that match the syntax `[Section]Prefix` or
    `[Section]Suffix`, where `[Section]` matches the English names of sections,
    like `Weapons` or `Adjacency`, or `LeadSuffix`, with string values, or keyed
    with `Trivia` with the value either being a string or an array of strings; a
    string included as-is, and an array being formatted as a bulleted list, or keyed
    with `Videos` with an array of tables that match the format
    `{YouTube = '[Video ID]', '[Display name]'}`, where `[Video ID]` is the 11-ish
    character YouTube video ID, and `[Display name]` is the link caption to display.
    You can also force a section to appear and/or overwrite the main contents of it
    with a `[Section]` key, and either a `true` value to force it to appear, or
    a string value to force it to appear and overwrite the main body of the section.
    Prefix and suffix additions are still respected.
    Which is a very wordy way to say to look like this example:
    ```lua
    UnitData = {
        SSL0403 = {
            LeadSuffix = "Paragraph to appear after the generated lead paragraph.",
            AdjacencyPrefix = "Paragraph to appear before the Adjacency section.",
            Videos = {
                {YouTube = 'IInITjdtaPM', 'Time-lapse'},
            },
            Trivia = {
                'This would appear as a bullet point in the trivia section.',
                'As would this.',
            },
            Balance = "This unit is mad OP because it's the only way I can get an er",
        },
    }
    ```
    If you don't have such a document, you can remove the `ExtraData` field or
    set it to `false`.

  * `LoadExtraBlueprints`, optional, hash of extra blueprint types to actually load.
    `Unit` and `Projectile` are loaded by default, this allows loading of `Beam`,
    `Mesh`, `Prop`, `Emitter`, and `TrailEmitter` blueprints.

  * `base64`, optional, a table of flags for encoding image data as base 64. The
    only accepted flag is currently `UnitIcons`, because after testing, GitHub
    wiki markdown strips base64 `src` fields of images, so it's not actually useful
    for its intended purpose of limiting how quickly unauthenticated users hit the
    rate and rest limits for GitHub API calls, so was never developed further.

* `WikiOptions` contains the following bool-ish options:

  * `Language` should be the two letter language code for which LOC files should
    be loaded. They are not ISO_639-1. Non-`'US'` is only partially supported.

  * `GenerateHomePage`, `GenerateSidebar`, `GenerateModPages`, `GenerateUnitPages`,
    `GenerateProjectilesPage` and `GenerateCategoryPages`; `true` or `false`:
    Generate those parts or not.

  * `IncludeStrategicIcon`; `true` or `false`: If true it will include the strategic
    icon in the infobox and automatically copy required icons into the output from
    the generator directory. The packaged icons are from the *BrewLAN* large icon
    mod. If you want something else, like the vanilla icons, that's on you.

  * `AbilityDescriptions`; `true` or `false`: If false it lists the abilities of
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

  * `LocalRepuUnitPageBlueprintLink` and `OnlineRepoUnitPageBlueprintLink`, if they
    exist, it create unit page links to the original `.bp` files on the repo, using
    the the pair as a regex search and replace on the source location it found the
    reference `.bp` files at.

* `CleanupOptions` (Depreciated) handles options for 'cleanup', which uses regex
  expressions to remove specific values from blueprint values. Contains the
  following bool options:

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

* `RebuildBlueprintOptions` handles options for 'rebuild', which rebuilds blueprints
  by re-serializing loaded unit blueprints files. Beautifying them you might say. It
  contains the following bool options:

  * `RebuildBpFiles`; either `nil`/`false` or a hash of blueprint types to rebuild,
    for example:
    ```lua
    {
        Unit = true,
        Beam = false,
        Mesh = false,
        Prop = false,
        Emitter = false,
        Projectile = false,
        TrailEmitter = false,
    }
    ```
    would have it rebuild just unit blueprints. `false` values can be removed/excluded.
    Said blueprint types need to be actually loaded. See `LoadExtraBlueprints`.
  * `RemoveUnusedValues`, if `true`, removes the unit blueprint values:
    * `bp.General.Category`
    * `bp.General.Classification`
    * `bp.General.TechLevel`
    * `bp.General.UnitWeight`
    * `bp.Display.PlaceholderMeshName`
    * `bp.Display.SpawnRandomRotation`
    * `bp.UseOOBTestZoom`
    * `bp.Interface`

  * `CleanupBuildOnLayerCaps` if `true` does the following to `bp.Physics.BuildOnLayerCaps`:
    * If the unit has a motion type that isn't `RULEUMT_None`, it removes the table;
      they don't use it, and you shouldn't trust anything it says.
    * If the unit has a motion type of `RULEUMT_None` and has `LAYER_Land` as the
      only true value it removes the table; that's the default.
    * Otherwise it removes any false values. This will leave an empty table if there
      are no true values. This is functionally different from having no table.

  * `CleanupGeneralBackgroundIcon` if `true` and the unit has a `bp.General` table,
    changes the `bp.General.Icon` value to correctly match what layers the unit can
    exist on, or to indicate what it can build if it's a factory structure.

  * `CleanupWreckageLayers` if `true`, it will remove false values from wreckage layers.
  * `CleanupCommandCaps` if `true`, it will remove false values from command caps,
    if there were no true values, it removes the table.
  * `CleanupIntelOverlayCategories` if `true`, it will give the `OVERLAYRADAR`, `-SONAR`
    and `-OMNI` categories to anything with ranges in those things greater than 0,
    and take it from anything else. It will do the same for the `OVERLAYCOUNTERINTEL`
    category to anything that doesn't have a non-0 field radius for radar stealth,
    sonar stealth, or cloak, or a non-0 max jammer radius and more than 0 jammer blips.
  * `RemoveMilitaryOverlayCategories` if `true`, it will remove the `OVERLAY` categories
    for `AIR`, `NAVY`, `DEFENSE`, `DIRECTFIRE`, and `INDIRECTFIRE`. They are not
    referenced in `rangeoverlayparams.lua`.
  * `RemoveProductCategories` if `true`, removes categories starting with `PRODUCT`;
    in the core game they are only useful for *easily* restricting units added by
    patches and FA, which is a questionable use at best (and still attainable
    without the categories by checking `bp.Source` and the first letter of the ID),
    and in mods *generally* only indicates where the unit bp was originally copied
    from, or if updated to actually indicate the mod just occupies memory.

    *Steps down off soap box*
  * `RecalculateThreat` if `true`, recalculates the units threat, based on
    `Utilities/Threat.lua`.

* `ModDirectories` should point to your local copies of the mod(s) you wish to
load in the order you wish them to appear. It assumes, but doesn't require, multiple
mods. It requires a valid `mod_info.lua` file directly in each. If a mod contains
no units, then no page will be generated for it.

* `BlueprintExclusions` is an array of regex matches for what to exclude from
blueprint searches. They are matched against the whole path of any `.bp` file.
Lowercase.

* `BlueprintIdExclusions` is an array of exact blueprint IDs to exclude. Case insensitive.

* `FooterCategories` is a list of unit categories that the generator should create
category pages for, and link to at the bottom of the relevant units. They appear
on unit pages in the order written, so I tried to order them in a natural language
order, or as close to as possible. If you have no units in a given category, no
page will be generated. Add or remove as seems appropriate for your mods needs.

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
If you have important content in `/hook/lua/system/Blueprints.lua`, you can have
the generator run it by adding a `WikiBlueprints` function to that file called in
the same way as `ModBlueprints`, except by the generator instead of the game.

This is easier to achieve if your `Blueprints.lua` is formatted such that your
`ModBlueprints` hook is populated with function calls rather than with code ran
directly within that hook. However, as outlined below, it needs to be valid Lua 5.4.

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
which case uppercase. If it doesn't find the icon it will use a default fall-back.

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
  end
end

print("end")
```
To use it save it as `.lua` in the images folder, create a `/test/` subfolder and
run it. It creates renamed copies in the test folder.

If your unit blueprints themselves are mixed case then god help you.
