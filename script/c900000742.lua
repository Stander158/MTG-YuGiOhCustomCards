--MTG Memory Deluge
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	MTG.InstallTrackers()
	--"To activate this card, you must banish 2 cards from your Extra Deck
	--face-up, including 1 "MTG Island"; excavate cards from the top of your Deck
	--equal to the number of cards banished this turn, add up to 2 excavated
	--cards that mention "MTG" to your hand, also place the rest on the bottom of
	--your Deck in any order."
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(MTG.ExtraBanishCost(2,CARD_MTG_ISLAND))
	e1:SetTarget(s.extg)
	e1:SetOperation(s.exop)
	c:RegisterEffect(e1)
	--"You can banish this card from your GY and banish 3 cards from your Extra
	--Deck face-up, including 1 "MTG Island"; [the same excavation]."
	--
	--Same payload, different price -- three Extra Deck cards instead of two, and
	--the card itself. Both routes share s.exop rather than repeating it, so a
	--change to the excavation cannot land on only one of them.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	--No count limit: the printed text does not have one. The cost is what
	--bounds it -- this card plus 3 Extra Deck cards including a named land,
	--and there are only 3 copies of that land in the whole Extra Deck.
	e2:SetCost(s.gycost)
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_ISLAND}

--Two banishes in one cost: this card itself, plus three from the Extra Deck.
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():IsAbleToRemoveAsCost()
			and MTG.CanPayExtra(tp,3,CARD_MTG_ISLAND)
	end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
	local g=MTG.SelectExtra(tp,3,CARD_MTG_ISLAND)
	if g then Duel.Remove(g,POS_FACEUP,REASON_COST) end
end

function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end
function s.thfilter(c)
	return c:ListsArchetype(SET_MTG) and c:IsAbleToHand()
end
--"the number of cards banished this turn" is read after the cost has been paid,
--so this card and the Extra Deck cards are included -- which is what makes the
--effect scale with how much the deck has been churning.
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local ct=MTG.BanishedThisTurn()
	if ct<=0 then return end
	local dct=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
	if dct<ct then ct=dct end
	if ct<=0 then return end
	Duel.ConfirmDecktop(tp,ct)
	local g=Duel.GetDecktopGroup(tp,ct)
	local hg=g:Filter(s.thfilter,nil)
	if #hg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=hg:Select(tp,0,2,nil)
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
			g:Sub(sg)
		end
	end
	if #g>0 then
		Duel.SortDecktop(tp,tp,#g)
		--Bottom-decked one at a time, which is how the engine expresses "in any
		--order" for the remainder of an excavation.
		for tc in aux.Next(g) do
			Duel.MoveSequence(tc,1)
		end
	end
end
