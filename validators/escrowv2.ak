use aiken/builtin
use aiken/dict
use aiken/hash
use aiken/list
use aiken/transaction.{InlineDatum, Output, ScriptContext, Spend, Transaction}
use aiken/transaction/credential.{ScriptCredential, VerificationKeyCredential}
use aiken/transaction/value.{quantity_of}
use escrow_to_index_fund/types.{ControlState, State}
use escrow_to_index_fund/v1/types as v1
use escrow_to_index_fund/v2/types as v2

validator(control_nft_policy: ByteArray) {
  fn escrow_v2(
    datum: Data,
    redeemer: v2.EscrowRedeemV2,
    ctx: ScriptContext,
  ) -> Bool {
    let ScriptContext { transaction, purpose } = ctx

    expect Spend(ref) = purpose

    let Transaction { inputs, reference_inputs, outputs, mint, .. } =
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

    // allow for update but don't force it
    when redeemer.action is {
      // Unlock if contract is current version and owner is present
      v2.Unlock -> {
        expect v2.EscrowStateV2 { owner, auto_update, .. }: v2.EscrowStateV2 =
          datum

        todo
      }

      // Update from previous version to current version
      v2.UpdatePastVersion -> {
        // Checking for previous version here
        // State is a generic type, so we need to specify the type
        expect State { escrow_state: v1_escrow, version: 1 }: State<
          v1.EscrowState,
        > = datum

        expect Some(own_input) =
          list.find(inputs, fn(inp) { inp.output_reference == ref })

        expect [(token_name, 1)] =
          own_input.output.value
            |> value.tokens(control_nft_policy)
            |> dict.to_list

        let mint = value.from_minted_value(mint)

        expect quantity_of(mint, control_nft_policy, token_name) == -1
        //
        expect Some(Output { value: out_value, .. }) =
          list.find(
            outputs,
            fn(out) {
              if out.address == own_input.output.address {
                expect InlineDatum(out_datum) = out.datum

                expect State { escrow_state, version }: State<v2.EscrowStateV2> =
                  out_datum
                // datum
                let out_tag: Data =
                  ref |> builtin.serialise_data |> hash.blake2b_256

                and {
                  out_tag == escrow_state.tag,
                  version == 2,
                  v1_escrow.owner == escrow_state.owner,
                  !escrow_state.auto_update,
                }
              } else {
                False
              }
            },
          )

        let value =
          own_input.output.value
            |> value.to_dict
            |> dict.delete(control_nft_policy)

        value == value.to_dict(out_value)
      }

      v2.Update -> {
        expect datum: State<v2.EscrowStateV2> = datum

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
