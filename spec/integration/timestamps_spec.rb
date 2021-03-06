require 'spec_helper'

describe 'DataMapper::Timestamp' do

  supported_by :all do

    RSpec.shared_examples_for "Timestamp (shared behavior)", :shared => true do
      it "should not set the created_at/on fields if they're already set" do
        green_smoothie = GreenSmoothie.new(:name => 'Banana')
        time = (DateTime.now - 100)
        green_smoothie.created_at = time
        green_smoothie.created_on = time
        green_smoothie.save
        expect(green_smoothie.created_at).to eq(time)
        expect(green_smoothie.created_on).to eq(time)
        expect(green_smoothie.created_at).to be_a_kind_of(DateTime)
        expect(green_smoothie.created_on).to be_a_kind_of(Date)
      end

      it "should set the created_at/on fields on creation" do
        green_smoothie = GreenSmoothie.new(:name => 'Banana')
        expect(green_smoothie.created_at).to be_nil
        expect(green_smoothie.created_on).to be_nil
        green_smoothie.save
        expect(green_smoothie.created_at).to be_a_kind_of(DateTime)
        expect(green_smoothie.created_on).to be_a_kind_of(Date)
      end

      it "should not alter the create_at/on fields on model updates" do
        green_smoothie = GreenSmoothie.new(:id => 2, :name => 'Berry')
        expect(green_smoothie.created_at).to be_nil
        expect(green_smoothie.created_on).to be_nil
        green_smoothie.save
        original_created_at = green_smoothie.created_at
        original_created_on = green_smoothie.created_on
        green_smoothie.name = 'Strawberry'
        green_smoothie.save
        expect(green_smoothie.created_at).to eql(original_created_at)
        expect(green_smoothie.created_on).to eql(original_created_on)
      end

      it "should set the updated_at/on fields on creation and on update" do
        green_smoothie = GreenSmoothie.new(:name => 'Mango')
        expect(green_smoothie.updated_at).to be_nil
        expect(green_smoothie.updated_on).to be_nil
        green_smoothie.save
        expect(green_smoothie.updated_at).to be_a_kind_of(DateTime)
        expect(green_smoothie.updated_on).to be_a_kind_of(Date)
        original_updated_at = green_smoothie.updated_at
        original_updated_on = green_smoothie.updated_on
        time_tomorrow = DateTime.now + 1
        date_tomorrow = Date.today + 1
        allow(DateTime).to receive(:now) { time_tomorrow }
        allow(Date).to receive(:today) { date_tomorrow }
        green_smoothie.name = 'Cranberry Mango'
        green_smoothie.save
        expect(green_smoothie.updated_at).not_to eql(original_updated_at)
        expect(green_smoothie.updated_on).not_to eql(original_updated_on)
        expect(green_smoothie.updated_at).to eql(time_tomorrow)
        expect(green_smoothie.updated_on).to eql(date_tomorrow)
      end

      it "should only set the updated_at/on fields on dirty objects" do
        green_smoothie = GreenSmoothie.new(:name => 'Mango')
        expect(green_smoothie.updated_at).to be_nil
        expect(green_smoothie.updated_on).to be_nil
        green_smoothie.save
        expect(green_smoothie.updated_at).to be_a_kind_of(DateTime)
        expect(green_smoothie.updated_on).to be_a_kind_of(Date)
        original_updated_at = green_smoothie.updated_at
        original_updated_on = green_smoothie.updated_on
        time_tomorrow = DateTime.now + 1
        date_tomorrow = Date.today + 1
        allow(DateTime).to receive(:now) { time_tomorrow }
        allow(Date).to receive(:today) { date_tomorrow }
        green_smoothie.save
        expect(green_smoothie.updated_at).not_to eql(time_tomorrow)
        expect(green_smoothie.updated_on).not_to eql(date_tomorrow)
        expect(green_smoothie.updated_at).to eql(original_updated_at)
        expect(green_smoothie.updated_on).to eql(original_updated_on)
      end

      describe '#touch' do
        it 'should update the updated_at/on fields' do
          green_smoothie = GreenSmoothie.create(:name => 'Mango')

          time_tomorrow = DateTime.now + 1
          date_tomorrow = Date.today + 1
          allow(DateTime).to receive(:now) { time_tomorrow }
          allow(Date).to receive(:today) { date_tomorrow }

          green_smoothie.touch

          expect(green_smoothie.updated_at).to eql(time_tomorrow)
          expect(green_smoothie.updated_on).to eql(date_tomorrow)
        end

        it 'should not update the created_at/on fields' do
          green_smoothie = GreenSmoothie.create(:name => 'Mango')

          original_created_at = green_smoothie.created_at
          original_created_on = green_smoothie.created_on

          green_smoothie.touch

          expect(green_smoothie.created_at).to equal(original_created_at)
          expect(green_smoothie.created_on).to equal(original_created_on)
        end
      end
    end

    describe "explicit property declaration" do
      before do
        Object.send(:remove_const, :GreenSmoothie) if defined?(GreenSmoothie)
        class GreenSmoothie
          include DataMapper::Resource

          property :id,         Serial
          property :name,       String
          property :created_at, DateTime, :required => true
          property :created_on, Date,     :required => true
          property :updated_at, DateTime, :required => true
          property :updated_on, Date,     :required => true

          auto_migrate!
        end
      end

      include_examples "Timestamp (shared behavior)"
    end

    describe "implicit property declaration" do
      before do
        Object.send(:remove_const, :GreenSmoothie) if defined?(GreenSmoothie)
        class GreenSmoothie
          include DataMapper::Resource

          property :id,   Serial
          property :name, String

          timestamps :at, :on

          auto_migrate!
        end
      end

      include_examples "Timestamp (shared behavior)"
    end

    describe "timestamps helper" do
      describe "inclusion" do
        before :each do
          @klass = Class.new do
            include DataMapper::Resource
          end
        end

        it "should provide #timestamps" do
          expect(@klass).to respond_to(:timestamps)
        end

        it "should set the *at properties" do
          @klass.timestamps :at

          expect(@klass.properties).to be_named(:created_at)
          expect(@klass.properties[:created_at]).to be_kind_of(DataMapper::Property::DateTime)
          expect(@klass.properties).to be_named(:updated_at)
          expect(@klass.properties[:updated_at]).to be_kind_of(DataMapper::Property::DateTime)
        end

        it "should set the *on properties" do
          @klass.timestamps :on

          expect(@klass.properties).to be_named(:created_on)
          expect(@klass.properties[:created_on]).to be_kind_of(DataMapper::Property::Date)
          expect(@klass.properties).to be_named(:updated_on)
          expect(@klass.properties[:updated_on]).to be_kind_of(DataMapper::Property::Date)
        end

        it "should set multiple properties" do
          @klass.timestamps :created_at, :updated_on

          expect(@klass.properties).to be_named(:created_at)
          expect(@klass.properties).to be_named(:updated_on)
        end

        it "should fail on unknown property name" do
          expect { @klass.timestamps :wowee }.to raise_error(DataMapper::Timestamp::InvalidTimestampName)
        end

        it "should fail on empty arguments" do
          expect { @klass.timestamps }.to raise_error(ArgumentError)
        end
      end
    end

  end

end
