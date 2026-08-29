--MTG Urabrask, Heretic Praetor
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--"You can only control 1"
	c:SetUniqueOnField(1,0,id)
	--"Cannot be Normal Summoned/Set. Must first be Special Summoned (from your
	--hand) by banishing 2 cards from your Extra Deck face-up, including 1
	--"MTG Mountain"."
	c:EnableUnsummonable()
	c:EnableReviveLimit()
	MTG.AddExtraBanishSummonProcedure(c,2,CARD_MTG_MOUNTAIN)
	--"During your Draw Phase, if you would conduct your normal draw, draw 2
	--cards instead." Same shape as Time-Tearing Morganite (19403423).
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_DRAW_COUNT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(1,0)
	e1:SetValue(2)
	c:RegisterEffect(e1)
	--"Once per turn, if your opponent adds a card(s) from their Deck to their
	--hand, except during the Draw Phase or the Damage Step: You can banish that
	--card." Soft once per turn -- SetCountLimit without the passcode, so it
	--resets if this card leaves and returns.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.rmcon)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_MOUNTAIN}

function s.rmfilter(c,tp)
	return c:IsPreviousLocation(LOCATION_DECK) and c:IsPreviousControler(1-tp)
end
--Duel.IsDamageStep does not exist; the phase constants are the check. The Draw
--Phase exclusion is written the same way for the same reason.
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	if ph==PHASE_DRAW or ph==PHASE_DAMAGE or ph==PHASE_DAMAGE_CAL then return false end
	return eg:IsExists(s.rmfilter,1,nil,tp)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.rmfilter,nil,tp)
	if chk==0 then return #g>0 and g:IsExists(Card.IsAbleToRemove,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,1-tp,LOCATION_HAND)
end
--"that card" refers back to "a card(s)", so the whole group added by that event
--is banished, not just one of them.
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.rmfilter,nil,tp):Filter(Card.IsAbleToRemove,nil)
	g=g:Filter(Card.IsLocation,nil,LOCATION_HAND)
	if #g>0 then Duel.Remove(g,POS_FACEUP,REASON_EFFECT) end
end
