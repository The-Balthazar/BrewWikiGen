--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------
local categoryData = {}

local MenuSortCats = {
    SORTCONSTRUCTION = 'SORTCONSTRUCTION',
    SORTECONOMY = 'SORTECONOMY',
    SORTDEFENSE = 'SORTDEFENSE',
    SORTSTRATEGIC = 'SORTSTRATEGIC',
    SORTINTEL = 'SORTINTEL',
}

local function HashFactionCat(bp, cat)
    if FactionCategoryIndexes[cat] then
        if bp.FactionCategory == nil then
            bp.FactionCategory = cat
        elseif not bp.FactionCategoryHash[cat] then -- Make sure it's not a dupe of the same
            bp.FactionCategory = false -- has multiple faction categories
        end
        bp.FactionCategoryHash[cat] = cat
    elseif not cat then
        if bp.FactionCategory == nil then
            bp.FactionCategory = 'OTHER'
        end
    end
end

local function HashTechCat(bp, cat)
    local TCatI = TechCategoryIndexes[cat]
    if TCatI then
        bp.TechIndex = bp.TechIndex and math.min(bp.TechIndex, TCatI) or TCatI
    end
    HashFactionCat(bp, cat)
end

function HashUnitCategories(bp)
    bp.CategoriesHash = {
        -- Implicit categories
        [bp.id] = bp.id, -- lower case ID
        ALLUNITS = 'ALLUNITS',
    }
    bp.FactionCategoryHash = {}
    bp.FactionCategory = nil -- sanitise in case of multiple calls
    if not bp.Categories then return end
    for i, cat in ipairs(bp.Categories) do
        cat = string.upper(cat)
        bp.CategoriesHash[cat] = cat
        bp.SortCategory = bp.SortCategory or MenuSortCats[cat]
        HashTechCat(bp, cat)
    end
    bp.SortCategory = bp.SortCategory or 'SORTOTHER'
    HashFactionCat(bp)
end

function UnitPageCategories(bp)
    if not FooterCategories[1] then return '' end

    local cattext = ''
    for i, cat in ipairs(FooterCategories) do
        if bp.CategoriesHash[cat] then

            if not categoryData[cat] then categoryData[cat] = {} end
            table.insert(categoryData[cat], bp)

            cattext = cattext..(cattext~=''and' · 'or'').."\n"..xml:a{href='_categories.'..stringSanitiseFilename(cat)}(cat)
        end
    end
    if cattext ~= '' then
        cattext = "\n"..xml:table{align='center'}(
            xml:td{width='1215px'}('Categories : '..cattext),''
        )
    end
    return cattext
end

function GenerateCategoryPages()
    if not FooterCategories[1] then
        return
    end
    local num = 0
    for cat, datum in pairs(categoryData) do
        local function catRow(datum)
            local s = "\n"
            for i, bp in sortedpairs(datum, TechAscendingIDAscending) do
                local switch = {
                    [0] = bp.ID,
                    [1] = (bp.General.UnitName or '')..(bp.TechDescription or ''),
                    [2] = (bp.General.UnitName or '')..': '..(bp.TechDescription or ''),
                }

                s = s..
                '    '..xml:tr(
                '        '..xml:td(xml:a{href=bp.ID}(UnitIcon(bp.ID,{width='21px'}))),
                '        '..xml:td(xml:code{}(bp.id)),
                '        '..xml:td(xml:a{href=stringSanitiseFilename(bp.ModInfo.name)}(xml:img{src='icons/mods/'..(bp.ModInfo.icon and stringSanitiseFilename(bp.ModInfo.name, true, true) or 'mod')..'.png', width='21px'})),
                '        '..xml:td(xml:a{href=bp.ID}(switch[BinaryCounter{bp.General.UnitName, bp.TechDescription}])),
                '    ').."\n"
            end
            return s
        end

        md = io.open(OutputDirectory..'_categories.'..cat..'.md', "w")
        :write('Units with the '..xml:code(cat).." category.\n"..xml:table(catRow(datum)).."\n")
        :close()
        num = num+1
    end

    print("Generated "..num.." category pages")
end
