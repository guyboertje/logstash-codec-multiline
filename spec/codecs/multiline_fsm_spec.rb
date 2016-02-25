require "logstash/codecs/multiline_fsm"
require_relative "../supports/helpers.rb"

describe LogStash::Codecs::MultilineFsm do
  let(:listener) { Mlc::ListenerTracer.new() }
  let(:buffer) { listener.buf}
  let(:what)   { :previous }
  let(:negate) { false }
  let(:regex)  { %r"\A\-{1,3}" }

  before { lines.each {|l| subject.accept(l) } }

  context "when config is previous and !negate" do
    let(:lines) do
      ["foo", "foo", "--bar", "--baz", "foo"]
    end

    subject { described_class.new(listener, negate, what, regex) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["foo", "foo, --bar, --baz"])
      expect(buffer).to eq(["foo"])
    end
  end

  context "when config is previous and negate" do
    let(:negate) { true }
    let(:lines) do
      ["--foo", "--the", "cat", "sat", "on", "the", "mat", "--bar"]
    end

    subject { described_class.new(listener, negate, what, regex) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["--foo", "--the, cat, sat, on, the, mat"])
      expect(buffer).to eq(["--bar"])
    end
  end

  context "when config is next and !negate" do
    let(:what) { :next }
    let(:regex)  { %r"\s\-{1,3}\z" }
    let(:lines) do
      ["foo", "the -", "cat -", "sat -", "on -", "the -", "mat", "bar"]
    end

    subject { described_class.new(listener, negate, what, regex) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["foo", "the -, cat -, sat -, on -, the -, mat"])
      expect(buffer).to eq(["bar"])
    end
  end

  context "when config is next and negate" do
    let(:what) { :next }
    let(:negate) { true }
    let(:regex)  { %r"\s\-{1,3}\z" }
    let(:lines) do
      ["foo -", "the", "cat", "sat", "on", "the", "mat -", "bar -"]
    end

    subject { described_class.new(listener, negate, what, regex) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["foo -", "the, cat, sat, on, the, mat -"])
      expect(buffer).to eq(["bar -"])
    end
  end

  context "when config is begin and end inclusive" do
    let(:what) { :next }
    let(:negate) { true }
    let(:beginr)  { %r"\A\-{1,3}\sbegin\s\-{1,3}\z" }
    let(:endr)    { %r"\A\-{1,3}\send\s\-{1,3}\z" }
    let(:exclusive) { false }
    let(:lines) do
      ["foo", "--- begin ---", "the", "cat", "sat", "on", "the", "mat", "--- end ---", "bar"]
    end

    subject { described_class.new(listener, negate, what, beginr, endr, exclusive) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["foo", "--- begin ---, the, cat, sat, on, the, mat, --- end ---"])
      expect(buffer).to eq(["bar"])
    end
  end

  context "when config is begin and end exclusive" do
    let(:what) { :next }
    let(:negate) { true }
    let(:beginr)  { %r"\A\-{1,3}\sbegin\s\-{1,3}\z" }
    let(:endr)    { %r"\A\-{1,3}\send\s\-{1,3}\z" }
    let(:exclusive) { true }
    let(:lines) do
      ["foo", "--- begin ---", "the", "cat", "sat", "on", "the", "mat", "--- end ---", "bar"]
    end

    subject { described_class.new(listener, negate, what, beginr, endr, exclusive) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["foo", "the, cat, sat, on, the, mat"])
      expect(buffer).to eq(["bar"])
    end
  end

  context "when config is begin and end exclusive and there are multiple begins" do
    let(:what) { :next }
    let(:negate) { true }
    let(:beginr)  { %r"\A\-{1,3}\sbegin\s\-{1,3}\z" }
    let(:endr)    { %r"\A\-{1,3}\send\s\-{1,3}\z" }
    let(:exclusive) { true }
    let(:lines) do
      ["foo", "--- begin ---", "the", "cat", "sat", "--- begin ---", "on", "the", "mat", "--- end ---", "bar"]
    end

    subject { described_class.new(listener, negate, what, beginr, endr, exclusive) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["foo", "the, cat, sat, --- begin ---, on, the, mat"])
      expect(buffer).to eq(["bar"])
    end
  end

  context "when config is begin and end exclusive and there are multiple ends" do
    let(:what) { :next }
    let(:negate) { true }
    let(:beginr)  { %r"\A\-{1,3}\sbegin\s\-{1,3}\z" }
    let(:endr)    { %r"\A\-{1,3}\send\s\-{1,3}\z" }
    let(:exclusive) { true }
    let(:lines) do
      ["foo", "--- begin ---", "the", "cat", "sat", "on", "the", "--- end ---", "mat", "--- end ---", "bar"]
    end

    subject { described_class.new(listener, negate, what, beginr, endr, exclusive) }

    it "flushes and buffers correctly" do
      expect(listener.full_trace_for(:flush)).to eq(["foo", "the, cat, sat, on, the", "mat", "--- end ---"])
      expect(buffer).to eq(["bar"])
    end
  end
end
