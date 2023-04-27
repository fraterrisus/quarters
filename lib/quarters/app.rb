# frozen_string_literal: true

require "gosu"
require_relative "./coin"

module Quarters
  class App < Gosu::Window

    BOARD_HEIGHT = 1024
    BOARD_WIDTH = 768

    def initialize(*args)
      super(BOARD_WIDTH, BOARD_HEIGHT, *args)
      self.caption = "Quarters"

      @bg = App.make_background
      @coin = Quarters::Coin.new(BOARD_WIDTH / 2, BOARD_HEIGHT - 100)
      @power = 0
      @display_power = 0

      @redraw = true
    end

    def self.make_background
    end

    def update
      if @coin.moving?
        @coin.update
        @redraw = true
      else
        old_power = @display_power.dup
        if Gosu::button_down?(Gosu::KB_Q)
          close
        elsif Gosu::button_down?(Gosu::MS_LEFT)
          @power = [100, @power+2].min
          @display_power = @power
        elsif Gosu::button_down?(Gosu::KB_R)
          @coin.warp(BOARD_WIDTH / 2, BOARD_HEIGHT - 100)
          @redraw = true
        elsif @power&.positive?
          @coin.kick(@power, Gosu.angle(mouse_x, mouse_y, @coin.x, @coin.y))
          @power = 0
        else
          @display_power = @power
        end
        @redraw ||= (old_power != @display_power)
      end
    end

    def needs_redraw?
      @redraw
    end

    def draw
      x_min = 10
      y_min = BOARD_HEIGHT - 20
      wid = 200
      hgt = 20
      Gosu.draw_rect(x_min, y_min, wid, hgt, Gosu::Color::RED, 1)
      Gosu.draw_rect(x_min+1, y_min+1, wid-2, hgt-2, Gosu::Color::BLACK, 2)
      Gosu.draw_rect(x_min+1, y_min+1, @display_power*2, hgt-2, Gosu::Color::RED, 3)
      Gosu::Image.from_text(@display_power, 20).draw(x_min, y_min, 3)

      @coin.draw
      @redraw = false
    end
  end
end
