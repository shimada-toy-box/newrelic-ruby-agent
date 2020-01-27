# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/rpm/blob/master/LICENSE for complete details.

require_relative 'distributed_tracing/cross_app_payload'
require_relative 'distributed_tracing/cross_app_tracing'

require_relative 'distributed_tracing/distributed_trace_transport_type'
require_relative 'distributed_tracing/distributed_trace_payload'

require_relative 'distributed_tracing/trace_context'

module NewRelic
  module Agent
    #
    # This module contains helper methods related to Distributed
    # Tracing, an APM feature that ties together traces from multiple
    # apps in one view.  Use it to add distributed tracing to protocols
    # not already supported by the agent.
    #
    # @api public
    module DistributedTracing
      extend NewRelic::SupportabilityHelper
      extend self
      # Create a payload object containing the current transaction's
      # tracing properties (e.g., duration, priority).  You can use
      # this object to generate headers to inject into a network
      # request, so that the downstream service can participate in a
      # distributed trace.
      #
      # @return [DistributedTracePayload] Payload for the current
      #                                   transaction, or +nil+ if we
      #                                   could not create the payload
      #
      # @api public
      def create_distributed_trace_payload
        record_api_supportability_metric(:create_distributed_trace_payload)

        unless Agent.config[:'distributed_tracing.enabled']
          NewRelic::Agent.logger.warn "Not configured to create New Relic distributed trace payload"
          nil
        end

        transaction = Transaction.tl_current
        transaction.distributed_tracer.create_distributed_trace_payload if transaction
      rescue => e
        NewRelic::Agent.logger.error 'error during create_distributed_trace_payload', e
        nil
      end

      # Decode a JSON string containing distributed trace properties
      # (e.g., calling application, priority) and apply them to the
      # current transaction.  You can use it to receive distributed
      # tracing information protocols the agent does not already
      # support.
      #
      # This method will fail if you call it after calling
      # {#create_distributed_trace_payload}.
      #
      # @param payload [String] Incoming distributed trace payload,
      #                         either as a JSON string or as a
      #                         header-friendly string returned from
      #                         {DistributedTracePayload#http_safe}
      #
      # @return nil
      #
      # @api public
      def accept_distributed_trace_payload payload
        record_api_supportability_metric(:accept_distributed_trace_payload)
        
        unless Agent.config[:'distributed_tracing.enabled']
          NewRelic::Agent.logger.warn "Not configured to accept New Relic distributed trace payload"
          nil
        end

        return unless transaction = Transaction.tl_current
        transaction.distributed_tracer.accept_distributed_trace_payload(payload)
        nil
      rescue => e
        NewRelic::Agent.logger.error 'error during accept_distributed_trace_payload', e
        nil
      end
    end
  end
end