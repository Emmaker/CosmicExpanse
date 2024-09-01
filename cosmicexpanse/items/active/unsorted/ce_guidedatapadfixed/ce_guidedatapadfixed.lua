require "/scripts/util.lua"

function init()
  self.upgrades = config.getParameter("upgrades")
  self.swingTime = config.getParameter("swingTime")
  activeItem.setArmAngle(-math.pi / 2)
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  if not self.swingTimer and fireMode == "primary" and player then
    self.swingTimer = self.swingTime
  end

  if self.swingTimer then
    self.swingTimer = math.max(0, self.swingTimer - dt)

    activeItem.setArmAngle((-math.pi / 2) * (self.swingTimer / self.swingTime))

    if self.swingTimer == 0 then
      unlockGuides()
    end
  end
end

function unlockGuides()
  for _, codex in pairs(config.getParameter("codices")) do
    world.sendEntityMessage(player.id(), "cf_learncodex", codex)
  end

  interface.queueMessage("Guides added to Lexicon!", 4, 0.5)

  item.consume(1)
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.aimDirection)
end