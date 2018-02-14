require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Encounter::Calendar do
  before(:each) do
    @conn = Encounter::Connection.new(domain: 'test.en.cx')
    @calendar = Encounter::Calendar.new(@conn)
  end

  it 'should raise if no connection' do
    expect { Encounter::Calendar.new }.to raise_error(ArgumentError)
  end

  it 'should load region list' do
    expect(@calendar.load_regions.class).to be Array

    expect(@calendar.load_regions.size).to eq 51
    
    country = @calendar.load_regions.select { |x| x[:name] == 'Беларусь'}.first
    
    expect(country[:id]).to eq 100007
    expect(country[:regions].size).to eq 6
    
    region = country[:regions].select { |x| x[:id] == 100007 }.first
    expect(region[:name]).to eq 'Гомельская обл.'
    expect(region[:cities].size).to eq 2
  end
  
  it 'should load Real gamelist' do
    announces = @calendar.load_announces
    expect(announces.size).to eq 200

    expect(announces.first.class).to be Encounter::Game
    expect(announces.first.gid).to eq 59_787
    expect(announces.first.domain).to eq 'http://uae.en.cx/'
    expect(announces.first.authors.size).to eq 1
    expect(announces.first.authors.first.class).to be Encounter::Player
    expect(announces.first.start_time).to eq 'February 02, 2018 07:59:00 UTC'

    expect(announces[2].money).to eq '1 000 руб.'
    expect(announces[2].authors.size).to eq 3
    expect(announces[2].authors.first.name).to eq 'Marks'
    expect(announces[2].authors.last.uid).to eq 39_999
  end

  it 'should load single page' do
    announces = @calendar.load_announces(
      status: 'Coming', zone: 'Real', page: 2
    )

    expect(announces.count).to eq 20
  end
end
