use aiken/builtin
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, ScriptContext, Spend, Transaction, WithdrawFrom,
}
use aiken/transaction/credential.{
  Address, Credential, Inline, ScriptCredential, StakeCredential,
  VerificationKey, VerificationKeyCredential,
}
use aiken/transaction/value.{quantity_of}
use escrow_to_index_fund/types.{Dat}

pub const nft_policy: ByteArray = ""

pub const nft_name: ByteArray = ""

/// Control Contract
validator {
  fn change_action_validator(
    datum: Dat,
    _redeemer: Data,
    ctx: ScriptContext,
  ) -> Bool {
    let Dat { current_upgrade_contract, .. } = datum

    // Check Upgrade contract is present
    let ScriptContext { transaction, .. } = ctx

    let Transaction { inputs, .. } = transaction

    // Allow the upgrade contract to govern the update rules
    list.any(
      inputs,
      fn(inp) {
        let inp_cred = inp.output.address.payment_credential
        expect ScriptCredential(contract) = inp_cred
        contract == current_upgrade_contract
      },
    )
  }

  fn mint_upgrade_token(_redeemer: Data, ctx: ScriptContext) -> Bool {
    todo
  }
}
