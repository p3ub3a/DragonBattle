defmodule Battle do
    def start do 
        necromancerHp = 1000
        dragonHp = 10000

        Process.register(self(), :parentProcess)

        dragonProcess = spawn(Dragon, :battle, [dragonHp, [], [1]])
        Process.register(dragonProcess, :dragonProcess)
        dragonStrategyProcess = spawn(DragonStrategy, :useWhiptail, [])
        Process.register(dragonStrategyProcess, :dsp)

        necromancerProcess = spawn(Necromancer, :battle, [necromancerHp, [], []])
        Process.register(necromancerProcess, :necromancerProcess)
        necromancerStrategyProcess = spawn(NecromancerStrategy, :useSkill, [])
        Process.register(necromancerStrategyProcess, :nsp)

        receive do
            {:gameOver, message } -> 
                Process.exit(dragonProcess, :gameOver)
                Process.exit(dragonStrategyProcess, :gameOver)
                Process.exit(necromancerProcess, :gameOver)
                Process.exit(necromancerStrategyProcess, :gameOver)
                IO.puts "#{message}"
                Process.exit(self(), :gameOver)
        end
    end

    def getDamage(min, max) do
        damage = Enum.random(min..max)
    end

    def shutdownProcesses(zkList, zaList) do
        IO.puts "shutting down necromancer strategy process ..."
        Process.exit(Process.whereis(:nsp), :kill)
        IO.puts "shutting down dragon strategy process ..."
        Process.exit(Process.whereis(:dsp), :kill)
    end
end

defmodule Dragon do
    def battle(dragonHp, zkList, zaList) do
        
        receive do
            {:info, damageTaken} ->
                dragonHp = dragonHp - damageTaken
                if dragonHp <= 0 do 
                    send(:necromancerProcess, {:characterDead, "Dragon"})
                else
                    IO.puts "The dragon took #{damageTaken} damage, dragon hp remaining: #{dragonHp}"
                end
                battle(dragonHp, zkList, zaList)
            {:necromancerDead, characterName} ->
                IO.puts "#{characterName} was defeated!"
                Battle.shutdownProcesses(zkList, zaList)
                send(:parentProcess, {:gameOver, "The dragon won the battle with #{dragonHp} hp remaining!"})
            {:zkDead, zkID} ->
                IO.puts "ZK_#{zkID} was defeated!"
                Process.exit(Process.whereis(:"ZK_SS_#{zkID}"), :normal)
                battle(dragonHp, List.delete(zkList, zkID), zaList)
            {:zaDead, zaID} ->
                IO.puts "ZA_#{zaID} was defeated!"
                Process.exit(Process.whereis(:"ZA_S_#{zaID}"), :normal)
                battle(dragonHp, zkList, List.delete(zaList, zaID))
            {:updateZkList, newZombieKnight} ->
                battle(dragonHp, zkList ++ [newZombieKnight], zaList)
            {:updateZaList, newZombieArcher} ->
                battle(dragonHp, zkList, zaList ++ [newZombieArcher])

            # -------------------- skills --------------------
            {:whiptail, skillName} ->
                getDamage = &(Battle.getDamage/2)
                damage = getDamage.(50, 100)

                if Enum.count(zkList) == 0 do
                    zaID = Enum.random(zaList)
                    if zaID == 1 do
                        send(:necromancerProcess, {:info, damage})
                        IO.puts "Dragon used #{skillName} for #{damage} damage on Necromancer"
                    else
                        send(:"ZA_#{zaID}", {:info, damage})
                        IO.puts "Dragon used #{skillName} for #{damage} damage on ZA_#{zaID}"
                    end
                else
                    zkID = Enum.random(zkList)
                    if Process.whereis(:"ZK_#{zkID}") != nil do
                        
                        send(:"ZK_#{zkID}", {:info, damage})
                        IO.puts "Dragon used #{skillName} for #{damage} damage on ZK_#{zkID}"
                    end
                end
                battle(dragonHp, zkList, zaList)
            {:dragonBreath, skillName} ->
                Enum.each(zkList, fn zkID -> 
                    if Process.whereis(:"ZK_#{zkID}") != nil do
                        getDamage = &(Battle.getDamage/2)
                        damage = getDamage.(50, 150)
                        send(:"ZK_#{zkID}", {:info, damage})
                        IO.puts "Dragon used #{skillName} for #{damage} damage on ZK_#{zkID}"
                    end
                end)

                Enum.each(zaList, fn zaID -> 
                    if Process.whereis(:"ZA_#{zaID}") != nil do
                        getDamage = &(Battle.getDamage/2)
                        damage = getDamage.(50, 150)
                        if zaID == 1 do
                            send(:necromancerProcess, {:info, damage})
                            IO.puts "Dragon used #{skillName} for #{damage} damage on Necromancer"
                        else
                            send(:"ZA_#{zaID}", {:info, damage})
                            IO.puts "Dragon used #{skillName} for #{damage} damage on ZA_#{zaID}"
                        end
                    end
                end)
                battle(dragonHp, zkList, zaList)
        end
    end
end

