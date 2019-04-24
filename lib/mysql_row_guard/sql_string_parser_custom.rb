require 'mysql_row_guard'
require 'parslet'

module MysqlRowGuard
  class SqlStringParserCustom
    attr_reader :buffer, :output, :previous

    BREAK_CHARS = [' ', '`', '.', ',', '(', ')']
    NON_WORD = /\W/

    DOUBLE_QUOTE = '"'
    SINGLE_QUOTE = "'"
    STRING_ESCAPE = '\\'

    def initialize(tables: {})
      @buffer = []
      @output = ''
      @tables = tables
      @previous = ''
    end

    def parse(text)
      text.each_char do |char|
        case char
        when DOUBLE_QUOTE
          if buffer.first == DOUBLE_QUOTE # end_quote?
            buffer_add(char)
            flush_quote unless [STRING_ESCAPE, DOUBLE_QUOTE].include?(buffer[-2]) #escaped_quote?
          elsif buffer.first == SINGLE_QUOTE
            buffer_add(char)
          else
            flush
            buffer_add(char)
          end
        when SINGLE_QUOTE
          if buffer.first == SINGLE_QUOTE # end_quote?
            buffer_add(char)
            flush_quote unless [STRING_ESCAPE, SINGLE_QUOTE].include?(buffer[-2]) #escaped_quote?
          elsif buffer.first == DOUBLE_QUOTE
            buffer_add(char)
          else
            flush
            buffer_add(char)
          end
        when NON_WORD
          flush if previous !~ NON_WORD
          buffer_add(char)
        else
          flush if previous =~ NON_WORD
          buffer_add(char)
        end
      end

      flush
      flush_quote
      output
    end

    private

    def buffer_add(char)
      @previous = char
      @buffer << char
    end

    def flush_quote
      if buffer.any?
        @output << buffer.join
        reset_buffer
      end
    end

    def flush
      if buffer.any? && !buffer_is_quote?
        string = buffer.join
        @output << (@tables[string.downcase] || string)
        reset_buffer
      end
    end

    def buffer_is_quote?
      [SINGLE_QUOTE, DOUBLE_QUOTE].include?(buffer.first)
    end

    def reset_buffer
      @buffer = []
      @previous = ''
    end
  end


  # class SqlStringCommandParserCustom
  #   attr_reader :buffer, :output
  #
  #   WHITESPACE = /\s/
  #   NON_WHITESPACE = /\S/
  #
  #   def initialize
  #     @buffer = []
  #     @output = []
  #   end
  #
  #   def parse(text)
  #     text.each_char do |char|
  #       case char
  #       when WHITESPACE
  #         flush if previous.match(NON_WHITESPACE)
  #         @buffer << char
  #       else
  #         flush if previous.match(WHITESPACE)
  #         @buffer << char
  #       end
  #     end
  #
  #     flush
  #     output
  #   end
  #
  #   private
  #
  #   def flush
  #     if buffer.any?
  #       @output << buffer.join
  #       @buffer = []
  #     end
  #   end
  #
  #   def previous
  #     buffer.last || ''
  #   end
  # end
  #
  # class SqlStringTransformerCustom
  #   def initialize(&block)
  #     @command = block
  #   end
  #
  #   def apply(parsed)
  #     parsed.map do |item|
  #       if item[:command]
  #         @command.call(item[:command])
  #       else
  #         item[:string]
  #       end
  #     end
  #   end
  # end

  # class QuoteParser
  #   QUOTE_ESCAPE = '\\'
  #
  #   def self.for(quote: '"', buffer: buffer)
  #     if buffer.first == quote # end_quote?
  #       if [QUOTE_ESCAPES, quote].include?(buffer[-2]) #escaped_quote?
  #         :nil
  #       else
  #         :string
  #       end
  #     else
  #       :command
  #     end
  #   end
  #
  #   def initalize(buffer: buffer, char: char)
  #
  #   end
  #
  #   def parse
  #     yield
  #     flush()
  #   end
  # end
  #
  # class QuoteParserString
  #   attr_reader :buffer
  #   def initialize(buffer: )
  #     @buffer = buffer
  #   end
  #
  #   def parse
  #     yield
  #     buffer.flush(:string)
  #   end
  # end
end
