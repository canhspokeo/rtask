require 'time'

module RTask
  # Class provides misc helper methods
  class TaskHelper
    # Check if wait time is up.
    # @param start_time: Start time to check against.
    # @param timeout: Timeout in milliseconds.
    # @return True if time is up; False otherwise.
    def self.time_up?(start_time, timeout)
      timeout.positive? && (Time.now - start_time) * 1000.0 >= timeout
    end
  end
end
