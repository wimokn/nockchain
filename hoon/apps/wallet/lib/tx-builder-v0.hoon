/=  transact  /common/tx-engine
/=  wt  /apps/wallet/lib/types
/=  zo  /common/zoon
::
|=  $:  names=(list nname:transact)
        =order:wt
        fee=coins:transact
        sign-key=schnorr-seckey:transact
        =timelock-intent:transact
        get-note=$-(nname:transact nnote:v0:transact)
    ==
|^
^-  inputs:transact
?-  -.order
    %multiple  (create-multiple-inputs build-multiple-ledger)
    %single  (create-single-inputs build-single-ledger names)
==
::
++  build-multiple-ledger
  ?>  ?=(%multiple -.order)
  =/  gifts=(list coins:transact)  gifts.order
  =/  recipients=(list sig:transact)  (parse-recipients recipients.order)
  ?.  ?&  =((lent names) (lent recipients))
          =((lent names) (lent gifts))
      ==
    ~|("different number of names/recipients/gifts" !!)
  =|  result=ledger:wt
  |-
  ?~  names  result
  ?~  gifts  result
  ?~  recipients  result
  %=  $
    result      [[i.names i.recipients i.gifts timelock-intent] result]
    names       t.names
    gifts       t.gifts
    recipients  t.recipients
  ==
::
++  build-single-ledger
  ?>  ?=(%single -.order)
  =/  recipient=sig:transact  (parse-recipient recipient.order)
  ::  validate sufficient funds
  =/  total-assets=coins:transact
    %+  roll  names
    |=  [name=nname:transact acc=coins:transact]
    (add acc assets:(get-note name))
  ?.  (gte total-assets (add gift.order fee))
    ~|("insufficient funds: need {<(add gift.order fee)>}, have {<total-assets>}" !!)
  ::  create single ledger entry
  ~[[-.names recipient gift.order timelock-intent]]
::
++  create-multiple-inputs
  |=  =ledger:wt
  ^-  inputs:transact
  =/  [ins=(list $>(%0 input:transact)) spent-fee=?]
    %^  spin  ledger  `?`%.n
    |=  $:  $:  name=nname:transact
                recipient=sig:transact
                gift=coins:transact
                =timelock-intent:transact
            ==
          spent-fee=?
        ==
    =/  note=nnote:v0:transact  (get-note name)
    ?:  (gth gift assets.note)
      ~|  "gift {<gift>} larger than assets {<assets.note>} for recipient {<recipient>}"
      !!
    ?:  ?&  !spent-fee
            (lte (add gift fee) assets.note)
        ==
      ::  we can subtract the fee from this note
      :_  %.y
      (create-input note recipient gift timelock-intent fee)
    ::  we cannot subtract the fee from this note
    :_  spent-fee
    (create-input note recipient gift timelock-intent 0)
  ?.  spent-fee
    ~|("no note suitable to subtract fee from, aborting operation" !!)
  (multi:new:v0:inputs:transact ins)
::
++  create-single-inputs
  |=  [=ledger:wt names=(list nname:transact)]
  ^-  inputs:transact
  ?~  ledger  ~
  =/  recipient=sig:transact  recipient.i.ledger
  =/  gifts=coins:transact  gifts.i.ledger
  =/  =timelock-intent:transact  timelock-intent.i.ledger
  (distribute-single-spend names recipient gifts timelock-intent)
::
++  distribute-single-spend
  |=  $:  names=(list nname:transact)
          recipient=sig:transact
          gifts=coins:transact
          =timelock-intent:transact
      ==
  ::  check total assets can cover gift + fee
  =/  total-assets=coins:transact
    %+  roll  names
    |=  [name=nname:transact acc=coins:transact]
    (add acc assets:(get-note name))
  ?.  (gte total-assets (add gifts fee))
    ~|("insufficient total assets: need {<(add gifts fee)>}, have {<total-assets>}" !!)
  ::  distribute gift across notes, with fee distributed separately
  =/  remaining-gift=coins:transact  gifts
  =/  remaining-fee=coins:transact  fee
  =|  result=(list $>(%0 input:transact))
  |-
  ?~  names  (multi:new:v0:inputs:transact result)
  ::  exit early if nothing left to distribute
  ?:  &(=(0 remaining-gift) =(0 remaining-fee))
    (multi:new:v0:inputs:transact result)
  =/  note=nnote:v0:transact  (get-note i.names)
  ::  determine how much of the gift this note should handle
  =/  gift-portion=coins:transact
    ?:  =(0 remaining-gift)  0
    (min remaining-gift assets.note)
  =.  remaining-gift  (sub remaining-gift gift-portion)
  ::  determine fee portion after reserving for gift
  =/  available-for-fee=coins:transact  (sub assets.note gift-portion)
  =/  fee-portion=coins:transact
    ?:  =(0 remaining-fee)  0
    (min remaining-fee available-for-fee)
  =.  remaining-fee  (sub remaining-fee fee-portion)
  ::  only create input if there's something to spend
  ?:  &(=(0 gift-portion) =(0 fee-portion))
    $(names t.names)
  ::  create input with this note's contribution
  =/  input=input:transact
    (create-distributed-input note recipient gift-portion timelock-intent fee-portion)
  ?>  ?=(%0 -.input)
  =.  result  [input result]
  $(names t.names)
