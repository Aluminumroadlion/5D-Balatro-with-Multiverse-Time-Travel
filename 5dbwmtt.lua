SMODS.Atlas{key = 'Jokers', path = 'Jokers.png', px = 71, py = 95 }

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
        text={
          "A snapshot of",
          "a {C:attention}Timeline #2#{}"
        }
    },
    loc_vars = function(self, info_queue, card)
      return { vars = {
        card.ability.extra.round_num,
        card.ability.extra.timeline_num
      }}
    end,
    config = {
      consumable = true,
      extra = {
        round_num = 1,
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
      return true
    end,
    keep_on_use = function(self, card)
      return true
    end,
    use = function(self, card, area, copier)
      G.FUNCS.start_run(e, {
        savetext = G.timeline_archive[card.ability.extra.timeline_num][card.ability.extra.round_num],
        timeline_tracker = G.timeline_tracker,
        timeline_archive = G.timeline_archive
      })
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
  for j = 1, #G.timeline_archive do
    G.timelines[j] = CardArea(
      G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
      5*G.CARD_W,
      0.95*G.CARD_H, 
      {card_limit = 5, type = 'consumeable', highlight_limit = 1, collection = false})
    table.insert(all_nodes, 
    {n=G.UIT.R, config={align = "cm", padding = 0.07, no_fill = true}, nodes={
      {n=G.UIT.O, config={object = G.timelines[j]}}
    }}
    )
  end

  local maxlength = 0
  for j = 1, #G.timeline_archive do
    if #G.timeline_archive[j] > maxlength then
      maxlength = #G.timeline_archive[j]
    end
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
    for j = 1, 3 do
      table.insert(G.timeline_archive, {})
    end
  end
  start_run_ref(self, args)
end

local new_round_ref = new_round
function new_round()
  new_round_ref(self)
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
end

function load_timelines(args)
  local current_page = args.cycle_config.current_option
  local min_round = 1+5*(current_page-1)
  local max_round = min_round+5-1
  
  for i = min_round, max_round do
    for j = 1, #G.timeline_archive do
      if G.timeline_archive[j][i] ~= nil then
        local card = Card(G.timelines[j].T.x + G.timelines[j].T.w/2, G.timelines[j].T.y, G.CARD_W, G.CARD_H, nil, G.P_CENTERS['c_5dbwmtt_round'])
        card.ability.extra.round_num = i
        card.ability.extra.timeline_num = j
        G.timelines[j]:emplace(card)
      end
    end
  end
end