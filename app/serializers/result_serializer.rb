class ResultSerializer < ActiveModel::Serializer
  attributes :id, :gateway_id, :created_at, :upload, :download, :label

  def label
    ResultCalculator.time_label(TimeCalculator.round_down(created_at, 30.minutes), ResultCalculator::BY_CREATED_AT)
  end
end
