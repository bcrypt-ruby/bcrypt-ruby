require "mkmf"
dir_config("bcrypt")
CONFIG['CC'] << " -Wall "
create_makefile("bcrypt")

