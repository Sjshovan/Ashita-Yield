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

require 'os'

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local chatColors = {
    primary = "\31\200%s",
    secondary = "\31\207%s",
    info = "\31\1%s",
    warn = "\31\140%s",
    danger = "\31\167%s",
    success = "\31\158%s"
}

----------------------------------------------------------------------------------------------------
-- func: displayHelp
-- desc: Show help table entries in the players chat log.
----------------------------------------------------------------------------------------------------
function displayHelp(table)
    for index, command in pairs(table) do
        displayResponse(command)
    end
end

----------------------------------------------------------------------------------------------------
-- func: displayResponse
-- desc: Show a message with the given color in the players chat log.
----------------------------------------------------------------------------------------------------
function displayResponse(response, color)
    color = color or chatColors.info
    print(strColor(response, color))
end

----------------------------------------------------------------------------------------------------
-- func: helpCommandEntry
-- desc: Build a command description.
----------------------------------------------------------------------------------------------------
function helpCommandEntry(command, description)
    local shortName = strColor("yld", chatColors.primary)
    local command = strColor(command, chatColors.secondary)
    local sep = strColor("=>", chatColors.primary)
    local description = strColor(description, chatColors.info)
    return string.format("%s %s %s %s", shortName, command, sep, description)
end

----------------------------------------------------------------------------------------------------
-- func: helpTypeEntry
-- desc: Build a help description.
----------------------------------------------------------------------------------------------------
function helpTypeEntry(name, description)
    local name = strColor(name, chatColors.secondary)
    local sep = strColor("=>", chatColors.primary)
    local description = strColor(description, chatColors.info)
    return string.format("%s %s %s", name, sep, description)
end

----------------------------------------------------------------------------------------------------
-- func: helpTitle
-- desc: Build a help title.
----------------------------------------------------------------------------------------------------
function helpTitle(context)
    local context = strColor(context, chatColors.danger)
    return string.format("%s Help: %s", _addon.name, context)
end

----------------------------------------------------------------------------------------------------
-- func: helpSeparator
-- desc: Build a help separator.
----------------------------------------------------------------------------------------------------
function helpSeparator(character, count)
    local sep = ''
    for i = 1, count do
        sep = sep .. character
    end
    return strColor(sep, chatColors.warn)
end

----------------------------------------------------------------------------------------------------
-- func: commandResponse
-- desc: Build a command response.
----------------------------------------------------------------------------------------------------
function commandResponse(message, success)
    local responseColor = chatColors.success
    local responseType = 'Success'
    if not success then
        responseType = 'Error'
        responseColor = chatColors.danger
    end
    return string.format("%s: %s", 
        strColor(responseType, responseColor), strColor(message, chatColors.info)
    )
end

----------------------------------------------------------------------------------------------------
-- func: sortKeysByAlphabet
-- desc: Sort table keys alphabetically.
----------------------------------------------------------------------------------------------------
function table.sortKeysByAlphabet(t, desc)
    local ret = {}
    for k, v in pairs(t) do
        table.insert(ret, k)
    end
    if (desc) then
        table.sort(ret, function(a, b) return a:lower() < b:lower() end);
    else
        table.sort(ret, function(a, b) return a:lower() > b:lower() end);
    end
    return ret;
end

----------------------------------------------------------------------------------------------------
-- func: sortKeysByLength
-- desc: Sort table keys by string length.
----------------------------------------------------------------------------------------------------
function table.sortKeysByLength(t, desc)
    local ret = {}
    for k, v in pairs(t) do
        table.insert(ret, k)
    end
    if (desc) then
        table.sort(ret, function(a, b) return a:len() < b:len() end);
    else
        table.sort(ret, function(a, b) return a:len() > b:len() end);
    end
    return ret;
end

