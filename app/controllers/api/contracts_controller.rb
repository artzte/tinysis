module Api
  class ContractsController < Api::BaseController

    private

      def contract_params
        params.require(:contract).permit(:name)
      end

      def query_params
        [:term_id, :category_id, :contract_status]
      end

  end
end
