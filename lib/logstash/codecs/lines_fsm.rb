module LogStash
  class LinesFsm
    attr_reader :state, :buffer

    def initialize(listener, negate, what, begin_re, end_re = nil, excl = false)
      @listener = listener
      @buffer = ""
      @begin_re, @end_re = begin_re, end_re

      @state = :pass # or :accu
      @next_state = { :pass => :accu, :accu => :pass }.freeze
      @predicates = {}
      maccumulate = method(:accumulate)
      mflush = method(:flush)

      @tasks = {:pass => {}, :accu => {}}
      # tasks for next
      @tasks[:pass][:pass] = [mflush, maccumulate]
      @tasks[:pass][:accu] = [mflush, maccumulate]
      @tasks[:accu][:accu] = [maccumulate]
      @tasks[:accu][:pass] = [maccumulate]

      if end_re.nil? # legacy
        if what == :previous
          @tasks[:pass][:accu] = [maccumulate]
          @tasks[:accu][:pass] = [mflush, maccumulate]
        end
        # predicates are set once - no need for to cache the method procs
        if negate
          @predicates[:pass] = method(:not_match)
          @predicates[:accu] = method(:match)
        else
          @predicates[:pass] = method(:match)
          @predicates[:accu] = method(:not_match)
        end
      else # begin end
        @predicates[:pass] = method(:begin_match)
        @predicates[:accu] = method(:end_match)
        if excl
          @tasks[:pass][:accu] = [mflush]
          @tasks[:accu][:pass] = [mflush]
        else
          @tasks[:accu][:pass] = [maccumulate, mflush]
        end
      end
    end

    def accept(chunk)
      nxt = next_state(@predicates[state], chunk)
      @tasks[state][nxt].each do |t|
        t.call(chunk)
      end
      @state = nxt
    end

    def flush(*)
      return if @buffer.empty?
      @listener.accept(@buffer.chomp(''))
      @buffer.clear
    end

    private

    def accumulate(chunk)
      @buffer << "#{chunk}\n"
    end

    def next_state(predicate, chunk)
      !predicate.call(chunk) ? state : @next_state[state]
    end

    def match(chunk)
      @begin_re =~ chunk
    end
    alias_method :begin_match, :match

    def not_match(chunk)
      @begin_re !~ chunk
    end

    def end_match(chunk)
      @end_re =~ chunk
    end
  end
end
