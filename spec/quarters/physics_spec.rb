# frozen_string_literal: true

require 'rspec'
require 'quarters/coin'
require 'quarters/physics'

RSpec.describe 'Quarters::Physics' do
  before do
    # Do nothing
  end

  after do
    # Do nothing
  end

  context "calculate_collision" do
    context "for a 45d collision" do
      before do
        @coin_1 = Quarters::Coin.new(1, 1)
        @coin_1.kick(20.0, 0.0)

        @coin_2 = Quarters::Coin.new(0, 0)
        @coin_2.kick(20.0, 90.0)

        Quarters::Physics::calculate_collision(@coin_1, @coin_2)
      end

      it "reflects coin 1 to the E" do
        expect(@coin_1.angle.round(0) % 360).to eq(90.0)
        expect(@coin_1.speed.round(0)).to eq(5.0)
      end

      it "reflects coin 2 to the N" do
        expect(@coin_2.angle.round(0) % 360).to eq(0.0)
        expect(@coin_2.speed.round(0)).to eq(5.0)
      end
    end

    context "for a head-on collision" do
      before do
        @coin_1 = Quarters::Coin.new(1, 1)
        @coin_1.kick(20.0, 0.0)

        @coin_2 = Quarters::Coin.new(1, 0)

        Quarters::Physics::calculate_collision(@coin_1, @coin_2)
      end

      it "stops coin 1" do
        expect(@coin_1.speed.round(0)).to eq(0.0)
      end

      it "sends all energy to coin 2" do
        expect(@coin_2.angle.round(0)).to eq(0.0)
        expect(@coin_2.speed.round(0)).to eq(5.0)
      end
    end
  end
end
