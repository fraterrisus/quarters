# frozen_string_literal: true

require 'gosu'
require_relative './coin'
require_relative './physics'

module Quarters
  class App < Gosu::Window
    WINDOW_HEIGHT = 1024
    WINDOW_WIDTH = 768

    MARGIN = 10
    PITCH_X0 = MARGIN
    PITCH_X1 = WINDOW_WIDTH - MARGIN

    LINE_WIDTH = 5

    GOAL_X0 = (WINDOW_WIDTH / 2) - 75
    GOAL_X1 = (WINDOW_WIDTH / 2) + 75
    GOAL_Y0 = MARGIN + LINE_WIDTH
    GOAL_HEIGHT = Coin::DIAMETER * 2
    GOAL_Y1 = GOAL_Y0 + GOAL_HEIGHT

    PITCH_Y0 = MARGIN + GOAL_HEIGHT
    PITCH_Y1 = WINDOW_HEIGHT - 50

    PITCH_COLOR = Gosu::Color.argb(0xff008800)

    def initialize(*args)
      super(WINDOW_WIDTH, WINDOW_HEIGHT, *args)
      self.caption = 'Quarters'

      @bg = App.make_background
      @coins = [Coin.new, Coin.new, Coin.new]
      @power = 0

      @wins = 0
      @games = -1

      reset_coins
    end

    def update
      handle_movement if @state == :moving

      if Gosu.button_down?(Gosu::KB_TAB)
        return if @state == :end

        unless @tab_pushed
          select_next_coin
          return
        end
      else
        @tab_pushed = false
      end

      if Gosu.button_down?(Gosu::KB_Q)
        close
      elsif Gosu.button_down?(Gosu::MS_LEFT)
        if @state == :end
          reset_coins
          @redraw = true
        elsif @state == :serve
          serve
        elsif @highlight
          @start_time ||= Gosu.milliseconds
          @power = ((Gosu.milliseconds - @start_time) * 0.1).round(0)
          @power = 100 if @power > 100
          @redraw = true
        end
      elsif Gosu.button_down?(Gosu::MS_RIGHT) # TODO: testing, remove
        return if @state == :end

        if @highlight
          @coins[@highlight].warp(mouse_x, mouse_y)
          @redraw = true
        end
      elsif Gosu.button_down?(Gosu::KB_R)
        reset_coins unless @state == :serve
        @redraw = true
      elsif @state == :play && @power.positive?
        @start_time = nil
        generate_goal_line
        flick_coin
      end
    end

    def needs_redraw?
      @redraw
    end

    def draw
      @bg.draw(0, 0)

      x_min = 20
      y_min = WINDOW_HEIGHT - 30
      wid = 200
      hgt = 20
      Gosu.draw_rect(x_min, y_min, wid, hgt, Gosu::Color::RED, 1)
      Gosu.draw_rect(x_min + 1, y_min + 1, wid - 2, hgt - 2, Gosu::Color::BLACK, 2)
      Gosu.draw_rect(x_min + 1, y_min + 1, @power * 2, hgt - 2, Gosu::Color::RED, 3)
      Gosu::Image.from_text(@power, 20).draw(x_min, y_min, 3)

      win_text = "Wins: #{@wins}/#{@games}"
      Gosu::Image.from_text(win_text, 20).draw(WINDOW_WIDTH - 100, y_min, 3)

      @coins.each_with_index do |c, i|
        c.draw(i == @highlight ? 1.0 : 0.75)
        c.draw(i == @highlight ? 1.0 : 0.75)
      end

      if @state == :end
        text = ''
        text = 'GOAL!' if @won
        text = 'You lost!' if @lost
        i = Gosu::Image.from_text(text, 48)
        x_mid = WINDOW_WIDTH / 2
        y_mid = WINDOW_HEIGHT / 2
        Gosu.draw_rect(x_mid - 150, y_mid - 60, 300, 120, Gosu::Color::WHITE, 4)
        Gosu.draw_rect(x_mid - 145, y_mid - 55, 290, 110, Gosu::Color::BLACK, 4)
        i.draw(x_mid - (i.width / 2), y_mid - (i.height / 2), 4)
        @wins += 1 if @won
      end

      @redraw = false
    end

    private

    def handle_movement
      if @coins.select(&:moving?).any?
        @coins.each(&:step)
        10.times do
          @coins.select(&:moving?).each { |c| wall_bounce?(c) }
          check_goal_line unless @goal == :yes
          @lost = true if coin_collisions?
          @won = true if check_for_win
          @coins.each(&:step)
        end
        @redraw = true
        @coins.each { |c| @lost = true if out_of_bounds?(c) }
      else
        @lost = true if @highlight && @goal != :yes
        if @won || @lost
          @state = :end
          @allowed = []
        else
          @state = :play
          @allowed = [0, 1, 2].reject { |x| x == @highlight }
        end
        @highlight = -1
        @power = 0
        @redraw = true
      end
    end

    def select_next_coin
      return 0 if @allowed.empty?

      current = @allowed.index(@highlight) || -1
      new = (current + 1) % @allowed.size
      @highlight = @allowed[new]
      @tab_pushed = true
      @redraw = true
    end

    def flick_coin
      coin = @coins[@highlight]
      coin.kick_with_friction(@power, Gosu.angle(mouse_x, mouse_y, coin.x, coin.y))
      @state = :moving
    end

    def generate_goal_line
      a = [0, 1, 2]
      a.delete @highlight
      b = @coins[a[1]]
      a = @coins[a[0]]
      @goal_line = []
      dist = Gosu.distance(a.x, a.y, b.x, b.y)
      angle = Gosu.angle(a.x, a.y, b.x, b.y)
      x_comp = Gosu.offset_x(angle, Coin::RADIUS)
      y_comp = Gosu.offset_y(angle, Coin::RADIUS)
      inc = 0
      x = a.x
      y = a.y
      while inc <= dist
        @goal_line << [x, y]
        inc += Coin::RADIUS
        x += x_comp
        y += y_comp
      end
      @goal = :no
    end

    def check_goal_line
      return unless @highlight

      case @goal
      when :yes
        nil
      when :touch
        @goal = :yes unless touching_line?(@coins[@highlight])
      when :no
        @goal = :touch if touching_line?(@coins[@highlight])
      when nil
        @goal = :no
      else
        raise
      end
    end

    def check_for_win
      if @highlight
        coin = @coins[@highlight]
        if (coin.x - Coin::RADIUS) > GOAL_X0 &&
           (coin.x + Coin::RADIUS) < GOAL_X1 &&
           (coin.y + Coin::RADIUS) < (GOAL_Y0 + GOAL_HEIGHT)
          return true
        end
      end
      false
    end

    def touching_line?(coin)
      @goal_line.each do |pair|
        return true if Gosu.distance(coin.x, coin.y, pair[0], pair[1]) < Coin::RADIUS
      end
      false
    end

    def out_of_bounds?(coin)
      ((coin.x + Coin::RADIUS) < PITCH_X0) || ((coin.x - Coin::RADIUS) >= PITCH_X1) ||
        ((coin.y - Coin::RADIUS) >= PITCH_Y1) ||
        (((coin.y + Coin::RADIUS) < PITCH_Y0) &&
          (((coin.x - Coin::RADIUS) < GOAL_X0) || ((coin.x + Coin::RADIUS) > GOAL_X1)))
    end

    def wall_bounce?(coin)
      # Front posts
      if Gosu.distance(coin.x, coin.y, GOAL_X0, GOAL_Y1) <= Coin::RADIUS ||
         Gosu.distance(coin.x, coin.y, GOAL_X1, GOAL_Y1) <= Coin::RADIUS
        Physics.calculate_rebound(coin)
        return true
      end

      # Back netting
      if coin.x >= GOAL_X0 &&
         coin.x <= GOAL_X1 &&
         (coin.y - Coin::RADIUS) <= GOAL_Y0
        Physics.calculate_vertical_bounce(coin)
        return true
      end

      # Side netting
      if coin.y > GOAL_Y0 &&
         coin.y < GOAL_Y1 &&
         ((coin.x - GOAL_X0).abs <= Coin::RADIUS || (coin.x - GOAL_X1).abs <= Coin::RADIUS)
        Physics.calculate_horizontal_bounce(coin)
        return true
      end

      false
    end

    def coin_collisions?
      @hits ||= []
      @hits.select! { |p| p.first == @highlight }

      plink = false
      return false if @highlight.nil?

      [0, 1, 2].each do |i|
        next if i == @highlight
        next if @hits.any? { |h| h[1] == i }
        next unless coins_overlap?(@highlight, i)

        @hits.unshift([@highlight, i])
        Physics.calculate_collision(@coins[@highlight], @coins[i])
        puts "plink! (#{@highlight},#{i})"
        plink = true
      end

      plink
    end

    def serve
      coin = @coins.first
      return unless Gosu.distance(mouse_x, mouse_y, coin.x, coin.y) < 3 * Coin::DIAMETER

      @state = :moving
      @coins[1].kick(Gosu.random(7, 15), Gosu.random(290, 340))
      @coins[2].kick(Gosu.random(7, 15), Gosu.random(20, 70))
      @highlight = nil
    end

    def reset_coins
      x = WINDOW_WIDTH / 2
      y = WINDOW_HEIGHT - 100
      dx = Coin::DIAMETER * 0.5
      dy = Coin::DIAMETER * 0.8
      @coins[0].warp(x, y)
      @coins[1].warp(x - dx, y - dy - rand(5))
      @coins[2].warp(x + dx, y - dy - rand(5))

      @state = :serve
      @allowed = [0]
      @highlight = 0

      @lost = false
      @won = false
      @games += 1

      @redraw = true
    end

    def coins_overlap?(a, b)
      Gosu.distance(@coins[a].x, @coins[a].y, @coins[b].x, @coins[b].y) <= Coin::DIAMETER
    end

    class << self
      def make_background
        Gosu.render(WINDOW_WIDTH, WINDOW_HEIGHT) do
          Gosu.draw_rect( # Pitch boundary
            PITCH_X0,
            PITCH_Y0,
            PITCH_X1 - PITCH_X0,
            PITCH_Y1 - PITCH_Y0,
            Gosu::Color::WHITE, 1
          )
          Gosu.draw_rect( # Goal box
            GOAL_X0 - LINE_WIDTH,
            GOAL_Y0 - LINE_WIDTH,
            (GOAL_X1 - GOAL_X0) + (2 * LINE_WIDTH),
            GOAL_HEIGHT + (2 * LINE_WIDTH),
            Gosu::Color::WHITE, 1
          )
          Gosu.draw_rect( # Pitch field
            PITCH_X0 + LINE_WIDTH,
            PITCH_Y0 + LINE_WIDTH,
            PITCH_X1 - PITCH_X0 - (2 * LINE_WIDTH),
            PITCH_Y1 - PITCH_Y0 - (2 * LINE_WIDTH),
            PITCH_COLOR, 1
          )
          Gosu.draw_rect( # Goal field
            GOAL_X0,
            GOAL_Y0,
            GOAL_X1 - GOAL_X0,
            GOAL_HEIGHT - 1,
            PITCH_COLOR, 1
          )
        end
      end
    end
  end
end
