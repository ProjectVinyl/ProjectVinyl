class FixHeatness < ActiveRecord::Migration
  def change
    Video.all.each do |v|
      v.computeHotness.save()
    end
  end
end
