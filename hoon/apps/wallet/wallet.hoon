::  /ker/wallet/wallet: nockchain wallet
/=  bip39  /common/bip39
/=  slip10  /common/slip10
/=  m  /common/markdown/types
/=  md  /common/markdown/markdown
/=  transact  /common/tx-engine
/=  z   /common/zeke
/=  zo  /common/zoon
/=  dumb  /apps/dumbnet/lib/types
/=  *   /common/zose
/=  *  /common/wrapper
/=  wt  /apps/wallet/lib/types
/=  wutils  /apps/wallet/lib/utils
/=  tx-builder  /apps/wallet/lib/tx-builder-v0
=>
=|  bug=_&
|%
::
::  re-exporting names from wallet types while passing the bug flag
++  utils  ~(. wutils bug)
++  debug  debug:utils
++  warn  warn:utils
++  s10  s10:utils
++  moat  (keep state:wt)
--
::
%-  (moat &)
^-  fort:moat
|_  =state:wt
+*  v  ~(. vault:utils state)
    d  ~(. draw:utils state)
    p  ~(. plan:utils transaction-tree.state)
::
++  load
  |=  old=versioned-state:wt
  ^-  state:wt
  |^
  |-
  ?:  ?=(%3 -.old)
    old
  ~>  %slog.[0 'load: State upgrade required']
  ?-  -.old
    %0  $(old state-0-1)
    %1  $(old state-1-2)
    %2  $(old state-2-3)
  ==
  ::
  ++  state-0-1
    ^-  state-1:wt
    ?>  ?=(%0 -.old)
    ~>  %slog.[0 'upgrade version 0 to 1']
    :*  %1
        balance.old
        active-master.old
        keys.old
        last-block.old
        peek-requests.old
        active-transaction.old
        active-input.old
        active-seed.old
        transaction-tree.old
        pending-commands.old
    ==
  ::
  ++  state-1-2
    ^-  state-2:wt
    ?>  ?=(%1 -.old)
    ~>  %slog.[0 'upgrade version 1 to 2']
    :*  %2
        balance=*balance:wt
        active-master.old
        keys.old
        last-block.old
        peek-requests.old
        active-transaction.old
        active-input.old
        active-seed.old
        transaction-tree.old
        pending-commands.old
    ==
  ::
  ++  state-2-3
    ^-  state:wt
    ?>  ?=(%2 -.old)
    ~>  %slog.[0 'upgrade version 2 to 3']
    =/  new-keys=keys:wt
      %+  roll  ~(tap of keys.old)
      |=  [[=trek m=meta-v2:wt] new=keys:wt]
      %-  ~(put of new)
      :-  trek
      ^-  meta:wt
      ?.  ?=(%coil -.m)
        m
      [%coil [%0 +.m]]
    =/  new-master=active:wt
      ?~  active-master.old  ~
      `[%0 +.u.active-master.old]
    :*  %3
        balance.old
        new-master
        new-keys
        last-block.old
        peek-requests.old
        active-transaction.old
        active-input.old
        active-seed.old
        transaction-tree.old
        pending-commands.old
    ==
  --
::
++  peek
  |=  arg=path
  ^-  (unit (unit *))
  %-  (debug "peek: {<arg>}")
  =/  =(pole)  arg
  ?+  pole  ~
    ::
      [%balance ~]
    ``balance.state
    ::
      [%state ~]
    ``state
    ::
    ::  returns a list of pubkeys
      [%tracked-pubkeys include-watch-only=? ~]
    :+  ~
      ~
    =;  signing-keys=(list @t)
      ?.  include-watch-only.pole
        signing-keys
      (weld signing-keys watch-keys:get:v)
    %+  turn
      ~(coils get:v %pub)
    |=  =coil:wt
    key-b58:(to-b58:coil:wt coil)
  ==
::
++  poke
  |=  =ovum:moat
  |^
  ^-  [(list effect:wt) state:wt]
  =/  cause=(unit cause:wt)
    %-  (soft cause:wt)
    cause.input.ovum
  =/  failure=effect:wt  [%markdown '## Poke failed']
  ?~  cause
    %-  (warn "input does not have a proper cause: {<cause.input.ovum>}")
    [~[failure] state]
  =/  =cause:wt  u.cause
  ::%-  (debug "cause: {<-.cause>}")
  =/  wir=(pole)  wire.ovum
  ?+    wir  ~|("unsupported wire: {<wire.ovum>}" !!)
      [%poke %grpc ver=@ pid=@ tag=@tas ~]
    ::
    ::  at the time of writing, there is only one poke that emits a %grpc
    ::  therefore, it is unnecessary at this point to manage pending requests.
    =^  effs  state
      (do-grpc-bind cause tag.wir)
    [effs state]
  ::
      [%poke ?(%one-punch %sys %wallet) ver=@ *]
    ?+    -.cause  ~|("unsupported cause: {<-.cause>}" !!)
        %show                  (show:utils state path.cause)
        %keygen                (do-keygen cause)
        %derive-child          (do-derive-child cause)
        %sign-tx               (do-sign-tx cause)
        %list-notes            (do-list-notes cause)
        %list-notes-by-pubkey  (do-list-notes-by-pubkey cause)
        %list-notes-by-pubkey-csv  (do-list-notes-by-pubkey-csv cause)
        %create-tx             (do-create-tx cause)
        %update-balance-grpc   (do-update-balance-grpc cause)
        %sign-message          (do-sign-message cause)
        %verify-message        (do-verify-message cause)
        %sign-hash             (do-sign-hash cause)
        %verify-hash           (do-verify-hash cause)
        %import-keys           (do-import-keys cause)
        %import-extended       (do-import-extended cause)
        %import-watch-only-pubkey  (do-import-watch-only-pubkey cause)
        %export-keys           (do-export-keys cause)
        %export-master-pubkey  (do-export-master-pubkey cause)
        %import-master-pubkey  (do-import-master-pubkey cause)
        %gen-master-privkey    (do-gen-master-privkey cause)
        %send-tx               (do-send-tx cause)
        %show-tx               (do-show-tx cause)
        %list-active-addresses  (do-list-active-addresses cause)
        %show-seedphrase       (do-show-seedphrase cause)
        %show-master-pubkey    (do-show-master-pubkey cause)
        %show-master-privkey   (do-show-master-privkey cause)
        %list-master-addresses  (do-list-master-addresses cause)
        %set-active-master-address  (do-set-active-master-address cause)
    ::
        %file
      ?>  ?=(%write +<.cause)
      [[%exit 0]~ state]
    ==
  ==
  ::
  ++  do-grpc-bind
    |=  [=cause:wt typ=@tas]
    %-  (debug "grpc-bind")
    ?>  ?=(%grpc-bind -.cause)
    ?+    typ  !!
        %balance
      (do-update-balance-grpc [%update-balance-grpc result.cause])
    ==
  ::
  ++  do-update-balance-grpc
    |=  =cause:wt
    ?>  ?=(%update-balance-grpc -.cause)
    %-  (debug "update-balance-grpc")
    %-  (debug "last balance size: {<(lent ~(tap z-by:zo notes.balance.state))>}")
    =/  softed=(unit (unit (unit balance:wt)))
      %-  (soft (unit (unit balance:wt)))
      balance.cause
    ?~  softed
      %-  (debug "do-update-balance-grpc: %balance: could not soft result")
      [~ state]
    =/  balance-result=(unit (unit _balance.state))  u.softed
    ?~  balance-result
      %-  (warn "%update-balance did not return a result: bad path")
      [~ state]
    ?~  u.balance-result
      %-  (warn "%update-balance did not return a result: nothing")
      [~ state]
    =/  update=balance:wt  u.u.balance-result
    =?  balance.state  (gte height.update height.balance.state)
      ?:  ?&  =(height.update height.balance.state)
              =(block-id.balance.state block-id.update)
          ==
          ~>  %slog.[0 'Received balance update from same block, adding update to current balance']
          ::  If it is duplicate balance update for the same address, union should have no impact
          update(notes (~(uni z-by:zo notes.balance.state) notes.update))
      ~>  %slog.[0 'Received balance update for new heaviest block, overwriting balance with update']
      update
    %-  (debug "balance state updated!")
    [~ state]
  ::
  ++  do-import-keys
    |=  =cause:wt
    ?>  ?=(%import-keys -.cause)
    =/  new-keys=_keys.state
      %+  roll  keys.cause
      |=  [[=trek raw-meta=*] acc=_keys.state]
      =/  converted-meta=meta:wt
        ;;  meta:wt
        ?.  ?=(%coil -.raw-meta)
          ::  non-coil meta (label, seed, watch-key) - unchanged
          raw-meta
        ::  it's a coil, check if it's already versioned
        ::  meta-v3 coil: [%coil [%0|%1 coil-data]]
        ::  meta-v0 coil: [%coil coil-data]
        ::  we can check if +.raw-meta is itself a cell with %0 or %1 head
        =/  inner  +.raw-meta
        ?:  ?&  ?=(^ inner)
                ?|  ?=(%0 -.inner)
                    ?=(%1 -.inner)
                ==
            ==
          ::  already meta-v3 format
          raw-meta
        ::  old meta-v0 format, convert to meta-v3
        ::  inner is coil-data [=key =cc], wrap as [%0 coil-data]
        [%coil [%0 inner]]
      (~(put of acc) trek converted-meta)
    =/  master-key=coil:wt
      %-  head
      %+  murn  ~(tap of new-keys)
      |=  [t=trek m=meta:wt]
      ^-  (unit coil:wt)
      ?:  ?&
            ?=(%coil -.m)
            =((slag 2 t) /pub/m)
          ==
        `p.m
      ~
    =/  key-list=(list tape)
      %+  murn  ~(tap of new-keys)
      |=  [t=trek m=meta:wt]
      ^-  (unit tape)
      ?.  ?=(%coil -.m)  ~
      =/  =coil:wt  p.m
      =/  key-type=tape  ?:(?=(%pub -.key.coil) "Public Key" "Private Key")
      =/  key=@t  (slav %t (snag 1 (pout t)))
      =+  (to-b58:coil:wt coil)
      %-  some
      """
      - {key-type}: {(trip key-b58)}
      - Parent Key: {(trip key)}
      ---

      """
    =.  active-master.state  `master-key
    =.  keys.state  new-keys
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Imported Keys

        {(zing key-list)}
        """
        [%exit 0]
    ==
  ::
  ++  do-import-watch-only-pubkey
    |=  =cause:wt
    ?>  ?=(%import-watch-only-pubkey -.cause)
    :_  state(keys (watch-key:put:v key.cause))
    :~  :-  %markdown
        %-  crip
        """
        ## Imported watch-only pubkey

        - Imported key: {<key.cause>}
        """
        [%exit 0]
    ==
  ::
  ++  do-import-extended
    |=  =cause:wt
    ?>  ?=(%import-extended -.cause)
    %-  (debug "import-extended: {<extended-key.cause>}")
    =/  core  (from-extended-key:s10 extended-key.cause)
    =/  is-private=?  !=(0 prv:core)
    =/  key-type=?(%pub %prv)  ?:(is-private %prv %pub)
    =/  coil-key=key:wt
      ?:  is-private
        [%prv private-key:core]
      [%pub public-key:core]
    =/  protocol-version=@  protocol-version:core
    =/  [imported-coil=coil:wt public-coil=coil:wt]
      ?+    protocol-version  ~|('unsupported protocol version' !!)
           %0
        :-  [%0 coil-key chain-code:core]
        [%0 [%pub public-key] chain-code]:core
      ::
           %1
         :-  [%1 coil-key chain-code:core]
         [%1 [%pub public-key] chain-code]:core
      ==
    =/  key-label=@t
      ?:  is-private
        (crip "imported-private-{<(end [3 4] public-key:core)>}")
      (crip "imported-public-{<(end [3 4] public-key:core)>}")
    ::  if this is a master key (no parent), set as master
    ?:  =(0 dep:core)
      =.  active-master.state  (some public-coil)
      =.  keys.state  (key:put:v imported-coil ~ `key-label)
      =.  keys.state  (key:put:v public-coil ~ `key-label)
      =/  extended-type=tape  ?:(is-private "private" "public")
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          ## Imported {extended-type} key

          - import key: {(trip extended-key.cause)}
          - label: {(trip key-label)}
          - set as active master key
          """
          [%exit 0]
      ==
    ::  otherwise, import as derived key
    ::  first validate that this key is actually a child of the current master
    ?~  active-master.state
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          ## import failed

          cannot import derived key: no active master key set
          """
          [%exit 1]
      ==
    =/  master-pubkey-coil=coil:wt  (public:active:wt active-master.state)
    =/  expected-children=(set coil:wt)
      (derive-child:v ind:core)
    =/  imported-pubkey=@  public-key:core
    ::  find the public key coil from the derived children set
    =/  expected-pubkey-coil=(unit coil:wt)
      %-  ~(rep in expected-children)
      |=  [=coil:wt acc=(unit coil:wt)]
      ?^  acc  acc
      ?:  ?=(%pub -.key.coil)
        `coil
      ~
    ?~  expected-pubkey-coil
      ~|("no public key found in derived children - this should not happen" !!)
    =/  expected-pubkey=@  p.key.u.expected-pubkey-coil
    ?.  =(imported-pubkey expected-pubkey)
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          ## Import Failed

          Imported key at index {<ind:core>} does not match expected child of master key

          - Imported Public Key: {<imported-pubkey>}
          - Expected Public Key: {<expected-pubkey>}
          """
          [%exit 1]
      ==
    ::  key is valid, proceed with import
    =.  keys.state  (key:put:v imported-coil `ind:core `key-label)
    =/  extended-type=tape  ?:(is-private "private" "public")
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Imported {extended-type} Key

        - Import Key: {(trip extended-key.cause)}
        - Label: {(trip key-label)}
        - Index: {<ind:core>}
        - Verified as child of active master key
        """
        [%exit 0]
    ==
  ::
  ++  do-export-keys
    |=  =cause:wt
    ?>  ?=(%export-keys -.cause)
    =/  keys-list=(list [trek meta:wt])
      ~(tap of keys.state)
    =/  dat-jam  (jam keys-list)
    =/  path=@t  'keys.export'
    =/  =effect:wt  [%file %write path dat-jam]
    :_  state
    :~  effect
        :-  %markdown
        %-  crip
        """
        ## Exported Keys

        - Path: {<path>}
        """
        [%exit 0]
    ==
  ::
  ++  do-export-master-pubkey
    |=  =cause:wt
    ?>  ?=(%export-master-pubkey -.cause)
    %-  (debug "export-master-pubkey")
    ?~  active-master.state
      %-  (warn "wallet: no active keys available for export")
      [[%exit 0]~ state]
    =/  master-coil=coil:wt  ~(master get:v %pub)
    ?.  ?=(%pub -.key.master-coil)
      %-  (warn "wallet: fatal: master pubkey malformed")
      [[%exit 0]~ state]
    =/  dat-jam=@  (jam master-coil)
    =/  [key-b58=@t cc-b58=@t]  (to-b58:coil:wt master-coil)
    =/  extended-key=@t
      =/  core  (from-public:s10 ~(keyc get:coil:wt master-coil))
      extended-public-key:core
    =/  file-path=@t  'master-pubkey.export'
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Exported Master Public Key

        - Import Key: {(trip extended-key)}
        - Public Key: {(trip key-b58)}
        - Chain Code: {(trip cc-b58)}
        - Version: {<-.master-coil>}
        - File: {(trip file-path)}
        """
        [%exit 0]
        [%file %write file-path dat-jam]
    ==
  ::
  ++  do-import-master-pubkey
    |=  =cause:wt
    ?>  ?=(%import-master-pubkey -.cause)
    %-  (debug "import-master-pubkey: {<coil.cause>}")
    =/  raw-coil=*  coil.cause
    =/  master-pubkey-coil=coil:wt
      ;;  coil:wt
      ?:  ?&  ?=(^ raw-coil)
              ?|  ?=(%0 -.raw-coil)
                  ?=(%1 -.raw-coil)
              ==
          ==
        ::  already coil-v3 format
        raw-coil
      ::  old coil-v0 format, convert to coil-v3
      ::  raw-coil is coil-data [=key =cc], wrap as [%0 coil-data]
      [%0 +.raw-coil]
    =.  active-master.state  (some master-pubkey-coil)
    =/  label  `(crip "master-public-{<(end [3 4] p.key.master-pubkey-coil)>}")
    =.  keys.state  (key:put:v master-pubkey-coil ~ label)
    =/  [key-b58=@t cc-b58=@t]  (to-b58:coil:wt master-pubkey-coil)
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Imported Master Public Key

        - Public Key: {(trip key-b58)}
        - Chain Code: {(trip cc-b58)}
        - Version: {<-.master-pubkey-coil>}
        """
        [%exit 0]
    ==
  ::
  ++  do-gen-master-privkey
    |=  =cause:wt
    ?>  ?=(%gen-master-privkey -.cause)
    ::  We do not need to reverse the endian-ness of the seedphrase
    ::  because the bip39 code expects a tape.
    =/  seed=byts  [64 (to-seed:bip39 (trip seedphrase.cause) "")]
    =/  cor  (from-seed:s10 seed)
    =/  master-pubkey-coil=coil:wt  [%1 [%pub public-key] chain-code]:cor
    =/  master-privkey-coil=coil:wt  [%1 [%prv private-key] chain-code]:cor
    =.  active-master.state  (some master-pubkey-coil)
    =/  public-label  `(crip "master-public-{<(end [3 4] public-key:cor)>}")
    =/  private-label  `(crip "master-private-{<(end [3 4] public-key:cor)>}")
    =.  keys.state  (key:put:v master-privkey-coil ~ private-label)
    =.  keys.state  (key:put:v master-pubkey-coil ~ public-label)
    =.  keys.state  (seed:put:v seedphrase.cause)
    =/  [public-b58=@t cc-b58=@t]  (to-b58:coil:wt master-pubkey-coil)
    =/  [private-b58=@t *]  (to-b58:coil:wt master-privkey-coil)
    %-  (debug "active-master.state: {<active-master.state>}")
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Master Key (Imported)

        - Seed Phrase: {<seedphrase.cause>}
        - Master Public Key: {(trip public-b58)}
        - Master Private Key: {(trip private-b58)}
        - Chain Code: {(trip cc-b58)}
        - Version: {<-.master-pubkey-coil>}
        """
        [%exit 0]
    ==
  ::
  ++  do-send-tx
    |=  =cause:wt
    ?>  ?=(%send-tx -.cause)
    %-  (debug "send-tx: creating raw-tx")
    ::
    ::  note that new:raw-tx calls +validate already
    =/  raw=raw-tx:transact  (new:raw-tx:v0:transact p.dat.cause)
    =/  nock-cause=$>(%fact cause:dumb)
      [%fact %0 %heard-tx raw]
    %-  (debug "send-tx: made raw-tx, sending poke request over grpc")
    =/  pid  generate-pid:v
    :_  state
    :~
      [%grpc %poke pid nock-cause]
      [%nockchain-grpc %send-tx raw]
      [%exit 0]
    ==
  ::
  ++  do-show-tx
    |=  =cause:wt
    ?>  ?=(%show-tx -.cause)
    %-  (debug "show-tx: displaying transaction")
    =/  =transaction:wt  dat.cause
    =/  transaction-name=@t  name.transaction
    =/  ins-transaction=inputs:v0:transact  p.transaction
    =/  markdown-text=@t  (transaction:v0:display:utils transaction-name ins-transaction)
    :_  state
    :~
      [%markdown markdown-text]
      [%exit 0]
    ==
  ::
  ++  do-list-active-addresses
    |=  =cause:wt
    ?>  ?=(%list-active-addresses -.cause)
    =/  base58-sign-keys=(list tape)
      %+  turn  ~(coils get:v %pub)
      |=  =coil:wt
      =/  [key-b58=@t cc-b58=@t]  (to-b58:coil:wt coil)
      =/  version  -.coil
      =/  receive-address=@t
        ?:  =(%0 version)
          key-b58
        (pkh-b58-from-pubkey-b58:utils key-b58)
      """
      - Receive Address: {(trip receive-address)}
      - Chain Code: {(trip cc-b58)}
      - Version: {<version>}
      ---

      """
    =/  base58-watch-keys=(list tape)
      %+  turn  watch-keys:get:v
      |=  key-b58=@t
      """
      - {<key-b58>}
      ---

      """
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Addresses -- Signing

        {?~(base58-sign-keys "No pubkeys found" (zing base58-sign-keys))}

        ## Addresses -- Watch only

        {?~(base58-watch-keys "No pubkeys found" (zing base58-watch-keys))}
        """
        [%exit 0]
    ==
  ::
  ++  do-show-seedphrase
    |=  =cause:wt
    ?>  ?=(%show-seedphrase -.cause)
    %-  (debug "show-seedphrase")
    =/  =meta:wt  seed:get:v
    =/  seedphrase=@t
      ?:  ?=(%seed -.meta)
        +.meta
      %-  crip
      "no seedphrase found"
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Seed Phrase

        {<seedphrase>}
        """
        [%exit 0]
    ==
  ::
  ++  do-show-master-pubkey
    |=  =cause:wt
    ?>  ?=(%show-master-pubkey -.cause)
    %-  (debug "show-master-pubkey")
    =/  =coil:wt  ~(master get:v %pub)
    =/  extended-key=@t
      =/  core  (from-public:s10 ~(keyc get:coil:wt coil))
      extended-public-key:core
    =/  [key-b58=@t cc-b58=@t]  (to-b58:coil:wt coil)
    =/  version  -.coil
    =/  receive-address=@t
      ?:  =(%0 version)
        key-b58
      (pkh-b58-from-pubkey-b58:utils key-b58)
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Master Public Key

        - Import Key: {(trip extended-key)}
        - Receive Address: {(trip receive-address)}
        - Chain Code: {(trip cc-b58)}
        - Version: {<version>}
        """
        [%exit 0]
    ==
  ::
  ++  do-show-master-privkey
    |=  =cause:wt
    ?>  ?=(%show-master-privkey -.cause)
    %-  (debug "show-master-privkey")
    =/  =coil:wt  ~(master get:v %prv)
    =/  extended-key=@t
      =/  core  (from-private:s10 ~(keyc get:coil:wt coil))
      extended-private-key:core
    =/  [key-b58=@t cc-b58=@t]  (to-b58:coil:wt coil)
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Master Private Key

        - Import Key: {(trip extended-key)}
        - Private Key: {(trip key-b58)}
        - Chain Code: {(trip cc-b58)}
        - Version: {<-.coil>}
        """
        [%exit 0]
    ==
  ::
  ++  do-list-notes
    |=  =cause:wt
    ?>  ?=(%list-notes -.cause)
    %-  (debug "list-notes")
    :_  state
    :~  :-  %markdown
      %-  crip
      %+  welp
      """
      ## Wallet Notes

      """
      =-  ?:  =("" -)  "No notes found"  -
      %-  zing
      %+  turn  ~(val z-by:zo notes.balance.state)
      |=  =nnote:transact
      %-  trip
      (note:v0:display:utils nnote)
      ::
      [%exit 0]
    ==
  ::
  ++  do-list-notes-by-pubkey
    |=  =cause:wt
    ?>  ?=(%list-notes-by-pubkey -.cause)
    =/  target-pubkey=schnorr-pubkey:transact
      (from-b58:schnorr-pubkey:transact pubkey.cause)
    =/  matching-notes=(list [name=nname:transact note=nnote:transact])
      %+  skim  ~(tap z-by:zo notes.balance.state)
      |=  [name=nname:transact note=nnote:transact]
      ?^  -.note
        ::  v0 note
        (~(has z-in:zo pubkeys.sig.note) target-pubkey)
      =+  (make-pkh:spend-condition:transact 1 ~[target-pubkey])
      =(-.name (first:nname:transact root))
    :_  state
    :~  :-  %markdown
        %-  crip
        %+  welp
          """
          ## Wallet Notes for Public Key {<(to-b58:schnorr-pubkey:transact target-pubkey)>}

          """
        =-  ?:  =("" -)  "No notes found"  -
        %-  zing
        %+  turn  matching-notes
        |=  [* =nnote:transact]
        %-  trip
        (note:v0:display:utils nnote)
        ::
        [%exit 0]
    ==
  ::
  ++  do-list-notes-by-pubkey-csv
    |=  =cause:wt
    ?>  ?=(%list-notes-by-pubkey-csv -.cause)
    =/  target-pubkey=schnorr-pubkey:transact
      (from-b58:schnorr-pubkey:transact pubkey.cause)
    =/  matching-notes=(list [name=nname:transact note=nnote:transact])
      %+  skim  ~(tap z-by:zo notes.balance.state)
      |=  [name=nname:transact note=nnote:transact]
      ?^  -.note
        ::  v0 note
        (~(has z-in:zo pubkeys.sig.note) target-pubkey)
      =+  (make-pkh:spend-condition:transact 1 ~[target-pubkey])
      =(-.name (first:nname:transact root))
    =/  csv-header=tape
      "name_first,name_last,assets,block_height,source_hash"
    =/  csv-rows=(list tape)
      %+  turn  matching-notes
      |=  [name=nname:transact note=nnote:transact]
      ?^  -.note
        ::  v0 note
        =/  name-b58=[first=@t last=@t]  (to-b58:nname:transact name)
        =/  source-hash-b58=@t  (to-b58:hash:transact p.source.note)
        """
        {(trip first.name-b58)},{(trip last.name-b58)},{(ui-to-tape:utils assets.note)},{(ui-to-tape:utils origin-page.note)},{(trip source-hash-b58)}
        """
      ::  v1 note
      =/  name-b58=[first=@t last=@t]  (to-b58:nname:transact name)
      =/  source-hash-b58=@t  'N/A'
      """
      {(trip first.name-b58)},{(trip last.name-b58)},{(ui-to-tape:utils assets.note)},{(ui-to-tape:utils origin-page.note)},{(trip source-hash-b58)}
      """
    =/  csv-content=tape
      %+  welp  csv-header
      %+  welp  "\0a"
      %-  zing
      %+  turn  csv-rows
      |=  row=tape
      "{row}\0a"
    =/  filename=@t
      %-  crip
      "notes-{(trip (to-b58:schnorr-pubkey:transact target-pubkey))}.csv"
    :_  state
    :~  :-  %file
        :-  %write
        :-  filename
        %-  crip
        csv-content
        [%exit 0]
    ==
  ::
  ++  do-create-tx
    |=  =cause:wt
    ?>  ?=(%create-tx -.cause)
    |^
    %-  (debug "create-tx: {<names.cause>}")
    =/  names=(list nname:transact)  (parse-names names.cause)
    ?~  active-master.state
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          Cannot create a transaction without active master address set. Please import a master key or generate a new one.
          """
          [%exit 0]
      ==
    ?:  ?=(%1 -.u.active-master.state)
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          Active address corresponds to v1 key. Cannot sign a v0 transaction with v1 keys. Use the `list-master-addresses`
          command to list your master addresses. Then use `set-active-master-address` to set your active address to one corresponding
          to a v0 key if available.
          """
          [%exit 0]
      ==
    =/  sign-key  (sign-key:get:v sign-key.cause)
    =/  ins=inputs:v0:transact
      =+  ins=(tx-builder names order.cause fee.cause sign-key timelock-intent.cause get-note-v0:v)
      %-  ~(gas z-by:zo *(z-map:zo nname:transact input:v0:transact))
      %+  turn
        ~(tap z-by:zo ins)
      |=  [name=nname:transact input=input:transact]
      ^-  [nname:transact input:v0:transact]
      ?>  ?=(%0 -.input)
      [name +.input]
    (save-transaction ins)
    ::
    ++  parse-names
      |=  raw-names=(list [first=@t last=@t])
      ^-  (list nname:transact)
      %+  turn  raw-names
      |=  [first=@t last=@t]
      (from-b58:nname:transact [first last])
    ::
    ++  validate-inputs
      |=  =inputs:v0:transact
      ^-  ?
      ?&  (validate:inputs:v0:transact inputs)
          %+  levy  ~(tap z-by:zo inputs)
          |=  [name=nname:transact inp=input:v0:transact]
          (spendable:sig:transact sig.note.inp)
      ==
    ::
    ++  save-transaction
      |=  ins=inputs:v0:transact
      ^-  [(list effect:wt) state:wt]
      ~&  "Validating transaction before saving"
      ::  we fallback to the hash of the inputs as the transaction name
      ::  if the tx is invalid. this is just for display
      ::  in the error message, as an invalid tx is not saved.
      =/  transaction-name=@t
        %-  to-b58:hash:transact
        =-  %+  fall  -
            (hash:inputs:v0:transact ins)
        %-  mole
        |.
        ::  TODO: this also calls validate:inputs, but we need it to
        ::  get the id of the transaction. we should deduplicate this.
        id:(new:raw-tx:v0:transact ins)
      ::  jam inputs and save as transaction
      =/  =transaction:wt
        %*  .  *transaction:wt
          p  ins
          name  transaction-name
        ==
      ?.  (validate-inputs ins)
        =/  msg=@t
          %^  cat  3
            %-  crip
            """
            # TX Validation Failed

            Failed to validate the correctness of transaction {(trip transaction-name)}.

            Check that the note(s) you are spending from:

            1. Can be spent by the public key you are signing with.
            2. Have enough assets to cover the gift and fee.
            3. Have the correct timelock intent.

            ---


            """
          (transaction:v0:display:utils transaction-name ins)
        %-  (debug "{(trip msg)}")
        :_  state
        :~  [%markdown msg]
            [%exit 1]
        ==
      =/  transaction-jam  (jam transaction)
      =/  markdown-text=@t  (transaction:v0:display:utils transaction-name ins)
      =/  path=@t
        %-  crip
        "./txs/{(trip name.transaction)}.tx"
      %-  (debug "saving transaction to {<path>}")
      =/  =effect:wt  [%file %write path transaction-jam]
      :-  ~[effect [%markdown markdown-text] [%exit 0]]
      state
    --
  ::
  ++  do-keygen
    |=  =cause:wt
    ?>  ?=(%keygen -.cause)
    =+  [seed-phrase=@t cor]=(gen-master-key:s10 entropy.cause salt.cause)
    =/  master-public-coil  [%1 [%pub public-key] chain-code]:cor
    =/  master-private-coil  [%1 [%prv private-key] chain-code]:cor
    =/  old-active  active-master.state
    =.  active-master.state  (some master-public-coil)
    %-  (debug "keygen: public key: {<(en:base58:wrap public-key:cor)>}")
    %-  (debug "keygen: private key: {<(en:base58:wrap private-key:cor)>}")
    =/  pub-label  `(crip "master-public-{<(end [3 4] public-key:cor)>}")
    =/  prv-label  `(crip "master-public-{<(end [3 4] public-key:cor)>}")
    =.  keys.state  (key:put:v master-public-coil ~ pub-label)
    =.  keys.state  (key:put:v master-private-coil ~ prv-label)
    =.  keys.state  (seed:put:v seed-phrase)
    =/  extended-private=@t  extended-private-key:cor
    =/  extended-public=@t  extended-public-key:cor
    =/  [pubkey-b58=@t cc-b58=@t]  (to-b58:coil:wt master-public-coil)
    =/  [prvkey-b58=@t *]  (to-b58:coil:wt master-private-coil)
    =/  pkh-b58=@t  (pkh-b58-from-pubkey-b58:utils pubkey-b58)
    ::  If there was already an active master address, set it back to the old master address
    ::  The new keys generated are stored in the keys state and the user can manually
    ::  switch to them by running `set-active-master-address`
    =?  active-master.state  ?=(^ old-active)
      old-active
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Generated New Master Key
        Added keys to wallet.

        ### Receive Address (pkh address)
        {(trip pkh-b58)}

        ### Private Key
        {(trip prvkey-b58)}

        ### Chain Code
        {(trip cc-b58)}

        ### Import Private Key
        {(trip extended-private)}

        ### Import Public Key
        {(trip extended-public)}

        ### Seed Phrase
        {<seed-phrase>}
        """
        [%exit 0]
    ==
  ::
  ::  derives child keys of current master key
  ::  at index `i`. this will overwrite existing paths if
  ::  the master key changes
  ++  do-derive-child
    |=  =cause:wt
    ?>  ?=(%derive-child -.cause)
    =/  index
      ?:  hardened.cause
        (add i.cause (bex 31))
      i.cause
    =/  derived-keys=(set coil:wt)  (derive-child:v index)
    =.  keys.state
      %-  ~(rep in derived-keys)
      |=  [=coil:wt keys=_keys.state]
      =.  keys.state  keys
      (key:put:v coil `index label.cause)
    =/  key-text=tape
      %-  zing
      %+  turn  ~(tap in derived-keys)
      |=  =coil:wt
      =/  [key-b58=@t cc-b58=@t]  (to-b58:coil:wt coil)
      =/  version  -.coil
      =/  receive-address=@t
        ?:  ?=(%pub -.key.coil)
          ?:  =(%0 version)
            key-b58
          (pkh-b58-from-pubkey-b58:utils key-b58)
        'N/A (private key)'
      =/  key-type=tape
        ?:  ?=(%pub -.key.coil)
          "Public Key"
        "Private Key"
      """
      - {key-type}: {(trip key-b58)}
      - Receive Address: {(trip receive-address)}
      - Chain Code: {(trip cc-b58)}
      - Version: {<version>}
      ---

      """
    :_  state
    :~
      :-  %markdown
      %-  crip
      """
      ## Derive Child

      ### Derived Keys
      {key-text}
      """
      [%exit 0]
    ==
  ::
  ++  do-sign-tx
    |=  =cause:wt
    ?>  ?=(%sign-tx -.cause)
    %-  (debug "sign-tx: {<dat.cause>}")
    ?~  active-master.state
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          Cannot sign a transaction without active master address set. Please import a master key or generate a new one.
          """
          [%exit 0]
      ==
    ?:  ?=(%1 -.u.active-master.state)
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          Cannot sign a v0 transaction with v1 keys. Use the `list-master-addresses` command to list your master addresses.
          Then use `set-active-master-address` to set your master address to one corresponding to a v0 key if available.
          """
          [%exit 0]
      ==
    =/  sender-key=schnorr-seckey:transact
      (sign-key:get:v sign-key.cause)
    =/  signed-inputs=inputs:v0:transact
      %-  ~(run z-by:zo p.dat.cause)
      |=  input=input:v0:transact
      %-  (debug "signing input: {<input>}")
      =.  spend.input
        (sign:spend:v0:transact spend.input sender-key)
      input
    =/  signed-transaction=transaction:wt
      %=  dat.cause
        p  signed-inputs
      ==
    =/  transaction-jam  (jam signed-transaction)
    =/  path=@t
      %-  crip
      "./txs/{(trip name.signed-transaction)}.tx"
    %-  (debug "saving signed transaction to {<path>}")
    =/  =effect:wt  [%file %write path transaction-jam]
    :-  ~[effect [%exit 0]]
    state
  ::
  ++  do-sign-message
    |=  =cause:wt
    ?>  ?=(%sign-message -.cause)
    ?~  active-master.state
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          Cannot sign a message without active master address set. Please import a master key or generate a new one.
          """
          [%exit 0]
      ==
    ?:  ?=(%1 -.u.active-master.state)
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          Cannot sign a message with v1 keys until forthcoming wallet update. Use the `list-master-addresses` command to list
          your master addresses. Then use `set-active-master-address` to set your master address to an address corresponding
          to a v0 key if available.
          """
          [%exit 0]
      ==
    =/  sk=schnorr-seckey:transact  (sign-key:get:v sign-key.cause)
    =/  msg-belts=page-msg:transact  (new:page-msg:transact `cord`msg.cause)
    ?.  (validate:page-msg:transact msg-belts)
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          # Message could not be converted to a list of based elements, cannot sign

          ### Message

          {(trip `@t`msg.cause)}

          """
          [%exit 1]
      ==
    =/  digest  (hash:page-msg:transact msg-belts)
    =/  sig=schnorr-signature:transact
      %+  sign:affine:belt-schnorr:cheetah:z
        sk
      digest
    =/  sig-hash  (hash:schnorr-signature:transact sig)
    =/  sig-jam=@  (jam sig)
    =/  path=@t  'message.sig'
    =/  markdown-text=@t
      %-  crip
      """
      # Message signed, signature saved to message.sig

      ### Message

      {(trip `@t`msg.cause)}

      ### Signature (Hashed)

      {(trip (to-b58:hash:transact sig-hash))}

      """
    :_  state
    :~  [%file %write path sig-jam]
        [%markdown markdown-text]
        [%exit 0]
    ==
  ::
  ++  do-verify-message
    |=  =cause:wt
    ?>  ?=(%verify-message -.cause)
    =/  sig=schnorr-signature:transact
      (need ((soft schnorr-signature:transact) (cue sig.cause)))
    =/  pk=schnorr-pubkey:transact
      (from-b58:schnorr-pubkey:transact pk-b58.cause)
    =/  msg-belts=page-msg:transact  (new:page-msg:transact `cord`msg.cause)
    ?.  (validate:page-msg:transact msg-belts)
      :_  state
      :~  :-  %markdown
          %-  crip
          """
          # Message could not be converted to a list of based elements, cannot verify signature

          ### Message

          {(trip `@t`msg.cause)}

          """
          [%exit 1]
      ==
    =/  digest  (hash:page-msg:transact msg-belts)
    =/  ok=?
      %:  verify:affine:belt-schnorr:cheetah:z
          pk
          digest
          sig
      ==
    :_  state
    :~  :-  %markdown
        ?:  ok  '# Valid signature, message verified'  '# Invalid signature, message not verified'
        [%exit ?:(ok 0 1)]
    ==
  ::
  ++  do-sign-hash
    |=  =cause:wt
    ?>  ?=(%sign-hash -.cause)
    =/  sk=schnorr-seckey:transact  (sign-key:get:v sign-key.cause)
    =/  digest=hash:transact  (from-b58:hash:transact hash-b58.cause)
    =/  sig=schnorr-signature:transact
      %+  sign:affine:belt-schnorr:cheetah:z
        sk
      digest
    =/  sig-jam=@  (jam sig)
    =/  path=@t  'hash.sig'
    :_  state
    :~  [%file %write path sig-jam]
        [%markdown '## Hash signed, signature saved to hash.sig']
        [%exit 0]
    ==
  ::
  ++  do-verify-hash
    |=  =cause:wt
    ?>  ?=(%verify-hash -.cause)
    =/  sig=schnorr-signature:transact
      (need ((soft schnorr-signature:transact) (cue sig.cause)))
    =/  pk=schnorr-pubkey:transact
      (from-b58:schnorr-pubkey:transact pk-b58.cause)
    =/  digest=hash:transact  (from-b58:hash:transact hash-b58.cause)
    =/  ok=?
      %:  verify:affine:belt-schnorr:cheetah:z
          pk
          digest
          sig
      ==
    :_  state
    :~  :-  %markdown
        ?:  ok  '# Valid signature, hash verified'  '# Invalid signature, hash not verified'
        [%exit ?:(ok 0 1)]
    ==
    ::
  ++  do-list-master-addresses
    |=  =cause:wt
    ?>  ?=(%list-master-addresses -.cause)
    %-  (debug "list-master-addresses")
    =/  master-addrs=(list tape)
      %+  turn
        master-addresses:get:v
      |=  addr=@t
      ::  because the encoded public key is fixed width, v0 addresses will be fixed length.
      ::  thus, we can use the length of the b58 encoded address to determine the version
      =/  version  ?:(=(132 (met 3 addr)) %0 %1)
      =?  addr  =(addr (to-b58:active:wt active-master.state))
        (cat 3 addr ' **(active)**')
      """
      - Receive Address: {(trip addr)}
      - Version: {<version>}
      ---

      """
    :_  state
    :~  :-  %markdown
        %-  crip
        """
        ## Master Address Information
        Note: Receive addresses are the same as pubkeys for v0 keys. For v1 keys, the receive address is the hash of the public key.

        {(zing master-addrs)}
        """
        [%exit 0]
    ==
  ::
  ++  do-set-active-master-address
    |=  =cause:wt
    ?>  ?=(%set-active-master-address -.cause)
    %-  (debug "set-active-master-address")
    =/  addr-b58=@t  address-b58.cause
    =/  =coil:wt  (master-by-addr:get:v addr-b58)
    :_  state(active-master `coil)
    :~  :-  %markdown
        %-  crip
        """
        ## Set Active Master Address To:

        - {(trip addr-b58)}
        """
        [%exit 0]
    ==
  ::
  --  ::+poke
--
