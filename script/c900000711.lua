--MTG Island
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon: 1 "MTG" monster
	Link.AddProcedure(c,s.matfilter,1,1)
	--If this card is banished: excavate 1, Set it if it is an "MTG" Spell/Trap,
	--then draw 3 if all 3 copies are banished.
	--
	--No SetRange, matching Maliss <P> White Rabbit (69272449): for an
	--EFFECT_TYPE_SINGLE trigger the engine follows the card itself, and this one
	--fires as the card arrives in the banish zone.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_REMOVE)
	e1:SetTarget(s.extg)
	e1:SetOperation(s.exop)
	c:RegisterEffect(e1)
	--During your Standby Phase, if banished: shuffle it into the Extra Deck
	MTG.AddStandbyReturn(c,aux.Stringid(id,1))
end
s.listed_series={SET_MTG}
s.listed_names={id}

function s.matfilter(c)
	return c:IsSetCard(SET_MTG) and c:IsMonster()
end

function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_DRAW,nil,0,tp,3)
end
--The Set half is limited to Spell/Trap because a monster cannot be Set to the
--Spell & Trap Zone; the original wording did not distinguish.
function s.setfilter(c)
	return c:IsSetCard(SET_MTG) and c:IsSpellTrap() and c:IsSSetable()
end
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 then
		Duel.ConfirmDecktop(tp,1)
		local tc=Duel.GetDecktopGroup(tp,1):GetFirst()
		if tc and s.setfilter(tc) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
			Duel.DisableShuffleCheck()
			Duel.SSet(tp,tc)
			--"also it can be activated this turn": a Set Spell/Trap normally
			--cannot be activated on the turn it was Set, so the permission has
			--to be granted explicitly and expires with the turn.
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
			tc:RegisterEffect(e1,true)
		elseif tc then
			Duel.DisableShuffleCheck()
			Duel.SendtoGrave(tc,REASON_EFFECT)
		end
	end
	if MTG.BanishedCount(tp,id)>=3 and Duel.IsPlayerCanDraw(tp,3) then
		Duel.BreakEffect()
		Duel.Draw(tp,3,REASON_EFFECT)
	end
end