::
++  create-distributed-input
  |=  $:  note=nnote:v0:transact
          recipient=sig:transact
          gift-portion=coins:transact
          =timelock-intent:transact
          fee-portion=coins:transact
      ==
  ^-  input:transact
  =/  used=coins:transact  (add gift-portion fee-portion)
  ?.  (gte assets.note used)
    ~|("note has insufficient assets: need {<used>}, have {<assets.note>}" !!)
  =/  refund=coins:transact  (sub assets.note used)
  =/  refund-address=sig:transact  sig.note
  =/  seed-list=(list seed:v0:transact)
    =|  seeds=(list seed:v0:transact)
    ::  add gift seed if there's a gift portion
    =?  seeds  (gth gift-portion 0)
      :_  seeds
      %-  new:seed:v0:transact
      :*  *(unit source:transact)
          recipient
          timelock-intent
          gift-portion
          (hash:nnote:v0:transact note)
      ==
    ::  add refund seed if there's a refund
    =?  seeds  (gth refund 0)
      :_  seeds
      %-  new:seed:v0:transact
      :*  *(unit source:transact)
          refund-address
          *timelock-intent:transact
          refund
          (hash:nnote:v0:transact note)
      ==
    seeds
  =/  seeds-set=seeds:v0:transact  (new:seeds:transact seed-list)
  =/  spend-obj=spend:v0:transact  (new:spend:v0:transact seeds-set fee-portion)
  =.  spend-obj  (sign:spend:v0:transact spend-obj sign-key)
  [%0 note spend-obj]
::
++  create-input
  |=  $:  note=nnote:v0:transact
          recipient=sig:transact
          gifts=coins:transact
          =timelock-intent:transact
          fee=coins:transact
      ==
  ^-  $>(%0 input:transact)
  =/  gift-seed=seed:v0:transact
    %-  new:seed:v0:transact
    :*  *(unit source:transact)
        recipient
        timelock-intent
        gifts
        (hash:nnote:v0:transact note)
    ==
  =/  refund=coins:transact  (sub assets.note (add gifts fee))
  =/  refund-address=sig:transact  sig.note
  =/  seed-list=(list seed:v0:transact)
    ?:  =(0 refund)  ~[gift-seed]
    :~  gift-seed
        %-  new:seed:v0:transact
        :*  *(unit source:transact)
            refund-address
            *timelock-intent:transact
            refund
            (hash:nnote:v0:transact note)
        ==
    ==
  =/  seeds-set=seeds:v0:transact  (new:seeds:v0:transact seed-list)
  =/  spend-obj=spend:v0:transact  (new:spend:v0:transact seeds-set fee)
  =.  spend-obj  (sign:spend:v0:transact spend-obj sign-key)
  [%0 note spend-obj]
::
++  parse-recipients
  |=  raw-recipients=(list [m=@ pks=(list @t)])
  ^-  (list sig:transact)
  (turn raw-recipients parse-recipient)
::
++  parse-recipient
  |=  raw-recipient=[m=@ pks=(list @t)]
  ^-  sig:transact
  =/  lk=sig:transact
    %+  from-list:m-of-n:new:sig:transact  m.raw-recipient
    (turn pks.raw-recipient from-b58:schnorr-pubkey:transact)
  ?.  (spendable:sig:transact lk)
    ~|("recipient {<(to-b58:sig:transact lk)>} is not spendable" !!)
  lk
--
