module Pomodoro

  class Pomodoro
    attr_accessor :label, :finished, :remaining_at_pause, :break_duration
    
    def initialize(duration,break_duration)
      @finished = false
      @start = Time.now
      @break_duration = break_duration
      
      @end = @start + (duration + @break_duration)
    end

    def time_remaining
      @end - Time.now.to_i
    end

    def work_time_remaining
      @end - (Time.now.to_i + @break_duration)
    end
    
    def pause
      @remaining_at_pause = time_remaining
    end

    def resume
      @end = Time.now + @remaining_at_pause.to_i
    end 

  end
end
  
