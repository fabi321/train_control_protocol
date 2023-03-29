require('queue')

pending = queue()
---@type table<number, table<string, number>>
registered = {}

---@param channel_type number
---@param poll_interval number
function register(channel_type, poll_interval)
    registered[channel_type] = {
        poll_interval=poll_interval,
        poll_interval_done=poll_interval,
        last_value=0,
        init=0,
    }
end

---@param channel_type number
---@param input_id number
function process(channel_type, input_id)
    ---@type table<string, number>
    local current_channel = registered[channel_type]
    ---@type number
    local current_value = input.getNumber(input_id)
    if current_channel.poll_interval_done > 0 then
        current_channel.poll_interval_done = current_channel.poll_interval_done - 1
    elseif current_channel.last_value ~= current_value then
        current_channel.last_value = current_value
        current_channel.poll_interval_done = current_channel.poll_interval
        if current_channel.init == 0 then
            current_channel.init = 1
        else
            pending:pushright({channel_type, current_value})
        end
    end
    ---@type number
    local received_type = input.getNumber(31)
    ---@type number
    local received_value = input.getNumber(32)
    if received_type == channel_type then
        output.setNumber(input_id, received_value)
    end
end

function send()
    local current = pending:popleft()
    if current ~= nil then
        output.setNumber(31, current[1])
        output.setNumber(32, current[2])
    else
        output.setNumber(31, 0)
        output.setNumber(32, 0)
    end
end
