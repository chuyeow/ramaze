module Ramaze
  class Resolver
    attr_accessor :current

    def initialize(current)
      @current = current
    end

    # Entering point for Dispatcher, first Controller::resolve(path) and then
    # renders the resulting Action.

    def handle(path)
      action = resolve(path)
      current[:controller] = action.controller
      action.render
    end

    def resolve(path)
      mapping     = Global.mapping
      controllers = Global.controllers

      raise_no_controller(path) if controllers.empty? or mapping.empty?
      first_controller = nil

      # Look through the possible ways of interpreting the path until we find
      # one that matches an existing controller action.
      patterns_for(path) do |controller, method, params|
        if controller = mapping[controller]
          first_controller ||= controller

          action = controller.resolve_action(method, *params)
          next unless action

          template = action.template

          valid_action =
            if action_stack_size > 0 || Global.actionless_templates
              action.method or (params.empty? && template)
            else
              action.method
            end

          if valid_action
            action.context = current
            # TODO:
            #   * dangerous as well
            #     Cache.resolved[path] = action
            return action
          end
        end
      end

      raise_no_action(first_controller, path) if first_controller
      raise_no_controller(path)
    end

    # Iterator that yields potential ways in which a given path could be mapped
    # to controller, action and params. It produces them in strict order, with
    # longest controller path favoured, then longest action path.

    def patterns_for path
      # Split into fragments, and remove empty ones (which split may have output).
      # The to_s is vital as sometimes we are passed an array.
      fragments = path.to_s.split '/'
      fragments.delete ''

      # Work through all the possible splits of controller and 'the rest' (action
      # + params) starting with longest possible controller.
      fragments.length.downto(0) do |ca_split|
        controller = '/' + fragments[0...ca_split].join('/')

        # Work on the remaining portion, generating all the action/params splits.
        fragments.length.downto(ca_split) do |ap_split|
          action = fragments[ca_split...ap_split].join '__'
          params = fragments[ap_split..-1]
          if action.empty?
            yield controller, 'index', params
          else
            yield controller, "#{action}__index", params
            yield controller, action, params
          end
        end
      end
    end

    def action_stack_size
      (current[:action_stack] ||= []).size
    end

    # Raises Ramaze::Error::NoFilter
    # TODO:
    #   * is this called at all for anybody?
    #     I think everybody does have filters.

    def raise_no_filter(path)
      raise Ramaze::Error::NoFilter, "No Filter found for `#{path}'"
    end

    # Raises Ramaze::Error::NoController

    def raise_no_controller(path)
      raise Ramaze::Error::NoController, "No Controller found for `#{path}'"
    end

    # Raises Ramaze::Error::NoAction

    def raise_no_action(controller, path)
      current.controller = controller
      # Thread.current[:controller] = controller
      raise Ramaze::Error::NoAction, "No Action found for `#{path}' on #{controller}"
    end
  end
end
