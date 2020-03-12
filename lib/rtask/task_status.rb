# frozen_string_literal: true

module RTask
  module TaskStatus
    # The task has been initialized but has not yet been scheduled.
    CREATED = 'created'

    # The task has been scheduled for execution but has not yet begun executing.
    PENDING = 'pending'

    # The task is running but has not yet completed.
    RUNNING   = 'running'

    # The task completed execution successfully.
    COMPLETED = 'completed'

    # The task has been canceled.
    CANCELED = 'canceled'

    # The task completed due to an exception.
    FAULTED = 'faulted'
  end
end
