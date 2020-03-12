RSpec.describe RTask do
  context '.run' do
    it 'a task does not return result' do
      task = RTask.run do
        nil
      end
      expect(task.result).to be nil
      expect(task.status).to be RTask::TaskStatus::COMPLETED
      expect(task.exception).to be nil
    end

    it 'a task return result' do
      task = RTask.run do
        'task'
      end
      expect(task.result).to eq 'task'
      expect(task.status).to be RTask::TaskStatus::COMPLETED
      expect(task.exception).to be nil
    end

    it 'a task raise exception' do
      task = RTask.run do
        raise 'exception in task block'
      end
      expect(task.result).to be nil
      expect(task.status).to be RTask::TaskStatus::FAULTED
      expect(task.exception).to_not be nil
    end

    it 'multiple tasks mixed results' do
      task1 = RTask.run do
        nil
      end
      task2 = RTask.run do
        'task'
      end
      task3 = RTask.run do
        raise 'exception in task block'
      end

      expect(task1.result).to be nil
      expect(task1.status).to be RTask::TaskStatus::COMPLETED
      expect(task1.exception).to be nil

      expect(task2.result).to eq 'task'
      expect(task2.status).to be RTask::TaskStatus::COMPLETED
      expect(task2.exception).to be nil

      expect(task3.result).to be nil
      expect(task3.status).to be RTask::TaskStatus::FAULTED
      expect(task3.exception.message).to eq 'exception in task block'
    end

    it 'is not a blocking call' do
      start_time = Time.now
      RTask.run do
        sleep 10
      end
      end_time = Time.now
      expect(1000.0 * (end_time - start_time)).to be < 1000
    end
  end
end