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
        byebug
        return head :unauthorized if !@video.owned_by(current_user)

        video.story_cards.destroy
        video.story_cards.create(params[:story_cards].accept(
          :style, :left, :top, :width, :height,
          :start_time, :end_time,
          :title, :media, :image, :url
        ))

        return render json: {
          success: true
        }
      end
    end
  end
end
