--MTG Elesh Norn, Grand Cenobite
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	c:EnableUnsummonable()
	c:EnableReviveLimit()
	MTG.AddExtraBanishSummonProcedure(c,2,CARD_MTG_PLAINS)
	--"Other monsters you control gain 800 ATK/DEF."
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.othertarget)
	e1:SetValue(800)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)
	--"Monsters your opponent controls lose 800 ATK/DEF."
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetValue(-800)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
	--"If a monster's ATK or DEF becomes 0 by this effect, send it to the GY."
	--
	--Only the opponent's side can reach 0 here, since your own monsters are
	--being raised. EVENT_ADJUST is the engine's re-evaluation point, so this
	--catches a monster arriving at 0 as well as one pushed there.
	--
	--Caveat worth knowing: once a value is clamped at 0 the engine cannot say
	--whether it started above 0, so a monster printed with 0 ATK is also sent.
	--Distinguishing them would mean tracking each monster's value from before
	--the debuff applied, which is a lot of machinery for an edge case.
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_TOGRAVE)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_ADJUST)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.tgcon)
	e5:SetOperation(s.tgop)
	c:RegisterEffect(e5)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_PLAINS}

function s.othertarget(e,c)
	return c~=e:GetHandler()
end

function s.tgfilter(c)
	return c:IsFaceup() and (c:GetAttack()==0 or c:GetDefense()==0) and c:IsAbleToGrave()
end
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.tgfilter,tp,0,LOCATION_MZONE,1,nil)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT) end
end
