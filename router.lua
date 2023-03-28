i=input;o=output
gn=i.getNumber;sn=o.setNumber

proto_desc = property.getText('protocol')
protocol = {}
for channel in proto_desc:gmatch('([^=]+)') do
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
--  5. normal (forward client and rear switch)
--  6. inverted (rear client and forward switch)

function process(message_type, value, zone)
	local current_proto = protocol[message_type]
	if current_proto.R and zone == 2 then
		return nil
	end
	if current_proto.I and (zone == 2 or zone == 3 or zone == 6) then
		value = -value
	end

end

fwd_pending = queue()
rear_pending = queue()
client_pending = queue()
state = {}

function onTick()
	fwd_client_in_type = gn(10)
	fwd_client_in_value = gn(11)
	rear_client_in_type = gn(12)
	rear_client_in_value = gn(13)
	fwd_switch_in_type = gn(14)
	fwd_switch_in_value = gn(15)
	rear_switch_in_type = gn(16)
	rear_switch_in_value = gn(17)
	fwd_client_out_type = 0
	fwd_client_out_value = 0
	fwd_client_out_type = 0
	rear_client_out_value = 0
	rear_switch_out_type = 0
	fwd_switch_out_value = 0
	rear_switch_out_type = 0
	rear_switch_out_value = 0
	sn(10, fwd_client_out_type)
	sn(11, fwd_client_out_value)
	sn(12, rear_client_out_type)
	sn(13, rear_client_out_value)
	sn(14, fwd_switch_out_type)
	sn(15, fwd_switch_out_value)
	sn(16, rear_switch_out_type)
	sn(17, rear_switch_out_value)
end
