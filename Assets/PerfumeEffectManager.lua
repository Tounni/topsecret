--!Type(Module)

--!SerializeField
local perfumeEffect1: GameObject = nil
--!SerializeField
local perfumeEffect2: GameObject = nil
--!SerializeField
local perfumeEffect3: GameObject = nil
--!SerializeField
local perfumeEffect4: GameObject = nil
--!SerializeField
local perfumeEffect5: GameObject = nil
--!SerializeField
local sparkleEffect: GameObject = nil

-- Perfume effect map
local PerfumeEffects = {}

-- Events
local RequestPerfumeEffectEvent = Event.new("RequestPerfumeEffectEvent")
local ApplyPerfumeEffectEvent = Event.new("ApplyPerfumeEffectEvent")

-------------------
-- CLIENT SIDE
-------------------
function self:ClientAwake()
    -- Map is filled here so that GameObjects are properly loaded on client
    PerfumeEffects = {
        ["blue"] = perfumeEffect1,
        ["green"] = perfumeEffect2,
        ["purple"] = perfumeEffect3,
        ["strawberry"] = perfumeEffect4,
        ["watermelon"] = perfumeEffect5,
    }

    ApplyPerfumeEffectEvent:Connect(function(player, effectKey)
        local character = player.character
        if not character then
            warn("[Client]: Player character missing!")
            return
        end

        -- 🌸 Main perfume effect
        local mainEffect = PerfumeEffects[effectKey]
        if mainEffect then
            local fx = GameObject.Instantiate(mainEffect)
            fx.transform.parent = character.transform
            fx.transform.localPosition = Vector3.new(0, 0, 0)
            -- fx:Play()
            print("[Client]: Perfume effect '" .. effectKey .. "' applied to " .. player.name)
        else
            warn("[Client]: No perfume effect found for key: " .. tostring(effectKey))
        end

        -- ✨ Sparkle overlay
        if sparkleEffect then
            local sparkles = GameObject.Instantiate(sparkleEffect)
            sparkles.transform.parent = character.transform
            sparkles.transform.localPosition = Vector3.new(0, 0, 0)
            -- sparkles:Play()
            print("[Client]: Sparkle effect applied to " .. player.name)
        else
            warn("[Client]: sparkleEffect is not assigned!")
        end
    end)
end

-------------------
-- SERVER SIDE
-------------------
function self:ServerAwake()
    RequestPerfumeEffectEvent:Connect(function(player, effectKey)
        print("[Server]: Perfume request from " .. player.name .. " for key '" .. effectKey .. "'")
        ApplyPerfumeEffectEvent:FireAllClients(player, effectKey)
    end)
end

-------------------
-- EXPORTED API
-------------------
local PerfumeEffectManager = {}

function ApplyPerfumeEffect(player, effectKey)
    RequestPerfumeEffectEvent:FireServer(effectKey)
end

