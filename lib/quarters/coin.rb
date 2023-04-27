# frozen_string_literal: true

require 'gosu'

module Quarters
  class Coin
    WIDTH = 20
    HEIGHT = 20

    IMAGE_DATA = [
      0xff.chr, 0xff.chr, 0xff.chr, 0xff.chr
    ].join * WIDTH * HEIGHT

    STATIC_MU = 5
    SLIDING_MU = 0.7

    def initialize(x, y)
      @x = x
      @y = y
      @speed = 0
      @angle = nil
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

    def update
      @x += Gosu.offset_x(@angle, @speed)
      @y += Gosu.offset_y(@angle, @speed)
      apply_friction
    end

    def draw
      @image.draw(@x - (WIDTH / 2), @y - (HEIGHT / 2), 2)
    end

    def x
      @x
    end

    def y
      @y
    end

    def image
      @image
    end

    private

    def apply_friction
      @speed = @speed - SLIDING_MU
      @speed = 0 if @speed < 0.1
    end
  end
end
