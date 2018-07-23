require "spec_helper"

module Terraforming
  module Resource
    describe DatadogDashboards do
      let(:api_key) do
        "api_key"
      end

      let(:app_key) do
        "app_key"
      end

      let(:client) do
        Dogapi::Client.new(api_key, app_key)
      end

      let(:get_dashboards_response) do
        ["200",
         {"dashes"=>
           [{"read_only"=>false,
             "resource"=>"/api/v1/dash/234714",
             "description"=>"created by somebody@somewhere.com",
             "title"=>"somebody Test timeboard",
             "created"=>"2018-06-14T08:24:11.282198+00:00",
             "id"=>"835184",
             "created_by"=>
              {"disabled"=>false,
               "handle"=>"somebody@somewhere.com",
               "name"=>nil,
               "is_admin"=>true,
               "role"=>nil,
               "access_role"=>"adm",
               "verified"=>true,
               "email"=>"somebody@somewhere.com",
               "icon"=>
                "https://secure.gravatar.com/avatar/4557d7a1034d08021332122d621d8b80?s=48&d=retro"},
             "modified"=>"2018-06-14T08:24:11.282213+00:00"}]}]
      end

      let(:get_dashboard_response) do
        ["200",
         {"dash"=>
           {"read_only"=>false,
            "graphs"=>
             [{"definition"=>
                {"viz"=>"toplist",
                 "status"=>"done",
                 "requests"=>
                  [{"q"=>
                     "top(avg:nothing.command.execution{*} by {platform}.as_count(), 10, 'mean', 'desc')",
                    "style"=>
                     {"width"=>"normal", "palette"=>"dog_classic", "type"=>"solid"},
                    "type"=>nil,
                    "conditional_formats"=>[]}],
                 "autoscale"=>true},
               "title"=>"Avg of nothing.command.execution over * by platform"}],
            "description"=>"created by somebody@somewhere.com",
            "title"=>"nothing Usage",
            "created"=>"2018-06-09T03:50:27.700307+00:00",
            "id"=>831452,
            "created_by"=>
             {"disabled"=>false,
              "handle"=>"somebody@somewhere.com",
              "name"=>"no body",
              "is_admin"=>true,
              "role"=>nil,
              "access_role"=>"adm",
              "verified"=>true,
              "email"=>"somebody@somewhere.com",
              "icon"=>
               "https://secure.gravatar.com/avatar/f55138262e1f6a469c6a1035313ac2fb?s=48&d=retro"},
            "modified"=>"2018-06-15T08:31:10.783026+00:00"},
          "url"=>"/dash/234714/nothing-usage",
          "resource"=>"/api/v1/dash/234714"}]
      end

      before do
        allow(client).to receive(:get_dashboards).and_return(get_dashboards_response)
        allow(client).to receive(:get_dashboard).and_return(get_dashboard_response)
      end

      describe ".tf" do
        it "should generate tf" do
          expect(described_class.tf(client)).to eq <<-EOS
resource "datadog_timeboard" "somebody-Test-timeboard" {
  title       = "somebody Test timeboard"
  description = "created by somebody@somewhere.com"
  read_only   = false

  graph {
    title = ""
    viz   = "toplist"

    request {
      q = "top(avg:nothing.command.execution{*} by {platform}.as_count(), 10, 'mean', 'desc')"
      type = ""
      style {
        palette = "dog_classic"
        type = "solid"
        width = "normal"
      }
    }

  }
}
          EOS
        end
      end

      describe ".tfstate" do
        it "should generate tfstate" do
          expect(described_class.tfstate(client)).to eq JSON.pretty_generate({
            "version": 1,
            "serial": 1,
            "modules": [
              {
                "path": [
                  "root"
                ],
                "outputs": {
                },
                "resources": {
                  "datadog_timeboard.somebody-Test-timeboard": {
                    "type": "datadog_dashboard",
                    "primary": {
                      "id": "835184",
                      "attributes": {
                        "id": "835184",
                        "title": "created by somebody@somewhere.com",
                        "description": "created by somebody@somewhere.com",
                        "read_only": false,
                        "graph.0.viz": "toplist",
                        "graph.0.autoscale": true,
                        "graph.0.request.0.style.width": "normal",
                        "graph.0.request.0.style.palette": "dog_classic",
                        "graph.0.request.0.style.type": "solid",
                        "graph.0.request.0.q": "top(avg:nothing.command.execution{*} by {platform}.as_count(), 10, 'mean', 'desc')",
                        "graph.0.request.0.type": nil,
                        "graph.0.request.0.conditional_formats": [

                        ]
                      }
                    }
                  }
                }
              }
            ]
          })
        end
      end
    end
  end
end