----------------------------------------------------------------------------------------------------
-- func: sortReportsByDate
-- desc: Sort the tables values by it time stamp strings.
----------------------------------------------------------------------------------------------------
function table.sortReportsByDate(t, desc)
    local ret = {}
    for k, v in pairs(t) do
        table.insert(ret, v)
    end
    local now = os.time();
    if (desc) then
        table.sort(ret, function(a, b)
            local yA, mA, dA = string.match(string.gsub(string.match(a, "__(.*)__"), "_", "-"), "(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$");
            local hA, miA, sA = string.match(string.gsub(string.match(a, ".*__(.*).log$"), "_", ":"), "(%d%d):?(%d?%d?):?(%d?%d?)$");
            local yB, mB, dB = string.match(string.gsub(string.match(b, "__(.*)__"), "_", "-"), "(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$");
            local hB, miB, sB = string.match(string.gsub(string.match(b, ".*__(.*).log$"), "_", ":"), "(%d%d):?(%d?%d?):?(%d?%d?)$");

            local diffA = os.difftime(now, os.time{year=yA, month=mA, day=dA, hour=hA, min=miA, sec=sA});
            local diffB = os.difftime(now, os.time{year=yB, month=mB, day=dB, hour=hB, min=miB, sec=sB});

            return diffA < diffB
        end);
    else
        table.sort(ret, function(a, b)
            local yA, mA, dA = string.match(string.gsub(string.match(a, "__(.*)__"), "_", "-"), "(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$");
            local hA, miA, sA = string.match(string.gsub(string.match(a, ".*__(.*).log$"), "_", ":"), "(%d%d):?(%d?%d?):?(%d?%d?)$");
            local yB, mB, dB = string.match(string.gsub(string.match(b, "__(.*)__"), "_", "-"), "(%d%d%d%d)-?(%d?%d?)-?(%d?%d?)$");
            local hB, miB, sB = string.match(string.gsub(string.match(b, ".*__(.*).log$"), "_", ":"), "(%d%d):?(%d?%d?):?(%d?%d?)$");

            local diffA = os.difftime(now, os.time{year=yA, month=mA, day=dA, hour=hA, min=miA, sec=sA});
            local diffB = os.difftime(now, os.time{year=yB, month=mB, day=dB, hour=hB, min=miB, sec=sB});

            return diffA > diffB
        end);
    end
    return ret;
end

----------------------------------------------------------------------------------------------------
-- func: getIndexFromKey
-- desc: Obtain a table index from the given table key.
----------------------------------------------------------------------------------------------------
function table.getIndexFromKey(t, key)
    for _, k in ipairs(table.keys(t)) do
        if key == k then
            return _;
        end
    end
    return nil
end

----------------------------------------------------------------------------------------------------
-- func: camelToTitle
-- desc: Convert a camel case string to a title.
----------------------------------------------------------------------------------------------------
function string.camelToTitle(s)
    return string.gsub(string.upperfirst(s), "([A-Z][a-z]?)", " %1"):sub(2);
end

----------------------------------------------------------------------------------------------------
-- func: lowerToTitle
-- desc: Convert a lower case string to a title.
----------------------------------------------------------------------------------------------------
function string.lowerToTitle(s)
    s = string.gsub(" "..s, "%W%l", string.upper):sub(2);
    s = string.gsub(s, "('[A-Z])", string.lower);
    return s
end

----------------------------------------------------------------------------------------------------
-- func: strColor
-- desc: Add color to a string.
----------------------------------------------------------------------------------------------------
function strColor(str, color) 
    return string.format(color, str)
end

----------------------------------------------------------------------------------------------------
-- func: showToolTip
-- desc: Shows a tooltip with imgui.
----------------------------------------------------------------------------------------------------
function imguiShowToolTip(text, enabled)
    if enabled then
        imgui.TextDisabled('(?)');
        if (imgui.IsItemHovered()) then
            imgui.SetTooltip(text);
        end
    end
    return enabled
end

----------------------------------------------------------------------------------------------------
-- func: imguiFullSep
-- desc: Create a multi-line separator.
----------------------------------------------------------------------------------------------------
function imguiFullSep()
    imgui.Spacing();
    imgui.Separator();
    imgui.Spacing();
