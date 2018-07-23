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
        resources = dashboards.inject({}) do |result, dashboard|
          options = options_of(dashboard)
          attributes = {
            "id" => dashboard["id"].to_s,
            "title" => dashboard["description"],
            "description" => dashboard["description"],
            "read_only" => dashboard["read_only"]
          }

          def set(object, subject, prefix, key, default=nil)
            if default.nil?
              if subject.key?(key)
                object["#{prefix}.#{key}"] = subject[key]
              end
            else
              object["#{prefix}.#{key}"] = subject.key?(key) ? subject[key] : default
            end
          end

          if options.key?('graphs')
            options['graphs'].each_with_index do |graph, g_index|
              prefix = "graph.#{g_index}"
              set(attributes, graph, prefix, 'title')
              graph  = graph['definition']
              # --- scalars
              set(attributes, graph, prefix, 'viz')
              set(attributes, graph, prefix, 'autoscale')
              set(attributes, graph, prefix, 'precision')
              set(attributes, graph, prefix, 'custom_unit')
              set(attributes, graph, prefix, 'text_align')
              set(attributes, graph, prefix, 'include_no_metric_hosts')
              set(attributes, graph, prefix, 'include_ungrouped_hosts')
              # --- events
              if graph.key?('events')
                attributes["#{prefix}.events"] = graph['events'].map { |e| e['q'] }.join(',')
              end
              # --- yaxis
              if graph.key?('yaxis')
                y_prefix = "#{prefix}.yaxis"
                set(attributes, graph['yaxis'], y_prefix, 'min')
                set(attributes, graph['yaxis'], y_prefix, 'max')
                set(attributes, graph['yaxis'], y_prefix, 'scale')
              end
              # --- style
              if graph.key?('style')
                s_prefix = "#{prefix}.style"
                set(attributes, graph['style'], s_prefix, 'palette')
                set(attributes, graph['style'], s_prefix, 'palette_flip')
              end
              # --- markers
              if graph.key?('markers')
                graph['markers'].each_with_index do |marker, m_index|
                  m_prefix = "#{prefix}.marker.#{m_index}"
                  set(attributes, marker, m_prefix, 'type')
                  set(attributes, marker, m_prefix, 'value')
                  set(attributes, marker, m_prefix, 'label')
                end
              end
              # --- requests
              if graph.key?('requests')
                graph['requests'].each_with_index do |request, r_index|
                  r_prefix = "#{prefix}.request.#{r_index}"
                  if request.key?('style')
                    request['style'].each do |key, value|
                      attributes["#{r_prefix}.style.#{key}"] = value
                    end
                  end # end style
                  set(attributes, request, r_prefix, 'q')
                  set(attributes, request, r_prefix, 'aggregator')
                  set(attributes, request, r_prefix, 'type')
                  set(attributes, request, r_prefix, 'conditional_formats')
                end
              end # end request
            end
          else
            attributes['graph.#'] = '0'
          end # end graph

          result["datadog_timeboard.#{resource_name_of(dashboard)}"] = {
            "type" => "datadog_dashboard",
            "primary" => {
              "id" => dashboard["id"].to_s,
              "attributes" => attributes
            }
          }
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
        @client.get_dashboards[1]["dashes"]
      end

      def options_of(dashboard)
        @client.get_dashboard(id=dashboard["id"])[1]["dash"]
      end

      def resource_name_of(dashboard)
        dashboard["title"].gsub(/[^a-zA-Z0-9 ]/, "").gsub(" ", "-")
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
