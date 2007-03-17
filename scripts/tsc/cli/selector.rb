# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

require 'tsc/cli/response.rb'

module TSC
  module CLI
    class Selector
      attr_reader :communicator, :config, :decorators

      def initialize(config, communicator, decorators = {})
        @config = config
        @communicator = communicator

        @decorators = Hash[
          :selector => proc { |_message|
            "#{_message.capitalize} (select a number)"
          },
          :question => proc { |_message|
            _message.capitalize
          }
        ].update(decorators)

        config[:other] = true if other.nil? && choices.empty?
        config[:other] = nil if other == false
      end

      def start
        pool = [ preferred, current, *choices ].compact.uniq
        if none or select or pool.size > 1 or Array(pool.first).size > 1
          menu
        else
          (pool.empty? or other) ? question(pool.first) : menu
        end
      end

      def menu
        @registry = []
        communicator.choose { |_menu|
          _menu.select_by = :index
          _menu.header = decorators[:selector][header]
          _menu.default = default_item_number.to_s

          add_category _menu, :current, :preferred
          add_category _menu, :select do
            throw :SELECT
          end

          choices.each do |_choice|
            item = Array(_choice)

            result = item.first
            display = item.last
            
            if register_item(:choice, result)
              add_choice _menu, display do
                Response.selected(result)
              end
            end
          end

          add_category _menu, :other do
            question(current || preferred)
          end

          add_category _menu, :none do
            nil
          end
        }
      end

      def question(answer)
        Response.entered(
          communicator.ask("#{decorators[:question][header]}? ") { |_question|
            _question.default = answer if answer
          }
        )
      end

      private
      #######

      def default_item_number
        [ config[:default].to_i, 1 ].max
      end

      def header
        config[:header]
      end

      def preferred
        config[:preferred]
      end

      def current
        config[:current]
      end

      def other
        config[:other]
      end

      def select
        config[:select]
      end

      def none
        config[:none]
      end

      def choices
        @choices ||= Array(config[:choices]).compact
      end

      def add_choice(menu, choice, &block)
        menu.choice figure_item(choice), &(block || proc { choice })
      end

      def figure_item(choice)
        @registry.size == default_item_number ? "[#{choice}]" : choice
      end

      def add_category(menu, *categories, &block)
        categories.each do |_category|
          item = config[_category]
          next unless register_item(_category, item)

          if block
            label = case item
              when true
                "#{_category} ..."
              when false
                _category
              when String
                "#{item} ..."
            end

            add_choice menu, "<#{label}>", &block
          else
            add_choice(menu, "#{_category} => #{item}") {
              Response.selected(item)
            }
          end
        end
      end

      def register_item(category, item)
        return false if item.nil?

        entry = case item
          when true, false
            [ category, item ]
          else
            item
        end
        return false if @registry.include? entry

        @registry.push entry
      end
    end
  end
end

if $0 == __FILE__ or defined?(Test::Unit::TestCase)
  require 'test/unit'
  
  class TSC::CLI::SelectorTest < Test::Unit::TestCase
    def setup
    end
    
    def teardown
    end
  end
end
