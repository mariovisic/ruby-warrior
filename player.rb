class Player
  def initialize(*args)
    @health = Health.new
  end

  def health_change(warrior)
    @health.update(warrior.respond_to?(:health) ? warrior.health : 20)
    @health.diff
  end

  def play_turn(warrior)
    Turn.new(warrior, health_change(warrior)).perform
  end
end

class Health
  def update(health)
    @old_health = @new_health
    @new_health = health
  end

  def diff
    (@new_health || 0) - (@old_health || 0)
  end
end

class Turn
  def initialize(warrior, health_change)
    @warrior       = warrior
    if @warrior.respond_to?(:feel)
      @forwards      = warrior.feel
      @backwards     = warrior.feel(:backward)
    else
      @forwards  = Struct.new(:wall?, :enemy?, :captive?).new(false, false, false)
      @backwards = Struct.new(:wall?, :enemy?, :captive?).new(false, false, false)
    end
    @health_change = health_change
  end

  def perform
    turn_around                  ||
    attack_enemies               ||
    retreat_from_attacking_enemy ||
    move_towards_attacking_enemy ||
    attack_enemies_from_distance ||
    rest                         ||
    rescue_creatures             ||
    move_forward
  end

  private

  def turn_around
    @forwards.wall? && @warrior.pivot!
  end

  def attack_enemies
    @forwards.enemy? && @warrior.attack!
  end

  def rest
    if @warrior.respond_to?(:health)
      @warrior.health < 20 && @warrior.rest!
    end
  end

  def retreat_from_attacking_enemy
    @health_change < 0 && @warrior.health < 7 && @backwards.empty? && @warrior.walk!(:backward)
  end

  def move_towards_attacking_enemy
    @health_change < 0 && @warrior.walk!
  end

  def rescue_creatures
    @forwards.captive? && @warrior.rescue!
  end

  def move_forward
    @warrior.walk!
  end

  def attack_enemies_from_distance
    if @warrior.respond_to?(:look)
     !@warrior.look.any?(&:captive?) && @warrior.look.any?(&:enemy?) && @warrior.shoot!
    end
  end
end
