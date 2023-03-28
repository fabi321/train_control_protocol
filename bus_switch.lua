i=input;o=output
gn=i.getNumber;sn=o.setNumber

require("queue")

state = 0
pending = queue()
tick = 0
last_update = -1/0


function onTick()
	tick = tick + 1
	mc_in_type = gn(10)
	mc_in_value = gn(11)
	is_connected = gn(12) == 1
	in_type = gn(31)
	in_value = gn(32)
	mc_out_type = 0
	mc_out_value = 0
	out_type = 0
	out_value = 0
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
	sn(10, mc_out_type)
	sn(11, mc_out_value)
	sn(31, out_type)
	sn(32, out_value)
end
