#!/usr/bin/env ruby

# Pomarola is a Ruby/GTK based task manager to work with the pomodoro technique
# It allows not only to track time in Pomodoro's style but also to keep a work log
# of previous pomodoros.

# Author:: 

require "gtk3"
require "glib2"
require "notify"
require "pp"
require_relative "lib/pomodoro"


class Pomarola
  attr_accessor :current_pomodoro, :pomodoros, :loop
  def initialize
    @stopped_pomodoro = true
    @pomodoro_count = 0
    @pomodoro_length = 1500
    @break_length = 300
    @long_break_multiplier = 4
    
    @ui = Gtk::Builder.new
    @ui.add_from_file "ui/pomarola.ui"
    
    #connect all handlers except the start_pomodoro 
    @ui.connect_signals do |handler|
      unless handler == "start_pomodoro"
        method(handler)
      end
    end

    #Get the objects from the glade file 
    @timer = @ui.get_object "pomodoro_timer"
    @main_window = @ui.get_object "main_window"
    @start_button = @ui.get_object "start_pomodoro"
    @past_pomodoros_list = @ui.get_object "past_pomodoros_list"
    @past_pomodoros_view = @ui.get_object "past_pomodoros_view"
    @pomodoro_renderer_label = Gtk::CellRendererText.new
    @pomodoro_renderer_label.set_property 'editable', true
    @pomodoro_renderer = Gtk::CellRendererText.new
    @past_pomodoros_view.model = @past_pomodoros_list

    @cols = [
      Gtk::TreeViewColumn.new("Name", @pomodoro_renderer_label, :text => 0),
      Gtk::TreeViewColumn.new("Time Rested", @pomodoro_renderer, :text => 1),
    ]
    
    @cols.each do |col|
      @past_pomodoros_view.append_column col
    end
    
    @start_pomodoro_id = @start_button.signal_connect "clicked" do |button|
      start_pomodoro(button)
    end
    
    @pomodoro_renderer_label.signal_connect "edited" do |widget,row,new_text|
      update_cell(widget,row,new_text)
    end
    
    @main_window.signal_connect "destroy" do
      Gtk.main_quit
    end
    @main_window.show_all
  end


  # This handler is triggered by pressing the start button
  # it should start the countdown for the pomodoro to expire
  #
  # ==== Attributes
  # * +widget+ - GtkButton : the originating widget
  #
  
  def start_pomodoro(widget)
    if @stopped_pomodoro #If the pomodoro is returning from stopped, we create a new pomodoro
      @stopped_pomodoro = false
      @current_pomodoro = Pomodoro::Pomodoro.new(@pomodoro_length, @break_length)
    else
      @current_pomodoro.resume #Recalculate current pomodoro status
    end
    
    @break_notify, @end_notify = false
    change_play_status(:pause)
    
    # execute in the GLib loop each 0.5 second
    @loop = GLib::Timeout.add_seconds(0.5) do
      
      remaining = @current_pomodoro.time_remaining
      
      if !(remaining.to_i <= 0) && @start_button.label == Gtk::Stock::MEDIA_PAUSE
        if remaining.to_i <= @current_pomodoro.break_duration  #we notify the user this cycle is about to end
          
          @timer.set_text @current_pomodoro.time_remaining.strftime("(Break) %M:%S")
          
          if !@break_notify
            Notify.notify "Time to rest", "This cycle is over, time for some rest"
            @break_notify = true
          end
        else
          @timer.set_text @current_pomodoro.work_time_remaining.strftime("%M:%S")
        end
        
        if remaining.to_i <= 2 && !@end_notify  #we notify the user this cycle is about to end
          Notify.notify "Your break is about to finish", "Get ready for the next cycle"
          @end_notify = true
        end
        
        true # continue in the loop
        
      elsif !@stopped_pomodoro &&  (remaining.to_i <= 0) 
        update_log(@current_pomodoro)
        if @pomodoro_count == 3 #check whether is time for the long break 
          @current_pomodoro = Pomodoro::Pomodoro.new(@pomodoro_length, @break_length * @long_break_multiplier)
          @pomodoro_count = 0
        else
          @current_pomodoro = Pomodoro::Pomodoro.new(@pomodoro_length, @break_length)
          @pomodoro_count += 1
        end
        @break_notify,@end_notify = false
        true
      else
        false # stop the loop
      end
    end
  end
  #
  # updates the log list
  #
  def update_log(pomodoro)
    diff = pomodoro.start - pomodoro.break_duration
    iter = @past_pomodoros_list.append()
    iter[0] = '(Insert Label here)'
    iter[1] = diff.strftime("%M:%S")
  end

  #
  # This method changes the images on the play button to the paused status
  # more importantly it disconnects the current handler attached to the clicked event
  # ===== Attributes
  # +status+ - symbol
  # ===== Examples
  # change_play_status(:start)
  # change_play_status(:pause)
  
  def change_play_status(status)
      
    case status
    when :start
      @start_button.label = Gtk::Stock::MEDIA_PLAY
      @start_button.set_image Gtk::Image.new( :stock =>  Gtk::Stock::MEDIA_PLAY)
 
      @start_button.signal_handler_disconnect @start_pomodoro_id
      @start_pomodoro_id = @start_button.signal_connect "clicked" do |button|
        start_pomodoro(button)
      end
    when :pause
      @start_button.label = Gtk::Stock::MEDIA_PAUSE
      @start_button.set_image Gtk::Image.new( :stock =>  Gtk::Stock::MEDIA_PAUSE)
      @start_button.signal_handler_disconnect @start_pomodoro_id
      @start_pomodoro_id = @start_button.signal_connect "clicked" do |button|
        pause_pomodoro(button)
      end
    end
  end
  
  # Stops the pomodoro timer
  def stop_pomodoro(button)
    @stopped_pomodoro = true
    @timer.label = "00:00"
    change_play_status(:start)
  end

  # Pauses the current pomodoro
  def pause_pomodoro(button)
    @current_pomodoro.pause
    change_play_status(:start)
  end

  def update_cell(cell,row,new_text )
    iter = @past_pomodoros_list.get_iter(row)
    iter[0] = new_text
  end
  
end

Gtk.init
pomarola = Pomarola.new
Gtk.main
