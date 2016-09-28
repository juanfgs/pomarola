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
require 'json'

module Pomodoro

  class Pomodoro
    attr_accessor :label, :finished, :remaining_at_pause, :break_duration, :start
    
    def initialize(args)
      @finished = false
      if args[:hash].nil?
        @start = Time.now
        @label = args[:label]
        @break_duration = args[:break_duration]
        @end = @start + (args[:duration] + @break_duration)
      else
        @start = Time.new(args[:hash]["start"])
        @label = args[:hash]["label"]
        @break_duration = args[:hash]["break_duration"]
        @end = Time.new(args[:hash]["end"])
      end
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

    def to_json(args= {})
      hash = {}

      self.instance_variables.each do |var|
        hash[var_name] = self.instance_variable_get var
      end
      hash.to_json
    end

    def from_json string
      
      JSON.load(string).each do |var,val|
        self.instance_variable_set var,val
      end
    end

    
    
  end
end
  
