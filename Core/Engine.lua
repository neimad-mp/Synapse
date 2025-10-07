Synapse.Engine = Synapse.Engine or {}

-- Module registry
local modules = {}   -- key = class, value = module table

function Synapse.RegisterModule(class, mod)
  modules[class] = mod
end

-- Dispatch: get active module
function Synapse.Active()
  return modules[ Synapse.PlayerClass() ]
end

-- Single entrypoint you’ll bind to a key
function Synapse.Click()
  local mod = Synapse.Active()
  if mod and mod.OnClick then
    mod:OnClick()
  else
    Synapse.Print("No module loaded for this class yet.")
  end
end
