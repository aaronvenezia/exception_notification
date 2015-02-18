module ExceptionNotifier
  class HipchatNotifier

    attr_accessor :from
    attr_accessor :room
    attr_accessor :message_options

    def initialize(options)
      begin
        api_token         = options.delete(:api_token)
        room_name         = options.delete(:room_name)
        opts              = {
            :api_version => options.delete(:api_version) || 'v1',
            :server_url => options.delete(:server_url) || nil
        }
        @from             = options.delete(:from) || 'Exception'
        @room             = HipChat::Client.new(api_token, opts)[room_name]
        @message_template = options.delete(:message_template) || ->(exception, the_options) {
          puts the_options[:env]['exception_notifier.exception_data']
          if the_options
            data = the_options[:env]['exception_notifier.exception_data']
            "User: #{data[:user]} from #{data[:company]} Getting Exception: '#{exception.message.split('<').join('').split('>').join('')}' on '#{exception.backtrace.first}'"
          else
            "Exception: '#{exception.message.split('<').join('').split('>').join('')}' on '#{exception.backtrace.first}'"
          end
        }
        @message_options  = options
        @message_options[:color] ||= 'red'
      rescue
        @room = nil
      end
    end

    def call(exception, options={})
      return if !active?

      message = @message_template.call(exception, options)
      @room.send(@from, message, @message_options)
    end

    private

    def active?
      !@room.nil?
    end
  end
end
