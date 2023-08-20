use aiken/transaction.{OutputReference}
use aiken/transaction/credential.{Address}

pub type EscrowAction {
  Unlock
  Update
}

pub type EscrowRedeem {
  action: EscrowAction,
  control_reference: OutputReference,
}

pub type EscrowState {
  owner: Address,
  version: Int,
}
