--[[
Copyright © 2021, Sjshovan (LoTekkie)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Yield nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Sjshovan (LoTekkie) BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

_addon.name = 'Yield';
_addon.description = 'Track and edit a variety of metrics related to gathering within a simple GUI.';
_addon.author = 'Sjshovan (LoTekkie) Sjshovan@Gmail.com';
_addon.version = '1.0.3';
_addon.commands = {'/yield', '/yld'};

require 'templates';
require 'libs.baseprices';
require 'libs.zonenames';
require 'helpers';

require 'common';
require 'ffxi.enums';
require 'ffxi.vanatime';
require 'timer';
require 'd3d8';

--[[ #TODOs & Notes
    - cleanup code
    - figure out a way to scale better, use table? can we align?
--]]

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local settings = table.copy(defaultSettingsTemplate);
local state    = table.copy(stateTemplate);
local metrics  = {};
local textures = {};

local ashitaResourceManager = AshitaCore:GetResourceManager();
local ashitaChatManager     = AshitaCore:GetChatManager();
local ashitaDataManager     = AshitaCore:GetDataManager();
local ashitaParty           = ashitaDataManager:GetParty();
local ashitaPlayer          = ashitaDataManager:GetPlayer();
local ashitaInventory       = ashitaDataManager:GetInventory();
local ashitaTarget          = ashitaDataManager:GetTarget();
local ashitaEntity          = ashitaDataManager:GetEntity();

local gatherTypes =
{
    [1] = { name = "harvesting", short = "ha.", target = "Harvesting Point", tool = "sickle",        toolId = 1020, action = "harvest" },
    [2] = { name = "excavating", short = "ex.", target = "Excavation Point", tool = "pickaxe",       toolId = 605,  action = "dig up" },
    [3] = { name = "logging",    short = "lo.", target = "Logging Point",    tool = "hatchet",       toolId = 1021, action = "cut off" },
    [4] = { name = "mining",     short = "mi.", target = "Mining Point",     tool = "pickaxe",       toolId = 605,  action = "dig up" },
    [5] = { name = "clamming",   short = "cl.", target = "Clamming Point",   tool = "clamming kit",  toolId = 511,  action = "find" },
    [6] = { name = "fishing",    short = "fi.", target = nil,                tool = "bait",          toolId = 3,    action = "caught" },
    [7] = { name = "digging",    short = "di.", target = nil,                tool = "gysahl green",  toolId = 4545, action = "dig" }
}

local settingsTypes =
{
    [1] = { name = "general" },
    [2] = { name = "setPrices" },
    [3] = { name = "setColors" },
    [4] = { name = "setAlerts" },
    [5] = { name = "reports" },
    [6] = { name = "feedback" },
    [7] = { name = "about" }
}

local helpTypes =
{
    [1] = { name = "generalInfo" },
    [2] = { name = "commonQuestions" },
}

local metricsTotalsToolTips =
{
    lost     = "Total number of yields lost.",
    breaks   = "Total number of broken tools.",
    yields   = "Total successful gathers.",
    attempts = "Total attempts at gathering.",
}

local windowScales =
{
    [0] = 1.0;
    [1] = 1.15;
    [2] = 1.30;
}

local playerStorage = { available_pct = 100 };

local containers =
{
    inventory = 0,
    satchel   = 5,
    sack      = 6,
    case      = 7,
    wardrobe  = 8,
    wardrobe2 = 10,
    wardrobe3 = 11,
    wardrobe4 = 12
}

local helpTable =
{
    commands =
    {
        helpSeparator('=', 26),
        helpTitle('Commands'),
        helpSeparator('=', 26),
        helpCommandEntry('unload', 'Unload Yield.'),
        helpCommandEntry('reload', 'Reload Yield.'),
        helpCommandEntry('find', 'Move Yield to the top left corner of your screen.');
        helpCommandEntry('about', 'Display information about Yield.'),
        helpCommandEntry('help', 'Display Yield commands.'),
        helpSeparator('=', 26),
    },

    about =
    {
        helpSeparator('=', 23),
        helpTitle('About'),
        helpSeparator('=', 23),
        helpTypeEntry('Name', string.format("%s by Lotekkie & Narpt", _addon.name)),
        helpTypeEntry('Description', _addon.description),
        helpTypeEntry('Author', _addon.author),
        helpTypeEntry('Version', _addon.version),
        helpTypeEntry('Support/Donate', "https://Paypal.me/Sjshovan OR For Gil donations: I play on Wings private server! (https://www.wingsxi.com/wings/) My in-game name is LoTekkie."),
        helpSeparator('=', 23),
    }
}

local modalConfirmPromptTemplate = "Are you sure you want to %s?";
local defaultFontSize            = imgui.GetFontSize();

local sounds = { [0] = "" };
local reports = {};

----------------------------------------------------------------------------------------------------
-- UI Variables
---------------------------------------------------------------------------------------------------
local uiVariables =
{
    -- User Set
    ["var_WindowOpacity"]         = { nil, ImGuiVar_FLOAT, 1.0 },
    ["var_ShowToolTips"]          = { nil, ImGuiVar_BOOLCPP, true },
    ["var_TargetValue"]           = { nil, ImGuiVar_UINT32, 0 },
    ["var_WindowScaleIndex"]      = { nil, ImGuiVar_UINT32, 0 },
    ["var_ShowDetailedYields"]    = { nil, ImGuiVar_BOOLCPP, true },
    ["var_YieldDetailsColor"]     = { nil, ImGuiVar_FLOATARRAY, 4 };
    ["var_UseImageButtons"]       = { nil, ImGuiVar_BOOLCPP, true },
    ["var_EnableSoundAlerts"]     = { nil, ImGuiVar_BOOLCPP, true },
    ["var_TargetSoundFile"]       = { nil, ImGuiVar_CDSTRING, 128},
    ["var_FishingSkillSoundFile"] = { nil, ImGuiVar_CDSTRING, 128},
    ["var_ClamBreakSoundFile"]    = { nil, ImGuiVar_CDSTRING, 128},
    ["var_AutoGenReports"]        = { nil, ImGuiVar_BOOLCPP, true },
    ["var_ReportFontScale"]       = { nil, ImGuiVar_FLOAT, 1.0 },
    ["var_WindowLocked"]          = { nil, ImGuiVar_BOOLCPP, false },

    -- Internal
    ['var_WindowVisible']          = { nil, ImGuiVar_BOOLCPP, true },
    ['var_SettingsVisible']        = { nil, ImGuiVar_BOOLCPP, false },
    ["var_HelpVisible"]            = { nil, ImGuiVar_BOOLCPP, false },
    ['var_AllSoundIndex']          = { nil, ImGuiVar_UINT32, 0 },
    ['var_AllColors']              = { nil, ImGuiVar_FLOATARRAY, 4 },
    ["var_TargetSoundIndex"]       = { nil, ImGuiVar_UINT32, 0 },
    ["var_FishingSkillSoundIndex"] = { nil, ImGuiVar_UINT32, 0 },
    ["var_ClamBreakSoundIndex"]    = { nil, ImGuiVar_UINT32, 0 },
    ["var_IssueTitle"]             = { nil, ImGuiVar_CDSTRING, 256 },
    ["var_IssueBody"]              = { nil, ImGuiVar_CDSTRING, 16384 },
    ['var_ReportSelected']         = { nil, ImGuiVar_INT32, nil },
}

----------------------------------------------------------------------------------------------------
-- func: loadUiVariables
-- desc: Loads the ui variables from the Yield settings file.
----------------------------------------------------------------------------------------------------
function loadUiVariables()
    -- Load the UI variables..
    imgui.SetVarValue(uiVariables["var_WindowOpacity"][1], settings.general.opacity);
    imgui.SetVarValue(uiVariables["var_TargetValue"][1], settings.general.targetValue);
    imgui.SetVarValue(uiVariables["var_ShowToolTips"][1], settings.general.showToolTips);
    imgui.SetVarValue(uiVariables["var_WindowScaleIndex"][1], settings.general.windowScaleIndex);
    imgui.SetVarValue(uiVariables["var_ShowDetailedYields"][1], settings.general.showDetailedYields);
    imgui.SetVarValue(uiVariables["var_UseImageButtons"][1], settings.general.useImageButtons);
    imgui.SetVarValue(uiVariables["var_EnableSoundAlerts"][1], settings.general.enableSoundAlerts);
    imgui.SetVarValue(uiVariables["var_AutoGenReports"][1], settings.general.autoGenReports);

    local r, g, b, a = colorToRGBA(settings.general.yieldDetailsColor);
    imgui.SetVarValue(uiVariables["var_YieldDetailsColor"][1], r/255, g/255, b/255, a/255);

    for gathering, yields in pairs(settings.yields) do -- per yield
        for yield, data in pairs(yields) do
            imgui.SetVarValue(uiVariables[string.format("var_%s_%s_prices", gathering, yield)][1], data.singlePrice, data.stackPrice);
            local r, g, b, a = colorToRGBA(data.color);
            imgui.SetVarValue(uiVariables[string.format("var_%s_%s_color", gathering, yield)][1], r/255, g/255, b/255, a/255);
            -- re-index for file changes
            local soundIndex = getSoundIndex(data.soundFile);
            imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)][1], soundIndex);
            local soundFile = sounds[soundIndex];
            imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1], soundFile);
        end
        -- per gathering
        imgui.SetVarValue(uiVariables[string.format("var_%s_priceMode", gathering)][1], settings.priceModes[gathering]);
    end

    for gathering, data in pairs(metrics) do -- per metric
        imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", gathering)][1], data.estimatedValue);
    end

    -- target sound file
    local soundIndex = getSoundIndex(settings.general.targetSoundFile);
    imgui.SetVarValue(uiVariables["var_TargetSoundIndex"][1], soundIndex);
    local soundFile = sounds[soundIndex];
    imgui.SetVarValue(uiVariables["var_TargetSoundFile"][1], soundFile);

    -- fishing skill sound file
    soundIndex = getSoundIndex(settings.general.fishingSkillSoundFile);
    imgui.SetVarValue(uiVariables["var_FishingSkillSoundIndex"][1], soundIndex);
    soundFile = sounds[soundIndex];
    imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"][1], soundFile);

    -- clam break sound file
    soundIndex = getSoundIndex(settings.general.clamBreakSoundFile);
    imgui.SetVarValue(uiVariables["var_ClamBreakSoundIndex"][1], soundIndex);
    soundFile = sounds[soundIndex];
    imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"][1], soundFile);

    -- All colors
    local r, g, b, a = colorToRGBA(-3877684);
    imgui.SetVarValue(uiVariables["var_AllColors"][1], r/255, g/255, b/255, a/255);
end

----------------------------------------------------------------------------------------------------
-- func: updatePlotPoints
-- desc: Update the display of all plots every second.
----------------------------------------------------------------------------------------------------
function updatePlotPoints()
    if state.timers[state.gathering] then
        totalSecs = metrics[state.gathering].secondsPassed
        metrics[state.gathering].secondsPassed = totalSecs + 1
        local timeSpan = 3600 -- one hour
        local timePassed = metrics[state.gathering].secondsPassed
        local pointsWindowMax = 60 -- one min
        local yieldsOverTime = metrics[state.gathering].totals.yields * (timeSpan / timePassed)
        local valueOverTime =  metrics[state.gathering].estimatedValue * (timeSpan / timePassed)
        if totalSecs >= pointsWindowMax then
            table.remove(metrics[state.gathering].points.yields, 2)
            table.remove(metrics[state.gathering].points.values, 2)
        end
        table.insert(metrics[state.gathering].points.yields, yieldsOverTime)
        table.insert(metrics[state.gathering].points.values, valueOverTime)
    end
end

----------------------------------------------------------------------------------------------------
-- func: updatePlayerStorage
-- desc: Update the global playerStorage table with gathering tool counts and available inventory space every second.
----------------------------------------------------------------------------------------------------
function updatePlayerStorage()
    local storage = {};
    for _, data in ipairs(gatherTypes) do
        if data.name ~= "clamming" then
            local itemId = data.toolId;
            if data.name == "fishing" then -- check equipment (for fishing bait)
                local item = ashitaInventory:GetEquippedItem(data.toolId);
                if item then
                    itemId = getItemIdFromContainers(item.ItemIndex, containers);
                end
            end
            storage[data.tool] = getItemCountFromContainers(itemId, containers);
        else -- clamming (key item)
            if (AshitaCore:GetDataManager():GetPlayer():HasKeyItem(data.toolId)) then
                storage[data.tool] = 1
            else
                storage[data.tool] = 0
            end
        end
    end
    storage["available"], storage["available_pct"] = getAvailableStorageFromContainers({0});
    playerStorage = storage;
end

----------------------------------------------------------------------------------------------------
-- func: getPrice
-- desc: Get the price for the given yield based on user settings.
----------------------------------------------------------------------------------------------------
function getPrice(itemName, gatherType)
    if gatherType == nil then gatherType = state.gathering; end
    local data = settings.yields[gatherType][itemName];
    local price = data.singlePrice or 0;
    switch(settings.priceModes[gatherType]) : caseof
    {
        [0] = function() price = data.stackPrice / data.stackSize or 0 end, -- stackPrice
        [2] = function() price = basePrices[data.id] or 0 end, -- NPCPrice
    }
    return math.floor(price);
end

----------------------------------------------------------------------------------------------------
-- func: adjTotal
-- desc: Modify the "total" metric by the value given.
----------------------------------------------------------------------------------------------------
function adjTotal(metricName, val)
    local total = metrics[state.gathering].totals[metricName]
    if total == nil then total = 0 end
    metrics[state.gathering].totals[metricName] = total + val
end

----------------------------------------------------------------------------------------------------
-- func: adjYield
-- desc: Modify the "yield" metric by the value given.
----------------------------------------------------------------------------------------------------
function adjYield(yieldName, val)
    local yield = metrics[state.gathering].yields[yieldName]
    if yield == nil then yield = 0 end
    metrics[state.gathering].yields[yieldName] = yield + val
    return metrics[state.gathering].yields[yieldName];
end

----------------------------------------------------------------------------------------------------
-- func: recordCurrentZone
-- desc: Get the current zone and append it to the zones table.
----------------------------------------------------------------------------------------------------
function recordCurrentZone()
    local zoneId = getPlayerZoneId();
    if not table.hasvalue(settings.zones[state.gathering], zoneId) then
        table.insert(settings.zones[state.gathering], zoneId);
    end
end

----------------------------------------------------------------------------------------------------
-- func: calcTargetProgress
-- desc: Calculate and normalize the value of progress towards reaching the target value.
----------------------------------------------------------------------------------------------------
function calcTargetProgress()
    local progress = metrics[state.gathering].estimatedValue/settings.general.targetValue
    if progress == math.huge or progress ~= progress then progress = 0.0 end
    if progress < 0 then progress = 0.0 end
    if progress > 1.0 then progress = 1.0 end
    return progress
end

----------------------------------------------------------------------------------------------------
-- func: getGatherTypeData
-- desc: Obtain a table of gathering related data.
----------------------------------------------------------------------------------------------------
function getGatherTypeData()
    for _, data in ipairs(gatherTypes) do
        if data.name == state.gathering then
            return data;
        end
    end
end

----------------------------------------------------------------------------------------------------
-- func: getItemCountFromContainers
-- desc: Obtain a count of the given item within the given container types.
----------------------------------------------------------------------------------------------------
function getItemCountFromContainers(itemId, containers)
    itemCount = 0;
    for containerName, containerId in pairs(containers) do
        for i = 0, ashitaInventory:GetContainerMax(containerId), 1 do -- check containers
            local entry = ashitaInventory:GetItem(containerId, i);
            if entry then
                if entry.Id == itemId and entry.Id ~= 0 and entry.Id ~= 65535 then
                    local item = ashitaResourceManager:GetItemById(entry.Id);
                    if item then
                        local quantity = 1;
                        if entry.Count and item.StackSize > 1 then
                            quantity = entry.Count;
                        end
                        itemCount = itemCount + quantity;
                    end
                end
            end
        end
    end
    return itemCount;
end

