-- Modules/Rogue.lua
-- Synapse Rogue Module (RoguePrio v1.6 wrapped) — Vanilla/Turtle, Lua 5.0 safe

local Rogue = {
  Name    = "RoguePrio v1.6",
  Version = "1.7",  -- bumped for Riposte
}

-- (optional one-time banner kept from earlier)
Synapse = Synapse or {}
if not Synapse.__once_rogue_loaded_banner then
  Synapse.__once_rogue_loaded_banner = true
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Modules\\Rogue.lua loaded.")
  end
end

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

local function HasSpell(name) return SpellIndex(name) ~= nil end

local function SpellReady(name)
  local idx = SpellIndex(name)
  if not idx then return false end
  local start, duration, enable = GetSpellCooldown(idx, "spell")
  if (start == 0) or (duration == 0) then return true end
  local remain = (start + duration) - GetTime()
  return remain <= 0
end

----------------------------------------------------------------
-- Core helpers
----------------------------------------------------------------
local function CP() return (GetComboPoints("target") or 0) end
local function Energy() return (UnitMana("player") or 0) end
local function ValidTarget() return UnitExists("target") and UnitCanAttack("player", "target") end

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

local function IsStealthedLegacy()
  for i=1,16 do
    local tex = UnitBuff("player", i)
    if not tex then break end
    if string.find(tex, "Ability_Stealth") then return true end
  end
  return false
end

local COST = {
  ["Riposte"]         = 10, -- NEW
  ["Eviscerate"]       = 30,
  ["Slice and Dice"]   = 20,
  ["Rupture"]          = 20,
  ["Ghostly Strike"]   = 40,
  ["Sinister Strike"]  = 40,
  ["Kick"]             = 25,
  ["Surprise Attack"]  = 10,
  ["Cheap Shot"]       = 60,
}

----------------------------------------------------------------
-- Immunity tracking (by mob name)
----------------------------------------------------------------
Rogue.Immune = Rogue.Immune or {}

----------------------------------------------------------------
-- Next ability decision (Kick → Riposte → rotation)
----------------------------------------------------------------
local function NextSpell()
  if not ValidTarget() then return nil end

  local name = UnitName("target")
  local cp, e = CP(), Energy()

  local snd_known = HasSpell("Slice and Dice")
  local rup_known = HasSpell("Rupture")
  local gs_known  = HasSpell("Ghostly Strike")
  local ev_known  = HasSpell("Eviscerate")
  local ss_known  = HasSpell("Sinister Strike")
  local kick_known= HasSpell("Kick")
  local rip_known = HasSpell("Riposte")

  local snd = snd_known and BuffUp("Ability_Rogue_SliceDice") or false
  local rup = rup_known and DebuffUp("Ability_Rogue_Rupture") or false

  if name and Rogue.Immune[name] then rup = true end

  -- 1) Interrupt
  if kick_known and Synapse and Synapse.IsTargetCasting and Synapse.IsTargetCasting() then
    if SpellReady("Kick") and e >= COST["Kick"] then
      return "Kick", COST["Kick"]
    end
  end

  -- 2) Riposte (only during short window after "You parry.")
  if rip_known and (Synapse and Synapse.Combat) then
    if (Synapse.Combat.RiposteExpire or 0) > GetTime() then
      if SpellReady("Riposte") and e >= COST["Riposte"] then
        return "Riposte", COST["Riposte"]
      end
    end
  end

  -- 3) Normal flow below
  if cp < 1 then
    if gs_known and SpellReady("Ghostly Strike") and e >= COST["Ghostly Strike"] then
      return "Ghostly Strike", COST["Ghostly Strike"]
    end
    if ss_known then return "Sinister Strike", COST["Sinister Strike"] end
    return nil
  end

  if cp == 1 then
    if snd_known and (not snd) and e >= COST["Slice and Dice"] then
      return "Slice and Dice", COST["Slice and Dice"]
    end
    if rup_known and (not rup) and e >= COST["Rupture"] then
      return "Rupture", COST["Rupture"]
    end
    if gs_known and SpellReady("Ghostly Strike") and e >= COST["Ghostly Strike"] then
      return "Ghostly Strike", COST["Ghostly Strike"]
    end
    if ss_known then return "Sinister Strike", COST["Sinister Strike"] end
    return nil
  end

  if cp >= 2 then
    if ev_known and snd and (rup or not rup_known) and e >= COST["Eviscerate"] then
      return "Eviscerate", COST["Eviscerate"]
    end
    if snd_known and (not snd) and e >= COST["Slice and Dice"] then
      return "Slice and Dice", COST["Slice and Dice"]
    end
    if rup_known and (not rup) and e >= COST["Rupture"] then
      return "Rupture", COST["Rupture"]
    end
  end

  if ss_known then return "Sinister Strike", COST["Sinister Strike"] end
  return nil
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------
function Rogue:OnClick()
  if (not UnitExists("target")) or UnitIsFriend("player","target") then
    TargetNearestEnemy()
  end
  if not ValidTarget() then return end

  AttackTarget()

  -- Stealth opener
  if HasSpell("Cheap Shot") and IsStealthedLegacy() and SpellReady("Cheap Shot") and Energy() >= (COST["Cheap Shot"] or 60) then
    CastSpellByName("Cheap Shot")
    return
  end

  local spell, need = NextSpell()
  if not spell then return end
  if need and Energy() < need then return end

  CastSpellByName(spell)
end

function Rogue:OnLogin()
  if Synapse and Synapse.Print then
    Synapse.Print("Rogue module ready (Riposte enabled). /synapse click to test.")
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Rogue module ready (Riposte). /synapse click to test.")
  end
end

----------------------------------------------------------------
-- Registration (hard-safe)
----------------------------------------------------------------
Synapse.Modules = Synapse.Modules or {}
Synapse.PendingModules = Synapse.PendingModules or {}
if type(Synapse.RegisterModule) == "function" then
  Synapse.RegisterModule("ROGUE", Rogue)
else
  Synapse.Modules["ROGUE"] = Rogue
  Synapse.PendingModules["ROGUE"] = Rogue
end
