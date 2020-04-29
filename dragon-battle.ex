defmodule Battle do
    def start do 
        necromancerHp = 10000
        dragonHp = 1000000

        parent = self()

        # dragonProcess = spawn(&(Dragon.useWhiptail/2)) ??

        dsp = spawn(DragonStrategy, :battleNecromancer, [necromancerHp, parent])
        nsp = spawn(NecromancerStrategy, :battleDragon, [dragonHp, parent])

        receive do
            {:gameOver, message } -> 
                Process.exit(dsp, :gameOver)
                Process.exit(nsp, :gameOver)
                IO.puts "#{message}"
        end
    end

    def dealDamage(targetHp, min, max) do
        remainingHp = targetHp - Enum.random(min..max)
    end
end

defmodule DragonStrategy do
    def battleNecromancer(necromancerHp, parent) do

        dragonStrategyProcess = self()

        spawn(Dragon, :useWhiptail, [necromancerHp, dragonStrategyProcess])

        receive do
            {:action, targetHp} -> 
                if targetHp <= 0 do 
                    send(parent, {:gameOver, "The dragon won the battle!"})
                else
                    IO.puts "The dragon used Whip Tail, necromancer has #{targetHp} HP remaining"
                    battleNecromancer(targetHp, parent) 
                end
        # after
        #     5 -> :timeout
        end
    end
end

defmodule NecromancerStrategy do
    def battleDragon(dragonHp, parent) do

        necromancerStrategyProcess = self()

        spawn(Necromancer, :useAntiZombieBolt, [dragonHp, necromancerStrategyProcess])

        receive do
            {:action, targetHp} -> 
                if targetHp <= 0 do 
                    send(parent, {:gameOver, "The necromancer won the battle!"})
                else
                    IO.puts "The necromancer used Anti Zombie Bolt, dragon has #{targetHp} HP remaining"
                    battleDragon(targetHp, parent) 
                end
        # after
        #     12 -> :timeout
        end
    end
end

defmodule Dragon do
    def useWhiptail(targetHp, process) do
        dealDamage = &(Battle.dealDamage/3)
        targetHp = dealDamage.(targetHp, 50, 100)
        # targetHp = Battle.dealDamage(targetHp, 50, 100)
        Process.sleep(5)
        send(process, {:action, targetHp}) 
    end
end

defmodule Necromancer do
    def useAntiZombieBolt(targetHp, process) do
        dealDamage = &(Battle.dealDamage/3)
        targetHp = dealDamage.(targetHp, 0, 1000)
        Process.sleep(12)
        send(process, {:action, targetHp}) 
    end
end