use aiken/builtin
use aiken/hash
use aiken/list
use aiken/transaction.{InlineDatum, ScriptContext, Spend, Transaction}
use aiken/transaction/credential.{ScriptCredential, VerificationKeyCredential}
use aiken/transaction/value.{quantity_of}
use escrow_to_index_fund/types.{ControlState, State}
use escrow_to_index_fund/v1/types as v1

validator(control_nft_policy: ByteArray) {
  fn escrow(
    datum: State<v1.EscrowState>,
    redeemer: v1.EscrowRedeem,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = ctx

    expect Spend(ref) = purpose

    let Transaction { reference_inputs, outputs, extra_signatories, mint, .. } =
      transaction

    expect Some(ref_input) =
      list.find(
        reference_inputs,
        fn(inp) { inp.output_reference == redeemer.control_reference },
      )

    // check control contract for current version
    expect quantity_of(ref_input.output.value, control_nft_policy, "") == 1
    //
    expect InlineDatum(control_datum) = ref_input.output.datum

    expect ScriptCredential(control_script) =
      ref_input.output.address.payment_credential

    expect control_script == control_nft_policy
    //
    expect ControlState { current_action_validator, current_version, .. }: ControlState =
      control_datum

    when redeemer.action is {
      v1.Unlock -> {
        expect datum.version == current_version
        //
        expect VerificationKeyCredential(owner_key) =
          datum.escrow_state.owner.payment_credential

        list.has(extra_signatories, owner_key)
      }
      v1.Update -> {
        expect datum.version < current_version
        //
        let mint = mint |> value.from_minted_value

        let token_name = ref |> builtin.serialise_data |> hash.blake2b_256

        // mints an update nft
        expect quantity_of(mint, control_nft_policy, token_name) == 1
        //
        // check for update contract
        expect Some(output) =
          list.find(
            outputs,
            fn(out) {
              when out.address.payment_credential is {
                VerificationKeyCredential(_) -> False
                ScriptCredential(sh) -> and {
                    sh == current_action_validator,
                    quantity_of(out.value, control_nft_policy, token_name) == 1,
                  }
              }
            },
          )

        expect InlineDatum(out_datum) = output.datum
        //
        let datum: Data = datum

        out_datum == datum
      }
    }
  }
}
