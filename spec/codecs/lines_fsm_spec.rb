require "logstash/codecs/lines_fsm"
require_relative "../supports/helpers.rb"

describe LogStash::LinesFsm do
  let(:listener) { Mlc::AcceptTracer.new() }

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
      expect(listener.lines).to eq(["foo", "foo\n--bar\n--baz"])
      expect(subject.buffer).to eq("foo\n")
    end
  end

  context "when config is previous and negate" do
    let(:negate) { true }
    let(:lines) do
      ["--foo", "--the", "cat", "sat", "on", "the", "mat", "--bar"]
    end

    subject { described_class.new(listener, negate, what, regex) }

    it "flushes and buffers correctly" do
      expect(listener.lines).to eq(["--foo", "--the\ncat\nsat\non\nthe\nmat"])
      expect(subject.buffer).to eq("--bar\n")
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
      expect(listener.lines).to eq(["foo", "the -\ncat -\nsat -\non -\nthe -\nmat"])
      expect(subject.buffer).to eq("bar\n")
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
      expect(listener.lines).to eq(["foo -", "the\ncat\nsat\non\nthe\nmat -"])
      expect(subject.buffer).to eq("bar -\n")
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
      expect(listener.lines).to eq(["foo", "--- begin ---\nthe\ncat\nsat\non\nthe\nmat\n--- end ---"])
      expect(subject.buffer).to eq("bar\n")
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
      expect(listener.lines).to eq(["foo", "the\ncat\nsat\non\nthe\nmat"])
      expect(subject.buffer).to eq("bar\n")
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
      expect(listener.lines).to eq(["foo", "the\ncat\nsat\n--- begin ---\non\nthe\nmat"])
      expect(subject.buffer).to eq("bar\n")
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
      expect(listener.lines).to eq(["foo", "the\ncat\nsat\non\nthe", "mat", "--- end ---"])
      expect(subject.buffer).to eq("bar\n")
    end
  end
end
