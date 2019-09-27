require 'projectvinyl/storage/video_directory'

module Admin
  class FilesController < BaseAdminController
  
    ALLOW_ROOTS = ['public','private','encoding']
    ALLOW_DIRS = ['stream', 'cover', 'avatar', 'banner']
    
    def index
      json = params[:format] == 'json'

      if !user_signed_in? || !current_user.is_contributor?
        return render_error_file 403, json
      end
      
      load_location
      
      if !ALLOW_ROOTS.include?(@location[0]) && @location.length > 1 && !ALLOW_DIRS.include?(@location[1])
        return render_error_file 403, json
      end

      begin
        @public = ProjectVinyl::Storage::VideoDirectory.entries(@path).limit(50)
        if json
          if (params[:start] && !@public.start_from(params[:start], params[:offset])) || (params[:end] && !@public.end_with(params[:end]) && json)
            return render json: {}
          end
        end
        
        if ALLOW_ROOTS.include?(@path)
          @public.filter do |loc|
            name = loc.split('.')[0]
            loc.index('.').nil? && ALLOW_DIRS.include?(name)
          end
        end
        
        if @path.index('public/avatar') == 0 || @path.index('public/banner') == 0
          @public.names_resolver do |names, ids, path|
            User.where('id IN (' + ids.join(',') + ')').pluck(:id, :username).each do |i|
              names[i[0].to_s] = i[1]
            end
          end
        else
          @public.names_resolver do |names, ids, path|
            if path.length == 6 && path[1] == 'stream'
              if vid = Video.where(id: path.last.to_i).first
                ids.each do |id|
                  names[id] = vid.title
                end
              end
            elsif path.length == 5 && path[1] == 'stream'
              ids = ids.map {|id| id.to_i }.uniq
              Video.where('id IN (?)', ids).pluck(:id, :title).each do |i|
                names[i[0].to_s] = i[1]
              end
            end
          end
        end
        
      rescue Exception => e
        return render_error_file 404, json
      end
      
      if json
        render json: {
          content: render_to_string(partial: 'file', collection: @public.items),
          start: @public.start_ref,
          end: @public.end_ref
        }
      end
      
      @crumb = {
        stack: [
          { link: '/admin', title: 'Admin' },
        ],
        title: "Control Panel"
      }
    end
    
    private
    def load_location
      @location = (params[:p] || "public/stream").strip

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
