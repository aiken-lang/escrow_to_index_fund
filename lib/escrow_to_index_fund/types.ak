pub type ControlState {
  current_action_validator: ByteArray,
  governance_nft_policy: ByteArray,
  governance_nft_asset_name: ByteArray,
  current_version: Int,
}

pub type State<t> {
  escrow_state: t,
  version: Int,
}
