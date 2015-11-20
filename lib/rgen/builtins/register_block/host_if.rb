RGen.list_item(:register_block, :host_if) do
  shared_context do
    attr_accessor :enabled_host_ifs
  end

  configuration do
    item_base do
      field :host_if do
        @host_if || shared_context.enabled_host_ifs.first
      end

      build do |value|
        @host_if  = shared_context.enabled_host_ifs.find do |host_if|
          host_if.to_sym.casecmp(value.to_sym) == 0
        end
        if @host_if.nil?
          error "unknown host interface: #{value}"
        end
      end
    end

    def build_factory
      f             = @factory.new
      f.target_item = item_base
      f
    end
  end

  rtl do
    shared_context.enabled_host_ifs = @enabled_items

    item_base do
      build do
        group(:host_if) do
          logic :command_valid , width: 1
          logic :write         , width: 1
          logic :read          , width: 1
          logic :address       , width: address_width
          logic :write_data    , width: configuration.data_width
          logic :write_mask    , width: configuration.data_width
          logic :response_valid, width: 1
          logic :read_data     , width: configuration.data_width
          logic :status        , width: 3
        end
      end

      def address_width
        Math.log2(source.byte_size).ceil
      end
    end

    factory do
      def select_target_item(configuration, register_block)
        @target_items[configuration.host_if]
      end
    end
  end
end
