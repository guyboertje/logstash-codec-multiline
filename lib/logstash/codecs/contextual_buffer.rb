
module LogStash module Codecs class ContextualBuffer
  attr_reader :context

  def initialize(max_lines, max_bytes)
    clear
    @max_lines = max_lines
    @max_bytes = max_bytes
  end

  def overwrite_context(ctx)
    @context = ctx
  end

  def append(text)
    @buffer_bytes += text.bytesize
    @buffer.push(text)
  end

  def join(sep = $/)
    @buffer.join(sep)
  end

  def any?
    @buffer_bytes > 0
  end

  def empty?
    @buffer_bytes == 0
  end

  def clear
    @buffer = []
    @buffer_bytes = 0
    @context = {}
  end

  def multiple_lines?
    @buffer.size > 1
  end

  def over_maximum_lines?
    @buffer.size > @max_lines
  end

  def over_maximum_bytes?
    @buffer_bytes >= @max_bytes
  end

  def over_limits?
    over_maximum_lines? || over_maximum_bytes?
  end

end end end
