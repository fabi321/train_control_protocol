require('peripheral_lib')

register(20, 20)
register(21, 60)
register(22, 60)

function onTick()
    process(20, 1)
    process(21, 2)
    process(22, 3)
    send()
end
