RSpec.describe RTask do
  context '.run_each' do
    it 'tasks do not return results' do
      len = Etc.nprocessors - 1
      tasks = RTask.run_each((1..len).to_a) do |item|
        sleep 0.1
        "task#{item}"
        nil
      end
      expected_results = Array.new(len) { nil }
      expect(tasks.map(&:result)).to eq expected_results
    end

    it 'items in a short array' do
      len = Etc.nprocessors - 1
      tasks = RTask.run_each((1..len).to_a) do |item|
        sleep 0.1
        "task#{item}"
      end
      expected_results = Array.new(len) { |i| "task#{i + 1}" }
      expect(tasks.map(&:result)).to eq expected_results
    end

    it 'items in a long array' do
      len = 2 * Etc.nprocessors
      tasks = RTask.run_each((1..len).to_a) do |item|
        sleep 0.1
        "task#{item}"
      end
      expected_results = Array.new(len) { |i| "task#{i + 1}" }
      expect(tasks.map(&:result)).to eq expected_results
    end

    it 'is a non-blocking call' do
      start_time = Time.now
      RTask.run_each((1..2).to_a) do |item|
        sleep 0.1
        "task#{item}"
      end
      end_time = Time.now
      expect(1000.0 * (end_time - start_time)).to be < 1000
    end
  end
end
