--MTG Vorinclex, Voice of Hunger
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	--"Cannot be Normal Summoned/Set. Must first be Special Summoned (from your
	--hand) by banishing 2 cards from your Extra Deck face-up, including 1
	--"MTG Forest"."
	c:EnableUnsummonable()
	c:EnableReviveLimit()
	MTG.AddExtraBanishSummonProcedure(c,2,CARD_MTG_FOREST)
	--"Your opponent cannot target this card with card effects."
	--
	--aux.tgoval is the engine's own "only the opponent's effects" value, so this
	--stays out of your own way -- your removal and your own "MTG" cards can
	--still target it.
	--
	--Deliberately not EFFECT_FLAG_CANNOT_DISABLE: the text does not say the
	--protection survives negation, and Mekk-Knight Crusadia Avramax (21887175),
	--which is where this wording comes from almost verbatim, does not set it
	--either. A negated Vorinclex is targetable.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	--"Monsters your opponent controls cannot target monsters for attacks,
	--except this card."
	--
	--Shaped after Altergeist Fifinellag (12977245): a field effect whose target
	--range is the opponent's Monster Zone -- those are the attackers it binds --
	--and whose value answers, for a proposed battle target, whether it may NOT
	--be chosen. Everything but this card answers yes, which is what makes it a
	--lure rather than a shield.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetValue(s.atlimit)
	c:RegisterEffect(e2)
	--"If this card attacks a Defense Position monster, inflict piercing battle
	--damage to your opponent."
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e3)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_FOREST}

function s.atlimit(e,c)
	return c~=e:GetHandler()
end
