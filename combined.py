from sw_mc_builder import *

add_include_path("peripherals")
add_include_path("lua_src")

from peripherals.basic_drive import mc as basic_drive_mc
from peripherals.peripheral_switch import mc as peripheral_switch_mc
from peripherals.train_controller import mc as train_controller_mc

if __name__ == "__main__":
    handle_mcs(basic_drive_mc, peripheral_switch_mc, train_controller_mc)