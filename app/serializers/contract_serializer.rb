class ContractSerializer < ActiveModel::Serializer
  attributes :id, :name, :learning_objectives, :contract_status, :term_id, :category_id, :facilitator_id

  #has_many :enrollments
end
