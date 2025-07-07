local mod_config = SMODS.current_mod.config
local max_timelines
local verticalUIrows
if mod_config.verticalUIrows and mod_config.verticalUIrows > 0 then
  verticalUIrows = mod_config.verticalUIrows
  if mod_config.mtt then 
    max_timelines = mod_config.verticalUIrows
  end
else
  verticalUIrows = 3
end
if not mod_config.mtt then 
  max_timelines = 1
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
    G.culled_table = recursive_table_cull({
        cardAreas = cardAreas,
        tags = tags,
        GAME = G.GAME,
        STATE = G.STATE,
        ACTION = G.action or nil,
        BLIND = G.GAME.blind:save(),
        BACK = G.GAME.selected_back:save(),
        VERSION = G.VERSION
    })
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

time_travel_classify = function(card, args)
  local timeline_num
  local round_num
  local classification
  if card and card.ability then
    timeline_num = card.ability.extra.timeline_num
    round_num = card.ability.extra.round_num+1
  elseif args then
    if args.timeline_num then timeline_num = args.timeline_num end
    if args.round_num then round_num = args.round_num+1 end
  else
    timeline_num = G.timeline_tracker
    round_num = G.GAME.round
  end
  if (#G.timeline_archive[timeline_num]==round_num) then
    if G.timeline_archive[timeline_num][round_num].STATE == G.STATES.GAME_OVER then
      return "death"
    end
    if (G.timeline_tracker == timeline_num) then
      return "self_travel"
    else
      return "terminal_travel"
    end
  end
  if find_unoccupied_timeline() then return "multiverse_time_travel" end
end

find_unoccupied_timeline = function()
  local next_timeline = nil
  for j=1,#G.timeline_archive do
    if #G.timeline_archive[j] == 0 then 
      next_timeline = j
      break
    end
  end
  return next_timeline
end

function can_time_travel()
  for j = 1, #G.timeline_archive do
    for i = 1,#G.timeline_archive[j] do
      local classification = time_travel_classify(nil, {round_num=i-1, timeline_num=j})
      if classification == "terminal_travel" or classification == "multiverse_time_travel" then
        return true
      else
        if mod_config.debug_messages then print(j.." "..i.." is "..(classification or "nil")) end
      end
    end
  end
  return false
end

function tableContains(table, value)
  if table and #table then
    for i = 1,#table do
      if (table[i] == value) then
        return true
      end
    end
  end
  return false
end

-- hooks
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
  if not args.run_from_timeline then save_timeline_to_archive({forced_save = true}) end
end

local ease_round_ref = ease_round
function ease_round(mod)
  ease_round_ref(mod)
  save_timeline_to_archive()
end

local update_game_over_ref = Game.update_game_over
function Game:update_game_over(dt)
  if not G.STATE_COMPLETE then
    G.timeline_archive[G.timeline_tracker][#G.timeline_archive[G.timeline_tracker]] = nil
    save_timeline_to_archive({forced_save = true})
  end
  return update_game_over_ref(self, dt)
end

-- local create_UIBox_game_over_ref = create_UIBox_game_over
-- function create_UIBox_game_over()
--   local t = create_UIBox_game_over_ref()
--   if true then
--     local node = nodeCrawler_UIBox_game_over(t)
--     local time_travel_button = {n=G.UIT.R, config={align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = G.C.GREEN, button = "notify_then_time_travel", shadow = true, focus_args = {nav = 'wide'}}, nodes={
--       {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true, maxw = 4.8}, nodes={
--         {n=G.UIT.T, config={text = "Time Travel", scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}
--       }}
--     }}
--     table.insert(node.nodes, 1, time_travel_button)
--   end
--   return t
-- end

-- function nodeCrawler_UIBox_game_over(t)
--   if t and t.nodes then
--     -- check if button found
--     if t.nodes[1].config and t.nodes[1].config.id then
--       if t.nodes[1].config.id == 'from_game_over' then
--         return t
--       end
--     end
--     -- if not, keep crawling
--     for _,v in pairs(t.nodes) do
--       local crawl = nodeCrawler_UIBox_game_over(v)

--       return 
--     end
--   end
--   return nil
-- end