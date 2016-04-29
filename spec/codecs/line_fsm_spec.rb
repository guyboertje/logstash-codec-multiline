require "logstash/codecs/line_fsm"
require_relative "../supports/helpers.rb"

describe LogStash::LineFsm do
  let(:listener) { Mlc::AcceptTracer.new() }

  let(:endchar)   { "^" }
  let(:beginchar) { "~" }

  before { lines.each {|l| subject.accept(l) } }

  describe "specify begin and end chars" do
    subject { described_class.new(listener, endchar, beginchar) }

    context "when lines are: ''" do
      let(:lines) do
        [""]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq([])
        expect(subject.buffer).to be_nil
      end
    end

    context "when lines are: '~foo^~bar^~baz^'" do
      let(:lines) do
        ["~foo^~bar^~baz^"]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq(["foo", "bar", "baz"])
        expect(subject.buffer).to eq("")
      end
    end

    context "when lines are: '~~foo^~bar^^~baz^'" do
      let(:lines) do
        ["~~foo^~bar^^~baz^"]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq(["foo", "bar", "baz"])
        expect(subject.buffer).to eq("")
      end
    end
  end

  describe "specify end char" do
    subject { described_class.new(listener, endchar) }

    context "when lines are: ''" do
      let(:lines) do
        [""]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq([])
        expect(subject.buffer).to be_nil
      end
    end

    context "when lines are: '^^^foo^^bar^baz'" do
      let(:lines) do
        ["^^^foo^^bar^baz"]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq(["foo", "bar"])
        expect(subject.buffer).to eq("baz")
      end
    end

    context "when lines are: 'foo\\nbar\\nbaz\\n'" do
      let(:endchar)   { "\n" }
      let(:lines) do
        ["foo\nbar\nbaz\n"]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq(["foo", "bar", "baz"])
        expect(subject.buffer).to eq("")
      end
    end

    context "when lines are: '^^^foo^bar^baz^^^^'" do
      let(:lines) do
        ["^^^foo^bar^baz^^^^"]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq(["foo", "bar", "baz"])
        expect(subject.buffer).to eq("")
      end
    end

    context "when lines are: 'foo^bar^baz'" do
      let(:lines) do
        ["foo^bar^baz"]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq(["foo", "bar"])
        expect(subject.buffer).to eq("baz")
      end
    end

    context "when lines are: 'foo^bar^ba' and 'z^qux^nof" do
      let(:lines) do
        ["foo^bar^ba", "z^qux^nof^^"]
      end

      it "buffers and flushes correctly" do
        expect(listener.lines).to eq(["foo", "bar", "baz", "qux", "nof"])
        expect(subject.buffer).to eq("")
      end
    end
  end
end
