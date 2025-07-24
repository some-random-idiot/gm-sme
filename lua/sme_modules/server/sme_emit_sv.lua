util.AddNetworkString("SMENetworkSound")

local muffle = GetConVar("sme_active")

hook.Add("EntityEmitSound", "SMEMuffler",  function(sndData)
    if not muffle:GetBool() then return end
    
    net.Start("SMENetworkSound", true)
    net.WriteTable(sndData)
    net.SendPAS(sndData.Pos and sndData.Pos or IsValid(sndData.Entity) and sndData.Entity:GetPos() or vector_origin)

    return false
end)