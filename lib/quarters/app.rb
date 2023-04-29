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
      @coins = [Quarters::Coin.new, Quarters::Coin.new, Quarters::Coin.new]
      @power = 0

      reset_coins
    end

    def self.make_background; end

    def update
      if @state == :moving
        if @coins.any?(&:moving?)
          10.times do
            @coins.each(&:step)
            check_for_collisions
          end
          @redraw = true
          return
        else
          @state = :play
          @power = 0
          @allowed = [0, 1, 2].reject { |x| x == @highlight }
          @highlight = nil
          @redraw = true
        end
      end

      if Gosu::button_down?(Gosu::KB_TAB)
        unless @tab_pushed
          select_next_coin
          return
        end
      else
        @tab_pushed = false
      end

      if Gosu::button_down?(Gosu::KB_Q)
        close
      elsif Gosu::button_down?(Gosu::MS_LEFT)
        if @state == :serve
          serve
        elsif @highlight
          @power = [100, @power+2].min || 0
          @redraw = true
        end
      elsif Gosu::button_down?(Gosu::KB_R)
        reset_coins
        @redraw = true
      elsif @state == :play && @power.positive?
        flick_coin
      end
    end

    def needs_redraw?
      @redraw
    end

    def draw
      mid = BOARD_WIDTH / 2
      Gosu.draw_rect(10, 50, BOARD_WIDTH - 20, BOARD_HEIGHT - 90, Gosu::Color::WHITE, 1)
      Gosu.draw_rect(mid - 80, 10, 160, 45, Gosu::Color::WHITE, 1)
      Gosu.draw_rect(15, 55, BOARD_WIDTH - 30, BOARD_HEIGHT - 100, 0xff008800, 1)
      Gosu.draw_rect(mid - 75, 15, 150, 39, 0xff008800, 1)

      x_min = 20
      y_min = BOARD_HEIGHT - 30
      wid = 200
      hgt = 20
      Gosu.draw_rect(x_min, y_min, wid, hgt, Gosu::Color::RED, 1)
      Gosu.draw_rect(x_min+1, y_min+1, wid-2, hgt-2, Gosu::Color::BLACK, 2)
      Gosu.draw_rect(x_min+1, y_min+1, @power*2, hgt-2, Gosu::Color::RED, 3)
      Gosu::Image.from_text(@power, 20).draw(x_min, y_min, 3)

      @coins.each_with_index do |c, i|
        c.draw(i == @highlight ? 1.0 : 0.75)
        c.draw(i == @highlight ? 1.0 : 0.75)
      end
      @redraw = false
    end

    private

    def select_next_coin
      current = @allowed.index(@highlight) || -1
      new = (current + 1) % @allowed.size
      @highlight = @allowed[new]
      @tab_pushed = true
      @redraw = true
    end

    def flick_coin
      coin = @coins[@highlight]
      coin.kick(@power, Gosu.angle(mouse_x, mouse_y, coin.x, coin.y))
      @state = :moving
    end

    def check_for_collisions
      return false if @highlight.nil?

      [0, 1, 2].each do |i|
        next if i == @highlight

        if coins_overlap?(@highlight, i)
          Quaters::Physics.calculate_collision(@coins[@highlight], @coins[i])
          puts "plink! (#{i})"
          return true
        end
      end
      false
    end

    def serve
      coin = @coins.first
      if Gosu.distance(mouse_x, mouse_y, coin.x, coin.y) < 3 * Quarters::Coin::DIAMETER
        @state = :moving
        @coins[1].kick(Gosu.random(20, 30), Gosu.random(290, 340))
        @coins[2].kick(Gosu.random(20, 30), Gosu.random(20, 70))
        @highlight = nil
      end
    end

    def reset_coins
      x = BOARD_WIDTH / 2
      y = BOARD_HEIGHT - 100
      dx = Quarters::Coin::DIAMETER * 0.5
      dy = Quarters::Coin::DIAMETER * 0.75
      @coins[0].warp(x, y)
      @coins[1].warp(x - dx, y - dy - rand(5))
      @coins[2].warp(x + dx, y - dy - rand(5))

      @state = :serve
      @allowed = []
      @highlight = nil

      @redraw = true
    end

    def coins_overlap?(a, b)
      Gosu.distance(@coins[a].x, @coins[a].y, @coins[b].x, @coins[b].y) <= Quarters::Coin::DIAMETER
    end

  end
end
