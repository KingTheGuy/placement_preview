Utils = {}

---@param this_string string the string
---@param split string sub to split at
function Utils.Splitter(this_string, split)
	local new_word = {}
	local index = string.find(this_string, split)
	if index == nil then
		new_word[1] = this_string
		new_word[2] = this_string
		return new_word
	end
	local split_index = index
	local split_start = ""
	for x = 0, split_index - 1, 1 do
		split_start = split_start .. string.sub(this_string, x, x)
	end
	new_word[1] = split_start

	local split_end = ""
	for x = split_index + #split, #this_string, 1 do
		split_end = split_end .. string.sub(this_string, x, x)
	end
	new_word[2] = split_end
	return new_word
end

function Utils.StringContains(str, find)
	str = string.upper(str)
	find = string.upper(find)
	local i, _ = string.find(str, find)
	-- core.log(string.format("what does this return? %s",tostring(i)))
	return i
end


function Utils.Split(str, delimiter)
	local result = {}
	for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end
