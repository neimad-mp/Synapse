-- Core/Engine.lua
-- Synapse core engine (Vanilla/Turtle, Lua 5.0 safe)

Synapse   = Synapse or {}
SynapseDB = SynapseDB or { settings = { debug = false }, }

local function dprint(msg)
  if SynapseDB and SynapseDB.settings and SynapseDB.settings.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse:debug]|r " .. tostring(msg), 0.7, 0.9, 1.0)
  end
end

-- Central module table
Synapse.Modules = Synapse.Modules or {}

-- Player class (token like "ROGUE")
local function PlayerClass()
  local _, class = UnitClass("player")
  -- Normalize defensively (some private cores return weird casing)
  if type(class) == "string" then
    -- upper in a Lua 5.0 friendly way:
    class = string.gsub(class, "%a", function(c)
      local b = string.byte(c)
      if b >= 97 and b <= 122 then return string.char(b - 32) end
      return c
    end)
  end
  return class
end

function Synapse.RegisterModule(class, mod)
  if not class or not mod then return end
  Synapse.Modules[class] = mod
  mod.Class = class
  dprint("Registered module for class: " .. class .. (mod.Name and (" (" .. mod.Name .. ")") or ""))
end

function Synapse.Active()
  local c = PlayerClass()
  if not c then return nil end
  -- Try exact, then uppercase key (in case a module registered with a different case)
  local mod = Synapse.Modules[c]
  if not mod and type(c) == "string" then
    mod = Synapse.Modules[string.upper(c)]
  end
  return mod
end

-- Engine-owned Click (overrides provisional one from Synapse.lua)
function Synapse.Click()
  local mod = Synapse.Active()
  if mod and mod.OnClick then
    dprint("Dispatching click to active module.")
    mod:OnClick()
    return
  end
  local cls = PlayerClass() or "UNKNOWN"
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r No active module for this class yet (" .. cls .. ").")
end

-- Adopt pending modules immediately if any were queued before Core loaded
if Synapse.PendingModules then
  for class, mod in pairs(Synapse.PendingModules) do
    Synapse.RegisterModule(class, mod)
  end
  Synapse.PendingModules = nil
  dprint("Adopted pending modules at Engine load.")
end
