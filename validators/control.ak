use aiken/list
use aiken/transaction.{
  InlineDatum, Mint, OutputReference, ScriptContext, Transaction,
}
use aiken/transaction/value.{quantity_of}
use escrow_to_index_fund/types.{ControlState}

type GovernanceAction {
  ChangeActionValidator(Int)
}

type MintAction {
  Genesis(Int)
  Update
  Burn
}

/// Control Contract
validator(utxo_ref: OutputReference) {
  fn change_action_validator(
    datum: ControlState,
    redeemer: GovernanceAction,
    ctx: ScriptContext,
  ) -> Bool {
    let ControlState { governance_nft_policy, governance_nft_asset_name, .. } =
      datum

    // Check Governance nft is present
    let ScriptContext { transaction, .. } = ctx

    let Transaction { outputs, .. } = transaction

    let ChangeActionValidator(nft_output_index) = redeemer

    // Allow the nft which can be in a update validator to govern the update rules
    expect Some(output) = list.at(outputs, nft_output_index)

    quantity_of(output.value, governance_nft_policy, governance_nft_asset_name) == 1
  }

  fn mint_update_token(redeemer: MintAction, ctx: ScriptContext) -> Bool {
    // Check Governance nft is present
    let ScriptContext { transaction, purpose } = ctx

    let Transaction { inputs, outputs, .. } = transaction

    expect Mint(own_policy) = purpose

    when redeemer is {
      Genesis(output_index) -> {
        // Mint empty token name under this policy and initialize with default datum
        // Uses utxo ref to ensure genesis is run only once
        expect Some(_) =
          list.find(inputs, fn(input) { input.output_reference == utxo_ref })

        expect Some(output) = list.at(outputs, output_index)

        // can replace with look up datum
        // I use inline for simplicity
        expect InlineDatum(datum) = output.datum

        expect _: ControlState = datum

        quantity_of(output.value, own_policy, "") == 1
      }

      Update ->
        // Mints a unique token
        // Used in conjunction with Update action from the action validator for unique outputs
        todo
      Burn ->
        // Allow burning the tokens
        todo
    }
  }
}
