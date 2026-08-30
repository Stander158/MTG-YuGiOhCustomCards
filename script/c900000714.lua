--MTG Plains
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon: 1 Tuner + 1+ non-Tuner monsters
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	--If this card is banished: gain 1200 LP, then banish 1 monster if all 3
	--copies are banished
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_REMOVE)
	e1:SetTarget(s.lptg)
	e1:SetOperation(s.lpop)
	c:RegisterEffect(e1)
	--During your Standby Phase, if banished: shuffle it into the Extra Deck
	MTG.AddStandbyReturn(c,aux.Stringid(id,2))
end
s.listed_series={SET_MTG}
s.listed_names={id}

function s.lptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1200)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_MZONE)
end
function s.rmfilter(c)
	return c:IsAbleToRemove()
end
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Recover(tp,1200,REASON_EFFECT)
	if MTG.BanishedCount(tp,id)<3 or not MTG.BonusAvailable(tp,id) then return end
	if not Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) then return end
	if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then return end
	MTG.UseBonus(tp,id)
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	--"its controller gains LP equal to its ATK" -- read before the banish,
	--since a banished card has no ATK to ask for.
	local atk=tc:GetAttack()
	local owner=tc:GetControler()
	if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)>0 and atk>0 then
		Duel.Recover(owner,atk,REASON_EFFECT)
	end
end
