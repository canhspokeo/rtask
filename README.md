# RTask

RTask mimicks Task class in .NET to allow writing asynchronous code in ruby easier.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rtask'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rtask

## Usage
Run a task
```ruby
# this is a non-blocking call
task = RTask.run do
    # expensive code to run asynchronous
    'result of the task'
end

# other code

task.result    # This is blocking call. Return 'result of the task'
task.status    # 'completed'
```

Create and run a new task manually
```ruby
task = RTask::Task.new
    # expensive code to run asynchronous
    'result of the task'
end

# Can register a callback to be called when the task completes successfully.
# The task is passed the callback block automatically
task.oncomplete do |t|
    # code here.
    # if the callback registered after task completed, it's executed immediatedly.
end

# Can register a callback to be called when the task completes with error.
# The task is passed the callback block automatically
task.onfault do |t|
    # code here.
    # if the callback registered after task completed, it's executed immediatedly.
end

# task can be chained one after another.
# The antecedent task is passed to the next task block as parameter.
# task2 will be executed right after task completed regardless of error.
task2 = task.continue_with do |t|
    # code to run asynchronous
    t.result + ' result of the task2'
end

task.start      # Start running the task. This is a non-blocking call
task.result     # 'result of the task'
task2.result    # 'result of the task result of the task2'
```

Cancel a task
```ruby
task = RTask.run do
    sleep 10
end

# other work

task.cancel
task.status     # 'canceled'
```

Get exception thrown by the task
```ruby
task = RTask.run do
    raise 'error'
end

task.result     # nil
task.status     # 'faulted'
task.exception  # the exception thrown by the task
```

Wait for task(s) to finish
```ruby
tasks = []

tasks << RTask.run do
    sleep 2
    'task 1'
end

tasks << Rtask.run do
    sleep 1
    'task 2'
end

task = TRask.wait_any(tasks)    # wait for any task to finish and return the first finished task.
task.result     # 'taks 2'

RTask.wait_all(tasks)           # wait for all tasks to finish.
```

Run each item in the array with a task
```ruby
# without index
tasks = RTask.run_each([1, 2, 3]]) do |item|
    # code to execute on item
end

# with index
tasks = RTask.run_each_with_index(1, 2, 3) do |item, index|
    # code to execute on item
end

RTask.wait_all(tasks)
```

Create a completed task
```ruby
task = RTask.from_result('completed')

task = RTask.from_exception(StandardError.new('error message'))

task = RTask.from_canceled

```

Gets and sets parallel level
```ruby
pl = RTask.parallel_level   # gets number of tasks can be run at the same time.
                            # Default to the number of processors available.

RTask.parallel_level = 10   # sets number of tasks can be run at the same time.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/canhspokeo/rtask.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
