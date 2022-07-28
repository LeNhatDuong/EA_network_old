class HardWorker
  include Sidekiq::Worker

  def perform
    system("/bin/bash -l -c '#{File.join(Rails.root, 'script', 'speed_test_client')} \'#{CONFIGS['host']}\' manual'")
  end
end
