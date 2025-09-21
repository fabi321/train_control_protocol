require('peripheral_lib')

register(20, 5)
register(21, 20)
register(22, 20)

-- tumfl: preserve
function onTick()
    process(20, 1)
    process(21, 2)
    process(22, 3)
    send()
end
