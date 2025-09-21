from sw_mc_builder import *

add_include_path("../lua_src")

mc = Microcontroller("Peripheral Switch", 4, 4, "You can remove any excess nodes without any problem.")

lua_input = comp.unconnected(SignalType.Composite)

for i in range(1, 16):
    name = "Priority input" if i == 1 else f"Input {i}"
    input_signal = comp.input(SignalType.Composite, name)
    mc.place_input(input_signal, i % 4, i // 4)
    lua_input[i*2-1:i*2] = input_signal[31:]

output_signal, _ = comp.lua_script_file("peripheral_switch.lua", lua_input)
mc.add_image_from_file("peripheral_switch.png")
mc.place_output(output_signal, "Output")

if __name__ == "__main__":
    handle_mcs(mc)