----------------------------------------------------------------------------------------------------
-- func: getItemPriceFromContainers
-- desc: Obtain the price of a given item from within the given container types.
----------------------------------------------------------------------------------------------------
function getItemPriceFromContainers(itemId, containers)
    for containerName, containerId in pairs(containers) do
        for i = 0, ashitaInventory:GetContainerMax(containerId), 1 do -- check containers
            local entry = ashitaInventory:GetItem(containerId, i);
            if entry then
                if entry.Id == itemId and entry.Id ~= 0 and entry.Id ~= 65535 then
                    return entry.Price;
                end
            end
        end
    end
    return 0;
end

----------------------------------------------------------------------------------------------------
-- func: getItemIdFromContainers
-- desc: Obtain an item ID from the given item index, checks within given container types.
----------------------------------------------------------------------------------------------------
function getItemIdFromContainers(itemIndex, containers)
    itemId = nil;
    for containerName, containerId in pairs(containers) do
        for i = 0, ashitaInventory:GetContainerMax(containerId), 1 do -- check containers
            local entry = ashitaInventory:GetItem(containerId, i);
            if entry then
                if entry.Index == itemIndex then
                   return entry.Id;
                end
            end
        end
    end
    return itemId;
end

----------------------------------------------------------------------------------------------------
-- func: getAvailableStorageFromContainers
-- desc: Obtain the available storage space from within the given container types.
----------------------------------------------------------------------------------------------------
function getAvailableStorageFromContainers(containers)
    total = 0;
    available = 0;
    for _, containerId in pairs(containers) do
        local max = ashitaInventory:GetContainerMax(containerId) - 1;
        local used = 0;
        total = total + max;
        for i = 0, max, 1 do
            local entry = ashitaInventory:GetItem(containerId, i);
            if entry then
                if entry.Id > 0 and entry.Id < 65535 then
                    used = used + 1;
                end
            end
        end
        available = available + (max - used);
    end
    return available, math.floor(available/total*100); -- pct
end

----------------------------------------------------------------------------------------------------
-- func: sortKeysByTotalValue
-- desc: Sort yields based on their total value.
----------------------------------------------------------------------------------------------------
function table.sortKeysByTotalValue(t, desc)
    local ret = {}
    for k, v in pairs(t) do
        table.insert(ret, k)
    end
    local totalA = function(a, b) return math.floor(getPrice(a) * metrics[state.gathering].yields[a]); end;
    local totalB = function(a, b) return math.floor(getPrice(b) * metrics[state.gathering].yields[b]); end;
    if (desc) then
        table.sort(ret, function(a, b) return totalA(a, b) < totalB(a, b); end);
    else
        table.sort(ret, function(a, b) return totalA(a, b) > totalB(a, b); end);
    end
    return ret;
end

----------------------------------------------------------------------------------------------------
-- func: updateAllStates
-- desc: Set all tracked gathering states to the given state.
----------------------------------------------------------------------------------------------------
function updateAllStates(newState)
    state.gathering = newState;
    state.settings.setPrices.gathering = newState;
    state.settings.setColors.gathering = newState;
    state.settings.setAlerts.gathering = newState;
    state.settings.reports.gathering = newState;
end

----------------------------------------------------------------------------------------------------
-- func: getSoundOptions
-- desc: Obtain a formatted string of sound options used for sound selection drop-downs.
----------------------------------------------------------------------------------------------------
function getSoundOptions()
    local options = "None\0";
    for i, file in pairs(sounds) do
        options = options..file.."\0";
    end
    return options.."\0";
end

----------------------------------------------------------------------------------------------------
-- func: alertYield
-- desc: Play the user set sound for the given yield if alerts are enabled.
----------------------------------------------------------------------------------------------------
function alertYield(yieldName)
    local yieldData = settings.yields[state.gathering][yieldName];
    if yieldData.soundFile ~= "" then
        return playAlert(yieldData.soundFile);
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: playAlert
-- desc: Play the given sound file if alerts are enabled.
----------------------------------------------------------------------------------------------------
function playAlert(soundFile)
    if settings.general.enableSoundAlerts then
        playSound(soundFile);
        return true;
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: playSound
-- desc: Play the given sound file.
----------------------------------------------------------------------------------------------------
function playSound(soundFile)
    if soundFile ~= "" then
        ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
    end
end

----------------------------------------------------------------------------------------------------
-- func: getSoundIndex
-- desc: Obtain the stored table index of the given sound file name.
----------------------------------------------------------------------------------------------------
function getSoundIndex(fileName)
    for i, file in pairs(sounds) do
        if fileName == file then
            return i;
        end
    end
    return 0;
end

----------------------------------------------------------------------------------------------------
-- func: checkTargetAlertReady
-- desc: Check if we should play the target value alert.
----------------------------------------------------------------------------------------------------
function checkTargetAlertReady()
    state.values.targetAlertReady = metrics[state.gathering].estimatedValue < settings.general.targetValue;
end

----------------------------------------------------------------------------------------------------
-- func: sendIssue
-- desc: Send an issue or feedback to github issues.
----------------------------------------------------------------------------------------------------
function sendIssue(title, body)
    io.popen(string.format('%s "%s" "%s"', _addon.path .. "tools\\sendissue.exe", title, body));
end

----------------------------------------------------------------------------------------------------
-- func: fileExists
-- desc: Check if the given file exits.
----------------------------------------------------------------------------------------------------
function fileExists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

----------------------------------------------------------------------------------------------------
-- func: linesFrom
-- desc: Obtain lines from the given file.
----------------------------------------------------------------------------------------------------
function linesFrom(file)
  if not fileExists(file) then return {} end
  lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

----------------------------------------------------------------------------------------------------
-- func: getPlayerName
-- desc: Obtain the current players name.
----------------------------------------------------------------------------------------------------
function getPlayerName(lower)
    local name = ashitaParty:GetMemberName(0);
    if lower then
        name = string.lower(name);
    end
    return name
end

----------------------------------------------------------------------------------------------------
-- func: getPlayerZoneId
-- desc: Obtain the current zone ID.
----------------------------------------------------------------------------------------------------
function getPlayerZoneId()
    return ashitaParty:GetMemberZone(0);
end

