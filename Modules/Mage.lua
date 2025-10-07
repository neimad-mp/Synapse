-- Modules/Mage.lua
-- Synapse Mage Module — Vanilla/Turtle, Lua 5.0 safe

local Mage = {
  Name    = "Mage (Synapse scaffold)",
  Version = "0.1",
}

------------------------------------------------------------
-- Spellbook utilities
------------------------------------------------------------
Mage.SB = {}

local function SpellIndex(name)
  if Mage.SB[name] then return Mage.SB[name] end
  for i = 1, 180 do
    local s = GetSpellName(i, "spell")
    if s == name then Mage.SB[name] = i; return i end
  end
  return nil
end

local function SpellReady(name)
  local idx = SpellIndex(name)
  if not idx then return false end
  local start, duration, enable = GetSpellCooldown(idx, "spell")
  if (start == 0) or (duration == 0) then return true end
  local remain = (start + duration) - GetTime()
  return remain <= 0
end

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function Mana() return UnitMana("player") or 0 end
local function ValidTarget()
  return UnitExists("target") and UnitCanAttack("player", "target")
end

-- Crude melee-range detector (works well enough for Nova decisions)
local function IsTargetInMelee()
  -- In Vanilla, exact range checking via API is limited; use weapon swing as hint.
  -- We’ll rely on player being hit / aura hooks optionally later.
  return CheckInteractDistance and CheckInteractDistance("target", 3) -- 3 = melee-ish
end

------------------------------------------------------------
-- Costs (approx; Turtle cores vary a bit by rank)
------------------------------------------------------------
local COST = {
  ["Fireball"]     = 95,
  ["Frostbolt"]    = 75,
  ["Fire Blast"]   = 110,
  ["Frost Nova"]   = 75,
  ["Counterspell"] = 0,
  ["Arcane Missiles"] = 150,
}

------------------------------------------------------------
-- Rotation
-- Priorities (very simple):
-- 1) Counterspell if target is (likely) casting.
-- 2) If target in melee, Frost Nova (if safe/ready).
-- 3) Fire Blast on cooldown for instant DPS (optional).
-- 4) Main nuke: Frostbolt (or Fireball fallback).
-- 5) Arcane Missiles as safe channel fallback when moving logic is absent.
------------------------------------------------------------
local function NextSpell()
  if not ValidTarget() then return nil end

  -- 1) Interrupt
  if Synapse and Synapse.IsTargetCasting and Synapse.IsTargetCasting() then
    if SpellReady("Counterspell") then
      return "Counterspell", COST["Counterspell"]
    end
  end

  -- 2) Frost Nova if in melee range (keep it conservative)
  if IsTargetInMelee() and SpellReady("Frost Nova") and Mana() >= COST["Frost Nova"] then
    return "Frost Nova", COST["Frost Nova"]
  end

  -- 3) Instant filler
  if SpellReady("Fire Blast") and Mana() >= COST["Fire Blast"] then
    return "Fire Blast", COST["Fire Blast"]
  end

  -- 4) Main nuke
  if Mana() >= COST["Frostbolt"] and SpellIndex("Frostbolt") then
    return "Frostbolt", COST["Frostbolt"]
  end
  if Mana() >= COST["Fireball"] and SpellIndex("Fireball") then
    return "Fireball", COST["Fireball"]
  end

  -- 5) Channel fallback
  if Mana() >= COST["Arcane Missiles"] and SpellIndex("Arcane Missiles") then
    return "Arcane Missiles", COST["Arcane Missiles"]
  end

  return nil
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function Mage:OnClick()
  if (not UnitExists("target")) or UnitIsFriend("player","target") then
    TargetNearestEnemy()
  end
  if not ValidTarget() then return end

  -- (No auto-attack for casters)
  local spell, need = NextSpell()
  if not spell then return end
  if need and Mana() < need then return end

  CastSpellByName(spell)
end

function Mage:OnLogin()
  if Synapse and Synapse.Print then
    Synapse.Print("Mage module ready. /synapse click to test.")
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Mage module ready. /synapse click to test.")
  end
end

-- Optional event hooks a future module could implement
function Mage:OnEvent(ev, a1,a2,a3,a4,a5) end
function Mage:OnAura(unit) end
function Mage:OnTargetChange() end

------------------------------------------------------------
-- Registration
------------------------------------------------------------
if Synapse and Synapse.RegisterModule then
  Synapse.RegisterModule("MAGE", Mage)
else
  Synapse = Synapse or {}
  Synapse.PendingModules = Synapse.PendingModules or {}
  Synapse.PendingModules["MAGE"] = Mage
end
