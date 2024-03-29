require 'projectvinyl/storage/video_directory'

module Admin
  class FilesController < BaseAdminController

    ALLOW_ROOTS = ['public','private','encoding']
    FILTERED_ROOTS = ['public','private']
    ALLOW_DIRS = ['stream', 'avatar']

    def index
      json = params[:format] == 'json'

      return render_status_page :forbidden if !user_signed_in? || !current_user.is_contributor?

      load_location

      return render_status_page :forbidden if !ALLOW_ROOTS.include?(@location[0]) && @location.length > 1 && !ALLOW_DIRS.include?(@location[1])

      begin
        @public = ProjectVinyl::Storage::VideoDirectory.entries(@path).limit(50)

        if params[:start] && (!json || params[:position] == 'after')
          return render json: {} if !@public.buffer_before(params[:start], params[:offset]) && json
        end

        if params[:end] && params[:position] == 'before'
          return render json: {} if !@public.buffer_after(params[:end], params[:offset]) && json
        end

        if FILTERED_ROOTS.include?(@path)
          @public.filter do |loc|
            name = loc.split('.')[0]
            loc.index('.').nil? && ALLOW_DIRS.include?(name)
          end
        end

        add_resolver

      rescue Exception => e
        return render_status_page :not_found
      end

      if json
        render json: {
          content: render_to_string(partial: 'file', formats: [:html], collection: @public.items),
          start: @public.start_ref,
          end: @public.end_ref
        }
      end

      @public.names

      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
        ],
        title: "Control Panel"
      }
    end

    private
    def add_resolver

      if @location.length == 6
        if @location[1] == 'avatar'
          return @public.names_resolver do |names, ids, path|
            if @user = User.where(id: path.last.to_i).first
              ids.each {|id| names[id] = @user.username }
            end
          end
        end

        return @public.names_resolver do |names, ids, path|
          if @video = Video.where(id: path.last.to_i).first
            ids.each {|id| names[id] = @video.title }
          end
        end
      end

      if @location.length == 5 || (@location.length == 3 && @location[2] == 'lostnfound')
        if @location[1] == 'avatar'
          return @public.names_resolver do |names, ids, path|
            ids = ids.map {|id| id.to_i }.uniq
            User.where('id IN (?)', ids).pluck(:id, :username).each {|i| names[i[0].to_s] = i[1] }
          end
        end

        return @public.names_resolver do |names, ids, path|
          ids = ids.map {|id| id.to_i }.uniq
          Video.where('id IN (?)', ids).pluck(:id, :title).each {|i| names[i[0].to_s] = i[1] }
        end
      end

      if @location.length == 4
        return @public.names_resolver do |names, ids, path|
          year = path[2].to_i
          month = path[3].to_i
          if (year && month)
            ids.each do |id|
              day = id.to_i
              if day
                names[id] = Date.new(year, month, day).strftime("%A, %d-%m-%Y")
              end
            end
          end
        end
      end

      if @location.length == 3
        return @public.names_resolver do |names, ids, path|
          year = path[2].to_i
          if (year && year > 0)
            ids.each do |id|
              month = id.to_i
              if month
                names[id] = Date.new(year, month, 1).strftime("%B, %Y")
              end
            end
          end
        end
      end
    end

    def load_location
      @location = (params[:p] || params[:path] || "public/stream").strip

      if @location == ''
        @location = ['public']
      else
        @location = @location.split(/\/|\\/)
      end

      if @location.empty? && @location[0] != 'encoding'
        @location = ['public'] + @location
      end

      @path = @location.join('/')
    end
  end
end
