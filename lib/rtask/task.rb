require_relative 'task_status'
require_relative 'task_scheduler'
require_relative 'task_helper'

module RTask
  # The Task class represents a single operation that executes asynchronously.
  class Task
    # Internal status of the task.
    # _Client should not use this directly. Use +status+ instead._
    attr_accessor :__status

    # Internal result of the task.
    # _Client should not use this directly. Use +result+ instead._
    attr_accessor :__result

    # Exception raised during task execution.
    # _Client should not use this directly. Use +exception+ instead._
    attr_accessor :__exception

    # Id of the process that is executing the task.
    # _Client should not use this directly. Use +pid+ instead._
    attr_accessor :__pid

    attr_reader :name
    attr_reader :block
    attr_reader :block_params
    attr_reader :next_tasks
    attr_reader :oncomplete_block
    attr_reader :onfault_block

    def initialize(options = {}, &block)
      @block = block
      @block_params = options[:params] || []
      @name = options[:name] || "task #{object_id}"
      @__status = TaskStatus::CREATED

      # trap 'ctrl + c' or Interupt signal and kill the running process
      Signal.trap('INT') do
        Process.kill('QUIT', @__pid) if @__pid&.positive?
        exit
      end
    end

    # Gets status of the task. See +RTask::TaskStatus+ for all possible statuses.
    def status
      @__status
    end

    # Gets result of the task. This is a blocking call.
    # It also can be used to wait for the task to finish.
    # @param timeout: time to wait for result in milliseconds.
    # @return: result of the task.
    def result(timeout = -1)
      start_time = Time.now
      loop do
        return @__result if finished? || TaskHelper.time_up?(start_time, timeout)
      end
    end

    # Gets process id that executes the task.
    def pid
      @__pid
    end

    # Gets exception raised by the task.
    def exception
      @__exception
    end

    # Check if the task has ran to completion successfully.
    def completed?
      @__status == TaskStatus::COMPLETED
    end

    # Check if the task has been canceled.
    # It happens when user cancel the task by calling +cancel+ method.
    def canceled?
      @__status == TaskStatus::CANCELED
    end

    # Check if the task is faulted.
    # It happens when there is error/exception during task execution.
    def faulted?
      @__status == TaskStatus::FAULTED
    end

    # Check if the task has been finished either successfully or faulted or canceled.
    def finished?
      @__status == TaskStatus::COMPLETED ||
        @__status == TaskStatus::FAULTED ||
        @__status == TaskStatus::CANCELED
    end

    # Cancel the task after being scheduled for execution.
    def cancel
      @__status = TaskStatus::CANCELED
      TaskScheduler.remove_task(self)
      Process.kill('QUIT', @__pid) if @__pid&.positive?
    end

    # Start the task.
    # Use this method to run task created by +RTask::Task.new+.
    def start
      TaskScheduler.add_task(self)
    end

    # Register a callback block on task complete.
    # The block will be called right away if task has been completed.
    def oncomplete(&block)
      @oncomplete_block = block
      yield if completed?
    end

    # Register a callback block on task fault.
    # The block will be called right away if task has been faulted.
    def onfault(&block)
      @onfault_block = block
      yield if faulted?
    end

    # Creates a continuation that executes asynchronously when the target Task completes.
    # The antecedent task is passed to continuing task block.
    # @return: The continuing task.
    def continue_with(options = {}, &block)
      params = options[:params] || []
      params << self
      @next_tasks = [] if @next_tasks.nil?
      task = Task.new(options.merge(params: params), &block)
      @next_tasks << task
      task.start if completed? || faulted?
      task
    end

    # Execute the task.
    # _Client should not use this method directly.
    # Use +Task.run+ or +#start+ method instead._
    def __execute
      Thread.new do
        tasks = flatten_task_tree
        pipe_reader, pipe_writer = IO.pipe
        @__pid = execute_in_process(tasks, pipe_reader, pipe_writer)
        pipe_writer.close

        tasks.each do |task|
          task.__pid = @__pid
          task.__status = TaskStatus::RUNNING

          begin
            task.__result = Marshal.load(pipe_reader)
          rescue EOFError
            # do nothing
          end

          if task.__result == '__TASK_FINISHED_WITH_EXCEPTION__'
            faulted_result(task, Marshal.load(pipe_reader))
          else
            task.__result = nil if task.__result == '__TASK_FINISHED_NO_RESULT__' || task.canceled?
            task.__status = TaskStatus::COMPLETED unless task.canceled?
          end

          yield if block_given?

          case task.__status
          when TaskStatus::COMPLETED
            task.oncomplete_block&.call(task)
          when TaskStatus::FAULTED
            task.onfault_block&.call(task)
          end
        end

        pipe_reader.close
      end
    end

    private

    # Flatten the task tree breath first.
    # @return: Array of tasks.
    def flatten_task_tree
      tasks = [self]
      start_index = 0
      loop do
        end_index = tasks.length
        while start_index < end_index
          tasks.concat(tasks[start_index].next_tasks) unless tasks[start_index].next_tasks.nil?
          start_index += 1
        end
        break if end_index == tasks.length

        start_index = end_index
      end
      tasks
    end

    # Execute the task in a forked process.
    # @return: pid of the forked process
    def execute_in_process(tasks, pipe_reader, pipe_writer)
      Process.fork do
        tasks.each do |task|
          begin
            task.__status = TaskStatus::RUNNING
            pipe_reader.close
            result = task.block.call(*task.block_params)
            Marshal.dump(result || '__TASK_FINISHED_NO_RESULT__', pipe_writer)
            task.__result = result
            task.__status = TaskStatus::COMPLETED
          rescue StandardError => e
            begin
              Marshal.dump('__TASK_FINISHED_WITH_EXCEPTION__', pipe_writer)
              Marshal.dump(e, pipe_writer)
              faulted_result(task, e)
            rescue Errno::EPIPE
              # Broken pipe. Happen when the main process finishes before this process finishes.
            end
          end
        end
      end
    end

    # Sets task to faulted result.
    def faulted_result(task, exception)
      task.__result = nil
      task.__exception = exception
      task.__status = TaskStatus::FAULTED
    end

  end
end
