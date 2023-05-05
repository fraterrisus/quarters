# frozen_string_literal: true

require 'gosu'

module Quarters
  module Physics
    def self.calculate_horizontal_bounce(c, dampen = 1.0)
      dx = Gosu.offset_x(c.angle, c.speed)
      dy = Gosu.offset_y(c.angle, c.speed)
      angle = Gosu.angle(0, 0, dx * -1, dy)
      c.kick(c.speed * dampen, angle)
    end

    def self.calculate_vertical_bounce(c, dampen = 1.0)
      dx = Gosu.offset_x(c.angle, c.speed)
      dy = Gosu.offset_y(c.angle, c.speed)
      angle = Gosu.angle(0, 0, dx, dy * -1)
      c.kick(c.speed * dampen, angle)
    end

    def self.calculate_rebound(c)
      c.kick((c.speed * 2) + Coin::STATIC_MU, (c.angle + 180) % 360)
    end

    def self.calculate_collision(a, b)
      # Calculate angle of impact
      impulse_angle = Gosu.angle(a.x, a.y, b.x, b.y)

      # Normalize angles of motion along the angle of impact and convert to radians
      a_norm = ((a.angle - impulse_angle) % 360).gosu_to_radians
      b_norm = ((b.angle - impulse_angle) % 360).gosu_to_radians
      # Calculate the rebound force along the angle of impact
      impulse_force = (a.speed * Math.sin(a_norm)) - (b.speed * Math.sin(b_norm))
      # ... and unnormalize to find its components along (true) X and Y
      impulse_dx = Gosu.offset_x(impulse_angle, impulse_force)
      impulse_dy = Gosu.offset_y(impulse_angle, impulse_force)

      # Calculate the X/Y components of the coins' velocity
      a_dx_i = Gosu.offset_x(a.angle, a.speed)
      a_dy_i = Gosu.offset_y(a.angle, a.speed)
      b_dx_i = Gosu.offset_x(b.angle, b.speed)
      b_dy_i = Gosu.offset_y(b.angle, b.speed)

      # Modify coin velocity components by the rebound force
      a_dy_f = a_dy_i + impulse_dy
      a_dx_f = a_dx_i + impulse_dx
      b_dy_f = b_dy_i - impulse_dy
      b_dx_f = b_dx_i - impulse_dx

      # and convert back into polar coordinates
      a_final_angle = Gosu.angle(0, 0, a_dx_f, a_dy_f)
      a_final_force = Gosu.distance(0, 0, a_dx_f, a_dy_f)
      b_final_angle = Gosu.angle(0, 0, b_dx_f, b_dy_f)
      b_final_force = Gosu.distance(0, 0, b_dx_f, b_dy_f)

      a.kick(a_final_force, a_final_angle)
      b.kick(b_final_force, b_final_angle)
    end
  end
end
