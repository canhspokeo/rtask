RSpec.describe RTask do
  context '.wait_all' do
    it 'without timeout' do
      tasks = []
      tasks << RTask.run do
        'task1'
      end
      tasks << RTask.run do
        'task2'
      end
      result = RTask.wait_all(tasks)
      expect(result).to be true
      expect(tasks.map(&:status)).to eq [RTask::TaskStatus::COMPLETED, RTask::TaskStatus::COMPLETED]
    end

    it 'with timeout without task finishes' do
      task1 = RTask.run do
        sleep 10
        'task1'
      end
      task2 = RTask.run do
        sleep 10
        'task2'
      end
      result = RTask.wait_all(task1, task2, timeout: 1000)
      expect(result).to be false
      expect(task1.status).to_not eq RTask::TaskStatus::COMPLETED
      expect(task2.status).to_not eq RTask::TaskStatus::COMPLETED
    end

    it 'with timeout with task finishes' do
      task1 = RTask.run do
        'task1'
      end
      task2 = RTask.run do
        sleep 10
        'task2'
      end
      result = RTask.wait_all(task1, task2, timeout: 1000)
      expect(result).to be false
      expect(task1.status).to eq RTask::TaskStatus::COMPLETED
      expect(task2.status).to_not eq RTask::TaskStatus::COMPLETED
    end
  end
end