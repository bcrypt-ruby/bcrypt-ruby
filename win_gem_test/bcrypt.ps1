# PowerShell script for building & testing SQLite3-Ruby fat binary gem
# Code by MSP-Greg, see https://github.com/MSP-Greg/av-gem-build-test

# load utility functions, pass 64 or 32
. $PSScriptRoot\shared\appveyor_setup.ps1 $args[0]
if ($LastExitCode) { exit }

# above is required code
#———————————————————————————————————————————————————————————————— above for all repos

Make-Const gem_name  'bcrypt'
Make-Const repo_name 'bcrypt-ruby'
Make-Const url_repo  'https://github.com/codahale/bcrypt-ruby.git'

#———————————————————————————————————————————————————————————————— lowest ruby version
Make-Const ruby_vers_low 20

#———————————————————————————————————————————————————————————————— make info
Make-Const dest_so   'lib'
Make-Const exts      @(
  @{ 'conf' = 'ext/mri/extconf.rb' ; 'so' = 'bcrypt_ext' }
)
Make-Const write_so_require $false

#———————————————————————————————————————————————————————————————— Run-Tests
function Run-Tests {
  # call with comma separated list of gems to install or update
  Update-Gems rspec, rake
  rake -f Rakefile_wintest -N -R norakelib | Set-Content -Path $log_name -PassThru -Encoding UTF8
  rspec_summary
}

#———————————————————————————————————————————————————————————————— below for all repos
# below is required code
Make-Const dir_gem  $(Convert-Path $PSScriptRoot\..)
Make-Const dir_ps   $PSScriptRoot

Push-Location $PSScriptRoot
.\shared\make.ps1
.\shared\test.ps1
Pop-Location
exit $ttl_errors_fails + $exit_code
