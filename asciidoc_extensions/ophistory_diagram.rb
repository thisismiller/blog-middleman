require 'asciidoctor/extensions'
require 'asciidoctor-diagram/diagram_processor'
require 'asciidoctor-diagram/diagram_converter'
require 'asciidoctor-diagram/util/cli'
require 'asciidoctor-diagram/util/cli_generator'
require 'asciidoctor-diagram/util/platform'

module Asciidoctor
  module Diagram

    class OpHistoryConverter
      include DiagramConverter
      include CliGenerator

      def supported_formats
        [:svg]
      end

      def collect_options(source)
        options = source.attr('options', '').split(',')

        {}
      end

      def convert(source, format, options)
        generate_file(source.find_command('ophistory'), 'txt', format.to_s, source.to_s) do |tool_path, input_path, output_path|
          args = [tool_path, "--embed", Platform.native_path(input_path), "-o#{Platform.native_path(output_path)}"]

          args
        end

      end
    end

    class OpHistoryBlockProcessor < DiagramBlockProcessor
      use_converter OpHistoryConverter
    end

    class OpHistoryBlockMacroProcessor < DiagramBlockMacroProcessor
      use_converter OpHistoryConverter
    end

    class OpHistoryInlineMacroProcessor < DiagramInlineMacroProcessor
      use_converter OpHistoryConverter
    end

  end
end

Asciidoctor::Extensions.register do
  block Asciidoctor::Diagram::OpHistoryBlockProcessor, :ophistory
  block_macro Asciidoctor::Diagram::OpHistoryBlockMacroProcessor, :ophistory
  inline_macro Asciidoctor::Diagram::OpHistoryInlineMacroProcessor, :ophistory
end