defmodule Necromancer do
    def battle(necromancerHp, zombieKnights, zombieArchers) do
        enemyUnits = []
        
        receive do
            {:info, damageTaken} ->
                necromancerHp = necromancerHp - damageTaken
                if necromancerHp <= 0 do 
                    send(:dragonProcess, {:necromancerDead, "Necromancer"})
                else
                    IO.puts "The necromancer took #{damageTaken} damage, necromancerHp remaining #{necromancerHp}"
                end
                battle(necromancerHp, zombieKnights, zombieArchers)
            {:characterDead, characterName} ->
                if(characterName == "Dragon") do
                    IO.puts "#{characterName} was defeated!"
                    Battle.shutdownProcesses(zombieKnights, zombieArchers)
                    send(:parentProcess, {:gameOver, "The necromancer won the battle with #{necromancerHp} hp remaining!"})
                else
                    battle(necromancerHp, List.delete(zombieKnights, characterName), List.delete(zombieArchers, characterName))
                end
                
            # -------------------- skills --------------------
            {:antiZombieBolt, skillName} ->
                getDamage = &(Battle.getDamage/2)
                damage = getDamage.(0, 1000)
                send(:dragonProcess, {:info, damage})
                IO.puts "Necromancer used #{skillName} for #{damage} damage"
                battle(necromancerHp, zombieKnights, zombieArchers)
            {:summonZombieKnight, skillName} ->
                zombieKnightHp = 600
                zkID = generateZombieID(zombieKnights)

                zkProcess = spawn(ZombieKnight, :battle, [zombieKnightHp, zkID])
                zkSwordSlashProcess = spawn(ZombieKnight, :useSwordSlash, [zkID])
                Process.register(zkProcess, :"ZK_#{zkID}")
                Process.register(zkSwordSlashProcess, :"ZK_SS_#{zkID}")

                zombieKnights = zombieKnights ++ [zkID]
                send(:dragonProcess, {:updateZkList, zkID})
                IO.puts "Necromancer used #{skillName} and has an army size of: #{Enum.count(zombieKnights)} zombie knights and #{Enum.count(zombieArchers)} zombie archers"
                battle(necromancerHp, zombieKnights, zombieArchers)
            {:summonZombieArcher, skillName} ->
                zombieArcherHp = 100
                zaID = generateZombieID(zombieArchers)

                zaProcess = spawn(ZombieArcher, :battle, [zombieArcherHp, zaID])
                zaShotProcess = spawn(ZombieArcher, :useShot, [zaID])
                Process.register(zaProcess, :"ZA_#{zaID}")
                Process.register(zaShotProcess, :"ZA_S_#{zaID}")

                zombieArchers = zombieArchers ++ [zaID]
                send(:dragonProcess, {:updateZaList, zaID})

                IO.puts "Necromancer used #{skillName} and has an army size of: #{Enum.count(zombieKnights)} zombie knights and #{Enum.count(zombieArchers)} zombie archers"
                battle(necromancerHp, zombieKnights, zombieArchers)
        end
    end

    def generateZombieID(zombieList) do
        zombieID = :rand.uniform(100000)
        if Enum.member?(zombieList, zombieID) do
            generateZombieID(zombieList)
        else
            zombieID
        end
    end
end

defmodule DragonStrategy do
    def useWhiptail() do
        # There's a 20% chance to use dragonBreath instead of whiptail
        chance = :rand.uniform(5)

        if chance != 1 do
            send(:dragonProcess, {:whiptail, "whiptail"}) 
        else 
            send(:dragonProcess, {:dragonBreath, "dragon breath"}) 
        end
        Process.link(Process.whereis(:dsp))
        Process.sleep(80)
        useWhiptail()
    end
end

defmodule NecromancerStrategy do
    def useSkill() do
        skillNr = :rand.uniform(3)
        case skillNr do
            1 -> 
                useAntiZombieBolt()
                Process.sleep(120)
            2 -> 
                summonZombieKnight()
                Process.sleep(500)
            3 -> 
                summonZombieArcher()
                Process.sleep(700)
            _ -> "invalid skill number"
        end
        useSkill()
    end

    def useAntiZombieBolt() do
        send(:necromancerProcess, {:antiZombieBolt, "anti zombie bolt"}) 
    end

    def summonZombieKnight() do
        send(:necromancerProcess, {:summonZombieKnight, "summon zombie knight"}) 
    end

    def summonZombieArcher() do
        send(:necromancerProcess, {:summonZombieArcher, "summon zombie archer"}) 
    end
end

defmodule ZombieKnight do
    def battle(zombieKnightHp, zkID) do
        receive do
            {:info, damageTaken} ->
                zombieKnightHp = zombieKnightHp - damageTaken
                if zombieKnightHp <= 0 do 
                    send(:necromancerProcess, {:characterDead, zkID})
                    send(:dragonProcess, {:zkDead, zkID})
                    zombieKnightHp
                else
                    IO.puts "ZK_#{zkID} took #{damageTaken} damage, ZK_#{zkID} has #{zombieKnightHp} hp remaining"
                    battle(zombieKnightHp, zkID)
                end
        end
    end

    def useSwordSlash(zkID) do
        getDamage = &(Battle.getDamage/2)
        damage = getDamage.(20, 50)
        send(:dragonProcess, {:info, damage})
        IO.puts "Zombie knight #{zkID} used sword slash for #{damage} damage"
        Process.link(Process.whereis(:nsp))
        Process.sleep(100)
        useSwordSlash(zkID)
    end
end

defmodule ZombieArcher do
    def battle(zombieArcherHp, zaID) do
        receive do
            {:info, damageTaken} ->
                zombieArcherHp = zombieArcherHp - damageTaken
                if zombieArcherHp <= 0 do 
                    send(:necromancerProcess, {:characterDead, zaID})
                    send(:dragonProcess, {:zaDead, zaID})
                else
                    IO.puts "ZA_#{zaID} took #{damageTaken} damage, ZA_#{zaID} has #{zombieArcherHp} hp remaining"
                    battle(zombieArcherHp, zaID)
                end
        end
    end

    def useShot(zaID) do
        getDamage = &(Battle.getDamage/2)
        damage = getDamage.(100, 200)
        send(:dragonProcess, {:info, damage})
        IO.puts "Zombie archer #{zaID} used shot for #{damage} damage"
        Process.link(Process.whereis(:nsp))
        Process.sleep(300)
        useShot(zaID)
    end
end