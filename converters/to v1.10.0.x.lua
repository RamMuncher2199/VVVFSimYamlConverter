local args = {...} --given arguments
local raw_file_data = args[1]
local raw_yaml_data = raw_file_data

function count_yaml_spaces(str, index)
    local index = index or 1
    local found = string.sub(str, index, index + 1) == "  "
    found = found or (string.sub(str, index, index + 1) == "- ")
    local count = 0
    while found do 
        count = count + 1
        index = index + 2
        found = string.sub(str, index, index + 1) == "  "
        found = found or (string.sub(str, index, index + 1) == "- ")
    end
    return count
end


--[[
changes v1.9.1.1 --> v1.10.0.2

MasconData was renamed to JerkSetting

(BrakingPattern or AcceleratePattern)/number/AsyncModulationData/CarrierWaveData/CarrierFrequencyTable/CarrierFrequencyTableValues
was renamed to 
(BrakingPattern or AcceleratePattern)/number/AsyncModulationData/CarrierWaveData/CarrierFrequencyTable/Table

(BrakingPattern or AcceleratePattern)/number/PulseMode/CarrierWave
was added to v1.10.0.2, investigate (later)!!! 
ok i investigated, i think we can get away with defining defaults for these
  PulseMode:
    CarrierWave: <-- must be added!
      Option: FallStart
      Type: Triangle

--these were removed, however I do not know what they were replaced by (or what their purpose was) :C
  PulseMode:
    Shift: false
    Square: false 
    Continuous: false
]]


--perform simple replacements
raw_yaml_data = string.gsub(raw_yaml_data, "MasconData", "JerkSetting")
raw_yaml_data = string.gsub(raw_yaml_data, "CarrierFrequencyTableValues", "Table")
--L3P3Alt1Width -> PulseWidth --saw this on the patchnotes for 1.9.1.0
raw_yaml_data = string.gsub(raw_yaml_data, "L3P3Alt1Width", "PulseWidth")

function findAndRemoveEntry(haystack, needle, start, replacement, max_index) --removes something found in haystack, runs literally
    local found = string.find(haystack, needle, start, true)
    --we know where it is, search backwards and forwards for newlines to remove this line
    if found and Check(max_index, found < (max_index or 0), true) then 
        local reversed = string.reverse(string.sub(haystack, 1, found))
        local firstNL = #reversed - string.find(reversed, "\n", 1, true)
        local secondNL = string.find(haystack, "\n", found, true)

        haystack = string.sub(haystack, 1, firstNL) .. (replacement or "") .. string.sub(haystack, secondNL, #haystack)
    end

    return haystack
end

--add missing things that are required for v1.10.0.x that are in the PulseMode maps
local PulseMode = string.find(raw_yaml_data, "PulseMode", 1, true)
while PulseMode do
    --count indents, and insert required data
    local first_newline = string.find(raw_yaml_data, "\n", PulseMode, true)
    local second_newline = string.find(raw_yaml_data, "\n", first_newline + 1, true)
    local line = string.sub(raw_yaml_data, first_newline + 1, second_newline - 1)
    local spaces = count_yaml_spaces(line)
    --print("glorp: "..spaces)
    --add now
    --print(#raw_yaml_data)
    local addition = string.rep("  ", spaces) .. "CarrierWave:".."\n"
    addition = addition .. string.rep("  ", spaces + 1) .. "Option: FallStart".."\n"
    addition = addition .. string.rep("  ", spaces + 1) .. "Type: Triangle".."\n"
    
    
    raw_yaml_data = string.sub(raw_yaml_data, 1, first_newline) .. addition .. string.sub(raw_yaml_data, first_newline + 1, #raw_yaml_data)
    --print(#raw_yaml_data)

    --remove stuff inside of here if they exist
    raw_yaml_data = findAndRemoveEntry(raw_yaml_data, "Shift", PulseMode)
    raw_yaml_data = findAndRemoveEntry(raw_yaml_data, "Square", PulseMode)
    raw_yaml_data = findAndRemoveEntry(raw_yaml_data, "Continuous", PulseMode)


    PulseMode = string.find(raw_yaml_data, "PulseMode", PulseMode + 1, true)
end


--[[small fix for certain files: out-of-range frequencies in ModulationIndex maps (the full key path is ControlFrequencyFrom->Amplitude->Default, and Default: is only used in this context)
local Default = string.find(raw_yaml_data, "Default:", 1, true)
while Default do
    --count indents, and insert required data
    local first_newline = string.find(raw_yaml_data, "\n", Default, true)
    local second_newline = string.find(raw_yaml_data, "\n", first_newline + 1, true)
    local line = string.sub(raw_yaml_data, first_newline + 1, second_newline - 1)
    local spaces = count_yaml_spaces(line)


    --fix startfrequency in Default modulation index contexts
    raw_yaml_data = findAndRemoveEntry(raw_yaml_data, "StartFrequency: -1", Default, string.rep("  ", spaces).."StartFrequency: 0", string.find(raw_yaml_data, "StartFrequency: ", Default, true) + 5)


    Default = string.find(raw_yaml_data, "Default:", Default + 1, true)
end
]]

--[[find key CarrierFrequencyTableValues: and if there's no entries, change contents to [], also replace the key with Table:
local CarrierFrequencyTableValues = string.find(raw_yaml_data, "CarrierFrequencyTableValues", 1, true)
while CarrierFrequencyTableValues do
    --find newline before CarrierFrequencyTableValues
    local str = string.sub(raw_yaml_data, 1, CarrierFrequencyTableValues)
    before_cftv = string.find(string.reverse(str), "\n", 1, true)
    before_cftv = #str - before_cftv
    local indents = count_yaml_spaces(string.sub(raw_yaml_data, before_cftv + 2, CarrierFrequencyTableValues - 1))
    --now check if there's an array following this

    CarrierFrequencyTableValues = string.find(raw_yaml_data, "CarrierFrequencyTableValues", CarrierFrequencyTableValues + 1, true)
end
]]


return raw_yaml_data
