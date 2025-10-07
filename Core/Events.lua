local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    local mod = Synapse.Active()
    if mod and mod.OnLogin then mod:OnLogin() end
    Synapse.Print("v0.1 loaded – module: "..(Synapse.PlayerClass() or "Unknown"))
  end
end)
