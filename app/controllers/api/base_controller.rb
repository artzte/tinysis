module Api
  class Api::BaseController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :set_resource, only: [:destroy, :show, :update]

    # POST /api/{plural_resource_name}
    def create
      set_resource(resource_class.new(resource_params))

      if get_resource.save
        render json: get_resource, status: :created
      else
        render json: get_resource.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/{plural_resource_name}/1
    def destroy
      get_resource.destroy
      head :no_content
    end

    # GET /api/{plural_resource_name}
    def index
      plural_resource_name = "@#{resource_name.pluralize}"
      resources = resource_class.where(_query_params)
                                #.page(page_params[:page])
                                #.per(page_params[:page_size])
      #resources = resources.includes(includes)

      instance_variable_set(plural_resource_name, resources)
      render json: instance_variable_get(plural_resource_name)
    end

    # GET /api/{plural_resource_name}/1
    def show
      render json: get_resource
    end

    # PATCH/PUT /api/{plural_resource_name}/1
    def update
      if get_resource.update(resource_params)
        render :show
      else
        render json: get_resource.errors, status: :unprocessable_entity
      end
    end

    private

      # Returns the resource from the created instance variable
      # @return [Object]
      def get_resource
        instance_variable_get("@#{resource_name}")
      end


      # Returns joins for the query
      # @return [Array]
      def includes
        []
      end

      # Returns the allowed parameters for searching
      # Override this method in each API controller
      # to permit additional parameters to search on
      # @return [Hash]
      def query_params
        {}
      end

      def _query_params
        # this assumes that an album belongs to an artist and has an :artist_id
        # allowing us to filter by this
        filtered = params.permit(query_params)
        filtered.each do |k,v|
          if /,/.match(v)
            v = v.split(',')
            filtered[k] = v
          elsif %w{true false}.include? v
            Rails.logger.info "v is #{v} #{v.class}"
            filtered[k] = v == 'true' ? 1 : 0
          end
        end
        Rails.logger.info filtered
        filtered
      end

      # Returns the allowed parameters for pagination
      # @return [Hash]
      def page_params
        params.permit(:page, :page_size)
      end

      # The resource class based on the controller
      # @return [Class]
      def resource_class
        @resource_class ||= resource_name.classify.constantize
      end

      # The singular name for the resource class based on the controller
      # @return [String]
      def resource_name
        @resource_name ||= self.controller_name.singularize
      end

      # Only allow a trusted parameter "white list" through.
      # If a single resource is loaded for #create or #update,
      # then the controller for the resource must implement
      # the method "#{resource_name}_params" to limit permitted
      # parameters for the individual model.
      def resource_params
        @resource_params ||= self.send("#{resource_name}_params")
      end

      # Use callbacks to share common setup or constraints between actions.
      def set_resource(resource = nil)
        resource ||= resource_class.find(params[:id])
        instance_variable_set("@#{resource_name}", resource)
      end
  end
end

