module Reorderable
  extend ActiveSupport::Concern

  PREV = -1
  NEXT = 1

  included do
    before_destroy :shift_on_destroyed
    after_create :shift_on_created

    scope :shift_by, ->(amount) { update_all("index = index + #{amount.to_i}") }
    scope :following, ->(index) { discriminate('>', index) }
    scope :leading, ->(index) { discriminate('<', index) }
    scope :discriminate, ->(comparitor, index) { where('index ' + comparitor + ' ?', index) }

    scope :shift_between, ->(from, to) {
      return where('index >= ? AND index < ?', to, from).shift_by(NEXT) if to < from
      where('index > ? AND index <= ?', from, to).shift_by(PREV)
    }

    def self.has_siblings(sym)
      define_method :siblings do
        self.send(sym)
      end
    end

    def self.after_move(sym)
      define_method :after_move do
        self.send(sym)
      end
    end
  end

  def move(new_index)
    from = index
    to = new_index

    if to != from
      siblings.shift_between(from, to) if respond_to?(:siblings)
      after_move if respond_to?(:after_move)
      self.index = new_index
      self.save
    end
  end

  protected
  def shift_on_created
    puts "Shifting!"
    siblings.following(index - 1).where.not(id: id).shift_by(NEXT) if respond_to?(:siblings)
  end
  def shift_on_destroyed
    siblings.following(index).shift_by(PREV) if respond_to?(:siblings)
  end
end
