-- Modules/Mage.lua
-- Synapse Mage Module — Vanilla/Turtle, Lua 5.0 safe

local Mage = {
  Name    = "Mage (Synapse scaffold)",
  Version = "0.2",
}

-- Ensure Synapse exists (just in case)
Synapse = Synapse or {}

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

local function HasSpell(name)
  return SpellIndex(name) ~= nil
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

-- Crude melee-ish range (Vanilla-friendly)
local function InMelee()
  return CheckInteractDistance and CheckInteractDistance("target", 3)
end

------------------------------------------------------------
-- Approx costs (varies by rank; just guards)
------------------------------------------------------------
local COST = {
  ["Fireball"]       = 95,
  ["Frostbolt"]      = 75,
  ["Fire Blast"]     = 110,
  ["Frost Nova"]     = 75,
  ["Counterspell"]   = 0,
  ["Arcane Missiles"]= 150,
}

------------------------------------------------------------
-- Rotation (HasSpell-gated)
------------------------------------------------------------
local function NextSpell()
  if not ValidTarget() then return nil end

  -- 1) Interrupt
  if HasSpell("Counterspell") and Synapse.IsTargetCasting and Synapse.IsTargetCasting() then
    if SpellReady("Counterspell") then return "Counterspell", COST["Counterspell"] end
  end

  -- 2) Frost Nova if in melee (if known)
  if InMelee() and HasSpell("Frost Nova") and SpellReady("Frost Nova") and Mana() >= (COST["Frost Nova"] or 0) then
    return "Frost Nova", COST["Frost Nova"]
  end

  -- 3) Instant filler if known
  if HasSpell("Fire Blast") and SpellReady("Fire Blast") and Mana() >= (COST["Fire Blast"] or 0) then
    return "Fire Blast", COST["Fire Blast"]
  end

  -- 4) Main nuke: prefer Frostbolt if known, else Fireball, else Missiles
  if HasSpell("Frostbolt") and Mana() >= (COST["Frostbolt"] or 0) then
    return "Frostbolt", COST["Frostbolt"]
  end
  if HasSpell("Fireball") and Mana() >= (COST["Fireball"] or 0) then
    return "Fireball", COST["Fireball"]
  end
  if HasSpell("Arcane Missiles") and Mana() >= (COST["Arcane Missiles"] or 0) then
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

  local spell, need = NextSpell()
  if not spell then return end
  if need and Mana() < need then return end

  CastSpellByName(spell)
end

function Mage:OnLogin()
  if Synapse.Print then Synapse.Print("Mage module ready. /synapse click to test.")
  else DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Mage module ready. /synapse click to test.") end
end

-- Optional hooks
function Mage:OnEvent(ev, a1,a2,a3,a4,a5) end
function Mage:OnAura(unit) end
function Mage:OnTargetChange() end

------------------------------------------------------------
-- Registration (hard-safe)
------------------------------------------------------------
Synapse.Modules = Synapse.Modules or {}
Synapse.PendingModules = Synapse.PendingModules or {}
if type(Synapse.RegisterModule) == "function" then
  Synapse.RegisterModule("MAGE", Mage)
else
  Synapse.Modules["MAGE"] = Mage
  Synapse.PendingModules["MAGE"] = Mage
end
