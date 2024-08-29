require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"

function init()
  storage.complete = storage.complete or false
  self.compassUpdate = config.getParameter("compassUpdate", 0.5)
  self.descriptions = config.getParameter("descriptions")

  self.inventorsItem = config.getParameter("inventorsItem")

  self.furnaceItem = config.getParameter("furnaceItem")

  self.barItem = config.getParameter("barItem")
  self.barCount = config.getParameter("barCount")

  self.miningItem = config.getParameter("miningItem")

  self.tutorialUid = config.getParameter("tutorialUid")

  setPortraits()

  storage.stage = storage.stage or 1
  self.stages = {
    craftInventors,
    craftFurnace,
    smeltBar,
    craftMining,
    returnTutorial
  }

  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])
end

function questInteract(entityId)
  if self.onInteract then
    return self.onInteract(entityId)
  end
end

function update(dt)
  self.state:update(dt)

  if storage.complete then
    quest.setCanTurnIn(true)
  end
end

function craftInventors()
  quest.setProgress(nil)
  quest.setCompassDirection(nil)

  while storage.stage == 1 do
    quest.setObjectiveList({{self.descriptions.craftInventors, false}})
    if player.hasItem({self.inventorsItem}) then
      storage.stage = 2
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function craftFurnace()
  quest.setProgress(nil)
  quest.setCompassDirection(nil)

  while storage.stage == 2 do
    quest.setObjectiveList({{self.descriptions.craftFurnace, false}})

    if player.hasItem(self.furnaceItem) then
      storage.stage = 3
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function smeltBar()
  quest.setCompassDirection(nil)

  while storage.stage == 3 do
    quest.setObjectiveList({{self.descriptions.smeltBar, false}})
    quest.setProgress(player.hasCountOfItem(self.barItem) / self.barCount)
    if player.hasItem({name = self.barItem, count = self.barCount}) then
      storage.stage = 4
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function craftMining()
  quest.setProgress(nil)
  quest.setCompassDirection(nil)

  while storage.stage == 4 do
    quest.setObjectiveList({{self.descriptions.craftMining, false}})

    if player.hasItem(self.miningItem) then
      storage.stage = 5
    elseif not player.hasItem({name = self.barItem, count = self.barCount}) then
      storage.stage = 3
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function returnTutorial(dt)
  quest.setCompassDirection(nil)
    quest.setParameter("tutorial", {type = "entity", uniqueId = self.tutorialUid})
    quest.setIndicators({"tutorial"})
    quest.setObjectiveList({{self.descriptions.returnTutorial, false}})

    local trackTutorial = util.uniqueEntityTracker(self.tutorialUid, self.compassUpdate)
    while true do
      if not storage.complete then
        local tutorialResult = trackTutorial()
        questutil.pointCompassAt(tutorialResult)
        if tutorialResult then
          storage.complete = true
        end
      else
        quest.setCanTurnIn(true)
        quest.setIndicators({})
      end
      coroutine.yield()
    end
    self.state:set(self.stages[storage.stage])
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end