require("queue")

state = 0
pending = queue()
tick = 0
last_update = -1/0

-- tumfl: preserve
function onTick()
	local tick = tick + 1
	local mc_in_type = input.getNumber(10)
	local mc_in_value = input.getNumber(11)
	local is_connected = input.getNumber(12) == 1
	local in_type = input.getNumber(31)
	local in_value = input.getNumber(32)
	local mc_out_type = 0
	local mc_out_value = 0
	local out_type = 0
	local out_value = 0
	if state == 0 then
		if is_connected then
			out_type = 1
			out_value = tick - last_update
			state = 1
		end
	elseif state <= 3 then
		state = state + 1
	elseif state == 4 then
		if in_type == 1 then
			mc_out_type = 1
			if in_value > tick - last_update then
				mc_out_value = 100
			else
				mc_out_value = 101
			end
			state = 5
		else
			state = 0
		end
		state = 5
	elseif state == 5 then
		if mc_in_type >= 10 then
			last_update = tick
			pending:pushleft({mc_in_type, mc_in_value})
		end
		if in_type >= 10 then
			last_update = tick
			pending:pushleft({in_type, in_value})
			mc_out_type = in_type
			mc_out_value = in_value
		end
		local current = pending:popleft()
		if current ~= nil then
			out_type = current[1]
			out_value = current[2]
		end
	end
	if not is_connected then
		state = 0
	end
	output.setNumber(10, mc_out_type)
	output.setNumber(11, mc_out_value)
	output.setNumber(31, out_type)
	output.setNumber(32, out_value)
end
