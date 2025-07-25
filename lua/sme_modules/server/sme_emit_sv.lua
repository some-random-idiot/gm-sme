util.AddNetworkString("SMENetworkSound")

local muffle = GetConVar("sme_active")

hook.Add("EntityEmitSound", "SMEMuffler",  function(sndData)
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