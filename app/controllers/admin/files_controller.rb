module Admin
  class FilesController < ApplicationController
    before_action :authenticate_user!
    
    def index
      render_path(params, false)
    end

    def page
      render_path(params, true)
    end
    
    private
    def render_path(params, ajax)
      if !user_signed_in? || !current_user.is_contributor?
        if ajax
          return head 403
        end
        return render file: '/public/403.html', layout: false
      end
      @location = (params[:p] || "public/stream").strip
      if @location == ''
        @location = ['public']
      else
        @location = @location.split(/\/|\\/)
      end
      if @location.empty? && @location[0] != 'encoding'
        @location = ['public'] + @location
      end
      if @location.length > 1 && @location[1] != 'stream' && @location[1] != 'cover' && @location[1] != 'avatar' && @location[1] != 'banner'
        if @location[0] != 'encoding'
          if ajax
            return head 403
          end
          return render file: '/public/403.html', layout: false
        end
      end
      if @location[0] != 'public' && @location[0] != 'private' && @location[0] != 'encoding'
        if ajax
          return head 403
        end
        return render file: '/public/403.html', layout: false
      end
      begin
        @location = @location.join('/')
        @public = VideoDirectory.entries(@location).limit(50)
        if params[:start] && !@public.start_from(params[:start], params[:offset]) && ajax
          return render json: {}
        end
        if params[:end] && !@public.end_with(params[:end]) && ajax
          return render json: {}
        end
        if @location == 'public' || @location == 'private'
          @public.filter do |loc|
            name = loc.split('.')[0]
            loc.index('.').nil? && (name == 'stream' || name == 'cover' || name == 'avatar' || name == 'banner')
          end
        end
        if @location.index('public/avatar') == 0 || @location.index('public/banner') == 0
          @public.names_resolver do |names, ids|
            User.where('id IN (' + ids.join(',') + ')').pluck(:id, :username).each do |i|
              names[i[0].to_s] = i[1]
            end
          end
        else
          @public.names_resolver do |names, ids|
            Video.where('id IN (' + ids.join(',') + ')').pluck(:id, :title).each do |i|
              names[i[0].to_s] = i[1]
            end
          end
        end
      rescue Exception => e
        if ajax
          return head 404
        end
        return render file: '/public/404.html', layout: false
      end
      if ajax
        render json: {
          content: render_to_string(partial: '/admin/file.html.erb', collection: @public.items),
          start: @public.start_ref,
          end: @public.end_ref
        }
      end
    end
  end
end
