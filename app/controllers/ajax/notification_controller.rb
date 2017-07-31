module Ajax
  class NotificationController < ApplicationController
    def view
      if user_signed_in?
        if params[:chat]
          result = {
            chats: []
          }
          if current_user.notification_count != params[:notes].to_i || current_user.feed_count != params[:feeds].to_i || current_user.message_count != params[:mail].to_i
            result[:notices] = current_user.notification_count
            result[:feeds] = current_user.feed_count
            result[:mail] = current_user.message_count
          end
          ids = []
          values = {}
          params[:chat].split(',').each do |t|
            t = t.split(':')
            ids << t[0]
            values[t[0].to_i] = t[1].to_i
          end
          CommentThread.where('id IN (?)', ids.uniq).each do |thread|
            last = thread.comments.last.id
            next unless last != values[thread.id]
            c = thread.comments.includes(:direct_user).order(:created_at).reverse_order.limit(50).reverse
            result[:chats] << {
              id: thread.id,
              content: render_to_string(partial: 'thread/chat_message_set', locals: { thread: c }),
              last: last
            }
          end
          return render json: result
        end
        if current_user.notification_count != params[:notes].to_i || current_user.feed_count != params[:feeds].to_i || current_user.message_count != params[:mail].to_i
          return render json: {
            notices: current_user.notification_count,
            feeds: current_user.feed_count,
            mail: current_user.message_count
          }
        else
          return head 204
        end
      end
      head 401
    end
  end
end