----------------------------------------------------------------------------------------------------
-- func: generateGatheringReport
-- desc: Generate a report file using tracked metrics.
----------------------------------------------------------------------------------------------------
function generateGatheringReport(gatherType)
    if gatherType == nil then gatherType = state.gathering; end
    if getPlayerName() == "" then return false; end
    local zones = settings.zones[gatherType];
    local zonesCount = table.count(zones);
    local metrics = metrics[gatherType];
    local zoneName = zoneNames[getPlayerZoneId()];
    if zonesCount > 0 then -- there has been some activity here.
        zoneName = zoneNames[zones[1]];
        if zonesCount > 1 then zoneName = "Multiple Zones"; end
    end
    zoneName = string.gsub(zoneName, " ", "_");
    local sep = "------------\n";
    local date = os.date('*t');
    local dateTimeStamp = string.format("%.4d_%.2d_%.2d__%.2d_%.2d_%.2d", date.year, date.month, date.day, date.hour, date.min, date.sec);
    local fname = string.format('%s__%s.log', zoneName, dateTimeStamp);
    local fpath = string.format('%s/%s/%s/%s', _addon.path, 'reports', getPlayerName(), gatherType);
    if (not ashita.file.dir_exists(fpath)) then
        ashita.file.create_dir(fpath);
    end
    local file = io.open(string.format('%s/%s', fpath, fname), 'w+');
    if (file ~= nil) then
        local dateTimeStampNice = string.format("%.4d-%.2d-%.2d %.2d:%.2d:%.2d", date.year, date.month, date.day, date.hour, date.min, date.sec);
        file:write(string.format("%s YIELD REPORT : [%s]\n", string.upper(gatherType), dateTimeStampNice));
        file:write(sep);
        file:write("ZONES\n");
        file:write(sep);
        if zonesCount > 1 then
            for i, id in ipairs(settings.zones[gatherType]) do
                local zoneName = zoneNames[id];
                file:write("\t"..zoneName.."\n");
            end
        else
            file:write("\t"..zoneName.."\n");
        end
        file:write(sep);
        file:write("METRICS\n");
        file:write(sep);
        for name, val in pairs(metrics.totals) do
            file:write(string.format("\t%s: %s\n", name, val));
        end
        local successRate = metrics.totals.yields/metrics.totals.attempts * 100
        if successRate == math.huge or successRate ~= successRate then successRate = 0.0 end
        if successRate < 0 then successRate = 0.0 end
        file:write(string.format("\tSuccess Rate: %.2f%%\n", successRate, 0, 100));
        file:write(string.format("\tTime Passed: %s\n", os.date("!%X", (metrics.secondsPassed))));
        file:write(string.format("\tEstimated Value: %s\n", metrics.estimatedValue));
        file:write(string.format("\tYields per Hour: %.2f\n", metrics.points.yields[#metrics.points.yields]));
        file:write(string.format("\tValue per Hour: %.2f\n", metrics.points.values[#metrics.points.values]));
        file:write(string.format("\tTarget Value: %s\n", settings.general.targetValue));
        local targetReached = metrics.estimatedValue >= settings.general.targetValue;
        local targetReachedAnswer = "No";
        if targetReached then targetReachedAnswer = "Yes"; end
        file:write(string.format("\tTarget Reached: %s\n", targetReachedAnswer));
        file:write(sep);
        file:write("YIELDS\n");
        file:write(sep);
        if table.count(metrics.yields) > 0 then
            for name, count in pairs(metrics.yields) do
                file:write(string.format("\t%s: %s %s\n", name, count, string.format("@%dea.=(%s)", getPrice(name, gatherType), math.floor(getPrice(name, gatherType) * metrics.yields[name]))));
            end
        else
            file:write("\tNone");
        end
        file:close();
        reports[gatherType][#reports[gatherType] + 1] = fname;
        return true;
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: saveSettings
-- desc: Saves the Yield settings file.
----------------------------------------------------------------------------------------------------
function saveSettings()
    -- Obtain the configuration variables..
    settings.general.opacity               = imgui.GetVarValue(uiVariables["var_WindowOpacity"][1]);
    settings.general.targetValue           = imgui.GetVarValue(uiVariables["var_TargetValue"][1]);
    settings.general.showToolTips          = imgui.GetVarValue(uiVariables["var_ShowToolTips"][1]);
    settings.general.windowScaleIndex      = imgui.GetVarValue(uiVariables["var_WindowScaleIndex"][1]);
    settings.general.yieldDetailsColor     = colorTableToInt(imgui.GetVarValue(uiVariables["var_YieldDetailsColor"][1]));
    settings.general.useImageButtons       = imgui.GetVarValue(uiVariables["var_UseImageButtons"][1]);
    settings.general.enableSoundAlerts     = imgui.GetVarValue(uiVariables["var_EnableSoundAlerts"][1]);
    settings.general.targetSoundFile       = imgui.GetVarValue(uiVariables["var_TargetSoundFile"][1]);
    settings.general.fishingSkillSoundFile = imgui.GetVarValue(uiVariables["var_FishingSkillSoundFile"][1]);
    settings.general.clamBreakSoundFile    = imgui.GetVarValue(uiVariables["var_ClamBreakSoundFile"][1]);
    settings.general.autoGenReports        = imgui.GetVarValue(uiVariables["var_AutoGenReports"][1]);

    for gathering, yields in pairs(settings.yields) do
        for yield, data in pairs(yields) do
            local yieldSettings = settings.yields[gathering][yield];
            local prices = imgui.GetVarValue(uiVariables[string.format("var_%s_%s_prices", gathering, yield)][1]);
            yieldSettings.singlePrice = prices[1];
            yieldSettings.stackPrice  = prices[2];
            yieldSettings.color       = colorTableToInt(imgui.GetVarValue(uiVariables[string.format("var_%s_%s_color", gathering, yield)][1]));
            yieldSettings.soundFile   = imgui.GetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1]);
        end
        settings.priceModes[gathering] = imgui.GetVarValue(uiVariables[string.format("var_%s_priceMode", gathering)][1]);
    end

    for _, data in ipairs(gatherTypes) do
        metrics[data.name].estimatedValue = tonumber(imgui.GetVarValue(uiVariables[string.format("var_%s_estimatedValue", data.name)][1]))
    end

    -- Obtain the metrics..
    settings.metrics = table.copy(metrics);

    -- Obtain the state..
    settings.state.gathering           = state.gathering;
    settings.state.lastKnownGathering  = state.values.lastKnownGathering;
    settings.state.windowPosX          = state.window.posX;
    settings.state.windowPosY          = state.window.posY;
    settings.state.clamBucketBroken    = state.values.clamBucketBroken;
    settings.state.clamConfirmedYields = state.values.clamConfirmedYields;
    settings.state.clamBucketTotal     = state.values.clamBucketTotal;
    settings.state.clamBucketPz        = state.values.clamBucketPz;
    settings.state.clamBucketPzMax     = state.values.clamBucketPzMax;
    settings.state.firstLoad           = state.firstLoad;

    -- Save the configuration variables..
    ashita.settings.save(_addon.path .. 'settings/settings.json', settings);
end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Called when the addon is loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
    state.initializing = true

    -- Ensure the settings folder exists..
    ashita.file.create_dir(_addon.path .. '/settings/');
    ashita.file.create_dir(_addon.path .. '/reports/');
    ashita.file.create_dir(_addon.path .. '/reports/' .. getPlayerName());

    -- Load and merge the users settings..
    settings = ashita.settings.load_merged(
        _addon.path .. '/settings/settings.json', settings
    )

    -- loop through gathering types..
    for _, data in ipairs(gatherTypes) do
        -- Populate the metrics table..
        if table.haskey(settings.metrics, data.name) then
            metrics[data.name] = table.copy(settings.metrics[data.name]);
        else
            metrics[data.name] = table.copy(metricsTemplate);
        end
        -- Initialize state timers..
        state.timers[data.name] = false;
        -- Add estimated value ui variables...
        uiVariables[string.format("var_%s_estimatedValue", data.name)] = { nil, ImGuiVar_UINT32, 0 }
        -- Add textures..
        local texturePath = string.format('images\\%s.png', data.name)
        local hres, texture = ashita.d3dx.CreateTextureFromFileA(_addon.path .. texturePath);

        if texture == nil then
            state.values.btnTextureFailure = true;
            displayResponse(string.format("Yield: Failed to load texture (%s). Buttons will now default to text display.", texturePath), "\31\167%s");
            imgui.SetVarValue(uiVariables["var_UseImageButtons"][1], false);
        end
        textures[data.name] = texture;
    end

    -- Update saved gathering state..
    updateAllStates(settings.state.gathering);

    -- misc state updates..
    checkTargetAlertReady();
    state.values.lastKnownGathering  = settings.state.lastKnownGathering;
    state.window.posX                = settings.state.windowPosX;
    state.window.posY                = settings.state.windowPosY;
    state.values.clamBucketBroken    = settings.state.clamBucketBroken;
    state.values.clamConfirmedYields = settings.state.clamConfirmedYields;
    state.values.clamBucketTotal     = settings.state.clamBucketTotal;
    state.values.clamBucketPz        = settings.state.clamBucketPz;
    state.values.clamBucketPzMax     = settings.state.clamBucketPzMax;
    state.firstLoad                  = settings.state.firstLoad;

    -- Add price ui variables from settings..
    for gathering, yields in pairs(settings.yields) do
        for yield, data in pairs(yields) do -- per yield
            uiVariables[string.format("var_%s_%s_prices", gathering, yield)] = { nil, ImGuiVar_INT32ARRAY, 2 };
            uiVariables[string.format("var_%s_%s_color", gathering, yield)] = { nil, ImGuiVar_FLOATARRAY, 4 };
            uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)] = { nil, ImGuiVar_CDSTRING, 128 };
            uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)] = { nil, ImGuiVar_UINT32, 0 };
        end
        -- per gathering
        uiVariables[string.format("var_%s_priceMode", gathering)] = { nil, ImGuiVar_UINT32, 0 };
    end

    -- Retrieve sounds files..
    for f in io.popen(string.format('dir "%s\\sounds" /b', _addon.path)):lines() do
        sounds[#sounds + 1] = f;
    end

    -- Retrieve reports..
    for _, data in ipairs(gatherTypes) do
        if not table.haskey(reports, data.name) then reports[data.name] = {}; end
        if getPlayerName() ~= "" then
            local dirName = string.format("%s\\reports\\%s\\%s", _addon.path, getPlayerName(), data.name);
            if ashita.file.dir_exists(dirName) then
                for f in io.popen(string.format("dir %s /b", dirName)):lines() do
                    reports[data.name][#reports[data.name] + 1] = f;
                end
            else
                ashita.file.create_dir(dirName);
            end
            state.reportsLoaded = true;
        end
    end

    -- Create timers..
    if ashita.timer.create_timer("updatePlotPoints") then
        ashita.timer.adjust_timer("updatePlotPoints", 1, 0, updatePlotPoints)
        ashita.timer.start_timer("updatePlotPoints")
    end
    if ashita.timer.create_timer("updatePlayerStorage") then
        ashita.timer.adjust_timer("updatePlayerStorage", 1, 0, updatePlayerStorage)
        ashita.timer.start_timer("updatePlayerStorage")
    end

    if ashita.timer.create_timer("inactivityCheck") then
        ashita.timer.adjust_timer("inactivityCheck", 1, 0, function()
            if state.timers[state.gathering] then
                state.values.inactivitySeconds = state.values.inactivitySeconds + 1;
                if state.values.inactivitySeconds == 300 then -- 5min
                    for _, data in ipairs(gatherTypes) do
                        state.timers[data.name] = false; -- shutdown timers
                    end
                    displayResponse("Yield: Timers halted due to inactivity.", "\31\140%s");
                end
            else
                state.values.inactivitySeconds = 0;
            end
            if state.attempting then
                state.values.inactivitySeconds = 0;
            end
        end)
        ashita.timer.start_timer("inactivityCheck")
    end

    -- Initialize custom variables..
    for varName, data in pairs(uiVariables) do
        if (data[2] >= ImGuiVar_CDSTRING) then
            uiVariables[varName][1] = imgui.CreateVar(uiVariables[varName][2], uiVariables[varName][3]);
        else
            uiVariables[varName][1] = imgui.CreateVar(uiVariables[varName][2]);
        end
        if (#data > 2 and data[2] < ImGuiVar_CDSTRING) then
            imgui.SetVarValue(uiVariables[varName][1], uiVariables[varName][3]);
        end
    end

    -- Load ui variables from the settings file..
    loadUiVariables();

    if state.firstLoad then
        imgui.SetVarValue(uiVariables["var_HelpVisible"][1], true);
    end
end)

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Save the settings file..
    saveSettings();

    -- Remove timers..
    ashita.timer.remove_timer("updatePlotPoints");
    ashita.timer.remove_timer("updatePlayerStorage");
    ashita.timer.remove_timer("inactivityCheck");

    -- Cleanup the custom variables..
    for varName, data in pairs(uiVariables) do
        if (uiVariables[varName][1] ~= nil) then
            imgui.DeleteVar(uiVariables[varName][1]);
        end
        uiVariables[varName][1] = nil;
    end
end)

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when the addon is handling a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    local commandArgs = command:lower():args();

    if not table.hasvalue(_addon.commands, commandArgs[1]) then
        return false;
    end

    local responseMessage = "";
    local success = true;

    if commandArgs[2] == 'reload' or commandArgs[2] == 'r' then
        AshitaCore:GetChatManager():QueueCommand('/addon reload yield', 1);

    elseif commandArgs[2] == 'unload' or commandArgs[2] == 'u' then
        response_message = 'Thank you for using Yield. Goodbye.';
        AshitaCore:GetChatManager():QueueCommand('/addon unload yield', 1);

    elseif commandArgs[2] == 'about' or commandArgs[2] == 'a' then
        displayHelp(helpTable.about);

    elseif commandArgs[2] == 'help' or commandArgs[2] == 'h' then
        displayHelp(helpTable.commands);
    --[[ test commands
    elseif commandArgs[2] == "test" then
        settings.general.showToolTips = not settings.general.showToolTips;

    elseif commandArgs[2] == "test2" then
        settings.general.windowScaleIndex = cycleIndex(settings.general.windowScaleIndex, 0, 2, 1);
    --]]
    elseif commandArgs[2] == "find" or commandArgs[2] == 'f' then
        imgui.SetWindowPos(string.format("%s v%s by Lotekkie & Narpt", _addon.name, _addon.version), 0, 0);
    else
        displayHelp(helpTable.commands);
    end

    if responseMessage ~= "" then
        displayResponse(
            commandResponse(response_message, success)
        );
    end

    return false;
end)

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)

    -- Ensure proper chat modes..
    if not table.hasvalue({919, 654, 702, 662, 664, 129}, mode) then state.attempting = false; return false; end
    if (blocked) then state.attempting = false; return false; end

    -- Remove colors form message..
    message = string.strip_colors(message);
    message = string.lower(message);

    -- Ensure we care..
    if not state.attempting then
        if state.values.lastKnownGathering == "fishing" then -- play alert on skill-up
            local skillup = string.contains(message, string.format("%s's fishing skill rises", getPlayerName(true)))
            if skillup then
                playAlert(imgui.GetVarValue(uiVariables["var_FishingSkillSoundFile"][1]));
            end
        elseif getPlayerZoneId() == 4 then -- Bibiki Bay
            local obtainedBucket = string.contains(message, "obtained key item: clamming kit");
            local returnedBucket = string.contains(message, "you return the clamming kit");
            local upgraded = string.match(message, "^your clamming capacity has increased to (.*) ponzes!")
            if upgraded then
                state.values.clamBucketPzMax = tonumber(upgraded);
            end
            if obtainedBucket or returnedBucket then
                state.values.clamConfirmedYields = table.copy(metrics["clamming"].yields);
                state.values.clamBucketBroken = false;
                state.values.clamBucketPz = 0;
                state.values.clamBucketPzMax = 50;
                saveSettings();
            end
        end
        return false;
    end

    -- Ensure correct state..
    updateAllStates(state.attemptType);

    -- Check the attempt.
    if state.attempting then
        if not state.timers[state.gathering] then
            state.timers[state.gathering] = true
        end

        local val = 0;
        local success = false;
        local successBreak = false;
        local unable = false;
        local broken = false;
        local full = false;

        local gatherData = getGatherTypeData(state.gathering);
        switch(gatherData.name) : caseof
        {
            ["digging"] = function ()
                successBreak = false;
                success = string.match(message, "obtained: (.*).") or successBreak
                unable = string.contains(message, "you dig, but find nothing.");
                broken = false;
                lost = false;
            end,
            ["fishing"] = function ()
                successBreak = false;
                success = string.match(message, string.format("%s %s a[n]? (.*)!", getPlayerName(true), gatherData.action)) or successBreak
                unable = string.contains(message, "you didn't catch anything.") or string.contains(message, "you give up");
                broken = string.contains(message, "your rod breaks.");
                lost = string.contains(message, "you lost your catch") or string.contains(message, "your line breaks.") or string.contains(message, "but cannot carry any more items.");
            end,
            ["clamming"] = function ()
                successBreak = false;
                success = string.match(message, string.format("^you %s a[n]? (.*) and toss it into your bucket.", gatherData.action));
                unable = string.contains(message, "with a broken bucket!") --or string.contains(message, "someone has been digging here.");
                broken = string.contains(message, "and toss it into your bucket...");
                lost = false;
                if success then
                    if state.values.clamBucketTotal == nil then state.values.clamBucketTotal = 0; end
                    state.values.clamBucketTotal = state.values.clamBucketTotal + 1;
                end
                if broken then
                    success = nil;
                    metrics[state.gathering].yields = table.copy(state.values.clamConfirmedYields);
                    metrics[state.gathering].totals.yields = table.sumValues(metrics[state.gathering].yields);
                    metrics[state.gathering].estimatedValue = 0;
                    state.values.clamBucketTotal = 0;
                    state.values.clamBucketPz = 0;
                    state.values.clamBucketPzMax = 50;
                    for yield, count in pairs(metrics[state.gathering].yields) do
                        local price = getPrice(yield);
                        metrics[state.gathering].estimatedValue = metrics[state.gathering].estimatedValue + (price * count);
                    end
                    imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1], metrics[state.gathering].estimatedValue);
                    playAlert(imgui.GetVarValue(uiVariables["var_ClamBreakSoundFile"][1]));
                end
                if broken or unable then
                    state.values.clamBucketBroken = true;
                    ashita.timer.once(1, function () -- let plots update a second
                        state.timers[state.gathering] = false;
                    end);
                    saveSettings();
                end
            end,
            ["default"] = function ()
                successBreak = string.match(message, string.format("^you %s a[n]? (.*), but your %s .*", gatherData.action, gatherData.tool));
                success = string.match(message, string.format("^you successfully %s a[n]? (.*)!", gatherData.action)) or successBreak
                unable = string.contains(message, "you are unable to");
                broken = string.match(message, "^your (.*) breaks!");
                lost = false;
            end
        }

        full = string.contains(message, "you cannot carry any more") or string.contains(message, "your inventory is full");

        if success then
            local of = string.match(success, "of (.*)");
            if of then success = of end;
        end
        if success then
            success = string.lowerToTitle(success);
            if not table.haskey(settings.yields[state.gathering], success) then
                displayResponse(string.format("Yield: The %s yield name (%s) is unrecognized! Please report this to LoTekkie.", state.gathering, success), "\31\167%s");
                state.attempting = false;
                return false;
            end
            val = getPrice(success);
            adjYield(success, 1);
            if state.gathering == "clamming" then
                state.values.clamBucketPz = state.values.clamBucketPz + settings.yields[state.gathering][success].pz
            end
            local soundPlaying = alertYield(success);
            if successBreak then adjTotal("breaks", 1); end
            adjTotal("yields", 1);
        elseif broken then
            adjTotal("breaks", 1);
        elseif full or lost then
            adjTotal("lost", 1);
        end
        if success or unable or broken or full or lost then
            adjTotal("attempts", 1);
            recordCurrentZone();
            state.values.lastKnownGathering = state.gathering;
            state.attempting = false;
        end
        curVal = metrics[state.gathering].estimatedValue;
        metrics[state.gathering].estimatedValue = curVal + val;
        imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1], metrics[state.gathering].estimatedValue);
        local targetReached = metrics[state.gathering].estimatedValue >= settings.general.targetValue;
        if state.values.targetAlertReady and targetReached then
            local soundFile = imgui.GetVarValue(uiVariables["var_TargetSoundFile"][1]);
            playAlert(soundFile);
            state.values.targetAlertReady = false;
        end
    end
    return false;
end);

----------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Event called when the client is sending a packet to the server.
----------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet, packet_modified, blocked)
    if id == 0x36 then -- helm
        for gathering, data in pairs(gatherTypes) do
            if data.target == ashitaTarget:GetTargetName() then
                state.attempting = true;
                state.attemptType = data.name;
                state.gathering = data.name;
            end
        end
    elseif id == 0x01A then -- clam
        if ashitaTarget:GetTargetName() == "Clamming Point" and AshitaCore:GetDataManager():GetPlayer():HasKeyItem(511) then
            state.attempting = true;
            state.attemptType = "clamming";
            state.gathering = "clamming";
        elseif struct.unpack("H", packet, 0x0A) == 0x1104 then -- digging
            state.attempting = true;
            state.attemptType = "digging";
            state.gathering = "digging";
        else
            state.attempting = false;
        end
    elseif id == 0x110 then -- fishing
        local action = struct.unpack("H", packet, 0x0E + 1);
        if action ~= 4 then
            state.attempting = true;
            state.attemptType = "fishing";
            state.gathering = "fishing";
        else
            state.attempting = false
        end
    end
    return false;
end);

----------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the client is receiving a packet from the server.
----------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet, packet_modified, blocked)
    if id == 0x00B then -- zoning out (11)
        state.attempting = false;
        state.values.zoning = true;
        state.values.preZoneCounts["available"] = playerStorage['available'];
        state.values.preZoneCounts["available_pct"] = playerStorage["available_pct"];
        for _, data in ipairs(gatherTypes) do
            state.timers[data.name] = false; -- shutdown timers
            state.values.preZoneCounts[data.tool] = playerStorage[data.tool];
        end
        if state.values.lastKnownGathering ~= nil then
            if settings.general.autoGenReports then
                generateGatheringReport(state.values.lastKnownGathering);
            end
            state.values.lastKnownGathering = nil;
        end
    elseif (id == 0x01D and state.values.zoning) then -- inventory ready
          state.values.zoning = false;
    end
    return false;
end);

-- The settings window
local SettingsWindow =
{
    modalSaveAction = function (self)
        imgui.CloseCurrentPopup();
        imgui.SetVarValue(uiVariables["var_SettingsVisible"][1], false)
        updateAllStates(state.gathering);
        saveSettings();
        imgui.SetVarValue(uiVariables["var_AllSoundIndex"][1], 0);
        local r, g, b, a = colorToRGBA(-3877684);
        imgui.SetVarValue(uiVariables["var_AllColors"][1], r/255, g/255, b/255, a/255);
        checkTargetAlertReady();
        state.values.feedbackSubmitted = false;
        state.values.feedbackMissing = false;
        imgui.SetVarValue(uiVariables["var_IssueTitle"][1], "");
        imgui.SetVarValue(uiVariables["var_IssueBody"][1], "")
        imgui.SetVarValue(uiVariables['var_ReportSelected'][1], nil);
        state.values.currentReportName = nil;
    end,

    Draw = function (self, title)
        local scaledHeightReduction = 0;
        if state.window.scale == 1.15 then scaledHeightReduction = 7 elseif state.window.scale == 1.30 then scaledHeightReduction = 12 end;
        imgui.SetNextWindowSize(state.window.widthSettings, state.window.heightSettings - scaledHeightReduction, ImGuiSetCond_Always);
        if state.values.centerWindow then
            imgui.SetNextWindowPosCenter(1);
            state.values.centerWindow = false;
        end
        if (not imgui.Begin(title, uiVariables["var_SettingsVisible"][1], imgui.bor(ImGuiWindowFlags_MenuBar, ImGuiWindowFlags_NoResize))) then
            imgui.End();
            return;
        end

        imgui.SetWindowFontScale(state.window.scale);
        -- SETTINGS_MENU
        if imgui.BeginMenuBar() then
            for i, data in ipairs(settingsTypes) do
                local btnName = string.camelToTitle(data.name);
                imguiPushActiveBtnColor(state.settings.activeIndex == i);
                if imgui.Button(btnName) then
                   state.settings.activeIndex = i;
                   state.values.feedbackSubmitted = false;
                   state.values.feedbackMissing = false;
                   imgui.SetVarValue(uiVariables["var_IssueTitle"][1], "");
                   imgui.SetVarValue(uiVariables["var_IssueBody"][1], "")
                end
                imgui.PopStyleColor();
                imgui.SameLine(0.0, state.window.spaceSettingsBtn);
            end
            imgui.EndMenuBar();
        end
        -- /SETTINGS_MENU

        -- render settings pages..
        imgui.BeginGroup();
        imgui.Spacing();
        switch(state.settings.activeIndex) : caseof
        {
            [1] = function() renderSettingsGeneral() end,
            [2] = function() renderSettingsSetPrices() end,
            [3] = function() renderSettingsSetColors() end,
            [4] = function() renderSettingsSetAlerts() end,
            [5] = function() renderSettingsReports() end,
            [6] = function() renderSettingsFeedback() end,
            [7] = function() renderSettingsAbout() end,
        };
        imgui.EndGroup();

        imgui.Spacing();

        if imgui.Button("Done") then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"][1], false);
        end

        imgui.SameLine();
        imgui.Text("OR close window to save.");

        -- Recalculate
        local yieldsExist = table.count(metrics[state.settings.setPrices.gathering].yields) > 0;
        if state.settings.activeIndex == 2 and yieldsExist then -- if we are setting prices
            local spaceBtnRecalculate = state.window.spaceBtnRecalculate;
            if settings.general.showToolTips then spaceBtnRecalculate = spaceBtnRecalculate - ( imgui.GetFontSize() * 24 / defaultFontSize ) end
            if state.window.scale == 1.15 then spaceBtnRecalculate = spaceBtnRecalculate + 3 end;
            if state.window.scale == 1.30 then spaceBtnRecalculate = spaceBtnRecalculate + 6 end;
            imgui.SameLine(0.0, spaceBtnRecalculate);
            if imguiShowToolTip("Recalculate the estimated value with your current price settings.", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if imgui.Button("Recalculate Value") then
                updateAllStates(state.settings.setPrices.gathering);
                metrics[state.gathering].estimatedValue = 0;
                for yield, count in pairs(metrics[state.gathering].yields) do
                    local price = getPrice(yield);
                    metrics[state.gathering].estimatedValue = metrics[state.gathering].estimatedValue + (price * count);
                end
                imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1], metrics[state.gathering].estimatedValue);
            end
        end

        if state.initializing then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"][1], false);
            imgui.SetVarValue(uiVariables["var_HelpVisible"][1], false);
            imgui.CloseCurrentPopup();
        end

        imgui.PopStyleVar();
        imgui.End();
    end
}

