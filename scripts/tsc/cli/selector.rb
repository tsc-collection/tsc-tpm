# Copyright (c) 2006, Gennady Bystritsky <bystr@mac.com>
# 
# Distributed under the MIT Licence.
# This is free software. See 'LICENSE' for details.
# You must read and accept the license prior to use.

module TSC
  module CLI
    class Selector
      attr_reader :communicator, :config

      def initialize(config, communicator)
        @config = config
        @communicator = communicator

        @config[:other] = true if choices.empty?
      end

      def start
        pool = [ preferred, current, *choices ].compact.uniq
        if pool.size > 1
          menu
        else
          question pool.first
        end
      end

      def menu
        @registry = []
        communicator.choose { |_menu|
          _menu.select_by = :index
          _menu.header = "Please select #{header}"
          _menu.default = default_item_number.to_s

          add_category _menu, :current, :preferred

          choices.each do |_choice|
            add_choice _menu, _choice if register_item(_choice)
          end

          add_category _menu, :other do
            question(preferred || current)
          end
        }
      end

      def question(answer)
        communicator.ask("#{header}? ") { |_question|
          _question.default = answer if answer
        }
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

      def choices
        @choices ||= Array(config[:choices]).flatten.compact
      end

      def add_choice(menu, choice, &block)
        choice = "[#{choice}]" if @registry.size == default_item_number
        menu.choice choice, &block
      end

      def add_category(menu, *categories, &block)
        categories.each do |_category|
          item = config[_category]
          next unless register_item(item)

          if block
            add_choice menu, "<#{_category} ...>", &block
          else
            add_choice(menu, "#{_category} => #{item}") {
              item
            }
          end
        end
      end

      def register_item(item)
        return false unless item
        return false if @registry.include?(item)

        @registry.push item
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
