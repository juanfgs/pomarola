# coding: utf-8
#      This file is part of Pomarola.

#    Pomarola is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Pomarola is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Pomarola.  If not, see <http://www.gnu.org/licenses/>.

# Author: Juan Francisco Giménez Silva 

module Pomodoro

  class Pomodoro
    attr_accessor :label, :finished, :remaining_at_pause, :break_duration, :start
    
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
  
