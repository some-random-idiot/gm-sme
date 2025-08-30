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
    recipientfilter = recipientfilter and recipientfilter or player.GetAll()

    local soundPatch = oldCreateSound(ent, snd, recipientfilter)

    soundPatchRelations[soundPatch] = {
        Entity = ent,
        SoundName = snd,
        RecipientFilter = recipientfilter,
        Playing = false
    }

    net.Start("SMENetworkCreateSound", true)
    net.WriteEntity(ent)
    net.WriteString(snd)
    net.Send(recipientfilter)
    
    return soundPatch
end

if VJ then
    local oldVJCreateSound = VJ.CreateSound
    -- VJ's CreateSound uses localized CreateSound, which means we can't override CreateSound and call it a day.
    -- Hopefully, not many addons does this.
    function VJ.CreateSound(ent, sdFile, sdLevel, sdPitch, customFunc)
        local oldCustomFunc = customFunc
        
        if istable(sdFile) then
            sdFile = sdFile[math.random(1, #sdFile)]
        end

        if not sdFile then return end

        customFunc = function(sndP)
            -- This has to be done because VJ's CreateSound calls PlayEx right after a soundpatch is created.
            -- Luckily, custom function is called right in the middle of it.
            soundPatchRelations[sndP] = {
                Entity = ent,
                SoundName = sdFile,
                RecipientFilter = VJ_RecipientFilter,
                Playing = false
            }

            if oldCustomFunc then oldCustomFunc(sndP) end
        end

        local soundPatch = oldVJCreateSound(ent, sdFile, sdLevel, sdPitch, customFunc)

        net.Start("SMENetworkCreateSound", true)
        net.WriteEntity(ent)
        net.WriteString(sdFile)
        net.Send(VJ_RecipientFilter)

        soundPatch:SetSoundLevel(sdLevel)
        soundPatch:ChangePitch(sdPitch)

        return soundPatch
    end
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
local soundPatchIsPlayingOld = soundPatchMeta.IsPlaying

function soundPatchMeta:Play()
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]

        if not relation then return end

        net.Start("SMENetworkSoundPatchPlay", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.Send(relation.RecipientFilter)

        timer.Remove(tostring(self) .. "FadeOutUpdateIsPlaying")
        relation.Playing = true

        return
    end

    soundPatchPlayOld(self)
end

function soundPatchMeta:PlayEx(vol, pitch)
    if muffle:GetBool() and vol and pitch then
        local relation = soundPatchRelations[self]

        if not relation then return end

        net.Start("SMENetworkSoundPatchPlayEx", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteFloat(vol)
        net.WriteUInt(pitch, 8)
        net.Send(relation.RecipientFilter)
        
        timer.Remove(tostring(self) .. "FadeOutUpdateIsPlaying")
        relation.Playing = true

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

        timer.Remove(tostring(self) .. "FadeOutUpdateIsPlaying")
        relation.Playing = false

        return
    end

    soundPatchStopOld(self)
end

function soundPatchMeta:ChangePitch(pitch, delta)
    if muffle:GetBool() and pitch then
        delta = delta and delta or 0
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
    if muffle:GetBool() and vol then
        delta = delta and delta or 0
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
    if muffle:GetBool() and seconds then
        local relation = soundPatchRelations[self]
        
        if not relation then return end

        net.Start("SMENetworkSoundPatchFadeOut", true)
        net.WriteEntity(relation.Entity)
        net.WriteString(relation.SoundName)
        net.WriteFloat(seconds)
        net.Send(relation.RecipientFilter)
        
        timer.Create(tostring(self) .. "FadeOutUpdateIsPlaying", seconds, 1, function()
            if not relation then return end
            relation.Playing = false
        end)

        return
    end

    soundPatchFadeOutOld(self, seconds)
end

function soundPatchMeta:SetDSP(dsp)
    if muffle:GetBool() and dsp then
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
    if muffle:GetBool() and level then
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

function soundPatchMeta:IsPlaying()
    if muffle:GetBool() then
        local relation = soundPatchRelations[self]
        
        if not relation then return end
        
        return relation.Playing
    end

    return soundPatchIsPlayingOld(self)
end