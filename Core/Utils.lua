Synapse = Synapse or {}
SynapseDB = SynapseDB or { settings = {}, }

function Synapse.Print(msg, r,g,b)
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r "..tostring(msg), r or 1, g or 1, b or 1)
end

-- Vanilla-friendly string helpers
function Synapse.sfind(s, pat) return string.find(s, pat) end
function Synapse.now() return GetTime() end

-- Class/Spec detection
function Synapse.PlayerClass()
  local _, class = UnitClass("player")
  return class
end
