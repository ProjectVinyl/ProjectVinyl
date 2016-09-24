class HotnessTwo < ActiveRecord::Migration
  def change
    Video.all.each do |v|
      v.heat = v.computeHotness
      v.save
    end
  end
end
