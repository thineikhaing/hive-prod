class MyTestJob  < Struct.new(:topic_id)

  def perform
    p "perform use delay job"
    Topic.test_delay_job(topic_id)

  end

  def display_name
    return "my test delay job"
  end

  def error(job, exception)
    p 'fail to run the job'
  end


end
