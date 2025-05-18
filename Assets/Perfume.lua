--!Type(Client)

--!SerializeField
local perfumeSprayObject: GameObject = nil
--!SerializeField
local effectKey: string = "floral" -- or "sweet", "mystic", etc.

function self:ClientStart()
    local tapHandler = self:GetComponent(TapHandler)
    if tapHandler then
        tapHandler.Tapped:Connect(function()
            ToggleSpray()
            ApplyPerfumeToPlayer()
        end)
    end
end

function ToggleSpray()
    if perfumeSprayObject.activeSelf then return end

    perfumeSprayObject:SetActive(true)

    Timer.After(5, function()
        perfumeSprayObject:SetActive(false)
    end)
end

function ApplyPerfumeToPlayer()
    local PerfumeEffectManager = require("PerfumeEffectManager")
    PerfumeEffectManager.ApplyPerfumeEffect(client.localPlayer, effectKey)
end
