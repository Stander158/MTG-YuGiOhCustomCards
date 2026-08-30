--MTG Wandering Emperor
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	--A card must be told it may hold a custom counter before one can be placed.
	c:EnableCounterPermit(COUNTER_WANDERING_EMPEROR)
	--Activate. The Extra Deck banish is the activation cost.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(MTG.ExtraBanishCost(2,CARD_MTG_PLAINS))
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	--"If you control an "MTG" card, you can activate this card from your hand,
	--or the turn it was Set."
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e2:SetCondition(s.handcon)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	c:RegisterEffect(e3)
	--"Each time you would take battle or effect damage, you can remove 1
	--Wandering Emperor Counter from this card instead."
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CHANGE_DAMAGE)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTargetRange(1,0)
	e4:SetValue(s.damval)
	c:RegisterEffect(e4)
	--"Once per turn (Quick Effect): You can activate 1 of these effects."
	--
	--EFFECT_TYPE_QUICK_O, not IGNITION. As an ignition effect this was usable
	--only in your own Main Phase, which is what "can't activate it on the
	--opponent's turn" was. The card it is named after is instant-speed, and a
	--Continuous Trap that can only act on its controller's turn is a strange
	--thing, so the printed text gains "(Quick Effect)" to match.
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE+CATEGORY_SPECIAL_SUMMON
		+CATEGORY_TOKEN+CATEGORY_REMOVE+CATEGORY_COUNTER)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetRange(LOCATION_SZONE)
	e5:SetCountLimit(1)
	e5:SetTarget(s.efftg)
	e5:SetOperation(s.effop)
	c:RegisterEffect(e5)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_PLAINS,CARD_SAMURAI_TOKEN}
s.counter_place_list={COUNTER_WANDERING_EMPEROR}

function s.handcon(e)
	return Duel.IsExistingMatchingCard(s.mtgfilter,e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,e:GetHandler())
end
function s.mtgfilter(c)
	return c:IsSetCard(SET_MTG) and c:IsFaceup()
end

--"When this card resolves: Place 3 Wandering Emperor Counters on it."
--
--Only the location is checked. An IsRelateToEffect guard was here too, and it
--is the one link in this chain that cannot be verified statically -- if it ever
--reads false the card lands with no counters, which silently removes two of its
--three menu options and makes the whole effect look like it works only
--sometimes.
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_SZONE) and c:IsFaceup() then
		c:AddCounter(COUNTER_WANDERING_EMPEROR,3)
	end
end

--The value function is where the engine asks how much damage to apply, so the
--replacement is decided here. Returning 0 is what "instead" means; the counter
--is the price.
--
--Mandatory, not optional, and that is forced by the engine rather than chosen:
--a prompt here dies with "function yesno action is not allowed here". Value
--functions may have side effects -- Duel.Hint and e:Reset are used this way by
--shipped cards -- but they may not stop and ask the player anything, and no
--shipped card prompts from one. There is no optional-replacement mechanism for
--damage the way there is for destruction, so the printed text drops its "you
--can" to match what the card actually does.
function s.damval(e,re,val,r,rp,rc)
	local c=e:GetHandler()
	local tp=c:GetControler()
	if val<=0 then return val end
	if not (c:IsFaceup() and c:IsLocation(LOCATION_SZONE)) then return val end
	if c:GetCounter(COUNTER_WANDERING_EMPEROR)<1 then return val end
	Duel.Hint(HINT_CARD,0,id)
	c:RemoveCounter(tp,COUNTER_WANDERING_EMPEROR,1,REASON_EFFECT)
	return 0
end

--The three bullets. Which ones are offered depends on the counters available
--and on there being a legal target, so an option that cannot resolve is never
--shown.
function s.tgfilter(c)
	return c:IsFaceup()
end
function s.rmfilter(c)
	return c:IsFaceup() and c:IsAbleToRemove()
end
function s.options(e,tp)
	local c=e:GetHandler()
	local ct=c:GetCounter(COUNTER_WANDERING_EMPEROR)
	local ops,idx={},{}
	if Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) then
		table.insert(ops,aux.Stringid(id,0)) table.insert(idx,1)
	end
	if ct>=1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,CARD_SAMURAI_TOKEN,0,TYPES_TOKEN,2000,2000,5,RACE_WARRIOR,ATTRIBUTE_EARTH) then
		table.insert(ops,aux.Stringid(id,1)) table.insert(idx,2)
	end
	if ct>=2 and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) then
		table.insert(ops,aux.Stringid(id,2)) table.insert(idx,3)
	end
	return ops,idx
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ops=s.options(e,tp)
		return #ops>0
	end
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ops,idx=s.options(e,tp)
	if #ops==0 then return end
	local pick=idx[Duel.SelectOption(tp,table.unpack(ops))+1]
	if pick==1 then
		c:AddCounter(COUNTER_WANDERING_EMPEROR,1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		local tc=g:GetFirst()
		if not tc then return end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(400)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		tc:RegisterEffect(e2)
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e3:SetValue(1)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
		tc:RegisterEffect(e3)
	elseif pick==2 then
		c:RemoveCounter(tp,COUNTER_WANDERING_EMPEROR,1,REASON_EFFECT)
		local token=Duel.CreateToken(tp,CARD_SAMURAI_TOKEN)
		Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
	else
		c:RemoveCounter(tp,COUNTER_WANDERING_EMPEROR,2,REASON_EFFECT)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
		if #g>0 then Duel.Remove(g,POS_FACEUP,REASON_EFFECT) end
	end
end
