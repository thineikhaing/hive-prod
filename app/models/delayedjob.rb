
module Delayed
  class Job < ActiveRecord::Base
    self.table_name = "delayed_jobs"
    attr_accessible :priority, :run_at, :queue, :priority, :attempts, :handler , :last_error, :run_at,
                    :failed_at, :locked_at, :locked_by  # ActiveRecord instance
  end
end