-- The help window
local helpWindow =
{
    Draw = function (self, title)
        local scaledHeightReduction = 0;
        if state.window.scale == 1.15 then scaledHeightReduction = 7 elseif state.window.scale == 1.30 then scaledHeightReduction = 12 end;
        imgui.SetNextWindowSize(state.window.widthSettings, state.window.heightSettings - scaledHeightReduction, ImGuiSetCond_Always);
        if state.values.centerWindow then
            imgui.SetNextWindowPosCenter(1);
            state.values.centerWindow = false;
        end
        if (not imgui.Begin(title, uiVariables["var_HelpVisible"][1], imgui.bor(ImGuiWindowFlags_MenuBar, ImGuiWindowFlags_NoResize))) then
            imgui.End();
            return;
        end
        imgui.SetWindowFontScale(state.window.scale);

        -- HELP_MENU
        if imgui.BeginMenuBar() then
            for i, data in ipairs(helpTypes) do
                local btnName = string.camelToTitle(data.name);
                imguiPushActiveBtnColor(state.help.activeIndex == i);
                if imgui.Button(btnName) then
                    state.help.activeIndex = i;
                end
                imgui.PopStyleColor();
                imgui.SameLine(0.0, state.window.spaceSettingsBtn);
            end
            imgui.EndMenuBar();
        end
        -- /HELP_MENU

        imgui.BeginGroup();
        imgui.Spacing();
        switch(state.help.activeIndex) : caseof
        {
            [1] = function() renderHelpGeneral() end,
            [2] = function() renderHelpQsAndAs() end
        };
        imgui.EndGroup();
        imgui.Spacing();

        if imgui.Button("Done") then
            imgui.SetVarValue(uiVariables["var_HelpVisible"][1], false);
        end

        imgui.SameLine();
        imgui.Text("OR close window to exit.");

        if state.initializing then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"][1], false);
            imgui.SetVarValue(uiVariables["var_HelpVisible"][1], false);
            imgui.CloseCurrentPopup();
        end

        imgui.End();
    end
}

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is rendering.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    local windowScale           = windowScales[settings.general.windowScaleIndex];
    local scaledFontSize        = windowScale*defaultFontSize;

    local scaledHeightReduction = 0;
    if windowScale == 1.15 then scaledHeightReduction = 34 elseif windowScale == 1.30 then scaledHeightReduction = 54 end;

    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 5.0);
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 5.0);
    imgui.PushStyleVar(ImGuiStyleVar_ChildWindowRounding, 5.0);
    imgui.PushStyleVar(ImGuiStyleVar_Alpha, settings.general.opacity);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, scaledFontSize*5/defaultFontSize, scaledFontSize*5/defaultFontSize);
    imgui.PushStyleColor(ImGuiCol_Border, 0.21, 0.47, 0.59, 0.5);
    imgui.PushStyleColor(ImGuiCol_PlotLines, 0.77, 0.83, 0.80, 0.3);
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, 0.77, 0.83, 0.80, 0.3);
    imgui.PushStyleColor(ImGuiCol_TitleBgActive, 17/255, 17/255, 30/255, 1.0);

    -- MAIN
    imgui.SetNextWindowSize(scaledFontSize*250/defaultFontSize, scaledFontSize*500/defaultFontSize - scaledHeightReduction, ImGuiSetCond_Always);
    if state.initializing and state.firstLoad then
        imgui.SetNextWindowPosCenter(1);
        state.values.centerWindow = true;
    elseif state.initializing then
        imgui.SetNextWindowPos(state.window.posX , state.window.posY);
    end
    if not imgui.Begin(string.format("%s v%s by Lotekkie & Narpt", _addon.name, _addon.version), imgui.GetVarValue(uiVariables['var_WindowVisible'][1]), imgui.bor(ImGuiWindowFlags_MenuBar, ImGuiWindowFlags_NoResize)) then
        imgui.End();
        return
    end

    state.window = -- Calculations based on scaled window sizes
    {
        scale                 = windowScale,
        height                = scaledFontSize * 500.0 / defaultFontSize,
        width                 = scaledFontSize * 250.0 / defaultFontSize,
        padX                  = scaledFontSize * 5.0   / defaultFontSize,
        padY                  = scaledFontSize * 5.0   / defaultFontSize,
        spaceGatherBtn        = scaledFontSize * 6.5   / defaultFontSize * windowScale + (windowScale - 1.0) * 2,
        spaceGatherImg        = scaledFontSize * 6.3   / defaultFontSize * windowScale + (windowScale - 1.0) * 4,
        heightHeaderMain      = scaledFontSize * 15.0  / defaultFontSize,
        heightPlot            = scaledFontSize * 25.0  / defaultFontSize,
        heightYields          = scaledFontSize * 130.0 / defaultFontSize,
        spaceToolTip          = scaledFontSize * 4.0   / defaultFontSize,
        spaceFooterBtn        = scaledFontSize * 4.0   / defaultFontSize * windowScale + (windowScale - 1.0) * 2,
        widthSettings         = scaledFontSize * 500.0 / defaultFontSize,
        heightSettings        = scaledFontSize * 450.0 / defaultFontSize,
        heightSettingsContent = scaledFontSize * 367.0 / defaultFontSize,
        heightSettingsScroll  = scaledFontSize * 343.0 / defaultFontSize,
        spacePriceModeRadio   = scaledFontSize * 26.0  / defaultFontSize * windowScale + (windowScale - 1.0) * 2,
        spacePriceDefaults    = scaledFontSize * 177.0 / defaultFontSize,
        spaceEstimatedValue   = scaledFontSize * 12.0  / defaultFontSize * windowScale + (windowScale - 1.0) * 2,
        widthModalConfirm     = scaledFontSize * 350.0 / defaultFontSize,
        heightModalConfirm    = scaledFontSize * 102.0 / defaultFontSize,
        spaceColorDefaults    = scaledFontSize * 177.0 / defaultFontSize,
        widthWidgetDefault    = scaledFontSize * 275.0 / defaultFontSize,
        spaceSettingsBtn      = scaledFontSize * 6.0   / defaultFontSize * windowScale + (windowScale - 1.0) * 2,
        spaceSettingsDefaults = scaledFontSize * 377.0 / defaultFontSize,
        widthWidgetValue      = scaledFontSize * 191.0 / defaultFontSize,
        offsetPriceColumns1   = scaledFontSize * 140.0 / defaultFontSize,
        offsetPriceColumns2   = scaledFontSize * 270.0 / defaultFontSize,
        heightPriceColumns    = scaledFontSize * 25.0  / defaultFontSize,
        offsetPriceCursorY    = scaledFontSize * 2.0   / defaultFontSize,
        offsetNameCursorY     = scaledFontSize * 5.0   / defaultFontSize,
        sizeGatherTexture     = scaledFontSize * 20.0  / defaultFontSize,
        spaceBtnRecalculate   = scaledFontSize * 152.0 / defaultFontSize,
        spaceReportsDelete    = scaledFontSize * 176.0 / defaultFontSize,
        widthReportScale      = scaledFontSize * 150.0 / defaultFontSize
    }

    imgui.SetWindowFontScale(state.window.scale);


    if getPlayerName() ~= "" and not state.reportsLoaded then
        for _, data in ipairs(gatherTypes) do
            local dirName = string.format("%s\\reports\\%s\\%s", _addon.path, getPlayerName(), data.name);
            if ashita.file.dir_exists(dirName) then
                for f in io.popen(string.format("dir %s /b", dirName)):lines() do
                    reports[data.name][#reports[data.name] + 1] = f;
                end
            else
                ashita.file.create_dir(dirName);
            end
        end
        state.reportsLoaded = true;
    end

    -- MAIN_MENU
    if imgui.BeginMenuBar() then
        local btnAction = function(data)
            updateAllStates(data.name);
            state.values.inactivitySeconds = 0;
            checkTargetAlertReady();
            imgui.SetVarValue(uiVariables['var_ReportSelected'][1], nil);
            state.values.currentReportName = nil;
            state.settings.setColors.gathering = data.name;
            local r, g, b, a = colorToRGBA(-3877684);
            imgui.SetVarValue(uiVariables["var_AllColors"][1], r/255, g/255, b/255, a/255);
            state.settings.setAlerts.gathering = data.name;
            imgui.SetVarValue(uiVariables["var_AllSoundIndex"][1], 0);
        end
        for _, data in ipairs(gatherTypes) do
            if state.values.btnTextureFailure or not settings.general.useImageButtons then
                imguiPushActiveBtnColor(data.name == state.gathering);
                if imgui.SmallButton(string.upperfirst(data.short)) then
                    btnAction(data);
                end
            else
                local texture = textures[data.name];
                imguiPushActiveBtnColor(data.name == state.gathering);
                local textureSize = state.window.sizeGatherTexture;
                if imgui.ImageButton(texture:Get(), textureSize, textureSize) then
                    btnAction(data);
                end
            end
            imgui.PopStyleColor();
            if imgui.IsItemHovered() then
                imgui.SetTooltip(string.upperfirst(data.name));
            end
            imgui.SameLine(0.0, state.window.spaceGatherBtn);
        end
        imgui.EndMenuBar();
    end
    -- /MAIN_MENU

    imguiHalfSep();

    -- MAIN_HEADER
    if imguiShowToolTip(string.format("Progress towards your target value (adjusted within settings)."), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip)
    end
    if imgui.BeginChild("Header", -1, state.window.heightHeaderMain) then
        imgui.SetWindowFontScale(state.window.scale);
        local progress = calcTargetProgress()

        if progress < 1 and progress >= 0.5 then
            imgui.PushStyleColor(ImGuiCol_Text, 1, 1, 0.54, 1); -- warn
        elseif progress < 0.5 then
            imgui.PushStyleColor(ImGuiCol_Text, 1, 0.615, 0.615, 1); -- danger
        else
            imgui.PushStyleColor(ImGuiCol_Text, 0.39, 0.96, 0.13, 1); -- success
        end
        imgui.ProgressBar(progress, -1, state.window.heightHeaderMain, string.format("%s/%s", metrics[state.gathering].estimatedValue, settings.general.targetValue))
        imgui.PopStyleColor();
        imgui.EndChild();
    end
    -- /MAIN_HEADER

    imguiHalfSep(true);

    -- totals metrics
    for total, metric in pairs(table.sortKeysByLength(metrics[state.gathering].totals, true)) do
        if state.gathering == "digging" and metric == "breaks" then
            if imguiShowToolTip("Current Moon percentage.", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            imgui.Text(string.format("%s:", string.upperfirst("Moon")));
            imgui.SameLine();
            local moonPct = tostring(ashita.ffxi.vanatime.get_current_date().moon_percent);
            imgui.TextUnformatted(moonPct.."%");
        else
            if imguiShowToolTip(metricsTotalsToolTips[metric], settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            imgui.Text(string.format("%s:", string.upperfirst(metric)));
            imgui.SameLine();
            imgui.Text(metrics[state.gathering].totals[metric])
        end
        if state.gathering == "clamming" and metric == "yields" then
            imgui.SameLine();
            imgui.Text("~");
            imgui.SameLine();
            if imguiShowToolTip("Total pz value in current bucket (will turn red when within 5 points of limit). ", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            local pzDiff = state.values.clamBucketPzMax - state.values.clamBucketPz;
            if pzDiff <= 5 then
                imgui.PushStyleColor(ImGuiCol_Text, 1, 0.615, 0.615, 1); -- danger
            elseif pzDiff <= state.values.clamBucketPzMax/2 then
                imgui.PushStyleColor(ImGuiCol_Text, 1, 1, 0.54, 1); -- warn
            else
                imgui.PushStyleColor(ImGuiCol_Text, 0.77, 0.83, 0.80, 1); -- plain
            end
            imgui.Text(string.format("Bucket: %spz", state.values.clamBucketPz));
            imgui.PopStyleColor();
        end
    end
    -- totals metrics

    -- gathering tools
    if imguiShowToolTip("Total gathering tools on hand.", settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end
    local gatherData = getGatherTypeData();

    local avail = playerStorage[gatherData.tool] or 0;
    if state.values.zoning then avail = state.values.preZoneCounts[gatherData.tool]; end

    local targetAvail = 12;
    if state.gathering == "clamming" then targetAvail = 1; end

    if avail < targetAvail then
        imgui.PushStyleColor(ImGuiCol_Text, 1, 0.615, 0.615, 1); -- danger
    else
        if state.gathering == "clamming" and state.values.clamBucketBroken then
            imgui.PushStyleColor(ImGuiCol_Text, 1, 1, 0.54, 1); -- warn
        else
            imgui.PushStyleColor(ImGuiCol_Text, 0.77, 0.83, 0.80, 1); -- plain
        end
    end

    local toolName = string.lowerToTitle(gatherData.tool)
    if not table.hasvalue({"fishing", "clamming"}, gatherData.name) then
        toolName = toolName.."s"
    end
    imgui.Text(toolName..":");
    imgui.SameLine();

    local value = avail;
    if state.gathering == "clamming" then
        if not state.values.clamBucketBroken then
            if avail == 1 then value = "Ready"; else value = "None"; end
        else
            value = "Broken";
        end
    end
    imgui.Text(value);
    imgui.PopStyleColor();
    -- /gathering tools

    -- inventory
    if imguiShowToolTip("Total inventory slots available (main inventory only).", settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end
    local availPct = playerStorage['available_pct'];
    if state.values.zoning then availPct = state.values.preZoneCounts['available_pct']; end
    if availPct < 50 and availPct >= 25 then
        imgui.PushStyleColor(ImGuiCol_Text, 1, 1, 0.54, 1); -- warn
    elseif availPct < 25 then
        imgui.PushStyleColor(ImGuiCol_Text, 1, 0.615, 0.615, 1); -- danger
    else
        imgui.PushStyleColor(ImGuiCol_Text, 0.77, 0.83, 0.80, 1); -- plain
    end
    imgui.Text("Inventory:")
    imgui.SameLine();

    local avail = playerStorage['available'] or 0;
    if state.values.zoning then avail = state.values.preZoneCounts['available']; end

    imgui.Text(avail);
    imgui.PopStyleColor();
    -- /inventory

    -- time passed
    if imguiShowToolTip(string.format("Time passed since your first %s attempt or when the timer was manually started.", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end
    imgui.Text("Time Passed:");
    imgui.SameLine();
    local r, g, b, a = 1, 0.615, 0.615, 1 -- danger
    if state.timers[state.gathering] then
        r, g, b, a = 0.77, 0.83, 0.80, 1 -- plain
    end
    imgui.TextColored(r, g, b, a, os.date("!%X", (metrics[state.gathering].secondsPassed)))
    -- /time passed

    imgui.Spacing();

    -- timer
    if imguiShowToolTip(string.format("Start, stop, or clear the %s timer.", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end
    imgui.Text("Timer:")
    imgui.SameLine();
    if imgui.SmallButton(state.values.btnStartTimer) then
        state.timers[state.gathering] = not state.timers[state.gathering];
    end
    if state.timers[state.gathering] then
        state.values.btnStartTimer = "Stop";
    else
        state.values.btnStartTimer = "Start";
    end
    imgui.SameLine();
    if imgui.SmallButton("Clear") then
        state.timers[state.gathering] = false;
        metrics[state.gathering].secondsPassed = 0;
    end
    -- /timer

    imguiHalfSep();
    imgui.AlignFirstTextHeightToWidgets();
    -- value
    imgui.PushStyleColor(ImGuiCol_Text, 0.39, 0.96, 0.13, 1); -- success
    if imguiShowToolTip(string.format("Editable estimated value of all %s yields (yield prices adjusted within settings).", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end

    imgui.Text("Value:")
    if settings.general.showToolTips then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    else
        imgui.SameLine();
    end

    imgui.PushItemWidth(-1);
    imgui.PushAllowKeyboardFocus(false);
    if (imgui.InputInt('', uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1])) then
        metrics[state.gathering].estimatedValue = imgui.GetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1]);
        checkTargetAlertReady();
    end
    imgui.PopStyleColor();
    imgui.PopItemWidth();
    imgui.PopAllowKeyboardFocus();
    -- /value

    imguiHalfSep(true);

    -- plot yields
    imgui.PushItemWidth(-1);
    local plotYields = metrics[state.gathering].points.yields;
    local yieldsLabelMap =
    {
        [1] = string.format("Yields/HR (%.2f)", metrics[state.gathering].points.yields[#metrics[state.gathering].points.yields]),
        [2] = string.format("%.2f/HR", metrics[state.gathering].points.yields[#metrics[state.gathering].points.yields]),
        [3] = ""
    }
    imgui.AlignFirstTextHeightToWidgets();
    local plotYieldsLabel = yieldsLabelMap[state.values.yieldsLabelIndex];
    if imguiShowToolTip(string.format("Plot histogram of %s yields per hour (click the on plot to cycle its label displays).", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end

    local yieldsPerHour = metrics[state.gathering].points.yields[#metrics[state.gathering].points.yields];
    local targetYields = 120;
    if state.gathering == "fishing" then targetYields = 90; end

    if yieldsPerHour < targetYields and yieldsPerHour >= targetYields/2 then
        imgui.PushStyleColor(ImGuiCol_Text, 1, 1, 0.54, 1); -- warn
    elseif yieldsPerHour < targetYields/2 then
        imgui.PushStyleColor(ImGuiCol_Text, 1, 0.615, 0.615, 1); -- danger
    else
        imgui.PushStyleColor(ImGuiCol_Text, 0.39, 0.96, 0.13, 1); -- success
    end

    imgui.PlotHistogram("", plotYields, #plotYields, 0, plotYieldsLabel, FLT_MIN, FLT_MAX, 0.0, state.window.heightPlot);
    imgui.PopStyleColor()
    if imgui.IsItemClicked() then
        state.values.yieldsLabelIndex = cycleIndex(state.values.yieldsLabelIndex, 1, 3);
    end
    if imgui.IsItemClicked(1) then
        state.values.yieldsLabelIndex = cycleIndex(state.values.yieldsLabelIndex, 1, 3, -1);
    end
    if imgui.IsItemHovered() then
        if plotYieldsLabel == "" then
            imgui.SetTooltip(string.format("Yields/HR (%.2f)", yieldsPerHour));
        else
            imgui.SetTooltip("");
        end
    end
    -- /plot yields

    -- plot values
    local plotValues = metrics[state.gathering].points.values;
    local valuesLabelMap =
    {
        [1] = string.format("Value/HR (%.2f)", metrics[state.gathering].points.values[#metrics[state.gathering].points.values]),
        [2] = string.format("%.2f/HR", metrics[state.gathering].points.values[#metrics[state.gathering].points.values]),
        [3] = ""
    }
    local plotValuesLabel = valuesLabelMap[state.values.valuesLabelIndex];
    if imguiShowToolTip("Plot lines of the estimated value per hour (L/R click on the plot to cycle its label displays).", settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end

    local valuesPerHour = metrics[state.gathering].points.values[#metrics[state.gathering].points.values];
    local targetValue = 30000;

    if valuesPerHour < targetValue and valuesPerHour >= targetValue/2 then
        imgui.PushStyleColor(ImGuiCol_Text, 1, 1, 0.54, 1); -- warn
    elseif valuesPerHour < targetValue/2 then
        imgui.PushStyleColor(ImGuiCol_Text, 1, 0.615, 0.615, 1); -- danger
    else
        imgui.PushStyleColor(ImGuiCol_Text, 0.39, 0.96, 0.13, 1); -- success
    end

    imgui.PlotLines("", plotValues, #plotValues, 0, plotValuesLabel, FLT_MIN, FLT_MAX, 0.0, state.window.heightPlot);
    imgui.PopStyleColor()
    if imgui.IsItemClicked() then
        state.values.valuesLabelIndex = cycleIndex(state.values.valuesLabelIndex, 1, 3);
    end
    if imgui.IsItemClicked(1) then
        state.values.valuesLabelIndex = cycleIndex(state.values.valuesLabelIndex, 1, 3, -1);
    end
    if imgui.IsItemHovered() then
        if plotValuesLabel == "" then
            imgui.SetTooltip(string.format("Value/HR (%.2f)", valuesPerHour));
        else
            imgui.SetTooltip("");
        end
    end
    -- /plot values
    imgui.PopItemWidth();
    imguiFullSep();

    -- MAIN_SCROLLING
    imgui.AlignFirstTextHeightToWidgets();
    if imguiShowToolTip(string.format("Scrollable List of current %s yields and their amounts (L/R click on the list to cycle its sorting methods).", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end

    yieldsSortMap =
    {
        [1] = { table.sortKeysByAlphabet(metrics[state.gathering].yields, false), "Alphabetical (DESC)" },
        [2] = { table.sortKeysByAlphabet(metrics[state.gathering].yields, true), "Alphabetical (ASC)" },
        [3] = { table.sortbykey(metrics[state.gathering].yields, false), "Count (DESC)" },
        [4] = { table.sortbykey(metrics[state.gathering].yields, true), "Count (ASC)" },
        [5] = { table.sortKeysByTotalValue(metrics[state.gathering].yields, false), "Value (DESC)" },
        [6] = { table.sortKeysByTotalValue(metrics[state.gathering].yields, true), "Value (ASC)"}
    }

    if imgui.BeginChild("Scrolling", -1, state.window.heightYields, true) then
        imgui.SetWindowFontScale(state.window.scale);
        -- yields
        imgui.PushTextWrapPos(imgui.GetContentRegionAvailWidth());
        for _, item in pairs(yieldsSortMap[state.values.yieldSortIndex][1]) do
            if settings.general.showToolTips then
                imgui.SetCursorPosX(imgui.GetCursorPosX() - 3.0);
                imgui.TextDisabled('(?)');
                if imgui.IsItemHovered() then
                    state.values.yieldListHovered = false;
                    state.values.yieldListBtnsHovered = true;
                    imgui.SetTooltip(string.format("Manually Add(+) or subtract(-) %s", item));
                elseif state.values.yieldListHovered then
                    state.values.yieldListBtnsHovered = false
                end
                imgui.SameLine(0.0, state.window.spaceToolTip - 1.5);
            end
            imgui.BeginGroup();
            imgui.SmallButton("-");
            if imgui.IsItemClicked() then
                adjYield(item, -1);
                adjTotal("yields", -1);
                val = getPrice(item);
                curVal = metrics[state.gathering].estimatedValue;
                metrics[state.gathering].estimatedValue = curVal - val;
                imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1], metrics[state.gathering].estimatedValue);
            end
            imgui.SameLine(0.0, 1.0);
            imgui.SmallButton("+");
            if imgui.IsItemClicked() then
                adjYield(item, 1);
                adjTotal("yields", 1);
                val = getPrice(item);
                curVal = metrics[state.gathering].estimatedValue;
                metrics[state.gathering].estimatedValue = curVal + val;
                imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1], metrics[state.gathering].estimatedValue);
            end
            imgui.EndGroup();
            if imgui.IsItemHovered() then
                state.values.yieldListHovered = false;
                state.values.yieldListBtnsHovered = true;
                imgui.SetTooltip("");
            elseif state.values.yieldListHovered then
                state.values.yieldListBtnsHovered = false
                imgui.SetTooltip(string.format("Sort Type: %s", yieldsSortMap[state.values.yieldSortIndex][2]));
            end
            imgui.SameLine(0.0, state.window.spaceToolTip);
            local r, g, b, a = colorToRGBA(settings.yields[state.gathering][item].color);

            local shortName = settings.yields[state.gathering][item].short;
            local adjItemName = shortName or item;

            imgui.TextColored(r/255, g/255, b/255, a/255, adjItemName..":");

            imgui.SameLine(0.0, state.window.spaceToolTip);
            imgui.Text(metrics[state.gathering].yields[item]);

            if settings.general.showDetailedYields then
                local pricePer = getPrice(item);
                local r, g, b, a = colorToRGBA(settings.general.yieldDetailsColor);
                imgui.TextColored(r/255, g/255, b/255, a/255, string.format("@%dea.=(%s)", getPrice(item), math.floor(getPrice(item) * metrics[state.gathering].yields[item])));
            end
        end
        imgui.PopTextWrapPos();
        imgui.EndChild();
        if imgui.IsItemClicked() then
            state.values.yieldListClicked = true;
            if not state.values.yieldListBtnsHovered then
                state.values.yieldSortIndex = cycleIndex(state.values.yieldSortIndex, 1, 6);
            end
        end
        if imgui.IsItemClicked(1) then
            state.values.yieldListClicked = true;
            if not state.values.yieldListBtnsHovered then
                state.values.yieldSortIndex = cycleIndex(state.values.yieldSortIndex, 1, 6, -1);
            end
        end
        if imgui.IsItemHovered() then
            if table.count(metrics[state.gathering].yields) == 0 then
                imgui.SetTooltip(string.format("Sort Type: %s", yieldsSortMap[state.values.yieldSortIndex][2]));
            else
                if not state.values.yieldListClicked then
                    state.values.yieldListHovered = true;
                end
            end
        else
            state.values.yieldListHovered = false;
        end
        if not imgui.IsMouseDown(1) and not imgui.IsMouseDown(0) then
            state.values.yieldListClicked = false;
        end
        -- /yields
    end
    -- /MAIN_SCROLLING

    imguiFullSep();

    if imgui.Button("Exit") then
        state.actions.modalConfirmAction = function() AshitaCore:GetChatManager():QueueCommand('/addon unload yield', 1); end
        state.values.modalConfirmPrompt = string.format(modalConfirmPromptTemplate, "Exit");
        state.values.modalConfirmHelp = "(All gathering data will be saved.)";
        imgui.OpenPopup("Yield Confirm")
    end

    imgui.SameLine(0.0, state.window.spaceFooterBtn);

    if imgui.Button("Reload") then
        state.actions.modalConfirmAction = function() AshitaCore:GetChatManager():QueueCommand('/addon reload yield', 1); end
        state.values.modalConfirmPrompt = string.format(modalConfirmPromptTemplate, "Reload");
        state.values.modalConfirmHelp = "(All gathering data will be saved.)";
        imgui.OpenPopup("Yield Confirm")
    end

    imgui.SameLine(0.0, state.window.spaceFooterBtn);

    if imgui.Button("Reset") then
        state.actions.modalConfirmAction = function()
            -- Generate report..
            if settings.general.autoGenReports then
                generateGatheringReport(state.gathering);
            end
            -- Reset the metrics..
            metrics[state.gathering] = table.copy(metricsTemplate);
            -- Reset the timers..
            for timerName, running in pairs(state.timers) do
                state.timers[timerName] = false
            end
            -- Reset ui variables..
            imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)][1], metrics[state.gathering].estimatedValue);
            -- Reset the zones..
            settings.zones[state.gathering] = {};
            state.values.lastKnownGathering = nil;
        end
        state.values.modalConfirmPrompt = string.format(modalConfirmPromptTemplate, "Reset");
        state.values.modalConfirmHelp = string.format("(Current %s data will be lost.)", string.upperfirst(state.gathering));
        state.values.modalConfirmDanger = true;
        if state.gathering == "clamming" then
            state.values.clamConfirmedYields = {};
            state.values.clamBucketPz = 0;
        end
        saveSettings();
        imgui.OpenPopup("Yield Confirm")
    end

    imgui.SameLine(0.0, state.window.spaceFooterBtn);

    if imgui.Button("Settings") then
        if imgui.GetVarValue(uiVariables["var_HelpVisible"][1]) then
            imgui.SetVarValue(uiVariables["var_HelpVisible"][1], false);
        end
        imgui.SetVarValue(uiVariables["var_SettingsVisible"][1], true);
        state.values.centerWindow = true;
    end

    imgui.SameLine(0.0, state.window.spaceFooterBtn);

    if imgui.Button("Help") then
        if imgui.GetVarValue(uiVariables["var_SettingsVisible"][1]) then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"][1], false);
        end
        imgui.SetVarValue(uiVariables["var_HelpVisible"][1], true);
        state.values.centerWindow = true;
    end

    -- CONFIRM
    local scaledHeightReduction = 0;
    if windowScale == 1.15 then scaledHeightReduction = 10 elseif windowScale == 1.30 then scaledHeightReduction = 16 end;
    imgui.SetNextWindowSize(state.window.widthModalConfirm, state.window.heightModalConfirm - scaledHeightReduction, ImGuiSetCond_Always)
    if imgui.BeginPopupModal("Yield Confirm", imgui.GetVarValue(uiVariables['var_WindowVisible'][1]), imgui.bor(ImGuiWindowFlags_NoResize)) then
        imgui.SetWindowFontScale(state.window.scale);
        imgui.Text(state.values.modalConfirmPrompt);
        imgui.Spacing();
        if state.values.modalConfirmHelp then
            local r, g, b, a = 0.39, 0.96, 0.13, 1
            if state.values.modalConfirmDanger then
                r, g, b, a =  1, 0.615, 0.615, 1
            end
            imgui.TextColored(r, g, b, a, state.values.modalConfirmHelp);
        end
        imguiFullSep();
        if imgui.Button("Yes") or state.initializing then
            imgui.CloseCurrentPopup();
            state.actions.modalCancelAction = function() end
            state.actions.modalConfirmAction();
        end
        imgui.SameLine(0.0, 10);
        if imgui.Button("No") then
            imgui.CloseCurrentPopup();
            state.actions.modalConfirmAction = function() end
            state.actions.modalCancelAction();
        end
        imgui.SameLine();
        imgui.Text("OR click away to exit.");
        if (not imgui.IsMouseHoveringAnyWindow() and imgui.IsMouseClicked()) then
            SettingsWindow:modalSaveAction();
        end
        if state.initializing then
            imgui.CloseCurrentPopup();
            imgui.SetVarValue(uiVariables["var_SettingsVisible"][1], false);
        end
        imgui.EndPopup();
    else
        state.values.modalConfirmPrompt = ""
        state.values.modalConfirmHelp   = ""
        state.values.modalConfirmDanger = false
    end
    -- /CONFIRM

    state.initializing = false
    -- /MAIN

    state.window.posX, state.window.posY = imgui.GetWindowPos();

    imgui.End();

    -- SETTINGS
    if imgui.GetVarValue(uiVariables["var_SettingsVisible"][1]) then
        state.values.settingsWindowOpen = true;
        SettingsWindow:Draw("Yield Settings")
    elseif state.values.settingsWindowOpen then
        state.values.settingsWindowOpen = false;
        SettingsWindow:modalSaveAction();
    end
    -- /SETTINGS

    -- HELP
    if imgui.GetVarValue(uiVariables["var_HelpVisible"][1]) then
        state.values.helpWindowOpen = true;
        helpWindow:Draw("Yield Help");
    elseif state.values.helpWindowOpen then
        state.values.helpWindowOpen = false;
        state.firstLoad = false;
    end
    -- /HELP
end);

----------------------------------------------------------------------------------------------------
-- func: renderSettingsGeneral
-- desc: Renders the General settings.
----------------------------------------------------------------------------------------------------
function renderSettingsGeneral()
    if imgui.BeginChild("General", -1, state.window.heightSettingsContent, imgui.GetVarValue(uiVariables['var_WindowVisible'][1])) then
        imgui.SetWindowFontScale(state.window.scale);
        imgui.PushItemWidth(state.window.widthWidgetDefault);

        imgui.AlignFirstTextHeightToWidgets();
        imgui.TextColored(1, 1, 0.54, 1, "Window");

        local spaceSettingsDefaults = state.window.spaceSettingsDefaults;
        if settings.general.showToolTips then spaceSettingsDefaults = spaceSettingsDefaults - ( imgui.GetFontSize() * 24 / defaultFontSize ) end
        imgui.SameLine(0.0, spaceSettingsDefaults);
        if imguiShowToolTip("Set all general settings to their defaults.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end

        --imgui.PushStyleColor(ImGuiCol_Button, 0.21, 0.47, 0.59, 1); -- info
        if imgui.Button("Defaults") then
            settings.general = table.copy(defaultSettingsTemplate.general);
            imgui.SetVarValue(uiVariables["var_WindowOpacity"][1], settings.general.opacity);
            imgui.SetVarValue(uiVariables["var_TargetValue"][1], settings.general.targetValue);
            imgui.SetVarValue(uiVariables["var_ShowToolTips"][1], settings.general.showToolTips);
            imgui.SetVarValue(uiVariables["var_WindowScaleIndex"][1], settings.general.windowScaleIndex);
            imgui.SetVarValue(uiVariables["var_ShowDetailedYields"][1], settings.general.showDetailedYields);
            imgui.SetVarValue(uiVariables["var_UseImageButtons"][1], settings.general.useImageButtons);
            imgui.SetVarValue(uiVariables["var_EnableSoundAlerts"][1], true);
            imgui.SetVarValue(uiVariables["var_AutoGenReports"][1], true);
            local r, g, b, a = colorToRGBA(settings.general.yieldDetailsColor);
            imgui.SetVarValue(uiVariables["var_YieldDetailsColor"][1], r/255, g/255, b/255, a/255);
        end
        --imgui.PopStyleColor();

        imguiHalfSep(true);

        -- Opacity
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Current alpha channel value of all Yield windows.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.SliderFloat("Window Opacity", uiVariables['var_WindowOpacity'][1], 0.25, 1.0, "%1.2f")) then
            settings.general.opacity = imgui.GetVarValue(uiVariables['var_WindowOpacity'][1])
        end
        -- /Opacity

        imgui.Spacing();

        -- Scale
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Current size for all Yield windows.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if imgui.Combo("Window Size", uiVariables['var_WindowScaleIndex'][1], "Small\0Medium\0Large\0\0") then
            settings.general.windowScaleIndex = imgui.GetVarValue(uiVariables['var_WindowScaleIndex'][1]);
        end
        -- /Scale

        imguiFullSep();

        imgui.TextColored(1, 1, 0.54, 1, "Gathering")

        imguiFullSep();

        -- Target Value
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Amount you would like to earn this session (affects progress bar).", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.InputInt("Target Value", uiVariables['var_TargetValue'][1])) then
            settings.general.targetValue = imgui.GetVarValue(uiVariables['var_TargetValue'][1]);
        end
        -- /Target Value

        imgui.Spacing();

        -- Target Sound
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Sound that will be played when you reach your target value (will only play if your target is reached through gathering).", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if imgui.Button("Play") then
        end
        if imgui.IsItemClicked() then
            local soundFile = imgui.GetVarValue(uiVariables["var_TargetSoundFile"][1]);
            if soundFile ~= "" then
                ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
            end
        end
        imgui.SameLine();
        local scaledWidths ={ [0] = 232, [1] = 268, [2] = 304 };
        imgui.PushItemWidth(scaledWidths[settings.general.windowScaleIndex]);
        if imgui.Combo("Target Alert", uiVariables["var_TargetSoundIndex"][1], getSoundOptions()) then
            local soundIndex = imgui.GetVarValue(uiVariables["var_TargetSoundIndex"][1]);
            local soundFile = sounds[soundIndex];
            imgui.SetVarValue(uiVariables["var_TargetSoundFile"][1], "");
            imgui.SetVarValue(uiVariables["var_TargetSoundFile"][1], soundFile);
        end
        imgui.PopItemWidth();
        -- /Target Sound

        -- Detailed Yields
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Toggles the display of the math breakdown in the scrollable yields list.", settings.general.showToolTips) then
            imgui.SameLine(0.0 , state.window.spaceToolTip);
        end
        if (imgui.Checkbox("Show Detailed Yields", uiVariables['var_ShowDetailedYields'][1])) then
            settings.general.showDetailedYields = imgui.GetVarValue(uiVariables['var_ShowDetailedYields'][1]);
        end
        -- /Detailed Yields

        imgui.Spacing();

        -- Yield Details Color
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Set the color of the math breakdown in the scrollable yields list.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        local r, g, b, a = colorToRGBA(settings.general.yieldDetailsColor);

        if imgui.ColorEdit4("Yield Details Color", uiVariables["var_YieldDetailsColor"][1]) then
            settings.general.yieldDetailsColor = colorTableToInt(imgui.GetVarValue(uiVariables["var_YieldDetailsColor"][1]));
        end
        -- /Yield Details Color

        imgui.Spacing();

        -- Sound Alerts
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Toggles the set sound alerts for incoming yields.", settings.general.showToolTips) then
            imgui.SameLine(0.0 , state.window.spaceToolTip);
        end
        if (imgui.Checkbox("Enable Sound Alerts", uiVariables['var_EnableSoundAlerts'][1])) then
            settings.general.enableSoundAlerts = imgui.GetVarValue(uiVariables['var_EnableSoundAlerts'][1]);
        end
        -- /Sound Alerts

        -- Reports
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Toggles automatic report generation when zoning or after a data reset (you may still manually generate a report regardless).", settings.general.showToolTips) then
            imgui.SameLine(0.0 , state.window.spaceToolTip);
        end
        if (imgui.Checkbox("Auto Generate Reports", uiVariables['var_AutoGenReports'][1])) then
            settings.general.autoGenReports = imgui.GetVarValue(uiVariables['var_AutoGenReports'][1]);
        end
        -- /Reports

        imguiFullSep();

        imgui.TextColored(1, 1, 0.54, 1, "Misc") -- warn

        imguiFullSep();

        -- Image Buttons
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Toggles the display of images used for all gathering buttons. If off, text will be used instead.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.Checkbox('Use Image Buttons', uiVariables["var_UseImageButtons"][1])) then
            settings.general.useImageButtons = imgui.GetVarValue(uiVariables["var_UseImageButtons"][1]);
        end
        -- /Image Buttons

        -- Tooltips
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Toggles the display of (?)s and their tooltips.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.Checkbox('Show (?) Tooltips', uiVariables['var_ShowToolTips'][1])) then
            settings.general.showToolTips = imgui.GetVarValue(uiVariables['var_ShowToolTips'][1]);
        end
        -- /Tooltips
        imgui.PopItemWidth();

        imgui.EndChild()
    end
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsSetPrices
-- desc: Renders the Set Prices settings.
----------------------------------------------------------------------------------------------------
function renderSettingsSetPrices()
    local gathering = state.settings.setPrices.gathering

    if imgui.BeginChild("Set Prices", -1, state.window.heightSettingsContent, imgui.GetVarValue(uiVariables['var_WindowVisible'][1]), imgui.bor(ImGuiWindowFlags_MenuBar, ImGuiWindowFlags_NoResize)) then
        imgui.SetWindowFontScale(state.window.scale);

        if imgui.BeginMenuBar() then
            local btnAction = function(data)
                state.settings.setPrices.gathering = data.name;
            end
            for _, data in ipairs(gatherTypes) do
                if state.values.btnTextureFailure or not settings.general.useImageButtons then
                    imguiPushActiveBtnColor(data.name == gathering);
                    if imgui.SmallButton(string.upperfirst(data.short)) then
                        btnAction(data);
                    end
                else
                    local texture = textures[data.name];
                    imguiPushActiveBtnColor(data.name == gathering);
                    local textureSize = state.window.sizeGatherTexture;
                    if imgui.ImageButton(texture:Get(), textureSize, textureSize) then
                        btnAction(data);
                    end
                end
                imgui.PopStyleColor();
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(string.upperfirst(data.name));
                end

                imgui.SameLine(0.0, state.window.spaceGatherBtn);
            end

            -- Defaults
            local spacePriceDefaults = state.window.spacePriceDefaults;
            if settings.general.showToolTips then
                spacePriceDefaults = spacePriceDefaults - ( imgui.GetFontSize() * 24 / defaultFontSize );
                if state.window.scale > 1.0 then spacePriceDefaults = spacePriceDefaults + 2 end;
            end
            imgui.SameLine(0.0, spacePriceDefaults);
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip(string.format("Set all %s prices to their default values (0).", string.upperfirst(gathering)), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if imgui.SmallButton("Defaults", uiVariables[string.format("var_%s_priceMode", gathering)][1], 2) then
                for yield, data in pairs(settings.yields[gathering], true) do
                    settings.yields[gathering][yield].singlePrice = 0;
                    settings.yields[gathering][yield].stackPrice = 0;
                    imgui.SetVarValue(uiVariables[string.format("var_%s_%s_prices", gathering, yield)][1], 0, 0);
                end
                imgui.SetVarValue(uiVariables[string.format("var_%s_priceMode", gathering)][1], 0);
            end
            -- Defaults
            imgui.EndMenuBar();
        end

        -- Columns
        imgui.SetCursorPosX(0);
        if imgui.BeginChild("Column Names", imgui.GetWindowWidth(), state.window.heightPriceColumns) then
            imgui.SetWindowFontScale(state.window.scale);
            imgui.Columns(3, "Price Mode Columns", false);
            imgui.SetColumnOffset(1, state.window.offsetPriceColumns1);
            --local col2Offset = state.window.offsetPriceColumns2;
            imgui.SameLine(0.0, 5.0);
            imgui.AlignFirstTextHeightToWidgets();
            local cursorOffsetY = state.window.offsetPriceCursorY;
            imgui.SetCursorPosY(imgui.GetCursorPosY() + cursorOffsetY);
            --imgui.SetCursorPosX(imgui.GetCursorPosX() + 10.0);

            if imguiShowToolTip("Use the set single-item prices for calculations.", settings.general.showToolTips) then
                imgui.SameLine(0.0, 0.0);
            end
            if imgui.RadioButton("Single Prices", uiVariables[string.format("var_%s_priceMode", gathering)][1], 1) then
                settings.priceModes[gathering] = imgui.GetVarValue(uiVariables[string.format("var_%s_priceMode", gathering)][1]);
            end
            imgui.NextColumn();
            imgui.SetCursorPosY(imgui.GetCursorPosY() + cursorOffsetY);
            imgui.SetCursorPosX(imgui.GetCursorPosX() - 5.0);
            imgui.SetColumnOffset(2, state.window.offsetPriceColumns2);
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip("Use the set stack prices for calculations (Yield will do the math for you).", settings.general.showToolTips) then
                imgui.SameLine(0.0, 0.0);
            end
            if imgui.RadioButton("Stack Prices", uiVariables[string.format("var_%s_priceMode", gathering)][1], 0) then
                settings.priceModes[gathering] = imgui.GetVarValue(uiVariables[string.format("var_%s_priceMode", gathering)][1]);
            end
            imgui.NextColumn();
            -- NPC prices
            local spacePriceMode = state.window.spacePriceModeRadio;
            if settings.general.showToolTips then spacePriceMode = 6.0 end
            imgui.SameLine(0.0, spacePriceMode);
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip(string.format("Use NPC base prices (Yield will automatically fetch the NPC single item prices as you gather). This option will override your set prices without modifying them.", string.upperfirst(gathering)), settings.general.showToolTips) then
                imgui.SameLine(0.0, 0.0);
            end
            if imgui.RadioButton("NPC prices", uiVariables[string.format("var_%s_priceMode", gathering)][1], 2) then
                settings.priceModes[gathering] = imgui.GetVarValue(uiVariables[string.format("var_%s_priceMode", gathering)][1]);
            end
            -- /NPC prices

            imgui.EndChild();
        end

        -- /Columns
        imgui.Separator();
        if imgui.BeginChild("Scrolling", -1, -1) then
            imgui.SetWindowFontScale(state.window.scale);
            for i, yield in pairs(table.sortKeysByAlphabet(settings.yields[gathering], true)) do
                local data = settings.yields[gathering][yield];
                 if data.id ~= nil then
                    imgui.AlignFirstTextHeightToWidgets();
                    if imguiShowToolTip(string.format("Set the single-item and or stack prices for %s.", yield), settings.general.showToolTips) then
                        imgui.SameLine(0.0, state.window.spaceToolTip);
                    end
                    imgui.PushItemWidth(state.window.widthWidgetDefault);
                    local adjItemName = data.short or yield;
                     local disabled = settings.priceModes[gathering] == 2;
                     imguiPushDisabled(disabled);
                     local flags = 0;
                     if disabled then flags = ImGuiInputTextFlags_ReadOnly; end
                     if imgui.InputInt2(adjItemName, uiVariables[string.format("var_%s_%s_prices", gathering, yield)][1], imgui.bor(flags)) then
                         local prices = imgui.GetVarValue(uiVariables[string.format("var_%s_%s_prices", gathering, yield)][1]);
                         settings.yields[gathering][yield].singlePrice = prices[1];
                         settings.yields[gathering][yield].stackPrice = prices[2];
                     end
                    imgui.PopItemWidth();
                    imguiPopDisabled(disabled);
                end
            end
            imgui.EndChild()
        end
        imgui.EndChild()
    end
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsSetColors
-- desc: Renders the Set Colors settings.
----------------------------------------------------------------------------------------------------
function renderSettingsSetColors()
    local gathering = state.settings.setColors.gathering;
    if imgui.BeginChild("Set Colors", -1, state.window.heightSettingsContent, imgui.GetVarValue(uiVariables['var_WindowVisible'][1]), imgui.bor(ImGuiWindowFlags_MenuBar, ImGuiWindowFlags_NoResize)) then
        imgui.SetWindowFontScale(state.window.scale);
        if imgui.BeginMenuBar() then
            local btnAction = function(data)
                state.settings.setColors.gathering = data.name;
                local r, g, b, a = colorToRGBA(-3877684);
                imgui.SetVarValue(uiVariables["var_AllColors"][1], r/255, g/255, b/255, a/255);
            end
            for _, data in ipairs(gatherTypes) do
                if state.values.btnTextureFailure or not settings.general.useImageButtons then
                    imguiPushActiveBtnColor(data.name == gathering);
                    if imgui.SmallButton(string.upperfirst(data.short)) then
                        btnAction(data);
                    end
                else
                    local texture = textures[data.name];
                    imguiPushActiveBtnColor(data.name == gathering);
                    local textureSize = state.window.sizeGatherTexture;
                    if imgui.ImageButton(texture:Get(), textureSize, textureSize) then
                        btnAction(data);
                    end
                end
                imgui.PopStyleColor();
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(string.upperfirst(data.name));
                end
                imgui.SameLine(0.0, state.window.spaceGatherBtn);
            end
            -- Defaults
            local spaceColorDefaults = state.window.spaceColorDefaults;
            if settings.general.showToolTips then
                spaceColorDefaults = spaceColorDefaults - ( imgui.GetFontSize() * 24 / defaultFontSize );
                if state.window.scale > 1.0 then spaceColorDefaults = spaceColorDefaults + 2 end;
            end
            imgui.SameLine(0.0, spaceColorDefaults);
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip(string.format("Set all %s yield colors to their defaults.", string.upperfirst(gathering)), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if imgui.SmallButton("Defaults") then
                for yield, data in pairs(settings.yields[gathering]) do
                    settings.yields[gathering][yield].color = -3877684 -- plain
                    local r, g, b, a = colorToRGBA(-3877684);
                    imgui.SetVarValue(uiVariables[string.format("var_%s_%s_color", gathering, yield)][1], r/255, g/255, b/255, a/255);
                    imgui.SetVarValue(uiVariables["var_AllColors"][1], r/255, g/255, b/255, a/255);
                end
            end
            -- /Defaults
            imgui.EndMenuBar();
        end
        -- All
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Set the text color for all yields when they are displayed in the yield list.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        local scaledWidths ={ [0] = 275, [1] = 318, [2] = 364 };
        imgui.PushItemWidth(state.window.widthWidgetDefault);
        if imgui.ColorEdit4("Set All", uiVariables["var_AllColors"][1]) then
            local color = imgui.GetVarValue(uiVariables["var_AllColors"][1]);
            for yield, data in pairs(settings.yields[gathering]) do
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_color", gathering, yield)][1], color[1], color[2], color[3], color[4]);
                settings.yields[gathering][yield].color = colorTableToInt(imgui.GetVarValue(uiVariables[string.format("var_%s_%s_color", gathering, yield)][1]));
            end
        end
        imgui.PopItemWidth();
        -- All
        imgui.Separator();
        for data, yield in pairs(table.sortKeysByAlphabet(settings.yields[gathering], true)) do
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip(string.format("Set the text color for %s when its displayed in the yield list.", yield), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            local r, g, b, a = colorToRGBA(settings.yields[gathering][yield].color);
            imgui.PushStyleColor(ImGuiCol_Text, r/255, g/255, b/255, a/255);
            imgui.PushItemWidth(state.window.widthWidgetDefault);
            local shortName = settings.yields[gathering][yield].short;
            local adjItemName = shortName or yield;
            if (imgui.ColorEdit4(adjItemName, uiVariables[string.format("var_%s_%s_color", gathering, yield)][1])) then
                settings.yields[gathering][yield].color = colorTableToInt(imgui.GetVarValue(uiVariables[string.format("var_%s_%s_color", gathering, yield)][1]));
            end
            imgui.PopStyleColor();
            imgui.PopItemWidth();
        end
        imgui.EndChild()
    end
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsSetAlerts
-- desc: Renders the Set Alerts settings.
----------------------------------------------------------------------------------------------------
function renderSettingsSetAlerts()
    local gathering = state.settings.setAlerts.gathering;
    if imgui.BeginChild("Set Alerts", -1, state.window.heightSettingsContent, imgui.GetVarValue(uiVariables['var_WindowVisible'][1]), imgui.bor(ImGuiWindowFlags_MenuBar, ImGuiWindowFlags_NoResize)) then
        imgui.SetWindowFontScale(state.window.scale);
        if imgui.BeginMenuBar() then
            local btnAction = function(data)
                state.settings.setAlerts.gathering = data.name;
                imgui.SetVarValue(uiVariables["var_AllSoundIndex"][1], 0);
            end
            for _, data in ipairs(gatherTypes) do
            if state.values.btnTextureFailure or not settings.general.useImageButtons then
                imguiPushActiveBtnColor(data.name == gathering);
                if imgui.SmallButton(string.upperfirst(data.short)) then
                    btnAction(data);
                end
            else
                local texture = textures[data.name];
                imguiPushActiveBtnColor(data.name == gathering);
                local textureSize = state.window.sizeGatherTexture;
                if imgui.ImageButton(texture:Get(), textureSize, textureSize) then
                    btnAction(data);
                end
            end
            imgui.PopStyleColor();
            if imgui.IsItemHovered() then
                imgui.SetTooltip(string.upperfirst(data.name));
            end
            imgui.SameLine(0.0, state.window.spaceGatherBtn);
            end
            -- Defaults
            local spaceColorDefaults = state.window.spaceColorDefaults;
            if settings.general.showToolTips then
                spaceColorDefaults = spaceColorDefaults - ( imgui.GetFontSize() * 24 / defaultFontSize );
                if state.window.scale > 1.0 then spaceColorDefaults = spaceColorDefaults + 2 end;
            end
            imgui.SameLine(0.0, spaceColorDefaults);
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip(string.format("Set all %s yield colors to their defaults.", string.upperfirst(gathering)), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if imgui.SmallButton("Defaults") then
                for yield, data in pairs(settings.yields[gathering]) do
                    settings.yields[gathering][yield].soundIndex = 0
                    imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1], "");
                    imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)][1], 0);
                    imgui.SetVarValue(uiVariables["var_AllSoundIndex"][1], 0);
                end
                if gathering == "fishing" then
                    imgui.SetVarValue(uiVariables["var_FishingSkillSoundIndex"][1], 0);
                    imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"][1], "");
                end
                if gathering == "clamming" then
                    imgui.SetVarValue(uiVariables["var_ClamBreakSoundIndex"][1], 0);
                    imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"][1], "");
                end
            end
            -- /Defaults
            imgui.EndMenuBar();
        end
        -- All
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Set a sound alert for all yields.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        local scaledWidths ={ [0] = 273, [1] = 318, [2] = 364 };
        imgui.PushItemWidth(scaledWidths[settings.general.windowScaleIndex]);
        if imgui.Combo("Set All", uiVariables["var_AllSoundIndex"][1], getSoundOptions()) then
            local soundIndex = imgui.GetVarValue(uiVariables["var_AllSoundIndex"][1]);
            local soundFile = sounds[soundIndex];
            for yield, data in pairs(settings.yields[gathering]) do
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)][1], soundIndex);
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1], "");
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1], soundFile);
            end
            if gathering == "fishing" then
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundIndex"][1], soundIndex);
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"][1], "");
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"][1], soundFile);
            end
            if gathering == "clamming" then
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundIndex"][1], soundIndex);
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"][1], "");
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"][1], soundFile);
            end
        end
        imgui.PopItemWidth();
        -- All

        imgui.Separator();

        --  Fishing Skillup
        if gathering == "fishing" then
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip("Set a sound alert for when you receive a fishing skill-up.", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if imgui.Button("Play") then end
            if imgui.IsItemClicked() then
                local soundFile = imgui.GetVarValue(uiVariables["var_FishingSkillSoundFile"][1]);
                if soundFile ~= "" then
                    ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
                end
            end
            imgui.SameLine();
            imgui.PushItemWidth(state.window.widthWidgetDefault - 45);
            if imgui.Combo("Skill-Up", uiVariables["var_FishingSkillSoundIndex"][1], getSoundOptions()) then
                local soundIndex = imgui.GetVarValue(uiVariables["var_FishingSkillSoundIndex"][1]);
                local soundFile = sounds[soundIndex];
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"][1], "");
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"][1], soundFile);
            end
            imgui.PopItemWidth();
            imgui.Separator();
        end
        -- /Fishing Skillup

        -- Clamming break
        if gathering == "clamming" then
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip("Set a sound alert for when your clamming bucket breaks.", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if imgui.Button("Play") then end
            if imgui.IsItemClicked() then
                local soundFile = imgui.GetVarValue(uiVariables["var_ClamBreakSoundFile"][1]);
                if soundFile ~= "" then
                    ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
                end
            end
            imgui.SameLine();
            imgui.PushItemWidth(state.window.widthWidgetDefault - 45);
            if imgui.Combo("Bucket Break", uiVariables["var_ClamBreakSoundIndex"][1], getSoundOptions()) then
                local soundIndex = imgui.GetVarValue(uiVariables["var_ClamBreakSoundIndex"][1]);
                local soundFile = sounds[soundIndex];
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"][1], "");
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"][1], soundFile);
            end
            imgui.PopItemWidth();
            imgui.Separator();
        end
        -- /Clamming break

        for data, yield in pairs(table.sortKeysByAlphabet(settings.yields[gathering], true)) do
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip(string.format("Set a sound alert for %s when it enters the yields list.", yield), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            local shortName = settings.yields[gathering][yield].short;
            local adjItemName = shortName or yield;
            if imgui.Button("Play") then end
            if imgui.IsItemClicked() then
                local soundFile = imgui.GetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1]);
                if soundFile ~= "" then
                    ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
                end
            end
            imgui.SameLine();
            imgui.PushItemWidth(state.window.widthWidgetDefault - 45);
            if imgui.Combo(adjItemName, uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)][1], getSoundOptions()) then
                local soundIndex = imgui.GetVarValue(uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)][1]);
                local soundFile = sounds[soundIndex];
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1], "");
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)][1], soundFile);
            end
            imgui.PopItemWidth();
        end
        imgui.EndChild();
    end
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsReports
-- desc: Renders the Reports section in settings.
----------------------------------------------------------------------------------------------------
function renderSettingsReports()
    local gathering = state.settings.reports.gathering;
    local sortedReports = table.sortReportsByDate(reports[gathering], true);
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, 5, 5);
    if imgui.BeginChild("Reports", -1, state.window.heightSettingsContent, imgui.GetVarValue(uiVariables['var_WindowVisible'][1]), imgui.bor(ImGuiWindowFlags_MenuBar, ImGuiWindowFlags_NoResize)) then
        imgui.SetWindowFontScale(state.window.scale);
        if imgui.BeginMenuBar() then
            local btnAction = function(data)
                state.settings.reports.gathering = data.name;
                imgui.SetVarValue(uiVariables['var_ReportSelected'][1], nil);
                state.values.currentReportName = nil;
            end
            for _, data in ipairs(gatherTypes) do
            if state.values.btnTextureFailure or not settings.general.useImageButtons then
                imguiPushActiveBtnColor(data.name == gathering);
                if imgui.SmallButton(string.upperfirst(data.short)) then
                    btnAction(data);
                end
            else
                local texture = textures[data.name];
                imguiPushActiveBtnColor(data.name == gathering);
                local textureSize = state.window.sizeGatherTexture;
                if imgui.ImageButton(texture:Get(), textureSize, textureSize) then
                    btnAction(data);
                end
            end
            imgui.PopStyleColor();
            if imgui.IsItemHovered() then
                imgui.SetTooltip(string.upperfirst(data.name));
            end
            imgui.SameLine(0.0, state.window.spaceGatherBtn);
            end
            -- Generate
            local spaceColorDefaults = state.window.spaceColorDefaults;
            if settings.general.showToolTips then
                spaceColorDefaults = spaceColorDefaults - ( imgui.GetFontSize() * 24 / defaultFontSize );
                if state.window.scale > 1.0 then spaceColorDefaults = spaceColorDefaults + 2 end;
            end
            imgui.SameLine(0.0, spaceColorDefaults);
            imgui.AlignFirstTextHeightToWidgets();
            if imguiShowToolTip(string.format("Manually generate a %s report using its current yield data.", string.upperfirst(gathering)), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            local disabled = imguiPushDisabled(state.values.genReportDisabled);
            if imgui.SmallButton("Generate") then
                if not disabled then
                    state.values.currentReportName = nil
                    if generateGatheringReport(gathering) then
                        state.values.genReportDisabled = true;
                        ashita.timer.once(2, function()
                            state.values.genReportDisabled = false;
                        end);
                    end
                end
            end
            imguiPopDisabled(disabled);
            -- /Generate
            imgui.EndMenuBar();
        end
        imgui.SetCursorPosX(0);
        imgui.PushStyleColor(ImGuiCol_Border, 0, 0, 0, 0);
        if imgui.BeginChild("Report List", imgui.GetWindowWidth(), state.window.heightYields-25, true) then
            imgui.SetWindowFontScale(state.window.scale);
            imgui.PushTextWrapPos(imgui.GetContentRegionAvailWidth());

            if table.count(reports[gathering]) > 0 then
                for _, file in ipairs(sortedReports, true) do
                    local name = file
                    if _ == 1 and #reports[gathering] > 1 then
                        imgui.PushStyleColor(ImGuiCol_Text, 1, 1, 0.54, 1); -- warn
                        name = file.." --latest"
                    else
                        imgui.PushStyleColor(ImGuiCol_Text, 0.77, 0.83, 0.80, 1); -- plain
                    end
                    if imgui.Selectable(name, imgui.GetVarValue(uiVariables["var_ReportSelected"][1]) == _, ImGuiSelectableFlags_AllowDoubleClick) then
                        imgui.SetVarValue(uiVariables['var_ReportSelected'][1], _);
                        state.values.readReportDisabled = false;
                        if (imgui.IsMouseDoubleClicked(0)) then
                            state.values.currentReportName = sortedReports[imgui.GetVarValue(uiVariables["var_ReportSelected"][1])];
                        end
                    end
                    imgui.PopStyleColor();
                end
            else
                if getPlayerName() ~= "" then
                    imgui.Text("No reports..")
                else
                    imgui.TextColored(1, 0.615, 0.615, 1, string.format("Unable to manage reports with no character loaded."));
                end
            end
            imgui.EndChild()
        end
        imgui.PopStyleColor();

        imgui.Separator();
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Read the selected report within the view window below (or double-click on the file name to perform this action).", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        local disabled = imguiPushDisabled(imgui.GetVarValue(uiVariables["var_ReportSelected"][1]) == 0);
        if imgui.Button("Read") then -- here
            local selectedIndex = imgui.GetVarValue(uiVariables["var_ReportSelected"][1]);
            local fname = sortedReports[selectedIndex];
            if state.values.currentReportName ~= fname then
                state.values.currentReportName = fname;
            end
        end
        imguiPopDisabled(disabled);
        imgui.SameLine(0.0, state.window.spaceSettingsBtn * 2);
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Clear the selection window above and the report view window below.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        disabled = imguiPushDisabled(imgui.GetVarValue(uiVariables["var_ReportSelected"][1]) == 0);
        if imgui.Button("Clear") then
            state.values.currentReportName = nil;
            imgui.SetVarValue(uiVariables["var_ReportSelected"][1], nil);
        end
        imguiPopDisabled(disabled);

        imgui.SameLine(0.0, state.window.spaceSettingsBtn * 2);
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Adjust the font scale of the report.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        imgui.PushItemWidth(state.window.widthReportScale);
        imgui.SliderFloat("", uiVariables['var_ReportFontScale'][1], 1.0, 1.5, "%.2f")
        imgui.PopItemWidth();
        imgui.SameLine();

        local spaceReportsDeleteMap = {[0] = state.window.spaceReportsDelete, [1] = state.window.spaceReportsDelete - 5, [2] = state.window.spaceReportsDelete - 8};
        local spaceReportsDelete = spaceReportsDeleteMap[settings.general.windowScaleIndex]
        if settings.general.showToolTips then
            spaceReportsDelete = spaceReportsDelete - ( (imgui.GetFontSize() * 24) * 4 / defaultFontSize );
            if state.window.scale > 1.0 then spaceReportsDelete = spaceReportsDelete + 2 end;
        end

        imgui.SameLine(0.0, spaceReportsDelete);

        local disabled = imguiPushDisabled(imgui.GetVarValue(uiVariables["var_ReportSelected"][1]) == 0);
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Delete the selected report entry.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end

        if imgui.Button("Delete") then
            if not disabled and getPlayerName() ~= "" then
                local selectedIndex = imgui.GetVarValue(uiVariables["var_ReportSelected"][1]);
                local fname = sortedReports[selectedIndex];
                if fname ~= nil then
                    local fpath = string.format('%s/%s/%s/%s/%s', _addon.path, 'reports', getPlayerName(), gathering, fname);
                    os.remove(fpath);
                    for _, fileName in ipairs(reports[gathering]) do
                        if fileName == fname then
                            table.remove(reports[gathering], _)
                        end
                    end
                    state.values.currentReportName = nil;
                    imgui.SetVarValue(uiVariables["var_ReportSelected"][1], #sortedReports-1);
                end
            end
        end

        imguiPopDisabled(disabled);

        imgui.Separator();

        imgui.SetCursorPosX(0);
        imgui.PushStyleColor(ImGuiCol_Border, 0, 0, 0, 0);
        if imgui.BeginChild("Read Report", imgui.GetWindowWidth(), -1, true) then
            imgui.SetWindowFontScale(imgui.GetVarValue(uiVariables['var_ReportFontScale'][1]));
            imgui.PushTextWrapPos(imgui.GetContentRegionAvailWidth());
            local fname = state.values.currentReportName;
            if fname ~= nil then
                if getPlayerName() ~= "" then
                    local fpath = string.format('%s/%s/%s/%s/%s', _addon.path, 'reports', getPlayerName(), gathering, fname);
                    local lines = linesFrom(fpath);
                    if table.count(lines) > 0 then
                        for _, line in pairs(lines) do
                            imgui.TextUnformatted(line);
                        end
                    else
                        imgui.TextColored(1, 0.615, 0.615, 1, string.format("File (%s) is unable to be read. Either this file has been moved, deleted, or you have changed characters. Reload yield to update this list.", state.values.currentReportName))
                    end
                else
                    imgui.TextColored(1, 0.615, 0.615, 1, string.format("Unable to manage reports with no character loaded."));
                end
            elseif getPlayerName() == "" then
                imgui.TextColored(1, 0.615, 0.615, 1, string.format("Unable to manage reports with no character loaded."));
            end
            imgui.EndChild()
        end
        imgui.PopStyleColor();
        imgui.EndChild();
    end
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsFeedback
-- desc: Renders the Reports section in settings.
----------------------------------------------------------------------------------------------------
function renderSettingsFeedback()
    if imgui.BeginChild("Set Alerts", -1, state.window.heightSettingsContent, true) then
        imgui.SetWindowFontScale(state.window.scale);
        local hasTitle = imgui.GetVarValue(uiVariables["var_IssueTitle"][1]):len() > 0;
        local hasBody = imgui.GetVarValue(uiVariables["var_IssueBody"][1]):len() > 0;
        local msg = "I hope you are enjoying Yield!"
        local widget = imgui.Text
        local r, g, b, a = 0.77, 0.83, 0.80, 1 -- plain
        if not hasTitle and state.values.feedbackMissing then
            msg = "Please enter a title.   "
            widget = imgui.BulletText;
            r, g, b, a = 1, 0.615, 0.615, 1 -- danger
        elseif not hasBody and state.values.feedbackMissing then
            msg = "Please enter some feedback.   "
            widget = imgui.BulletText;
            r, g, b, a = 1, 0.615, 0.615, 1 -- danger
        end
        local fontWidth = (msg:len()*imgui.GetFontSize()/2) / 1.75
        imgui.SetCursorPosX(imgui.GetContentRegionAvailWidth()/2 - fontWidth);
        imgui.PushStyleColor(ImGuiCol_Text, r, g, b, a);
        widget(msg);
        imgui.PopStyleColor();
        imguiFullSep();
        imgui.PushTextWrapPos(imgui.GetContentRegionAvailWidth());
        imgui.SetCursorPosX(imgui.GetContentRegionAvailWidth()/16);
        imgui.Text("If you have discovered a problem or want to provide some feedback you can do so here anonymously!")
        local widgetWidth = state.window.widthWidgetDefault+75
        local centerWidget = imgui.GetWindowContentRegionWidth()/2 - widgetWidth/2
        if settings.general.showToolTips then centerWidget = centerWidget - ( imgui.GetFontSize() * 24 / defaultFontSize ); end
        imgui.SetCursorPosY(imgui.GetWindowHeight() / 5);
        imgui.SetCursorPosX(centerWidget);
        imgui.AlignFirstTextHeightToWidgets();
        imgui.PushItemWidth(widgetWidth);
        if imguiShowToolTip("Enter a title for your feedback/issue submission.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        imgui.InputText('Title', uiVariables['var_IssueTitle'][1], 128, imgui.bor(ImGuiInputTextFlags_EnterReturnsTrue));
        imgui.Spacing();
        imgui.SetCursorPosX(centerWidget);
        imgui.AlignFirstTextHeightToWidgets();
        if imguiShowToolTip("Enter your feedback/issue.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        imgui.InputTextMultiline('Body', uiVariables['var_IssueBody'][1], 16384, state.window.widthWidgetDefault+75, imgui.GetTextLineHeight() * 16, imgui.bor(ImGuiInputTextFlags_AllowTabInput, ImGuiInputTextFlags_EnterReturnsTrue));
        imgui.PopItemWidth();
        imgui.Spacing();
        local widgetPos = state.window.widthWidgetDefault+75
        local centerWidget = imgui.GetWindowContentRegionWidth()/2 - widgetPos/2
        imgui.SetCursorPosX(centerWidget);
        if not state.values.feedbackSubmitted then
            if imgui.Button("Submit") then
                if not hasBody or not hasTitle then
                    state.values.feedbackMissing = true;
                else
                   state.values.feedbackSubmitted = true;
                   state.values.feedbackMissing = false;
                   local title = imgui.GetVarValue(uiVariables["var_IssueTitle"][1]);
                   local body = imgui.GetVarValue(uiVariables["var_IssueBody"][1]);
                   sendIssue(title, body);
                   imgui.SetVarValue(uiVariables["var_IssueTitle"][1], "");
                   imgui.SetVarValue(uiVariables["var_IssueBody"][1], "")
                end
            end
        end
        if state.values.feedbackSubmitted then
            imgui.SetCursorPosX(centerWidget);
            imgui.PushStyleColor(ImGuiCol_Text, 0.39, 0.96, 0.13, 1); -- success
            imgui.Text("Thank you for your feedback!");
            imgui.PopStyleColor();
            imgui.SameLine();
            imgui.PushStyleColor(ImGuiCol_Text, 1, 0.615, 0.615, 1); -- danger
            imgui.Text("<3");
            imgui.PopStyleColor();
        end
        imgui.PushTextWrapPos(imgui.GetWindowContentRegionWidth());
        imgui.SetCursorPosY(imgui.GetWindowHeight()-imgui.GetTextLineHeight()*2);
        if imguiShowToolTip("All submissions are anonymous and will go to LoTekkie's github issue tracker for Ashita-Yield.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        imgui.Text("* To: https://github.com/LoTekkie/Ashita-Yield/issues.");
        imgui.PopTextWrapPos();
        imgui.EndChild();
    end
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsAbout
-- desc: Renders the About section in settings.
---------------------------------------------------------------------------------------------------
function renderSettingsAbout()
    if imgui.BeginChild("About", -1, state.window.heightSettingsContent, true) then
        imgui.SetWindowFontScale(state.window.scale);
        imgui.Spacing();
        imgui.PushTextWrapPos(imgui.GetContentRegionAvailWidth());
        imgui.TextColored(1, 1, 0.54, 1, "Name:"); imgui.Text(string.format("%s by Lotekkie & Narpt", _addon.name));
        imgui.Spacing();
        imgui.TextColored(1, 1, 0.54, 1, "Description:"); imgui.Text(_addon.description); imgui.Text("https://github.com/LoTekkie/Ashita-Yield");
        imgui.Spacing();
        imgui.TextColored(1, 1, 0.54, 1, "Author:"); imgui.Text(_addon.author);
        imgui.Spacing();
        imgui.TextColored(1, 1, 0.54, 1, "Version:"); imgui.Text(_addon.version);
        imgui.Spacing();
        imgui.TextColored(1, 1, 0.54, 1, "Support/Donate:"); imgui.Text("https://Paypal.me/Sjshovan\nOR\nFor Gil donations: I play on Wings private server! (https://www.wingsxi.com/wings/) My in-game name is LoTekkie.");
        imgui.Spacing();
        imgui.PushStyleColor(ImGuiCol_Button, 0.21, 0.47, 0.59, 1); -- info
        if imgui.Button("Go to Paypal") then
            ashita.misc.open_url("https://Paypal.me/Sjshovan");
        end
        imgui.PopStyleColor();
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Special Thanks:");
        imguiFullSep();
        imgui.Text("To Narpt (https://www.twitch.tv/narpt): For his awesome streams, invaluable feedback/ideas/testing, and the inspiration to make this!");
        imgui.Spacing();
        imgui.Text("To Hughesyourdaddy (https://www.omega-ffxi.com): For granting me the freedom to create this within the FFXI Omega private server.");
        imgui.Spacing();
        imgui.Text("To the Ashita team (https://www.ashitaxi.com/): For making this possible.");
        imgui.Spacing();
        imgui.Text("To Ashita Discord members (https://discord.gg/3FbepVGh): For their feedback and knowledge.");
        imgui.Spacing();
        imgui.Text("To everyone who reported bugs and submitted feedback, thanks for helping make Yield great!");
        imgui.EndChild();
    end
end

----------------------------------------------------------------------------------------------------
-- func: renderHelpGeneral
-- desc: Renders the general help section with the help window.
---------------------------------------------------------------------------------------------------
function renderHelpGeneral()
    if imgui.BeginChild("HelpGeneral", -1, state.window.heightSettingsContent, true) then
        imgui.SetWindowFontScale(state.window.scale);
        imgui.Spacing();
        imgui.PushTextWrapPos(imgui.GetContentRegionAvailWidth());
        if state.firstLoad then
            imgui.TextColored(1, 1, 0.54, 1, "Welcome to Yield!"); imgui.Separator();
            imgui.Text("Before you begin, please take a moment to read through the following general information and common questions to familiarize yourself.");
            imgui.Text("If you would like to read this later you can open this window anytime by click the 'Help' button located at the bottom of the app.");
            imguiHalfSep(true);
        end
        imgui.TextColored(1, 1, 0.54, 1, "Navigating Yield"); imgui.Separator();
        imgui.Text("Your main tool for navigating Yield is the mouse. You will find that if you take your time and hover over the (?) tooltips as well as other items within the interface that Yield will give you an explanation of each item, don't be afraid to take the time to explore!");
        imgui.Text("The real power of Yield comes from within its Settings window. There are a variety of features and customization options there to accommodate almost every gatherer's need.");
        imguiHalfSep(true);
        imgui.TextColored(1, 1, 0.54, 1, "Gathering"); imgui.Separator();
        imgui.Text("Yield supports every gathering type in the game and switching between them here is a breeze, simply click on the icons at the top of the Main window. If you hover your mouse over them, Yield will tell you which gathering type you are switching to. If you start gathering and forget to switch, don't worry, Yield will automatically switch to the correct type and begin working to keep track of your stats!");
        imgui.Spacing();
        imgui.Text("Don't forget to set those prices! Before heading out to begin gathering, it is recommended that you set your prices for yields within the Settings/Set Prices window. If you forget for some reason, that's ok, you can always update the prices later and recalculate your Estimated Value from within the same window.");
        imgui.Spacing();
        imgui.Text("Yield is intelligent and will begin tracking and recording for you without the need for you to do anything first. After you load Yield, simply start gathering and watch the magic happen!");
        imguiHalfSep(true);
        imgui.TextColored(1, 1, 0.54, 1, "Settings"); imgui.Separator();
        imgui.Text("Yield automatically saves all the changes you make in your Settings window each time the Settings window is closed. You do not need to worry about reloading and losing your Prices/Colors/Alerts or any of your current metrics. When you exit the game and come back, everything will be right where you left it.");
        imguiHalfSep(true);
        imgui.TextColored(1, 1, 0.54, 1, "Alerts"); imgui.Separator();
        imgui.Text("Yield ships with a variety of sounds, used for alerts, out of the box. If you find yourself wanting to add custom sounds, it couldn't be easier. All sounds used for Yield alerts can be found within the /sounds folder. To add a new sound, ensure the sound file is in .wav format (e.g. my_new_sound.wav), and drop it into /sounds. After that, reload Yield and your new sound should be available in all sound selection drop-downs.")
        imguiHalfSep(true);
        imgui.TextColored(1, 1, 0.54, 1, "Reports"); imgui.Separator();
        imgui.Text("Yield allows you to generate detailed reports using the metrics it has tracked while you gathered. You do not need to use Yield to manage these files but these reports can be read and deleted from within the Settings/Reports window. These files are stored locally with the /reports folder of the Yield addon. It is safe to remove these files even while Yield is loaded. Yield will inform you that the files no longer exist if you attempt to read them.");
        imgui.Text("Generation of reports can occur both manually and automatically. If you enable automatic generation of reports Yield will generate a report both when you zone and when you reset the data for a particular gathering type.");
        imgui.Text("While automatic report generation can happen when you zone, it won't always happen when you zone. Yield will attempt to determine when it should generate on zone change based on your activity.");
        imguiHalfSep(true);
        imgui.TextColored(1, 1, 0.54, 1, "Tips/Tricks"); imgui.Separator();
        imgui.Text("1. Double-click on the title bar of any window to minimize it.");
        imgui.Text("2. left-click or right-click on your plots within the Main window to cycle the display of their labels.");
        imgui.Text("3. left-click or right-click on the yields list within the Main window to cycle the sorting methods of the list.");
        imgui.Text("4. If you forget to shut off your timer when you walk away from Yield, it will automatically shut them off for you after approx. 5 minutes.");
        imgui.Text("5. You can Double-click on a file name in Reports to view its contents rather than using the Read button.");
        imgui.Text("6. You can left-click drag on the R: G: B: A: color boxes with your mouse to change their values quickly. You can also left-click on the main color box to change color input methods.");
        imgui.Text("7. You can view the moon percentage by switching to the digging gathering type.");
        imguiHalfSep(true);
        imgui.TextColored(1, 1, 0.54, 1, "Bugs/Errors"); imgui.Separator();
        imgui.Text("Unfortunately, nothing is perfect, not even Yield. You may come across a problem while using Yield to help you become the ultimate gatherer. I understand the frustration of these occurrences and that is why I added an easy in-app way to report these problems directly to me so I can quickly get the issues resolved.");
        imgui.Text("To report an issue directly to me, simply head on over to Settings/Feedback. Enter a title, an explanation, and hit submit.");
        imgui.Text("By taking a mere moment to send a report, you are effectively taking part in the active development of Yield and helping it become even better. This time you take to do so is greatly appreciated!");
        imguiHalfSep(true);
        imgui.TextColored(1, 1, 0.54, 1, "Text Commands"); imgui.Separator();
        imgui.Text("Yield has a few text commands to quickly load/reload/unload. To see a full list of the available commands type: '/yield help' in your chat while Yield is loaded.");
        imgui.Spacing();
        imgui.EndChild();
    end
end

----------------------------------------------------------------------------------------------------
-- func: renderHelpQsAndAs
-- desc: Renders the Q's and A's section with the help window.
---------------------------------------------------------------------------------------------------
function renderHelpQsAndAs()
    if imgui.BeginChild("HelpQnA", -1, state.window.heightSettingsContent, true) then
        imgui.SetWindowFontScale(state.window.scale);
        imgui.Spacing();
        imgui.PushTextWrapPos(imgui.GetContentRegionAvailWidth());
        imgui.Separator();
        imgui.TextColored(1, 1, 0.54, 1, "Q: Is this addon available for Windower?"); imgui.Separator();
        imgui.Text("A: Unfortunately, No. Windower does not currently offer the technology used to create this addon. If they ever do, I will absolutely port it over. ")
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Q: Why isn't feature X/Y/Z implemented?"); imgui.Separator();
        imgui.Text("A: I'm positive many of you out there have some amazing ideas on how to make Yield better. I'd love to hear them! You can contact me through Feedback in Settings, by email (sjshovan@gmail.com), or on discord (LoTekkie #6070).")
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Q: How can I donate/support?"); imgui.Separator();
        imgui.Text("A: Head on over to the About section in Settings. There you can see some ways that I am able to receive your support. Thank you!");
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Q: I have upgraded from a previous version now everything went bonkers! What do I do?"); imgui.Separator();
        imgui.Text("A: If you reach a scenario where Yield wont display correctly or is acting strange, first try reloading the addon. If you are still experiencing issues try the following steps:")
        imgui.Text("1. Exit out of Final Fantasy 11.");
        imgui.Text("2. Navigate to the Yield addon and delete your settings/ folder.");
        imgui.Text("3. Start Final Fantasy 11 and load Yield.")
        imgui.Text("If you are still experiencing issues, reach out to me and I will attempt to solve them.");
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Q: I cannot find the Yield window! What do I do?"); imgui.Separator();
        imgui.Text("A: Type /yield find or /yld f in your chat bar. This will force the Yield window to return to the top left of your screen.");
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Q: Which server do you play on?"); imgui.Separator();
        imgui.Text("A: I am currently playing on Wings private server (https://www.wingsxi.com/). My in-game name is LoTekkie. Hope to see you around!");
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Q: Have you created any other FFXI addons?"); imgui.Separator();
        imgui.Text("A: Yes, I have also authored Mount Muzzle(Windower+Ashita) and Battle Stations(Windower). You can obtain these through their respective launchers.");
        imguiFullSep();
        imgui.TextColored(1, 1, 0.54, 1, "Q: I have a question that I don't see here. How do I contact you?"); imgui.Separator();
        imgui.Text("A: You can contact me through Feedback in Settings, by email (sjshovan@gmail.com), or on discord (LoTekkie #6070).");
        imgui.Spacing();
        imgui.EndChild();
    end
end