#
# Fluent
#
# Copyright (C) 2011 FURUHASHI Sadayuki
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
require 'fluent/plugin/bare_output'
require 'fluent/match'

module Fluent::Plugin
  class RouteOutput < BareOutput
    Fluent::Plugin.register_output('route', self)

    helpers :event_emitter

    config_section :route, param_name: :route_configs, multi: true, required: true do
      config_argument :pattern, :string, default: '**'
      config_param :@label, :string, default: nil
      config_param :remove_tag_prefix, :string, default: nil
      config_param :add_tag_prefix, :string, default: nil
      config_param :copy, :bool, default: false
    end

    config_param :remove_tag_prefix, :string, default: nil
    config_param :add_tag_prefix, :string, default: nil

    config_param :match_cache_size, :integer, default: 256
    config_param :tag_cache_size, :integer, default: 256

    attr_reader :routes

    def tag_modifier(remove_tag_prefix, add_tag_prefix)
      tag_cache_size = @tag_cache_size
      cache = {}
      mutex = Mutex.new
      removed_prefix = remove_tag_prefix ? remove_tag_prefix + "." : ""
      added_prefix = add_tag_prefix ? add_tag_prefix + "." : ""
      ->(tag){
        if cached = cache[tag]
          cached
        else
          modified = tag.start_with?(removed_prefix) ? tag.sub(removed_prefix, added_prefix) : added_prefix + tag
          mutex.synchronize do
            if cache.size >= tag_cache_size
              remove_keys = cache.keys[0...(tag_cache_size / 2)]
              cache.delete_if{|key, _value| remove_keys.include?(key) }
            end
            cache[tag] = modified
          end
          modified
        end
      }
    end

    def configure(conf)
      if conf.elements(name: 'store').size > 0
        raise Fluent::ConfigError, "<store> section is not available in route plugin"
      end

      super

      @match_cache = {}
      @routes = []
      @route_configs.each do |rc|
        route_router = event_emitter_router(rc['@label'])
        modifier = tag_modifier(rc.remove_tag_prefix, rc.add_tag_prefix)
        @routes << Route.new(rc.pattern, route_router, modifier, rc.copy)
      end
      @default_tag_modifier = (@remove_tag_prefix || @add_tag_prefix) ? tag_modifier(@remove_tag_prefix, @add_tag_prefix) : nil
      @mutex = Mutex.new
    end

    class Route
      def initialize(pattern, router, tag_modifier, copy)
        @router = router
        @pattern = Fluent::MatchPattern.create(pattern)
        @tag_modifier = tag_modifier
        @copy = copy
      end

      def match?(tag)
        @pattern.match(tag)
      end

      def copy?
        @copy
      end

      def emit(tag, es)
        tag = @tag_modifier.call(tag)
        @router.emit_stream(tag, es)
      end
    end

    def process(tag, es)
      modified_tag, targets = @match_cache[tag]
      unless targets
        modified_tag = @default_tag_modifier ? @default_tag_modifier.call(tag) : tag
        targets = []
        @routes.each do |r|
          if r.match?(modified_tag)
            targets << r
            break unless r.copy?
          end
        end

        @mutex.synchronize do
          if @match_cache.size >= @match_cache_size
            remove_keys = @match_cache.keys[0...(@match_cache_size / 2)]
            @match_cache.delete_if{|key, _value| remove_keys.include?(key) }
          end
          @match_cache[tag] = [modified_tag, targets]
        end
      end

      case targets.size
      when 0
        # do nothing
      when 1
        targets.first.emit(modified_tag, es)
      else
        targets.each do |target|
          dup_es = if es.respond_to?(:dup)
                     es.dup
                   else
                     m_es = MultiEventStream.new
                     es.each{|t,r| m_es.add(t, r) }
                     m_es
                   end
          target.emit(modified_tag, dup_es)
        end
      end
    end
  end
end
