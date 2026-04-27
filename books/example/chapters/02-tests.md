# Prove di rendering
\setsectioncolor{dg-red}{dg-red}


```statblock
layout: Daggerheart Environment
source: daggerheart-environment
name: The Dark Forest
tier: 1
type: Exploration
description: A dense forest filled with shadows and danger.
impulses: Explore, Survive, Escape
difficulty: 10
potential_adversaries: Goblin Scout, Shadow Beast
feats:
  - name: Dense Trees - Passive
    text: Provides cover and concealment.
  - name: Hidden Paths - Passive
    text: Allows for stealthy movement.
```

::: {.squarebox}
Test di squarebox per colore
:::

```statblock
layout: Daggerheart Adversary
source: daggerheart-adversary
name: Vampire, The Bloodthirsty
tier: 2
type: Solo
description: A fearsome vampire that preys on the weak.
motives_and_tactics: Attack from shadows, drain blood
difficulty: 15
thresholds: 16/30
hp: 8
stress: 4
atk: "+4"
attack: Fangs
range: Close
damage: 2d8+2 (Magical)
experience: Bloodthirsty Knowledge +3
feats:
  - name: Blood Drain - Action
    text: Make an attack against a target within Close range. On a success, deal 2 and the target must mark an Armor Slot without gaining its benefit (they can still use armor to reduce the damage).
  - name: Shadow Step - Action
    text: Move to a location within Close range, ignoring terrain.
```


## Tripudio di tabelle

| Header 1 | Header 2 | Header 3 | Header 4 |
|----------|----------|----------|----------|
| Item 1   | Item 2   | Item 3   | Item 4   |
| Item 4   | Item 5   | Item 6   | Item 7   |
| Item 7   | Item 8   | Item 9   | Item 10  |

::: {.fullpage}
| Header 1 | Header 2 | Header 3 | Header 4 | Header 5 | Header 6 | Header 7 | Header 8 | Header 9 |
|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| Item 1   | Item 2   | Item 3   | Item 4   | Item 5   | Item 6   | Item 7   | Item 8   | Item 9   |
| Item 4   | Item 5   | Item 6   | Item 7   | Item 8   | Item 9   | Item 10  | Item 11  | Item 12  |
| Item 7   | Item 8   | Item 9   | Item 10  | Item 11  | Item 12  | Item 13  | Item 14  | Item 15  |
:::


## Altra tabella

::: {.fullpage}
| Header 1 | Header 2 | Header 3 | Header 4 | Header 5 | Header 6 | Header 7 | Header 8 | Header 9 |
|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| Item 1   | Item 2   | Item 3   | Item 4   | Item 5   | Item 6   | Item 7   | Item 8   | Item 9   |
| Item 4   | Item 5   | Item 6   | Item 7   | Item 8   | Item 9   | Item 10  | Item 11  | Item 12  |
| Item 7   | Item 8   | Item 9   | Item 10  | Item 11  | Item 12  | Item 13  | Item 14  | Item 15  |
:::


::: {.pagebreak}
:::

::: {.fullpage}
## Avversari ed ambienti

Esempi di rendering per avversari ed ambienti
:::

### Ambienti

```statblock
layout: Daggerheart Environment
source: daggerheart-environment
name: Burning Heart of the Woods
tier: 3
type: Exploration
description: Thick indigo ash fills the air around a towering moss-covered tree that burns eternally with flames a sickly shade of blue.
impulses: Beat out an uncanny rhythm for all to follow, corrupt the woods
difficulty: 16
potential_adversaries: Beasts (Bear, Glass Snake), Elementals (Elemental Spark), Verdant Defenders (Dryad, Oak Treant, Stag Knight)
feats:
  - name: Chaos Magic Locus - Passive
    text: When a PC makes a Spellcast Roll, they must roll two Fear Dice and take the higher result.
  - name: The Indigo Flame - Passive
    text: PCs who approach the central tree can make a Knowledge Roll to identify the magic that consumed this environment. On a success, they learn three details; on a success with Fear, two; on a failure, mark a Stress to learn one. Details include that this is Fallen magic, spread through ashen moss, cleansable only by a ritual of nature magic with a Progress Countdown (8).
  - name: Grasping Vines - Action
    text: Animate vines bristling with thorns whip out from the underbrush. A target must succeed on an Agility Reaction Roll or become Restrained and Vulnerable until they break free with a successful Finesse or Strength Roll or by dealing 10 damage to the vines. When escaping, the target takes **1d8+4** physical damage and loses a Hope.
  - name: Charcoal Constructs - Action
    text: Warped animals wreathed in indigo flame trample through a point of your choice. All targets within Close range of that point must make an Agility Reaction Roll. Targets who fail take **3d12+3** physical damage; targets who succeed take half.
  - name: Choking Ash - Reaction (Countdown Loop 6)
    text: When the PCs enter, activate the countdown. When it triggers, all characters must make a Strength or Instinct Reaction Roll. Targets who fail take **4d6+5** direct physical damage; targets who succeed take half. Protective masks or clothes grant advantage on the roll.
```

