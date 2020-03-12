require_relative 'rtask/version'
require_relative 'rtask/task_status'
require_relative 'rtask/task_helper'
require_relative 'rtask/task_scheduler'
require_relative 'rtask/task'

# Module provides capability of writing concurrent and asynchronous code.
# The main type is +Task+ which represents an asynchronous operation.
module RTask
  class << self
    # Run a new task asynchronously.
    # The result of the block is returned via +task.result+ after task finishes execution.
    # It is a non-blocking call.
    # @param options: Options to run the task.
    #                 params: Array of parameters for the block
    # @return: An instance of +Task+ class.
    def run(options = {}, &block)
      task = Task.new(options, &block)
      TaskScheduler.add_task(task)
      task
    end

    # Run each item asynchronously.
    # The result of the block is returned via +task.result+ after task finishes execution.
    # It is a non-blocking call.
    # @param items: Array of items to be run.
    # @param block: Block of code to run with each item
    # @return: Array of tasks
    def run_each(items, options = {}, &block)
      return if items.nil?

      tasks = []
      items.each.with_index do |item, index|
        params = [item]
        params << index if options[:with_index] == true
        opts = options.merge(params: params)
        tasks << run(opts, &block)
      end
      tasks
    end

    # Run each item with index asynchronously.
    # The result of the block is returned via +task.result+ after task finishes execution.
    # It is a non-blocking call.
    # @param items: Array of items to be run.
    # @param block: Block of code to run with each item with index
    # @return: Array of tasks.
    def run_each_with_index(items, options = {}, &block)
      run_each(items, options.merge(with_index: true), &block)
    end

    # Wait all of the provided tasks to complete.
    # @param tasks: List or array of tasks to wait for.
    # @param timeout: time to wait in milliseconds.
    # @return: true if all tasks completed; false if timeout.
    def wait_all(*tasks, timeout: -1)
      return if tasks.nil? || tasks.length.zero?

      tasks = *tasks[0] if tasks.length == 1 && tasks[0].class == Array
      start_time = Time.now
      loop do
        count = 0
        tasks.each do |task|
          count += 1 if task.completed? || task.canceled? || task.faulted?
        end

        return true if count == tasks.length
        return false if TaskHelper.time_up?(start_time, timeout)
      end
    end

    # Wait for any of the provided tasks to complete.
    # @param tasks: List or array of tasks to wait for.
    # @param timeout: time to wait in milliseconds.
    # @return: The completed task; nil if timeout
    def wait_any(*tasks, timeout: -1)
      return if tasks.nil? || tasks.length.zero?

      tasks = *tasks[0] if tasks.length == 1 && tasks[0].class == Array
      start_time = Time.now
      loop do
        tasks.each do |task|
          return task if task.completed? || task.canceled? || task.faulted?
        end

        return if TaskHelper.time_up?(start_time, timeout)
      end
    end

    # Create a task that's completed successfully with the specified result.
    # @return: A completed task.
    def from_result(result)
      task = Task.new
      task.__status = TaskStatus::COMPLETED
      task.__result = result
      task
    end

    # Create a task that's completed with the specified exception.
    # @return: An faulted task.
    def from_exception(exception)
      task = Task.new
      task.__status = TaskStatus::FAULTED
      task.__exception = exception
      task
    end

    # Create a task that's been canceled.
    # @return: A canceled task.
    def from_canceled
      task = Task.new
      task.__status = TaskStatus::CANCELED
      task
    end

    # Gets parallel level. Default to number of processors.
    def parallel_level
      TaskScheduler.parallel_level
    end

    # Sets parallel level.
    def parallel_level=(level)
      TaskScheduler.parallel_level = level
    end

  end # end of class << self
end
