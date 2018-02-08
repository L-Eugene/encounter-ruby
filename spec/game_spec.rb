require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Encounter::Game do
  before(:each) do
    @conn = Encounter::Connection.new(domain: 'test.en.cx')
  end

  it 'Should load existing game' do
    @game = Encounter::Game.new(@conn, domain: 'test.en.cx', gid: 60756)
    expect(@game.authors.size).to eq 1
    expect(@game.type).to eq 'Points'
    expect(@game.limit).to eq 7
  end
  
  it 'Should raise if domain not given' do
    expect { Encounter::Game.new(@conn, gid: 5) }.to raise_error(ArgumentError)
  end
  
  it 'Should raise if gid not given' do
    expect { 
      Encounter::Game.new(@conn, domain: 'test.en.cx') 
    }.to raise_error(ArgumentError)
  end

  it 'Should raise if game does not exist' do
    expect {
      Encounter::Game.new(@conn, domain: 'test.en.cx', gid: 60750).name
    }.to raise_error(RuntimeError)
  end
  
  it 'Should load data from initialize' do
    @game = Encounter::Game.new(
      @conn, 
      domain: 'test.en.cx', gid: 60756, type: 'Real', limit: 0
    )
    expect(@game.type).to eq 'Real'
    expect(@game.limit).to eq 0
    @game.authors
    expect(@game.type).to eq 'Points'
    expect(@game.limit).to eq 7
  end
end

