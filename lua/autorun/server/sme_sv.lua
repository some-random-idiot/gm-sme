util.AddNetworkString("SMENetworkSound")
util.AddNetworkString("SMENetworkSoundPatchPlay")
util.AddNetworkString("SMENetworkSoundPatchStop")
util.AddNetworkString("SMENetworkSoundPatchChangeVol")

local muffle = CreateConVar("sme_active", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable or disable sound muffling.", 0, 1)

-- We need to keep track of serverside soundpatches to replicate its actions clientside.
-- Sound patch functions (other than play) do not trigger EntityEmitSound hook, so this is the best solution I can think of.
local soundPatchRelations = {}

local oldCreateSound = CreateSound
CreateSound = function(ent, snd, filter)
    local soundPatch = oldCreateSound(ent, snd, filter)

    soundPatchRelations[soundPatch] = { ent, snd }

    return soundPatch
end

local soundPatchMeta = FindMetaTable("CSoundPatch")

local soundPatchPlayOld = soundPatchMeta.Play
local soundPatchPlayExOld = soundPatchMeta.PlayEx
local soundPatchStopOld = soundPatchMeta.Stop
function soundPatchMeta:Play()
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]

        if not relation then return end

        net.Start("SMENetworkSoundPatchPlay", true)
        net.WriteEntity(relation[1])
        net.WriteString(relation[2])
        net.WriteUInt(self:GetSoundLevel(), 8)
        net.WriteUInt(self:GetPitch(), 8)
        net.WriteFloat(self:GetVolume())
        net.WriteUInt(self:GetDSP(), 8)
        net.WriteUInt(SND_NOFLAGS, 11)
        net.Broadcast()

        return
    end

    soundPatchPlayOld(self)
end
function soundPatchMeta:PlayEx(vol, pitch)
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]

        if not relation then return end

        net.Start("SMENetworkSoundPatchPlay", true)
        net.WriteEntity(relation[1])
        net.WriteString(relation[2])
        net.WriteUInt(self:GetSoundLevel(), 8)
        net.WriteUInt(pitch, 8)
        net.WriteFloat(vol)
        net.WriteUInt(self:GetDSP(), 8)
        net.WriteUInt(SND_NOFLAGS, 11)
        net.Broadcast()

        return
    end

    soundPatchPlayExOld(self, vol, pitch)
end
function soundPatchMeta:Stop()
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end
        
        net.Start("SMENetworkSoundPatchStop", true)
        net.WriteEntity(relation[1])
        net.WriteString(relation[2])
        net.Broadcast()

        return
    end

    soundPatchStopOld(self)
end

local soundPatchChangeVolOld = soundPatchMeta.ChangeVolume
local soundPatchChangePitchOld = soundPatchMeta.ChangePitch
local soundPatchFadeOutOld = soundPatchMeta.FadeOut
function soundPatchMeta:ChangeVolume(vol, delta)
    soundPatchChangeVolOld(self, vol, delta)

    if muffle:GetBool() then
        -- Delta support is not possible because get volume always return 0 for some god-forsaken reason.
        local relation = soundPatchRelations[self]
        
        if not relation then return end

        net.Start("SMENetworkSoundPatchPlay", true)  -- We technically modify sounds using EmitSound so...
        net.WriteEntity(relation[1])
        net.WriteString(relation[2])
        net.WriteUInt(self:GetSoundLevel(), 8)
        net.WriteUInt(self:GetPitch(), 8)
        net.WriteFloat(vol)
        net.WriteUInt(self:GetDSP(), 8)
        net.WriteUInt(SND_CHANGE_VOL + SND_IGNORE_NAME, 11)
        net.Broadcast()
    end
end
function soundPatchMeta:ChangePitch(pitch, delta)
    soundPatchChangePitchOld(self, pitch, delta)
    
    if muffle:GetBool() then
        -- Same delta situation here.
        local relation = soundPatchRelations[self]
        
        if not relation then return end
        
        net.Start("SMENetworkSoundPatchPlay", true)
        net.WriteEntity(relation[1])
        net.WriteString(relation[2])
        net.WriteUInt(self:GetSoundLevel(), 8)
        net.WriteUInt(pitch, 8)
        net.WriteFloat(self:GetVolume())
        net.WriteUInt(self:GetDSP(), 8)
        net.WriteUInt(SND_CHANGE_PITCH + SND_IGNORE_NAME, 11)
        net.Broadcast()
    end
end
function soundPatchMeta:FadeOut(seconds)
    soundPatchFadeOutOld(self, seconds)

    if muffle:GetBool() then
        -- Same delta situation here.
        local relation = soundPatchRelations[self]
        
        if not relation then return end

        net.Start("SMENetworkSoundPatchPlay", true)
        net.WriteEntity(relation[1])
        net.WriteString(relation[2])
        net.WriteUInt(self:GetSoundLevel(), 8)
        net.WriteUInt(self:GetPitch(), 8)
        net.WriteFloat(0)
        net.WriteUInt(self:GetDSP(), 8)
        net.WriteUInt(SND_CHANGE_VOL + SND_IGNORE_NAME, 11)
        net.Broadcast()
    end
end

cvars.AddChangeCallback("sme_active", function(cvar, old, new)
    if new == "1" then
        print("[SME] Muffler is now active.")
    else
        print("[SME] Muffler is now inactive.")
    end
end, "SMEChanged")

hook.Add("EntityEmitSound", "SMEMuffler",  function(sndData)
    if not muffle:GetBool() then return end
    
    net.Start("SMENetworkSound", true)
    net.WriteTable(sndData)
    net.SendPAS(sndData.Pos and sndData.Pos or IsValid(sndData.Entity) and sndData.Entity:GetPos() or vector_origin)

    return false
end)