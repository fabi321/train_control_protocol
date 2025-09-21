i = input
o = output
gn = i.getNumber
sn = o.setNumber

require("queue")

pending = queue()

-- tumfl: preserve
function onTick()
    sn(31, 0)
    sn(32, 0)
    if gn(1) >= 10 then
        pending:pushleft({gn(1), gn(2)})
    end
    for i=3,31,2 do
        if gn(i) >= 10 then
            pending:pushright({gn(i), gn(i + 1)})
        end
    end
    local current = pending:popleft()
    if current ~= nil then
        sn(31, current[1])
        sn(32, current[2])
    end
end
