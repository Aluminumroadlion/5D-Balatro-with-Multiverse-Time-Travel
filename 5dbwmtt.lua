SMODS.Atlas{key = 'Jokers', path = 'Jokers.png', px = 71, py = 95 }
local mod_config = SMODS.current_mod.config
local verticalUIrows = 3
local max_timelines = nil
local round_text
if mod_config.mtt then 
  max_timelines = 3
  round_text={
    "A snapshot of",
    "{C:attention}Timeline #2#{}"
  }
else
  max_timelines = 1
  round_text={
    "A snapshot of",
    "the {C:attention}Timeline{}"
  }
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
      local classification = time_travel_classify(card)
      if mod_config.mtt then 
        if classification == "self_travel" then return false end
        if classification == "terminal_travel" then return true end
        if classification == "multiverse_time_travel" and find_unoccupied_timeline then return true end
      else 
        return true 
      end
      return false
    end,
    keep_on_use = function(self, card)
      return true
    end,
    use = function(self, card, area, copier)
      if mod_config.mtt then
        if #G.timeline_archive[G.timeline_tracker] < G.GAME.round then 
           
        end
        local classification = time_travel_classify(card)
        if classification == "terminal_travel" then
          local savetext = G.timeline_archive[card.ability.extra.timeline_num][card.ability.extra.round_num+1]
          if mod_config.debug_messages then
            print("5DBWMTT: Travelling to "..card.ability.extra.timeline_num.." "..(card.ability.extra.round_num+1).."...")
          end
          G.FUNCS.start_run(e, {
            savetext = savetext,
            timeline_tracker = card.ability.extra.timeline_num,
            timeline_archive = G.timeline_archive,
            run_from_timeline = true
          })
        else
          if classification == "multiverse_time_travel" then
            local new_timeline_tracker = find_unoccupied_timeline()
            for i=1,(card.ability.extra.round_num+1)-1 do
              if G.timeline_archive[new_timeline_tracker][i] == nil then
                G.timeline_archive[new_timeline_tracker][i] = "dummy_time_point"
              end
            end
            G.timeline_archive[new_timeline_tracker][card.ability.extra.round_num+1] = G.timeline_archive[card.ability.extra.timeline_num][card.ability.extra.round_num+1]
            G.timeline_tracker = new_timeline_tracker
            if mod_config.debug_messages then
              print("5DBWMTT: Travelling to "..new_timeline_tracker.." "..(card.ability.extra.round_num+1).."...")
            end
            G.FUNCS.start_run(e, {
              savetext = G.timeline_archive[new_timeline_tracker][card.ability.extra.round_num+1],
              timeline_tracker = new_timeline_tracker,
              timeline_archive = G.timeline_archive,
              run_from_timeline = true
            })
          else
            if mod_config.debug_messages then
              print("5DBWMTT Error: Unknown travel type")
            end
          end
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

