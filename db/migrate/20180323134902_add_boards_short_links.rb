class AddBoardsShortLinks < ActiveRecord::Migration[5.1]
  def change
    add_column :boards, :short_name, :string
    Board.reset_column_information
    Board.all.each do |i|
      i.short_name = i.title.downcase.split(' ')[0]
      if i.short_name == 'general'
        i.short_name = 'b'
      end
      i.save
    end
  end
end
