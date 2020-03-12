RSpec.describe RTask::TaskScheduler do
  before(:each) do
    RTask::TaskScheduler.class_variable_set :@@pending_tasks, []
  end

  let(:task) do
    RTask::Task.new do
      'task'
    end
  end

  context '.add_task' do
    before(:each) do
      allow(Thread).to receive(:new) {}
    end

    it 'add a task' do
      RTask::TaskScheduler.add_task(task)
      expect(RTask::TaskScheduler.pending_tasks_count).to be 1
    end

    it 'add multiple tasks' do
      task2 = RTask::Task.new do
        'task2'
      end
      RTask::TaskScheduler.add_task(task)
      RTask::TaskScheduler.add_task(task2)
      expect(RTask::TaskScheduler.pending_tasks_count).to be 2
    end

    it 'update task status to pending' do
      RTask::TaskScheduler.add_task(task)
      expect(task.status).to eq RTask::TaskStatus::PENDING
    end
  end

  context '.remove_task' do
    before(:each) do
      allow(Thread).to receive(:new) {}
    end

    it 'remove an existing task' do
      RTask::TaskScheduler.add_task(task)
      RTask::TaskScheduler.remove_task(task)
      expect(RTask::TaskScheduler.pending_tasks_count).to be 0
    end

    it 'remove non-existing task' do
      RTask::TaskScheduler.remove_task(task)
      expect(RTask::TaskScheduler.pending_tasks_count).to be 0
    end
  end

  context 'task monitor thread' do
    def task_executor_thread
      RTask::TaskScheduler.class_variable_get(:@@task_executor_thread)
    end

    it 'start when first task added' do
      RTask::TaskScheduler.add_task(task)
      expect(task_executor_thread).to_not be nil
    end

    it 'wakeup when subsequence tasks added' do
      RTask::TaskScheduler.add_task(task)
      task.result
      RTask::TaskScheduler.add_task(task)
      expect(task_executor_thread).to receive(:wakeup)
      task.result
    end

    # it 'wakeup when task finishes execution' do
    #   # ToDo:
    # end

    it 'stop when there is no pending tasks' do
      RTask::TaskScheduler.add_task(task)
      task.result
      sleep 0.5
      expect(task_executor_thread.status).to eq 'sleep'
    end

    it 'stop when parallel level reaches max' do
      # wait for task scheduler to drain all tasks.
      while RTask::TaskScheduler.pending_tasks_count > 0 ||
            RTask::TaskScheduler.running_tasks_count > 0
        sleep 0.1
      end

      (Etc.nprocessors + 1).times do
        task = RTask::Task.new do
          sleep 1
          'task'
        end
        RTask::TaskScheduler.add_task(task)
      end
      sleep 0.5
      expect(RTask::TaskScheduler.pending_tasks_count).to eq 1
      expect(RTask::TaskScheduler.running_tasks_count).to eq Etc.nprocessors
    end

    it 'remove pending task from queue for execution' do
      RTask::TaskScheduler.add_task(task)
      task.result
      expect(RTask::TaskScheduler.pending_tasks_count).to eq 0
    end

  end
end