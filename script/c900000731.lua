--MTG Llanowar Elves
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	--"Must first be Special Summoned (from your hand) by banishing 1
	--"MTG Forest" from your Extra Deck face-up."
	c:EnableReviveLimit()
	MTG.AddExtraBanishSummonProcedure(c,1,CARD_MTG_FOREST)
	--"During your Main Phase: You can change this card's battle position, and if
	--you do, send 1 "MTG" card from your Deck to the GY."
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.postg)
	e1:SetOperation(s.posop)
	c:RegisterEffect(e1)
	--"While this card is face-up on the field, face-up monsters your opponent
	--controls are changed to the same battle position as this card."
	--
	--Built as a trigger on EVENT_ADJUST rather than a true continuous lock: the
	--engine has no effect that holds a monster's battle position equal to
	--another card's. EVENT_ADJUST is re-evaluated constantly, so this behaves
	--continuously in play -- it catches monsters that arrive face-up and
	--monsters that change position, and it re-applies after this card flips.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_POSITION)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_ADJUST)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.synccon)
	e2:SetOperation(s.syncop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_FOREST}

function s.tgfilter(c)
	return c:IsSetCard(SET_MTG) and c:IsAbleToGrave()
end
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanChangePosition() end
	Duel.SetOperationInfo(0,CATEGORY_POSITION,e:GetHandler(),1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
--"and if you do" -- the mill only happens when the position actually changed.
--
--Duel.ChangePosition's two-argument form is (face-up attack -> A, face-DOWN
--attack -> B); a monster sitting in face-up defence matches neither, so it
--never moved. The single-argument form sets one position outright, which is
--what a straight toggle wants.
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local pos=c:IsPosition(POS_FACEUP_ATTACK) and POS_FACEUP_DEFENSE or POS_FACEUP_ATTACK
	if Duel.ChangePosition(c,pos)==0 then return end
	if not Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT) end
end

--The position this card is currently in, which the opponent's board is matched
--to. A face-down Llanowar Elves has no face-up position to copy, and the effect
--only applies "while this card is face-up".
function s.mypos(e)
	local c=e:GetHandler()
	if not c:IsFaceup() then return nil end
	if c:IsPosition(POS_FACEUP_ATTACK) then return POS_FACEUP_ATTACK end
	return POS_FACEUP_DEFENSE
end
function s.mismatch(c,pos)
	return c:IsFaceup() and not c:IsPosition(pos) and c:IsCanChangePosition()
end
function s.synccon(e,tp,eg,ep,ev,re,r,rp)
	local pos=s.mypos(e)
	return pos~=nil and Duel.IsExistingMatchingCard(s.mismatch,tp,0,LOCATION_MZONE,1,nil,pos)
end
function s.syncop(e,tp,eg,ep,ev,re,r,rp)
	local pos=s.mypos(e)
	if not pos then return end
	local g=Duel.GetMatchingGroup(s.mismatch,tp,0,LOCATION_MZONE,nil,pos)
	if #g>0 then Duel.ChangePosition(g,pos) end
end
