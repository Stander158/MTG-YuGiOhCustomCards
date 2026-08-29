--MTG Force of Will
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--"When a card or effect is activated: Negate that activation, and if you do,
	--destroy that card."
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.cost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	--"You can activate this card from your hand by paying 400 LP and banishing
	--1 card from your hand face-down." EFFECT_TRAP_ACT_IN_HAND grants only the
	--permission; the extra price is charged in the cost below.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_MOUNTAIN}

function s.handcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.CheckLPCost(tp,400)
		and Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,tp,LOCATION_HAND,0,1,e:GetHandler())
end

--One cost function for both routes. The Extra Deck banish is always owed; the
--LP and the face-down hand banish are owed only when this card is being
--activated out of the hand, which is what "activate this card from your hand
--by..." means -- it is the price of the permission, not of the card.
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local fromhand=c:IsLocation(LOCATION_HAND)
	if chk==0 then
		if not MTG.CanPayExtra(tp,2,CARD_MTG_MOUNTAIN) then return false end
		if fromhand then
			return Duel.CheckLPCost(tp,400)
				and Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,tp,LOCATION_HAND,0,1,c)
		end
		return true
	end
	local g=MTG.SelectExtra(tp,2,CARD_MTG_MOUNTAIN)
	if g then Duel.Remove(g,POS_FACEUP,REASON_COST) end
	if fromhand then
		Duel.PayLPCost(tp,400)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local hg=Duel.SelectMatchingCard(tp,Card.IsAbleToRemoveAsCost,tp,LOCATION_HAND,0,1,1,c)
		--Face-down, which hides it from anything that reads the banish zone.
		if #hg>0 then Duel.Remove(hg,POS_FACEDOWN,REASON_COST) end
	end
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsChainNegatable(ev)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(re:GetHandler(),REASON_EFFECT)
	end
end
