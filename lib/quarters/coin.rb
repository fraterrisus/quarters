# frozen_string_literal: true

require 'gosu'

module Quarters
  class Coin
    DIAMETER = 30
    RADIUS = DIAMETER / 2

    FORCE_MULTIPLIER = 3.0

    STATIC_MU = 5.0
    SLIDING_MU = 0.7

    def initialize(x = 0, y = 0)
      @x = x
      @y = y
      @speed = 0.0
      @angle = 0
      @image = Gosu::Image.new('lib/media/quarter.png')
    end

    attr_reader :x, :y, :angle, :speed, :image

    def speed=(new_speed)
      @speed = [new_speed, 0.0].max
    end

    def warp(x, y)
      @x = x
      @y = y
    end

    def self.compensate_for_static_friction(force)
      (force * FORCE_MULTIPLIER) + STATIC_MU
    end

    def kick(force, angle)
      self.speed = force
      @angle = angle
    end

    def kick_with_friction(force, angle)
      self.speed = (force / FORCE_MULTIPLIER) - STATIC_MU
      @angle = angle
    end

    def moving?
      @speed.positive?
    end

    def step
      @x += Gosu.offset_x(@angle, @speed) / 10
      @y += Gosu.offset_y(@angle, @speed) / 10
      apply_friction
    end

    def draw(grey = 1.0)
      mask = (grey * 255).to_i
      color = (255 << 24) + (mask << 16) + (mask << 8) + mask
      @image.draw(@x - (DIAMETER / 2), @y - (DIAMETER / 2), 2, 1, 1, color)
    end

    def height
      DIAMETER
    end

    def width
      DIAMETER
    end

    private

    def apply_friction
      @speed -= SLIDING_MU / 10
      @speed = 0.0 if @speed < 0.1
    end
  end
end
