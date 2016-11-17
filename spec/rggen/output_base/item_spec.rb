require_relative '../../spec_helper'

module RgGen::OutputBase
  describe Item do
    before(:all) do
      @template_engine  = Class.new(TemplateEngine) do
        def file_extension
          :erb
        end
        def parse_template(path)
          BabyErubis::Text.new.from_str(File.read(path), path)
        end
        def render(context, template)
          template.render(context)
        end
      end
    end

    after do
      @template_engine.instance_eval { @templates.clear if @templates }
    end

    let(:configuration) do
      RgGen::InputBase::Component.new(nil)
    end

    let(:register_map) do
      RgGen::InputBase::Component.new(nil)
    end

    let(:component) do
      Component.new(nil, configuration, register_map)
    end

    let(:template_engine) do
      @template_engine.instance
    end

    let(:code) do
      double('code')
    end

    def define_item(base = Item, &body)
      Class.new(base, &body)
    end

    def create_item(klass)
      klass.new(component).tap { |item| component.add_item(item)}
    end

    def define_and_create_item(base = Item, &body)
      create_item(define_item(base, &body))
    end

    def expected_code(c)
      expect(code).to receive(:<<).with(c).ordered
    end

    describe "#build" do
      context ".buildでブロックが与えられた場合" do
        let(:item) do
          define_and_create_item do
            attr_reader :foo
            build { @foo  = object_id }
          end
        end

        it "登録されたブロックをアイテムのコンテキストで実行する" do
          item.build
          expect(item.foo).to eq item.object_id
        end

        context "継承されたとき" do
          let(:child_item) do
            define_and_create_item(item.class) do
              attr_reader :bar
              build { @bar  = object_id }
            end
          end

          let(:grandchild_item) do
            define_and_create_item(child_item.class) {}
          end

          specify "登録されたブロックが継承先に引き継がれる" do
            grandchild_item.build
            expect(grandchild_item.foo).to eq grandchild_item.object_id
            expect(grandchild_item.bar).to eq grandchild_item.object_id
          end
        end
      end
    end

    describe "#generate_pre_code" do
      context ".generate_pre_codeで登録されたコード生成ブロックの種類が指定された場合" do
        let(:foo_item) do
          define_and_create_item { generate_pre_code(:foo) { |c| c << 'foo' } }
        end

        let(:bar_item) do
          define_and_create_item { generate_pre_code(:bar) { 'bar' } }
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
        end

        it "指定されたコード生成ブロックを実行する" do
          foo_item.generate_pre_code(:foo, code)
          bar_item.generate_pre_code(:bar, code)
        end
      end

      context ".generate_pre_codeで複数回コード生成が登録された場合" do
        let(:item) do
          define_and_create_item do
            generate_pre_code(:foo) { 'foo' }
            generate_pre_code(:bar) { 'bar' }
            generate_pre_code(:baz) { 'baz' }
          end
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
          expect(code).not_to receive(:<<).with('baz')
        end

        it "指定された種類のコード生成ブロックを実行する" do
          item.generate_pre_code(:foo, code)
          item.generate_pre_code(:bar, code)
        end
      end

      context ".generate_pre_codeで登録されていないコード生成の種類が指定された場合" do
        let(:item) do
          define_and_create_item { generate_pre_code(:foo) { 'foo' } }
        end

        before do
          expect(code).not_to receive(:<<)
        end

        it "何も起こらない" do
          expect {
            item.generate_pre_code(:bar, code)
          }.not_to raise_error
        end
      end

      context "継承されたとき" do
        let(:item) do
          define_and_create_item { generate_pre_code(:foo) { 'foo' } }
        end

        let(:child_item) do
          define_and_create_item(item.class) { generate_pre_code(:bar) { 'bar' } }
        end

        let(:grandchild_item) do
          define_and_create_item(child_item.class) {}
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
        end

        specify "登録されたコード生成ブロックが継承先に引き継がれる" do
          grandchild_item.generate_pre_code(:foo, code)
          grandchild_item.generate_pre_code(:bar, code)
        end
      end

      context "継承先で同名のコード生成ブロックが登録された場合" do
        let(:item) do
          define_and_create_item { generate_pre_code(:foo) { 'foo' } }
        end

        let(:child_item) do
          define_and_create_item(item.class) { generate_pre_code(:foo) { 'bar' } }
        end

        specify "新しいコード生成ブロックで上書きされる" do
          expected_code 'bar'
          child_item.generate_pre_code(:foo, code)
        end

        specify "親クラスの生成ブロックは上書きされない" do
          expected_code 'foo'
          item.generate_pre_code(:foo, code)
        end
      end
    end

    describe "#generate_code" do
      context ".generate_codeで登録されたコード生成ブロックの種類が指定された場合" do
        let(:foo_item) do
          define_and_create_item {  generate_code(:foo) { |c| c << 'foo' } }
        end

        let(:bar_item) do
          define_and_create_item {  generate_code(:bar) { 'bar' } }
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
        end

        it "指定されたコード生成ブロックを実行する" do
          foo_item.generate_code(:foo, code)
          bar_item.generate_code(:bar, code)
        end
      end

      context ".generate_codeで複数回コード生成が登録された場合" do
        let(:item) do
          define_and_create_item do
            generate_code(:foo) { 'foo' }
            generate_code(:bar) { 'bar' }
            generate_code(:baz) { 'baz' }
          end
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
          expect(code).not_to receive(:<<).with('baz')
        end

        it "指定された種類のコード生成ブロックを実行する" do
          item.generate_code(:foo, code)
          item.generate_code(:bar, code)
        end
      end

      context ".generate_code_from_templateでテンプレートからのコード生成が設定された場合" do
        let(:template_content) do
          '<%= content %>'
        end

        let(:call_info) do
          /^#{__FILE__}/
        end

        let(:foo_item) do
          engine  = @template_engine
          define_and_create_item do
            template_engine engine
            generate_code_from_template(:foo)
            def content
              'foo'
            end
          end
        end

        let(:bar_item) do
          define_and_create_item(foo_item.class) do
            generate_code_from_template(:bar, 'bar.erb')
            def content
              'bar'
            end
          end
        end

        before do
          allow(File).to receive(:read).and_return(template_content)
          allow(template_engine).to receive(:process_template).and_call_original
          allow(template_engine).to receive(:process_template).and_call_original
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
        end

        it ".template_engineで登録されたテンプレートエンジンでテンプレートを処理し、コードを生成する" do
          foo_item.generate_code(:foo, code)
          bar_item.generate_code(:bar, code)
          expect(template_engine).to have_received(:process_template).with(foo_item, nil      , call_info)
          expect(template_engine).to have_received(:process_template).with(bar_item, 'bar.erb', call_info)
        end
      end

      context ".generate_codeで登録されていないコード生成の種類が指定された場合" do
        let(:item) do
          define_and_create_item { generate_code(:foo) { 'foo' } }
        end

        before do
          expect(code).not_to receive(:<<)
        end

        it "何も起こらない" do
          expect {
            item.generate_code(:bar, code)
          }.not_to raise_error
        end
      end

      context "継承されたとき" do
        let(:item) do
          define_and_create_item { generate_code(:foo) { 'foo' } }
        end

        let(:child_item) do
          define_and_create_item(item.class) { generate_code(:bar) { 'bar' } }
        end

        let(:grandchild_item) do
          define_and_create_item(child_item.class) {}
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
        end

        specify "登録されたコード生成ブロックが継承先に引き継がれる" do
          grandchild_item.generate_code(:foo, code)
          grandchild_item.generate_code(:bar, code)
        end
      end

      context "継承先で同名のコード生成ブロックが登録された場合" do
        let(:item) do
          define_and_create_item { generate_code(:foo) { 'foo' } }
        end

        let(:child_item) do
          define_and_create_item(item.class) { generate_code(:foo) { 'bar' } }
        end

        specify "新しいコード生成ブロックで上書きされる" do
          expected_code 'bar'
          child_item.generate_code(:foo, code)
        end

        specify "親クラスの生成ブロックは上書きされない" do
          expected_code 'foo'
          item.generate_code(:foo, code)
        end
      end
    end

    describe "#generate_post_code" do
      context ".generate_post_codeで登録されたコード生成ブロックの種類が指定された場合" do
        let(:foo_item) do
          define_and_create_item {  generate_post_code(:foo) { |c| c << 'foo' } }
        end

        let(:bar_item) do
          define_and_create_item {  generate_post_code(:bar) { 'bar' } }
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
        end

        it "指定されたコード生成ブロックを実行する" do
          foo_item.generate_post_code(:foo, code)
          bar_item.generate_post_code(:bar, code)
        end
      end

      context ".generate_post_codeで複数回コード生成が登録された場合" do
        let(:item) do
          define_and_create_item do
            generate_post_code(:foo) { 'foo' }
            generate_post_code(:bar) { 'bar' }
            generate_post_code(:baz) { 'baz' }
          end
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
          expect(code).not_to receive(:<<).with('baz')
        end

        it "指定された種類のコード生成ブロックを実行する" do
          item.generate_post_code(:foo, code)
          item.generate_post_code(:bar, code)
        end
      end

      context ".generate_post_codeで登録されていないコード生成の種類が指定された場合" do
        let(:item) do
          define_and_create_item { generate_post_code(:foo) { 'foo' } }
        end

        before do
          expect(code).not_to receive(:<<)
        end

        it "何も起こらない" do
          expect {
            item.generate_post_code(:bar, code)
          }.not_to raise_error
        end
      end

      context "継承されたとき" do
        let(:item) do
          define_and_create_item { generate_post_code(:foo) { 'foo' } }
        end

        let(:child_item) do
          define_and_create_item(item.class) { generate_post_code(:bar) { 'bar' } }
        end

        let(:grandchild_item) do
          define_and_create_item(child_item.class) {}
        end

        before do
          expected_code 'foo'
          expected_code 'bar'
        end

        specify "登録されたコード生成ブロックが継承先に引き継がれる" do
          grandchild_item.generate_post_code(:foo, code)
          grandchild_item.generate_post_code(:bar, code)
        end
      end

      context "継承先で同名のコード生成ブロックが登録された場合" do
        let(:item) do
          define_and_create_item { generate_post_code(:foo) { 'foo' } }
        end

        let(:child_item) do
          define_and_create_item(item.class) { generate_post_code(:foo) { 'bar' } }
        end

        specify "新しいコード生成ブロックで上書きされる" do
          expected_code 'bar'
          child_item.generate_post_code(:foo, code)
        end

        specify "親クラスの生成ブロックは上書きされない" do
          expected_code 'foo'
          item.generate_post_code(:foo, code)
        end
      end
    end

    describe "#write_file" do
      context ".write_fileでファイル名パターン、コード生成ブロックが登録されている場合" do
        before do
          allow(FileWriter).to receive(:new).and_wrap_original do |m, *args|
            m.call(*args).tap do |w|
              @writer = w
              allow(w).to receive(:write_file).and_call_original
            end
          end
        end

        let(:file_writer) do
          @writer
        end

        let(:foo_item) do
          define_and_create_item do
            write_file('<%= object_id %>.txt') { object_id }
          end
        end

        let(:bar_item) do
          create_item(foo_item.class)
        end

        it ".write_fileで登録されたファイル名パターン、コード生成ブロックをFileWriterオブジェクトで処理し、ファイルを書き出す" do
          expect {
            foo_item.write_file
            bar_item.write_file
            foo_item.write_file("foo")
            bar_item.write_file(["bar", "bar"])
          }.to write_binary_files [
            [        "#{foo_item.object_id}.txt", "#{foo_item.object_id}"],
            [        "#{bar_item.object_id}.txt", "#{bar_item.object_id}"],
            [    "foo/#{foo_item.object_id}.txt", "#{foo_item.object_id}"],
            ["bar/bar/#{bar_item.object_id}.txt", "#{bar_item.object_id}"]
          ]
          expect(file_writer).to have_received(:write_file).with(foo_item, nil)
          expect(file_writer).to have_received(:write_file).with(bar_item, nil)
          expect(file_writer).to have_received(:write_file).with(foo_item, "foo")
          expect(file_writer).to have_received(:write_file).with(bar_item, ["bar", "bar"])
        end

        specify "FileWriterオブジェクトはオブジェクト間で共有される" do
          allow(File).to receive(:binwrite)
          foo_item.write_file
          bar_item.write_file
          expect(FileWriter).to have_received(:new).once
        end
      end

      context ".write_fileで生成ブロックが登録されていない場合" do
        before do
          expect(FileWriter).not_to receive(:new)
        end

        let(:item) do
          define_and_create_item {}
        end

        it "何も起こらない" do
          expect {
            item.write_file
          }.not_to write_binary_file
        end
      end
    end

    describe "#process_template" do
      let(:template_content) do
        '<%= content %>'
      end

      let(:call_info) do
        /^#{__FILE__}/
      end

      let(:foo_item) do
        engine  = @template_engine
        define_and_create_item do
          template_engine engine
          generate_code(:foo) { |c| c << process_template }
          def content
            'foo'
          end
        end
      end

      let(:bar_item) do
        define_and_create_item(foo_item.class) do
          generate_code(:bar) { |c| c << process_template('bar.erb') }
          def content
            'bar'
          end
        end
      end

      before do
        allow(File).to receive(:read).and_return(template_content)
        allow(template_engine).to receive(:process_template).and_call_original
        allow(template_engine).to receive(:process_template).and_call_original
      end

      before do
        expected_code 'foo'
        expected_code 'bar'
      end

      it ".template_engineで登録されたテンプレートエンジンでテンプレートを処理し、コードを生成する" do
        foo_item.generate_code(:foo, code)
        bar_item.generate_code(:bar, code)
        expect(template_engine).to have_received(:process_template).with(foo_item, nil      , call_info)
        expect(template_engine).to have_received(:process_template).with(bar_item, 'bar.erb', call_info)
      end
    end

    describe "#exported_methods" do
      let(:item) do
        define_and_create_item do
          export :foo
          export :bar, :baz
        end
      end

      let(:child_item) do
        define_and_create_item(item.class) { export :qux }
      end

      let(:grandchild_item) do
        define_and_create_item(child_item.class) { export :quux }
      end

      it ".exportで登録されたメソッド名一覧を返す" do
        expect(item.exported_methods).to match [:foo, :bar, :baz]
      end

      specify "継承元のメソッド名一覧を引き継ぐ" do
        expect(     child_item.exported_methods).to match [:foo, :bar, :baz, :qux       ]
        expect(grandchild_item.exported_methods).to match [:foo, :bar, :baz, :qux, :quux]
      end
    end
  end
end
