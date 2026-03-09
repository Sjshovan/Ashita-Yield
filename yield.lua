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

addon.name = 'yield';
addon.desc = 'Track and edit a variety of metrics related to gathering within a simple GUI.';
addon.author = 'Sjshovan (LoTekkie) Sjshovan@Gmail.com';
addon.version = '2.0';

_addon = {}; -- For compatibility
_addon.name = 'Yield';
_addon.description = addon.desc;
_addon.author = addon.author;
_addon.version = addon.version;
_addon.commands = {'/yield', '/yld'};
_addon.path = addon.path;

require('common');
local imgui = require('imgui');
local ffi = require('ffi');
local d3d8 = require('d3d8');
local d3d8dev = d3d8.get_device();
local unpack_ret = table.unpack or unpack;

-- Tooltip queue: attach helper text to the next interactive control hover.
local queuedHoverTooltip = nil;
_G.__yield_queue_hover_tooltip = function(text, enabled)
    if not enabled then
        queuedHoverTooltip = nil;
        return false;
    end
    local tip = tostring(text or "");
    if tip == "" then
        queuedHoverTooltip = nil;
    else
        queuedHoverTooltip = tip;
    end
    -- Keep existing call-sites from drawing inline "(?)" placeholders.
    return false;
end

local function applyQueuedHoverTooltip()
    if queuedHoverTooltip ~= nil and queuedHoverTooltip ~= "" then
        if imgui.IsItemHovered() then
            imgui.SetTooltip(queuedHoverTooltip);
        end
        queuedHoverTooltip = nil;
    end
end

local function wrapImguiTooltipAware(fnName)
    _G.__yield_imgui_orig = _G.__yield_imgui_orig or {};
    if type(_G.__yield_imgui_orig[fnName]) ~= 'function' then
        _G.__yield_imgui_orig[fnName] = imgui[fnName];
    end
    local orig = _G.__yield_imgui_orig[fnName];
    if type(orig) ~= 'function' then
        return;
    end
    imgui[fnName] = function(...)
        local ret = { orig(...) };
        applyQueuedHoverTooltip();
        return unpack_ret(ret);
    end
end

do
    local tooltipAwareFns = {
        'Button', 'SmallButton', 'ImageButton', 'Checkbox', 'Combo',
        'SliderFloat', 'SliderInt', 'InputInt', 'InputInt2', 'InputFloat',
        'InputText', 'InputTextMultiline', 'ColorEdit4', 'RadioButton', 'Selectable'
    };
    for _, fnName in ipairs(tooltipAwareFns) do
        wrapImguiTooltipAware(fnName);
    end
end

-- Create ImGui enum compatibility for v4
if not ImGuiStyleVar then
    ImGuiStyleVar = {
        Alpha = 0,
        WindowPadding = 1,
        WindowRounding = 2,
        WindowBorderSize = 3,
        WindowMinSize = 4,
        WindowTitleAlign = 5,
        ChildRounding = 6,
        ChildBorderSize = 7,
        PopupRounding = 8,
        PopupBorderSize = 9,
        FramePadding = 10,
        FrameRounding = 11,
        FrameBorderSize = 12,
        ItemSpacing = 13,
        ItemInnerSpacing = 14,
        IndentSpacing = 15,
        ScrollbarSize = 16,
        ScrollbarRounding = 17,
        GrabMinSize = 18,
        GrabRounding = 19,
        TabRounding = 20,
        ButtonTextAlign = 21,
        SelectableTextAlign = 22,
    }
end

if not ImGuiCol then
    ImGuiCol = {
        Text = 0,
        TextDisabled = 1,
        WindowBg = 2,
        ChildBg = 3,
        PopupBg = 4,
        Border = 5,
        BorderShadow = 6,
        FrameBg = 7,
        FrameBgHovered = 8,
        FrameBgActive = 9,
        TitleBg = 10,
        TitleBgActive = 11,
        TitleBgCollapsed = 12,
        MenuBarBg = 13,
        ScrollbarBg = 14,
        ScrollbarGrab = 15,
        ScrollbarGrabHovered = 16,
        ScrollbarGrabActive = 17,
        CheckMark = 18,
        SliderGrab = 19,
        SliderGrabActive = 20,
        Button = 21,
        ButtonHovered = 22,
        ButtonActive = 23,
        Header = 24,
        HeaderHovered = 25,
        HeaderActive = 26,
        Separator = 27,
        SeparatorHovered = 28,
        SeparatorActive = 29,
        ResizeGrip = 30,
        ResizeGripHovered = 31,
        ResizeGripActive = 32,
        Tab = 33,
        TabHovered = 34,
        TabActive = 35,
        TabUnfocused = 36,
        TabUnfocusedActive = 37,
        PlotLines = 38,
        PlotLinesHovered = 39,
        PlotHistogram = 40,
        PlotHistogramHovered = 41,
        TextSelectedBg = 42,
        DragDropTarget = 43,
        NavHighlight = 44,
        NavWindowingHighlight = 45,
        NavWindowingDimBg = 46,
        ModalWindowDimBg = 47,
    }
end

if not ImGuiWindowFlags then
    ImGuiWindowFlags = {
        None = 0,
        NoTitleBar = 1,
        NoResize = 2,
        NoMove = 4,
        NoScrollbar = 8,
        NoScrollWithMouse = 16,
        NoCollapse = 32,
        AlwaysAutoResize = 64,
        NoBackground = 128,
        NoSavedSettings = 256,
        NoMouseInputs = 512,
        MenuBar = 1024,
        HorizontalScrollbar = 2048,
        NoFocusOnAppearing = 4096,
        NoBringToFrontOnFocus = 8192,
        AlwaysVerticalScrollbar = 16384,
        AlwaysHorizontalScrollbar = 32768,
        AlwaysUseWindowPadding = 65536,
        NoNavInputs = 262144,
        NoNavFocus = 524288,
        UnsavedDocument = 1048576,
        NoNav = 786432,
        NoDecoration = 43,
        NoInputs = 786944,
    }
end

if not ImGuiCond then
    ImGuiCond = {
        Always = 1,
        Once = 2,
        FirstUseEver = 4,
        Appearing = 8,
    }
end

if not ImGuiInputTextFlags then
    ImGuiInputTextFlags = {
        None = 0,
        CharsDecimal = 1,
        CharsHexadecimal = 2,
        CharsUppercase = 4,
        CharsNoBlank = 8,
        AutoSelectAll = 16,
        EnterReturnsTrue = 32,
        CallbackCompletion = 64,
        CallbackHistory = 128,
        CallbackAlways = 256,
        CallbackCharFilter = 512,
        AllowTabInput = 1024,
        CtrlEnterForNewLine = 2048,
        NoHorizontalScroll = 4096,
        AlwaysInsertMode = 8192,
        ReadOnly = 16384,
        Password = 32768,
        NoUndoRedo = 65536,
        CharsScientific = 131072,
    }
end

-- Create global shortcuts for commonly used flags
ImGuiInputTextFlags_ReadOnly = ImGuiInputTextFlags.ReadOnly;
ImGuiInputTextFlags_EnterReturnsTrue = ImGuiInputTextFlags.EnterReturnsTrue;
ImGuiInputTextFlags_AllowTabInput = ImGuiInputTextFlags.AllowTabInput;

require 'templates';
require 'libs.baseprices';
require 'libs.zonenames';
require 'helpers';

----------------------------------------------------------------------------------------------------
-- Texture loading helper for v4
----------------------------------------------------------------------------------------------------
local C = ffi.C;

ffi.cdef[[
    typedef struct IDirect3DTexture8 IDirect3DTexture8;
    int32_t __stdcall D3DXCreateTextureFromFileA(void*, const char*, IDirect3DTexture8**);
]];

function LoadTexture(texturePath)
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local res = C.D3DXCreateTextureFromFileA(d3d8dev, texturePath, texture_ptr);
    if res == 0 then -- S_OK
        return tonumber(ffi.cast("uint32_t", texture_ptr[0]));
    end
    return nil;
end

----------------------------------------------------------------------------------------------------
-- Timer replacement for v4 (no built-in timer system)
----------------------------------------------------------------------------------------------------
local timers = {};
local timer_id_counter = 0;

local timer_module = {};
function timer_module.create(name, interval, iterations, callback)
    if timers[name] then
        return false;
    end
    timers[name] = {
        interval = interval,
        iterations = iterations,
        callback = callback,
        elapsed = 0,
        running = false,
        count = 0
    };
    return true;
end

function timer_module.start(name)
    if timers[name] then
        timers[name].running = true;
        return true;
    end
    return false;
end

function timer_module.remove(name)
    timers[name] = nil;
    return true;
end

function timer_module.once(delay_ms, callback)
    timer_id_counter = timer_id_counter + 1;
    local name = string.format('once_%d', timer_id_counter);
    timer_module.create(name, delay_ms / 1000, 1, function()
        callback();
        timer_module.remove(name);
    end);
    timer_module.start(name);
end

function timer_module.update(delta)
    for name, timer in pairs(timers) do
        if timer.running then
            timer.elapsed = timer.elapsed + delta;
            if timer.elapsed >= timer.interval then
                timer.elapsed = 0;
                timer.callback();
                timer.count = timer.count + 1;
                if timer.iterations > 0 and timer.count >= timer.iterations then
                    timer.running = false;
                end
            end
        end
    end
end

ashita.timer = timer_module;

--[[ #TODOs & Notes
    - cleanup code
    - figure out a way to scale better, use table? can we align?
--]]

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local settings_lib = require('settings');
local default_settings = table.copy(defaultSettingsTemplate);
local settings = settings_lib.load(default_settings);
local state    = table.copy(stateTemplate);
local metrics  = {};
local textures = {};

local ashitaResourceManager = AshitaCore:GetResourceManager();
local ashitaChatManager     = AshitaCore:GetChatManager();
local ashitaParty           = AshitaCore:GetMemoryManager():GetParty();
local ashitaPlayer          = AshitaCore:GetMemoryManager():GetPlayer();
local ashitaInventory       = AshitaCore:GetMemoryManager():GetInventory();
local ashitaTarget          = AshitaCore:GetMemoryManager():GetTarget();
local ashitaEntity          = AshitaCore:GetMemoryManager():GetEntity();

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

local eventAlertDefs =
{
    harvesting =
    {
        { key = "tool_break",     label = "Tool Break",     tip = "Play when your tool breaks." },
        { key = "no_yield",       label = "No Yield",       tip = "Play when you find nothing or fail to gather." },
        { key = "inventory_full", label = "Inventory Full", tip = "Play when inventory is full." },
        { key = "yield_lost",     label = "Yield Lost",     tip = "Play when a yield is lost." },
    },
    excavating =
    {
        { key = "tool_break",     label = "Tool Break",     tip = "Play when your tool breaks." },
        { key = "no_yield",       label = "No Yield",       tip = "Play when you find nothing or fail to gather." },
        { key = "inventory_full", label = "Inventory Full", tip = "Play when inventory is full." },
        { key = "yield_lost",     label = "Yield Lost",     tip = "Play when a yield is lost." },
    },
    logging =
    {
        { key = "tool_break",     label = "Tool Break",     tip = "Play when your tool breaks." },
        { key = "no_yield",       label = "No Yield",       tip = "Play when you find nothing or fail to gather." },
        { key = "inventory_full", label = "Inventory Full", tip = "Play when inventory is full." },
        { key = "yield_lost",     label = "Yield Lost",     tip = "Play when a yield is lost." },
    },
    mining =
    {
        { key = "tool_break",     label = "Pickaxe Break",  tip = "Play when your pickaxe breaks." },
        { key = "no_yield",       label = "Mine Nothing",   tip = "Play when you are unable to mine anything." },
        { key = "inventory_full", label = "Inventory Full", tip = "Play when inventory is full." },
        { key = "yield_lost",     label = "Yield Lost",     tip = "Play when a yield is lost." },
    },
    clamming =
    {
        { key = "bucket_break",   label = "Bucket Break",   tip = "Play when your clamming bucket breaks." },
        { key = "no_yield",       label = "No Yield",       tip = "Play when you fail to obtain a clamming yield." },
        { key = "inventory_full", label = "Inventory Full", tip = "Play when inventory is full." },
        { key = "yield_lost",     label = "Yield Lost",     tip = "Play when a yield is lost." },
    },
    fishing =
    {
        { key = "tool_break",     label = "Rod Break",      tip = "Play when your fishing rod breaks." },
        { key = "no_yield",       label = "No Catch",       tip = "Play when you do not catch anything." },
        { key = "inventory_full", label = "Inventory Full", tip = "Play when inventory is full." },
        { key = "yield_lost",     label = "Line Break/Lost",tip = "Play when you lose your catch or line breaks." },
    },
    digging =
    {
        { key = "no_yield",       label = "No Yield",       tip = "Play when you find nothing." },
        { key = "inventory_full", label = "Inventory Full", tip = "Play when inventory is full." },
        { key = "yield_lost",     label = "Yield Lost",     tip = "Play when a yield is lost." },
    },
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
local windowScaleMin = 1.00;
local windowScaleMax = 2.00;

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
        helpCommandEntry('fake', 'Seed fake yields for all gathering types (dev).'),
        helpCommandEntry('about', 'Display information about Yield.'),
        helpCommandEntry('help', 'Display Yield commands.'),
        helpSeparator('=', 26),
    },

    about =
    {
        helpSeparator('=', 23),
        helpTitle('About'),
        helpSeparator('=', 23),
        helpTypeEntry('Name', string.format("%s by Lotekkie", _addon.name)),
        helpTypeEntry('Description', _addon.description),
        helpTypeEntry('Author', _addon.author),
        helpTypeEntry('Version', _addon.version),
        helpTypeEntry('Community', "Report issues, share ideas, and contribute at https://github.com/Sjshovan/Ashita-Yield/issues"),
        helpTypeEntry('Support', "Optional support: https://Paypal.me/Sjshovan"),
        helpSeparator('=', 23),
    }
}

local modalConfirmPromptTemplate = "Are you sure you want to %s?";
local defaultFontSize            = nil;

local sounds = { [0] = "" };
local reports = {};

----------------------------------------------------------------------------------------------------
-- UI Variables (v4: Direct values instead of imgui vars)
---------------------------------------------------------------------------------------------------
local uiVariables =
{
    -- User Set
    ["var_WindowOpacity"]         = { 1.0 },
    ["var_ShowToolTips"]          = { true },
    ["var_TargetValue"]           = { 0 },
    ["var_WindowScaleIndex"]      = { 0 },
    ["var_WindowScale"]           = { 1.0 },
    ["var_WindowScalePct"]        = { 100 },
    ["var_ShowDetailedYields"]    = { true },
    ["var_YieldDetailsColor"]     = { 1.0, 1.0, 1.0, 1.0 },
    ["var_UseImageButtons"]       = { true },
    ["var_EnableSoundAlerts"]     = { true },
    ["var_TargetSoundFile"]       = { '' },
    ["var_FishingSkillSoundFile"] = { '' },
    ["var_ClamBreakSoundFile"]    = { '' },
    ["var_AutoGenReports"]        = { true },
    ["var_WindowLocked"]          = { false },
    ["var_TextScaleBase"]         = { 1.15 },
    ["var_TextScaleFactor"]       = { 0.45 },
    ["var_MetricsTextScaleBase"]  = { 1.15 },
    ["var_MetricsTextScaleFactor"]= { 0.45 },
    ["var_ButtonTextScaleBase"]   = { 1.10 },
    ["var_ButtonTextScaleFactor"] = { 0.45 },
    ["var_ButtonSizeXBase"]       = { 0.95 },
    ["var_ButtonSizeXFactor"]     = { 1.0 },
    ["var_ButtonSizeYBase"]       = { 0.95 },
    ["var_ButtonSizeYFactor"]     = { 1.0 },
    ["var_WindowXScaleBase"]      = { 1.0 },
    ["var_WindowXScaleFactor"]    = { 1.0 },
    ["var_WindowYScaleBase"]      = { 1.0 },
    ["var_WindowYScaleFactor"]    = { 1.0 },

    -- Internal
    ['var_WindowVisible']          = { true },
    ['var_SettingsVisible']        = { false },
    ["var_HelpVisible"]            = { false },
    ['var_AllSoundIndex']          = { 0 },
    ['var_AllColors']              = { 1.0, 1.0, 1.0, 1.0 },
    ["var_TargetSoundIndex"]       = { 0 },
    ["var_FishingSkillSoundIndex"] = { 0 },
    ["var_ClamBreakSoundIndex"]    = { 0 },
    ["var_IssueTitle"]             = { '' },
    ["var_IssueBody"]              = { '' },
    ['var_ReportSelected']         = { 0 },
    ["var_ReportFontScale"]        = { 1.0 },
}

local function clampWindowScale(scale)
    local value = tonumber(scale) or 1.0;
    if value < windowScaleMin then
        value = windowScaleMin;
    elseif value > windowScaleMax then
        value = windowScaleMax;
    end
    return value;
end

local function scaleToPercent(scale)
    return math.floor((clampWindowScale(scale) * 100.0) + 0.5);
end

local function percentToScale(percent)
    return clampWindowScale((tonumber(percent) or 100) / 100.0);
end

local function nearestWindowScaleIndex(scale)
    local input = clampWindowScale(scale);
    local bestIndex = 0;
    local bestDist = math.huge;
    for index, value in pairs(windowScales) do
        local dist = math.abs(value - input);
        if dist < bestDist then
            bestDist = dist;
            bestIndex = index;
        end
    end
    return bestIndex;
end

local function getWindowScale()
    if settings.general.windowScale ~= nil then
        return clampWindowScale(settings.general.windowScale);
    end
    return clampWindowScale(windowScales[settings.general.windowScaleIndex] or 1.0);
end

local function syncWindowScaleSettings(scale)
    local clamped = clampWindowScale(scale);
    settings.general.windowScale = clamped;
    settings.general.windowScaleIndex = nearestWindowScaleIndex(clamped);
    imgui.SetVarValue(uiVariables["var_WindowScale"], clamped);
    imgui.SetVarValue(uiVariables["var_WindowScalePct"], scaleToPercent(clamped));
    imgui.SetVarValue(uiVariables["var_WindowScaleIndex"], settings.general.windowScaleIndex);
end

local function clampSettingNumber(value, defaultValue, minValue, maxValue)
    local n = tonumber(value);
    if n == nil then
        n = defaultValue;
    end
    if minValue ~= nil and n < minValue then
        n = minValue;
    end
    if maxValue ~= nil and n > maxValue then
        n = maxValue;
    end
    return n;
end

local function ensureScaleTuningSettings()
    if settings and settings.general then
        local g = settings.general;
        local legacyBtnXFactor = tonumber(g.buttonSizeXFactor);
        local legacyBtnYFactor = tonumber(g.buttonSizeYFactor);
        local legacyBtnFactorOk =
            (legacyBtnXFactor == 1.0 or legacyBtnXFactor == 0.0) and
            (legacyBtnYFactor == 1.0 or legacyBtnYFactor == 0.0);
        local legacyDefaults =
            tonumber(g.textScaleBase) == 1.29 and tonumber(g.textScaleFactor) == 0.525 and
            tonumber(g.metricsTextScaleBase) == 1.29 and tonumber(g.metricsTextScaleFactor) == 0.525 and
            tonumber(g.buttonTextScaleBase) == 1.29 and tonumber(g.buttonTextScaleFactor) == 0.525 and
            tonumber(g.buttonSizeXBase) == 1.0 and tonumber(g.buttonSizeYBase) == 1.0 and
            legacyBtnFactorOk;
        if legacyDefaults then
            g.textScaleBase = 1.15;
            g.textScaleFactor = 0.45;
            g.metricsTextScaleBase = 1.15;
            g.metricsTextScaleFactor = 0.45;
            g.buttonTextScaleBase = 1.10;
            g.buttonTextScaleFactor = 0.45;
            g.buttonSizeXBase = 0.95;
            g.buttonSizeXFactor = 1.0;
            g.buttonSizeYBase = 0.95;
            g.buttonSizeYFactor = 1.0;
            writeDebugLog('migrate scale defaults -> v2');
        end
        if tonumber(g.windowYScaleFactor) == 0.72 then
            g.windowYScaleFactor = 1.0;
        end
    end
    settings.general.textScaleBase      = clampSettingNumber(settings.general.textScaleBase, 1.15, 0.5, 3.0);
    settings.general.textScaleFactor    = clampSettingNumber(settings.general.textScaleFactor, 0.45, 0.0, 3.0);
    settings.general.metricsTextScaleBase   = clampSettingNumber(settings.general.metricsTextScaleBase, settings.general.textScaleBase, 0.5, 3.0);
    settings.general.metricsTextScaleFactor = clampSettingNumber(settings.general.metricsTextScaleFactor, settings.general.textScaleFactor, 0.0, 3.0);
    settings.general.buttonTextScaleBase    = clampSettingNumber(settings.general.buttonTextScaleBase, 1.10, 0.5, 3.0);
    settings.general.buttonTextScaleFactor  = clampSettingNumber(settings.general.buttonTextScaleFactor, settings.general.textScaleFactor, 0.0, 3.0);
    settings.general.buttonSizeXBase        = clampSettingNumber(settings.general.buttonSizeXBase, 0.95, 0.5, 3.0);
    settings.general.buttonSizeXFactor      = clampSettingNumber(settings.general.buttonSizeXFactor, 1.0, 0.0, 3.0);
    settings.general.buttonSizeYBase        = clampSettingNumber(settings.general.buttonSizeYBase, 0.95, 0.5, 3.0);
    settings.general.buttonSizeYFactor      = clampSettingNumber(settings.general.buttonSizeYFactor, 1.0, 0.0, 3.0);
    settings.general.windowXScaleBase   = clampSettingNumber(settings.general.windowXScaleBase, 1.0, 0.5, 3.0);
    settings.general.windowXScaleFactor = clampSettingNumber(settings.general.windowXScaleFactor, 1.0, 0.0, 3.0);
    settings.general.windowYScaleBase   = clampSettingNumber(settings.general.windowYScaleBase, 1.0, 0.5, 3.0);
    settings.general.windowYScaleFactor = clampSettingNumber(settings.general.windowYScaleFactor, 1.0, 0.0, 3.0);
end

local function sanitizeColorSettings()
    local defaultYieldColor = colorTableToInt({ 1.0, 1.0, 1.0, 1.0 });
    if settings.general == nil then
        return;
    end
    if settings.general.yieldDetailsColor == nil then
        settings.general.yieldDetailsColor = defaultYieldColor;
        writeDebugLog('sanitizeColorSettings: fixed general yieldDetailsColor');
    elseif tonumber(settings.general.yieldDetailsColor) == 0 then
        -- Recover from corrupted transparent-black sentinel values persisted by older color-edit flow.
        settings.general.yieldDetailsColor = defaultYieldColor;
        writeDebugLog('sanitizeColorSettings: recovered general yieldDetailsColor from 0');
    else
        -- Keep the details text color opaque for readability and stable persistence.
        local cr, cg, cb, ca = colorToRGBA(settings.general.yieldDetailsColor);
        if ca == nil or ca <= 0 then
            settings.general.yieldDetailsColor = colorTableToInt({ (cr or 255) / 255, (cg or 255) / 255, (cb or 255) / 255, 1.0 });
            writeDebugLog('sanitizeColorSettings: forced general yieldDetailsColor alpha to 255');
        end
    end
    if settings.yields == nil then
        return;
    end
    for gathering, yields in pairs(settings.yields) do
        local totalCount = 0;
        local zeroCount = 0;
        for _, data in pairs(yields) do
            if data ~= nil then
                totalCount = totalCount + 1;
                if data.color == 0 then
                    zeroCount = zeroCount + 1;
                end
            end
        end
        -- Recovery: if an entire gathering set is zeroed, treat as corrupted state.
        if totalCount > 0 and zeroCount == totalCount then
            writeDebugLog(string.format('sanitizeColorSettings: recovering all-zero colors for gather=%s count=%d', tostring(gathering), totalCount));
            for _, data in pairs(yields) do
                if data ~= nil then
                    data.color = defaultYieldColor;
                end
            end
        end
        for yieldName, data in pairs(yields) do
            if data ~= nil and data.color == nil then
                data.color = defaultYieldColor;
                writeDebugLog(string.format('sanitizeColorSettings: fixed color gather=%s item=%s', tostring(gathering), tostring(yieldName)));
            end
        end
    end
end

local function getDefaultYieldColorInt()
    -- Keep yield defaults on neutral, readable text unless user customizes.
    return colorTableToInt({ 1.0, 1.0, 1.0, 1.0 });
end

local function getDefaultYieldColorRgba()
    local c = getDefaultYieldColorInt();
    local r, g, b, a = colorToRGBA(c);
    return r / 255, g / 255, b / 255, (a or 255) / 255;
end

local function syncScaleTuningVarsFromSettings()
    ensureScaleTuningSettings();
    imgui.SetVarValue(uiVariables["var_TextScaleBase"], settings.general.textScaleBase);
    imgui.SetVarValue(uiVariables["var_TextScaleFactor"], settings.general.textScaleFactor);
    imgui.SetVarValue(uiVariables["var_MetricsTextScaleBase"], settings.general.metricsTextScaleBase);
    imgui.SetVarValue(uiVariables["var_MetricsTextScaleFactor"], settings.general.metricsTextScaleFactor);
    imgui.SetVarValue(uiVariables["var_ButtonTextScaleBase"], settings.general.buttonTextScaleBase);
    imgui.SetVarValue(uiVariables["var_ButtonTextScaleFactor"], settings.general.buttonTextScaleFactor);
    imgui.SetVarValue(uiVariables["var_ButtonSizeXBase"], settings.general.buttonSizeXBase);
    imgui.SetVarValue(uiVariables["var_ButtonSizeXFactor"], settings.general.buttonSizeXFactor);
    imgui.SetVarValue(uiVariables["var_ButtonSizeYBase"], settings.general.buttonSizeYBase);
    imgui.SetVarValue(uiVariables["var_ButtonSizeYFactor"], settings.general.buttonSizeYFactor);
    imgui.SetVarValue(uiVariables["var_WindowXScaleBase"], settings.general.windowXScaleBase);
    imgui.SetVarValue(uiVariables["var_WindowXScaleFactor"], settings.general.windowXScaleFactor);
    imgui.SetVarValue(uiVariables["var_WindowYScaleBase"], settings.general.windowYScaleBase);
    imgui.SetVarValue(uiVariables["var_WindowYScaleFactor"], settings.general.windowYScaleFactor);
end

local function syncScaleTuningSettingsFromVars()
    settings.general.textScaleBase      = clampSettingNumber(imgui.GetVarValue(uiVariables["var_TextScaleBase"]), 1.15, 0.5, 3.0);
    settings.general.textScaleFactor    = clampSettingNumber(imgui.GetVarValue(uiVariables["var_TextScaleFactor"]), 0.45, 0.0, 3.0);
    settings.general.metricsTextScaleBase   = clampSettingNumber(imgui.GetVarValue(uiVariables["var_MetricsTextScaleBase"]), settings.general.textScaleBase, 0.5, 3.0);
    settings.general.metricsTextScaleFactor = clampSettingNumber(imgui.GetVarValue(uiVariables["var_MetricsTextScaleFactor"]), settings.general.textScaleFactor, 0.0, 3.0);
    settings.general.buttonTextScaleBase    = clampSettingNumber(imgui.GetVarValue(uiVariables["var_ButtonTextScaleBase"]), 1.10, 0.5, 3.0);
    settings.general.buttonTextScaleFactor  = clampSettingNumber(imgui.GetVarValue(uiVariables["var_ButtonTextScaleFactor"]), settings.general.textScaleFactor, 0.0, 3.0);
    settings.general.buttonSizeXBase        = clampSettingNumber(imgui.GetVarValue(uiVariables["var_ButtonSizeXBase"]), 0.95, 0.5, 3.0);
    settings.general.buttonSizeXFactor      = clampSettingNumber(imgui.GetVarValue(uiVariables["var_ButtonSizeXFactor"]), 1.0, 0.0, 3.0);
    settings.general.buttonSizeYBase        = clampSettingNumber(imgui.GetVarValue(uiVariables["var_ButtonSizeYBase"]), 0.95, 0.5, 3.0);
    settings.general.buttonSizeYFactor      = clampSettingNumber(imgui.GetVarValue(uiVariables["var_ButtonSizeYFactor"]), 1.0, 0.0, 3.0);
    settings.general.windowXScaleBase   = clampSettingNumber(imgui.GetVarValue(uiVariables["var_WindowXScaleBase"]), 1.0, 0.5, 3.0);
    settings.general.windowXScaleFactor = clampSettingNumber(imgui.GetVarValue(uiVariables["var_WindowXScaleFactor"]), 1.0, 0.0, 3.0);
    settings.general.windowYScaleBase   = clampSettingNumber(imgui.GetVarValue(uiVariables["var_WindowYScaleBase"]), 1.0, 0.5, 3.0);
    settings.general.windowYScaleFactor = clampSettingNumber(imgui.GetVarValue(uiVariables["var_WindowYScaleFactor"]), 1.0, 0.0, 3.0);
end

local function ensureAlertEventSettings()
    settings.alertEvents = settings.alertEvents or {};
    for gatherName, defs in pairs(eventAlertDefs) do
        settings.alertEvents[gatherName] = settings.alertEvents[gatherName] or {};
        for _, def in ipairs(defs) do
            if type(settings.alertEvents[gatherName][def.key]) ~= "string" then
                settings.alertEvents[gatherName][def.key] = "";
            end
        end
    end
    -- Backward compatibility: seed clamming bucket break event from legacy setting.
    if settings.general and settings.general.clamBreakSoundFile and settings.general.clamBreakSoundFile ~= "" then
        if settings.alertEvents.clamming and settings.alertEvents.clamming.bucket_break == "" then
            settings.alertEvents.clamming.bucket_break = settings.general.clamBreakSoundFile;
        end
    end
    -- Backward compatibility: migrate old mining pebble event sound to Pebble yield sound.
    local oldPebble = settings.alertEvents
        and settings.alertEvents.mining
        and settings.alertEvents.mining.pebble_hit or "";
    if oldPebble ~= "" and settings.yields and settings.yields.mining then
        for yieldName, data in pairs(settings.yields.mining) do
            if tostring(yieldName):lower() == "pebble" then
                if type(data.soundFile) ~= "string" or data.soundFile == "" then
                    data.soundFile = oldPebble;
                    data.soundIndex = getSoundIndex(oldPebble);
                    writeDebugLog('migrate pebble_hit -> mining.Pebble soundFile');
                end
                break;
            end
        end
    end
end

local function getAlertEventVarNames(gathering, eventKey)
    return
        string.format("var_%s_%s_eventSoundIndex", gathering, eventKey),
        string.format("var_%s_%s_eventSoundFile", gathering, eventKey);
end

local function syncAlertEventVars(gathering, eventKey)
    local idxVarName, fileVarName = getAlertEventVarNames(gathering, eventKey);
    uiVariables[idxVarName] = uiVariables[idxVarName] or { 0 };
    uiVariables[fileVarName] = uiVariables[fileVarName] or { "" };

    local soundFile = settings.alertEvents[gathering][eventKey] or "";
    local soundIndex = getSoundIndex(soundFile);
    imgui.SetVarValue(uiVariables[idxVarName], soundIndex);
    imgui.SetVarValue(uiVariables[fileVarName], sounds[soundIndex] or "");
end

local function setAlertEventSound(gathering, eventKey, soundIndex)
    local idxVarName, fileVarName = getAlertEventVarNames(gathering, eventKey);
    local idx = tonumber(soundIndex) or 0;
    local file = sounds[idx] or "";
    settings.alertEvents[gathering][eventKey] = file;
    imgui.SetVarValue(uiVariables[idxVarName], idx);
    imgui.SetVarValue(uiVariables[fileVarName], file);
end

local function playGatherEventAlert(gathering, eventKey)
    if gathering == nil or eventKey == nil then
        return false;
    end
    if settings.alertEvents == nil or settings.alertEvents[gathering] == nil then
        return false;
    end
    local file = settings.alertEvents[gathering][eventKey] or "";
    if file == "" then
        return false;
    end
    return playAlert(file);
end

local function setWindowFontScale(scale)
    local s = tonumber(scale) or 1.0;
    if state and state.window then
        state.window.currentTextScale = s;
    end
    -- Always apply scale explicitly so temporary button-font changes restore reliably.
    imgui.SetWindowFontScale(s);
end

