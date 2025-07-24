-- TODO: Test garbage collection.

local networkedSoundPatches = {}
local entNetworkedSoundPatches = {}

net.Receive("SMENetworkCreateSound", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    
    if not IsValid(ent) then return end

    local soundPatch = CreateSound(ent, snd)

    -- Use entity and sound name combined as a key because "You can only create one CSoundPatch per audio file, per entity at the same time.".
    networkedSoundPatches[ent:EntIndex() .. snd] = soundPatch

    if not entNetworkedSoundPatches[ent] then entNetworkedSoundPatches[ent] = {} end

    table.insert(entNetworkedSoundPatches[ent], soundPatch)
end)

net.Receive("SMENetworkSoundPatchPlay", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    
    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]

    if not soundPatch then return end

    soundPatch:Play()
end)

net.Receive("SMENetworkSoundPatchPlayEx", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    local vol = net.ReadFloat()
    local pitch = net.ReadUInt(8)

    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]

    if not soundPatch then return end

    soundPatch:PlayEx(vol, pitch)
end)

net.Receive("SMENetworkSoundPatchStop", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    
    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]

    if not soundPatch then return end

    soundPatch:Stop()
end)


net.Receive("SMENetworkSoundPatchChangePitch", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    local pitch = net.ReadUInt(8)
    local delta = net.ReadFloat()
    
    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]
    
    if not soundPatch then return end

    soundPatch:ChangePitch(pitch, delta)
end)

net.Receive("SMENetworkSoundPatchChangeVol", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    local vol = net.ReadFloat()
    local delta = net.ReadFloat()
    
    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]
    
    if not soundPatch then return end
    
    soundPatch:ChangePitch(vol, delta)
end)

net.Receive("SMENetworkSoundPatchFadeOut", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    local seconds = net.ReadFloat()
    
    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]
    
    if not soundPatch then return end

    soundPatch:FadeOut(seconds)
end)

net.Receive("SMENetworkSoundPatchSetDSP", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    local dsp = net.ReadUInt(8)
    
    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]
    
    if not soundPatch then return end
    
    soundPatch:SetDSP(dsp)
end)

net.Receive("SMENetworkSoundPatchSetSoundLevel", function()
    local ent = net.ReadEntity()
    local snd = net.ReadString()
    local level = net.ReadUInt(8)
    
    if not IsValid(ent) then return end

    local soundPatch = networkedSoundPatches[ent:EntIndex() .. snd]
    
    if not soundPatch then return end
    
    soundPatch:SetSoundLevel(level)
end)

hook.Add("EntityRemoved", "SMEEntCSoundPatchRemove", function(ent, fullUpdate)
    if fullUpdate then return end
    if not entNetworkedSoundPatches[ent] then return end

    for _, soundPatch in ipairs(entNetworkedSoundPatches[ent]) do
        soundPatch:Stop()
    end

    entNetworkedSoundPatches[ent] = nil  -- For garbage collection.
end)