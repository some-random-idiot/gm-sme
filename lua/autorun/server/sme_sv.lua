local cl_luas, _ = file.Find("sme_modules/client/*", "LUA")

for _, lua in ipairs(cl_luas) do
    AddCSLuaFile("sme_modules/client/" .. lua)
end

cvars.AddChangeCallback("sme_active", function(cvar, old, new)
    if new == "1" then
        print("[SME] Muffler is now active.")
    else
        print("[SME] Muffler is now inactive.")
    end
end, "SMEChanged")

print("[SME] Sound Muffling Effect initialized!")