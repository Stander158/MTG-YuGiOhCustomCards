--MTG Mu Terra Grand
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--"When this card is activated: You can add 1 "MTG" monster from your Deck to
	--your hand."
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--"Monsters cannot declare an attack unless their controller controls a
	--Defense Position monster."
	--
	--Applies to both players, which is why the target range covers both sides.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.atlimit)
	c:RegisterEffect(e2)
	--"At the end of the Damage Step, if a monster declared an attack: Change
	--that monster to Defense Position."
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_POSITION)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_DAMAGE_STEP_END)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCondition(s.poscon)
	e3:SetOperation(s.posop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_MTG}

function s.thfilter(c)
	return c:IsSetCard(SET_MTG) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then return end
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--"unless their controller controls a Defense Position monster" -- read per
--attacker, so each player is judged on their own board.
function s.defexists(tp)
	return Duel.IsExistingMatchingCard(s.deffilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.deffilter(c)
	return c:IsPosition(POS_DEFENSE)
end
function s.atlimit(e,c)
	return not s.defexists(c:GetControler())
end

function s.poscon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	return a~=nil and a:IsRelateToBattle() and a:IsFaceup()
		and a:IsPosition(POS_FACEUP_ATTACK) and a:IsCanChangePosition()
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	if a and a:IsRelateToBattle() and a:IsFaceup() then
		Duel.ChangePosition(a,POS_FACEUP_DEFENSE)
	end
end
