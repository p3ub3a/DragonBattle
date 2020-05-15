defmodule Battle do
    def start do 
        necromancerHp = 10000
        dragonHp = 1000000

        Process.register(self(), :parentProcess)

        dragonProcess = spawn(Dragon, :battle, [dragonHp, []])
        Process.register(dragonProcess, :dragonProcess)
        dragonStrategyProcess = spawn(DragonStrategy, :useWhiptail, [])

        necromancerProcess = spawn(Necromancer, :battle, [necromancerHp, []])
        Process.register(necromancerProcess, :necromancerProcess)
        necromancerStrategyProcess = spawn(NecromancerStrategy, :useSkills, [])

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
    def battle(dragonHp, zkList) do
        
        receive do
            {:info, damageTaken} ->
                dragonHp = dragonHp - damageTaken
                if dragonHp <= 0 do 
                    send(:necromancerProcess, {:characterDead, "Dragon"})
                else
                    IO.puts "The dragon took #{damageTaken} damage, dragon hp remaining: #{dragonHp}"
                end
                battle(dragonHp, zkList)
            {:characterDead, characterName} ->
                IO.puts "#{characterName} was defeated!"
                if(characterName == "Necromancer") do
                    send(:parentProcess, {:gameOver, "The dragon won the battle!"})
                else
                    List.delete(zkList, characterName)
                end
                battle(dragonHp, zkList)
            {:updateZkList, updatedZkList} ->
                battle(dragonHp, updatedZkList)

            # -------------------- skills --------------------
            {:whiptail, skillName} ->
                getDamage = &(Battle.getDamage/2)
                damage = getDamage.(50, 100)

                if Enum.count(zkList) == 0 do
                    send(:necromancerProcess, {:info, damage})
                    IO.puts "Dragon used #{skillName} for #{damage} damage on Necromancer"
                else
                    zkID = Enum.random(zkList)
                    send(:"ZK_#{zkID}", {:info, damage})
                    IO.puts "Dragon used #{skillName} for #{damage} damage on ZK_#{zkID}"
                end
                battle(dragonHp, zkList)
            #{:dragonBreath, skillName} ->

        end
    end
end

defmodule Necromancer do
    def battle(necromancerHp, zombieKnights) do
        enemyUnits = []
        
        receive do
            {:info, damageTaken} ->
                necromancerHp = necromancerHp - damageTaken
                if necromancerHp <= 0 do 
                    send(:dragonProcess, {:characterDead, "Necromancer"})
                else
                    IO.puts "The necromancer took #{damageTaken} damage, necromancerHp remaining #{necromancerHp}"
                end
                battle(necromancerHp, zombieKnights)
            {:characterDead, characterName} ->
                if(characterName == "Dragon") do
                    IO.puts "#{characterName} was defeated!"
                    send(:parentProcess, {:gameOver, "The necromancer won the battle!"})
                else
                    List.delete(zombieKnights, characterName)
                end
                battle(necromancerHp, zombieKnights)
            # -------------------- skills --------------------
            {:antiZombieBolt, skillName} ->
                getDamage = &(Battle.getDamage/2)
                damage = getDamage.(0, 1000)
                send(:dragonProcess, {:info, damage})
                IO.puts "Necromancer used #{skillName} for #{damage} damage"
                battle(necromancerHp, zombieKnights)
            {:summonZombieKnight, skillName} ->
                zombieKnightHp = 600
                zkID = generateZKID(zombieKnights)

                zkProcess = spawn(ZombieKnight, :battle, [zombieKnightHp, zkID])
                zkSwordSlashProcess = spawn(ZombieKnight, :useSwordSlash, [])
                Process.register(zkProcess, :"ZK_#{zkID}")
                Process.register(zkSwordSlashProcess, :"ZK_SS_#{zkID}")

                zombieKnights = zombieKnights ++ [zkID]
                send(:dragonProcess, {:updateZkList, zombieKnights})

                IO.puts "Necromancer used #{skillName} and has an army size of: #{Enum.count(zombieKnights)} zombie knights"
                battle(necromancerHp, zombieKnights)
        end
    end

    def generateZKID(zkList) do
        zkID = :rand.uniform(10000000)
        if Enum.member?(zkList, zkID) do
            generateZKID(zkList)
        else
            zkID
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
    def useSkills() do
        spawn(NecromancerStrategy, :useAntiZombieBolt, [])
        spawn(NecromancerStrategy, :summonZombieKnight, [])
    end

    def useAntiZombieBolt() do
        send(:necromancerProcess, {:antiZombieBolt, "anti zombie bolt"}) 
        Process.sleep(1200)
        useAntiZombieBolt()
    end

    def summonZombieKnight() do
        send(:necromancerProcess, {:summonZombieKnight, "summon zombie knight"}) 
        Process.sleep(2000)
        summonZombieKnight()
    end
end

defmodule ZombieKnight do
    def battle(zombieKnightHp, zkID) do
        receive do
            {:info, damageTaken} ->
                zombieKnightHp = zombieKnightHp - damageTaken
                if zombieKnightHp <= 0 do 
                    send(:necromancerProcess, {:characterDead, zkID})
                    send(:dragonProcess, {:characterDead, zkID})
                    Process.exit(:"ZK_#{zkID}", :kill)
                    Process.exit(:"ZK_SS_#{zkID}", :kill)
                else
                    IO.puts "ZK_#{zkID} took #{damageTaken} damage, ZK_#{zkID} has #{zombieKnightHp} remaining"
                    battle(zombieKnightHp, zkID)
                end
        end
    end

    def useSwordSlash() do
        getDamage = &(Battle.getDamage/2)
        damage = getDamage.(20, 50)
        send(:dragonProcess, {:info, damage})
        IO.puts "Zombie knight used sword slash for #{damage} damage"
        Process.sleep(500)
        useSwordSlash()
    end
end