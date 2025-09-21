---@type string
proto_desc = property.getText('protocol')
---@type table<number, table<string, boolean>>
protocol = {}
for channel in proto_desc:gmatch('([^=]+)') do
	---@type table<string, boolean>
	local tmp = {}
	for l in channel:gmatch("%a") do
		tmp[l] = true
	end
	protocol[tonumber(channel:match("%d+"))] = tmp
end

require("queue")

-- zones:
--    (input zones)
--  1. forward client
--  2. rear client
--  3. forward switch
--  4. rear switch
--    (output zones)
--  5. forward client
--  6. rear client
--  7. forward switch
--  8. rear switch

---@param message_type number
---@param value number
---@param zone number
---@return number | nil
function process(message_type, value, zone)
	local current_proto = protocol[message_type]
	if current_proto.R and zone == 2 then
		return nil
	end
	if current_proto.I and (zone == 2 or zone == 3 or zone == 6 or zone == 7) then
		value = -value
	end
	return value
end

---@type table<number, number>
state = {}

function update(to_update, type)
	for k, v in pairs(protocol) do
		if v.s then
			to_update:pushright({k, state[k]})
		end
	end
	if type == 101 then
		for k, v in pairs(protocol) do
			if v.S then
				to_update:pushright({k, state[k]})
			end
		end
	end
end

fwd_switch_pending = queue()
rear_switch_pending = queue()
fwd_client_pending = queue()
rear_client_pending = queue()

-- tumfl: preserve
function onTick()
	local fwd_client_in_type = input.getNumber(10)
	local fwd_client_in_value = input.getNumber(11)
	local rear_client_in_type = input.getNumber(12)
	local rear_client_in_value = input.getNumber(13)
	local fwd_switch_in_type = input.getNumber(14)
	local fwd_switch_in_value = input.getNumber(15)
	local rear_switch_in_type = input.getNumber(16)
	local rear_switch_in_value = input.getNumber(17)
	local type = fwd_client_in_type
	if protocol[type] then
		local value = process(type, fwd_client_in_value, 1)
		fwd_switch_pending:pushright({type, value})
		rear_switch_pending:pushright({type, value})
		state[type] = value
	end
	type = rear_client_in_type
	if protocol[type] then
		local value = process(type, rear_client_in_value, 2)
		fwd_switch_pending:pushright({type, value})
		rear_switch_pending:pushright({type, value})
		state[type] = value
	end
	type = fwd_switch_in_type
	if protocol[type] then
		local value = process(type, fwd_switch_in_value, 3)
		fwd_client_pending:pushright({type, value})
		rear_client_pending:pushright({type, value})
		state[type] = value
	elseif type == 1 then
		if fwd_switch_in_value == 100 or fwd_switch_in_value == 101 then
			update(fwd_switch_pending, fwd_switch_in_value)
		end
	end
	type = rear_switch_in_type
	if protocol[type] then
		local value = process(type, rear_switch_in_value, 4)
		fwd_client_pending:pushright({type, value})
		rear_client_pending:pushright({type, value})
		state[type] = value
	elseif type == 1 then
		if rear_switch_in_value == 100 or rear_switch_in_value == 101 then
			update(rear_switch_pending, rear_switch_in_value)
		end
	end
	local fwd_client_out_type = 0
	local fwd_client_out_value = 0
	local rear_client_out_type = 0
	local rear_client_out_value = 0
	local fwd_switch_out_type = 0
	local fwd_switch_out_value = 0
	local rear_switch_out_type = 0
	local rear_switch_out_value = 0
	local pending = fwd_client_pending:popleft()
	if pending ~= nil then
		fwd_client_out_type = pending[1]
		fwd_client_out_value = process(pending[1], pending[2], 5)
	end
	pending = rear_client_pending:popleft()
	if pending ~= nil then
		rear_client_out_type = pending[1]
		rear_client_out_value = process(pending[1], pending[2], 6)
	end
	pending = fwd_switch_pending:popleft()
	if pending ~= nil then
		fwd_switch_out_type = pending[1]
		fwd_switch_out_value = process(pending[1], pending[2], 7)
	end
	pending = rear_switch_pending:popleft()
	if pending ~= nil then
		rear_switch_out_type = pending[1]
		rear_switch_out_value = process(pending[1], pending[2], 8)
	end
	output.setNumber(10, fwd_client_out_type)
	output.setNumber(11, fwd_client_out_value)
	output.setNumber(12, rear_client_out_type)
	output.setNumber(13, rear_client_out_value)
	output.setNumber(14, fwd_switch_out_type)
	output.setNumber(15, fwd_switch_out_value)
	output.setNumber(16, rear_switch_out_type)
	output.setNumber(17, rear_switch_out_value)
end
