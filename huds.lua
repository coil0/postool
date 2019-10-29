local HUD_POSITION = { x = postool.hudPosX, y = postool.hudPosY }
local HUD_ALIGNMENT = { x = 1, y = 0 }
local HUD_SCALE = { x = 100, y = 100 }

-- hud id map (playername -> { playername = { tIDs = { hud-ids }, tb = { toggles }, ... )
postool.tHudDB = {}


-- 'hide' an element
local function clearHud(oPlayer, iID)

	oPlayer:hud_change(iID, 'text', '')

end -- clearHud


-- position element vertically
local function setHudYoffset(oPlayer, iID, iY)

	oPlayer:hud_change(iID, 'offset', { x = 0, y = iY })

end -- setHudYoffset


-- toggle between left and right side of screen
postool.toggleHudPosition = function(oPlayer)

	local sName = oPlayer:get_player_name()

	local tDB = postool.tHudDB[sName]

	if not tDB then
		-- should never happen
		print('[postool]huds:toggleHudPosition: DB corruption!')
		return
	end

	-- get current definition
	local tDef = oPlayer:hud_get(tDB.tIDs.time)

	-- make new position
	local tPosNew = {
		x = 1 - tDef.position.x,
		y = tDef.position.y
	}

	-- apply new position
	for _, iID in pairs(tDB.tIDs) do

		oPlayer:hud_change(iID, 'position', tPosNew)

	end

end -- toggleHudPosition


-- recalculate y offset and clear if needed
postool.rebuildHud = function(oPlayer)

	local sName = oPlayer:get_player_name()

	local tDB = postool.tHudDB[sName]

	if not tDB then
		-- should never happen
		print('[postool]huds:rebuildHud: DB corruption!')
		return
	end

	local iY = 0
	local iDiff = -18
	local bOff = not tDB.bMain

	local iID = tDB.tIDs.block
	if tDB.tb[4] then

		iY = iY + iDiff

		if bOff then clearHud(oPlayer, iID) end

	else

		clearHud(oPlayer, iID)

	end -- block

	iID = tDB.tIDs.node
	if tDB.tb[3] then

		setHudYoffset(oPlayer, iID, iY)

		iY = iY + iDiff

		if bOff then clearHud(oPlayer, iID) end

	else

		clearHud(oPlayer, iID)

	end -- node

	iID = tDB.tIDs.time
	if tDB.tb[2] then

		setHudYoffset(oPlayer, iID, iY)

		iY = iY + iDiff

		if bOff then clearHud(oPlayer, iID) end

	else

		clearHud(oPlayer, iID)

	end -- time

	iID = tDB.tIDs.trainTime
	if tDB.tb[1] then

		setHudYoffset(oPlayer, iID, iY)

		iY = iY + iDiff

		if bOff then clearHud(oPlayer, iID) end

	else

		clearHud(oPlayer, iID)

	end -- train

end -- rebuildHud


-- called when player joins
-- initialize the hud elements
postool.generateHud = function(oPlayer)

	local sName = oPlayer:get_player_name()

	if postool.tHudDB[sName] then
		-- already set up
		return
	end

	local tDB = {
		tIDs = {},
		tb = {
			true == postool.hudShowTrain,
			true == postool.hudShowTime,
			true == postool.hudShowNode,
			true == postool.hudShowBlock
		},
		bMain = true == postool.hudShowMain,
		bDefaultPosition = true,
		bFirstRun = true
	}

	tDB.tIDs.trainTime = oPlayer:hud_add({
		hud_elem_type = 'text',
		name = 'postoolTrainTime',
		position = HUD_POSITION,
		offset = { x = 0, y = -54 },
		text = 'Initializing...',
		scale = HUD_SCALE,
		alignment = HUD_ALIGNMENT,
		number = postool.hudColour
	})
	tDB.tIDs.time = oPlayer:hud_add({
		hud_elem_type = 'text',
		name = 'postoolTime',
		position = HUD_POSITION,
		offset = { x = 0, y = -36 },
		text = 'Initializing...',
		scale = HUD_SCALE,
		alignment = HUD_ALIGNMENT,
		number = postool.hudColour
	})
	tDB.tIDs.node = oPlayer:hud_add({
		hud_elem_type = 'text',
		name = 'postoolNode',
		position = HUD_POSITION,
		offset = { x = 0, y = -18 },
		text = 'Initializing...',
		scale = HUD_SCALE,
		alignment = HUD_ALIGNMENT,
		number = postool.hudColour
	})
	tDB.tIDs.block = oPlayer:hud_add({
		hud_elem_type = 'text',
		name = 'postoolBlock',
		position = HUD_POSITION,
		offset = { x = 0, y = 0 },
		text = 'Initializing...',
		scale = HUD_SCALE,
		alignment = HUD_ALIGNMENT,
		number = postool.hudColour
	})

	postool.tHudDB[sName] = tDB

	-- this had no effect, so we use first-run-method
	--postool.rebuildHud(oPlayer)

end -- generatHud


-- show new text
postool.updateHud = function(oPlayer, sTrain, sTime)

	local sName = oPlayer:get_player_name()
	local tDB = postool.tHudDB[sName]

	if tDB.tb[1] then

		oPlayer:hud_change(tDB.tIDs.trainTime, 'text', sTrain)

	end -- rwt

	if tDB.tb[2] then

		oPlayer:hud_change(tDB.tIDs.time, 'text', sTime)

	end -- time

	-- need to get positon strings at all?
	if not (tDB.tb[3] or tDB.tb[4]) then return end

	local sNode, sBlock = postool.getPositions(oPlayer)

	if tDB.tb[3] then

		oPlayer:hud_change(tDB.tIDs.node, 'text', sNode)

	end -- node

	if tDB.tb[4] then

		oPlayer:hud_change(tDB.tIDs.block, 'text', sBlock)

	end -- block

end -- updateHud


-- called after player leaves
-- remove hud elements
postool.removeHud = function(oPlayer)

	local sName = oPlayer:get_player_name()
	local tDB = postool.tHudDB[sName]
	if not tDB then return end

	-- remove each hud
	for _, iID in pairs(tDB.tIDs) do

		oPlayer:hud_remove(iID)

	end

	-- remove metadata
	postool.tHudDB[sName] = nil

end -- removeHud


-- track time of last call
local iTimeNext = 0


postool.register_globalstep = function()

	-- check if need to update
	local iTimeNow = os.clock()
	if iTimeNext > iTimeNow then
		-- not yet
		return
	end

	iTimeNext = iTimeNow + postool.hudMinUpdateInterval

	-- Update hud text that is the same for all players
	local sTrain = postool.hudTitleTrain .. postool.getTimeTrain()
	local sTime = postool.hudTitleTime .. postool.getTime()

	for _, oPlayer in ipairs(minetest.get_connected_players()) do

		local sName = oPlayer:get_player_name()

		local tDB = postool.tHudDB[sName]
		if not tDB then
			print('[postool]huds:globalstep: strange, no hud data for player: ' .. sName)
			postool.generateHud(oPlayer)
			tDB = postool.tHudDB[sName]
		end
--[[
		if not tDB.tIDs then
			print('[postool]huds:globalstep: very strange, no hud IDs for player: ' .. sName)
			return
		end
--]]

		-- is this the first run for this player?
		if tDB.bFirstRun then

			postool.rebuildHud(oPlayer)
			tDB.bFirstRun = false

		-- check if player has turned on hud at all
		elseif tDB.bMain then

			postool.updateHud(oPlayer, sTrain, sTime)

		end

	end -- loop players

end -- register_globalstep
