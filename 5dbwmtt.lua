local mod_config = SMODS.current_mod.config
local verticalUIrows
if mod_config.debug_messages then
  print("5DBWMTT: Debug Messages Enabled") 
else
  print("5DBWMTT: Debug Messages Disabled")
end
if mod_config.verticalUIrows then
  verticalUIrows = mod_config.verticalUIrows
else
  verticalUIrows = 3
end
assert(SMODS.load_file('utils.lua'))()
assert(SMODS.load_file('consumable.lua'))()

-- TO-DO LIST:
-- stop user from leaving time travel screen on death
-- delete extra hand cardarea when time travelling
-- fix no default unlocks
-- if possible? save at the right time, right after hand is drawn

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

G.FUNCS.create_UIBox_spacetime_map = function()
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

  if not args then args = {} end
  args.cycle_config = {}
  args.cycle_config.current_option = 1
  if G.STAGE == G.STAGES.GAME_OVER then args.no_back = true end
  load_timelines(args)
  
  local t =  create_UIBox_generic_options({ back_func = 'exit_overlay_menu', contents = {
        {n=G.UIT.R, config={align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=all_nodes}, 
        {n=G.UIT.R, config={align = "cm"}, nodes={
          create_option_cycle({options = page_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_timelines_page', current_option = 1, colour = G.C.RED, no_pips = true, focus_args = {snap_to = true, nav = 'wide'}})
        }}
    }}, args)
  return t
end

G.FUNCS.notify_then_time_travel = function(e)
  G.OVERLAY_MENU:remove()
  G.OVERLAY_MENU = nil

  G.E_MANAGER:add_event(Event({
    blockable = false,
    func = (function()
      unlock_notify()
      return true
    end)
  }))

  G.E_MANAGER:add_event(Event({
    blockable = false,
    func = (function()
      if #G.E_MANAGER.queues.unlock <= 0 and not G.OVERLAY_MENU then
        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu{
          definition = G.FUNCS.create_UIBox_spacetime_map()
        }
        if (e.config.id == 'from_game_over' or e.config.id == 'from_game_won') then G.OVERLAY_MENU.config.no_esc =true end
        return true
      end
    end)
  }))
end

function load_timelines(args)
  -- for some reason stop_use() doesn't work
  G.GAME.STOP_USE = 0
  local current_page = args.cycle_config.current_option
  if mod_config.mtt then
    local min_round = 1+5*(current_page-1)
    local max_round = min_round+5-1
    for i = min_round, max_round do
      for j = 1, #G.timeline_archive do
        create_time_point(i, j)
      end
    end
  else
    for index = 1+(current_page-1)*#G.timelines*5, (current_page-1)*(#G.timelines*5)+#G.timelines*5 do
      local j = 1
      while #G.timelines[j].cards >= G.timelines[j].config.card_limit do j = j+1 end
      create_time_point(index, 1)
    end
  end
end

-- create the time point card when given a timeline_archive position
create_time_point = function(i, j)
  local card
  local center
  local classification = time_travel_classify(nil, {round_num=i-1, timeline_num=j})
  if classification == "death" then
    center = G.P_CENTERS['c_5dbwmtt_death']
  elseif classification == "self_travel" then
    center = G.P_CENTERS['c_5dbwmtt_you']
  else
    center = G.P_CENTERS['c_5dbwmtt_round']
  end
  card = Card(G.timelines[j].T.x + G.timelines[j].T.w/2, G.timelines[j].T.y, G.CARD_W, G.CARD_H, nil, center)
  if G.timeline_archive[j][i] == "dummy_time_point" or G.timeline_archive[j][i] == nil then
    card.states.visible = false
  else
    card.ability.extra.round_num = i-1
    card.ability.extra.timeline_num = j
  end
  G.timelines[j]:emplace(card)
end