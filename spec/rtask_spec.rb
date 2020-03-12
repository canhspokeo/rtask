RSpec.describe RTask do
  it "has a version number" do
    expect(RTask::VERSION).not_to be nil
  end

  context '.from_result' do
    it 'return a completed task' do
      task = RTask.from_result('completed task')
      expect(task.status).to eq RTask::TaskStatus::COMPLETED
      expect(task.result).to eq 'completed task'
    end
  end

  context '.from_exception' do
    it 'return a faulted task' do
      task = RTask.from_exception(StandardError.new('error message'))
      expect(task.status).to eq RTask::TaskStatus::FAULTED
      expect(task.exception.message).to eq 'error message'
    end
  end

  context '.from_canceled' do
    it 'return a canceled task' do
      task = RTask.from_canceled
      expect(task.status).to eq RTask::TaskStatus::CANCELED
    end
  end
end
