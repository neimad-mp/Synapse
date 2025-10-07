-- Modules/Warrior.lua
-- Synapse Warrior Module — Vanilla/Turtle, Lua 5.0 safe

local Warrior = {
  Name    = "Warrior (Synapse scaffold)",
  Version = "0.2",
}

Synapse = Synapse or {}

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
-- Helpers (Rage uses UnitMana in 1.12)
------------------------------------------------------------
local function Rage() return UnitMana("player") or 0 end
local function ValidTarget() return UnitExists("target") and UnitCanAttack("player", "target") end

local function TargetHealthPct()
  local hp = UnitHealth("target"); local hpmax = UnitHealthMax("target")
  if not hp or not hpmax or hpmax == 0 then return 100 end
  return math.floor((hp / hpmax) * 100)
end

------------------------------------------------------------
-- Approx costs (rank-dependent)
------------------------------------------------------------
local COST = {
  ["Heroic Strike"] = 15,
  ["Rend"]          = 10,
  ["Hamstring"]     = 10,
  ["Bloodrage"]     = 0,
  ["Execute"]       = 15,
  ["Overpower"]     = 5,
  ["Sunder Armor"]  = 15,
  ["Pummel"]        = 10,
}

------------------------------------------------------------
-- Rotation (HasSpell-gated; simple)
------------------------------------------------------------
local function NextAbility()
  if not ValidTarget() then return nil end
  local r = Rage()
  local hpct = TargetHealthPct()

  -- 1) Interrupt if known (stance not managed here)
  if HasSpell("Pummel") and Synapse.IsTargetCasting and Synapse.IsTargetCasting() then
    if SpellReady("Pummel") and r >= (COST["Pummel"] or 0) then
      return "Pummel", COST["Pummel"]
    end
  end

  -- 2) Execute
  if HasSpell("Execute") and hpct <= 20 and r >= (COST["Execute"] or 0) then
    return "Execute", COST["Execute"]
  end

  -- 3) Bootstrap rage
  if HasSpell("Bloodrage") and r < 15 and SpellReady("Bloodrage") then
    return "Bloodrage", COST["Bloodrage"]
  end

  -- 4) Rend (very naive—no undead/immune detection)
  if HasSpell("Rend") and SpellReady("Rend") and r >= (COST["Rend"] or 0) then
    -- Uncomment to enforce early bleed:
    -- return "Rend", COST["Rend"]
  end

  -- 5) Sunder (optional shred)
  if HasSpell("Sunder Armor") and SpellReady("Sunder Armor") and r >= (COST["Sunder Armor"] or 0) then
    -- Uncomment if you want to stack Sunder by default:
    -- return "Sunder Armor", COST["Sunder Armor"]
  end

  -- 6) Main filler
  if HasSpell("Heroic Strike") and r >= (COST["Heroic Strike"] or 0) then
    return "Heroic Strike", COST["Heroic Strike"]
  end

  -- 7) Hamstring (manual situational; usually when fleeing)
  -- if HasSpell("Hamstring") and r >= (COST["Hamstring"] or 0) then
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

  local ab, need = NextAbility()
  if not ab then return end
  if need and Rage() < need then return end

  CastSpellByName(ab)
end

function Warrior:OnLogin()
  if Synapse.Print then Synapse.Print("Warrior module ready. /synapse click to test.")
  else DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Warrior module ready. /synapse click to test.") end
end

-- Optional hooks
function Warrior:OnEvent(ev, a1,a2,a3,a4,a5) end
function Warrior:OnAura(unit) end
function Warrior:OnTargetChange() end

------------------------------------------------------------
-- Registration (hard-safe)
------------------------------------------------------------
Synapse.Modules = Synapse.Modules or {}
Synapse.PendingModules = Synapse.PendingModules or {}
if type(Synapse.RegisterModule) == "function" then
  Synapse.RegisterModule("WARRIOR", Warrior)
else
  Synapse.Modules["WARRIOR"] = Warrior
  Synapse.PendingModules["WARRIOR"] = Warrior
end
