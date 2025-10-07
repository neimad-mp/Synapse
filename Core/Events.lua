-- Core/Events.lua
-- Event router + lightweight cast + parry detection (Vanilla/Turtle, Lua 5.0 safe)

Synapse = Synapse or {}
SynapseDB = SynapseDB or { settings = { debug = false }, }
Synapse.Combat = Synapse.Combat or { TargetCastingExpire = 0, TargetLastCastName = nil, RiposteExpire = 0 }

local function dprint(msg)
  if SynapseDB and SynapseDB.settings and SynapseDB.settings.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse:debug]|r " .. tostring(msg), 0.7, 0.9, 1.0)
  end
end

local ev = CreateFrame("Frame")

-- Module routing
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("UNIT_AURA")

-- Cast-start heuristics (English clients)
ev:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
ev:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")

-- NEW: Parry detection (these carry “You parry.” lines on 1.12)
ev:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")
ev:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES")

local function markTargetCasting(msg)
  local tname = UnitName("target")
  if not tname or not msg then return end
  if string.find(msg, "begins to cast") and string.find(msg, tname) then
    Synapse.Combat.TargetCastingExpire = GetTime() + 2.0
    Synapse.Combat.TargetLastCastName  = tname
    dprint("Detected target cast: " .. msg)
  end
end

local function markRiposte(msg)
  if not msg then return end
  local m = string.lower(msg)
  -- Examples seen: "You parry." or "... You parry."
  if string.find(m, "you parry") then
    Synapse.Combat.RiposteExpire = GetTime() + 5.5 -- slightly > 5s to be safe
    dprint("Parry detected → Riposte window opened.")
  end
end

ev:SetScript("OnEvent", function()
  local mod = Synapse.Active()

  -- Generic pass-through
  if mod and mod.OnEvent then
    mod:OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  end

  -- Convenience routing
  if event == "PLAYER_TARGET_CHANGED" then
    if mod and mod.OnTargetChange then mod:OnTargetChange() end
    Synapse.Combat.TargetCastingExpire = 0
    Synapse.Combat.TargetLastCastName  = UnitName("target")
    return
  end

  if event == "UNIT_AURA" then
    if (arg1 == "player" or arg1 == "target") and mod and mod.OnAura then
      mod:OnAura(arg1)
    end
    return
  end

  -- Heuristics
  if arg1 then
    markTargetCasting(arg1)
    if event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES"
       or event == "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES" then
      markRiposte(arg1)
    end
  end
end)
