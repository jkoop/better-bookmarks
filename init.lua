-------------------------------------------------
--  Copyleft 2019-2022 Joe Koop                --
--  https://github.com/jkoop/better-bookmarks  --
-------------------------------------------------

local storage = minetest.get_mod_storage()
local betterBookmarks = {}

function betterBookmarks.setPos(longBookmarkName, position)
	if not (longBookmarkName and position) then
		return false
	end

	-- set the bookmark
	storage:set_string(longBookmarkName, minetest.pos_to_string(position, 2))

	minetest.log("action", "[better_bookmarks] set bookmark " .. longBookmarkName .. " to " .. minetest.pos_to_string(position, 0))
	return true
end

function betterBookmarks.getPos(longBookmarkName)
	if not longBookmarkName then
		return false
	end

	return minetest.string_to_pos(storage:get_string(longBookmarkName)) or false
end

function betterBookmarks.delPos(longBookmarkName)
	if not longBookmarkName then
		return false
	end

	storage:set_string(longBookmarkName, '')

	return true
end

function betterBookmarks.setBookmark(playerName, bookmarkName)
	if bookmarkName == "" or string.find(bookmarkName, '%.') then -- string.find looks for patterns, not strings
		return false, "Invalid usage, see /help bmset."
	end

	local player = minetest.get_player_by_name(playerName)

	-- player can't set bookmark if they're not in the world
	if not minetest.is_player(player) then
		return false, "You are not online."
	end

	local playerPosition = player.get_pos(player) -- <- that's anoying

	if betterBookmarks.setPos(playerName .. '.' .. bookmarkName, playerPosition) then
		return true, "Bookmark set."
	else
		return false, "Couldn't set bookmark. This is a bug."
	end
end

function betterBookmarks.goToBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Invalid usage, see /help bm."
	end

	local bookmarkPosition = betterBookmarks.getPos(playerName .. '.' .. bookmarkName)

	if bookmarkPosition then
		return true, minetest.pos_to_string(bookmarkPosition, 0)
	else
		return false, "Couldn't get bookmark."
	end
end

function betterBookmarks.deleteBookmark(playerName, bookmarkName)
	if bookmarkName == "" then
		return false, "Invalid usage, see /help bmdel."
	end

	local success = betterBookmarks.delPos(playerName .. '.' .. bookmarkName)

	if success then
		return true, "Removed bookmark."
	else
		return false, "Couldn't remove bookmark."
	end
end

minetest.register_chatcommand("bmset", {
	params = "bookmark-name",
	description = "Set a bookmark. Bookmark names cannot contain '.'",
	func = betterBookmarks.setBookmark
})

minetest.register_chatcommand("bm", {
	params = "bookmark-name",
	description = "Go to a bookmark",
	func = betterBookmarks.goToBookmark
})

minetest.register_chatcommand("bmdel", {
	params = "bookmark-name",
	description = "Delete a bookmark",
	func = betterBookmarks.deleteBookmark
})