-- Log current text/button scale sizing once per second per window tag.
local function logScaleSnapshot(tag, extra)
    if not state or not state.window or not state.values then
        return;
    end
    local now = os.clock();
    state.values.scaleSnapshotLogAt = state.values.scaleSnapshotLogAt or {};
    local last = state.values.scaleSnapshotLogAt[tag] or 0;
    if (now - last) < 1.0 then
        return;
    end
    state.values.scaleSnapshotLogAt[tag] = now;

    local fontPx = tonumber(imgui.GetFontSize()) or 0.0;
    local baseFontPx = tonumber(defaultFontSize) or fontPx or 0.0;
    local textScale = tonumber(state.window.textScale) or 1.0;
    local metricsScale = tonumber(state.window.metricsTextScale) or textScale;
    local buttonTextScale = tonumber(state.window.buttonTextScale) or textScale;
    local buttonSizeXScale = tonumber(state.window.buttonSizeXScale) or 1.0;
    local buttonSizeYScale = tonumber(state.window.buttonSizeYScale) or 1.0;
    local padX = 4.0 * buttonSizeXScale;
    local padY = 3.0 * buttonSizeYScale;
    local textFontPx = baseFontPx * textScale;
    local metricsFontPx = baseFontPx * metricsScale;
    local buttonFontPx = baseFontPx * buttonTextScale;
    local approxButtonH = buttonFontPx + (padY * 2.0);
    local frameH = tonumber(imgui.GetFrameHeight()) or 0.0;
    local frameHS = tonumber(imgui.GetFrameHeightWithSpacing()) or 0.0;
    local lineH = (imgui.GetTextLineHeight and tonumber(imgui.GetTextLineHeight())) or 0.0;
    local currentTextScale = tonumber(state.window.currentTextScale) or textScale;
    local actualW, actualH = 0.0, 0.0;
    local okSize, size = pcall(function() return imgui.GetWindowSize(); end);
    if okSize and type(size) == "table" then
        if size.x ~= nil then
            actualW = tonumber(size.x) or actualW;
            actualH = tonumber(size.y) or actualH;
        elseif size[1] ~= nil then
            actualW = tonumber(size[1]) or actualW;
            actualH = tonumber(size[2]) or actualH;
        end
    else
        local okW, w = pcall(function() return imgui.GetWindowWidth(); end);
        local okH, h = pcall(function() return imgui.GetWindowHeight(); end);
        if okW then actualW = tonumber(w) or actualW; end
        if okH then actualH = tonumber(h) or actualH; end
    end

    writeDebugLog(string.format(
        "scale_snapshot tag=%s scale=%.3f x=%.3f y=%.3f text=%.3f metrics=%.3f btnText=%.3f btnSizeX=%.3f btnSizeY=%.3f " ..
        "fontPx=%.2f baseFontPx=%.2f textFontPx=%.2f metricsFontPx=%.2f btnFontPx=%.2f btnPad=(%.1f,%.1f) btnApproxH=%.2f " ..
        "frameH=%.2f frameHS=%.2f lineH=%.2f currentText=%.3f win=(%.1f,%.1f) settings=(%.1f,%.1f) modal=(%.1f,%.1f) actualWin=(%.1f,%.1f) %s",
        tostring(tag),
        tonumber(state.window.scale) or 0.0,
        tonumber(state.window.xScale) or 0.0,
        tonumber(state.window.yScale) or 0.0,
        textScale,
        metricsScale,
        buttonTextScale,
        buttonSizeXScale,
        buttonSizeYScale,
        fontPx,
        baseFontPx,
        textFontPx,
        metricsFontPx,
        buttonFontPx,
        padX,
        padY,
        approxButtonH,
        frameH,
        frameHS,
        lineH,
        currentTextScale,
        tonumber(state.window.width) or 0.0,
        tonumber(state.window.height) or 0.0,
        tonumber(state.window.widthSettings) or 0.0,
        tonumber(state.window.heightSettings) or 0.0,
        tonumber(state.window.widthModalConfirm) or 0.0,
        tonumber(state.window.heightModalConfirm) or 0.0,
        actualW,
        actualH,
        extra or ""
    ));
end

local colorSavePending = false;
local applyDefaultButtonTooltip;
local function queueColorSave(context)
    if colorSavePending then
        return;
    end
    colorSavePending = true;
    ashita.timer.once(300, function()
        colorSavePending = false;
        writeDebugLog(string.format('queueColorSave flush: %s', tostring(context)));
        trySaveSettings(string.format('color_change_%s', tostring(context)), true);
    end);
end

local function uiButton(...)
    local label = select(1, ...);
    local padX = 4.0;
    local padY = 3.0;
    if state and state.window then
        padX = padX * (tonumber(state.window.buttonSizeXScale) or 1.0);
        padY = padY * (tonumber(state.window.buttonSizeYScale) or 1.0);
    end
    imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { padX, padY });
    local pressed = imgui.Button(...);
    imgui.PopStyleVar();
    if type(applyDefaultButtonTooltip) == "function" then
        applyDefaultButtonTooltip(label);
    end
    return pressed;
end

local function uiArrowButton(id, dir, fallbackLabel, fallbackSize)
    local padX = 4.0;
    local padY = 3.0;
    if state and state.window then
        padX = padX * (tonumber(state.window.buttonSizeXScale) or 1.0);
        padY = padY * (tonumber(state.window.buttonSizeYScale) or 1.0);
    end

    if type(imgui.ArrowButton) == 'function' then
        imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { padX, padY });
        local ok, pressed = pcall(function()
            return imgui.ArrowButton(tostring(id or "##arrow"), tonumber(dir) or 0);
        end);
        imgui.PopStyleVar();
        if ok then
            return pressed == true;
        end
    end

    return uiButton(fallbackLabel or "^", fallbackSize);
end

local function calcScaledButtonHeight()
    local h = imgui.GetFrameHeight();
    if state and state.window then
        -- Keep button text scaling uniform with the active window text scale.
        local textScale = tonumber(state.window.textScale) or 1.0;
        local padY = 3.0 * (tonumber(state.window.buttonSizeYScale) or 1.0);
        local fontPx = (tonumber(defaultFontSize) or imgui.GetFontSize() or 12.0) * textScale;
        h = math.max(h, fontPx + (padY * 2.0));
    end
    return h;
end

local function calcFooterMetrics()
    local ui = state and state.window and state.window.ui or nil;
    local uiSpace = ui and ui.space or nil;
    local uiButton = ui and ui.button or nil;
    local scale = (state and state.window and tonumber(state.window.scale)) or 1.0;

    local buttonH = math.max(
        tonumber(calcScaledButtonHeight()) or 0.0,
        (uiButton and tonumber(uiButton.minH)) or 0.0
    );
    local symPad = math.max(
        2.0,
        (uiSpace and tonumber(uiSpace.sm)) or (scale * 2.0)
    );
    local bottomPadTarget = math.max(
        2.0,
        ((uiSpace and tonumber(uiSpace.xs)) or 0.0) + 2.0
    );
    local reserve = math.max(
        tonumber(imgui.GetFrameHeightWithSpacing()) or 0.0,
        buttonH + bottomPadTarget
    );
    -- Shared footer breathing room for both main and settings windows so vertical
    -- button spacing is identical at all scales.
    local extraBottom = math.max(3.5, (((uiSpace and tonumber(uiSpace.xs)) or 0.0) * 1.65));
    reserve = math.ceil((tonumber(reserve) or 0.0) + extraBottom);
    return buttonH, symPad, bottomPadTarget, reserve;
end

local function pushSelectedBorderStyle(isSelected)
    if isSelected then
        imgui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, math.max(1.0, tonumber(state.window.scale) or 1.0));
        imgui.PushStyleColor(ImGuiCol_Border, { 0.39, 0.96, 0.13, 1.0 });
    else
        imgui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0.0);
        imgui.PushStyleColor(ImGuiCol_Border, { 0, 0, 0, 0 });
    end
end

local estimateButtonWidth;
local uiActionButton;
local uiSmallButton;
local uiSmallButtonBoosted;
local uiSmallButtonCompact;
local ACTION_BTN_BOOST = 1.00;
local SETTINGS_HEADER_TEXT_COLOR = { 1.0, 1.0, 0.54, 1.0 }; -- warn yellow
local SETTINGS_HEADER_LINE_COLOR = { 0.24, 0.25, 0.27, 1.0 }; -- neutral gray
local SETTINGS_HEADER_BTN_COLOR = { 0.24, 0.25, 0.27, 1.0 };
local SETTINGS_HEADER_BTN_HOVER = { 0.34, 0.36, 0.38, 1.0 };
local SETTINGS_HEADER_BTN_ACTIVE = { 0.34, 0.36, 0.38, 1.0 };
local defaultButtonTooltips =
{
    ["Exit"] = "Unload Yield.",
    ["Reload"] = "Reload Yield.",
    ["Reset"] = "Reset current gathering metrics and timer.",
    ["Settings"] = "Open Yield settings.",
    ["Help"] = "Open Yield help.",
    ["Done"] = "Save changes and close settings.",
    ["Save"] = "Save current settings.",
    ["Cancel"] = "Discard unsaved changes.",
    ["Use Defaults"] = "Restore defaults for this page.",
    ["Defaults"] = "Restore default values.",
    ["Apply"] = "Apply current changes.",
    ["Read"] = "Read the selected report.",
    ["Close"] = "Close the active report view.",
    ["Delete"] = "Delete selected report files.",
    ["Generate"] = "Generate a new report.",
    ["Open Issues"] = "Open the Yield GitHub issues page.",
    ["Open Repo"] = "Open the Yield GitHub repository.",
    ["Open Discord"] = "Open the Ashita community Discord.",
    ["Support Development"] = "Open the Yield support page.",
    ["Recalculate Value"] = "Recompute estimated value from yields and prices.",
    ["Start"] = "Start the timer for this gathering type.",
    ["Stop"] = "Stop the timer for this gathering type.",
    ["Clear"] = "Reset elapsed timer to zero.",
    ["Play"] = "Play the selected sound.",
    ["Yes"] = "Confirm action.",
    ["No"] = "Cancel action.",
    ["Submit"] = "Submit feedback report.",
    ["Go to Paypal"] = "Open donation page in browser.",
};

local function getVisibleLabelText(label)
    if type(label) ~= "string" then
        return nil;
    end
    local text = string.match(label, "^(.-)##") or label;
    text = string.gsub(text, "^%s+", "");
    text = string.gsub(text, "%s+$", "");
    if text == "" then
        return nil;
    end
    return text;
end

applyDefaultButtonTooltip = function(label)
    if settings == nil or settings.general == nil or settings.general.showToolTips ~= true then
        return;
    end
    if imgui.IsItemHovered == nil or imgui.SetTooltip == nil then
        return;
    end
    if not imgui.IsItemHovered() then
        return;
    end
    local visible = getVisibleLabelText(label);
    if visible == nil then
        return;
    end
    local tip = defaultButtonTooltips[visible];
    if tip ~= nil and tip ~= "" then
        imgui.SetTooltip(tip);
    end
end

local function estimateHeaderActionWidth(label)
    local w = estimateButtonWidth(label or "", false);
    local baseline = estimateButtonWidth("Defaults", false);
    return math.max(tonumber(w) or 0.0, tonumber(baseline) or 0.0) * ACTION_BTN_BOOST;
end

local function renderSettingsHeaderRow(title, rightLabel, tooltip, onClick)
    local rowY = imgui.GetCursorPosY();
    local rowX = imgui.GetCursorPosX();
    local rowAvail = imgui.GetContentRegionAvail();
    if type(rowAvail) == "table" and rowAvail.x ~= nil then
        rowAvail = tonumber(rowAvail.x) or 0.0;
    end
    imgui.SetCursorPosX(rowX);
    imgui.SetCursorPosY(rowY);
    imgui.AlignTextToFramePadding();
    imgui.TextColored(SETTINGS_HEADER_TEXT_COLOR, tostring(title or ""));

    if rightLabel ~= nil and rightLabel ~= "" then
        local btnW = estimateHeaderActionWidth(rightLabel);
        local btnX = rowX + rowAvail - btnW;
        if btnX < rowX then btnX = rowX; end
        imgui.SetCursorPosX(btnX);
        imgui.SetCursorPosY(rowY);
        imgui.AlignTextToFramePadding();
        if uiActionButton(rightLabel) and type(onClick) == "function" then
            onClick();
        end
        if tooltip ~= nil and tooltip ~= "" and settings.general.showToolTips and imgui.IsItemHovered() then
            imgui.SetTooltip(tooltip);
        end
    end

    local rowH = imgui.GetFrameHeightWithSpacing();
    imgui.SetCursorPosX(rowX);
    imgui.SetCursorPosY(rowY + rowH);
    imgui.PushStyleColor(ImGuiCol.Separator, SETTINGS_HEADER_LINE_COLOR);
    imgui.Separator();
    imgui.PopStyleColor();
    imgui.Spacing();
end

local function renderSettingsMenuBarHeader(title, rightLabel, tooltip, onClick)
    local prevScale = (state and state.window and state.window.currentTextScale) or (state and state.window and state.window.textScale) or 1.0;
    local headerScale = (state and state.window and state.window.textScale) or 1.0;
    local padX = 4.0 * ((state and state.window and tonumber(state.window.buttonSizeXScale)) or 1.0);
    local padY = 3.0 * ((state and state.window and tonumber(state.window.buttonSizeYScale)) or 1.0);
    imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { padX, padY });
    if not imgui.BeginMenuBar() then
        imgui.PopStyleVar();
        return;
    end
    setWindowFontScale(headerScale);
    local rowX = imgui.GetCursorPosX();
    local rowY = imgui.GetCursorPosY();
    local rowAvail = imgui.GetContentRegionAvail();
    if type(rowAvail) == "table" and rowAvail.x ~= nil then
        rowAvail = tonumber(rowAvail.x) or 0.0;
    end

    imgui.SetCursorPosX(rowX);
    imgui.SetCursorPosY(rowY);
    imgui.AlignTextToFramePadding();
    imgui.TextColored(SETTINGS_HEADER_TEXT_COLOR, tostring(title or ""));

    if rightLabel ~= nil and rightLabel ~= "" then
        local btnW = estimateHeaderActionWidth(rightLabel);
        local btnX = rowX + rowAvail - btnW;
        if btnX < rowX then btnX = rowX; end
        imgui.SetCursorPosX(btnX);
        imgui.SetCursorPosY(rowY);
        imgui.AlignTextToFramePadding();
        if uiActionButton(rightLabel) and type(onClick) == "function" then
            onClick();
        end
        if tooltip ~= nil and tooltip ~= "" and settings.general.showToolTips and imgui.IsItemHovered() then
            imgui.SetTooltip(tooltip);
        end
    end

    imgui.EndMenuBar();
    imgui.PopStyleVar();
    setWindowFontScale(prevScale);
    imgui.Spacing();
end

local function renderSettingsTitleBar(title, gatherSelected, onGatherSelect, gatherBtnBoost)
    local prevScale = (state and state.window and state.window.currentTextScale) or (state and state.window and state.window.textScale) or 1.0;
    local headerScale = (state and state.window and state.window.textScale) or 1.0;
    local padX = 4.0 * ((state and state.window and tonumber(state.window.buttonSizeXScale)) or 1.0);
    local padY = 3.0 * ((state and state.window and tonumber(state.window.buttonSizeYScale)) or 1.0);
    imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { padX, padY });
    if not imgui.BeginMenuBar() then
        imgui.PopStyleVar();
        return;
    end

    setWindowFontScale(headerScale);
    local rowX = imgui.GetCursorPosX();
    local rowY = imgui.GetCursorPosY();
    local rowAvail = imgui.GetContentRegionAvail();
    if type(rowAvail) == "table" and rowAvail.x ~= nil then
        rowAvail = tonumber(rowAvail.x) or 0.0;
    end

    local boost = tonumber(gatherBtnBoost) or 1.18;
    local cursorX = rowX;
    if gatherSelected ~= nil and type(onGatherSelect) == "function" then
        local gap = (state and state.window and state.window.spaceGatherBtn) or 4.0;
        for _, data in ipairs(gatherTypes or {}) do
            imgui.SetCursorPosX(cursorX);
            imgui.SetCursorPosY(rowY);
            local isSelected = (data.name == gatherSelected);
            pushSelectedBorderStyle(isSelected);
            if state.values.btnTextureFailure or not settings.general.useImageButtons then
                imguiPushActiveBtnColor(isSelected);
                if uiSmallButtonBoosted(string.upperfirst(data.short), boost) then
                    onGatherSelect(data);
                end
                cursorX = cursorX + (estimateButtonWidth(string.upperfirst(data.short), true) * boost) + gap;
            else
                local texture = textures[data.name];
                local textureSize = state.window.sizeGatherTexture * boost;
                imguiPushActiveBtnColor(isSelected);
                if imgui.ImageButton(texture, { textureSize, textureSize }) then
                    onGatherSelect(data);
                end
                cursorX = cursorX + textureSize + (state.window.scale * 8.0) + gap;
            end
            imgui.PopStyleColor(2);
            imgui.PopStyleVar();
            if imgui.IsItemHovered() then
                imgui.SetTooltip(string.upperfirst(data.name));
            end
        end
    end

    local titleText = tostring(title or "");
    local titleW = imgui.CalcTextSize(titleText);
    if type(titleW) == "table" and titleW.x ~= nil then
        titleW = tonumber(titleW.x) or 0.0;
    end

    local statusText = nil;
    local statusColor = nil;
    if state.values.settingsStatusText ~= nil and state.values.settingsStatusText ~= "" then
        if os.clock() <= (state.values.settingsStatusUntil or 0) then
            statusText = tostring(state.values.settingsStatusText);
            statusColor = state.values.settingsStatusColor or { 0.77, 0.83, 0.80, 1.0 };
        else
            state.values.settingsStatusText = "";
        end
    end

    local sepText = " | ";
    local sepW = imgui.CalcTextSize(sepText);
    if type(sepW) == "table" and sepW.x ~= nil then
        sepW = tonumber(sepW.x) or 0.0;
    end

    local statusW = 0.0;
    if statusText ~= nil then
        statusW = imgui.CalcTextSize(statusText);
        if type(statusW) == "table" and statusW.x ~= nil then
            statusW = tonumber(statusW.x) or 0.0;
        end
    end

    local blockW = (tonumber(titleW) or 0.0);
    if statusText ~= nil then
        blockW = blockW + (tonumber(sepW) or 0.0) + (tonumber(statusW) or 0.0);
    end
    local blockX = rowX + rowAvail - blockW;
    if blockX < cursorX then blockX = cursorX; end

    imgui.SetCursorPosX(blockX);
    imgui.SetCursorPosY(rowY);
    imgui.AlignTextToFramePadding();
    if statusText ~= nil then
        imgui.TextColored(statusColor, statusText);
        imgui.SameLine(0.0, 0.0);
        imgui.AlignTextToFramePadding();
        imgui.TextColored(SETTINGS_HEADER_TEXT_COLOR, sepText);
        imgui.SameLine(0.0, 0.0);
        imgui.AlignTextToFramePadding();
    end
    imgui.TextColored(SETTINGS_HEADER_TEXT_COLOR, titleText);

    imgui.EndMenuBar();
    imgui.PopStyleVar();
    setWindowFontScale(prevScale);
end

local function renderSettingsPageStatusRow()
    -- Status now renders inline in renderSettingsTitleBar as "Status | Page".
end

local function pushSettingsPageMenuBarSizing()
    local padX = 4.0 * ((state and state.window and tonumber(state.window.buttonSizeXScale)) or 1.0);
    local padY = 3.0 * ((state and state.window and tonumber(state.window.buttonSizeYScale)) or 1.0);
    local scale = (state and state.window and tonumber(state.window.scale)) or 1.0;
    local extraY = math.max(1.5, scale * 1.10);
    imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { padX, padY + extraY });
end

uiActionButton = function(label)
    local h = calcScaledButtonHeight();
    local minW = 64.0;
    if state and state.window then
        local scaleX = tonumber(state.window.buttonSizeXScale) or 1.0;
        minW = minW * scaleX;
    end
    local w;
    if type(estimateButtonWidth) == 'function' then
        w = estimateButtonWidth(label, false);
        -- Keep primary action buttons visually uniform regardless of short labels (e.g. "Done").
        local baseline = estimateButtonWidth("Defaults", false);
        minW = math.max(minW, tonumber(baseline) or 0.0);
    else
        -- Safety fallback: avoid hard-crash if helper was not initialized yet.
        local textPx = imgui.CalcTextSize(label);
        if type(textPx) == 'table' and textPx.x ~= nil then
            textPx = textPx.x;
        end
        local padX = 4.0 * ((state and state.window and tonumber(state.window.buttonSizeXScale)) or 1.0);
        w = (tonumber(textPx) or 0.0) + (padX * 2.0);
        writeDebugLog(string.format('uiActionButton fallback width used for label=%s', tostring(label)));
    end
    w = math.max(tonumber(w) or 0.0, minW) * ACTION_BTN_BOOST;
    h = h * ACTION_BTN_BOOST;
    return uiButton(label, { w, h });
end

uiSmallButton = function(...)
    local label = select(1, ...);
    local padX = 3.0;
    local padY = 2.0;
    if state and state.window then
        padX = padX * (tonumber(state.window.buttonSizeXScale) or 1.0);
        padY = padY * (tonumber(state.window.buttonSizeYScale) or 1.0);
    end
    imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { padX, padY });
    local pressed = imgui.SmallButton(...);
    imgui.PopStyleVar();
    if type(applyDefaultButtonTooltip) == "function" then
        applyDefaultButtonTooltip(label);
    end
    return pressed;
end

uiSmallButtonBoosted = function(label, boost)
    local b = tonumber(boost) or 1.0;
    if b < 0.50 then b = 0.50; end
    local padX = 3.0;
    local padY = 2.0;
    if state and state.window then
        padX = padX * (tonumber(state.window.buttonSizeXScale) or 1.0);
        padY = padY * (tonumber(state.window.buttonSizeYScale) or 1.0);
    end
    imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { padX * b, padY * b });
    local pressed = imgui.SmallButton(label);
    imgui.PopStyleVar();
    if type(applyDefaultButtonTooltip) == "function" then
        applyDefaultButtonTooltip(label);
    end
    return pressed;
end

uiSmallButtonCompact = function(label)
    return uiSmallButton(label);
end

local function uiButtonCompact(label)
    return uiButton(label);
end

estimateButtonWidth = function(label, isSmall)
    local text = tostring(label or "");
    -- ImGui labels can include an ID suffix after '##'; width should use visible text only.
    local visibleText = string.match(text, "^(.-)##") or text;
    local fontSize = imgui.GetFontSize();
    local textWidth = #visibleText * fontSize * 0.55;
    if imgui.CalcTextSize ~= nil then
        local ok, size = pcall(function() return imgui.CalcTextSize(visibleText); end);
        if ok and size ~= nil then
            if type(size) == "table" then
                if size.x ~= nil then
                    textWidth = tonumber(size.x) or textWidth;
                elseif size[1] ~= nil then
                    textWidth = tonumber(size[1]) or textWidth;
                end
            end
        end
    end
    local padX = isSmall and 3.0 or 4.0;
    if state and state.window then
        padX = padX * (tonumber(state.window.buttonSizeXScale) or 1.0);
    end
    return textWidth + (padX * 2.0);
end

local function estimateButtonWidthForButtons(label, isSmall)
    if type(estimateButtonWidth) ~= "function" then
        return 0.0;
    end
    local w = estimateButtonWidth(label, isSmall);
    return tonumber(w) or 0.0;
end

local function sameLineIfFits(nextLabel, spacing, isSmall)
    local nextWidth = estimateButtonWidth(nextLabel, isSmall);
    local avail = imgui.GetContentRegionAvail();
    if avail > (nextWidth + (tonumber(spacing) or 0.0)) then
        imgui.SameLine(0.0, spacing or 0.0);
        return true;
    end
    return false;
end

local function alignButtonGroupRight(labels, spacing, isSmall)
    local totalWidth = 0.0;
    for i, label in ipairs(labels or {}) do
        totalWidth = totalWidth + estimateButtonWidth(label, isSmall);
        if i < #labels then
            totalWidth = totalWidth + (spacing or 0.0);
        end
    end
    local padX = (state and state.window and state.window.padX) or 5.0;
    local targetX = imgui.GetWindowWidth() - padX - totalWidth;
    local currentX = imgui.GetCursorPosX();
    if targetX > currentX then
        imgui.SameLine(targetX, 0.0);
        return true;
    end
    return false;
end

local function getAvailX(avail)
    if type(avail) == "table" and avail.x ~= nil then
        return tonumber(avail.x) or 0.0;
    end
    return tonumber(avail) or 0.0;
end

local function getAvailXY(avail, fallbackY)
    if type(avail) == "table" then
        local x = tonumber(avail.x) or tonumber(avail[1]) or 0.0;
        local y = tonumber(avail.y) or tonumber(avail[2]) or tonumber(fallbackY) or 0.0;
        return x, y;
    end
    local x = tonumber(avail) or 0.0;
    local y = tonumber(fallbackY) or 0.0;
    return x, y;
end

-- Distribute buttons evenly across a row with symmetric edge spacing.
local function computeEvenRowPositions(startX, availWidth, widths, minGap, edgePad)
    local positions = {};
    local count = #widths;
    if count <= 0 then
        return positions, 0.0, 0.0, 0.0;
    end

    local totalWidth = 0.0;
    for i = 1, count do
        totalWidth = totalWidth + (tonumber(widths[i]) or 0.0);
    end

    local avail = math.max(0.0, tonumber(availWidth) or 0.0);
    local edge = math.max(0.0, tonumber(edgePad) or 0.0);
    local gap = math.max(0.0, tonumber(minGap) or 0.0);
    local slots = count + 1;
    local free = avail - totalWidth - (edge * 2.0);
    local equalGap = free / slots;
    if equalGap > gap then
        gap = equalGap;
    end

    -- If the configured minimum gap does not fit, gracefully compress the gaps.
    local required = totalWidth + (gap * slots) + (edge * 2.0);
    if required > avail then
        gap = math.max(0.0, (avail - totalWidth - (edge * 2.0)) / slots);
    end

    local x = (tonumber(startX) or 0.0) + edge + gap;
    for i = 1, count do
        positions[i] = x;
        x = x + (tonumber(widths[i]) or 0.0) + gap;
    end
    return positions, gap, edge, totalWidth;
end

-- Distribute a row with no outer gaps: first and last items are flush to row edges.
local function computeFlushRowPositions(startX, availWidth, widths, minGap)
    local positions = {};
    local count = #widths;
    if count <= 0 then
        return positions, 0.0, 0.0, 0.0;
    end

    local totalWidth = 0.0;
    for i = 1, count do
        totalWidth = totalWidth + (tonumber(widths[i]) or 0.0);
    end

    local avail = math.max(0.0, tonumber(availWidth) or 0.0);
    local gap = 0.0;
    local slots = count - 1;
    if slots > 0 then
        gap = math.max(0.0, tonumber(minGap) or 0.0);
        local equalGap = (avail - totalWidth) / slots;
        if equalGap > gap then
            gap = equalGap;
        end
        local required = totalWidth + (gap * slots);
        if required > avail then
            gap = math.max(0.0, (avail - totalWidth) / slots);
        end
    end

    local x = tonumber(startX) or 0.0;
    for i = 1, count do
        positions[i] = x;
        x = x + (tonumber(widths[i]) or 0.0) + gap;
    end
    return positions, gap, 0.0, totalWidth;
end

local function logLayoutBreadcrumb(tag, details)
    if not state or not state.values then
        return;
    end
    local now = os.clock();
    state.values.layoutLogAt = state.values.layoutLogAt or {};
    local key = tostring(tag or "layout");
    local last = state.values.layoutLogAt[key] or 0;
    if (now - last) < 1.0 then
        return;
    end
    state.values.layoutLogAt[key] = now;
    writeDebugLog(string.format("layout_%s %s", key, tostring(details or "")));
end

local function logFooterItemRect(tag, label, rowY, reserve)
    if not state or not state.values then
        return;
    end
    local now = os.clock();
    state.values.footerRectLogAt = state.values.footerRectLogAt or {};
    local key = tostring(tag or "footer");
    local last = state.values.footerRectLogAt[key] or 0;
    if (now - last) < 1.0 then
        return;
    end
    state.values.footerRectLogAt[key] = now;

    local afterY = tonumber(imgui.GetCursorPosY()) or 0.0;
    local startY = tonumber(rowY) or 0.0;
    local reserveY = tonumber(reserve) or 0.0;
    local consumedY = afterY - startY;
    local overflowY = consumedY - reserveY;
    local frameH = tonumber(imgui.GetFrameHeight()) or 0.0;
    local frameHS = tonumber(imgui.GetFrameHeightWithSpacing()) or 0.0;
    local lineH = tonumber(imgui.GetTextLineHeight()) or 0.0;
    writeDebugLog(string.format(
        "footer_item_rect tag=%s label=%s rowY=%.1f afterY=%.1f reserve=%.1f consumedY=%.1f overflowY=%.2f frameH=%.2f frameHS=%.2f lineH=%.2f",
        key, tostring(label or ""), startY, afterY, reserveY,
        consumedY, overflowY, frameH, frameHS, lineH
    ));
end

local function applyYieldColorFromVar(gathering, yieldName)
    local varName = string.format("var_%s_%s_color", gathering, yieldName);
    local var = uiVariables[varName];
    if var == nil then
        return nil;
    end
    local color = getColorVarTable(var, varName);
    local r = tonumber(color[1]) or 1.0;
    local g = tonumber(color[2]) or 1.0;
    local b = tonumber(color[3]) or 1.0;
    -- Force opaque text colors; transparent text causes "missing items" confusion.
    imgui.SetVarValue(var, r, g, b, 1.0);
    local converted = colorTableToInt({ r, g, b, 1.0 });
    if settings.yields and settings.yields[gathering] and settings.yields[gathering][yieldName] then
        settings.yields[gathering][yieldName].color = converted;
    end
    return converted;
end

local function syncGatherYieldColorVars(gathering)
    if settings.yields == nil or settings.yields[gathering] == nil then
        return;
    end
    for yieldName, data in pairs(settings.yields[gathering]) do
        local varName = string.format("var_%s_%s_color", gathering, yieldName);
        uiVariables[varName] = uiVariables[varName] or { 1.0, 1.0, 1.0, 1.0 };
        local r, g, b, a = colorToRGBA(data.color or getDefaultYieldColorInt());
        if a == nil or a <= 0 then a = 255; end
        imgui.SetVarValue(uiVariables[varName], r / 255, g / 255, b / 255, a / 255);
    end
end

local function getGatherBulkColorRgba(gathering)
    if settings == nil or settings.yields == nil or settings.yields[gathering] == nil then
        return getDefaultYieldColorRgba();
    end

    local sortedYields = table.sortKeysByAlphabet(settings.yields[gathering], true);
    if sortedYields == nil or #sortedYields <= 0 then
        return getDefaultYieldColorRgba();
    end

    local firstYield = sortedYields[1];
    local data = settings.yields[gathering][firstYield];
    local colorInt = (data and data.color) or getDefaultYieldColorInt();
    local r, g, b, a = colorToRGBA(colorInt);
    if a == nil or a <= 0 then
        a = 255;
    end
    return (r or 255) / 255, (g or 255) / 255, (b or 255) / 255, a / 255;
end

local function syncAllColorsVarForGather(gathering, reason)
    if gathering == nil or uiVariables["var_AllColors"] == nil then
        return;
    end

    local r, g, b, a = getGatherBulkColorRgba(gathering);
    imgui.SetVarValue(uiVariables["var_AllColors"], r, g, b, a);
    writeDebugLog(string.format(
        'setColors bulk sync gather=%s reason=%s rgba=(%.3f,%.3f,%.3f,%.3f)',
        tostring(gathering), tostring(reason or "unknown"),
        tonumber(r) or 0.0, tonumber(g) or 0.0, tonumber(b) or 0.0, tonumber(a) or 0.0
    ));
end

local function fitWindowRect(baseWidth, baseHeight, maxWidth, maxHeight, fitPct)
    local pct = tonumber(fitPct) or 1.0;
    local safeW = math.max(1.0, (tonumber(maxWidth) or baseWidth) * pct);
    local safeH = math.max(1.0, (tonumber(maxHeight) or baseHeight) * pct);
    local ratioW = safeW / math.max(1.0, baseWidth);
    local ratioH = safeH / math.max(1.0, baseHeight);
    local ratio = math.min(1.0, ratioW, ratioH);
    return baseWidth * ratio, baseHeight * ratio;
end

local function normalizeYieldName(name)
    local value = tostring(name or ""):lower();
    value = value:gsub("^%s+", ""):gsub("%s+$", "");
    value = value:gsub("^an%s+", ""):gsub("^a%s+", "");
    value = value:gsub("[^%w]", "");
    return value;
end

local function resolveYieldName(gathering, parsed)
    if gathering == nil or parsed == nil then
        return nil;
    end
    local yields = settings.yields[gathering];
    if yields == nil then
        return nil;
    end

    -- Fast path exact key match.
    if table.haskey(yields, parsed) then
        return parsed;
    end

    local target = normalizeYieldName(parsed);
    if target == "" then
        return nil;
    end

    for yieldName, _ in pairs(yields) do
        if normalizeYieldName(yieldName) == target then
            return yieldName;
        end
    end

    -- Fallback for pluralized parse results (e.g. "Fish Scales" / "Fish Scale").
    if target:sub(-1) == "s" then
        local singular = target:sub(1, -2);
        for yieldName, _ in pairs(yields) do
            if normalizeYieldName(yieldName) == singular then
                return yieldName;
            end
        end
    end

    return nil;
end

-- Helper functions for v4 variable compatibility
function imgui.SetVarValue(var, ...)
    if type(var) ~= 'table' then
        print(string.format("Warning: imgui.SetVarValue called with non-table: %s", type(var)));
        return;
    end
    local args = {...};
    if #args == 1 then
        var[1] = args[1];
    elseif #args == 4 then
        -- Color array (flat rgba tuple for ColorEdit4 compatibility)
        var[1] = args[1];
        var[2] = args[2];
        var[3] = args[3];
        var[4] = args[4];
    elseif #args == 3 then
        -- Triple values (single/stack/npc prices)
        var[1] = args[1];
        var[2] = args[2];
        var[3] = args[3];
    elseif #args == 2 then
        -- Two values
        var[1] = args[1];
        var[2] = args[2];
    end
end

function imgui.GetVarValue(var)
    if type(var) ~= 'table' then
        print(string.format("Warning: imgui.GetVarValue called with non-table: %s", type(var)));
        return nil;
    end
    if type(var[1]) == 'table' then
        return var[1][1], var[1][2], var[1][3], var[1][4];
    elseif var[4] ~= nil then
        return var[1], var[2], var[3], var[4];
    elseif var[3] ~= nil then
        return var[1], var[2], var[3];
    elseif var[2] ~= nil then
        return var[1], var[2];
    else
        return var[1];
    end
end

function imgui.CreateVar(varType, size)
    if varType == nil then return {0}; end
    return {0}; -- placeholder, actual values set by SetVarValue
end

