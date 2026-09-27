require File.expand_path('../spec_helper', __dir__)

# Only implements the hooks needed to run a native operation on another thread.
class BCryptOffloadScheduler
  attr_reader :calls
  attr_accessor :before_work

  def initialize
    @calls = 0
  end

  def blocking_operation_wait(work)
    @calls += 1
    @before_work.call if @before_work
    Fiber.new(blocking: true) { Thread.new { work.call }.value }.resume
  end

  def block(*)
    raise 'unexpected block'
  end

  def unblock(*)
    raise 'unexpected unblock'
  end

  def kernel_sleep(*)
    raise 'unexpected sleep'
  end

  def io_wait(*)
    raise 'unexpected IO'
  end

  def fiber_interrupt(*)
    raise 'unexpected interrupt'
  end
end

describe 'BCrypt fiber scheduler offloading' do
  before do
    skip 'requires CRuby 3.4 or later' unless RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.4')
    @scheduler = BCryptOffloadScheduler.new
    Fiber.set_scheduler(@scheduler)
  end

  after do
    Fiber.set_scheduler(nil) if @scheduler
  end

  it 'generates the same salt on a worker thread' do
    input = '0123456789abcdef'
    expected = BCrypt::Engine.send(:__bc_salt, '$2a$', 4, input)
    actual = Fiber.new { BCrypt::Engine.send(:__bc_salt, '$2a$', 4, input) }.resume

    expect(actual).to eq(expected)
    expect(@scheduler.calls).to eq(1)
  end

  it 'hashes a known test vector on a worker thread' do
    actual = Fiber.new { BCrypt::Engine.hash_secret('U*U', '$2a$05$CCCCCCCCCCCCCCCCCCCCC.') }.resume

    expect(actual).to eq('$2a$05$CCCCCCCCCCCCCCCCCCCCC.E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW')
    expect(@scheduler.calls).to eq(1)
  end

  it 'keeps salt inputs alive and unchanged while handing work to the scheduler' do
    prefix = '$2a$'.dup
    input = '0123456789abcdef'.dup
    expected = BCrypt::Engine.send(:__bc_salt, prefix, 4, input)
    @scheduler.before_work = proc do
      prefix.replace('changed')
      input.replace('changed')
      GC.start
      GC.compact if GC.respond_to?(:compact)
    end

    actual = Fiber.new { BCrypt::Engine.send(:__bc_salt, prefix, 4, input) }.resume

    expect(actual).to eq(expected)
    expect(@scheduler.calls).to eq(1)
  end

  it 'keeps hash inputs alive and unchanged while handing work to the scheduler' do
    secret = 'U*U'.dup
    salt = '$2a$05$CCCCCCCCCCCCCCCCCCCCC.'.dup
    @scheduler.before_work = proc do
      secret.replace('changed')
      salt.replace('changed')
      GC.start
      GC.compact if GC.respond_to?(:compact)
    end

    actual = Fiber.new { BCrypt::Engine.hash_secret(secret, salt) }.resume

    expect(actual).to eq('$2a$05$CCCCCCCCCCCCCCCCCCCCC.E5YPO9kmyuRGyh0XouQYb4YMJKvyOeW')
    expect(@scheduler.calls).to eq(1)
  end

  it 'preserves native failure results on a worker thread' do
    salt = Fiber.new { BCrypt::Engine.send(:__bc_salt, '$2a$', 32, '0123456789abcdef') }.resume
    hash = Fiber.new { BCrypt::Engine.send(:__bc_crypt, 'secret', '$2a$03$CCCCCCCCCCCCCCCCCCCCC.') }.resume

    expect(salt).to be_nil
    expect(hash).to be_nil
    expect(@scheduler.calls).to eq(2)
  end
end
