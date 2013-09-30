require "cf/cli/app/base"

module CF::App
  class Scale < Base
    desc "Update the instances/memory limit for an application"
    group :apps, :info
    input :app, :desc => "Application to update", :argument => true,
          :from_given => by_name(:app)
    input :instances, :desc => "Number of instances to run",
          :type => :numeric
    input :memory, :desc => "Memory limit"
    input :cpu_quota, :desc => "Cpu quota"
    input :disk, :desc => "Disk quota"
    input :restart, :desc => "Restart app after updating?", :default => true

    def scale
      app = input[:app]

      if input.has?(:instances)
        instances = input[:instances, app.total_instances]
      end

      if input.has?(:memory)
        memory = input[:memory, app.memory]
      end

      if input.has?(:cpu_quota)
        cpu_quota = input[:cpu_quota, app.cpu_quota]
      end

      if input.has?(:disk)
        disk = input[:disk, human_mb(app.disk_quota)]
      end

      unless instances || memory || disk || cpu_quota
        instances = input[:instances, app.total_instances]
        memory = input[:memory, app.memory]
        cpu_quota = input[:cpu_quota, app.cpu_quota]
      end

      app.total_instances = instances if input.has?(:instances)
      app.memory = megabytes(memory) if input.has?(:memory)
      app.disk_quota = megabytes(disk) if input.has?(:disk)
      app.cpu_quota = cpu_quota if input.has?(:cpu_quota)

      fail "No changes!" unless app.changed?

      with_progress("Scaling #{c(app.name, :name)}") do
        app.update!
      end

      needs_restart = app.changes.key?(:memory) || app.changes.key?(:disk_quota)

      if needs_restart && app.started? && input[:restart]
        invoke :restart, :app => app
      end
    end

    private

    def ask_instances(default)
      ask("Instances", :default => default)
    end

    def ask_memory(default)
      ask("Memory Limit", :choices => memory_choices,
          :default => human_mb(default), :allow_other => true)
    end

    def ask_cpu_quota(default)
      ask("Cpu cores", :choices => cpu_choices,
          :default => '0.1', :allow_other => true)
    end

  end
end
