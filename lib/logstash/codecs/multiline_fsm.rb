module LogStash module Codecs class MultilineFsm
    attr_reader :state

    def initialize(listener, negate, what, begin_re, end_re = nil, excl = false)
      @listener = listener
      @begin_re, @end_re = begin_re, end_re

      @state = :pass # or :accu
      @next_state = { :pass => :accu, :accu => :pass }.freeze
      @predicates = {}
      @tasks = {:pass => {}, :accu => {}}

      # predicates for negate == false
      @predicates[:pass] = :match
      @predicates[:accu] = :not_match

      # tasks for next
      @tasks[:pass][:pass] = [:flush, :buffer]
      @tasks[:pass][:accu] = [:flush, :buffer]
      @tasks[:accu][:accu] = [:buffer]
      @tasks[:accu][:pass] = [:buffer]

      if end_re.nil? # legacy
        if what == :previous
          @tasks[:pass][:accu] = [:buffer]
          @tasks[:accu][:pass] = [:flush, :buffer]
        end
        if negate
          @predicates[:pass] = :not_match
          @predicates[:accu] = :match
        end
      else # begin end
        @predicates[:pass] = :begin_match
        @predicates[:accu] = :end_match
        if excl
          @tasks[:pass][:accu] = [:flush]
          @tasks[:accu][:pass] = [:flush]
        else
          @tasks[:accu][:pass] = [:buffer, :flush]
        end
      end
    end

    def accept(line)
      nxt = next_state(@predicates[state], line)
      @tasks[state][nxt].each do |t|
        @listener.send(t, line)
      end
      @state = nxt
    end

    private

    def next_state(predicate, line)
      !send(predicate, line) ? state : @next_state[state]
    end

    def match(line)
      @begin_re =~ line
    end
    alias_method :begin_match, :match

    def not_match(line)
      @begin_re !~ line
    end

    def end_match(line)
      @end_re =~ line
    end
  end end end
