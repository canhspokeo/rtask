require 'etc'
require_relative 'task_status'

module RTask
  # Class to handle work of queueing, scheduling, and executing tasks.
  class TaskScheduler
    @@parallel_level = (ENV['PARALLEL_LEVEL'] || Etc.nprocessors).to_i

    @@task_executor_thread = nil
    @@pending_tasks = []
    @@pending_tasks_mutex = Mutex.new
    @@running_tasks_count = 0
    @@running_tasks_mutex = Mutex.new

    class << self
      # Queue a task for execution.
      # @param task: Task to be executed.
      def add_task(task)
        @@pending_tasks_mutex.synchronize do
          @@pending_tasks << task
          task.__status = TaskStatus::PENDING
          start_task_executor_thread
        end
      end

      # Remove a task from the queue therefore it will not be scheduled
      # for execution if not yet be done.
      # If the task is being executed, nothing will happen.
      # @param task: Task to be dequeued.
      def remove_task(task)
        @@pending_tasks_mutex.synchronize do
          @@pending_tasks.delete(task)
        end
      end

      # Gets number of pending tasks.
      def pending_tasks_count
        @@pending_tasks.length
      end

      # Gets number of running tasks.
      def running_tasks_count
        @@running_tasks_count
      end

      # Gets parallel level. Default to number of processors.
      def parallel_level
        @@parallel_level
      end

      # Sets parallel level.
      def parallel_level=(level)
        @@parallel_level = level if level.positive?
      end

      private

      # Start a thread that monitors the pending task queue and
      # execute task when resource available.
      def start_task_executor_thread
        unless @@task_executor_thread.nil?
          @@task_executor_thread.wakeup
          return
        end

        @@task_executor_thread = Thread.new do
          loop do
            if @@parallel_level > @@running_tasks_count
              task = nil
              @@pending_tasks_mutex.synchronize do
                task = @@pending_tasks.shift
              end

              if task.nil?
                Thread.stop
              else
                execute_task(task)
              end
            else
              Thread.stop
            end
          end
        end
      end

      # Execute the task
      def execute_task(task)
        @@running_tasks_mutex.synchronize { @@running_tasks_count += 1 }
        task.__execute do
          @@running_tasks_mutex.synchronize do
            @@running_tasks_count -= 1
            @@task_executor_thread.wakeup
          end
        end
      end
    end
    # end of self
  end
end
