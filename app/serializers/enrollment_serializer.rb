class EnrollmentSerializer < ActiveModel::Serializer
  attributes :id, :participant_id, :role, :enrollment_status, :completion_status, :completion_date, :creator_id, :created_at, :updated_at, :finalized_on
  belongs_to :contract
end
