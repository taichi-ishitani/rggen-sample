define_list_item :bit_field, :type, :foo do
  register_map do
  end
end

define_list_item :register_block, :host_if, :bar do
  rtl do
  end
end

enable :global        , [:data_width, :address_width]
enable :register_block, [:name, :base_address]
enable :register      , [:offset_address, :name, :array, :shadow, :accessibility, :uniquness_validator]
enable :bit_field     , [:bit_assignment, :name, :type, :initial_value, :reference]
enable :bit_field     , :type, [:rw, :ro, :foo, :reserved]
enable :register_block, [:top_module, :clock_reset, :host_if, :response_mux]
enable :register_block, :host_if, [:apb, :bar]
enable :register      , [:address_decoder, :read_data]
enable :register_block, [:ral_package_definition, :block_model_definition, :reg_model_declarations, :block_model_constructor, :reg_model_creator, :block_model_default_map_creator]
enable :register      , [:reg_model_definition, :field_model_declarations, :reg_model_constructor, :field_model_creator, :shadow_index_configurator, :reg_model_declaration, :reg_model_creation]
enable :bit_field     , [:field_model_declaration, :field_model_creation]
