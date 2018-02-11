require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Encounter::Team do
  before(:each) do
    @conn = Encounter::Connection.new(domain: 'test.en.cx')
  end

  it "should load existing team" do
    t = Encounter::Team.new(@conn, tid: 528)

    expect(t.name).to eq 'Infe®no'
    expect(t.created_at).to eq '7 декабря 2005'
    expect(t.players).to eq 29
    expect(t.points).to eq 6538.16
    expect(t.games).to eq 200
    expect(t.wins).to eq 53
    expect(t.anthem).to eq 'http://cdn.endata.cx/data/teams/hymns/528.mp3'
    expect(t.website).to eq 'http://inferno.encounter.by'
    expect(t.forum).to eq 'inferno.encounter.by'
  end

  it 'should load team manpower' do
    t = Encounter::Team.new(@conn, tid: 528)

    expect(t.captain.class).to be Encounter::Player
    expect(t.captain.uid).to eq 4_203

    expect(t.active.size).to eq 4
    expect(t.active[1].uid).to eq 19_350
    expect(t.active.last.uid).to eq 150_015

    expect(t.reserve.size).to eq 24
    expect(t.reserve.first.uid).to eq 5_910
    expect(t.reserve.last.uid).to eq 1_569_009
  end

  it 'should raise if tid is not given' do
    expect {
      Encounter::Team.new(@conn, {}).name
    }.to raise_error(ArgumentError)
  end

  it 'should raise if team does not exist' do
    expect {
      Encounter::Team.new(@conn, tid: 4).name
    }.to raise_error(RuntimeError)
  end
end