time_travel_classify = function(card)
  local classification = nil
  if (#G.timeline_archive[card.ability.extra.timeline_num]==card.ability.extra.round_num+1) then
    if (G.timeline_tracker == card.ability.extra.timeline_num) then
      classification = "self_travel"
    else
      classification = "terminal_travel"
    end
  end
  if not classification and find_unoccupied_timeline() then classification = "multiverse_time_travel" end
  return classification
end

find_unoccupied_timeline = function()
  local next_timeline = nil
  for j=1,#G.timeline_archive do
    if #G.timeline_archive[j] == 0 then 
      if mod_config.debug_messages then 
        print("5DBWMTT: New timeline found at "..j)
      end
      next_timeline = j
      break
    end
  end
  return next_timeline
end

G.FUNCS.your_timelines_page = function(args)
  if not args or not args.cycle_config then return end
  for j = 1, #G.timelines do
    for i = #G.timelines[j].cards,1, -1 do
      local c = G.timelines[j]:remove_card(G.timelines[j].cards[i])
      c:remove()
      c = nil
    end
  end

  load_timelines(args)
end

function create_UIBox_spacetime_map()
  local all_nodes = {}

  G.timelines = {}
  for j = 1, verticalUIrows do
    G.timelines[j] = CardArea(
      G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
      5*G.CARD_W,
      0.95*G.CARD_H, 
      {card_limit = 5, type = 'consumeable', highlight_limit = 1, collection = false}
    )
    table.insert(all_nodes, 
    {n=G.UIT.R, config={align = "cm", padding = 0.07, no_fill = true}, nodes={
      {n=G.UIT.O, config={object = G.timelines[j]}}
    }}
    )
  end

  local maxlength = 0
  if mod_config.mtt then 
    for j = 1, #G.timeline_archive do
      if #G.timeline_archive[j] > maxlength then
        maxlength = #G.timeline_archive[j]
      end
    end
  else
    maxlength = #G.timeline_archive[1]/#G.timelines
  end
  local page_options = {}
  for i = 1, math.ceil(maxlength/5) do
    table.insert(page_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(maxlength/5)))
  end

  args = {cycle_config = {current_option = 1}}
  load_timelines(args)
  
  local t =  create_UIBox_generic_options({ back_func = 'exit_overlay_menu', contents = {
        {n=G.UIT.R, config={align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=all_nodes}, 
        {n=G.UIT.R, config={align = "cm"}, nodes={
          create_option_cycle({options = page_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_timelines_page', current_option = 1, colour = G.C.RED, no_pips = true, focus_args = {snap_to = true, nav = 'wide'}})
        }}
    }})
  return t
end

local start_run_ref = Game.start_run
function Game:start_run(args)
  G.timeline_tracker = args.timeline_tracker or 1
  G.timeline_archive = args.timeline_archive or nil
  if not G.timeline_archive then 
    G.timeline_archive = {}
    for j = 1, max_timelines do
      table.insert(G.timeline_archive, {})
    end
  end
  start_run_ref(self, args)
  if not args.run_from_timeline then save_timeline_to_archive({["forced_save"] = true}) end
end

local ease_round_ref = ease_round
function ease_round(mod)
  ease_round_ref(mod)
  save_timeline_to_archive()
end

function save_timeline_to_archive(args)
  if not args then args = {} end
  if #G.timeline_archive[G.timeline_tracker] <= G.GAME.round+1 or args.forced_save then
    local cardAreas = {}
    for k, v in pairs(G) do
      if (type(v) == "table") and v.is and v:is(CardArea) then 
        local cardAreaSer = v:save()
        if cardAreaSer then cardAreas[k] = cardAreaSer end
      end
    end

    local tags = {}
    for k, v in ipairs(G.GAME.tags) do
      if (type(v) == "table") and v.is and v:is(Tag) then 
        local tagSer = v:save()
        if tagSer then tags[k] = tagSer end
      end
    end

    args = {}
    args.return_table = true
    G.culled_table = save_run(args)
    table.insert(G.timeline_archive[G.timeline_tracker], G.culled_table)
    if mod_config.debug_messages then
      print("5DBWMTT: Saved at "..G.timeline_tracker.." "..#G.timeline_archive[G.timeline_tracker])
    end
  else
    if mod_config.debug_messages then
      print("5DBWMTT: Save FAILED at "..G.timeline_tracker.." "..#G.timeline_archive[G.timeline_tracker])
    end
  end
end

function load_timelines(args)
  local current_page = args.cycle_config.current_option
  if mod_config.mtt then
    local min_round = 1+5*(current_page-1)
    local max_round = min_round+5-1
    for i = min_round, max_round do
      for j = 1, #G.timeline_archive do
        local card = Card(G.timelines[j].T.x + G.timelines[j].T.w/2, G.timelines[j].T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS['c_5dbwmtt_round'])
        card.ability.extra.round_num = i-1
        card.ability.extra.timeline_num = j
        if G.timeline_archive[j][i] == "dummy_time_point" or G.timeline_archive[j][i] == nil then
          card.states.visible = false
        end
        G.timelines[j]:emplace(card)
      end
    end
  else
    for index = 1+(current_page-1)*#G.timelines*5, (current_page-1)*(#G.timelines*5)+#G.timelines*5 do
      local j = 1
      while #G.timelines[j].cards >= G.timelines[j].config.card_limit do j = j+1 end
      local card = Card(G.timelines[j].T.x + G.timelines[j].T.w/2, G.timelines[j].T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS['c_5dbwmtt_round'])
      card.ability.extra.round_num = index-1
      card.ability.extra.timeline_num = 1
      if G.timeline_archive[1][index] == "dummy_time_point" or G.timeline_archive[1][index] == nil then
        card.states.visible = false
      end
      G.timelines[j]:emplace(card)
    end
  end
end