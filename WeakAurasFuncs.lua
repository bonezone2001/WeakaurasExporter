-- A bunch of weakaura funcs that are in the private namespace (inaccessible from this addon)
-- Should make updating pretty easy (hopefully) although some functions are modified to work in this context

local CompressDisplay, TableToString, StringToTable

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

local configForDeflate = {level = 9}
local configForLS = {
    errorOnUnserializableType =  false
}

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/Types.lua#L3168
local non_transmissable_fields = {
    controlledChildren = true,
    parent = true,
    authorMode = true,
    skipWagoUpdate = true,
    ignoreWagoUpdate = true,
    preferToUpdate = true,
    information = {
        saved = true
    }
}

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/Types.lua#L3181C28-L3181C28
local non_transmissable_fields_v2000 = {
    authorMode = true,
    skipWagoUpdate = true,
    ignoreWagoUpdate = true,
    preferToUpdate = true,
    information = {
        saved = true
    }
}

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/Transmission.lua#L266
function TableToString(inTable, forChat)
    local serialized = LibSerialize:SerializeEx(configForLS, inTable)
    local compressed
    compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)

    local encoded = "!WA:2!"
    if(forChat) then
        encoded = encoded .. LibDeflate:EncodeForPrint(compressed)
    else
        encoded = encoded .. LibDeflate:EncodeForWoWAddonChannel(compressed)
    end
    return encoded
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/WeakAuras.lua#L5969
function shouldInclude(data, includeGroups, includeLeafs)
    if data.controlledChildren then
        return includeGroups
    else
        return includeLeafs
    end
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/WeakAuras.lua#L5977
function Traverse(data, includeSelf, includeGroups, includeLeafs)
    if includeSelf and shouldInclude(data, includeGroups, includeLeafs) then
        coroutine.yield(data)
    end

    if data.controlledChildren then
        for _, child in ipairs(data.controlledChildren) do
            Traverse(WeakAuras.GetData(child), true, includeGroups, includeLeafs)
        end
    end
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/WeakAuras.lua#L6001
function TraverseSubGroups(data)
    return Traverse(data, false, true, false)
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/WeakAuras.lua#L6037C31-L6037C31
function CoTraverseSubGroups(data)
    return coroutine.wrap(TraverseSubGroups), data
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/WeakAuras.lua#L6042C31-L6042C31
function CoTraverseAllChildren(data)
  return coroutine.wrap(TraverseAllChildren), data
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/WeakAuras.lua#L6005C12-L6005C12
function TraverseAllChildren(data)
    return Traverse(data, false, true, true)
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/Transmission.lua#L104C10-L104C10
function stripNonTransmissableFields(datum, fieldMap)
    for k, v in pairs(fieldMap) do
        if type(v) == "table" and type(datum[k]) == "table" then
            stripNonTransmissableFields(datum[k], v)
        elseif v == true then
            datum[k] = nil
        end
    end
end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/Transmission.lua#L114C19-L114C19
function CompressDisplay(data, version)
    -- Clean up custom trigger fields that are unused
    -- Those can contain lots of unnecessary data.
    -- Also we warn about any custom code, so removing unnecessary
    -- custom code prevents unnecessary warnings
    for triggernum, triggerData in ipairs(data.triggers) do
        local trigger, untrigger = triggerData.trigger, triggerData.untrigger
    
        if (trigger and trigger.type ~= "custom") then
            trigger.custom = nil;
            trigger.customDuration = nil;
            trigger.customName = nil;
            trigger.customIcon = nil;
            trigger.customTexture = nil;
            trigger.customStacks = nil;
            if (untrigger) then
            untrigger.custom = nil;
            end
        end
    end
  
    local copiedData = CopyTable(data)
    local non_transmissable = version >= 2000 and non_transmissable_fields_v2000 or non_transmissable_fields
    stripNonTransmissableFields(copiedData, non_transmissable)
    copiedData.tocversion = WeakAuras.BuildInfo
    return copiedData;
  end

-- https://github.com/WeakAuras/WeakAuras2/blob/5d1854a1aaa764c22fae434ce388118e882713f9/WeakAuras/Transmission.lua#L351C1-L351C1
function DisplayToString(id)
    local data = WeakAuras.GetData(id)
    if data then
        data.uid = data.uid or WeakAuras.GenerateUniqueID()

        -- Check which transmission version we want to use
        local version = 1421
        for child in CoTraverseSubGroups(data) do -- luacheck: ignore
            version = 2000
            break;
        end

        local transmitData = CompressDisplay(data, version)
        local transmit = {
          m = "d",
          d = transmitData,
          v = version,
          s = versionString
        }
        
        if(data.controlledChildren) then
            transmit.c = {};
            local uids = {}
            local index = 1

            for child in CoTraverseAllChildren(data) do
                if child.uid then
                    if uids[child.uid] then
                        child.uid = WeakAuras.GenerateUniqueID()
                    else
                        uids[child.uid] = true
                    end
                else
                    child.uid = GenerateUniqueID()
                end
                transmit.c[index] = CompressDisplay(child, version);
                index = index + 1
            end
        end

        return TableToString(transmit, true);
    else
        print("No data found for ", id)
        return "";
    end
end