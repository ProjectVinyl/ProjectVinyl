class Board < ApplicationRecord
  has_many :comment_threads, as: :owner, dependent: :destroy
  
  scope :sorted, -> { order(:title) }
  scope :listables, -> { sorted.pluck(:id, :title) }
  
  def self.find_board(id)
    Board.where('id = ? OR short_name = ?', id, id).first
  end

  def threads
    comment_threads.includes(:direct_user).order('pinned DESC, locked ASC, created_at DESC')
  end

  def total_comments
    @posts.nil? ? (@posts = comment_threads.sum(:total_comments)) : @posts
  end

  def total_threads
    @nthreads.nil? ? (@nthreads = comment_threads.count) : @nthreads
  end

  def link
    "/forum/#{self.short_name}"
  end

  def last_comment
    @last_comment || (@last_comment = Comment.joins(:comment_thread).where('`comments`.hidden = false AND `comment_threads`.owner_type = "Board" AND `comment_threads`.owner_id = ?', self.id).order(:created_at, :updated_at).reverse_order.limit(1).first)
  end

  def last_poster
    @last_poster || (@last_poster = last_comment ? last_comment.user : UserDummy.new(0))
  end
end
