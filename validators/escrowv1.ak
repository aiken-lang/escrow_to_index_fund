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
use escrow_to_index_fund/v1/types as v1

validator(nft_policy: ByteArray) {
  fn escrow(
    datum: v1.EscrowState,
    redeemer: v1.EscrowRedeem,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = ctx

    expect Spend(ref) = purpose

    let Transaction { inputs, reference_inputs, outputs, extra_signatories, .. } =
      transaction

    expect Some(Input { output, .. }) =
      list.find(inputs, fn(inp) { inp.output_reference == ref })

    let Output { address, .. } = output

    expect Some(ref_input) =
      list.find(reference_inputs, fn(inp) { inp.output_reference == ref })

    // check control contract for current version
    expect Some(control_input) =
      list.find(
        reference_inputs,
        fn(inp) { redeemer.control_reference == inp.output_reference },
      )

    expect quantity_of(control_input.output.value, nft_policy, "") == 1
    expect InlineDatum(control_datum) = control_input.output.datum

    expect Dat { current_action_validator, current_version, .. }: Dat =
      control_datum

    when redeemer.action is {
      v1.Unlock -> {
        expect datum.version == current_version
        expect VerificationKeyCredential(owner_key) =
          datum.owner.payment_credential

        list.has(extra_signatories, owner_key)
      }
      v1.Update -> {
        expect datum.version < current_version
        // check for upgrade contract
        todo
      }
    }
  }
}