```statblock
layout: Daggerheart Environment
source: daggerheart-environment
name: Castle Siege
tier: 3
type: Event
description: An active siege with an attacking force fighting to gain entry to a fortified castle.
impulses: Bleed out the will to fight, breach the walls, build tension
difficulty: 17
potential_adversaries: Mercenaries (Harrier, Sellsword, Spellblade, Weaponmaster), Noble Forces (Archer Squadron, Conscript, Elite Soldier, Knight of the Realm)
feats:
  - name: Secret Entrance - Passive
    text: A PC can find or recall a secret way into the castle with a successful Instinct or Knowledge Roll.
  - name: Siege Weapons - Action (Consequence Countdown 6)
    text: The attacking force deploys siege weapons to raze the defenders' fortifications. Activate the countdown when the siege begins. When it triggers, the defenders' fortifications have been breached, attackers flood inside, you gain 2 Fear, then shift to the Pitched Battle environment.
  - name: Reinforcements! - Action
    text: Summon a Knight of the Realm, a number of Tier 3 Minions equal to the number of PCs, and two adversaries of your choice within Far range of a chosen PC. The Knight of the Realm immediately takes the spotlight.
  - name: Collateral Damage - Reaction
    text: When an adversary is defeated, spend a Fear to have a stray siege weapon strike a point on the battlefield. All targets within Very Close range must make an Agility Reaction Roll. Targets who fail take **3d8+3** physical or magic damage and must mark a Stress; targets who succeed must mark a Stress.
```
### Avversari



```statblock
layout: Daggerheart Adversary
source: daggerheart-adversary
name: Demon of Wrath
tier: 3
type: Bruiser
description: A hulking demon with boulder-sized fists, driven by endless rage.
motives_and_tactics: Fuel anger, impress rivals, wreak havoc
difficulty: 17
thresholds: 22/40
hp: 7
stress: 5
atk: "+3"
attack: Fists
range: Very Close
damage: 3d8+1 (Magical)
experience: Intimidation +2
feats:
  - name: Anger Unrelenting - Passive
    text: The Demon's attacks deal direct damage.
  - name: Battle Lust - Action
    text: "**Spend a Fear** to boil the blood of all PCs within Far range. They use a d20 as their Fear Die until the end of the scene."
  - name: Retaliation - Reaction
    text: When the Demon takes damage from an attack within Close range, you can **mark a Stress** to make a standard attack against the attacker.
  - name: Blood and Souls - Reaction (Countdown Loop 6)
    text: Activate the first time an attack is made within sight of the Demon. It ticks down when a PC takes a violent action. When it triggers, summon **1d4** Minor Demons, who appear at Close range.
```

```statblock
layout: Daggerheart Adversary
source: daggerheart-adversary
name: Young Ice Dragon
tier: 3
type: Solo
description: A glacier-blue dragon with four powerful limbs and frost-tinged wings.
motives_and_tactics: Avalanche, defend lair, fly, freeze, defend what is mine, maul
difficulty: 18
thresholds: 21/41
hp: 10
stress: 6
atk: "+7"
attack: Bite and Claws
range: Close
damage: 4d10 (Physical)
experience: Protect What Is Mine +3
feats:
  - name: Relentless (3) - Passive
    text: The Dragon can be spotlighted up to three times per GM turn. Spend Fear as usual to spotlight them.
  - name: Rend and Crush - Passive
    text: If a target damaged by the Dragon doesn't mark an Armor Slot to reduce the damage, they must mark a Stress.
  - name: No Hope - Passive
    text: When a PC rolls with Fear while within Far range of the Dragon, they lose a Hope.
  - name: Blizzard Breath - Action
    text: "**Spend 2 Fear** to release an icy whorl in front of the Dragon within Close range. All targets must make an Agility Reaction Roll. Targets who fail take **4d6+5** magic damage and are Restrained by ice until freed with a Strength Roll; targets who succeed must mark 2 Stress or take half damage."
  - name: Avalanche - Action
    text: "**Spend a Fear** to unleash a huge downfall of snow and ice covering all creatures within Far range. Targets must succeed on an Instinct Reaction Roll or become Vulnerable until they dig free. For each PC that fails, you gain a Fear."
  - name: Frozen Scales - Reaction
    text: When a creature makes a successful attack against the Dragon from within Very Close range, they must mark a Stress and become Chilled until their next rest or they clear a Stress. While Chilled, they have disadvantage on attack rolls.
  - name: Momentum - Reaction
    text: When the Dragon makes a successful attack against a PC, you gain a Fear.
```
