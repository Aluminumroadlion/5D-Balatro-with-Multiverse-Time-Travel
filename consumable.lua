SMODS.Atlas{key = 'Jokers', path = 'Jokers.png', px = 71, py = 95 }
local mod_config = SMODS.current_mod.config
local round_text
if mod_config.mtt then 
  round_text={
    "A snapshot of",
    "{C:attention}Timeline #2#{}"
  }
else
  round_text={
    "A snapshot of",
    "the {C:attention}Timeline{}"
  }
end

-- use function: time travels player to the time point corresponding to the values of the input card
use_function = function(self, card, area, copier)
  if mod_config.mtt then
    local classification = time_travel_classify(card)
    if classification == "terminal_travel" then
      local savetext = G.timeline_archive[card.ability.extra.timeline_num][card.ability.extra.round_num+1]
      if mod_config.debug_messages then print("5DBWMTT: Travelling to "..card.ability.extra.timeline_num.." "..(card.ability.extra.round_num+1).."...") end
      G.FUNCS.start_run(e, {
      savetext = savetext,
      timeline_tracker = card.ability.extra.timeline_num,
      timeline_archive = G.timeline_archive,
      run_from_timeline = true
      })
    elseif classification == "multiverse_time_travel" then
      local new_timeline_tracker = find_unoccupied_timeline()
      if mod_config.debug_messages then print("5DBWMTT: Creating timeline at "..new_timeline_tracker.." "..(card.ability.extra.round_num+1).."...") end
      for i=1,(card.ability.extra.round_num+1) do
        if G.timeline_archive[new_timeline_tracker][i] == nil then
          G.timeline_archive[new_timeline_tracker][i] = "dummy_time_point"
        end
      end
      if mod_config.debug_messages then print("5DBWMTT: Copying time point at "..card.ability.extra.timeline_num.." "..(card.ability.extra.round_num+1).."...") end
      G.timeline_archive[new_timeline_tracker][card.ability.extra.round_num+1] = copy_table(G.timeline_archive[card.ability.extra.timeline_num][card.ability.extra.round_num+1])
      G.FUNCS.start_run(e, {
          savetext = G.timeline_archive[new_timeline_tracker][card.ability.extra.round_num+1],
          timeline_tracker = new_timeline_tracker,
          timeline_archive = G.timeline_archive,
          run_from_timeline = true
      })
    elseif mod_config.debug_messages then print("5DBWMTT Error: Unknown travel type")
    end
  else
    local savetext = G.timeline_archive[card.ability.extra.timeline_num][card.ability.extra.round_num+1]
    for index = card.ability.extra.round_num+1, #G.timeline_archive[card.ability.extra.timeline_num] do
        G.timeline_archive[card.ability.extra.timeline_num][index] = nil
    end
    G.FUNCS.start_run(e, {
        savetext = savetext,
        timeline_tracker = G.timeline_tracker,
        timeline_archive = G.timeline_archive,
        run_from_timeline = true
    })
  end
end

can_use_function = function(self, card)
  local classification = time_travel_classify(card)
  if mod_config.mtt then 
    if classification == "self_travel" then return false end
    if classification == "terminal_travel" then return true end
    if classification == "multiverse_time_travel" and find_unoccupied_timeline() then return true end
  else 
    return true 
  end
end

SMODS.ConsumableType{
    key = 'time_point',
    primary_colour = HEX("b1b1b1"),
    secondary_colour = G.C.BLACK,
    loc_txt = {
 		name = 'Time Point',
 		collection = 'Time Points',
 	},
    collection_rows = {1},
}
SMODS.Consumable{
    key = 'round',
    set = 'time_point',
    loc_txt = {
        name = "Round #1#",
        text=round_text
    },
    loc_vars = function(self, info_queue, card)
      return { vars = {
        card.ability.extra.round_num,
        card.ability.extra.timeline_num,
      }}
    end,
    config = {
      consumable = true,
      extra = {
        round_num = 0,
        timeline_num = 1
      }
    },
    no_collection = false,
    atlas = 'Jokers',
    pos = {x=2, y=13},
    unlocked = true,
    check_for_unlock = function(self, args)
      return true
    end,
    can_use = function(self, card)
      return can_use_function(self, card)
    end,
    keep_on_use = function(self, card)
      return true
    end,
    use = function(self, card, area, copier)
      return use_function(self, card, area, copier)
    end,
    set_sprites = function(self, card, front)
      card.children.center.scale.y = card.children.center.scale.y/1.2
    end,
    set_ability = function(self, card, initial, delay_sprites)
      local H = card.T.h
      local W = card.T.w
      H = H/1.2
      card.T.h = H
    end,
    load = function(self, card, card_table, other_card)
      local H = G.CARD_H
      local W = G.CARD_W
      card.T.h = H*scale/1.2*scale
      card.T.w = W*scale
    end,
}
SMODS.Consumable{
    key = 'you',
    set = 'time_point',
    loc_txt = {
        name = "You",
        text={"#3#"}
    },
    loc_vars = function(self, info_queue, card)
      return { vars = {
        card.ability.extra.round_num,
        card.ability.extra.timeline_num,
        card.ability.extra.text
      }}
    end,
    config = {
      consumable = true,
      extra = {
        round_num = 0,
        timeline_num = 1,
        text = "A humble Joker",
      }
    },
    no_collection = false,
    atlas = 'Jokers',
    pos = {x=0, y=0},
    unlocked = true,
    check_for_unlock = function(self, args)
      return true
    end,
    can_use = function(self, card)
        return false
    end,
    keep_on_use = function(self, card)
      return true
    end,
    use = function(self, card, area, copier)
        return true
    end,
    set_card_type_badge = function(self, card, badges)
      badges[#badges+1] = create_badge("Joker", G.C.RED, G.C.WHITE, 1)
    end,
    set_sprites = function(self, card, front)
      card.children.center.scale.y = card.children.center.scale.y/1.2
    end,
    set_ability = function(self, card, initial, delay_sprites)
      local H = card.T.h
      local W = card.T.w
      H = H/1.2
      card.T.h = H
    end,
    load = function(self, card, card_table, other_card)
      local H = G.CARD_H
      local W = G.CARD_W
      card.T.h = H*scale/1.2*scale
      card.T.w = W*scale
    end,
}
SMODS.Consumable{
    key = 'death',
    set = 'time_point',
    loc_txt = {
        name = "Round #1#",
        text={
          "On {C:attention}Round #1#{},",
          "you died",
        }
    },
    loc_vars = function(self, info_queue, card)
      return { vars = {
        card.ability.extra.round_num,
        card.ability.extra.timeline_num,
      }}
    end,
    config = {
      consumable = true,
      extra = {
        round_num = 0,
        timeline_num = 1,
      }
    },
    no_collection = false,
    atlas = 'Jokers',
    pos = {x=3, y=4},
    unlocked = true,
    check_for_unlock = function(self, args)
      return true
    end,
    can_use = function(self, card)
      return can_use_function(self, card)
    end,
    keep_on_use = function(self, card)
      return true
    end,
    use = function(self, card, area, copier)
      return use_function(self, card, area, copier)
    end,
    set_sprites = function(self, card, front)
      card.children.center.scale.y = card.children.center.scale.y/1.2
    end,
    set_ability = function(self, card, initial, delay_sprites)
      local H = card.T.h
      local W = card.T.w
      H = H/1.2
      card.T.h = H
    end,
    load = function(self, card, card_table, other_card)
      local H = G.CARD_H
      local W = G.CARD_W
      card.T.h = H*scale/1.2*scale
      card.T.w = W*scale
    end,
}