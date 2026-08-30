# "MTG" — custom cards for EDOPro

17 custom Yu-Gi-Oh! cards for **Project Ignis: EDOPro**, translating Magic: The
Gathering's land economy into Yu-Gi-Oh.

Cards from your Extra Deck are banished face-up to pay for things. The five
lands — **Island**, **Mountain**, **Forest**, **Plains** and **Swamp**, one for
each Extra Deck summoning method — pay you back for being banished, then shuffle
themselves back on your Standby Phase. Everything else in the set is priced in
lands, and the five Phyrexian Praetors each demand their own colour.

> **Both players need these cards installed.** Custom cards are not transmitted
> during a duel; each client simulates locally, so a missing card on either side
> breaks the game.

---

## Install — auto-updating (recommended)

Add this repository to EDOPro and it will pull updates on every launch.

Edit `config/user_configs.json` in your EDOPro folder — use that file rather
than `configs.json`, so an official EDOPro update can't overwrite your entry.
If the whole file is new, this is all it needs:

```json
{
	"repos": [
		{
			"url": "https://github.com/Stander158/MTG-YuGiOhCustomCards",
			"repo_name": "MTG custom cards",
			"repo_path": "./repositories/mtg",
			"should_update": true,
			"should_read": true
		}
	]
}
```

**If you already have entries in `"repos"`** (from another custom set), add the
object above alongside them — and remember the comma between entries.

Restart EDOPro. The cards appear in the deck editor once **Alternate formats**
is ticked, and a duel must allow custom cards (*Allowed cards: Anything goes*).
They carry the **CSTM** label so they can't be mistaken for real cards.

## Install — manual

Copy `mtg-cards.cdb`, `strings.conf`, `script/` and `pics/` into your EDOPro
`expansions/` folder. Nothing here overwrites a shipped file.

---

## The cards

| Passcode | Name | Type |
| --- | --- | --- |
| 900000711 | MTG Island | WATER / Aqua / Link |
| 900000712 | MTG Mountain | FIRE / Pyro / Fusion |
| 900000713 | MTG Forest | EARTH / Plant / Link |
| 900000714 | MTG Plains | LIGHT / Fairy / Synchro |
| 900000715 | MTG Swamp | DARK / Zombie / Xyz |
| 900000721 | MTG Urabrask, Heretic Praetor | FIRE / Fiend |
| 900000722 | MTG Sheoldred, the Apocalypse | DARK / Fiend |
| 900000723 | MTG Elesh Norn, Grand Cenobite | LIGHT / Fiend |
| 900000724 | MTG Jin-Gitaxias, Progress Tyrant | WATER / Fiend |
| 900000725 | MTG Vorinclex, Voice of Hunger | EARTH / Fiend |
| 900000731 | MTG Llanowar Elves | EARTH / Spellcaster |
| 900000741 | MTG Wandering Emperor | Trap / Continuous |
| 900000742 | MTG Memory Deluge | Spell / Quick-Play |
| 900000743 | MTG Force of Will | Trap / Counter |
| 900000744 | MTG Infernal Grasp | Spell / Quick-Play |
| 900000745 | Mu Terra Grand | Spell / Field |
| 900000746 | MTG Scheme of the Praetor | Spell / Continuous |

Plus `Samurai of the Emperor Token` (900000791), which MTG Wandering Emperor
summons. `Mu Terra Grand` is part of the set but deliberately not an "MTG"
card itself -- it searches the archetype without belonging to it.

## Status

Playtested, and a first round of reports has been fixed: the lands not returning
from the banish zone, MTG Wandering Emperor crashing on damage, MTG Elesh Norn
sweeping Link monsters that have no DEF to reduce, MTG Swamp leaving the
opponent's hand revealed, and several effects whose printed limits and code
disagreed.

Still worth watching: MTG Llanowar Elves' battle position lock is a trigger
standing in for a continuous effect the engine does not have, and MTG Elesh
Norn cannot tell a monster reduced to 0 ATK from one printed at 0, so it sends
both. Bug reports welcome.

## Credits

Card design by a friend of the repository owner; implementation and card text in
this repository by the owner.

Card artwork is the official Magic: The Gathering illustrations, retrieved as
art crops from [Scryfall](https://scryfall.com) and credited per card in
[ART-CREDITS.md](ART-CREDITS.md). Two cards use art from elsewhere, noted there.

Magic: The Gathering is © Wizards of the Coast. Yu-Gi-Oh! is © Konami. This is
an unofficial, non-commercial fan project, not affiliated with or endorsed by
either.
