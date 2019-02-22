require 'active_record'
require_relative 'sequent_oj'

module Sequent
  module Core

    module SerializesEvent
      def event
        payload = Sequent::Core::Oj.strict_load(self.event_json)
        Class.const_get(self.event_type).deserialize_from_json(payload)
      end

      def event=(event)
        self.aggregate_id = event.aggregate_id
        self.sequence_number = event.sequence_number
        self.organization_id = event.organization_id if event.respond_to?(:organization_id)
        self.event_type = event.class.name
        self.created_at = event.created_at
        self.event_json = self.class.serialize_to_json(event)
      end

      module ClassMethods
        def serialize_to_json(event)
          Sequent::Core::Oj.dump(event)
        end
      end

      def self.included(host_class)
        host_class.extend(ClassMethods)
      end
    end

    class EventRecord < ActiveRecord::Base
      include SerializesEvent

      self.table_name = "event_records"

      belongs_to :stream_record
      belongs_to :command_record
      has_many :command_records, foreign_key: 'event_aggregate_id'

      validates_presence_of :aggregate_id, :sequence_number, :event_type, :event_json, :stream_record, :command_record
      validates_numericality_of :sequence_number, only_integer: true, greater_than: 0

      def parent
        command_record
      end

      def children
        command_records
      end

      def origin
        find_origin(parent)
      end

      def find_origin(record)
        return find_origin(record.parent) if record.parent.present?
        record
      end
    end
  end
end
