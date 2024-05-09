local Tracking = {}

---Track cmd
---@param cmd Command
Tracking.track = function(cmd)
  -- track things here
  print("tracking", cmd.lhs)
end

return Tracking
