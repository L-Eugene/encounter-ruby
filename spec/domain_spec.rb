require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Encounter::Domain do
  before(:each) do
    @conn = Encounter::Connection.new(domain: 'test.en.cx')
  end

  it 'should load announces' do
    ann = Encounter::Domain.new(@conn, 'test.en.cx').announces
    expect(ann.size).to eq 11
    expect(ann.first.class).to be Encounter::Game
    expect(ann.first.gid).to eq 60_303
    expect(ann.last.gid).to eq 57_988
  end

  it 'should load player list' do
    usr = Encounter::Domain.new(@conn, 'test.en.cx').players
    expect(usr.size).to eq 919
    expect(usr.first.class).to be Encounter::Player
    expect(usr.first.uid).to eq 46_148
  end

  it 'should load team list' do
    tms = Encounter::Domain.new(@conn, 'test.en.cx').teams
    expect(tms.size).to eq 150
    expect(tms.first.class).to be Encounter::Team
    expect(tms.first.tid).to eq 24_561
    expect(tms.last.tid).to eq 10
  end
  
  it 'should load past games' do
    arc = Encounter::Domain.new(@conn, 'test.en.cx').archive
    expect(arc.size).to eq 72
    expect(arc.first.class).to be Encounter::Game
    expect(arc.first.gid).to eq 59_425
  end

  it 'should load domain rating' do
    expect(Encounter::Domain.new(@conn, 'test.en.cx').stars).to eq 7
  end

  it 'should load calendar region list' do
    regions = Encounter::Domain.new(@conn, 'test.en.cx').calendar_regions
    expect(regions.class).to be Array

    expect(regions.size).to eq 51
    
    country = regions.select { |x| x[:name] == 'Беларусь'}.first
    
    expect(country[:id]).to eq 100007
    expect(country[:regions].size).to eq 6
    
    region = country[:regions].select { |x| x[:id] == 100007 }.first
    expect(region[:name]).to eq 'Гомельская обл.'
    expect(region[:cities].size).to eq 2
  end

  it 'should load Real gamelist' do
    announces = Encounter::Domain.new(@conn, 'test.en.cx').calendar
    expect(announces.size).to eq 200

    expect(announces.first.class).to be Encounter::Game
    expect(announces.first.gid).to eq 59_787
    expect(announces.first.domain).to eq 'uae.en.cx'
    expect(announces.first.authors.size).to eq 1
    expect(announces.first.authors.first.class).to be Encounter::Player
    expect(announces.first.start_time).to eq 'February 02, 2018 07:59:00 UTC'

    expect(announces[2].money).to eq '1 000 руб.'
    expect(announces[2].authors.size).to eq 3
    expect(announces[2].authors.first.name).to eq 'Marks'
    expect(announces[2].authors.last.uid).to eq 39_999
  end

  it 'should load single page' do
    announces = Encounter::Domain.new(@conn, 'test.en.cx').calendar(
      status: 'Coming', zone: 'Real', page: 2
    )

    expect(announces.count).to eq 20
  end
end
