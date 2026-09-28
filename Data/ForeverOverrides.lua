local ADDON_NAME, ns = ...

-- WoW Forever-specific additions and corrections.
--
-- This file is intentionally kept separate from the Classic baseline.
-- Add new Forever creatures, new ranks, or changed ability mappings here.
--
-- Forever renames Classic "Screech" to "Demoralizing Screech". Creature
-- tooltip rows are normalized below so the displayed name matches Forever;
-- Core.lua treats both names as the same learned-knowledge key.

-- Verified Forever observations live here independently of the Classic/Petopia
-- baseline. Keep provenance with each row so future Beast Lore/community data
-- can be audited instead of silently replacing the baseline.
ns.ForeverCreatureAbilities = {
    [270693] = {
        {
            ability = "Bite", rank = 2, family = "Crocolisk", level = 15,
            zone = "Loch Modan", subzone = "The Loch",
            source = "tamed", verified = true,
        },
    },
}

ns.ForeverCreatureAbilitiesByName = {
    ["Daggerfang"] = ns.ForeverCreatureAbilities[270693],
}

local ALL_FAMILIES = { "Bat","Bear","Boar","Bird of Prey","Carrion Bird","Cat","Core Hound","Crab","Crocolisk","Fox","Gorilla","Hyena","Raptor","Scorpid","Spider","Tallstrider","Turtle","Wind Serpent","Wolf" }

ns.ForeverAbilityOverrides = {
    ["Bite"]={description="Bites the enemy, causing {damage} damage.",families={"Bat","Boar","Carrion Bird","Core Hound","Crocolisk","Fox","Hyena","Raptor","Spider","Turtle","Wind Serpent","Wolf"}},
    ["Charge"]={description="Charges an enemy, immobilizing it briefly and empowering the next melee attack.",families={"Boar"}},
    ["Claw"]={description="Claws the enemy, causing {damage} damage.",families={"Bear","Bird of Prey","Cat","Crab","Gorilla","Scorpid"}},
    ["Cower"]={description="Cowers, reducing the pet's threat by {threat}.",families=ALL_FAMILIES},
    ["Dash"]={description="Increases the pet's movement speed by {speed}% for {duration}.",families={"Bear","Boar","Cat","Core Hound","Crab","Crocolisk","Fox","Gorilla","Raptor","Scorpid","Spider","Turtle","Wolf"}},
    ["Dive"]={description="Increases the pet's movement speed by {speed}% for {duration}.",families={"Bat","Bird of Prey","Carrion Bird","Wind Serpent"}},
    ["Furious Howl"]={description="The wolf howls, increasing nearby party members' next physical attack by {damage}.",families={"Wolf"}},
    ["Lightning Breath"]={description="Breathes lightning at the enemy, causing {damage} Nature damage.",families={"Wind Serpent"}},
    ["Prowl"]={description="Puts the pet in stealth, slowing movement and empowering its first attack.",families={"Cat"}},
    ["Scorpid Poison"]={description="Poisons the enemy for {damage} Nature damage over {duration}.",families={"Scorpid"}},
    ["Demoralizing Screech"]={description="Screeches, causing {damage} damage and reducing nearby enemies' attack power for {duration}.",families={"Carrion Bird"}},
    ["Shell Shield"]={description="Withdraws into its shell, reducing damage taken while modifying attacks.",families={"Turtle"}},
    ["Thunderstomp"]={description="Shakes the ground, causing {damage} Nature damage to nearby enemies.",families={"Gorilla"},ranks={[4]={source="wild",unverifiedDetails=true}}},
    ["Lava Breath"]={description="Breathes lava, causing {damage} Fire damage and slowing casting speed.",families={"Core Hound"},ranks={[1]={petLevel=48,source="wild",unverifiedDetails=true},[2]={petLevel=48,source="wild",unverifiedDetails=true}}},
    ["Swipe"]={description="Swipes at an enemy, causing {damage} damage.",families={"Bear"},ranks={[1]={source="wild",unverifiedDetails=true}}},
    ["Mine!"]={description="Strikes the enemy for {damage} and disarms it for {duration}.",families={"Bird of Prey"},ranks={[1]={source="wild",unverifiedDetails=true}}},
    ["Pinch"]={description="Pinches the enemy, causing {damage} damage.",families={"Crab"},ranks={[1]={source="wild",unverifiedDetails=true}}},
    ["Dismember"]={description="Dismembers the enemy, causing {damage} damage.",families={"Crocolisk"},ranks={[1]={source="wild",unverifiedDetails=true}}},
    ["Trickster's Dance"]={description="Increases dodge by {dodge}% and attack speed by {speed}% for {duration}.",families={"Fox"},ranks={[1]={source="wild"}}},
    ["Tendon Rip"]={description="Tears at the enemy's legs for {damage} over {duration}, reducing movement speed by {slow}%.",families={"Hyena"},ranks={[1]={source="wild"}}},
    ["Savage Rend"]={description="Slashes the enemy, causing a bleed for {damage} over {duration}.",families={"Raptor"},ranks={[1]={source="wild"}}},
    ["Web"]={description="Webs the enemy, causing {damage} over time and immobilizing it for {duration}.",families={"Spider"},ranks={[1]={source="wild",unverifiedDetails=true}}},
    ["Dust Cloud"]={description="Kicks up dust, reducing the enemy's armor by {armor} for {duration}.",families={"Tallstrider"},ranks={[1]={source="wild"}}},
    ["Faster Attack"]={description="Increases the pet's attack speed by {speed}%.",families=ALL_FAMILIES,kind="native",ranks={[1]={petLevel=1,source="native"},[2]={petLevel=1,source="native"},[3]={petLevel=1,source="native"},[4]={petLevel=1,source="native"},[5]={petLevel=1,source="native"},[6]={petLevel=1,source="native"},[7]={petLevel=1,source="native"}}},
    ["Slower Attack"]={description="Decreases the pet's attack speed by {speed}%.",families=ALL_FAMILIES,kind="native",ranks={[2]={petLevel=1,source="native"},[3]={petLevel=1,source="native"}}},
}


-- Normalize the Classic creature mapping to Forever's in-game ability name.
-- Keep the underlying Classic metadata intact for reference/source auditing.
if ns.ClassicCreatureAbilitiesByName then
    for _, rows in pairs(ns.ClassicCreatureAbilitiesByName) do
        for _, row in ipairs(rows) do
            if row.ability == "Screech" then
                row.ability = "Demoralizing Screech"
            end
        end
    end
end
