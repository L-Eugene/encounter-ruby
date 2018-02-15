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
end
