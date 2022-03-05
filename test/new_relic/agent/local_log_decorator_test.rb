# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.

require File.expand_path('../../../test_helper', __FILE__)
require 'new_relic/agent/local_log_decorator'

module NewRelic::Agent
  module LocalLogDecorator
    class LocalLogDecoratorTest < Minitest::Test
      MESSAGE = 'message'.freeze

      def setup
        @enabled_config = {
          :entity_guid => 'GUID',
          :'application_logging.local_decorating.enabled' => true,
          :'application_logging.enabled' => true,
          :'instrumentation.logger' => 'auto',
        }
        NewRelic::Agent.config.add_config_for_testing(@enabled_config)
      end

      def teardown
        NewRelic::Agent.config.remove_config(@enabled_config)
      end

      def test_does_not_decorate_if_local_decoration_disabled
        with_config(
          :'application_logging.local_decorating.enabled' => false,
          :'application_logging.enabled' => true,
          :'instrumentation.logger' => 'disabled'
        ) do
          decorated_message = LocalLogDecorator.decorate(MESSAGE)
          assert_equal MESSAGE, decorated_message
        end
      end

      def test_does_not_decorate_if_instrumentation_logger_disabled
        with_config(
          :'instrumentation.logger' => 'disabled',
          :'application_logging.local_decorating.enabled' => true,
          :'application_logging.enabled' => true
        ) do
          decorated_message = LocalLogDecorator.decorate(MESSAGE)
          assert_equal MESSAGE, decorated_message
        end
      end

      def test_does_not_decorate_if_application_logging_disabled
        with_config(
          :'application_logging.enabled' => false,
          :'application_logging.local_decorating.enabled' => true,
          :'instrumentation.logger' => 'disabled'
        ) do
          decorated_message = LocalLogDecorator.decorate(MESSAGE)
          assert_equal MESSAGE, decorated_message
        end
      end

      def test_decorates_if_enabled
        NewRelic::Agent::Hostname.stubs(:get).returns('localhost')
        Tracer.stubs(:current_trace_id).returns('trace_id')
        Tracer.stubs(:current_span_id).returns('span_id')

        decorated_message = LocalLogDecorator.decorate(MESSAGE)
        assert_equal decorated_message, "#{MESSAGE} NR-LINKING|GUID|localhost|trace_id|span_id|"
      end
    end
  end
end
