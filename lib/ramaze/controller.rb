#          Copyright (c) 2008 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'ramaze/helper'
require 'ramaze/template'
require 'ramaze/action'

require 'ramaze/controller/error'

module Ramaze

  # The Controller is responsible for combining and rendering actions.

  class Controller
    include Helper::Methods

    helper :redirect, :link, :sendfile, :flash, :cgi, :partial

    # Whether or not to map this controller on startup automatically

    trait[:automap] ||= true

    # Place to map the Controller to, this is something like '/' or '/foo'

    trait[:map] ||= nil

    # Caches patterns for the given path.

    trait :pattern_cache => Hash.new{|h,k| h[k] = Controller.pattern_for(k) }

    class << self
      # When Controller is subclassed the resulting class is placed in
      # Global.controllers and a new trait :actions_cached is set on it.

      def inherited controller
        controller.trait :actions_cached => {}
        Global.controllers << controller
        if map = controller.mapping
          Log.dev("mapping #{map} => #{controller}")
          Global.mapping[map] ||= controller
        end
      end

      # called from Ramaze.startup, adds Cache.actions and Cache.patterns, walks
      # all controllers subclassed so far and adds them to the Global.mapping if
      # they are not assigned yet.

      def startup options = {}
        Log.dev("found Controllers: #{Global.controllers.inspect}")

        check_path("Public root: '%s' doesn't exist", Global.public_root)
        check_path("View root: '%s' doesn't exist", Global.view_root)

        require 'ramaze/controller/main' if Global.mapping.empty?

        Log.debug("mapped Controllers: #{Global.mapping.inspect}")
      end

      # checks paths for existance and logs a warning if it doesn't exist yet.

      def check_path(message, *paths)
        paths.each do |path|
          Log.warn(message % path) unless File.directory?(path)
        end
      end

      # if trait[:automap] is set and controller is not in Global.mapping yet
      # this will build a new default mapping-point, MainController is put
      # at '/' by default.

      def mapping
        global_mapping = Global.mapping.invert[self]
        return global_mapping if global_mapping
        if ancestral_trait[:automap] && self.to_s !~ /#<Class:/
          name = self.to_s.gsub('Controller', '').gsub('::', '/').clone
          name == 'Main' ? '/' : "/#{name.snake_case}"
        end
      end

      # Map Controller to the given syms or strings.
      # Replaces old mappings.
      # If you want to _add_ a mapping, just modify Global.mapping.

      def map(*syms)
        Global.mapping.delete_if{|k,v| v == self}

        syms.each do |sym|
          Global.mapping[sym.to_s] = self
        end
      end

      # Returns the Controller at a mapped path.

      def at(mapping)
        Global.mapping[mapping.to_s]
      end

      # Define a layout for all actions on this controller
      #
      # Example:
      #   class Foo < Ramaze::Controller
      #     layout :foo
      #   end
      #
      #  This defines the action :foo to be layout of the controller and will
      #  render the layout after any other action has been rendered, assigns
      #  @content to the result of the action and then goes on rendering
      #  the layout-action where @content may or may not be used, returning
      #  whatever the layout returns.

      def layout(*meth_or_hash)
        if meth_or_hash.empty?
          trait[:layout] ||= (
            ancestral_trait[:layout] || {:all => nil, :deny => Set.new} ).dup
        else
          meth_or_hash = meth_or_hash.first
          if meth_or_hash.respond_to?(:to_hash)
            meth_or_hash.each do |layout_name, *actions|
              actions.flatten.each do |action|
                layout[action.to_s] = layout_name
              end
            end
          else
            layout[:all] = meth_or_hash
          end
        end
      end

      # Deny layout for passed names of actions.
      # Name should be name of the method or template without extension, as
      # String or Symbol
      #
      # Usage:
      #   class MainController < Ramaze::Controller
      #     deny_layout :atom
      #
      #     def atom
      #       "I won't have layout"
      #     end
      #   end

      def deny_layout(*actions)
        actions.each do |action|
          layout[:deny] << action.to_s
        end
      end

      # Define a view_root for Controller, returns the current view_root
      # if no argument is given.
      # Runs every given path through Controller::check_path

      def view_root *args
        if args.empty?
          @view_root
        else
          check_path("#{self}.view_root: '%s' doesn't exist", *args)
          @view_root = args.flatten
        end
      end

      # This is used for template rerouting, takes action, optionally a
      # controller and action to route to.
      #
      # Usage:
      #   class MainController
      #     template :index, OtherController, :list
      #     template :foo, :bar
      #     template :bar, :file => '/absolute/path'
      #     template :baz, :file => 'relative/path'
      #     template :abc, :controller => OtherController
      #     template :xyz, :controller => OtherController, :action => 'list'
      #
      #     def index
      #       'will use template from OtherController#list'
      #     end
      #
      #     def foo
      #       'will use template from self#bar'
      #     end
      #
      #     def bar
      #       'will use template from /absolute/path'
      #     end
      #
      #     def baz
      #       'will use template from relative/path'
      #     end
      #
      #     def abc
      #       'will use template from OtherController#index'
      #     end
      #
      #     def xyz
      #       'will use template from OtherController#list'
      #     end
      #   end

      def template(this, *argv)
        case argv.first
        when Hash
          options, *ignored = argv
          controller = options[:controller] || options['controller']
          action = options[:action] || options['action']
          file = options[:file] || options['file']
          info = {}
          if file
            file = file.to_s
            unless Pathname(file).absolute?
              root = [view_root || Global.view_root].flatten.first
              file = File.join(root, file)
            end
            info[:file] = file
          else
            controller ||= self
            action = (action || 'index').to_s
            info[:controller] = controller
            info[:action] = action
          end
          trait "#{this}_template" => info
        else
          controller, action, *ignored = argv
          controller, action = self, controller unless action
          trait "#{this}_template" => {:controller => controller, :action => action}
        end
      end

      # Try to produce an Action from the given path and paremters with the
      # appropiate template if one exists.

      def resolve_action(path, *parameter)
        path, parameter = path.to_s, parameter.map{|e| e.to_s}

        if info = trait["#{path}_template"]
          unless template = info[:file]
            controller, action = info.values_at(:controller, :action)
            template = resolve_template(action)
          end
        end

        method, params = resolve_method(path, *parameter)

        if method or parameter.empty?
          template ||= resolve_template(path)
        end

        action = Action.create(:controller => self,
                               :method => method,
                               :params => params,
                               :path => path,
                               :template => template)

        return false unless action.valid_rest?
        action
      end

      # Composes an array with the template-paths to look up in the right order.
      # Usually this is composed of Global.view_root and the mapping of the
      # controller.

      def template_paths
        if paths = view_root
          paths
        else
          view_root(Global.view_root / mapping)
        end
      end

      # Search the #template_paths for a fitting template for path.
      # Only the first found possibility for the generated glob is returned.

      def resolve_template(path)
        path = path.to_s
        path_converted = path.split('__').inject{|s,v| s/v}
        possible_paths = [path, path_converted].compact

        paths = template_paths.map{|pa|
          possible_paths.map{|a| pa/a }
        }.flatten.uniq

        glob = "{#{paths.join(',')}}.{#{extension_order.join(',')}}"

        Dir[glob].first
      end

      # Uses custom defined engines and all available engines and throws it
      # against the extensions for the template to find the most likely
      # templating-engine to use ordered by priority and likelyhood.

      def extension_order
        t_extensions = Template::ENGINES
        all_extensions = t_extensions.values.flatten

        if engine = trait[:engine]
          c_extensions = t_extensions.select{|k,v| k == engine}.map{|k,v| v}.flatten
          return (c_extensions + all_extensions).uniq
        end

        all_extensions
      end

      # Based on methodname and arity, tries to find the right method on
      # current controller.
      def resolve_method(name, *params)
        cam = cached_action_methods

        if cam.include?(name)
          method = name
        else
          name = name.gsub(/__/, '/')
          method = name if cam.include?(name)
        end

        if method
          arity = instance_method(method).arity
          if arity < 0 or params.size == arity
            return method, params
          end
        end

        return nil, []
      end

      # List or create a list of action methods to be cached

      def cached_action_methods
        Cache.action_methods[self] ||= action_methods
      end

      # methodnames that may be used for current controller.
      def action_methods
        ancs = relevant_ancestors + Helper::LOOKUP.to_a

        ancs.reverse.inject [] do |meths, anc|
          meths +
            anc.public_instance_methods(false).map{|im| im.to_s } -
            anc.private_instance_methods(false).map{|im| im.to_s }
        end
      end

      # This is a method to specify the templating engine for your controller.
      # It basically just is sugar for:
      #   trait :engine => Haml
      #
      # Usage:
      #   class MainController < Ramaze::Controller
      #     engine :Haml
      #   end

      def engine(name)
        name = Template.const_get(name)
      rescue NameError => ex
        Log.warn ex
        Log.warn "Try to use passed engine directly"
      ensure
        trait :engine => name
      end

      def relevant_ancestors(parent = Ramaze::Controller)
        ancestors.select do |anc|
          anc.ancestors.include?(parent)
        end
      end
    end

    attr_accessor :context

    def initialize(context)
      @context = context
    end

    private

    # Simplistic render, rerouting to Controller.handle(*args)

    def render *args
      self.class.handle(*args)
    end
  end
end
