require("queue")

pending = queue()

-- tumfl: preserve
function onTick()
    output.setNumber(31, 0)
    output.setNumber(32, 0)
    if input.getNumber(1) >= 10 then
        pending:pushleft({input.getNumber(1), input.getNumber(2)})
    end
    for i=3,31,2 do
        if input.getNumber(i) >= 10 then
            pending:pushright({input.getNumber(i), input.getNumber(i + 1)})
        end
    end
    local current = pending:popleft()
    if current ~= nil then
        output.setNumber(31, current[1])
        output.setNumber(32, current[2])
    end
end
