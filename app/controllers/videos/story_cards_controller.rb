module Videos
  class StoryCardsController < BaseVideosController

    def show
      check_then do |video|
        @video = video
        @cards = video.story_cards
        render partial: 'show'
      end
    end

    def update
      check_then do |video|
        return head :unauthorized if !video.owned_by(current_user)

        video.story_cards.destroy_all

        if params.key?(:video) && params[:video].key?(:cards)
          card = params[:video][:cards].map{|c| c.permit(
            :content_id, :content_type,
            :style, :left, :top, :width, :height,
            :start_time, :end_time,
            :title, :media, :image, :url
          )}

          video.story_cards.create(card)
        end
        video.save

        return render json: {
          success: true
        }
      end
    end
  end
end
