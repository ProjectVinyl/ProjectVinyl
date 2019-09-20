module Api
  class BaseApiController < ApplicationController
    include PathHelper

    before_action :pre_filter

    protected
    def pre_filter
      if !params[:key] || !(@token = ApiToken.validate_token(params[:key]))
        return fail :unauthorized, status: 401, message: "Unauthorized"
      end

      if !@token.hit
        return fail 429, status: 429, message: "Too Many Requests"
      end

      @include = (params[:include] || '').split(',').map {|a| a.strip.to_sym}
    end

    def fail(code, e)
      render json: {
        success: false,
        error: e
      }, status: code
    end

    def succeed(data, incl = nil)
      render json: {
        success: true,
        data: data,
        included: incl
      }
    end

    def include_hash(asked)
      data = {}
      @include.each do |key|
        if asked.include?(key)
          data[key] = true
        end
      end

      data
    end
  end
end
