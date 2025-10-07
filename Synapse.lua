-- Synapse (core bootstrap) — Vanilla/Turtle (Lua 5.0 safe)

-- Global namespace & SavedVariables -----------------------------------------
Synapse   = Synapse or {}
SynapseDB = SynapseDB or { settings = { debug = false }, }

-- Safe print helpers ---------------------------------------------------------
function Synapse.Print(msg, r, g, b)
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r " .. tostring(msg), r or 1, g or 1, b or 1)
end

local function dprint(msg)
  if SynapseDB and SynapseDB.settings and SynapseDB.settings.debug then
    Synapse.Print("[debug] " .. tostring(msg), 0.7, 0.9, 1.0)
  end
end

-- Class helper (Vanilla API) -------------------------------------------------
function Synapse.PlayerClass()
  local _, class = UnitClass("player")
  return class
end

-- Provisional Click (Engine may override this later) -------------------------
if not Synapse.Click then
  function Synapse.Click()
    local active = nil
    if Synapse.Active then
      active = Synapse.Active()
    end
    if active and active.OnClick then
      dprint("Dispatching click to active module (provisional).")
      active:OnClick()
      return
    end
    Synapse.Print("No active module for this class yet (" .. (Synapse.PlayerClass() or "?") .. ").")
  end
end

-- Slash command --------------------------------------------------------------
SlashCmdList = SlashCmdList or {}
SLASH_SYNAPSE1 = "/synapse"

local function Synapse_Help()
  Synapse.Print("Commands:", 0.8, 1.0, 1.0)
  Synapse.Print("/synapse                - show module/status")
  Synapse.Print("/synapse click          - force a single rotation click")
  Synapse.Print("/synapse debug on|off   - toggle debug logging")
  Synapse.Print("/synapse debug toggle   - flip debug on/off")
  Synapse.Print("/synapse module         - show active module info")
  Synapse.Print("/synapse repair         - adopt pending modules now")
end

local function Synapse_ShowStatus()
  local class = Synapse.PlayerClass() or "UNKNOWN"
  local dbg = (SynapseDB and SynapseDB.settings and SynapseDB.settings.debug) and "ON" or "OFF"
  local hasActive = (Synapse.Active and Synapse.Active() and true) or false
  local modName = "none"
  if hasActive and Synapse.Active().Name then
    modName = Synapse.Active().Name
  elseif hasActive then
    modName = class
  end
  Synapse.Print("Class: " .. class .. "  |  Active module: " .. modName .. "  |  Debug: " .. dbg)
end

local function Synapse_SetDebug(on)
  SynapseDB.settings = SynapseDB.settings or {}
  SynapseDB.settings.debug = on and true or false
  Synapse.Print("Debug is now " .. (SynapseDB.settings.debug and "ON" or "OFF") .. ".")
end

-- Adoption helper (safe to call anytime) ------------------------------------
function Synapse.AdoptPendingModules()
  if not Synapse.RegisterModule then
    dprint("RegisterModule not ready; pending adoption deferred.")
    return
  end
  if Synapse.PendingModules then
    for class, mod in pairs(Synapse.PendingModules) do
      Synapse.RegisterModule(class, mod)
    end
    Synapse.PendingModules = nil
    dprint("Adopted pending modules.")
  end
end

SlashCmdList["SYNAPSE"] = function(msg)
  msg = string.lower(msg or "")

  if msg == "" then
    Synapse_ShowStatus()
    Synapse_Help()
    return
  end

  if msg == "click" then
    Synapse.Click()
    return
  end

  if string.find(msg, "^debug") then
    if msg == "debug on" then Synapse_SetDebug(true); return end
    if msg == "debug off" then Synapse_SetDebug(false); return end
    if msg == "debug toggle" then
      Synapse_SetDebug(not (SynapseDB.settings and SynapseDB.settings.debug))
      return
    end
    Synapse.Print("Usage: /synapse debug on|off|toggle")
    return
  end

  if msg == "module" then
    Synapse_ShowStatus()
    return
  end

  if msg == "repair" then
    Synapse.AdoptPendingModules()
    Synapse_ShowStatus()
    return
  end

  Synapse_Help()
end

-- Login banner & adoption handshake -----------------------------------------
local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
  -- Adopt in case Modules loaded before Core/Engine
  Synapse.AdoptPendingModules()

  -- Friendly banner
  Synapse.Print("v0.1 loaded — type /synapse for help.", 0.1, 0.9, 0.3)

  -- If Core/Engine provided Active() + module OnLogin hook, call it
  if Synapse.Active then
    local mod = Synapse.Active()
    if mod and mod.OnLogin then
      dprint("Calling active module OnLogin().")
      mod:OnLogin()
    end
  end
end)
