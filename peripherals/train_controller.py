import json

from pathlib import Path

from sw_mc_builder import *

add_include_path("../lua_src")

def parse_json() -> str:
    with (Path(__file__).parent.parent / 'protocol.json').open() as f:
        protocol_definition = json.load(f)
    result_str: str = ''
    for id, definition in protocol_definition.items():
        result_str += id
        if definition.get('sync'):
            result_str += 'S'
        elif definition.get('sync_newer'):
            result_str += 's'
        if definition.get('invert'):
            result_str += 'I'
        if definition.get('add'):
            result_str += 'A'
        if definition.get('ignore_rear'):
            result_str += 'R'
        result_str += '='
    return result_str[:-1]


protocol = parse_json()

mc = Microcontroller("Train Controller", 4, 3, "Controls a train car and communicates with neighbouring cars on a bus")

from_front_switch = comp.input(SignalType.Composite, "From front switch")
from_rear_switch = comp.input(SignalType.Composite, "From rear switch")

router_result = comp.placeholder(SignalType.Composite)
trusted_mode = comp.property_toggle(False, "Trusted Mode", "Only connect trusted cars.", "Connect all cars.")

def get_connector_interaction(i: int, other_result: CompositeWire) -> CompositeWire:
    name: str = "Rear" if i == 0 else "Front"
    name_lower: str = name.lower()

    coupler_connected = comp.input(SignalType.Boolean, f"{name} coupler connected")
    mc.place_input(coupler_connected, i * 2, 1)
    from_coupler = comp.input(SignalType.Composite, f"From {name_lower} coupler")
    mc.place_input(from_coupler, i * 2, 0)

    for_handshake = from_coupler.set(10, coupler_connected)
    for_handshake[11] = trusted_mode
    handshake_result, _ = comp.lua_script_file("handshake.lua", for_handshake)
    disconnect_coupler = handshake_result.get_bool(10)
    authenticated = handshake_result.get_bool(11)
    to_bus_switch = from_coupler.set(12, authenticated.int())
    result_base: int = 14 + 2 * i
    to_bus_switch[10:11] = router_result[result_base:result_base+1]
    switch_result, _ = comp.lua_script_file("bus_switch.lua", to_bus_switch, minify=False)
    to_coupler = authenticated.switch(other_result, handshake_result)

    mc.place_output(disconnect_coupler, f"Disconnect {name_lower} coupler", x=1 + i * 2, y=1)
    mc.place_output(to_coupler, f"To {name_lower} coupler", x=1 + i * 2, y=0)
    mc.add_boolean_tooltip(f"{name} coupler authenticated", authenticated)
    return switch_result

front_connector_result = comp.placeholder(SignalType.Composite)

rear_connector_result = get_connector_interaction(0, front_connector_result)
front_connector_result_ = get_connector_interaction(1, rear_connector_result)
front_connector_result.replace_producer(front_connector_result_)

to_router = comp.unconnected(SignalType.Composite)

to_router[10:11] = from_front_switch[31:]
to_router[12:13] = from_rear_switch[31:]
to_router[14:15] = front_connector_result[10:11]
to_router[16:17] = rear_connector_result[10:11]

router_result_, _ = comp.lua_script_file("router.lua", to_router)
router_result.replace_producer(router_result_)

INPUT_REWRITE_REAR: str = """
function onTick()
	output.setNumber(31,input.getNumber(10))
	output.setNumber(32,input.getNumber(11))
end
"""

to_rear_switch, _ = comp.lua_script(INPUT_REWRITE_REAR, router_result, minify=False)

INPUT_REWRITE_FRONT: str = """
function onTick()
    output.setNumber(31,input.getNumber(12))
    output.setNumber(32,input.getNumber(13))
end
"""
to_front_switch, _ = comp.lua_script(INPUT_REWRITE_FRONT, router_result, minify=False)

mc.add_image_from_file("train_controller.png")
mc.place_input(from_front_switch, 0, 2)
mc.place_input(from_rear_switch, 2, 2)
mc.place_output(to_front_switch, "To front switch", x=1, y=2)
mc.place_output(to_rear_switch, "To rear switch", x=3, y=2)
mc.add_text_property("protocol", protocol, force_property=True)

if __name__ == "__main__":
    handle_mcs(mc)
