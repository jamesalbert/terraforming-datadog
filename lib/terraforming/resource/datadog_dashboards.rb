module Terraforming
  module Resource
    class DatadogDashboards
      def self.tf(client = nil)
        self.new(client).tf
      end

      def self.tfstate(client = nil)
        self.new(client).tfstate
      end

      def initialize(client)
        @client = client
      end

      def tf
        apply_template(@client)
      end

      def tfstate
        puts(1)
        resources = dashboards.inject({}) do |result, monitor|
          puts(2)
          options = options_of(dashboard)
          result
        end

        generate_tfstate(resources)
      end

      private

      # TODO(dtan4): Use terraform's utility method
      def apply_template(client)
        ERB.new(open(template_path).read, nil, "-").result(binding)
      end

      def format_number(n)
        n.to_i == n ? n.to_i : n
      end

      def generate_tfstate(resources)
        JSON.pretty_generate({
          "version" => 1,
          "serial" => 1,
          "modules" => [
            {
              "path" => [
                "root"
              ],
              "outputs" => {},
              "resources" => resources,
            }
          ]
        })
      end

      def longest_key_length_of(hash)
        return 0 if hash.empty?
        hash.keys.sort_by { |k| k.length }.reverse[0].length
      end

      def dashboards
        @client.get_all_screenboards[1]
      end

      def options_of(monitor)
        monitor["options"]
      end

      def resource_name_of(monitor)
        monitor["name"].gsub(/[^a-zA-Z0-9 ]/, "").gsub(" ", "-")
      end

      def silenced_value(v)
        v.nil? ? 0 : v
      end

      def template_path
        File.join(File.expand_path(File.join(File.dirname(__FILE__), "..")), "template", "tf", "datadog_dashboards.erb")
      end
    end
  end
end
