RSpec.describe RTask::Task do
  context '.name' do
    it 'default name' do
      task = RTask::Task.new do
        'task'
      end
      expect(task.name).to match(/task \d+/)
    end

    it 'custom name' do
      task = RTask::Task.new(name: 'task 1') do
        'task'
      end
      expect(task.name).to eq 'task 1'
    end
  end

  context '.start' do
    it 'a task does not return result' do
      task = RTask::Task.new do
        'task'
      end
      task.start
      task.result
      expect(task.status).to be RTask::TaskStatus::COMPLETED
    end

    it 'a task return result' do
      task = RTask::Task.new do
        'task'
      end
      task.start
      expect(task.result).to eq 'task'
    end
  end

  context '.result' do
    it 'without timeout' do
      task = RTask::Task.new do
        'task'
      end
      task.start
      expect(task.result).to eq 'task'
    end

    it 'with timeout no result' do
      task = RTask::Task.new do
        sleep 10
        'task'
      end
      task.start
      expect(task.result(1000)).to be nil
    end

    it 'with timeout with result' do
      task = RTask::Task.new do
        'task'
      end
      task.start
      expect(task.result(1000)).to eq 'task'
    end
  end

  context '.cancel' do
    it 'a task that is running' do
      task = RTask::Task.new do
        sleep 10
        'task'
      end
      task.start
      while task.status != RTask::TaskStatus::RUNNING
        # wait for task to be executed
      end
      pid = task.pid
      task.cancel
      expect(task.status).to be RTask::TaskStatus::CANCELED
      sleep 1 # wait some time for the process to shut down
      expect { Process.getpgid(pid) }.to raise_error Errno::ESRCH
    end

    it 'a task that has been completed' do
      task = RTask::Task.new do
        'task'
      end
      task.start
      task.result
      task.cancel
      expect(task.status).to be RTask::TaskStatus::CANCELED
      expect(task.result).to eq 'task'
    end

    it 'a task that is not yet scheduled' do
      task = RTask::Task.new do
        'task'
      end
      task.cancel
      expect(task.status).to be RTask::TaskStatus::CANCELED
      expect(task.result).to be nil
    end
  end

  context '.oncomplete' do
    it 'call oncomplete callback when complete' do
      task = RTask::Task.new do
        'task'
      end
      oncomplete_block_called = false
      task.oncomplete do
        oncomplete_block_called = true
      end
      task.start
      task.result
      expect(oncomplete_block_called).to be true
    end

    it 'call oncomplete callback right away when register after completed' do
      task = RTask::Task.new do
        'task'
      end
      task.start
      task.result
      oncomplete_block_called = false
      task.oncomplete do
        oncomplete_block_called = true
      end
      expect(oncomplete_block_called).to be true
    end

    it 'should not call onfault callback on complete' do
      task = RTask::Task.new do
        'task'
      end
      onfault_block_called = false
      task.onfault do
        onfault_block_called = true
      end
      task.start
      task.result
      expect(onfault_block_called).to be false
    end

    it 'pass the task itself to oncomplete block' do
      task = RTask::Task.new do
        'task'
      end
      task_result_oncomplete = nil
      task.oncomplete do |t|
        task_result_oncomplete = t.result
      end
      task.start
      task.result
      expect(task_result_oncomplete).to eq 'task'
    end
  end

  context '.onfault' do
    it 'call onfault callback when fault' do
      task = RTask::Task.new do
        raise 'error'
      end
      onfault_block_called = false
      task.onfault do
        onfault_block_called = true
      end
      task.start
      task.result
      expect(onfault_block_called).to be true
    end

    it 'call onfault callback right away when register after faulted' do
      task = RTask::Task.new do
        raise 'error'
      end
      task.start
      task.result
      onfault_block_called = false
      task.onfault do
        onfault_block_called = true
      end
      expect(onfault_block_called).to be true
    end

    it 'should not call oncomplete callback when fault' do
      task = RTask::Task.new do
        raise 'error'
      end
      oncomplete_block_called = false
      task.oncomplete do
        oncomplete_block_called = true
      end
      task.start
      task.result
      expect(oncomplete_block_called).to be false
    end

    it 'pass the task itself to onfault block' do
      task = RTask::Task.new do
        raise 'error'
      end
      task_exception_onfault = nil
      task.onfault do |t|
        task_exception_onfault = t.exception
      end
      task.start
      task.result
      expect(task_exception_onfault.message).to eq 'error'
    end
  end

  context '.continue_with' do
    let(:task_1) do
      RTask::Task.new do
        'task_1'
      end
    end

    it 'both tasks finish' do
      task_1_1 = task_1.continue_with do
        'task_1_1'
      end
      task_1.start

      expect(task_1.result).to eq 'task_1'
      expect(task_1_1.result).to eq 'task_1_1'
    end

    it 'both tasks are executed by one process' do
      task_1_1 = task_1.continue_with do
        'task_1_1'
      end
      task_1.start

      task_1.result
      task_1_1.result
      expect(task_1.pid).to eq task_1_1.pid
    end

    it 'antecedent task is passed to continuing task block' do
      task_1_1 = task_1.continue_with do |ant_task|
        ant_task.result + '+' + 'task_1_1'
      end
      task_1.start

      expect(task_1_1.result).to eq 'task_1+task_1_1'
    end

    it 'start on different process when antecedent task completed already' do
      task_1.start
      task_1.result
      task_1_1 = task_1.continue_with do |ant_task|
        ant_task.result + '+' + 'task_1_1'
      end
      task_1_1.result
      expect(task_1.pid).to_not eq task_1_1.pid
    end

    it 'start on different process when antecedent task faulted already' do
      task_1 = RTask::Task.new do
        raise 'task_1 error'
      end
      task_1.start
      task_1.result

      task_1_1 = task_1.continue_with do |ant_task|
        ant_task.result + '+' + 'task_1_1'
      end
      task_1_1.result
      expect(task_1.pid).to_not eq task_1_1.pid
    end

    it 'tasks finish in correct order' do
      task_1 = RTask::Task.new do
        sleep 0.1
        Time.now
      end
      task_1_1 = task_1.continue_with do
        sleep 0.1
        Time.now
      end
      task_1_2 = task_1.continue_with do
        sleep 0.1
        Time.now
      end
      task_1_1_1 = task_1_1.continue_with do
        sleep 0.1
        Time.now
      end
      task_1_2_1 = task_1_2.continue_with do
        sleep 0.1
        Time.now
      end

      task_1.start

      expect(task_1.result).to be < task_1_1.result
      expect(task_1.result).to be < task_1_2.result
      expect(task_1_1.result).to be < task_1_2.result
      expect(task_1_1.result).to be < task_1_1_1.result
      expect(task_1_2.result).to be < task_1_2_1.result
      expect(task_1_1_1.result).to be < task_1_2_1.result
    end
  end
end