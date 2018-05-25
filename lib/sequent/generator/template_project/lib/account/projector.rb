require_relative '../records/account_record'

class Account
  class Projector < Sequent::Core::Projector
    on AccountAdded do |event|
      create_record(AccountRecord, aggregate_id: event.aggregate_id)
    end

    on AccountNameChanged do |event|
      update_all_records(AccountRecord, {aggregate_id: event.aggregate_id}, name: event.name)
    end
  end
end