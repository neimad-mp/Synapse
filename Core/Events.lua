-- Core/Events.lua
-- Event router + lightweight cast detection (Vanilla/Turtle, Lua 5.0 safe)

Synapse = Synapse or {}
SynapseDB = SynapseDB or { settings = { debug = false }, }
Synapse.Combat = Synapse.Combat or { TargetCastingExpire = 0, TargetLastCastName = nil }

local function dprint(msg)
  if SynapseDB and SynapseDB.settings and SynapseDB.settings.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse:debug]|r " .. tostring(msg), 0.7, 0.9, 1.0)
  end
end

local ev = CreateFrame("Frame")

-- Route some useful events to modules (modules can implement OnEvent/OnTargetChange/OnAura)
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("UNIT_AURA")

-- Optional: primitive cast-start heuristics from chat messages (English clients)
-- NOTE: Vanilla/Turtle doesn’t expose CombatLogGetCurrentEventInfo; we sniff “begins to cast”.
ev:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
ev:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_BUFF")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE")

local function markTargetCasting(msg)
  -- Crude English-only heuristic: look for "begins to cast" and the current target's name
  local tname = UnitName("target")
  if not tname or not msg then return end
  if string.find(msg, "begins to cast") and string.find(msg, tname) then
    Synapse.Combat.TargetCastingExpire = GetTime() + 2.0 -- 2s reaction window
    Synapse.Combat.TargetLastCastName = tname
    dprint("Detected target cast: " .. msg)
  end
end

ev:SetScript("OnEvent", function()
  local mod = Synapse.Active()

  -- Generic pass-through
  if mod and mod.OnEvent then
    -- Vanilla uses globals: event, arg1..argN
    mod:OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  end

  -- Convenience routing
  if event == "PLAYER_TARGET_CHANGED" then
    if mod and mod.OnTargetChange then mod:OnTargetChange() end
    -- Clear/retarget cast heuristic when swapping targets
    Synapse.Combat.TargetCastingExpire = 0
    Synapse.Combat.TargetLastCastName = UnitName("target")
    return
  end

  if event == "UNIT_AURA" then
    -- Only forward for player/target for now
    if (arg1 == "player" or arg1 == "target") and mod and mod.OnAura then
      mod:OnAura(arg1)
    end
    return
  end

  -- Heuristic: chat messages that often include "begins to cast <Spell>"
  if arg1 then
    markTargetCasting(arg1)
  end
end)
