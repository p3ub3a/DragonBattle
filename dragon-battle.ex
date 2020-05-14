defmodule Battle do
    def start do 
        necromancerHp = 10000
        dragonHp = 1000000

        parentProcess = self()

        dragonProcess = spawn(Dragon, :battle, [necromancerHp, parentProcess])
        dsp = spawn(DragonStrategy, :useWhiptail, [dragonProcess])

        necromancerProcess = spawn(Necromancer, :battle, [dragonHp, parentProcess])
        nsp = spawn(NecromancerStrategy, :useAntiZombieBolt, [necromancerProcess])

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
    def battle(dragonHp, parentProcess) do
        process = self()
        # enemyList = 
        
        receive do
            {:info, damageTaken} ->
                if dragonHp <= 0 do 
                    send(parentProcess, {:gameOver, "The necromancer won the battle!"})
                else
                    dragonHp = dragonHp - damageTaken
                    IO.puts "The dragon took #{damageTaken} damage"
                end
                battle(dragonHp, parentProcess)
            {:characterDead, characterName} ->

            # -------------------- skills --------------------
            {:whiptail, skillName} ->
                dealDamage = &(Battle.getDamage/2)
                # ???
                send(necromancerProcess, {:info, getDamage.(50, 100)})
                # 
                battle(dragonHp, parentProcess)
            {:dragonBreath, skillName} ->

        end
    end
end

defmodule Necromancer do
    def battle(necromancerHp, parentProcess) do
        process = self()
        # enemyList = 
        
        receive do
            {:info, damageTaken} ->
                if necromancerHp <= 0 do 
                    send(parentProcess, {:gameOver, "The dragon won the battle!"})
                else
                    necromancerHp = necromancerHp - damageTaken
                    IO.puts "The necromancer took #{damageTaken} damage"
                end
                battle(necromancerHp, parentProcess)
            {:characterDead, characterName} ->

            # -------------------- skills --------------------
            {:antiZombieBolt, skillName} ->
                dealDamage = &(Battle.getDamage/2)
                # ???
                send(dragonProcess, {:info, getDamage.(0, 1000)})
                # 
                battle(necromancerHp, parentProcess)
            {:zombieKnight, skillName} ->
                
        end
    end
end

defmodule DragonStrategy do
    def useWhiptail(dragonProcess) do
        send(dragonProcess, {:whiptail, "whiptail"}) 
        Process.sleep(5)
        useWhiptail(dragonProcess)
    end
end

defmodule NecromancerStrategy do
    def useAntiZombieBolt(necromancerProcess) do
        send(necromancerProcess, {:antiZombieBolt, "anti zombie bolt"}) 
        Process.sleep(12)
        useAntiZombieBolt(necromancerProcess)
    end

    def summonZombieKnight(necromancerProcess) do
        send(necromancerProcess, {:zombieKnight, "summon zombie knight"}) 
        Process.sleep(20)
        summonZombieKnight(necromancerProcess)
    end
end

defmodule ZombieKnight do
    receive do
            
    end
end