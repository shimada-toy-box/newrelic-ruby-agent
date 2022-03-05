# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    #
    # This module contains helper methods related to decorating log messages
    module LocalLogDecorator
      extend self

      def decorate(message)
        return message unless decorating_enabled?
        metadata = NewRelic::Agent.linking_metadata
        "#{message} NR-LINKING|#{metadata["entity.guid"]}|#{metadata["hostname"]}|#{metadata["trace.id"]}|#{metadata["span.id"]}|"
      end

      private

      def decorating_enabled?
        NewRelic::Agent.config[:'application_logging.enabled'] &&
          NewRelic::Agent.config[:'instrumentation.logger'] != 'disabled' &&
          NewRelic::Agent.config[:'application_logging.local_decorating.enabled']
      end
    end
  end
end
