--MTG Swamp
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon: 2 Level 1 monsters
	Xyz.AddProcedure(c,nil,1,2)
	--If this card is banished: look at the opponent's hand, then discard 1 from
	--it if all 3 copies are banished
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_REMOVE)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	--During your Standby Phase, if banished: shuffle it into the Extra Deck
	MTG.AddStandbyReturn(c,aux.Stringid(id,2))
end
s.listed_series={SET_MTG}
s.listed_names={id}

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_HANDES,nil,1,1-tp,LOCATION_HAND)
end
--"Look at" is a temporary reveal, not permanent public knowledge. Duel.Confirm-
--Cards leaves the hand face-up to the viewer until it is shuffled, so the
--ShuffleHand at the end is what ends the look -- and it has to happen on every
--path. It used to sit inside the "3 banished" branch, so any resolution that
--did not reach the discard left the opponent's hand exposed for the rest of the
--duel. Trap Dustshoot (64697231) shuffles unconditionally for the same reason.
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
	if #hg==0 then return end
	Duel.ConfirmCards(tp,hg)
	if MTG.BanishedCount(tp,id)>=3 and MTG.BonusAvailable(tp,id) then
		--Paying is the "you can" here; with nothing discardable there is
		--nothing to pay for, so the prompt is skipped rather than wasting 3000 LP.
		local dg=hg:Filter(Card.IsDiscardable,nil)
		if #dg>0 and Duel.CheckLPCost(tp,3000)
			and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			MTG.UseBonus(tp,id)
			Duel.BreakEffect()
			Duel.PayLPCost(tp,3000)
			--You have just looked at the hand, so you choose which card goes.
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
			local sg=dg:Select(tp,1,1,nil)
			if #sg>0 then Duel.SendtoGrave(sg,REASON_EFFECT|REASON_DISCARD) end
		end
	end
	Duel.ShuffleHand(1-tp)
end
