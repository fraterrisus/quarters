module Quarters
  module Physics
    def self.calculate_horizontal_bounce(c, dampen = 1.0)
      dx = Gosu.offset_x(c.angle, c.speed)
      dy = Gosu.offset_y(c.angle, c.speed)
      force = (c.speed * 2) + Coin::STATIC_MU
      angle = Gosu.angle(0, 0, dx * -1, dy)
      c.kick(force * dampen, angle)
    end

    def self.calculate_vertical_bounce(c, dampen = 1.0)
      dx = Gosu.offset_x(c.angle, c.speed)
      dy = Gosu.offset_y(c.angle, c.speed)
      force = (c.speed * 2) + Coin::STATIC_MU
      angle = Gosu.angle(0, 0, dx, dy * -1)
      c.kick(force * dampen, angle)
    end

    def self.calculate_rebound(c)
      c.kick((c.speed * 2) + Coin::STATIC_MU, (c.angle + 180) % 360)
    end

    def self.calculate_collision(a, b)
      pi = 2 * Math.acos(0.0)

      # impulse_angle = 360 - ((180.0 / pi) * Math.atan(1.0 * (a.x - b.x) / (a.y - b.y)))
      impulse_angle = Gosu.angle(a.x, a.y, b.x, b.y)
      impulse_mag = (a.speed * Math.cos(((a.angle - impulse_angle) % 360) * pi / 180)) -
        (b.speed * Math.cos(((b.angle - impulse_angle) % 360) * pi / 180))
      impulse_dx = Gosu.offset_x(impulse_angle, impulse_mag)
      impulse_dy = Gosu.offset_y(impulse_angle, impulse_mag)

      a_dx_i = Gosu.offset_x(a.angle, a.speed)
      a_dy_i = Gosu.offset_y(a.angle, a.speed)
      b_dx_i = Gosu.offset_x(b.angle, b.speed)
      b_dy_i = Gosu.offset_y(b.angle, b.speed)

      a_dy_f = a_dy_i - impulse_dy
      a_dx_f = a_dx_i - impulse_dx
      b_dy_f = b_dy_i + impulse_dy
      b_dx_f = b_dx_i + impulse_dx

      a_final_angle = Gosu.angle(0, 0, a_dx_f, a_dy_f)
      a_final_mag = Gosu.distance(0, 0, a_dx_f, a_dy_f)
      b_final_angle = Gosu.angle(0, 0, b_dx_f, b_dy_f)
      b_final_mag = Gosu.distance(0, 0, b_dx_f, b_dy_f)

      a_final_mag = 2 * (a_final_mag + Coin::STATIC_MU)
      b_final_mag = 2 * (b_final_mag + Coin::STATIC_MU)

      a.kick(a_final_mag, a_final_angle)
      b.kick(b_final_mag, b_final_angle)
    end
  end
end