----------------------------------------------------------------------------------------------------
-- func: loadUiVariables
-- desc: Loads the ui variables from the Yield settings file.
----------------------------------------------------------------------------------------------------
function loadUiVariables()
    ensureAlertEventSettings();
    ensureScaleTuningSettings();
    sanitizeColorSettings();
    writeDebugLog('loadUiVariables: begin');
    -- Load the UI variables..
    imgui.SetVarValue(uiVariables["var_WindowOpacity"], settings.general.opacity);
    imgui.SetVarValue(uiVariables["var_TargetValue"], settings.general.targetValue);
    imgui.SetVarValue(uiVariables["var_ShowToolTips"], settings.general.showToolTips);
    syncWindowScaleSettings(settings.general.windowScale or windowScales[settings.general.windowScaleIndex] or 1.0);
    imgui.SetVarValue(uiVariables["var_ShowDetailedYields"], settings.general.showDetailedYields);
    imgui.SetVarValue(uiVariables["var_UseImageButtons"], settings.general.useImageButtons);
    imgui.SetVarValue(uiVariables["var_EnableSoundAlerts"], settings.general.enableSoundAlerts);
    imgui.SetVarValue(uiVariables["var_AutoGenReports"], settings.general.autoGenReports);
    syncScaleTuningVarsFromSettings();

    local r, g, b, a = colorToRGBA(settings.general.yieldDetailsColor);
    imgui.SetVarValue(uiVariables["var_YieldDetailsColor"], r/255, g/255, b/255, a/255);
    local vr, vg, vb, va = imgui.GetVarValue(uiVariables["var_YieldDetailsColor"]);
    writeDebugLog(string.format('loadUiVariables general_color int=%s rgba=(%s,%s,%s,%s) var=(%s,%s,%s,%s)',
        tostring(settings.general.yieldDetailsColor), tostring(r), tostring(g), tostring(b), tostring(a),
        tostring(vr), tostring(vg), tostring(vb), tostring(va)));

    for gathering, yields in pairs(settings.yields) do -- per yield
        local loadedCount = 0;
        local sampleLogged = false;
        for yield, data in pairs(yields) do
            local priceVar = string.format("var_%s_%s_prices", gathering, yield);
            local colorVar = string.format("var_%s_%s_color", gathering, yield);
            local soundIndexVar = string.format("var_%s_%s_soundIndex", gathering, yield);
            local soundFileVar = string.format("var_%s_%s_soundFile", gathering, yield);

            -- Create variables if they don't exist
            if not uiVariables[priceVar] then uiVariables[priceVar] = { 0, 0, 0 }; end
            if not uiVariables[colorVar] then uiVariables[colorVar] = { 1.0, 1.0, 1.0, 1.0 }; end
            if not uiVariables[soundIndexVar] then uiVariables[soundIndexVar] = { 0 }; end
            if not uiVariables[soundFileVar] then uiVariables[soundFileVar] = { '' }; end

            local npcPrice = tonumber(data.npcPrice);
            if npcPrice == nil then
                npcPrice = tonumber(basePrices[data.id]) or 0;
                data.npcPrice = npcPrice;
            end
            imgui.SetVarValue(uiVariables[priceVar], data.singlePrice, data.stackPrice, npcPrice);
            local r, g, b, a = colorToRGBA(data.color);
            imgui.SetVarValue(uiVariables[colorVar], r/255, g/255, b/255, a/255);
            if not sampleLogged then
                local cr, cg, cb, ca = imgui.GetVarValue(uiVariables[colorVar]);
                writeDebugLog(string.format('loadUiVariables color_sample gather=%s item=%s int=%s rgba=(%s,%s,%s,%s) var=(%s,%s,%s,%s)',
                    tostring(gathering), tostring(yield), tostring(data.color),
                    tostring(r), tostring(g), tostring(b), tostring(a),
                    tostring(cr), tostring(cg), tostring(cb), tostring(ca)));
                sampleLogged = true;
            end
            loadedCount = loadedCount + 1;
            -- re-index for file changes
            local soundIndex = getSoundIndex(data.soundFile);
            imgui.SetVarValue(uiVariables[soundIndexVar], soundIndex);
            local soundFile = sounds[soundIndex];
            imgui.SetVarValue(uiVariables[soundFileVar], soundFile);
        end
        -- per gathering
        local priceModeVar = string.format("var_%s_priceMode", gathering);
        if not uiVariables[priceModeVar] then uiVariables[priceModeVar] = { false }; end
        imgui.SetVarValue(uiVariables[priceModeVar], settings.priceModes[gathering]);
        writeDebugLog(string.format('loadUiVariables: gather=%s loaded_colors=%d', tostring(gathering), loadedCount));
    end

    for gathering, data in pairs(metrics) do -- per metric
        imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", gathering)], data.estimatedValue);
    end

    -- target sound file
    local soundIndex = getSoundIndex(settings.general.targetSoundFile);
    imgui.SetVarValue(uiVariables["var_TargetSoundIndex"], soundIndex);
    local soundFile = sounds[soundIndex];
    imgui.SetVarValue(uiVariables["var_TargetSoundFile"], soundFile);

    -- fishing skill sound file
    soundIndex = getSoundIndex(settings.general.fishingSkillSoundFile);
    imgui.SetVarValue(uiVariables["var_FishingSkillSoundIndex"], soundIndex);
    soundFile = sounds[soundIndex];
    imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"], soundFile);

    -- clam break sound file
    soundIndex = getSoundIndex(settings.general.clamBreakSoundFile);
    imgui.SetVarValue(uiVariables["var_ClamBreakSoundIndex"], soundIndex);
    soundFile = sounds[soundIndex];
    imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"], soundFile);

    -- All colors
    syncAllColorsVarForGather(state.settings.setColors.gathering or state.gathering, "loadUiVariables");

    -- Report read-pane text scale (UI-only; not persisted).
    local reportScale = tonumber(imgui.GetVarValue(uiVariables["var_ReportFontScale"])) or 1.0;
    if reportScale < 1.0 then reportScale = 1.0; end
    if reportScale > 1.5 then reportScale = 1.5; end
    imgui.SetVarValue(uiVariables["var_ReportFontScale"], reportScale);

    for gathering, defs in pairs(eventAlertDefs) do
        for _, def in ipairs(defs) do
            syncAlertEventVars(gathering, def.key);
        end
    end
    writeDebugLog('loadUiVariables: end');
end

----------------------------------------------------------------------------------------------------
-- func: updatePlotPoints
-- desc: Update the display of all plots every second.
----------------------------------------------------------------------------------------------------
function updatePlotPoints()
    if state.timers[state.gathering] then
        local gather = state.gathering;
        local metric = metrics[gather];
        if metric == nil then
            return;
        end

        local totalSecs = tonumber(metric.secondsPassed) or 0;
        local newSecs = totalSecs + 1;
        metric.secondsPassed = newSecs;

        local pointsWindowMax = 60; -- one minute of rendered points
        local timeSpan = 3600;
        local elapsed = math.max(1, tonumber(metric.secondsPassed) or 1);
        local curYields = tonumber(metric.totals and metric.totals.yields) or 0;
        local curValue = tonumber(metric.estimatedValue) or 0;
        local yieldsOverTime = curYields * (timeSpan / elapsed);
        local valueOverTime = curValue * (timeSpan / elapsed);

        metric.points = metric.points or { yields = { 0 }, values = { 0 } };
        metric.points.yields = metric.points.yields or { 0 };
        metric.points.values = metric.points.values or { 0 };
        table.insert(metric.points.yields, yieldsOverTime);
        table.insert(metric.points.values, valueOverTime);
        while #metric.points.yields > pointsWindowMax do
            table.remove(metric.points.yields, 1);
        end
        while #metric.points.values > pointsWindowMax do
            table.remove(metric.points.values, 1);
        end
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
            local player = AshitaCore:GetMemoryManager():GetPlayer();
            if player and player:HasKeyItem(data.toolId) then
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
    if settings.yields[gatherType] == nil then
        writeDebugLog(string.format('WARN getPrice missing gather settings: %s', tostring(gatherType)));
        return 0;
    end

    local data = settings.yields[gatherType][itemName];
    if data == nil then
        writeDebugLog(string.format('WARN getPrice missing item settings: gather=%s item=%s', tostring(gatherType), tostring(itemName)));
        return 0;
    end

    local singlePrice = tonumber(data.singlePrice) or 0;
    local stackPrice = tonumber(data.stackPrice) or 0;
    local stackSize = tonumber(data.stackSize) or 0;
    local npcPrice = tonumber(data.npcPrice);
    if npcPrice == nil then
        npcPrice = tonumber(basePrices[data.id]) or 0;
        data.npcPrice = npcPrice;
    end

    local price = 0;
    -- Priority: stack -> single -> npc -> 0.
    if stackPrice > 0 then
        if stackSize > 0 then
            price = stackPrice / stackSize;
        else
            -- Fallback when stack size metadata is missing/invalid.
            price = stackPrice;
        end
    elseif singlePrice > 0 then
        price = singlePrice;
    elseif npcPrice > 0 then
        price = npcPrice;
    else
        price = 0;
    end
    return math.floor(tonumber(price) or 0);
end

local function recalculateEstimatedValueForGathering(gathering)
    local gatherName = tostring(gathering or "");
    if gatherName == "" then
        writeDebugLog('recalculate_estimated skipped: missing gathering');
        return false, 0, 0;
    end

    local gatherMetrics = metrics[gatherName];
    if gatherMetrics == nil then
        writeDebugLog(string.format('recalculate_estimated skipped: missing metrics for %s', gatherName));
        return false, 0, 0;
    end

    gatherMetrics.yields = gatherMetrics.yields or {};
    local trackedRows = 0;
    local estimatedValue = 0;
    for yieldName, count in pairs(gatherMetrics.yields) do
        local qty = tonumber(count) or 0;
        if qty > 0 then
            trackedRows = trackedRows + 1;
            estimatedValue = estimatedValue + (getPrice(yieldName, gatherName) * qty);
        end
    end

    gatherMetrics.estimatedValue = math.max(0, math.floor(tonumber(estimatedValue) or 0));
    local estVarName = string.format("var_%s_estimatedValue", gatherName);
    if uiVariables[estVarName] ~= nil then
        imgui.SetVarValue(uiVariables[estVarName], gatherMetrics.estimatedValue);
    end

    writeDebugLog(string.format('recalculate_estimated gather=%s tracked=%d value=%d',
        gatherName, tonumber(trackedRows) or 0, tonumber(gatherMetrics.estimatedValue) or 0));
    return true, trackedRows, gatherMetrics.estimatedValue;
end

