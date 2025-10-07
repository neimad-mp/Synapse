-- Modules/Warrior.lua
-- Synapse Warrior Module — Vanilla/Turtle, Lua 5.0 safe

local Warrior = {
  Name    = "Warrior (Synapse scaffold)",
  Version = "0.1",
}

------------------------------------------------------------
-- Spellbook utilities
------------------------------------------------------------
Warrior.SB = {}

local function SpellIndex(name)
  if Warrior.SB[name] then return Warrior.SB[name] end
  for i = 1, 180 do
    local s = GetSpellName(i, "spell")
    if s == name then Warrior.SB[name] = i; return i end
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
-- Helpers (Warrior uses Rage via UnitMana in Vanilla)
------------------------------------------------------------
local function Rage() return UnitMana("player") or 0 end
local function ValidTarget()
  return UnitExists("target") and UnitCanAttack("player", "target")
end

-- Health % helper (for Execute threshold)
local function TargetHealthPct()
  local hp = UnitHealth("target")
  local hpmax = UnitHealthMax("target")
  if not hp or not hpmax or hpmax == 0 then return 100 end
  return math.floor((hp / hpmax) * 100)
end

------------------------------------------------------------
-- Costs (approx; rank-dependent in Vanilla)
------------------------------------------------------------
local COST = {
  ["Heroic Strike"] = 15,
  ["Rend"]          = 10,
  ["Hamstring"]     = 10,
  ["Bloodrage"]     = 0,   -- generates rage over time
  ["Execute"]       = 15,  -- plus consumes remaining rage
  ["Overpower"]     = 5,
  ["Sunder Armor"]  = 15,
  ["Pummel"]        = 10,  -- Berserker Stance; keep optional
}

------------------------------------------------------------
-- Basic rotation priorities:
-- 1) Interrupt if (likely) casting: Pummel (if spell exists & stance allows).
-- 2) Execute if target <=20% and enough rage.
-- 3) Keep Rend (if not immune/undead/etc.—no detection here, simple).
-- 4) Sunder Armor as filler if rage allows (optional).
-- 5) Heroic Strike as main spender (simple).
-- 6) Hamstring if target is fleeing (not detected here; leave as manual).
-- 7) Use Bloodrage if rage is very low to kickstart.
------------------------------------------------------------
local function NextAbility()
  if not ValidTarget() then return nil end
  local r = Rage()
  local hpct = TargetHealthPct()

  -- 1) Interrupt
  if Synapse and Synapse.IsTargetCasting and Synapse.IsTargetCasting() then
    if SpellIndex("Pummel") and SpellReady("Pummel") and r >= COST["Pummel"] then
      return "Pummel", COST["Pummel"]
    end
  end

  -- 2) Execute
  if hpct <= 20 and SpellIndex("Execute") and r >= COST["Execute"] then
    return "Execute", COST["Execute"]
  end

  -- 7) Bloodrage to bootstrap (if very low rage)
  if r < 15 and SpellIndex("Bloodrage") and SpellReady("Bloodrage") then
    return "Bloodrage", COST["Bloodrage"]
  end

  -- 3) Keep Rend up (very naive — no bleed immunity checks)
  -- Texture check for debuffs is possible; keeping it simple for scaffold.
  if SpellIndex("Rend") and SpellReady("Rend") and r >= COST["Rend"] then
    -- Optional: gate on missing debuff (skipped for scaffold)
    -- return "Rend", COST["Rend"]
  end

  -- 4) Sunder Armor (optional armor shred)
  if SpellIndex("Sunder Armor") and SpellReady("Sunder Armor") and r >= COST["Sunder Armor"] then
    -- return "Sunder Armor", COST["Sunder Armor"]
  end

  -- 5) Heroic Strike as a reliable filler
  if SpellIndex("Heroic Strike") and r >= COST["Heroic Strike"] then
    return "Heroic Strike", COST["Heroic Strike"]
  end

  -- 6) Hamstring (manual/conditional; omitted by default)
  -- if SpellIndex("Hamstring") and r >= COST["Hamstring"] then
  --   return "Hamstring", COST["Hamstring"]
  -- end

  return nil
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------
function Warrior:OnClick()
  if (not UnitExists("target")) or UnitIsFriend("player","target") then
    TargetNearestEnemy()
  end
  if not ValidTarget() then return end

  AttackTarget()

  local ability, need = NextAbility()
  if not ability then return end
  if need and Rage() < need then return end

  CastSpellByName(ability)
end

function Warrior:OnLogin()
  if Synapse and Synapse.Print then
    Synapse.Print("Warrior module ready. /synapse click to test.")
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Warrior module ready. /synapse click to test.")
  end
end

-- Optional event hooks for future expansion
function Warrior:OnEvent(ev, a1,a2,a3,a4,a5) end
function Warrior:OnAura(unit) end
function Warrior:OnTargetChange() end

------------------------------------------------------------
-- Registration
------------------------------------------------------------
if Synapse and Synapse.RegisterModule then
  Synapse.RegisterModule("WARRIOR", Warrior)
else
  Synapse = Synapse or {}
  Synapse.PendingModules = Synapse.PendingModules or {}
  Synapse.PendingModules["WARRIOR"] = Warrior
end
