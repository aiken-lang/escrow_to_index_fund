use aiken/transaction.{OutputReference}
use aiken/transaction/credential.{Address}

pub type EscrowActionV2 {
  Unlock
  Update
  UpdatePastVersion
}

pub type EscrowRedeemV2 {
  action: EscrowActionV2,
  control_reference: OutputReference,
}

pub type EscrowStateV2 {
  tag: Data,
  owner: Address,
  auto_update: Bool,
}
