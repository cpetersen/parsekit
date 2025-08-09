# frozen_string_literal: true

RSpec.shared_examples "a parser method" do |method_name|
  it "returns a string" do
    result = subject.send(method_name, valid_input)
    expect(result).to be_a(String)
  end

  it "raises ArgumentError for empty input" do
    expect { subject.send(method_name, empty_input) }.to raise_error(ArgumentError)
  end

  it "handles unicode input" do
    result = subject.send(method_name, unicode_input)
    expect(result).to be_a(String)
  end
end

RSpec.shared_examples "thread safe operation" do |method_name|
  it "is thread safe" do
    results = Concurrent::Array.new
    threads = 10.times.map do |i|
      Thread.new do
        result = subject.send(method_name, "thread_#{i}")
        results << result
      end
    end
    threads.each(&:join)
    
    expect(results.size).to eq(10)
    expect(results).to all(be_a(String))
  end
end

RSpec.shared_examples "configuration aware" do
  it "respects strict_mode configuration" do
    strict_subject = described_class.new(strict_mode: true)
    expect(strict_subject.strict_mode?).to be true
    
    regular_subject = described_class.new(strict_mode: false)
    expect(regular_subject.strict_mode?).to be false
  end

  it "maintains configuration after operations" do
    configured_subject = described_class.new(
      strict_mode: true,
      max_depth: 75,
      encoding: "ASCII"
    )
    
    # Perform operation
    configured_subject.parse("test")
    
    # Check configuration unchanged
    config = configured_subject.config
    expect(config[:strict_mode]).to be true
    expect(config[:max_depth]).to eq(75)
    expect(config[:encoding]).to eq("ASCII")
  end
end