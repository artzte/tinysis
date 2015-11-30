module Api
  class EnrollmentsController < Api::BaseController

    private

      def enrollment_params
        params.require(:enrollment).permit(:contract_id, :participant_id, :role)
      end

      def query_params
        [:contract_id, :participant_id]
      end

  end
end
