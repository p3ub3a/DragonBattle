defmodule Battle do
    def start do 
        necromancerHp = 10000
        dragonHp = 1000000

        Process.register(self(), :parentProcess)

        dragonProcess = spawn(Dragon, :battle, [necromancerHp])
        Process.register(dragonProcess, :dragonProcess)
        dragonStrategyProcess = spawn(DragonStrategy, :useWhiptail, [])

        necromancerProcess = spawn(Necromancer, :battle, [dragonHp])
        Process.register(necromancerProcess, :necromancerProcess)
        necromancerStrategyProcess = spawn(NecromancerStrategy, :useAntiZombieBolt, [])

        receive do
            {:gameOver, message } -> 
                Process.exit(dragonProcess, :gameOver)
                Process.exit(dragonStrategyProcess, :gameOver)
                Process.exit(necromancerProcess, :gameOver)
                Process.exit(necromancerStrategyProcess, :gameOver)
                IO.puts "#{message}"
        end
    end

    def getDamage(min, max) do
        damage = Enum.random(min..max)
    end
end

defmodule Dragon do
    def battle(dragonHp) do
        # enemyList = 
        
        receive do
            {:info, damageTaken} ->
                if dragonHp <= 0 do 
                    send(:necromancerProcess, {:characterDead, "Dragon"})
                else
                    dragonHp = dragonHp - damageTaken
                    IO.puts "The dragon took #{damageTaken} damage"
                end
                battle(dragonHp)
            {:characterDead, characterName} ->
                IO.puts "#{characterName} was defeated!"
                if(characterName == "Necromancer") do
                    send(:parentProcess, {:gameOver, "The dragon won the battle!"})
                end
                battle(dragonHp)
            # -------------------- skills --------------------
            {:whiptail, skillName} ->
                getDamage = &(Battle.getDamage/2)
                damage = getDamage.(50, 100)
                send(:necromancerProcess, {:info, damage})
                IO.puts "Dragon used #{skillName} for #{damage} damage"
                battle(dragonHp)
            #{:dragonBreath, skillName} ->

        end
    end
end

defmodule Necromancer do
    def battle(necromancerHp) do
        # enemyList = 
        
        receive do
            {:info, damageTaken} ->
                if necromancerHp <= 0 do 
                    send(:dragonProcess, {:characterDead, "Necromancer"})
                else
                    necromancerHp = necromancerHp - damageTaken
                    IO.puts "The necromancer took #{damageTaken} damage"
                end
                battle(necromancerHp)
            {:characterDead, characterName} ->
                IO.puts "#{characterName} was defeated!"
                if(characterName == "Dragon") do
                    send(:parentProcess, {:gameOver, "The necromancer won the battle!"})
                end
                battle(necromancerHp)
            # -------------------- skills --------------------
            {:antiZombieBolt, skillName} ->
                getDamage = &(Battle.getDamage/2)
                damage = getDamage.(0, 1000)
                send(:dragonProcess, {:info, damage})
                IO.puts "Necromancer used #{skillName} for #{damage} damage"
                battle(necromancerHp)
            #{:zombieKnight, skillName} ->
                
        end
    end
end

defmodule DragonStrategy do
    def useWhiptail() do
        send(:dragonProcess, {:whiptail, "whiptail"}) 
        Process.sleep(500)
        useWhiptail()
    end
end

defmodule NecromancerStrategy do
    def useAntiZombieBolt() do
        send(:necromancerProcess, {:antiZombieBolt, "anti zombie bolt"}) 
        Process.sleep(1200)
        useAntiZombieBolt()
    end

    def summonZombieKnight() do
        send(:necromancerProcess, {:zombieKnight, "summon zombie knight"}) 
        Process.sleep(2000)
        summonZombieKnight()
    end
end

# defmodule ZombieKnight do
#     receive do
            
#     end
# end