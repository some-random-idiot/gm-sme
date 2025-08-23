util.AddNetworkString("SMENetworkSound")

local muffle = GetConVar("sme_active")

-- The emit sound hook has to be at the bottom of the stack to let other hooks modify sounds.
local exclamationCount = 1
local emitSoundHookTable = hook.GetTable()["EntityEmitSound"]

if emitSoundHookTable then
    local emitSoundHooks = table.GetKeys(emitSoundHookTable)
    table.sort(emitSoundHooks, function(a, b)
        -- GetKeys returns in an unsorted manner.
        return a < b
    end)
    
    local _, replaceCount = string.gsub(emitSoundHooks[1], "!", "!")

    exclamationCount = replaceCount
end

local exclamations = string.rep("!", exclamationCount + 1)

hook.Add("EntityEmitSound",  exclamations .. "SMEMuffler",  function(sndData)
    if not muffle:GetBool() then return end

    if IsValid(sndData.Entity) and not sndData.Pos then
        -- This should help when the networking is too slow to network the entity in time before its removal.
        sndData.Pos = sndData.Entity:GetPos()
    end

    net.Start("SMENetworkSound", true)
    net.WriteTable(sndData)
    net.SendPAS(sndData.Pos and sndData.Pos or IsValid(sndData.Entity) and sndData.Entity:GetPos() or vector_origin)

    return false
end)