end

----------------------------------------------------------------------------------------------------
-- func: imguiHalfSep
-- desc: Create a multi-line separator, choose to switch the order.
----------------------------------------------------------------------------------------------------
function imguiHalfSep(flip)
    if not flip then
        imgui.Spacing();
        imgui.Separator();
    else
        imgui.Separator();
        imgui.Spacing();
    end
end

----------------------------------------------------------------------------------------------------
-- func: cycleIndex
-- desc: Move forwards or backwards from the given index by the given direction.
----------------------------------------------------------------------------------------------------
function cycleIndex(index, min, max, dir)
    if dir == nil then dir = 1 end;
    local newIndex = index + dir;
    if newIndex > max then
        newIndex = min
    end
    if newIndex < min then
        newIndex = max
    end
    return newIndex;
end

----------------------------------------------------------------------------------------------------
-- func: colorTableToInt
-- desc: Converts an imgui color table to a D3DCOLOR int.
----------------------------------------------------------------------------------------------------
function colorTableToInt(t)
    local a = t[4];
    local r = t[1] * 255;
    local g = t[2] * 255;
    local b = t[3] * 255;

    -- Handle 3 and 4 color tables..
    if (a == nil) then
        a = 255;
    else
        a = a * 255;
    end

    return math.d3dcolor(a, r, g, b);
end

----------------------------------------------------------------------------------------------------
-- func: colorToRGBA
-- desc: Converts a color to its rgba values.
----------------------------------------------------------------------------------------------------
function colorToRGBA(c)
    local a = bit.rshift(bit.band(c, 0xFF000000), 24);
    local r = bit.rshift(bit.band(c, 0x00FF0000), 16);
    local g = bit.rshift(bit.band(c, 0x0000FF00), 8);
    local b = bit.band(c, 0x000000FF);
    return r, g, b, a;
end

----------------------------------------------------------------------------------------------------
-- func: imguiPushActiveBtnColor
-- desc: Add some button color if the condition is met.
----------------------------------------------------------------------------------------------------
function imguiPushActiveBtnColor(cond)
    if cond then
        imgui.PushStyleColor(ImGuiCol_Button, 0.21, 0.47, 0.59, 1); -- info
    else
        imgui.PushStyleColor(ImGuiCol_Button, 0.25, 0.69, 1.0, 0.1); -- secondary
    end
    return cond;
end

----------------------------------------------------------------------------------------------------
-- func: imguiPushDisabled
-- desc: Make the item look disabled if the given condition is met.
----------------------------------------------------------------------------------------------------
function imguiPushDisabled(cond)
    if cond then
        imgui.PushStyleVar(ImGuiStyleVar_Alpha, 0.5);
        imgui.PushStyleColor(ImGuiCol_ButtonHovered, 49/255, 62/255, 75/255, 1);
        imgui.PushStyleColor(ImGuiCol_ButtonActive, 49/255, 62/255, 75/255, 1);
    end
    return cond;
end

----------------------------------------------------------------------------------------------------
-- func: imguiPopDisabled
-- desc: Remove the disabled look if the given condition is met.
----------------------------------------------------------------------------------------------------
function imguiPopDisabled(cond)
    if cond then
        imgui.PopStyleVar();
        imgui.PopStyleColor();
        imgui.PopStyleColor();
    end
end

----------------------------------------------------------------------------------------------------
-- func: wait
-- desc: Halt the application for the given number of seconds.
----------------------------------------------------------------------------------------------------
function wait(seconds)
    local time = seconds or 1
    local start = os.time()
    repeat until os.time() == start + time
end

----------------------------------------------------------------------------------------------------
-- func: table.sumValues
-- desc: Add all the values of the given table.
----------------------------------------------------------------------------------------------------
function table.sumValues(t)
    local val = 0;
    for k, v in pairs(t) do
        if (type(v) == 'number') then
            val = val + v;
        end
    end
    return val
end