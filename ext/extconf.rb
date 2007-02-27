require "mkmf"
dir_config("bcrypt_ext")
# enable this when we're feeling nitpicky
# CONFIG['CC'] << " -Wall "
create_makefile("bcrypt_ext")