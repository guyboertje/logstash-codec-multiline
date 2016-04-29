module LogStash
  class LineFsm
    attr_reader :state

    def initialize(listener, end_char = "\n", begin_char = nil)
      @listener = listener
      @begin_char, @end_char = begin_char, end_char
      @tasks, @state = {}, :drop
      # these task determine what should happen when going from state
      # to state, even if the state stays the same.
      mdrop = method(:drop)
      maccu = method(:accumulate)
      mflus = method(:flush)
      @tasks, @predicates = {}, {}
      @tasks[:drop] = {:drop => [mdrop], :accu => []}
      @tasks[:accu] = {:accu => [maccu], :drop => [mflus]}
      @next_state = { :drop => :accu, :accu => :drop }.freeze

      # these predicates determine whether a state can transition to another state
      if begin_char.nil?
        @predicates[:drop] = method(:not_end_match)
        @predicates[:accu] = method(:end_match)
      else
        # begin end
        @predicates[:drop] = method(:not_begin_and_end_match)
        @predicates[:accu] = method(:begin_or_end_match)
      end

      @start = @size = 0
      @len, @data = 1, ""
    end

    def accept(data)
      if left > 0
        @data = @data.slice(@start, left) + data
      else
        @data = data
      end
      @start = 0
      @len = 1
      @size = @data.size
      while @size > @start + @len.pred
        nxt = next_state(@predicates[state])
        tsks = @tasks[state][nxt]
        tsks.each do |t|
          t.call
        end
        @state = nxt
      end
    end

    def buffer
      @data[@start, left]
    end

    def flush
      @listener.accept(current_slice)
      @start = @start + @len
      @len = 1
    end

    private

    def drop
      @start = @start.succ
    end

    def accumulate
      @len = @len.succ
    end

    def left
      @size - @len
    end

    def next_state(predicate)
      predicate.call ? @next_state[state] : state
    end

    def current_slice
      @data[@start, @len.pred]
    end

    def current_char
      @data[@start + @len.pred]
    end

    def end_match
      @end_char == current_char
    end

    def not_end_match
      @end_char != current_char
    end

    def begin_or_end_match
      char = current_char
      @end_char == char || @begin_char == char
    end

    def not_begin_and_end_match
      char = current_char
      @begin_char != char && @end_char != char
    end
  end
end
