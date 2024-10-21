require "/scripts/cfutil.lua"

function init()
  self.questList = "scrollAreaQuests.listQuests"
  self.stagesList = "scrollAreaStages.listStages"

  self.categories = root.assetJson("/interface/scripted/cequestlog/categories.config")

  clear()
  populateQuests()
end

function clear()
  widget.setVisible("acceptButton", false)
  widget.setVisible("acceptButtonDisabled", false)
  widget.setVisible("trackButton", false)
  widget.setVisible("trackButtonDisabled", true)
  widget.setVisible("abandonButton", false)
  widget.setVisible("abandonButtonDisabled", true)
end

function populateQuests()
  local playerQuests = player.questIds()
  local completed = widget.getSelectedData("questTabs") == "completed"

  local addDivider = function(path)
    path = util.absolutePath("/interface/scripted/cequestlog/", path)
    local divider = widget.addListItem(self.questList)

    widget.removeChild(string.format("%s.%s", self.questList, divider), "background")
    widget.removeChild(string.format("%s.%s", self.questList, divider), "indicator")
    widget.removeChild(string.format("%s.%s", self.questList, divider), "name")

    widget.setImage(string.format("%s.%s.divider", self.questList, divider), path)
  end
  local addQuest = function(id)
    local acceptedQuest = player.hasAcceptedQuest(id)
    local canStartQuest = player.canStartQuest(id)

    local content = player.acceptedQuest and player.quest(id).content or root.questConfig(id)
    local item = widget.addListItem(self.questList)

    widget.removeChild(string.format("%s.%s", self.questList, item), "divider")

    widget.setText(string.format("%s.%s.name", self.questList, item), content.title)
    widget.setData(string.format("%s.%s", self.questList, item), id)

    local indicator = "/assetmissing.png"
    if not acceptedQuest then
      if canStartQuest then
        indicator = "/interface/scripted/cequestlog/questIndicators.png:accept"
      else
        indicator = "/interface/scripted/cequestlog/questIndicators.png:locked"
      end
    elseif player.trackedQuestId() == id then
      indicator = "/interface/scripted/cequestlog/questIndicators.png:active"
    elseif player.canTurnInQuest(id) then
      indicator = "/interface/scripted/cequestlog/questIndicators.png:turnin"
    end

    widget.setImage(string.format("%s.%s.indicator", self.questList, item), indicator)
  end

  widget.clearListItems(self.questList)

  -- Populate categorized quests
  for _, category in pairs(self.categories) do
    local divider = false

    for _, quest in pairs(category.quests) do
      if (quest.alwaysShow or contains(playerQuests, quest.id)) and player.hasCompletedQuest(quest.id) == completed then
        if not divider then
          divider = true
          addDivider(category.divider)
        end

        addQuest(quest.id)
      end

      for i, questId in pairs(playerQuests) do
        if questId == quest.id then table.remove(playerQuests, i) break end
      end
    end
  end

  -- Populate uncategorized quests
  addDivider("/interface/scripted/cequestlog/dividers/other.png")
  for _, questId in pairs(playerQuests) do
    if player.hasCompletedQuest(questId) == completed then
      addQuest(questId)
    end
  end
end

function selectQuest()
  local id = widget.getData(string.format("%s.%s", self.questList, widget.getListSelected(self.questList)))
  if not id then clear() return end -- Nu dividers

  local acceptedQuest = player.hasAcceptedQuest(id)
  local canStartQuest = player.canStartQuest(id)
  local completedQuest = player.hasCompletedQuest(id)

  local content = player.acceptedQuest and player.quest(id).content or root.questConfig(id)
  if content.canBeAbandoned == nil then content.canBeAbandoned = true end
  -- cfutil.deepPrintTable(content)

  widget.setVisible("acceptButton", not acceptedQuest and canStartQuest)
  widget.setVisible("acceptButtonDisabled", not acceptedQuest and not canStartQuest)
  widget.setVisible("trackButton", acceptedQuest and not completedQuest)
  widget.setVisible("trackButtonDisabled", not acceptedQuest or completedQuest)
  widget.setVisible("abandonButton", acceptedQuest and not completedQuest and content.canBeAbandoned)
  widget.setVisible("abandonButtonDisabled", not acceptedQuest or completedQuest or not content.canBeAbandoned)

  widget.setText("trackButton", player.trackedQuestId() == id and "Stop Tracking" or "Track Quest")
end

function acceptQuest()
  local id = widget.getData(string.format("%s.%s", self.questList, widget.getListSelected(self.questList)))
  if not id then clear() return end -- Nu dividers

  player.startQuest(id)
  pane.dismiss()
end

function abandonQuest()
  local id = widget.getData(string.format("%s.%s", self.questList, widget.getListSelected(self.questList)))
  if not id then clear() return end -- Nu dividers

  player.callQuest(id, "quest.fail")
  clear()
  populateQuests()
end

function toggleTracking()
  local id = widget.getData(string.format("%s.%s", self.questList, widget.getListSelected(self.questList)))
  if not id then clear() return end -- Nu dividers

  if player.trackedQuestId() == id then
    player.setTrackedQuest()

    widget.setText("trackButton", "Track Quest")
    populateQuests()
  else
    player.setTrackedQuest(id)

    widget.setText("trackButton", "Stop Tracking")
    populateQuests()
  end
end