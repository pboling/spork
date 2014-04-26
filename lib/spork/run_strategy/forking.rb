class Spork::RunStrategy::Forking < Spork::RunStrategy
  def self.available?
    Kernel.respond_to?(:fork)
  end

  def is_parallel?
    @is_parallel
  end

  def child_forker(argv, stderr, stdout)
    ::Spork::Forker.new do
      $stdout, $stderr = stdout, stderr
      load test_framework.helper_file
      Spork.exec_each_run
      result = test_framework.run_tests(argv, stderr, stdout)
      Spork.exec_after_each_run
      result
    end
  end

  def run(argv, stderr, stdout)
    @is_parallel = argv.include?('--test_env_number')
    if is_parallel?

      # We are running *with* parallel_tests
      # Not aborting if running because we expect more than one to be running.
      #abort if running?

      @children ||= []
      @children << (child = child_forker(argv, stderr, stdout))
      @children = @children.reject {|c| c == child}
      child.result

    else

      # We are running without parallel_tests
      abort if child_running?

      @child = child_forker(argv, stderr, stdout)
      @child.result

    end
  end

  def abort
    if is_parallel?
      @children && @children.each {|child| child.abort}
    else
      @child && @child.abort
    end
  end

  def preload
    test_framework.preload
  end

  def running?
    if is_parallel?
      @children && @children.detect {|child| child.running?}
    else
      child_running?
    end
  end

  def child_running?
    @child && @child.running?
  end

  def assert_ready!
    raise RuntimeError, "This process hasn't loaded the environment yet by loading the prefork block" unless Spork.using_spork?
  end
end
