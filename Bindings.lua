-- Bindings.lua — load BEFORE Bindings.xml
-- Defines header + friendly label for the keybinding.

-- Header text shown in the Key Bindings menu
BINDING_HEADER_SYNAPSE    = "Synapse"

-- Display name for the specific binding (matches name="SYNAPSE_CAST")
BINDING_NAME_SYNAPSE_CAST = "Synapse Cast (Click Active Module)"

-- Optional wrapper (only used if you call it from XML)
function Synapse_Binding_Click()
  if Synapse and Synapse.Click then
    Synapse.Click()
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffaa[Synapse]|r Not ready yet.")
  end
end
