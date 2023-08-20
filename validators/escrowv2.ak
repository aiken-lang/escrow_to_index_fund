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
use escrow_to_index_fund/v1/types as v1
use escrow_to_index_fund/v2/types as v2

validator(nft_policy: ByteArray) {
  fn escrow_v2(
    datum: Data,
    redeemer: v2.EscrowRedeemV2,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = ctx

    expect Spend(ref) = purpose

    let Transaction { inputs, reference_inputs, outputs, .. } = transaction

    expect Some(Input { output, .. }) =
      list.find(inputs, fn(inp) { inp.output_reference == ref })

    let Output { address, value, .. } = output

    // allow for upgrade but don't force it
    when redeemer.action is {
      // Unlock if contract is current version and owner is present
      v2.Unlock -> {
        expect v2.EscrowStateV2 { owner, version, auto_upgrade, .. }: v2.EscrowStateV2 =
          datum

        todo
      }

      // Upgrade from previous version to current version
      v2.UpdatePastVersion -> {
        expect v1.EscrowState { owner, version: 1 }: v1.EscrowState = datum

        expect Some(Output { value: out_value, .. }) =
          list.find(
            outputs,
            fn(out) {
              if out.address == address {
                expect InlineDatum(out_datum) = out.datum

                expect a: v2.EscrowStateV2 = out_datum
                // datum
                let out_tag: Data =
                  ref |> builtin.serialise_data |> hash.blake2b_256

                and {
                  out_tag == a.tag,
                  a.version == 2,
                  a.owner == owner,
                  !a.auto_upgrade,
                }
              } else {
                False
              }
            },
          )

        value == out_value
      }

      v2.Update -> todo
    }
  }
}
