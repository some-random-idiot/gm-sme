local predictedSounds = {}

local muffle = GetConVar("sme_active")

local attenuation = CreateConVar("sme_attenuation", 1, {FCVAR_ARCHIVE}, "Enable or disable custom attenuation. Disable this if you think sound radii are too low.", 0, 1)
local soundBounce = CreateConVar("sme_sound_bouncing", 1, {FCVAR_ARCHIVE}, "Enable or disable sound bouncing. You can turn this off if you're experiencing performance problems. Note that this makes sound muffling way less accurate.", 0, 1)
local soundLaunchDist = CreateConVar("sme_sound_launch_dist", 200, {FCVAR_ARCHIVE}, "Part of sound bouncing. How far can a sound launch from a source before it starts bouncing.", 1, 1000)
local minThickness = CreateConVar("sme_min_thickness", 100, {FCVAR_ARCHIVE}, "How much distance between you and where a sound source hit a solid for muffling effect to apply. Increase if you think sounds get muffled too easily. Decrease if you think that sounds hardly gets muffled. Setting it to 0 effectively disables it.", 0, 1000)
local farMuffleDistance = CreateConVar("sme_far_muffle_dist", 5000, {FCVAR_ARCHIVE}, "How far away should a sound be for it to be muffled regardless of occlusion. Setting it to 0 effectively disables it.", 0, 10000)

-- Bump this to top of the hooks stack.
-- This is to ensure that other hooks down the line recieve real sound name and not the prefixed version.
local tildeCount = 1
local emitSoundHookTable = hook.GetTable()["EntityEmitSound"]

