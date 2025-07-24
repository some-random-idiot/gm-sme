util.AddNetworkString("SMENetworkCreateSound")
util.AddNetworkString("SMENetworkSoundPatchPlay")
util.AddNetworkString("SMENetworkSoundPatchPlayEx")
util.AddNetworkString("SMENetworkSoundPatchStop")
util.AddNetworkString("SMENetworkSoundPatchChangeVol")
util.AddNetworkString("SMENetworkSoundPatchChangePitch")
util.AddNetworkString("SMENetworkSoundPatchFadeOut")
util.AddNetworkString("SMENetworkSoundPatchSetDSP")
util.AddNetworkString("SMENetworkSoundPatchSetSoundLevel")

local muffle = GetConVar("sme_active")

-- We need to keep track of serverside soundpatches to replicate its actions clientside.
-- Sound patch functions (other than play) do not trigger EntityEmitSound hook, which means we have to create custom networking for it.
local soundPatchRelations = {}
local oldCreateSound = CreateSound

CreateSound = function(ent, snd, recipientfilter)
    local soundPatch = oldCreateSound(ent, snd, recipientfilter)

    soundPatchRelations[soundPatch] = {
        Entity = ent, 
        SoundName = snd,
        RecipientFilter = recipientfilter
    }

    net.Start("SMENetworkCreateSound")
    net.WriteEntity(ent)
    net.WriteString(snd)
    net.Send(recipientfilter)

    return soundPatch
end

local soundPatchMeta = FindMetaTable("CSoundPatch")
local soundPatchPlayOld = soundPatchMeta.Play
local soundPatchPlayExOld = soundPatchMeta.PlayEx
local soundPatchStopOld = soundPatchMeta.Stop
local soundPatchChangeVolOld = soundPatchMeta.ChangeVolume
local soundPatchChangePitchOld = soundPatchMeta.ChangePitch
local soundPatchFadeOutOld = soundPatchMeta.FadeOut
local soundPatchSetDSPOld = soundPatchMeta.SetDSP
local soundPatchSetSoundLevelOld = soundPatchMeta.SetSoundLevel

function soundPatchMeta:Play()
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]

        if not relation then return end

        net.Start("SMENetworkSoundPatchPlay", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchPlayOld(self)
end

function soundPatchMeta:PlayEx(vol, pitch)
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]

        if not relation then return end

        net.Start("SMENetworkSoundPatchPlayEx", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteFloat(vol)
        net.WriteUInt(pitch, 8)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchPlayExOld(self, vol, pitch)
end

function soundPatchMeta:Stop()
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end
        
        net.Start("SMENetworkSoundPatchStop", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchStopOld(self)
end

function soundPatchMeta:ChangePitch(pitch, delta)
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end
        
        net.Start("SMENetworkSoundPatchChangePitch", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteUInt(pitch, 8)
        net.WriteFloat(delta)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchChangePitchOld(self, pitch, delta)
end

function soundPatchMeta:ChangeVolume(vol, delta)
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end

        net.Start("SMENetworkSoundPatchChangeVol", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteFloat(vol)
        net.WriteFloat(delta)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchChangeVolOld(self, vol, delta)
end

function soundPatchMeta:FadeOut(seconds)
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end

        net.Start("SMENetworkSoundPatchFadeOut", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteFloat(seconds)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchFadeOutOld(self, seconds)
end

function soundPatchMeta:SetDSP(dsp)
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end

        net.Start("SMENetworkSoundPatchSetDSP", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteUInt(dsp, 8)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchSetDSPOld(self, dsp)
end

function soundPatchMeta:SetSoundLevel(level)
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end

        net.Start("SMENetworkSoundPatchSetSoundLevel", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteUInt(level, 8)
        net.Send(relation.RecipientFilter)

        return
    end

    soundPatchSetSoundLevelOld(self, level)
end