# frozen_string_literal: true

require 'gosu'

module Quarters
  class Coin
    DIAMETER = 20

    IMAGE_DATA = [
      0xff.chr, 0xff.chr, 0xff.chr, 0xff.chr
    ].join * DIAMETER * DIAMETER

    STATIC_MU = 5
    SLIDING_MU = 0.7

    def initialize(x=0, y=0)
      @x = x
      @y = y
      @speed = 0
      @angle = 0
      # @image = Gosu::Image.from_blob(WIDTH, HEIGHT, IMAGE_DATA)
      @image = Gosu::Image.new('lib/media/coin.png')
    end

    def warp(x, y)
      @x = x
      @y = y
    end

    def kick(force, angle)
      @speed = [0, (force / 2.0) - STATIC_MU].max
      @angle = angle
    end

    def moving?
      @speed > 0
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

    attr_reader :x, :y, :angle, :speed, :image

    def height
      DIAMETER
    end

    def width
      DIAMETER
    end

    private

    def apply_friction
      @speed = @speed - (SLIDING_MU / 10)
      @speed = 0 if @speed < 0.1
    end
  end
end
