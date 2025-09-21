from sw_mc_builder import *

add_include_path("../lua_src")

controller_input = comp.input(SignalType.Composite, "From car controller")
throttle_brake = comp.input(SignalType.Number, "Throttle/Brake")
direction = comp.input(SignalType.Number, "Direction")
engine_state = comp.input(SignalType.Number, "Engine state")

updated_controller_input = controller_input.set(slice(None, 3), [throttle_brake, direction, engine_state])
result, _ = comp.lua_script_file("basic_drive.lua", updated_controller_input, minify=False)

throttle_result, direction_result, engine_result = result[:3]

mc = Microcontroller("Basic Drive", 4, 2, "A basic drive system for trains.")
mc.add_image_from_file("basic_drive.png")
mc.place_input(controller_input, 0, 0)
mc.place_output(result, "To car controller", x=0, y=1)
mc.place_input(throttle_brake, 1, 0)
mc.place_output(throttle_result, "Throttle", x=1, y=1)
mc.place_input(direction, 2, 0)
mc.place_output(direction_result, "Direction", x=2, y=1)
mc.place_input(engine_state, 3, 0)
mc.place_output(engine_result, "Brake", x=3, y=1)

if __name__ == "__main__":
    handle_mcs(mc)