local function getSortedYieldNames(gathering)
    local names = {};
    if settings == nil or settings.yields == nil or settings.yields[gathering] == nil then
        return names;
    end
    for yieldName, _ in pairs(settings.yields[gathering]) do
        names[#names + 1] = yieldName;
    end
    table.sort(names, function(a, b)
        return tostring(a) < tostring(b);
    end);
    return names;
end

local function seedFakeYieldsForGather(gathering, gatherIndex)
    if gathering == nil then
        return 0, 0, 0;
    end
    metrics[gathering] = metrics[gathering] or table.copy(metricsTemplate);
    metrics[gathering].totals = metrics[gathering].totals or table.copy(metricsTemplate.totals);
    metrics[gathering].points = metrics[gathering].points or table.copy(metricsTemplate.points);
    metrics[gathering].yields = {};

    local yieldNames = getSortedYieldNames(gathering);
    local take = math.min(#yieldNames, 8);
    local totalYields = 0;
    local estimatedValue = 0;

    for i = 1, take do
        local yieldName = yieldNames[i];
        local count = ((tonumber(gatherIndex) or 1) * 2) + i;
        metrics[gathering].yields[yieldName] = count;
        totalYields = totalYields + count;
        estimatedValue = estimatedValue + (getPrice(yieldName, gathering) * count);
    end

    metrics[gathering].totals.yields = totalYields;
    metrics[gathering].totals.attempts = totalYields + math.max(8, take);
    metrics[gathering].totals.breaks = math.max(0, math.floor(take / 2));
    metrics[gathering].totals.lost = math.max(0, math.floor(take / 3));
    metrics[gathering].estimatedValue = estimatedValue;
    metrics[gathering].secondsPassed = math.max(120, totalYields * 8);
    metrics[gathering].points.yields = { math.max(1, totalYields * 2) };
    metrics[gathering].points.values = { math.max(0, estimatedValue * 2) };

    local estimatedVarName = string.format("var_%s_estimatedValue", gathering);
    if uiVariables[estimatedVarName] ~= nil then
        imgui.SetVarValue(uiVariables[estimatedVarName], estimatedValue);
    end

    return take, totalYields, estimatedValue;
end

local function seedFakeYieldsAllGatherings()
    local seededGatherCount = 0;
    local seededItemRows = 0;
    for i, data in ipairs(gatherTypes) do
        local gathering = data and data.name or nil;
        local rowCount = 0;
        local totalYields = 0;
        local est = 0;
        rowCount, totalYields, est = seedFakeYieldsForGather(gathering, i);
        if rowCount > 0 then
            seededGatherCount = seededGatherCount + 1;
            seededItemRows = seededItemRows + rowCount;
            writeDebugLog(string.format('seed_fake gather=%s rows=%d total=%d value=%d',
                tostring(gathering), tonumber(rowCount) or 0, tonumber(totalYields) or 0, tonumber(est) or 0));
        end
    end
    checkTargetAlertReady();
    trySaveSettings('seed_fake_yields', true);
    return seededGatherCount, seededItemRows;
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
    writeDebugLog(string.format('adjYield gather=%s item=%s delta=%d total=%d', tostring(state.gathering), tostring(yieldName), tonumber(val) or 0, tonumber(metrics[state.gathering].yields[yieldName]) or 0));
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
        for i = 0, ashitaInventory:GetContainerCountMax(containerId), 1 do -- check containers
            local entry = ashitaInventory:GetContainerItem(containerId, i);
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
        for i = 0, ashitaInventory:GetContainerCountMax(containerId), 1 do -- check containers
            local entry = ashitaInventory:GetContainerItem(containerId, i);
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
        for i = 0, ashitaInventory:GetContainerCountMax(containerId), 1 do -- check containers
            local entry = ashitaInventory:GetContainerItem(containerId, i);
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
    local total = 0;
    local available = 0;
    for _, containerId in pairs(containers) do
        local slotCount = tonumber(ashitaInventory:GetContainerCountMax(containerId)) or 0;
        local lastIndex = slotCount - 1;
        local used = 0;
        total = total + slotCount;
        for i = 0, lastIndex, 1 do
            local entry = ashitaInventory:GetContainerItem(containerId, i);
            if entry then
                if entry.Id > 0 and entry.Id < 65535 then
                    used = used + 1;
                end
            end
        end
        available = available + (slotCount - used);
    end
    local pct = 0;
    if total > 0 then
        pct = math.floor(available / total * 100);
    end
    return available, pct; -- pct
end

----------------------------------------------------------------------------------------------------
-- func: sortKeysByTotalValue
-- desc: Sort yields based on their total value.
----------------------------------------------------------------------------------------------------
function table.sortKeysByTotalValue(t, desc)
    if type(t) ~= 'table' then
        return {};
    end
    local ret = {}
    for k, v in pairs(t) do
        table.insert(ret, k)
    end
    local totalA = function(a, b) return math.floor(getPrice(a) * (tonumber(metrics[state.gathering].yields[a]) or 0)); end;
    local totalB = function(a, b) return math.floor(getPrice(b) * (tonumber(metrics[state.gathering].yields[b]) or 0)); end;
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
    if newState == nil then
        return;
    end

    if metrics[newState] == nil then
        metrics[newState] = table.copy(metricsTemplate);
        writeDebugLog(string.format('WARN updateAllStates initialized missing metrics for: %s', tostring(newState)));
    end

    metrics[newState].totals = metrics[newState].totals or table.copy(metricsTemplate.totals);
    metrics[newState].points = metrics[newState].points or table.copy(metricsTemplate.points);
    metrics[newState].points.yields = metrics[newState].points.yields or { 0 };
    metrics[newState].points.values = metrics[newState].points.values or { 0 };
    metrics[newState].yields = metrics[newState].yields or {};
    metrics[newState].estimatedValue = tonumber(metrics[newState].estimatedValue) or 0;
    metrics[newState].secondsPassed = tonumber(metrics[newState].secondsPassed) or 0;

    settings.zones[newState] = settings.zones[newState] or {};
    state.timers[newState] = state.timers[newState] or false;

    local estVarName = string.format("var_%s_estimatedValue", newState);
    uiVariables[estVarName] = uiVariables[estVarName] or { 0 };

    state.gathering = newState;
    state.settings.setPrices.gathering = newState;
    state.settings.setColors.gathering = newState;
    state.settings.setAlerts.gathering = newState;
    state.settings.reports.gathering = newState;
    writeDebugLog(string.format('updateAllStates -> %s', tostring(newState)));
end

----------------------------------------------------------------------------------------------------
-- func: getSoundOptions
-- desc: Obtain a formatted string of sound options used for sound selection drop-downs.
----------------------------------------------------------------------------------------------------
function getSoundOptions()
    local options = "None\0";
    for i = 1, #sounds do
        local file = sounds[i];
        if file ~= nil and file ~= "" then
            options = options..file.."\0";
        end
    end
    return options.."\0";
end

----------------------------------------------------------------------------------------------------
-- func: alertYield
-- desc: Play the user set sound for the given yield if alerts are enabled.
----------------------------------------------------------------------------------------------------
function alertYield(yieldName)
    if settings.yields == nil or settings.yields[state.gathering] == nil then
        return false;
    end
    local yieldData = settings.yields[state.gathering][yieldName];
    if yieldData ~= nil and yieldData.soundFile ~= nil and yieldData.soundFile ~= "" then
        return playAlert(yieldData.soundFile);
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: getPlotRange
-- desc: Compute plot range using zero-baseline and a persistent high-water max.
----------------------------------------------------------------------------------------------------
local function getPlotRange(points, floorMax, plotKey)
    local observedMax = 0.0;
    if type(points) == "table" then
        for _, v in ipairs(points) do
            local n = tonumber(v);
            if n ~= nil and n > observedMax then
                observedMax = n;
            end
        end
    end
    if observedMax <= 0.0 then
        observedMax = tonumber(floorMax) or 1.0;
    end
    if observedMax < 1.0 then
        observedMax = 1.0;
    end

    local highWater = observedMax;
    if plotKey ~= nil and state ~= nil and state.values ~= nil then
        state.values.plotHighWater = state.values.plotHighWater or {};
        local prevHigh = tonumber(state.values.plotHighWater[plotKey]) or 0.0;
        if prevHigh > highWater then
            highWater = prevHigh;
        else
            state.values.plotHighWater[plotKey] = highWater;
        end
    end

    return 0.0, highWater;
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
    if fileName == nil or fileName == "" then
        return 0;
    end
    for i = 1, #sounds do
        local file = sounds[i];
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
    local issuesBaseUrl = "https://github.com/Sjshovan/Ashita-Yield/issues/new";

    local function urlEncode(s)
        local text = tostring(s or "");
        text = text:gsub("\r\n", "\n"):gsub("\r", "\n");
        text = text:gsub("([^%w%-%._~])", function(c)
            return string.format("%%%02X", string.byte(c));
        end);
        return text;
    end

    local gatherName = tostring(state and state.gathering or "unknown");
    local playerName = getPlayerName() or "";
    if playerName == "" then playerName = "unknown"; end
    local addonVersion = tostring((_addon and _addon.version) or "unknown");
    local addonName = tostring((_addon and _addon.name) or "Yield");
    local luaVersion = tostring(_VERSION or "unknown");
    local windowScale = tostring(getWindowScale() or 1.0);
    local ashitaVersion = "unknown";
    local okAshita, ashitaVer = pcall(function()
        if AshitaCore ~= nil and AshitaCore.GetInstallPath ~= nil then
            -- Fallback-friendly marker when explicit version api is unavailable in runtime bindings.
            return tostring(AshitaCore:GetInstallPath());
        end
        return nil;
    end);
    if okAshita and ashitaVer ~= nil and ashitaVer ~= "" then
        ashitaVersion = tostring(ashitaVer);
    end
    local appContext = {
        "",
        "---",
        "### Environment",
        string.format("- Addon: %s", addonName),
        string.format("- Addon Version: %s", addonVersion),
        string.format("- Branch/Release: %s", addonVersion),
        string.format("- Ashita Runtime: %s", ashitaVersion),
        string.format("- Lua: %s", luaVersion),
        string.format("- Gathering Type: %s", gatherName),
        string.format("- Window Scale: %s", windowScale),
        string.format("- Character: %s", playerName),
        string.format("- Local Time: %s", os.date('%Y-%m-%d %H:%M:%S')),
    };
    local contextText = table.concat(appContext, "\n");

    local safeTitle = tostring(title or ""):gsub("^%s+", ""):gsub("%s+$", "");
    local safeBody = tostring(body or ""):gsub("^%s+", ""):gsub("%s+$", "");
    local fullBody = string.format("%s\n\n%s", safeBody, contextText);

    -- Keep URL length under practical browser limits.
    local maxBodyLen = 6000;
    if #fullBody > maxBodyLen then
        fullBody = string.sub(fullBody, 1, maxBodyLen) .. "\n\n[truncated]";
    end

    local targetUrl = string.format("%s?title=%s&body=%s", issuesBaseUrl, urlEncode(safeTitle), urlEncode(fullBody));
    writeDebugLog(string.format('sendIssue open_url title_len=%d body_len=%d', #safeTitle, #fullBody));
    ashita.misc.open_url(targetUrl);
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
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

----------------------------------------------------------------------------------------------------
-- func: writeDebugLog
-- desc: Write debug output to file for troubleshooting.
----------------------------------------------------------------------------------------------------
function writeDebugLog(message)
    local logDir = string.format('%slogs\\', _addon.path);
    if not ashita.fs.exists(logDir) then
        ashita.fs.create_dir(logDir);
    end

    local logFile = string.format('%syield_debug.log', logDir);
    local file = io.open(logFile, 'a+');
    if file ~= nil then
        file:write(string.format('[%s] %s\n', os.date('%Y-%m-%d %H:%M:%S'), tostring(message)));
        file:close();
    end
end

----------------------------------------------------------------------------------------------------
-- func: trySaveSettings
-- desc: Save settings safely and log errors instead of hard-crashing.
----------------------------------------------------------------------------------------------------
function trySaveSettings(context, suppressChat)
    local ok, err = pcall(saveSettings);
    if not ok then
        writeDebugLog(string.format('ERROR saveSettings (%s): %s', context or 'unknown', tostring(err)));
        writeDebugLog(debug.traceback());
        if not suppressChat then
            displayResponse('Yield: Failed to save settings. See logs\\yield_debug.log for details.', "\31\167%s");
        end
    end
    return ok;
end

----------------------------------------------------------------------------------------------------
-- func: formatElapsedTime
-- desc: Format elapsed seconds as HH:MM:SS.
----------------------------------------------------------------------------------------------------
function formatElapsedTime(totalSeconds)
    local secs = math.max(0, math.floor(tonumber(totalSeconds) or 0));
    local hours = math.floor(secs / 3600);
    local minutes = math.floor((secs % 3600) / 60);
    local seconds = secs % 60;
    return string.format('%02d:%02d:%02d', hours, minutes, seconds);
end

----------------------------------------------------------------------------------------------------
-- func: queueAddonCommand
-- desc: Safely queue an addon command.
----------------------------------------------------------------------------------------------------
function queueAddonCommand(command)
    local cm = AshitaCore and AshitaCore.GetChatManager and AshitaCore:GetChatManager() or nil;
    if cm and cm.QueueCommand then
        local attempts = {
            function() cm:QueueCommand(1, command); end,
            function() cm:QueueCommand(command, 1); end,
            function() cm:QueueCommand(-1, command); end,
            function() cm:QueueCommand(-1, 1, command); end,
        };
        for i, fn in ipairs(attempts) do
            local ok, err = pcall(fn);
            if ok then
                writeDebugLog(string.format('queueAddonCommand ok attempt=%d cmd=%s', tonumber(i) or 0, tostring(command)));
                return true;
            end
            writeDebugLog(string.format('queueAddonCommand attempt=%d failed cmd=%s err=%s', tonumber(i) or 0, tostring(command), tostring(err)));
        end
        writeDebugLog(string.format('queueAddonCommand failed (all signatures) cmd=%s', tostring(command)));
        return false;
    end
    writeDebugLog(string.format('queueAddonCommand failed (chat manager unavailable): %s', tostring(command)));
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: runSafe
-- desc: Execute a callback with error logging.
----------------------------------------------------------------------------------------------------
function runSafe(context, callback)
    local ok, err = pcall(callback);
    if not ok then
        writeDebugLog(string.format('ERROR %s: %s', tostring(context), tostring(err)));
        writeDebugLog(debug.traceback());
    end
    return ok;
end

local function openConfirmModal(actionText, helpText, danger, confirmAction, cancelAction)
    state.actions.modalConfirmAction = type(confirmAction) == 'function' and confirmAction or function() end;
    state.actions.modalCancelAction = type(cancelAction) == 'function' and cancelAction or function() end;
    state.values.modalConfirmPrompt = string.format(modalConfirmPromptTemplate, tostring(actionText or "continue"));
    state.values.modalConfirmHelp = helpText or "";
    state.values.modalConfirmDanger = danger == true;
    state.values.confirmIgnoreClickAway = true;
    writeDebugLog(string.format('openConfirmModal prompt=%s danger=%s', tostring(state.values.modalConfirmPrompt), tostring(state.values.modalConfirmDanger)));
    -- Defer popup-open to the main render scope that owns BeginPopupModal.
    state.values.openConfirmRequested = true;
end

local function deepEqual(a, b, seen)
    if a == b then
        return true;
    end
    if type(a) ~= type(b) then
        return false;
    end
    if type(a) ~= 'table' then
        return false;
    end
    seen = seen or {};
    if seen[a] and seen[a] == b then
        return true;
    end
    seen[a] = b;
    for k, v in pairs(a) do
        if not deepEqual(v, b[k], seen) then
            return false;
        end
    end
    for k, _ in pairs(b) do
        if a[k] == nil then
            return false;
        end
    end
    return true;
end

local function deepCopy(value, seen)
    if type(value) ~= 'table' then
        return value;
    end
    seen = seen or {};
    if seen[value] ~= nil then
        return seen[value];
    end
    local copy = {};
    seen[value] = copy;
    for k, v in pairs(value) do
        copy[deepCopy(k, seen)] = deepCopy(v, seen);
    end
    return copy;
end

local function setSettingsStatus(text, color, durationSec)
    state.values.settingsStatusText = tostring(text or "");
    state.values.settingsStatusColor = color or { 0.77, 0.83, 0.80, 1.0 };
    state.values.settingsStatusUntil = os.clock() + (tonumber(durationSec) or 2.0);
end

local function serializeSimple(value)
    local t = type(value);
    if t == 'nil' then return 'nil'; end
    if t == 'boolean' then return value and 'true' or 'false'; end
    if t == 'number' then return string.format('%.6f', value); end
    if t == 'string' then return value; end
    if t ~= 'table' then return tostring(value); end
    local parts = {};
    local n = #value;
    for i = 1, n do
        parts[#parts + 1] = serializeSimple(value[i]);
    end
    local keys = {};
    for k, _ in pairs(value) do
        if type(k) ~= 'number' or k < 1 or k > n or math.floor(k) ~= k then
            keys[#keys + 1] = k;
        end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b); end);
    for _, k in ipairs(keys) do
        parts[#parts + 1] = tostring(k) .. '=' .. serializeSimple(value[k]);
    end
    return '{' .. table.concat(parts, ',') .. '}';
end

local function isTrackedSettingsUiVar(name)
    if type(name) ~= 'string' then
        return false;
    end
    if name == "var_WindowOpacity"
        or name == "var_TargetValue"
        or name == "var_ShowToolTips"
        or name == "var_WindowScale"
        or name == "var_WindowScalePct"
        or name == "var_ShowDetailedYields"
        or name == "var_UseImageButtons"
        or name == "var_EnableSoundAlerts"
        or name == "var_AutoGenReports"
        or name == "var_YieldDetailsColor"
        or name == "var_TargetSoundIndex"
        or name == "var_TargetSoundFile"
        or name == "var_FishingSkillSoundIndex"
        or name == "var_FishingSkillSoundFile"
        or name == "var_ClamBreakSoundIndex"
        or name == "var_ClamBreakSoundFile"
        or name == "var_TextScaleBase"
        or name == "var_TextScaleFactor"
        or name == "var_MetricsTextScaleBase"
        or name == "var_MetricsTextScaleFactor"
        or name == "var_ButtonTextScaleBase"
        or name == "var_ButtonTextScaleFactor"
        or name == "var_ButtonSizeXBase"
        or name == "var_ButtonSizeXFactor"
        or name == "var_ButtonSizeYBase"
        or name == "var_ButtonSizeYFactor"
        or name == "var_WindowXScaleBase"
        or name == "var_WindowXScaleFactor"
        or name == "var_WindowYScaleBase"
        or name == "var_WindowYScaleFactor" then
        return true;
    end
    if string.match(name, '^var_.+_.+_prices$') then return true; end
    if string.match(name, '^var_.+_.+_color$') then return true; end
    if string.match(name, '^var_.+_.+_soundIndex$') then return true; end
    if string.match(name, '^var_.+_.+_soundFile$') then return true; end
    if string.match(name, '^var_.+_.+_eventSoundIndex$') then return true; end
    if string.match(name, '^var_.+_.+_eventSoundFile$') then return true; end
    return false;
end

local function buildSettingsUiFingerprint()
    local keys = {};
    for k, _ in pairs(uiVariables or {}) do
        if isTrackedSettingsUiVar(k) then
            keys[#keys + 1] = k;
        end
    end
    table.sort(keys);
    local parts = {};
    for _, k in ipairs(keys) do
        parts[#parts + 1] = k .. '=' .. serializeSimple(uiVariables[k]);
    end
    return table.concat(parts, '|');
end

local function commitSettingsSnapshot()
    state.values.settingsSnapshot = deepCopy(settings);
    state.values.settingsUiSnapshotFingerprint = buildSettingsUiFingerprint();
end

local function clearTransientSettingsSelections()
    state.values.colorSelectionsByGather = {};
    state.values.soundSelectionsByGather = {};
    state.values.reportSelectionsByGather = {};
end

local function hasPendingSettingsChanges()
    local snap = state.values.settingsSnapshot;
    if type(snap) ~= 'table' then
        return true;
    end
    return not deepEqual(settings, snap);
end

local function applyGeneralDefaults()
    settings.general = table.copy(defaultSettingsTemplate.general);
    imgui.SetVarValue(uiVariables["var_WindowOpacity"], settings.general.opacity);
    imgui.SetVarValue(uiVariables["var_TargetValue"], settings.general.targetValue);
    imgui.SetVarValue(uiVariables["var_ShowToolTips"], settings.general.showToolTips);
    syncWindowScaleSettings(settings.general.windowScale or 1.0);
    imgui.SetVarValue(uiVariables["var_ShowDetailedYields"], settings.general.showDetailedYields);
    imgui.SetVarValue(uiVariables["var_UseImageButtons"], settings.general.useImageButtons);
    imgui.SetVarValue(uiVariables["var_EnableSoundAlerts"], true);
    imgui.SetVarValue(uiVariables["var_AutoGenReports"], true);
    local r, g, b, a = colorToRGBA(settings.general.yieldDetailsColor);
    imgui.SetVarValue(uiVariables["var_YieldDetailsColor"], r / 255, g / 255, b / 255, a / 255);
    syncScaleTuningVarsFromSettings();
end

local function applyPricesDefaults(gathering)
    for yield, data in pairs(settings.yields[gathering], true) do
        settings.yields[gathering][yield].singlePrice = 0;
        settings.yields[gathering][yield].stackPrice = 0;
        local defaultNpc = tonumber(basePrices[settings.yields[gathering][yield].id]) or 0;
        settings.yields[gathering][yield].npcPrice = defaultNpc;
        imgui.SetVarValue(uiVariables[string.format("var_%s_%s_prices", gathering, yield)], 0, 0, defaultNpc);
    end
end

local function applyColorsDefaults(gathering)
    for yield, data in pairs(settings.yields[gathering]) do
        local defaultColor = getDefaultYieldColorInt();
        settings.yields[gathering][yield].color = defaultColor;
        local r, g, b, a = getDefaultYieldColorRgba();
        imgui.SetVarValue(uiVariables[string.format("var_%s_%s_color", gathering, yield)], r, g, b, a);
        imgui.SetVarValue(uiVariables["var_AllColors"], r, g, b, a);
    end
    syncGatherYieldColorVars(gathering);
    writeDebugLog(string.format('setColors defaults applied: gather=%s', tostring(gathering)));
end

local function applyAlertsDefaults(gathering)
    for yield, data in pairs(settings.yields[gathering]) do
        settings.yields[gathering][yield].soundIndex = 0;
        imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)], "");
        imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)], 0);
        imgui.SetVarValue(uiVariables["var_AllSoundIndex"], 0);
    end
    if gathering == "fishing" then
        imgui.SetVarValue(uiVariables["var_FishingSkillSoundIndex"], 0);
        imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"], "");
    end
    if gathering == "clamming" then
        imgui.SetVarValue(uiVariables["var_ClamBreakSoundIndex"], 0);
        imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"], "");
    end
    local defs = eventAlertDefs[gathering] or {};
    for _, def in ipairs(defs) do
        setAlertEventSound(gathering, def.key, 0);
    end
end

local function getActiveReportsGathering()
    local rawGathering = state and state.settings and state.settings.reports and state.settings.reports.gathering;
    local gathering = rawGathering;
    if gathering == nil or gathering == "" then
        gathering = state and state.gathering or nil;
    end
    if gathering == nil or gathering == "" then
        gathering = "harvesting";
    end
    if tostring(rawGathering or "") ~= tostring(gathering) then
        writeDebugLog(string.format('reports gathering fallback raw=%s resolved=%s', tostring(rawGathering), tostring(gathering)));
    end
    state.settings = state.settings or {};
    state.settings.reports = state.settings.reports or {};
    state.settings.reports.gathering = gathering;
    reports[gathering] = reports[gathering] or {};
    return gathering;
end

local function generateReportsFromFooter()
    local gathering = getActiveReportsGathering();
    if state.values.genReportDisabled then
        state.values.reportsStatusText = "Generate is on cooldown.";
        return;
    end
    state.values.currentReportName = nil;
    if generateGatheringReport(gathering) then
        refreshReportsForGather(gathering);
        local sortedReports = table.sortReportsByDate(reports[gathering] or {}, true);
        writeDebugLog(string.format('reports post-generate gather=%s sorted_count=%s first=%s',
            tostring(gathering), tostring(#sortedReports), tostring(sortedReports[1])));
        if sortedReports[1] ~= nil then
            imgui.SetVarValue(uiVariables['var_ReportSelected'], 1);
            state.values.currentReportName = sortedReports[1];
            state.values.forceReportListTop = true;
            state.values.reportsStatusText = string.format("Generated: %s", tostring(sortedReports[1]));
            writeDebugLog(string.format('reports auto-select latest gather=%s index=1 file=%s', tostring(gathering), tostring(sortedReports[1])));
        end
        state.values.genReportDisabled = true;
        ashita.timer.once(2000, function()
            state.values.genReportDisabled = false;
        end);
    else
        state.values.reportsStatusText = "Generate failed.";
    end
end

----------------------------------------------------------------------------------------------------
-- func: getColorVarTable
-- desc: Normalize color vars to { r, g, b, a } in 0.0-1.0 range.
----------------------------------------------------------------------------------------------------
function getColorVarTable(var, context)
    if type(var) ~= 'table' then
        writeDebugLog(string.format('WARN invalid color var (%s): %s', tostring(context), type(var)));
        return {1.0, 1.0, 1.0, 1.0};
    end

    if type(var[1]) == 'table' then
        return var[1];
    end

    if type(var[1]) == 'number' and type(var[2]) == 'number' and type(var[3]) == 'number' and type(var[4]) == 'number' then
        return { var[1], var[2], var[3], var[4] };
    end

    writeDebugLog(string.format('WARN malformed color var (%s): v1=%s v2=%s v3=%s v4=%s',
        tostring(context), tostring(var[1]), tostring(var[2]), tostring(var[3]), tostring(var[4])));
    return {1.0, 1.0, 1.0, 1.0};
end

local function getOpaqueYieldDetailsColorFromVar(context)
    local color = getColorVarTable(uiVariables["var_YieldDetailsColor"], context or "var_YieldDetailsColor");
    local r = tonumber(color[1]) or 1.0;
    local g = tonumber(color[2]) or 1.0;
    local b = tonumber(color[3]) or 1.0;

    imgui.SetVarValue(uiVariables["var_YieldDetailsColor"], r, g, b, 1.0);
    return colorTableToInt({ r, g, b, 1.0 }), r, g, b;
end

----------------------------------------------------------------------------------------------------
-- func: getPlayerName
-- desc: Obtain the current players name.
----------------------------------------------------------------------------------------------------
function getPlayerName(lower)
    local name = '';
    if ashitaParty and ashitaParty.GetMemberName then
        name = ashitaParty:GetMemberName(0) or '';
    end
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
    if ashitaParty and ashitaParty.GetMemberZone then
        return ashitaParty:GetMemberZone(0);
    end
    return 0;
end

----------------------------------------------------------------------------------------------------
-- func: getCurrentTargetName
-- desc: Obtain the current target name safely.
----------------------------------------------------------------------------------------------------
function getCurrentTargetName()
    if not ashitaTarget or not ashitaTarget.GetTargetIndex or not ashitaEntity then
        return nil;
    end

    local targetIndex = ashitaTarget:GetTargetIndex(0);
    if not targetIndex or targetIndex == 0 then
        return nil;
    end

    local name = ashitaEntity:GetName(targetIndex);
    if not name or name == '' then
        return nil;
    end

    return name;
end

local function getReportsRootPath()
    return string.format('%sconfig\\%s\\reports', AshitaCore:GetInstallPath(), addon.name);
end

local function getReportsCharPath()
    local playerName = getPlayerName();
    if playerName == "" then
        return nil;
    end
    return string.format('%s\\%s', getReportsRootPath(), playerName);
end

local function getReportsTypePath(gatherType)
    local charPath = getReportsCharPath();
    if charPath == nil or gatherType == nil then
        return nil;
    end
    return string.format('%s\\%s', charPath, gatherType);
end

local function ensureReportsDirectories(gatherType)
    local addonConfigPath = string.format('%sconfig\\%s', AshitaCore:GetInstallPath(), addon.name);
    ashita.fs.create_dir(addonConfigPath);
    ashita.fs.create_dir(getReportsRootPath());
    local charPath = getReportsCharPath();
    if charPath ~= nil then
        ashita.fs.create_dir(charPath);
        if gatherType ~= nil then
            ashita.fs.create_dir(string.format('%s\\%s', charPath, gatherType));
        end
    end
end

local function refreshReportsForGather(gatherType)
    if gatherType == nil then
        return;
    end
    reports[gatherType] = {};
    ensureReportsDirectories(gatherType);
    local dirName = getReportsTypePath(gatherType);
    if dirName == nil then
        writeDebugLog(string.format('refreshReportsForGather skipped: gather=%s (no char path)', tostring(gatherType)));
        return;
    end
    if ashita.fs.exists(dirName) then
        for f in io.popen(string.format("dir \"%s\" /b", dirName)):lines() do
            reports[gatherType][#reports[gatherType] + 1] = f;
        end
    end
    writeDebugLog(string.format('refreshReportsForGather gather=%s count=%d dir=%s', tostring(gatherType), #reports[gatherType], tostring(dirName)));
end

----------------------------------------------------------------------------------------------------
-- func: generateGatheringReport
-- desc: Generate a report file using tracked metrics.
----------------------------------------------------------------------------------------------------
function generateGatheringReport(gatherType)
    if gatherType == nil then gatherType = state.gathering; end
    if getPlayerName() == "" then return false; end
    reports[gatherType] = reports[gatherType] or {};
    writeDebugLog(string.format('generateGatheringReport begin gather=%s', tostring(gatherType)));

    local zones = settings.zones[gatherType] or {};
    local zonesCount = table.count(zones);
    local metricData = metrics[gatherType];
    if metricData == nil then return false; end
    local zoneName = zoneNames[getPlayerZoneId()] or 'Unknown Zone';
    if zonesCount > 0 then -- there has been some activity here.
        zoneName = zoneNames[zones[1]] or zoneName;
        if zonesCount > 1 then zoneName = "Multiple Zones"; end
    end
    zoneName = string.gsub(zoneName, " ", "_");
    local sep = "------------\n";
    local date = os.date('*t');
    local dateTimeStamp = string.format("%.4d_%.2d_%.2d__%.2d_%.2d_%.2d", date.year, date.month, date.day, date.hour, date.min, date.sec);
    local fname = string.format('%s__%s.log', zoneName, dateTimeStamp);
    ensureReportsDirectories(gatherType);
    local dirPath = getReportsTypePath(gatherType);
    if dirPath == nil then
        writeDebugLog(string.format('generateGatheringReport failed gather=%s reason=no_dirPath', tostring(gatherType)));
        return false;
    end
    local fpath = string.format('%s\\%s', dirPath, fname);
    if fileExists(fpath) then
        local suffix = 1;
        while suffix <= 99 do
            local candidate = string.format('%s__%s__%02d.log', zoneName, dateTimeStamp, suffix);
            local candidatePath = string.format('%s\\%s', dirPath, candidate);
            if not fileExists(candidatePath) then
                fname = candidate;
                fpath = candidatePath;
                break;
            end
            suffix = suffix + 1;
        end
    end
    local file = io.open(fpath, 'w+');
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
        for name, val in pairs(metricData.totals) do
            file:write(string.format("\t%s: %s\n", name, val));
        end
        local successRate = metricData.totals.yields/metricData.totals.attempts * 100
        if successRate == math.huge or successRate ~= successRate then successRate = 0.0 end
        if successRate < 0 then successRate = 0.0 end
        file:write(string.format("\tSuccess Rate: %.2f%%\n", successRate, 0, 100));
        file:write(string.format("\tTime Passed: %s\n", formatElapsedTime(metricData.secondsPassed)));
        file:write(string.format("\tEstimated Value: %s\n", metricData.estimatedValue));
        file:write(string.format("\tYields per Hour: %.2f\n", metricData.points.yields[#metricData.points.yields]));
        file:write(string.format("\tValue per Hour: %.2f\n", metricData.points.values[#metricData.points.values]));
        file:write(string.format("\tTarget Value: %s\n", settings.general.targetValue));
        local targetReached = metricData.estimatedValue >= settings.general.targetValue;
        local targetReachedAnswer = "No";
        if targetReached then targetReachedAnswer = "Yes"; end
        file:write(string.format("\tTarget Reached: %s\n", targetReachedAnswer));
        file:write(sep);
        file:write("YIELDS\n");
        file:write(sep);
        local reportYields = metricData.yields or {};
        local hasYieldEntries = false;
        for _, count in pairs(reportYields) do
            if (tonumber(count) or 0) > 0 then
                hasYieldEntries = true;
                break;
            end
        end
        if hasYieldEntries then
            for _, name in ipairs(table.sortbykey(reportYields, false)) do
                local count = tonumber(reportYields[name]) or 0;
                if count > 0 then
                    local unitPrice = getPrice(name, gatherType);
                    file:write(string.format("\t%s: %s @%dea.=(%s)\n", name, count, unitPrice, math.floor(unitPrice * count)));
                end
            end
        else
            file:write("\tNone\n");
        end
        file:close();
        reports[gatherType][#reports[gatherType] + 1] = fname;
        writeDebugLog(string.format('generateGatheringReport success gather=%s file=%s', tostring(gatherType), tostring(fpath)));
        return true;
    end
    writeDebugLog(string.format('generateGatheringReport failed gather=%s file_open=%s', tostring(gatherType), tostring(fpath)));
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: saveSettings
-- desc: Saves the Yield settings file.
----------------------------------------------------------------------------------------------------
function saveSettings()
    writeDebugLog('saveSettings begin');
    ensureAlertEventSettings();
    sanitizeColorSettings();
    -- Obtain the configuration variables..
    settings.general.opacity               = imgui.GetVarValue(uiVariables["var_WindowOpacity"]);
    settings.general.targetValue           = imgui.GetVarValue(uiVariables["var_TargetValue"]);
    settings.general.showToolTips          = imgui.GetVarValue(uiVariables["var_ShowToolTips"]);
    syncWindowScaleSettings(imgui.GetVarValue(uiVariables["var_WindowScale"]));
    settings.general.yieldDetailsColor     = getOpaqueYieldDetailsColorFromVar("saveSettings.var_YieldDetailsColor");
    settings.general.useImageButtons       = imgui.GetVarValue(uiVariables["var_UseImageButtons"]);
    settings.general.enableSoundAlerts     = imgui.GetVarValue(uiVariables["var_EnableSoundAlerts"]);
    settings.general.targetSoundFile       = imgui.GetVarValue(uiVariables["var_TargetSoundFile"]);
    settings.general.fishingSkillSoundFile = imgui.GetVarValue(uiVariables["var_FishingSkillSoundFile"]);
    settings.general.clamBreakSoundFile    = imgui.GetVarValue(uiVariables["var_ClamBreakSoundFile"]);
    settings.general.autoGenReports        = imgui.GetVarValue(uiVariables["var_AutoGenReports"]);
    syncScaleTuningSettingsFromVars();

    for gathering, defs in pairs(eventAlertDefs) do
        settings.alertEvents[gathering] = settings.alertEvents[gathering] or {};
        for _, def in ipairs(defs) do
            local idxVarName, fileVarName = getAlertEventVarNames(gathering, def.key);
            local fileVar = uiVariables[fileVarName];
            if fileVar ~= nil then
                settings.alertEvents[gathering][def.key] = imgui.GetVarValue(fileVar) or "";
            else
                settings.alertEvents[gathering][def.key] = settings.alertEvents[gathering][def.key] or "";
            end
        end
    end

    for gathering, yields in pairs(settings.yields) do
        local savedColorCount = 0;
        local savedZeroColorCount = 0;
        for yield, data in pairs(yields) do
            local yieldSettings = settings.yields[gathering][yield];
            local priceVarName = string.format("var_%s_%s_prices", gathering, yield);
            local colorVarName = string.format("var_%s_%s_color", gathering, yield);
            local soundVarName = string.format("var_%s_%s_soundFile", gathering, yield);

            local priceVar = uiVariables[priceVarName];
            local singlePrice = tonumber(yieldSettings.singlePrice) or 0;
            local stackPrice  = tonumber(yieldSettings.stackPrice) or 0;
            local npcPrice    = tonumber(yieldSettings.npcPrice) or tonumber(basePrices[yieldSettings.id]) or 0;
            if priceVar ~= nil then
                local vSingle, vStack, vNpc = imgui.GetVarValue(priceVar);
                if vSingle ~= nil then singlePrice = tonumber(vSingle) or singlePrice; end
                if vStack ~= nil then stackPrice = tonumber(vStack) or stackPrice; end
                if vNpc ~= nil then npcPrice = tonumber(vNpc) or npcPrice; end
            else
                -- Keep existing stored values when this row did not initialize a UI var yet.
                writeDebugLog(string.format('saveSettings missing price var: %s (preserving existing values)', priceVarName));
            end
            yieldSettings.singlePrice = singlePrice;
            yieldSettings.stackPrice  = stackPrice;
            yieldSettings.npcPrice    = npcPrice;

            local colorVar = uiVariables[colorVarName];
            if colorVar ~= nil then
                -- Do not blindly overwrite color from UI vars at save-time.
                -- Set Colors updates settings.yields[..].color live; preserve that as source of truth.
                if yieldSettings.color == nil then
                    local converted = applyYieldColorFromVar(gathering, yield);
                    if converted ~= nil then
                        yieldSettings.color = converted;
                    end
                end
                if yieldSettings.color == 0 then
                    savedZeroColorCount = savedZeroColorCount + 1;
                end
                savedColorCount = savedColorCount + 1;
            else
                writeDebugLog(string.format('saveSettings missing color var: %s', colorVarName));
            end

            local soundVar = uiVariables[soundVarName];
            if soundVar ~= nil then
                yieldSettings.soundFile = imgui.GetVarValue(soundVar);
            else
                writeDebugLog(string.format('saveSettings missing sound var: %s', soundVarName));
            end
        end
        settings.priceModes[gathering] = imgui.GetVarValue(uiVariables[string.format("var_%s_priceMode", gathering)]);
        writeDebugLog(string.format('saveSettings: gather=%s saved_colors=%d zero_colors=%d', tostring(gathering), savedColorCount, savedZeroColorCount));
    end

    for _, data in ipairs(gatherTypes) do
        metrics[data.name].estimatedValue = tonumber(imgui.GetVarValue(uiVariables[string.format("var_%s_estimatedValue", data.name)]))
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
    if settings_lib and settings_lib.save then
        settings_lib.save();
    elseif settings and settings.save then
        settings.save();
    else
        error('settings save function is unavailable.');
    end
    writeDebugLog('saveSettings end');
end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Called when the addon is loaded.
----------------------------------------------------------------------------------------------------
ashita.events.register('load', 'yield_load', function()
    state.initializing = true
    writeDebugLog('===== Yield session start =====');

    -- Initialize imgui-dependent variables
    defaultFontSize = imgui.GetFontSize();

    -- Ensure the settings folder exists..
    ensureReportsDirectories();

    -- Settings already loaded at top of file
    ensureAlertEventSettings();
    settings.general.windowScale = clampWindowScale(settings.general.windowScale or windowScales[settings.general.windowScaleIndex] or 1.0);
    settings.general.windowScaleIndex = nearestWindowScaleIndex(settings.general.windowScale);
    ensureScaleTuningSettings();
    sanitizeColorSettings();

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
        uiVariables[string.format("var_%s_estimatedValue", data.name)] = { 0 }
        -- Add textures..
        local texturePath = string.format('images/%s.png', data.name)
        local fullPath = addon.path .. texturePath;
        local texture = nil;

        -- In v4, textures are loaded via Direct3D FFI
        if ashita.fs.exists(fullPath) then
            texture = LoadTexture(fullPath);
            if texture == nil then
                state.values.btnTextureFailure = true;
                displayResponse(string.format("Yield: Failed to load texture (%s). Buttons will now default to text display.", texturePath), "\31\167%s");
                settings.general.useImageButtons = false;
            end
        else
            state.values.btnTextureFailure = true;
            displayResponse(string.format("Yield: Failed to load texture (%s). Buttons will now default to text display.", texturePath), "\31\167%s");
            settings.general.useImageButtons = false;
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
            uiVariables[string.format("var_%s_%s_prices", gathering, yield)] = { 0, 0, 0 };
            uiVariables[string.format("var_%s_%s_color", gathering, yield)] = { 1.0, 1.0, 1.0, 1.0 };
            uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)] = { '' };
            uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)] = { 0 };
        end
        -- per gathering
        uiVariables[string.format("var_%s_priceMode", gathering)] = { false };
    end

    -- Retrieve sounds files..
    for f in io.popen(string.format('dir "%s\\sounds" /b', _addon.path)):lines() do
        sounds[#sounds + 1] = f;
    end

    -- Retrieve reports..
    for _, data in ipairs(gatherTypes) do
        if not table.haskey(reports, data.name) then reports[data.name] = {}; end
        if getPlayerName() ~= "" then
            refreshReportsForGather(data.name);
            state.reportsLoaded = true;
        end
    end

    -- Create timers..
    if ashita.timer.create('updatePlotPoints', 1, 0, updatePlotPoints) then
        ashita.timer.start('updatePlotPoints')
    end
    if ashita.timer.create('updatePlayerStorage', 1, 0, updatePlayerStorage) then
        ashita.timer.start('updatePlayerStorage')
    end

    if ashita.timer.create('inactivityCheck', 1, 0, function()
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
    end) then
        ashita.timer.start('inactivityCheck')
    end

    -- Load ui variables from the settings file..
    loadUiVariables();

    if state.firstLoad then
        imgui.SetVarValue(uiVariables["var_HelpVisible"], true);
    end
end)

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.events.register('unload', 'yield_unload', function()
    writeDebugLog('unload begin');

    -- Save the settings file..
    local saveOk = trySaveSettings('unload', true);
    writeDebugLog(string.format('unload save complete ok=%s', tostring(saveOk)));

    -- Remove timers..
    pcall(function() ashita.timer.remove('updatePlotPoints'); end);
    pcall(function() ashita.timer.remove('updatePlayerStorage'); end);
    pcall(function() ashita.timer.remove('inactivityCheck'); end);

    writeDebugLog('unload end');
end)

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when the addon is handling a command.
---------------------------------------------------------------------------------------------------
ashita.events.register('command', 'yield_command', function(e)
    local commandArgs = e.command:lower():args();

    if not table.hasvalue(_addon.commands, commandArgs[1]) then
        return;
    end

    e.blocked = true;

    local responseMessage = "";
    local success = true;

    if commandArgs[2] == 'reload' or commandArgs[2] == 'r' then
        queueAddonCommand('/addon reload yield');

    elseif commandArgs[2] == 'unload' or commandArgs[2] == 'u' then
        responseMessage = 'Thank you for using Yield. Goodbye.';
        queueAddonCommand('/addon unload yield');

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
        state.window.posX = 0;
        state.window.posY = 0;
        state.initializing = true;
    elseif commandArgs[2] == 'fake' or commandArgs[2] == 'seed' then
        local gatherCount, itemRows = seedFakeYieldsAllGatherings();
        responseMessage = string.format('Seeded fake yields for %d gathering types (%d yield rows).', tonumber(gatherCount) or 0, tonumber(itemRows) or 0);
        success = (gatherCount > 0);
    else
        displayHelp(helpTable.commands);
    end

    if responseMessage ~= "" then
        displayResponse(
            commandResponse(responseMessage, success)
        );
    end
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.events.register('text_in', 'yield_text_in', function(e)
    if (e.blocked) then state.attempting = false; return; end

    -- Keep filtering while idle, but do not drop active gather attempts on non-standard server modes.
    local mode = bit.band(e.mode or 0, 0x000000FF);
    local acceptedModes = {919, 654, 702, 662, 664, 129};
    if not state.attempting and not table.hasvalue(acceptedModes, e.mode) and not table.hasvalue(acceptedModes, mode) then
        return;
    end

    -- Remove colors form message..
    local message = string.strip_colors(e.message);
    message = string.lower(message);
    if state.attempting then
        writeDebugLog(string.format('text_in attempting=true mode=%s gather=%s message=%s', tostring(e.mode), tostring(state.gathering), tostring(message)));
    end

    -- Ensure we care..
    if not state.attempting then
        if state.values.lastKnownGathering == "fishing" then -- play alert on skill-up
            local skillup = string.contains(message, string.format("%s's fishing skill rises", getPlayerName(true)))
            if skillup then
                playAlert(imgui.GetVarValue(uiVariables["var_FishingSkillSoundFile"]));
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
                trySaveSettings('text_in_clam_bucket');
            end
        end
        return;
    end

    -- Ensure correct state..
    updateAllStates(state.attemptType);

    -- Check the attempt.
    if state.attempting then
        local ok, err = pcall(function()
        if not state.timers[state.gathering] then
            state.timers[state.gathering] = true
        end

        local val = 0;
        local success = false;
        local successBreak = false;
        local unable = false;
        local broken = false;
        local full = false;
        local lost = false;

        local gatherData = getGatherTypeData(state.gathering);
        if gatherData == nil then
            writeDebugLog(string.format('ERROR missing gatherData for state.gathering=%s attemptType=%s', tostring(state.gathering), tostring(state.attemptType)));
            state.attempting = false;
            return;
        end
        if gatherData.name == "digging" then
            successBreak = false;
            success = string.match(message, "obtained: (.*).") or false;
            unable = string.contains(message, "you dig, but find nothing.");
            broken = false;
            lost = false;
        elseif gatherData.name == "fishing" then
            local playerName = getPlayerName(true);
            successBreak = false;
            success = string.match(message, string.format("^%s %s a (.*)!$", playerName, gatherData.action))
                or string.match(message, string.format("^%s %s an (.*)!$", playerName, gatherData.action))
                or string.match(message, "^you caught a (.*)!$")
                or string.match(message, "^you caught an (.*)!$")
                or string.match(message, "^you catch a (.*)!$")
                or string.match(message, "^you catch an (.*)!$")
                or false;
            unable = string.contains(message, "you didn't catch anything.") or string.contains(message, "you give up");
            broken = string.contains(message, "your rod breaks.");
            lost = string.contains(message, "you lost your catch") or string.contains(message, "your line breaks.") or string.contains(message, "but cannot carry any more items.");
        elseif gatherData.name == "clamming" then
            successBreak = false;
            success = string.match(message, string.format("^you %s a (.*) and toss it into your bucket.", gatherData.action))
                or string.match(message, string.format("^you %s an (.*) and toss it into your bucket.", gatherData.action));
            unable = string.contains(message, "with a broken bucket!");
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
                imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)], metrics[state.gathering].estimatedValue);
                playAlert(imgui.GetVarValue(uiVariables["var_ClamBreakSoundFile"]));
            end
            if broken or unable then
                state.values.clamBucketBroken = true;
                ashita.timer.once(1000, function () -- let plots update a second
                    state.timers[state.gathering] = false;
                end);
                trySaveSettings('text_in_clam_broken');
            end
        else
            successBreak = string.match(message, string.format("^you %s a (.*), but your %s .*", gatherData.action, gatherData.tool))
                or string.match(message, string.format("^you %s an (.*), but your %s .*", gatherData.action, gatherData.tool));
            success = string.match(message, string.format("^you successfully %s a (.*)!$", gatherData.action))
                or string.match(message, string.format("^you successfully %s an (.*)!$", gatherData.action))
                or string.match(message, string.format("^you %s a (.*)%%.$", gatherData.action))
                or string.match(message, string.format("^you %s an (.*)%%.$", gatherData.action))
                or string.match(message, "^obtained: (.*)%.?$")
                or string.match(message, "^you successfully .- a (.*)!$")
                or string.match(message, "^you successfully .- an (.*)!$")
                or string.match(message, "^you .- a (.*)%.$")
                or string.match(message, "^you .- an (.*)%.$")
                or successBreak;
            unable = string.contains(message, "you are unable to") or string.contains(message, "you find nothing");
            broken = string.match(message, "^your (.*) breaks!")
                or string.match(message, "^your (.*) breaks%.")
                or string.contains(message, string.format("but your %s breaks", gatherData.tool))
                or string.contains(message, string.format("but your %s break", gatherData.tool));
            lost = false;
        end

        full = string.contains(message, "you cannot carry any more") or string.contains(message, "your inventory is full");

        if success then
            local successRaw = tostring(success);
            -- Normalize combined yield+break lines:
            -- "you dig up an iron ore, but your pickaxe breaks."
            success = tostring(success)
                :gsub("%s*,%s*but your%s+.-$", "")
                :gsub("%s+but your%s+.-$", "")
                :gsub("[%!%.,]+$", "")
                :gsub("^%s+", "")
                :gsub("%s+$", "");
            local of = string.match(success, "of (.*)");
            if of then success = of end;
            if broken and not successBreak then
                successBreak = success;
            end
            writeDebugLog(string.format(
                'parse_success normalize gather=%s raw="%s" normalized="%s" successBreak=%s broken=%s',
                tostring(state.gathering), tostring(successRaw), tostring(success), tostring(successBreak), tostring(broken)));
        end
        writeDebugLog(string.format('parse_result gather=%s success=%s unable=%s broken=%s lost=%s full=%s',
            tostring(state.gathering), tostring(success), tostring(unable), tostring(broken), tostring(lost), tostring(full)));

        if unable then
            playGatherEventAlert(state.gathering, "no_yield");
        end
        if full then
            playGatherEventAlert(state.gathering, "inventory_full");
        end
        if lost then
            playGatherEventAlert(state.gathering, "yield_lost");
        end

        if success then
            writeDebugLog(string.format('parse_success pre-resolve gather=%s value="%s"', tostring(state.gathering), tostring(success)));
            success = string.lowerToTitle(success);
            local resolvedSuccess = resolveYieldName(state.gathering, success);
            if resolvedSuccess == nil then
                writeDebugLog(string.format('unknown_yield gather=%s parsed=%s', tostring(state.gathering), tostring(success)));
                displayResponse(string.format("Yield: The %s yield name (%s) is unrecognized! Please report this to LoTekkie.", state.gathering, success), "\31\167%s");
                state.attempting = false;
                return false;
            end
            success = resolvedSuccess;
            writeDebugLog(string.format('parse_success resolved gather=%s resolved="%s" break=%s successBreak=%s',
                tostring(state.gathering), tostring(success), tostring(broken), tostring(successBreak)));
            val = getPrice(success);
            adjYield(success, 1);
            if state.gathering == "clamming" then
                state.values.clamBucketPz = state.values.clamBucketPz + settings.yields[state.gathering][success].pz
            end
            local yieldSoundPlayed = alertYield(success);
            if successBreak then
                writeDebugLog(string.format('parse_dual_event gather=%s yield=%s break=true yieldSoundPlayed=%s',
                    tostring(state.gathering), tostring(success), tostring(yieldSoundPlayed)));
                adjTotal("breaks", 1);
                local playBreakAlert = function()
                    if state.gathering == "clamming" then
                        playGatherEventAlert(state.gathering, "bucket_break");
                    else
                        playGatherEventAlert(state.gathering, "tool_break");
                    end
                end
                if yieldSoundPlayed then
                    -- Stagger break sound so success + break are both clearly audible.
                    ashita.timer.once(450, playBreakAlert);
                else
                    playBreakAlert();
                end
            end
            adjTotal("yields", 1);
            writeDebugLog(string.format('parse_success totals gather=%s yields=%s breaks=%s attempts=%s',
                tostring(state.gathering),
                tostring(metrics[state.gathering].totals.yields),
                tostring(metrics[state.gathering].totals.breaks),
                tostring(metrics[state.gathering].totals.attempts)));
        elseif broken then
            writeDebugLog(string.format('parse_break_only gather=%s message="%s"', tostring(state.gathering), tostring(message)));
            adjTotal("breaks", 1);
            if state.gathering == "clamming" then
                playGatherEventAlert(state.gathering, "bucket_break");
            else
                playGatherEventAlert(state.gathering, "tool_break");
            end
        elseif full or lost then
            adjTotal("lost", 1);
        end
        if success or unable or broken or full or lost then
            adjTotal("attempts", 1);
            recordCurrentZone();
            state.values.lastKnownGathering = state.gathering;
            state.attempting = false;
        end
        local curVal = metrics[state.gathering].estimatedValue;
        metrics[state.gathering].estimatedValue = curVal + val;
        imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)], metrics[state.gathering].estimatedValue);
        local targetReached = metrics[state.gathering].estimatedValue >= settings.general.targetValue;
        if state.values.targetAlertReady and targetReached then
            local soundFile = imgui.GetVarValue(uiVariables["var_TargetSoundFile"]);
            playAlert(soundFile);
            state.values.targetAlertReady = false;
        end
        end);
        if not ok then
            writeDebugLog(string.format('ERROR text_in gather attempt: %s', tostring(err)));
            writeDebugLog(debug.traceback());
            state.attempting = false;
        end
    end
end);

----------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Event called when the client is sending a packet to the server.
----------------------------------------------------------------------------------------------------
ashita.events.register('packet_out', 'yield_packet_out', function(e)
    local targetName = getCurrentTargetName();
    if e.id == 0x36 or e.id == 0x01A or e.id == 0x110 then
        writeDebugLog(string.format('packet_out id=0x%03X target=%s attempting=%s gather=%s', e.id, tostring(targetName), tostring(state.attempting), tostring(state.gathering)));
    end

    if e.id == 0x36 then -- helm
        local matched = false;
        for gathering, data in pairs(gatherTypes) do
            if data.target ~= nil and data.target == targetName then
                state.attempting = true;
                state.attemptType = data.name;
                state.gathering = data.name;
                matched = true;
                break;
            end
        end
        if not matched then
            state.attempting = false;
        end
        writeDebugLog(string.format('packet_out_helm matched=%s gather=%s', tostring(matched), tostring(state.gathering)));
    elseif e.id == 0x01A then -- clam
        local player = AshitaCore:GetMemoryManager():GetPlayer();
        if targetName == "Clamming Point" and player and player:HasKeyItem(511) then
            state.attempting = true;
            state.attemptType = "clamming";
            state.gathering = "clamming";
        elseif struct.unpack("H", e.data, 0x0A + 1) == 0x1104 then -- digging
            state.attempting = true;
            state.attemptType = "digging";
            state.gathering = "digging";
        else
            state.attempting = false;
        end
        writeDebugLog(string.format('packet_out_01A attempting=%s attemptType=%s gather=%s', tostring(state.attempting), tostring(state.attemptType), tostring(state.gathering)));
    elseif e.id == 0x110 then -- fishing
        local action = struct.unpack("H", e.data, 0x0E + 1);
        if action ~= 4 then
            state.attempting = true;
            state.attemptType = "fishing";
            state.gathering = "fishing";
        else
            state.attempting = false
        end
        writeDebugLog(string.format('packet_out_fishing action=%s attempting=%s', tostring(action), tostring(state.attempting)));
    end
end);

----------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the client is receiving a packet from the server.
----------------------------------------------------------------------------------------------------
ashita.events.register('packet_in', 'yield_packet_in', function(e)
    if e.id == 0x00B then -- zoning out (11)
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
    elseif (e.id == 0x01D and state.values.zoning) then -- inventory ready
          state.values.zoning = false;
    end
end);

-- The settings window
local SettingsWindow =
{
    modalApplyAction = function (self, context)
        writeDebugLog(string.format('SettingsWindow.modalApplyAction context=%s', tostring(context)));
        updateAllStates(state.gathering);
        if not hasPendingSettingsChanges() then
            setSettingsStatus("No changes to save.", { 1, 1, 0.54, 1.0 }, 2.0);
            return true;
        end
        local ok = trySaveSettings(context or 'settings_apply_button');
        if ok then
            commitSettingsSnapshot();
            clearTransientSettingsSelections();
            setSettingsStatus("Saved settings.", { 0.39, 0.96, 0.13, 1.0 }, 2.0);
            return true;
        end
        setSettingsStatus("Failed to save settings.", { 1.0, 0.615, 0.615, 1.0 }, 3.0);
        return false;
    end,

    modalSaveAction = function (self)
        writeDebugLog('SettingsWindow.modalSaveAction invoked');
        local ok = self:modalApplyAction('settings_modal_save');
        if not ok then
            return;
        end
        imgui.CloseCurrentPopup();
        imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
        imgui.SetVarValue(uiVariables["var_AllSoundIndex"], 0);
        syncAllColorsVarForGather(state.settings.setColors.gathering or state.gathering, "modalSaveAction");
        checkTargetAlertReady();
        state.values.feedbackSubmitted = false;
        state.values.feedbackMissing = false;
        imgui.SetVarValue(uiVariables["var_IssueTitle"], "");
        imgui.SetVarValue(uiVariables["var_IssueBody"], "")
        imgui.SetVarValue(uiVariables['var_ReportSelected'], 0);
        state.values.currentReportName = nil;
        state.values.settingsSnapshot = nil;
    end,

    modalCancelAction = function (self, alreadyClosed, keepSnapshot)
        writeDebugLog('SettingsWindow.modalCancelAction invoked');
        local snap = state.values.settingsSnapshot;
        if type(snap) == 'table' then
            settings = deepCopy(snap);
            loadUiVariables();
            updateAllStates(settings.state and settings.state.gathering or state.gathering);
            setSettingsStatus("Discarded unsaved changes.", { 1, 1, 0.54, 1.0 }, 2.0);
        end
        if keepSnapshot then
            commitSettingsSnapshot();
        else
            state.values.settingsSnapshot = nil;
            state.values.settingsUiSnapshotFingerprint = nil;
        end
        if not alreadyClosed then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
        end
    end,

    Draw = function (self, title)
        local io = imgui.GetIO();
        local width, height = state.window.widthSettings, state.window.heightSettings;
        imgui.SetNextWindowSize({ width, height }, ImGuiCond.Always);
        if state.values.centerWindow then
            imgui.SetNextWindowPos({ io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.5 }, ImGuiCond.Always, { 0.5, 0.5 });
            state.values.centerWindow = false;
        end
        if (not imgui.Begin(title, uiVariables["var_SettingsVisible"], bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoCollapse, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoScrollWithMouse))) then
            imgui.End();
            return;
        end

        if state.values.settingsJustOpened then
            -- Re-baseline after first successful render to avoid false "dirty" state on open.
            commitSettingsSnapshot();
            state.values.settingsJustOpened = false;
        end

        imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1.0 });
        setWindowFontScale(state.window.textScale);
        -- SETTINGS_MENU
        if imgui.BeginMenuBar() then
            local rowStartX = imgui.GetCursorPosX();
            local rowStartY = imgui.GetCursorPosY();
            local rowAvailX = getAvailX(imgui.GetContentRegionAvail());
            local navLabels = {};
            local navWidths = {};
            for i, data in ipairs(settingsTypes) do
                local btnName = string.camelToTitle(data.name);
                navLabels[i] = btnName;
                navWidths[i] = estimateButtonWidthForButtons(btnName, false);
            end
            local uiSpace = state.window.ui and state.window.ui.space or nil;
            local navMinGap = (uiSpace and tonumber(uiSpace.navMinGap)) or state.window.spaceSettingsBtn or 6.0;
            local navEdgePad = (uiSpace and tonumber(uiSpace.navEdgePad)) or 0.0;
            local navPositions, navGap, navEdge, navTotalWidth = computeEvenRowPositions(rowStartX, rowAvailX, navWidths, navMinGap, navEdgePad);
            logLayoutBreadcrumb("nav_settings", string.format(
                "count=%d avail=%.1f total=%.1f gap=%.1f edge=%.1f",
                #settingsTypes, tonumber(rowAvailX) or 0.0, tonumber(navTotalWidth) or 0.0, tonumber(navGap) or 0.0, tonumber(navEdge) or 0.0
            ));
            for i, data in ipairs(settingsTypes) do
                local btnName = navLabels[i];
                imgui.SetCursorPosX(navPositions[i] or rowStartX);
                imgui.SetCursorPosY(rowStartY);
                local isSelected = (state.settings.activeIndex == i);
                pushSelectedBorderStyle(isSelected);
                imguiPushActiveBtnColor(isSelected);
                if uiButton(btnName) then
                   state.settings.activeIndex = i;
                   state.values.feedbackSubmitted = false;
                   state.values.feedbackMissing = false;
                   imgui.SetVarValue(uiVariables["var_IssueTitle"], "");
                   imgui.SetVarValue(uiVariables["var_IssueBody"], "")
                end
                imgui.PopStyleColor(2);
                imgui.PopStyleVar();
            end
            imgui.EndMenuBar();
        end
        -- /SETTINGS_MENU

        local activePage = tonumber(state.settings.activeIndex) or 1;
        local showFooterRecalculate = (activePage == 2);
        logScaleSnapshot("settings", string.format("page=%s", tostring(activePage)));

        -- Use a body child to keep the footer pinned like the primary window.
        local footerButtonHeight, footerSymPad, footerBottomPadTarget, footerReserve = calcFooterMetrics();
        local settingsFooterReserve = math.ceil(tonumber(footerReserve) or 0.0);

        if imgui.BeginChild("SettingsBodyHost", { -1, -settingsFooterReserve }, false, bit.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoScrollWithMouse)) then
            local bodyFallbackY = math.max(0.0, (tonumber(imgui.GetWindowHeight()) or 0.0) - (tonumber(imgui.GetCursorPosY()) or 0.0) - (tonumber(state.window.padY) or 0.0));
            local _, bodyAvailY = getAvailXY(imgui.GetContentRegionAvail(), bodyFallbackY);
            state.window.heightSettingsContent = math.max((state.window.scale or 1.0) * 120.0, bodyAvailY);
            state.window.heightSettingsScroll = math.max((state.window.scale or 1.0) * 90.0, state.window.heightSettingsContent - (imgui.GetFrameHeightWithSpacing() * 1.2));

            -- render settings pages..
            imgui.BeginGroup();
            switch(state.settings.activeIndex, {
                [1] = function() renderSettingsGeneral() end,
                [2] = function() renderSettingsSetPrices() end,
                [3] = function() renderSettingsSetColors() end,
                [4] = function() renderSettingsSetAlerts() end,
                [5] = function() renderSettingsReports() end,
                [6] = function() renderSettingsFeedback() end,
                [7] = function() renderSettingsAbout() end,
            })
            imgui.EndGroup();
        end
        -- Remove only the body->footer vertical item gap; keep footer geometry math unchanged.
        local itemGapX = (state.window.ui and state.window.ui.space and tonumber(state.window.ui.space.sm)) or 0.0;
        imgui.PushStyleVar(ImGuiStyleVar.ItemSpacing, { itemGapX, 0.0 });
        imgui.EndChild();
        imgui.PopStyleVar();

        local pageHasSettings = (activePage >= 1 and activePage <= 4);
        local isDirty = pageHasSettings and hasPendingSettingsChanges();
        local pageActionLabel = nil;
        if activePage >= 1 and activePage <= 4 then
            pageActionLabel = "Use Defaults";
        elseif activePage == 5 then
            pageActionLabel = "Generate";
        end

        local function renderSettingsFooter(footerStartX, footerStartY, footerAvail, footerOpenedFlag)
            local footerAvailX, footerAvailY = getAvailXY(footerAvail, settingsFooterReserve);
            footerAvailY = math.max(0.0, math.min(tonumber(footerAvailY) or 0.0, tonumber(settingsFooterReserve) or 0.0));
            local footerSpacing = state.window.spaceSettingsBtn or 6.0;
            local footerRowOffset = math.max(0.0, (footerAvailY - footerButtonHeight) * 0.5);
            local footerRowY = footerStartY + footerRowOffset;
            local footerTopPad = footerRowOffset;
            local footerBottomPad = math.max(0.0, footerAvailY - footerRowOffset - footerButtonHeight);
            local function footerBtnWidth(label)
                return math.max(0.0, tonumber(estimateButtonWidthForButtons(label, false)) or 0.0);
            end
            local function footerButton(label, width)
                return uiButton(label, { tonumber(width) or footerBtnWidth(label), footerButtonHeight });
            end
            local rightPrimaryW = 0.0;
            local rightSecondaryLabel = nil;
            local rightSecondaryW = 0.0;
            if showFooterRecalculate and pageActionLabel == "Use Defaults" then
                rightSecondaryLabel = "Recalculate Value";
                rightSecondaryW = footerBtnWidth(rightSecondaryLabel);
            end
            local rightWLog = 0.0;
            local rightXLog = 0.0;
            local rightInsetLog = -1.0;
            if pageActionLabel ~= nil then
                rightPrimaryW = footerBtnWidth(pageActionLabel);
                rightWLog = rightPrimaryW;
                if rightSecondaryLabel ~= nil then
                    rightWLog = rightWLog + footerSpacing + rightSecondaryW;
                end
                rightXLog = footerStartX + footerAvailX - rightWLog - rightInsetLog;
                if rightXLog < footerStartX then rightXLog = footerStartX; end
                -- Pixel-snap to avoid fractional-x rendering drift at some scales.
                rightXLog = math.floor((tonumber(rightXLog) or 0.0) + 0.5);
            end

            local now = os.clock();
            state.values.settingsFooterLogAt = state.values.settingsFooterLogAt or 0;
            if (now - state.values.settingsFooterLogAt) >= 1.0 then
                state.values.settingsFooterLogAt = now;
                writeDebugLog(string.format("settings_footer page=%s dirty=%s scale=%.2f open=%s reserve=%.1f btnH=%.1f symPad=%.1f topPad=%.1f bottomPad=%.1f rightW=%.1f rightX=%.1f rightInset=%.1f start=(%.1f,%.1f) avail=(%.1f,%.1f) rowY=%.1f",
                    tostring(activePage), tostring(isDirty), tonumber(state.window.scale) or 0.0, tostring(footerOpenedFlag), tonumber(settingsFooterReserve) or 0.0,
                    tonumber(footerButtonHeight) or 0.0, tonumber(footerSymPad) or 0.0,
                    tonumber(footerTopPad) or 0.0, tonumber(footerBottomPad) or 0.0,
                    tonumber(rightWLog) or 0.0, tonumber(rightXLog) or 0.0, tonumber(rightInsetLog) or 0.0,
                    tonumber(footerStartX) or 0.0, tonumber(footerStartY) or 0.0,
                    tonumber(footerAvailX) or 0.0, tonumber(footerAvailY) or 0.0,
                    tonumber(footerRowY) or 0.0));
            end

            -- Left group: Done or Save/Cancel
            imgui.SetCursorPosX(footerStartX);
            imgui.SetCursorPosY(footerRowY);
            if pageHasSettings and isDirty then
                local savePressed = footerButton("Save");
                logFooterItemRect("settings_left", "Save", footerRowY, settingsFooterReserve);
                if savePressed then
                    writeDebugLog(string.format('settings footer click Save page=%s dirty=%s', tostring(activePage), tostring(isDirty)));
                    self:modalApplyAction('settings_save_button');
                end
                imgui.SameLine(0.0, footerSpacing);
                local cancelPressed = footerButton("Cancel");
                if cancelPressed then
                    writeDebugLog(string.format('settings footer click Cancel page=%s dirty=%s', tostring(activePage), tostring(isDirty)));
                    self:modalCancelAction(true, true);
                end
            else
                local donePressed = footerButton("Done");
                logFooterItemRect("settings_left", "Done", footerRowY, settingsFooterReserve);
                if donePressed then
                    writeDebugLog(string.format('settings footer click Done page=%s dirty=%s', tostring(activePage), tostring(isDirty)));
                    if pageHasSettings then
                        local ok = trySaveSettings('settings_done_close', true);
                        writeDebugLog(string.format('settings Done pre-close save ok=%s', tostring(ok)));
                        if ok then
                            commitSettingsSnapshot();
                        end
                    end
                    state.values.settingsSnapshot = nil;
                    state.values.settingsUiSnapshotFingerprint = nil;
                    imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
                end
            end

            -- Right group: page action
            if pageActionLabel ~= nil then
                imgui.SetCursorPosX(rightXLog);
                imgui.SetCursorPosY(footerRowY);
            end

            if pageActionLabel == "Use Defaults" then
                if rightSecondaryLabel ~= nil then
                    local recalcPressed = footerButton(rightSecondaryLabel, rightSecondaryW);
                    logFooterItemRect("settings_right", "Recalculate Value", footerRowY, settingsFooterReserve);
                    if recalcPressed then
                        local gatherForRecalc = state.settings.setPrices.gathering;
                        openConfirmModal(
                            string.format("recalculate %s estimated value", string.upperfirst(tostring(gatherForRecalc))),
                            "This recomputes Estimated Value from tracked yields using the current Set Prices values.",
                            false,
                            function()
                                local ok, trackedRows, value = recalculateEstimatedValueForGathering(gatherForRecalc);
                                if ok then
                                    setSettingsStatus(string.format("Recalculated %s: %d (from %d tracked yields).",
                                        string.upperfirst(tostring(gatherForRecalc)), tonumber(value) or 0, tonumber(trackedRows) or 0),
                                        { 0.39, 0.96, 0.13, 1.0 }, 2.5);
                                else
                                    setSettingsStatus("Failed to recalculate estimated value.", { 1.0, 0.615, 0.615, 1.0 }, 3.0);
                                end
                            end
                        );
                    end
                    if settings.general.showToolTips and imgui.IsItemHovered() then
                        imgui.SetTooltip("Recalculate this gathering type's Estimated Value from current prices.");
                    end
                    imgui.SameLine(0.0, footerSpacing);
                end

                local defaultsPressed = footerButton("Use Defaults", rightPrimaryW);
                logFooterItemRect("settings_right", "Use Defaults", footerRowY, settingsFooterReserve);
                if defaultsPressed then
                    if activePage == 1 then
                        openConfirmModal(
                            "reset General settings to defaults",
                            "(Current General settings will be lost.)",
                            true,
                            function()
                                applyGeneralDefaults();
                            end
                        );
                    elseif activePage == 2 then
                        local gathering = state.settings.setPrices.gathering;
                        openConfirmModal(
                            string.format("reset %s prices to defaults", string.upperfirst(gathering)),
                            "(Current price values for this gathering type will be lost.)",
                            true,
                            function()
                                applyPricesDefaults(gathering);
                            end
                        );
                    elseif activePage == 3 then
                        local gathering = state.settings.setColors.gathering;
                        openConfirmModal(
                            string.format("reset %s yield colors to defaults", string.upperfirst(gathering)),
                            "(Current color settings for this gathering type will be lost.)",
                            true,
                            function()
                                applyColorsDefaults(gathering);
                            end
                        );
                    elseif activePage == 4 then
                        local gathering = state.settings.setAlerts.gathering;
                        openConfirmModal(
                            string.format("reset %s alerts to defaults", string.upperfirst(gathering)),
                            "(Current sound alert settings for this gathering type will be lost.)",
                            true,
                            function()
                                applyAlertsDefaults(gathering);
                            end
                        );
                    end
                end
                if settings.general.showToolTips and imgui.IsItemHovered() then
                    imgui.SetTooltip("Reset this settings page to default values.");
                end
            elseif pageActionLabel == "Generate" then
                local generateDisabled = imguiPushDisabled(state.values.genReportDisabled);
                local generatePressed = footerButton("Generate", rightWLog);
                logFooterItemRect("settings_right", "Generate", footerRowY, settingsFooterReserve);
                if generatePressed then
                    if not generateDisabled then
                        runSafe('reports_footer_generate', function()
                            generateReportsFromFooter();
                        end);
                    end
                end
                if settings.general.showToolTips and imgui.IsItemHovered() then
                    local gatherForTip = getActiveReportsGathering();
                    imgui.SetTooltip(string.format("Manually generate a %s report using its current yield data.", string.upperfirst(tostring(gatherForTip))));
                end
                imguiPopDisabled(generateDisabled);
            end
        end

        local footerOpened = imgui.BeginChild("SettingsFooterRow", { -1, settingsFooterReserve }, false, bit.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoScrollWithMouse));
        if footerOpened then
            local footerStartX = imgui.GetCursorPosX();
            local footerStartY = imgui.GetCursorPosY();
            local footerAvail = imgui.GetContentRegionAvail();
            renderSettingsFooter(footerStartX, footerStartY, footerAvail, true);
        end
        imgui.EndChild();
        if not footerOpened then
            local footerStartX = imgui.GetCursorPosX();
            local footerStartY = imgui.GetCursorPosY();
            local footerAvail = imgui.GetContentRegionAvail();
            renderSettingsFooter(footerStartX, footerStartY, footerAvail, false);
        end
        if state.initializing then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
            imgui.SetVarValue(uiVariables["var_HelpVisible"], false);
            imgui.CloseCurrentPopup();
        end

        -- SCALE TUNING (must render in same window scope that opens it)
        if state.values.openScaleTuningRequested then
            imgui.OpenPopup("Scale Tuning");
            state.values.scaleTuningIgnoreClickAway = true;
            state.values.openScaleTuningRequested = false;
        end
        local tuningWidth, tuningHeight = state.window.widthSettings * 0.80, state.window.heightSettings * 0.72;
        local tuningX = (io.DisplaySize.x * 0.5) - (tuningWidth * 0.5);
        local tuningY = (io.DisplaySize.y * 0.5) - (tuningHeight * 0.5);
        imgui.SetNextWindowSize({ tuningWidth, tuningHeight }, ImGuiCond.Always);
        imgui.SetNextWindowPos({ io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.5 }, ImGuiCond.Always, { 0.5, 0.5 });
        if imgui.BeginPopupModal("Scale Tuning", uiVariables["var_SettingsVisible"], bit.bor(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoCollapse)) then
            setWindowFontScale(state.window.textScale);
            logScaleSnapshot("scale_tuning", "");
            local closeScaleTuning = false;
            imgui.Text("Tune global scaling behavior.");
            imgui.Text("Changes preview live while this modal is open.");
            imgui.Separator();
            imgui.PushItemWidth(state.window.widthWidgetDefault);
            imgui.SliderFloat("Rest Text Base", uiVariables["var_TextScaleBase"], 0.50, 2.50, "%.3f");
            imgui.SliderFloat("Rest Text Factor", uiVariables["var_TextScaleFactor"], 0.00, 2.50, "%.3f");
            imgui.Separator();
            imgui.SliderFloat("Metrics Text Base", uiVariables["var_MetricsTextScaleBase"], 0.50, 2.50, "%.3f");
            imgui.SliderFloat("Metrics Text Factor", uiVariables["var_MetricsTextScaleFactor"], 0.00, 2.50, "%.3f");
            imgui.Separator();
            imgui.SliderFloat("Button Text Base", uiVariables["var_ButtonTextScaleBase"], 0.50, 2.50, "%.3f");
            imgui.SliderFloat("Button Text Factor", uiVariables["var_ButtonTextScaleFactor"], 0.00, 2.50, "%.3f");
            imgui.Separator();
            imgui.SliderFloat("Button Size X Base", uiVariables["var_ButtonSizeXBase"], 0.50, 2.50, "%.3f");
            imgui.SliderFloat("Button Size X Factor", uiVariables["var_ButtonSizeXFactor"], 0.00, 2.50, "%.3f");
            imgui.SliderFloat("Button Size Y Base", uiVariables["var_ButtonSizeYBase"], 0.50, 2.50, "%.3f");
            imgui.SliderFloat("Button Size Y Factor", uiVariables["var_ButtonSizeYFactor"], 0.00, 2.50, "%.3f");
            imgui.Separator();
            imgui.SliderFloat("Window X Base", uiVariables["var_WindowXScaleBase"], 0.50, 2.50, "%.3f");
            imgui.SliderFloat("Window X Factor", uiVariables["var_WindowXScaleFactor"], 0.00, 2.50, "%.3f");
            imgui.SliderFloat("Window Y Base", uiVariables["var_WindowYScaleBase"], 0.50, 2.50, "%.3f");
            imgui.SliderFloat("Window Y Factor", uiVariables["var_WindowYScaleFactor"], 0.00, 2.50, "%.3f");
            imgui.PopItemWidth();

            syncScaleTuningSettingsFromVars();

            imgui.Separator();
            local tuningLabels = { "Defaults", "Apply", "Close" };
            local tuningStartX = imgui.GetCursorPosX();
            local tuningStartY = imgui.GetCursorPosY();
            local tuningAvail = imgui.GetContentRegionAvail();
            local tuningWidths = {};
            local tuningTotal = 0.0;
            for i, label in ipairs(tuningLabels) do
                tuningWidths[i] = estimateButtonWidth(label, false);
                tuningTotal = tuningTotal + tuningWidths[i];
            end
            local tuningGap = 0.0;
            if #tuningLabels > 0 then
                tuningGap = (tuningAvail - tuningTotal) / (#tuningLabels + 1);
                if tuningGap < 0 then tuningGap = 0; end
            end
            local function setTuningBtnPos(index)
                local x = tuningStartX + tuningGap;
                if index > 1 then
                    for i = 1, index - 1 do
                        x = x + tuningWidths[i] + tuningGap;
                    end
                end
                imgui.SetCursorPosX(x);
                imgui.SetCursorPosY(tuningStartY);
            end
            setTuningBtnPos(1);
            if uiButtonCompact("Defaults") then
                openConfirmModal(
                    "reset scale tuning to defaults",
                    "(Current scale tuning values will be lost.)",
                    true,
                    function()
                        settings.general.textScaleBase      = defaultSettingsTemplate.general.textScaleBase;
                        settings.general.textScaleFactor    = defaultSettingsTemplate.general.textScaleFactor;
                        settings.general.metricsTextScaleBase   = defaultSettingsTemplate.general.metricsTextScaleBase;
                        settings.general.metricsTextScaleFactor = defaultSettingsTemplate.general.metricsTextScaleFactor;
                        settings.general.buttonTextScaleBase    = defaultSettingsTemplate.general.buttonTextScaleBase;
                        settings.general.buttonTextScaleFactor  = defaultSettingsTemplate.general.buttonTextScaleFactor;
                        settings.general.buttonSizeXBase        = defaultSettingsTemplate.general.buttonSizeXBase;
                        settings.general.buttonSizeXFactor      = defaultSettingsTemplate.general.buttonSizeXFactor;
                        settings.general.buttonSizeYBase        = defaultSettingsTemplate.general.buttonSizeYBase;
                        settings.general.buttonSizeYFactor      = defaultSettingsTemplate.general.buttonSizeYFactor;
                        settings.general.windowXScaleBase   = defaultSettingsTemplate.general.windowXScaleBase;
                        settings.general.windowXScaleFactor = defaultSettingsTemplate.general.windowXScaleFactor;
                        settings.general.windowYScaleBase   = defaultSettingsTemplate.general.windowYScaleBase;
                        settings.general.windowYScaleFactor = defaultSettingsTemplate.general.windowYScaleFactor;
                        syncScaleTuningVarsFromSettings();
                    end
                );
            end

            setTuningBtnPos(2);
            if uiButtonCompact("Apply") then
                writeDebugLog('scale_tuning click Apply');
                syncScaleTuningSettingsFromVars();
                local ok = trySaveSettings('scale_tuning_apply', true);
                if ok then
                    commitSettingsSnapshot();
                    writeDebugLog('scale_tuning apply save ok');
                    setSettingsStatus("Saved settings.", { 0.39, 0.96, 0.13, 1.0 }, 2.0);
                else
                    writeDebugLog('scale_tuning apply save failed');
                    setSettingsStatus("Failed to save settings.", { 1.0, 0.615, 0.615, 1.0 }, 3.0);
                end
            end

            setTuningBtnPos(3);
            if uiButtonCompact("Close") then
                writeDebugLog('scale_tuning click Close');
                closeScaleTuning = true;
                local ok = trySaveSettings('scale_tuning_close', true);
                if ok then
                    commitSettingsSnapshot();
                    writeDebugLog('scale_tuning close save ok');
                    setSettingsStatus("Saved settings.", { 0.39, 0.96, 0.13, 1.0 }, 2.0);
                else
                    writeDebugLog('scale_tuning close save failed');
                    setSettingsStatus("Failed to save settings.", { 1.0, 0.615, 0.615, 1.0 }, 3.0);
                end
            end

            if type(imgui.IsMouseClicked) == 'function' and not closeScaleTuning then
                local suppressClickAway = state.values.scaleTuningIgnoreClickAway == true;
                if suppressClickAway then
                    local mouseDown = false;
                    local okDown, downResult = pcall(function() return imgui.IsMouseDown(0); end);
                    if okDown then
                        mouseDown = downResult == true;
                    end
                    if not mouseDown then
                        state.values.scaleTuningIgnoreClickAway = false;
                        suppressClickAway = false;
                    end
                end

                local mouseClicked = false;
                local okClick, clickResult = pcall(function() return imgui.IsMouseClicked(0); end);
                if okClick then
                    mouseClicked = clickResult == true;
                else
                    local okClickAlt, clickAltResult = pcall(function() return imgui.IsMouseClicked(); end);
                    mouseClicked = okClickAlt and clickAltResult == true;
                end

                if mouseClicked and not suppressClickAway then
                    local mx, my = io.MousePos.x, io.MousePos.y;
                    local outside = (mx < tuningX) or (mx > (tuningX + tuningWidth)) or (my < tuningY) or (my > (tuningY + tuningHeight));
                    if outside then
                        closeScaleTuning = true;
                    end
                end
            end

            if closeScaleTuning then
                imgui.CloseCurrentPopup();
            end
            imgui.EndPopup();
        else
            state.values.scaleTuningIgnoreClickAway = false;
        end

        imgui.PopStyleColor();
        imgui.End();
    end
}

-- The help window
local helpWindow =
{
    Draw = function (self, title)
        local io = imgui.GetIO();
        local width, height = state.window.widthSettings, state.window.heightSettings;
        imgui.SetNextWindowSize({ width, height }, ImGuiCond.Always);
        if state.values.centerWindow then
            imgui.SetNextWindowPos({ io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.5 }, ImGuiCond.Always, { 0.5, 0.5 });
            state.values.centerWindow = false;
        end
        if (not imgui.Begin(title, uiVariables["var_HelpVisible"], bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoCollapse))) then
            imgui.End();
            return;
        end
        imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1.0 });
        setWindowFontScale(state.window.textScale);
        logScaleSnapshot("help", "");

        -- HELP_MENU
        if imgui.BeginMenuBar() then
            local rowStartX = imgui.GetCursorPosX();
            local rowStartY = imgui.GetCursorPosY();
            local rowAvailX = getAvailX(imgui.GetContentRegionAvail());
            local navLabels = {};
            local navWidths = {};
            for i, data in ipairs(helpTypes) do
                local btnName = string.camelToTitle(data.name);
                navLabels[i] = btnName;
                navWidths[i] = estimateButtonWidthForButtons(btnName, false);
            end
            local uiSpace = state.window.ui and state.window.ui.space or nil;
            local navMinGap = (uiSpace and tonumber(uiSpace.navMinGap)) or state.window.spaceSettingsBtn or 6.0;
            local navEdgePad = (uiSpace and tonumber(uiSpace.navEdgePad)) or 0.0;
            local navPositions, navGap, navEdge, navTotalWidth = computeEvenRowPositions(rowStartX, rowAvailX, navWidths, navMinGap, navEdgePad);
            logLayoutBreadcrumb("nav_help", string.format(
                "count=%d avail=%.1f total=%.1f gap=%.1f edge=%.1f",
                #helpTypes, tonumber(rowAvailX) or 0.0, tonumber(navTotalWidth) or 0.0, tonumber(navGap) or 0.0, tonumber(navEdge) or 0.0
            ));
            for i, data in ipairs(helpTypes) do
                local btnName = navLabels[i];
                imgui.SetCursorPosX(navPositions[i] or rowStartX);
                imgui.SetCursorPosY(rowStartY);
                imguiPushActiveBtnColor(state.help.activeIndex == i);
                if uiButton(btnName) then
                    state.help.activeIndex = i;
                end
                imgui.PopStyleColor();
            end
            imgui.EndMenuBar();
        end
        -- /HELP_MENU

        imgui.BeginGroup();
        imgui.Spacing();
        switch(state.help.activeIndex, {
            [1] = function() renderHelpGeneral() end,
            [2] = function() renderHelpQsAndAs() end
        })
        imgui.EndGroup();
        if uiActionButton("Done") then
            imgui.SetVarValue(uiVariables["var_HelpVisible"], false);
        end

        imgui.SameLine();
        local prevScale = (state and state.window and state.window.currentTextScale) or state.window.textScale;
        setWindowFontScale(state.window.buttonTextScale);
        imgui.Text("OR close window to exit.");
        setWindowFontScale(prevScale);

        if state.initializing then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
            imgui.SetVarValue(uiVariables["var_HelpVisible"], false);
            imgui.CloseCurrentPopup();
        end

        imgui.PopStyleColor();
        imgui.End();
    end
}

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is rendering.
----------------------------------------------------------------------------------------------------
local last_time = os.clock();
ashita.events.register('d3d_present', 'yield_render', function()
    -- Ensure imgui is initialized
    if not defaultFontSize then
        defaultFontSize = imgui.GetFontSize();
    end

    -- Update timers
    local current_time = os.clock();
    local delta = current_time - last_time;
    last_time = current_time;
    ashita.timer.update(delta);

    local windowScale = getWindowScale();
    local xScale = math.max(0.25, settings.general.windowXScaleBase + ((windowScale - 1.0) * settings.general.windowXScaleFactor));
    local yScale = math.max(0.25, settings.general.windowYScaleBase + ((windowScale - 1.0) * settings.general.windowYScaleFactor));
    local function sx(value)
        return value * xScale;
    end
    local function sy(value)
        return value * yScale;
    end

    local function styleColorOpaque(col, fallback)
        local r = tonumber(fallback and fallback[1]) or 0.0;
        local g = tonumber(fallback and fallback[2]) or 0.0;
        local b = tonumber(fallback and fallback[3]) or 0.0;
        local ok, c = pcall(function() return imgui.GetStyleColorVec4(col); end);
        if ok and type(c) == "table" then
            r = tonumber(c.x) or tonumber(c[1]) or r;
            g = tonumber(c.y) or tonumber(c[2]) or g;
            b = tonumber(c.z) or tonumber(c[3]) or b;
        end
        return { r, g, b, 1.0 };
    end

    imgui.PushStyleVar(ImGuiStyleVar.WindowRounding, 5.0);
    imgui.PushStyleVar(ImGuiStyleVar.FrameRounding, 5.0);
    imgui.PushStyleVar(ImGuiStyleVar.ChildRounding, 5.0);
    imgui.PushStyleVar(ImGuiStyleVar.Alpha, settings.general.opacity);
    local paddingX = sx(5.0);
    local paddingY = sy(5.0);
    imgui.PushStyleVar(ImGuiStyleVar.WindowPadding, { paddingX, paddingY });
    -- Keep 1.0 opacity fully opaque even if the active ImGui theme has translucent backgrounds.
    imgui.PushStyleColor(ImGuiCol.WindowBg, styleColorOpaque(ImGuiCol.WindowBg, { 17/255, 17/255, 30/255 }));
    imgui.PushStyleColor(ImGuiCol.ChildBg, styleColorOpaque(ImGuiCol.ChildBg, { 17/255, 17/255, 30/255 }));
    imgui.PushStyleColor(ImGuiCol.PopupBg, styleColorOpaque(ImGuiCol.PopupBg, { 17/255, 17/255, 30/255 }));
    imgui.PushStyleColor(ImGuiCol.Border, { 0.21, 0.47, 0.59, 0.5 });
    imgui.PushStyleColor(ImGuiCol.PlotLines, { 0.77, 0.83, 0.80, 0.3 });
    imgui.PushStyleColor(ImGuiCol.PlotHistogram, { 0.77, 0.83, 0.80, 0.3 });
    imgui.PushStyleColor(ImGuiCol.TitleBgActive, { 17/255, 17/255, 30/255, 1.0 });

    -- MAIN
    imgui.SetNextWindowSize({ sx(250.0), sy(500.0) }, ImGuiCond.Always);
    if state.initializing and state.firstLoad then
        local io = imgui.GetIO();
        imgui.SetNextWindowPos({ io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.5 }, ImGuiCond.Always, { 0.5, 0.5 });
        state.values.centerWindow = true;
    elseif state.initializing then
        imgui.SetNextWindowPos({ state.window.posX , state.window.posY });
    end
    if not imgui.Begin(string.format("%s v%s by Lotekkie", _addon.name, _addon.version), imgui.GetVarValue(uiVariables['var_WindowVisible']), bit.bor(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoScrollWithMouse, ImGuiWindowFlags.NoCollapse)) then
        imgui.End();
        return
    end

    imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1.0 });
    local textScale = math.max(0.25, settings.general.textScaleBase + ((windowScale - 1.0) * settings.general.textScaleFactor));
    local metricsTextScale = math.max(0.25, settings.general.metricsTextScaleBase + ((windowScale - 1.0) * settings.general.metricsTextScaleFactor));
    local buttonTextScale = math.max(0.25, settings.general.buttonTextScaleBase + ((windowScale - 1.0) * settings.general.buttonTextScaleFactor));
    local buttonSizeXScale = math.max(0.25, settings.general.buttonSizeXBase + ((windowScale - 1.0) * settings.general.buttonSizeXFactor));
    local buttonSizeYScale = math.max(0.25, settings.general.buttonSizeYBase + ((windowScale - 1.0) * settings.general.buttonSizeYFactor));
    state.window = -- Calculations based on scaled window sizes
    {
        scale                 = windowScale,
        xScale                = xScale,
        yScale                = yScale,
        textScale             = textScale,
        metricsTextScale      = metricsTextScale,
        buttonTextScale       = buttonTextScale,
        buttonSizeXScale      = buttonSizeXScale,
        buttonSizeYScale      = buttonSizeYScale,
        height                = sy(500.0),
        width                 = sx(250.0),
        padX                  = sx(5.0),
        padY                  = sy(5.0),
        spaceGatherBtn        = sx(7.0),
        spaceGatherImg        = sx(7.0),
        -- Ensure progress bar height tracks text size so label does not look oversized.
        heightHeaderMain      = math.max(sy(18.0), (defaultFontSize * textScale) + sy(6.0)),
        heightPlot            = sy(25.0),
        heightYields          = sy(130.0),
        spaceToolTip          = sx(4.0),
        spaceFooterBtn        = sx(3.0),
        widthSettings         = sx(500.0),
        heightSettings        = sy(450.0),
        heightSettingsContent = sy(390.0),
        heightSettingsScroll  = sy(366.0),
        spacePriceModeRadio   = sx(26.0),
        spacePriceDefaults    = sx(177.0),
        spaceEstimatedValue   = sx(12.0),
        widthModalConfirm     = sx(350.0),
        heightModalConfirm    = sy(102.0),
        spaceColorDefaults    = sx(177.0),
        widthWidgetDefault    = sx(275.0),
        spaceSettingsBtn      = sx(7.0),
        spaceSettingsDefaults = sx(377.0),
        widthWidgetValue      = sx(191.0),
        offsetPriceColumns1   = sx(140.0),
        offsetPriceColumns2   = sx(270.0),
        heightPriceColumns    = sy(25.0),
        offsetPriceCursorY    = sy(2.0),
        offsetNameCursorY     = sy(5.0),
        sizeGatherTexture     = sx(20.0),
        spaceBtnRecalculate   = sx(152.0),
        spaceReportsDelete    = sx(176.0),
        widthReportScale      = sx(150.0)
    }
    local tokenButtonPadX = 4.0 * buttonSizeXScale;
    local tokenButtonPadY = 3.0 * buttonSizeYScale;
    state.window.ui =
    {
        font =
        {
            body    = textScale,
            metrics = metricsTextScale,
            button  = buttonTextScale,
        },
        space =
        {
            xs            = sx(2.0),
            sm            = sx(4.0),
            md            = sx(7.0),
            lg            = sx(12.0),
            vRow          = sy(4.0),
            vSection      = sy(8.0),
            vPage         = sy(12.0),
            navMinGap     = sx(6.0),
            navEdgePad    = sx(2.0),
            footerMinGap  = sx(6.0),
            footerEdgePad = sx(2.0),
        },
        button =
        {
            padX = tokenButtonPadX,
            padY = tokenButtonPadY,
            minH = math.max(
                tonumber(imgui.GetFrameHeight()) or 0.0,
                ((tonumber(defaultFontSize) or imgui.GetFontSize() or 12.0) * buttonTextScale) + (tokenButtonPadY * 2.0)
            ),
        },
        footer =
        {
            bottomPad = math.max(4.0, windowScale * 2.0),
        },
    };
    logLayoutBreadcrumb("phase1_tokens", string.format(
        "scale=%.2f navGap=%.1f footerGap=%.1f btnMinH=%.1f",
        tonumber(windowScale) or 0.0,
        tonumber(state.window.ui.space.navMinGap) or 0.0,
        tonumber(state.window.ui.space.footerMinGap) or 0.0,
        tonumber(state.window.ui.button.minH) or 0.0
    ));

    setWindowFontScale(state.window.textScale);
    logScaleSnapshot("main", "");


    if getPlayerName() ~= "" and not state.reportsLoaded then
        for _, data in ipairs(gatherTypes) do
            refreshReportsForGather(data.name);
        end
        state.reportsLoaded = true;
    end

    -- MAIN_MENU
    local gatherBtnBoost = 1.18;
    local gatherMenuPadX = 4.0 * (tonumber(state.window.buttonSizeXScale) or 1.0);
    local gatherMenuPadY = 4.0 * (tonumber(state.window.buttonSizeYScale) or 1.0);
    local btnAction = function(data)
        runSafe(string.format('main_btnAction_%s', tostring(data and data.name)), function()
            updateAllStates(data.name);
            state.values.inactivitySeconds = 0;
            checkTargetAlertReady();
            imgui.SetVarValue(uiVariables['var_ReportSelected'], 0);
            state.values.currentReportName = nil;
            state.settings.setColors.gathering = data.name;
            syncAllColorsVarForGather(data.name, "main_gather_switch");
            state.settings.setAlerts.gathering = data.name;
            imgui.SetVarValue(uiVariables["var_AllSoundIndex"], 0);
        end);
    end
    imgui.PushStyleVar(ImGuiStyleVar.FramePadding, { gatherMenuPadX, gatherMenuPadY });
    local rowStartX = imgui.GetCursorPosX();
    local rowStartY = imgui.GetCursorPosY();
    local rowAvail = imgui.GetContentRegionAvail();
    if type(rowAvail) == "table" and rowAvail.x ~= nil then
        rowAvail = tonumber(rowAvail.x) or 0.0;
    end
    local widths = {};
    for i, data in ipairs(gatherTypes) do
        local w = 0.0;
        if state.values.btnTextureFailure or not settings.general.useImageButtons then
            w = estimateButtonWidth(string.upperfirst(data.short), true) * gatherBtnBoost;
        else
            local textureSize = state.window.sizeGatherTexture * gatherBtnBoost;
            w = textureSize + (state.window.scale * 8.0);
        end
        widths[i] = w;
    end
    local uiSpace = state.window.ui and state.window.ui.space or nil;
    local navMinGap = (uiSpace and tonumber(uiSpace.navMinGap)) or state.window.spaceGatherBtn or 0.0;
    local navPositions, navGap, navEdge, navTotalWidth =
        computeFlushRowPositions(rowStartX, rowAvail, widths, navMinGap);
    logLayoutBreadcrumb("nav_main_even", string.format(
        "count=%d avail=%.1f total=%.1f gap=%.1f edge=%.1f",
        #gatherTypes, tonumber(rowAvail) or 0.0, tonumber(navTotalWidth) or 0.0, tonumber(navGap) or 0.0, tonumber(navEdge) or 0.0
    ));
    for i, data in ipairs(gatherTypes) do
        imgui.SetCursorPosX(navPositions[i] or rowStartX);
        imgui.SetCursorPosY(rowStartY);
        local isSelected = (data.name == state.gathering);
        if isSelected then
            imgui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, math.max(1.0, tonumber(state.window.scale) or 1.0));
            imgui.PushStyleColor(ImGuiCol_Border, { 0.39, 0.96, 0.13, 1.0 });
        else
            imgui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0.0);
            imgui.PushStyleColor(ImGuiCol_Border, { 0, 0, 0, 0 });
        end
        if state.values.btnTextureFailure or not settings.general.useImageButtons then
            imguiPushActiveBtnColor(isSelected);
            if uiSmallButtonBoosted(string.upperfirst(data.short), gatherBtnBoost) then
                btnAction(data);
            end
        else
            local texture = textures[data.name];
            imguiPushActiveBtnColor(isSelected);
            local textureSize = state.window.sizeGatherTexture * gatherBtnBoost;
            if imgui.ImageButton(texture, { textureSize, textureSize }) then
                btnAction(data);
            end
        end
        imgui.PopStyleColor(2);
        imgui.PopStyleVar();
        if imgui.IsItemHovered() then
            imgui.SetTooltip(string.upperfirst(data.name));
        end
    end
    local rowHeight = imgui.GetFrameHeightWithSpacing();
    if not state.values.btnTextureFailure and settings.general.useImageButtons then
        rowHeight = (state.window.sizeGatherTexture * gatherBtnBoost) + (state.window.scale * 6.0);
    end
    imgui.SetCursorPosX(rowStartX);
    imgui.SetCursorPosY(rowStartY + rowHeight);
    imgui.PopStyleVar();
    -- /MAIN_MENU

    imguiHalfSep();

    -- MAIN_HEADER
    if imguiShowToolTip(string.format("Progress towards your target value (adjusted within settings)."), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end
    if imgui.BeginChild("Header", { -1, state.window.heightHeaderMain }, false, bit.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoScrollWithMouse)) then
        local desiredHeaderScale = tonumber(state.window.textScale) or 1.0;
        setWindowFontScale(desiredHeaderScale);
        -- Some ImGui wrappers apply child font scale relative to parent window scale.
        -- Normalize to target pixel size so header text exactly matches metrics text.
        local defaultPx = tonumber(defaultFontSize) or tonumber(imgui.GetFontSize()) or 14.0;
        local desiredHeaderFontPx = defaultPx * desiredHeaderScale;
        local actualHeaderFontPx = tonumber(imgui.GetFontSize()) or desiredHeaderFontPx;
        if actualHeaderFontPx > 0.0 and math.abs(actualHeaderFontPx - desiredHeaderFontPx) > 0.01 then
            local correction = desiredHeaderFontPx / actualHeaderFontPx;
            setWindowFontScale((tonumber(state.window.currentTextScale) or desiredHeaderScale) * correction);
        end
        local progress = calcTargetProgress();
        local targetValue = tonumber(settings.general.targetValue) or 0;
        local curValue = tonumber(metrics[state.gathering].estimatedValue) or 0;
        local progressPct = math.floor((progress * 100.0) + 0.5);
        local progressLabelIndex = tonumber(state.values.progressLabelIndex) or 1;
        local progressLabel;
        if progressLabelIndex == 2 then
            progressLabel = string.format("%d%%", progressPct);
        else
            progressLabel = string.format("%s/%s", curValue, targetValue);
        end
        logScaleSnapshot("main_header_progress", string.format("label_mode=%s", tostring(progressLabelIndex)));

        local lr, lg, lb, la = 0.39, 0.96, 0.13, 1; -- success
        if progress < 1 and progress >= 0.5 then
            lr, lg, lb, la = 1, 1, 0.54, 1; -- warn
        elseif progress < 0.5 then
            lr, lg, lb, la = 1, 0.615, 0.615, 1; -- danger
        end
        local availW = imgui.GetContentRegionAvail();
        local barWidth = tonumber(availW) or 0;
        if type(availW) == "table" and availW.x ~= nil then
            barWidth = tonumber(availW.x) or barWidth;
        end
        if barWidth <= 0 then
            barWidth = imgui.GetWindowWidth() - ((state.window.padX or 5) * 2);
        end
        local barPosX = imgui.GetCursorPosX();
        local barPosY = imgui.GetCursorPosY();
        -- Hide built-in progress label and render centered text manually.
        imgui.PushStyleColor(ImGuiCol_Text, { 0, 0, 0, 0 });
        imgui.ProgressBar(progress, { -1, state.window.heightHeaderMain }, "");
        local progressHovered = (imgui.IsItemHovered ~= nil and imgui.IsItemHovered() == true);
        imgui.PopStyleColor();
        local textWidth = (#progressLabel * imgui.GetFontSize() * 0.52);
        if imgui.CalcTextSize ~= nil then
            local okSize, sz = pcall(function() return imgui.CalcTextSize(progressLabel); end);
            if okSize and type(sz) == "table" then
                if sz.x ~= nil then
                    textWidth = tonumber(sz.x) or textWidth;
                elseif sz[1] ~= nil then
                    textWidth = tonumber(sz[1]) or textWidth;
                end
            end
        end
        local overlayX = barPosX + math.max(0, (barWidth - textWidth) / 2);
        local overlayY = barPosY + math.max(0, (state.window.heightHeaderMain - imgui.GetTextLineHeight()) / 2);
        imgui.SetCursorPosX(overlayX);
        imgui.SetCursorPosY(overlayY);
        imgui.PushStyleColor(ImGuiCol_Text, { lr, lg, lb, la });
        imgui.TextUnformatted(progressLabel);
        imgui.PopStyleColor();
        -- Use the progress bar item itself as the interaction surface.
        local hovered = progressHovered;
        if state.values.progressHoverLast == nil then
            state.values.progressHoverLast = false;
        end
        if hovered ~= state.values.progressHoverLast then
            state.values.progressHoverLast = hovered;
            writeDebugLog(string.format('progress hover changed: hovered=%s width=%s height=%s', tostring(hovered), tostring(barWidth), tostring(state.window.heightHeaderMain)));
        end
        state.values.progressArmL = state.values.progressArmL or false;
        state.values.progressArmR = state.values.progressArmR or false;
        state.values.progressMouseLPrev = state.values.progressMouseLPrev or false;
        state.values.progressMouseRPrev = state.values.progressMouseRPrev or false;

        local lDown = false;
        local rDown = false;
        local lReleased = false;
        local rReleased = false;

        local okDownL, downL = pcall(function() return imgui.IsMouseDown(0); end);
        if okDownL then lDown = (downL == true); end
        local okDownR, downR = pcall(function() return imgui.IsMouseDown(1); end);
        if okDownR then rDown = (downR == true); end

        local okRelL, relL = pcall(function() return imgui.IsMouseReleased(0); end);
        if okRelL then
            lReleased = (relL == true);
        else
            lReleased = (state.values.progressMouseLPrev == true and lDown == false);
        end
        local okRelR, relR = pcall(function() return imgui.IsMouseReleased(1); end);
        if okRelR then
            rReleased = (relR == true);
        else
            rReleased = (state.values.progressMouseRPrev == true and rDown == false);
        end

        if hovered and lDown then
            if not state.values.progressArmL then
                state.values.progressArmL = true;
                writeDebugLog('progress arm L');
            end
        end
        if hovered and rDown then
            if not state.values.progressArmR then
                state.values.progressArmR = true;
                writeDebugLog('progress arm R');
            end
        end

        if lReleased then
            if state.values.progressArmL and hovered then
                state.values.progressLabelIndex = cycleIndex(progressLabelIndex, 1, 2);
                writeDebugLog(string.format('progress toggle release L: index=%s', tostring(state.values.progressLabelIndex)));
            end
            state.values.progressArmL = false;
        end
        if rReleased then
            if state.values.progressArmR and hovered then
                state.values.progressLabelIndex = cycleIndex(progressLabelIndex, 1, 2, -1);
                writeDebugLog(string.format('progress toggle release R: index=%s', tostring(state.values.progressLabelIndex)));
            end
            state.values.progressArmR = false;
        end

        state.values.progressMouseLPrev = lDown;
        state.values.progressMouseRPrev = rDown;

        if settings.general.showToolTips and hovered then
            imgui.SetTooltip("Progress to target value. Click to toggle label (value/target or %).");
        end
        imgui.EndChild();
    end
    -- /MAIN_HEADER

    imguiHalfSep(true);

    -- Use dedicated metrics text tuning for metric-heavy sections.
    setWindowFontScale(state.window.metricsTextScale);
    logScaleSnapshot("main_metrics_block", "");

    -- totals metrics
    for total, metric in pairs(table.sortKeysByLength(metrics[state.gathering].totals, true)) do
        if state.gathering == "digging" and metric == "breaks" then
            if imguiShowToolTip("Current Moon percentage.", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            imgui.Text(string.format("%s:", string.upperfirst("Moon")));
            imgui.SameLine();
            local memMgr = AshitaCore:GetMemoryManager();
            local party = memMgr:GetParty();
            local moonPct = party and tostring(party:GetMoonPercent()) or "0";
            imgui.TextUnformatted(moonPct.."%");
        else
            if imguiShowToolTip(metricsTotalsToolTips[metric], settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            imgui.Text(string.format("%s:", string.upperfirst(metric)));
            if settings.general.showToolTips and imgui.IsItemHovered() then
                imgui.SetTooltip(tostring(metricsTotalsToolTips[metric] or ""));
            end
            imgui.SameLine();
            imgui.Text(tostring(metrics[state.gathering].totals[metric]))
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
                imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.615, 0.615, 1 }); -- danger
            elseif pzDiff <= state.values.clamBucketPzMax/2 then
                imgui.PushStyleColor(ImGuiCol_Text, { 1, 1, 0.54, 1 }); -- warn
            else
                imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1 }); -- plain
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
        imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.615, 0.615, 1 }); -- danger
    else
        if state.gathering == "clamming" and state.values.clamBucketBroken then
            imgui.PushStyleColor(ImGuiCol_Text, { 1, 1, 0.54, 1 }); -- warn
        else
            imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1 }); -- plain
        end
    end

    local toolName = string.lowerToTitle(gatherData.tool)
    if not table.hasvalue({"fishing", "clamming"}, gatherData.name) then
        toolName = toolName.."s"
    end
    imgui.Text(toolName..":");
    if settings.general.showToolTips and imgui.IsItemHovered() then
        imgui.SetTooltip("Current tool count for this gathering type.");
    end
    imgui.SameLine();

    local value = tostring(avail);
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
        imgui.PushStyleColor(ImGuiCol_Text, { 1, 1, 0.54, 1 }); -- warn
    elseif availPct < 25 then
        imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.615, 0.615, 1 }); -- danger
    else
        imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1 }); -- plain
    end
    imgui.Text("Inventory:")
    if settings.general.showToolTips and imgui.IsItemHovered() then
        imgui.SetTooltip("Available slots in your main inventory.");
    end
    imgui.SameLine();

    local avail = playerStorage['available'] or 0;
    if state.values.zoning then avail = state.values.preZoneCounts['available']; end

    imgui.Text(tostring(avail));
    imgui.PopStyleColor();
    -- /inventory

    -- time passed
    if imguiShowToolTip(string.format("Time passed since your first %s attempt or when the timer was manually started.", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end
    imgui.Text("Time Passed:");
    if settings.general.showToolTips and imgui.IsItemHovered() then
        imgui.SetTooltip("Elapsed timer used for /HR calculations.");
    end
    imgui.SameLine();
    local r, g, b, a = 1, 0.615, 0.615, 1 -- danger
    if state.timers[state.gathering] then
        r, g, b, a = 0.77, 0.83, 0.80, 1 -- plain
    end
    imgui.TextColored({ r, g, b, a }, formatElapsedTime(metrics[state.gathering].secondsPassed))
    -- /time passed

    imgui.Spacing();

    -- timer
    if imguiShowToolTip(string.format("Start, stop, or clear the %s timer.", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end
    imgui.Text("Timer:")
    if settings.general.showToolTips and imgui.IsItemHovered() then
        imgui.SetTooltip("Start or stop tracking elapsed time for this session.");
    end
    imgui.SameLine();
    if uiSmallButton(state.values.btnStartTimer) then
        state.timers[state.gathering] = not state.timers[state.gathering];
    end
    if state.timers[state.gathering] then
        state.values.btnStartTimer = "Stop";
    else
        state.values.btnStartTimer = "Start";
    end
    imgui.SameLine();
    if uiSmallButton("Clear") then
        state.timers[state.gathering] = false;
        metrics[state.gathering].secondsPassed = 0;
    end
    -- /timer

    imguiHalfSep();
    imgui.AlignTextToFramePadding();
    -- value
    imgui.PushStyleColor(ImGuiCol_Text, { 0.39, 0.96, 0.13, 1 }); -- success
    if imguiShowToolTip(string.format("Editable estimated value of all %s yields (yield prices adjusted within settings).", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end

    imgui.Text("Value:")
    if settings.general.showToolTips and imgui.IsItemHovered() then
        imgui.SetTooltip("Estimated total value from tracked yields and configured prices.");
    end
    if settings.general.showToolTips then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    else
        imgui.SameLine();
    end

    imgui.PushItemWidth(-1);
    if (imgui.InputInt('', uiVariables[string.format("var_%s_estimatedValue", state.gathering)])) then
        metrics[state.gathering].estimatedValue = imgui.GetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)]);
        checkTargetAlertReady();
    end
    imgui.PopStyleColor();
    imgui.PopItemWidth();
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
    imgui.AlignTextToFramePadding();
    local plotYieldsLabel = yieldsLabelMap[state.values.yieldsLabelIndex];
    if imguiShowToolTip(string.format("Plot histogram of %s yields per hour (L/R click on the plot to cycle its label displays).", string.upperfirst(state.gathering)), settings.general.showToolTips) then
        imgui.SameLine(0.0, state.window.spaceToolTip);
    end

    local yieldsPerHour = metrics[state.gathering].points.yields[#metrics[state.gathering].points.yields];
    local targetYields = 120;
    if state.gathering == "fishing" then targetYields = 90; end
    local yieldsPlotMin, yieldsPlotMax = getPlotRange(plotYields, nil, string.format('%s:yields', tostring(state.gathering)));

    if yieldsPerHour < targetYields and yieldsPerHour >= targetYields/2 then
        imgui.PushStyleColor(ImGuiCol_Text, { 1, 1, 0.54, 1 }); -- warn
    elseif yieldsPerHour < targetYields/2 then
        imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.615, 0.615, 1 }); -- danger
    else
        imgui.PushStyleColor(ImGuiCol_Text, { 0.39, 0.96, 0.13, 1 }); -- success
    end
    imgui.PushStyleColor(ImGuiCol.PlotHistogramHovered, { 0.77, 0.83, 0.80, 0.3 });

    imgui.PlotHistogram("", plotYields, #plotYields, 0, plotYieldsLabel, yieldsPlotMin, yieldsPlotMax, { 0.0, state.window.heightPlot });
    imgui.PopStyleColor(2)
    if imgui.IsItemClicked() then
        state.values.yieldsLabelIndex = cycleIndex(state.values.yieldsLabelIndex, 1, 3);
    end
    if imgui.IsItemClicked(1) then
        state.values.yieldsLabelIndex = cycleIndex(state.values.yieldsLabelIndex, 1, 3, -1);
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip(string.format(
            "Yields/HR trend\nCurrent: %.2f\nRange: 0 to session high-water\nL/R click: cycle label format",
            yieldsPerHour
        ));
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
    local valuesPlotMin, valuesPlotMax = getPlotRange(plotValues, nil, string.format('%s:values', tostring(state.gathering)));

    if valuesPerHour < targetValue and valuesPerHour >= targetValue/2 then
        imgui.PushStyleColor(ImGuiCol_Text, { 1, 1, 0.54, 1 }); -- warn
    elseif valuesPerHour < targetValue/2 then
        imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.615, 0.615, 1 }); -- danger
    else
        imgui.PushStyleColor(ImGuiCol_Text, { 0.39, 0.96, 0.13, 1 }); -- success
    end

    imgui.PlotLines("", plotValues, #plotValues, 0, plotValuesLabel, valuesPlotMin, valuesPlotMax, { 0.0, state.window.heightPlot });
    imgui.PopStyleColor()
    if imgui.IsItemClicked() then
        state.values.valuesLabelIndex = cycleIndex(state.values.valuesLabelIndex, 1, 3);
    end
    if imgui.IsItemClicked(1) then
        state.values.valuesLabelIndex = cycleIndex(state.values.valuesLabelIndex, 1, 3, -1);
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip(string.format(
            "Value/HR trend\nCurrent: %.2f\nRange: 0 to session high-water\nL/R click: cycle label format",
            valuesPerHour
        ));
    end
    -- /plot values
    imgui.PopItemWidth();
    imguiFullSep();

    -- MAIN_SCROLLING
    setWindowFontScale(state.window.textScale);
    imgui.AlignTextToFramePadding();
    -- Intentionally no section-level tooltip here; row controls have explicit tooltips.

    yieldsSortMap = {}
    local sortedOk = runSafe(string.format('build_yieldsSortMap_%s', tostring(state.gathering)), function()
        yieldsSortMap =
        {
            [1] = { table.sortKeysByAlphabet(metrics[state.gathering].yields, false), "Alphabetical (DESC)" },
            [2] = { table.sortKeysByAlphabet(metrics[state.gathering].yields, true), "Alphabetical (ASC)" },
            [3] = { table.sortbykey(metrics[state.gathering].yields, false), "Count (DESC)" },
            [4] = { table.sortbykey(metrics[state.gathering].yields, true), "Count (ASC)" },
            [5] = { table.sortKeysByTotalValue(metrics[state.gathering].yields, false), "Value (DESC)" },
            [6] = { table.sortKeysByTotalValue(metrics[state.gathering].yields, true), "Value (ASC)"}
        }
    end);
    if not sortedOk then
        yieldsSortMap =
        {
            [1] = { {}, "Alphabetical (DESC)" },
            [2] = { {}, "Alphabetical (ASC)" },
            [3] = { {}, "Count (DESC)" },
            [4] = { {}, "Count (ASC)" },
            [5] = { {}, "Value (DESC)" },
            [6] = { {}, "Value (ASC)"}
        }
    end

    local uiSpace = state.window.ui and state.window.ui.space or nil;
    local mainFooterButtonHeight, mainFooterSymPad, mainFooterBottomPadTarget, footerReserve = calcFooterMetrics();
    if imgui.BeginChild("Scrolling", { -1, -footerReserve }, true) then
        -- Reset per-frame button-hover guard so list sorting clicks cannot get stuck disabled.
        state.values.yieldListBtnsHovered = false;
        local yieldListRowHovered = false;
        local mousePos = nil;
        local mouseY = nil;
        if imgui.GetMousePos ~= nil then
            mousePos = imgui.GetMousePos();
            if type(mousePos) == "table" then
                mouseY = tonumber(mousePos.y or mousePos[2]);
            end
        end
        -- yields
        for _, item in pairs(yieldsSortMap[state.values.yieldSortIndex][1]) do
            imgui.PushID(item);
            local rowCount = tonumber(metrics[state.gathering].yields[item]) or 0;
            local rowPrice = tonumber(getPrice(item)) or 0;
            local rowTotal = math.floor(rowPrice * rowCount);
            local rowTooltip = string.format("%s\nCount: %d\nPrice: %d ea\nTotal: %d", tostring(item), rowCount, rowPrice, rowTotal);
            local rowAdjustButtonHovered = false;
            imgui.BeginGroup();
            imgui.BeginGroup();
            uiSmallButton("-");
            if settings.general.showToolTips and imgui.IsItemHovered() then
                yieldListRowHovered = true;
                state.values.yieldListBtnsHovered = true;
                rowAdjustButtonHovered = true;
                imgui.SetTooltip(string.format("Subtract 1 %s\nCurrent: %d", tostring(item), rowCount));
            end
            if imgui.IsItemClicked() then
                yieldListRowHovered = true;
                adjYield(item, -1);
                adjTotal("yields", -1);
                local val = getPrice(item);
                local curVal = metrics[state.gathering].estimatedValue;
                metrics[state.gathering].estimatedValue = curVal - val;
                imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)], metrics[state.gathering].estimatedValue);
            end
            imgui.SameLine(0.0, 1.0);
            uiSmallButton("+");
            if settings.general.showToolTips and imgui.IsItemHovered() then
                yieldListRowHovered = true;
                state.values.yieldListBtnsHovered = true;
                rowAdjustButtonHovered = true;
                imgui.SetTooltip(string.format("Add 1 %s\nCurrent: %d", tostring(item), rowCount));
            end
            if imgui.IsItemClicked() then
                yieldListRowHovered = true;
                adjYield(item, 1);
                adjTotal("yields", 1);
                local val = getPrice(item);
                local curVal = metrics[state.gathering].estimatedValue;
                metrics[state.gathering].estimatedValue = curVal + val;
                imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", state.gathering)], metrics[state.gathering].estimatedValue);
            end
            imgui.EndGroup();
            if imgui.IsItemHovered() then
                yieldListRowHovered = true;
                state.values.yieldListBtnsHovered = true;
                if settings.general.showToolTips and not rowAdjustButtonHovered then
                    imgui.SetTooltip(string.format("Adjust %s count", tostring(item)));
                end
            end
            imgui.SameLine(0.0, state.window.spaceToolTip);
            local yieldSettings = settings.yields[state.gathering][item];
            if yieldSettings == nil then
                writeDebugLog(string.format('WARN missing yield settings for display: gather=%s item=%s', tostring(state.gathering), tostring(item)));
                yieldSettings = { color = getDefaultYieldColorInt(), short = nil };
            end
            local r, g, b, a = colorToRGBA(yieldSettings.color);
            if a == nil or a <= 0 then a = 255; end

            local shortName = yieldSettings.short;
            local adjItemName = shortName or item;

            imgui.TextColored({ r/255, g/255, b/255, a/255 }, adjItemName..":");
            if imgui.IsItemHovered() then
                yieldListRowHovered = true;
                if settings.general.showToolTips then
                    imgui.SetTooltip(rowTooltip);
                end
            end

            imgui.SameLine(0.0, state.window.spaceToolTip);
            imgui.Text(tostring(metrics[state.gathering].yields[item]));
            if imgui.IsItemHovered() then
                yieldListRowHovered = true;
                if settings.general.showToolTips then
                    imgui.SetTooltip(rowTooltip);
                end
            end

            if settings.general.showDetailedYields then
                local r, g, b, a = colorToRGBA(settings.general.yieldDetailsColor);
                if a == nil or a <= 0 then a = 255; end
                imgui.TextColored({ r/255, g/255, b/255, a/255 }, string.format("@%dea.=(%s)", getPrice(item), math.floor(getPrice(item) * metrics[state.gathering].yields[item])));
                if imgui.IsItemHovered() then
                    yieldListRowHovered = true;
                    if settings.general.showToolTips then
                        imgui.SetTooltip(rowTooltip);
                    end
                end
            end
            imgui.EndGroup();
            if mouseY ~= nil and imgui.GetItemRectMin ~= nil and imgui.GetItemRectMax ~= nil then
                local rowRectMin = imgui.GetItemRectMin();
                local rowRectMax = imgui.GetItemRectMax();
                if type(rowRectMin) == "table" and type(rowRectMax) == "table" then
                    local rowMinY = tonumber(rowRectMin.y or rowRectMin[2]);
                    local rowMaxY = tonumber(rowRectMax.y or rowRectMax[2]);
                    if rowMinY ~= nil and rowMaxY ~= nil and mouseY >= rowMinY and mouseY <= rowMaxY then
                        yieldListRowHovered = true;
                    end
                end
            end
            if imgui.IsItemHovered() then
                yieldListRowHovered = true;
                if settings.general.showToolTips and not rowAdjustButtonHovered then
                    imgui.SetTooltip(rowTooltip);
                end
            end
            imgui.PopID();
        end
        imgui.EndChild();
        if imgui.IsItemClicked() then
            state.values.yieldListClicked = true;
            if not state.values.yieldListBtnsHovered and not yieldListRowHovered then
                state.values.yieldSortIndex = cycleIndex(state.values.yieldSortIndex, 1, 6);
                writeDebugLog(string.format('yield list sort click L: index=%s', tostring(state.values.yieldSortIndex)));
            else
                writeDebugLog('yield list sort blocked L: row/item hover active');
            end
        end
        if imgui.IsItemClicked(1) then
            state.values.yieldListClicked = true;
            if not state.values.yieldListBtnsHovered and not yieldListRowHovered then
                state.values.yieldSortIndex = cycleIndex(state.values.yieldSortIndex, 1, 6, -1);
                writeDebugLog(string.format('yield list sort click R: index=%s', tostring(state.values.yieldSortIndex)));
            else
                writeDebugLog('yield list sort blocked R: row/item hover active');
            end
        end
        state.values.yieldListHovered = false;
        if not imgui.IsMouseDown(1) and not imgui.IsMouseDown(0) then
            state.values.yieldListClicked = false;
        end
        -- /yields
    end
    -- /MAIN_SCROLLING

    local mainFooterOpened = imgui.BeginChild("MainFooterRow", { -1, footerReserve }, false, bit.bor(ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoScrollWithMouse));
    local footerLabels = { "Exit", "Reload", "Reset", "Settings", "Help" };
    local footerStartX = imgui.GetCursorPosX();
    local footerStartY = imgui.GetCursorPosY();
    local footerAvail = imgui.GetContentRegionAvail();
    local footerAvailX, footerAvailY = getAvailXY(footerAvail, footerReserve);
    local footerRowOffset = math.max(0.0, (footerAvailY - mainFooterButtonHeight) * 0.5);
    local footerRowY = footerStartY + footerRowOffset;
    local footerTopPad = footerRowOffset;
    local footerBottomPad = math.max(0.0, footerAvailY - footerRowOffset - mainFooterButtonHeight);
    local footerWidths = {};
    for i, label in ipairs(footerLabels) do
        footerWidths[i] = estimateButtonWidthForButtons(label, false);
    end
    local footerMinGap = (uiSpace and tonumber(uiSpace.footerMinGap)) or state.window.spaceFooterBtn or 0.0;
    local footerPositions, footerGap, footerEdge, footerWidthTotal =
        computeFlushRowPositions(footerStartX, footerAvailX, footerWidths, footerMinGap);
    logLayoutBreadcrumb("footer_main_even", string.format(
        "count=%d startY=%.1f avail=(%.1f,%.1f) total=%.1f gap=%.1f edge=%.1f btnH=%.1f symPad=%.1f topPad=%.1f bottomPad=%.1f",
        #footerLabels,
        tonumber(footerStartY) or 0.0,
        tonumber(footerAvailX) or 0.0, tonumber(footerAvailY) or 0.0,
        tonumber(footerWidthTotal) or 0.0, tonumber(footerGap) or 0.0, tonumber(footerEdge) or 0.0,
        tonumber(mainFooterButtonHeight) or 0.0, tonumber(mainFooterSymPad) or 0.0,
        tonumber(footerTopPad) or 0.0, tonumber(footerBottomPad) or 0.0
    ));
    local function setFooterButtonPos(index)
        local x = footerPositions[index] or footerStartX;
        imgui.SetCursorPosX(x);
        imgui.SetCursorPosY(footerRowY);
    end
    local function mainFooterButton(label, index)
        return uiButton(label, { tonumber(footerWidths[index]) or 0.0, mainFooterButtonHeight });
    end

    setFooterButtonPos(1);
    local exitPressed = mainFooterButton("Exit", 1);
    logFooterItemRect("main_left", "Exit", footerRowY, footerReserve);
    if exitPressed then
        writeDebugLog('Exit button clicked');
        openConfirmModal(
            "Exit",
            "(All gathering data will be saved.)",
            false,
            function()
                queueAddonCommand('/addon unload yield');
            end
        );
    end

    setFooterButtonPos(2);
    if mainFooterButton("Reload", 2) then
        writeDebugLog('Reload button clicked');
        openConfirmModal(
            "Reload",
            "(All gathering data will be saved.)",
            false,
            function()
                queueAddonCommand('/addon reload yield');
            end
        );
    end

    setFooterButtonPos(3);
    if mainFooterButton("Reset", 3) then
        writeDebugLog(string.format('Reset button clicked gather=%s', tostring(state.gathering)));
        openConfirmModal(
            "Reset",
            string.format("(Current %s data will be lost.)", string.upperfirst(state.gathering)),
            true,
            function()
                writeDebugLog(string.format('Reset confirmed gather=%s', tostring(state.gathering)));
                local gather = state.gathering;
                -- Try report generation, but never block reset on report errors.
                if settings.general.autoGenReports then
                    runSafe(string.format('reset_generate_report_%s', tostring(gather)), function()
                        generateGatheringReport(gather);
                    end);
                end
                -- Reset the metrics..
                metrics[gather] = table.copy(metricsTemplate);
                if state.values ~= nil and state.values.plotHighWater ~= nil then
                    state.values.plotHighWater[string.format('%s:yields', tostring(gather))] = nil;
                    state.values.plotHighWater[string.format('%s:values', tostring(gather))] = nil;
                end
                -- Reset the timers..
                for timerName, _ in pairs(state.timers) do
                    state.timers[timerName] = false;
                end
                -- Reset ui variables..
                imgui.SetVarValue(uiVariables[string.format("var_%s_estimatedValue", gather)], metrics[gather].estimatedValue);
                -- Reset the zones..
                settings.zones[gather] = {};
                state.values.lastKnownGathering = nil;
                if gather == "clamming" then
                    state.values.clamConfirmedYields = {};
                    state.values.clamBucketPz = 0;
                end
                trySaveSettings(string.format('reset_confirm_%s', tostring(gather)), true);
            end
        );
    end

    setFooterButtonPos(4);
    if mainFooterButton("Settings", 4) then
        if imgui.GetVarValue(uiVariables["var_HelpVisible"]) then
            imgui.SetVarValue(uiVariables["var_HelpVisible"], false);
        end
        imgui.SetVarValue(uiVariables["var_SettingsVisible"], true);
        state.values.centerWindow = true;
    end

    setFooterButtonPos(5);
    local helpPressed = mainFooterButton("Help", 5);
    logFooterItemRect("main_right", "Help", footerRowY, footerReserve);
    if helpPressed then
        if imgui.GetVarValue(uiVariables["var_SettingsVisible"]) then
            imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
        end
        imgui.SetVarValue(uiVariables["var_HelpVisible"], true);
        state.values.centerWindow = true;
    end
    if not mainFooterOpened then
        logLayoutBreadcrumb("footer_main_even", "child_open=false");
    end
    imgui.EndChild();

    -- CONFIRM
    local io = imgui.GetIO();
    local modalWidth, modalHeight = state.window.widthModalConfirm, state.window.heightModalConfirm;
    local modalX = (io.DisplaySize.x * 0.5) - (modalWidth * 0.5);
    local modalY = (io.DisplaySize.y * 0.5) - (modalHeight * 0.5);
    imgui.SetNextWindowSize({ modalWidth, modalHeight }, ImGuiCond.Always)
    imgui.SetNextWindowPos({ io.DisplaySize.x * 0.5, io.DisplaySize.y * 0.5 }, ImGuiCond.Always, { 0.5, 0.5 });
    if state.values.openConfirmRequested then
        writeDebugLog(string.format('confirm modal requested open prompt=%s', tostring(state.values.modalConfirmPrompt)));
        imgui.OpenPopup("Yield Confirm");
        state.values.openConfirmRequested = false;
    end
    imgui.PushStyleVar(ImGuiStyleVar.Alpha, 1.0);
    if imgui.BeginPopupModal("Yield Confirm", imgui.GetVarValue(uiVariables['var_WindowVisible']), bit.bor(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoCollapse)) then
        setWindowFontScale(state.window.textScale);
        logScaleSnapshot("confirm", "");
        local handledByButton = false;
        imgui.Text(state.values.modalConfirmPrompt);
        imgui.Spacing();
        if state.values.modalConfirmHelp then
            local r, g, b, a = 0.39, 0.96, 0.13, 1
            if state.values.modalConfirmDanger then
                r, g, b, a =  1, 0.615, 0.615, 1
            end
            imgui.TextColored({ r, g, b, a }, state.values.modalConfirmHelp);
        end
        imguiFullSep();
        if uiButtonCompact("Yes") or state.initializing then
            handledByButton = true;
            imgui.CloseCurrentPopup();
            state.actions.modalCancelAction = function() end
            writeDebugLog('confirm modal: YES');
            local action = state.actions and state.actions.modalConfirmAction or nil;
            if type(action) == 'function' then
                local ok, err = pcall(action);
                if not ok then
                    writeDebugLog(string.format('ERROR confirm action: %s', tostring(err)));
                    writeDebugLog(debug.traceback());
                end
            else
                writeDebugLog('ERROR confirm action missing or not a function');
            end
        end
        imgui.SameLine(0.0, 10);
        if uiButtonCompact("No") then
            handledByButton = true;
            imgui.CloseCurrentPopup();
            state.actions.modalConfirmAction = function() end
            writeDebugLog('confirm modal: NO');
            local cancelAction = state.actions and state.actions.modalCancelAction or nil;
            if type(cancelAction) == 'function' then
                local ok, err = pcall(cancelAction);
                if not ok then
                    writeDebugLog(string.format('ERROR cancel action: %s', tostring(err)));
                    writeDebugLog(debug.traceback());
                end
            else
                writeDebugLog('ERROR cancel action missing or not a function');
            end
        end
        imgui.SameLine();
        imgui.Text("OR click away to cancel.");

        if not handledByButton and type(imgui.IsMouseClicked) == 'function' then
            local suppressClickAway = state.values.confirmIgnoreClickAway == true;
            if suppressClickAway then
                local mouseDown = false;
                local okDown, downResult = pcall(function() return imgui.IsMouseDown(0); end);
                if okDown then
                    mouseDown = downResult == true;
                end
                if not mouseDown then
                    state.values.confirmIgnoreClickAway = false;
                    suppressClickAway = false;
                end
            end

            local mouseClicked = false;
            local okClick, clickResult = pcall(function() return imgui.IsMouseClicked(0); end);
            if okClick then
                mouseClicked = clickResult == true;
            else
                local okClickAlt, clickAltResult = pcall(function() return imgui.IsMouseClicked(); end);
                mouseClicked = okClickAlt and clickAltResult == true;
            end

            if mouseClicked and not suppressClickAway then
                local mx, my = io.MousePos.x, io.MousePos.y;
                local outside = (mx < modalX) or (mx > (modalX + modalWidth)) or (my < modalY) or (my > (modalY + modalHeight));
                if outside then
                    handledByButton = true;
                    imgui.CloseCurrentPopup();
                    state.actions.modalConfirmAction = function() end;
                    writeDebugLog('confirm modal: click-away cancel');
                    local cancelAction = state.actions and state.actions.modalCancelAction or nil;
                    if type(cancelAction) == 'function' then
                        local ok, err = pcall(cancelAction);
                        if not ok then
                            writeDebugLog(string.format('ERROR click-away cancel action: %s', tostring(err)));
                            writeDebugLog(debug.traceback());
                        end
                    end
                end
            end
        end
        if state.initializing then
            imgui.CloseCurrentPopup();
            imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
        end
        imgui.EndPopup();
    else
        state.values.modalConfirmPrompt = ""
        state.values.modalConfirmHelp   = ""
        state.values.modalConfirmDanger = false
        state.values.confirmIgnoreClickAway = false
    end
    imgui.PopStyleVar();
    -- /CONFIRM

    state.initializing = false
    -- /MAIN

    state.window.posX, state.window.posY = imgui.GetWindowPos();

    imgui.PopStyleColor();
    imgui.End();

    -- SETTINGS
    if imgui.GetVarValue(uiVariables["var_SettingsVisible"]) then
        if not state.values.settingsWindowOpen then
            -- Re-sync UI vars from persisted settings whenever Settings opens.
            -- This keeps all color pickers aligned with saved values after reloads.
            loadUiVariables();
            commitSettingsSnapshot();
            state.values.settingsJustOpened = true;
            state.values.settingsStatusText = "";
            state.values.settingsStatusUntil = 0;
        end
        state.values.settingsWindowOpen = true;
        SettingsWindow:Draw("Yield Settings")
    elseif state.values.settingsWindowOpen then
        writeDebugLog('Settings window closed');
        state.values.settingsWindowOpen = false;
        state.values.settingsJustOpened = false;
        if type(state.values.settingsSnapshot) == 'table' then
            local dirtyOnClose = hasPendingSettingsChanges();
            if dirtyOnClose then
                local ok = trySaveSettings('settings_window_close', true);
                writeDebugLog(string.format('settings window close auto-save ok=%s', tostring(ok)));
                if ok then
                    commitSettingsSnapshot();
                else
                    -- Preserve previous behavior on save failure: restore last snapshot.
                    SettingsWindow:modalCancelAction(true);
                end
            else
                state.values.settingsSnapshot = nil;
                state.values.settingsUiSnapshotFingerprint = nil;
            end
        else
            state.values.settingsUiSnapshotFingerprint = nil;
        end
    end
    -- /SETTINGS

    -- HELP
    if imgui.GetVarValue(uiVariables["var_HelpVisible"]) then
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
    pushSettingsPageMenuBarSizing();
    if imgui.BeginChild("General", { -1, state.window.heightSettingsContent }, imgui.GetVarValue(uiVariables['var_WindowVisible']), bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize)) then
        setWindowFontScale(state.window.textScale);
        imgui.PushItemWidth(state.window.widthWidgetDefault);
        renderSettingsTitleBar("General");
        renderSettingsPageStatusRow();
        imgui.TextColored(SETTINGS_HEADER_TEXT_COLOR, "Window");
        imguiFullSep();

        -- Opacity
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Current alpha channel value of all Yield windows.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.SliderFloat("Window Opacity", uiVariables['var_WindowOpacity'], 0.25, 1.0, "%1.2f")) then
            settings.general.opacity = imgui.GetVarValue(uiVariables['var_WindowOpacity'])
        end
        -- /Opacity

        imgui.Spacing();

        -- Scale
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Current size for all Yield windows.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if imgui.SliderFloat("Window Scale", uiVariables['var_WindowScale'], windowScaleMin, windowScaleMax, "%.2fx") then
            syncWindowScaleSettings(imgui.GetVarValue(uiVariables['var_WindowScale']));
        end
        if imgui.InputInt("Window Scale %", uiVariables['var_WindowScalePct']) then
            syncWindowScaleSettings(percentToScale(imgui.GetVarValue(uiVariables['var_WindowScalePct'])));
        end
        -- /Scale

        imguiFullSep();

        imgui.TextColored({ 1, 1, 0.54, 1 }, "Gathering")

        imguiFullSep();

        -- Target Value
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Amount you would like to earn this session (affects progress bar).", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.InputInt("Target Value", uiVariables['var_TargetValue'])) then
            settings.general.targetValue = imgui.GetVarValue(uiVariables['var_TargetValue']);
        end
        -- /Target Value

        imgui.Spacing();

        -- Target Sound
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Sound that will be played when you reach your target value (will only play if your target is reached through gathering).", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if uiButton("Play") then
        end
        if imgui.IsItemClicked() then
            local soundFile = imgui.GetVarValue(uiVariables["var_TargetSoundFile"]);
            if soundFile ~= "" then
                ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
            end
        end
        imgui.SameLine();
        imgui.PushItemWidth(state.window.widthWidgetValue);
        if imgui.Combo("Target Alert", uiVariables["var_TargetSoundIndex"], getSoundOptions()) then
            local soundIndex = imgui.GetVarValue(uiVariables["var_TargetSoundIndex"]);
            local soundFile = sounds[soundIndex];
            imgui.SetVarValue(uiVariables["var_TargetSoundFile"], "");
            imgui.SetVarValue(uiVariables["var_TargetSoundFile"], soundFile);
        end
        imgui.PopItemWidth();
        -- /Target Sound

        -- Detailed Yields
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Toggles the display of the math breakdown in the scrollable yields list.", settings.general.showToolTips) then
            imgui.SameLine(0.0 , state.window.spaceToolTip);
        end
        if (imgui.Checkbox("Show Detailed Yields", uiVariables['var_ShowDetailedYields'])) then
            settings.general.showDetailedYields = imgui.GetVarValue(uiVariables['var_ShowDetailedYields']);
        end
        -- /Detailed Yields

        imgui.Spacing();

        -- Yield Details Color
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Set the color of the math breakdown in the scrollable yields list.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if imgui.ColorEdit4("Yield Details Color", uiVariables["var_YieldDetailsColor"]) then
            local converted, cr, cg, cb = getOpaqueYieldDetailsColorFromVar("general.yieldDetailsColor");
            settings.general.yieldDetailsColor = converted;
            writeDebugLog(string.format('general yieldDetailsColor changed rgb=(%.3f,%.3f,%.3f)', tonumber(cr) or 0.0, tonumber(cg) or 0.0, tonumber(cb) or 0.0));
        end
        -- /Yield Details Color

        imgui.Spacing();

        -- Sound Alerts
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Toggles the set sound alerts for incoming yields.", settings.general.showToolTips) then
            imgui.SameLine(0.0 , state.window.spaceToolTip);
        end
        if (imgui.Checkbox("Enable Sound Alerts", uiVariables['var_EnableSoundAlerts'])) then
            settings.general.enableSoundAlerts = imgui.GetVarValue(uiVariables['var_EnableSoundAlerts']);
        end
        -- /Sound Alerts

        -- Reports
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Toggles automatic report generation when zoning or after a data reset (you may still manually generate a report regardless).", settings.general.showToolTips) then
            imgui.SameLine(0.0 , state.window.spaceToolTip);
        end
        if (imgui.Checkbox("Auto Generate Reports", uiVariables['var_AutoGenReports'])) then
            settings.general.autoGenReports = imgui.GetVarValue(uiVariables['var_AutoGenReports']);
        end
        -- /Reports

        imguiFullSep();

        imgui.TextColored({ 1, 1, 0.54, 1 }, "Misc") -- warn

        imguiFullSep();

        -- Image Buttons
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Toggles the display of images used for all gathering buttons. If off, text will be used instead.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.Checkbox('Use Image Buttons', uiVariables["var_UseImageButtons"])) then
            settings.general.useImageButtons = imgui.GetVarValue(uiVariables["var_UseImageButtons"]);
        end
        -- /Image Buttons

        -- Tooltips
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Toggles display of UI hover tooltips.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if (imgui.Checkbox('Show Tooltips', uiVariables['var_ShowToolTips'])) then
            settings.general.showToolTips = imgui.GetVarValue(uiVariables['var_ShowToolTips']);
        end
        -- /Tooltips

        imgui.Spacing();
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Open advanced scale and sizing tuning controls.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if uiButton("Scale Tuning") then
            syncScaleTuningVarsFromSettings();
            state.values.openScaleTuningRequested = true;
        end

        imgui.Spacing();
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Open the Help window with first-time guidance enabled for this session.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        if uiButton("Show First-Time Info") then
            state.firstLoad = true;
            state.help.activeIndex = 1;
            imgui.SetVarValue(uiVariables["var_HelpVisible"], true);
            imgui.SetVarValue(uiVariables["var_SettingsVisible"], false);
            state.values.centerWindow = true;
            writeDebugLog('manual first-time help requested from General settings');
        end

        imgui.PopItemWidth();

        imgui.EndChild()
    end
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsSetPrices
-- desc: Renders the Set Prices settings.
----------------------------------------------------------------------------------------------------
function renderSettingsSetPrices()
    local gathering = state.settings.setPrices.gathering

    pushSettingsPageMenuBarSizing();
    if imgui.BeginChild("Set Prices", { -1, state.window.heightSettingsContent }, imgui.GetVarValue(uiVariables['var_WindowVisible']), bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize)) then
        logScaleSnapshot("settings_prices_begin", "");
        local gatherBtnBoost = 1.18;
        local btnAction = function(data)
            runSafe(string.format('setPrices_btnAction_%s', tostring(data and data.name)), function()
                state.settings.setPrices.gathering = data.name;
                gathering = data.name;
            end);
        end
        renderSettingsTitleBar("Prices", gathering, btnAction, gatherBtnBoost);
        renderSettingsPageStatusRow();

        -- Columns
        imgui.SetCursorPosX(0);
        if imgui.BeginChild("Column Names", { imgui.GetWindowWidth(), state.window.heightPriceColumns }) then
            logScaleSnapshot("settings_prices_columns", "");
            local colGap = 4.0;
            local totalW = state.window.widthWidgetDefault;
            local colW = math.max(48.0, (totalW - (colGap * 2.0)) / 3.0);
            local headerStartX = imgui.GetCursorPosX();
            local labels = { "Stack", "Single", "NPC" };
            for idx, label in ipairs(labels) do
                local labelW = imgui.CalcTextSize(label);
                if type(labelW) == "table" and labelW.x ~= nil then labelW = labelW.x; end
                local cellX = headerStartX + ((idx - 1) * (colW + colGap));
                local centeredX = cellX + ((colW - (tonumber(labelW) or 0.0)) / 2.0);
                imgui.SetCursorPosX(centeredX);
                imgui.AlignTextToFramePadding();
                imgui.TextUnformatted(label);
                if idx < #labels then
                    imgui.SameLine();
                end
            end

            imgui.EndChild();
        end

        -- /Columns
        imgui.Separator();
        imgui.Spacing();
        -- Outer settings footer is now pinned; no internal reserve needed here.
        if imgui.BeginChild("Scrolling", { -1, 0 }) then
            logScaleSnapshot("settings_prices_list", "");
            for i, yield in pairs(table.sortKeysByAlphabet(settings.yields[gathering], true)) do
                local data = settings.yields[gathering][yield];
                 if data.id ~= nil then
                    imgui.AlignTextToFramePadding();
                    if imguiShowToolTip(string.format("Set single, stack, and npc prices for %s. Value uses priority: stack/stackSize, then single, then npc.", yield), settings.general.showToolTips) then
                        imgui.SameLine(0.0, state.window.spaceToolTip);
                    end
                    local adjItemName = data.short or yield;
                    local priceVarName = string.format("var_%s_%s_prices", gathering, yield);
                    local priceVar = uiVariables[priceVarName];
                    if priceVar == nil then
                        priceVar = { 0, 0, 0 };
                        uiVariables[priceVarName] = priceVar;
                    end
                    local storedSingle = tonumber(data.singlePrice) or 0;
                    local storedStack = tonumber(data.stackPrice) or 0;
                    local storedNpc = tonumber(data.npcPrice);
                    if storedNpc == nil then
                        storedNpc = tonumber(basePrices[data.id]) or 0;
                    end
                    local singlePrice, stackPrice, npcPrice = imgui.GetVarValue(priceVar);
                    if singlePrice == nil or stackPrice == nil or npcPrice == nil then
                        singlePrice = singlePrice ~= nil and tonumber(singlePrice) or storedSingle;
                        stackPrice = stackPrice ~= nil and tonumber(stackPrice) or storedStack;
                        npcPrice = npcPrice ~= nil and tonumber(npcPrice) or storedNpc;
                        imgui.SetVarValue(priceVar, singlePrice, stackPrice, npcPrice);
                    end
                    imgui.PushID(string.format("%s::%s", tostring(gathering), tostring(yield)));
                    local totalW = state.window.widthWidgetDefault;
                    local colGap = 4.0;
                    local stVar = { stackPrice or 0 };
                    local sVar = { singlePrice or 0 };
                    local nVar = { npcPrice or 0 };
                    local colW = math.max(48.0, (totalW - (colGap * 2.0)) / 3.0);
                    imgui.PushItemWidth(colW);
                    local changedStack = imgui.InputInt("##stack_price", stVar, 0, 0);
                    imgui.SameLine(0.0, colGap);
                    local changedSingle = imgui.InputInt("##single_price", sVar, 0, 0);
                    imgui.SameLine(0.0, colGap);
                    local changedNpc = imgui.InputInt("##npc_price", nVar, 0, 0);
                    imgui.PopItemWidth();
                    imgui.SameLine(0.0, state.window.spaceToolTip);
                    imgui.AlignTextToFramePadding();
                    imgui.TextUnformatted(adjItemName);
                    local s = math.max(0, tonumber(sVar[1]) or 0);
                    local st = math.max(0, tonumber(stVar[1]) or 0);
                    local n = math.max(0, tonumber(nVar[1]) or tonumber(basePrices[data.id]) or 0);
                    local changedAny = (changedStack or changedSingle or changedNpc) == true;
                    if changedAny or s ~= (tonumber(singlePrice) or 0) or st ~= (tonumber(stackPrice) or 0) or n ~= (tonumber(npcPrice) or 0) then
                        imgui.SetVarValue(priceVar, s, st, n);
                        settings.yields[gathering][yield].singlePrice = s;
                        settings.yields[gathering][yield].stackPrice = st;
                        settings.yields[gathering][yield].npcPrice = n;
                        writeDebugLog(string.format('setPrices sync gather=%s item=%s single=%d stack=%d npc=%d changed=%s',
                            tostring(gathering), tostring(yield), tonumber(s) or 0, tonumber(st) or 0, tonumber(n) or 0, tostring(changedAny)));
                    end
                    imgui.PopID();
                end
            end
            imgui.EndChild()
        end
        imgui.EndChild()
    end
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsSetColors
-- desc: Renders the Set Colors settings.
----------------------------------------------------------------------------------------------------
function renderSettingsSetColors()
    local gathering = state.settings.setColors.gathering;
    state.values.colorSelectionsByGather = state.values.colorSelectionsByGather or {};
    state.values.colorSelectionsByGather[gathering] = state.values.colorSelectionsByGather[gathering] or {};
    local selectedColors = state.values.colorSelectionsByGather[gathering];
    if state.values.setColorsBulkInitGather ~= gathering then
        syncAllColorsVarForGather(gathering, "setColors_page_enter");
        state.values.setColorsBulkInitGather = gathering;
    end
    pushSettingsPageMenuBarSizing();
    if imgui.BeginChild("Set Colors", { -1, state.window.heightSettingsContent }, imgui.GetVarValue(uiVariables['var_WindowVisible']), bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize)) then
        setWindowFontScale(state.window.textScale);
        logScaleSnapshot("settings_colors_begin", "");
        local gatherBtnBoost = 1.18;
        local btnAction = function(data)
            runSafe(string.format('setColors_btnAction_%s', tostring(data and data.name)), function()
                writeDebugLog(string.format('setColors switch: %s -> %s', tostring(gathering), tostring(data.name)));
                state.settings.setColors.gathering = data.name;
                gathering = data.name;
                syncAllColorsVarForGather(gathering, "setColors_switch");
                state.values.setColorsBulkInitGather = gathering;
            end);
        end
        renderSettingsTitleBar("Colors", gathering, btnAction, gatherBtnBoost);
        renderSettingsPageStatusRow();
        local sortedYields = table.sortKeysByAlphabet(settings.yields[gathering], true);
        local selectedCount = 0;
        for _, yName in ipairs(sortedYields) do
            if selectedColors[yName] then
                selectedCount = selectedCount + 1;
            end
        end
        logScaleSnapshot("settings_colors_list", "");
        local allSelected = (#sortedYields > 0 and selectedCount == #sortedYields);
        local selectAllVar = { allSelected };
        if imgui.Checkbox("##set_colors_select_all", selectAllVar) then
            local setSel = selectAllVar[1] == true;
            for _, yName in ipairs(sortedYields) do
                selectedColors[yName] = setSel;
            end
            selectedCount = setSel and #sortedYields or 0;
        end
        imgui.SameLine();
        imgui.TextUnformatted("Select All");
        imgui.SameLine();
        imgui.Text(string.format("(%d/%d)", selectedCount, #sortedYields));
        imgui.Spacing();
        imgui.Separator();
        -- All
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Set the text color for all yields when they are displayed in the yield list.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        local bulkColorLabel = "Set All##bulk_color_apply";
        if selectedCount > 0 then
            bulkColorLabel = "Set Selected##bulk_color_apply";
        end
        imgui.PushItemWidth(state.window.widthWidgetDefault);
        if imgui.ColorEdit4(bulkColorLabel, uiVariables["var_AllColors"]) then
            local color = getColorVarTable(uiVariables["var_AllColors"], "var_AllColors");
            writeDebugLog(string.format('setColors set-all raw gather=%s rgba=(%s,%s,%s,%s)',
                tostring(gathering), tostring(color[1]), tostring(color[2]), tostring(color[3]), tostring(color[4])));
            local sampleLogged = 0;
            local applySelectedOnly = selectedCount > 0;
            local appliedCount = 0;
            local converted = colorTableToInt({ color[1], color[2], color[3], 1.0 });
            for yield, data in pairs(settings.yields[gathering]) do
                if not applySelectedOnly or selectedColors[yield] then
                    local varName = string.format("var_%s_%s_color", gathering, yield);
                    uiVariables[varName] = uiVariables[varName] or { 1.0, 1.0, 1.0, 1.0 };
                    imgui.SetVarValue(uiVariables[varName], color[1], color[2], color[3], 1.0);
                    settings.yields[gathering][yield].color = converted;
                    appliedCount = appliedCount + 1;
                    if sampleLogged < 3 then
                        local vr, vg, vb, va = imgui.GetVarValue(uiVariables[varName]);
                        writeDebugLog(string.format('setColors set-all sample gather=%s item=%s var=(%s,%s,%s,%s) converted=%s stored=%s',
                            tostring(gathering), tostring(yield), tostring(vr), tostring(vg), tostring(vb), tostring(va), tostring(converted), tostring(settings.yields[gathering][yield].color)));
                        sampleLogged = sampleLogged + 1;
                    end
                end
            end
            writeDebugLog(string.format('setColors set-all applied gather=%s selectedOnly=%s applied=%d total=%d',
                tostring(gathering), tostring(applySelectedOnly), appliedCount, #sortedYields));
            syncGatherYieldColorVars(gathering);
            writeDebugLog(string.format('setColors set-all changed: gather=%s', tostring(gathering)));
        end
        imgui.PopItemWidth();
        -- All
        imgui.Spacing();
        imgui.Separator();
        for _, yield in ipairs(sortedYields) do
            imgui.AlignTextToFramePadding();
            local rowCheckVar = { selectedColors[yield] == true };
            if imgui.Checkbox(string.format("##set_color_chk_%s_%s", gathering, yield), rowCheckVar) then
                selectedColors[yield] = rowCheckVar[1] == true;
            end
            imgui.SameLine();
            if imguiShowToolTip(string.format("Set the text color for %s when its displayed in the yield list.", yield), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            local varName = string.format("var_%s_%s_color", gathering, yield);
            uiVariables[varName] = uiVariables[varName] or { 1.0, 1.0, 1.0, 1.0 };
            imgui.PushItemWidth(state.window.widthWidgetDefault);
            local shortName = settings.yields[gathering][yield].short;
            local adjItemName = shortName or yield;
            local rowColorLabel = string.format("##set_color_%s_%s", gathering, yield);
            if (imgui.ColorEdit4(rowColorLabel, uiVariables[varName])) then
                applyYieldColorFromVar(gathering, yield);
                writeDebugLog(string.format('setColors item changed: gather=%s item=%s', tostring(gathering), tostring(yield)));
            end
            imgui.PopItemWidth();
            imgui.SameLine();
            local vr, vg, vb, va = imgui.GetVarValue(uiVariables[varName]);
            imgui.TextColored(
                { tonumber(vr) or 1.0, tonumber(vg) or 1.0, tonumber(vb) or 1.0, tonumber(va) or 1.0 },
                adjItemName
            );
        end
        imgui.EndChild()
    end
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsSetAlerts
-- desc: Renders the Set Alerts settings.
----------------------------------------------------------------------------------------------------
function renderSettingsSetAlerts()
    local gathering = state.settings.setAlerts.gathering;
    state.values.soundSelectionsByGather = state.values.soundSelectionsByGather or {};
    state.values.soundSelectionsByGather[gathering] = state.values.soundSelectionsByGather[gathering] or {};
    local selectedSounds = state.values.soundSelectionsByGather[gathering];
    pushSettingsPageMenuBarSizing();
    if imgui.BeginChild("Set Alerts", { -1, state.window.heightSettingsContent }, imgui.GetVarValue(uiVariables['var_WindowVisible']), bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize)) then
        setWindowFontScale(state.window.textScale);
        local gatherBtnBoost = 1.18;
        local btnAction = function(data)
            runSafe(string.format('setAlerts_btnAction_%s', tostring(data and data.name)), function()
                state.settings.setAlerts.gathering = data.name;
                gathering = data.name;
                imgui.SetVarValue(uiVariables["var_AllSoundIndex"], 0);
            end);
        end
        renderSettingsTitleBar("Alerts", gathering, btnAction, gatherBtnBoost);
        renderSettingsPageStatusRow();
        local sortedYields = table.sortKeysByAlphabet(settings.yields[gathering], true);
        local defs = eventAlertDefs[gathering] or {};
        local soundTargets = {};
        for _, yName in ipairs(sortedYields) do
            table.insert(soundTargets, { key = yName, kind = "yield", ref = yName });
        end
        for _, def in ipairs(defs) do
            table.insert(soundTargets, { key = "__event:" .. tostring(def.key), kind = "event", ref = def.key });
        end
        if gathering == "fishing" then
            table.insert(soundTargets, { key = "__special:fishing_skill", kind = "special", ref = "fishing_skill" });
        end
        if gathering == "clamming" then
            table.insert(soundTargets, { key = "__special:clam_break", kind = "special", ref = "clam_break" });
        end
        local selectedCount = 0;
        for _, t in ipairs(soundTargets) do
            if selectedSounds[t.key] then
                selectedCount = selectedCount + 1;
            end
        end
        local allSelected = (#soundTargets > 0 and selectedCount == #soundTargets);
        local selectAllVar = { allSelected };
        if imgui.Checkbox("##set_alerts_select_all", selectAllVar) then
            local setSel = selectAllVar[1] == true;
            for _, t in ipairs(soundTargets) do
                selectedSounds[t.key] = setSel;
            end
        end
        imgui.SameLine();
        imgui.TextUnformatted("Select All");
        imgui.SameLine();
        imgui.Text(string.format("(%d/%d)", selectedCount, #soundTargets));
        imgui.Spacing();
        imgui.Separator();
        -- All
        imgui.AlignTextToFramePadding();
        if imguiShowToolTip("Set a sound alert for all yields.", settings.general.showToolTips) then
            imgui.SameLine(0.0, state.window.spaceToolTip);
        end
        local bulkSoundLabel = "Set All##bulk_sound_apply";
        if selectedCount > 0 then
            bulkSoundLabel = "Set Selected##bulk_sound_apply";
        end
        imgui.PushItemWidth(state.window.widthWidgetDefault);
        if imgui.Combo(bulkSoundLabel, uiVariables["var_AllSoundIndex"], getSoundOptions()) then
            local soundIndex = imgui.GetVarValue(uiVariables["var_AllSoundIndex"]);
            local soundFile = sounds[soundIndex];
            local applySelectedOnly = selectedCount > 0;
            for yield, data in pairs(settings.yields[gathering]) do
                if not applySelectedOnly or selectedSounds[yield] then
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)], soundIndex);
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)], "");
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)], soundFile);
                end
            end
            local applyFishingSkill = (not applySelectedOnly) or selectedSounds["__special:fishing_skill"] == true;
            local applyClamBreak = (not applySelectedOnly) or selectedSounds["__special:clam_break"] == true;
            if gathering == "fishing" and applyFishingSkill then
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundIndex"], soundIndex);
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"], "");
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"], soundFile);
            end
            if gathering == "clamming" and applyClamBreak then
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundIndex"], soundIndex);
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"], "");
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"], soundFile);
            end
            for _, def in ipairs(defs) do
                local eventKey = "__event:" .. tostring(def.key);
                if (not applySelectedOnly) or selectedSounds[eventKey] == true then
                    setAlertEventSound(gathering, def.key, soundIndex);
                end
            end
        end
        imgui.PopItemWidth();
        -- All
        imgui.Spacing();

        imgui.Separator();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Event Alerts");
        imgui.Separator();
        for _, def in ipairs(defs) do
            local idxVarName, fileVarName = getAlertEventVarNames(gathering, def.key);
            uiVariables[idxVarName] = uiVariables[idxVarName] or { 0 };
            uiVariables[fileVarName] = uiVariables[fileVarName] or { "" };
            imgui.AlignTextToFramePadding();
            local eventCheckKey = "__event:" .. tostring(def.key);
            local eventCheckVar = { selectedSounds[eventCheckKey] == true };
            if imgui.Checkbox(string.format("##set_alert_event_chk_%s_%s", gathering, def.key), eventCheckVar) then
                selectedSounds[eventCheckKey] = eventCheckVar[1] == true;
            end
            imgui.SameLine();
            if imguiShowToolTip(def.tip, settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if uiButton(string.format("Play##%s_%s", gathering, def.key)) then
                local soundFile = imgui.GetVarValue(uiVariables[fileVarName]);
                if soundFile ~= "" then
                    ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
                end
            end
            imgui.SameLine();
            imgui.PushItemWidth(state.window.widthWidgetDefault - 45);
            if imgui.Combo(def.label, uiVariables[idxVarName], getSoundOptions()) then
                local soundIndex = imgui.GetVarValue(uiVariables[idxVarName]);
                setAlertEventSound(gathering, def.key, soundIndex);
            end
            imgui.PopItemWidth();
        end
        if #defs > 0 then
            imgui.Separator();
        end

        --  Fishing Skillup
        if gathering == "fishing" then
            imgui.AlignTextToFramePadding();
            local fishCheckVar = { selectedSounds["__special:fishing_skill"] == true };
            if imgui.Checkbox("##set_alert_special_chk_fishing_skill", fishCheckVar) then
                selectedSounds["__special:fishing_skill"] = fishCheckVar[1] == true;
            end
            imgui.SameLine();
            if imguiShowToolTip("Set a sound alert for when you receive a fishing skill-up.", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if uiButton("Play##FishingSkill") then
                local soundFile = imgui.GetVarValue(uiVariables["var_FishingSkillSoundFile"]);
                if soundFile ~= "" then
                    ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
                end
            end
            imgui.SameLine();
            imgui.PushItemWidth(state.window.widthWidgetDefault - 45);
            if imgui.Combo("Skill-Up", uiVariables["var_FishingSkillSoundIndex"], getSoundOptions()) then
                local soundIndex = imgui.GetVarValue(uiVariables["var_FishingSkillSoundIndex"]);
                local soundFile = sounds[soundIndex];
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"], "");
                imgui.SetVarValue(uiVariables["var_FishingSkillSoundFile"], soundFile);
            end
            imgui.PopItemWidth();
            imgui.Separator();
        end
        -- /Fishing Skillup

        -- Clamming break
        if gathering == "clamming" then
            imgui.AlignTextToFramePadding();
            local clamCheckVar = { selectedSounds["__special:clam_break"] == true };
            if imgui.Checkbox("##set_alert_special_chk_clam_break", clamCheckVar) then
                selectedSounds["__special:clam_break"] = clamCheckVar[1] == true;
            end
            imgui.SameLine();
            if imguiShowToolTip("Set a sound alert for when your clamming bucket breaks.", settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            if uiButton("Play##ClamBreak") then
                local soundFile = imgui.GetVarValue(uiVariables["var_ClamBreakSoundFile"]);
                if soundFile ~= "" then
                    ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
                end
            end
            imgui.SameLine();
            imgui.PushItemWidth(state.window.widthWidgetDefault - 45);
            if imgui.Combo("Bucket Break", uiVariables["var_ClamBreakSoundIndex"], getSoundOptions()) then
                local soundIndex = imgui.GetVarValue(uiVariables["var_ClamBreakSoundIndex"]);
                local soundFile = sounds[soundIndex];
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"], "");
                imgui.SetVarValue(uiVariables["var_ClamBreakSoundFile"], soundFile);
            end
            imgui.PopItemWidth();
            imgui.Separator();
        end
        -- /Clamming break
        imgui.Spacing();

        for _, yield in ipairs(sortedYields) do
            imgui.PushID(yield);
            imgui.AlignTextToFramePadding();
            local rowCheckVar = { selectedSounds[yield] == true };
            if imgui.Checkbox(string.format("##set_alert_chk_%s_%s", gathering, yield), rowCheckVar) then
                selectedSounds[yield] = rowCheckVar[1] == true;
            end
            imgui.SameLine();
            if imguiShowToolTip(string.format("Set a sound alert for %s when it enters the yields list.", yield), settings.general.showToolTips) then
                imgui.SameLine(0.0, state.window.spaceToolTip);
            end
            local shortName = settings.yields[gathering][yield].short;
            local adjItemName = shortName or yield;
            if uiButton("Play") then
                local soundFile = imgui.GetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)]);
                if soundFile ~= "" then
                    ashita.misc.play_sound(string.format(_addon.path.."sounds\\%s", soundFile));
                end
            end
            imgui.SameLine();
            imgui.PushItemWidth(state.window.widthWidgetDefault - 45);
            if imgui.Combo(adjItemName, uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)], getSoundOptions()) then
                local soundIndex = imgui.GetVarValue(uiVariables[string.format("var_%s_%s_soundIndex", gathering, yield)]);
                local soundFile = sounds[soundIndex];
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)], "");
                imgui.SetVarValue(uiVariables[string.format("var_%s_%s_soundFile", gathering, yield)], soundFile);
            end
            imgui.PopItemWidth();
            imgui.PopID();
        end
        imgui.EndChild();
    end
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsReports
-- desc: Renders the Reports section in settings.
----------------------------------------------------------------------------------------------------
function renderSettingsReports()
    local gathering = getActiveReportsGathering();
    state.values.reportSelectionsByGather = state.values.reportSelectionsByGather or {};
    state.values.reportSelectionsByGather[gathering] = state.values.reportSelectionsByGather[gathering] or {};
    local selectedReports = state.values.reportSelectionsByGather[gathering];
    reports[gathering] = reports[gathering] or {};
    local sortedReports = table.sortReportsByDate(reports[gathering] or {}, true);
    imgui.PushStyleVar(ImGuiStyleVar.WindowPadding, { 5, 5 });
    pushSettingsPageMenuBarSizing();
    if imgui.BeginChild("Reports", { -1, state.window.heightSettingsContent }, imgui.GetVarValue(uiVariables['var_WindowVisible']), bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize)) then
        logScaleSnapshot("settings_reports_begin", "");
        local gatherBtnBoost = 1.18;
        local btnAction = function(data)
            runSafe(string.format('reports_btnAction_%s', tostring(data and data.name)), function()
                state.settings.reports.gathering = data.name;
                gathering = data.name;
                state.values.reportSelectionsByGather[gathering] = state.values.reportSelectionsByGather[gathering] or {};
                selectedReports = state.values.reportSelectionsByGather[gathering];
                imgui.SetVarValue(uiVariables['var_ReportSelected'], 0);
                state.values.currentReportName = nil;
                refreshReportsForGather(gathering);
            end);
        end
        renderSettingsTitleBar("Reports", gathering, btnAction, gatherBtnBoost);
        renderSettingsPageStatusRow();
        if state.values.reportsStatusText ~= nil and state.values.reportsStatusText ~= "" then
            imgui.TextColored({ 0.67, 0.93, 0.67, 1 }, state.values.reportsStatusText);
            imgui.Separator();
            imgui.Spacing();
        end
        sortedReports = table.sortReportsByDate(reports[gathering] or {}, true);
        local allReportsSelected = (#sortedReports > 0);
        for _, fileName in ipairs(sortedReports) do
            if not selectedReports[fileName] then
                allReportsSelected = false;
                break;
            end
        end
        local selectAllToggleDisabled = imguiPushDisabled(#sortedReports <= 0);
        local selectAllVar = { allReportsSelected };
        if imgui.Checkbox("##reports_select_all", selectAllVar) then
            local setSelected = selectAllVar[1] == true;
            for _, fileName in ipairs(sortedReports) do
                selectedReports[fileName] = setSelected;
            end
            writeDebugLog(string.format('reports toggle select all gather=%s value=%s total=%s',
                tostring(gathering), tostring(setSelected), tostring(#sortedReports)));
        end
        imgui.SameLine();
        imgui.TextUnformatted("Select All");
        imguiPopDisabled(selectAllToggleDisabled);
        imgui.Spacing();
        imgui.Separator();
        imgui.SetCursorPosX(0);
        imgui.PushStyleColor(ImGuiCol.Border, { 0, 0, 0, 0 });
        local _, reportsAvailY = getAvailXY(imgui.GetContentRegionAvail(), state.window.heightSettingsContent);
        local minListHeight = state.window.scale * 80.0;
        local minReadHeight = state.window.scale * 80.0;
        local controlsReserve = state.window.scale * 92.0;
        local maxListHeight = math.max(minListHeight, reportsAvailY - controlsReserve - minReadHeight);
        state.values.reportsListHeight = state.values.reportsListHeight or math.max(minListHeight, reportsAvailY * 0.25);
        if state.values.reportsListHeight < minListHeight then
            state.values.reportsListHeight = minListHeight;
        elseif state.values.reportsListHeight > maxListHeight then
            state.values.reportsListHeight = maxListHeight;
        end
        local listHeight = state.values.reportsListHeight;
        if imgui.BeginChild("Report List", { imgui.GetWindowWidth(), listHeight }, true) then
            logScaleSnapshot("settings_reports_list", "");
            imgui.PushTextWrapPos(getAvailX(imgui.GetContentRegionAvail()));
            if state.values.forceReportListTop then
                if imgui.SetScrollY ~= nil then
                    imgui.SetScrollY(0);
                end
                state.values.forceReportListTop = false;
                writeDebugLog(string.format('reports list scrolled top gather=%s', tostring(gathering)));
            end

            if #sortedReports > 0 then
                for idx, file in ipairs(sortedReports) do
                    local name = file
                    if idx == 1 and #sortedReports > 1 then
                        imgui.PushStyleColor(ImGuiCol_Text, { 1, 1, 0.54, 1 }); -- warn
                        name = file.." --latest"
                    else
                        imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1 }); -- plain
                    end
                    local rowCheckVar = { selectedReports[file] == true };
                    if imgui.Checkbox(string.format("##rpt_chk_%s_%s", tostring(gathering), tostring(idx)), rowCheckVar) then
                        selectedReports[file] = rowCheckVar[1] == true;
                        writeDebugLog(string.format('reports select checkbox gather=%s file=%s checked=%s', tostring(gathering), tostring(file), tostring(selectedReports[file])));
                    end
                    imgui.SameLine();
                    if imgui.Selectable(name, imgui.GetVarValue(uiVariables["var_ReportSelected"]) == idx, ImGuiSelectableFlags_AllowDoubleClick) then
                        imgui.SetVarValue(uiVariables['var_ReportSelected'], idx);
                        writeDebugLog(string.format('reports select click gather=%s index=%s file=%s', tostring(gathering), tostring(idx), tostring(sortedReports[idx])));
                        if (imgui.IsMouseDoubleClicked(0)) then
                            state.values.currentReportName = sortedReports[idx];
                            state.values.reportsListHeight = minListHeight;
                            writeDebugLog(string.format('reports select dblclick gather=%s index=%s file=%s', tostring(gathering), tostring(idx), tostring(sortedReports[idx])));
                        end
                    end
                    imgui.PopStyleColor();
                end
            else
                if getPlayerName() ~= "" then
                    imgui.Text("No reports..")
                else
                    imgui.TextColored({1, 0.615, 0.615, 1}, string.format("Unable to manage reports with no character loaded."));
                end
            end
            imgui.EndChild()
        end
        imgui.PopStyleColor();
        local splitterHeight = math.max(9.8, state.window.scale * 8.5);
        local splitterX = imgui.GetCursorPosX();
        local splitterY = imgui.GetCursorPosY();
        local splitterW = getAvailX(imgui.GetContentRegionAvail());
        imgui.PushStyleColor(ImGuiCol.Button, { 0.22, 0.24, 0.25, 1 });
        imgui.PushStyleColor(ImGuiCol.ButtonHovered, { 0.30, 0.33, 0.35, 1 });
        imgui.PushStyleColor(ImGuiCol.ButtonActive, { 0.39, 0.42, 0.44, 1 });
        imgui.Button("##reports_splitter", { -1, splitterHeight });
        local splitterAfterX = imgui.GetCursorPosX();
        local splitterAfterY = imgui.GetCursorPosY();
        local splitterActive = (imgui.IsItemActive ~= nil and imgui.IsItemActive()) or false;
        local splitterHovered = (imgui.IsItemHovered ~= nil and imgui.IsItemHovered()) or false;
        imgui.SetCursorPosX(splitterAfterX);
        imgui.SetCursorPosY(splitterAfterY);
        if splitterActive then
            local io = imgui.GetIO();
            local dy = 0;
            if io ~= nil and io.MouseDelta ~= nil and io.MouseDelta.y ~= nil then
                dy = tonumber(io.MouseDelta.y) or 0;
            end
            if dy ~= 0 then
                state.values.reportsListHeight = math.max(minListHeight, math.min(maxListHeight, state.values.reportsListHeight + dy));
            end
        end
        if splitterHovered then
            imgui.SetTooltip("Drag to resize list / read panes.");
        end
        imgui.PopStyleColor(3);

        imgui.Separator();
        local actionRowStartX = imgui.GetCursorPosX();
        local actionRowStartY = imgui.GetCursorPosY();
        local actionRowAvail = getAvailX(imgui.GetContentRegionAvail());
        local selectedIndex = tonumber(imgui.GetVarValue(uiVariables["var_ReportSelected"])) or 0;
        if selectedIndex <= 0 or sortedReports[selectedIndex] == nil then
            selectedIndex = 0;
            imgui.SetVarValue(uiVariables["var_ReportSelected"], 0);
        end

        imgui.SetCursorPosX(actionRowStartX);
        imgui.SetCursorPosY(actionRowStartY);
        local readDisabled = (selectedIndex <= 0 or sortedReports[selectedIndex] == nil);
        local disabled = imguiPushDisabled(readDisabled);
        if uiButton("Read") then
            local fname = sortedReports[selectedIndex];
            if state.values.currentReportName ~= fname then
                state.values.currentReportName = fname;
            end
            if fname ~= nil then
                state.values.reportsListHeight = minListHeight;
            end
            state.values.lastReportReadPath = nil;
            if fname ~= nil and getPlayerName() ~= "" then
                local dirPath = getReportsTypePath(gathering);
                local fpath = string.format('%s\\%s', dirPath or "", fname);
                local lines = linesFrom(fpath);
                if #lines > 0 then
                    state.values.reportsStatusText = string.format("Loaded report (%d lines): %s", #lines, tostring(fname));
                else
                    state.values.reportsStatusText = string.format("Unable to read report: %s", tostring(fname));
                end
            end
            writeDebugLog(string.format('reports read click gather=%s index=%s file=%s', tostring(gathering), tostring(selectedIndex), tostring(fname)));
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Read the selected report in the pane below.");
        end
        imguiPopDisabled(disabled);

        imgui.SameLine(0.0, state.window.spaceSettingsBtn * 2);
        imgui.SetCursorPosY(actionRowStartY);
        local readingActive = (state.values.currentReportName ~= nil and state.values.currentReportName ~= "");
        disabled = imguiPushDisabled(not readingActive);
        if uiButton("Close") then
            state.values.currentReportName = nil;
            state.values.lastReportReadPath = nil;
            imgui.SetVarValue(uiVariables["var_ReportSelected"], 0);
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Close the current report view.");
        end
        imguiPopDisabled(disabled);

        imgui.SameLine(0.0, state.window.spaceSettingsBtn * 2);
        imgui.SetCursorPosY(actionRowStartY);
        local sliderStartX = imgui.GetCursorPosX();
        local sliderDisabled = imguiPushDisabled(not readingActive);
        imgui.PushItemWidth(state.window.widthReportScale);
        if imgui.SliderFloat("##reports_font_scale", uiVariables["var_ReportFontScale"], 1.0, 1.5, "%.2f") then
            local reportScale = tonumber(imgui.GetVarValue(uiVariables["var_ReportFontScale"])) or 1.0;
            if reportScale < 1.0 then reportScale = 1.0; end
            if reportScale > 1.5 then reportScale = 1.5; end
            imgui.SetVarValue(uiVariables["var_ReportFontScale"], reportScale);
        end
        imgui.PopItemWidth();
        imguiPopDisabled(sliderDisabled);
        local sliderEndX = sliderStartX + (tonumber(state.window.widthReportScale) or 0.0);
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Adjust the text size used in the report reader.");
        end

        local selectedCount = 0;
        for _, fileName in ipairs(sortedReports) do
            if selectedReports[fileName] then selectedCount = selectedCount + 1; end
        end
        local deleteW = estimateButtonWidth("Delete", false);
        local deleteX = actionRowStartX + actionRowAvail - deleteW;
        if deleteX < actionRowStartX then
            deleteX = actionRowStartX;
        end
        local arrowLabelUp = "/\\";
        local arrowLabelDown = "\\/";
        local arrowDirUp = tonumber(_G.ImGuiDir_Up) or 2;
        local arrowDirDown = tonumber(_G.ImGuiDir_Down) or 3;
        local arrowW = math.max(estimateButtonWidth(arrowLabelUp, false), estimateButtonWidth(arrowLabelDown, false));
        local arrowGap = state.window.spaceSettingsBtn or 6.0;
        local arrowGroupW = (arrowW * 2.0) + arrowGap;
        local betweenW = deleteX - sliderEndX;
        local arrowPad = math.max(0.0, (betweenW - arrowGroupW) * 0.5);
        local arrowStartX = sliderEndX + arrowPad;
        if arrowStartX + arrowGroupW > deleteX then
            arrowStartX = math.max(sliderEndX + arrowGap, deleteX - arrowGroupW - arrowGap);
        end
        imgui.SetCursorPosX(arrowStartX);
        imgui.SetCursorPosY(actionRowStartY);
        if uiArrowButton("##reports_up_arrow", arrowDirUp, arrowLabelUp, { arrowW, calcScaledButtonHeight() }) then
            state.values.reportsListHeight = minListHeight;
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Maximize the report reader pane.");
        end
        imgui.SameLine(0.0, arrowGap);
        imgui.SetCursorPosY(actionRowStartY);
        if uiArrowButton("##reports_down_arrow", arrowDirDown, arrowLabelDown, { arrowW, calcScaledButtonHeight() }) then
            state.values.reportsListHeight = maxListHeight;
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Minimize the report reader pane.");
        end
        imgui.SetCursorPosX(deleteX);
        imgui.SetCursorPosY(actionRowStartY);
        local deleteSelectedDisabled = imguiPushDisabled(selectedCount <= 0);
        if uiButton("Delete") then
            if selectedCount > 0 and getPlayerName() ~= "" then
                local dirPath = getReportsTypePath(gathering);
                local deleted = 0;
                for _, fileName in ipairs(sortedReports) do
                    if selectedReports[fileName] then
                        local fpath = string.format('%s\\%s', dirPath or "", fileName);
                        writeDebugLog(string.format('reports delete selected gather=%s file=%s path=%s exists=%s',
                            tostring(gathering), tostring(fileName), tostring(fpath), tostring(fileExists(fpath))));
                        os.remove(fpath);
                        deleted = deleted + 1;
                    end
                end
                refreshReportsForGather(gathering);
                state.values.currentReportName = nil;
                state.values.lastReportReadPath = nil;
                imgui.SetVarValue(uiVariables["var_ReportSelected"], 0);
                state.values.reportSelectionsByGather[gathering] = {};
                selectedReports = state.values.reportSelectionsByGather[gathering];
                state.values.reportsStatusText = string.format("Deleted %d selected report(s).", deleted);
            end
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip("Delete all selected report files.");
        end
        imguiPopDisabled(deleteSelectedDisabled);

        imgui.Separator();

        imgui.SetCursorPosX(0);
        imgui.PushStyleColor(ImGuiCol.Border, { 0, 0, 0, 0 });
        -- Outer settings footer is now pinned; no internal reserve needed here.
        if imgui.BeginChild("Read Report", { imgui.GetWindowWidth(), 0 }, true) then
            logScaleSnapshot("settings_reports_read", "");
            local reportScale = tonumber(imgui.GetVarValue(uiVariables["var_ReportFontScale"])) or 1.0;
            if reportScale < 1.0 then reportScale = 1.0; end
            if reportScale > 1.5 then reportScale = 1.5; end
            local baseTextScale = tonumber(state.window.textScale) or 1.0;
            if baseTextScale < 0.25 then baseTextScale = 1.0; end
            -- Small calibration: report body glyphs render perceptually larger than control text.
            local calibratedBase = baseTextScale * 0.80;
            setWindowFontScale(calibratedBase * reportScale);
            imgui.PushTextWrapPos(getAvailX(imgui.GetContentRegionAvail()));
            local fname = state.values.currentReportName;
            if fname ~= nil then
                if getPlayerName() ~= "" then
                    local dirPath = getReportsTypePath(gathering);
                    local fpath = string.format('%s\\%s', dirPath or "", fname);
                    if state.values.lastReportReadPath ~= fpath then
                        writeDebugLog(string.format('reports read open gather=%s file=%s path=%s exists=%s',
                            tostring(gathering), tostring(fname), tostring(fpath), tostring(fileExists(fpath))));
                        state.values.lastReportReadPath = fpath;
                    end
                    local lines = linesFrom(fpath);
                    if #lines > 0 then
                        for _, line in pairs(lines) do
                            imgui.TextUnformatted(line);
                        end
                    else
                        imgui.TextColored({1, 0.615, 0.615, 1}, string.format("File (%s) is unable to be read. Either this file has been moved, deleted, or you have changed characters. Reload yield to update this list.", state.values.currentReportName))
                    end
                else
                    imgui.TextColored({ 1, 0.615, 0.615, 1 }, string.format("Unable to manage reports with no character loaded."));
                end
            elseif getPlayerName() == "" then
                imgui.TextColored({ 1, 0.615, 0.615, 1 }, string.format("Unable to manage reports with no character loaded."));
            end
            setWindowFontScale(baseTextScale);
            imgui.EndChild()
        end
        imgui.PopStyleColor();
        imgui.EndChild();
    end
    imgui.PopStyleVar();
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsFeedback
-- desc: Renders the Reports section in settings.
----------------------------------------------------------------------------------------------------
function renderSettingsFeedback()
    pushSettingsPageMenuBarSizing();
    if imgui.BeginChild("Feedback", { -1, state.window.heightSettingsContent }, true, bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize)) then
        setWindowFontScale(state.window.textScale);
        renderSettingsTitleBar("Feedback");
        renderSettingsPageStatusRow();
        local hasTitle = imgui.GetVarValue(uiVariables["var_IssueTitle"]):len() > 0;
        local hasBody = imgui.GetVarValue(uiVariables["var_IssueBody"]):len() > 0;
        local msg = "I hope you are enjoying Yield!";
        local widget = imgui.Text;
        local r, g, b, a = 0.77, 0.83, 0.80, 1; -- plain
        if not hasTitle and state.values.feedbackMissing then
            msg = "Please enter a title.";
            widget = imgui.BulletText;
            r, g, b, a = 1, 0.615, 0.615, 1; -- danger
        elseif not hasBody and state.values.feedbackMissing then
            msg = "Please enter some feedback.";
            widget = imgui.BulletText;
            r, g, b, a = 1, 0.615, 0.615, 1; -- danger
        end

        local availX = getAvailX(imgui.GetContentRegionAvail());
        local panelWidth = (tonumber(state.window.widthWidgetDefault) or 0.0) + 110.0;
        local panelMax = math.max(320.0, availX - 20.0);
        if panelWidth > panelMax then panelWidth = panelMax; end
        if panelWidth < 260.0 then panelWidth = 260.0; end
        local panelX = math.max(0.0, (availX - panelWidth) * 0.5);
        local bodyHeight = math.max(imgui.GetTextLineHeight() * 12.0, imgui.GetWindowHeight() * 0.34);

        local msgSize = imgui.CalcTextSize(msg);
        local msgWidth = 0.0;
        if type(msgSize) == "table" then
            msgWidth = tonumber(msgSize.x or msgSize[1]) or 0.0;
        else
            msgWidth = tonumber(msgSize) or 0.0;
        end
        imgui.SetCursorPosX(math.max(0.0, (availX - msgWidth) * 0.5));
        imgui.PushStyleColor(ImGuiCol_Text, { r, g, b, a });
        widget(msg);
        imgui.PopStyleColor();

        imgui.Spacing();
        imgui.SetCursorPosX(panelX);
        imgui.PushTextWrapPos(panelX + panelWidth);
        imgui.Text("If you have discovered a problem or want to provide feedback, this will open a pre-filled GitHub issue.");
        imgui.PopTextWrapPos();

        imgui.Spacing();
        imgui.SetCursorPosX(panelX);
        imgui.PushItemWidth(panelWidth);
        imgui.InputText('Title', uiVariables['var_IssueTitle'], 128, bit.bor(ImGuiInputTextFlags_EnterReturnsTrue));
        if settings.general.showToolTips and imgui.IsItemHovered() then
            imgui.SetTooltip("Enter a title for your feedback/issue submission.");
        end

        imgui.Spacing();
        imgui.SetCursorPosX(panelX);
        imgui.InputTextMultiline('Body', uiVariables['var_IssueBody'], 16384, panelWidth, bodyHeight, bit.bor(ImGuiInputTextFlags_AllowTabInput, ImGuiInputTextFlags_EnterReturnsTrue));
        if settings.general.showToolTips and imgui.IsItemHovered() then
            imgui.SetTooltip("Enter your feedback/issue.");
        end
        imgui.PopItemWidth();

        imgui.Spacing();
        imgui.SetCursorPosX(panelX);
        if not state.values.feedbackSubmitted then
            if uiButton("Submit") then
                if not hasBody or not hasTitle then
                    state.values.feedbackMissing = true;
                else
                   state.values.feedbackSubmitted = true;
                   state.values.feedbackMissing = false;
                   local title = imgui.GetVarValue(uiVariables["var_IssueTitle"]);
                   local body = imgui.GetVarValue(uiVariables["var_IssueBody"]);
                   sendIssue(title, body);
                   imgui.SetVarValue(uiVariables["var_IssueTitle"], "");
                   imgui.SetVarValue(uiVariables["var_IssueBody"], "")
                end
            end
        end
        if settings.general.showToolTips and imgui.IsItemHovered() then
            imgui.SetTooltip("Submitting opens your browser with a pre-filled GitHub issue for the Yield repository.");
        end
        if state.values.feedbackSubmitted then
            imgui.SetCursorPosX(panelX);
            imgui.PushStyleColor(ImGuiCol_Text, { 0.39, 0.96, 0.13, 1 }); -- success
            imgui.Text("Issue draft opened in browser.");
            imgui.PopStyleColor();
            imgui.SameLine();
            imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.615, 0.615, 1 }); -- danger
            imgui.Text("<3");
            imgui.PopStyleColor();
        end

        local footerY = imgui.GetWindowHeight() - (imgui.GetTextLineHeight() * 2.2);
        if footerY > imgui.GetCursorPosY() then
            imgui.SetCursorPosY(footerY);
        else
            imgui.Spacing();
        end
        imgui.SetCursorPosX(panelX);
        imgui.PushTextWrapPos(panelX + panelWidth);
        imgui.Text("* To: https://github.com/Sjshovan/Ashita-Yield/issues");
        if settings.general.showToolTips and imgui.IsItemHovered() then
            imgui.SetTooltip("Submitting opens your browser with a pre-filled GitHub issue for the Yield repository.");
        end
        imgui.PopTextWrapPos();
        imgui.EndChild();
    end
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderSettingsAbout
-- desc: Renders the About section in settings.
---------------------------------------------------------------------------------------------------
function renderSettingsAbout()
    pushSettingsPageMenuBarSizing();
    if imgui.BeginChild("About", { -1, state.window.heightSettingsContent }, true, bit.bor(ImGuiWindowFlags.MenuBar, ImGuiWindowFlags.NoResize)) then
        setWindowFontScale(state.window.textScale);
        renderSettingsTitleBar("About");
        renderSettingsPageStatusRow();
        imgui.Spacing();
        local contentStartX = imgui.GetCursorPosX();
        local availX = getAvailX(imgui.GetContentRegionAvail());
        local leftPad = 8.0;
        local panelX = contentStartX + leftPad;
        local panelWidth = math.max(220.0, availX - leftPad - 4.0);
        local panelRight = panelX + panelWidth;

        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol_Text, { 0.77, 0.83, 0.80, 1 });
        imgui.PushTextWrapPos(panelRight);
        imgui.Text("Yield is community-driven. Feedback, bug reports, and ideas are always welcome.");
        imgui.PopTextWrapPos();
        imgui.PopStyleColor();
        imgui.Spacing();

        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol.Separator, SETTINGS_HEADER_LINE_COLOR);
        imgui.Separator();
        imgui.PopStyleColor();
        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol_Text, SETTINGS_HEADER_TEXT_COLOR);
        imgui.Text("Project");
        imgui.PopStyleColor();
        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol.Separator, SETTINGS_HEADER_LINE_COLOR);
        imgui.Separator();
        imgui.PopStyleColor();
        imgui.Spacing();

        imgui.SetCursorPosX(panelX);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Name:"); imgui.SameLine(); imgui.Text(string.format("%s by Lotekkie", _addon.name));
        imgui.SetCursorPosX(panelX);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Version:"); imgui.SameLine(); imgui.Text(_addon.version);
        imgui.SetCursorPosX(panelX);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Author:"); imgui.SameLine(); imgui.Text(_addon.author);
        imgui.SetCursorPosX(panelX);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Description:");
        imgui.SetCursorPosX(panelX);
        imgui.PushTextWrapPos(panelRight);
        imgui.Text(_addon.description);
        imgui.PopTextWrapPos();
        imgui.SetCursorPosX(panelX);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Repository:");
        imgui.SetCursorPosX(panelX);
        imgui.PushTextWrapPos(panelRight);
        imgui.Text("https://github.com/Sjshovan/Ashita-Yield");
        imgui.PopTextWrapPos();

        imgui.Spacing();
        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol.Separator, SETTINGS_HEADER_LINE_COLOR);
        imgui.Separator();
        imgui.PopStyleColor();
        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol_Text, SETTINGS_HEADER_TEXT_COLOR);
        imgui.Text("Community");
        imgui.PopStyleColor();
        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol.Separator, SETTINGS_HEADER_LINE_COLOR);
        imgui.Separator();
        imgui.PopStyleColor();
        imgui.Spacing();

        imgui.SetCursorPosX(panelX);
        imgui.PushTextWrapPos(panelRight);
        imgui.Text("Use these links to share ideas, report issues, and support the project.");
        imgui.PopTextWrapPos();
        imgui.Spacing();

        local btnGap = 8.0;
        local btnIssuesW = estimateButtonWidthForButtons("Open Issues", false);
        local btnRepoW = estimateButtonWidthForButtons("Open Repo", false);
        local btnDiscordW = estimateButtonWidthForButtons("Open Discord", false);
        local actionRowW = btnIssuesW + btnRepoW + btnDiscordW + (btnGap * 2.0);
        local compactActions = actionRowW > panelWidth;
        imgui.SetCursorPosX(panelX);
        if uiButton("Open Issues") then
            ashita.misc.open_url("https://github.com/Sjshovan/Ashita-Yield/issues");
        end
        if not compactActions then imgui.SameLine(0.0, btnGap); else imgui.SetCursorPosX(panelX); end
        if uiButton("Open Repo") then
            ashita.misc.open_url("https://github.com/Sjshovan/Ashita-Yield");
        end
        if not compactActions then imgui.SameLine(0.0, btnGap); else imgui.SetCursorPosX(panelX); end
        if uiButton("Open Discord") then
            ashita.misc.open_url("https://discord.gg/3FbepVGh");
        end

        imgui.Spacing();
        imgui.SetCursorPosX(panelX);
        if uiButton("Support Development") then
            ashita.misc.open_url("https://Paypal.me/Sjshovan");
        end

        imguiFullSep();
        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol_Text, SETTINGS_HEADER_TEXT_COLOR);
        imgui.Text("Special Thanks");
        imgui.PopStyleColor();
        imgui.SetCursorPosX(panelX);
        imgui.PushStyleColor(ImGuiCol.Separator, SETTINGS_HEADER_LINE_COLOR);
        imgui.Separator();
        imgui.PopStyleColor();
        imgui.Spacing();

        imgui.SetCursorPosX(panelX);
        imgui.PushTextWrapPos(panelRight);
        imgui.Text("Thanks to the Ashita team, community testers, and everyone who reported bugs and shared feedback.");
        imgui.PopTextWrapPos();
        imgui.EndChild();
    end
    imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: renderHelpGeneral
