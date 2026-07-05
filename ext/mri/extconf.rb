if RUBY_PLATFORM == "java"
  # Don't do anything when run in JRuby; this allows gem installation to pass.
  # We need to write a dummy Makefile so that RubyGems doesn't think compilation
  # failed.
  File.open('Makefile', 'w') do |f|
    f.puts "all:"
    f.puts "\t@true"
    f.puts "install:"
    f.puts "\t@true"
  end
  exit 0
else
  require "mkmf"

  # From Openwall's crypt_blowfish Makefile.
  # This is `bcrypt_ext` (our extension) + CRYPT_OBJS from that Makefile.
  $objs = %w(bcrypt_ext.o crypt_blowfish.o crypt_gensalt.o wrapper.o)

  # x86.S is an optional i386 assembly implementation; it is guarded by
  # #ifdef __i386__ and assembles to an empty object everywhere else.
  # MSVC cannot assemble it at all, so leave it out there and rely on the
  # portable C implementation (BF_ASM == 0) in crypt_blowfish.c.
  $objs << "x86.o" unless $mswin

  $defs << "-D__SKIP_GNU"
  dir_config("bcrypt_ext")
  create_makefile("bcrypt_ext")
end
