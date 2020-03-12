RSpec.describe RTask do
  context '.run_each_with_index' do
    it 'index is passed to the block and do not return results' do
      tasks = RTask.run_each_with_index((1..4).to_a) do |item, index|
        expect(index).to_not be nil
        "task#{item} index#{index}"
        nil
      end
      expect(tasks.length).to eq 4
      expect(tasks.map(&:result)).to eq [nil, nil, nil, nil]
    end

    it 'index is passed to the block and return results' do
      tasks = RTask.run_each_with_index((1..4).to_a) do |item, index|
        "task#{item} index#{index}"
      end
      expect(tasks.length).to eq 4
      expect(tasks.map(&:result)).to eq ['task1 index0', 'task2 index1', 'task3 index2', 'task4 index3']
    end

    it 'not a blocking call' do
      start_time = Time.now
      RTask.run_each_with_index((1..4).to_a) do |item, index|
        "task#{item} index#{index}"
      end
      end_time = Time.now
      expect(1000.0 * (end_time - start_time)).to be < 1000
    end
  end
end