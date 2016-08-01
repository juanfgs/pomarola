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
    @ui.add_from_file "ui/tomate.ui"

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
    @start_pomodoro_id = @start_button.signal_connect "clicked" do |button|
      start_pomodoro(button)
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
    
    change_play_status( :pause)
    
    # execute in the GLib loop each 0.5 seconds
    @loop = GLib::Timeout.add_seconds(0.5) do
      
      
      remaining = @current_pomodoro.time_remaining
 
      work_time_remaining = @current_pomodoro.work_time_remaining
      
      if !(remaining.to_i <= 0) && @start_button.label == Gtk::Stock::MEDIA_PAUSE
        
        @timer.set_text work_time_remaining.strftime("%M:%S")
        
        if remaining.to_i < @break_length && @break_length - 1 < remaining.to_i #we notify the user this cycle is about to end
          Notify.notify "Time to rest", "This cycle is over, time for some rest"
        end
        
        if remaining.to_i < 60 && 59 < remaining.to_i #we notify the user this cycle is about to end
          Notify.notify "Your break is about to finish", "Get ready for the next cycle"
        end
        
        if (remaining.to_i <= 0) #We notify the user and save the pomodoro
          @current_pomodoro = Pomodoro::Pomodoro.new()
          @pomodoro_count++
                         
          update_log(@current_pomodoro)
        end
        true # continue in the loop
      else
        false # stop the loop
      end
    end
  end

  #
  # updates the log list
  #
  def update_log(pomodoro)

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
    @paused = true
    @current_pomodoro.pause

    change_play_status(:start)
  end
  
end

Gtk.init
pomarola = Pomarola.new
Gtk.main
