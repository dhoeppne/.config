-- Hammerspoon config
-- Reload config automatically when this file changes
local configWatcher = hs.pathwatcher.new(hs.configdir, function(files)
  local doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end):start()

hs.notify.show("Hammerspoon", "", "Config loaded")

-- Load work-only modules (IGNORE_ prefix is not committed to the config repo)
pcall(require, "IGNORE_slack")
