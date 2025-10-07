-- Modules/Rogue.lua
-- Synapse Rogue Module (RoguePrio v1.6 wrapped) — Vanilla/Turtle, Lua 5.0 safe

local Rogue = {
  Name = "RoguePrio v1.6",
  Version = "1.6",
}

----------------------------------------------------------------
-- Spellbook utilities
----------------------------------------------------------------
Rogue.SB = {}

local function SpellIndex(name)
  if Rogue.SB[name] then return Rogue.SB[name] end
  for i = 1, 180 do
    local s = GetSpellName(i, "spell")
    if s == name then Rogue.SB[name] = i; return i end
  end
  return nil
end

local function SpellReady(name)
  local idx = SpellIndex(name)
  if not idx then return false end
  local start, duration, enable = GetSpellCooldown(idx, "spell")
  -- Turtle/Vanilla: ready if start==0 or duration==0 (defensive across cores)
  if (start == 0) or (duration == 0) then return true end
  -- Fallback check: timer expired
  local remain = (start + duration) - GetTime()
  return remain <= 0
end

----------------------------------------------------------------
-- Core helpers
----------------------------------------------------------------
local function CP()
  local v = GetComboPoints("target")
  return v or 0
end

local function Energy()
  local v = UnitMana("player")
  return v or 0
end

local function ValidTarget()
  return UnitExists("target") and UnitCanAttack("player", "target")
end

local function BuffUp(texPart)
  for i=1,16 do
    local tex = UnitBuff("player", i)
    if not tex then break end
    if string.find(tex, texPart) then return true end
  end
  return false
end

local function DebuffUp(texPart)
  for i=1,16 do
    local tex = UnitDebuff("target", i)
    if not tex then break end
    if string.find(tex, texPart) then return true end
  end
  return false
end

-- Stealth detector that works in Vanilla/Turtle (texture check)
local function IsStealthedLegacy()
  for i=1,16 do
    local tex = UnitBuff("player", i)
    if not tex then break end
    if string.find(tex, "Ability_Stealth") then return true end
  end
  return false
end

local COST = {
  ["Eviscerate"]       = 30,
  ["Slice and Dice"]   = 20,
  ["Rupture"]          = 20,
  ["Ghostly Strike"]   = 40,
  ["Sinister Strike"]  = 40,
  ["Kick"]             = 25,
  ["Surprise Attack"]  = 10,
  ["Cheap Shot"]       = 60, -- only to vet energy checks if needed
}

----------------------------------------------------------------
-- Immunity tracking (by mob name)
----------------------------------------------------------------
Rogue.Immune = Rogue.Immune or {}

----------------------------------------------------------------
-- Next ability decision
----------------------------------------------------------------
local function NextSpell()
  if not ValidTarget() then return nil end

  local name = UnitName("target")
  local cp, e = CP(), Energy()
  local snd = BuffUp("Ability_Rogue_SliceDice")
  local rup = DebuffUp("Ability_Rogue_Rupture")

  -- Respect per-mob bleed immunity memory
  if name and Rogue.Immune[name] then rup = true end

  -- Highest priority: Kick if target is (likely) casting
  if Synapse and Synapse.IsTargetCasting and Synapse.IsTargetCasting() then
    if SpellReady("Kick") and e >= COST["Kick"] then
      return "Kick", COST["Kick"]
    end
  end

  -- Stealth opener handled in OnClick() before we reach here

  -- Ghostly Strike opener (nice early damage/avoid)
  if cp < 1 then
    if SpellReady("Ghostly Strike") and e >= COST["Ghostly Strike"] then
      return "Ghostly Strike", COST["Ghostly Strike"]
    end
    return "Sinister Strike", COST["Sinister Strike"]
  end

  -- With 1 CP, establish SnD or Rupture
  if cp == 1 then
    if not snd and e >= COST["Slice and Dice"] then
      return "Slice and Dice", COST["Slice and Dice"]
    end
    if not rup and e >= COST["Rupture"] then
      return "Rupture", COST["Rupture"]
    end
    if SpellReady("Ghostly Strike") and e >= COST["Ghostly Strike"] then
      return "Ghostly Strike", COST["Ghostly Strike"]
    end
    return "Sinister Strike", COST["Sinister Strike"]
  end

  -- 2+ CP: finishers when setup buffs/debuffs are up
  if cp >= 2 then
    if snd and rup and e >= COST["Eviscerate"] then
      return "Eviscerate", COST["Eviscerate"]
    end
    if not snd and e >= COST["Slice and Dice"] then
      return "Slice and Dice", COST["Slice and Dice"]
    end
    if not rup and e >= COST["Rupture"] then
      return "Rupture", COST["Rupture"]
    end
  end

  return "Sinister Strike", COST["Sinister Strike"]
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------
function Rogue:OnClick()
  -- Ensure we have a hostile target
  if (not UnitExists("target")) or UnitIsFriend("player","target") then
    TargetNearestEnemy()
  end
  if not ValidTarget() then return end

  -- Start auto-attack if not already swinging
  AttackTarget()

  -- Stealth opener (Vanilla-safe)
  if IsStealthedLegacy() and SpellReady("Cheap Shot") and Energy() >= (COST["Cheap Shot"] or 60) then
    CastSpellByName("Cheap Shot")
    return
  end

  -- Decide next ability
  local spell, need = NextSpell()
  if not spell then return end

  if need and Energy() < need then
    -- Not enough energy; try again on next click
    return
  end

  CastSpellByName(spell)
end

function Rogue:OnLogin()
  if Synapse and Synapse.Print then
    Synapse.Print("Rogue module ready. /synapse click to test.")
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Rogue module ready. /synapse click to test.")
  end
end

----------------------------------------------------------------
-- Registration
----------------------------------------------------------------
if Synapse and Synapse.RegisterModule then
  Synapse.RegisterModule("ROGUE", Rogue)
else
  -- Fallback if Core not yet loaded; Engine adopts pending modules later.
  Synapse = Synapse or {}
  Synapse.PendingModules = Synapse.PendingModules or {}
  Synapse.PendingModules["ROGUE"] = Rogue
end
