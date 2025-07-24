hook.Add("EntityRemoved", "SMEEntRemoved", function(ent, fullUpdate)
    if fullUpdate then return end

    -- CHAN_VOICE sounds seems to be able to exist without a parent entity so we need to stop it here.
    ent:EmitSound("common/null.wav", 75, 100, 1, CHAN_VOICE, SND_STOP_LOOPING)
end)

print("[SME] Sound Muffling Effect initialized!")