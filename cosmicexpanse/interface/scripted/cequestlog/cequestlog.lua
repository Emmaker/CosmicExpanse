require "/scripts/cfutil.lua"

function init()
  self.questList = "scrollAreaQuests.listQuests"
  self.stagesList = "scrollAreaStages.listStages"

  self.categories = root.assetJson("/interface/scripted/cequestlog/categories.config")

  widget.setVisible("trackButton", false)
  widget.setVisible("trackButtonDisabled", true)
  widget.setVisible("abandonButton", false)
  widget.setVisible("abandonButtonDisabled", true)

  populateQuests()
end

function populateQuests()
  local playerQuests = player.questIds()
  local completed = widget.getSelectedData("questTabs") == "completed"

  widget.clearListItems(self.questList)

  -- Populate categorized quests
  for _, category in pairs(self.categories) do
    local divider = false

    for _, quest in pairs(category.quests) do
      if (quest.alwaysShow or contains(playerQuests, quest.id)) and player.hasCompletedQuest(quest.id) == completed then
        if not divider then
          divider = widget.addListItem(self.questList)
          local path = util.absolutePath("/interface/scripted/cequestlog/", category.divider)

          widget.removeChild(string.format("%s.%s", self.questList, divider), "background")
          widget.removeChild(string.format("%s.%s", self.questList, divider), "name")

          widget.setImage(string.format("%s.%s.divider", self.questList, divider), path)
        end

        local content = player.quest(quest.id).content
        local item = widget.addListItem(self.questList)

        widget.setText(string.format("%s.%s.name", self.questList, item), content.title)
        widget.setData(string.format("%s.%s", self.questList, item), quest.id)
      end

      for i, questId in pairs(playerQuests) do
        if questId == quest.id then table.remove(playerQuests, i) break end
      end
    end
  end

  -- Populate uncategorized quests
  divider = widget.addListItem(self.questList)

  widget.removeChild(string.format("%s.%s", self.questList, divider), "background")
  widget.removeChild(string.format("%s.%s", self.questList, divider), "name")

  widget.setImage(string.format("%s.%s.divider", self.questList, divider), "/interface/scripted/cequestlog/dividers/other.png")

  for _, questId in pairs(playerQuests) do
    if player.hasCompletedQuest(questId) == completed then
      local content = player.quest(questId).content
      local item = widget.addListItem(self.questList)

      widget.setText(string.format("%s.%s.name", self.questList, item), content.title)
      widget.setData(string.format("%s.%s", self.questList, item), questId)
    end
  end
end