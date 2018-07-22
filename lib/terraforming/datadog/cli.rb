module Terraforming
  module Datadog
    class CLI < Thor
      def self.cli_options
        option :tfstate, type: :boolean
        option :api_key, type: :string
        option :app_key, type: :string
      end

      desc "monitors", "Datadog Monitors"
      cli_options
      def ddm
        execute(Terraforming::Resource::DatadogMonitor, options)
      end

      desc "timeboards", "Datadog Timeboards"
      cli_options
      def timeboards
        execute(Terraforming::Resource::DatadogTimeboards, options)
      end

      desc "version", "terraforming-datadog version"
      cli_options
      def version
        puts Terraforming::Datadog::VERSION
      end

      private

      def execute(klass, options)
        api_key = options[:api_key] || ENV["DATADOG_API_KEY"]
        app_key = options[:app_key] || ENV["DATADOG_APP_KEY"]
        if not (api_key and app_key)
          puts "Please provide an API key to submit your data"
          exit(1)
        end
        client = Dogapi::Client.new(api_key, app_key)
        puts options[:tfstate] ? klass.tfstate(client) : klass.tf(client)
      end
    end
  end
end
