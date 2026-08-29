--MTG Mountain
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon: 2 "MTG" monsters
	Fusion.AddProcMix(c,true,true,s.matfilter,s.matfilter)
	--If this card is banished: 400 damage, then 1200 more if all 3 are banished
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_REMOVE)
	e1:SetTarget(s.damtg)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)
	--During your Standby Phase, if banished: shuffle it into the Extra Deck
	MTG.AddStandbyReturn(c,aux.Stringid(id,1))
end
s.listed_series={SET_MTG}
s.listed_names={id}

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_MTG,fc,sumtype,tp) and c:IsMonster()
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(400)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,400)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
	if MTG.BanishedCount(tp,id)>=3 then
		Duel.BreakEffect()
		Duel.Damage(1-tp,1200,REASON_EFFECT)
	end
end
