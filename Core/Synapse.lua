local _, class = UnitClass("player")
if class == "ROGUE" then
  Synapse_LoadModule("Rogue")
elseif class == "MAGE" then
  Synapse_LoadModule("Mage")
end