if emitSoundHookTable then
    local emitSoundHooks = table.GetKeys(emitSoundHookTable)
    table.sort(emitSoundHooks, function(a, b)
        return a < b
    end)
    
    local _, replaceCount = string.gsub(emitSoundHooks[#emitSoundHooks], "~", "~")

    tildeCount = replaceCount
end

local tildes = string.rep("~", tildeCount + 1)

hook.Add("EntityEmitSound", tildes .. "SMEMuffler",  function(sndData)
    if not muffle:GetBool() then return end
    
    local entity = sndData.Entity
    local ply = LocalPlayer()
    local playedBySME = string.sub(sndData.SoundName, 1, 1) == ":"
    
    if not IsValid(ply) then return end
    if not playedBySME and not sndData.Pos and not IsValid(entity) then return end

    local eyePos = ply:EyePos()
    local origin = sndData.Pos and sndData.Pos or IsValid(entity) and entity:EyePos() or vector_origin
    local originUp = origin:Angle():Up()
    local originRight = origin:Angle():Right()
    local originFwd = origin:Angle():Forward()
    local filter = entity != ply and entity
    
    local minTr
    local trHitPlayer = false
    local distMin = math.huge
    if soundBounce:GetBool() then
        local range = soundLaunchDist:GetInt()
        local trCheckUp = util.QuickTrace(origin, originUp * range, filter)
        local trUpDist = trCheckUp.HitPos:Distance(origin)
        local trCheckDown = util.QuickTrace(origin, -originUp * range, filter)
        local trDownDist = trCheckDown.HitPos:Distance(origin)
        local trCheckLeft = util.QuickTrace(origin, -originRight * range, filter)
        local trLeftDist = trCheckLeft.HitPos:Distance(origin)
        local trCheckRight = util.QuickTrace(origin, originRight * range, filter)
        local trRightDist = trCheckRight.HitPos:Distance(origin)
        local trCheckFwd = util.QuickTrace(origin, originFwd * range, filter)
        local trFwdDist = trCheckFwd.HitPos:Distance(origin)
        local trCheckBack = util.QuickTrace(origin, -originFwd * range, filter)
        local trBackDist = trCheckBack.HitPos:Distance(origin)

        local trUp = util.TraceLine({
            start = origin + originUp * trUpDist,
            endpos = eyePos,
            filter = filter
        })
        local trDown = util.TraceLine({
            start = origin - originUp * trDownDist,
            endpos = eyePos,
            filter = filter
        })
        local trLeft = util.TraceLine({
            start = origin - originRight * trLeftDist,
            endpos = eyePos,
            filter = filter
        })
        local trRight = util.TraceLine({
            start = origin + originRight * trRightDist,
            endpos = eyePos,
            filter = filter
        })
        local trFwd = util.TraceLine({
            start = origin + originFwd * trFwdDist,
            endpos = eyePos,
            filter = filter
        })
        local trBack = util.TraceLine({
            start = origin - originFwd * trBackDist,
            endpos = eyePos,
            filter = filter
        })
        local traces = {trUp, trDown, trLeft, trRight, trFwd, trBack}

        -- for _, t in ipairs(traces) do
        --     debugoverlay.Line(t.StartPos, t.HitPos, 5, color_white, true)
        -- end

        for _, t in ipairs(traces) do
            if t.Entity != ply then continue end
            trHitPlayer = true
            break
        end

        local distUp = trUp.HitPos:Distance(eyePos)
        local distDown = trDown.HitPos:Distance(eyePos)
        local distLeft = trLeft.HitPos:Distance(eyePos)
        local distRight = trRight.HitPos:Distance(eyePos)
        local distFwd = trFwd.HitPos:Distance(eyePos)
        local distBack = trBack.HitPos:Distance(eyePos)

        local distMinIndex = 0
        for index, d in ipairs({distUp, distDown, distLeft, distRight, distFwd, distBack}) do
            if distMin <= d then continue end

            distMin = d
            distMinIndex = index
        end
        minTr = traces[distMinIndex]
    else
        minTr = util.TraceLine({
            start = origin,
            endpos = eyePos,
            filter = filter
        })
        
        if minTr.Entity == ply then trHitPlayer = true end
        distMin = minTr.HitPos:Distance(eyePos)
    end
    
    local dsp = sndData.DSP
    local trueDist = minTr.StartPos:Distance(minTr.HitPos)
    local farAF = farMuffleDistance:GetInt() > 0 and trueDist > farMuffleDistance:GetInt() or false

    if not trHitPlayer and minTr.Hit then
        if distMin > 2000 then
            dsp = 31
        elseif distMin > 1000 then
            dsp = 14
        elseif distMin >= minThickness:GetInt() then
            dsp = 30
        end
        if attenuation:GetBool() then sndData.Volume = math.min(1000 / origin:Distance(eyePos), sndData.Volume) end
    elseif farAF then
        dsp = 132
        if attenuation:GetBool() then sndData.Volume = math.min(1500 / origin:Distance(eyePos), sndData.Volume) end
    end

    if dsp == 1 then
        -- We can't allow automatic DSP here because it messes up the muffling.
        dsp = 0
    end

    sndData.DSP = dsp

    local realName = sndData.SoundName

    if playedBySME then
        realName = string.sub(sndData.SoundName, 2)
    end

    -- We use a hilariously hacky way of determining whether a sound is predicted. Predicted sounds play both clientside and serverside on the same CurTime.
    if playedBySME and predictedSounds[realName] and sndData.Entity == LocalPlayer() then
        return false
    elseif not playedBySME then
        -- Clientside sound always play before the serverside one can be networked, which is why we can do this.
        predictedSounds[realName] = true
    end
    
    if playedBySME then
        sndData.SoundName = realName
    end

    return true
end)

net.Receive("SMENetworkSound", function()
    local snd = net.ReadTable()

    if snd.SentenceIndex and IsValid(snd.Entity) then
        -- Voice lines.
        EmitSentence(snd.OriginalSoundName, snd.Entity:GetPos(), snd.Entity:EntIndex(), snd.Channel, snd.Volume, snd.SoundLevel, snd.Flags, snd.Pitch)
    elseif (IsValid(snd.Entity) and snd.Entity:IsWorld() or not IsValid(snd.Entity)) and snd.Pos then
        -- Sound without a true source.
        -- If position is also nil, assume it's a bogus source.
        EmitSound(snd.SoundName, snd.Pos, 0, snd.Channel, snd.Volume, snd.SoundLevel, snd.Flags, snd.Pitch, snd.DSP)
    elseif IsValid(snd.Entity) and not snd.Entity:IsWorld() then
        -- Sound with true source.
        snd.Entity:EmitSound(":" .. snd.SoundName, snd.SoundLevel, snd.Pitch, snd.Volume, snd.Channel, snd.Flags, snd.DSP)
    end
end)
