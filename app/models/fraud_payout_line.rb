# frozen_string_literal: true

class FraudPayoutLine < ApplicationRecord
  include Ledgerable

  belongs_to :fraud_payout_run
  belongs_to :user

  has_many :shop_orders, dependent: :nullify
end
