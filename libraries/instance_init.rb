
require File.expand_path('../helpers', __FILE__)

class Logstash
  class Instance
    class Init

      include Helpers::Logstash

      def initialize(new_resource, run_context=nil)
        @new_resource = new_resource
        @run_context = run_context
      end

      def create
        create_service_script
      end

      def enable
        enable_service
      end

      def disable
        disable_service
      end

      def jar_path
        logstash_jar_with_path(@new_resource.dst_dir, @new_resource.version)
      end

      def ls_svc
        logstash_service(@new_resource.name)
      end

      def ls_dir
        logstash_conf_dir(@new_resource.conf_dir, @new_resource.name)
      end

      def conf_file
        logstash_config_file(@new_resource.conf_dir, @new_resource.name)
      end

      private

      def create_service_script
        r = Chef::Resource::Template.new(logstash_service(@new_resource.name), @run_context)
        r.cookbook 'logstash'
        r.source   'logstash-init.erb'
        r.path     ::File.join('', '/etc/init.d', ls_svc)
        r.variables({
            :conf_file       => conf_file,
            :jar_path        => jar_path,
            :name            => @new_resource.name,
            :service_options => @new_resource.service_options,
            :user            => @new_resource.user,
          })
        r.run_action(:create)
      end

      def enable_service
        if ::File.directory?(ls_dir)
          if logstash_has_configs?(ls_dir)
            s = Chef::Resource::Service.new(ls_svc, @run_context)
            s.run_action([:enable, :start])
          else
            Chef::Log.info("#{ ls_dir } has no configs. Not enabling #{ ls_svc }.")
          end
        else
          Chef::Log.info("#{ ls_dir } does not exist. Not enabling #{ ls_svc }.")
        end
      end

      def disable_service
        s = Chef::Resource::Service.new(ls_svc, @run_context)
        s.run_action([:disable, :stop])
      end

    end
  end
end
