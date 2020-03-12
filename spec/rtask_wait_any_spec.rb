RSpec.describe RTask do
  context '.wait_any' do
    it 'without timeout' do
      tasks = []
      tasks << RTask.run do
        'task1'
      end
      tasks << RTask.run do
        sleep 10
        'task2'
      end
      task = RTask.wait_any(tasks)
      expect(task.status).to eq RTask::TaskStatus::COMPLETED
      expect(task).to be tasks[0]
    end

    it 'with timeout no tasks finish' do
      task1 = RTask.run do
        sleep 10
        'task1'
      end
      task2 = RTask.run do
        sleep 10
        'task2'
      end
      task = RTask.wait_any(task1, task2, timeout: 1000)
      expect(task).to be nil
    end

    it 'with timeout with task finishes' do
      task1 = RTask.run do
        'task1'
      end
      task2 = RTask.run do
        sleep 10
        'task2'
      end
      task = RTask.wait_any(task1, task2, timeout: 1000)
      expect(task.status).to eq RTask::TaskStatus::COMPLETED
      expect(task).to be task1
    end

  end
end