-- desc: Renders the general help section with the help window.
---------------------------------------------------------------------------------------------------
function renderHelpGeneral()
    if imgui.BeginChild("HelpGeneral", { -1, state.window.heightSettingsContent }, true) then
        setWindowFontScale(state.window.textScale);
        imgui.Spacing();
        imgui.PushTextWrapPos(imgui.GetContentRegionAvail());
        if state.firstLoad then
            imgui.TextColored({ 1, 1, 0.54, 1 }, "Welcome to Yield!"); imgui.Separator();
            imgui.Text("Before you begin, please take a moment to read through the following general information and common questions to familiarize yourself.");
            imgui.Text("If you would like to read this later you can open this window anytime by click the 'Help' button located at the bottom of the app.");
            imguiHalfSep(true);
        end
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Navigating Yield"); imgui.Separator();
        imgui.Text("Your main tool for navigating Yield is the mouse. If you hover over controls and items in the interface, Yield will provide contextual explanations. Take your time and explore.");
        imgui.Text("The real power of Yield comes from within its Settings window. There are a variety of features and customization options there to accommodate almost every gatherer's need.");
        imguiHalfSep(true);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Gathering"); imgui.Separator();
        imgui.Text("Yield supports every gathering type in the game and switching between them here is a breeze, simply click on the icons at the top of the Main window. If you hover your mouse over them, Yield will tell you which gathering type you are switching to. If you start gathering and forget to switch, don't worry, Yield will automatically switch to the correct type and begin working to keep track of your stats!");
        imgui.Spacing();
        imgui.Text("Don't forget to set those prices! Before heading out to begin gathering, it is recommended that you set your prices for yields within the Settings/Set Prices window. If you forget for some reason, that's ok, you can always update the prices later and recalculate your Estimated Value from within the same window.");
        imgui.Spacing();
        imgui.Text("Yield is intelligent and will begin tracking and recording for you without the need for you to do anything first. After you load Yield, simply start gathering and watch the magic happen!");
        imguiHalfSep(true);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Settings"); imgui.Separator();
        imgui.Text("Yield automatically saves all the changes you make in your Settings window each time the Settings window is closed. You do not need to worry about reloading and losing your Prices/Colors/Alerts or any of your current metrics. When you exit the game and come back, everything will be right where you left it.");
        imguiHalfSep(true);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Alerts"); imgui.Separator();
        imgui.Text("Yield ships with a variety of sounds, used for alerts, out of the box. If you find yourself wanting to add custom sounds, it couldn't be easier. All sounds used for Yield alerts can be found within the /sounds folder. To add a new sound, ensure the sound file is in .wav format (e.g. my_new_sound.wav), and drop it into /sounds. After that, reload Yield and your new sound should be available in all sound selection drop-downs.")
        imguiHalfSep(true);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Reports"); imgui.Separator();
        imgui.Text("Yield allows you to generate detailed reports using the metrics it has tracked while you gathered. You do not need to use Yield to manage these files but these reports can be read and deleted from within the Settings/Reports window. These files are stored locally with the /reports folder of the Yield addon. It is safe to remove these files even while Yield is loaded. Yield will inform you that the files no longer exist if you attempt to read them.");
        imgui.Text("Generation of reports can occur both manually and automatically. If you enable automatic generation of reports Yield will generate a report both when you zone and when you reset the data for a particular gathering type.");
        imgui.Text("While automatic report generation can happen when you zone, it won't always happen when you zone. Yield will attempt to determine when it should generate on zone change based on your activity.");
        imguiHalfSep(true);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Tips/Tricks"); imgui.Separator();
        imgui.Text("1. Double-click on the title bar of any window to minimize it.");
        imgui.Text("2. left-click or right-click on your plots within the Main window to cycle the display of their labels.");
        imgui.Text("3. left-click or right-click on the yields list within the Main window to cycle the sorting methods of the list.");
        imgui.Text("4. If you forget to shut off your timer when you walk away from Yield, it will automatically shut them off for you after approx. 5 minutes.");
        imgui.Text("5. You can Double-click on a file name in Reports to view its contents rather than using the Read button.");
        imgui.Text("6. You can left-click drag on the R: G: B: A: color boxes with your mouse to change their values quickly. You can also left-click on the main color box to change color input methods.");
        imgui.Text("7. You can view the moon percentage by switching to the digging gathering type.");
        imguiHalfSep(true);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Bugs/Errors"); imgui.Separator();
        imgui.Text("Unfortunately, nothing is perfect, not even Yield. You may come across a problem while using Yield to help you become the ultimate gatherer. I understand the frustration of these occurrences and that is why I added an easy in-app way to report these problems directly to me so I can quickly get the issues resolved.");
        imgui.Text("To report an issue directly to me, simply head on over to Settings/Feedback. Enter a title, an explanation, and hit submit.");
        imgui.Text("By taking a mere moment to send a report, you are effectively taking part in the active development of Yield and helping it become even better. This time you take to do so is greatly appreciated!");
        imguiHalfSep(true);
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Text Commands"); imgui.Separator();
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
    if imgui.BeginChild("HelpQnA", { -1, state.window.heightSettingsContent }, true) then
        setWindowFontScale(state.window.textScale);
        imgui.Spacing();
        imgui.PushTextWrapPos(imgui.GetContentRegionAvail());
        imgui.Separator();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: Is this addon available for Windower?"); imgui.Separator();
        imgui.Text("A: Unfortunately, No. Windower does not currently offer the technology used to create this addon. If they ever do, I will absolutely port it over. ")
        imguiFullSep();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: Why isn't feature X/Y/Z implemented?"); imgui.Separator();
        imgui.Text("A: I'm positive many of you out there have some amazing ideas on how to make Yield better. I'd love to hear them! You can contact me through Feedback in Settings, by email (sjshovan@gmail.com), or on discord (LoTekkie #6070).")
        imguiFullSep();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: How can I donate/support?"); imgui.Separator();
        imgui.Text("A: Head on over to the About section in Settings. There you can see some ways that I am able to receive your support. Thank you!");
        imguiFullSep();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: I have upgraded from a previous version now everything went bonkers! What do I do?"); imgui.Separator();
        imgui.Text("A: If you reach a scenario where Yield wont display correctly or is acting strange, first try reloading the addon. If you are still experiencing issues try the following steps:")
        imgui.Text("1. Exit out of Final Fantasy 11.");
        imgui.Text("2. Navigate to the Yield addon and delete your settings/ folder.");
        imgui.Text("3. Start Final Fantasy 11 and load Yield.")
        imgui.Text("If you are still experiencing issues, reach out to me and I will attempt to solve them.");
        imguiFullSep();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: I cannot find the Yield window! What do I do?"); imgui.Separator();
        imgui.Text("A: Type /yield find or /yld f in your chat bar. This will force the Yield window to return to the top left of your screen.");
        imguiFullSep();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: Where can I share ideas or follow updates?"); imgui.Separator();
        imgui.Text("A: Use Settings -> Feedback to send ideas and bug reports, or visit the project issues page at https://github.com/Sjshovan/Ashita-Yield/issues.");
        imguiFullSep();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: Have you created any other FFXI addons?"); imgui.Separator();
        imgui.Text("A: Yes, I have also authored Mount Muzzle(Windower+Ashita) and Battle Stations(Windower). You can obtain these through their respective launchers.");
        imguiFullSep();
        imgui.TextColored({ 1, 1, 0.54, 1 }, "Q: I have a question that I don't see here. How do I contact you?"); imgui.Separator();
        imgui.Text("A: You can contact me through Feedback in Settings, by email (sjshovan@gmail.com), or on discord (LoTekkie #6070).");
        imgui.Spacing();
        imgui.EndChild();
    end
end
