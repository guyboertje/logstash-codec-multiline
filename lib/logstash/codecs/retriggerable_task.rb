require "concurrent"

module LogStash module Codecs class RetriggerableTask
  class DummyListener
    def timeout
      STDOUT.puts "..... task timed out ....."
    end
  end

  attr_reader :thread

  def initialize(delay, listener = DummyListener.new)
    @delay = calculate_delay(delay)
    @listener = listener
    @counter = Concurrent::AtomicFixnum.new(0 + @delay)
    @stopped = Concurrent::AtomicBoolean.new(false)
    @semaphore = Concurrent::Semaphore.new(1)
    @semaphore.drain_permits
  end

  def retrigger
    return if stopped?
    if executing?
      STDERR.puts "----- exec acquire"
      @semaphore.acquire
    end

    if pending?
      STDERR.puts "----- reset_counter"
      reset_counter
    else
      STDERR.puts "----- start"
      start
    end
  end

  def close
    @stopped.make_true
  end

  def counter
    @counter.value
  end

  def executing?
    running? && counter < 1
  end

  def pending?
    running? && counter > 0
  end

  private

  def calculate_delay(value)
    # in multiples of 0.25 seconds
    return 1 if value < 0.25
    (value / 0.25).floor
  end

  def reset_counter
    @counter.value = 0 + @delay
  end

  def running?
    @thread && @thread.alive?
  end

  def start()
    reset_counter
    @thread = Thread.new do
      while counter > 0
        break if stopped?
        sleep 0.25
        @counter.decrement
      end

      @semaphore.drain_permits
      if !stopped?
        if block_given?
          yield
        else
          @listener.timeout
        end
      end
      @semaphore.release
    end
  end

  def stopped?
    @stopped.value
  end
end end end
