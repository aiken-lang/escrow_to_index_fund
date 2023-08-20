use aiken/transaction.{OutputReference}
use aiken/transaction/credential.{Address}

pub type EscrowActionV2 {
  Unlock
  Update
  UpdatePastVersion
}

pub type EscrowRedeemV2 {
  control_reference: OutputReference,
  action: EscrowActionV2,
}

pub type EscrowStateV2 {
  tag: Data,
  owner: Address,
  version: Int,
  auto_upgrade: Bool,
}
