module Api
  class TermsController < Api::BaseController

    private

      def term_params
        params.require(:term).permit(:name, :active, :school_year)
      end

      def query_params
        [:active, :school_year]
      end

  end
end
